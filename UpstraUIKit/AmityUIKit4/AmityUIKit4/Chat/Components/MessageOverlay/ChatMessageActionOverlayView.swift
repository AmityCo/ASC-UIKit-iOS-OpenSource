//
//  ChatMessageActionOverlayView.swift
//  AmityUIKit4
//

import SwiftUI

// MARK: - ChatReactionPickerViewModel

class ChatReactionPickerViewModel: ObservableObject {
    @Published var reactionFrames: [String: CGRect] = [:]
    @Published var hoveredReaction: String? = nil

    var showTooltipBelow: Bool = false

    var initialDragPoint: CGPoint = .zero

    var commitReaction: ((String) -> Void)?

    // ── Drag helpers ─────────────────────────────────────────────────────

    @discardableResult
    func checkHoveredReaction(at point: CGPoint) -> String? {
        if initialDragPoint == .zero {
            initialDragPoint = point
        }
        guard arePointsDistinct(point, initialDragPoint, distance: 10) else { return nil }

        var matched: String? = nil
        for (name, frame) in reactionFrames {
            let enlarged = CGRect(
                x: frame.origin.x - 10,
                y: frame.origin.y - 200,
                width: frame.width + 20,
                height: frame.height + 400
            )
            if enlarged.contains(point) {
                matched = name
            }
        }

        if matched != nil, hoveredReaction != matched {
            ImpactFeedbackGenerator.impactFeedback(style: .medium)
            hoveredReaction = matched
        }
        if matched == nil {
            hoveredReaction = nil
        }
        return matched
    }

    func reset() {
        hoveredReaction = nil
        initialDragPoint = .zero
    }

    private func arePointsDistinct(_ p1: CGPoint, _ p2: CGPoint, distance: CGFloat) -> Bool {
        abs(p1.x - p2.x) >= distance || abs(p1.y - p2.y) >= distance
    }
}

// MARK: - Preference key for per-emoji frame tracking (Chat v4)

private struct ChatReactionFrameKey: PreferenceKey {
    static var defaultValue: ReactionFrame? = nil
    static func reduce(value: inout ReactionFrame?, nextValue: () -> ReactionFrame?) {
        value = nextValue() ?? value
    }
}

// MARK: - ChatReactionPickerView

struct ChatReactionPickerView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    let message: MessageModel
    let dismissAction: () -> Void

    @StateObject private var reactionVM: AmityLiveChatMessageReactionPickerViewModel
    @ObservedObject var hoverVM: ChatReactionPickerViewModel

    init(message: MessageModel, hoverVM: ChatReactionPickerViewModel, dismissAction: @escaping () -> Void) {
        self.message = message
        self.hoverVM = hoverVM
        self.dismissAction = dismissAction
        self._reactionVM = StateObject(wrappedValue: AmityLiveChatMessageReactionPickerViewModel(message: message))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MessageReactionConfiguration.shared.allReactions, id: \.id) { _ in
                Color.clear.frame(width: 42, height: 42)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(viewConfig.theme.backgroundColor))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .overlay(
            HStack(spacing: 4) {
                ForEach(MessageReactionConfiguration.shared.allReactions, id: \.id) { reaction in
                    let isHovered = hoverVM.hoveredReaction == reaction.name
                    let isSelected = reactionVM.message.myReactions.contains(where: { $0 == reaction.name })

                    ZStack {
                        Color(viewConfig.theme.backgroundShade1Color)
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                            .opacity(isSelected ? 1 : 0)

                        Image(reaction.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .scaleEffect(isHovered ? 1.25 : 1.0)
                            .offset(y: isHovered ? (hoverVM.showTooltipBelow ? 10 : -10) : 0)
                            .zIndex(isHovered ? 1 : 0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.35), value: hoverVM.hoveredReaction)
                    }
                    .frame(width: 42, height: 42)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ChatReactionFrameKey.self,
                                    value: ReactionFrame(id: reaction.name, frame: geo.frame(in: .global))
                                )
                        }
                    )
                    .onPreferenceChange(ChatReactionFrameKey.self) { frame in
                        if let frame = frame {
                            hoverVM.reactionFrames[frame.id] = frame.frame
                        }
                    }
                    .overlay(
                        ZStack {
                            Text(AmityStringProvider.chat.resolveChatReactionDisplayName(reaction.name))
                                .applyTextStyle(.captionSmall(.white))
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(20, corners: .allCorners)
                                .opacity(isHovered ? 1.0 : 0.0)
                                .offset(y: hoverVM.showTooltipBelow ? 30 : -60)
                        }
                        .allowsHitTesting(false)
                        .frame(width: 70, height: 200)
                        .frame(maxWidth: 80)
                        .offset(y: 14)
                        .clipped(antialiased: false)
                    )
                    .onTapGesture {
                        ImpactFeedbackGenerator.impactFeedback(style: .medium)
                        guard message.syncState == .synced else { return }
                        if isSelected {
                            reactionVM.removeRaction(reaction: reaction.name)
                        } else {
                            reactionVM.addReaction(reaction: reaction.name)
                        }
                        dismissAction()
                    }
                    .accessibilityIdentifier(reaction.accessibilityId)
                }
            }
        )
        .onAppear {
            hoverVM.commitReaction = { name in
                guard message.syncState == .synced else { return }
                if reactionVM.message.myReactions.contains(where: { $0 == name }) {
                    reactionVM.removeRaction(reaction: name)
                } else {
                    reactionVM.addReaction(reaction: name)
                }
            }
        }
    }
}

struct ChatActionMenuView: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    let message: MessageModel
    let messageAction: AmityMessageAction
    let dismissAction: () -> Void

    var body: some View {
        ChatMessageActionView(message: message, messageAction: messageAction, dismissAction: dismissAction)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(viewConfig.theme.backgroundColor))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
    }
}

struct ChatMessageActionOverlayView<Content: View>: View {
    @EnvironmentObject var viewConfig: AmityViewConfigController
    @State var isMenuActive: Bool = true
    var message: MessageModel
    let messageAction: AmityMessageAction
    let namespace: Namespace.ID
    let content: () -> Content
    let dismissAction: () -> Void

    var body: some View { EmptyView() }
}
