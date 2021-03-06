//
//  BaseNavigationController.swift
//  LightSmartLock
//
//  Created by mugua on 2019/11/19.
//  Copyright © 2019 mugua. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    lazy var _navigationDelegate = MyVCNavigationControllerDelegate()
    
    var clearBackTitle: Bool = true
    
    @available(iOS 13.0, *)
    private lazy var navBarAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = UIColor.clear
        return appearance
    }()
    
    @available(iOS 13.0, *)
    private lazy var buttonAppearance: UIBarButtonItemAppearance = {
        let appearance = UIBarButtonItemAppearance()
        return appearance
    }()
    
    private var previousViewController: UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[viewControllers.count - 2]
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        controlClearBackTitle(vc: viewController)
        if self.viewControllers.count == 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        
        if let style = viewController as? NavigationSettingStyle {
            self.setNavigationStyle(style)
        }
        
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if let style = self.previousViewController as? NavigationSettingStyle {
            self.setNavigationStyle(style)
        }
        
        return super.popViewController(animated: animated)
    }
  
    
    override open func show(_ vc: UIViewController, sender: Any?) {
        controlClearBackTitle(vc: vc)
        if let style = vc as? NavigationSettingStyle {
            self.setNavigationStyle(style)
        }
        
        if self.viewControllers.count == 1 {
            vc.hidesBottomBarWhenPushed = true
        }
        
        super.show(vc, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        
        self.delegate = _navigationDelegate
    }
    
}

extension BaseNavigationController {
    
    fileprivate func commonInit() {
        
        navigationBar.shadowImage = UIImage(color: .clear, size: CGSize(width: UIScreen.main.bounds.width, height: 0.5))
        navigationBar.layer.shadowColor = UIColor.clear.cgColor
        navigationBar.isTranslucent = false
        self.interactivePopGestureRecognizer?.delegate = self
        
        guard let style = topViewController as? NavigationSettingStyle else {
            return
        }
        
        navigationBar.prefersLargeTitles = style.isLargeTitle
        
        if let backgroundColor = style.backgroundColor {
            navigationBar.barTintColor = backgroundColor
        }
        
        if let itemColor = style.itemColor {
            
            navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : itemColor,
                                                      NSAttributedString.Key.font: style.titleFont]
            
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : itemColor], for: .normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : itemColor.withAlphaComponent(0.4)], for: .disabled)
            
            navigationBar.tintColor = itemColor
        }
    }
    
    fileprivate func setNavigationStyle(_ style: NavigationSettingStyle) {
        
        navigationBar.prefersLargeTitles = style.isLargeTitle
        
        if let bgColor = style.backgroundColor {
            if #available(iOS 13.0, *) {
                navBarAppearance.backgroundColor = bgColor
                navigationBar.standardAppearance = navBarAppearance
                navigationBar.scrollEdgeAppearance = navBarAppearance
                navigationBar.compactAppearance = navBarAppearance
                
            } else {
                navigationBar.barTintColor = bgColor
            }
        }
        
        if let itemColor = style.itemColor {
            if #available(iOS 13.0, *) {
                navBarAppearance.titleTextAttributes = [.foregroundColor: itemColor]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: itemColor, .font: style.titleFont]
                buttonAppearance.normal.titleTextAttributes = [.foregroundColor : itemColor]
                buttonAppearance.disabled.titleTextAttributes = [.foregroundColor : itemColor.withAlphaComponent(0.4)]
                navBarAppearance.buttonAppearance = buttonAppearance
                navBarAppearance.backButtonAppearance = buttonAppearance
                navigationBar.standardAppearance = navBarAppearance
                navigationBar.scrollEdgeAppearance = navBarAppearance
                navigationBar.compactAppearance = navBarAppearance
                
            } else {
                navigationBar.tintColor = itemColor
                navigationBar.titleTextAttributes =
                    [.foregroundColor: itemColor]
                navigationBar.largeTitleTextAttributes = [.foregroundColor: itemColor, .font: style.titleFont]
            }
        }
    }
    
    fileprivate func controlClearBackTitle(vc: UIViewController) {
        if clearBackTitle {
            
            let button = UIButton(type: .custom)
            let image = UIImage(named: "back_arrow")?.withRenderingMode(.alwaysTemplate)
            button.setImage(image, for: UIControl.State())
            button.sizeToFit()
            button.contentHorizontalAlignment = .left
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
            button.addTarget(self, action: #selector(popToPreviousVC), for: .touchUpInside)
            guard let style = vc as? NavigationSettingStyle, let naviBkColor = style.backgroundColor else {
                return
            }
            guard let color = UIColor(contrastingBlackOrWhiteColorOn: naviBkColor, isFlat: true) else { return }
            button.tintColor = color
            
        }
    }
    
    @objc func popToPreviousVC() {
        let _ = self.popViewController(animated: true)
    }
}


extension BaseNavigationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.viewControllers.count > 1
    }
}
