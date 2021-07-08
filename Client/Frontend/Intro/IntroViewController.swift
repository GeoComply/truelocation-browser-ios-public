/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

enum FxALoginFlow {
    case emailFlow
    case signUpFlow
}

protocol IntroViewControllerDelegate: AnyObject {
    func introViewControllerDidFinish(_ introViewController: IntroViewController, showLoginFlow: FxALoginFlow?)
}

class IntroViewController: UIViewController {
    // private var
    // Private views
    private var pageVC: OobeePageVC!
    weak var delegate: IntroViewControllerDelegate?
    
    var currentPage = 0
    
    // Closure delegate
    var didFinishClosure: ((IntroViewController, FxAPageType?) -> Void)?
    
    // MARK: Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
        
        UIView.animate(withDuration: 0.1) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    // MARK: View setup
    private func initialViewSetup() {
        setupPageVC()
    }
    
    private func setupPageVC() {
        pageVC = OobeePageVC()
        pageVC.dissmissCallback = { [weak self] in
            self?.pageVC.view.removeFromSuperview()
            self?.pageVC.removeFromParent()
            self?.view.backgroundColor = UIColor.white
            self?.startBrowsing()
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageVC.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        } else {
            pageVC.view.frame = view.bounds
        }
        if #available(iOS 13, *) {
            pageVC.view.backgroundColor = .systemBackground
        } else {
            pageVC.view.backgroundColor = .white
        }
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        pageVC.setupPages()
        pageVC.view.center = view.center
    }
    
    @objc func startBrowsing() {
        delegate?.introViewControllerDidFinish(self, showLoginFlow: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboarding, extras: ["slide-num": currentPage])
    }
}

// MARK: UIViewController setup
extension IntroViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}
