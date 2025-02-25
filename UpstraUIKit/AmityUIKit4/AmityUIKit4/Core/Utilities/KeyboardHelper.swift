//
//  KeyboardHelper.swift
//  AmityUIKit4
//
//  Created by Nishan on 9/4/2567 BE.
//

import SwiftUI
import Combine

protocol KeyboardNotification {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardNotification {
    
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
