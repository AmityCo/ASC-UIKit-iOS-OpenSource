//
//  Error+Extension.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

enum AmityError: Int, Error {
    
    case unknown = 99999
    case noPermission = 40301
    case bannedWord = 400308
    case noUserAccessPermission = 400301
    case fileServiceIsNotReady = 38528523
    case userNotFound = 40000001
    case unableToLeaveCommunity = 400317
    
    init?(error: Error?) {
        guard let errorCode = error?._code,
              let _error = AmityError(rawValue: errorCode) else {
            return nil
        }
        self = _error
    }
}
