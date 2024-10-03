//
//  Debouncer.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 9/20/24.
//

class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Trigger the action after some delay
    public func run(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    public func cancel() {
        workItem?.cancel()
    }
}
