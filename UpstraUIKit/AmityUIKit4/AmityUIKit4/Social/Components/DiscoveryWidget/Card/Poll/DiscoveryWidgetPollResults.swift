//
//  DiscoveryWidgetPollResults.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/9/26.
//

import Foundation

/// Ordering, capping and percentage arithmetic for the widget's read-only poll.
///
/// This is a **new** read-only tree, deliberately not a flag on the feed's interactive poll. The
/// ordering rule below would otherwise sit one boolean away from the feed, where the *authored*
/// order is load-bearing.
struct DiscoveryWidgetPollResults {

    struct Option: Identifiable {
        let answer: AmityPostModel.PollModel.Answer
        let share: Double
        /// The leading option — highest vote share, and always rendered first. Never set on a
        /// zero-vote poll: with no votes there is no leader.
        let isLeading: Bool

        var id: String { answer.id }

        var formattedPercentage: String {
            let value = DiscoveryWidgetPollResults.percentageFormatter.string(from: NSNumber(value: share * 100)) ?? "0"
            return "\(value)%"
        }
    }

    let poll: AmityPostModel.PollModel
    /// Every option, ordered leader-first.
    let orderedOptions: [Option]
    /// The prefix that fits the card's fixed 296 poll budget.
    let visibleOptions: [Option]

    init(poll: AmityPostModel.PollModel) {
        self.poll = poll

        let total = poll.voteCount
        let highest = poll.answers.map(\.voteCount).max() ?? 0

        // Descending by vote share, ties broken by authored order so ordering is stable across
        // renders of the same pool. PDT-4639 states only that the leader comes first; whether the
        // remainder is sorted or left authored is unconfirmed (Plan 39 Q8) — a full sort is the
        // reading that also satisfies the weaker one.
        let ranked = poll.answers.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.voteCount != rhs.element.voteCount {
                    return lhs.element.voteCount > rhs.element.voteCount
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)

        // Only the first-ranked option is emphasised, so a tie for the lead never paints two
        // leaders — which is the ambiguity Q8 leaves open.
        var leaderAssigned = false
        self.orderedOptions = ranked.map { answer in
            let isLeading = highest > 0 && total > 0 && answer.voteCount == highest && !leaderAssigned
            if isLeading { leaderAssigned = true }
            return Option(
                answer: answer,
                share: total > 0 ? Double(answer.voteCount) / Double(total) : 0,
                isLeading: isLeading
            )
        }

        // The cap is a consequence of the fixed budget, not an independent product rule: options
        // fill it in order and the remainder is not rendered. Because ordering puts the leader
        // first, the options that survive are the ones that carry the result — and *See full
        // results* is always there as the route to the rest.
        let capacity = poll.isImagePoll
            ? DiscoveryWidgetMetrics.pollVisibleImageOptionCount
            : DiscoveryWidgetMetrics.pollVisibleTextOptionCount
        self.visibleOptions = Array(orderedOptions.prefix(capacity))
    }

    var hasVotes: Bool {
        poll.voteCount > 0
    }

    /// `{voteCount} • {status}` — the remaining time while ongoing, *Ended* once closed. An ended
    /// poll differs from an ongoing one **only** here; its results render identically.
    var statusText: String {
        let formattedVoteCount = Self.voteCountFormatter.string(from: NSNumber(value: poll.voteCount)) ?? "0"
        let voteCountKey = poll.voteCount == 1
            ? AmityLocalizedStringSet.Social.pollVoter
            : AmityLocalizedStringSet.Social.pollVoters
        let votes = voteCountKey.localized(arguments: formattedVoteCount)
        return "\(votes) • \(remainingStatus)"
    }

    private var remainingStatus: String {
        guard !poll.isClosed else {
            return AmityLocalizedStringSet.Social.discoveryWidgetPollEnded.localizedString
        }
        return PollStatus(poll: poll, isInPendingFeed: false).statusInfo
    }

    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let voteCountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter
    }()
}
