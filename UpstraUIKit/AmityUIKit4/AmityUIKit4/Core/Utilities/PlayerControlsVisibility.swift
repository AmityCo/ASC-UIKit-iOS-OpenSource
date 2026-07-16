//
//  PlayerControlsVisibility.swift
//  AmityUIKit4
//
//  Created by Prisa Damrongsiri on 08/07/25.
//

import Foundation

final class PlayerControlsVisibility: ObservableObject {

    @Published private(set) var isVisible: Bool

    private let debouncer: Debouncer

    init(autoHideDelay: TimeInterval = 1, initiallyVisible: Bool = false) {
        self.debouncer = Debouncer(delay: autoHideDelay)
        self.isVisible = initiallyVisible
    }

    func tapOverlay(isPlaying: Bool) {
        if isVisible {
            dismissImmediately()
        } else {
            show(autoHide: isPlaying)
        }
    }

    func show(autoHide: Bool) {
        isVisible = true
        autoDismissIfNeeded(autoHide: autoHide)
    }
    
    private func autoDismissIfNeeded(autoHide: Bool) {
        if autoHide {
            scheduleAutoDismiss()
        } else {
            debouncer.cancel()
        }
    }

    private func dismissImmediately() {
        debouncer.cancel()
        isVisible = false
    }

    private func scheduleAutoDismiss() {
        debouncer.run { [weak self] in
            self?.isVisible = false
        }
    }
}
