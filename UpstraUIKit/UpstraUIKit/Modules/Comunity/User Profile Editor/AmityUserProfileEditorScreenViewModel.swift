//
//  AmityEditUserProfileScreenViewModel.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 15/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityUserProfileEditorScreenViewModel: AmityUserProfileEditorScreenViewModelType {
    
    private let userRepository = AmityUserRepository()
    private var userObject: AmityObject<AmityUser>?
    private var userCollectionToken: AmityNotificationToken?
    private let dispatchGroup = DispatchGroupWraper()
    private let amityUserUpdateBuilder = AmityUserUpdateOptions()
    private let fileRepository = AmityFileRepository()
    
    weak var delegate: AmityUserProfileEditorScreenViewModelDelegate?
    var user: AmityUserModel?
    
    init() {
        userObject = userRepository.getUser(AmityUIKitManagerInternal.shared.client.currentUserId!)
        userCollectionToken = userObject?.observe { [weak self] user, error in
            guard let strongSelf = self,
                  let user = user.snapshot else{ return }
            
            strongSelf.user = AmityUserModel(user: user)
            strongSelf.delegate?.screenViewModelDidUpdate(strongSelf)
        }
    }
    
    func updateUser(displayName: String, aboutDescription: String, avatar: UIImage?, completion: @escaping (Bool) -> Void) {
        
        let amityUserUpdateBuilder = AmityUserUpdateOptions()
        amityUserUpdateBuilder.setDisplayName(displayName)
        amityUserUpdateBuilder.setUserDescription(aboutDescription)
        
        Task { @MainActor in
            
            // Try to upload image first
            var imageData: AmityImageData?
            if let avatar {
                imageData = try? await fileRepository.uploadImage(avatar, progress: nil)
            }
            
            if let imageData {
                amityUserUpdateBuilder.setAvatar(imageData)
            }
            
            do {
                try await AmityUIKitManagerInternal.shared.client.editUser(amityUserUpdateBuilder)
                completion(true)
            } catch let error {
                completion(false)
            }
        }
    }
}
