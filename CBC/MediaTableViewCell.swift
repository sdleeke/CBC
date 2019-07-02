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

/**
 Cell that displays a mediaItem
 */
class MediaTableViewCell: UITableViewCell
{
    deinit {
        debug(self)
    }
    
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
            titleString.append(NSAttributedString(string: service, attributes: Constants.Fonts.Attributes.body))
        }
        
        if mediaItem.hasSpeaker, let speaker = mediaItem.speaker?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            titleString.append(speaker)
        }
        
        let detailString = NSMutableAttributedString()
        
        var title:String?
        
        var partFound = false
        for partPreamble in Constants.PART_PREAMBLES {
            if searchText == nil,
                let string = mediaItem.title,
                let rangeTo = string.range(of: partPreamble + Constants.PART_INDICATOR),
                let rangeFrom = string.range(of: partPreamble + Constants.PART_INDICATOR) {
                // This causes searching for "(Part " to present a blank title.
                let first = String(string[..<rangeTo.upperBound])
                let second = String(string[rangeFrom.upperBound...])
                title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                partFound = true
                break
            }
        }
        
        if !partFound {
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

        if let category = mediaItem.category, category != Globals.shared.media.category.selected {
            if !detailString.string.isEmpty {
                detailString.append(NSAttributedString(string: "\n"))
            }
            detailString.append(NSAttributedString(string: category))
        }

        self.title.attributedText = titleString
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
    
    //    var overlay = [String:UIProgressView]()
    
    var percentComplete : [String:Double]?
    {
        get {
            guard let percentComplete = mediaItem?.percentComplete, percentComplete.values.count > 0 else {
                return nil
            }
            
            return percentComplete
        }
    }

    var max : Double?
    {
        get {
            guard let values = self.percentComplete?.values, values.count > 0 else {
                return nil
            }

            var max = 0.0

            values.forEach { (value:Double) in
                if value > max {
                    max = value
                }
            }

            return max
        }
    }

    @objc func percentComplete(_ notification : NSNotification)
    {
        guard let mediaItem = notification.object as? MediaItem, self.mediaItem == mediaItem else {
            return
        }
        
//        guard let percentComplete = mediaItem.percentComplete else {
//            downloadProgressBar.isHidden = true
//            downloadProgressBar.progress = 0
//            return
//        }
        
        downloadProgressBar.isHidden = max == nil
        downloadProgressBar.progress = Float(max ?? 0)
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
        
        downloadProgressBar.isHidden = self.percentComplete == nil
        
//        if let values = mediaItem?.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
//            transcript.percentComplete != nil
//        }), values.count > 0 {
//            let transcripts = Array(values)
////            var count = 1
//            for transcript in transcripts {
//                if let purpose = transcript.purpose, let percentComplete = transcript.percentComplete, var factor = Double(percentComplete) {
////                    overlay[purpose]?.removeFromSuperview()
//
//                    factor /= 100.0
//
//                    transcriptWorking = true
//                    downloadProgressBar.isHidden = false
//                    downloadProgressBar.progress = Float(factor)
//
////                    overlay[purpose] = UIProgressView()
////
////                    let frame = downloadProgressBar.frame
////                    overlay[purpose]?.frame = frame
////                    overlay[purpose]?.frame.origin.y -= CGFloat(count) * frame.height
////
////                    //  * CGFloat(factor)
////
////                    overlay[purpose]?.progress = Float(factor)
////
////                    switch purpose {
////                    case Purpose.audio:
//////                        overlay[purpose]?.backgroundColor = UIColor.lightGray
////                        break
////
////                    case Purpose.video:
//////                        overlay[purpose]?.backgroundColor = UIColor.darkGray
////                        break
////
////                    default:
//////                        overlay[purpose]?.backgroundColor = UIColor.lightGray
////                        break
////                    }
////
//////                    overlay[purpose]?.alpha = 0.35
////
////                    if let overlay = overlay[purpose] {
////                        self.addSubview(overlay)
////                    }
//                }
////                count += 1
//            }
//        } else {
//            transcriptWorking = false
//            downloadProgressBar.isHidden = true
//            downloadProgressBar.progress = 0
//
////            overlay.values.forEach({ (view:UIView) in
////                view.removeFromSuperview()
////            })
//        }
        
//        setupProgressBarForAudio()
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
//            if mediaItem != oldValue {
//                percentComplete = nil
//            }
            
            if (oldValue != nil) {
                Thread.onMain {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PERCENT_COMPLETE), object: oldValue)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: oldValue)
                }
            }
            
            if (mediaItem != nil) {
                Thread.onMain {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.percentComplete(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PERCENT_COMPLETE), object: self.mediaItem)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
                }
            }

//            overlay.values.forEach({ (view:UIView) in
//                view.removeFromSuperview()
//            })
            
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
                if Globals.shared.media.search.transcripts.value == true, Globals.shared.media.search.isActive {
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
                    
                    // Add the count
                    DispatchQueue.global(qos: .userInteractive).async {
                        if let count = mediaItem.notesTokens?.result?[searchText] {
                            Thread.onMain {
                                // Make sure we're still in the right place.
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
        
        if mediaItem.hasOutline {
            attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.OUTLINE, attributes: Constants.FA.Fonts.Attributes.icons))
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
    
//    var transcriptWorking = false
    
//    func setupProgressBarForAudio()
//    {
//        guard Thread.isMainThread else {
//            Alerts.shared.alert(title: "Not Main Thread", message: "MediaTableViewCell:setupProgressBarForAudio")
//            return
//        }
//
//        guard let download = mediaItem?.audioDownload else {
//            return
//        }
//
//        switch download.state {
//        case .none:
//            self.downloadProgressBar.isHidden = true
//            self.downloadProgressBar.progress = 0
////            if !transcriptWorking {
////            }
//            break
//
//        case .downloaded:
//            self.downloadProgressBar.isHidden = true
//            self.downloadProgressBar.progress = 1
////            if !transcriptWorking {
////            }
//            break
//
//        case .downloading:
//            self.downloadProgressBar.isHidden = false
//            if (download.totalBytesExpectedToWrite > 0) {
//                self.downloadProgressBar.progress = Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite)
//            } else {
//                self.downloadProgressBar.progress = 0
//            }
//            break
//        }
//    }
    
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
