//
//  LoginConfigModel.swift
//  SampleApp
//

import Foundation

enum ApiRegion: String, Codable, CaseIterable, Identifiable {
    case staging
    case sg
    case eu
    case us

    var id: String { rawValue }

    var title: String {
        switch self {
        case .staging: return "Staging"
        case .sg:      return "SG"
        case .eu:      return "EU"
        case .us:      return "US"
        }
    }
}

enum UserType: String, Codable, CaseIterable, Identifiable {
    case signedIn = "signed-in"
    case visitor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .signedIn: return "Signed-in"
        case .visitor:  return "Visitor"
        }
    }
}

enum ThemeOption: String, Codable, CaseIterable, Identifiable {
    case `default`
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: return "Default"
        case .light:   return "Light"
        case .dark:    return "Dark"
        }
    }
}

struct LoginConfigModel: Codable, Equatable {
    // User
    var userId: String
    var displayName: String
    var userType: UserType

    // Network
    var apiRegion: ApiRegion
    var apiKey: String
    var uploadURL: String

    // Security (Screen 2)
    var secureMode: Bool
    var authSignatureURL: String
    var authSignatureExpiresAt: Date

    // Behaviour (Screen 2)
    var visitorCanViewClip: Bool
    var hideExplore: Bool
    var socialCommunityCreationButtonVisible: Bool

    // Appearance (Screen 2)
    var theme: ThemeOption
    var syncNetworkConfig: Bool

    static let platformDefaultUserId = "ios-test"

    static func makeDefault(stagingApiKey: String, stagingUploadURL: String) -> LoginConfigModel {
        LoginConfigModel(
            userId: "",
            displayName: "",
            userType: .signedIn,
            apiRegion: .staging,
            apiKey: stagingApiKey,
            uploadURL: stagingUploadURL,
            secureMode: false,
            authSignatureURL: "",
            authSignatureExpiresAt: Date().addingTimeInterval(3600),
            visitorCanViewClip: false,
            hideExplore: false,
            socialCommunityCreationButtonVisible: true,
            theme: .default,
            syncNetworkConfig: false
        )
    }
}

struct AppliedEnvSnapshot: Codable, Equatable {
    var region: ApiRegion
    var apiKey: String
    var uploadURL: String
}
