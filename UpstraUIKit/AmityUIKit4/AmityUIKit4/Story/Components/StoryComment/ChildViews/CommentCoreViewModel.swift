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
    @Published var scrollToEditingAnchorId: String?
    
    var loadedItems: [PaginatedItem<AmityComment>] = []

    private var commentCollection: AmityCollection<AmityComment>?
    private let commentManager = CommentManager()
    var paginator: UIKitPaginator<AmityComment>?
    
    let referenceId: String
    let referenceType: AmityCommentReferenceType
    let hideEmptyText: Bool
    @Published var hideCommentButtons: Bool
    
    private var paginatorCancellable: AnyCancellable?
    
    let targetCommentId: String?
    let targetCommentParentId: String?
    
    let rootCommentId: String?
    
    var isL2Target: Bool {
        guard let parentId = targetCommentParentId, let rootId = rootCommentId else { return false }
        return parentId != rootId
    }
    
    var highlightTargetCommentId: String? {
        guard isL2Target else { return nil }
        return targetCommentId
    }
    
    var targetCommentReply: PaginatedItem<AmityCommentModel>?
    var targetComment: PaginatedItem<AmityCommentModel>?
    @Published var targetL2Comment: PaginatedItem<AmityCommentModel>?
    
    let targetCommentFetcher = TargetCommentFetcher()
    @Published var isTargetCommentFetched = false
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
         rootCommentId: String? = nil,
         preloadRepliesOfComment: Bool = false,
         loadComments: Bool = true
    ) {
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.hideEmptyText = hideEmptyText
        self.hideCommentButtons = hideCommentButtons
        self.targetCommentId = targetCommentId
        self.targetCommentParentId = targetCommentParentId
        self.rootCommentId = rootCommentId
        self.preloadRepliesOfComment = preloadRepliesOfComment

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

        guard loadComments else { return }

        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    orderBy: .descending,
                                                    includeDeleted: true)
        let collection = commentManager.getComments(queryOptions: queryOptions)
        commentCollection = collection
        let idToExclude: String?
        let isL2 = targetCommentParentId != nil && rootCommentId != nil && targetCommentParentId != rootCommentId
        if isL2, let rootId = rootCommentId {
            idToExclude = rootId
        } else {
            idToExclude = targetCommentParentId ?? targetCommentId
        }
        paginator = UIKitPaginator(liveCollection: collection, adPlacement: .comment, communityId: communityId, excludedId: idToExclude, modelIdentifier: { model in
            return model.commentId
        })
        paginator?.load()

        paginatorCancellable = paginator?.$snapshots.sink { [weak self] items in
            guard let self else { return }

            self.loadingStatus = self.commentCollection?.loadingStatus ?? .notLoading
            self.loadedItems = items

            if targetCommentId == nil {
                self.renderCommentFeed()
            } else if self.isTargetCommentFetched {
                self.renderCommentFeed()
            }
        }

        if let targetCommentId {
            if isL2Target, let rootId = rootCommentId {
                self.targetCommentFetcher.fetchComment(id: rootId) { [weak self] rootComment in
                    guard let self else { return }
                    
                    self.isTargetCommentFetched = true
                    
                    if let rootComment, !rootComment.isDeleted {
                        let root = PaginatedItem(id: rootComment.commentId, type: .content(AmityCommentModel(comment: rootComment)))
                        self.targetComment = root
                    } else {
                        DispatchQueue.main.async {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString)
                        }
                    }
                    
                    if let parentId = self.targetCommentParentId {
                        self.targetCommentFetcher.fetchComment(id: parentId) { [weak self] l1Comment in
                            guard let self else { return }
                            if let l1Comment, !l1Comment.isDeleted {
                                let reply = PaginatedItem(id: l1Comment.commentId, type: .content(AmityCommentModel(comment: l1Comment)))
                                self.targetCommentReply = reply
                            } else {
                                DispatchQueue.main.async {
                                    Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString)
                                }
                            }
                            self.targetCommentFetcher.fetchComment(id: targetCommentId) { l2Comment in
                                if let l2Comment, !l2Comment.isDeleted {
                                    let l2 = PaginatedItem(id: l2Comment.commentId, type: .content(AmityCommentModel(comment: l2Comment)))
                                    self.targetL2Comment = l2
                                } else {
                                    DispatchQueue.main.async {
                                        Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString)
                                    }
                                }
                                self.renderCommentFeed()
                            }
                        }
                    } else {
                        self.renderCommentFeed()
                    }
                }
            } else {
                self.targetCommentFetcher.fetchTargetComment(id: targetCommentId) { parent, reply in
                    self.isTargetCommentFetched = true
                                    
                    if let parent, !parent.isDeleted {
                        let parentComment = PaginatedItem(id: parent.commentId, type: .content(AmityCommentModel(comment: parent)))
                        self.targetComment = parentComment
                    } else {
                        DispatchQueue.main.async {
                            Toast.showToast(style: .warning, message: AmityLocalizedStringSet.Comment.replyUnavailableToastMessage.localizedString)
                        }
                    }
                    
                    if let reply {
                        let replyComment = PaginatedItem(id: reply.commentId, type: .content(AmityCommentModel(comment: reply)))
                        self.targetCommentReply = replyComment
                    }
                    
                    self.renderCommentFeed()
                }
            }
        }
    }
    
    func renderCommentFeed() {
        var items = [PaginatedItem<AmityCommentModel>]()
        
        if let targetComment {
            items.insert(targetComment, at: 0)
        }
        
        let mappedLoadedItems = loadedItems.map {
            switch $0.type {
            case .content(let comment):
                return PaginatedItem(id: $0.id, type: .content(AmityCommentModel(comment: comment)))
            case .ad(let ad):
                return PaginatedItem(id: $0.id, type: .ad(ad))
            case .bannerAd(let placement):
                return PaginatedItem(id: $0.id, type: .bannerAd(placement))
            }
        }
        items.append(contentsOf: mappedLoadedItems)
        self.commentItems = items
    }
    
    func getChildComments(parentId: String, isL2Thread: Bool = false) -> AmityCollection<AmityComment> {
        let queryOptions = AmityCommentQueryOptions(referenceId: referenceId,
                                                    referenceType: referenceType,
                                                    filterByParentId: true,
                                                    parentId: parentId,
                                                    orderBy: isL2Thread ? .ascending : .descending,
                                                    includeDeleted: false,
                                                    pageSize: 5)
        return commentManager.getComments(queryOptions: queryOptions)
    }
    
    @MainActor
    func editComment(comment: AmityCommentModel) async throws {
        let links = AmityPreviewLinkWizard.shared.buildLinks(from: comment.text)
        let metadata = comment.metadata ?? ["mentioned": []]
        let updateOptions = AmityCommentUpdateOptions(text: comment.text, metadata: metadata, mentioneesBuilder: comment.mentioneeBuilder, links: links.isEmpty ? [] : links)
        try await commentManager.editComment(withId: comment.id, options: updateOptions)
        refreshOptimisticL2Comment(commentId: comment.id)
    }
    
    func refreshOptimisticL2Comment(commentId: String) {
        let liveObject = commentManager.getComment(commentId: commentId)
        guard let snapshot = liveObject.snapshot, let parentId = snapshot.parentId else { return }
        if var comments = optimisticL2InsertComments[parentId] {
            if let idx = comments.firstIndex(where: { $0.commentId == commentId }) {
                comments[idx] = snapshot
                optimisticL2InsertComments[parentId] = comments
            }
        }
    }
    
    @Published var optimisticL2InsertIds: [String: [String]] = [:]
    @Published var optimisticL2InsertComments: [String: [AmityComment]] = [:]

    @Published var expandRepliesForCommentId: String? = nil

    func registerOptimisticL2Reply(comment: AmityComment, l1ParentId: String) {
        let commentId = comment.commentId
        var ids = optimisticL2InsertIds[l1ParentId] ?? []
        if !ids.contains(commentId) {
            ids.insert(commentId, at: 0) // prepend newest
        }
        optimisticL2InsertIds[l1ParentId] = ids

        var comments = optimisticL2InsertComments[l1ParentId] ?? []
        if !comments.contains(where: { $0.commentId == commentId }) {
            comments.insert(comment, at: 0) // prepend newest
        }
        optimisticL2InsertComments[l1ParentId] = comments
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

    func getTargetL2Comment() -> AmityCommentModel? {
        if case .content(let l2Comment) = targetL2Comment?.type {
            return l2Comment
        }
        return nil
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
            
            if let parentCommentId = comment?.parentId {
                replyComment = comment
                fetchComment(id: parentCommentId) { parentComment in
                    completion(parentComment, replyComment)
                }
            } else {
                completion(comment, nil)
            }
        }
    }
    
    func fetchComment(id: String, completion: @escaping (_ comment: AmityComment?) -> Void) {
        token = commentManager.getComment(commentId: id).observe({ [weak self] liveComment, error in
            if let error {
                Log.warn(">> Error while fetching target comment \(id): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let self else {
                completion(nil)
                return
            }
            
            completion(liveComment.snapshot)
        })
    }
}
