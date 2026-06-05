//
//  AmityVisitorUsageLimitObserver.swift
//  AmityUIKit4
//

import Foundation
import Combine
import AmitySDK

final class AmityVisitorUsageLimitObserver {

    static let shared = AmityVisitorUsageLimitObserver()

    private var cancellable: AnyCancellable?

    private init() {}

    func start() {
        cancellable?.cancel()
        cancellable = AmityUIKitManagerInternal.shared.client
            .visitorUsageLimitReachedPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                AmityUIKit4Manager.behaviour.globalBehavior?.handleVisitorUsageLimitReached()
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }
}
