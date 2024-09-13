//
//  NotificationSettingView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 8/27/24.
//

import SwiftUI


struct CommunityNotificationSettingView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    private let title: String
    private let description: String
    @Binding private var selectedSetting: CommunityNotificationSettingOption
    
    init(title: String, description: String, selectedSetting: Binding<CommunityNotificationSettingOption>) {
        self.title = title
        self.description = description
        self._selectedSetting = selectedSetting
    }
    
    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            SettingRadioButtonView(isSelected: selectedSetting == .everyone, text: AmityLocalizedStringSet.Social.communityNotificationSettingOptionEveryone.localizedString)
                .onTapGesture {
                    selectedSetting = .everyone
                }
            
            SettingRadioButtonView(isSelected: selectedSetting == .onlyModerator, text: AmityLocalizedStringSet.Social.communityNotificationSettingOptionOnlyModerator.localizedString)
                .onTapGesture {
                    selectedSetting = .onlyModerator
                }
            
            SettingRadioButtonView(isSelected: selectedSetting == .off, text: AmityLocalizedStringSet.Social.communityNotificationSettingOptionOff.localizedString)
                .onTapGesture {
                    selectedSetting = .off
                }
        }
    }
}
