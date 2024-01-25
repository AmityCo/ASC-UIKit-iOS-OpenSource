//
//  ToastVC.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/16/24.
//

import UIKit
import SwiftUI


public enum ToastStyle {
    case success, warning
}

public struct ToastView: View {
    var message: String
    var style: ToastStyle
    
    public init(message: String, style: ToastStyle) {
        self.message = message
        self.style = style
    }
    
    public var body: some View {
        HStack {
            Image(getIcon(style: style))
                .padding(EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 0))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
        }
        .background(Color.black)
        .cornerRadius(6.0)
        .padding([.leading, .trailing], 16)
    }
    
    private func getIcon(style: ToastStyle) -> ImageResource {
        switch style {
        case .success:
            return AmityIcon.statusSuccessIcon.getImageResource()
        case .warning:
            return AmityIcon.statusWarningIcon.getImageResource()
        }
    }
}


struct ToastModifier: ViewModifier {
    @Binding var showToast: Bool
    var message: String
    var style: ToastStyle
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if showToast {
                        Spacer()
                        withAnimation {
                            ToastView(message: message, style: style)
                                .padding(.bottom, 60)
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

extension View {
    public func showToast(isPresented: Binding<Bool>, style: ToastStyle, message: String) -> some View {
        self.modifier(ToastModifier(showToast: isPresented, message: message, style: style))
    }
}


public class Toast: UIViewController {

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
    
    static func makeView(style: ToastStyle, message: String) -> UIView {
        let vc = Toast(nibName: String(describing: self), bundle: AmityUIKit4Manager.bundle)
        vc.message = message
        vc.style = style
        return vc.view
    }
    
    public static func showToast(style: ToastStyle, message: String) {
        let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }
        guard let window = keyWindow else { return }
        
        let toastView = Toast.makeView(style: style, message: message)
        toastView.frame = CGRect(x: 0, y: CGFloat(UIScreen.main.bounds.height - (60 * UIScreen.main.scale)), width: UIScreen.main.bounds.width, height: toastView.frame.height)
        toastView.alpha = 0.0
        
        window.addSubview(toastView)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
            toastView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 3.0, options: .curveEaseInOut, animations: {
                toastView.alpha = 0.0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        }
    }
    
}
