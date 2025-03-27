//
//  AmityLivestreamBehavior.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 22/10/2567 BE.
//

import AmitySDK
import SwiftUI

open class AmityLivestreamBehavior {
    
    public init() {}
    
    open func createRecordedPlayer(stream: AmityStream, client: AmityClient) -> any View {
        return RecordedStreamPlayerView(livestream: stream, client: client)
    }
    
    open func createLivestreamPlayer(stream: AmityStream, client: AmityClient, isPlaying: Bool) -> any View {
        return LivestreamPlayerView(stream: stream, client: client, isPlaying: isPlaying)
    }
    
}
