//
//  StoryCreationPageBehaviour.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/22/23.
//

import Foundation
import SwiftUI

public class StoryCreationPageBehaviour {
    public class Context {
        let page: AmityStoryCreationPage
        
        init(page: AmityStoryCreationPage) {
            self.page = page
        }
    }
    
    public func event1(context: StoryCreationPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
    
    public func goToCameraPage(context: StoryCreationPageBehaviour.Context) {
        Log.add(event: .info, "")
    }
}
