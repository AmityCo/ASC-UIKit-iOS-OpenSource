//
//  VideoInfoHelper.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import Foundation
import AVFoundation
import UIKit

class AmityMediaMetadata {
    
    /// File size in bytes
    static func getFileSize(from url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }
    
    @available(iOS 15, *)
    /// Duration in seconds
    static func getDuration(from asset: AVAsset) async throws -> TimeInterval {
        let duration = try await asset.load(.duration)
        return duration.seconds
    }
    
    static func generateThumbnail(from url: URL, at time: TimeInterval = 0) async throws -> UIImage? {
        let asset = AVURLAsset(url: url)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let cgImage = cgImage {
                    let uiImage = UIImage(cgImage: cgImage)
                    continuation.resume(returning: uiImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    @available(iOS 15, *)
    static func getResolution(from asset: AVAsset) async throws -> CGSize? {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        let size = naturalSize.applying(preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    @available(iOS 15, *)
    static func getFrameRate(from asset: AVAsset) async throws -> Float? {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        return nominalFrameRate
    }
    
    @available(iOS 15, *)
    static func getBitRate(from asset: AVAsset) async throws -> Float? {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
        return estimatedDataRate
    }
    
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
