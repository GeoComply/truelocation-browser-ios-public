// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit
import Shared

protocol TabToolbarProtocol: AnyObject {
    var tabToolbarDelegate: TabToolbarDelegate? { get set }
    var addNewTabButton: ToolbarButton { get }
    var tabsButton: TabsButton { get }
    var appMenuButton: ToolbarButton { get }
    var bookmarksButton: ToolbarButton { get }
    var homeButton: ToolbarButton { get }
    var forwardButton: ToolbarButton { get }
    var backButton: ToolbarButton { get }
    var multiStateButton: ToolbarButton { get }
    var actionButtons: [NotificationThemeable & UIButton] { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateMiddleButtonState(_ state: MiddleButtonState)
    func updatePageStatus(_ isWebPage: Bool)
    func updateTabCount(_ count: Int, animated: Bool)
    func privateModeBadge(visible: Bool)
    func warningMenuBadge(setVisible: Bool)
}

protocol TabToolbarDelegate: AnyObject {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressHome(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressBookmarks(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

enum MiddleButtonState {
    case reload
    case stop
    case search
    case home
}

@objcMembers
open class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol
    let ImageReload = UIImage.templateImageNamed("nav-refresh")
    let ImageStop = UIImage.templateImageNamed("nav-stop")
    let ImageSearch = UIImage.templateImageNamed("search")
    let ImageNewTab = UIImage.templateImageNamed("nav-add")
    let ImageHome = UIImage.templateImageNamed("menu-Home")

    func setMiddleButtonState(_ state: MiddleButtonState) {
        let device = UIDevice.current.userInterfaceIdiom
        switch (state, device) {
        case (.search, _):
            middleButtonState = .search
            toolbar.multiStateButton.setImage(ImageSearch, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarSearchAccessibilityLabel
        case (.reload, .pad):
            middleButtonState = .reload
            toolbar.multiStateButton.setImage(ImageReload, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarReloadAccessibilityLabel
        case (.stop, .pad):
            middleButtonState = .stop
            toolbar.multiStateButton.setImage(ImageStop, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarStopAccessibilityLabel
        default:
            toolbar.multiStateButton.setImage(ImageHome, for: .normal)
            toolbar.multiStateButton.accessibilityLabel = .TabToolbarHomeAccessibilityLabel
            middleButtonState = .home
        }
    }

    // Default state as reload
    var middleButtonState: MiddleButtonState = .home

    func setTheme(forButtons buttons: [NotificationThemeable]) {
        buttons.forEach { $0.applyTheme() }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("nav-back")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        toolbar.backButton.accessibilityLabel = .TabToolbarBackAccessibilityLabel
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBack))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("nav-forward")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        toolbar.forwardButton.accessibilityLabel = .TabToolbarForwardAccessibilityLabel
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressForward))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(didClickForward), for: .touchUpInside)

        if UIDevice.current.userInterfaceIdiom == .phone {
            toolbar.multiStateButton.setImage(UIImage.templateImageNamed("menu-Home"), for: .normal)
        } else {
            toolbar.multiStateButton.setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
        }
        toolbar.multiStateButton.accessibilityLabel = .TabToolbarReloadAccessibilityLabel

        let longPressMultiStateButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressMultiStateButton))
        toolbar.multiStateButton.addGestureRecognizer(longPressMultiStateButton)

        toolbar.multiStateButton.addTarget(self, action: #selector(didPressMultiStateButton), for: .touchUpInside)

        toolbar.tabsButton.addTarget(self, action: #selector(didClickTabs), for: .touchUpInside)
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTabs))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)

        toolbar.addNewTabButton.setImage(UIImage.templateImageNamed("menu-NewTab"), for: .normal)
        toolbar.addNewTabButton.accessibilityLabel = .AddTabAccessibilityLabel
        toolbar.addNewTabButton.addTarget(self, action: #selector(didClickAddNewTab), for: .touchUpInside)
        toolbar.addNewTabButton.accessibilityIdentifier = "TabToolbar.addNewTabButton"

        toolbar.appMenuButton.contentMode = .center
        toolbar.appMenuButton.setImage(UIImage.templateImageNamed("nav-menu"), for: .normal)
        toolbar.appMenuButton.accessibilityLabel = .AppMenuButtonAccessibilityLabel
        toolbar.appMenuButton.addTarget(self, action: #selector(didClickMenu), for: .touchUpInside)
        toolbar.appMenuButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.settingsMenuButton

        toolbar.homeButton.contentMode = .center
        toolbar.homeButton.setImage(UIImage.templateImageNamed("menu-Home"), for: .normal)
        toolbar.homeButton.accessibilityLabel = .AppMenuButtonAccessibilityLabel
        toolbar.homeButton.addTarget(self, action: #selector(didClickHome), for: .touchUpInside)
        toolbar.homeButton.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.homeButton
        
        toolbar.bookmarksButton.contentMode = .center
        toolbar.bookmarksButton.setImage(UIImage.templateImageNamed(ImageIdentifiers.bookmarks), for: .normal)
        toolbar.bookmarksButton.accessibilityLabel = .AppMenuButtonAccessibilityLabel
        toolbar.bookmarksButton.addTarget(self, action: #selector(didClickLibrary), for: .touchUpInside)
        toolbar.bookmarksButton.accessibilityIdentifier = "TabToolbar.libraryButton"
        setTheme(forButtons: toolbar.actionButtons)
    }

    func didClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .navigateTabHistoryBack)
    }

    func didLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .navigateTabHistoryBack)
        }
    }

    func didClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func didLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.tabsButton)
        }
    }

    func didClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .navigateTabHistoryForward)
    }

    func didLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .navigateTabHistoryForward)
        }
    }

    func didClickMenu() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.appMenuButton)
    }

    func didClickHome() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressHome(toolbar, button: toolbar.appMenuButton)
    }

    func didClickLibrary() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBookmarks(toolbar, button: toolbar.appMenuButton)
    }

    func didClickAddNewTab() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .addNewTabButton)
        toolbar.tabToolbarDelegate?.tabToolbarDidPressAddNewTab(toolbar, button: toolbar.addNewTabButton)
    }

    func didPressMultiStateButton() {
        switch middleButtonState {
        case .home:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressHome(toolbar, button: toolbar.multiStateButton)
        case .search:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .startSearchButton)
            toolbar.tabToolbarDelegate?.tabToolbarDidPressSearch(toolbar, button: toolbar.multiStateButton)
        case .stop:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressStop(toolbar, button: toolbar.multiStateButton)
        case .reload:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressReload(toolbar, button: toolbar.multiStateButton)
        }
    }

    func didLongPressMultiStateButton(_ recognizer: UILongPressGestureRecognizer) {
        switch middleButtonState {
        case .search, .home:
            return
        default:
            if recognizer.state == .began {
                toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.multiStateButton)
            }
        }
    }
}
