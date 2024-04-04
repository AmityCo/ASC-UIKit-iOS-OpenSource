//
//  ReactionListPage.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 3/13/24.
//

import SwiftUI
import AmitySDK
import Combine

struct ReactionListPage: View {
    @State private var currentTab: Int = 0
    @State private var tabBarOptions: [String] = ["All"]
    
    @StateObject private var viewModel: ReactionListPageViewModel = ReactionListPageViewModel()
    
    private let referenceId: String
    private let referenceType: AmityReactionReferenceType
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    init(referenceId: String, referenceType: AmityReactionReferenceType) {
        self.referenceId = referenceId
        self.referenceType = referenceType
    }
    
    var body: some View {
        VStack {
            BottomSheetDragIndicator()
                .foregroundColor(Color(viewConfig.defaultLightTheme.baseColorShade3))
            
            ZStack(alignment: .bottom) {
                TabBarView(currentTab: self.$currentTab, tabBarOptions: $tabBarOptions)
                    .selectedTabColor(viewConfig.theme.primaryColor)
                    .frame(height: 30)
                    .zIndex(1)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(viewConfig.theme.baseColorShade4))
                    .offset(y: -1)
            }
            
            TabView(selection: self.$currentTab) {
                ScrollViewReader { scrollViewReader in
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(viewModel.reactedUsers.enumerated()), id: \.element.userId) { index, user in
                                Section {
                                    HStack {
                                        AsyncImage(placeholder: AmityIcon.defaultCommunityAvatar.getImageResource(), url: URL(string: user.avatarURL))
                                            .frame(width: 35, height: 35)
                                            .clipShape(Circle())
                                            .padding(.leading, 14)
                                            
                                        
                                        Text(user.displayName)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color(viewConfig.theme.baseColor))
                                        
                                        Spacer()
                                    }
                                    .frame(height: 40)
                                }
                                .onAppear {
                                    if index == viewModel.reactedUsers.count - 1 {
                                        viewModel.loadMore()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.all)
            
        }
        .background(Color(viewConfig.theme.backgroundColor).ignoresSafeArea())
        .onReceive(viewModel.$reactedUsers) { users in
            if users.count != 0 {
                tabBarOptions[currentTab] = "All \(users.count)"
            }
        }
        .onAppear {
            viewModel.getReactedUsers(.like, referenceId: referenceId, referenceType: referenceType)
        }
    }

}

class ReactionListPageViewModel: ObservableObject {
    @Published var reactedUsers: [ReactionUser] = []
    private var reactionCollection: AmityCollection<AmityReaction>?
    
    private let reactionManger = ReactionManager()
    private var cancellable: AnyCancellable?
    
    func getReactedUsers(_ reactionType: ReactionType, referenceId: String, referenceType: AmityReactionReferenceType) {
        reactionCollection = reactionManger.getReactions(reactionType, referenceId: referenceId, referenceType: referenceType)
        cancellable = nil
        cancellable = reactionCollection?.$snapshots
            .sink(receiveValue: { [weak self] reactions in
                Log.add(event: .info, "Reaction: \(reactions.count)")
                self?.reactedUsers = reactions.map { ReactionUser(reaction: $0) }
            })
    }
    
    func loadMore() {
        guard let collection = reactionCollection, collection.hasNext else { return }
        collection.nextPage()
    }
}


struct ReactionUser {
    let userId: String
    let displayName: String
    let avatarURL: String
    
    init(reaction: AmityReaction) {
        self.userId = reaction.creator?.userId ?? ""
        self.displayName = reaction.creator?.displayName ?? ""
        self.avatarURL = reaction.creator?.getAvatarInfo()?.fileURL ?? ""
    }
    
    init(userId: String, displayName: String, avatarURL: String) {
        self.userId = userId
        self.displayName = displayName
        self.avatarURL = ""
    }
}
