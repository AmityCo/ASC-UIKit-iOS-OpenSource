//
//  SettingToggleButtonView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/26/24.
//

import SwiftUI

struct SettingToggleButtonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let isEnabled: Binding<Bool>
    private let title: String
    private let description: String
    
    init(isEnabled: Binding<Bool>, title: String, description: String) {
        self.isEnabled = isEnabled
        self.title = title
        self.description = description
    }
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 6) {
                Text(title)
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Toggle("", isOn: isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(viewConfig.theme.primaryColor)))
                .frame(width: 48, height: 28)
        }
        .contentShape(Rectangle())
    }
}
