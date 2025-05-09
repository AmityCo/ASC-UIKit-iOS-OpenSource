//
//  ContentReportSuccessView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 29/4/25.
//

import SwiftUI

struct ContentReportSuccessView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                Image(AmityIcon.reportSuccessIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(Color(viewConfig.theme.primaryColor))
                
                Text("Thanks for your report.")
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColor)))
                    .padding(.top, 16)
                
                Text("Our moderators will review this content and take action if it violates our guidelines.")
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade2)))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Divider()
            
            Button(AmityLocalizedStringSet.Social.reportReasonDoneButton.localizedString) {
                action?()
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .padding(16)
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}

struct ContentReportErrorView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                Image(AmityIcon.emptyStateExplore.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 40)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade2))
                
                Text(AmityLocalizedStringSet.Social.postDetailDeletedPostTitle.localizedString)
                    .applyTextStyle(.headline(Color(viewConfig.theme.baseColorShade3)))
                    .padding(.top, 16)
                
                Text(AmityLocalizedStringSet.Social.postDetailDeletedPostMessage.localizedString)
                    .applyTextStyle(.body(Color(viewConfig.theme.baseColorShade3)))
                    .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            Divider()
            
            Button(AmityLocalizedStringSet.Social.reportReasonCloseButton.localizedString) {
                action?()
            }
            .buttonStyle(AmityPrimaryButtonStyle(viewConfig: viewConfig))
            .padding(16)
        }
        .background(Color(viewConfig.theme.backgroundColor))
    }
}
