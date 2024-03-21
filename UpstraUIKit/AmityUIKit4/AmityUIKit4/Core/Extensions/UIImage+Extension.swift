//
//  UIImage+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/3/24.
//

import UIKit
import SwiftUI

enum ImageOrientation {
    case portrait, landscape
}

extension UIImage {
    var averageGradientColor: [Color]? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let startColor = UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
        let stopColor = UIColor(red: CGFloat(bitmap[2]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[0]) / 255, alpha: CGFloat(bitmap[3]) / 255)
        return [Color(startColor), Color(stopColor)]
    }
    
    var orientation: ImageOrientation {
        return self.size.height > self.size.width ? .portrait : .landscape
    }
}
