/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

open class SQLiteQueue: TabQueue {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    open func addToQueue(_ tab: ShareItem) -> Success {
        let args: Args = [tab.url, tab.title]
        return db.run("INSERT OR IGNORE INTO queue (url, title) VALUES (?, ?)", withArgs: args)
    }

    fileprivate func factory(_ row: SDRow) -> ShareItem {
        return ShareItem(url: row["url"] as! String, title: row["title"] as? String, favicon: nil)
    }

    open func getQueuedTabs() -> Deferred<Maybe<Cursor<ShareItem>>> {
        return db.runQuery("SELECT url, title FROM queue", args: nil, factory: self.factory)
    }

    open func clearQueuedTabs() -> Success {
        return db.run("DELETE FROM queue")
    }
}
