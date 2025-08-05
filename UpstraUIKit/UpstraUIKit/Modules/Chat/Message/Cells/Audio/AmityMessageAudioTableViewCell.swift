//
//  AmityMessageAudioTableViewCell.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 2/12/2563 BE.
//  Copyright © 2563 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

final class AmityMessageAudioTableViewCell: AmityMessageTableViewCell {
    
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var actionImageView: UIImageView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        durationLabel.text = "0:00"
        actionImageView.image = AmityIconSet.Chat.iconPlay
    }
    
    func setupView() {
        durationLabel.text = "0:00"
        durationLabel.font = AmityFontSet.body
        durationLabel.textAlignment = .right
        actionImageView.image = AmityIconSet.Chat.iconPlay
        
        activityIndicatorView.hidesWhenStopped = true
        
    }
    
    override func display(message: AmityMessageModel) {
        if !message.isDeleted {
            
            let attachment = message.object.getFileInfo()
            
            if message.isOwner {
                durationLabel.textColor = AmityColorSet.baseInverse
                actionImageView.tintColor = AmityColorSet.baseInverse
                activityIndicatorView.style = .medium
                switch message.syncState {
                case .syncing:
                    durationLabel.alpha = 0
                    activityIndicatorView.startAnimating()
                case .synced, .default, .error:
                    durationLabel.alpha = 1
                    activityIndicatorView.stopAnimating()
                @unknown default:
                    break
                }
            } else {
                durationLabel.textColor = AmityColorSet.base
                actionImageView.tintColor = AmityColorSet.base
                activityIndicatorView.style = .medium
            }
            
            if AmityAudioPlayer.shared.isPlaying(), AmityAudioPlayer.shared.fileName == message.messageId {
                actionImageView.image = AmityIconSet.Chat.iconPause
            } else {
                actionImageView.image = AmityIconSet.Chat.iconPlay
            }
        }
        super.display(message: message)
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        let displaynameHeight: CGFloat = message.isOwner ? 0 : 22
        if message.isDeleted {
            return AmityMessageTableViewCell.deletedMessageCellHeight + displaynameHeight
        }
        return 90 + displaynameHeight
    }
    
}

extension AmityMessageAudioTableViewCell {
    
    @IBAction func playTap(_ sender: UIButton) {
        if !message.isDeleted && message.syncState == .synced {
            sender.isEnabled = false
            
            AmityUIKitManagerInternal.shared.messageMediaService.download(for: message.object) { [weak self] in
                self?.durationLabel.alpha = 0
                self?.activityIndicatorView.startAnimating()
            } completion: { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let url):
                    self?.playAudio(fileName: strongSelf.message.messageId, path: url)
                    
                    sender.isEnabled = true
                    strongSelf.activityIndicatorView.stopAnimating()
                    strongSelf.durationLabel.alpha = 1
                case .failure(let error):
                    Log.add(error.localizedDescription)
                }
            }
        }
    }
    
    func playAudio(fileName: String, path: URL) {
        AmityAudioPlayer.shared.stop()
        AmityAudioPlayer.shared.fileName = fileName
        AmityAudioPlayer.shared.path = path
        
        AmityAudioPlayer.shared.onPlay = { [weak self] in
            guard let self else { return }
            actionImageView.image = AmityIconSet.Chat.iconPause
            delegate?.performEvent(self, events: .audioPlaying)
        }
        
        AmityAudioPlayer.shared.onStop = { [weak self] in
            self?.actionImageView.image = AmityIconSet.Chat.iconPlay
            self?.durationLabel.text = "0:00"
        }
        
        AmityAudioPlayer.shared.onFinish = { [weak self] in
            self?.actionImageView.image = AmityIconSet.Chat.iconPlay
            self?.durationLabel.text = "0:00"
        }
        
        AmityAudioPlayer.shared.onDurationChange = { [weak self] duration in
            self?.durationLabel.text = duration
        }
        
        AmityAudioPlayer.shared.play()
    }
}
