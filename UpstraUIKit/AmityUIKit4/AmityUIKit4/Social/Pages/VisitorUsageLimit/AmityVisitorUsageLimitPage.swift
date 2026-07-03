//
//  AmityVisitorUsageLimitPage.swift
//  AmityUIKit4
//

import SwiftUI

public struct AmityVisitorUsageLimitPage: AmityPageView {
    @EnvironmentObject public var host: AmitySwiftUIHostWrapper
    @StateObject private var viewConfig: AmityViewConfigController

    public var id: PageId {
        .visitorUsageLimitPage
    }

    @State private var showToast: Bool = false

    public init() {
        self._viewConfig = StateObject(wrappedValue: AmityViewConfigController(pageId: .visitorUsageLimitPage))
    }

    public var body: some View {
        ZStack {
            Color(viewConfig.theme.backgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    ZStack {
                        Image(AmityIcon.amityIcWarningDocument.imageResource)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(viewConfig.theme.baseColorShade3))
                            .frame(width: 60, height: 40)
                    }
                    .frame(width: 64, height: 64)

                    VStack(spacing: 0) {
                        Text(AmityLocalizedStringSet.Social.visitorUsageLimitTitle.localizedString)
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColorShade3)))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 252)

                        Text(AmityLocalizedStringSet.Social.visitorUsageLimitSubtitle.localizedString)
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade3)))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 252)
                    }
                }

                Button {
                    AmityUIKit4Manager.behaviour.globalBehavior?.handleVisitorUsageLimitSignIn()
                } label: {
                    Text(AmityLocalizedStringSet.Social.visitorUsageLimitSignIn.localizedString)
                        .applyTextStyle(.bodyBold(Color(viewConfig.theme.primaryColor)))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 343)

            VStack {
                Spacer()
                if showToast {
                    AmityVisitorUsageLimitToastView(
                        message: AmityLocalizedStringSet.Social.visitorUsageLimitToast.localizedString
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            host.controller?.navigationController?.isNavigationBarHidden = true
            withAnimation {
                showToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showToast = false
                }
            }
        }
        .updateTheme(with: viewConfig)
    }
}

struct AmityVisitorUsageLimitToastView: View {
    let message: String

    @State private var dragOffset: CGFloat = 0
    @State private var isDismissed: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(AmityIcon.infoIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 24, height: 24)

            Text(message)
                .applyTextStyle(.body(.white))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(AmityFixedColor.shared.toastBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 0)
                .shadow(color: Color(red: 96/255, green: 97/255, blue: 112/255).opacity(0.16), radius: 2, x: 0, y: 0.5)
        )
        .offset(x: dragOffset)
        .opacity(isDismissed ? 0 : 1)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        withAnimation {
                            dragOffset = value.translation.width > 0 ? 1000 : -1000
                            isDismissed = true
                        }
                    } else {
                        withAnimation {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
