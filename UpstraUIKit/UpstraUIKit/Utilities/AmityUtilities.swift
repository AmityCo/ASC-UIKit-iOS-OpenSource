//
//  AmityUtilities.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 9/9/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

struct AmityUtilities {
    static func showError() {
        let alertController = UIAlertController(title: "Something wrong", message: "Please try again", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .default, handler: nil))
        UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    static func UINibs(nibName: String) -> UINib {
        return UINib(nibName: nibName, bundle: AmityUIKitManager.bundle)
    }
}

class AlertController {
    
    struct DismissConfig {
        let title: String
        let action: (() -> Void)?
    }
    
    static func showAlert(in vc: UIViewController, title: String, message: String, dismiss: DismissConfig = .init(title: AmityLocalizedStringSet.General.ok.localizedString, action: nil)) {
        let cancelAction = UIAlertAction(title: dismiss.title, style: .cancel, handler: { _ in dismiss.action?() })
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(cancelAction)

        vc.present(alertController, animated: true, completion: nil)
    }
}
