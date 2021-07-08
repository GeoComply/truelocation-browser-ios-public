/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/// The sqlite-backed implementation of the metadata protocol containing images and content for pages.
open class SQLiteMetadata {
    let db: BrowserDB

    required public init(db: BrowserDB) {
        self.db = db
    }
}

extension SQLiteMetadata: Metadata {
    // A cache key is a conveninent, readable identifier for a site in the metadata database which helps
    // with deduping entries for the same page.
    typealias CacheKey = String

    /// Persists the given PageMetadata object to browser.db in the page_metadata table.
    ///
    /// - parameter metadata: Metadata object
    /// - parameter pageURL:  URL of page metadata was fetched from
    /// - parameter expireAt: Expiration/TTL interval for when this metadata should expire at.
    ///
    /// - returns: Deferred on success
    public func storeMetadata(_ metadata: PageMetadata, forPageURL pageURL: URL,
                              expireAt: UInt64) -> Success {
        guard let cacheKey = pageURL.displayURL?.absoluteString else {
            return succeed()
        }

        // Replace any matching cache_key entries if they exist
        let selectUniqueCacheKey = "coalesce((SELECT cache_key FROM page_metadata WHERE cache_key = ?), ?)"
        let args: Args = [cacheKey, cacheKey, metadata.siteURL, metadata.mediaURL, metadata.title,
                          metadata.type, metadata.description, metadata.providerName,
                          expireAt]

        let insert = """
            INSERT OR REPLACE INTO page_metadata (
                cache_key, site_url, media_url, title, type, description, provider_name, expired_at
            ) VALUES (\(selectUniqueCacheKey), ?, ?, ?, ?, ?, ?, ?)
            """

        return self.db.run(insert, withArgs: args)
    }

    /// Purges any metadata items living in page_metadata that are expired.
    ///
    /// - returns: Deferred on success
    public func deleteExpiredMetadata() -> Success {
        let sql = "DELETE FROM page_metadata WHERE expired_at <= (CAST(strftime('%s', 'now') AS LONG)*1000)"
        return self.db.run(sql)
    }

}
