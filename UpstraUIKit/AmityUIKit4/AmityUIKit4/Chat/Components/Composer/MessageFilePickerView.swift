//
//  MessageFilePickerView.swift
//  AmityUIKit4
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MessageFilePickerView: UIViewControllerRepresentable {
    /// Called once with a local file URL, or `nil` if the user cancelled.
    let onSelected: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType]
        if #available(iOS 14.0, *) {
            types = [UTType.item]
        } else {
            types = []
        }
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        }
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSelected: onSelected) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelected: (URL?) -> Void
        init(onSelected: @escaping (URL?) -> Void) { self.onSelected = onSelected }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let source = urls.first else {
                onSelected(nil)
                return
            }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "_" + source.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: source, to: tempURL)
                onSelected(tempURL)
            } catch {
                onSelected(nil)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onSelected(nil)
        }
    }
}
