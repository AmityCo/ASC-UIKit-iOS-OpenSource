//
//  TimerManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/5/23.
//

import Foundation

class TimerManager {
    
    var timer: Timer?
    var timerAction: (() -> Void)?
    
    func setTimerAction(timerAction: @escaping () -> Void) {
        self.timerAction = {
            timerAction()
        }
    }
    
    @objc func handleTimerAction() {
        timerAction?()
    }
    
    func startTimer() {
        timer = Timer(timeInterval: 0.001, target: self, selector: #selector(handleTimerAction), userInfo: nil, repeats: true)
        
        // Start the timer manually
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    
    func stopTimer() {
        // Invalidate the timer to stop it
        timer?.invalidate()
    }
}

class TimerAction {
    var timerAction: (() -> Void)?
}
