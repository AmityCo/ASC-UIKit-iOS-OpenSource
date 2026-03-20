//
//  AmityProductTagSelectionHeaderElement.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/14/26.
//

import SwiftUI

struct AmityProductTagSelectionHeaderElement: AmityElementView {

    var pageId: PageId?
    var componentId: ComponentId?

    var id: ElementId {
        return .productTagSelectionHeader
    }

    @EnvironmentObject var viewConfig: AmityViewConfigController

    let mode: AmityProductTagSelectionMode
    let selectedCount: Int
    let maxCount: Int
    let isDoneEnabled: Bool
    let onClose: () -> Void
    let onDone: () -> Void

    var body: some View {
        AmityView(configId: configId,
                  config: { configDict -> (createModeTitle: String, editModeTitle: String, livestreamModeTitle: String, doneButtonText: String) in
            let createModeTitle = configDict["create_mode_title"] as? String ?? "Tag products"
            let editModeTitle = configDict["edit_mode_title"] as? String ?? "Edit tags"
            let livestreamModeTitle = configDict["livestream_mode_title"] as? String ?? "Add products"
            let doneButtonText = configDict["done_button_text"] as? String ?? "Done"
            return (createModeTitle, editModeTitle, livestreamModeTitle, doneButtonText)
        }) { config in
            if mode == .livestream {
                // Livestream mode: centered title with X button on right
                HStack {
                    Spacer()
                        .frame(width: 24)

                    Spacer()

                    VStack(spacing: 4) {
                        Text(titleForMode(mode: mode, config: config))
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

                        Text("\(selectedCount)/\(maxCount)")
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    }

                    Spacer()

                    Button(action: onClose) {
                        Image(AmityIcon.closeIcon.imageResource)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                .background(Color(viewConfig.theme.backgroundColor))
            } else {
                // Create/Edit mode: close button on left, title centered, done button on right
                HStack {
                    Button(action: onClose) {
                        Image(AmityIcon.closeIcon.imageResource)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(viewConfig.theme.baseColor))
                    }
                    .padding(.leading, 16)

                    Spacer()

                    VStack(spacing: 4) {
                        Text(titleForMode(mode: mode, config: config))
                            .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))

                        Text("\(selectedCount)/\(maxCount)")
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade2)))
                    }

                    Spacer()

                    Button(action: {
                        if isDoneEnabled {
                            onDone()
                        }
                    }) {
                        Text(config.doneButtonText)
                            .applyTextStyle(.body(Color(isDoneEnabled ? viewConfig.theme.primaryColor : viewConfig.theme.primaryColor.blend(.shade2))))
                    }
                    .disabled(!isDoneEnabled)
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                .background(Color(viewConfig.theme.backgroundColor))
            }
        }
    }
    
    private func titleForMode(mode: AmityProductTagSelectionMode, config: (createModeTitle: String, editModeTitle: String, livestreamModeTitle: String, doneButtonText: String)) -> String {
        switch mode {
        case .create:
            return config.createModeTitle
        case .edit:
            return config.editModeTitle
        case .livestream:
            return config.livestreamModeTitle
        }
    }
}
