// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import Shared

protocol LibraryPanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension LibraryPanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
    
    func getRecentlyClosedTabContexMenuActions(for site: Site, recentlyClosedPanelDelegate: RecentlyClosedPanelDelegate?) ->  [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { _ in
            recentlyClosedPanelDelegate?.openRecentlyClosedSiteInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            recentlyClosedPanelDelegate?.openRecentlyClosedSiteInNewTab(siteURL, isPrivate: true)
        }

        return [PhotonRowActions(openInNewTabAction), PhotonRowActions(openInNewPrivateTabAction)]
    }
    
    func getRemoteTabContexMenuActions(for site: Site, remotePanelDelegate: RemotePanelDelegate?) ->  [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { _ in
            remotePanelDelegate?.remotePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }
        /*
        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            remotePanelDelegate?.remotePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [PhotonRowActions(openInNewTabAction), PhotonRowActions(openInNewPrivateTabAction)]
        */
        return [PhotonRowActions(openInNewTabAction)]
    }

    func getDefaultContextMenuActions(for site: Site, libraryPanelDelegate: LibraryPanelDelegate?) -> [PhotonRowActions]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle,
                                                       iconString: ImageIdentifiers.newTab) { _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }.items
        
        /*
        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle,
                                                              iconString: "quick_action_new_private_tab") { _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }.items
        
        return [openInNewTabAction, openInNewPrivateTabAction]
         */
        return [openInNewTabAction]
    }
}
