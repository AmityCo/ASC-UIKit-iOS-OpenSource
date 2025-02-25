//
//  String+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import UIKit

extension String {
    public var localizedString: String {
            return NSLocalizedString(self, tableName: "AmityLocalizable", bundle: AmityUIKit4Manager.bundle, value: "", comment: "")
    }
    
    func localized(arguments: CVarArg...) -> String {
        let localizedText = NSLocalizedString(self, tableName: "AmityLocalizable", bundle: AmityUIKit4Manager.bundle, value: "", comment: "")
        let formattedText = String(format: localizedText, arguments: arguments)
        return formattedText
    }
    
    var isValidURL: Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    public func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }
    
    func size(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}
