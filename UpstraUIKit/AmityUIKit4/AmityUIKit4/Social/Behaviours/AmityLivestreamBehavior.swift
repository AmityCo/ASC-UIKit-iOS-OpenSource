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
        print("To present recorded stream, please override \(AmityLivestreamBehavior.self).\(#function), see https://docs.amity.co for more details.")
        return EmptyView()
    }
    
    open func createLivestreamPlayer(stream: AmityStream, client: AmityClient, isPlaying: Bool) -> any View {
        print("To present live stream, please override \(AmityLivestreamBehavior.self).\(#function), see https://docs.amity.co for more details.")
        return EmptyView()
    }
    
}
