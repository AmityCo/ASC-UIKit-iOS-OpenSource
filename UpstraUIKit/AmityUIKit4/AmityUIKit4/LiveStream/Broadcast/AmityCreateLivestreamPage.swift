//
//  AmityCreateLivestreamPage.swift
//  AmityUIKitLiveStream
//
//  Created by Nishan Niraula on 28/2/25.
//

import SwiftUI
import AVKit
import UIKit
import AmitySDK

public struct AmityCreateLivestreamPage: AmityPageView {
    
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var id: PageId {
        return .createLivestreamPage
    }
    
    @StateObject private var viewConfig: AmityViewConfigController
    @StateObject private var viewModel: LiveStreamConferenceViewModel
    @StateObject private var broadcasterViewModel: LiveStreamBroadcasterViewModel
  
    public init(targetId: String, targetType: AmityPostTargetType) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .createLivestreamPage))
        let broadcasterViewModel = LiveStreamBroadcasterViewModel(role: .host)
        self._broadcasterViewModel = StateObject(wrappedValue: broadcasterViewModel)
        
        let conferenceViewModel = LiveStreamConferenceViewModel(targetId: targetId, targetType: targetType, participantRole: .host, broadcasterViewModel: broadcasterViewModel)
        self._viewModel = StateObject(wrappedValue: conferenceViewModel)
    }
    
    public init(event: AmityEvent) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .createLivestreamPage))
        let broadcasterViewModel = LiveStreamBroadcasterViewModel(role: .host)
        self._broadcasterViewModel = StateObject(wrappedValue: broadcasterViewModel)
        
        let conferenceViewModel = LiveStreamConferenceViewModel(event: event, participantRole: .host, broadcasterViewModel: broadcasterViewModel)
        self._viewModel = StateObject(wrappedValue: conferenceViewModel)
    }
    
    public var body: some View {
        LiveStreamConferenceView(viewModel: viewModel, broadcasterViewModel: broadcasterViewModel)
            .environmentObject(viewConfig)
            .environmentObject(host)
    }
}

// Helper modifiers

struct VisibleModifier: ViewModifier {
    
    var condition: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(condition ? 1 : 0)
    }
}

extension View {
    
    /// Convenience modifier. Does not remove the view and modifies opacity only.
    func visibleWhen(_ condition: Bool) -> some View {
        self
            .modifier(VisibleModifier(condition: condition))
    }
}
