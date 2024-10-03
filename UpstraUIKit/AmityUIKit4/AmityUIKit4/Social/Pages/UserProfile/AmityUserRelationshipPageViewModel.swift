//
//  AmityUserRelationshipPageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/24/24.
//

import Foundation
import AmitySDK
import Combine

public class AmityUserRelationshipPageViewModel: ObservableObject {
    @Published var user: AmityUserModel?
    
    private var cancellable: AnyCancellable?
    private var liveObject: AmityObject<AmityUser>
    private let userManager = UserManager()
    private let userId: String
    
    public init(_ userId: String) {
        self.userId = userId
        
        self.liveObject = userManager.getUser(withId: userId)
        self.cancellable = liveObject.$snapshot
            .sink(receiveValue: { [weak self] user in
                guard let user else { return }
                self?.user = AmityUserModel(user: user)
        })
    }
    
    func block(userId: String) async throws {
        try await userManager.blockUser(withId: userId)
    }
    
    @discardableResult
    func flagUser(userId: String) async throws -> Bool {
        try await userManager.flagUser(withId: userId)
    }
    
    @discardableResult
    func unflaguser(userId: String) async throws -> Bool {
        try await userManager.unflagUser(withId: userId)
    }
    
    @discardableResult
    func flaggedByMe(userId: String) async throws -> Bool {
        try await userManager.isUserFlaggedByMe(withId: userId)
    }
}
