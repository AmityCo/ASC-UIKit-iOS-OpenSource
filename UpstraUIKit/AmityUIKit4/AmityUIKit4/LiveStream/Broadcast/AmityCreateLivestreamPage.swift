//
//  AmityCreateLivestreamPage.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 28/2/25.
//

import SwiftUI
import AVKit
import UIKit
import AmityLiveVideoBroadcastKit
import AmitySDK

public struct AmityCreateLivestreamPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .createLivestreamPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: AmityCreateLiveStreamViewModel
    @StateObject private var permissionChecker = LiveStreamPermissionChecker()
    @StateObject private var pickerViewModel = ImageVideoPickerViewModel()
    @StateObject private var liveStreamAlert = LiveStreamAlert.shared
            
    @State private var showThumbnailEditSheet = false
    @State private var showMediaPicker = false
    
    public init(targetId: String, targetType: AmityPostTargetType) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .userProfilePage))
        self._viewModel = StateObject(wrappedValue: AmityCreateLiveStreamViewModel(targetId: targetId, targetType: targetType))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            
            let isPermissionGranted = permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted
            if isPermissionGranted {
                LiveStreamBroadcastPreviewView(broadcaster: viewModel.broadcaster)
                    .readSize { previewSize in
                        viewModel.setupBroadcaster(previewSize: previewSize)
                    }
                    .edgesIgnoringSafeArea(.top)
            }
            
            // Overlay State:
            // Permission Request | Denied: Transparent (0%)
            // Permission Granted: Transparent (50%)
            // Stream Started: Transparent (100%)
            let isStreaming = viewModel.currentState.isStreaming
            
            let isBroadcastConnectedState = viewModel.broadcasterState == .connected
            let overlayOpacity = isStreaming && isBroadcastConnectedState && !viewModel.isLiveStreamEndCountdownStarted ? 0 : isPermissionGranted ? 0.5 : 1
            Color.black
                .opacity(overlayOpacity)
                .edgesIgnoringSafeArea(.all)
            
            // Setup View
            let isPermissionDenied = permissionChecker.cameraPermissionState == .denied || permissionChecker.microphonePermissionState == .denied
            ZStack(alignment: .bottom) {
                
                // Stack #1
                // Overlay which covers the home button safe area
                Color.black
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(height: 50)
                
                // Stack #2 Editor
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {
                            headerView
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .opacity(isPermissionDenied ? 0 : 1)
                            
                            LiveStreamSetupView(viewModel: viewModel, permissionChecker: permissionChecker)
                                .onTapGesture {
                                    hideKeyboard()
                                }
                                .opacity(viewModel.currentState != .setup ? 0 : 1)
                        }
                        
                        liveStreamStartingState
                            .visibleWhen(viewModel.currentState == .started)
                        
                        // Previous state should be disconnected or connected
                        liveStreamReconnectingState
                            .visibleWhen(viewModel.currentState == .streaming && viewModel.isReconnecting) // We do not want to show reconnecting state when stream is about to end as live timer is still running while it tries to reconnect.
                        
                        liveStreamEndingCountdownState
                            .visibleWhen(viewModel.isLiveStreamEndCountdownStarted)
                    }
                    
                    footerView
                }
            }
            
            // Stack #3 Permission View
            VStack {
                headerView
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                
                LiveStreamPermissionView(info: .cameraAndMicrophone)
            }
            .opacity(isPermissionDenied ? 1 : 0)
        }
        .ignoresSafeArea(.keyboard)
        .updateTheme(with: viewConfig)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            
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
        .alert(isPresented: $liveStreamAlert.isPresented, content: {
            if let dismissButton = liveStreamAlert.alertState.dismissButton {
                Alert(title: Text(liveStreamAlert.alertState.title), message: Text(liveStreamAlert.alertState.message), dismissButton: dismissButton)
            } else {
                Alert(title: Text(liveStreamAlert.alertState.title), message: Text(liveStreamAlert.alertState.message), primaryButton: liveStreamAlert.alertState.primaryButton, secondaryButton: liveStreamAlert.alertState.secondaryButton)
            }
        })
        .onChange(of: viewModel.currentState) { newValue in
            switch newValue {
            case .ending:
                Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Social.liveStreamToastEndAtMaxDurationMessage.localizedString)
                
            case .ended(let reason):
                let postId = viewModel.createdPost?.postId ?? ""
                
                if reason == .manual {
                    
                    self.dismissToPostDetailPage(postId: postId)
                    
                    return
                }
                
                if reason == .connectionIssue {
                    
                    self.dismissToPostDetailPage(postId: postId)
                    
                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.General.noInternetConnection.localizedString)
                    
                    return
                }
                
                if reason == .maxDuration {
                    liveStreamAlert.show(for: .streamEndedDueToMaxDuration(action: {
                        self.dismissToPostDetailPage(postId: postId)
                    }))
                    return
                }
                
                // Show terminated page
                if reason == .terminated {
                    let terminatedVc = AmitySwiftUIHostingController(rootView: AmityLivestreamTerminatedPage(type: .streamer))
                    terminatedVc.modalPresentationStyle = .overFullScreen
                    self.host.controller?.navigationController?.pushViewController(terminatedVc, animated: false)
                    return
                }
            default:
                break
            }
        }
    }
    
    func dismissToPostDetailPage(postId: String) {
        self.host.controller?.dismiss(animated: true, completion: {
            
            // Move to post detail page
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let postDetailPage = AmityPostDetailPage(id: postId)
                let topController = UIApplication.topViewController()
                topController?.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: postDetailPage))
            }
        })
    }
    
    @ViewBuilder
    var liveStreamStartingState: some View {
        VStack {
            Spacer()
            
            LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                .frame(width: 40, height: 40)
            
            Text(AmityLocalizedStringSet.Social.liveStreamStartingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    var liveStreamReconnectingState: some View {
        VStack {
            Spacer()
            
            LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config(strokeWidth: 2))
                .frame(width: 40, height: 40)
            
            Text(AmityLocalizedStringSet.Social.liveStreamReconnectingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            Text(AmityLocalizedStringSet.Social.liveStreamReconnectingStateMessage.localizedString)
                .applyTextStyle(.caption(Color.white))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    var liveStreamEndingCountdownState: some View {
        VStack {
            Spacer()
            
            Text(AmityLocalizedStringSet.Social.liveStreamEndingStateTitle.localizedString)
                .applyTextStyle(.titleBold(Color.white))
                .padding(.top, 12)
            
            LivestreamCountdownTimer(totalCountdown: 10, currentCountdown: $viewModel.liveStreamEndCountdown)
                .frame(width: 72, height: 72)
                .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    
    @ViewBuilder
    var headerView: some View {
        HStack {
            if viewModel.currentState == .setup {
                Button {
                    let dismissAction = {
                        host.controller?.dismiss(animated: true)
                    }
                    if !viewModel.streamDescription.isEmpty || !viewModel.streamTitle.isEmpty || viewModel.selectedImage != nil {
                        liveStreamAlert.show(for: .streamDiscard(action: {
                            dismissAction()
                        }))
                    } else {
                        dismissAction()
                    }
                } label: {
                    Image(AmityIcon.LiveStream.close.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.white)
                        .padding(2)
                        .background(Color.black.opacity(0.5))
                        .clipped()
                        .clipShape(Circle())
                }
                
                Spacer(minLength: 24)
                
                Button {
                    let context = AmityLivestreamPostTargetSelectionPage.Context(onSelection: { selectedTarget in
                        if let selectedTarget {
                            viewModel.targetDisplayName = selectedTarget.displayName
                        } else {
                            viewModel.targetDisplayName = AmityLocalizedStringSet.Social.liveStreamMyTimelineLabel.localizedString
                        }
                    }, isOpenedFromLiveStreamPage: true)
                    let view = AmityLivestreamPostTargetSelectionPage(context: context)
                    let controller = AmitySwiftUIHostingController(rootView: view)
                    controller.modalPresentationStyle = .fullScreen
                    host.controller?.navigationController?.present(controller, animated: true)
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Text(AmityLocalizedStringSet.Social.liveStreamTargetLiveOnLabel.localizedString)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.white)
                            .lineLimit(1)
                        
                        Text(viewModel.targetDisplayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.white)
                            .lineLimit(1)
                        
                        Image(AmityIcon.LiveStream.targetSelectionArrow.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(Color.white)
                    }
                }
            }
            else {
                Text(AmityLocalizedStringSet.Social.liveStreamDurationLabel.localized(arguments: "\(viewModel.liveDuration)"))
                    .applyTextStyle(.captionBold(.white))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#FF305A"))
                    .cornerRadius(4, corners: .allCorners)
                    .visibleWhen(viewModel.currentState.isStreaming)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var footerView: some View {
        HStack {
            if viewModel.currentState == .setup {
                thumbnailButton
                    .bottomSheet(isShowing: $showThumbnailEditSheet, height: .contentSize, sheetContent: {
                        VStack(spacing: 0) {
                            BottomSheetItemView(icon: AmityIcon.LiveStream.thumbnail.imageResource, text: AmityLocalizedStringSet.Social.liveStreamChangeThumbnailLabel.localizedString).onTapGesture {
                                showThumbnailEditSheet.toggle()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showMediaPicker.toggle()
                                }
                            }
                            
                            BottomSheetItemView(icon: AmityIcon.trashBinRedIcon.imageResource, text: AmityLocalizedStringSet.Social.liveStreamDeleteThumbnailLabel.localizedString, iconSize: CGSize(width: 20, height: 18), isDestructive: true).onTapGesture {
                                showThumbnailEditSheet.toggle()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.selectedImage = nil
                                }
                            }
                        }
                        .padding(.bottom, 64)
                    })
                    .fullScreenCover(isPresented: $showMediaPicker, content: {
                        MultiSelectionMediaPicker(viewModel: pickerViewModel, mediaType: .constant(.images), sourceType: .constant(.photoLibrary), selectionLimit: 1)
                    })
                    .onChange(of: pickerViewModel.selectedImages) { newValue in
                        guard !newValue.isEmpty else { return }
                        viewModel.selectedImage = newValue.first
                        
                        // Upload thumbnail
                        viewModel.uploadThumbnail(image: newValue.first)
                    }
            } else {
                Button {
                    liveStreamAlert.show(for: .streamEndedManually(action: {
                        viewModel.endLiveStream(reason: .manual)
                    }))
                } label: {
                    Text(AmityLocalizedStringSet.Social.liveStreamEndLiveLabel.localizedString)
                        .applyTextStyle(.bodyBold(Color.white))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .border(radius: 8, borderColor: Color.white, borderWidth: 1)
                }
                .buttonStyle(.plain)
                .visibleWhen(viewModel.currentState == .streaming)
            }
            
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
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.vertical, 21)
        .background(Color.black)
    }
    
    
    @ViewBuilder
    var thumbnailButton: some View {
        
        if let selectedImage = viewModel.selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 40)
                .clipped()
                .continuousCornerRadius(4)
                .border(radius: 4, borderColor: .white, borderWidth: 1)
                .overlay(
                    ZStack {
                        Color.black.opacity(0.5)
                        
                        LiveStreamCircularProgressBar(progress: $viewModel.thumbnailUploadProgress, config: LiveStreamCircularProgressBar.Config(backgroundColor: UIColor.white.withAlphaComponent(0.5), foregroundColor: UIColor.white, strokeWidth: 2, shouldAutoRotate: true))
                            .frame(width: 24, height: 24)
                    }
                        .opacity(viewModel.isUploadingThumbnail && viewModel.thumbnailUploadProgress <= 100 ? 1 : 0)
                )
                .onTapGesture {
                    pickerViewModel.selectedImages = []
                    
                    showThumbnailEditSheet.toggle()
                }
        } else {
            Button {
                showMediaPicker.toggle()
            } label: {
                HStack {
                    Image(AmityIcon.LiveStream.thumbnail.imageResource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                    
                    Text(AmityLocalizedStringSet.Social.liveStreamAddThumbnailLabel.localizedString)
                        .foregroundColor(Color.white)
                        .font(.system(size: 13, weight: .semibold))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 4)
            }
        }
    }

}

struct LiveStreamSetupView: View {
    
    @ObservedObject var viewModel: AmityCreateLiveStreamViewModel
    @ObservedObject var permissionChecker: LiveStreamPermissionChecker
    @StateObject var networkMonitor = NetworkMonitor()
    
    private let liveStreamTitleCharLimit = 30
    
    var body: some View {
        VStack(spacing: 0) {
            let isPermissionGranted = permissionChecker.cameraPermissionState == .granted && permissionChecker.microphonePermissionState == .granted
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    titleTextField
                        .padding(.top, 16)
                    
                    descTextField
                        .padding(.top, 12)
                }
                .padding(.horizontal)
            }
            .padding(.top, 8)
            .opacity(isPermissionGranted && viewModel.currentState == .setup ? 1 : 0)
            
            Button {
                guard networkMonitor.isConnected else {
                    LiveStreamAlert.shared.show(for: .streamError)
                    return
                }
                
                viewModel.startStream(title: viewModel.streamTitle, description: viewModel.streamDescription)
            } label: {
                let isShutterButtonDisabled = viewModel.streamTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isUploadingThumbnail
                Image(isShutterButtonDisabled ? AmityIcon.LiveStream.shutterButtonDisabled.imageResource : AmityIcon.LiveStream.shutterButtonEnabled.imageResource)
            }
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var titleTextField: some View {
        ZStack(alignment: .leading) {
            Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamTitle.localizedString)
                .foregroundColor(Color.white.opacity(0.8))
                .font(.system(size: 24, weight: .bold))
                .opacity(viewModel.streamTitle.isEmpty ? 1 : 0)
            
            TextField("", text: $viewModel.streamTitle)
                .foregroundColor(Color.white)
                .font(.system(size: 24, weight: .bold))
                .onChange(of: viewModel.streamTitle) { newValue in
                    guard newValue.count > liveStreamTitleCharLimit else { return }
                    viewModel.streamTitle = String(newValue.prefix(30))
                }
        }
    }
    
    @ViewBuilder
    private var descTextField: some View {
        if #available(iOS 16.0, *) {
            ZStack(alignment: .leading) {
                Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamDesc.localizedString)
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.system(size: 15, weight: .regular))
                    .opacity(viewModel.streamDescription.isEmpty ? 1 : 0)
                
                TextField("", text: $viewModel.streamDescription, axis: .vertical)
                    .foregroundColor(Color.white)
                    .font(.system(size: 15, weight: .regular))
            }
        } else {
            ZStack(alignment: .leading) {
                Text(AmityLocalizedStringSet.Social.liveStreamInputAddStreamDesc.localizedString)
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(.system(size: 15, weight: .regular))
                    .opacity(viewModel.streamDescription.isEmpty ? 1 : 0)
                
                TextField("", text: $viewModel.streamDescription)
                    .foregroundColor(Color.white)
                    .font(.system(size: 15, weight: .regular))
            }
        }
    }
}

// Helper modifiers

struct VisibleModifier: ViewModifier {
    
    var condition: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(condition ? 1 : 0)
    }
}

extension View {
    
    func visibleWhen(_ condition: Bool) -> some View {
        self
            .modifier(VisibleModifier(condition: condition))
    }
}

// social home page - target selection (present)
