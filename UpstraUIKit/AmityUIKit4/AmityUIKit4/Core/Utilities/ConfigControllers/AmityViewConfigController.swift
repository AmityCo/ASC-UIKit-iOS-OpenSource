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
        
        self.defaultLightTheme = AmityThemeColor(primaryColor: lightTheme.primaryColor!, secondaryColor: lightTheme.secondaryColor!, secondaryColorShade1: lightTheme.secondaryColorShade1!, baseColor: lightTheme.baseColor!, baseColorShade1: lightTheme.baseColorShade1!, baseColorShade2: lightTheme.baseColorShade2!, baseColorShade3: lightTheme.baseColorShade3!, baseColorShade4: lightTheme.baseColorShade4!, alertColor: lightTheme.alertColor!, backgroundColor: lightTheme.backgroundColor!, baseInverseColor: lightTheme.baseInverseColor!, backgroundShade1Color: lightTheme.backgroundShade1Color!, highlightColor: lightTheme.highlightColor!)
        
        self.defaultDarkTheme = AmityThemeColor(primaryColor: darkTheme.primaryColor!, secondaryColor: darkTheme.secondaryColor!, secondaryColorShade1: darkTheme.secondaryColorShade1!, baseColor: darkTheme.baseColor!, baseColorShade1: darkTheme.baseColorShade1!, baseColorShade2: darkTheme.baseColorShade2!, baseColorShade3: darkTheme.baseColorShade3!, baseColorShade4: darkTheme.baseColorShade4!, alertColor: darkTheme.alertColor!, backgroundColor: darkTheme.backgroundColor!, baseInverseColor: darkTheme.baseInverseColor!, backgroundShade1Color: darkTheme.backgroundShade1Color!, highlightColor: darkTheme.highlightColor!)
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
        return config[key] as? T
    }
    
    public func getText(elementId: ElementId) -> String? {
        getConfig(elementId: elementId, key: "text", of: String.self)
    }
    
    public func getImage(elementId: ElementId) -> ImageResource {
        AmityIcon.getImageResource(named: getConfig(elementId: elementId, key: "image", of: String.self) ?? "")
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
        text = config["text"] as? String
        image = config["image"] as? String
        icon = config["icon"] as? String ?? image
    }
}
