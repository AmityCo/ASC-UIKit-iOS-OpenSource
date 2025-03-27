//
//  LiveStreamPermissionView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 7/3/25.
//

import SwiftUI

struct LiveStreamPermission {
    
    let title: String
    let message: String
    
    static let cameraAndMicrophone = LiveStreamPermission(title: AmityLocalizedStringSet.Social.liveStreamPermissionCameraAndMicrophoneTitle.localizedString, message: AmityLocalizedStringSet.Social.liveStreamPermissionCameraAndMicrophoneMessage.localizedString)
    static let photos = LiveStreamPermission(title: "Allow access to your photos", message: "This lets you use photos from this device as live stream thumbnail image.")
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

struct LiveStreamPermissionView: View {
    
    let info: LiveStreamPermission
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
            
            VStack(spacing: 0) {
                Spacer()
                
                Text(info.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                
                Text(info.message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(AmityLocalizedStringSet.Social.liveStreamPermissionOpenSettingsLabel.localizedString)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .background(Color.blue)
                .cornerRadius(8)
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

#if DEBUG
#Preview {
    LiveStreamPermissionView(info: LiveStreamPermission.cameraAndMicrophone)
}
#endif
