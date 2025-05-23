//
//  LiveStreamBroadcastViewController.swift
//  AmityUIKitLiveStream
//
//  Created by Nutchaphon Rewik on 30/8/2564 BE.
//

import UIKit
import AmitySDK
import AmityLiveVideoBroadcastKit
import AmityUIKit

final public class LiveStreamBroadcastViewController: UIViewController {
    
    /// When the user finish live streaming, it will present post detail page.
    /// When the user exit post detail page, the it will dismiss back to this destination.
    public weak var destinationToUnwindBackAfterFinish: UIViewController?
    
    // MARK: - Dependencies
    
    let client: AmityClient
    let targetId: String?
    let targetType: AmityPostTargetType
    let communityRepository: AmityCommunityRepository
    let userRepository: AmityUserRepository
    let fileRepository: AmityFileRepository
    let streamRepository: AmityStreamRepository
    let postRepository: AmityPostRepository
    var broadcaster: AmityVideoBroadcaster?
    
    // MARK: - Internal Const Properties
    
    /// The queue to execute go live operations.
    let goLiveOperationQueue = OperationQueue()
    
    /// Formatter to render live duration in streamingStatusLabel
    let liveDurationFormatter = DateComponentsFormatter()
    
    // MARK: - Private Const Properties
    private let mentionManager: ASCMentionManager
    // MARK: - States
    
    private var hasSetupBroadcaster = false
    
    /// Store cover image url, after the user choose cover image from the image picker.
    /// This will be used when the user press "go live" button.
    ///
    /// LiveStreamBroadcastVC+CoverImagePicker.swift
    var coverImageUrl: URL?
    
    /// Indicate current container state.
    ///
    /// LiveStreamBroadcast+UIContainerState.swift
    var containerState = ContainerState.create
    
    /// After successfully perform go live operationes, we will set the post.
    /// We use this post to start publish live stream, and navigate to post detail page, after the user finish streaming.
    var createdPost: AmityPost?
    
    /// This is set when this page start live publishing live stream.
    /// We use this state to display live stream timer.
    var startedAt: Date?
    
    /// We start this timer when we begin to publish stream.
    var liveDurationTimer: Timer?
    
    var liveObjectQueryToken: AmityNotificationToken?
    
    // MARK: - UI General
    @IBOutlet weak var renderingContainer: UIView!
    @IBOutlet private weak var overlayView: UIView!
    
    // MARK: - UI Container Create Components
    @IBOutlet weak var uiContainerCreate: UIView!
    
    // - uiContainerCreate.topRightStackView
    @IBOutlet private weak var selectCoverButton: UIButton!
    @IBOutlet private weak var coverImageContainer: UIView!
    @IBOutlet private weak var coverImageView: UIImageView!
    
    // - uiContainerCreate.detailStackView
    @IBOutlet weak var targetImageView: UIImageView!
    @IBOutlet weak var targetNameLabel: UILabel!
    @IBOutlet weak var titleTextField: AmityTextField!
    @IBOutlet weak var descriptionTextView: AmityTextView!
    
    @IBOutlet weak var goLiveButton: UIButton!
    @IBOutlet weak var streamCreatingStackView: UIStackView!
    @IBOutlet weak var streamCreateActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var streamCreateLabel: UILabel!
    
    // MARK: - UI Container Streaming Components
    @IBOutlet weak var uiContainerStreaming: UIView!
    @IBOutlet weak var streamingContainer: UIView!
    @IBOutlet weak var streamingStatusLabel: UILabel!
    @IBOutlet weak var finishButton: UIButton!
    
    // MARK: - UI Container End Components
    @IBOutlet weak var uiContainerEnd: UIView!
    @IBOutlet weak var streamEndActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var streamEndLabel: UILabel!
    
    // MARK: - UI Mention tableView
    @IBOutlet private var mentionTableView: AmityMentionTableView!
    @IBOutlet private var mentionTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var mentionTableViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Keyboard Observations
    // LiveStreamBroadcastVC+Keyboard.swift
    var keyboardIsHidden = true
    var keyboardHeight: CGFloat = 0
    var keyboardObservationTokens: [NSObjectProtocol] = []
    
    var isStartStreaming = false
    var currentAppIdleTimerDisabled = false
    
    // MARK: - Init / Deinit
    
    public init(client: AmityClient, targetId: String?, targetType: AmityPostTargetType) {
        
        self.client = client
        self.targetId = targetId
        self.targetType = targetType
         
        communityRepository = AmityCommunityRepository(client: client)
        userRepository = AmityUserRepository(client: client)
        fileRepository = AmityFileRepository(client: client)
        streamRepository = AmityStreamRepository(client: client)
        postRepository = AmityPostRepository(client: client)
        broadcaster = AmityVideoBroadcaster(client: client)
        mentionManager = ASCMentionManager(withType: .post(communityId: targetId))
        
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "LiveStreamBroadcastViewController", bundle: bundle)
        
        goLiveOperationQueue.maxConcurrentOperationCount = 1
        // It's fine to set the underlyingQueue to main thread.
        // The work items will be schedule and pickup on the main thread.
        // While the actual work will be run in the background thread.
        // See the detail of main() functions of GoLive operations.
        goLiveOperationQueue.underlyingQueue = .main
        
        liveDurationFormatter.allowedUnits = [.minute, .second]
        liveDurationFormatter.unitsStyle = .positional
        liveDurationFormatter.zeroFormattingBehavior = .pad
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        liveObjectQueryToken = nil
        unobserveKeyboardFrame()
        stopLiveDurationTimer()
        
        /// Disable app idle timer if it was previously disabled.
        if !currentAppIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        queryTargetDetail()
        observeKeyboardFrame()
        updateCoverImageSelection()
        switchToUIState(.create)
        mentionManager.delegate = self
        mentionManager.highlightAttributes = [.font: AmityFontSet.bodyBold, .foregroundColor: UIColor.white]
        mentionManager.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: UIColor.white]
        
        // Observe app life cycle notfications
        NotificationCenter.default.addObserver(self, selector: #selector(suspendLiveStream), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeLiveStream), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if !UIApplication.shared.isIdleTimerDisabled {
            currentAppIdleTimerDisabled = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //
        updateUIBaseOnKeyboardFrame()
        //
        // If the permission is authorized, we can try setup broadcaster now.
        if permissionsGranted() {
            trySetupBroadcaster()
        } else if permissionsNotDetermined() {
            requestPermissions { [weak self] granted in
                if granted {
                    self?.trySetupBroadcaster()
                } else {
                    self?.presentPermissionRequiredDialogue()
                }
            }
        } else {
            presentPermissionRequiredDialogue()
        }
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUIBaseOnKeyboardFrame()
    }
    
    @objc
    func suspendLiveStream() {
        guard let _ = createdPost,
              let broadcaster else {
            return
        }
        
        broadcaster.suspendPublish()
    }
    
    @objc
    func resumeLiveStream() {
        guard let createdPost,
              let broadcaster,
              let firstChildPost = createdPost.childrenPosts.first,
              let stream = firstChildPost.getLiveStreamInfo() else {
            return
        }
        
        broadcaster.startPublish(existingStreamId: stream.streamId)
    }
    
    // MARK: - Internal Functions
    
    /// goLiveButtomSpace will change base on keyboard frame.
    func updateUIBaseOnKeyboardFrame() {
        
        // Currently we don't do update UI base on keyboard.
        
        guard isViewLoaded, view.window != nil else {
            // only perform this logic, when view controller is visible.
            return
        }
        if keyboardIsHidden {
            mentionTableViewBottomConstraint.constant = 0
        } else {
            mentionTableViewBottomConstraint.constant = keyboardHeight
        }
        view.setNeedsLayout()
        
    }
    
    /// Call this function to update UI state, when the user select / unselect cover image
    func updateCoverImageSelection() {
        if let coverImageUrl = coverImageUrl {
            coverImageView.image = UIImage(contentsOfFile: coverImageUrl.path)
            selectCoverButton.isHidden = true
            coverImageContainer.isHidden = false
        } else {
            selectCoverButton.isHidden = false
            coverImageContainer.isHidden = true
        }
    }
    
    // MARK: - Private Functions
    
    private func setupViews() {
        
        targetNameLabel.textColor = .white
        targetNameLabel.font = AmityFontSet.bodyBold
        
        targetImageView.contentMode = .scaleAspectFill
        targetImageView.layer.cornerRadius = targetImageView.bounds.height * 0.5
        targetImageView.backgroundColor = UIColor.lightGray
        
        titleTextField.maxLength = 30
        titleTextField.font = AmityFontSet.headerLine
        titleTextField.textColor = .white
        titleTextField.returnKeyType = .done
        titleTextField.delegate = self
        
        descriptionTextView.text = nil
        descriptionTextView.padding = .zero
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.font = AmityFontSet.body
        descriptionTextView.placeholder = "Tap to add post description..."
        descriptionTextView.textColor = .white
        descriptionTextView.returnKeyType = .done
        descriptionTextView.customTextViewDelegate = self
        descriptionTextView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: UIColor.white]
        
        let textViewToolbar: UIToolbar = UIToolbar()
        textViewToolbar.barStyle = .default
        textViewToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(cancelInput))
        ]
        textViewToolbar.sizeToFit()
        descriptionTextView.inputAccessoryView = textViewToolbar
        
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 4
        coverImageView.isUserInteractionEnabled = true
        coverImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectCoverButtonDidTouch)))
        
        goLiveButton.backgroundColor = .white
        goLiveButton.clipsToBounds = true
        goLiveButton.layer.cornerRadius = 4
        goLiveButton.layer.borderWidth = 1
        goLiveButton.layer.borderColor = UIColor(red: 0.647, green: 0.663, blue: 0.71, alpha: 1).cgColor
        goLiveButton.setAttributedTitle(NSAttributedString(string: "Go live", attributes: [
            .foregroundColor: UIColor.black,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        
        finishButton.backgroundColor = .black
        finishButton.setAttributedTitle(NSAttributedString(string: "Finish", attributes: [
            .foregroundColor: UIColor.white,
            .font: AmityFontSet.bodyBold
        ]), for: .normal)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.clipsToBounds = true
        finishButton.layer.cornerRadius = 4
        finishButton.layer.borderColor = UIColor.white.cgColor
        finishButton.layer.borderWidth = 1
        finishButton.isHidden = true
        
        streamingContainer.clipsToBounds = true
        streamingContainer.layer.cornerRadius = 4
        streamingContainer.backgroundColor = UIColor(red: 1, green: 0.188, blue: 0.353, alpha: 1)
        streamingStatusLabel.textColor = .white
        streamingStatusLabel.font = AmityFontSet.captionBold
        setupMentionTableView()
        
        streamCreatingStackView.isHidden = true
    }
    
    private func trySetupBroadcaster() {
        if !hasSetupBroadcaster && permissionsGranted() {
            hasSetupBroadcaster = true
            setupBroadcaster()
        }
    }
    
    private func setupBroadcaster() {
        
        guard let broadcaster = broadcaster else {
            assertionFailure("broadcaster must exist at this point.")
            return
        }
        
        let config = AmityStreamBroadcasterConfiguration()
        config.canvasFitting = .fill
        config.bitrate = 3_000_000 // 3mbps
        config.frameRate = .fps30
        
        broadcaster.delegate = self
        broadcaster.videoResolution = renderingContainer.bounds.size
        broadcaster.setup(with: config)
        
        // Embed broadcaster.previewView
        broadcaster.previewView.translatesAutoresizingMaskIntoConstraints = false
        renderingContainer.addSubview(broadcaster.previewView)
        
        NSLayoutConstraint.activate([
            broadcaster.previewView.centerYAnchor.constraint(equalTo: renderingContainer.centerYAnchor),
            broadcaster.previewView.centerXAnchor.constraint(equalTo: renderingContainer.centerXAnchor),
            broadcaster.previewView.widthAnchor.constraint(equalToConstant: renderingContainer.bounds.width),
            broadcaster.previewView.heightAnchor.constraint(equalToConstant: renderingContainer.bounds.height)
        ])
        
    }
    
    private func switchCamera() {
        
        guard let broadcaster = broadcaster else {
            assertionFailure("broadcaster must exist at this point.")
            return
        }
        
        switch broadcaster.switchCamera {
        case .front:
            broadcaster.switchCamera = .back
        case .back:
            broadcaster.switchCamera = .front
        @unknown default:
            assertionFailure("Unhandled case")
        }
        
    }
    
    private func presentEndLiveStreamConfirmationDialogue() {
        let title = "Do yo want to end the live stream?"
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let end = UIAlertAction(title: "End", style: .default) { [weak self] action in
            self?.finishLive()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(end)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func cancelInput() {
        view.endEditing(true)
    }
    
    private func setupMentionTableView() {
        mentionTableView.isHidden = true
        mentionTableView.delegate = self
        mentionTableView.dataSource = self
        mentionTableView.register(AmityMentionTableViewCell.nib, forCellReuseIdentifier: "AmityMentionTableViewCell")
    }
    
    // MARK: - IBActions
    
    @IBAction private func switchCameraButtonDidTouch() {
        switchCamera()
    }
    
    @IBAction private func selectCoverButtonDidTouch() {
        if coverImageUrl != nil {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let selectImagesAction = UIAlertAction(title: "Change cover image", style: .default) { [weak self] _ in
                self?.presentCoverImagePicker()
            }
            
            actionSheet.addAction(selectImagesAction)
            
            let removeCoverPhotoAction = UIAlertAction(title: "Remove cover image", style: .destructive) { [weak self] _ in
                // Handle removing the cover photo
                self?.coverImageUrl = nil
                self?.updateCoverImageSelection()
            }
            
            actionSheet.addAction(removeCoverPhotoAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            actionSheet.addAction(cancelAction)
            
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = selectCoverButton // Set the button that triggered the action sheet
                popoverController.sourceRect = selectCoverButton.bounds
            }
            
            present(actionSheet, animated: true, completion: nil)
            
        } else {
            self.presentCoverImagePicker()
        }
      
    }
    
    @IBAction private func closeButtonDidTouch() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func goLiveButtonDidTouch() {
        let titleCount = "\(titleTextField.text ?? "")\n\n".count
        let metadata = mentionManager.getMetadata(shift: titleCount)
        let mentionees = mentionManager.getMentionees()
        
        mentionManager.resetState()
        
        goLive(metadata: metadata, mentionees: mentionees)
    }
    
    @IBAction func finishButtonDidTouch() {
        presentEndLiveStreamConfirmationDialogue()
    }
    
}

extension LiveStreamBroadcastViewController: AmityTextViewDelegate {
    public func textViewDidChangeSelection(_ textView: AmityTextView) {
        mentionManager.changeSelection(textView)
    }
    
    public func textView(_ textView: AmityTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text?.count ?? 0 > ASCMentionManager.maximumCharacterCountForPost {
            didReachMaxCharacterCountLimit()
            return false
        }
        return mentionManager.shouldChangeTextIn(textView, inRange: range, replacementText: text, currentText: textView.text ?? "")
    }
}

extension LiveStreamBroadcastViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        switch textField {
        case titleTextField:
            return titleTextField.verifyFields(shouldChangeCharactersIn: range, replacementString: string)
            
        default:
            return true
        }
    }
    
}

extension LiveStreamBroadcastViewController: AmityVideoBroadcasterDelegate {
    public func amityVideoBroadcasterDidUpdateState(_ broadcaster: AmityLiveVideoBroadcastKit.AmityVideoBroadcaster) {
        updateStreamingStatusText()
    }
    
}

// MARK: - ASCMentionManagerDelegate
extension LiveStreamBroadcastViewController: ASCMentionManagerDelegate {
    
    public func didUpdateMentionUsers(users: [AmityUIKit.AmityMentionUserModel]) {
        if users.isEmpty {
            mentionTableViewHeightConstraint.constant = 0
            mentionTableView.isHidden = true
        } else {
            var heightConstant:CGFloat = 240.0
            if users.count < 5 {
                heightConstant = CGFloat(users.count) * 52.0
            }
            mentionTableViewHeightConstraint.constant = heightConstant
            mentionTableView.isHidden = false
            mentionTableView.reloadData()
        }
    }
    
    public func didReachMaxMentionLimit() {
        let alertController = UIAlertController(title: AmityLocalizedStringSet.Mention.unableToMentionTitle.localizedString, message: AmityLocalizedStringSet.Mention.unableToMentionReplyDescription.localizedString, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: AmityLocalizedStringSet.General.done.localizedString, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func didReachMaxCharacterCountLimit() {
        let title = "Unable to post"
        let message = "Unable message"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    public func didCreateAttributedString(attributedString: NSAttributedString) {
        descriptionTextView.attributedText = attributedString
        descriptionTextView.typingAttributes = [.font: AmityFontSet.body, .foregroundColor: UIColor.white]
    }
}

// MARK: - UITableViewDataSource
extension LiveStreamBroadcastViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mentionManager.mentionProvider.mentionList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AmityMentionTableViewCell") as? AmityMentionTableViewCell else { return UITableViewCell() }
        
        let provider = mentionManager.mentionProvider
        if indexPath.row < provider.mentionList.count {
            let model = provider.mentionList[indexPath.row]
            cell.display(with: model)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LiveStreamBroadcastViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AmityMentionTableViewCell.height
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var textInput: UITextInput = titleTextField
        var text = titleTextField.text
        if !titleTextField.isFirstResponder {
            textInput = descriptionTextView
            text = descriptionTextView.text
        }
        
        mentionManager.addMention(from: textInput, in: text ?? "", at: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            mentionManager.mentionProvider.loadMore()
        }
    }
}
