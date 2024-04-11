//
//  AsyncImage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import UIKit

struct AsyncImage: View {
    let placeholder: ImageResource
    let url: URL?
    let contentMode: ContentMode
    
    init(placeholder: ImageResource, url: URL?, contentMode: ContentMode = .fill) {
        self.placeholder = placeholder
        self.url = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        GeometryReader { proxy in
            Image(placeholder)
                .resizable()
                .modifier(ImageScaleMode(mode: contentMode))
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(
                    VStack {
                        if let url {
                            URLImage(url, content: { image in
                                image
                                    .resizable()
                                    .modifier(ImageScaleMode(mode: contentMode))
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            })
                        }
                    }
                )
        }
    }
}

struct ImageScaleMode: ViewModifier {
    
    let mode: ContentMode
    
    func body(content: Content) -> some View {
        if mode == .fit {
            content
                .scaledToFit()
        } else {
            content
                .scaledToFill()
                .clipped()
                .clipShape(Circle())
        }
    }
}
