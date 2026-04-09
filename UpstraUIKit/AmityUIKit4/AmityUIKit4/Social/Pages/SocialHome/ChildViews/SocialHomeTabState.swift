//
//  AmitySocialHomeTabState.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 4/8/26.
//

import SwiftUI
import Combine

/// Shared observable that broadcasts tab-switch events to child components
/// living inside the SocialHome Pager.
///
/// Components can observe `selectedTab` via `onChange` and decide whether
/// they need to refresh. This avoids tight coupling between the container
/// and individual tab components.
///
/// Usage:
///   - The container (SocialHomeContainerView) owns and injects this as
///     an `@EnvironmentObject`.
///   - Each tab component reads `@EnvironmentObject var tabState` and
///     reacts in its own `onChange(of: tabState.selectedTab)`.
class SocialHomeTabState: ObservableObject {
    @Published var selectedTab: AmitySocialHomePageTab = .newsFeed
}
