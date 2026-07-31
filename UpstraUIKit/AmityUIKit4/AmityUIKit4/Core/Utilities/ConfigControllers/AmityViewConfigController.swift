//
//  AmityViewConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/28/23.
//

import SwiftUI
import UIKit
import Combine

class AmityViewConfigController: NSObject, ObservableObject {
    @Published var theme: AmityThemeColor
    let defaultLightTheme: AmityThemeColor
    let defaultDarkTheme: AmityThemeColor
    
    let pageId: PageId?
    let componentId: ComponentId?
    
    init(pageId: PageId?, componentId: ComponentId? = nil) {
        self.pageId = pageId
        self.componentId = componentId
        let configId = "\(pageId?.rawValue ?? "*")/\(componentId?.rawValue ?? "*")/*"
        
        self.theme = AmityUIKitConfigController.shared.getTheme(configId: configId)
        
        self.defaultLightTheme = AmityViewConfigController.buildDefaultThemeColor(from: lightTheme)
        self.defaultDarkTheme = AmityViewConfigController.buildDefaultThemeColor(from: darkTheme)
    }
    
    private static func buildDefaultThemeColor(from theme: AmityTheme) -> AmityThemeColor {
        AmityThemeColor(primaryColor: theme.primaryColor!,
                        primaryColorShade1: theme.primaryColorShade1!,
                        primaryColorShade2: theme.primaryColorShade2!,
                        primaryColorShade3: theme.primaryColorShade3!,
                        primaryColorShade4: theme.primaryColorShade4!,
                        secondaryColor: theme.secondaryColor!,
                        secondaryColorShade1: theme.secondaryColorShade1!,
                        secondaryColorShade2: theme.secondaryColorShade2!,
                        secondaryColorShade3: theme.secondaryColorShade3!,
                        secondaryColorShade4: theme.secondaryColorShade4!,
                        neutralGreyShade1Color: theme.neutralGreyShade1Color!,
                        neutralGreyShade2Color: theme.neutralGreyShade2Color!,
                        neutralGreyShade3Color: theme.neutralGreyShade3Color!,
                        neutralGreyShade4Color: theme.neutralGreyShade4Color!,
                        neutralGreyShade5Color: theme.neutralGreyShade5Color!,
                        neutralGreyShade6Color: theme.neutralGreyShade6Color!,
                        baseColor: theme.baseColor!,
                        baseColorShade1: theme.baseColorShade1!,
                        baseColorShade2: theme.baseColorShade2!,
                        baseColorShade3: theme.baseColorShade3!,
                        baseColorShade4: theme.baseColorShade4!,
                        alertColor: theme.alertColor!,
                        alertColorShade1: theme.alertColorShade1!,
                        backgroundColor: theme.backgroundColor!,
                        baseInverseColor: theme.baseInverseColor!,
                        backgroundShade1Color: theme.backgroundShade1Color!,
                        highlightColor: theme.highlightColor!,
                        destructiveShade1Color: theme.destructiveShade1Color!,
                        destructiveShade2Color: theme.destructiveShade2Color!,
                        destructiveShade3Color: theme.destructiveShade3Color!,
                        destructiveShade4Color: theme.destructiveShade4Color!,
                        destructiveShade5Color: theme.destructiveShade5Color!,
                        transparentBlackShade1Color: theme.transparentBlackShade1Color!,
                        transparentBlackShade2Color: theme.transparentBlackShade2Color!,
                        transparentBlackShade3Color: theme.transparentBlackShade3Color!,
                        transparentBlackShade4Color: theme.transparentBlackShade4Color!,
                        transparentBlackShade5Color: theme.transparentBlackShade5Color!,
                        transparentWhiteShade1Color: theme.transparentWhiteShade1Color!,
                        transparentWhiteShade2Color: theme.transparentWhiteShade2Color!,
                        transparentWhiteShade3Color: theme.transparentWhiteShade3Color!,
                        transparentWhiteShade4Color: theme.transparentWhiteShade4Color!,
                        transparentWhiteShade5Color: theme.transparentWhiteShade5Color!,
                        transparentWhiteShade6Color: theme.transparentWhiteShade6Color!,
                        transparentWhiteShade7Color: theme.transparentWhiteShade7Color!,
                        transparentRedShade1Color: theme.transparentRedShade1Color!)
    }

    // MARK: Private functions
    private func constructConfigId(pageId: PageId?, componentId: ComponentId?, elementId: ElementId?) -> String {
        let pageId = pageId?.rawValue ?? "*"
        let componentId = componentId?.rawValue ?? "*"
        let elementId = elementId?.rawValue ?? "*"
        let configId = "\(pageId)/\(componentId)/\(elementId)"
        
        return configId
    }
    
    // MARK: Public functions
    public func updateTheme() {
        let configId = "\(pageId?.rawValue ?? "*")/\(componentId?.rawValue ?? "*")/*"
        self.theme = AmityUIKitConfigController.shared.getTheme(configId: configId)
    }
    
    public func getConfig<T>(elementId: ElementId? = nil,
                             key: String,
                             of type: T.Type) -> T? {
        let configId = constructConfigId(pageId: pageId, componentId: componentId, elementId: elementId)
        let config = AmityUIKitConfigController.shared.getConfig(configId: configId)
        let value = config[key] as? T
        if let str = value as? String, str.isEmpty { return nil }
        return value
    }
    
    public func getText(elementId: ElementId) -> String? {
        getConfig(elementId: elementId, key: "text", of: String.self)
    }
    
    public func getImage(elementId: ElementId, placeholder: String = "") -> ImageResource {
        AmityIcon.getImageResource(named: getConfig(elementId: elementId, key: "image", of: String.self) ?? placeholder)
    }
    
    public func isHidden(elementId: ElementId? = nil) -> Bool {
        let configId = constructConfigId(pageId: pageId, componentId: componentId, elementId: elementId)
        return AmityUIKitConfigController.shared.isExcluded(configId: configId)
    }
    
    var currentStyle: AmityThemeStyle {
        return AmityUIKitConfigController.shared.getCurrentThemeStyle()
    }
    
    func forElement(_ id: ElementId) -> ElementConfiguration {
        let configId = constructConfigId(pageId: pageId, componentId: componentId, elementId: id)
        let config = AmityUIKitConfigController.shared.getConfig(configId: configId)
        return ElementConfiguration(config: config)
    }
    
    func forElement(_ id: ElementId, pageId: PageId?, componentId: ComponentId?) -> ElementConfiguration {
        let configId = constructConfigId(pageId: pageId, componentId: componentId, elementId: id)
        let config = AmityUIKitConfigController.shared.getConfig(configId: configId)
        return ElementConfiguration(config: config)
    }
}

struct ElementConfiguration {
    let text: String?
    let image: String?
    let icon: String? // Deprecated
    
    init(config: [String: Any]) {
        let rawText = config["text"] as? String
        text = (rawText?.isEmpty == false) ? rawText : nil
        image = config["image"] as? String
        icon = config["icon"] as? String ?? image
    }
}
