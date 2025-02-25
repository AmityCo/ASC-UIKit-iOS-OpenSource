//
//  AmityUserProfileImageView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/17/24.
//

import SwiftUI

struct AmityUserProfileImageView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let displayName: String
    let avatarURL: URL?
    var onLoaded: ((Bool) -> Void)?
    
    init(displayName: String, avatarURL: URL?) {
        let name = "\(displayName.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " ")"
        self.displayName = name.uppercased()
        self.avatarURL = avatarURL
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Circle()
                    .fill(Color(viewConfig.theme.primaryColor.blend(.shade2)))
                    .overlay (
                        Text(displayName)
                            .applyTextStyle(.custom(geometry.size.height * 0.55, .regular, .white))
                    )
                
                AsyncImage(url: avatarURL)
                    .onLoaded(onLoaded)
            }
        }
    }
}

extension AmityUserProfileImageView: AmityViewBuildable {
    public func onLoaded(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onLoaded, value: callback)
    }
}
