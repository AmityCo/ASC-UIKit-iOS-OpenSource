//
//  AmitySwiftUIHostWrapper.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/23.
//

import SwiftUI
import UIKit
import Combine

public typealias ViewController = UIViewController
public typealias HostingController = UIHostingController

public class AmitySwiftUIHostWrapper: ObservableObject {
    public weak var controller: ViewController?
}

public class AmitySwiftUIHostingController<Content>: HostingController<ModifiedContent<Content,SwiftUI._EnvironmentKeyWritingModifier<AmitySwiftUIHostWrapper?>>> where Content : View {
    
    public init(rootView: Content) {
        let container = AmitySwiftUIHostWrapper()
        let modified = rootView.environmentObject(container) as! ModifiedContent<Content, _EnvironmentKeyWritingModifier<AmitySwiftUIHostWrapper?>>
        super.init(rootView: modified)
        container.controller = self
    }
  
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if PiPState.shared.hasActiveController {
            let style = viewControllerToPresent.modalPresentationStyle
            if style == .fullScreen || style == .overFullScreen {
                PiPState.shared.startPiPIfNeeded()
            }
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    /// Counterpart to the navigate-away starts above: coming BACK to the livestream
    /// page collapses its floating window again. Handles returning by pop or dismiss,
    /// which the entry-point restores (feed / story / event / notification tray) do not
    /// cover — those only fire when the stream is opened afresh. No-ops for every other
    /// page; `PiPState` identity-checks the registered livestream host.
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiPState.shared.restoreActivePiPIfReturningToLivestream(self)
    }
}

public class AmitySwiftUIHostingNavigationController<Content>: UINavigationController where Content: View {

    public convenience init(rootView: Content) {
        let hostingController = AmitySwiftUIHostingController(rootView: rootView)
        self.init(rootViewController: hostingController)
    }

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if PiPState.shared.hasActiveController {
            PiPState.shared.startPiPIfNeeded()
        }
        super.pushViewController(viewController, animated: animated)
    }
}

// Swipe Gesture Backup
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {

    open override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = AmityUIKit4Manager.behaviour.swipeToBackGestureBehavior {
            interactivePopGestureRecognizer?.delegate = self
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let swipeBehavior = AmityUIKit4Manager.behaviour.swipeToBackGestureBehavior {
            return swipeBehavior.gestureRecognizerShouldBegin(navigationController: self, gestureRecognizer)
        }
        
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let swipeBehavior = AmityUIKit4Manager.behaviour.swipeToBackGestureBehavior {
            return swipeBehavior.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
        }
        
        return false
    }
}
