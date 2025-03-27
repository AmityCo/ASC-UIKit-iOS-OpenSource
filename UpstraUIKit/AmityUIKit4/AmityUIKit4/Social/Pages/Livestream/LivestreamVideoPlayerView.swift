//
//  LivestreamVideoPlayerView.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import SwiftUI

struct LivestreamVideoPlayerView: View {
    
    @StateObject private var viewConfig: AmityViewConfigController = AmityViewConfigController(pageId: nil)
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper
    @State private var showOverlay = false
    @State private var opacity = 0.0
    @State private var isPlaying = true
    @StateObject var networkMonitor = NetworkMonitor()
    @State var degreesRotating = 0.0
    
    private let debouncer = Debouncer(delay: 2)
    @StateObject var viewModel: LivestreamVideoPlayerViewModel
    
    init(post: AmityPostModel) {
        self._viewModel = StateObject(wrappedValue: LivestreamVideoPlayerViewModel(post: post))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
                .ignoresSafeArea()
            
            if let stream = viewModel.stream {
                let streamTerminationLabels = stream.moderation?.terminateLabels ?? []
                if !streamTerminationLabels.isEmpty {
                    VStack(alignment: .center) {
                        Image(AmityIcon.livestreamErrorIcon.getImageResource())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .padding(.bottom, 12)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedTitle.localizedString)
                            .applyTextStyle(.titleBold(Color.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerTerminatedMessage.localizedString)
                            .applyTextStyle(.caption(Color.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                } else if stream.status == .ended {
                    VStack(alignment: .center) {
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedTitle.localizedString)
                            .applyTextStyle(.titleBold(Color.white))
                            .padding(.bottom, 4)
                        
                        Text(AmityLocalizedStringSet.Social.livestreamPlayerEndedMessage.localizedString)
                            .applyTextStyle(.caption(Color.white))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack {
                            Text(AmityLocalizedStringSet.Social.livestreamPlayerLive.localizedString)
                                .applyTextStyle(.captionBold(Color.white))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(UIColor(hex: "FF305A")))
                                .cornerRadius(4, corners: .allCorners)
                                .padding(.all, 16)
                        }
                        
                        if let view = AmityUIKitManagerInternal.shared.behavior.livestreamBehavior?.createLivestreamPlayer(stream: stream, client: AmityUIKit4Manager.client, isPlaying: $isPlaying.wrappedValue && networkMonitor.isConnected) {
                            AnyView(view)
                                .padding(.bottom, 70)
                        }
                    }
                }
                // Stream is not available but request to fetch stream is complete.
            } else if viewModel.isLoaded {
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamErrorIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerUnavailableMessage.localizedString)
                        .applyTextStyle(.caption(Color.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            }
            
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(alignment: .center) {
                    Image(AmityIcon.livestreamReconnectingIcon.imageResource)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(degreesRotating))
                        .padding(.bottom, 12)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerReconnectingTitle.localizedString)
                        .applyTextStyle(.titleBold(Color.white))
                        .padding(.bottom, 4)
                    
                    Text(AmityLocalizedStringSet.Social.livestreamPlayerReconnectingMessage.localizedString)
                        .applyTextStyle(.caption(Color.white))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    withAnimation(.linear(duration: 1)
                        .speed(1).repeatForever(autoreverses: false)) {
                            degreesRotating = 360.0
                        }
                }
            }
            .opacity(networkMonitor.isConnected ? 0 : 1)
                        
            VStack {
                HStack {
                    Image(AmityIcon.livestreamCloseIcon.imageResource)
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .onTapGesture {
                            viewModel.unobservePostAndStream()
                            
                            host.controller?.dismiss(animated: true)
                        }
                    
                    Spacer()
                }
                .padding(.leading, 36)
                .padding(.top, 10)
                
                Spacer()
                
                Image(isPlaying ? AmityIcon.livestreamPauseIcon.getImageResource() : AmityIcon.videoControlIcon.getImageResource())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .onTapGesture {
                        displayOverlay()
                        isPlaying.toggle()
                    }
                
                Spacer()
            }
            .opacity(opacity)
            .animation(.easeInOut(duration: opacity == 0 ? 1.0 : 0), value: opacity)
            
            PostDetailEmptyStateView(action: {
                viewModel.unobservePostAndStream()
                
                host.controller?.dismiss(animated: true)
            })
            .ignoresSafeArea()
            .opacity(viewModel.isPostDeleted ? 1 : 0)
            .onChange(of: viewModel.isPostDeleted) { isDeleted in
                if isDeleted {
                    isPlaying = false
                }
            }
        }
        .onTapGesture {
            displayOverlay()
        }
        .onChange(of: viewModel.isStreamTerminated) { isTerminated in
            guard isTerminated else { return }
            
            // Show terminated screen
            let terminatedVc = AmitySwiftUIHostingController(rootView: AmityLivestreamTerminatedPage(type: .watcher, onDismiss: {
                viewModel.unobservePostAndStream()
            }))
            terminatedVc.modalPresentationStyle = .overFullScreen
            self.host.controller?.navigationController?.pushViewController(terminatedVc, animated: false)
            
            // Stop player
            isPlaying = false
        }
    }
    
    func displayOverlay() {
        opacity = 1.0
        
        debouncer.run {
            opacity = 0.0
        }
    }
}
