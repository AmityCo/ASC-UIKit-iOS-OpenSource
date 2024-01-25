//
//  String+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import Foundation

extension String {
    public var localizedString: String {
            return NSLocalizedString(self, tableName: "AmityLocalizable", bundle: AmityUIKit4Manager.bundle, value: "", comment: "")
    }
}
