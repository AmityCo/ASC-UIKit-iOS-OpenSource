//
//  AmityUIKit4.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/21/23.
//

import UIKit
import AmitySDK

/// AmityUIKit4
public final class AmityUIKit4Manager {
    
    private init() { }
    
    
    /// Setup AmityUIKit instance. Internally it creates AmityClient instance
    /// from AmitySDK.
    ///
    /// If you are using `AmitySDK` & `AmityUIKit` within same project, you can setup `AmityClient` instance using this method and access it using static property `client`.
    ///
    /// - Parameters:
    ///   - apiKey: ApiKey provided by Amity
    ///   - region: The region to which this UIKit connects to. By default, region is .global
    public static func setup(apiKey: String, region: AmityRegion = .SG) {
        RemoteConfig.setup(apiKey: apiKey, httpEndpoint: region.httpUrl)
        AmityUIKitManagerInternal.shared.setup(apiKey, region: region)
    }
    
    
    /// Setup AmityUIKit instance. Internally it creates AmityClient instance from AmitySDK.
    ///
    /// If you do not need extra configuration, please use setup(apiKey:_, region:_) method instead.
    ///
    /// Also if you are using `AmitySDK` & `AmityUIKit` within same project, you can setup `AmityClient` instance using this method and access it using static property `client`.
    ///
    /// - Parameters:
    ///   - apiKey: ApiKey provided by Amity
    ///   - endpoint: Custom Endpoint to which this UIKit connects to.
    public static func setup(apiKey: String, endpoint: AmityEndpoint) {
        RemoteConfig.setup(apiKey: apiKey, httpEndpoint: endpoint.httpUrl ?? "")
        AmityUIKitManagerInternal.shared.setup(apiKey, endpoint: endpoint)
    }
    
    
    /// Setup AmityUIKit instance by using AmityClient from AmitySDK.
    ///
    /// If you already have AmityClient instance from SDK, you can setup by using it.
    ///
    /// - Parameters:
    ///   - client: AmityClient from AmitySDK
    public static func setup(client: AmityClient) {
        AmityUIKitManagerInternal.shared.setup(client)
    }
    
    // MARK: - Setup Authentication
    
    /// Registers current user with server. This is analogous to "login" process. If the user is already registered, local
    /// information is used. It is okay to call this method multiple times.
    ///
    /// Note:
    /// You do not need to call `unregisterDevice` before calling this method. If new user is being registered, then sdk handles unregistering process automatically.
    /// So simply call `registerDevice` with new user information.
    ///
    /// - Parameters:
    ///   - userId: Id of the user
    ///   - displayName: Display name of the user. If display name is not provided, user id would be set as display name.
    ///   - authToken: Auth token for this user if you are using secure mode.
    ///   - completion: Completion handler.
    public static func registerDevice(
        withUserId userId: String,
        displayName: String?,
        authToken: String? = nil,
        sessionHandler: SessionHandler,
        completion: AmityRequestCompletion? = nil) {
            AmityUIKitManagerInternal.shared.registerDevice(userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler, completion: completion)
        }
    
    @MainActor
    public static func registerDeviceAsVisitor(
        authSignature: String?,
        authSignatureExpiresAt: Date?,
        sessionHandler: SessionHandler) async throws {
            try await AmityUIKitManagerInternal.shared.registerDeviceAsGuest(authSignature: authSignature, authSignatureExpiresAt: authSignatureExpiresAt, sessionHandler: sessionHandler)
        }
    /// Unregisters current user. This removes all data related to current user & terminates conenction with server. This is analogous to "logout" process.
    /// Once this method is called, the only way to re-establish connection would be to call `registerDevice` method again.
    ///
    /// Note:
    /// You do not need to call this method before calling `registerDevice`.
    public static func unregisterDevice() {
        AmityUIKitManagerInternal.shared.unregisterDevice()
    }
    
    
    /// Registers this device for receiving apple push notification
    /// - Parameter deviceToken: Correct apple push notificatoin token received from the app.
    public static func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        AmityUIKitManagerInternal.shared.registerDeviceForPushNotification(deviceToken, completion: completion)
    }
    
    /// Unregisters this device for receiving push notification related to AmitySDK.
    public static func unregisterDevicePushNotification(completion: AmityRequestCompletion? = nil) {
        let currentUserId = AmityUIKitManagerInternal.shared.currentUserId
        Task { @MainActor in
            do {
                let success = try await AmityUIKitManagerInternal.shared.unregisterDevicePushNotification(for: currentUserId)
                completion?(success, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    public static func setEnvironment(_ env: [String: Any]) {
        AmityUIKitManagerInternal.shared.env = env
    }
    
    public static func didUpdateClient() {
        AmityUIKitManagerInternal.shared.didUpdateClient()
    }
    
    // MARK: - Variable
    
    /// Public instance of `AmityClient` from `AmitySDK`. If you are using both`AmitySDK` & `AmityUIKit` in a same project, we recommend to have only one instance of `AmityClient`. You can use this instance instead.
    public static var client: AmityClient {
        return AmityUIKitManagerInternal.shared.client
    }
    
    public static var behaviour: AmityUIKitBehaviour {
        set {
            AmityUIKitManagerInternal.shared.behavior = newValue
        } get {
            return AmityUIKitManagerInternal.shared.behavior
        }
    }
    
    static var bundle: Bundle {
        return Bundle(for: self)
    }
    
    /// Custom asset bundle provided by the user to override UIKit4 images
    static var customAssetBundle: Bundle?
    
    /// Sets a custom asset bundle for overriding UIKit4 images.
    ///
    /// Use this to provide your own assets in place of UIKit4's defaults.
    /// Your custom image will only be loaded if the image name does not exist in the UIKit4 bundle.
    ///
    /// - Note: If you provide an image with the same name as a UIKit4 default asset,
    ///   the UIKit4 version will take priority and your custom image will not be used.
    ///
    /// - Parameter bundle: The bundle containing your custom assets
    public static func setCustomAssetBundle(bundle: Bundle) {
        customAssetBundle = bundle
    }

    /// Sets a custom configuration JSON file to override the default bundled config.
    ///
    /// Use this method to provide a custom configuration JSON file from your app's bundle.
    ///
    /// Example:
    /// ```swift
    /// if let path = Bundle.main.path(forResource: "CustomUIKitConfig", ofType: "json") {
    ///     AmityUIKit4Manager.setCustomConfigFile(path)
    /// }
    /// ```
    ///
    /// - Parameter filePath: The absolute file path to the configuration JSON file.
    // MARK: Phase 1 module flags

    /// The Phase 1 modules and what each is sold with.
    ///
    /// A host that offers its own module switches has to render the bundle rules
    /// — "Post needs Community" — and the alternative was a second copy of the
    /// graph in the sample app. These are the catalog's rules, from the network's
    /// module settings, the same ones the gate applies: with no settings row yet
    /// every entry is empty, because nothing cascades until the rules arrive.
    public static var moduleRequirements: [String: (all: [String], any: [String])] {
        Dictionary(uniqueKeysWithValues: AmityUIKitFeature.allCases.map {
            ($0.rawValue, AmityUIKitConfigController.shared.moduleRequirement($0.rawValue))
        })
    }

    // MARK: Public

    /// Whether a module resolves on under the given switches, the catalog's bundle
    /// rules applied — none until the network's module settings have been read.
    ///
    /// A pure function over a flag set the caller supplies, for a host rendering
    /// its own switches. It knows nothing of grants and feeds nothing into the
    /// gate; `isModuleAvailable` is the gate's answer (REQ-020).
    public static func isModuleEnabled(_ key: String, under flags: [String: Bool]) -> Bool {
        AmityUIKitConfigController.shared.resolveFeature(key, flags: flags)
    }

    /// Whether a module is available in this app.
    ///
    /// The network's plan is the only source that can withhold one — nothing
    /// local can withhold or grant a module. This is the resolved answer over
    /// the entitlement, with the catalog's prerequisite rules applied, which is
    /// the same question every gated page, component and element already asks.
    /// So a host reading it sees exactly what the UIKit will do.
    ///
    /// Synchronous and free of I/O by contract (REQ-019): it is read while views
    /// are being built, and it never reads the store — the snapshot is rebuilt
    /// when the SDK posts `AmityModuleSettings.didUpdateNotification`.
    ///
    /// Distinct from `isModuleEnabled(_:under:)`, which is a pure function over
    /// flags a caller supplies and knows nothing of entitlements — for a host
    /// rendering its own switches.
    public static func isModuleAvailable(_ feature: AmityUIKitFeature) -> Bool {
        AmityUIKitConfigController.shared.isFeatureEnabled(feature)
    }

    /// The same answer with its reason. `notGranted` is about this module;
    /// `prerequisiteUnavailable` is about another one, and names every
    /// prerequisite that would have satisfied it.
    public static func moduleAvailability(_ feature: AmityUIKitFeature) -> AmityUIKitModuleAvailability {
        AmityUIKitConfigController.shared.moduleAvailability(feature)
    }

    /// Every module this UIKit gates, for a host rendering a settings screen.
    public static var moduleAvailability: [AmityUIKitModuleAvailability] {
        AmityUIKitConfigController.shared.moduleAvailabilities()
    }

    public static func setConfigFile(_ filePath: String) {
        AmityUIKitConfigController.shared.setConfigFile(filePath)
    }

    public static func syncNetworkConfig() async throws {
        try await AmityUIKitManagerInternal.shared.syncNetworkConfig()
    }
}

final class AmityUIKitManagerInternal: NSObject {
    
    // MARK: - Properties
    
    public static let shared = AmityUIKitManagerInternal()
    private var _client: AmityClient?
    private var apiKey: String = ""
    private var notificationTokenMap: [String: String] = [:]
    
    private(set) var fileService = AmityFileService()
    private(set) var messageMediaService = AmityMessageMediaService()
    
    var shareableLinkConfig: AmityShareableLinkConfiguration?
    
    var currentUserId: String { return client.currentUserId ?? "" }
    let remoteConfig = RemoteConfig()
    
    var client: AmityClient {
        guard let client = _client else {
            fatalError("Something went wrong. Please ensure `AmityUIKitManager.setup(:_)` get called before accessing client.")
        }
        return client
    }

    /// The client if `setup(_:)` has run, nil otherwise — for reads that are
    /// legitimately reachable before setup and must answer "unknown" then,
    /// not crash. `client` above is for code that cannot run without one.
    var clientIfSetUp: AmityClient? { _client }
    
    var env: [String: Any] = [:]
    
    var behavior: AmityUIKitBehaviour = AmityUIKitBehaviour()
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
        AmityLog.logLevel = .all
        print("-- ** AmityUIKit Version: \(BuildInfo.version) Build: \(BuildInfo.gitHash) ** --")
        setupUIKitBehaviour()
    }
    
    // MARK: - Setup functions
    
    func setup(_ apiKey: String, region: AmityRegion) {
        AmityLog.logLevel = .all
        guard let client = try? AmityClient(apiKey: apiKey, region: region) else { return }
        
        _client = client
        _client?.delegate = self
       
        verifyStoredConfigForCurrentApiKey()
    }
    
    func setup(_ apiKey: String, endpoint: AmityEndpoint) {
        AmityLog.logLevel = .all
        guard let client = try? AmityClient(apiKey: apiKey, endpoint: endpoint) else { return }
        
        _client = client
        _client?.delegate = self

        verifyStoredConfigForCurrentApiKey()
    }
    
    func setup(_ client: AmityClient) {
        AmityLog.logLevel = .all
        _client = client
        _client?.delegate = self
        didUpdateClient()
        
        verifyStoredConfigForCurrentApiKey()
        Log.add(event: .info, "Is AmityClient established: \(client.isEstablished)")
    }
    
    private func verifyStoredConfigForCurrentApiKey() {
        if !remoteConfig.isCurrentApiKeyMatchingStoredNetwork() {
            do {
                try remoteConfig.clearStoredConfig()
            } catch let error {
                Log.warn("Remote config error: \(error)")
            }
        }
        // Every setup path lands here, which makes it the one place the gate can
        // read the network's entitlements: the client exists by now. After the
        // stale-network cleanup above, not before — a gate built from the
        // previous network's answer would hold it for the whole launch. This
        // registers for AmityModuleSettings.didUpdateNotification (once per
        // process — a re-setup or network switch re-reads, it does not
        // subscribe twice) and then reads. The UIKit never fetches this.
        AmityUIKitConfigController.shared.refreshModuleEntitlements()
    }
    
    func syncNetworkConfig() async throws {
        try await remoteConfig.getRemoteConfig()
    }
    
    func setupUIKitBehaviour() {
        // CreateStoryPage
        let createStoryPageBehaviour = AmityCreateStoryPageBehaviour()
        behavior.createStoryPageBehaviour = createStoryPageBehaviour
        
        // StoryCreationPage
        let draftStoryPageBehaviour = AmityDraftStoryPageBehaviour()
        behavior.draftStoryPageBehaviour = draftStoryPageBehaviour
        
        // StoryTabComponent
        let storyTabComponentBehaviour = AmityStoryTabComponentBehaviour()
        behavior.storyTabComponentBehaviour = storyTabComponentBehaviour
        
        // ViewStoryPage
        let viewStoryPageBehaviour = AmityViewStoryPageBehaviour()
        behavior.viewStoryPageBehaviour = viewStoryPageBehaviour
        
        // CommentTrayComponent
        let commentTrayComponentBehavior = AmityCommentTrayComponentBehavior()
        behavior.commentTrayComponentBehavior = commentTrayComponentBehavior
        
        // StoryTargetSelectionPage
        let storyTargetSelectionPageBehaviour = AmityStoryTargetSelectionPageBehaviour()
        behavior.storyTargetSelectionPageBehaviour = storyTargetSelectionPageBehaviour
        
        // SocialHomePage
        let socialHomePageBehavior = AmitySocialHomePageBehavior()
        behavior.socialHomePageBehavior = socialHomePageBehavior
        
        // SocialHomeTopNavigationComponent
        let socialHomeTopNavigationComponentBehavior = AmitySocialHomeTopNavigationComponentBehavior()
        behavior.socialHomeTopNavigationComponentBehavior = socialHomeTopNavigationComponentBehavior
        
        // MyCommunitiesComponentBehavior
        let myCommunitiesComponentBehavior = AmityMyCommunitiesComponentBehavior()
        behavior.myCommunitiesComponentBehavior = myCommunitiesComponentBehavior
        
        // NewsFeedComponent
        let newsFeedComponentBehavior = AmityNewsFeedComponentBehavior()
        behavior.newsFeedComponentBehavior = newsFeedComponentBehavior
        
        // GlobalFeedComponent
        let globalFeedComponentBehavior = AmityGlobalFeedComponentBehavior()
        behavior.globalFeedComponentBehavior = globalFeedComponentBehavior
        
        // PostContentComponent
        let postContentComponentBehavior = AmityPostContentComponentBehavior()
        behavior.postContentComponentBehavior = postContentComponentBehavior
        
        // CreatePostMenuComponent
        let createPostMenuComponentBehavior = AmityCreatePostMenuComponentBehavior()
        behavior.createPostMenuComponentBehavior = createPostMenuComponentBehavior
        
        // PostTargetSelectionPage
        let postTargetSelectionPageBehavior = AmityPostTargetSelectionPageBehavior()
        behavior.postTargetSelectionPageBehavior = postTargetSelectionPageBehavior
        
        // PostDetailPage
        let postDetailPageBehavior = AmityPostDetailPageBehavior()
        behavior.postDetailPageBehavior = postDetailPageBehavior
        
        // SocialGlobalSearchPage
        let socialGlobalSearchPageBehavior = AmitySocialGlobalSearchPageBehavior()
        behavior.socialGlobalSearchPageBehavior = socialGlobalSearchPageBehavior
        
        // MyCommunitiesSearchPage
        let myCommunitiesSearchPageBehavior = AmityMyCommunitiesSearchPageBehavior()
        behavior.myCommunitiesSearchPageBehavior = myCommunitiesSearchPageBehavior
        
        // PostSearchResultComponent
        let postSearchResultComponentBehavior = AmityPostSearchResultComponentBehavior()
        behavior.postSearchResultComponentBehavior = postSearchResultComponentBehavior
        
        // CommunitySearchResultComponent
        let communitySearchResultComponentBehavior = AmityCommunitySearchResultComponentBehavior()
        behavior.communitySearchResultComponentBehavior = communitySearchResultComponentBehavior
        
        // UserSearchResultComponentBehavior
        let userSearchResultComponentBehavior = AmityUserSearchResultComponentBehavior()
        behavior.userSearchResultComponentBehavior = userSearchResultComponentBehavior
        
        // PostComposerPage
        let postComposerPageBehavior = AmityPostComposerPageBehavior()
        behavior.postComposerPageBehavior = postComposerPageBehavior
        
        // CommunityProfilePage
        let communityProfilePageBehavior = AmityCommunityProfilePageBehavior()
        behavior.communityProfilePageBehavior = communityProfilePageBehavior
        
        // CommunitySetupPage
        let communitySetupPageBehavior = AmityCommunitySetupPageBehavior()
        behavior.communitySetupPageBehavior = communitySetupPageBehavior
        
        // CommunityMembershipPage
        let communityMembershipPageBehavior = AmityCommunityMembershipPageBehavior()
        behavior.communityMembershipPageBehavior = communityMembershipPageBehavior
        
        // CommunitySettingPage
        let communitySettingPageBehavior = AmityCommunitySettingPageBehavior()
        behavior.communitySettingPageBehavior = communitySettingPageBehavior
        
        // CommunityNotificaitonSettingPage
        let communityNotificationSettingPageBehavior = AmityCommunityNotificationSettingPageBehavior()
        behavior.communityNotificationSettingPageBehavior = communityNotificationSettingPageBehavior
        
        // UserProfilePage
        let userProfilePageBehavior = AmityUserProfilePageBehavior()
        behavior.userProfilePageBehavior = userProfilePageBehavior
        
        // UserProfileHeaderComponent
        let userProfileHeaderComponentBehavior = AmityUserProfileHeaderComponentBehavior()
        behavior.userProfileHeaderComponentBehavior = userProfileHeaderComponentBehavior
        
        // UserRelationshipPage
        let userRelationshipPageBehavior = AmityUserRelationshipPageBehavior()
        behavior.userRelationshipPageBehavior = userRelationshipPageBehavior
        
        // UserPendingFollowRequestsPage
        let userPendingFollowRequestsPageBehavior = AmityUserPendingFollowRequestsPageBehavior()
        behavior.userPendingFollowRequestsPageBehavior = userPendingFollowRequestsPageBehavior
        
        // BlockedUsersPage
        let blockedUsersPageBehavior = AmityBlockedUsersPageBehavior()
        behavior.blockedUsersPageBehavior = blockedUsersPageBehavior
        
        // PendingPostContentComponent
        let pendingPostContentComponentBehavior = AmityPendingPostContentComponentBehavior()
        behavior.pendingPostContentComponentBehavior = pendingPostContentComponentBehavior
        
        // Poll Post
        let pollTargetSelectionPageBehavior = AmityPollTargetSelectionPageBehavior()
        behavior.pollTargetSelectionPageBehavior = pollTargetSelectionPageBehavior
        
        let livestreamBehavior = AmityLivestreamBehavior()
        behavior.livestreamBehavior = livestreamBehavior
        
        let liveStreamPostTargetSelectionPageBehavior = AmityLivestreamPostTargetSelectionPageBehavior()
        behavior.liveStreamPostTargetSelectionPageBehavior = liveStreamPostTargetSelectionPageBehavior
        
        let notificationTrayPageBehavior = AmityNotificationTrayPageBehavior()
        behavior.notificationTrayPageBehavior = notificationTrayPageBehavior
        
        let joinRequestComponentBehavior = AmityJoinRequestContentComponentBehavior()
        behavior.joinRequestContentComponentBehavior = joinRequestComponentBehavior
        
        let clipFeedPageBehavior = AmityClipFeedPageBehavior()
        behavior.clipFeedPageBehavior = clipFeedPageBehavior
        
        let draftClipPageBehavior = AmityDraftClipPageBehavior()
        behavior.draftClipPageBehavior = draftClipPageBehavior
        
        let globalBehavior = AmityGlobalBehavior()
        behavior.globalBehavior = globalBehavior
        
        // Event
        behavior.eventTargetSelectionPageBehavior = AmityEventTargetSelectionPageBehavior()
        behavior.eventDetailPageBehavior = AmityEventDetailPageBehavior()
        behavior.exploreEventFeedComponentBehavior = AmityExploreEventFeedComponentBehavior()
        behavior.myEventFeedComponentBehavior = AmityMyEventFeedComponentBehavior()
        behavior.eventSetupPageBehavior = AmityEventSetupPageBehavior()
    }
    
    func registerDevice(_ userId: String,
                        displayName: String?,
                        authToken: String?,
                        sessionHandler: SessionHandler,
                        completion: AmityRequestCompletion?) {
        Task { @MainActor in
            do {
                try await client.login(userId: userId, displayName: displayName, authToken: authToken, sessionHandler: sessionHandler)
                await revokeDeviceTokens()
                didUpdateClient()
                completion?(true, nil)
            } catch let error {
                completion?(false, error)
            }
        }
    }
    
    @MainActor
    func registerDeviceAsGuest(authSignature: String?,
                               authSignatureExpiresAt: Date?,
                               sessionHandler: SessionHandler) async throws {
        
        try await client.loginAsVisitor(authSignature: authSignature, authSignatureExpiresAt: authSignatureExpiresAt, sessionHandler: sessionHandler)
        // Subscribe to visitor usage-limit events. SDK only emits for visitor/bot users.
        AmityVisitorUsageLimitObserver.shared.start()
        
        didUpdateClient()
    }
    
    func unregisterDevice() {
        AmityFileCache.shared.clearCache()
        AmityVisitorUsageLimitObserver.shared.stop()
        self._client?.logout()
    }
    
    func registerDeviceForPushNotification(_ deviceToken: String, completion: AmityRequestCompletion? = nil) {
        // It's possible that `deviceToken` can be changed while user is logging in.
        // To prevent user from registering notification twice, we will revoke the current one before register new one.
        Task { @MainActor in
            do {
                await revokeDeviceTokens()
                
                try await client.registerPushNotification(withDeviceToken: deviceToken)
                
                if let currentUserId = _client?.currentUserId {
                    // if register device successfully, binds device token to user id.
                    notificationTokenMap[currentUserId] = deviceToken
                }
                completion?(true, nil)
            } catch let error {
                completion?(false, error)
            }
            
        }
    }
    
    @MainActor
    func unregisterDevicePushNotification(for userId: String) async throws -> Bool {
        
        do {
            try await client.unregisterPushNotification()
            if let currentUserId = self._client?.currentUserId {
                // if unregister device successfully, remove device token belonging to the user id.
                self.notificationTokenMap[currentUserId] = nil
            }
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func revokeDeviceTokens() async {
        
        await withThrowingTaskGroup(of: Bool.self, body: { group in
            for (userId, _) in notificationTokenMap {
                group.addTask {
                    try await self.unregisterDevicePushNotification(for: userId)
                }
            }
        })
        
    }
    
    func didUpdateClient() {
        // Update file repository to use in file service.
        fileService.fileRepository = AmityFileRepository()
        messageMediaService.fileRepository = AmityFileRepository()
        
        let accessToken = self.client.accessToken ?? ""
        let authenticatedRequest = AnyModifier { request in
            var r = request
            r.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return r
        }
        
        KingfisherManager.shared.defaultOptions = [
            .requestModifier(authenticatedRequest)
        ]
        
        // Initialize AdEngine so that we can start fetching ad settings here
        let _ = AdEngine.shared

        Task {
            await fetchShareableLinkConfig()
        }
    }
    
    func canShareLink(for type: AmitySharableContentType) -> Bool {
        return shareableLinkConfig?.isEnabled(type) ?? false
    }

    func generateShareableLink(for type: AmitySharableContentType, id: String) -> String {
        return shareableLinkConfig?.generateLink(type, referenceId: id) ?? ""
    }
    
    @MainActor
    private func fetchShareableLinkConfig() async {
        do {
            shareableLinkConfig = try await client.getShareableLinkConfiguration()
        } catch let error {
            Log.add(event: .info, "Shareable link configuration error: \(error.localizedDescription)")
            shareableLinkConfig = nil
        }
    }
    
    public var currentUserType: AmityUserType {
        return client.currentUserType
    }
    
    public var isGuestUser: Bool {
        return client.currentUserType == .visitor || client.currentUserType == .bot
    }
}

extension AmityUIKitManagerInternal: AmityClientDelegate {
    func didReceiveError(error: Error) {
        Log.add(event: .error, error.localizedDescription)
    }
}

extension AmityClient {
    var isEstablished: Bool {
        switch sessionState {
        case .established:
            return true
        default:
            return false
        }
    }
}

