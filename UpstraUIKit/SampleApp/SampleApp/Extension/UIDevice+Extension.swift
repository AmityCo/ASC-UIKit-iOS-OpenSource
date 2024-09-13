//
//  UIDevice+Extension.swift
//  SampleApp
//
//  Created by Zay Yar Htun on 9/6/24.
//  Copyright © 2024 Eko. All rights reserved.
//

import UIKit

extension UIDevice {
    /// Returns `true` if the device has a notch
    static var hasNotch: Bool {
        guard #available(iOS 11.0, *), let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return false }
        return window.safeAreaInsets.top >= 44
    }
}
