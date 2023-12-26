// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

enum FxALoginFlow {
    case emailFlow
    case signUpFlow
}

protocol IntroViewControllerDelegate: AnyObject {
    func introViewControllerDidFinish(_ introViewController: IntroViewController, showLoginFlow: FxALoginFlow?)
}

class IntroViewController: UIViewController, OnViewDismissable {
    var onViewDismissed: (() -> Void)? = nil
    // private var
    // Private views
    /*
    private lazy var welcomeCard: IntroScreenWelcomeView = {
        let welcomeCardView = IntroScreenWelcomeView()
        welcomeCardView.translatesAutoresizingMaskIntoConstraints = false
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()
    private lazy var syncCard: IntroScreenSyncView = {
        let syncCardView = IntroScreenSyncView()
        syncCardView.translatesAutoresizingMaskIntoConstraints = false
        syncCardView.clipsToBounds = true
        return syncCardView
    }()
     */
    // Closure delegate
    var didFinishClosure: ((IntroViewController, FxAPageType?) -> Void)?
    
    private var pageVC: OobeePageVC!
    weak var delegate: IntroViewControllerDelegate?
    
    // MARK: Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        pageVC = nil
        didFinishClosure = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }
    
    // MARK: View setup
    private func initialViewSetup() {
        //setupIntroView()
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
            pageVC.view.frame = CGRect(origin: .zero, size: ViewControllerConsts.PreferredSize.IntroViewController) // CGRect(x: 0, y: 0, width: 375, height: 667)
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
        
        // Fix size on ipad
        pageVC.view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }
    
    @objc func startBrowsing() {
        delegate?.introViewControllerDidFinish(self, showLoginFlow: nil)
        //TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboarding, extras: ["slide-num": currentPage])
        //self.didFinishClosure?(self, nil)
    }
    
    //onboarding intro view
    /*
    private func setupIntroView() {
        // Initialize
        view.addSubview(syncCard)
        view.addSubview(welcomeCard)
        
        // Constraints
        setupWelcomeCard()
        setupSyncCard()
    }
    
    private func setupWelcomeCard() {
        NSLayoutConstraint.activate([
            welcomeCard.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomeCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            welcomeCard.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Buton action closures
        // Next button action
        welcomeCard.nextClosure = {
            UIView.animate(withDuration: 0.3, animations: {
                self.welcomeCard.alpha = 0
            }) { _ in
                self.welcomeCard.isHidden = true
                TelemetryWrapper.recordEvent(category: .action, method: .view, object: .syncScreenView)
            }
        }
        // Close button action
        welcomeCard.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
        // Sign in button closure
        welcomeCard.signInClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
        // Sign up button closure
        welcomeCard.signUpClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
    
    private func setupSyncCard() {
        NSLayoutConstraint.activate([
            syncCard.topAnchor.constraint(equalTo: view.topAnchor),
            syncCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            syncCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            syncCard.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        // Start browsing button action
        syncCard.startBrowsing = {
            self.didFinishClosure?(self, nil)
        }
        // Sign-up browsing button action
        syncCard.signUp = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
     */
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
