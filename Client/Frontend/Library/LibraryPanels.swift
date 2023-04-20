// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import Storage

protocol LibraryPanel: NotificationThemeable {
    var libraryPanelDelegate: LibraryPanelDelegate? { get set }
}

struct LibraryPanelUX {
    static let EmptyTabContentOffset = -180
}

protocol LibraryPanelDelegate: AnyObject {
    func libraryPanelDidRequestToSignIn()
    func libraryPanelDidRequestToCreateAccount()
    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
    func libraryPanel(didSelectURL url: URL, visitType: VisitType)
    func libraryPanel(didSelectURLString url: String, visitType: VisitType)
}

enum LibraryPanelType: Int, CaseIterable {
    case bookmarks = 0
    case history = 1
    case downloads = 2
    case readingList = 3
    
    var title: String {
        switch self {
        case .bookmarks:
            return .AppMenuBookmarksTitleString
        case .history:
            return .AppMenuHistoryTitleString
        case .downloads:
            return .AppMenuDownloadsTitleString
        case .readingList:
            return .AppMenuReadingListTitleString
        }
    }
}

/**
 * Data for identifying and constructing a LibraryPanel.
 */
class LibraryPanelDescriptor {
    var viewController: UIViewController?
    var navigationController: UINavigationController?

    fileprivate let makeViewController: (_ profile: Profile, _ tabManager: TabManager) -> UIViewController
    fileprivate let profile: Profile
    fileprivate let tabManager: TabManager

    let imageName: String
    let activeImageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    init(makeViewController: @escaping ((_ profile: Profile, _ tabManager: TabManager) -> UIViewController), profile: Profile, tabManager: TabManager, imageName: String, accessibilityLabel: String, accessibilityIdentifier: String) {
        self.makeViewController = makeViewController
        self.profile = profile
        self.tabManager = tabManager
        self.imageName = "panelIcon" + imageName
        self.activeImageName = self.imageName + "-active"
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func setup() {
        guard viewController == nil else { return }
        let viewController = makeViewController(profile, tabManager)
        self.viewController = viewController
        navigationController = ThemedNavigationController(rootViewController: viewController)
    }
}

class LibraryPanels {
    fileprivate let profile: Profile
    fileprivate let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    lazy var enabledPanels = [
        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager  in
                return BookmarksPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            imageName: "Bookmarks",
            accessibilityLabel: .LibraryPanelBookmarksAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.Bookmarks"),

        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return HistoryPanel(profile: profile, tabManager: tabManager)
            },
            profile: profile,
            tabManager: tabManager,
            imageName: "History",
            accessibilityLabel: .LibraryPanelHistoryAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.History"),

        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return DownloadsPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            imageName: "Downloads",
            accessibilityLabel: .LibraryPanelDownloadsAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.Downloads"),
        
        // GG Overriden // Reading List, old TLB removed but keep showing in list. 0a6a1c90a15c3b9d47b48213a9e9ef466aaad537
        LibraryPanelDescriptor(
            makeViewController: { profile, tabManager in
                return ReadingListPanel(profile: profile)
            },
            profile: profile,
            tabManager: tabManager,
            imageName: "ReadingList",
            accessibilityLabel: .LibraryPanelReadingListAccessibilityLabel,
            accessibilityIdentifier: "LibraryPanels.ReadingList")
    ]
}
