//
//  AmityHyperLinkConfigComponent.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/23/24.
//

import SwiftUI
import Combine

public struct HyperLinkModel {
    public var url: String
    public var urlName: String
    
    public func getDomainName() -> String? {
        return URLHelper.concatProtocolIfNeeded(urlStr: url)?.host
    }
    
    public func getCustomName() -> String {
        return urlName
    }
}

public struct AmityHyperLinkConfigComponent: AmityComponentView {
    public var pageId: PageId?
    
    public var id: ComponentId {
        .hyperLinkConfigComponent
    }
    
    @Binding private var isPresented: Bool
    @Binding private var data: HyperLinkModel
    @StateObject private var viewModel = AmityHyperLinkConfigComponentViewModel()
    @State private var isRemoveLinkAlertShown: Bool = false
    @State private var isUnsavedAlertShown: Bool = false
    
    public init(isPresented: Binding<Bool>, data: Binding<HyperLinkModel>) {
        self._isPresented = isPresented
        self._data = data
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(hex: "#EBECEF")))
                let urlModel = InfoTextFieldModel(title: "URL", placeholder: "https://example.com", isMandatory: true, errorMessage: "Please enter a valid URL.")
                
                InfoTextField(data: urlModel, text: $viewModel.urlText, isValid: $viewModel.urlIsValid)
                
                let linkNameModel = InfoTextFieldModel(title: "Customize link text", placeholder: "Name your link", isMandatory: false, infoMessage: "This text will show on the link instead of URL.", errorMessage: "", maxCharCount: 30)
                InfoTextField(data: linkNameModel, text: $viewModel.urlNameText, isValid: $viewModel.urlNameIsValid)
                
                if !data.url.isEmpty {
                    getRemoveLinkButton()
                }
                Spacer()
            }
            .navigationTitle("Add link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isUnsavedAlertShown.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.black)
                    .alert(isPresented: $isUnsavedAlertShown) {
                        Alert(title: Text("Unsaved changes"),
                              message: Text("Are you sure you want to cancel? Your changes won't be saved."),
                              primaryButton: .default(Text("No")
                                .foregroundColor(.accentColor)),
                              secondaryButton: .default(Text("Yes")
                                .foregroundColor(.accentColor), action: {
                            isPresented.toggle()
                        }))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        data.url = viewModel.urlText
                        data.urlName = viewModel.urlNameText
                        isPresented.toggle()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isDoneButtonDisabled)
                }
            }
            .onChange(of: isPresented) { value in
                hideKeyboard()
                // Update the data as soon as this view is presented.
                if value {
                    viewModel.urlText = data.url
                    viewModel.urlNameText = data.urlName
                }
            }
        }
    }
    
    func getRemoveLinkButton() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Image(AmityIcon.trashBinRedIcon.getImageResource())
                    .frame(width: 20, height: 20)
                    .padding(.trailing, 6)
                Text("Remove link")
                    .font(.system(size: 15))
                    .foregroundColor(.red)
                Spacer()
            }
            .onTapGesture {
                isRemoveLinkAlertShown.toggle()
            }
            .alert(isPresented: $isRemoveLinkAlertShown) {
                Alert(title: Text("Remove link?"),
                      message: Text("This link will be removed from story."),
                      primaryButton: .cancel(),
                      secondaryButton: .destructive(Text("Remove"), action: {
                    data.url = ""
                    data.urlName = ""
                    isPresented.toggle()
                }))
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor(hex: "#EBECEF")))
        }
        .padding(EdgeInsets(top: 40, leading: 16, bottom: 0, trailing: 16))
        
        
    }
}

public class AmityHyperLinkConfigComponentViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published var urlIsValid: Bool = true
    @Published var urlNameText: String = ""
    @Published var urlNameIsValid: Bool = true
    @Published var isDoneButtonDisabled: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []

    init() {
        Publishers.CombineLatest3($urlText, $urlIsValid, $urlNameIsValid)
            .map { urlText, urlIsValid, urlNameIsValid in
                let value = urlIsValid && urlNameIsValid && !urlText.isEmpty
                return !value
            }
            .assign(to: \.isDoneButtonDisabled, on: self)
            .store(in: &cancellables)
    }
        
}


fileprivate struct Preview: View {
    @State var isPresented: Bool = false
    @State var data = HyperLinkModel(url: "www.youtube.com", urlName: "")
    
    var body: some View {
        AmityHyperLinkConfigComponent(isPresented: $isPresented, data: $data)
    }
    
}

#if DEBUG
#Preview {
    Preview()
}
#endif
