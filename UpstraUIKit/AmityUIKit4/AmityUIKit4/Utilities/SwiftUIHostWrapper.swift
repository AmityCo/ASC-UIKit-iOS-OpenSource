//
//  SwiftUIHostWrapper.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/15/23.
//

import SwiftUI
import UIKit

public typealias ViewController = UIViewController
public typealias HostingController = UIHostingController

public class SwiftUIHostWrapper: ObservableObject {
    public weak var controller: ViewController?
}

public class SwiftUIHostingController<Content>: HostingController<ModifiedContent<Content,SwiftUI._EnvironmentKeyWritingModifier<SwiftUIHostWrapper?>>> where Content : View {
    
    public init(rootView: Content) {
        let container = SwiftUIHostWrapper()
        let modified = rootView.environmentObject(container) as! ModifiedContent<Content, _EnvironmentKeyWritingModifier<SwiftUIHostWrapper?>>
        super.init(rootView: modified)
        container.controller = self
    }
  
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
