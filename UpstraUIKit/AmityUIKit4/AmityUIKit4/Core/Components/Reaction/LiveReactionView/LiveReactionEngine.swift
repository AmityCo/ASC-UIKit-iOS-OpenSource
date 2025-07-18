//
//  LiveReactionEngine.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/19/25.
//

class LiveReactionEngine {
    struct ReactionCount {
        let reactionName: String
        let count: Int
    }
    
    // Five queues for five lanes
    var queues: [[ReactionCount]] = Array(repeating: [], count: 5)
    
    @discardableResult
    func processReactions(_ reactions: [AmityLiveReactionModel]) -> [ReactionCount] {
        // Step 1: Group by reactionName
        var reactionGroups: [String: Int] = [:]
        
        for reaction in reactions {
            reactionGroups[reaction.reactionName, default: 0] += 1
        }
        
        // Step 2: Convert to ReactionCount array
        let reactionCounts = reactionGroups.map { ReactionCount(reactionName: $0.key, count: $0.value) }
        
        // Step 3: Distribute to 5 lanes using the existing algorithm
        let distributedReactions = distributeTo5Lanes(reactionCounts)
        
        // Step 4: Store reactions in their respective lane queues
        var laneIndex = 0
        for reaction in distributedReactions {
            queues[laneIndex].append(reaction)
            laneIndex = (laneIndex + 1) % 5
        }
        
        return distributedReactions
    }
    
    private func distributeTo5Lanes(_ reactionCounts: [ReactionCount]) -> [ReactionCount] {
        var lanes: [ReactionCount] = []
        
        // Sort the counts descendingly
        let sortedReactions = reactionCounts.sorted { $0.count > $1.count }
        
        var remainingLanes = 5
        
        for (index, reaction) in sortedReactions.enumerated() where remainingLanes > 0 {
            let remainingReactions = sortedReactions.count - index
            
            // Calculate how many lanes this reaction can occupy
            let minLanesNeeded = min(1, remainingLanes) // At least 1 lane
            let maxLanesAllowed = min(remainingLanes - (remainingReactions - 1), reaction.count)
            let lanesForThisReaction = max(minLanesNeeded, maxLanesAllowed)
            
            // Distribute the reaction count across the lanes
            let countPerLane = reaction.count / lanesForThisReaction
            let remainder = reaction.count % lanesForThisReaction
            
            for j in 0..<lanesForThisReaction {
                let count = countPerLane + (j < remainder ? 1 : 0)
                lanes.append(ReactionCount(reactionName: reaction.reactionName, count: count))
            }
            
            remainingLanes -= lanesForThisReaction
        }
        
        return lanes
    }
    
    // Helper methods to work with queues
    func getQueueForLane(_ laneIndex: Int) -> [ReactionCount] {
        guard laneIndex >= 0 && laneIndex < queues.count else { return [] }
        return queues[laneIndex]
    }
    
    func dequeueFromLane(_ laneIndex: Int, maxCount: Int = 5) -> ReactionCount? {
        guard laneIndex >= 0 && laneIndex < queues.count, !queues[laneIndex].isEmpty else { return nil }
        
        // Get the next reaction but limit its count for performance
        var reaction = queues[laneIndex][0]
        
        if reaction.count <= maxCount {
            // Remove completely if we're taking all
            queues[laneIndex].removeFirst()
        } else {
            // Split the reaction and take only a batch
            let remaining = reaction.count - maxCount
            queues[laneIndex][0] = ReactionCount(reactionName: reaction.reactionName, count: remaining)
            reaction = ReactionCount(reactionName: reaction.reactionName, count: maxCount)
        }
        
        return reaction
    }
    
    func clearAllQueues() {
        queues = Array(repeating: [], count: 5)
    }
}

