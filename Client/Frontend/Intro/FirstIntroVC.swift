/*************************************************************************
* © 2019-2021 GeoComply Solutions Inc.
* All Rights Reserved.
* NOTICE: All information contained herein is, and remains
* the property of GeoComply Solutions Inc.
* Dissemination, distribution, copying of this information or reproduction
* of this material is strictly forbidden unless prior written permission
* is obtained from GeoComply Solutions Inc.
*/

final class FirstIntroVC: UIViewController {
    
    // MARK: UI & UX Elements
    private var btNext: UIButton!
    private var ivLogoAny: UIView!
    private var ivLogoDark: UIView!
    private var lbLogoDark: UILabel!
    private var lbSubtitle: UILabel!
    private var lbTitle: UILabel!
    private var viewCircleBottom: UIView!
    private var viewLogo: UIView!
    
    // MARK: Constants & Variables
    private var nextPagePressed: (()->())?
    
    init(_ nextPageCallback: (()->())?) {
        super.init(nibName: nil, bundle: nil)
        nextPagePressed = nextPageCallback
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
        setupColorScheme()

    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        
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
        viewLogo = UIView()
        
        lbTitle = UILabel()
        let attrs1 = [NSAttributedString.Key.font : UIFont.openSanRegular()]
        let attrs2 = [NSAttributedString.Key.font : UIFont.openSanBold(size: 20)]
        let attributedString1 = NSMutableAttributedString(string:"Welcome to ", attributes:attrs1)
        let attributedString2 = NSMutableAttributedString(string:"TrueLocation Browser!", attributes:attrs2)
        attributedString1.append(attributedString2)
        lbTitle.adjustsFontSizeToFitWidth = true
        lbTitle.attributedText = attributedString1
        lbTitle.textAlignment = .center
        
        lbSubtitle = UILabel()
        lbSubtitle.font = UIFont.openSanRegular()
        lbSubtitle.textAlignment = .justified
        lbSubtitle.numberOfLines = 2
        lbSubtitle.text = "A Secure Location Verified\nBrowser for E-Commerce."
        
        btNext = UIButton()
        btNext.setTitle("Next", for: .normal)
        btNext.titleLabel?.font = UIFont.openSanRegular(size: 18)
        btNext.clipsToBounds = false
        btNext.layer.cornerRadius = 5
        
        viewCircleBottom = UIView()
        var radius = view.frame.width * 3 / 2
        if UIDevice.current.userInterfaceIdiom == .pad {
            radius = ViewControllerConsts.PreferredSize.IntroViewController.width * 3 / 2
        }
        viewCircleBottom.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
        viewCircleBottom.clipsToBounds = true
        viewCircleBottom.layer.cornerRadius = radius / 2
        
        ivLogoAny = UIImageView(image: UIImage(named: "true-location"))
        ivLogoAny.contentMode = .scaleAspectFit
        
        ivLogoDark = UIImageView(image: UIImage(named: "splash"))
        ivLogoDark.contentMode = .scaleAspectFit
        
        lbLogoDark = UILabel()
        lbLogoDark.text = "TrueLocation"
        lbLogoDark.font = UIFont.fireSanBold(size: 36)
        
        viewLogo.addSubview(ivLogoDark)
        viewLogo.addSubview(ivLogoAny)
        viewLogo.addSubview(lbLogoDark)
        
        view.addSubview(btNext)
        view.addSubview(lbSubtitle)
        view.addSubview(lbTitle)
        view.addSubview(viewCircleBottom)
        view.addSubview(viewLogo)
        
        viewLogo.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view)
            $0.height.equalTo(view.scaleWithCurrentScreenSize(316,736,false))
        }
        
        lbTitle.snp.makeConstraints {
            $0.top.equalTo(viewLogo.snp.bottom)
            $0.leading.greaterThanOrEqualTo(view).offset(view.scaleWithCurrentScreenSize(5, 414))
            $0.trailing.greaterThanOrEqualTo(view).offset(-view.scaleWithCurrentScreenSize(5, 414))
            $0.centerX.equalTo(view)
        }
        
        lbSubtitle.snp.makeConstraints {
            $0.top.equalTo(lbTitle.snp.bottom).offset(view.scaleWithCurrentScreenSize(37,736,false))
            $0.centerX.equalTo(view)
        }
        
        btNext.snp.makeConstraints {
            $0.top.equalTo(lbSubtitle.snp.bottom).offset(view.scaleWithCurrentScreenSize(66,736,false))
            $0.width.equalTo(view.scaleWithCurrentScreenSize(90.25,414))
            $0.height.equalTo(view.scaleWithCurrentScreenSize(32,736,false))
            $0.centerX.equalTo(view)
        }
        
        ivLogoAny.snp.makeConstraints {
            $0.width.equalTo(view.scaleWithCurrentScreenSize(226,414))
            $0.height.equalTo(view.scaleWithCurrentScreenSize(159,736,false))
            $0.top.equalTo(viewLogo).offset(view.scaleWithCurrentScreenSize(96,736,false))
            $0.centerX.equalTo(viewLogo)
        }
        
        ivLogoDark.snp.makeConstraints {
            $0.width.height.equalTo(view.scaleWithCurrentScreenSize(130,414))
            $0.top.equalTo(viewLogo).offset(view.scaleWithCurrentScreenSize(96,736,false))
            $0.centerX.equalTo(viewLogo)
        }
        
        lbLogoDark.snp.makeConstraints {
            $0.top.equalTo(ivLogoDark.snp.bottom)
            $0.centerX.equalTo(viewLogo)
        }
        
        viewCircleBottom.snp.makeConstraints {
            $0.width.height.equalTo(radius)
            $0.top.equalTo(view.snp.bottom).offset(-viewCircleBottom.frame.width/4)
            $0.centerX.equalTo(view)
        }
        
        btNext.addTarget(self, action: #selector(btNextPressed), for: .touchUpInside)
    }
    
    @objc private func btNextPressed() {
        nextPagePressed?()
    }
    
    private func setupColorScheme() {
        func setupForLightAndNormalMode() {
            ivLogoAny.isHidden = false
            lbLogoDark.isHidden = true
            ivLogoDark.isHidden = true
            
            btNext.setTitleColor(UIColor(rgb:0x243665), for: .normal)
            btNext.backgroundColor = UIColor(rgb:0x59CEEA)
            lbTitle.textColor = UIColor(rgb:0x243665)
            lbSubtitle.textColor = UIColor(rgb:0x243665)
            viewCircleBottom.backgroundColor = UIColor(rgb:0x59CEEA)
        }
        
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                ivLogoAny.isHidden = true
                lbLogoDark.isHidden = false
                ivLogoDark.isHidden = false

                btNext.setTitleColor(.black, for: .normal)
                btNext.backgroundColor = .white
                lbLogoDark.textColor = .white
                lbTitle.textColor = .white
                lbSubtitle.textColor = .white
                viewCircleBottom.backgroundColor = .white
            } else {
                setupForLightAndNormalMode()
            }
        } else {
            setupForLightAndNormalMode()
        }
    }
}
