//
//  MediaTableViewCell.swift
//  CBC
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

extension MediaTableViewCell : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
}

extension MediaTableViewCell : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class MediaTableViewCell: UITableViewCell
{
    weak var vc:UIViewController?
    
    @IBOutlet weak var countLabel: UILabel!
    
    func clear()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:clear")
            return
        }
        
        self.title.attributedText = nil
        self.detail.attributedText = nil
    }
    
    func hideUI()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:hideUI")
            return
        }
        
        isHiddenUI(true)
        
        downloadProgressBar.isHidden = true
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI")
            return
        }
        
        title.isHidden = state
        detail.isHidden = state
        
        icons.isHidden = state
    }
    
    func setupText()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupText")
            return
        }
        
        clear()

        guard let mediaItem = mediaItem else {
            return
        }
        
        let titleString = NSMutableAttributedString()
        
        if let formattedDate = mediaItem.formattedDate?.highlighted(searchText) {
            titleString.append(formattedDate)
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        if let service = mediaItem.service {
            titleString.append(NSAttributedString(string: service, attributes: Constants.Fonts.Attributes.normal))
        }
        
        if mediaItem.hasSpeaker, let speaker = mediaItem.speaker?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            titleString.append(speaker)
        }
        
        self.title.attributedText = titleString
        
        let detailString = NSMutableAttributedString()
        
        var title:String?
        
        if searchText == nil,
            let string = mediaItem.title,
            let rangeTo = string.range(of: " (Part"),
            let rangeFrom = string.range(of: " (Part ") {
            // This causes searching for "(Part " to present a blank title.
            let first = String(string[..<rangeTo.upperBound])
            let second = String(string[rangeFrom.upperBound...])
            title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
        } else {
            title = mediaItem.title
        }
        
        if let title = title?.boldHighlighted(searchText) {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            
            detailString.append(title)
        }
        
        if let scriptureReference = mediaItem.scriptureReference?.highlighted(searchText) {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            
            detailString.append(scriptureReference)
        }
        
        if mediaItem.hasClassName, let className = mediaItem.className?.highlighted(searchText) {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            detailString.append(className)
        }
        
        if mediaItem.hasEventName, let eventName = mediaItem.eventName?.highlighted(searchText) {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            detailString.append(eventName)
        }

        if let category = mediaItem.category, category != Globals.shared.mediaCategory.selected {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            detailString.append(NSAttributedString(string: category))
        }

        self.detail.attributedText = detailString
    }
    
    @objc func stopEditing()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:stopEditing")
            return
        }
        
        if isEditing {
            // tableView.isEditing must be done on the main thread.
            (vc as? MediaTableViewController)?.tableView.isEditing = false
            (vc as? MediaViewController)?.tableView.isEditing = false
        }
    }
    
    @objc func updateUI()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:updateUI")
            return
        }
        
        guard (mediaItem != nil) else {
            isHiddenUI(true)
            print("No mediaItem for cell!")
            return
        }

        if (detail.text != nil) || (detail.attributedText != nil) {
            isHiddenUI(false)
        }
        
        setupProgressBarForAudio()

        setupIcons()

        setupText()
    }
    
    var searchText:String?
    {
        willSet {
            
        }
        didSet {
            updateUI()
        }
    }
    
    var mediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if (oldValue != nil) {
                Thread.onMainThread {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: oldValue)
                }
            }
            
            if (mediaItem != nil) {
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
                }
            }
            
            updateUI()
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var detailText: UITextView!
    @IBOutlet weak var icons: UILabel!
    
    func setupIcons()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        let attrString = NSMutableAttributedString()
        
        if (Globals.shared.mediaPlayer.mediaItem == mediaItem) {
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .paused:
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAY, attributes: Constants.FA.Fonts.Attributes.icons))
                    break
                    
                case .playing:
                    if Globals.shared.mediaPlayer.url == Globals.shared.mediaPlayer.mediaItem?.playingURL {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAYING, attributes: Constants.FA.Fonts.Attributes.icons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAY, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                    break
                    
                case .stopped:
                    break
                    
                case .none:
                    break
                    
                default:
                    break
                }
            }
        }
        
        if mediaItem.hasTags {
            if (mediaItem.tagsSet?.count > 1) {
                if mediaItem.searchHit(searchText).tags {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                } else {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.icons))
                }
            } else {
                if mediaItem.searchHit(searchText).tags {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                } else {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.icons))
                }
            }
        }
        
        if mediaItem.hasNotes {
            if (vc as? MediaTableViewController) != nil {
                if Globals.shared.search.transcripts, Globals.shared.search.active {
                    if mediaItem.searchHit(self.searchText).transcript {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                } else {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.icons))
                }
            } else
            
            if (vc as? LexiconIndexViewController) != nil {
                if let searchText = self.searchText {
                    if mediaItem.searchHit(searchText).transcript {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                    
                    DispatchQueue.global(qos: .userInteractive).async {
                        if let count = mediaItem.notesTokens?.result?[searchText] {
                            Thread.onMainThread {
                                if self.mediaItem == mediaItem {
                                    self.countLabel.text = count.description
                                }
                            }
                        }
                    }
                }
            } else {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.icons))
            }
        }
        
        if mediaItem.hasSlides {
            attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.SLIDES, attributes: Constants.FA.Fonts.Attributes.icons))
        }
        
        if mediaItem.hasVideo {
            attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: Constants.FA.Fonts.Attributes.icons))
        }
        
        if mediaItem.hasAudio {
            attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: Constants.FA.Fonts.Attributes.icons))
        }
        
        if mediaItem.hasAudio, let state = mediaItem.audioDownload?.state {
            switch state {
            case .none:
                break
                
            case .downloaded:
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.DOWNLOADED, attributes: Constants.FA.Fonts.Attributes.icons))
                break
                
            case .downloading:
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.DOWNLOADING, attributes: Constants.FA.Fonts.Attributes.icons))
                break
            }
        }
        
        if mediaItem.hasAudio, mediaItem.audioDownload?.exists == true {
        }
        
        self.icons.attributedText = attrString
    }
    
    func setupProgressBarForAudio()
    {
        guard Thread.isMainThread else {
            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupProgressBarForAudio")
            return
        }
        
        guard let download = mediaItem?.audioDownload else {
            return
        }
        
        switch download.state {
        case .none:
            self.downloadProgressBar.isHidden = true
            self.downloadProgressBar.progress = 0
            break
            
        case .downloaded:
            self.downloadProgressBar.isHidden = true
            self.downloadProgressBar.progress = 1
            break
            
        case .downloading:
            self.downloadProgressBar.isHidden = false
            if (download.totalBytesExpectedToWrite > 0) {
                self.downloadProgressBar.progress = Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite)
            } else {
                self.downloadProgressBar.progress = 0
            }
            break
        }
    }
    
    @IBOutlet weak var downloadProgressBar: UIProgressView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
