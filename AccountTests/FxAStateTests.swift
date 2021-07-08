/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import FxA
import Shared
import SwiftyJSON

import XCTest

let keyLength = UInt(KeyLength)

class FxAStateTests: XCTestCase {
    class func stateForLabel(_ label: FxAStateLabel) -> FxAState {
        let kXCS = "6ae94683571c7a7c54dab4700aa3995f"
        let now = Date.now()

        switch label {
        case .engagedBeforeVerified:
            return EngagedBeforeVerifiedState(
                knownUnverifiedAt: now + 1, lastNotifiedUserAt: now + 2,
                sessionToken: Data.randomOfLength(keyLength)!,
                keyFetchToken: Data.randomOfLength(keyLength)!,
                unwrapkB: Data.randomOfLength(keyLength)!)

        case .engagedAfterVerified:
            return EngagedAfterVerifiedState(
                sessionToken: Data.randomOfLength(keyLength)!,
                keyFetchToken: Data.randomOfLength(keyLength)!,
                unwrapkB: Data.randomOfLength(keyLength)!)

        case .cohabitingBeforeKeyPair:
            return CohabitingBeforeKeyPairState(sessionToken: Data.randomOfLength(keyLength)!,
                kSync: Data.randomOfLength(keyLength)!, kXCS: kXCS)

        case .cohabitingAfterKeyPair:
            let keyPair = RSAKeyPair.generate(withModulusSize: 512)!
            return CohabitingAfterKeyPairState(sessionToken: Data.randomOfLength(keyLength)!,
                kSync: Data.randomOfLength(keyLength)!, kXCS: kXCS,
                keyPair: keyPair, keyPairExpiresAt: now + 1)

        case .married:
            let keyPair = RSAKeyPair.generate(withModulusSize: 512)!
            return MarriedState(sessionToken: Data.randomOfLength(keyLength)!,
                kSync: Data.randomOfLength(keyLength)!, kXCS: kXCS,
                keyPair: keyPair, keyPairExpiresAt: now + 1,
                certificate: "certificate", certificateExpiresAt: now + 2)

        case .separated:
            return SeparatedState()

        case .doghouse:
            return DoghouseState()
        }
    }

    func testSerialization() {
        // Journal of Negative Results: make sure we aren't *always* succeeding.
        // This Married state will have an earlier timestamp than the one generated after the loop.
        let state1 = FxAStateTests.stateForLabel(.married) as! MarriedState

        for stateLabel in FxAStateLabel.allValues {
            let stateFromLabel = FxAStateTests.stateForLabel(stateLabel)
            let d = stateFromLabel.asJSON()
            if let e = state(fromJSON:d)?.asJSON() {
                // We can't compare arbitrary Swift Dictionary instances directly, but the following appears to work.
                XCTAssertEqual(
                    NSDictionary(dictionary: d.dictionaryObject!),
                    NSDictionary(dictionary: e.dictionaryObject!))
            } else {
                XCTFail("Expected to create state.")
            }
        }

        // This Married state will have a later timestamp than the one generated before the loop.
        let state2 = FxAStateTests.stateForLabel(.married) as! MarriedState
        // We can't compare arbitrary Swift Dictionary instances directly, but the following appears to work.
        XCTAssertNotEqual(
            NSDictionary(dictionary: state1.asJSON().dictionaryObject!),
            NSDictionary(dictionary: state2.asJSON().dictionaryObject!))
    }

    func testMigrationV1V2() {
        let marriedState = FxAStateTests.stateForLabel(.married) as! MarriedState

        // Modify the JSON to make it look like a v1 persisted state.
        var dict = marriedState.asJSON().dictionary!
        dict["version"] = 1
        dict.removeValue(forKey: "kXCS")
        dict.removeValue(forKey: "kSync")
        let kA = Data.randomOfLength(keyLength)!
        let kB = Data.randomOfLength(keyLength)!
        dict["kA"] = JSON(kA.hexEncodedString)
        dict["kB"] = JSON(kB.hexEncodedString)
        let stateV1 = JSON(dict)

        let loadedState = state(fromJSON: stateV1)!
        let newJSON = loadedState.asJSON()
        XCTAssertNotNil(newJSON["kSync"])
        XCTAssertNotNil(newJSON["kXCS"])
    }
}
