/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

class Uploader {
    /**
     * Upload just about anything that can be turned into something we can upload.
     */
    func sequentialPosts<T>(_ items: [T], by: Int, lastTimestamp: Timestamp, storageOp: @escaping ([T], Timestamp) -> DeferredTimestamp) -> DeferredTimestamp {

        // This needs to be a real Array, not an ArraySlice,
        // for the types to line up.
        let chunks = chunk(items, by: by).map { Array($0) }

        let start = deferMaybe(lastTimestamp)

        let perChunk: ([T], Timestamp) -> DeferredTimestamp = { (records, timestamp) in
            // TODO: detect interruptions -- clients uploading records during our sync --
            // by using ifUnmodifiedSince. We can detect uploaded records since our download
            // (chain the download timestamp into this function), and we can detect uploads
            // that race with our own (chain download timestamps across 'walk' steps).
            // If we do that, we can also advance our last fetch timestamp after each chunk.
            log.debug("Uploading \(records.count) records.")
            return storageOp(records, timestamp)
        }

        return walk(chunks, start: start, f: perChunk)
    }
}

open class IndependentRecordSynchronizer: TimestampedSingleCollectionSynchronizer {
    private func reportApplyStatsWrap<T>(apply: @escaping (T) -> Success) -> (T) -> Success {
        return { record in
            return apply(record).bind({ result in
                var stats = SyncDownloadStats()
                stats.applied = 1
                if result.isSuccess {
                    stats.succeeded = 1
                } else {
                    stats.failed = 1
                }
                self.statsSession.recordDownload(stats: stats)
                return Deferred(value: result)
            })
        }
    }

    /**
     * Just like the usual applyIncomingToStorage, but doesn't fast-forward the timestamp.
     */
    func applyIncomingRecords<T>(_ records: [T], apply: @escaping (T) -> Success) -> Success {
        if records.isEmpty {
            log.debug("No records; done applying.")
            return succeed()
        }

        return walk(records, f: reportApplyStatsWrap(apply: apply))
    }

    func applyIncomingToStorage<T>(_ records: [T], fetched: Timestamp, apply: @escaping (T) -> Success) -> Success {
        func done() -> Success {
            log.debug("Bumping fetch timestamp to \(fetched).")
            self.lastFetched = fetched
            return succeed()
        }

        if records.isEmpty {
            log.debug("No records; done applying.")
            return done()
        }

        return walk(records, f: reportApplyStatsWrap(apply: apply)) >>> done
    }
}

extension TimestampedSingleCollectionSynchronizer {
    /**
     * On each chunk that we upload, we pass along the server modified timestamp to the next,
     * chained through the provided `onUpload` function.
     *
     * The last chunk passes this modified timestamp out, and we assign it to lastFetched.
     *
     * The idea of this is twofold:
     *
     * 1. It does the fast-forwarding that every other Sync client does.
     *
     * 2. It allows us to (eventually) pass the last collection modified time as If-Unmodified-Since
     *    on each upload batch, as we do between the download and the upload phase.
     *    This alone allows us to detect conflicts from racing clients.
     *
     * In order to implement the latter, we'd need to chain the date from getSince in place of the
     * 0 in the call to uploadOutgoingFromStorage in each synchronizer.
     */
    func uploadRecords<T>(_ records: [Record<T>], lastTimestamp: Timestamp, storageClient: Sync15CollectionClient<T>, onUpload: @escaping (POSTResult, Timestamp?) -> DeferredTimestamp) -> DeferredTimestamp {
        if records.isEmpty {
            log.debug("No modified records to upload.")
            return deferMaybe(lastTimestamp)
        }

        func reportUploadStatsWrap(result: POSTResult, timestamp: Timestamp?) -> DeferredTimestamp {
            let stats = SyncUploadStats(sent: result.success.count, sentFailed: result.failed.count)
            self.statsSession.recordUpload(stats: stats)
            return onUpload(result, timestamp)
        }

        let batch = storageClient.newBatch(ifUnmodifiedSince: (lastTimestamp == 0) ? nil : lastTimestamp, onCollectionUploaded: reportUploadStatsWrap)
        return batch.addRecords(records)
            >>> batch.endBatch
            >>> {
                let timestamp = batch.ifUnmodifiedSince ?? lastTimestamp
                self.setTimestamp(timestamp)
                return deferMaybe(timestamp)
            }
    }

    func uploadRecordsSingleBatch<T>(_ records: [Record<T>], lastTimestamp: Timestamp, storageClient: Sync15CollectionClient<T>) -> Deferred<Maybe<(timestamp: Timestamp, succeeded: [GUID])>> {
        if records.isEmpty {
            log.debug("No modified records to upload.")
            return deferMaybe((timestamp: lastTimestamp, succeeded: []))
        }

        func reportUploadStatsWrap(result: POSTResult, timestamp: Timestamp?) -> DeferredTimestamp {
            let stats = SyncUploadStats(sent: result.success.count, sentFailed: result.failed.count)
            self.statsSession.recordUpload(stats: stats)
            return deferMaybe(timestamp ?? lastTimestamp)
        }

        let batch = storageClient.newBatch(ifUnmodifiedSince: (lastTimestamp == 0) ? nil : lastTimestamp, onCollectionUploaded: reportUploadStatsWrap)
        return batch.addRecords(records, singleBatch: true)
            >>== batch.endSingleBatch
            >>== { (succeeded, lastModified) in
                guard let timestamp = lastModified else {
                    return deferMaybe(FatalError(message: "Could not retrieve lastModified from the server response."))
                }
                self.setTimestamp(timestamp)
                return deferMaybe((timestamp: timestamp, succeeded: succeeded))
        }
    }
}
