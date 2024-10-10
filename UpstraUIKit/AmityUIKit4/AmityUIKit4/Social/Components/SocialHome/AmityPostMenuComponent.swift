//
//  AmityPostMenuComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/5/24.
//

import SwiftUI

enum PostMenuType: String, CaseIterable, Identifiable {
    var id: String {
        rawValue
    }
    
    case post = "Post"
    case story = "Story"
//    case poll = "Poll"
//    case liveStream = "Livestream"
}

public struct AmityCreatePostMenuComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    private let postTypes: [PostMenuType] = PostMenuType.allCases
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Binding private var isPresented: Bool
    
    @State private var showPostCreationMenuScaleEffect: Bool = false
    
    public var id: ComponentId {
        .createPostMenu
    }
    
    public init(isPresented: Binding<Bool>? = nil, pageId: PageId? = nil) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .createPostMenu))
        self._isPresented = isPresented ?? Binding.constant(false)
    }
    
    public var body: some View {
        VStack {
            HStack {
                Spacer()
                getMenuView()
                    .scaleEffect(showPostCreationMenuScaleEffect ? 1.0 : 0.0, anchor: .topTrailing)
            }
            Spacer()
        }
        .background(Color.clear)
        .onAppear {
            withAnimation(.bouncy(duration: 0.2, extraBounce: 0.1)) {
                showPostCreationMenuScaleEffect.toggle()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleScaleEffect()
        }
    }
    
    
    @ViewBuilder
    private func getMenuView() -> some View {
        VStack(spacing: 24) {
            ForEach(postTypes, id: \.rawValue) { type in
                switch type {
                case .post:
                    let createPostButton = viewConfig.getConfig(elementId: .createPostButton, key: "image", of: String.self) ?? ""
                    let createPostTitle = viewConfig.getConfig(elementId: .createPostButton, key: "text", of: String.self) ?? ""
                    getItemView(image: AmityIcon.getImageResource(named: createPostButton), title: createPostTitle)
                        .onTapGesture {
                            goToPostCreation()
                        }
                        .accessibilityIdentifier(AccessibilityID.Social.CreatePostMenu.createPostButton)
                case .story:
                    let createStoryButton = viewConfig.getConfig(elementId: .createStoryButton, key: "image", of: String.self) ?? ""
                    let createStoryTitle = viewConfig.getConfig(elementId: .createStoryButton, key: "text", of: String.self) ?? ""
                    getItemView(image: AmityIcon.getImageResource(named: createStoryButton), title: createStoryTitle)
                        .onTapGesture {
                            goToStoryCreation()
                        }
                        .accessibilityIdentifier(AccessibilityID.Social.CreatePostMenu.createStoryButton)
//                case .poll:
//                    let icon = AmityIcon.createPollMenuIcon
//                    getItemView(image: icon.getImageResource(), title: type.rawValue)
//                        .onTapGesture {
//                            Log.add(event: .info, "Create: Poll")
//                        }
//                case .liveStream:
//                    let icon = AmityIcon.createLivestreamMenuIcon
//                    getItemView(image: icon.getImageResource(), title: type.rawValue)
//                        .onTapGesture {
//                            Log.add(event: .info, "Create: LiveStream")
//                        }
                }
            }
        }
        .padding(EdgeInsets(top: 26, leading: 16, bottom: 26, trailing: 16))
        .frame(width: 200, alignment: .bottom)
        .background(Color(viewConfig.theme.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .shadow(radius: 2, y: 1)
        .padding(.top, 68)
        .padding(.trailing, 20)
    }
    
    
    @ViewBuilder
    private func getItemView(image: ImageResource, title: String) -> some View {
        HStack(spacing: 10) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 15.0, weight: .semibold))
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    
    private func toggleScaleEffect() {
        withAnimation(.bouncy(duration: 0.2, extraBounce: 0.1)) {
            showPostCreationMenuScaleEffect.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withoutAnimation {
                isPresented.toggle()
            }
        }
    }
    
    private func goToPostCreation() {
        withoutAnimation {
            isPresented.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let context = AmityCreatePostMenuComponentBehavior.Context(component: self)
            AmityUIKitManagerInternal.shared.behavior.createPostMenuComponentBehavior?.goToSelectPostTargetPage(context: context)
        }
    }
    
    private func goToStoryCreation() {
        withoutAnimation {
            isPresented.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let context = AmityCreatePostMenuComponentBehavior.Context(component: self)
            AmityUIKitManagerInternal.shared.behavior.createPostMenuComponentBehavior?.goToSelectStoryTargetPage(context: context)
        }
    }
}
