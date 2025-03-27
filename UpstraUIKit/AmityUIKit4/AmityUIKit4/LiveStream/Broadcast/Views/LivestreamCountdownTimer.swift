//
//  LivestreamCountdownTimer.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 13/3/25.
//

import SwiftUI

struct LivestreamCountdownTimer: View {
    
    let config: LiveStreamCircularProgressBar.Config = .init()
    let totalCountdown: Int
    @Binding var currentCountdown: Int
        
    var body: some View {
        ZStack {
            // Gray background circle with border
            Circle()
                .stroke(Color(config.backgroundColor), lineWidth: config.strokeWidth)
            
            let progress: Double = Double(totalCountdown - currentCountdown) * 10
            Circle()
                .trim(from: 0, to: progress > 0 ? CGFloat(min(progress, 100)) / 100 : 0)
                .stroke(progress > 0 ? Color(config.foregroundColor) : Color.clear, lineWidth: config.strokeWidth)
                .rotationEffect(Angle(degrees: -90)) // Start from top
            
            Text("\(currentCountdown)")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color.white)
        }
    }
}

#if DEBUG
#Preview {
    ZStack{
        Color.blue
        
        Color.black.opacity(0.5)
        
        LivestreamCountdownTimer(totalCountdown: 10, currentCountdown: .constant(10))
            .frame(width: 72, height: 72)
    }
}
#endif
