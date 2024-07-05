//
//  PostContentLiveStreamView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/16/24.
//

import SwiftUI

struct PostContentLiveStreamView: View {
    let post: AmityPostModel
    
    init(post: AmityPostModel) {
        self.post = post
    }
    
    var body: some View {
        AsyncImage(placeholder: AmityIcon.defaultCommunity.getImageResource(), url: URL(string: post.liveStream?.thumbnail?.fileURL ?? ""))
    }
}
