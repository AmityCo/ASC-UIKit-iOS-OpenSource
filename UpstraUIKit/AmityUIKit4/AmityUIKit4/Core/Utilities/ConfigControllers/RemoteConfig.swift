//
//  RemoteConfig.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 25/3/2568 BE.
//

public class RemoteConfig {
    private let configFileName = "remoteConfig.json"
    static let shared = RemoteConfig()
    
    private static var apiKey = ""
    private static var httpEndpoint = ""
    
    public static func setup(apiKey: String, httpEndpoint: String) {
        RemoteConfig.apiKey = shared.hashApiKey(apiKey)
        RemoteConfig.httpEndpoint = httpEndpoint
    }
    
    @MainActor
    func getRemoteConfig() async throws {
        guard let url = URL(string: "\(RemoteConfig.httpEndpoint)/api/v3/network-settings/uikit") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        let token = AmityUIKit4Manager.client.accessToken ?? ""
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let data = try await fetchData(from: request)
                
        try saveConfigToFile(data: data)
        
        AmityUIKitConfigController.shared.refreshConfig()
    }
    
    private func fetchData(from request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, 
                          userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        return data
    }
    
    private func getConfigFileURL(named fileName: String? = nil) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName ?? configFileName)
    }
    
    func getStoredConfig() -> [String: Any]? {
        do {
            let fileURL = try getConfigFileURL()
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } else {
                print("Config file does not exist")
                return nil
            }
        } catch {
            print("Error reading config file: \(error)")
            return nil
        }
    }
    
    func getStoredConfigAsDictionary() -> [String: Any]? {
        guard let jsonObject = getStoredConfig(),
              let configObject = jsonObject["config"] as? [String: Any] else {
            return nil
        }
        return configObject
    }
    
    
    func getMergedConfig() -> [String: Any] {
        let localConfig = loadLocalConfig(fileName: "AmityUIKitConfig")
        return mergeWithLocalConfig(localConfig)
    }
    
    func loadLocalConfig(fileName: String) -> [String: Any] {
        if let path = AmityUIKit4Manager.bundle.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    return jsonResult
                }
            } catch {
                print("Error loading local config: \(error)")
                return [:]
            }
        }
        return [:]
    }
    
    func mergeWithLocalConfig(_ localConfig: [String: Any]) -> [String: Any] {
        guard let remoteConfig = getStoredConfigAsDictionary() else {
            return wrapConfigWithMetadata(localConfig)
        }
        
        var mergedConfig = localConfig
        
        mergeDict(&mergedConfig, with: remoteConfig)
        
        return wrapConfigWithMetadata(mergedConfig)
    }
    
    private func wrapConfigWithMetadata(_ config: [String: Any]) -> [String: Any] {
        return [
            "config": config,
            "network": RemoteConfig.apiKey
        ]
    }
    
    private func mergeDict(_ target: inout [String: Any], with source: [String: Any]) {
        for (key, sourceValue) in source {
            if var targetValue = target[key] as? [String: Any],
               let sourceDict = sourceValue as? [String: Any] {
                mergeDict(&targetValue, with: sourceDict)
                target[key] = targetValue
            } else {
                target[key] = sourceValue
            }
        }
    }
    
    private func saveConfigToFile(data: Data) throws {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        
        var jsonDict: [String: Any] = [:]
        
        if let config = jsonObject as? [String: Any] {
            jsonDict = config
        }
        jsonDict["network"] = RemoteConfig.apiKey
        
        let updatedData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        
        let fileURL = try getConfigFileURL()
        try updatedData.write(to: fileURL, options: .atomic)
    }
    
    
    func clearStoredConfig() throws {
        let fileURL = try getConfigFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            AmityUIKitConfigController.shared.refreshConfig()
        }
    }
    
    private func hashApiKey(_ apiKey: String) -> String {
        let data = apiKey.data(using: .utf8)!
        let hash = data.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) }
        return String(hash)
    }
    
    func isCurrentApiKeyMatchingStoredNetwork() -> Bool {
        
        guard let storedConfig = getStoredConfig(),
              let storedNetwork = storedConfig["network"] as? String,
              !storedNetwork.isEmpty else {
            return false
        }
        return storedNetwork == RemoteConfig.apiKey
    }
}
