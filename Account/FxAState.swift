/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared
import SwiftyJSON

// The version of the state schema we persist.
let StateSchemaVersion = 2

// We want an enum because the set of states is closed.  However, each state has state-specific
// behaviour, and the state's behaviour accumulates, so each state is a class.  Switch on the
// label to get exhaustive cases.
public enum FxAStateLabel: String {
    case engagedBeforeVerified = "engagedBeforeVerified"
    case engagedAfterVerified = "engagedAfterVerified"
    case cohabitingBeforeKeyPair = "cohabitingBeforeKeyPair"
    case cohabitingAfterKeyPair = "cohabitingAfterKeyPair"
    case married = "married"
    case separated = "separated"
    case doghouse = "doghouse"

    // See http://stackoverflow.com/a/24137319
    static let allValues: [FxAStateLabel] = [
        engagedBeforeVerified,
        engagedAfterVerified,
        cohabitingBeforeKeyPair,
        cohabitingAfterKeyPair,
        married,
        separated,
        doghouse,
    ]
}

public enum FxAActionNeeded {
    case none
    case needsVerification
    case needsPassword
    case needsUpgrade
}

func state(fromJSON json: JSON) -> FxAState? {
    if json.error != nil {
        return nil
    }
    if let version = json["version"].int {
        if version == 1 {
            return stateV1(fromJSON: json)
        } else if version == 2 {
            return stateV2(fromJSON: json)
        }
    }
    return nil
}

func stateV1(fromJSON json: JSON) -> FxAState? {
    var json = json
    json["version"] = 2
    if let kB = json["kB"].string?.hexDecodedData {
        let kSync = FxAClient10.deriveKSync(kB)
        let kXCS = FxAClient10.computeClientState(kB)
        json["kSync"] = JSON(kSync.hexEncodedString as NSString)
        json["kXCS"] = JSON(kXCS as NSString)
        json["kA"] = JSON.null
        json["kB"] = JSON.null
    }
    return stateV2(fromJSON: json)
}

// Identical to V1 except `(kA, kB)` have been replaced with `(kSync, kXCS)` throughout.
func stateV2(fromJSON json: JSON) -> FxAState? {
    if let labelString = json["label"].string {
        if let label = FxAStateLabel(rawValue: labelString) {
            switch label {
            case .engagedBeforeVerified:
                if let
                    sessionToken = json["sessionToken"].string?.hexDecodedData,
                    let keyFetchToken = json["keyFetchToken"].string?.hexDecodedData,
                    let unwrapkB = json["unwrapkB"].string?.hexDecodedData,
                    let knownUnverifiedAt = json["knownUnverifiedAt"].int64,
                    let lastNotifiedUserAt = json["lastNotifiedUserAt"].int64 {
                    return EngagedBeforeVerifiedState(
                        knownUnverifiedAt: UInt64(knownUnverifiedAt), lastNotifiedUserAt: UInt64(lastNotifiedUserAt),
                        sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                }

            case .engagedAfterVerified:
                if let
                    sessionToken = json["sessionToken"].string?.hexDecodedData,
                    let keyFetchToken = json["keyFetchToken"].string?.hexDecodedData,
                    let unwrapkB = json["unwrapkB"].string?.hexDecodedData {
                    return EngagedAfterVerifiedState(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
                }

            case .cohabitingBeforeKeyPair:
                if let
                    sessionToken = json["sessionToken"].string?.hexDecodedData,
                    let kSync = json["kSync"].string?.hexDecodedData,
                    let kXCS = json["kXCS"].string {
                    return CohabitingBeforeKeyPairState(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS)
                }

            case .cohabitingAfterKeyPair:
                if let
                    sessionToken = json["sessionToken"].string?.hexDecodedData,
                    let kSync = json["kSync"].string?.hexDecodedData,
                    let kXCS = json["kXCS"].string,
                    let keyPairJSON = json["keyPair"].dictionaryObject,
                    let keyPair = RSAKeyPair(jsonRepresentation: keyPairJSON),
                    let keyPairExpiresAt = json["keyPairExpiresAt"].int64 {
                    return CohabitingAfterKeyPairState(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS,
                                                       keyPair: keyPair, keyPairExpiresAt: UInt64(keyPairExpiresAt))
                }

            case .married:
                if let
                    sessionToken = json["sessionToken"].string?.hexDecodedData,
                    let kSync = json["kSync"].string?.hexDecodedData,
                    let kXCS = json["kXCS"].string,
                    let keyPairJSON = json["keyPair"].dictionaryObject,
                    let keyPair = RSAKeyPair(jsonRepresentation: keyPairJSON),
                    let keyPairExpiresAt = json["keyPairExpiresAt"].int64,
                    let certificate = json["certificate"].string,
                    let certificateExpiresAt = json["certificateExpiresAt"].int64 {
                    return MarriedState(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS,
                                        keyPair: keyPair, keyPairExpiresAt: UInt64(keyPairExpiresAt),
                                        certificate: certificate, certificateExpiresAt: UInt64(certificateExpiresAt))
                }

            case .separated:
                return SeparatedState()

            case .doghouse:
                return DoghouseState()
            }
        }
    }
    return nil
}

// Not an externally facing state!
open class FxAState: JSONLiteralConvertible {
    open var label: FxAStateLabel { return FxAStateLabel.separated } // This is bogus, but we have to do something!

    open var actionNeeded: FxAActionNeeded {
        // Kind of nice to have this in one place.
        switch label {
        case .engagedBeforeVerified: return .needsVerification
        case .engagedAfterVerified: return .none
        case .cohabitingBeforeKeyPair: return .none
        case .cohabitingAfterKeyPair: return .none
        case .married: return .none
        case .separated: return .needsPassword
        case .doghouse: return .needsUpgrade
        }
    }

    open func asJSON() -> JSON {
        return JSON([
            "version": StateSchemaVersion,
            "label": self.label.rawValue,
        ])
    }
}

open class SeparatedState: FxAState {
    override open var label: FxAStateLabel { return FxAStateLabel.separated }

    override public init() {
        super.init()
    }
}

// Not an externally facing state!
open class TokenState: FxAState {
    let sessionToken: Data

    init(sessionToken: Data) {
        self.sessionToken = sessionToken
        super.init()
    }

    open override func asJSON() -> JSON {
        var d: [String: JSON] = super.asJSON().dictionary!
        d["sessionToken"] = JSON(sessionToken.hexEncodedString as NSString)
        return JSON(d)
    }
}

// Not an externally facing state!
open class ReadyForKeys: TokenState {
    let keyFetchToken: Data
    let unwrapkB: Data

    init(sessionToken: Data, keyFetchToken: Data, unwrapkB: Data) {
        self.keyFetchToken = keyFetchToken
        self.unwrapkB = unwrapkB
        super.init(sessionToken: sessionToken)
    }

    open override func asJSON() -> JSON {
        var d: [String: JSON] = super.asJSON().dictionary!
        d["keyFetchToken"] = JSON(keyFetchToken.hexEncodedString as NSString)
        d["unwrapkB"] = JSON(unwrapkB.hexEncodedString as NSString)
        return JSON(d)
    }
}

open class EngagedBeforeVerifiedState: ReadyForKeys {
    override open var label: FxAStateLabel { return FxAStateLabel.engagedBeforeVerified }

    // Timestamp, in milliseconds after the epoch, when we first knew the account was unverified.
    // Use this to avoid nagging the user to verify her account immediately after connecting.
    let knownUnverifiedAt: Timestamp
    let lastNotifiedUserAt: Timestamp

    public init(knownUnverifiedAt: Timestamp, lastNotifiedUserAt: Timestamp, sessionToken: Data, keyFetchToken: Data, unwrapkB: Data) {
        self.knownUnverifiedAt = knownUnverifiedAt
        self.lastNotifiedUserAt = lastNotifiedUserAt
        super.init(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    open override func asJSON() -> JSON {
        var d = super.asJSON().dictionary!
        d["knownUnverifiedAt"] = JSON(NSNumber(value: knownUnverifiedAt))
        d["lastNotifiedUserAt"] = JSON(NSNumber(value: lastNotifiedUserAt))
        return JSON(d)
    }

    func withUnwrapKey(_ unwrapkB: Data) -> EngagedBeforeVerifiedState {
        return EngagedBeforeVerifiedState(
            knownUnverifiedAt: knownUnverifiedAt, lastNotifiedUserAt: lastNotifiedUserAt,
            sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }
}

open class EngagedAfterVerifiedState: ReadyForKeys {
    override open var label: FxAStateLabel { return FxAStateLabel.engagedAfterVerified }

    override public init(sessionToken: Data, keyFetchToken: Data, unwrapkB: Data) {
        super.init(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }

    func withUnwrapKey(_ unwrapkB: Data) -> EngagedAfterVerifiedState {
        return EngagedAfterVerifiedState(sessionToken: sessionToken, keyFetchToken: keyFetchToken, unwrapkB: unwrapkB)
    }
}

// Not an externally facing state!
open class TokenAndKeys: TokenState {
    public let kSync: Data
    public let kXCS: String

    init(sessionToken: Data, kSync: Data, kXCS: String) {
        self.kSync = kSync
        self.kXCS = kXCS
        super.init(sessionToken: sessionToken)
    }

    open override func asJSON() -> JSON {
        var d = super.asJSON().dictionary!
        d["kSync"] = JSON(kSync.hexEncodedString as NSString)
        d["kXCS"] = JSON(kXCS as NSString)
        return JSON(d)
    }
}

open class CohabitingBeforeKeyPairState: TokenAndKeys {
    override open var label: FxAStateLabel { return FxAStateLabel.cohabitingBeforeKeyPair }
}

// Not an externally facing state!
open class TokenKeysAndKeyPair: TokenAndKeys {
    let keyPair: KeyPair
    // Timestamp, in milliseconds after the epoch, when keyPair expires.  After this time, generate a new keyPair.
    let keyPairExpiresAt: Timestamp

    init(sessionToken: Data, kSync: Data, kXCS: String, keyPair: KeyPair, keyPairExpiresAt: Timestamp) {
        self.keyPair = keyPair
        self.keyPairExpiresAt = keyPairExpiresAt
        super.init(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS)
    }

    open override func asJSON() -> JSON {
        var d = super.asJSON().dictionary!
        d["keyPair"] = JSON(keyPair.jsonRepresentation() as Any)
        d["keyPairExpiresAt"] = JSON(NSNumber(value: keyPairExpiresAt))
        return JSON(d)
    }

    func isKeyPairExpired(_ now: Timestamp) -> Bool {
        return keyPairExpiresAt < now
    }
}

open class CohabitingAfterKeyPairState: TokenKeysAndKeyPair {
    override open var label: FxAStateLabel { return FxAStateLabel.cohabitingAfterKeyPair }
}

open class MarriedState: TokenKeysAndKeyPair {
    override open var label: FxAStateLabel { return FxAStateLabel.married }

    let certificate: String
    let certificateExpiresAt: Timestamp

    init(sessionToken: Data, kSync: Data, kXCS: String, keyPair: KeyPair, keyPairExpiresAt: Timestamp, certificate: String, certificateExpiresAt: Timestamp) {
        self.certificate = certificate
        self.certificateExpiresAt = certificateExpiresAt
        super.init(sessionToken: sessionToken, kSync: kSync, kXCS: kXCS, keyPair: keyPair, keyPairExpiresAt: keyPairExpiresAt)
    }

    open override func asJSON() -> JSON {
        var d = super.asJSON().dictionary!
        d["certificate"] = JSON(certificate as NSString)
        d["certificateExpiresAt"] = JSON(NSNumber(value: certificateExpiresAt))
        return JSON(d)
    }

    func isCertificateExpired(_ now: Timestamp) -> Bool {
        // Without the 5 min early expiration, the certificate may be too close to expiring, and expire by the time it gets used.
        let t = now < (5 * OneMinuteInMilliseconds) ? 0 : now - (5 * OneMinuteInMilliseconds)
        return certificateExpiresAt < t
    }

    func withoutKeyPair() -> CohabitingBeforeKeyPairState {
        let newState = CohabitingBeforeKeyPairState(sessionToken: sessionToken,
            kSync: kSync, kXCS: kXCS)
        return newState
    }

    func withoutCertificate() -> CohabitingAfterKeyPairState {
        let newState = CohabitingAfterKeyPairState(sessionToken: sessionToken,
            kSync: kSync, kXCS: kXCS,
            keyPair: keyPair, keyPairExpiresAt: keyPairExpiresAt)
        return newState
    }

    open func generateAssertionForAudience(_ audience: String, now: Timestamp) -> String {
        let assertion = JSONWebTokenUtils.createAssertionWithPrivateKeyToSign(with: keyPair.privateKey,
            certificate: certificate,
            audience: audience,
            issuer: "127.0.0.1",
            issuedAt: now,
            duration: OneHourInMilliseconds)
        return assertion!
    }
}

open class DoghouseState: FxAState {
    override open var label: FxAStateLabel { return FxAStateLabel.doghouse }

    override public init() {
        super.init()
    }
}
