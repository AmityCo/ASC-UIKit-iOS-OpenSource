//
//  AmityLivestreamPlayerPage.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 10/10/2567 BE.
//

import SwiftUI
import AmitySDK

public struct AmityLivestreamPlayerPage: AmityPageView {
    
    let post: AmityPostModel
        
    public var id: PageId {
        .livestreamPlayerPage
    }
    
    public init(post: AmityPost) {
        self.post = AmityPostModel(post: post)
    }
    
    public var body: some View {
        if let livestream = post.liveStream {
            if post.livestreamState == .recorded {
                RecordedStreamPlayerView(livestream: livestream, client: AmityUIKit4Manager.client)
                    .ignoresSafeArea(.all)
            } else {
                LivestreamVideoPlayerView(post: post)
            }
        }
    }
    
}
