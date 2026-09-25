//
//  ToastVC.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import UIKit
import SwiftUI


public enum ToastStyle {
    case success
    case warning
    case loading
    case info
}

public struct ToastView: View {
    @State private var rotatingDegree = 0.0
    static let toastViewTag: Int = 101010
    
    var message: String
    var style: ToastStyle
    
    public init(message: String, style: ToastStyle) {
        self.message = message
        self.style = style
    }
    

    public var body: some View {
        HStack(spacing: 0) {
            if style == .loading {
                Image(getIcon(style: style))
                    .frame(width: 20, height: 20)
                    .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12))                    
                    .rotationEffect(.degrees(rotatingDegree))
                    .onAppear {
                        withAnimation(.linear(duration: 1).speed(1).repeatForever(autoreverses: false)) {
                            rotatingDegree = 360.0
                        }
                    }
                
            } else {
                Image(getIcon(style: style))
                    .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 8))
            }
            Text(message)
                .applyTextStyle(.body(.white))
                .lineLimit(2)
                .padding(.trailing, 8)
            Spacer()
        }
        .background(Color(AmityFixedColor.shared.toastBackground))
        .cornerRadius(6.0)
        .padding([.leading, .trailing], 16)
    }
    
    private func getIcon(style: ToastStyle) -> ImageResource {
        switch style {
        case .success:
            return AmityIcon.statusSuccessIcon.getImageResource()
        case .warning:
            return AmityIcon.statusWarningIcon.getImageResource()
        case .info:
            return AmityIcon.statusInfoIcon.getImageResource()
        case .loading:
            return AmityIcon.statusLoadingIcon.getImageResource()
        }
    }
}


struct ToastModifier: ViewModifier {
    @Binding var showToast: Bool
    var message: String
    var style: ToastStyle
    var bottomPadding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if showToast {
                        Spacer()
                        withAnimation {
                            ToastView(message: message, style: style)
                                .padding(.bottom, bottomPadding)
                        }
                    }
                }
            )
            .onChange(of: showToast) { isShown in
                if isShown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showToast.toggle()
                        }
                    }
                }
            }
    }
}

/// To use with SwiftUI way
extension View {
    public func showToast(isPresented: Binding<Bool>, style: ToastStyle, message: String, bottomPadding: CGFloat = 60) -> some View {
        self.modifier(ToastModifier(showToast: isPresented, message: message, style: style, bottomPadding: bottomPadding))
    }
}

/// To use with UIKit way
public class Toast: UIViewController {

    /// Bottom padding for pages with no bottom bar.
    public static let defaultBottomPadding: CGFloat = 30
    /// Bottom padding for pages that have a bottom bar / text field.
    public static let bottomBarPadding: CGFloat = 60
    public static let bottomBarHeight: CGFloat = 60
    /// Gap between the visible toast pill and the top of the bottom bar, used by the
    /// `aboveBottomBarHeight:` overload. Toast-owned styling, not feature data.
    static let bottomBarGap: CGFloat = 12
    /// Empty space below the visible pill inside the toast's nib frame; subtracted so the gap above the
    /// bar is measured from the pill rather than the frame.
    static let toastContentBottomInset: CGFloat = 10

    @IBOutlet weak var content: UIView!
    
    var message: String = ""
    var style: ToastStyle = .success
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        let toastView = ToastView(message: message, style: style)
        let hostingController = UIHostingController(rootView: toastView)
        addChild(hostingController)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: content.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        
        
        hostingController.didMove(toParent: self)
    }
    
    private static func makeView(style: ToastStyle, message: String) -> UIView {
        let vc = Toast(nibName: String(describing: self), bundle: AmityUIKit4Manager.bundle)
        vc.message = message
        vc.style = style
        return vc.view
    }
    
    public static func showToast(style: ToastStyle, message: String, bottomPadding: CGFloat = Toast.defaultBottomPadding, autoHide: Bool = true) {

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                showToast(style: style, message: message, bottomPadding: bottomPadding, autoHide: autoHide)
            }
            return
        }
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }

        let safeAreaPadding = window.safeAreaInsets.bottom
        let padding = safeAreaPadding > bottomPadding ? safeAreaPadding + 10 : bottomPadding

        let toastView = Toast.makeView(style: style, message: message)
        toastView.tag = ToastView.toastViewTag
        toastView.frame = CGRect(x: 0, y: CGFloat(UIScreen.main.bounds.height - ((padding) * UIScreen.main.scale)), width: UIScreen.main.bounds.width, height: toastView.frame.height)

        present(toastView, in: window, autoHide: autoHide)
    }

    /// Positions the toast above a bottom bar (text field / compose bar) of `bottomBarHeight`,
    /// measured from the live safe-area inset so it is consistent across devices and screen scales.
    /// The bar height is supplied by the caller — Toast stores no feature-specific layout values.
    public static func showToast(style: ToastStyle, message: String, aboveBottomBarHeight bottomBarHeight: CGFloat, autoHide: Bool = true) {

        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                showToast(style: style, message: message, aboveBottomBarHeight: bottomBarHeight, autoHide: autoHide)
            }
            return
        }
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }

        let toastView = Toast.makeView(style: style, message: message)
        toastView.tag = ToastView.toastViewTag
        // Place the visible pill's bottom edge `bottomBarGap` above the top of the bottom bar;
        // `toastContentBottomInset` cancels the empty space the nib leaves below the pill.
        let originY = UIScreen.main.bounds.height - window.safeAreaInsets.bottom - bottomBarHeight - bottomBarGap - toastView.frame.height + toastContentBottomInset
        toastView.frame = CGRect(x: 0, y: originY, width: UIScreen.main.bounds.width, height: toastView.frame.height)

        present(toastView, in: window, autoHide: autoHide)
    }

    private static func present(_ toastView: UIView, in window: UIWindow, autoHide: Bool) {
        toastView.alpha = 0.0

        hideToastIfPresented()
        window.addSubview(toastView)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
            toastView.alpha = 1.0
        }) { _ in
            if autoHide {
                UIView.animate(withDuration: 0.5, delay: 3.0, options: .curveEaseInOut, animations: {
                    toastView.alpha = 0.0
                }, completion: { _ in
                    toastView.removeFromSuperview()
                })
            }
        }
    }

    public static func hideToastIfPresented(immediately: Bool = false) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { hideToastIfPresented(immediately: immediately) }
            return
        }
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        
        if let toastView = window.subviews.first(where: { $0.tag == ToastView.toastViewTag }) {
            let delay: TimeInterval = immediately ? 0.0 : 3.0
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseInOut, animations: {
                toastView.alpha = 0.0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        }
    }
    
}
