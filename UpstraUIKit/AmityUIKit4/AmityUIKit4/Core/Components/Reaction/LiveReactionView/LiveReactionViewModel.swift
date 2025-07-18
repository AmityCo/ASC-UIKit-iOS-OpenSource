//
//  LiveReactionViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 6/19/25.
//

import Foundation
import AmitySDK
import Combine

public struct AmityLiveReactionModel {
    var reactionName: String
    var referenceId: String = ""
    var referenceType: AmityLiveReactionReferenceType = .post
    var streamId: String = ""
    var icon: ImageResource = AmityIcon.Reaction.like.imageResource
}

struct ReactionAnimationModel: Identifiable {
    let id = UUID()
    let icon: ImageResource
    var name: String
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var angle: Double
    var laneIndex: Int
}

class LiveReactionViewModel {
    let width: CGFloat = 100
    let height: CGFloat = 320
    
    weak var containerView: LiveReactionUIView?
    private let stream: AmityStream
    
    private let reactionEngine = LiveReactionEngine()
    private let reactionManger = ReactionManager()
    private var cancellable: AnyCancellable?
    private var reactionsFromConfig: [(name: String, icon: ImageResource)] = []
    
    // Track whether animations are in progress for each lane
    private var isAnimatingLane = [Bool](repeating: false, count: 5)
    
    init(stream: AmityStream) {
        self.stream = stream
        getReactionDataFromConfig()
        subscribeLiveReactionEvent(stream)
        observeLiveReactions(stream)
    }
    
    deinit {
        unsubscribeLiveReactionEvent(stream)
    }
    
    /// Add a reaction to the container view and animate it
    func addReaction(_ reaction: AmityLiveReactionModel) {
        let newReaction = ReactionAnimationModel(
            icon: reaction.icon,
            name: reaction.reactionName,
            position: CGPoint(
                x: CGFloat.random(in: 20...(width-10)), // Random x position within lane
                y: self.height  // Start from bottom
            ),
            scale: 0.95,
            opacity: 1.0,
            angle: Double.random(in: -8...2),
            laneIndex: -1
        )
        
        containerView?.addReaction(newReaction)
        
        self.reactionManger.createLiveReaction(reaction.reactionName, referenceId: reaction.referenceId, referenceType: reaction.referenceType, streamId: reaction.streamId)
    }
    
    /// Observe live reactions for the given stream and process them
    private func observeLiveReactions(_ stream: AmityStream) {
        guard let post = stream.post else { return }
        cancellable = reactionManger.getLiveReactions(referenceId: post.postId, referenceType: .post, streamId: stream.streamId)
            .sink { [weak self] reactions in
                self?.processReactions(reactions.map {
                    AmityLiveReactionModel(reactionName: $0.reactionName,
                                           referenceId: $0.referenceId,
                                           referenceType: $0.referenceType,
                                           streamId: $0.streamId)
                })
            }
    }
    
    /// Process a batch of reactions and animate them in lanes
    private func processReactions(_ reactions: [AmityLiveReactionModel]) {
        // Process reactions through the engine
        reactionEngine.processReactions(reactions)
        
        // Start animations for each lane if not already animating
        for laneIndex in 0..<5 where !isAnimatingLane[laneIndex] {
            animateReactionsInLane(laneIndex)
        }
    }
    
    private func animateReactionsInLane(_ laneIndex: Int) {
        // Don't start if already animating this lane
        guard !isAnimatingLane[laneIndex] else { return }
        
        // Get next batch of reactions from the queue
        guard let reaction = reactionEngine.dequeueFromLane(laneIndex, maxCount: 5) else { return }
        
        isAnimatingLane[laneIndex] = true
                
        // Create reactions for the batch with staggered timing
        for i in 0..<reaction.count {
            // Stagger the animations slightly
            let delay = Double.random(in: 0.5...2.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                // Create a new reaction animation model
                let newReaction = ReactionAnimationModel(
                    icon: getReactionIcon(for: reaction.reactionName),
                    name: reaction.reactionName,
                    position: CGPoint(
                        x: CGFloat.random(in: 20...(width-10)), // Random x position within lane
                        y: self.height  // Start from bottom
                    ),
                    scale: 0.95,
                    opacity: 1.0,
                    angle: Double.random(in: -8...2),
                    laneIndex: laneIndex
                )
                
                // Notify the container view to add the reaction
                self.containerView?.addReaction(newReaction)
                
                // If this is the last animation, schedule checking for the next batch
                if i == reaction.count - 1 {
                    // Check if there are more items in this lane's queue
                    let hasMoreItems = !self.reactionEngine.getQueueForLane(laneIndex).isEmpty
                    
                    // Give some time for animations to progress before starting next batch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.isAnimatingLane[laneIndex] = false
                        
                        // Only attempt to animate next batch if we know there are more items
                        if hasMoreItems {
                            self?.animateReactionsInLane(laneIndex)
                        }
                    }
                }
            }
        }
    }
    
    private func getReactionDataFromConfig() {
        let reactionsDict = AmityUIKitConfigController.shared.config["reactions"] as? [[String: String]] ?? [[:]]
        
        reactionsDict.forEach { item in
            let name = item["name"] ?? ""
            let icon = ImageResource(name: item["image"] ?? "", bundle: AmityUIKit4Manager.bundle)
            
            let item = (name: name, icon: icon)
            reactionsFromConfig.append(item)
        }
    }
    
    private func getReactionIcon(for reactionName: String) -> ImageResource {
        if let reaction = reactionsFromConfig.first(where: { (name, icon) in
            name == reactionName
        }) {
            return reaction.icon
        } else {
            return AmityIcon.Reaction.like.imageResource // Default to like if unknown
        }
    }
        
    
    private func subscribeLiveReactionEvent(_ stream: AmityStream) {
        stream.post?.subscribeEvent(.liveReaction) { success, error in
            if error != nil {
                Log.add(event: .error, "Failed to subscribe to live reaction event: \(error!.localizedDescription)")
            } else {
                Log.add(event: .info, "Subscribed to live reaction event for post: \(stream.post?.postId ?? "unknown")")
            }
        }
    }
    
    private func unsubscribeLiveReactionEvent(_ stream: AmityStream) {
        stream.post?.unsubscribeEvent(.liveReaction) { success, error in
            if error != nil {
                Log.add(event: .error, "Failed to unsubscribe from live reaction event: \(error!.localizedDescription)")
            } else {
                Log.add(event: .info, "Unsubscribed from live reaction event for post: \(stream.post?.postId ?? "unknown")")
            }
        }
    }
}

