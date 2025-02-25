//
//  AmityView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/28/23.
//

import SwiftUI
import Foundation

struct AmityView<Content: View, Config>: View {
    private var configDict: [String: Any] = [:]
    
    private let content: (Config) -> Content
    private let config: ([String: Any]) -> Config
    
    init(configId: String, config: @escaping ([String: Any]) -> Config, @ViewBuilder content: @escaping (Config) -> Content) {
        self.content = content
        configDict = AmityUIKitConfigController.shared.getConfig(configId: configId)
        self.config = config
    }

    var body: some View {
        let config = config(configDict)
        content(config)
    }
}
