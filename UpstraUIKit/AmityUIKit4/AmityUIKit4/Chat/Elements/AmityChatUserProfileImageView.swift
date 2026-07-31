//
//  AmityChatUserProfileImageView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/17/24.
//

import SwiftUI

struct AmityChatUserProfileImageView: View {

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
                    .fill(Color(viewConfig.color(.surfaceAvatarProfileDefault)))
                    .overlay (
                        Text(displayName)
                            .applyTextStyle(.custom(geometry.size.height * 0.55, .regular, Color(viewConfig.color(.textAvatarAtomicGeneral))))
                    )

                AsyncImage(url: avatarURL)
                    .onLoaded(onLoaded)
                    .clipShape(Circle())
            }
        }
    }
}

extension AmityChatUserProfileImageView: AmityViewBuildable {
    public func onLoaded(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onLoaded, value: callback)
    }
}
