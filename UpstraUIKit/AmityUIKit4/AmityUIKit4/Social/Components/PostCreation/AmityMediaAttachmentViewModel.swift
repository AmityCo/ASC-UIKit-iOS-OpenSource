//
//  AmityMediaAttachmentViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/13/24.
//

import Foundation
import Combine

public class AmityMediaAttachmentViewModel: ObservableObject {
    @Published var medias: [AmityMedia] = []
    @Published var areAttachmentsReady: Bool = true
    @Published var isAnyMediaFailed: Bool = false
    var isPostEditing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(medias: [AmityMedia] = [], isPostEditing: Bool) {
        self.medias = medias
        self.isPostEditing = isPostEditing
        updateAttachmentReadiness()
        
        $medias
            .sink { [weak self] _ in
                self?.updateAttachmentReadiness()
            }
            .store(in: &cancellables)
    }
    
    // Call this method whenever a media's state changes
    func updateMediaState(_ media: AmityMedia) {
        updateAttachmentReadiness()
    }
    
    private func updateAttachmentReadiness() {
        if medias.isEmpty {
            areAttachmentsReady = true
            isAnyMediaFailed = false
        } else {
            // Consider media ready ONLY if it's in a final uploaded state
            areAttachmentsReady = !medias.contains { media in
                switch media.state {
                case .uploadedImage, .uploadedVideo, .downloadableImage, .downloadableVideo, .downloadableClip:
                    // These states are fully processed and ready
                    return false
                default:
                    // Any other state (including localURL, image, uploading, error)
                    // means we're not ready yet
                    return true
                }
            }
            
            isAnyMediaFailed = medias.contains { media in
                if case .error = media.state { return true } else { return false }
            }
        }
    }
}
