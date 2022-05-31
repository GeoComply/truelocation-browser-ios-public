// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Account
import Storage
@testable import Sync
import UIKit

import XCTest

class MockSyncServerTests: XCTestCase {
    var server: MockSyncServer!
    var client: Sync15StorageClient!

    override func setUp() {
        server = MockSyncServer(username: "1234567")
        server.start()
        client = getClient(server: server)
    }

    private func getClient(server: MockSyncServer) -> Sync15StorageClient? {
        guard let url = server.baseURL.asURL else {
            XCTFail("Couldn't get URL.")
            return nil
        }

        let authorizer: Authorizer = identity
        let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
        return Sync15StorageClient(serverURI: url, authorizer: authorizer, workQueue: queue, resultQueue: queue, backoff: MockBackoffStorage())
    }

    func testDeleteSpec() {
        // Deletion of a collection path itself, versus trailing slash, sets the right flags.
        let all = SyncDeleteRequestSpec.fromPath(path: "/1.5/123456/storage/bookmarks", withQuery: [:])!
        XCTAssertTrue(all.wholeCollection)
        XCTAssertNil(all.ids)

        let some = SyncDeleteRequestSpec.fromPath(path: "/1.5/123456/storage/bookmarks", withQuery: ["ids": "123456,abcdef" as AnyObject])!
        XCTAssertFalse(some.wholeCollection)
        XCTAssertEqual(["123456", "abcdef"], some.ids!)

        let one = SyncDeleteRequestSpec.fromPath(path: "/1.5/123456/storage/bookmarks/123456", withQuery: [:])!
        XCTAssertFalse(one.wholeCollection)
        XCTAssertNil(one.ids)
    }

    func testInfoCollections() {
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: Bytes.generateGUID(), modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        server.storeRecords(records: [], inCollection: "tabs", now: 1326252222500)
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: Bytes.generateGUID(), modified: 0)], inCollection: "bookmarks", now: 1326252222000)
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: Bytes.generateGUID(), modified: 0)], inCollection: "clients", now: 1326253333000)

        let expectation = self.expectation(description: "Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!
        client.getInfoCollections().upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!

            // JSON contents.
            XCTAssertEqual(response.value.collectionNames().sorted(), ["bookmarks", "clients", "tabs"])
            XCTAssertEqual(response.value.modified("bookmarks"), 1326252222000)
            XCTAssertEqual(response.value.modified("clients"), 1326253333000)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertEqual(response.metadata.records, 3) // bookmarks, clients, tabs.

            // X-Last-Modified, max of all collection modified timestamps.
            XCTAssertEqual(response.metadata.lastModifiedMilliseconds, 1326253333000)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGet() {
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: "guid", modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        let collectionClient = client.clientForCollection("bookmarks", encrypter: getEncrypter())

        let expectation = self.expectation(description: "Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!
        collectionClient.get("guid").upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!

            // JSON contents.
            XCTAssertEqual(response.value.id, "guid")
            XCTAssertEqual(response.value.modified, 1326251111000)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertEqual(response.metadata.lastModifiedMilliseconds, 1326251111000)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        // And now a missing record, which should produce a 404.
        collectionClient.get("missing").upon { result in
            XCTAssertNotNil(result.failureValue)
            guard let response = result.failureValue else {
                expectation.fulfill()
                return
            }
            XCTAssertNotNil(response as? NotFound<HTTPURLResponse>)
        }
    }

    func testWipeStorage() {
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: "a", modified: 0)], inCollection: "bookmarks", now: 1326251111000)
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: "b", modified: 0)], inCollection: "bookmarks", now: 1326252222000)
        server.storeRecords(records: [MockSyncServer.makeValidEnvelope(guid: "c", modified: 0)], inCollection: "clients", now: 1326253333000)
        server.storeRecords(records: [], inCollection: "tabs")

        // For now, only testing wiping the storage root, which is the only thing we use in practice.
        let expectation = self.expectation(description: "Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!
        client.wipeStorage().upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!

            // JSON contents: should be the empty object.
            let jsonData = try! response.value.rawData()
            let jsonString = String(data: jsonData, encoding: .utf8)!
            XCTAssertEqual(jsonString, "{}")

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertNil(response.metadata.lastModifiedMilliseconds)

            // And we really wiped the data.
            XCTAssertTrue(self.server.collections.isEmpty)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testPut() {
        // For now, only test uploading crypto/keys.  There's nothing special about this PUT, however.
        let expectation = self.expectation(description: "Waiting for result.")
        let before = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!
        client.uploadCryptoKeys(Keys.random(), withSyncKeyBundle: KeyBundle.random(), ifUnmodifiedSince: nil).upon { result in
            XCTAssertNotNil(result.successValue)
            guard let response = result.successValue else {
                expectation.fulfill()
                return
            }
            let after = decimalSecondsStringToTimestamp(millisecondsToDecimalSeconds(Date.now()))!

            // Contents: should be just the record timestamp.
            XCTAssertLessThanOrEqual(before, response.value)
            XCTAssertLessThanOrEqual(response.value, after)

            // X-Weave-Timestamp.
            XCTAssertLessThanOrEqual(before, response.metadata.timestampMilliseconds)
            XCTAssertLessThanOrEqual(response.metadata.timestampMilliseconds, after)
            // X-Weave-Records.
            XCTAssertNil(response.metadata.records)
            // X-Last-Modified.
            XCTAssertNil(response.metadata.lastModifiedMilliseconds)

            // And we really uploaded the record.
            XCTAssertNotNil(self.server.collections["crypto"])
            XCTAssertNotNil(self.server.collections["crypto"]?.records["keys"])

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
