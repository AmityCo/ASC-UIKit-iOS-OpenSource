//
//  AVPlayerLayerCache.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 23/6/25.
//

import Foundation
import AVFoundation

/// A Least Recently Used (LRU) cache for AVPlayerLayer instances
/// Manages video players efficiently by caching them with URL keys
class AVPlayerLayerCache {
    
    static let shared = AVPlayerLayerCache(capacity: 5)
    
    // MARK: - Node Structure for Doubly Linked List
    private class CacheNode {
        let key: String
        let playerLayer: AVPlayerLayer
        var prev: CacheNode?
        var next: CacheNode?
        
        init(key: String, playerLayer: AVPlayerLayer) {
            self.key = key
            self.playerLayer = playerLayer
        }
    }
    
    // MARK: - Properties
    private let capacity: Int
    private var cache: [String: CacheNode] = [:]
    private let head: CacheNode
    private let tail: CacheNode
    
    // MARK: - Initialization
    
    /// Initialize LRU cache with specified capacity
    /// - Parameter capacity: Maximum number of AVPlayerLayer instances to cache (default: 5)
    private init(capacity: Int = 5) {
        self.capacity = max(1, capacity) // Ensure minimum capacity of 1
        
        // Create dummy head and tail nodes for easier linked list operations
        self.head = CacheNode(key: "dummy://head", playerLayer: AVPlayerLayer())
        self.tail = CacheNode(key: "dummy://tail", playerLayer: AVPlayerLayer())
        
        // Connect head and tail
        head.next = tail
        tail.prev = head
    }
    
    // MARK: - Public Methods
    
    /// Get AVPlayerLayer for the given URL
    /// Creates new player if not in cache, otherwise returns cached player
    /// - Parameter url: The URL key for the video
    /// - parameter id: Clip Post Id
    /// - Returns: AVPlayerLayer instance ready for playback
    func getPlayerLayer(for url: URL, id: String) -> AVPlayerLayer {
        if let node = cache[id] {
            // Move to front (most recently used)
            moveToFront(node)
            return node.playerLayer
        } else {
            // Create new AVPlayerLayer
            let playerLayer = createPlayerLayer(for: url)
            
            // Add to cache
            let newNode = CacheNode(key: id, playerLayer: playerLayer)
            addToFront(newNode)
            cache[id] = newNode
            
            // Remove least recently used if over capacity
            if cache.count > capacity {
                removeLeastRecentlyUsed()
            }
            
            return playerLayer
        }
    }
    
    /// Remove a specific URL from cache
    /// - Parameter url: The URL to remove
    func removePlayerLayer(for id: String) {
        guard let node = cache[id] else { return }
        removeNode(node)
        cache.removeValue(forKey: id)
    }
    
    /// Clear all cached players
    func clearCache() {
        // Pause all players before clearing
        for (_, node) in cache {
            node.playerLayer.player?.pause()
        }
        
        cache.removeAll()
        head.next = tail
        tail.prev = head
    }
    
    /// Get current cache size
    var count: Int {
        return cache.count
    }
    
    /// Get maximum cache capacity
    var maxCapacity: Int {
        return capacity
    }
    
    /// Get all cached URLs in order of most to least recently used
    var cachedIds: [String] {
        var ids: [String] = []
        var current = head.next
        
        while current !== tail {
            if let node = current, node !== head {
                ids.append(node.key)
            }
            current = current?.next
        }
        
        return ids
    }
    
    // MARK: - Private Methods
    
    /// Create a new AVPlayerLayer for the given URL
    private func createPlayerLayer(for url: URL) -> AVPlayerLayer {
        let headers = [
            "Authorization": "Bearer \(AmityUIKitManagerInternal.shared.client.accessToken ?? "")"
        ]
        
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 1
        
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        
        let playerLayer = AVPlayerLayer(player: player)
        
        // Configure player layer with common settings
        playerLayer.videoGravity = .resizeAspectFill
        // playerLayer.needsDisplayOnBoundsChange = true
        
        return playerLayer
    }
    
    /// Add node to the front of the linked list (most recently used position)
    private func addToFront(_ node: CacheNode) {
        let nextNode = head.next // tailNode
        head.next = node
        node.prev = head
        node.next = nextNode
        nextNode?.prev = node
    }
    
    /// Move existing node to front of the linked list
    private func moveToFront(_ node: CacheNode) {
        removeNode(node)
        addToFront(node)
    }
    
    /// Remove node from linked list
    private func removeNode(_ node: CacheNode) {
        let prevNode = node.prev
        let nextNode = node.next
        prevNode?.next = nextNode
        nextNode?.prev = prevNode
    }
    
    /// Remove the least recently used item (tail's previous node)
    private func removeLeastRecentlyUsed() {
        guard let lruNode = tail.prev, lruNode !== head else { return }
        
        // Pause the player before removing
        lruNode.playerLayer.player?.pause()
        
        // lruNode.playerLayer.removeFromSuperlayer()
        
        removeNode(lruNode)
        cache.removeValue(forKey: lruNode.key)
    }
    
    // We use this when we receive memory warning
    func flushCacheItem() {
        removeLeastRecentlyUsed()
    }
}

// Helper Extension
extension AVPlayerLayerCache {
    
    /// Pause all cached players
    func pauseAllPlayers() {
        for (_, node) in cache {
            node.playerLayer.player?.pause()
        }
    }
    
    /// Resume player for specific URL if cached
    /// - Parameter url: URL of the player to resume
    func resumePlayer(for id: String) {
        guard let node = cache[id] else { return }
        node.playerLayer.player?.play()
        moveToFront(node) // Mark as recently used
    }
}
