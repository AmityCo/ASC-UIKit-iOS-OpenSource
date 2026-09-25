//
//  AmityDiscoveryWidgetComponentBehavior.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import Foundation

/// Where a Discovery Widget card sends the visitor.
///
/// The widget's whole purpose is to hand a visitor into the community, and the destination belongs
/// to the integrator — a PDP, a hosted community, a deep link. The topic id travels with the post so
/// an override can route per topic without threading the topic through its own state.
///
/// There is **no default destination**, and that is deliberate. PDT-4639 says only "the client's
/// destination" (Plan 39 Q10), which the UIKit cannot know: the widget is embedded on a page the
/// integrator owns, and a card may point at a PDP, a hosted community or a deep link. Navigating
/// somewhere arbitrary would be worse than not moving, so an unoverridden behavior does nothing.
///
/// Android and Web resolve it the same way — both ship `goToDestination` as an empty method.
open class AmityDiscoveryWidgetComponentBehavior {

    open class Context {
        public let component: AmityDiscoveryWidgetComponent
        public let topicId: String
        public let post: AmityPostModel

        init(component: AmityDiscoveryWidgetComponent, topicId: String, post: AmityPostModel) {
            self.component = component
            self.topicId = topicId
            self.post = post
        }
    }

    public init() {}

    /// Override to route the tapped card. `context` carries the topic id alongside the post, so an
    /// override can route per topic without threading the topic through its own state.
    open func goToDestination(context: AmityDiscoveryWidgetComponentBehavior.Context) {
    }
}
