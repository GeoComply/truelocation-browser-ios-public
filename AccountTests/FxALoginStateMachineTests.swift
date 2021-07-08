/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import FxA
import Shared

import XCTest

class MockFxALoginClient: FxALoginClient {
    // Fixed per mock client, for testing.
    let kA = Data.randomOfLength(UInt(KeyLength))!
    let wrapkB = Data.randomOfLength(UInt(KeyLength))!

    func keyPair() -> Deferred<Maybe<KeyPair>> {
        let keyPair: KeyPair = RSAKeyPair.generate(withModulusSize: 512)
        return Deferred(value: Maybe(success: keyPair))
    }

    func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAKeysResponse(kA: kA, wrapkB: wrapkB)
        return Deferred(value: Maybe(success: response))
    }

    func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxASignResponse(certificate: "certificate")
        return Deferred(value: Maybe(success: response))
    }

    func scopedKeyData(_ sessionToken: NSData, scope: String) -> Deferred<Maybe<[FxAScopedKeyDataResponse]>> {
        let response = [FxAScopedKeyDataResponse(scope: scope, identifier: scope, keyRotationSecret: "0000000000000000000000000000000000000000000000000000000000000000", keyRotationTimestamp: 1510726317123)]
        return Deferred(value: Maybe(success: response))
    }
}

// A mock client that fails locally (i.e., cannot connect to the network).
class MockFxALoginClientWithoutNetwork: MockFxALoginClient {
    override func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>> {
        // Fail!
        return Deferred(value: Maybe(failure: FxAClientError.local(NSError(domain: NSURLErrorDomain, code: -1000, userInfo: nil))))
    }

    override func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        // Fail!
        return Deferred(value: Maybe(failure: FxAClientError.local(NSError(domain: NSURLErrorDomain, code: -1000, userInfo: nil))))
    }

    override func scopedKeyData(_ sessionToken: NSData, scope: String) -> Deferred<Maybe<[FxAScopedKeyDataResponse]>> {
        // Fail!
        return Deferred(value: Maybe(failure: FxAClientError.local(NSError(domain: NSURLErrorDomain, code: -1000, userInfo: nil))))
    }
}

// A mock client that responds to keys and sign with 401 errors.
class MockFxALoginClientAfterPasswordChange: MockFxALoginClient {
    override func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAClientError.remote(RemoteError(code: 401, errno: 103, error: "Bad auth", message: "Bad auth message", info: "Bad auth info"))
        return Deferred(value: Maybe(failure: response))
    }

    override func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxAClientError.remote(RemoteError(code: 401, errno: 103, error: "Bad auth", message: "Bad auth message", info: "Bad auth info"))
        return Deferred(value: Maybe(failure: response))
    }

    override func scopedKeyData(_ sessionToken: NSData, scope: String) -> Deferred<Maybe<[FxAScopedKeyDataResponse]>> {
        let response = FxAClientError.remote(RemoteError(code: 401, errno: 103, error: "Bad auth", message: "Bad auth message", info: "Bad auth info"))
        return Deferred(value: Maybe(failure: response))
    }
}

// A mock client that responds to keys with 400/104 (needs verification responses).
class MockFxALoginClientBeforeVerification: MockFxALoginClient {
    override func keys(_ keyFetchToken: Data) -> Deferred<Maybe<FxAKeysResponse>> {
        let response = FxAClientError.remote(RemoteError(code: 400, errno: 104,
            error: "Unverified", message: "Unverified message", info: "Unverified info"))
        return Deferred(value: Maybe(failure: response))
    }

    override func scopedKeyData(_ sessionToken: NSData, scope: String) -> Deferred<Maybe<[FxAScopedKeyDataResponse]>> {
        let response = FxAClientError.remote(RemoteError(code: 400, errno: 104,
            error: "Unverified", message: "Unverified message", info: "Unverified info"))
        return Deferred(value: Maybe(failure: response))
    }
}

// A mock client that responds to sign with 503/999 (unknown server error).
class MockFxALoginClientDuringOutage: MockFxALoginClient {
    override func sign(_ sessionToken: Data, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let response = FxAClientError.remote(RemoteError(code: 503, errno: 999,
            error: "Unknown", message: "Unknown error", info: "Unknown err info"))
        return Deferred(value: Maybe(failure: response))
    }

    override func scopedKeyData(_ sessionToken: NSData, scope: String) -> Deferred<Maybe<[FxAScopedKeyDataResponse]>> {
        let response = FxAClientError.remote(RemoteError(code: 503, errno: 999,
            error: "Unknown", message: "Unknown error", info: "Unknown err info"))
        return Deferred(value: Maybe(failure: response))
    }
}

class FxALoginStateMachineTests: XCTestCase {
    let marriedState = FxAStateTests.stateForLabel(FxAStateLabel.married) as! MarriedState

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func withMachine(_ client: FxALoginClient, callback: (FxALoginStateMachine) -> Void) {
        let stateMachine = FxALoginStateMachine(client: client)
        callback(stateMachine)
    }

    func withMachineAndClient(_ callback: (FxALoginStateMachine, MockFxALoginClient) -> Void) {
        let client = MockFxALoginClient()
        withMachine(client) { stateMachine in
            callback(stateMachine, client)
        }
    }

    func testAdvanceWhenInteractionRequired() {
        // The simple cases are when we get to Separated and Doghouse.  There's nothing to do!
        // We just have to wait for user interaction.
        for stateLabel in [FxAStateLabel.separated, FxAStateLabel.doghouse] {
            let e = expectation(description: "Wait for login state machine.")
            let state = FxAStateTests.stateForLabel(stateLabel)
            withMachineAndClient { stateMachine, _ in
                stateMachine.advance(fromState: state, now: 0).upon { newState in
                    XCTAssertEqual(newState.label, stateLabel)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromEngagedBeforeVerified() {
        // Advancing from engaged before verified stays put.
        let e = self.expectation(description: "Wait for login state machine.")
        let engagedState = (FxAStateTests.stateForLabel(.engagedBeforeVerified) as! EngagedBeforeVerifiedState)
        withMachine(MockFxALoginClientBeforeVerification()) { stateMachine in
            stateMachine.advance(fromState: engagedState, now: engagedState.knownUnverifiedAt).upon { newState in
                XCTAssertEqual(newState.label.rawValue, engagedState.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromEngagedAfterVerified() {
        // Advancing from an Engaged state correctly XORs the keys.
        withMachineAndClient { stateMachine, client in
            // let unwrapkB = Bytes.generateRandomBytes(UInt(KeyLength))
            let unwrapkB = client.wrapkB // This way we get all 0s, which is easy to test.
            let engagedState = (FxAStateTests.stateForLabel(.engagedAfterVerified) as! EngagedAfterVerifiedState).withUnwrapKey(unwrapkB)

            let e = self.expectation(description: "Wait for login state machine.")
            stateMachine.advance(fromState: engagedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.married.rawValue)
                if let newState = newState as? MarriedState {
                    XCTAssertEqual(newState.kSync.hexEncodedString, "ec830aefab7dc43c66fb56acc16ed3b723f090ae6f50d6e610b55f4675dcbefba1351b80de8cbeff3c368949c34e8f5520ec7f1d4fa24a0970b437684259f946")
                    XCTAssertEqual(newState.kXCS, "66687aadf862bd776c8fc18b8e9f8e20")
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromEngagedAfterVerifiedWithoutNetwork() {
        // Advancing from engaged after verified, but during outage, stays put.
        withMachine(MockFxALoginClientWithoutNetwork()) { stateMachine in
            let engagedState = FxAStateTests.stateForLabel(.engagedAfterVerified)

            let e = self.expectation(description: "Wait for login state machine.")
            stateMachine.advance(fromState: engagedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, engagedState.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromCohabitingAfterVerifiedDuringOutage() {
        // Advancing from engaged after verified, but during outage, stays put.
        let e = self.expectation(description: "Wait for login state machine.")
        let state = (FxAStateTests.stateForLabel(.cohabitingAfterKeyPair) as! CohabitingAfterKeyPairState)
        withMachine(MockFxALoginClientDuringOutage()) { stateMachine in
            stateMachine.advance(fromState: state, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, state.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromCohabitingAfterVerifiedWithoutNetwork() {
        // Advancing from cohabiting after verified, but when the network is not available, stays put.
        let e = self.expectation(description: "Wait for login state machine.")
        let state = (FxAStateTests.stateForLabel(.cohabitingAfterKeyPair) as! CohabitingAfterKeyPairState)
        withMachine(MockFxALoginClientWithoutNetwork()) { stateMachine in
            stateMachine.advance(fromState: state, now: 0).upon { newState in
                XCTAssertEqual(newState.label.rawValue, state.label.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromMarried() {
        // Advancing from a healthy Married state is easy.
        let e = self.expectation(description: "Wait for login state machine.")
        withMachineAndClient { stateMachine, _ in
            stateMachine.advance(fromState: self.marriedState, now: 0).upon { newState in
                XCTAssertEqual(newState.label, FxAStateLabel.married)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromMarriedWithExpiredCertificate() {
        // Advancing from a Married state with an expired certificate gets back to Married.
        let e = self.expectation(description: "Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneWeekInMilliseconds + 1
        withMachineAndClient { stateMachine, _ in
            stateMachine.advance(fromState: self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.married.rawValue)
                if let newState = newState as? MarriedState {
                    // We should have a fresh certificate.
                    XCTAssertLessThan(self.marriedState.certificateExpiresAt, now)
                    XCTAssertGreaterThan(newState.certificateExpiresAt, now)
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromMarriedWithExpiredKeyPair() {
        // Advancing from a Married state with an expired keypair gets back to Married too.
        let e = self.expectation(description: "Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneMonthInMilliseconds + 1
        withMachineAndClient { stateMachine, _ in
            stateMachine.advance(fromState: self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.married.rawValue)
                if let newState = newState as? MarriedState {
                    // We should have a fresh key pair (and certificate, but we don't verify that).
                    XCTAssertLessThan(self.marriedState.keyPairExpiresAt, now)
                    XCTAssertGreaterThan(newState.keyPairExpiresAt, now)
                }
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAdvanceFromMarriedAfterPasswordChange() {
        // Advancing from a Married state with a 401 goes to Separated if it needs a new certificate.
        let e = self.expectation(description: "Wait for login state machine.")
        let now = self.marriedState.certificateExpiresAt + OneDayInMilliseconds + 1
        withMachine(MockFxALoginClientAfterPasswordChange()) { stateMachine in
            stateMachine.advance(fromState: self.marriedState, now: now).upon { newState in
                XCTAssertEqual(newState.label.rawValue, FxAStateLabel.separated.rawValue)
                e.fulfill()
            }
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
