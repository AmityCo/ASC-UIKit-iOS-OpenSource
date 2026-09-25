//
//  AmityUIKitNetworkCapture.swift
//  AmityUIKit4
//
//  Copyright © 2026 Amity. All rights reserved.
//

import Foundation
import AmitySDK

/// Capture seam for network traffic the UIKit issues itself, which the SDK never sees.
///
/// Today that means image loads through the vendored Kingfisher client. The seam is inert
/// until ``start(_:)`` is called, and only a debug host calls it — nothing in a released
/// integration installs a delegate or allocates a record.
///
/// - Note: HLS media segments are deliberately not captured. AVFoundation performs its own
///   networking for HLS; the only interception point is `AVAssetResourceLoader` with a custom
///   URL scheme, which would mean reimplementing segment delivery.
public final class AmityUIKitNetworkCapture {

    public static let shared = AmityUIKitNetworkCapture()

    private let lock = NSLock()
    private var sink: ((AmityNetworkActivity) -> Void)?
    private let imageDelegate = ImageCaptureDelegate()

    private init() {}

    /// `true` once a consumer has attached. Seams check this before doing any work.
    public var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return sink != nil
    }

    /// Attaches a consumer and installs the capture seams.
    public func start(_ sink: @escaping (AmityNetworkActivity) -> Void) {
        lock.lock()
        self.sink = sink
        lock.unlock()

        imageDelegate.owner = self
        KingfisherManager.shared.downloader.delegate = imageDelegate
    }

    /// Detaches the consumer and removes the seams.
    public func stop() {
        lock.lock()
        sink = nil
        lock.unlock()

        if KingfisherManager.shared.downloader.delegate === imageDelegate {
            KingfisherManager.shared.downloader.delegate = nil
        }
    }

    fileprivate func emit(_ build: () -> AmityNetworkActivity?) {
        lock.lock()
        let sink = self.sink
        lock.unlock()

        guard let sink, let activity = build() else { return }
        sink(activity)
    }
}

/// Bridges Kingfisher's downloader callbacks into `AmityNetworkActivity` records.
///
/// A started download emits an in-flight record (`endedAt == nil`); the completion emits a
/// record with the **same id**, which a consumer uses to replace the pending row in place.
private final class ImageCaptureDelegate: ImageDownloaderDelegate {

    weak var owner: AmityUIKitNetworkCapture?

    private let lock = NSLock()
    private var inFlight: [URL: (id: String, startedAt: Date)] = [:]

    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?) {
        guard let owner, owner.isActive else { return }

        let identifier = UUID().uuidString
        let startedAt = Date()
        lock.lock()
        inFlight[url] = (identifier, startedAt)
        lock.unlock()

        owner.emit {
            AmityNetworkActivity(
                id: identifier,
                type: .image,
                startedAt: startedAt,
                endedAt: nil,
                request: Self.makeRequest(url: url, request: request)
            )
        }
    }

    func imageDownloader(
        _ downloader: ImageDownloader,
        didFinishDownloadingImageForURL url: URL,
        with response: URLResponse?,
        error: Error?
    ) {
        guard let owner, owner.isActive else { return }

        lock.lock()
        let pending = inFlight.removeValue(forKey: url)
        lock.unlock()

        let identifier = pending?.id ?? UUID().uuidString
        let startedAt = pending?.startedAt ?? Date()
        let capturedRequest = Self.makeRequest(url: url, request: nil)

        owner.emit {
            guard let http = response as? HTTPURLResponse else {
                return AmityNetworkActivity(
                    id: identifier,
                    type: .image,
                    startedAt: startedAt,
                    endedAt: Date(),
                    request: capturedRequest,
                    error: error?.localizedDescription ?? "Image download failed with no response"
                )
            }

            let contentLength = http.expectedContentLength >= 0 ? http.expectedContentLength : nil
            return AmityNetworkActivity(
                id: identifier,
                type: .image,
                startedAt: startedAt,
                endedAt: Date(),
                request: capturedRequest,
                response: AmityNetworkResponse(
                    statusCode: http.statusCode,
                    message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode),
                    headers: Self.normalised(http.allHeaderFields),
                    // Image bytes are deliberately not retained — a feed scroll would pin
                    // megabytes in the consumer's buffer for no diagnostic gain.
                    body: nil,
                    bodyOmissionReason: .captureInactive,
                    contentLength: contentLength
                )
            )
        }
    }

    private static func makeRequest(url: URL, request: URLRequest?) -> AmityNetworkRequest {
        AmityNetworkRequest(
            method: request?.httpMethod ?? "GET",
            url: url.absoluteString,
            headers: (request?.allHTTPHeaderFields ?? [:]).reduce(into: [String: [String]]()) { result, pair in
                result[pair.key, default: []].append(pair.value)
            },
            body: nil,
            bodyOmissionReason: .empty
        )
    }

    private static func normalised(_ headers: [AnyHashable: Any]) -> [String: [String]] {
        headers.reduce(into: [String: [String]]()) { result, pair in
            guard let key = pair.key as? String else { return }
            result[key, default: []].append(String(describing: pair.value))
        }
    }
}
