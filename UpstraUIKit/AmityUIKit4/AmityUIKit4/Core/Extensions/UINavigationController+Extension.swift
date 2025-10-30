//
//  UINavigationController+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/13/24.
//

import UIKit

extension UINavigationController {
    enum _UINavigationControllerAnimation {
        case `default`, presentation
    }
    
    func pushViewController(_ viewController: UIViewController, animation: _UINavigationControllerAnimation = .default) {
        switch animation {
        case .default:
            self.pushViewController(viewController, animated: true)
            
        case .presentation:
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .moveIn
            transition.subtype = .fromTop
           
            // Apply the transition to the navigation controller's view layer
            self.view.layer.add(transition, forKey: kCATransition)
            
            // Push the view controller without animation, since the custom transition will handle it
            self.pushViewController(viewController, animated: false)
        }
        
    }
    
    func popViewController(animation: _UINavigationControllerAnimation = .default) {
        switch animation {
        case .default:
            self.popViewController(animated: true)
            
        case .presentation:
            let transition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .reveal
            transition.subtype = .fromBottom
            
            // Apply the transition to the navigation controller's view layer
            self.view.layer.add(transition, forKey: kCATransition)
            
            // Pop the top view controller without animation, since the custom transition will handle it
            self.popViewController(animated: false)
        }
    }
    
    @discardableResult
    func popToViewController<Page: AmityPageView>(_ page: Page.Type, animated: Bool) -> AmitySwiftUIHostingController<Page>? {
        guard let vc = self.viewControllers.last(where: { $0 is AmitySwiftUIHostingController<Page> }) else { return nil }
        popToViewController(vc, animated: animated)
        return vc as? AmitySwiftUIHostingController<Page>
    }
}
