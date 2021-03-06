// -*- mode: Swift -*-

// AUTOGENERATED BY glean_parser.  DO NOT EDIT.

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import MozillaAppServices

// swiftlint:disable superfluous_disable_command
// swiftlint:disable nesting
// swiftlint:disable line_length
// swiftlint:disable identifier_name
// swiftlint:disable force_try

extension GleanMetrics {
    enum Search {
        private static let countsLabel = CounterMetricType( // generated from search.counts
            category: "search",
            name: "counts",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// The labels for this counter are `{search-engine-name}.{source}`
        /// 
        /// If the search engine is bundled with Firefox-iOS, then
        /// `search-engine-name` will be the name of the search engine. If
        /// it is a custom search engine, the value will be `custom`.
        /// 
        /// The value of `source` will reflect the source from which the
        /// search started.  One of:
        /// * quicksearch
        /// * suggestion
        /// * actionbar
        static let counts = try! LabeledMetricType<CounterMetricType>( // generated from search.counts
            category: "search",
            name: "counts",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: countsLabel,
            labels: nil
        )

        /// The default search engine identifier if the search engine is
        /// pre-loaded with Firefox-iOS.  If it's a custom search engine,
        /// then the value will be 'custom'.
        static let defaultEngine = StringMetricType( // generated from search.default_engine
            category: "search",
            name: "default_engine",
            sendInPings: ["metrics"],
            lifetime: .application,
            disabled: false
        )

        /// Counts the number of times the start search button is
        /// pressed
        static let startSearchPressed = CounterMetricType( // generated from search.start_search_pressed
            category: "search",
            name: "start_search_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        private static let inContentLabel = CounterMetricType( // generated from search.in_content
            category: "search",
            name: "in_content",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: true
        )

        /// Records the type of interaction a user has on SERP pages.
        static let inContent = try! LabeledMetricType<CounterMetricType>( // generated from search.in_content
            category: "search",
            name: "in_content",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: true,
            subMetric: inContentLabel,
            labels: nil
        )

        private static let googleTopsitePressedLabel = CounterMetricType( // generated from search.google_topsite_pressed
            category: "search",
            name: "google_topsite_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times the google top site button
        /// is pressed
        static let googleTopsitePressed = try! LabeledMetricType<CounterMetricType>( // generated from search.google_topsite_pressed
            category: "search",
            name: "google_topsite_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: googleTopsitePressedLabel,
            labels: nil
        )

    }

    enum Preferences {
        enum ChangedKeys: Int32, ExtraKeys {
            case changedTo = 0
            case preference = 1

            public func index() -> Int32 {
                return self.rawValue
            }
        }

        /// Recorded when a preference is changed and includes the
        /// preference that changed as well as the value changed to
        /// recorded in the extra keys.
        static let changed = EventMetricType<ChangedKeys>( // generated from preferences.changed
            category: "preferences",
            name: "changed",
            sendInPings: ["events"],
            lifetime: .ping,
            disabled: false,
            allowedExtraKeys: ["changed_to", "preference"]
        )

        /// The name of the view that the user wants to see on new tabs.
        /// For example History, Homepage or Blank. It is used to measure
        /// usage of this feature, to see how effective feature promotion
        /// campaigns are and to establish a baseline number for when we
        /// introduce the new Activity Stream features.
        static let newTabExperience = StringMetricType( // generated from preferences.new_tab_experience
            category: "preferences",
            name: "new_tab_experience",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// The URL scheme of the mail client that the user wants to use
        /// for `mailto:` links. It is used to measure usage of this
        /// feature, to see how effective feature promotion campaigns are
        /// and to report back to third-party mail clients what percentage
        /// of users is using their client.
        static let mailClient = StringMetricType( // generated from preferences.mail_client
            category: "preferences",
            name: "mail_client",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the "Block Popups" preference.
        static let blockPopups = BooleanMetricType( // generated from preferences.block_popups
            category: "preferences",
            name: "block_popups",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the "Save Logins" preference.
        static let saveLogins = BooleanMetricType( // generated from preferences.save_logins
            category: "preferences",
            name: "save_logins",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the "Show Clipboard Bar" preference.
        static let showClipboardBar = BooleanMetricType( // generated from preferences.show_clipboard_bar
            category: "preferences",
            name: "show_clipboard_bar",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the "Close Private Tabs" preference.
        static let closePrivateTabs = BooleanMetricType( // generated from preferences.close_private_tabs
            category: "preferences",
            name: "close_private_tabs",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum ApplicationServices {
        /// Measures the state of the show Pocket stories preference.
        static let pocketStoriesVisible = BooleanMetricType( // generated from application_services.pocket_stories_visible
            category: "application_services",
            name: "pocket_stories_visible",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the show bookmark highlights
        /// preference.
        static let bookmarkHighlightsVisible = BooleanMetricType( // generated from application_services.bookmark_highlights_visible
            category: "application_services",
            name: "bookmark_highlights_visible",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the show recent highlights
        /// preference.
        static let recentHighlightsVisible = BooleanMetricType( // generated from application_services.recent_highlights_visible
            category: "application_services",
            name: "recent_highlights_visible",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum TrackingProtection {
        /// Measures the state of the tracking-protection enabled
        /// preference.
        static let enabled = BooleanMetricType( // generated from tracking_protection.enabled
            category: "tracking_protection",
            name: "enabled",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// A string representing the selected strength of the
        /// tracking-protection that is enabled. One of:
        /// * basic
        /// * strict
        static let strength = StringMetricType( // generated from tracking_protection.strength
            category: "tracking_protection",
            name: "strength",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum Theme {
        /// Measures the state of the "Use System Light/Dark Mode"
        /// theme preference.
        static let useSystemTheme = BooleanMetricType( // generated from theme.use_system_theme
            category: "theme",
            name: "use_system_theme",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the state of the "Manual/Automatic" theme
        /// preference.
        static let automaticMode = BooleanMetricType( // generated from theme.automatic_mode
            category: "theme",
            name: "automatic_mode",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the string representation of the current slider
        /// value of the automatic theme switching slider.
        static let automaticSliderValue = StringMetricType( // generated from theme.automatic_slider_value
            category: "theme",
            name: "automatic_slider_value",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Measures the name of the current theme.  One of:
        /// * normal
        /// * dark
        static let name = StringMetricType( // generated from theme.name
            category: "theme",
            name: "name",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum Tabs {
        /// Measures the current open tab count as the application
        /// goes to background. Each background event adds to this
        /// metric, making it the cumulative sum of all open tabs
        /// when the app goes to background. This can be divided by
        /// the number of baseline pings to determine the average
        /// open tab count.
        static let cumulativeCount = CounterMetricType( // generated from tabs.cumulative_count
            category: "tabs",
            name: "cumulative_count",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        private static let openLabel = CounterMetricType( // generated from tabs.open
            category: "tabs",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// The count of tabs opened by the user. Increments the
        /// appropriate label when either a normal or private tab
        /// is opened.
        static let open = try! LabeledMetricType<CounterMetricType>( // generated from tabs.open
            category: "tabs",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: openLabel,
            labels: ["normal-tab", "private-tab"]
        )

        private static let closeLabel = CounterMetricType( // generated from tabs.close
            category: "tabs",
            name: "close",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// The count of tabs closed by the user. Increments the
        /// appropriate label when either a normal or private tab
        /// is closed.
        static let close = try! LabeledMetricType<CounterMetricType>( // generated from tabs.close
            category: "tabs",
            name: "close",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: closeLabel,
            labels: ["normal-tab", "private-tab"]
        )

        private static let closeAllLabel = CounterMetricType( // generated from tabs.close_all
            category: "tabs",
            name: "close_all",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// The count of times the user closes all tabs. Increments the
        /// appropriate label when either a normal or private tab
        /// is closed.
        static let closeAll = try! LabeledMetricType<CounterMetricType>( // generated from tabs.close_all
            category: "tabs",
            name: "close_all",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: closeAllLabel,
            labels: ["normal-tab", "private-tab"]
        )

        /// Counts the number of times the add new tab button is
        /// pressed
        static let newTabPressed = CounterMetricType( // generated from tabs.new_tab_pressed
            category: "tabs",
            name: "new_tab_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Recorded when a user clicks an open tab
        static let clickTab = EventMetricType<NoExtraKeys>( // generated from tabs.click_tab
            category: "tabs",
            name: "click_tab",
            sendInPings: ["events"],
            lifetime: .ping,
            disabled: false,
            allowedExtraKeys: []
        )

        /// Recorded when a user opens the tab tray
        static let openTabTray = EventMetricType<NoExtraKeys>( // generated from tabs.open_tab_tray
            category: "tabs",
            name: "open_tab_tray",
            sendInPings: ["events"],
            lifetime: .ping,
            disabled: false,
            allowedExtraKeys: []
        )

        /// Recorded when a user closes the tab tray
        static let closeTabTray = EventMetricType<NoExtraKeys>( // generated from tabs.close_tab_tray
            category: "tabs",
            name: "close_tab_tray",
            sendInPings: ["events"],
            lifetime: .ping,
            disabled: false,
            allowedExtraKeys: []
        )

    }

    enum Bookmarks {
        private static let viewListLabel = CounterMetricType( // generated from bookmarks.view_list
            category: "bookmarks",
            name: "view_list",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times the bookmarks list is opened
        /// from either the Home Panel tab button or the App Menu.
        static let viewList = try! LabeledMetricType<CounterMetricType>( // generated from bookmarks.view_list
            category: "bookmarks",
            name: "view_list",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: viewListLabel,
            labels: ["app-menu", "home-panel"]
        )

        private static let addLabel = CounterMetricType( // generated from bookmarks.add
            category: "bookmarks",
            name: "add",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times a bookmark is added from the
        /// following:
        /// * Page Action Menu
        /// * Share Menu
        /// * Activity Stream context menu
        static let add = try! LabeledMetricType<CounterMetricType>( // generated from bookmarks.add
            category: "bookmarks",
            name: "add",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: addLabel,
            labels: ["activity-stream", "page-action-menu", "share-menu"]
        )

        private static let deleteLabel = CounterMetricType( // generated from bookmarks.delete
            category: "bookmarks",
            name: "delete",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times a bookmark is deleted from
        /// the following:
        /// * Page Action Menu
        /// * Activity Stream
        /// * Bookmarks Panel
        static let delete = try! LabeledMetricType<CounterMetricType>( // generated from bookmarks.delete
            category: "bookmarks",
            name: "delete",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: deleteLabel,
            labels: ["activity-stream", "bookmarks-panel", "page-action-menu"]
        )

        private static let openLabel = CounterMetricType( // generated from bookmarks.open
            category: "bookmarks",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times a bookmark is opened from
        /// the following:
        /// * Awesomebar results
        /// * Bookmarks Panel
        static let open = try! LabeledMetricType<CounterMetricType>( // generated from bookmarks.open
            category: "bookmarks",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: openLabel,
            labels: ["awesomebar-results", "bookmarks-panel"]
        )

    }

    enum ReaderMode {
        /// Counts how many times the reader mode is opened.
        static let open = CounterMetricType( // generated from reader_mode.open
            category: "reader_mode",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times the reader mode is closed.
        static let close = CounterMetricType( // generated from reader_mode.close
            category: "reader_mode",
            name: "close",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum ReadingList {
        private static let addLabel = CounterMetricType( // generated from reading_list.add
            category: "reading_list",
            name: "add",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times an item is added to the reading
        /// list from the following:
        /// * Reader Mode Toolbar
        /// * Share Extension
        /// * Page Action Menu
        static let add = try! LabeledMetricType<CounterMetricType>( // generated from reading_list.add
            category: "reading_list",
            name: "add",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: addLabel,
            labels: ["page-action-menu", "reader-mode-toolbar", "share-extension"]
        )

        /// Counts the number of times an item is opened from the
        /// Reading List
        static let open = CounterMetricType( // generated from reading_list.open
            category: "reading_list",
            name: "open",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        private static let deleteLabel = CounterMetricType( // generated from reading_list.delete
            category: "reading_list",
            name: "delete",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times an item is added to the
        /// reading list from the following:
        /// * Reader Mode Toolbar
        /// * Reading List Panel
        static let delete = try! LabeledMetricType<CounterMetricType>( // generated from reading_list.delete
            category: "reading_list",
            name: "delete",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false,
            subMetric: deleteLabel,
            labels: ["reader-mode-toolbar", "reading-list-panel"]
        )

        /// Counts the number of times a reading list item is
        /// marked as read.
        static let markRead = CounterMetricType( // generated from reading_list.mark_read
            category: "reading_list",
            name: "mark_read",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times a reading list item is
        /// marked as unread.
        static let markUnread = CounterMetricType( // generated from reading_list.mark_unread
            category: "reading_list",
            name: "mark_unread",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum SettingsMenu {
        /// Counts the number of times setting as default
        /// browser menu option is tapped.
        static let setAsDefaultBrowserPressed = CounterMetricType( // generated from settings_menu.set_as_default_browser_pressed
            category: "settings_menu",
            name: "set_as_default_browser_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: true
        )

    }

    enum QrCode {
        /// Counts the number of times a QR code is scanned.
        static let scanned = CounterMetricType( // generated from qr_code.scanned
            category: "qr_code",
            name: "scanned",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum DefaultBrowserCard {
        /// Counts the number of times default browser card is dismissed.
        static let dismissPressed = CounterMetricType( // generated from default_browser_card.dismiss_pressed
            category: "default_browser_card",
            name: "dismiss_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times the Go To Settings button on
        /// default browser card is clicked.
        static let goToSettingsPressed = CounterMetricType( // generated from default_browser_card.go_to_settings_pressed
            category: "default_browser_card",
            name: "go_to_settings_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: true
        )

    }

    enum DefaultBrowserOnboarding {
        /// Counts the number of times default browser onboarding is dismissed.
        static let dismissPressed = CounterMetricType( // generated from default_browser_onboarding.dismiss_pressed
            category: "default_browser_onboarding",
            name: "dismiss_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts the number of times the Go To Settings button on
        /// default browser onboarding is clicked.
        static let goToSettingsPressed = CounterMetricType( // generated from default_browser_onboarding.go_to_settings_pressed
            category: "default_browser_onboarding",
            name: "go_to_settings_pressed",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum App {
        /// Counts the number of times the app is opened from an external
        /// link, implying the client has Firefox set as a default browser.
        /// 
        /// Currently this is our most accurate way of measuring how
        /// often Firefox is set as the default browser.
        static let openedAsDefaultBrowser = CounterMetricType( // generated from app.opened_as_default_browser
            category: "app",
            name: "opened_as_default_browser",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: true
        )

    }

    enum LegacyIds {
        /// The client id from legacy telemetry.
        static let clientId = UuidMetricType( // generated from legacy.ids.client_id
            category: "legacy.ids",
            name: "client_id",
            sendInPings: ["deletion-request"],
            lifetime: .user,
            disabled: false
        )

    }

    enum Deletion {
        /// The FxA device id.
        static let syncDeviceId = StringMetricType( // generated from deletion.sync_device_id
            category: "deletion",
            name: "sync_device_id",
            sendInPings: ["deletion-request"],
            lifetime: .user,
            disabled: false
        )

    }

    enum Widget {
        /// Counts how many times the medium tabs widget opens url
        static let mTabsOpenUrl = CounterMetricType( // generated from widget.m_tabs_open_url
            category: "widget",
            name: "m_tabs_open_url",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times the large tabs widget opens url
        static let lTabsOpenUrl = CounterMetricType( // generated from widget.l_tabs_open_url
            category: "widget",
            name: "l_tabs_open_url",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times small quick action
        /// widget opens firefox for regular search
        static let sQuickActionSearch = CounterMetricType( // generated from widget.s_quick_action_search
            category: "widget",
            name: "s_quick_action_search",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times medium quick action
        /// widget opens firefox for regular search
        static let mQuickActionSearch = CounterMetricType( // generated from widget.m_quick_action_search
            category: "widget",
            name: "m_quick_action_search",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times medium quick action
        /// widget opens firefox for private search
        static let mQuickActionPrivateSearch = CounterMetricType( // generated from widget.m_quick_action_private_search
            category: "widget",
            name: "m_quick_action_private_search",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times medium quick action
        /// widget opens copied links
        static let mQuickActionCopiedLink = CounterMetricType( // generated from widget.m_quick_action_copied_link
            category: "widget",
            name: "m_quick_action_copied_link",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times medium quick action
        /// widget closes private tabs
        static let mQuickActionClosePrivate = CounterMetricType( // generated from widget.m_quick_action_close_private
            category: "widget",
            name: "m_quick_action_close_private",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

        /// Counts how many times user opens top site tabs
        static let mTopSitesWidget = CounterMetricType( // generated from widget.m_top_sites_widget
            category: "widget",
            name: "m_top_sites_widget",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

    enum Experiments {
        enum ExperimentEnrollmentKeys: Int32, ExtraKeys {
            case experimentId = 0
            case experimentName = 1
            case experimentVariant = 2

            public func index() -> Int32 {
                return self.rawValue
            }
        }

        /// Recorded when a preference is changed and includes the
        /// preference that changed as well as the value changed to
        /// recorded in the extra keys.
        static let experimentEnrollment = EventMetricType<ExperimentEnrollmentKeys>( // generated from experiments.experiment_enrollment
            category: "experiments",
            name: "experiment_enrollment",
            sendInPings: ["events"],
            lifetime: .ping,
            disabled: false,
            allowedExtraKeys: ["experiment_id", "experiment_name", "experiment_variant"]
        )

    }

    enum Pocket {
        /// Counts the number of times a user opens
        /// Pocket article from Firefox home Pocket feed
        static let openStory = CounterMetricType( // generated from pocket.open_story
            category: "pocket",
            name: "open_story",
            sendInPings: ["metrics"],
            lifetime: .ping,
            disabled: false
        )

    }

}
