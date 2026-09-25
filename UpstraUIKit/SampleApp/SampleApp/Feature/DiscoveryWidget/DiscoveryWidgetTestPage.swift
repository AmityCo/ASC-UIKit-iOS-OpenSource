//
//  DiscoveryWidgetTestPage.swift
//  SampleApp
//
//  Discovery Widget test screen — Plan 39 Phase 6.
//

import SwiftUI
import AmitySDK
import AmityUIKit4

/// A dedicated harness for the Discovery Widget.
///
/// No existing sample-app screen can exercise it: the widget needs a topic slug and a session, and
/// its most important failure modes are about *not rendering*, which a generic feed screen cannot
/// isolate.
///
/// Reachable states: empty pool · below threshold · all posts unsupported types · content-call
/// failure · loading · both breakpoints.
struct DiscoveryWidgetTestPage: View {

    @State private var topicId = "sample-topic"
    @State private var showHeader = true
    @State private var minVisibilityThreshold = 3
    /// Bumped on Apply so the widget remounts — evaluation is per page load, so a re-read of the
    /// pool means a new mount, exactly as production does.
    @State private var mountToken = UUID()
    @State private var lastClick: String?
    /// The widget itself has no default destination — `goToDestination` is empty on all three
    /// platforms, because the destination belongs to the integrator. This page stands in for one, so
    /// that "a card tap does something" is observable rather than something to take on trust.
    @State private var cardTap: CardTap?

    /// Identifiable so the alert is driven by the tap itself, not by a flag read alongside it.
    private struct CardTap: Identifiable {
        let id = UUID()
        let postId: String
        let topicId: String
    }

    var body: some View {
        VStack(spacing: 0) {
            controls

            Divider()

            // No scroll view and no padding: the container is exactly as tall as the widget makes
            // it. `fixedSize` vertically stops the stack compressing it, so what you see is the
            // widget's own content-derived height (552 compact / 584 expanded) and nothing else.
            //
            // A useful side effect — when the widget hides, this collapses to nothing, so the
            // "zero layout height" requirement is visible rather than something to take on trust.
            widget
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
        }
        .navigationTitle("Discovery Widget")
        .alert(item: $cardTap) { tap in
            Alert(title: Text(""),
                  message: Text("Post \(tap.postId)\nTopic \(tap.topicId)"),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Controls

    private var controls: some View {
        Form {
            Section(header: Text("Topic"),
                    footer: Text("The slug as saved in the console. The heading comes from the API's topicName, so there is nothing to type for it. A bogus slug is a real 404 — the widget hides. When it hides, the Xcode console carries the reason; the widget itself never shows one.")) {
                TextField("Topic slug", text: $topicId)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                // Sits next to the field rather than only at the foot of the form, which scrolls
                // — a button down there is below the fold.
                Button(action: apply) {
                    HStack {
                        Text("Load topic")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(trimmedTopicId.isEmpty)
            }

            Section(header: Text("Widget parameters")) {
                Toggle("showHeader", isOn: $showHeader)
                Stepper("minVisibilityThreshold: \(minVisibilityThreshold)",
                        value: $minVisibilityThreshold,
                        in: 1...10)
            }

            Section(header: Text("Session"),
                    footer: Text("Switch between a signed-in user and a visitor on the login screen.")) {
                HStack {
                    Text("Current")
                    Spacer()
                    Text(AmityUIKit4Manager.client.currentUserType.rawValue)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                // Same action — remounting is how every setting on this page takes effect, because
                // the widget evaluates once per page load and never mid-session.
                Button("Reload widget", action: apply)
                    .disabled(trimmedTopicId.isEmpty)

                if let lastClick {
                    Text("Last card click: \(lastClick)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var trimmedTopicId: String {
        topicId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var widget: some View {
        AmityDiscoveryWidgetComponent(
            topicId: topicId,
            showHeader: showHeader,
            minVisibilityThreshold: minVisibilityThreshold,
            onCardClick: { topicId, post in
                lastClick = "\(post.postId) (topic: \(topicId))"
                cardTap = CardTap(postId: post.postId, topicId: topicId)
            }
        )
        .id(mountToken)
    }

    // MARK: - Actions

    private func apply() {
        topicId = trimmedTopicId
        // A new identity tears down the component and its view model, so the next mount runs a
        // fresh `getPool` against whatever the slug now says — the same one-shot path a real page
        // load takes.
        mountToken = UUID()
    }
}
