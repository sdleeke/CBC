//
//  MediaTableViewCell.swift
//  TWU
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
//    var downloadObserver:Timer?

    weak var vc:UIViewController?
    
    @IBOutlet weak var countLabel: UILabel!
    
    func clear()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:clear")
            return
        }
        
        self.title.attributedText = nil
        self.detail.attributedText = nil
    }
    
    func hideUI()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:hideUI")
            return
        }
        
        isHiddenUI(true)
        
        downloadProgressBar.isHidden = true
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI")
            return
        }
        
        title.isHidden = state
        detail.isHidden = state
        
        icons.isHidden = state
    }
    
    func setupText()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupText")
            return
        }
        
        clear()

        guard let mediaItem = mediaItem else {
            return
        }
        
        let titleString = NSMutableAttributedString()
        
        if mediaItem.searchHit(searchText).formattedDate, let formattedDate = mediaItem.formattedDate {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = formattedDate.lowercased().range(of: searchText.lowercased()) {
                before = formattedDate.substring(to: range.lowerBound)
                string = formattedDate.substring(with: range)
                after = formattedDate.substring(from: range.upperBound)
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if let formattedDate = mediaItem.formattedDate {
                titleString.append(NSAttributedString(string:formattedDate, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        if let service = mediaItem.service {
            titleString.append(NSAttributedString(string: service, attributes: Constants.Fonts.Attributes.normal))
        }
        
        if mediaItem.hasSpeaker, mediaItem.searchHit(searchText).speaker, let speaker = mediaItem.speaker {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = speaker.lowercased().range(of: searchText.lowercased()) {
                before = speaker.substring(to: range.lowerBound)
                string = speaker.substring(with: range)
                after = speaker.substring(from: range.upperBound)
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            if mediaItem.hasSpeaker, let speaker = mediaItem.speaker {
                titleString.append(NSAttributedString(string:speaker, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        self.title.attributedText = titleString
        
        let detailString = NSMutableAttributedString()
        
        var title:String?
        
        if searchText == nil,
            let string = mediaItem.title,
            let rangeTo = string.range(of: " (Part"),
            let rangeFrom = string.range(of: " (Part ") {
            // This causes searching for "(Part " to present a blank title.
            let first = string.substring(to: rangeTo.upperBound)
            let second = string.substring(from: rangeFrom.upperBound)
            title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
        } else {
            title = mediaItem.title
        }
        
        if mediaItem.searchHit(searchText).title {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = title?.lowercased().range(of: searchText.lowercased()) {
                before = title?.substring(to: range.lowerBound)
                string = title?.substring(with: range)
                after = title?.substring(from: range.upperBound)
                
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.bold))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.boldHighlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.bold))
                }
            }
        } else {
            if let title = title, !title.isEmpty {
                detailString.append(NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold))
            }
        }
        
        if mediaItem.searchHit(searchText).scriptureReference, let scriptureReference = mediaItem.scriptureReference {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = scriptureReference.lowercased().range(of: searchText.lowercased()) {
                before = scriptureReference.substring(to: range.lowerBound)
                string = scriptureReference.substring(with: range)
                after = scriptureReference.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if let scriptureReference = mediaItem.scriptureReference {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: scriptureReference,   attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem.hasClassName, mediaItem.searchHit(searchText).className {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = mediaItem.className?.lowercased().range(of: searchText.lowercased()) {
                before = mediaItem.className?.substring(to: range.lowerBound)
                string = mediaItem.className?.substring(with: range)
                after = mediaItem.className?.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if mediaItem.hasClassName, let className = mediaItem.className {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: className, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem.hasEventName, mediaItem.searchHit(searchText).eventName {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = mediaItem.eventName?.lowercased().range(of: searchText.lowercased()) {
                before = mediaItem.eventName?.substring(to: range.lowerBound)
                string = mediaItem.eventName?.substring(with: range)
                after = mediaItem.eventName?.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: eventName, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        self.detail.attributedText = detailString

//        if var rect = icons.attributedText?.boundingRect(with: self.bounds.size, options: .usesLineFragmentOrigin, context: nil) {
//            rect.origin = icons.frame.origin
//            rect = self.convert(rect, to: detailText)
//            let path = UIBezierPath(rect: rect)
//            self.detailText.textContainer.exclusionPaths = [path]
//        }
//        self.detailText.backgroundColor = UIColor.clear
//        self.detailText.textAlignment = .left
//        self.detailText.textContainer.lineBreakMode = .byWordWrapping
//        self.detailText.textContainer.maximumNumberOfLines = 4
//        self.detailText.attributedText = detailString
    }
    
    func stopEditing()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:stopEditing")
            return
        }
        
        if isEditing {
            // tableView.isEditing must be done on the main thread.
            (vc as? MediaTableViewController)?.tableView.isEditing = false
            (vc as? MediaViewController)?.tableView.isEditing = false
        }
    }
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:updateUI")
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
                Thread.onMainThread() {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: oldValue)
                }
            }
            
            if (mediaItem != nil) {
                Thread.onMainThread() {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
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
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        let attrString = NSMutableAttributedString()
        
        if (globals.mediaPlayer.mediaItem == mediaItem) {
            if let state = globals.mediaPlayer.state {
                switch state {
                case .paused:
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAY, attributes: Constants.FA.Fonts.Attributes.icons))
                    break
                    
                case .playing:
                    if globals.mediaPlayer.url == globals.mediaPlayer.mediaItem?.playingURL {
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
            if (globals.search.transcripts || ((vc as? LexiconIndexViewController) != nil)) && mediaItem.searchHit(searchText).transcriptHTML {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
            } else {
                //                    print(searchText!)
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
        
        if mediaItem.hasAudio, mediaItem.audioDownload?.isDownloaded == true {
        }
        
        self.icons.attributedText = attrString
        
//        if let searchText = searchText {
//           
//        } else {
//            self.icons.attributedText = nil
//
//            var string = String()
//            
//            if (globals.mediaPlayer.mediaItem == mediaItem) {
//                if let state = globals.mediaPlayer.state {
//                    switch state {
//                    case .paused:
//                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAY
//                        break
//                        
//                    case .playing:
//                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAYING
//                        break
//                        
//                    case .stopped:
//                        break
//                        
//                    case .none:
//                        break
//                        
//                    default:
//                        break
//                    }
//                }
//            }
//
//            if mediaItem.hasTags {
//                if (mediaItem.tagsSet?.count > 1) {
//                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAGS
//                } else {
//                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAG
//                }
//            }
//            
//            if mediaItem.hasNotes {
//                string = string + Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT
//            }
//            
//            if mediaItem.hasSlides {
//                string = string + Constants.SINGLE_SPACE + Constants.FA.SLIDES
//            }
//            
//            if mediaItem.hasVideo {
//                string = string + Constants.SINGLE_SPACE + Constants.FA.VIDEO
//            }
//            
//            if mediaItem.hasAudio {
//                string = string + Constants.SINGLE_SPACE + Constants.FA.AUDIO
//            }
//            
//            if mediaItem.hasAudio, let state = mediaItem.audioDownload?.state {
//                switch state {
//                case .none:
//                    break
//                    
//                case .downloaded:
//                    string = string + Constants.SINGLE_SPACE + Constants.FA.DOWNLOADED
//                    break
//                    
//                case .downloading:
//                    string = string + Constants.SINGLE_SPACE + Constants.FA.DOWNLOADING
//                    break
//                }
//            }
//            
//            self.icons.text = string
//        }
    }
    
    func setupProgressBarForAudio()
    {
        guard Thread.isMainThread else {
            globals.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupProgressBarForAudio")
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
