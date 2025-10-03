//
//  GuestLoginView.swift
//  SampleApp
//
//  Created by Nishan Niraula on 24/9/25.
//  Copyright © 2025 Eko. All rights reserved.
//

import SwiftUI
import AmityUIKit
import AmityUIKit4

struct GuestLoginView: View {
    
    @State private var isSecureModeEnabled = false
    @State private var authSignatureExpiry: String = ""
    @State private var authSignatureURL: String = ""
    @State private var isFetchingToken = false
    
    let onLogin: ((_ isSecureMode: Bool,_ authSignature: String,_ authSignatureExpiry: Date?) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Visitor Login")
            
            GroupBox {
                if #available(iOS 16.0, *) {
                    LabeledContent("Device Id:", value: AmityUIKitManager.client.getVisitorDeviceId())
                        .lineLimit(1)
                } else {
                    Text("Device Id: \(AmityUIKitManager.client.getVisitorDeviceId())")
                        .lineLimit(1)
                }
            }
            
            Button {
                onCopyDeviceIdTap()
            } label: {
                HStack {
                    Spacer()
                    
                    Text("Copy Device Id")
                    
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            
            GroupBox {
                Toggle("Secure Mode", isOn: $isSecureModeEnabled)
                
                TextField("Bo's URL", text: $authSignatureURL)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isSecureModeEnabled)
                
                TextField("Auth Signature Expiry", text: $authSignatureExpiry)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isSecureModeEnabled)
            }
            
            Button {
                
                if isSecureModeEnabled {
                    // Show loading indicator
                    isFetchingToken = true
                    
                    guard !authSignatureURL.isEmpty else { return }
                                        
                    var authSignatureExpiryDate: Date
                    if authSignatureExpiry.isEmpty {
                        authSignatureExpiryDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date()
                    } else {
                        authSignatureExpiryDate = DateFormatter.ascDateFromISO8601String(authSignatureExpiry) ?? Date()
                    }
                    
                    Task { @MainActor in
                        let signature = try await fetchAuthSignature(expiryTimestamp: authSignatureExpiryDate)
                        
                        isFetchingToken = false
                        
                        onLogin?(isSecureModeEnabled, signature, authSignatureExpiryDate)
                    }
                } else {
                    onLogin?(isSecureModeEnabled, "", nil)
                }
                
            } label: {
                HStack {
                    Spacer()
                    
                    Text("Login As Guest")
                    
                    if isFetchingToken {
                        ProgressView()
                            .progressViewStyle(.automatic)
                    }
                    
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
            }
            .padding(.bottom, 32)

        }
        .padding(.horizontal, 24)
    }
    
    func onCopyDeviceIdTap() {
        let deviceId = AmityUIKitManager.client.getVisitorDeviceId()
        UIPasteboard.general.string = deviceId
        
        guard !deviceId.isEmpty else { return }
        
        #if canImport(AmityUIKit4)
        Toast.showToast(style: .warning, message: "Device Id Copied")
        #endif
    }
    
    @MainActor
    func fetchAuthSignature(expiryTimestamp: Date) async throws -> String {
        let deviceId = AmityUIKitManager.client.getVisitorDeviceId()
        
        let dateStr = DateFormatter.ascISO8601FractionalSecondsFormatter.string(from: expiryTimestamp)
        authSignatureExpiry = dateStr
        
        var baseURL = authSignatureURL
        if baseURL.hasSuffix("/") { baseURL.removeLast() }
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "authSignatureExpiresAt", value: dateStr),
        ]
        
        // Construct final URL
        guard let url = components.url else {
            print("❌ Invalid URL")
            return ""
        }
        
        // Create GET request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let decodedData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        let signature = decodedData["signature"] as? String ?? ""
        print("Guest User Login Data: \(decodedData)")
        return signature
    }
}
