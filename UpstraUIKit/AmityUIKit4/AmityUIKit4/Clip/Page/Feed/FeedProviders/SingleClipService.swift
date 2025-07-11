//
//  SingleClipService.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 28/6/25.
//

import SwiftUI
import AmitySDK
import Foundation

/// Used in post detail page
class SingleClipService: ClipService {
    
    init(clipPost: ClipPost) {
        super.init()
        
        self.clips = [clipPost]
        self.startIndex = 0
        self.currentIndex = 0
    }
    
    override func load() {
        self.loadingState = .loaded
        onLoadCompletion?()
    }
    
    override func canLoadMore() -> Bool {
        return false
    }
}
