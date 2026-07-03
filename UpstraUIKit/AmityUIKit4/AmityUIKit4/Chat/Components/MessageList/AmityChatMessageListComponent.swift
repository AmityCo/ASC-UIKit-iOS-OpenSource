//
//  AmityChatMessageListComponent.swift
//  AmityUIKit4
//

import SwiftUI
import AmitySDK
import UIKit

// MARK: - Date separator pill

private struct ChatDateSeparatorView: View {
    let label: String
    let theme: AmityThemeColor

    var body: some View {
        HStack {
            Spacer()
            Text(label)
                .applyTextStyle(.caption(Color(theme.baseColorShade1)))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(theme.backgroundColor))
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                )
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Date helpers

private extension Date {
    func chatSeparatorLabel() -> String {
        let cal = Calendar.current
        let f = DateFormatter()
        if let first = Locale.preferredLanguages.first {
            f.locale = Locale(identifier: first)
        }
        if cal.component(.year, from: self) == cal.component(.year, from: Date()) {
            f.dateFormat = "EEE, d MMM"
        } else {
            f.dateFormat = "EEE, d MMM yyyy"
        }
        return f.string(from: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Component

public struct AmityChatMessageListComponent: AmityComponentView {

    public var pageId: PageId?
    public var id: ComponentId { .messageList }

    @StateObject private var vm: AmityChatMessageListViewModel
    private var chatVM: AmityChatRoomViewModel
    @StateObject private var viewConfig: AmityViewConfigController
    @EnvironmentObject private var host: AmitySwiftUIHostWrapper

    /// Single owner of all scroll-position decisions (follow-to-bottom, keyboard,
    /// prepend, jump). Replaces the previous retry ladders + KVO auto-pin + the
    /// `isInitialLoad`/`isAdjustingForKeyboard`/`stickToBottomOnKeyboard` flags.
    @StateObject private var coordinator = ChatScrollCoordinator()

    @State private var newMessageBannerMessage: MessageModel? = nil
    @State private var bouncingMessageId: String? = nil

    private let bottomAnchorId = "___bottom___"

    public init(viewModel: AmityChatRoomViewModel, pageId: PageId? = .chatPage) {
        self.pageId = pageId
        self.chatVM = viewModel
        self._vm = StateObject(wrappedValue: viewModel.messageList)
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: pageId, componentId: .messageList))
    }

    public var body: some View {
        ZStack {
            messageListContent
                .opacity(vm.initialQueryState == .success ? 1 : 0)
                .onAppear { vm.queryMessages() }

            // Error empty state
            AmityEmptyStateView(configuration: .init(
                image: AmityIcon.Chat.greyRetryIcon.rawValue,
                title: nil,
                subtitle: AmityLocalizedStringSet.Chat.errorLoadingChat.localizedString,
                tapAction: { vm.queryMessages() }
            ))
                    .opacity(vm.initialQueryState == .error ? 1 : 0)

            // Banned empty state
            AmityEmptyStateView(configuration: .init(
                image: AmityIcon.Chat.bannedFromChatIcon.rawValue,
                title: AmityLocalizedStringSet.Chat.errorBannedTitleChat.localizedString,
                subtitle: AmityLocalizedStringSet.Chat.errorBannedSubTitleInChat.localizedString,
                iconSize: CGSize(width: 60, height: 60),
                iconTintColor: viewConfig.theme.baseColorShade4,
                tapAction: nil
            ))
            .opacity(vm.initialQueryState == .banned ? 1 : 0)
        }
        .onChange(of: vm.pendingReportMessageId) { msgId in
            guard let msgId = msgId else { return }
            vm.pendingReportMessageId = nil
            let page = AmityContentReportPage(type: .message(id: msgId))
                .environmentObject(viewConfig)
            let vc = AmitySwiftUIHostingNavigationController(rootView: page)
            vc.isNavigationBarHidden = true
            host.controller?.present(vc, animated: true)
        }
        .sheet(isPresented: $vm.showingReactionSheet) {
            if let msg = vm.selectedMessage, let amityMsg = msg.message {
                Group {
                    if #available(iOS 16, *) {
                        AmityReactionList(message: amityMsg, pageId: self.pageId)
                            .environmentObject(host)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.hidden)
                    } else {
                        AmityReactionList(message: amityMsg, pageId: self.pageId)
                            .environmentObject(host)
                    }
                }
            }
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .onChange(of: vm.showFailedActionSheet) { showing in
            guard showing else { return }
            presentFailedMessageActionSheet()
            vm.showFailedActionSheet = false
        }
        .onReceive(vm.$toastState) { state in
            guard let state else { return }
            chatVM.showToastMessage(message: state.message, style: state.style)
        }
        .onAppear { setupMessageActions() }
        .updateTheme(with: viewConfig)
    }

    // MARK: - Message list + FAB + mute banner

    private var messageListContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    scrollableMessages(proxy: proxy)

                    // New-message banner — shown only when the user is scrolled up
                    // (coordinator hysteresis). Tap → follow to bottom.
                    if let banner = newMessageBannerMessage, !coordinator.isNearBottom {
                        newMessageBanner(banner: banner)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 64)
                            .transition(.opacity)
                    }

                    // Scroll-to-latest FAB — visible only when scrolled up. The
                    // 24/80 hysteresis band (vs a raw 50pt) is what kills the flicker.
                    if !coordinator.isNearBottom {
                        scrollToLatestFAB()
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    }
                }
                .onAppear {
                    // Delegate the actual scroll to SwiftUI's proxy (realizes the
                    // target row → can't blank, unlike raw contentOffset).
                    // ALWAYS hop to the next runloop: this is invoked from the
                    // coordinator's contentSize/bounds KVO, which fires DURING
                    // SwiftUI's layout pass — calling proxy.scrollTo reentrantly
                    // there crashes (modifying state during view update / re-entrant
                    // contentSize recursion). The async escapes the update pass.
                    coordinator.requestScrollToBottom = { animated in
                        DispatchQueue.main.async {
                            if animated {
                                withAnimation { proxy.scrollTo(bottomAnchorId, anchor: .bottom) }
                            } else {
                                proxy.scrollTo(bottomAnchorId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            muteBanner
        }
    }

    private func scrollableMessages(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            scrollableContent(proxy: proxy)
        }
        // Simultaneous so it doesn't steal taps from buttons inside the list.
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
    }

    private func scrollableContent(proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(vm.messages.enumerated()), id: \.element.id) { index, message in
                messageRow(index: index, message: message)
            }

            // Zero-size bridge that hands the underlying UIScrollView to the
            // coordinator (which owns offset/size/bounds KVO + the follow latch).
            Color.clear
                .frame(height: 1)
                .id(bottomAnchorId)
                .background(ScrollViewAttacher(coordinator: coordinator))
        }
        .padding(.top, 8)
        // New message: follow if it's our own or we're near the bottom; otherwise
        // surface the banner. Follow goes through the coordinator (raw offset),
        // never proxy.scrollTo — see the channel rule in ChatScrollCoordinator.
        .onChange(of: vm.messages.last?.id) { _ in
            guard let latest = vm.messages.last else { return }
            if latest.isOwner || coordinator.isNearBottom {
                coordinator.followToBottom(animated: true)
                newMessageBannerMessage = nil
            } else {
                newMessageBannerMessage = latest
            }
            latest.message?.markRead()
        }
        .onAppear {
            coordinator.followToBottom(animated: false)
            vm.messages.last?.message?.markRead()
        }
        .onChange(of: vm.initialQueryState) { state in
            if state == .success {
                coordinator.followToBottom(animated: false)
                vm.messages.last?.message?.markRead()
            }
        }
        // Pagination: restore read position to the prior first row. Suppress the
        // bottom-pin for this one growth so the prepend doesn't yank to bottom.
        .onChange(of: vm.pagination.pagination) { _ in
            guard let anchor = vm.pagination.anchor else { return }
            coordinator.beginPrepend()
            proxy.scrollTo(anchor, anchor: .top)
            coordinator.endPrepend()
        }
        // Jump-to-message with bounce. A centered jump is an explicit
        // "reading up here" signal, so drop auto-follow.
        .onChange(of: vm.jumpToMessageId) { targetId in
            guard let targetId = targetId else { return }
            coordinator.markJumpedAway()
            withAnimation { proxy.scrollTo(targetId, anchor: .center) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                bouncingMessageId = targetId
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    bouncingMessageId = nil
                    vm.jumpToMessageId = nil
                }
            }
        }
    }

    @ViewBuilder
    private func messageRow(index: Int, message: MessageModel) -> some View {
        // Pagination spinner at top
        if message.id == vm.messages.first?.id, vm.isPaginationAvailable() {
            ProgressView()
                .progressViewStyle(.circular)
                .padding(.vertical, 8)
        }

        // Date separator
        let prev: MessageModel? = index > 0 ? vm.messages[index - 1] : nil
        if let createdAt = message.createdAt,
           prev == nil || prev?.createdAt.flatMap({ createdAt.isSameDay(as: $0) }) != true {
            ChatDateSeparatorView(
                label: createdAt.chatSeparatorLabel(),
                theme: viewConfig.theme
            )
            .id("date_\(message.id)")
        }

        // Bubble
        Group {
            if message.isOwner {
                AmityChatMessageSenderView(
                    message: message,
                    messageAction: vm.messageAction,
                    uploadProgress: vm.uploadProgress[message.uniqueId])
            } else {
                AmityChatMessageReceiverView(
                    message: message,
                    messageAction: vm.messageAction)
            }
        }
        .id(message.id)
        .padding(.bottom, message.id == vm.messages.last?.id ? 8 : 0)
        .accessibilityIdentifier(AccessibilityID.Chat.MessageList.bubbleContainer)
        .onAppear {
            if index == 0 { vm.loadMoreMessages() }
        }
        .scaleEffect(bouncingMessageId == message.id ? 1.08 : 1.0)
        .animation(
            bouncingMessageId == message.id
                ? .spring(response: 0.3, dampingFraction: 0.4, blendDuration: 0)
                : .default,
            value: bouncingMessageId
        )
    }

    private var muteBanner: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .frame(height: 1)
            Text(vm.muteState.localizedString)
                .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color(viewConfig.theme.backgroundShade1Color))
        }
        .opacity(vm.initialQueryState != .success ? 0 : 1)
        .isHidden(vm.muteState == .none || vm.hasModeratorPermission)
    }

    // MARK: - FAB & banner

    private func scrollToLatestFAB() -> some View {
        Button {
            coordinator.followToBottom(animated: true)
            newMessageBannerMessage = nil
        } label: {
            ZStack {
                Circle()
                    .fill(Color(viewConfig.theme.backgroundColor))
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .frame(width: 40, height: 40)
                Image(AmityIcon.Chat.downArrowIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
            }
        }
        .buttonStyle(.plain)
    }

    private func newMessageBanner(banner: MessageModel) -> some View {
        Button {
            coordinator.followToBottom(animated: true)
            newMessageBannerMessage = nil
        } label: {
            HStack(spacing: 10) {
                AmityUserProfileImageView(displayName: banner.displayName, avatarURL: banner.avatarURL)
                    .frame(width: 28, height: 28)

                Text(banner.isDeleted
                     ? AmityLocalizedStringSet.Chat.Preview.messageDeleted.localizedString
                     : (banner.type == .image ? AmityLocalizedStringSet.Chat.Preview.bannerPhoto.localizedString
                        : (banner.type == .video ? AmityLocalizedStringSet.Chat.Preview.bannerVideo.localizedString
                           : banner.text)))
                    .applyTextStyle(.custom(14, .regular, Color(viewConfig.theme.baseColor)))
                    .lineLimit(1)

                Spacer()

                Image(AmityIcon.Chat.downArrowIcon.imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade1))
                    .padding(.trailing, 10)
            }
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(viewConfig.theme.backgroundColor))
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message actions

    private func setupMessageActions() {
        let pushFullText: (String, String) -> Void = { text, title in
            let page = AmityChatFullTextPage(fullText: text, displayName: title)
                .environmentObject(viewConfig)
                .environmentObject(host)
            let vc: UIViewController = AmitySwiftUIHostingController(rootView: page)
            host.controller?.navigationController?.pushViewController(vc, animated: true)
        }
        let actions = AmityMessageAction(
            onCopy: { msg in
                UIPasteboard.general.string = msg.text
                chatVM.showToastMessage(
                    message: AmityLocalizedStringSet.Chat.toastCopied.localizedString,
                    style: .success)
            },
            onReply: { msg in
                chatVM.composer.action = .reply(msg)
            },
            onDelete: { msg in
                if msg.syncState == .error {
                    vm.deleteMessage(messageId: msg.id)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        guard let topVC = UIApplication.topViewController() else { return }
                        let alert = UIAlertController(
                            title: AmityLocalizedStringSet.Chat.deleteAlertTitle.localizedString,
                            message: AmityLocalizedStringSet.Chat.deleteAlertMessage.localizedString,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(
                            title: AmityLocalizedStringSet.General.cancel.localizedString,
                            style: .cancel))
                        alert.addAction(UIAlertAction(
                            title: AmityLocalizedStringSet.Chat.deleteButton.localizedString,
                            style: .destructive) { _ in
                                guard NetworkMonitor.shared.isConnected else {
                                    chatVM.showToastMessage(
                                        message: AmityLocalizedStringSet.Chat.toastDeleteErrorMessage.localizedString,
                                        style: .warning)
                                    return
                                }
                                vm.deleteMessage(messageId: msg.id)
                            })
                        topVC.present(alert, animated: true)
                    }
                }
            },
            onReport: { msg in
                vm.pendingReportMessageId = msg.id
            },
            onUnReport: { msg in
                vm.unReportMessage(messageId: msg.id)
            },
            onSaveImage: { msg in
                guard let url = msg.largeImageURL ?? msg.imageURL else { return }
                MessageMediaSaver.saveImage(from: url) { success in
                    let key = success
                        ? AmityLocalizedStringSet.Chat.SaveMedia.imageSuccess
                        : AmityLocalizedStringSet.Chat.SaveMedia.imageFailed
                    chatVM.showToastMessage(message: key.localizedString,
                                            style: success ? .success : .warning)
                }
            },
            onSaveVideo: { msg in
                guard let url = msg.videoPlaybackURL else { return }
                MessageMediaSaver.saveVideo(from: url) { success in
                    let key = success
                        ? AmityLocalizedStringSet.Chat.SaveMedia.videoSuccess
                        : AmityLocalizedStringSet.Chat.SaveMedia.videoFailed
                    chatVM.showToastMessage(message: key.localizedString,
                                            style: success ? .success : .warning)
                }
            },
            onSeeMore: { pushFullText($0, chatVM.channelDisplayName) },
            onResend: { msg in
                guard msg.syncState == .error else { return }
                Task {
                    do {
                        let _ = try await chatVM.messageList.chatManager.deleteMessage(messageId: msg.id)
                    } catch {
                    }

                    do {
                        switch msg.type {
                        case .text:
                            let text = msg.text
                            guard !text.isEmpty else { return }
                            let options = AmityTextMessageCreateOptions(
                                subChannelId: chatVM.channelId,
                                text: text,
                                parentId: msg.parentId
                            )
                            let _ = try await chatVM.messageList.chatManager.createTextMessage(options: options)
                        case .image:
                            guard let urlStr = msg.message?.getImageInfo()?.fileURL,
                                  let localURL = resolveLocalFileURL(from: urlStr) else { return }
                            let image = try await chatVM.messageList.chatManager.createImageMessage(
                                subChannelId: chatVM.channelId,
                                imageURL: localURL,
                                parentId: msg.parentId
                            )
                        case .video:
                            guard let urlStr = msg.message?.getVideoInfo()?.fileURL,
                                  let localURL = resolveLocalFileURL(from: urlStr) else { return }
                            let localThumbURL: URL? = await withCheckedContinuation { cont in
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let url = LocalVideoThumbnailCache.generateAndCache(videoURL: localURL)
                                    cont.resume(returning: url)
                                }
                            }
                            let recreated = try await chatVM.messageList.chatManager.createVideoMessage(
                                subChannelId: chatVM.channelId,
                                videoURL: localURL,
                                parentId: msg.parentId
                            )
                            if let localThumbURL {
                                LocalVideoThumbnailCache.associate(thumbnailURL: localThumbURL, withId: recreated.uniqueId)
                                LocalVideoThumbnailCache.associate(thumbnailURL: localThumbURL, withId: recreated.messageId)
                            }
                        case .file:
                            guard let urlStr = msg.message?.getFileInfo()?.fileURL,
                                  let localURL = resolveLocalFileURL(from: urlStr) else { return }
                            let _ = try await chatVM.messageList.chatManager.createFileMessage(
                                subChannelId: chatVM.channelId,
                                fileURL: localURL,
                                fileName: msg.message?.getFileInfo()?.attributes["name"] as? String,
                                parentId: msg.parentId
                            )
                        default:
                            break
                        }
                    } catch {
                        // Cancelling a resend lands in .error — don't toast that.
                        guard !error.isUploadCancelled else { return }
                        let isParentGone = msg.parentId != nil
                            && error.isAmityErrorCode(.itemNotFound)
                        let message = isParentGone
                            ? AmityLocalizedStringSet.Chat.toastReplyParentDeleted.localizedString
                            : AmityLocalizedStringSet.Chat.mediaFailedToSend.localizedString
                        chatVM.showToastMessage(
                            message: message,
                            style: .warning
                        )
                    }
                }
            }
        )
        actions.showReaction = { msg in
            vm.selectedMessage = msg
            vm.showingReactionSheet = true
        }
        actions.onSeeMoreReplied = { pushFullText($0, AmityLocalizedStringSet.Chat.Bubble.repliedMessage.localizedString) }
        actions.onEdit = { msg in
            chatVM.composer.action = .edit(msg)
        }
        actions.onFailedTap = { msg in
            vm.pendingFailedMessage = msg
            vm.showFailedActionSheet = true
        }
        // Cancel-X on an uploading media bubble: abort the upload + remove the
        // bubble immediately, no delete-confirmation dialog (Flutter parity).
        actions.onCancelUpload = { msg in
            vm.cancelUpload(uniqueId: msg.uniqueId)
        }
        vm.messageAction = actions
    }

    // MARK: - Failed-message action sheet (native UIAlertController)

    private func presentFailedMessageActionSheet() {
        let msg = vm.pendingFailedMessage

        // .alert, not .actionSheet — the latter's popover anchoring is broken on iOS 26.
        let alert = UIAlertController(
            title: AmityLocalizedStringSet.Chat.deleteActionSheetTitle.localizedString,
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: AmityLocalizedStringSet.Chat.Bubble.resend.localizedString,
            style: .default
        ) { _ in
            vm.pendingFailedMessage = nil
            if let msg { vm.messageAction.onResend?(msg) }
        })
        alert.addAction(UIAlertAction(
            title: AmityLocalizedStringSet.Chat.deleteButton.localizedString,
            style: .destructive
        ) { _ in
            vm.pendingFailedMessage = nil
            if let msg { vm.messageAction.onDelete?(msg) }
        })
        alert.addAction(UIAlertAction(
            title: AmityLocalizedStringSet.General.cancel.localizedString,
            style: .cancel
        ) { _ in
            vm.pendingFailedMessage = nil
        })

        let keyWindow = UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
        guard let rootVC = keyWindow?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        // Don't stack a duplicate alert (the tap can fire from icon + container).
        if topVC is UIAlertController { return }
        topVC.present(alert, animated: true)
    }

}

private func resolveLocalFileURL(from string: String) -> URL? {
    guard !string.isEmpty else { return nil }
    if let url = URL(string: string), url.scheme != nil {
        return url
    }
    return URL(fileURLWithPath: string)
}


#if DEBUG
#Preview {
    AmityChatMessageListComponent(viewModel: AmityChatRoomViewModel(channelId: ""))
}
#endif
