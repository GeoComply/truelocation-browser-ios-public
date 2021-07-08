/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import MozillaAppServices
import Shared
import Account
import Sync

class TelemetryWrapper {

    private func migratePathComponentInDocumentsDirectory(_ pathComponent: String, to destinationSearchPath: FileManager.SearchPathDirectory) {}

    init(profile: Profile) {}

    func initGlean(_ profile: Profile, sendUsageData: Bool) {}
    
    // Sets hashed fxa sync device id for glean deletion ping
    func setSyncDeviceId() {}

    // Function for recording metrics that are better recorded when going to background due
    // to the particular measurement, or availability of the information.
    @objc func recordPreferenceMetrics(notification: NSNotification) {
        
    }

    @objc func uploadError(notification: NSNotification) {
       
    }
}

// Enums for Event telemetry.
extension TelemetryWrapper {
    public enum EventCategory: String {
        case action = "action"
        case appExtensionAction = "app-extension-action"
        case prompt = "prompt"
        case enrollment = "enrollment"
        case firefoxAccount = "firefox_account"
    }

    public enum EventMethod: String {
        case add = "add"
        case background = "background"
        case cancel = "cancel"
        case change = "change"
        case close = "close"
        case closeAll = "close-all"
        case delete = "delete"
        case deleteAll = "deleteAll"
        case drag = "drag"
        case drop = "drop"
        case foreground = "foreground"
        case open = "open"
        case press = "press"
        case scan = "scan"
        case share = "share"
        case tap = "tap"
        case translate = "translate"
        case view = "view"
        case applicationOpenUrl = "application-open-url"
        case emailLogin = "email"
        case qrPairing = "pairing"
        case settings = "settings"
    }

    public enum EventObject: String {
        case app = "app"
        case bookmark = "bookmark"
        case bookmarksPanel = "bookmarks-panel"
        case download = "download"
        case downloadLinkButton = "download-link-button"
        case downloadNowButton = "download-now-button"
        case downloadsPanel = "downloads-panel"
        case keyCommand = "key-command"
        case locationBar = "location-bar"
        case qrCodeText = "qr-code-text"
        case qrCodeURL = "qr-code-url"
        case readerModeCloseButton = "reader-mode-close-button"
        case readerModeOpenButton = "reader-mode-open-button"
        case readingListItem = "reading-list-item"
        case setting = "setting"
        case tab = "tab"
        case tabTray = "tab-tray"
        case trackingProtectionStatistics = "tracking-protection-statistics"
        case trackingProtectionSafelist = "tracking-protection-safelist"
        case trackingProtectionMenu = "tracking-protection-menu"
        case url = "url"
        case searchText = "searchText"
        case whatsNew = "whats-new"
        case dismissUpdateCoverSheetAndStartBrowsing = "dismissed-update-cover_sheet_and_start_browsing"
        case dismissedUpdateCoverSheet = "dismissed-update-cover-sheet"
        case dismissedETPCoverSheet = "dismissed-etp-sheet"
        case dismissETPCoverSheetAndStartBrowsing = "dismissed-etp-cover-sheet-and-start-browsing"
        case dismissETPCoverSheetAndGoToSettings = "dismissed-update-cover-sheet-and-go-to-settings"
        case dismissedOnboarding = "dismissed-onboarding"
        case dismissedOnboardingEmailLogin = "dismissed-onboarding-email-login"
        case dismissedOnboardingSignUp = "dismissed-onboarding-sign-up"
        case privateBrowsingButton = "private-browsing-button"
        case startSearchButton = "start-search-button"
        case addNewTabButton = "add-new-tab-button"
        case removeUnVerifiedAccountButton = "remove-unverified-account-button"
        case tabSearch = "tab-search"
        case tabToolbar = "tab-toolbar"
        case experimentEnrollment = "experiment-enrollment"
        case chinaServerSwitch = "china-server-switch"
        case accountConnected = "connected"
        case accountDisconnected = "disconnected"
        case appMenu = "app_menu"
        case settings = "settings"
        case settingsMenuSetAsDefaultBrowser = "set-as-default-browser-menu-go-to-settings"
        case onboarding = "onboarding"
        case dismissDefaultBrowserCard = "default-browser-card"
        case goToSettingsDefaultBrowserCard = "default-browser-card-go-to-settings"
        case dismissDefaultBrowserOnboarding = "default-browser-onboarding"
        case goToSettingsDefaultBrowserOnboarding = "default-browser-onboarding-go-to-settings"
        case asDefaultBrowser = "as-default-browser"
        case mediumTabsOpenUrl = "medium-tabs-widget-url"
        case largeTabsOpenUrl = "large-tabs-widget-url"
        case smallQuickActionSearch = "small-quick-action-search"
        case mediumQuickActionSearch = "medium-quick-action-search"
        case mediumQuickActionPrivateSearch = "medium-quick-action-private-search"
        case mediumQuickActionCopiedLink = "medium-quick-action-copied-link"
        case mediumQuickActionClosePrivate = "medium-quick-action-close-private"
        case mediumTopSitesWidget = "medium-top-sites-widget"
        case pocketStory = "pocket-story"
    }

    public enum EventValue: String {
        case activityStream = "activity-stream"
        case appMenu = "app-menu"
        case awesomebarResults = "awesomebar-results"
        case bookmarksPanel = "bookmarks-panel"
        case browser = "browser"
        case contextMenu = "context-menu"
        case downloadCompleteToast = "download-complete-toast"
        case downloadsPanel = "downloads-panel"
        case homePanel = "home-panel"
        case homePanelTabButton = "home-panel-tab-button"
        case markAsRead = "mark-as-read"
        case markAsUnread = "mark-as-unread"
        case pageActionMenu = "page-action-menu"
        case readerModeToolbar = "reader-mode-toolbar"
        case readingListPanel = "reading-list-panel"
        case shareExtension = "share-extension"
        case shareMenu = "share-menu"
        case tabTray = "tab-tray"
        case topTabs = "top-tabs"
        case systemThemeSwitch = "system-theme-switch"
        case themeModeManually = "theme-manually"
        case themeModeAutomatically = "theme-automatically"
        case themeLight = "theme-light"
        case themeDark = "theme-dark"
        case privateTab = "private-tab"
        case normalTab = "normal-tab"
        case tabView = "tab-view"
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {}

    static func gleanRecordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String: Any]? = nil) {}
}
