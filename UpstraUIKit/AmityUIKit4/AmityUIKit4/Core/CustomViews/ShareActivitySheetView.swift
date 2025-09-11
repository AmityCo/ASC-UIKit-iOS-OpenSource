//
//  ShareActivitySheetView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/7/25.
//

import SwiftUI
import UIKit

struct ShareActivitySheetView: UIViewControllerRepresentable {
    
    let link: String
    
    init(link: String) {
        self.link = link
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareActivitySheetView>) -> UIActivityViewController {
        let shareURL = URL(string: link)!

        let controller = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<ShareActivitySheetView>) {
        // Left empty
    }
}
