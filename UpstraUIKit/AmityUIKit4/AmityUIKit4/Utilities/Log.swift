//
//  Log.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import Foundation

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
}

