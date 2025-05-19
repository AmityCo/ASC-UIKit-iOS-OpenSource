//
//  StreamManager.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/3/25.
//

import SwiftUI
import AmitySDK

class StreamManager {
    
    private let streamRepository = AmityStreamRepository(client: AmityUIKitManagerInternal.shared.client)
    
    func createStream(title: String, description: String?, thumbnail: AmityImageData?, metadata: [String: Any]?) async throws -> AmityStream {
        try await streamRepository.createStream(title: title, description: description ?? "", thumbnailImage: thumbnail, metadata: metadata, resolution: .SD)
    }
    
    func getStream(id: String) -> AmityObject<AmityStream> {
        return streamRepository.getStream(id)
    }
}
