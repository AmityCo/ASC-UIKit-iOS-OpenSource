//
//  LiveStreamBroadcastPreviewView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/3/25.
//

import SwiftUI
import AmityLiveVideoBroadcastKit

// SwiftUI wrapper for broadcaster
struct LiveStreamBroadcastPreviewView: UIViewRepresentable {
    
    let broadcaster: AmityVideoBroadcaster
    
    func makeUIView(context: Context) -> some UIView {
        let renderingContainer = UIView()
        
        // Note: Autolayout does not work here, Weird...
        broadcaster.previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderingContainer.addSubview(broadcaster.previewView)

        return renderingContainer
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}
