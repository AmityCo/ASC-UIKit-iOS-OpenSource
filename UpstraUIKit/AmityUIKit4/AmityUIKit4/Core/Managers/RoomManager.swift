//
//  RoomManager.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 10/31/25.
//

import AmitySDK
import Combine

class RoomManager {
    private let repository = AmityRoomRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createRoom(options: AmityRoomCreateOptions) async throws -> AmityRoom {
        return try await repository.createRoom(with: options)
    }
    
    func generateRoomToken(roomId: String) async throws -> (token: String, url: String)? {
        let result = try await repository.generateRoomToken(withId: roomId)
        guard let token = result?["coHostToken"] as? String, let url = result?["coHostUrl"] as? String else {
            return nil
        }
        
        
        return (token: token, url: url)
    }
    
    func getRoom(roomId: String) -> AmityObject<AmityRoom> {
        return repository.getRoom(withId: roomId)
    }
    
    @MainActor
    func stopRoom(roomId: String) async throws {
        let _ = try await repository.stopRoom(withId: roomId)
    }
    
    @MainActor
    func leaveRoom(roomId: String) async throws {
        let _ = try await repository.leaveRoom(withId: roomId)
    }
    
    @MainActor
    func removeCohost(roomId: String, userId: String) async throws {
        let _ = try await repository.removeParticipant(withId: roomId, userId: userId)
    }
    
    func getCoHostEvent(roomId: String) -> AnyPublisher<AmityCoHostEvent, Never> {
        return repository.getCoHostEvent(roomId: roomId)
    }
}
