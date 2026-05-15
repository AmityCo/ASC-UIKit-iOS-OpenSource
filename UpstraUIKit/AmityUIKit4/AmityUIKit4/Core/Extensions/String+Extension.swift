//
//  String+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import UIKit

extension String {
    
    /// Resolve a localized string by checking the consumer app bundle first,
    /// then falling back to the framework bundle. This allows consumer apps
    /// (e.g. via SPM) to provide their own translations in their app's lproj
    /// directories without modifying the framework.
    private static func resolveLocalized(_ key: String, table: String, bundle: Bundle) -> String {
        let bundles = bundle == Bundle.main ? [bundle] : [Bundle.main, bundle]
        for lang in Locale.preferredLanguages {
            let code = String(lang.prefix(2))
            if code == "en" { break }
            for b in bundles {
                if let lprojPath = b.path(forResource: code, ofType: "lproj"),
                   let lprojBundle = Bundle(path: lprojPath) {
                    let v = lprojBundle.localizedString(forKey: key, value: "", table: table)
                    if !v.isEmpty && v != key { return v }
                }
            }
        }
        // Fallback: check consumer bundle first for default locale, then framework
        for b in bundles {
            let v = NSLocalizedString(key, tableName: table, bundle: b, value: "", comment: "")
            if !v.isEmpty && v != key { return v }
        }
        return key
    }

    public var localizedString: String {
        return Self.resolveLocalized(self, table: "AmityLocalizable", bundle: AmityUIKit4Manager.bundle)
    }
    
    func localized(arguments: CVarArg...) -> String {
        let localizedText = Self.resolveLocalized(self, table: "AmityLocalizable", bundle: AmityUIKit4Manager.bundle)
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
    
    func capitalizeFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    var utf16Count: Int {
        self.utf16.count
    }

    func utf16Prefix(_ maxLength: Int) -> String {
        guard self.utf16.count > maxLength else { return self }
        let index = String.Index(utf16Offset: maxLength, in: self)
        return String(self[..<index])
    }
}
