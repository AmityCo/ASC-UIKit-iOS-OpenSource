//
//  AmitySocialHomeTopNavigationComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/9/24.
//

import Foundation

open class AmitySocialHomeTopNavigationComponentBehavior {
    
    open class Context {
        public let component: AmitySocialHomeTopNavigationComponent
        
        init(component: AmitySocialHomeTopNavigationComponent) {
            self.component = component
        }
    }
    
    public init() {}
    
    private func goToCommunitySetupPage() {
        
    }
    
    open func goToCreateCommunityPage(context: AmitySocialHomeTopNavigationComponentBehavior.Context) {
        let page = AmityCommunitySetupPage(mode: .create)
        let vc = AmitySwiftUIHostingController(rootView: page)
        context.component.host.controller?.navigationController?.pushViewController(vc, animation: .presentation)
    }
    
}
