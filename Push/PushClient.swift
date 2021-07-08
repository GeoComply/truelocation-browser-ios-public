/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

//public struct PushRemoteError {
//    static let MissingNecessaryCryptoKeys: Int32 = 101
//    static let InvalidURLEndpoint: Int32         = 102
//    static let ExpiredURLEndpoint: Int32         = 103
//    static let DataPayloadTooLarge: Int32        = 104
//    static let EndpointBecameUnavailable: Int32  = 105
//    static let InvalidSubscription: Int32        = 106
//    static let RouterTypeIsInvalid: Int32        = 108
//    static let InvalidAuthentication: Int32      = 109
//    static let InvalidCryptoKeysSpecified: Int32 = 110
//    static let MissingRequiredHeader: Int32      = 111
//    static let InvalidTTLHeaderValue: Int32      = 112
//    static let UnknownError: Int32               = 999
//}

public let PushClientErrorDomain = "org.mozilla.push.error"
private let PushClientUnknownError = NSError(domain: PushClientErrorDomain, code: 999,
                                             userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
private let log = Logger.browserLogger

/// Bug 1364403 – This is to be put into the push registration
private let apsEnvironment: [String: Any] = [
    "mutable-content": 1,
    "alert": [
        "title": " ",
        "body": " "
    ],
]

public struct PushRemoteError {
    let code: Int
    let errno: Int
    let error: String
    let message: String?

    public static func from(json: JSON) -> PushRemoteError? {
        guard let code = json["code"].int,
              let errno = json["errno"].int,
              let error = json["error"].string else {
            return nil
        }

        let message = json["message"].string
        return PushRemoteError(code: code, errno: errno, error: error, message: message)
    }
}

public enum PushClientError: MaybeErrorType {
    case Remote(PushRemoteError)
    case Local(Error)

    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error
            let messageString = error.message ?? ""
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error \"\(error.localizedDescription)\">"
        }
    }
}

public class PushClient {
    let endpointURL: NSURL
    let experimentalMode: Bool

    lazy fileprivate var urlSession = makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.ephemeral)

    public init(endpointURL: NSURL, experimentalMode: Bool = false) {
        self.endpointURL = endpointURL
        self.experimentalMode = experimentalMode
    }
}

public extension PushClient {
    func register(_ apnsToken: String) -> Deferred<Maybe<PushRegistration>> {
        //  POST /v1/{type}/{app_id}/registration
        let registerURL = endpointURL.appendingPathComponent("registration")!

        var mutableURLRequest = URLRequest(url: registerURL)
        mutableURLRequest.httpMethod = HTTPMethod.post.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters: [String: Any]
        if experimentalMode {
            parameters = [
                "token": apnsToken,
                "aps": apsEnvironment,
            ]
        } else {
            parameters = ["token": apnsToken]
        }

        mutableURLRequest.httpBody = JSON(parameters).stringify()?.utf8EncodedData

        if experimentalMode {
            log.info("curl -X POST \(registerURL.absoluteString) --data '\(JSON(parameters).stringify()!)'")
        }

        return send(request: mutableURLRequest) >>== { json in
            guard let response = PushRegistration.from(json: json) else {
                return deferMaybe(PushClientError.Local(PushClientUnknownError))
            }

            return deferMaybe(response)
        }
    }

    func updateUAID(_ apnsToken: String, withRegistration creds: PushRegistration) -> Deferred<Maybe<PushRegistration>> {
        //  PUT /v1/{type}/{app_id}/registration/{uaid}
        let registerURL = endpointURL.appendingPathComponent("registration/\(creds.uaid)")!
        var mutableURLRequest = URLRequest(url: registerURL)

        mutableURLRequest.httpMethod = HTTPMethod.put.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["token": apnsToken]
        mutableURLRequest.httpBody = JSON(parameters).stringify()?.utf8EncodedData

        return send(request: mutableURLRequest) >>== { json in
            KeychainStore.shared.setString(apnsToken, forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
            return deferMaybe(creds)
        }
    }

    func unregister(_ creds: PushRegistration) -> Success {
        //  DELETE /v1/{type}/{app_id}/registration/{uaid}
        let unregisterURL = endpointURL.appendingPathComponent("registration/\(creds.uaid)")

        var mutableURLRequest = URLRequest(url: unregisterURL!)
        mutableURLRequest.httpMethod = HTTPMethod.delete.rawValue
        mutableURLRequest.addValue("Bearer \(creds.secret)", forHTTPHeaderField: "Authorization")

        return send(request: mutableURLRequest) >>> succeed
    }
}

/// Utilities
extension PushClient {
    fileprivate func send(request: URLRequest) -> Deferred<Maybe<JSON>> {
        log.info("\(request.httpMethod!) \(request.url?.absoluteString ?? "nil")")
        let deferred = Deferred<Maybe<JSON>>()
        urlSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                deferred.fill(Maybe(failure: PushClientError.Local(error)))
                return
            }

            guard let _ = validatedHTTPResponse(response, contentType: "application/json"), let data = data, !data.isEmpty else {
                deferred.fill(Maybe(failure: PushClientError.Local(PushClientUnknownError)))
                return
            }

            do {
                let json = try JSON(data: data)
                if let remoteError = PushRemoteError.from(json: json) {
                    return deferred.fill(Maybe(failure: PushClientError.Remote(remoteError)))
                }
                deferred.fill(Maybe(success: json))
            } catch {
                return deferred.fill(Maybe(failure: PushClientError.Local(error)))
            }
        }.resume()

        return deferred
    }
}
