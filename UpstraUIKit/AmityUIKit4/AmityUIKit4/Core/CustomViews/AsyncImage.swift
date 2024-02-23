//
//  AsyncImage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI


struct AsyncImage: View {
    let placeholder: ImageResource
    let url: URL?
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let url {
                    URLImage(url, empty: {
                        Image(placeholder)
                            .resizable()
                            .clipped()
                    }, inProgress: {_ in }, failure: {_,_  in}, content: { image in
                        image
                            .resizable()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    })
                } else {
                    Image(placeholder)
                        .resizable()
                        .clipped()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
