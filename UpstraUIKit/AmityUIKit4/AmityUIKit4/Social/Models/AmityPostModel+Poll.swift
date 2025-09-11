//
//  AmityPostModel+Poll.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 20/6/25.
//

import SwiftUI
import AmitySDK

extension AmityPostModel {
    
    public class PollModel {
        
        // Public
        public let id: String
        public let question: String
        public let answers: [Answer]
        public let canVoteMultipleOptions: Bool
        public let status: String
        public let isClosed: Bool
        public let isVoted: Bool
        public let closedIn: UInt64 // This time is in milliseconds.
        public let voteCount: Int
        public let createdAt: Date
        public let isOpen: Bool
        public let isImagePoll: Bool
        
        public init(poll: AmityPoll) {
            self.id = poll.pollId
            self.question = poll.question
            self.canVoteMultipleOptions = poll.isMultipleVote
            self.status = poll.status
            self.isClosed = poll.isClosed
            self.isVoted = poll.isVoted
            self.closedIn = UInt64(poll.closedIn)
            self.voteCount = Int(poll.voteCount)
            self.answers = poll.answers.map { Answer(answer: $0) }
            self.createdAt = poll.createdAt
            self.isOpen = !poll.isClosed || !poll.isVoted
            self.isImagePoll = poll.answers.first?.dataType == "image"
        }
        
        public class Answer: Identifiable {
            public let id: String
            public let dataType: String
            public let text: String
            public let isVotedByUser: Bool
            public let voteCount: Int
            public let image: AmityImageData?
            
            public init(answer: AmityPollAnswer) {
                self.id = answer.answerId
                self.dataType = answer.dataType
                self.text = answer.text
                self.isVotedByUser = answer.isVotedByUser
                self.voteCount = Int(answer.voteCount)
                self.image = answer.image
            }
            
            // For testing purpose
            init(text: String) {
                self.id = UUID().uuidString
                self.dataType = "image"
                self.text = text
                self.isVotedByUser = false
                self.voteCount = 0
                self.image = nil
            }
        }
    }
}

class PollStatus {
    var statusInfo: String = ""
    var isInPendingFeed: Bool

    init(poll: AmityPostModel.PollModel, isInPendingFeed: Bool) {
        self.isInPendingFeed = isInPendingFeed
        if poll.isClosed {
            statusInfo = AmityLocalizedStringSet.Social.pollStatusEnded.localizedString
        } else {
            let closedInDate = poll.createdAt.addingTimeInterval(Double(poll.closedIn) / 1000)
            computeRemainingTime(closedInDate: closedInDate, isInPendingFeed: isInPendingFeed)
        }
    }
    
    private func computeRemainingTime(closedInDate: Date, isInPendingFeed: Bool) {
        let currentDate = Date()
        
        if closedInDate > currentDate {
            
            if isInPendingFeed {
                statusInfo = AmityLocalizedStringSet.Social.pollEndsOnLabel.localizedString + " " + Formatters.pollDurationFormatter.string(from: closedInDate)
                return
            }
            
            let difference = Calendar.current.dateComponents([.day,.hour,.minute], from: currentDate, to: closedInDate)
            
            if let remainingDays = difference.day, remainingDays > 0 {
                // In case of 3 days, 22 hour, we will display 4 days
                let remainingHours = difference.hour ?? 0
                let roundUpValue = remainingHours > 0 ? 1 : 0
                statusInfo = RemainingTime.days(count: remainingDays + roundUpValue).info
                return
            }
            
            if let remainingHours = difference.hour, remainingHours > 0 {
                statusInfo = RemainingTime.hours(count: remainingHours).info
                return
            }
            
            if let remainingMinutes = difference.minute, remainingMinutes > 0 {
                statusInfo = RemainingTime.minutes(count: remainingMinutes).info
                return
            } else {
                // We don't want to show remaining time in seconds. So we just show `1 minute`
                statusInfo = RemainingTime.minutes(count: 1).info
                return
            }
            
        } else {
            statusInfo = AmityLocalizedStringSet.Social.pollStatusEnded.localizedString
        }
    }
    
    private enum RemainingTime {
        case days(count: Int)
        case hours(count: Int)
        case minutes(count: Int)
        
        var info: String {
            switch self {
            case .days(let remainingDays):
                return "\(remainingDays)" + AmityLocalizedStringSet.Social.pollRemainingDaysLeft.localizedString
                
            case .hours(let remainingHours):
                return "\(remainingHours)" + AmityLocalizedStringSet.Social.pollRemainingHoursLeft.localizedString
                
            case .minutes(let remainingMinutes):
                return "\(remainingMinutes)" + AmityLocalizedStringSet.Social.pollRemainingMinutesLeft.localizedString
            }
        }
    }
}
