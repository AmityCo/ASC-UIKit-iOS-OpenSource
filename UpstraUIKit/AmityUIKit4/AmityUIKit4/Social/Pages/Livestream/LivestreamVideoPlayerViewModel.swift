//
//  LivestreamVideoPlayerViewModel.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 7/10/2567 BE.
//

import AmitySDK

class LivestreamVideoPlayerViewModel: ObservableObject {
    
    var streamRepository = AmityStreamRepository(client: AmityUIKit4Manager.client)
    
    var token: AmityNotificationToken?
    let post: AmityPostModel
    @Published var isLoaded = false
    
    @Published var stream: AmityStream?
    
    init(post: AmityPostModel) {
        self.post = post
        observeStream(streamId: post.liveStream?.streamId ?? "")
    }
    
    private func observeStream(streamId: String) {
        token?.invalidate()
        token = nil
        isLoaded = false
        
        token = streamRepository.getStream(streamId).observe { [weak self] data, error in
            self?.isLoaded = true
            if let stream = data.snapshot {                
                
                if stream.status != .idle {
                    self?.stream = stream
                }
                
                if stream.status == .ended {
                    NotificationCenter.default.post(name: .didLivestreamStatusUpdated, object: self?.post.object)
                }
                
            } else {
                print("Stream is not available or ended.")
            }
        }
    }
}
