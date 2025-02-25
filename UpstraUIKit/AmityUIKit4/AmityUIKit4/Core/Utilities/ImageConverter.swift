//
//  ImageConverter.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/1/24.
//
import Foundation
import AVKit
import ImageIO
import MobileCoreServices

class ImageConverter {
    
    static func convertImage(url: URL) -> URL? {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceSubsampleFactor: 2
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil), let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options), let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] else { return nil }
        
        let uuid = UUID().uuidString
        let suffix = "\(uuid).png"
        
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else { return nil }
        
        directory.appendingPathComponent(suffix)
        guard let absoluteString = directory.absoluteString, let destinationURL = URL(string: "\(absoluteString)\(suffix)"), let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return nil }
        
        CGImageDestinationAddImage(destination, cgImage, options)
        if CGImageDestinationFinalize(destination) {
            return destinationURL
        }
        
        return nil
    }
}
