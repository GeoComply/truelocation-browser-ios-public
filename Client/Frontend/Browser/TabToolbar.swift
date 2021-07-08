/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared

protocol TabToolbarProtocol: AnyObject {
    var tabToolbarDelegate: TabToolbarDelegate? { get set }
    var addNewTabButton: ToolbarButton { get }
    var tabsButton: TabsButton { get }
    var appMenuButton: ToolbarButton { get }
    var libraryButton: ToolbarButton { get }
    var forwardButton: ToolbarButton { get }
    var backButton: ToolbarButton { get }
    var multiStateButton: ToolbarButton { get }
    var actionButtons: [Themeable & UIButton] { get }

    func updateBackStatus(_ canGoBack: Bool)
    func updateForwardStatus(_ canGoForward: Bool)
    func updateMiddleButtonState(_ state: MiddleButtonState)
    func updatePageStatus(_ isWebPage: Bool)
    func updateTabCount(_ count: Int, animated: Bool)
    func privateModeBadge(visible: Bool)
    func appMenuBadge(setVisible: Bool)
    func warningMenuBadge(setVisible: Bool)
}

protocol TabToolbarDelegate: AnyObject {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressLibrary(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressSearch(_ tabToolbar: TabToolbarProtocol, button: UIButton)
    func tabToolbarDidPressAddNewTab(_ tabToolbar: TabToolbarProtocol, button: UIButton)
}

enum MiddleButtonState {
    case reload
    case stop
    case search
    case newTab
}

@objcMembers
open class TabToolbarHelper: NSObject {
    let toolbar: TabToolbarProtocol
    let ImageReload = UIImage.templateImageNamed("nav-refresh")
    let ImageStop = UIImage.templateImageNamed("nav-stop")
    let ImageSearch = UIImage.templateImageNamed("search")
    let ImageNewTab = UIImage.templateImageNamed("nav-add")
    
    func setMiddleButtonState(_ state: MiddleButtonState) {
        middleButtonState = state
        switch state {
            case .reload:
                toolbar.multiStateButton.setImage(ImageReload, for: .normal)
                toolbar.multiStateButton.accessibilityLabel = .TabToolbarReloadAccessibilityLabel
            case .stop:
                toolbar.multiStateButton.setImage(ImageStop, for: .normal)
                toolbar.multiStateButton.accessibilityLabel = .TabToolbarStopAccessibilityLabel
            case .search:
                toolbar.multiStateButton.setImage(ImageSearch, for: .normal)
                toolbar.multiStateButton.accessibilityLabel = .TabToolbarSearchAccessibilityLabel
            case .newTab:
                toolbar.multiStateButton.setImage(ImageNewTab, for: .normal)
                toolbar.multiStateButton.accessibilityLabel = .TabToolbarNewTabAccessibilityLabel
        }
    }
    
    // Default state as reload
    var middleButtonState: MiddleButtonState = .reload

    fileprivate func setTheme(forButtons buttons: [Themeable]) {
        buttons.forEach { $0.applyTheme() }
    }

    init(toolbar: TabToolbarProtocol) {
        self.toolbar = toolbar
        super.init()

        toolbar.backButton.setImage(UIImage.templateImageNamed("nav-back"), for: .normal)
        toolbar.backButton.accessibilityLabel = .TabToolbarBackAccessibilityLabel
        let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBack))
        toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
        toolbar.backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)

        toolbar.forwardButton.setImage(UIImage.templateImageNamed("nav-forward"), for: .normal)
        toolbar.forwardButton.accessibilityLabel = .TabToolbarForwardAccessibilityLabel
        let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressForward))
        toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
        toolbar.forwardButton.addTarget(self, action: #selector(didClickForward), for: .touchUpInside)

        toolbar.multiStateButton.setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
        toolbar.multiStateButton.accessibilityLabel = .TabToolbarReloadAccessibilityLabel
        let longPressMultiStateButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressMultiStateButton))
        toolbar.multiStateButton.addGestureRecognizer(longPressMultiStateButton)
        toolbar.multiStateButton.addTarget(self, action: #selector(didPressMultiStateButton), for: .touchUpInside)

        toolbar.tabsButton.addTarget(self, action: #selector(didClickTabs), for: .touchUpInside)
        let longPressGestureTabsButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressTabs))
        toolbar.tabsButton.addGestureRecognizer(longPressGestureTabsButton)

        toolbar.addNewTabButton.setImage(UIImage.templateImageNamed("menu-NewTab"), for: .normal)
        toolbar.addNewTabButton.accessibilityLabel = Strings.AddTabAccessibilityLabel
        toolbar.addNewTabButton.addTarget(self, action: #selector(didClickAddNewTab), for: .touchUpInside)
        toolbar.addNewTabButton.accessibilityIdentifier = "TabToolbar.addNewTabButton"
        
        toolbar.appMenuButton.contentMode = .center
        toolbar.appMenuButton.setImage(UIImage.templateImageNamed("nav-menu"), for: .normal)
        toolbar.appMenuButton.accessibilityLabel = Strings.AppMenuButtonAccessibilityLabel
        toolbar.appMenuButton.addTarget(self, action: #selector(didClickMenu), for: .touchUpInside)
        toolbar.appMenuButton.accessibilityIdentifier = "TabToolbar.menuButton"

        toolbar.libraryButton.contentMode = .center
        toolbar.libraryButton.setImage(UIImage.templateImageNamed("menu-library"), for: .normal)
        toolbar.libraryButton.accessibilityLabel = Strings.AppMenuButtonAccessibilityLabel
        toolbar.libraryButton.addTarget(self, action: #selector(didClickLibrary), for: .touchUpInside)
        toolbar.libraryButton.accessibilityIdentifier = "TabToolbar.libraryButton"
        setTheme(forButtons: toolbar.actionButtons)
    }

    func didClickBack() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
    }

    func didLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
        }
    }

    func didClickTabs() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func didLongPressTabs(_ recognizer: UILongPressGestureRecognizer) {
        toolbar.tabToolbarDelegate?.tabToolbarDidLongPressTabs(toolbar, button: toolbar.tabsButton)
    }

    func didClickForward() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
    }

    func didLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
        }
    }

    func didClickMenu() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar, button: toolbar.appMenuButton)
    }

    func didClickLibrary() {
        toolbar.tabToolbarDelegate?.tabToolbarDidPressLibrary(toolbar, button: toolbar.appMenuButton)
    }
    
    func didClickAddNewTab() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .addNewTabButton)
        toolbar.tabToolbarDelegate?.tabToolbarDidPressAddNewTab(toolbar, button: toolbar.addNewTabButton)
    }

    func didPressMultiStateButton() {
        switch middleButtonState {
        case .reload:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressReload(toolbar, button: toolbar.multiStateButton)
        case .search:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .startSearchButton)
            toolbar.tabToolbarDelegate?.tabToolbarDidPressSearch(toolbar, button: toolbar.multiStateButton)
        case .newTab:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressAddNewTab(toolbar, button: toolbar.addNewTabButton)
        case .stop:
            toolbar.tabToolbarDelegate?.tabToolbarDidPressStop(toolbar, button: toolbar.multiStateButton)
        }
    }

    func didLongPressMultiStateButton(_ recognizer: UILongPressGestureRecognizer) {
        switch middleButtonState {
        case .search, .newTab:
            return
        default:
            if recognizer.state == .began {
                toolbar.tabToolbarDelegate?.tabToolbarDidLongPressReload(toolbar, button: toolbar.multiStateButton)
            }
        }
    }
}

class ToolbarButton: UIButton {
    var selectedTintColor: UIColor!
    var unselectedTintColor: UIColor!
    var disabledTintColor = UIColor.Photon.Grey50

    // Optionally can associate a separator line that hide/shows along with the button
    weak var separatorLine: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustsImageWhenHighlighted = false
        selectedTintColor = tintColor
        unselectedTintColor = tintColor
        imageView?.contentMode = .scaleAspectFit
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var isHighlighted: Bool {
        didSet {
            self.tintColor = isHighlighted ? selectedTintColor : unselectedTintColor
        }
    }

    override open var isEnabled: Bool {
        didSet {
            self.tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        }
    }

    override var tintColor: UIColor! {
        didSet {
            self.imageView?.tintColor = self.tintColor
        }
    }

    override var isHidden: Bool {
        didSet {
            separatorLine?.isHidden = isHidden
        }
    }
}

extension ToolbarButton: Themeable {
    func applyTheme() {
        selectedTintColor = UIColor.theme.toolbarButton.selectedTint
        disabledTintColor = UIColor.theme.toolbarButton.disabledTint
        unselectedTintColor = UIColor.theme.browser.tint
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        imageView?.tintColor = tintColor
    }
}

class TabToolbar: UIView {
    weak var tabToolbarDelegate: TabToolbarDelegate?

    let tabsButton = TabsButton()
    let addNewTabButton = ToolbarButton()
    let appMenuButton = ToolbarButton()
    let libraryButton = ToolbarButton()
    let forwardButton = ToolbarButton()
    let backButton = ToolbarButton()
    let multiStateButton = ToolbarButton()
    let actionButtons: [Themeable & UIButton]

    fileprivate let privateModeBadge = BadgeWithBackdrop(imageName: "privateModeBadge", backdropCircleColor: UIColor.Defaults.MobilePrivatePurple)
    fileprivate let appMenuBadge = BadgeWithBackdrop(imageName: "menuBadge")
    fileprivate let warningMenuBadge = BadgeWithBackdrop(imageName: "menuWarning", imageMask: "warning-mask")

    var helper: TabToolbarHelper?
    private let contentView = UIStackView()

    fileprivate override init(frame: CGRect) {
        actionButtons = [backButton, forwardButton, multiStateButton, addNewTabButton, tabsButton, appMenuButton]
        super.init(frame: frame)
        setupAccessibility()

        addSubview(contentView)
        helper = TabToolbarHelper(toolbar: self)
        addButtons(actionButtons)

        privateModeBadge.add(toParent: contentView)
        appMenuBadge.add(toParent: contentView)
        warningMenuBadge.add(toParent: contentView)

        contentView.axis = .horizontal
        contentView.distribution = .fillEqually
    }

    override func updateConstraints() {
        privateModeBadge.layout(onButton: tabsButton)
        appMenuBadge.layout(onButton: appMenuButton)
        warningMenuBadge.layout(onButton: appMenuButton)

        contentView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self)
            make.bottom.equalTo(self.safeArea.bottom)
        }
        super.updateConstraints()
    }

    private func setupAccessibility() {
        backButton.accessibilityIdentifier = "TabToolbar.backButton"
        forwardButton.accessibilityIdentifier = "TabToolbar.forwardButton"
        multiStateButton.accessibilityIdentifier = "TabToolbar.multiStateButton"
        tabsButton.accessibilityIdentifier = "TabToolbar.tabsButton"
        addNewTabButton.accessibilityIdentifier = "TabToolbar.addNewTabButton"
        appMenuButton.accessibilityIdentifier = "TabToolbar.menuButton"
        accessibilityNavigationStyle = .combined
        accessibilityLabel = .TabToolbarNavigationToolbarAccessibilityLabel
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addButtons(_ buttons: [UIButton]) {
        buttons.forEach { contentView.addArrangedSubview($0) }
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawLine(context, start: .zero, end: CGPoint(x: frame.width, y: 0))
        }
    }

    fileprivate func drawLine(_ context: CGContext, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIColor.black.withAlphaComponent(0.05).cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: start.x, y: start.y))
        context.addLine(to: CGPoint(x: end.x, y: end.y))
        context.strokePath()
    }
}

extension TabToolbar: TabToolbarProtocol {
    func privateModeBadge(visible: Bool) {
        privateModeBadge.show(visible)
    }

    func appMenuBadge(setVisible: Bool) {
        // Warning badges should take priority over the standard badge
        guard warningMenuBadge.badge.isHidden else {
            return
        }

        appMenuBadge.show(setVisible)
    }

    func warningMenuBadge(setVisible: Bool) {
        // Disable other menu badges before showing the warning.
        if !appMenuBadge.badge.isHidden { appMenuBadge.show(false) }
        warningMenuBadge.show(setVisible)
    }

    func updateBackStatus(_ canGoBack: Bool) {
        backButton.isEnabled = canGoBack
    }

    func updateForwardStatus(_ canGoForward: Bool) {
        forwardButton.isEnabled = canGoForward
    }

    func updateMiddleButtonState(_ state: MiddleButtonState) {
        helper?.setMiddleButtonState(state)
    }

    func updatePageStatus(_ isWebPage: Bool) {

    }

    func updateTabCount(_ count: Int, animated: Bool) {
        tabsButton.updateTabCount(count, animated: animated)
    }
}

extension TabToolbar: Themeable, PrivateModeUI {
    func applyTheme() {
        backgroundColor = UIColor.theme.browser.background
        helper?.setTheme(forButtons: actionButtons)

        privateModeBadge.badge.tintBackground(color: UIColor.theme.browser.background)
        appMenuBadge.badge.tintBackground(color: UIColor.theme.browser.background)
        warningMenuBadge.badge.tintBackground(color: UIColor.theme.browser.background)
    }

    func applyUIMode(isPrivate: Bool) {
        privateModeBadge(visible: isPrivate)
    }
}
