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
    
    func dismissKeyboardOnDrag() -> some View {
        self.modifier(DismissKeyboardOnDrag())
    }
    
    func adaptiveVerticalPadding(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        self.modifier(AdaptiveVerticalPadding(top: top, bottom: bottom))
    }
    
    func border(radius: CGFloat, borderColor: Color, borderWidth: CGFloat) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
    }
    
    func continuousCornerRadius(_ radius: Double) -> some View {
        self
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
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

struct DismissKeyboardOnDrag: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 15)
                    .onEnded({ _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    })
            )
    }
}


struct AdaptiveVerticalPadding: ViewModifier {
    let additionalTopPadding: CGFloat
    let additionalBottomPadding: CGFloat
    @State private var topPadding: CGFloat = 0
    @State private var bottomPadding: CGFloat = 0

    init(top: CGFloat = 0, bottom: CGFloat = 0) {
        self.additionalTopPadding = top
        self.additionalBottomPadding = bottom
    }

    func body(content: Content) -> some View {
        content
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .edgesIgnoringSafeArea([.top, .bottom])
            .onAppear {
                calculatePadding()
            }
    }
    
    private func calculatePadding() {
        guard let window = UIApplication.shared.windows.first else { return }
        let safeAreaInsets = window.safeAreaInsets
        
       
        // For devices with a notch or home indicator
        if additionalTopPadding > 0 {
            topPadding = safeAreaInsets.top > 20 ? safeAreaInsets.top + additionalTopPadding : additionalTopPadding
        } else {
            topPadding = 0
        }
        
        if additionalBottomPadding > 0 {
            bottomPadding = safeAreaInsets.bottom > 0 ? safeAreaInsets.bottom + additionalBottomPadding : additionalBottomPadding
        } else {
            bottomPadding = 0
        }
    }
}
