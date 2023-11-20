// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

enum InactiveTabStatus: String, Codable {
    case normal
    case inactive
    case shouldBecomeInactive
}

struct InactiveTabStates: Codable {
    var currentState: InactiveTabStatus?
    var nextState: InactiveTabStatus?
}

enum TabUpdateState {
    case coldStart
    case sameSession
}

struct InactiveTabModel: Codable {

    // Contains [TabUUID String : InactiveTabState current or for next launch]
    var tabWithStatus: [String: InactiveTabStates] = [String: InactiveTabStates]()

    static let userDefaults = UserDefaults()

    /// Check to see if we ever ran this feature before, this is mainly
    /// to avoid tabs automatically going to their state on their first ever run
    static var hasRunInactiveTabFeatureBefore: Bool {
        get { return userDefaults.bool(forKey: PrefsKeys.KeyInactiveTabsFirstTimeRun) }
        set(value) { userDefaults.setValue(value, forKey: PrefsKeys.KeyInactiveTabsFirstTimeRun) }
    }

    static func save(tabModel: InactiveTabModel) {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabModel) {
            userDefaults.set(encoded, forKey: PrefsKeys.KeyInactiveTabsModel)
        }
    }

    static func get() -> InactiveTabModel? {
        if let inactiveTabsModel = userDefaults.object(forKey: PrefsKeys.KeyInactiveTabsModel) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let inactiveTabModel = try jsonDecoder.decode(InactiveTabModel.self, from: inactiveTabsModel)
                return inactiveTabModel
            }
            catch {
                print("Error occured")
            }
        }
        return nil
    }

    static func clear() {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
    }
}

class InactiveTabViewModel {
    private var inactiveTabModel = InactiveTabModel()
    private var allTabs = [Tab]()
    private var selectedTab: Tab?
    var inactiveTabs = [Tab]()
    var activeTabs = [Tab]()

    func updateInactiveTabs(with selectedTab: Tab?, tabs: [Tab]) {
        self.allTabs = tabs
        self.selectedTab = selectedTab
        clearAll()
        
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()
        
        let bvc = BrowserViewController.foregroundBVC()
        //First time starting up with this feature we'll have cold start as update state
        //after updating model we can mark tabs that needs to become inactive
        updateModelState(state: bvc.updateState)
        bvc.updateState = bvc.updateState == .coldStart ? .sameSession : bvc.updateState

        updateFilteredTabs()
    }
    
    private func updateModelState(state: TabUpdateState) {
        let currentDate = Date()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
        let day14_Old = Calendar.current.date(byAdding: .day, value: -14, to: noon) ?? Date()
        let defaultOldDay = day14_Old
        
//        let min_Old = Calendar.current.date(byAdding: .minute, value: -1, to: currentDate) ?? Date() // testing only
//        let defaultOldDay = min_Old
        
        let hasRunInactiveTabFeatureBefore = InactiveTabModel.hasRunInactiveTabFeatureBefore
        if hasRunInactiveTabFeatureBefore == false { InactiveTabModel.hasRunInactiveTabFeatureBefore = true }
        
        for tab in self.allTabs {
            //Append selected tab to normal tab as we don't want to remove that
            let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)
            
            // 1. Initializing and assigning an empty inactive tab state to the inactiveTabModel mode
            if inactiveTabModel.tabWithStatus[tab.tabUUID] == nil {
                inactiveTabModel.tabWithStatus[tab.tabUUID] = InactiveTabStates()
            }
            
            // 2. Current tab type from inactive tab model
            // Note:
            //  a) newly assigned inactive tab model will have empty `tabWithStatus`
            //     with nil current and next states
            //  b) an older inactive tab model will have a proper `tabWithStatus`
            let tabType = inactiveTabModel.tabWithStatus[tab.tabUUID]
            
            // 3. All tabs should start with a normal current state if they don't have any current state
            if tabType?.currentState == nil { inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal }

            if tab == selectedTab {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tabType?.nextState == .shouldBecomeInactive && state == .sameSession {
                continue
            } else if tab == selectedTab || tabDate > defaultOldDay || tabTimeStamp == 0 {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tabDate <= defaultOldDay {
                if hasRunInactiveTabFeatureBefore == false {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                } else if state == .coldStart {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .inactive
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = nil
                } else if state == .sameSession && tabType?.currentState != .inactive {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                }
            }
        }
        
        InactiveTabModel.save(tabModel: inactiveTabModel)
    }
    
    private func updateFilteredTabs() {
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()
        clearAll()
        for tab in self.allTabs {
            let status = inactiveTabModel.tabWithStatus[tab.tabUUID]
            if status == nil {
                activeTabs.append(tab)
            } else if let status = status, let currentState = status.currentState {
                addTab(state: currentState, tab: tab)
            }
        }
    }
    
    private func addTab(state: InactiveTabStatus?, tab: Tab) {
        switch state {
        case .inactive:
            inactiveTabs.append(tab)
        case .normal, .none:
            activeTabs.append(tab)
        case .shouldBecomeInactive: break
        }
    }
    
    private func clearAll() {
        activeTabs.removeAll()
        inactiveTabs.removeAll()
    }
}

extension InactiveTabViewModel {
    /// This function returns any tabs that are less than four days old.
    ///
    /// Because the "Jump Back In" and "Inactive Tabs" features are separate features,
    /// it is not a given that a tab has an active/inactive state. Thus, we must
    /// assume that if we want to use active/inactive state, we can do so without
    /// that particular feature being active but still respecting that logic.
    static func getActiveEligibleTabsFrom(_ tabs: [Tab], profile: Profile) -> [Tab] {
        var activeTabs = [Tab]()

        let currentDate = Date()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
        let day14_Old = Calendar.current.date(byAdding: .day, value: -14, to: noon) ?? Date()
        let defaultOldDay = day14_Old
        
        for tab in tabs {
            let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)

            if tabDate > defaultOldDay || tabTimeStamp == 0 {
                activeTabs.append(tab)
            }
        }

        return activeTabs
    }
}
