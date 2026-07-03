//
//  ChannelManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 12/3/2567 BE.
//

import Foundation
import AmitySDK

class ChannelManager {

    let repository: AmityChannelRepository

    init() {
        self.repository = AmityChannelRepository()
    }

    // MARK: - Channel queries

    func getChannel(channelId: String) -> AmityObject<AmityChannel> {
        return repository.getChannel(channelId)
    }

    func getCurrentUserChannelMember(channelId: String) -> AmityChannelMember? {
        return repository.getChannel(channelId).snapshot?.currentMember
    }

    func getChannels(with query: AmityChannelQueryOptions) -> AmityCollection<AmityChannel> {
        return repository.getChannels(with: query)
    }

    func getChannels(channelIds: [String]) -> AmityCollection<AmityChannel> {
        return repository.getChannels(channelIds: channelIds)
    }

    func searchChannels(options: AmityChannelSearchOptions) -> AmityCollection<AmityChannel> {
        return repository.searchChannels(options: options)
    }

    // MARK: - Channel lifecycle

    func createChannel(with builder: AmityChannelCreateOptions) async throws -> AmityChannel {
        return try await repository.createChannel(with: builder)
    }

    func joinChannel(channelId: String) async throws -> AmityChannel? {
        return try await repository.joinChannel(channelId: channelId)
    }

    func leaveChannel(channelId: String) async throws {
        try await repository.leaveChannel(channelId: channelId)
    }

    @discardableResult
    func updateChannel(builder: AmityChannelUpdateOptions) async throws -> AmityChannel {
        try await repository.editChannel(with: builder)
    }

    @discardableResult
    func editChannel(with builder: AmityChannelUpdateOptions) async throws -> AmityChannel {
        try await repository.editChannel(with: builder)
    }

    // MARK: - Archive

    func archiveChannel(channelId: String) async throws {
        try await repository.archiveChannel(channelId: channelId)
    }

    func unarchiveChannel(channelId: String) async throws {
        try await repository.unarchiveChannel(channelId: channelId)
    }

    func getArchivedChannels() -> AmityCollection<AmityChannel> {
        return repository.getArchivedChannels()
    }

    func getArchivedChannelIds() async throws -> [String] {
        return try await repository.getArchivedChannelIds()
    }

    // MARK: - Channel-level mute

    func muteChannel(channelId: String, mutePeriod: Int = 600) async throws {
        try await repository.muteChannel(channelId: channelId, mutePeriod: mutePeriod)
    }

    func unmuteChannel(channelId: String) async throws {
        try await repository.unmuteChannel(channelId: channelId)
    }

    // MARK: - Notification settings

    func notificationManager(channelId: String) -> AmityChannelNotificationsManager {
        return repository.notificationManagerForChannel(withId: channelId)
    }

    // MARK: - Membership

    func searchMembers(channelId: String, displayName: String, filterBuilder: AmityChannelMembershipFilterBuilder, roles: [String] = []) -> AmityCollection<AmityChannelMember> {
        let membership = AmityChannelMembership(channelId: channelId)
        return membership.searchMembers(displayName: displayName, filterBuilder: filterBuilder, roles: roles)
    }

    func getMembers(channelId: String, filter: AmityChannelMembershipFilter = .all, sortBy: AmitySortBy = .lastCreated, roles: [String] = []) -> AmityCollection<AmityChannelMember> {
        let membership = AmityChannelMembership(channelId: channelId)
        return membership.getMembers(filter: filter, sortBy: sortBy, roles: roles)
    }

    func addMembers(channelId: String, userIds: [String]) async throws {
        let membership = AmityChannelMembership(channelId: channelId)
        try await membership.addMembers(userIds)
    }

    func removeMembers(channelId: String, userIds: [String]) async throws {
        let membership = AmityChannelMembership(channelId: channelId)
        try await membership.removeMembers(userIds)
    }

    // MARK: - Moderation

    func banMembers(channelId: String, userIds: [String]) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        try await moderation.banMembers(userIds)
    }

    func unbanMembers(channelId: String, userIds: [String]) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        try await moderation.unbanMembers(userIds)
    }

    func muteMembers(channelId: String, userIds: [String], mutePeriod: Int = -1) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        try await moderation.muteMembers(userIds, mutePeriod: mutePeriod)
    }

    func unmuteMembers(channelId: String, userIds: [String]) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        try await moderation.unmuteMembers(userIds)
    }

    func addRole(channelId: String, userId: String, role: String) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        let _ = try await moderation.addRole(role, userIds: [userId])
    }

    func removeRole(channelId: String, userId: String, role: String) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        let _ = try await moderation.removeRole(role, userIds: [userId])
    }

    func addRole(channelId: String, role: String, userIds: [String]) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        let _ = try await moderation.addRole(role, userIds: userIds)
    }

    func removeRole(channelId: String, role: String, userIds: [String]) async throws {
        let moderation = AmityChannelModeration(channelId: channelId)
        let _ = try await moderation.removeRole(role, userIds: userIds)
    }
}
