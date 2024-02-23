//
//  AmityUIKitConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import Foundation

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
    
    
    func getConfig(configId: String) -> [String: Any] {
        let id = configId.components(separatedBy: "/")
        
        guard id.count == 3, let customizationConfig = config["customizations"] as? [String: Any] else {
            return [:]
        }
        
        // normal config
        if let config = customizationConfig[configId] as? [String: Any] {
            return config
        }
        
        // wild card config
        if id[1] != "*" {
            // component wildcard config
            if let config = customizationConfig["*/\(id[1])/*"] as? [String: Any] {
                return config
            }
        } else if id[2] != "*" {
            // element wildcard config
            if let config = customizationConfig["*/*/\(id[2])"] as? [String: Any] {
                return config
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
