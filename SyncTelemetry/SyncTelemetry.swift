/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import SwiftyJSON
import Shared

private let log = Logger.browserLogger
//private let ServerURL = "https://incoming.telemetry.mozilla.org".asURL!
//private let AppName = "Fennec"

public enum TelemetryDocType: String {
    case core = "core"
    case sync = "sync"
}

public protocol SyncTelemetryEvent {
    func record(_ prefs: Prefs)
}

open class SyncTelemetry {
    private static var prefs: Prefs?
    private static var telemetryVersion: Int = 4

    open class func initWithPrefs(_ prefs: Prefs) {
        assert(self.prefs == nil, "Prefs already initialized")
        self.prefs = prefs
    }

    open class func recordEvent(_ event: SyncTelemetryEvent) {
        guard let prefs = prefs else {
            assertionFailure("Prefs not initialized")
            return
        }

        event.record(prefs)
    }

    open class func send(ping: SyncTelemetryPing, docType: TelemetryDocType) {
        NSLog("TrueLocationBrowser-Log: \(#file) - \(#function)")
    }

    private static func commonPingFormat(forType type: TelemetryDocType) -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = formatter.string(from: NSDate() as Date)
        let displayVersion = [
            AppInfo.appVersion,
            "b",
            AppInfo.buildNumber
        ].joined()
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        return [
            "type": type.rawValue,
            "id": UUID().uuidString,
            "creationDate": date,
            "version": SyncTelemetry.telemetryVersion,
            "application": [
                "architecture": "arm",
                "buildId": AppInfo.buildNumber,
                "name": AppInfo.displayName,
                "version": AppInfo.appVersion,
                "displayVersion": displayVersion,
                "platformVersion": osVersion,
                "channel": AppConstants.BuildChannel.rawValue
            ]
        ]
    }
}

public protocol SyncTelemetryPing {
    var payload: JSON { get }
}
