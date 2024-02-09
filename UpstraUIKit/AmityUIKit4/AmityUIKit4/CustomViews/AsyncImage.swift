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
            Image(placeholder)
                .resizable()
                .overlay(
                    VStack {
                        if let url {
                            URLImage(url) { progress in
                                
                            } content: { image in
                                image
                                    .resizable()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
                        }
                    }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        
    }
}
