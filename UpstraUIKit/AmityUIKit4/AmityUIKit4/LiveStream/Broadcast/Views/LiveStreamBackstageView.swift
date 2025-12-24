//
//  LiveStreamBackstageView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/24/25.
//

import Foundation
import SwiftUI

struct LiveStreamBackstageView: View {
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    @ObservedObject var broadcasterViewModel: LiveStreamBroadcasterViewModel
    @StateObject private var permissionChecker = LiveStreamPermissionChecker()
    
    private let post: AmityPostModel
    private let onJoin: () -> Void
    private let onDismiss: () -> Void
    
    init(post: AmityPostModel, viewModel: LiveStreamBroadcasterViewModel, onJoin: @escaping () -> Void , onDismiss: @escaping () -> Void) {
        self.post = post
        self.broadcasterViewModel = viewModel
        self.onJoin = onJoin
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            let isPermissionGranted = permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted
            if isPermissionGranted {
                LiveStreamBroadcasterView(viewModel: broadcasterViewModel)
                    .dismissKeyboardOnDrag()
                    .padding(.bottom, 21) // footer view has 21 bottom padding
            }
            
            Color.black
                .edgesIgnoringSafeArea(.bottom)
                .frame(height: 50)
            
            VStack(spacing: 8) {
                headerView
                
                Spacer()
                
                joinBannerView
                    .padding(.horizontal, 16)
                
                footerView
            }
            
            let isPermissionDenied = permissionChecker.cameraPermissionState == .denied || permissionChecker.microphonePermissionState == .denied
            LiveStreamPermissionView(info: .cameraAndMicrophone)
                .opacity(isPermissionDenied ? 1 : 0)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                Image(AmityIcon.LiveStream.close.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 28)
                    .foregroundColor(Color.white)
                    .padding(2)
                    .onTapGesture {
                        onDismiss()
                    }
            
                Image(AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .circularBackground(radius: 34, color: .black.opacity(0.4))
                    .offset(x: 4, y: 46)
                    .visibleWhen(!broadcasterViewModel.enableMicrophone)
            }
        
            Spacer()
            
            Text(AmityLocalizedStringSet.Social.livestreamBackstageHeaderTitle.localizedString)
                .applyTextStyle(.body(.white))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var joinBannerView: some View {
        VStack(spacing: 16) {
            Text(AmityLocalizedStringSet.Social.livestreamBackstageSetupMessage.localizedString)
                .applyTextStyle(.body(.white))
                .multilineTextAlignment(.center)
            
            Button {
                onJoin()
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    
                    Image(AmityIcon.LiveStream.hostIcon.imageResource)
                        .resizable()
                        .frame(width: 20, height: 16)
                        .aspectRatio(contentMode: .fill)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamBackstageJoinLiveButton.localizedString)
                        .applyTextStyle(.bodyBold(.white))
                    
                    Spacer()
                }
                .padding(.all, 16)
                .background(Color.red)
                .cornerRadius(8.0, corners: .allCorners)
            }
        }
        .padding(.all, 16)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8.0, corners: .allCorners)
    }
    
    @ViewBuilder
    private var footerView: some View {
        HStack(spacing: 10) {
            Spacer()
            
            Button {
                broadcasterViewModel.toggleMicrophone()
            } label: {
                Image(broadcasterViewModel.enableMicrophone ? AmityIcon.LiveStream.mic.imageResource : AmityIcon.LiveStream.unmuteMic.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 4)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
            
            Button {
                broadcasterViewModel.switchCamera()
            } label: {
                Image(AmityIcon.LiveStream.switchCamera.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 4)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.vertical, 21)
        .background(Color.black)
    }
}
