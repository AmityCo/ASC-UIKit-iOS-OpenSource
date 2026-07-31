//
//  AmityUIKitConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import Foundation
import UIKit

class AmityUIKitConfigController {
    static let shared = AmityUIKitConfigController()
    private(set) var config: [String: Any] = [:]
    private var excludedList: Set<String> = []
    private(set) var featureFlag: AmityFeatureFlag?
    private var configFilePath: String?

    private init() {
        loadConfig()
    }

    private func loadConfig() {
        let configFilePath = configFilePath ?? AmityUIKit4Manager.bundle.path(forResource: "AmityUIKitConfig", ofType: "json")
        let localConfig = configFilePath.flatMap { loadConfigFile(filePath: $0) } ?? [:]
        let wrappedConfig = RemoteConfig.shared.mergeWithLocalConfig(localConfig)

        config = (wrappedConfig["config"] as? [String: Any]) ?? localConfig
        excludedList = Set(config["excludes"] as? [String] ?? [])
        featureFlag = try? AmityFeatureFlag.decode(from: config["feature_flags"] as? [String: Any] ?? [:])
    }

    func setConfigFile(_ filePath: String) {
        configFilePath = filePath
        refreshConfig()
    }

    func refreshConfig() {
        loadConfig()
        NotificationCenter.default.post(name: .configDidUpdate, object: nil)
    }
    
    // MARK: Public Functions
    
    func isExcluded(configId: String) -> Bool {
        let id = configId.components(separatedBy: "/")
        guard id.count == 3 else { return false }
        
        return excludedList.contains(configId) ||
        excludedList.contains("*/\(id[1])/*") ||
        excludedList.contains("*/\(id[1])/\(id[2])") ||
        excludedList.contains("*/*/\(id[2])")
    }
    
    func getTheme(configId: String? = nil) -> AmityThemeColor {
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let configStyle = AmityThemeStyle(rawValue: config["preferred_theme"] as? String ?? "light") ?? .light
        
        let style: AmityThemeStyle = configStyle == .system ? (systemStyle == .light ? .light : .dark) : (configStyle == .light ? .light : .dark)
        
        let fallbackTheme = style == .light ? lightTheme : darkTheme
        let globalTheme = getGlobalTheme(style) ?? fallbackTheme
        
        guard let configId else {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        let customizationConfig = config["customizations"] as? [String: Any]
        let id = configId.components(separatedBy: "/")
        guard id.count == 3 else {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        let pageComponentTheme = customizationConfig?[keyPath: "\(id[0])/\(id[1])/*.theme.\(style.rawValue)"] as? [String: Any]
        let pageTheme = customizationConfig?[keyPath: "\(id[0])/*/*.theme.\(style.rawValue)"] as? [String: Any]
        let componentTheme = customizationConfig?[keyPath: "*/\(id[1])/*.theme.\(style.rawValue)"] as? [String: Any]
        
        do {
            if let pageComponentTheme {
                return try getThemeColor(theme: pageComponentTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
            
            if let componentTheme {
                return try getThemeColor(theme: componentTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
            
            if let pageTheme {
                return try getThemeColor(theme: pageTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
        } catch {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
    }
    
    
    func getConfig(configId: String) -> [String: Any] {
        let id = configId.components(separatedBy: "/")
        
        guard id.count == 3, let customizationConfig = config["customizations"] as? [String: Any] else {
            return [:]
        }
        
        // If its an exact match, return it
        if let config = customizationConfig[configId] as? [String: Any] {
            return config
        }
        
        // #1. We find obvious variation
        let variations = [
            "*/\(id[1])/\(id[2])", // */<component>/<element>
            "*/\(id[1])/*", // */<component>/* i.e any component
            "*/*/\(id[2])" // */*/<element> i.e any element
        ]
        
        for variation in variations {
            if let config = customizationConfig[variation] as? [String: Any] {
                return config
            }
        }
        
        return [:]
    }
    
    // MARK: Private Functions
    
    private func getGlobalTheme(_ style: AmityThemeStyle) -> AmityTheme? {
        let globalTheme = config[keyPath: "theme.\(style.rawValue)"] as? [String: Any]
        do {
            return try globalTheme?.decode(AmityTheme.self)
        } catch {
            return nil
        }
    }
    
    
    private func getThemeColor(theme: AmityTheme, fallbackTheme: AmityTheme) -> AmityThemeColor {
        return AmityThemeColor(primaryColor: theme.primaryColor ?? fallbackTheme.primaryColor!,
                               primaryColorShade1: theme.primaryColorShade1 ?? fallbackTheme.primaryColorShade1!,
                               primaryColorShade2: theme.primaryColorShade2 ?? fallbackTheme.primaryColorShade2!,
                               primaryColorShade3: theme.primaryColorShade3 ?? fallbackTheme.primaryColorShade3!,
                               primaryColorShade4: theme.primaryColorShade4 ?? fallbackTheme.primaryColorShade4!,
                               secondaryColor: theme.secondaryColor ?? fallbackTheme.secondaryColor!,
                               secondaryColorShade1: theme.secondaryColorShade1 ?? fallbackTheme.secondaryColorShade1!,
                               secondaryColorShade2: theme.secondaryColorShade2 ?? fallbackTheme.secondaryColorShade2!,
                               secondaryColorShade3: theme.secondaryColorShade3 ?? fallbackTheme.secondaryColorShade3!,
                               secondaryColorShade4: theme.secondaryColorShade4 ?? fallbackTheme.secondaryColorShade4!,
                               neutralGreyShade1Color: theme.neutralGreyShade1Color ?? fallbackTheme.neutralGreyShade1Color!,
                               neutralGreyShade2Color: theme.neutralGreyShade2Color ?? fallbackTheme.neutralGreyShade2Color!,
                               neutralGreyShade3Color: theme.neutralGreyShade3Color ?? fallbackTheme.neutralGreyShade3Color!,
                               neutralGreyShade4Color: theme.neutralGreyShade4Color ?? fallbackTheme.neutralGreyShade4Color!,
                               neutralGreyShade5Color: theme.neutralGreyShade5Color ?? fallbackTheme.neutralGreyShade5Color!,
                               neutralGreyShade6Color: theme.neutralGreyShade6Color ?? fallbackTheme.neutralGreyShade6Color!,
                               baseColor: theme.baseColor ?? fallbackTheme.baseColor!,
                               baseColorShade1: theme.baseColorShade1 ?? fallbackTheme.baseColorShade1!,
                               baseColorShade2: theme.baseColorShade2 ?? fallbackTheme.baseColorShade2!,
                               baseColorShade3: theme.baseColorShade3 ?? fallbackTheme.baseColorShade3!,
                               baseColorShade4: theme.baseColorShade4 ?? fallbackTheme.baseColorShade4!,
                               alertColor: theme.alertColor ?? fallbackTheme.alertColor!,
                               alertColorShade1: theme.alertColorShade1 ?? fallbackTheme.alertColorShade1!,
                               backgroundColor: theme.backgroundColor ?? fallbackTheme.backgroundColor!,
                               baseInverseColor: theme.baseInverseColor ?? fallbackTheme.baseInverseColor!,
                               backgroundShade1Color: theme.backgroundShade1Color ?? fallbackTheme.backgroundShade1Color!,
                               highlightColor: theme.highlightColor ?? fallbackTheme.highlightColor!,
                               destructiveShade1Color: theme.destructiveShade1Color ?? fallbackTheme.destructiveShade1Color!,
                               destructiveShade2Color: theme.destructiveShade2Color ?? fallbackTheme.destructiveShade2Color!,
                               destructiveShade3Color: theme.destructiveShade3Color ?? fallbackTheme.destructiveShade3Color!,
                               destructiveShade4Color: theme.destructiveShade4Color ?? fallbackTheme.destructiveShade4Color!,
                               destructiveShade5Color: theme.destructiveShade5Color ?? fallbackTheme.destructiveShade5Color!,
                               transparentBlackShade1Color: theme.transparentBlackShade1Color ?? fallbackTheme.transparentBlackShade1Color!,
                               transparentBlackShade2Color: theme.transparentBlackShade2Color ?? fallbackTheme.transparentBlackShade2Color!,
                               transparentBlackShade3Color: theme.transparentBlackShade3Color ?? fallbackTheme.transparentBlackShade3Color!,
                               transparentBlackShade4Color: theme.transparentBlackShade4Color ?? fallbackTheme.transparentBlackShade4Color!,
                               transparentBlackShade5Color: theme.transparentBlackShade5Color ?? fallbackTheme.transparentBlackShade5Color!,
                               transparentWhiteShade1Color: theme.transparentWhiteShade1Color ?? fallbackTheme.transparentWhiteShade1Color!,
                               transparentWhiteShade2Color: theme.transparentWhiteShade2Color ?? fallbackTheme.transparentWhiteShade2Color!,
                               transparentWhiteShade3Color: theme.transparentWhiteShade3Color ?? fallbackTheme.transparentWhiteShade3Color!,
                               transparentWhiteShade4Color: theme.transparentWhiteShade4Color ?? fallbackTheme.transparentWhiteShade4Color!,
                               transparentWhiteShade5Color: theme.transparentWhiteShade5Color ?? fallbackTheme.transparentWhiteShade5Color!,
                               transparentWhiteShade6Color: theme.transparentWhiteShade6Color ?? fallbackTheme.transparentWhiteShade6Color!,
                               transparentWhiteShade7Color: theme.transparentWhiteShade7Color ?? fallbackTheme.transparentWhiteShade7Color!,
                               transparentRedShade1Color: theme.transparentRedShade1Color ?? fallbackTheme.transparentRedShade1Color!
        )
    }
    
    private func loadConfigFile(filePath: String) -> [String: Any]? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
            return try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any]
        } catch {
            Log.warn("Error loading config file at path: \(filePath), error: \(error)")
            return nil
        }
    }
    
    public func getCurrentThemeStyle() -> AmityThemeStyle {
        let configStyle = AmityThemeStyle(rawValue: config["preferred_theme"] as? String ?? "light") ?? .light
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let style: AmityThemeStyle = configStyle == .system ? (systemStyle == .light ? .light : .dark) : (configStyle == .light ? .light : .dark)
        return style
    }

    // MARK: - Chat feature flag accessors

    func enabledChannelTypes() -> [AmityChatChannelTypeFlag] {
        let raw = featureFlag?.chat.enabledChannelTypes ?? []
        let known = raw.compactMap { AmityChatChannelTypeFlag(rawValue: $0) }
        return known.isEmpty ? [.conversation, .community] : known
    }

    func isChatUserActionEnabled(_ name: String) -> Bool {
        guard let actions = featureFlag?.chat.conversationChatUserActions else {
            return true
        }
        if let entry = actions.first(where: { $0.name == name }) {
            return entry.enabled
        }
        return false
    }

    func hasAnyEnabledChatUserAction() -> Bool {
        guard let actions = featureFlag?.chat.conversationChatUserActions else {
            return true
        }
        let supported: Set<String> = ["mute", "report", "block"]
        return actions.contains(where: { supported.contains($0.name) && $0.enabled })
    }
}

struct AmityFeatureFlag: Codable {
    let post: PostFeatures
    let chat: ChatFeatures

    enum CodingKeys: String, CodingKey {
        case post
        case chat
    }

    init(post: PostFeatures = PostFeatures(),
         chat: ChatFeatures = ChatFeatures()) {
        self.post = post
        self.chat = chat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.post = try container.decodeIfPresent(PostFeatures.self, forKey: .post) ?? PostFeatures()
        self.chat = try container.decodeIfPresent(ChatFeatures.self, forKey: .chat) ?? ChatFeatures()
    }

    static func decode(from dictionary: [String: Any]) throws -> AmityFeatureFlag {
        // Convert dictionary to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])

        // Decode using JSONDecoder
        let decoder = JSONDecoder()
        return try decoder.decode(AmityFeatureFlag.self, from: jsonData)
    }
}

struct PostFeatures: Codable {
    let clip: ClipFeatures

    enum CodingKeys: String, CodingKey {
        case clip
    }

    init(clip: ClipFeatures = ClipFeatures()) {
        self.clip = clip
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clip = try container.decodeIfPresent(ClipFeatures.self, forKey: .clip) ?? ClipFeatures()
    }
}

struct ClipFeatures: Codable {
    let canCreate: AccessLevel
    let canViewTab: AccessLevel
    
    enum CodingKeys: String, CodingKey {
        case canCreate = "can_create"
        case canViewTab = "can_view_tab"
    }
    
    // Initialize with default values
    init(canCreate: AccessLevel = .signedInUserOnly, canViewTab: AccessLevel = .signedInUserOnly) {
        self.canCreate = canCreate
        self.canViewTab = canViewTab
    }
    
    // Custom decoder to handle default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.canCreate = try container.decodeIfPresent(AccessLevel.self, forKey: .canCreate) ?? .signedInUserOnly
        self.canViewTab = try container.decodeIfPresent(AccessLevel.self, forKey: .canViewTab) ?? .signedInUserOnly
    }
}

enum AccessLevel: String, Codable, CaseIterable {
    case all = "all"
    case signedInUserOnly = "signed_in_user_only"
    case none = "none"
}

// MARK: - Chat features

struct ChatFeatures: Codable {
    let enabledChannelTypes: [String]
    let conversationChatUserActions: [AmityChatUserActionFlag]?

    enum CodingKeys: String, CodingKey {
        case enabledChannelTypes = "enabled_channel_types"
        case conversationChatUserActions = "conversation_chat_user_actions"
    }

    init(enabledChannelTypes: [String] = [],
         conversationChatUserActions: [AmityChatUserActionFlag]? = nil) {
        self.enabledChannelTypes = enabledChannelTypes
        self.conversationChatUserActions = conversationChatUserActions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.enabledChannelTypes =
            try container.decodeIfPresent([String].self, forKey: .enabledChannelTypes) ?? []
        self.conversationChatUserActions =
            try container.decodeIfPresent([AmityChatUserActionFlag].self, forKey: .conversationChatUserActions)
    }
}

struct AmityChatUserActionFlag: Codable {
    let name: String
    let enabled: Bool
}

enum AmityChatChannelTypeFlag: String {
    case conversation
    case community
}
