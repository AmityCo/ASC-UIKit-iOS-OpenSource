//
//  AmityMediaPlayer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AVFoundation
import AVKit

// Note:
// Migrate to this AmityMediaPlayer from existing VideoPlayer implementation. Existing VideoPlayer has issue
// where it re-renders the player layer whenever its modifier is modified.

/// Wraps AVPlayer & AVPPlayerLayer in UIViewRepresentable. This class interacts with its controller to handle
/// playback. Controller supports
/// - play / pause
/// - seek
/// - mute / unmute
/// - Thumbnail generation for current video
struct AmityMediaPlayer: UIViewRepresentable {
    let url: URL
    
    @ObservedObject
    var controller: AmityMediaPlayerController
    
    init(url: URL, controller: AmityMediaPlayerController) {
        self.url = url
        self.controller = controller
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"
        ]
                
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.layer.addSublayer(playerLayer)

        controller.configure(playerLayer: playerLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}

struct AmityCustomMediaPlayer: View {
    let url: URL
    var onBackgroundTap: ((Bool) -> Void)? = nil
    @State var hideOverlay: Bool = false
    private let overlayDebouncer = Debouncer(delay: 2)
    @StateObject var playerController = AmityMediaPlayerController()
    @State private var sliderValue: Double = 0

    init(url: URL, onBackgroundTap: ((Bool) -> Void)? = nil) {
        self.url = url
        self.onBackgroundTap = onBackgroundTap
    }

    var body: some View {
        ZStack {
            AmityMediaPlayer(url: url, controller: playerController)
                .onTapGesture {
                    withAnimation {
                        hideOverlay.toggle()
                        onBackgroundTap?(hideOverlay)
                    }
                }

            HStack(spacing: 20) {
                Button(action: {
                    playerController.skipBackward()
                }) {
                    Image(systemName: "gobackward.10")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: {
                    playerController.togglePlayPause()
                }) {
                    Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                Button(action: {
                    playerController.skipForward()
                }) {
                    Image(systemName: "goforward.10")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .opacity(hideOverlay ? 0 : 1)
            .background(Color.clear)
            
            VStack(spacing: 0) {
                Spacer()

                VideoSeekBar(
                    value: $sliderValue,
                    range: 0...max(playerController.duration, 1),
                    onEditingChanged: { editing in
                        if editing {
                            playerController.beginSeeking()
                        } else {
                            playerController.seek(to: sliderValue)
                        }
                    }
                )
                .onChange(of: sliderValue) { newValue in
                    if playerController.isSeeking {
                        playerController.setCurrentTime(newValue)
                    }
                }
                .onChange(of: playerController.currentTime) { newTime in
                    if !playerController.isSeeking {
                        sliderValue = newTime
                    }
                }
                .padding(.horizontal, 30)

                HStack {
                    Text(Self.formatTime(playerController.currentTime))
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Text(Self.formatTime(playerController.duration))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .opacity(hideOverlay ? 0 : 1)
        }
        .onAppear {
            playerController.autoReplay = false
        }
        .onChange(of: playerController.isPlaying) { playing in
            if playing && !hideOverlay {
                overlayDebouncer.run {
                    withAnimation {
                        hideOverlay = true
                        onBackgroundTap?(hideOverlay)
                    }
                }
            } else {
                overlayDebouncer.cancel()
            }
        }
    }

    static func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "00:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

