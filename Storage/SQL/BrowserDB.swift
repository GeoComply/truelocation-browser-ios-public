/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Shared

private let log = Logger.syncLogger

public typealias Args = [Any?]

open class BrowserDB {
    fileprivate let db: SwiftData

    public let databasePath: String

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    public static let MaxVariableNumber = 999

    public init(filename: String, schema: Schema, files: FileAccessor) {
        log.debug("Initializing BrowserDB: \(filename).")

        self.databasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename).path

        self.db = SwiftData(filename: self.databasePath, schema: schema, files: files)
    }

    // Returns the SQLite version for debug purposes.
    public func sqliteVersion() -> Deferred<Maybe<String>> {
        return withConnection { connection -> String in
            let result = connection.executeQueryUnsafe("SELECT sqlite_version()", factory: { row -> String in
                return row[0] as? String ?? ""
            }, withArgs: nil)
            return result.asArray().first ?? ""
        }
    }

    // Returns the SQLite compile_options for debug purposes.
    public func sqliteCompileOptions() -> Deferred<Maybe<[String]>> {
        return withConnection { connection -> [String] in
            let result = connection.executeQueryUnsafe("PRAGMA compile_options", factory: { row -> String in
                return row[0] as? String ?? ""
            }, withArgs: nil)
            return result.asArray().filter({ !$0.isEmpty })
        }
    }

    // Returns the SQLite secure_delete setting for debug purposes.
    public func sqliteSecureDelete() -> Deferred<Maybe<Int>> {
        return withConnection { connection -> Int in
            let result = connection.executeQueryUnsafe("PRAGMA secure_delete", factory: { row -> Int in
                return row[0] as? Int ?? 0
            }, withArgs: nil)
            return result.asArray().first ?? 0
        }
    }

    // For testing purposes or other cases where we want to ensure that this `BrowserDB`
    // instance has been initialized (schema is created/updated).
    public func touch() -> Success {
        return withConnection { connection -> Void in
            guard let _ = connection as? ConcreteSQLiteDBConnection else {
                throw DatabaseError(description: "Could not establish a database connection")
            }
        }
    }

    /*
     * Opening a WAL-using database with a hot journal cannot complete in read-only mode.
     * The supported mechanism for a read-only query against a WAL-using SQLite database is to use PRAGMA query_only,
     * but this isn't all that useful for us, because we have a mixed read/write workload.
     */
    @discardableResult func withConnection<T>(flags: SwiftData.Flags = .readWriteCreate, _ callback: @escaping (_ connection: SQLiteDBConnection) throws -> T) -> Deferred<Maybe<T>> {
        return db.withConnection(flags, callback)
    }

    func transaction<T>(_ callback: @escaping (_ connection: SQLiteDBConnection) throws -> T) -> Deferred<Maybe<T>> {
        return db.transaction(callback)
    }

    @discardableResult func vacuum() -> Success {
        log.debug("Vacuuming a BrowserDB.")

        return withConnection({ connection -> Void in
            try connection.vacuum()
        })
    }

    @discardableResult func checkpoint() -> Success {
        log.debug("Checkpointing a BrowserDB.")

        return transaction { connection in
            connection.checkpoint()
        }
    }

    public class func varlist(_ count: Int) -> String {
        return "(" + Array(repeating: "?", count: count).joined(separator: ", ") + ")"
    }

    enum InsertOperation: String {
        case Insert = "INSERT"
        case Replace = "REPLACE"
        case InsertOrIgnore = "INSERT OR IGNORE"
        case InsertOrReplace = "INSERT OR REPLACE"
        case InsertOrRollback = "INSERT OR ROLLBACK"
        case InsertOrAbort = "INSERT OR ABORT"
        case InsertOrFail = "INSERT OR FAIL"
    }

    /**
     * Insert multiple sets of values into the given table.
     *
     * Assumptions:
     * 1. The table exists and contains the provided columns.
     * 2. Every item in `values` is the same length.
     * 3. That length is the same as the length of `columns`.
     * 4. Every value in each element of `values` is non-nil.
     *
     * If there are too many items to insert, multiple individual queries will run
     * in sequence.
     *
     * A failure anywhere in the sequence will cause immediate return of failure, but
     * will not roll back — use a transaction if you need one.
     */
    func bulkInsert(_ table: String, op: InsertOperation, columns: [String], values: [Args]) -> Success {
        // Note that there's a limit to how many ?s can be in a single query!
        // So here we execute 999 / (columns * rows) insertions per query.
        // Note that we can't use variables for the column names, so those don't affect the count.
        if values.isEmpty {
            log.debug("No values to insert.")
            return succeed()
        }

        let variablesPerRow = columns.count

        // Sanity check.
        assert(values[0].count == variablesPerRow)

        let cols = columns.joined(separator: ", ")
        let queryStart = "\(op.rawValue) INTO \(table) (\(cols)) VALUES "

        let varString = BrowserDB.varlist(variablesPerRow)

        let insertChunk: ([Args]) -> Success = { vals -> Success in
            let valuesString = Array(repeating: varString, count: vals.count).joined(separator: ", ")
            let args: Args = vals.flatMap { $0 }
            return self.run(queryStart + valuesString, withArgs: args)
        }

        let rowCount = values.count
        if (variablesPerRow * rowCount) < BrowserDB.MaxVariableNumber {
            return insertChunk(values)
        }

        log.debug("Splitting bulk insert across multiple runs. I hope you started a transaction!")
        let rowsPerInsert = (999 / variablesPerRow)
        let chunks = chunk(values, by: rowsPerInsert)
        log.debug("Inserting in \(chunks.count) chunks.")

        // There's no real reason why we can't pass the ArraySlice here, except that I don't
        // want to keep fighting Swift.
        return walk(chunks, f: { insertChunk(Array($0)) })
    }

    func write(_ sql: String, withArgs args: Args? = nil) -> Deferred<Maybe<Int>> {
        return withConnection { connection -> Int in
            try connection.executeChange(sql, withArgs: args)

            let modified = connection.numberOfRowsModified
            log.debug("Modified rows: \(modified).")
            return modified
        }
    }

    public func forceClose() {
        db.forceClose()
    }

    public func reopenIfClosed() {
        db.reopenIfClosed()
    }

    public func run(_ sql: String, withArgs args: Args? = nil) -> Success {
        return run([(sql, args)])
    }

    func run(_ commands: [String]) -> Success {
        return run(commands.map { (sql: $0, args: nil) })
    }

    /**
     * Runs an array of SQL commands. Note: These will all run in order in a transaction and will block
     * the caller's thread until they've finished. If any of them fail the operation will abort (no more
     * commands will be run) and the transaction will roll back, returning a DatabaseError.
     */
    func run(_ commands: [(sql: String, args: Args?)]) -> Success {
        if commands.isEmpty {
            return succeed()
        }

        return transaction { connection -> Void in
            for (sql, args) in commands {
                try connection.executeChange(sql, withArgs: args)
            }
        }
    }

    public func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>> {
        return withConnection { connection -> Cursor<T> in
            connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    public func runQueryConcurrently<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>> {
        return withConnection(flags: .readOnly) { connection -> Cursor<T> in
            connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    func runQueryUnsafe<T, U>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T, block: @escaping (Cursor<T>) throws -> U) -> Deferred<Maybe<U>> {
        return withConnection { connection -> U in
            let cursor = connection.executeQueryUnsafe(sql, factory: factory, withArgs: args)
            defer { cursor.close() }
            return try block(cursor)
        }
    }

    func queryReturnsResults(_ sql: String, args: Args? = nil) -> Deferred<Maybe<Bool>> {
        return runQuery(sql, args: args, factory: { _ in true })
         >>== { deferMaybe($0[0] ?? false) }
    }

    func queryReturnsNoResults(_ sql: String, args: Args? = nil) -> Deferred<Maybe<Bool>> {
        return runQuery(sql, args: nil, factory: { _ in false })
          >>== { deferMaybe($0[0] ?? true) }
    }
}
