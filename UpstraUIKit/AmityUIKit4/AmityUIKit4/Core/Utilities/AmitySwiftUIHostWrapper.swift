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
}

public class AmitySwiftUIHostingNavigationController<Content>: UINavigationController where Content: View {
    
    public convenience init(rootView: Content) {
        let hostingController = AmitySwiftUIHostingController(rootView: rootView)
        self.init(rootViewController: hostingController)
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
