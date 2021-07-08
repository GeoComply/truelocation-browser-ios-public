/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import XCGLogger
import SwiftyJSON

private let log = Logger.syncLogger

// Not an error that indicates a server problem, but merely an
// error that encloses a StorageResponse.
open class StorageResponseError<T>: MaybeErrorType, SyncPingFailureFormattable {
    public let response: StorageResponse<T>

    open var failureReasonName: SyncPingFailureReasonName {
        return .httpError
    }

    public init(_ response: StorageResponse<T>) {
        self.response = response
    }

    open var description: String {
        return "Error."
    }
}

open class RequestError: MaybeErrorType, SyncPingFailureFormattable {
    open var failureReasonName: SyncPingFailureReasonName {
        return .httpError
    }

    open var description: String {
        return "Request error."
    }
}

open class BadRequestError<T>: StorageResponseError<T> {
    public let request: URLRequest?

    public init(request: URLRequest?, response: StorageResponse<T>) {
        self.request = request
        super.init(response)
    }

    override open var description: String {
        return "Bad request."
    }
}

open class ServerError<T>: StorageResponseError<T> {
    override open var description: String {
        return "Server error."
    }

    override public init(_ response: StorageResponse<T>) {
        super.init(response)
    }
}

open class NotFound<T>: StorageResponseError<T> {
    override open var description: String {
        return "Not found. (\(T.self))"
    }

    override public init(_ response: StorageResponse<T>) {
        super.init(response)
    }
}

open class RecordParseError: MaybeErrorType, SyncPingFailureFormattable {
    open var description: String {
        return "Failed to parse record."
    }

    open var failureReasonName: SyncPingFailureReasonName {
        return .otherError
    }
}

open class MalformedMetaGlobalError: MaybeErrorType, SyncPingFailureFormattable {
    open var description: String {
        return "Supplied meta/global for upload did not serialize to valid JSON."
    }

    open var failureReasonName: SyncPingFailureReasonName {
        return .otherError
    }
}

open class RecordTooLargeError: MaybeErrorType, SyncPingFailureFormattable {
    public let guid: GUID
    public let size: ByteCount

    open var failureReasonName: SyncPingFailureReasonName {
        return .otherError
    }

    public init(size: ByteCount, guid: GUID) {
        self.size = size
        self.guid = guid
    }

    open var description: String {
        return "Record \(self.guid) too large: \(size) bytes."
    }
}

/**
 * Raised when the storage client is refusing to make a request due to a known
 * server backoff.
 * If you want to bypass this, remove the backoff from the BackoffStorage that
 * the storage client is using.
 */
open class ServerInBackoffError: MaybeErrorType, SyncPingFailureFormattable {
    fileprivate let until: Timestamp

    open var failureReasonName: SyncPingFailureReasonName {
        return .otherError
    }

    open var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        let s = formatter.string(from: Date.fromTimestamp(self.until))
        return "Server in backoff until \(s)."
    }

    public init(until: Timestamp) {
        self.until = until
    }
}

// Returns milliseconds. Handles decimals.
private func optionalSecondsHeader(_ input: AnyObject?) -> Timestamp? {
    if input == nil {
        return nil
    }

    if let val = input as? String {
        if let timestamp = decimalSecondsStringToTimestamp(val) {
            return timestamp
        }
    }

    if let seconds: Double = input as? Double {
        // Oh for a BigDecimal library.
        return Timestamp(seconds * 1000)
    }

    if let seconds: NSNumber = input as? NSNumber {
        // Who knows.
        return seconds.uint64Value * 1000
    }

    return nil
}

private func optionalIntegerHeader(_ input: AnyObject?) -> Int64? {
    if input == nil {
        return nil
    }

    if let val = input as? String {
        return Scanner(string: val).scanLongLong()
    }

    if let val: Double = input as? Double {
        // Oh for a BigDecimal library.
        return Int64(val)
    }

    if let val: NSNumber = input as? NSNumber {
        // Who knows.
        return val.int64Value
    }

    return nil
}

private func optionalUIntegerHeader(_ input: AnyObject?) -> Timestamp? {
    if input == nil {
        return nil
    }

    if let val = input as? String {
        return Scanner(string: val).scanUnsignedLongLong()
    }

    if let val: Double = input as? Double {
        // Oh for a BigDecimal library.
        return Timestamp(val)
    }

    if let val: NSNumber = input as? NSNumber {
        // Who knows.
        return val.uint64Value
    }

    return nil
}

public enum SortOption: String {
    case NewestFirst = "newest"
    case OldestFirst = "oldest"
    case Index = "index"
}

public struct ResponseMetadata {
    public let status: Int
    public let alert: String?
    public let nextOffset: String?
    public let records: UInt64?
    public let quotaRemaining: Int64?
    public let timestampMilliseconds: Timestamp         // Non-optional. Server timestamp when handling request.
    public let lastModifiedMilliseconds: Timestamp?     // Included for all success responses. Collection or record timestamp.
    public let backoffMilliseconds: UInt64?
    public let retryAfterMilliseconds: UInt64?

    public init(response: HTTPURLResponse) {
        self.init(status: response.statusCode, headers: response.allHeaderFields)
    }

    init(status: Int, headers: [AnyHashable: Any]) {
        // Work around bug https://bugs.swift.org/browse/SR-2429
        // response.allHeaderFields is case sensitive in versions newer than swift 2.
        // This is a 3 year old bug that has not been fixed.
        // Lowercase all of the header keys so we can index the headers map without
        // worrying about case.
        let headers = Dictionary(uniqueKeysWithValues: headers.map {
            (String(describing: $0.key).lowercased(), String(describing: $0.value))
        })

        self.status = status
        alert = headers["x-weave-alert"]
        nextOffset = headers["x-weave-next-offset"]
        records = optionalUIntegerHeader(headers["x-weave-records"] as AnyObject?)
        quotaRemaining = optionalIntegerHeader(headers["x-weave-quota-remaining"] as AnyObject?)
        timestampMilliseconds = optionalSecondsHeader(headers["x-weave-timestamp"] as AnyObject?) ?? 0
        lastModifiedMilliseconds = optionalSecondsHeader(headers["x-last-modified"] as AnyObject?)
        backoffMilliseconds = optionalSecondsHeader(headers["x-weave-backoff"] as AnyObject?) ??
                              optionalSecondsHeader(headers["x-backoff"] as AnyObject?)
        retryAfterMilliseconds = optionalSecondsHeader(headers["retry-after"] as AnyObject?)
    }
}

public struct StorageResponse<T> {
    public let value: T
    public let metadata: ResponseMetadata

    init(value: T, metadata: ResponseMetadata) {
        self.value = value
        self.metadata = metadata
    }

    init(value: T, response: HTTPURLResponse) {
        self.value = value
        self.metadata = ResponseMetadata(response: response)
    }
}

public typealias BatchToken = String

public typealias ByteCount = Int

public struct POSTResult {
    public let success: [GUID]
    public let failed: [GUID: String]
    public let batchToken: BatchToken?

    public init(success: [GUID], failed: [GUID: String], batchToken: BatchToken? = nil) {
        self.success = success
        self.failed = failed
        self.batchToken = batchToken
    }

    public static func fromJSON(_ json: JSON) -> POSTResult? {
        if json.isError() {
            return nil
        }

        let batchToken = json["batch"].string

        if let s = json["success"].array,
           let f = json["failed"].dictionary {
            var failed = false
            let stringOrFail: (JSON) -> String = { $0.string ?? { failed = true; return "" }() }

            // That's the basic structure. Now let's transform the contents.
            let successGUIDs = s.map(stringOrFail)
            if failed {
                return nil
            }
            let failedGUIDs = mapValues(f, f: stringOrFail)
            if failed {
                return nil
            }
            return POSTResult(success: successGUIDs, failed: failedGUIDs, batchToken: batchToken)
        }
        return nil
    }
}

public typealias Authorizer = (URLRequest) -> URLRequest

// TODO: don't be so naïve. Use a combination of uptime and wall clock time.
public protocol BackoffStorage {
    var serverBackoffUntilLocalTimestamp: Timestamp? { get set }
    func clearServerBackoff()
    func isInBackoff(_ now: Timestamp) -> Timestamp?   // Returns 'until' for convenience.
}

// Don't forget to batch downloads.
open class Sync15StorageClient {
    fileprivate let authorizer: Authorizer
    fileprivate let serverURI: URL

    public static let maxRecordSizeBytes: Int = 262_140       // A shade under 256KB.
    public static let maxPayloadSizeBytes: Int = 1_000_000    // A shade under 1MB.
    public static let maxPayloadItemCount: Int = 100          // Bug 1250747 will raise this.

    var backoff: BackoffStorage

    let workQueue: DispatchQueue
    let resultQueue: DispatchQueue

    public init(token: TokenServerToken, workQueue: DispatchQueue, resultQueue: DispatchQueue, backoff: BackoffStorage) {
        self.workQueue = workQueue
        self.resultQueue = resultQueue
        self.backoff = backoff

        // This is a potentially dangerous assumption, but failable initializers up the stack are a giant pain.
        // We want the serverURI to *not* have a trailing slash: to efficiently wipe a user's storage, we delete
        // the user root (like /1.5/1234567) and not an "empty collection" (like /1.5/1234567/); the storage
        // server treats the first like a DROP table and the latter like a DELETE *, and the former is more
        // efficient than the latter.

        self.serverURI = URL(string: token.api_endpoint.hasSuffix("/")
            ? String(token.api_endpoint[..<token.api_endpoint.index(before: token.api_endpoint.endIndex)])
            : token.api_endpoint)!
        self.authorizer = {
            (r: URLRequest) -> URLRequest in
            var req = r
            let helper = HawkHelper(id: token.id, key: token.key.data(using: .utf8, allowLossyConversion: false)!)
            req.setValue(helper.getAuthorizationValueFor(r), forHTTPHeaderField: "Authorization")
            return req
        }
    }

    public init(serverURI: URL, authorizer: @escaping Authorizer, workQueue: DispatchQueue, resultQueue: DispatchQueue, backoff: BackoffStorage) {
        self.serverURI = serverURI
        self.authorizer = authorizer
        self.workQueue = workQueue
        self.resultQueue = resultQueue
        self.backoff = backoff
    }

    func updateBackoffFromResponse<T>(_ response: StorageResponse<T>) {
        // N.B., we would not have made this request if a backoff were set, so
        // we can safely avoid doing the write if there's no backoff in the
        // response.
        // This logic will have to change if we ever invalidate that assumption.
        if let ms = response.metadata.backoffMilliseconds ?? response.metadata.retryAfterMilliseconds {
            log.info("Backing off for \(ms)ms.")
            self.backoff.serverBackoffUntilLocalTimestamp = ms + Date.now()
        }
    }

    func getFailureInfo(_ response: URLResponse?, _ error: Error?) -> MaybeErrorType? {
        func failFromResponse(_ httpResponse: HTTPURLResponse?) -> MaybeErrorType? {
            guard let httpResponse = httpResponse else {
                // TODO: better error.
                log.error("No response")
                return RecordParseError()
            }

            log.debug("Status code: \(httpResponse.statusCode).")
            let storageResponse = StorageResponse(value: httpResponse, metadata: ResponseMetadata(response: httpResponse))
            self.updateBackoffFromResponse(storageResponse)

            if httpResponse.statusCode >= 500 {
                log.debug("ServerError.")
                return ServerError(storageResponse)
            }

            if httpResponse.statusCode == 404 {
                log.debug("NotFound")
                return NotFound(storageResponse)
            }

            if httpResponse.statusCode >= 400 {
                log.debug("BadRequestError.")
                let req = URLRequest(url: httpResponse.url!)
                return BadRequestError(request: req, response: storageResponse)
            }

            return nil
        }

        let httpResponse = response as? HTTPURLResponse
        if error != nil {
            log.error("Response: \(httpResponse?.statusCode ?? 0). Got error \(error ??? "nil").")

            // If we got one, we don't want to hit the response nil case above and
            // return a RecordParseError, because a RequestError is more fittinghttpResponse
            if let httpResponse = httpResponse, let result = failFromResponse(httpResponse) {
                log.error("This was a failure response. Filled specific error type.")
                return result
            }

            log.error("Filling generic RequestError.")
            return RequestError()
        }

        if let result = failFromResponse(httpResponse) {
            return result
        }

        return nil
    }

    lazy fileprivate var urlSession: URLSession = makeURLSession(userAgent: UserAgent.syncUserAgent, configuration: URLSessionConfiguration.ephemeral)

    typealias URLSessionCompletion = (Data?, URLResponse?, Error?) -> Void

    func requestGET(_ url: URL, completion: @escaping URLSessionCompletion) {
        var req = URLRequest(url: url as URL)
        req.httpMethod = URLRequest.Method.get.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let authorized: URLRequest = self.authorizer(req)
        urlSession.dataTask(with: authorized) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    func requestDELETE(_ url: URL, completion: @escaping URLSessionCompletion) {
        var req = URLRequest(url: url as URL)
        req.httpMethod = URLRequest.Method.delete.rawValue
        req.setValue("1", forHTTPHeaderField: "X-Confirm-Delete")
        let authorized: URLRequest = self.authorizer(req)
        urlSession.dataTask(with: authorized) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    func requestWrite(_ url: URL, method: String, body: String, contentType: String, ifUnmodifiedSince: Timestamp?, completion: @escaping URLSessionCompletion) {
        var req = URLRequest(url: url as URL)
        req.httpMethod = method
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")

        if let ifUnmodifiedSince = ifUnmodifiedSince {
            req.setValue(millisecondsToDecimalSeconds(ifUnmodifiedSince), forHTTPHeaderField: "X-If-Unmodified-Since")
        }

        req.httpBody = body.data(using: .utf8)!
        let authorized: URLRequest = self.authorizer(req)
        urlSession.dataTask(with: authorized) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    func requestPUT(_ url: URL, body: JSON, ifUnmodifiedSince: Timestamp?, completion: @escaping URLSessionCompletion) {
        requestWrite(url, method: URLRequest.Method.put.rawValue, body: body.stringify()!, contentType: "application/json;charset=utf-8", ifUnmodifiedSince: ifUnmodifiedSince, completion: completion)
    }

    func requestPOST(_ url: URL, body: JSON, ifUnmodifiedSince: Timestamp?, completion: @escaping URLSessionCompletion) {
        requestWrite(url, method: URLRequest.Method.post.rawValue, body: body.stringify()!, contentType: "application/json;charset=utf-8", ifUnmodifiedSince: ifUnmodifiedSince, completion: completion)
    }

    func requestPOST(_ url: URL, body: [String], ifUnmodifiedSince: Timestamp?, completion: @escaping URLSessionCompletion) {
        let content = body.joined(separator: "\n")
        requestWrite(url, method: URLRequest.Method.post.rawValue, body: content, contentType: "application/newlines", ifUnmodifiedSince: ifUnmodifiedSince, completion: completion)
    }

    func requestPOST(_ url: URL, body: [JSON], ifUnmodifiedSince: Timestamp?, completion: @escaping URLSessionCompletion) {
        requestPOST(url, body: body.map { $0.stringify()! }, ifUnmodifiedSince: ifUnmodifiedSince, completion: completion)
    }

    /**
     * Returns true and fills the provided Deferred if our state shows that we're in backoff.
     * Returns false otherwise.
     */
    fileprivate func checkBackoff<T>(_ deferred: Deferred<Maybe<T>>) -> Bool {
        if let until = self.backoff.isInBackoff(Date.now()) {
            deferred.fill(Maybe<T>(failure: ServerInBackoffError(until: until)))
            return true
        }
        return false
    }

    fileprivate func doOp<T>(_ op: (URL, @escaping URLSessionCompletion) -> Void, path: String, f: @escaping (JSON) -> T?) -> Deferred<Maybe<StorageResponse<T>>> {

        let deferred = Deferred<Maybe<StorageResponse<T>>>(defaultQueue: self.resultQueue)

        if self.checkBackoff(deferred) {
            return deferred
        }

        // Special case "": we want /1.5/1234567 and not /1.5/1234567/.  See note about trailing slashes above.
        let url: URL
        if path == "" {
            url = self.serverURI // No trailing slash.
        } else {
            url = self.serverURI.appendingPathComponent(path)

        }

        op(url) { (data, response, error) in
            if let failure = self.getFailureInfo(response, error) {
                let result = Maybe<StorageResponse<T>>.failure(failure)
                deferred.fill(result)
                return
            }

            if let data = data {
                let json = JSON(data)
                if let v = f(json), let response = response as? HTTPURLResponse {
                    let storageResponse = StorageResponse<T>(value: v, response: response)
                    deferred.fill(Maybe(success: storageResponse))
                } else {
                    deferred.fill(Maybe(failure: RecordParseError()))
                }
                return
            }

            deferred.fill(Maybe(failure: RecordParseError()))
        }

        return deferred
    }

    // Sync storage responds with a plain timestamp to a PUT, not with a JSON body.
    fileprivate func putResource<T>(_ path: String, body: JSON, ifUnmodifiedSince: Timestamp?, parser: @escaping (String) -> T?) -> Deferred<Maybe<StorageResponse<T>>> {
        let url = self.serverURI.appendingPathComponent(path)
        return self.putResource(url, body: body, ifUnmodifiedSince: ifUnmodifiedSince, parser: parser)
    }

    fileprivate func putResource<T>(_ URL: Foundation.URL, body: JSON, ifUnmodifiedSince: Timestamp?, parser: @escaping (String) -> T?) -> Deferred<Maybe<StorageResponse<T>>> {

        let deferred = Deferred<Maybe<StorageResponse<T>>>(defaultQueue: self.resultQueue)
        if self.checkBackoff(deferred) {
            return deferred
        }

        requestPUT(URL, body: body, ifUnmodifiedSince: ifUnmodifiedSince) { (data, response, error) in
            if let failure = self.getFailureInfo(response, error) {
                let result = Maybe<StorageResponse<T>>.failure(failure)
                deferred.fill(result)
                return
            }

            if let data = data, let response = response as? HTTPURLResponse, let str = String(data: data, encoding: .utf8) {
                if let v = parser(str) {
                    let storageResponse = StorageResponse<T>(value: v, response: response)
                    deferred.fill(Maybe(success: storageResponse))
                } else {
                    deferred.fill(Maybe(failure: RecordParseError()))
                }
                return
            }
            deferred.fill(Maybe(failure: RecordParseError()))
        }

        return deferred
    }

    fileprivate func getResource<T>(_ path: String, f: @escaping (JSON) -> T?) -> Deferred<Maybe<StorageResponse<T>>> {
        return doOp(self.requestGET, path: path, f: f)
    }

    fileprivate func deleteResource<T>(_ path: String, f: @escaping (JSON) -> T?) -> Deferred<Maybe<StorageResponse<T>>> {
        return doOp(self.requestDELETE, path: path, f: f)
    }

    func wipeStorage() -> Deferred<Maybe<StorageResponse<JSON>>> {
        // In Sync 1.5 it's preferred that we delete the root, not /storage.
        return deleteResource("", f: { $0 })
    }

    func getInfoCollections() -> Deferred<Maybe<StorageResponse<InfoCollections>>> {
        return getResource("info/collections", f: InfoCollections.fromJSON)
    }

    func getMetaGlobal() -> Deferred<Maybe<StorageResponse<MetaGlobal>>> {
        return getResource("storage/meta/global") { json in
            // We have an envelope.  Parse the meta/global record embedded in the 'payload' string.
            let envelope = EnvelopeJSON(json)
            if envelope.isValid() {
                return MetaGlobal.fromJSON(JSON(parseJSON: envelope.payload))
            }
            return nil
        }
    }

    func getCryptoKeys(_ syncKeyBundle: KeyBundle, ifUnmodifiedSince: Timestamp?) -> Deferred<Maybe<StorageResponse<Record<KeysPayload>>>> {
        let syncKey = Keys(defaultBundle: syncKeyBundle)
        let encoder = RecordEncoder<KeysPayload>(decode: { KeysPayload($0) }, encode: { $0.json })
        let encrypter = syncKey.encrypter("keys", encoder: encoder)
        let client = self.clientForCollection("crypto", encrypter: encrypter)
        return client.get("keys")
    }

    func uploadMetaGlobal(_ metaGlobal: MetaGlobal, ifUnmodifiedSince: Timestamp?) -> Deferred<Maybe<StorageResponse<Timestamp>>> {
        let payload = metaGlobal.asPayload()
        if payload.json.isError() {
            return Deferred(value: Maybe(failure: MalformedMetaGlobalError()))
        }

        let record = JSON(["payload": payload.json.stringify() ?? JSON.null as Any, "id": "global"])
        return putResource("storage/meta/global", body: record, ifUnmodifiedSince: ifUnmodifiedSince, parser: decimalSecondsStringToTimestamp)
    }

    // The crypto/keys record is a special snowflake: it is encrypted with the Sync key bundle.  All other records are
    // encrypted with the bulk key bundle (including possibly a per-collection bulk key) stored in crypto/keys.
    func uploadCryptoKeys(_ keys: Keys, withSyncKeyBundle syncKeyBundle: KeyBundle, ifUnmodifiedSince: Timestamp?) -> Deferred<Maybe<StorageResponse<Timestamp>>> {
        let syncKey = Keys(defaultBundle: syncKeyBundle)
        let encoder = RecordEncoder<KeysPayload>(decode: { KeysPayload($0) }, encode: { $0.json })
        let encrypter = syncKey.encrypter("keys", encoder: encoder)
        let client = self.clientForCollection("crypto", encrypter: encrypter)

        let record = Record(id: "keys", payload: keys.asPayload())
        return client.put(record, ifUnmodifiedSince: ifUnmodifiedSince)
    }

    // It would be convenient to have the storage client manage Keys, but of course we need to use a different set of
    // keys to fetch crypto/keys itself.  See uploadCryptoKeys.
    func clientForCollection<T>(_ collection: String, encrypter: RecordEncrypter<T>) -> Sync15CollectionClient<T> {
        let storage = self.serverURI.appendingPathComponent("storage", isDirectory: true)
        return Sync15CollectionClient(client: self, serverURI: storage, collection: collection, encrypter: encrypter)
    }
}

private let DefaultInfoConfiguration = InfoConfiguration(maxRequestBytes: 1_048_576,
                                                         maxPostRecords: 100,
                                                         maxPostBytes: 1_048_576,
                                                         maxTotalRecords: 1666,
                                                         maxTotalBytes: 104_857_600)

/**
 * We'd love to nest this in the overall storage client, but Swift
 * forbids the nesting of a generic class inside another class.
 */
open class Sync15CollectionClient<T: CleartextPayloadJSON> {
    fileprivate let client: Sync15StorageClient
    fileprivate let encrypter: RecordEncrypter<T>
    fileprivate let collectionURI: URL
    fileprivate let collectionQueue = DispatchQueue(label: "com.mozilla.sync.collectionclient", attributes: [])
    fileprivate let infoConfig = DefaultInfoConfiguration

    public init(client: Sync15StorageClient, serverURI: URL, collection: String, encrypter: RecordEncrypter<T>) {
        self.client = client
        self.encrypter = encrypter
        self.collectionURI = serverURI.appendingPathComponent(collection, isDirectory: false)
    }

    var maxBatchPostRecords: Int {
        get {
            return infoConfig.maxPostRecords
        }
    }

    fileprivate func uriForRecord(_ guid: String) -> URL {
        return self.collectionURI.appendingPathComponent(guid)
    }

    open func newBatch(ifUnmodifiedSince: Timestamp? = nil, onCollectionUploaded: @escaping (POSTResult, Timestamp?) -> DeferredTimestamp) -> Sync15BatchClient<T> {
        return Sync15BatchClient(config: infoConfig,
                                 ifUnmodifiedSince: ifUnmodifiedSince,
                                 serializeRecord: self.serializeRecord,
                                 uploader: self.post,
                                 onCollectionUploaded: onCollectionUploaded)
    }

    // Exposed so we can batch by size.
    open func serializeRecord(_ record: Record<T>) -> String? {
        return self.encrypter.serializer(record)?.stringify()
    }

    open func post(_ lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [URLQueryItem]? = nil) -> Deferred<Maybe<StorageResponse<POSTResult>>> {
        let deferred = Deferred<Maybe<StorageResponse<POSTResult>>>(defaultQueue: client.resultQueue)

        if self.client.checkBackoff(deferred) {
            return deferred
        }

        let requestURI: URL
        if let queryParams = queryParams {
            requestURI = self.collectionURI.withQueryParams(queryParams)
        } else {
            requestURI = self.collectionURI
        }

        client.requestPOST(requestURI, body: lines, ifUnmodifiedSince: ifUnmodifiedSince) { (data, response, error) in
            do {
                let json = try jsonResponse(fromData: data)
                if let result = POSTResult.fromJSON(json), let response = response as? HTTPURLResponse {
                    let storageResponse = StorageResponse(value: result, response: response)
                    deferred.fill(Maybe(success: storageResponse))
                    return
                } else {
                    log.warning("Couldn't parse JSON response.")
                }
            } catch {
                log.warning("Couldn't parse JSON response. \(error)")
            }

            deferred.fill(Maybe(failure: RecordParseError()))
        }

        return deferred
    }

    open func post(_ records: [Record<T>], ifUnmodifiedSince: Timestamp?, queryParams: [URLQueryItem]? = nil) -> Deferred<Maybe<StorageResponse<POSTResult>>> {
        // TODO: charset
        // TODO: if any of these fail, we should do _something_. Right now we just ignore them.
        let lines = optFilter(records.map(self.serializeRecord))
        return self.post(lines, ifUnmodifiedSince: ifUnmodifiedSince, queryParams: queryParams)
    }

    open func put(_ record: Record<T>, ifUnmodifiedSince: Timestamp?) -> Deferred<Maybe<StorageResponse<Timestamp>>> {
        if let body = self.encrypter.serializer(record) {
            return self.client.putResource(uriForRecord(record.id), body: body, ifUnmodifiedSince: ifUnmodifiedSince, parser: decimalSecondsStringToTimestamp)
        }
        return deferMaybe(RecordParseError())
    }

    open func get(_ guid: String) -> Deferred<Maybe<StorageResponse<Record<T>>>> {
        let deferred = Deferred<Maybe<StorageResponse<Record<T>>>>(defaultQueue: client.resultQueue)

        if self.client.checkBackoff(deferred) {
            return deferred
        }

        client.requestGET(uriForRecord(guid)) { (data, response, error) in
            if let failure = self.client.getFailureInfo(response, error) {
                let result = Maybe<StorageResponse<Record<T>>>.failure(failure)
                deferred.fill(result)
                return
            }

            do {
                let json = try jsonResponse(fromData: data)
                let envelope = EnvelopeJSON(json)
                let record = Record<T>.fromEnvelope(envelope, payloadFactory: self.encrypter.factory)
                if let record = record, let response = response as? HTTPURLResponse {
                    let storageResponse = StorageResponse(value: record, response: response)
                    deferred.fill(Maybe(success: storageResponse))
                    return
                } else {
                    log.warning("Couldn't parse JSON response.")
                }
            } catch {
                log.warning("Couldn't parse JSON response. \(error)")

            }

            deferred.fill(Maybe(failure: RecordParseError()))
        }
        
        return deferred
    }

    /**
     * Unlike every other Sync client, we use the application/json format for fetching
     * multiple requests. The others use application/newlines. We don't want to write
     * another Serializer, and we're loading everything into memory anyway.
     *
     * It is the caller's responsibility to check whether the returned payloads are invalid.
     *
     * Only non-JSON and malformed envelopes will be dropped.
     */
    open func getSince(_ since: Timestamp, sort: SortOption?=nil, limit: Int?=nil, offset: String?=nil) -> Deferred<Maybe<StorageResponse<[Record<T>]>>> {
        let deferred = Deferred<Maybe<StorageResponse<[Record<T>]>>>(defaultQueue: client.resultQueue)

        // Fills the Deferred for us.
        if self.client.checkBackoff(deferred) {
            return deferred
        }

        var params: [URLQueryItem] = [
            URLQueryItem(name: "full", value: "1"),
            URLQueryItem(name: "newer", value: millisecondsToDecimalSeconds(since)),
        ]

        if let offset = offset {
            params.append(URLQueryItem(name: "offset", value: offset))
        }

        if let limit = limit {
            params.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }

        if let sort = sort {
            params.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }

        log.debug("Issuing GET with newer = \(since), offset = \(offset ??? "nil"), sort = \(sort ??? "nil").")
        client.requestGET(self.collectionURI.withQueryParams(params)) { (data, response, error) in
            if let failure = self.client.getFailureInfo(response, error) {
                let result = Maybe<StorageResponse<[Record<T>]>>.failure(failure)
                deferred.fill(result)
                return
            }

            do {
                log.verbose("Response is \(response?.debugDescription ?? "").")
                let json = try jsonResponse(fromData: data)
                guard let arr = json.array, let httpResponse = response as? HTTPURLResponse else {
                    log.warning("Non-array response.")
                    deferred.fill(Maybe(failure: RecordParseError()))
                    return
                }

                func recordify(_ json: JSON) -> Record<T>? {
                    let envelope = EnvelopeJSON(json)
                    return Record<T>.fromEnvelope(envelope, payloadFactory: self.encrypter.factory)
                }

                let records = arr.compactMap(recordify)
                let response = StorageResponse(value: records, response: httpResponse)
                deferred.fill(Maybe(success: response))
                return
            } catch {
                log.warning("Couldn't parse JSON response. \(error)")
            }

            deferred.fill(Maybe(failure: RecordParseError()))
        }

        return deferred
    }
}
