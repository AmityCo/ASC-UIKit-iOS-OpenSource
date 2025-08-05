//
//  AmityAudioPlayer.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 3/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AVFoundation

final class AmityAudioPlayer: NSObject {
    
    static let shared = AmityAudioPlayer()
    
    var fileName: String?
    var path: URL?
    private var _fileName: String?
    private var player: AVAudioPlayer!
    private var timer: Timer?
    private var duration: TimeInterval = 0.0 {
        didSet {
            displayDuration()
        }
    }
    func isPlaying() -> Bool {
        if player == nil {
            return false
        }
        return player.isPlaying
    }
    
    func play() {
        resetTimer()
        if player == nil {
            playAudio()
        } else {
            if _fileName != fileName {
                stop()
                playAudio()
            } else {
                if player.isPlaying {
                    stop()
                } else {
                    playAudio()
                }
            }
        }
    }
    
    func stop() {
        if player != nil {
            player.stop()
            player = nil
            resetTimer()
            onStop?()
        }
    }
    
    // MARK: - Helper functions
    
    private func playAudio() {
        _fileName = fileName
        prepare()
    }
    
    private func prepare() {
        guard let url = path else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
                self?.duration += timer.timeInterval
            })
            timer?.tolerance = 0.2
            guard let timer = timer else { return }
            RunLoop.main.add(timer, forMode: .common)
            
            self.onPlay?()
        } catch {
            Log.add("Error while playing audio \(error.localizedDescription)")
            player = nil
        }
    }
    
    private func displayDuration() {
        let time = Int(duration)
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        let display = String(format:"%01i:%02i", minutes, seconds)
        
        self.onDurationChange?(display)
    }
    
    private func resetTimer() {
        duration = 0
        timer?.invalidate()
    }
    
    var onPlay: (() -> Void)?
    var onStop: (() -> Void)?
    var onFinish: (() -> Void)?
    var onDurationChange: ((_ duration: String) -> Void)?
}

extension AmityAudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        fileName = nil
        resetTimer()
        
        onFinish?()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            Log.add("Error while decoding \(error.localizedDescription)")
        }
    }
}
