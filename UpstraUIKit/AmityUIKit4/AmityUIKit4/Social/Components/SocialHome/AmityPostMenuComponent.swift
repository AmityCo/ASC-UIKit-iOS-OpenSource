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
    case poll = "Poll"
    case liveStream = "Live stream"
    case story = "Story"
    case clip = "Clip"
    case event = "Event"

    /// The element each item asks the gate about, under `create_post_menu`.
    /// The menu and the "+" that opens it both read this, so the two cannot
    /// disagree about which items the gate lets through.
    var elementId: ElementId {
        switch self {
        case .post: .createPostButton
        case .poll: .createPollButton
        case .liveStream: .createLivestreamButton
        case .story: .createStoryButton
        case .clip: .createClipButton
        case .event: .createEventButton
        }
    }
}

class AmityCreatePostMenuViewModel: ObservableObject {
    /// `false` until the SDK answers. A "+" that only the event item would
    /// keep open therefore stays hidden until the permission is known, rather
    /// than drawing and then disappearing.
    @Published var hasCreateEventPermission: Bool = false

    /// The network's story setting. Read on every ask rather than once: the
    /// top navigation builds this model before social settings may have loaded.
    var allowsStoryCreation: Bool {
        AmityUIKitManagerInternal.shared.client.getSocialSettings()?.story?.allowAllUserToCreateStory ?? false
    }

    /// The items the menu shows under `menuConfig`, with this user's inputs.
    func shownItems(_ menuConfig: AmityViewConfigController) -> [PostMenuType] {
        AmityCreatePostMenuComponent.shownItems(menuConfig,
                                                allowsStoryCreation: allowsStoryCreation,
                                                canCreateEvent: hasCreateEventPermission)
    }
    
    init() {
        // Event Permission
        Task { @MainActor in
            self.hasCreateEventPermission = await AmityUIKit4Manager.client.hasPermission(.createEvent) 
        }
    }
}

public struct AmityCreatePostMenuComponent: AmityComponentView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    
    public var pageId: PageId?
    private let postTypes: [PostMenuType] = PostMenuType.allCases
    
    @StateObject private var viewConfig: AmityViewConfigController
    @Binding private var isPresented: Bool
    @StateObject private var viewModel: AmityCreatePostMenuViewModel
    
    @State private var showPostCreationMenuScaleEffect: Bool = false
    
    public var id: ComponentId {
        .createPostMenu
    }

    /// The items the menu shows: the ones the module gate (and the
    /// customer's `excludes`) lets through under `menuConfig` — a view config
    /// for `create_post_menu` — that this user can also create.
    ///
    /// The one answer to "what is in the menu". The menu draws exactly these,
    /// and the "+" that opens it is drawn only while this is not empty
    /// (module-availability §10.1, PDT-5867): the menu belongs to no module,
    /// each item keeps its own owner, and a menu with nothing in it is not
    /// drawn. Story also needs the network's story setting, Event the
    /// create-event permission.
    static func shownItems(_ menuConfig: AmityViewConfigController,
                           allowsStoryCreation: Bool,
                           canCreateEvent: Bool) -> [PostMenuType] {
        PostMenuType.allCases.filter { type in
            guard !menuConfig.isHidden(elementId: type.elementId) else { return false }
            switch type {
            case .story: return allowsStoryCreation
            case .event: return canCreateEvent
            case .post, .poll, .liveStream, .clip: return true
            }
        }
    }

    public init(isPresented: Binding<Bool>? = nil, pageId: PageId? = nil) {
        self.init(isPresented: isPresented, pageId: pageId, viewModel: AmityCreatePostMenuViewModel())
    }

    /// With the model the "+" decided on, so the menu opens on the same items.
    init(isPresented: Binding<Bool>?, pageId: PageId?, viewModel: AmityCreatePostMenuViewModel) {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .createPostMenu))
        self._isPresented = isPresented ?? Binding.constant(false)
        self._viewModel = StateObject(wrappedValue: viewModel)
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
            withAnimation(.bouncy(duration: 0.3, extraBounce: 0.1)) {
                showPostCreationMenuScaleEffect.toggle()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleScaleEffect()
        }
    
        // Applies the theme and, with it, AmityModuleGate. The menu itself is
        // unowned, so the gate passes it through; each item asks for itself.
        .updateTheme(with: viewConfig)
    }
    
    
    @ViewBuilder
    private func getMenuView() -> some View {
        let shown = viewModel.shownItems(viewConfig)
        VStack(spacing: 24) {
            ForEach(postTypes) { type in
                switch type {
                case .post:
                    let createPostButton = viewConfig.getConfig(elementId: .createPostButton, key: "image", of: String.self) ?? ""
                    let createPostTitle = viewConfig.getConfig(elementId: .createPostButton, key: "text", of: String.self) ?? AmityLocalizedStringSet.Social.createPostBottomSheetTitle.localizedString
                    getItemView(image: AmityIcon.getImageResource(named: createPostButton), title: createPostTitle)
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                        .accessibilityIdentifier(AccessibilityID.Social.CreatePostMenu.createPostButton)
                case .story:
                    let createStoryButton = viewConfig.getConfig(elementId: .createStoryButton, key: "image", of: String.self) ?? ""
                    let createStoryTitle = viewConfig.getConfig(elementId: .createStoryButton, key: "text", of: String.self) ?? AmityLocalizedStringSet.Social.createStoryBottomSheetTitle.localizedString
                    getItemView(image: AmityIcon.getImageResource(named: createStoryButton), title: createStoryTitle)
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                        .accessibilityIdentifier(AccessibilityID.Social.CreatePostMenu.createStoryButton)
                case .poll:
                    let icon = AmityIcon.createPollMenuIcon
                    getItemView(image: icon.imageResource, title: AmityLocalizedStringSet.Social.postMenuTypePoll.localizedString, imageSize: CGSize(width: 18, height: 18))
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                case .liveStream:
                    let icon = AmityIcon.createLivestreamMenuIcon
                    getItemView(image: icon.imageResource, title: AmityLocalizedStringSet.Social.postMenuTypeLiveStream.localizedString)
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                case .clip:
                    let icon = AmityIcon.createClipMenuIcon
                    getItemView(image: icon.imageResource, title: AmityLocalizedStringSet.Social.postMenuTypeClip.localizedString, imageSize: CGSize(width: 18, height: 18))
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                case .event:
                    let icon = AmityIcon.createEventMenuIcon
                    getItemView(image: icon.imageResource, title: AmityLocalizedStringSet.Social.postMenuTypeEvent.localizedString, imageSize: CGSize(width: 18, height: 18))
                        .onTapGesture {
                            handlePostMenuAction(type)
                        }
                        .isHidden(!shown.contains(type))
                        .accessibilityIdentifier(AccessibilityID.Event.CreateMenu.createEventButton)
                }
            }
        }
        .padding(EdgeInsets(top: 26, leading: 16, bottom: 26, trailing: 16))
        .frame(width: 200, alignment: .bottom)
        .background(Color(viewConfig.theme.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .shadow(radius: 2, y: 1)
        .padding(.top, 94)
        .padding(.trailing, 20)
    }
    
    
    @ViewBuilder
    private func getItemView(image: ImageResource, title: String, imageSize: CGSize = CGSize(width: 20, height: 20)) -> some View {
        HStack(spacing: 10) {
            Image(image)
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .frame(width: imageSize.width, height: imageSize.height)
                .foregroundColor(Color(viewConfig.theme.baseColor))
            
            Text(title)
                .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    
    private func toggleScaleEffect() {
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0.1)) {
            showPostCreationMenuScaleEffect.toggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withoutAnimation {
                isPresented.toggle()
            }
        }
    }
    
    private func handlePostMenuAction(_ type: PostMenuType) {
        withoutAnimation {
            isPresented.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let context = AmityCreatePostMenuComponentBehavior.Context(component: self)
            let behavior = AmityUIKitManagerInternal.shared.behavior.createPostMenuComponentBehavior
            switch type {
            case .post:
                behavior?.goToSelectPostTargetPage(context: context)
            case .story:
                behavior?.goToSelectStoryTargetPage(context: context)
            case .poll:
                behavior?.goToSelectPollPostTargetPage(context: context)
            case .liveStream:
                behavior?.goToSelectLiveStreamPostTargetPage(context: context)
            case .clip:
                behavior?.goToSelectClipPostTargetPage(context: context)
            case .event:
                behavior?.goToSelectEventTargetPage(context: context)
            }
        }
    }
}
