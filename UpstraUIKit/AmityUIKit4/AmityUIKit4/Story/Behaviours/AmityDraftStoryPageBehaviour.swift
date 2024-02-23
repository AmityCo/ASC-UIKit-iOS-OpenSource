//
//  DraftStoryPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/22/23.
//

import Foundation
import SwiftUI

open class AmityDraftStoryPageBehaviour {
    open class Context {
        public let page: AmityDraftStoryPage
        
        init(page: AmityDraftStoryPage) {
            self.page = page
        }
    }
    
    public init() {}
    
    open func event1(context: AmityDraftStoryPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
    
    open func goToCameraPage(context: AmityDraftStoryPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
}
