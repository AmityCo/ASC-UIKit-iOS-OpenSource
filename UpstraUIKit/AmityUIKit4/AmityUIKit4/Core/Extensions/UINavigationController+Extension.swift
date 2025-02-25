//
//  UINavigationController+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/13/24.
//

import UIKit

extension UINavigationController {
    public enum UINavigationControllerAnimation {
        case `default`, presentation
    }
    
    public func pushViewController(_ viewController: UIViewController, animation: UINavigationControllerAnimation = .default) {
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
    
    public func popViewController(animation: UINavigationControllerAnimation = .default) {
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
}
