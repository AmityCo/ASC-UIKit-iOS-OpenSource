//
//  AsyncImage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 2/1/24.
//

import SwiftUI
import UIKit

struct AsyncImage: View {
    let placeholder: ImageResource?
    let url: URL?
    let contentMode: ContentMode
    let placeholderView: AnyView?
    var onLoaded: ((Bool) -> Void)?

    /// Non-Amity hosts especially customAvatarURL reject the Authorization header (S3 answers 400 InvalidArgument).
    /// Set once on such a failure to retry the same URL unauthenticated.
    @State private var skipAuthHeader = false

    init(placeholder: ImageResource? = nil, url: URL?, contentMode: ContentMode = .fill) {
        self.placeholder = placeholder
        self.url = url
        self.contentMode = contentMode
        self.placeholderView = nil
    }
    
    init<PlaceholderView: View>(@ViewBuilder placeholderView: () -> PlaceholderView, url: URL?, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = nil
        self.placeholderView = AnyView(placeholderView())
    }
    
    /// Requests carry the Authorization header from `KingfisherManager.shared.defaultOptions` by
    /// default. On the retry pass an empty request modifier replaces it, so no header is sent.
    private var image: KFImage {
        let image = KFImage.url(url)
        return skipAuthHeader ? image.requestModifier { _ in } : image
    }

    var body: some View {
        GeometryReader { proxy in
            image
                .placeholder {
                    if let placeholder {
                        Image(placeholder)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let placeholderView {
                        placeholderView
                    }
                }
                .onSuccess({ _ in
                    onLoaded?(true)
                })
                .onFailure({ error in
                    if !skipAuthHeader, error.isAuthHeaderRejection {
                        Log.warn("AsyncImage host rejected auth header, retrying without it url=\(url?.absoluteString ?? "nil") code=\(error.errorCode)")
                        skipAuthHeader = true
                        return
                    }
                    Log.warn("AsyncImage failed url=\(url?.absoluteString ?? "nil") code=\(error.errorCode) \(error.localizedDescription)")
                    onLoaded?(false)
                })
                .resizable()
                .loadDiskFileSynchronously()
                .startLoadingBeforeViewAppear()
                .modifier(ImageScaleMode(mode: contentMode))
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .id(skipAuthHeader)
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
        }
    }
}

private extension KingfisherError {

    /// True when the response looks like the host refusing our Authorization header rather than
    /// a genuine access failure. S3 returns 400 InvalidArgument; other CDNs use 401/403.
    var isAuthHeaderRejection: Bool {
        guard case .responseError(let reason) = self,
              case .invalidHTTPStatusCode(let response) = reason else { return false }
        return (400...403).contains(response.statusCode)
    }
}

extension AsyncImage: AmityViewBuildable {
    func onLoaded(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onLoaded, value: callback)
    }
}
