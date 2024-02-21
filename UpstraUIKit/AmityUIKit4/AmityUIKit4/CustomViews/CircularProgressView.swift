//
//  CircularProgressView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/19/24.
//

import SwiftUI

public struct CircularProgressView: View {
    
    @State private var startProgress: CGFloat = 0.0
    @State private var stopProgress: CGFloat = 1.0
    @State private var showAnimation: Bool = false
    @State private var animationTimer: Timer?
    private let animationInterval: TimeInterval = 0.001
    
    
    public var body: some View {
        Circle()
            .stroke(lineWidth: 2.0)
            .fill(
                Color.blue
            )
            .overlay(
                Circle()
                    .trim(from: startProgress, to: stopProgress)
                    .stroke(
                        .white,
                        lineWidth: 2.0
                    )
                    .rotationEffect(.degrees(-90))
            )
            .onAppear {
                showAnimation = true
            }
            .onDisappear {
                showAnimation = false
            }
            .onChange(of: showAnimation) { showAnimation in
                if showAnimation {
                    animationTimer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { timer in
                        
                        if stopProgress >= 1 {
                            startProgress += animationInterval
                        } else {
                            stopProgress += animationInterval
                        }
                        
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
}

#if DEBUG
#Preview {
    CircularProgressView()
        .frame(width: 20, height: 20)
}
#endif
