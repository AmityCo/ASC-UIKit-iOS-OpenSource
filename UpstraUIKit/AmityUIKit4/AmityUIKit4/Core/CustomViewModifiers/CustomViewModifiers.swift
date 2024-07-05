//
//  CustomViewModifiers.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/25/24.
//

import SwiftUI
import Combine

// MARK: View

extension View {
    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    ///
    ///     Text("Label")
    ///         .isHidden(true, remove: false)
    ///
    /// Example for complete removal:
    ///
    ///     Text("Label")
    ///         .isHidden(true)
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///   - remove: Boolean value indicating whether or not to remove the view.
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = true) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
    
    func disableView(_ value: Bool) -> some View {
        return self.modifier(DisableView(disable: value))
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Assigns
    func updateTheme(with config: AmityViewConfigController) -> some View {
        return self.modifier(ThemeUpdater(viewConfig: config))
    }
    
    // Keyboard appear, disappear event
    var keyboardPublisher: AnyPublisher<(isAppeared: Bool, height: CGFloat), Never> {
        Publishers
            .Merge(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { notification -> (Bool, CGFloat) in
                        var keyboardHeight: CGFloat = 0.0
                        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                            let keyboardRectangle = keyboardFrame.cgRectValue
                            keyboardHeight = keyboardRectangle.height
                        }
                        return (true, keyboardHeight)
                    },
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in (false, 0.0) }
            )
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

// MARK: Button

private func withFeedback(
  _ style: UIImpactFeedbackGenerator.FeedbackStyle,
  _ action: @escaping () -> Void
) -> () -> Void {
  { () in
      ImpactFeedbackGenerator.impactFeedback(style: style)
      action()
  }
}

extension Button {
    init(
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
      ) {
        self.init(action: withFeedback(feedbackStyle, action), label: label)
      }
}


struct ThemeUpdater: ViewModifier {
    
    let viewConfig: AmityViewConfigController
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environmentObject(viewConfig)
            .onChange(of: colorScheme) { value in
                viewConfig.updateTheme()
            }
    }
}


public func withoutAnimation(action: @escaping () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
        action()
    }
}


struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return InnerView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    private class InnerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            
            superview?.superview?.backgroundColor = .clear
        }
        
    }
}


struct DisableView: ViewModifier {
    private let disable: Bool
    
    init(disable: Bool) {
        self.disable = disable
    }
    
    func body(content: Content) -> some View {
        content
            .overlay (
                overlayView
                    .clipShape(Circle())
            )
    }
    
    private var overlayView: some View {
        if disable {
            Color.black.opacity(0.1)
        } else {
            Color.clear
        }
    }
}

struct UpsideDown: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(x: -1.0, y: 1.0, anchor: .center)
    }
}

struct HiddenListSeparator: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .listRowSeparator(.hidden)
        } else {
            content
        }
    }
}
