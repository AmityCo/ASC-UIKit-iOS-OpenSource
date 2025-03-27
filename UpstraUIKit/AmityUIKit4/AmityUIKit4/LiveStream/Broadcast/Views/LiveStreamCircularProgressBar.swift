//
//  LiveStreamCircularProgressBar.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 11/3/25.
//

import SwiftUI

/// Progress
struct LiveStreamCircularProgressBar: View {
    @Binding var progress: Double
    let config: LiveStreamCircularProgressBar.Config
    
    init(progress: Binding<Double>, config: LiveStreamCircularProgressBar.Config) {
        self._progress = progress
        self.config = config
    }
    
    @State private var isRotating = false
    
    var body: some View {
        ProgressBar(progress: $progress, config: self.config)
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .animation(isRotating ? Animation.linear(duration: 2.0).repeatForever(autoreverses: false) : .default, value: isRotating)
            .onAppear {
                withAnimation {
                    isRotating = config.shouldAutoRotate
                }
            }
    }
    
    struct ProgressBar: View {
        @Binding var progress: Double
        let config: LiveStreamCircularProgressBar.Config

        var body: some View {
            ZStack {
                // Gray background circle with border
                Circle()
                    .stroke(Color(config.backgroundColor), lineWidth: config.strokeWidth)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress > 0 ? CGFloat(min(progress, 100)) / 100 : 0)
                    .stroke(progress > 0 ? Color(config.foregroundColor) : Color.clear, lineWidth: config.strokeWidth)
                    .rotationEffect(Angle(degrees: -90)) // Start from top
            }
        }
    }
}

extension LiveStreamCircularProgressBar {
    
    struct Config {
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        let strokeWidth: Double
        let shouldAutoRotate: Bool
        
        init(backgroundColor: UIColor = .gray.withAlphaComponent(0.5), foregroundColor: UIColor = .white, strokeWidth: Double = 2, shouldAutoRotate: Bool = true) {
            self.backgroundColor = backgroundColor
            self.foregroundColor = foregroundColor
            self.strokeWidth = strokeWidth
            self.shouldAutoRotate = shouldAutoRotate
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        Spacer()
        
        LiveStreamCircularProgressBar(progress: .constant(40), config: LiveStreamCircularProgressBar.Config())
            .frame(width: 30, height: 30)

        Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Color.black.opacity(0.1))
}
#endif
