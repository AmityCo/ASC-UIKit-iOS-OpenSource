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
    
    let pageId: PageId?
    let componentId: ComponentId?
    
    init(pageId: PageId?, componentId: ComponentId? = nil) {
        self.pageId = pageId
        self.componentId = componentId
        let configId = "\(pageId?.rawValue ?? "*")/\(componentId?.rawValue ?? "*")/*"
        
        self.theme = AmityUIKitConfigController.shared.getTheme(configId: configId)
        
        self.defaultLightTheme = AmityThemeColor(primaryColor: lightTheme.primaryColor!, secondaryColor: lightTheme.secondaryColor!, baseColor: lightTheme.baseColor!, baseColorShade1: lightTheme.baseColorShade1!, baseColorShade2: lightTheme.baseColorShade2!, baseColorShade3: lightTheme.baseColorShade3!, baseColorShade4: lightTheme.baseColorShade4!, alertColor: lightTheme.alertColor!, backgroundColor: lightTheme.backgroundColor!, baseInverseColor: lightTheme.baseInverseColor!, backgroundShade1Color: lightTheme.backgroundShade1Color!, highlightColor: lightTheme.highlightColor!)
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
}
