//
//  AmityPostTargetSelectionPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/7/24.
//

import Foundation

open class AmityPostTargetSelectionPageBehaviour {
    open class Context {
        public let page: AmityPostTargetSelectionPage
        
        init(page: AmityPostTargetSelectionPage) {
            self.page = page
        }
    }
    
    public init() {}
    
    open func event1(context: AmityPostTargetSelectionPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
    
    open func goToCameraPage(context: AmityPostTargetSelectionPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
}
