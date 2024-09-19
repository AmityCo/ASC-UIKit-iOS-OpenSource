//
//  EndpointsView.swift
//  SampleApp
//
//  Created by Nontapat Siengsanor on 8/11/2564 BE.
//  Copyright © 2564 BE Eko. All rights reserved.
//

import SwiftUI

struct EndpointsView: View {
    
    var saveButtonDidTap: (() -> Void)?
    @State var selectedEnv: EnvironmentType
    @State var config: EndpointConfigModel
    @State var httpEndpoint: String
    @State var uploadURL: String
    @State var apiKey: String
    
    init() {
        _selectedEnv = .init(initialValue: EndpointManager.shared.currentEnvironment)
        
        let config = EndpointManager.shared.currentEndpointConfig
        _config = .init(initialValue: config)
        _httpEndpoint = .init(initialValue: config.httpEndpoint)
        _apiKey = .init(initialValue: config.apiKey)
        _uploadURL = .init(initialValue: config.uploadURL)
    }
    
    var body: some View {
        
        Picker(selection: $selectedEnv.onChange(valueChange), label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
            ForEach(EnvironmentType.allCases, id: \.self) { env in
                Text(env.title).tag(env)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .padding()
        
        HStack {
            Text("API Key")
                .font(.caption)
            TextField("", text: $apiKey)
                .font(.subheadline)
                .background(Color(.systemGray6))
                .cornerRadius(3.0)
        }
        .padding()
        
        HStack {
            Text("Endpoint")
                .font(.caption)
            TextField("", text: $httpEndpoint)
                .font(.subheadline)
                .background(Color(.systemGray6))
                .cornerRadius(3.0)
        }
        .padding()
        
        HStack {
            Text("UploadURL")
                .font(.caption)
            TextField("", text: $uploadURL)
                .font(.subheadline)
                .background(Color(.systemGray6))
                .cornerRadius(3.0)
        }
        .padding()
        
        Button("Save") {
            // Save selected environment and update values if any
            EndpointManager.shared.update(environment: selectedEnv, apiKey: apiKey, httpEndpoint: httpEndpoint, socketEndpoint: httpEndpoint, uploadURL: uploadURL)
            saveButtonDidTap?()
        }
        
        Button("Reset") {
            EndpointManager.shared.resetEnvironments()
        }
    }
    
    func valueChange(_ tag: EnvironmentType) {
        config = EndpointManager.shared.getEndpointConfig(for: tag)
        httpEndpoint = config.httpEndpoint
        apiKey = config.apiKey
        uploadURL = config.uploadURL
    }
    
}

struct EndpointsView_Previews: PreviewProvider {
    static var previews: some View {
        EndpointsView()
    }
}
