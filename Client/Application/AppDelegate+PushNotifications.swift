// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import Sync
import XCGLogger
import UserNotifications
import Account
import MozillaAppServices

private let log = Logger.browserLogger

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to display a notification.
 * This will also likely be the extension point for wipes, resets, and getting access to data sources during a sync.
 */
enum SentTabAction: String {
    case view = "TabSendViewAction"

    static let TabSendURLKey = "TabSendURL"
    static let TabSendTitleKey = "TabSendTitle"
    static let TabSendCategory = "TabSendCategory"

    static func registerActions() {
        let viewAction = UNNotificationAction(identifier: SentTabAction.view.rawValue, title: .SentTabViewActionTitle, options: .foreground)

        // Register ourselves to handle the notification category set by NotificationService for APNS notifications
        let sentTabCategory = UNNotificationCategory(identifier: "org.mozilla.ios.SentTab.placeholder", actions: [viewAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))
        UNUserNotificationCenter.current().setNotificationCategories([sentTabCategory])
    }
}

extension AppDelegate {
    func pushNotificationSetup() {
       UNUserNotificationCenter.current().delegate = self
       SentTabAction.registerActions()

        NotificationCenter.default.addObserver(forName: .RegisterForPushNotifications, object: nil, queue: .main) { _ in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus != .denied {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }

        // If we see our local device with a pushEndpointExpired flag, clear the APNS token and re-register.
        NotificationCenter.default.addObserver(forName: .constellationStateUpdate, object: nil, queue: nil) { notification in
            if let newState = notification.userInfo?["newState"] as? ConstellationState {
                if newState.localDevice?.pushEndpointExpired ?? false {
                    MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
                    NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
                }
            }
        }

        // Use sync event as a periodic check for the apnsToken.
        // The notification service extension can clear this token if there is an error, and the main app can detect this and re-register.
        NotificationCenter.default.addObserver(forName: .ProfileDidStartSyncing, object: nil, queue: .main) { _ in
            let kc = MZKeychainWrapper.sharedClientAppContainerKeychain
            if kc.object(forKey: KeychainKey.apnsToken, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock) == nil {
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }
        }
    }

    private func openURLsInNewTabs(_ notification: UNNotification) {
        guard let urls = notification.request.content.userInfo["sentTabs"] as? [NSDictionary]  else { return }
        for sentURL in urls {
            if let urlString = sentURL.value(forKey: "url") as? String, let url = URL(string: urlString) {
                receivedURLs.append(url)
            }
        }

        // Check if the app is foregrounded, _also_ verify the BVC is initialized. Most BVC functions depend on viewDidLoad() having run –if not, they will crash.
        if UIApplication.shared.applicationState == .active && BrowserViewController.foregroundBVC().isViewLoaded {
            BrowserViewController.foregroundBVC().loadQueuedTabs(receivedURLs: receivedURLs)
            receivedURLs.removeAll()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when the user taps on a sent-tab notification from the background.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        openURLsInNewTabs(response.notification)
    }

    // Called when the user receives a tab (or any other notification) while in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        if profile?.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
            profile?.removeAccount()
            
            // show the notification
            completionHandler([.alert, .sound])
        } else {
            openURLsInNewTabs(notification)
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        RustFirefoxAccounts.shared.pushNotifications.didRegister(withDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed to register. \(error)")
        /*
        Sentry.shared.send(message: "Failed to register for APNS")
         */
    }
}
