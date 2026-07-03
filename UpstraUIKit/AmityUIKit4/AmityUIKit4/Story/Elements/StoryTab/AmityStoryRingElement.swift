//
//  AmityStoryRingElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/27/23.
//

import SwiftUI

struct AmityStoryRingElement: AmityElementView {
    
    var pageId: PageId?
    
    var componentId: ComponentId?
    
    var id: ElementId {
        return .storyRingElement
    }
    
    var showRing: Bool
    var animateRing: Bool
    var showErrorRing: Bool
    
    @State private var startProgress: CGFloat = 0.0
    @State private var stopProgress: CGFloat = 1.0
    @State private var animationTimer: Timer?
    private let animationInterval: TimeInterval = 0.0001
    
    var body: some View {
        let progressColor = AmityFixedColor.shared.storyRingProgress.map { Color($0) }
        let backgroundColor = Color(AmityUIKitConfigController.shared.getTheme().baseColorShade4)

        Circle()
            .stroke(lineWidth: 2.0)
            .fill(
                LinearGradient(colors: getRingColor(progressColor: progressColor, backgroundColor: [backgroundColor])
                               , startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                VStack {
                    if animateRing && !showErrorRing {
                        Circle()
                            .trim(from: startProgress, to: stopProgress)
                            .stroke(
                                backgroundColor,
                                lineWidth: 2.0
                            )
                            .rotationEffect(.degrees(-90))
                    }

                }
            )
        .onChange(of: animateRing) { showAnimation in
            if showAnimation && !showErrorRing {
                animationTimer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { timer in
                    
                    if stopProgress >= 1 {
                        startProgress += animationInterval
                    }
                    
                    stopProgress += animationInterval
                    
                    if startProgress >= 1 {
                        startProgress = 0.0
                        stopProgress = 0.0
                    }
                }

            } else{
                startProgress = 0.0
                stopProgress = 1.0
                animationTimer?.invalidate()
                animationTimer = nil
            }
        }
    }
    
    private func getRingColor(progressColor: [Color], backgroundColor: [Color]) -> [Color] {
        if showErrorRing {
            return [Color(AmityUIKitConfigController.shared.getTheme().alertColor)]
        } else if showRing {
            return progressColor
        } else {
            return backgroundColor
        }
    }
    
}


struct TestRing: View {
    @State private var startProgress: CGFloat = 0.0
    @State private var stopProgress: CGFloat = 1.0
    private let animationInterval: TimeInterval = 0.00001
    
    var body: some View {
        Circle()
            .stroke(lineWidth: 3.0)
            .fill(
                LinearGradient(colors: [.blue, .green]
                               , startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                VStack {
                    Circle()
                        .trim(from: startProgress, to: stopProgress)
                        .stroke(
                            .white,
                            lineWidth: 3.0
                        )
                        .rotationEffect(.degrees(-90))
                        .onAppear {
                            let timer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { timer in
//                                guard animateRing else {
//                                    startProgress = 0.0
//                                    stopProgress = 0.0
//                                    timer.invalidate()
//                                    return
//                                }
                                
                                if stopProgress >= 1 {
                                    startProgress += animationInterval
                                }
                                
                                stopProgress += animationInterval
                                
                                if startProgress >= 1 {
                                    startProgress = 0.0
                                    stopProgress = 0.0
                                }
                            }
                        }
                }
            )
    }
}

#if DEBUG
#Preview {
    TestRing()
}
#endif
