//
//  AmityNetworkLogOverlayWindow.swift
//  SampleApp
//

import UIKit

/// A window above the app window carrying nothing but the launcher button.
///
/// - Note: An earlier version hosted the whole viewer here as SwiftUI and tried to hit-test it.
///   That does not work: SwiftUI draws its hierarchy into the hosting controller's single view
///   rather than a view per element, so the window cannot tell content from empty space and
///   has to be told which rects are live. Keeping this window purely UIKit means `hitTest`
///   resolves to the button's own frame and passthrough is correct by construction.
final class AmityNetworkLogOverlayWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        // Only the button and its subviews claim touches; everything else falls through.
        return hit === rootViewController?.view ? nil : hit
    }
}

/// Hosts the launcher button and nothing else, so its own view is always the passthrough area.
final class AmityNetworkLogLauncherViewController: UIViewController {

    let button = AmityNetworkLogLauncherButton()

    var onTap: (() -> Void)?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -14),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -96),
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        button.addGestureRecognizer(pan)
    }

    @objc private func handleTap() {
        onTap?()
    }

    /// Dragging moves the button by transform only, so nothing relayouts while the finger is
    /// down — the previous resize implementation relayouted the whole app per frame.
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            button.transform = button.dragOrigin.translatedBy(x: translation.x, y: translation.y)
        case .ended, .cancelled, .failed:
            button.dragOrigin = button.transform
        default:
            break
        }
    }
}

/// The launcher: a live capture count over the last status seen.
///
/// The number is the content — it is more informative than any icon, and cheaper than an
/// indicator that animates continuously through a livestream.
final class AmityNetworkLogLauncherButton: UIButton {

    var dragOrigin: CGAffineTransform = .identity

    private let countLabel = UILabel()
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func update(count: Int, status: String) {
        countLabel.text = "\(count)"
        statusLabel.text = status
        accessibilityLabel = "Network log, \(count) captured, last status \(status)"
    }

    private func configure() {
        backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? .init(white: 0.92, alpha: 1) : .init(white: 0.16, alpha: 1) }
        layer.cornerRadius = 30
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemBackground.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 5)

        let foreground = UIColor { $0.userInterfaceStyle == .dark ? .init(white: 0.10, alpha: 1) : .white }
        countLabel.font = .monospacedSystemFont(ofSize: 17, weight: .bold)
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        [countLabel, statusLabel].forEach {
            $0.textColor = foreground
            $0.textAlignment = .center
        }

        let stack = UIStackView(arrangedSubviews: [countLabel, statusLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        update(count: 0, status: "—")
    }
}
