//
//  AmityDraftClipPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 17/6/25.
//

import SwiftUI
import UIKit
import CoreMedia
import AVKit
import AVFoundation
import AmitySDK

public struct AmityDraftClipPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .draftClipPage
    }
    
    let videoURL: URL
    
    @StateObject private var viewConfig: AmityViewConfigController
    @State private var playVideo: Bool = true
    @State private var videoContentMode: UIView.ContentMode = .scaleAspectFill
    @State private var playTime: CMTime = .zero
    @State private var isMuted: Bool = false
    @StateObject var viewModel = AmityDraftClipPageViewModel()
    
    @StateObject var alert: ClipPostAlert = ClipPostAlert()
    
    let targetId: String
    let targetType: AmityPostTargetType
    let community: AmityCommunityModel?
    
    public init(targetId: String, targetType: AmityPostTargetType, community: AmityCommunityModel? = nil, clipURL: URL) {
        self.videoURL = clipURL
        self.targetId = targetId
        self.targetType = targetType
        self.community = community
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .draftClipPage))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            
            Color.black
                .opacity(1)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ZStack {
                    
                    VideoPlayer(url: videoURL, play: $playVideo, time: $playTime)
                        .mute(isMuted)
                        .contentMode(videoContentMode)
                        .autoReplay(true)
                        .cornerRadius(12)
                    
                    uploadProgressView
                        .visibleWhen(viewModel.isUploadingClip)
                }
                
                footerView
            }
            
            headerView
        }
        .alert(isPresented: $alert.isPresented) {
            if let dismissButton = alert.alertState.dismissButton {
                Alert(title: Text(alert.alertState.title), message: Text(alert.alertState.message), dismissButton: dismissButton)
            } else {
                Alert(title: Text(alert.alertState.title), message: Text(alert.alertState.message), primaryButton: alert.alertState.primaryButton, secondaryButton: alert.alertState.secondaryButton)
            }
        }
        .onAppear {
            viewModel.uploadClip(url: videoURL)
            
            // If video is uploaded & video is paused (incase you move to composer page)
            if let _ = viewModel.clipData, !playVideo {
                playVideo = true
            }
        }
        .onChange(of: viewModel.isUploadError) { isError in
            if isError {
                alert.show(for: .failedToUpload(action: {
                    self.host.controller?.navigationController?.popViewController(animated: true)
                }))
            }
        }
    }
    
    @ViewBuilder
    var uploadProgressView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.top)
            
            LiveStreamCircularProgressBar(progress: $viewModel.uploadProgress, config: LiveStreamCircularProgressBar.Config(backgroundColor: UIColor.white.withAlphaComponent(0.5), foregroundColor: UIColor.white, strokeWidth: 2, shouldAutoRotate: true))
                .frame(width: 40, height: 40)
        }
    }
    
    @ViewBuilder
    var headerView: some View {
        HStack(spacing: 8) {
            Button {
                alert.show(for: .discardClip(action: {
                    host.controller?.navigationController?.popViewController(animated: true)
                }))
            } label: {
                Image(AmityIcon.backArrowIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.white)
                    .padding(7)
                    .background(Color.black.opacity(0.5))
                    .clipped()
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button {
                isMuted.toggle()
            } label: {
                Image(isMuted ? AmityIcon.muteIcon.imageResource : AmityIcon.unmuteIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.white)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .clipped()
                    .clipShape(Circle())
            }
            .disabled(viewModel.isUploadingClip)
            .visibleWhen(!viewModel.isUploadingClip)
            
            Button {
                videoContentMode = videoContentMode == .scaleAspectFit ? .scaleAspectFill : .scaleAspectFit
            } label: {
                Image(AmityIcon.aspectRatioIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color.white)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .clipped()
                    .clipShape(Circle())
            }
            .disabled(viewModel.isUploadingClip)
            .visibleWhen(!viewModel.isUploadingClip)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .opacity(alert.isPresented ? 0.7 : 1)
    }
    
    @ViewBuilder
    var footerView: some View {
        ZStack(alignment: .bottom) {
            // Overlay which covers the home button safe area
            Color.black
                .edgesIgnoringSafeArea(.bottom)
                .frame(height: 50)
            
            // Button
            HStack {
                Spacer()
                
                Button {
                    guard let clipData = viewModel.clipData else { return }
                    
                    // Pause the video
                    playVideo = false
                    
                    let draft = AmityClipDraft(clipData: clipData, displayMode: videoContentMode == .scaleAspectFit ? .fit : .fill, isMuted: isMuted)
                    let createOptions: AmityPostComposerOptions = AmityPostComposerOptions.createOptions(mode: .createClip(url: videoURL, draft: draft), targetId: targetType == .user ? nil : targetId, targetType: targetType, community: community)
                    
                    let view = AmityPostComposerPage(options: createOptions)
                    let controller = AmitySwiftUIHostingController(rootView: view)
                    host.controller?.navigationController?.pushViewController(controller, animated: true)
                    
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                            .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                        
                        Image(AmityIcon.rightArrowIcon.imageResource)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.vertical, 10)
                    .background(Color(viewConfig.theme.backgroundColor))
                    .clipShape(Capsule())
                    .contentShape(Rectangle())
                }
                .disabled(viewModel.isUploadingClip)
                .visibleWhen(!viewModel.isUploadingClip)
                .opacity(alert.isPresented ? 0.7 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color.black)
        }
    }
}

open class AmityDraftClipPageBehavior {
    
    open class Context {
        
        let page: AmityDraftClipPage
        let clipURL: URL
        let clipData: AmityClipData
        let displayMode: AmityClipDisplayMode
        let isMuted: Bool
        let targetId: String
        let targetType: AmityPostTargetType
        let community: AmityCommunityModel?
        
        init(page: AmityDraftClipPage, clipURL: URL, clipData: AmityClipData, displayMode: AmityClipDisplayMode, isMuted: Bool, targetId: String, targetType: AmityPostTargetType, community: AmityCommunityModel?) {
            self.page = page
            self.clipURL = clipURL
            self.clipData = clipData
            self.displayMode = displayMode
            self.isMuted = isMuted
            self.targetId = targetId
            self.targetType = targetType
            self.community = community
        }
    }
    
    public init() { }
    
    open func goToPostComposerPage(context: AmityDraftClipPageBehavior.Context) {
        let draft = AmityClipDraft(clipData: context.clipData, displayMode: context.displayMode, isMuted: context.isMuted)
        let createOptions: AmityPostComposerOptions = AmityPostComposerOptions.createOptions(mode: .createClip(url: context.clipURL, draft: draft), targetId: context.targetType == .user ? nil : context.targetId, targetType: context.targetType, community: context.community)
        
        let view = AmityPostComposerPage(options: createOptions)
        let controller = AmitySwiftUIHostingController(rootView: view)
        context.page.host.controller?.navigationController?.pushViewController(controller, animated: true)
    }
}
