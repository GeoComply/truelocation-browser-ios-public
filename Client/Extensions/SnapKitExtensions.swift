/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

extension UIView {

    var safeArea: ConstraintBasicAttributesDSL {
        return self.safeAreaLayoutGuide.snp
    }
    func scaleWithCurrentScreenSize(_ size: CGFloat, _ originalScreenDimension: CGFloat, _ isX: Bool = true) -> CGFloat {
        return isX ? size * frame.width / originalScreenDimension : size * frame.height / originalScreenDimension
    }
}
