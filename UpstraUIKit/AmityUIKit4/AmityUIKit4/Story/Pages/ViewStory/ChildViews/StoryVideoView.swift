//
//  StoryVideoView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/3/24.
//

import SwiftUI
import AVKit

struct StoryVideoView: View {
        
    private let videoURL: URL
    @Binding private var muteVideo: Bool
    @Binding private var playVideo: Bool
    @Binding private var time: CMTime
    private let onLoading: () -> Void
    private let onPlaying: (Double) -> Void
    
    init(videoURL: URL, muteVideo: Binding<Bool>, time: Binding<CMTime>, playVideo: Binding<Bool>, onLoading: @escaping () -> Void, onPlaying: @escaping (Double) -> Void) {
        self.videoURL = videoURL
        self._muteVideo = muteVideo
        self._time = time
        self._playVideo = playVideo
        self.onLoading = onLoading
        self.onPlaying = onPlaying
    }
    
    var body: some View {
        VideoPlayer(url: videoURL, play: $playVideo, time: $time)
            .autoReplay(false)
            .mute(muteVideo)
            .contentMode(.scaleAspectFit)
            .onStateChanged({ state in
                switch state {
                case .loading:
                    onLoading()
                case .playing(totalDuration: let totalDuration):
                    onPlaying(totalDuration)
                case .paused(playProgress: _, bufferProgress: _): break
                case .error(_): break
                }
            })
            .accessibilityIdentifier(AccessibilityID.Story.AmityViewStoryPage.storyVideoView)
    }
}

