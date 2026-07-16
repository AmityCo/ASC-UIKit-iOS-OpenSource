//
//  EndpointManager.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 11/11/2564 BE.
//  Copyright © 2564 BE Eko. All rights reserved.
//

import AmitySDK

struct EndpointConfigModel: Codable, Equatable {
    let apiKey: String
    let httpEndpoint: String
    let mqttEndpoint: String
    let uploadURL: String
}

class EndpointManager {

    static let shared = EndpointManager()

    private enum UserDefaultsKey {
        static let selectedRegion = "asc_sample_selected_region"
        static let overrides = "asc_sample_endpoint_overrides"
    }

    private(set) var currentRegion: ApiRegion {
        didSet {
            UserDefaults.standard.setValue(currentRegion.rawValue, forKey: UserDefaultsKey.selectedRegion)
        }
    }

    /// User-applied overrides keyed by region. Persisted across launches.
    /// When an override exists for the current region, `currentEndpointConfig` returns it
    /// in preference to the hardcoded `defaultConfig(for:)`.
    private var overrides: [String: EndpointConfigModel] {
        didSet {
            if let data = try? JSONEncoder().encode(overrides) {
                UserDefaults.standard.setValue(data, forKey: UserDefaultsKey.overrides)
            }
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: UserDefaultsKey.selectedRegion),
           let restored = ApiRegion(rawValue: raw) {
            currentRegion = restored
        } else {
            currentRegion = .staging
        }

        if let data = UserDefaults.standard.data(forKey: UserDefaultsKey.overrides),
           let decoded = try? JSONDecoder().decode([String: EndpointConfigModel].self, from: data) {
            overrides = decoded
        } else {
            overrides = [:]
        }
    }

    func setCurrentRegion(_ region: ApiRegion) {
        currentRegion = region
    }

    /// Apply a user-edited override for `region`. Only `apiKey` and `uploadURL` are user-editable per the spec;
    /// `httpEndpoint` and `mqttEndpoint` stay tied to the region's defaults.
    func applyOverride(region: ApiRegion, apiKey: String, uploadURL: String) {
        let regionDefault = EndpointManager.defaultConfig(for: region)
        overrides[region.rawValue] = EndpointConfigModel(
            apiKey: apiKey,
            httpEndpoint: regionDefault.httpEndpoint,
            mqttEndpoint: regionDefault.mqttEndpoint,
            uploadURL: uploadURL
        )
    }

    /// Drop the override for `region` — subsequent reads return the hardcoded default.
    func clearOverride(for region: ApiRegion) {
        overrides.removeValue(forKey: region.rawValue)
    }

    var currentEndpointConfig: EndpointConfigModel {
        if let override = overrides[currentRegion.rawValue] {
            return override
        }
        return EndpointManager.defaultConfig(for: currentRegion)
    }

    static func defaultConfig(for region: ApiRegion) -> EndpointConfigModel {
        switch region {
        case .staging:
            return EndpointConfigModel(
                apiKey: "YOUR_API_KEY",
                httpEndpoint: AmityRegion.SG.httpUrl,
                mqttEndpoint: AmityRegion.SG.mqttHost,
                uploadURL: AmityRegion.SG.uploadUrl
            )
        case .sg:
            return EndpointConfigModel(
                apiKey: "YOUR_API_KEY",
                httpEndpoint: AmityRegion.SG.httpUrl,
                mqttEndpoint: AmityRegion.SG.mqttHost,
                uploadURL: AmityRegion.SG.uploadUrl
            )
        case .eu:
            return EndpointConfigModel(
                apiKey: "YOUR_API_KEY",
                httpEndpoint: AmityRegion.EU.httpUrl,
                mqttEndpoint: AmityRegion.EU.mqttHost,
                uploadURL: AmityRegion.EU.uploadUrl
            )
        case .us:
            return EndpointConfigModel(
                apiKey: "YOUR_API_KEY",
                httpEndpoint: AmityRegion.US.httpUrl,
                mqttEndpoint: AmityRegion.US.mqttHost,
                uploadURL: AmityRegion.US.uploadUrl
            )
        }
    }
}
