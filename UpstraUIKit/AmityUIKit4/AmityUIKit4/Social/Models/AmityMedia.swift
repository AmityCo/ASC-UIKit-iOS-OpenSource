//
//  AmityMedia.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 5/7/24.
//

import Foundation
import AmitySDK
import Photos
import UIKit
import Combine

enum AmityMediaState {
    
    case uploading(progress: Double)
    case uploadedImage(data: AmityImageData)
    case uploadedVideo(data: AmityVideoData)
    case localAsset(PHAsset)
    case image(UIImage)
    case localURL(url: URL)
    case downloadableImage(imageData: AmityImageData, placeholder: UIImage)
    case downloadableVideo(videoData: AmityVideoData, thumbnailUrl: String?)
    case downloadableClip(clipData: AmityClipData, thumbnailUrl: String?)
    case none
    case error
    
}

enum AmityMediaType {
    case image
    case video
    case none
}

public class AmityMedia: Equatable, Hashable, Identifiable, ObservableObject {
    
    public let id = UUID().uuidString
    @Published var state: AmityMediaState
    var type: AmityMediaType
    
    var image: AmityImageData?
    var video: AmityVideoData?
    var clip: AmityClipData?
    
    @Published var altText: String?
    
    /// This property carry over when the state change from .localAsset to .uploadedVideo.
    var localAsset: PHAsset?
    
    /// This property carry over when the state change from .localURL to .uploadedVideo.
    var localUrl: URL?
    
    var localUIImage: UIImage?
    
    /// Thumbnail image that is generated from local video url.
    ///
    /// This property is valid, when the media.
    /// - 1. `state == .localURL` or `state == .uploaded`
    /// - 2. `type == .video`
    var generatedThumbnailImage: UIImage?
    
    init(state: AmityMediaState, type: AmityMediaType) {
        self.state = state
        self.type = type
    }
    
    private func showImage(from asset: PHAsset, in imageView: UIImageView, size preferredSize: CGSize?) {
    
        let targetSize = preferredSize ?? imageView.bounds.size
        let manager = PHImageManager.default()
    
        let option = PHImageRequestOptions()
        option.version = .current
        option.resizeMode = .none
        option.deliveryMode = .highQualityFormat
        option.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option, resultHandler: { (result, info) in
            if let result = result {
                imageView.image = result
            }
        })
    
    }
    
//    func loadImage(to imageView: UIImageView, preferredSize: CGSize? = nil) {
//        
//        switch state {
//        case .image(let image):
//            imageView.image = image
//            
//        case .localAsset(let asset):
//            showImage(from: asset, in: imageView, size: preferredSize)
//            
//        case .downloadableImage(let imageData, let placeholder):
//            imageView.loadImage(with: imageData.fileURL, size: .medium, placeholder: placeholder)
//            
//        case .downloadableVideo(_ , let thumbnailUrl):
//            if let thumbnailUrl = thumbnailUrl {
//                imageView.loadImage(
//                    with: thumbnailUrl,
//                    size: .medium,
//                    placeholder: AmityIconSet.videoThumbnailPlaceholder
//                )
//            } else {
//                imageView.image = AmityIconSet.videoThumbnailPlaceholder
//            }
//            
//        case .uploadedImage(let imageData):
//            imageView.loadImage(with: imageData.fileURL, size: .medium, placeholder: nil)
//            
//        case .uploadedVideo:
//            if let asset = localAsset {
//                showImage(from: asset, in: imageView, size: preferredSize)
//            } else if let generatedThumbnailImage = generatedThumbnailImage {
//                imageView.image = generatedThumbnailImage
//            } else {
//                assertionFailure("Unexpected state, .uploadedVideo must have a preview image to show.")
//            }
//            
//        case .localURL(let url):
//            switch type {
//            case .image:
//                let image = UIImage(contentsOfFile: url.path)
//                imageView.image = image
//            case .video:
//                imageView.image = generatedThumbnailImage
//            }
//            
//        case .none, .error, .uploading:
//            break
//        }
//        
//    }
//    
//    func getLocalURLForUploading(completion: @escaping (URL?) -> Void) {
//        switch state {
//        case .localURL(let url):
//            completion(url)
//        case .localAsset(let asset):
//            asset.getURL(completion: completion)
//        default:
//            completion(nil)
//        }
//    }
    
//    func getImageForUploading(completion: ((Result<UIImage, Error>) -> Void)?) {
//        switch state {
//        case .localAsset(let asset):
//            asset.getImage(completion: completion)
//        case .image(let image):
//            completion?(.success(image))
//        case .downloadableImage, .downloadableVideo, .uploadedImage, .uploadedVideo, .none, .uploading, .error, .localURL:
//            assertionFailure("This function for uploading process")
//            completion?(.failure(AmityError.unknown))
//        }
//    }
    
    // MARK: - Hasable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    public static func == (lhs: AmityMedia, rhs: AmityMedia) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Helpers
    public func isLocal() -> Bool {
        switch state {
            
        case .uploading(_), .uploadedImage(_), .uploadedVideo(_), .localAsset(_), .image(_), .localURL(_):
            return true
       
        case .downloadableImage(_, _), .downloadableVideo(_, _):
            return false
            
        default: return true
        }
    }
    
    public func getImageURL() -> URL? {
        switch self.state {
            
        case .downloadableImage(imageData: let imageData, placeholder: _):
            return URL(string: "\(imageData.fileURL)?size=medium")
            
        case .downloadableVideo(videoData: _, thumbnailUrl: let thumbnailUrl):
            return URL(string: "\(thumbnailUrl ?? "")?size=medium")
            
        case .downloadableClip(clipData: _, let thumbnailUrl):
            return URL(string: "\(thumbnailUrl ?? "")?size=medium")
            
        default: return nil
            
        }
    }
    
    public func getAltText(hasDefault: Bool = true) -> String? {
        let fallback = "No description available"
        
        if altText != nil {
            return altText
        }
        
        switch self.state {
        case .downloadableImage(imageData: let imageData, placeholder: _):
            guard let altText = imageData.altText, !altText.isEmpty else {
                return hasDefault ? fallback : nil
            }
            return altText
            
        default: return nil
        }
    }
}

