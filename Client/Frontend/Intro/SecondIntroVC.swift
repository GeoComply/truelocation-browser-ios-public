/*************************************************************************
* © 2019-2021 GeoComply Solutions Inc.
* All Rights Reserved.
* NOTICE: All information contained herein is, and remains
* the property of GeoComply Solutions Inc.
* Dissemination, distribution, copying of this information or reproduction
* of this material is strictly forbidden unless prior written permission
* is obtained from GeoComply Solutions Inc.
*/

import CoreLocation
import Shared

final class SecondIntroVC: UIViewController {
    
    // MARK: UI & UX Elements
    private var btNext: UIButton!
    private var lbSubtitle: UILabel!
    private var lbTitle: UILabel!
    private var pageControl: UIPageControl!
    private var ivLogo: UIImageView!
    private var viewCircleBottom: UIView!
    
    // MARK: Constants & Variables
    fileprivate var locationManager: CLLocationManager?
    fileprivate var timeRequestAlways: CFAbsoluteTime = 0
    
    private var nextPagePressed: (()->())?
    
    init(_ nextPageCallback: (()->())?) {
        super.init(nibName: nil, bundle: nil)
        nextPagePressed = nextPageCallback
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if #available(iOS 13.4, *) {
            deinitLocationManager()
            endTimerWaitRequestAlways()
        }else {
            locationManager = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
        setupColorScheme()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 13.4, *) {
            deinitLocationManager()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            guard traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle else { return }
            setupColorScheme()
        }
    }
    
    private func setupView() {
        guard view.subviews.count == 0 else { return }
        ivLogo = UIImageView(image: UIImage(named: "true-location-logo"))
        ivLogo.alpha = 0.6
        ivLogo.contentMode = .scaleToFill
        
        lbTitle = UILabel()
        lbTitle.font = UIFont.openSanRegular(size:17)
        lbTitle.textAlignment = .center
        lbTitle.numberOfLines = 4
        lbTitle.adjustsFontSizeToFitWidth = true
        lbTitle.minimumScaleFactor = 0.5
        lbTitle.text = "You must enable Location\nServices on your device to use\nthe TrueLocation Browser\nsupported websites."
        
        lbSubtitle = UILabel()
        let attrs1 = [NSAttributedString.Key.font : UIFont.openSanRegular(size: 17)]
        let attributedString1 = NSMutableAttributedString(string:"Please allow Location Service access\non the pop-up message.", attributes:attrs1)
        lbSubtitle.attributedText = attributedString1
        lbSubtitle.textAlignment = .center
        lbSubtitle.numberOfLines = 2
        
        btNext = UIButton()
        btNext.setTitle("Ok, I understand", for: .normal)
        btNext.titleLabel?.font = UIFont.openSanRegular(size: 18)
        btNext.titleLabel?.adjustsFontSizeToFitWidth = true
        btNext.titleLabel?.minimumScaleFactor = 0.2
        btNext.clipsToBounds = false
        btNext.layer.cornerRadius = 5
        
        viewCircleBottom = UIView()
        var radius = view.bounds.width * 3 / 2
        if UIDevice.current.userInterfaceIdiom == .pad {
            radius = ViewControllerConsts.PreferredSize.IntroViewController.width * 3 / 2
        }
        viewCircleBottom.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
        viewCircleBottom.clipsToBounds = true
        viewCircleBottom.layer.cornerRadius = radius / 2
        viewCircleBottom.backgroundColor = UIColor(rgb:0x59CEEA)
        
        view.addSubview(ivLogo)
        view.addSubview(btNext)
        view.addSubview(lbSubtitle)
        view.addSubview(lbTitle)
        view.addSubview(viewCircleBottom)
        
        ivLogo.snp.makeConstraints {
            $0.top.equalTo(view).offset(view.scaleWithCurrentScreenSize(110,736,false))
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(ivLogo.snp.width)
        }
        
        lbTitle.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(view).offset(view.scaleWithCurrentScreenSize(10,414))
            $0.trailing.greaterThanOrEqualTo(view).offset(-view.scaleWithCurrentScreenSize(10,414))
            $0.centerX.equalTo(view)
            $0.top.equalTo(view).offset(view.scaleWithCurrentScreenSize(220,736,false))
        }
        
        lbSubtitle.snp.makeConstraints {
            $0.top.equalTo(lbTitle.snp.bottom).offset(view.scaleWithCurrentScreenSize(24,736,false))
            $0.centerX.equalTo(view)
        }
        
        btNext.snp.makeConstraints {
            $0.top.equalTo(lbSubtitle.snp.bottom).offset(view.scaleWithCurrentScreenSize(40,736,false))
            $0.width.equalTo(view.scaleWithCurrentScreenSize(170.25,414))
            $0.height.equalTo(view.scaleWithCurrentScreenSize(32,736,false))
            $0.centerX.equalTo(view)
        }
        
        viewCircleBottom.snp.makeConstraints {
            $0.width.height.equalTo(radius)
            $0.top.equalTo(view.snp.bottom).offset(-viewCircleBottom.frame.width/4)
            $0.centerX.equalTo(view)
        }
        
        btNext.addTarget(self, action: #selector(requestLocationPermissionPressed), for: .touchUpInside)
    }
    
    @objc private func requestLocationPermissionPressed() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
        }
        
        let status = getCLAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            setDidRequestAlwayLocation(false)
        case .restricted, .denied, .authorizedAlways:
            callCompletedRequestPermission()
            return
        case .authorizedWhenInUse:
            if didRequestAlwayLocation() {
                callCompletedRequestPermission()
                return
            }
        @unknown default:
            callCompletedRequestPermission()
            return
        }
        
        if #available(iOS 13.4, *) {
            if !self.requestAlwaysAuthorizationLocation_iOS13_4_IfNeed(status: status) && status == .notDetermined {
                locationManager?.requestWhenInUseAuthorization()
            }else {
                callCompletedRequestPermission()
            }
        } else {
            self.requestAlwaysAuthorizationLocation()
        }
    }
    
    @available(iOS 13.4, *)
    private func deinitLocationManager() {
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    fileprivate func callCompletedRequestPermission() {
        if #available(iOS 13.4, *) {
            endTimerWaitRequestAlways()
            deinitLocationManager()
        }
        nextPagePressed?()
    }
    
    private func setupColorScheme() {
        func setupForLightAndNormalMode() {
            view.backgroundColor = UIColor(rgb:0xF8F8F8)
            btNext.setTitleColor(UIColor(rgb:0x243665), for: .normal)
            btNext.backgroundColor = UIColor(rgb:0x59CEEA)
            lbTitle.textColor = UIColor(rgb:0x243665)
            lbSubtitle.textColor = UIColor(rgb:0x243665)
            viewCircleBottom.backgroundColor = UIColor(rgb:0x59CEEA)
        }
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                view.backgroundColor = .black
                btNext.setTitleColor(.black, for: .normal)
                btNext.backgroundColor = .white
                lbTitle.textColor = UIColor.white
                lbSubtitle.textColor = UIColor.white
                viewCircleBottom.backgroundColor = .white
            } else {
                setupForLightAndNormalMode()
            }
        } else {
            setupForLightAndNormalMode()
        }
    }
}

// Profile
extension SecondIntroVC {
    func getProfile() -> Profile? {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.profile
        }
        return nil
    }
    
    func didRequestAlwayLocation() -> Bool {
        self.getProfile()?.prefs.boolForKey(AppConstants.PrefDidRequestAlwayLocation) ?? false
    }
    
    func setDidRequestAlwayLocation(_ didRequest: Bool) {
        self.getProfile()?.prefs.setBool(didRequest, forKey: AppConstants.PrefDidRequestAlwayLocation)
    }
}

extension SecondIntroVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #available(iOS 13.4, *) {
            if !self.requestAlwaysAuthorizationLocation_iOS13_4_IfNeed(status: status) && status != .notDetermined{
                callCompletedRequestPermission()
            }
        }else {
            callCompletedRequestPermission()
        }
    }
    
    func getCLAuthorizationStatus() -> CLAuthorizationStatus {
        var status:CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = self.locationManager?.authorizationStatus ?? CLAuthorizationStatus.denied
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        return status
    }
    
    @available(iOS 13.4, *)
    func requestAlwaysAuthorizationLocation_iOS13_4_IfNeed(status:CLAuthorizationStatus) -> Bool {
        // Show "Always Allow" if need.
        if !didRequestAlwayLocation() && status == .authorizedWhenInUse {
            addObserversRequestAuthorization()
            //invalidateTimeCallRequestAlways()
            self.timeRequestAlways = CFAbsoluteTimeGetCurrent()
            self.requestAlwaysAuthorizationLocation()
            return true
        }
        // Don't show.
        return false
    }
    
    func requestAlwaysAuthorizationLocation() {
        self.locationManager?.requestAlwaysAuthorization()
        self.setDidRequestAlwayLocation(true)
    }
    
    @available(iOS 13.4, *)
    @objc private func handleObserverWaitRequestAlways() {
        let oldTime = self.timeRequestAlways
        if oldTime > 0 && (CFAbsoluteTimeGetCurrent() - oldTime < 0.25) {
            callCompletedRequestPermission()
        }else if oldTime > 0 && getCLAuthorizationStatus() == .authorizedWhenInUse {
            callCompletedRequestPermission()
        }else {
            endTimerWaitRequestAlways()
        }
    }
    
    @available(iOS 13.4, *)
    private func invalidateTimeCallRequestAlways() {
        self.timeRequestAlways = 0
    }
    
    @available(iOS 13.4, *)
    @objc private func endTimerWaitRequestAlways() {
        invalidateTimeCallRequestAlways()
        removeObserversRequestAuthorization()
    }
    
    @available(iOS 13.4, *)
    private func addObserversRequestAuthorization() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleObserverWaitRequestAlways), name: UIScene.didActivateNotification, object: nil)
    }
    
    @available(iOS 13.4, *)
    private func removeObserversRequestAuthorization() {
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
    }
}
