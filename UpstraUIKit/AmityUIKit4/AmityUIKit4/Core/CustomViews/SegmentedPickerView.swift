//
//  SegmentedPickerView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/23.
//

import SwiftUI

struct SegmentedPickerView: View {

    private let titles: [String]
    @Binding private var currentIndex: Int
    
    init(titles: [String], currentIndex: Binding<Int>) {
        self.titles = titles
        self._currentIndex = currentIndex
    }

    /// - Returns the width of a picker item
    private func itemWidth(availableWidth: CGFloat) -> CGFloat {
        availableWidth / CGFloat(titles.count)
    }

    /// - Returns the x-offset for the current selection
    private func xOffsetForSelection(availableWidth: CGFloat) -> CGFloat {
        itemWidth(availableWidth: availableWidth) * CGFloat(currentIndex)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {

                // The background that moves between the items
                RoundedRectangle(cornerRadius: 24)
                    .foregroundColor(Color.white)
                    .frame(
                        width: itemWidth(availableWidth: proxy.size.width),
                        height: proxy.size.height
                    )
                    .offset(x: xOffsetForSelection(availableWidth: proxy.size.width))

                // The labels for the items
                HStack {
                    ForEach(Array(titles.enumerated()), id: \.element) { i, element in
                        Text("\(element)")
                            .applyTextStyle(.body(Color(UIColor(hex: "#898E9E"))))
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.1)) { currentIndex = i }
                            }
                            .accessibilityIdentifier(i == 0 ? AccessibilityID.Story.AmityCreateStoryPage.switchPhotoButton : AccessibilityID.Story.AmityCreateStoryPage.switchVideoButton)
                    }
                }
            }
        }
        
    }
}
