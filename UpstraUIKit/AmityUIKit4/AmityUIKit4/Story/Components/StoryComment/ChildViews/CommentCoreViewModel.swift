//
//  CommentCoreViewModel.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 4/4/25.
//
import SwiftUI
import AmitySDK
import Combine

class CommentCoreViewModel: ObservableObject {
    @Published var editingComment: AmityCommentModel?
    @Published var commentItems: [PaginatedItem<AmityCommentModel>] = []
    @Published var adSeetState: (isShown: Bool, ad: AmityAd?) = (false, nil)
    @Published var loadingStatus: AmityLoadingStatus = .notLoading
    @Published var hasScrolledToTop: Bool = true
    
    var loadedItems: [PaginatedItem<AmityComment>] = []
    
    private var commentCollection: AmityCollection<AmityComment>
    private let commentManager = CommentManager()
    var paginator: UIKitPaginator<AmityComment>
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let hideEmptyText: Bool
    @Published var hideCommentButtons: Bool
    
    private var paginatorCancellable: AnyCancellable?
    
    // We use this target when navigating from notification tray page.
    let targetCommentId: String?
    let targetCommentParentId: String?
    
    var targetCommentReply: PaginatedItem<AmityCommentModel>?
    var targetComment: PaginatedItem<AmityCommentModel>?
    
    let targetCommentFetcher = TargetCommentFetcher()
    var isTargetCommentFetched = false
    let preloadRepliesOfComment: Bool
    
    private let postManager = PostManager()
    private let storyManager = StoryManager()
    var post: AmityPostModel?
    var story: AmityStoryModel?
    
    var targetMembershipStatus: PostTargetMembershipStatus = .unknown
    
    init(referenceId: String,
         referenceType: AmityCommentReferenceType,
         hideEmptyText: Bool,
         hideCommentButtons: Bool,
         communityId: String? = nil,
         targetCommentId: String? = nil,
         targetCommentParentId: String? = nil,
         preloadRepliesOfComment: Bool = false
    ) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.hideEmptyText = hideEmptyText
        self.hideCommentButtons = hideCommentButtons
        self.targetCommentId = targetCommentId
        self.targetCommentParentId = targetCommentParentId
        self.preloadRepliesOfComment = preloadRepliesOfComment
        
        // Fetch target post
        if referenceType == .post {
            if let localPost = postManager.getPost(withId: referenceId).snapshot {
                self.post = AmityPostModel(post: localPost)
                self.targetMembershipStatus = PostTargetMembershipStatus.determineStatus(isJoined: post?.targetCommunity?.isJoined)
            }
        } else if referenceType == .story {
            if let localStory = storyManager.getStory(withId: referenceId).snapshot {
                self.story = AmityStoryModel(story: localStory)
                self.targetMembershipStatus = PostTargetMembershipStatus.determineStatus(isJoined: story?.community?.isJoined)
            }
        }
        
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        let collection = commentManager.getComments(queryOptions: queryOptions)
        commentCollection = collection
        let idToExclude = targetCommentParentId ?? targetCommentId
        paginator = UIKitPaginator(liveCollection: collection, adPlacement: .comment, communityId: communityId, excludedId: idToExclude, modelIdentifier: { model in
            return model.commentId
        })
        paginator.load()
        
        paginatorCancellable = paginator.$snapshots.sink { [weak self] items in
            guard let self else { return }
            
            self.loadingStatus = self.commentCollection.loadingStatus
            self.loadedItems = items
            
            // If there is no target, we render feed immediately
            if targetCommentId == nil {
                self.renderCommentFeed()
            } else if self.isTargetCommentFetched {
                self.renderCommentFeed()
            }
        }
        
        if let targetCommentId {
            
            // If there is target comment, we fetch those comment first
            self.targetCommentFetcher.fetchTargetComment(id: targetCommentId) { parent, reply in
                self.isTargetCommentFetched = true
                                
                if let parent {
                    let parentComment = PaginatedItem(id: parent.commentId, type: .content(AmityCommentModel(comment: parent)))
                    self.targetComment = parentComment
                }
                
                if let reply {
                    let replyComment = PaginatedItem(id: reply.commentId, type: .content(AmityCommentModel(comment: reply)))
                    self.targetCommentReply = replyComment
                }
                
                self.renderCommentFeed()
            }
        }
    }
    
    func renderCommentFeed() {
        var items = [PaginatedItem<AmityCommentModel>]()
        
        // Add target parent comment to the top
        // We handle targetReply in ReplyCommentView
        if let targetComment {
            items.insert(targetComment, at: 0)
        }
        
        // Add remaining comment
        let mappedLoadedItems = loadedItems.map {
            switch $0.type {
            case .content(let comment):
                return PaginatedItem(id: $0.id, type: .content(AmityCommentModel(comment: comment)))
            case .ad(let ad):
                return PaginatedItem(id: $0.id, type: .ad(ad))
            }
        }
        items.append(contentsOf: mappedLoadedItems)
        
        // Finally render the comment list
        self.commentItems = items
    }
    
    func getChildComments(parentId: String) -> AmityCollection<AmityComment> {
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    parentId: parentId,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        return commentManager.getComments(queryOptions: queryOptions)
    }
    
    @MainActor
    func editComment(comment: AmityCommentModel) async throws {
        let updateOptions = AmityCommentUpdateOptions(text: comment.text, metadata: comment.metadata, mentioneesBuilder: comment.mentioneeBuilder)
        try await commentManager.editComment(withId: comment.id, options: updateOptions)
    }
    
    func hasTargetReply(comment: AmityCommentModel) -> Bool {
        if case .content(let replyComment) = targetCommentReply?.type, replyComment.parentId == comment.commentId {
            return true
        }
        return false
    }
    
    func getTargetReply(for comment: AmityCommentModel) -> AmityCommentModel? {
        if case .content(let replyComment) = targetCommentReply?.type, replyComment.parentId == comment.commentId {
            return replyComment
        } else {
            return nil
        }
    }
}

class TargetCommentFetcher {
    
    private let commentManager = CommentManager()
    private var token: AmityNotificationToken?
    
    func fetchTargetComment(id: String, completion: @escaping (_ parent: AmityComment?, _ reply: AmityComment?) -> Void) {
        var replyComment: AmityComment?
        
        fetchComment(id: id) { [weak self] comment in
            guard let self else {
                completion(nil, nil)
                return
            }
            
            // If this comment has parent, its a reply comment
            if let parentCommentId = comment?.parentId {
                replyComment = comment
                // Fetch its parent
                fetchComment(id: parentCommentId) { parentComment in
                    completion(parentComment, replyComment)
                }
            } else {
                // This comment does not have parent
                completion(comment, nil)
            }
        }
    }
    
    private func fetchComment(id: String, completion: @escaping (_ comment: AmityComment?) -> Void) {
        token = commentManager.getComment(commentId: id).observe({ [weak self] liveComment, error in
            if let error {
                Log.warn(">> Error while fetching target comment \(id): \(error.localizedDescription)")
            }
            
            guard let self else {
                completion(nil)
                return
            }
                        
            completion(liveComment.snapshot)
        })
    }
}
