//
//  AmityView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/28/23.
//

import SwiftUI
import Foundation

struct AmityView<Content: View, Config>: View {
    private var configType: ConfigType
    private var configDict: [String: Any] = [:]
    
    private let content: (Config) -> Content
    private let config: ([String: Any]) -> Config
    
    init(configType: ConfigType, config: @escaping ([String: Any]) -> Config, @ViewBuilder content: @escaping (Config) -> Content) {
        self.configType = configType
        self.content = content
        configDict = AmityUIKitConfigController.shared.getConfig(ofType: configType)
        self.config = config
    }
    
    var body: some View {
        let config = config(configDict)
        content(config)
    }
    
}
