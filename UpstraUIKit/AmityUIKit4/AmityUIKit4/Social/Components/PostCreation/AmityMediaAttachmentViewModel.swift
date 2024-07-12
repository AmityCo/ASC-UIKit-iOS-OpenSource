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
    
    public init(medias: [AmityMedia] = []) {
        self.medias = medias
    }
}
