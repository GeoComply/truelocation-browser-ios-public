// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A protocol for any object to inherit the `cellIdentifier` string property.
///
/// Intended for use with views that must register/deque cells, this allows
/// a cleaner impelementation of the cell identifier by bypassing it being
/// hardcoded which is prone to error.
///
/// As defined in the extensions, this will generally, where adhering to the
/// implemented conditions, return a string describing `self`.
protocol ReusableCell: AnyObject {
    static var cellIdentifier: String { get }
}

extension ReusableCell where Self: UICollectionViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}

extension ReusableCell where Self: UITableViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}
