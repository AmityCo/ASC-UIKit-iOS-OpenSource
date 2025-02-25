//
//  LiveChatListView.swift
//  SampleApp
//
//  Created by Nishan on 3/4/2567 BE.
//  Copyright © 2567 BE Eko. All rights reserved.
//

import SwiftUI
import AmitySDK
import AmityUIKit4
import Combine

struct TestChannelModel: Identifiable {

    let id: String
    let displayName: String
        
    init(channel: AmityChannel) {
        self.displayName = channel.displayName ?? "-"
        self.id = channel.channelId
    }
}

struct LiveChatListView: View {
    
    @StateObject var viewModel = TestLiveChatListViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.channels) { channel in
                NavigationLink(destination: TestLiveChatView(channelId: channel.id)) {
                    
                    HStack(spacing: 12) {
                        Image(systemName: "doc.plaintext.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Name: \(channel.displayName)")
                                .font(.headline)
                                .fontWeight(.regular)
                                .lineLimit(1)
                            
                            Text("Id: \(channel.id)")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Live Channels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.queryChannel()
        }
    }
}

#if DEBUG
#Preview {
    LiveChatListView()
}
#endif

class TestLiveChatListViewModel: ObservableObject {
    let channelRepo = AmityChannelRepository(client: AmityUIKit4Manager.client)

    @Published var channels = [TestChannelModel]()
    private var channelCollection: AmityCollection<AmityChannel>?
    
    var token: AmityNotificationToken?

    func queryChannel() {
        let query = AmityChannelQuery()
        query.types = [AmityChannelQueryType.live]
        query.filter = .userIsMember
        query.includeDeleted = false
        channelCollection = channelRepo.getChannels(with: query)
        
        token = channelCollection?.observe({ [weak self] collection, _, error in
            let channels = collection.snapshots
            if collection.dataStatus == .fresh {

                var channelModels = [TestChannelModel]()
                for channel in channels {
                    channelModels.append(TestChannelModel(channel: channel))
                }

                self?.channels = channelModels
                self?.token?.invalidate()
            }
        })
    }
    
}

public struct TestLiveChatView: View {
    
    let channelId: String
    
    @State var showChat: Bool = true
    @State var playVideo: Bool = true
    
    public var body: some View {
        GeometryReader { proxy in
            
            if #available(iOS 16.4, *) {
                
                VStack {
                    
                    VideoPlayer(url: URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!, play: $playVideo)
                        .autoReplay(true)
                        .mute(true)
                        .contentMode(.scaleAspectFit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                    Spacer()
                    
                    Button(action: {
                        showChat.toggle()
                    }, label: {
                        Text("Show Live Chat")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    })
                    .tint(Color.blue)
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 32)
                    .cornerRadius(8)
                    .sheet(isPresented: $showChat) {
                        Capsule()
                            .fill(.gray)
                            .frame(width: 35, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                        AmityLiveChatPage(channelId: channelId)
                            .presentationDetents([.height(proxy.size.height - 190), .large])
                            .presentationDragIndicator(.hidden)
                            .presentationBackgroundInteraction(.enabled)
                            .interactiveDismissDisabled(true)
                        
                    }
                }
            } else {
                VStack {
                    VideoPlayer(url: URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!, play: $playVideo)
                        .autoReplay(true)
                        .contentMode(.scaleAspectFit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                    Spacer()
                    
                    Button(action: {
                        showChat.toggle()
                    }, label: {
                        Text("Show Live Chat")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.white)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    })
                    .background(Color.blue)
                    .padding(.horizontal, 32)
                    .cornerRadius(8)
                    .sheet(isPresented: $showChat) {
                        Capsule()
                            .fill(.gray)
                            .frame(width: 35, height: 5)
                            .padding(10)
                        AmityLiveChatPage(channelId: channelId)
                    }
                }
            }
        }
    }
}
