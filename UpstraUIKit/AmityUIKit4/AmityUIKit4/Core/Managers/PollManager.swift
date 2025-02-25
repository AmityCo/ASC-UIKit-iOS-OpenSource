//
//  PollManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 15/10/2567 BE.
//

import Foundation
import AmitySDK

class PollManager {
    private let pollRepository = AmityPollRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createPoll(question: String, answers: [String], isMultipleSelection: Bool, closedIn: Int) async throws -> String {
        
        let createOptions = AmityPollCreateOptions()
        createOptions.setQuestion(question)
        createOptions.setAnswerType(isMultipleSelection ? .multiple : .single)
        answers.forEach { answer in
            createOptions.setAnswer(answer)
        }
        createOptions.setTimeToClosePoll(closedIn)
        
        return try await pollRepository.createPoll(createOptions)
    }
    
    func deletePoll(pollId: String) async throws -> Bool {
        return try await pollRepository.deletePoll(withId: pollId)
    }
    
    func votePoll(pollId: String, answerIds: [String]) async throws -> Bool {
        return try await pollRepository.votePoll(withId: pollId, answerIds: answerIds)
    }
    
    func closePoll(pollId: String) async throws -> Bool {
        return try await pollRepository.closePoll(withId: pollId)
    }
}
