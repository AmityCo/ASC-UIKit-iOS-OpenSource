//
//  StoryCoreView.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 12/8/23.
//

import SwiftUI
import AVKit
import AmitySDK
import Combine

struct StoryCoreView: View {
    
    var targetName: String
    var avatar: UIImage
    var isVerified: Bool
    
    @EnvironmentObject var host: SwiftUIHostWrapper
    @EnvironmentObject var storyCollection: AmityCollection<AmityStory>
    @ObservedObject var storyCoreViewModel: StoryCoreViewModel
    
    @Binding var storySegmentIndex: Int
    @Binding var totalDuration: CGFloat
    @State private var tabIndex: Int = 0
    
    // TEMP: Need to implement async/await func later and check to get the correct result
    @State private var hasStoryManagePermission: Bool = StoryPermissionChecker.shared.checkUserHasManagePermission()
    
    var nextStorySegment: (() -> Void)?
    var previousStorySegment: (() -> Void)?
    
    init(storyCoreViewModel: StoryCoreViewModel, storySegmentIndex: Binding<Int>, totalDuration: Binding<CGFloat>, targetName: String, avatar: UIImage, isVerified: Bool, nextStorySegment: (() -> Void)? = nil, previousStorySegment: (() -> Void)? = nil) {
        self._storySegmentIndex = storySegmentIndex
        self._totalDuration = totalDuration
        self.targetName = targetName
        self.avatar = avatar
        self.isVerified = isVerified
        self.storyCoreViewModel = storyCoreViewModel
        self.nextStorySegment = nextStorySegment
        self.previousStorySegment = previousStorySegment
    }
    
    var body: some View {
        TabView(selection: $tabIndex) {
            ForEach(Array(storyCollection.snapshots.enumerated()), id: \.element.storyId) { index, amityStory in
               let storyModel = Story(story: amityStory)
                
                VStack(spacing: 0) {
                    ZStack {
                        GeometryReader { geometry in
                               if let imageURL = storyModel.imageURL {
                                ImageView(imageURL: imageURL, totalDuration: $totalDuration)
                                       .frame(width: geometry.size.width, height: geometry.size.height)
                            } else if let videoURLStr = storyModel.videoURLStr,
                                      let videoURL = URL(string: videoURLStr) {
                                VideoView(videoURL: videoURL, totalDuration: $totalDuration)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            getMetadataView(targetName: targetName,
                                            avatar: avatar,
                                            isVerified: isVerified,
                                            story: storyModel)
                            Spacer()
                        }
                        .offset(y: 30) // height + padding top, bottom of progressBarView
                        
                        getGestureView()
                            .offset(y: 80) // not to overlap gesture from metadata view
                    }
                    
                    getAnalyticView()
                }
                .onAppear {
                    // Last story already appeared on screen
                    Log.add(event: .info, "Story index: \(index) total: \(storyCollection.snapshots.count)")
                    if index == storyCollection.snapshots.count - 1 {
                        Log.add(event: .info, "Last Story is seen")
                        amityStory.analytics.markAsSeen()
                    }
                }
                .tag(index)
            }
            .onChange(of: storySegmentIndex) { index in
                tabIndex = index
            }
            .gesture(DragGesture().onChanged{ _ in})
            .animation(nil)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    

    func getMetadataView(targetName: String, avatar: UIImage, isVerified: Bool, story: Story) -> some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .padding(.leading, 20)
                
                if hasStoryManagePermission {
                    AmityCreateNewStoryButtonElement(componentId: .storyTabComponentId)
                        .frame(width: 16.0, height: 16.0)
                }
            }
            .onTapGesture {
                if hasStoryManagePermission {
                    goToStoryCreationPage(targetId: story.targetId, avatar: avatar)
                }
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(targetName)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(height: 20)
                        .foregroundColor(.white)
                        .onTapGesture {
                            host.controller?.dismiss(animated: true)
                        }
                    
                    if isVerified {
                        Image(AmityIcon.verifiedWhiteBadge.getImageResource())
                            .resizable()
                            .frame(width: 20, height: 20)
                            .offset(x: -5)
                    }
                }
                HStack {
                    Text(timeAgoString(from: story.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("By \(story.creatorName)")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                
            }
            
            Spacer()
        }
    }
    
    
    func getGestureView() -> some View {
        HStack(alignment: .center, spacing: 0) {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            //
                        })
                        .onEnded({ value in
                            //
                        })
                )
                .onTapGesture {
                    previousStorySegment?()
                }
        
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            //
                        })
                        .onEnded({ value in
                            //
                        })
                )
                .onTapGesture {
                    nextStorySegment?()
                }
    
        }
    }
    
    
    func getAnalyticView() -> some View {
        HStack(spacing: 10) {
            Label {
                Text("0")
                    .font(.system(size: 15))
            } icon: {
                Image(AmityIcon.eyeIcon.getImageResource())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 16)
                    .padding(.trailing, -4)
            }
            .foregroundColor(.white)
            
            Spacer()
    
            ZStack {
                Capsule()
                    .fill(Color(UIColor(hex: "#292B32")))
                    .frame(width: 56, height: 40)
                Label {
                    Text("0")
                        .font(.system(size: 15))
                        
                } icon: {
                    Image(AmityIcon.storyCommentIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 16)
                        .padding(.trailing, -4)
                }
                .foregroundColor(.white)
            }
            .gesture(DragGesture().onChanged{ _ in})
            .onTapGesture {
                Log.add(event: .info, "Comment Tapped")
            }
            
            ZStack {
                Capsule()
                    .fill(Color(UIColor(hex: "#292B32")))
                    .frame(width: 56, height: 40)
                Label {
                    Text("0")
                        .font(.system(size: 15))
                        
                } icon: {
                    Image(AmityIcon.storyLikeIcon.getImageResource())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 16)
                        .padding(.trailing, -4)
                }
                .foregroundColor(.white)
            }
            .gesture(DragGesture().onChanged{ _ in})
            .onTapGesture {
                Log.add(event: .info, "Like Tapped")
            }
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 5, trailing: 12))
        .frame(height: 50)
        .background(Color.black)
    }
    
    
    private func timeAgoString(from date: Date) -> String {
        let currentDate = Date()
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: date, to: currentDate)

        if let hour = components.hour, hour > 0 {
            return "\(hour) h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) m"
        } else {
            return "Just now"
        }
    }
    
    private func goToStoryCreationPage(targetId: String, avatar: UIImage?) {
        let cameraPage = AmityCameraPage(targetId: targetId, avatar: avatar)
        let controller = SwiftUIHostingController(rootView: cameraPage)
        
        host.controller?.navigationController?.setViewControllers([controller], animated: false)
    }
}

// TEMP: temporary solution for Caching
class StoryCoreViewModel: ObservableObject {
    
    var disposeBag: Set<AnyCancellable> = []
    
    init(storyCollection: AmityCollection<AmityStory>) {
        storyCollection.$snapshots
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { stories in
                var urls: [URL] = []
                
                for story in stories {
                    if let urlStr = story.getVideoInfo()?.getVideo(resolution: .res_720p),
                       let url = URL(string: urlStr) {
                        urls.append(url)
                    }
                    
                }
                
                VideoPlayer.preload(urls: urls)
            }.store(in: &disposeBag)
    }
}

struct ImageView: View {
    
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    
    let imageURL: URL
    @Binding var totalDuration: CGFloat
    
    init(imageURL: URL, totalDuration: Binding<CGFloat>) {
        self.imageURL = imageURL
        self._totalDuration = totalDuration
    }
    
    var body: some View {
        URLImage(imageURL) { progress in
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                .onAppear {
                    storyPageViewModel.shouldRunTimer = false
                }
                .onDisappear {
                    storyPageViewModel.shouldRunTimer = true
                }
                
        } content: { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .onAppear {
            totalDuration = 4.0
            Log.add(event: .info, "TotalDuration: \(totalDuration)")
        }
    }
}

struct VideoView: View {
    
    @EnvironmentObject var storyPageViewModel: AmityStoryPageViewModel
    
    private let videoURL: URL
    @Binding var totalDuration: CGFloat
    
    @State private var playVideo: Bool = false
    @State private var showActivityIndicator: Bool = false
    @State private var time: CMTime = .zero
    
    init(videoURL: URL, totalDuration: Binding<CGFloat>) {
        self.videoURL = videoURL
        self._totalDuration = totalDuration
    }
    
    var body: some View {
        VideoPlayer(url: videoURL, play: $playVideo, time: $time)
            .autoReplay(false)
            .contentMode(.scaleToFill)
            .onStateChanged({ state in
                switch state {
                case .loading:
                    storyPageViewModel.shouldRunTimer = false
                    showActivityIndicator = true
                case .playing(totalDuration: let totalDuration):
                    storyPageViewModel.shouldRunTimer = true
                    self.totalDuration = totalDuration
                    showActivityIndicator = false
                case .paused(playProgress: _, bufferProgress: _): break
                case .error(_): break

                }
            })
            .overlay(
                ActivityIndicatorView(isAnimating: $showActivityIndicator, style: .medium)
            )
            .onAppear {
                time = .zero
                playVideo = true
            }
            .onDisappear {
                playVideo = false
            }
    }
}
