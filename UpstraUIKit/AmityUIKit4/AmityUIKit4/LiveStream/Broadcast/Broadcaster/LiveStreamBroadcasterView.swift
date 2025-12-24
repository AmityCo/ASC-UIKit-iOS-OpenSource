//
//  LiveStreamBroadcasterView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/21/25.
//

import SwiftUI

struct LiveStreamBroadcasterView<Content: View>: View {
    @ObservedObject var viewModel: LiveStreamBroadcasterViewModel
    private let coHostOverlayView: () -> Content

    init(viewModel: LiveStreamBroadcasterViewModel,
         @ViewBuilder coHostOverlayView: @escaping () -> Content = { EmptyView() }) {
        self.viewModel = viewModel
        self.coHostOverlayView = coHostOverlayView
    }
    
    var body: some View {
        ZStack {
            if [.idle, .disconnected].contains(viewModel.broadcasterState) {
                previewView
            } else {
                broadcastView
                    .id(viewModel.forceRefreshID)
            }
        }
        .environmentObject(viewModel.room)
    }
    
    @ViewBuilder
    private var broadcastView: some View {
        VStack(spacing: 0) {
            ForEach(Array(getSortedParticipants().enumerated()), id: \.element.id) { index, participant in
                ZStack(alignment: .top) {
                    ParticipantView(showInformation: false)
                        .background(Color(.darkGray))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(5)
                    
                    if getSortedParticipants().count > 1 && index == getSortedParticipants().count - 1 {
                        coHostOverlayView()
                    }
                }
                .environmentObject(participant)
            }
        }
    }
    
    @ViewBuilder
    private var previewView: some View {
        LocalCameraPreview(localVideoTrack: viewModel.cameraPreviewTrack, cameraPosition: $viewModel.cameraPosition)
    }
    
    private func getSortedParticipants() -> [Participant] {
        Array(viewModel.room.allParticipants.values).sorted { p1, p2 in
            let p1IsLocal = p1 is LocalParticipant
            let p2IsLocal = p2 is LocalParticipant

            // If role is host, LocalParticipant comes first
            if viewModel.role == .host {
                if p1IsLocal { return true }
                if p2IsLocal { return false }
            }
            // If role is coHost, LocalParticipant comes second (after the host)
            else if viewModel.role == .coHost {
                if p1IsLocal { return false }
                if p2IsLocal { return true }
            }

            // Sort others by join time
            return (p1.joinedAt ?? Date()) < (p2.joinedAt ?? Date())
        }
    }

}
