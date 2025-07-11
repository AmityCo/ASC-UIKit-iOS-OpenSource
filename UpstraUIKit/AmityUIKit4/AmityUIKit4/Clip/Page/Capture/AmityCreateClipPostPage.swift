//
//  AmityCreateClipPostPage.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 16/6/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import AmitySDK

public struct AmityCreateClipPostPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .createClipPostPage
    }
    
    @StateObject private var videoPicker = ImageVideoPickerViewModel()
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var permissionChecker = LiveStreamPermissionChecker()
    @StateObject private var viewModel = AmityCreateClipPostPageViewModel()
    
    @State private var videoCaptureProgress: Double = 0
    @State private var showVideoPicker = false
    
    let targetId: String
    let targetType: AmityPostTargetType
    let community: AmityCommunityModel?
    
    public init(targetId: String, targetType: AmityPostTargetType, community: AmityCommunityModel? = nil) {
        self.targetId = targetId
        self.targetType = targetType
        self.community = community
        
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .createClipPostPage))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            
            Color.black
                .opacity(1)
                .edgesIgnoringSafeArea(.all)

            CameraPreviewView(cameraManager: viewModel.cameraManager, outputMode: .videoWithMic)
                .cornerRadius(12)
                .visibleWhen(permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted)
            
            VStack {
                headerView
                    .opacity(permissionChecker.cameraPermissionState == .notDetermined && permissionChecker.microphonePermissionState == .notDetermined ? 0.5 : 1)
                
                contentView
                
                footerView
            }
            
        }
        .ignoresSafeArea(.keyboard)
        .updateTheme(with: viewConfig)
        .onAppear {
            // Update permission status
            permissionChecker.checkCameraAndMicrophonePermissionStatus()
            
            // Handle Permission Stuffs
            Task {
                if permissionChecker.shouldAskForCameraPermission() {
                    await permissionChecker.requestCameraPermission()
                }
                
                if permissionChecker.shouldAskForMicrophonePermission() && permissionChecker.cameraPermissionState == .granted {
                    await permissionChecker.requestAudioPermission()
                }
            }
        }
        .alert(isPresented: $viewModel.clipPostAlert.isPresented) {
            Alert(title: Text(viewModel.clipPostAlert.alertState.title), message: Text(viewModel.clipPostAlert.alertState.message), dismissButton: viewModel.clipPostAlert.alertState.dismissButton)
        }
        .sheet(isPresented: $showVideoPicker) {
            ImageVideoPicker(viewModel: videoPicker, mediaType: [UTType.movie])
        }
        .onChange(of: videoPicker.selectedMediaURL) { value in
            guard let selectedMedia = videoPicker.selectedMedia, selectedMedia == UTType.movie.identifier else {
                Log.add(event: .error, "Selected media should not be nil")
                return
            }
            
            viewModel.processSelectedMedia(url: videoPicker.selectedMediaURL)
        }
        .onChange(of: viewModel.videoURL) { url in
            if let url {
                let page = AmityDraftClipPage(targetId: targetId, targetType: targetType, community: community, clipURL: url)
                let hostingWrapper = AmitySwiftUIHostingController(rootView: page)
                self.host.controller?.navigationController?.pushViewController(hostingWrapper, animated: true)
            }
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        ZStack(alignment: .bottom) {
            videoCaptureButton
                .padding(.bottom, 32)
            
            let info = LiveStreamPermission(title: AmityLocalizedStringSet.Social.liveStreamPermissionCameraAndMicrophoneTitle.localizedString, message: "This lets you record videos\nfrom this device.")
            LiveStreamPermissionView(info: info)
                .visibleWhen(permissionChecker.shouldAskForCameraPermission() || permissionChecker.shouldAskForMicrophonePermission())
        }
    }
    
    @ViewBuilder
    var videoCaptureButton: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 72, height: 72)
                .visibleWhen(viewModel.isCapturingVideo)
            
            Image(viewModel.isCapturingVideo ? AmityIcon.clipVideoStopButton.imageResource : AmityIcon.clipVideoStartButton.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: viewModel.isCapturingVideo ? 48 : 72, height: viewModel.isCapturingVideo ? 48 : 72)
            
            Circle()
                .trim(from: 0, to: viewModel.videoCaptureProgress)
                .stroke(Color(hex: "#FF305A"), style: StrokeStyle(lineWidth: 7, lineCap: .square))
                .rotationEffect(.degrees(-90))
                .frame(width: 66, height: 66)
                .visibleWhen(viewModel.isCapturingVideo)
        }
        .onTapGesture {
            if viewModel.isCapturingVideo {
                viewModel.stopCapture()
            } else {
                viewModel.startCapture()
            }
        }
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
                Button {
                    self.showVideoPicker = true
                } label: {
                    Image(AmityIcon.clipThumbnailIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .visibleWhen(!viewModel.isCapturingVideo)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    viewModel.switchCamera()
                } label: {
                    Image(AmityIcon.LiveStream.switchCamera.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .disabled(permissionChecker.cameraPermissionState != .granted || permissionChecker.microphonePermissionState != .granted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color.black)
        }
    }
    
    @ViewBuilder
    var headerView: some View {
        HStack {
            if viewModel.isCapturingVideo {
                Spacer()
                
                Text(viewModel.videoDurationLabel)
                    .applyTextStyle(.bodyBold(.white))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(hex: "#FF305A"))
                    .cornerRadius(4, corners: .allCorners)
                    .visibleWhen(viewModel.isCapturingVideo)
                
                Spacer()
            } else {
                Button {                    
                    host.controller?.dismiss(animated: true)
                } label: {
                    Image(AmityIcon.LiveStream.close.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.white)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .clipped()
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    viewModel.toggleFlash()
                } label: {
                    Image(viewModel.cameraFlashMode == .off ? AmityIcon.flashOffIcon.imageResource : AmityIcon.flashOnIcon.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color.white)
                        .padding(4)
                }
                .visibleWhen(permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
