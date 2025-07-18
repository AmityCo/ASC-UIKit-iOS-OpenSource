//
//  AmityLivestreamBannedPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/25/25.
//

import SwiftUI

public struct AmityLivestreamBannedPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController
    
    private var onDismiss: (() -> Void)? = nil
    
    public var id: PageId {
        return .liveStreamBannedPage
    }
    
    public init(onDismiss: (() -> Void)? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .liveStreamBannedPage))
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            AmityNavigationBar(title: "Live stream", showBackButton: false, showDivider: true)
            
            Spacer()
            
            VStack(spacing: 12) {
                Image(AmityIcon.triangleErrorIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(viewConfig.theme.baseColor))
                    .frame(width: 56, height: 42)
                
                Text("You've been banned.")
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .multilineTextAlignment(.center)
                
                Text("You can no longer access this live stream.")
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade1)))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(viewConfig.theme.baseColorShade4))
                    .frame(height: 1)
                
                Button {
                    host.controller?.dismiss(animated: true) {
                        onDismiss?()
                    }
                } label: {
                    Text("OK")
                        .applyTextStyle(.bodyBold(.white))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 40)
                .background(Color(viewConfig.theme.primaryColor))
                .cornerRadius(8, corners: .allCorners)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .updateTheme(with: viewConfig)
    }
}
