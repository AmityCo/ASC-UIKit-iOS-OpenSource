//
//  AmityUIKitConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import Foundation

enum ConfigType {
    case page(String)
    case component(String)
    case element(String)
}


class AmityUIKitConfigController {
    static let shared = AmityUIKitConfigController()
    private var config: [String: Any] = [:]
    private var excludedList: Set<String> = []
    
    private init() {
        configParser(configFile: "AmityUIKitConfig")
    }
    
    // MARK: Public Functions
    
    func isExcluded(configId: String) -> Bool {
        return excludedList.contains(configId)
    }
    
    
    func getGlobalTheme(theme: AmityTheme) -> AmityThemeColor? {
        let globalTheme = config["global_theme.\(theme.rawValue)"] as? [String: Any]
        do {
            return try globalTheme?.decode(AmityThemeColor.self)
        } catch {
            return nil
        }
    }
    
    
    func getPageTheme(theme: AmityTheme, configId: String) -> AmityThemeColor? {
        let customizationConfig = config["customizations"] as? [String: Any]
        let pageTheme = customizationConfig?[keyPath: "\(configId).page_theme.\(theme.rawValue)"] as? [String: Any]
        do {
            return try pageTheme?.decode(AmityThemeColor.self)
        } catch {
            return nil
        }
    }
    
    
    func getConfig(ofType: ConfigType) -> [String: Any] {
        let customizationConfig = config["customizations"] as? [String: Any]
        
        switch ofType {
            
        case .page(let configId):
            if let customizationConfig,
               let config = customizationConfig[configId] as? [String: Any] {
                return config
            }
        
        case .component(let configId):
            if let customizationConfig,
               let config = customizationConfig[configId] as? [String: Any] {
                return config
            } else {
                // Wildcard config
                let id = configId.components(separatedBy: "/")
                if id.count == 3,
                   let customizationConfig,
                   let config = customizationConfig[id[1]] as? [String: Any] {
                    return config
                }
            }
            
        case .element(let configId):
            if let customizationConfig,
               let config = customizationConfig[configId] as? [String: Any] {
                return config
            } else {
                // Wildcard config
                let id = configId.components(separatedBy: "/")
                if id.count == 3,
                   let customizationConfig,
                   let config = customizationConfig[id[2]] as? [String: Any] {
                    return config
                }
            }
        }
        
        return [:]
    }
    
    // MARK: Private Functions
    
    private func configParser(configFile: String) {
        config = loadConfigFile(fileName: configFile)
        excludedList = Set(config["excludes"] as? [String] ?? [])
    }
    
    private func loadConfigFile(fileName: String) -> [String: Any] {
        if let path = AmityUIKit4Manager.bundle.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    return jsonResult
                }
            } catch {
                return [:]
            }
        }
        return [:]
    }
}
