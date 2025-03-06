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
    @Published var isAllMediaValid: Bool = false
    @Published var isAnyMediaFailed: Bool = false
    
    public init(medias: [AmityMedia] = []) {
        self.medias = medias
    }
    
    func checkAllMediaValid() {
        isAllMediaValid = medias.filter({ media in
            switch media.state {
            case .uploadedImage, .uploadedVideo , .downloadableImage, .downloadableVideo:
                return false
            case .error:
                isAnyMediaFailed = true
                return true
            default:
                return true
            }
        }).isEmpty
    }
}
