//
//  AmityEventLocationView.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 14/10/25.
//

import SwiftUI
import AmitySDK

struct AmityEventLocationView: View {
    
    @EnvironmentObject var viewConfig: AmityViewConfigController
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showEventTypeSheet = false
    @State private var externalLink: String = ""
    
    @State private var addressTextFieldModel: InfoTextFieldModel = InfoTextFieldModel(
        title: "Address", placeholder: "Enter address of where this event will be happening", isMandatory: false,
        isExpandable: true, maxCharCount: 180)
    @State private var address = ""
    @State private var isAddressValid: Bool = true
    
    let selection: EventLocation?
    let onSaveAction: (EventLocation) -> Void
    
    @State private var draft: EventLocation
    @State private var isInputValid: Bool = false
    
    init(selection: EventLocation?, onSaveAction: @escaping (EventLocation) -> Void) {
        self.selection = selection
        self.onSaveAction = onSaveAction
        self.draft = selection ?? EventLocation()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                Spacer()
            }
            
            AmityNavigationBar(title: "Location", showDivider: true) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                }.padding(.leading, 8)
            } trailing: {
                Button {
                    let input = EventLocation(type: draft.type, platform: draft.platform, address: address, externalPlatformUrl: externalLink)
                    
                    guard input.isValid() else {
                        Log.warn("Event location input not valid")
                        return
                    }
                    
                    onSaveAction(input)
                    
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Done")
                        .applyTextStyle(.body(Color(isInputValid ? viewConfig.theme.primaryColor : viewConfig.theme.primaryColor.blend(.shade2))))
                }
                .disabled(!isInputValid)
                .padding(.trailing, 8)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Event Type")
                    .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                
                Button(action: {
                    showEventTypeSheet.toggle()
                }, label: {
                    VStack(spacing: 16) {
                        HStack {
                            Text(draft.type.title)
                                .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        
                        Divider()
                    }
                })
                
                if draft.type == .virtual {
                    // Platform
                    Text("Platform")
                        .applyTextStyle(.titleBold(Color(viewConfig.theme.baseColor)))
                        .padding(.top, 8)
                    
                    EventPlatformRadioButtonView(isSelected: draft.platform == .livestream, icon: AmityIcon.createLivestreamMenuIcon.imageResource, title: EventPlatform.livestream.rawValue, description: "Users can join the live stream on the app or website.")
                        .onTapGesture {
                            draft.platform = .livestream
                            
                            validateLocationInputs()
                        }
                    
                    EventPlatformRadioButtonView(isSelected: draft.platform == .external, icon: AmityIcon.externalPlatformIcon.imageResource, title: EventPlatform.external.rawValue, description: "Users will join the event on an external platform.")
                        .onTapGesture {
                            draft.platform = .external
                            
                            validateLocationInputs()
                        }
                        .padding(.top, 16)
                    
                    VStack(alignment: .trailing) {
                        TextField("Event link", text: $externalLink)
                            .applyTextStyle(.body(Color(viewConfig.theme.baseColor)))
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(Color(viewConfig.theme.baseColorShade4))
                            .cornerRadius(8, corners: .allCorners)
                            .padding(.leading, 40 + 12)
                            .onChange(of: externalLink) { newValue in
                                if newValue.last == " " {
                                    externalLink = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                
                                if newValue.count > 200 {
                                    ImpactFeedbackGenerator.impactFeedback(style: .light)
                                    
                                    externalLink = String(newValue.prefix(200))
                                }
                                
                                validateLocationInputs()
                            }
                        
                        Text("\(externalLink.count)/200")
                            .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
                    }
                    .visibleWhen(draft.platform == .external)
                    .disabled(draft.platform == .livestream)
                } else {
                    // Event Name
                    InfoTextField(
                        data: $addressTextFieldModel, text: $address,
                        isValid: $isAddressValid,
                        titleTextAccessibilityId: AccessibilityID.Social.CommunitySetup
                            .communityNameTitle
                    )
                    .alertColor(viewConfig.theme.alertColor)
                    .dividerColor(viewConfig.theme.baseColorShade4)
                    .infoTextColor(viewConfig.theme.baseColorShade2)
                    .textFieldTextColor(viewConfig.theme.baseColor)
                    .padding(.top, 8)
                    .onChange(of: address) { newValue in
                        validateLocationInputs()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .bottomSheet(isShowing: $showEventTypeSheet, height: .contentSize) {
            VStack(spacing: 0) {
                BottomSheetItemView(icon: nil, text: AmityEventType.inPerson.title)
                    .onTapGesture {
                        showEventTypeSheet.toggle()
                        
                        draft.type = .inPerson
                        
                        validateLocationInputs()
                    }
                
                BottomSheetItemView(icon: nil, text: AmityEventType.virtual.title)
                    .onTapGesture {
                        showEventTypeSheet.toggle()
                        
                        draft.type = .virtual
                        
                        validateLocationInputs()
                    }
            }
            .padding(.bottom, 64)
        }
        .onAppear {
            externalLink = draft.externalPlatformUrl
            address = draft.address
            
            validateLocationInputs()
        }
    }
    
    func validateLocationInputs() {
        let isAddressValid = !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isEventLinkValid = !externalLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if draft.type == .inPerson {
            isInputValid = isAddressValid
        } else {
            isInputValid = draft.platform == .livestream ? true : isEventLinkValid
        }
    }
}


struct EventPlatformRadioButtonView: View {
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    private let isSelected: Bool
    private let icon: ImageResource
    private let title: String
    private let description: String
    
    init(isSelected: Bool, icon: ImageResource, title: String, description: String) {
        self.isSelected = isSelected
        self.icon = icon
        self.title = title
        self.description = description
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            Rectangle()
                .fill(Color(viewConfig.theme.baseColorShade4))
                .clipShape(Circle())
                .overlay (
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color(viewConfig.theme.baseColor))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height:  20)
                )
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .applyTextStyle(.bodyBold(Color(viewConfig.theme.baseColor)))
                
                Text(description)
                    .applyTextStyle(.caption(Color(viewConfig.theme.baseColorShade1)))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 1)
                    .fill(.gray)
                    .frame(width: 20, height: 20)
                    .opacity(isSelected ? 0 : 1)
                
                Image(AmityIcon.pollRadioIcon.imageResource)
                    .frame(width: 22, height: 22)
                    .opacity(isSelected ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
    }
}
