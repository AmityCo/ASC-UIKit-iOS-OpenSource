//
//  UIApplication+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import UIKit

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    // This function will rewind the view controller stack to the specified view controller type
    // It will dismiss or pop view controllers until it finds the desired one
    class func rewind(to: UIViewController.Type, completion: ((UIViewController?) -> Void)? = nil) {
        guard let topVC = UIApplication.topViewController() else {
            completion?(nil)
            return
        }
        
        if topVC.isKind(of: to) {
            completion?(topVC)
            return
        }
        
        // Dismiss or pop, then recursively call again
        topVC.dismissOrPop(animated: false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                rewind(to: to, completion: completion)
            }
        }
    }
}
