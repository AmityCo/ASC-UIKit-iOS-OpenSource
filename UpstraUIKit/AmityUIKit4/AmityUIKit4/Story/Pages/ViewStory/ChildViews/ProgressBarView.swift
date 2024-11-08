//
//  ProgressBarView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/8/23.
//

import SwiftUI
import AmitySDK

struct ProgressBarView: View {
    let spacing: CGFloat = 3.0
    let pageId: PageId
    
    @ObservedObject var progressBarViewModel: ProgressBarViewModel
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(0..<progressBarViewModel.progressArray.count, id: \.self) { index in
                    AmityProgressBarElement(pageId: pageId, progressBarViewModel: progressBarViewModel.progressArray[index])
                }
                .onAppear {
                    Log.add(event: .info, "ProgressBar Stack Appeared")
                }
            }
        }
    }
}


class ProgressBarViewModel: ObservableObject {
    @Published var progressArray: [AmityProgressBarElementViewModel]
    
    init(progressArray: [AmityProgressBarElementViewModel]) {
        self.progressArray = progressArray
    }
}


