//
//  ApiTrace.swift
//  SampleApp
//
//  Records every server call the SDK makes, so "this module is switched off" can
//  be checked against the wire and not only against the screen.
//
//  ponytail: temporary diagnostic. One file per launch, appended, no rotation and
//  no upload — read it out of the simulator's container. Delete this file and its
//  one call site in AppManager when the module-flag audit is done.
//

import Combine
import Foundation
import AmitySDK
import AmityUIKit4

enum ApiTrace {

    private static let fileName = "amity-api-trace.jsonl"
    private static let queue = DispatchQueue(label: "co.amity.sample.apitrace")
    private static var fileURL: URL?
    private static var started = false
    private static var cancellable: AnyCancellable?

    /// Appends rather than truncates. A process that dies mid-run would otherwise
    /// take the whole trace with it, and the evidence would look like a clean run
    /// rather than a lost one. The harness deletes the file before launching; a
    /// second header inside one file means the app restarted, which is worth
    /// seeing.
    static func start(modulesOff: [String]) {
        guard !started else { return }
        started = true

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent(fileName)
        NSLog("[ApiTrace] writing to \(fileURL?.path ?? "?")")

        // The first line names the modules that were off for the run. Without it an
        // empty file cannot be told apart from a run where the tracer never started.
        write("{\"ts\":\"\(now())\",\"kind\":\"run\",\"modulesOff\":\(jsonArray(modulesOff.sorted()))}")

        // Re-register on every session state change. The observer registered once
        // after setup caught the login POST and then went silent: establishing a
        // session replaces the SDK's network layer and the observer with it. This
        // was found by measurement — the first trace had exactly one record, the
        // 403 from the login attempt, and nothing after the login that succeeded.
        cancellable = AmityUIKit4Manager.client.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { _ in observe() }
        observe()
    }

    private static func observe() {
        AmityUIKit4Manager.client.observeNetworkActivities { request, response, _ in
            guard let request, let url = request.url else { return }
            // The path names the endpoint and the query names the caller: every
            // post-listing endpoint takes dataTypes[], and only the clip feed asks
            // for clips. Android needed both to tell two callers of one endpoint
            // apart, and this SDK hands over the whole URLRequest, so record it.
            let method = request.httpMethod ?? "?"
            let path = url.path
            let query = url.query ?? ""
            // No response means the request left and never came back — a timeout,
            // a refused connection, a TLS error. Recorded as failed rather than as
            // status 0, because "the app sent nothing" and "the app sent something
            // that failed" are different answers and only one of them is clean.
            let failed = response == nil
            write("{\"ts\":\"\(now())\",\"kind\":\"http\""
                  + ",\"api\":\"?\""
                  + ",\"method\":\"\(esc(method))\""
                  + ",\"path\":\"\(esc(path))\""
                  + ",\"query\":\"\(esc(query))\""
                  + (failed ? ",\"failed\":true" : "")
                  + ",\"code\":\(response?.statusCode ?? 0)}")
        }
    }

    private static func write(_ line: String) {
        queue.async {
            guard let url = fileURL, let data = (line + "\n").data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: url)
            }
        }
    }

    private static let stamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func now() -> String { stamp.string(from: Date()) }

    private static func esc(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func jsonArray(_ values: [String]) -> String {
        "[" + values.map { "\"\(esc($0))\"" }.joined(separator: ",") + "]"
    }
}
