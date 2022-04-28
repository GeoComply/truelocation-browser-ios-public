/*************************************************************************
* © 2019-2021 GeoComply Solutions Inc.
* All Rights Reserved.
* NOTICE: All information contained herein is, and remains
* the property of GeoComply Solutions Inc.
* Dissemination, distribution, copying of this information or reproduction
* of this material is strictly forbidden unless prior written permission
* is obtained from GeoComply Solutions Inc.
*/

import SnapKit

class OobeePageVC: UIPageViewController {
    
    // MARK: UI & UX Elements
    var pages: [UIViewController]!
    let pageControl = SnakePageControl()
    var dissmissCallback: (() -> ())?
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        view.addSubview(pageControl)
        pageControl.indicatorPadding = 20
        pageControl.indicatorRadius = 4
        pageControl.tag = 1
        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(view.snp.bottom).offset(-63)
            $0.centerX.equalTo(view)
        }
        pageControl.pageCount = 3
        pageControl.activeTint = UIColor(rgb: 0x243665)
        pageControl.inactiveTint = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let subViews = view.subviews
        guard let scrollView = (subViews.first { $0 is UIScrollView }) else { return }
        scrollView.frame = view.bounds
    }
    
    func setupPages() {
        let firstIntroVC = FirstIntroVC(nextPage)
        firstIntroVC.view.frame = view.frame
        let secondIntroVC = SecondIntroVC(nextPage)
        secondIntroVC.view.frame = view.frame
        let thirdIntroVC = ThirdIntroVC(dissmiss)
        thirdIntroVC.view.frame = view.frame
        pages = [firstIntroVC, secondIntroVC, thirdIntroVC]
        setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
        dataSource = self
        delegate = self
    }
    
    func nextPage() {
        pageControl.progress = pageControl.progress + 1
        goToNextPage()
    }
    
    func dissmiss() {
        dissmissCallback?()
    }
}

// MARK: UIPageViewControllerDataSource
extension OobeePageVC: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        for (i, vc) in pages.enumerated() {
            if vc == viewController && i > 0 {
                return pages[i - 1]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        for (i, vc) in pages.enumerated() {
            if vc == viewController && i < pages.count - 1 {
                return pages[i + 1]
            }
        }
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
}

// MARK: UIPageViewControllerDelegate
extension OobeePageVC: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let selectedVC = pageViewController.viewControllers?.first else { return }
        for (i, vc) in pages.enumerated() {
            if selectedVC === vc {
                pageControl.progress = CGFloat(i)
                break
            }
        } 
    }
}

fileprivate extension UIPageViewController {
    func goToNextPage() {
        guard let currentViewController = self.viewControllers?.first, let nextViewController = dataSource?.pageViewController( self, viewControllerAfter: currentViewController ) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
    }
}
