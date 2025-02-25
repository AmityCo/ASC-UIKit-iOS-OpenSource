//
//  Log.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation
import SwiftUI
import OSLog

class Log {
    
    enum LogEvent: String {
        case success = "🟢"
        case info = "🟡"
        case warn = "⚠️"
        case error = "🔴"
    }
    
    // Prints on console for Debug purpose. This log will not be printed on release build.
    // › [Amity]: [ViewController.methodName()] : My Log
    static func add(event: LogEvent, _ info: Any, fileName:String = #file, methodName:String = #function) {
        #if DEBUG
        print("› [AmityUIKit]: \(event.rawValue) [\(fileName.components(separatedBy: "/").last!.components(separatedBy: ".").first!).\(methodName)] : \(info)")
        #endif
    }
    
    // Prints message on console. Use this if you want client to see the message on console.
    static func warn(_ info: Any) {
        print("› [AmityUIKit]: \(info)")
    }
    
    static func printChanges(_ type: any View.Type) {
        #if DEBUG
        if #available(iOS 15.0, *) {
            type._printChanges()
        } else {
            Log.add(event: .info, "Debugging SwiftUI view changes only works in iOS 15+.")
        }
        #endif
    }
}

extension Log {

    static let uikit = "AmityUIKit4"
    
    static var chat = Logger(subsystem: uikit, category: "Chat")
    
    static var story = Logger(subsystem: uikit, category: "Story")
    
    static var reaction = Logger(subsystem: uikit, category: "Reaction")
    
    static var ads = Logger(subsystem: uikit, category: "Ads")
    
    static var adAssets = Logger(subsystem: uikit, category: "Ads.Asset")
    
    static var adInjector = Logger(subsystem: uikit, category: "Ads.Injector")
}
