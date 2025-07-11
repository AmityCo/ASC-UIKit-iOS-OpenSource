//
//  VideoSeekBar.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 24/6/25.
//

import SwiftUI

struct VideoSeekBar: View {
    
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void = { _ in }

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    @State private var isDragging = false
    
    private let sliderHeight: Double = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: sliderHeight)

                // Filled progress
                Capsule()
                    .fill(Color.white)
                    .frame(width: CGFloat(progress) * geo.size.width, height: sliderHeight)

                // Knob only while dragging
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(radius: 1)
                    .offset(x: max(0, CGFloat(progress) * geo.size.width - sliderHeight))
                    .opacity(isDragging ? 1 : 0)
            }
            .contentShape(Rectangle()) // Make entire area tappable
            .frame(height: 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        onEditingChanged(true)

                        let location = gesture.location.x
                        let clamped = min(max(0, location), geo.size.width)
                        let newValue = range.lowerBound + (Double(clamped / geo.size.width) * (range.upperBound - range.lowerBound))
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 20)
    }
}
