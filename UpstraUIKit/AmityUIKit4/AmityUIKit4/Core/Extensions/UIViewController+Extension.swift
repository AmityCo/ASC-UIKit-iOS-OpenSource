//
//  UIViewController+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/27/25.
//

import UIKit

extension UIViewController {
    func dismissOrPop(animated: Bool = true, completion: (() -> Void)? = nil) {
        if presentingViewController != nil {
            // This view controller was presented modally
            dismiss(animated: animated, completion: completion)
        } else if let navigationController = navigationController,
                  navigationController.viewControllers.count > 1 {
            // This view controller is in a navigation stack and not the root
            navigationController.popViewController(animated: animated)
            // Call completion after pop animation
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.35 : 0)) {
                    completion()
                }
            }
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
}
