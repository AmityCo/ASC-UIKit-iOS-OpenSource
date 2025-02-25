//
//  AmityEditUserProfilePageViewModel.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/23/24.
//

import UIKit
import AmitySDK
import Combine

struct UserModel {
    var about: String
    var avatar: UIImage?
}

class AmityEditUserProfilePageViewModel: ObservableObject {
    @Published var user: AmityUserModel?
    private let userId: String
    private let userManager = UserManager()
    private let userObject: AmityObject<AmityUser>
    private var cancellable: AnyCancellable?
    
    init(userId: String) {
        self.userId = userId
        userObject = userManager.getUser(withId: userId)
        cancellable = userObject.$snapshot.sink { [weak self] user in
            guard let user else { return }
            let model = AmityUserModel(user: user)
            self?.user = model
        }
    }
    
    @discardableResult
    func updateUser(_ user: UserModel) async throws -> Bool {
        try await userManager.editUser(user: user)
    }
}
