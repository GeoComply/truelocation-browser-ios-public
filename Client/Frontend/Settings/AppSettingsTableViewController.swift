/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Account

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    var showContentBlockerSetting = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Title in the settings view controller title bar")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: .done,
            target: navigationController, action: #selector((navigationController as! ThemedNavigationController).done))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"

        // Refresh the user's FxA profile upon viewing settings. This will update their avatar,
        // display name, etc.
        // profile.rustFxA.refreshProfile()

        if showContentBlockerSetting {
            let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
            viewController.profile = profile
            viewController.tabManager = tabManager
            navigationController?.pushViewController(viewController, animated: false)
            // Add a done button from this view
            viewController.navigationItem.rightBarButtonItem = navigationItem.rightBarButtonItem
        }
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()
        
        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")
        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            SearchSetting(settings: self),
            NewTabPageSetting(settings: self),
            HomeSetting(settings: self),
//            OpenWithSetting(settings: self),
//            ThemeSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
                        titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
        ]
//        if #available(iOS 12.0, *) {
//            generalSettings.insert(SiriPageSetting(settings: self), at: 5)
//        }
        
        generalSettings += [
            BoolSetting(prefs: prefs, prefKey: "showClipboardBar", defaultValue: false,
                        titleText: Strings.SettingsOfferClipboardBarTitle,
                        statusText: Strings.SettingsOfferClipboardBarStatus),
            BoolSetting(prefs: prefs, prefKey: PrefsKeys.ContextMenuShowLinkPreviews, defaultValue: true,
                        titleText: Strings.SettingsShowLinkPreviewsTitle,
                        statusText: Strings.SettingsShowLinkPreviewsStatus)
        ]
        
//        if #available(iOS 14.0, *) {
//            settings += [
//                SettingSection(footerTitle: NSAttributedString(string: String.DefaultBrowserCardDescription), children: [DefaultBrowserSetting()])
//            ]
//        }
        
        settings += [ SettingSection(title: NSAttributedString(string: Strings.SettingsGeneralSectionTitle), children: generalSettings)]
        
        var privacySettings = [Setting]()
        
        
        privacySettings.append(ClearPrivateDataSetting(settings: self))
        
//        privacySettings += [
//            BoolSetting(prefs: prefs,
//                        prefKey: "settings.closePrivateTabs",
//                        defaultValue: false,
//                        titleText: .AppSettingsClosePrivateTabsTitle,
//                        statusText: .AppSettingsClosePrivateTabsDescription)
//        ]
        
        privacySettings.append(ContentBlockerSetting(settings: self))
        
        privacySettings.append(PrivacyPolicySetting())
        privacySettings.append(TermsOfUseSetting())
        
        settings += [
            SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
//            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [SendFeedbackSetting()]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
//                ExportBrowserDataSetting(settings: self),
//                ExportLogDataSetting(settings: self),
//                DeleteExportedDataSetting(settings: self),
//                ForceCrashSetting(settings: self),
//                SlowTheDatabase(settings: self),
//                SentryIDSetting(settings: self),
            ])]
        
        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }
}
