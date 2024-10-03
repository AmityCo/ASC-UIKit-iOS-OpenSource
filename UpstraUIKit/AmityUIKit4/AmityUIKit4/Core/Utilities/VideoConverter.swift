//
//  VideoConverter.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/1/24.
//
import Foundation
import AVKit
import ImageIO
import MobileCoreServices

class VideoConverter {
    
    static func convertVideo(asset: AVAsset, completion: @escaping (_ responseURL : URL?) -> Void) {
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        
        let uuid = UUID().uuidString
        let suffix = "\(uuid).mp4"
        
        guard let destinationURL = URL(string: "\(directory.absoluteString)\(suffix)") else { return }
        
        let preset = AVAssetExportPresetHighestQuality
        let outFileType = AVFileType.mp4
        
        AVAssetExportSession.determineCompatibility(ofExportPreset: preset, with: asset, outputFileType: outFileType) { isCompatible in
            
            guard isCompatible else {
                completion(nil)
                return
            }
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
                completion(nil)
                return
            }
            
            exportSession.outputFileType = outFileType
            exportSession.outputURL = destinationURL
            exportSession.exportAsynchronously {
                completion(exportSession.status == .completed ? destinationURL : nil)
            }
        }
    }
    
    static func shouldConvertVideo(asset: AVAsset) -> Bool {
        let hdrTracks = asset.tracks(withMediaCharacteristic: .containsHDRVideo)
        var isHDRVideo: Bool = false
        hdrTracks.forEach {
            if $0.hasMediaCharacteristic(.containsHDRVideo) {
                isHDRVideo = true
            }
        }
        
        // BE Supports standard file format such as 3gp, avi, f4v, flv, m4v, mov, mp4, ogv, 3g2, wmv, vob, webm, and mkv & standard codec i.e h.264
        // See Image+and+Video+Compatibility docs
        
        var isHEVCEncoded = false // H.265 Encoding
        var isH264Encoded = false
        if let videoTrack = asset.tracks(withMediaType: .video).first, let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription] {
            isHEVCEncoded = formatDescriptions.contains(where: { description in
                return CMFormatDescriptionGetMediaSubType(description) == kCMVideoCodecType_HEVC
            })
            
            isH264Encoded = formatDescriptions.contains(where: { description in
                return CMFormatDescriptionGetMediaSubType(description) == kCMVideoCodecType_H264
            })
        }
        
        Log.add(event: .info, "Checking video information, isHEVCEncoded: \(isHEVCEncoded) | isHDRVideo \(isHDRVideo) | isH264Encoded: \(isH264Encoded)")
        return isHDRVideo || isHEVCEncoded
    }
}
