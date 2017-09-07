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
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:clear", completion: nil)
            return
        }
        
        self.title.attributedText = nil
        self.detail.attributedText = nil
    }
    
    func hideUI()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:hideUI", completion: nil)
            return
        }
        
        isHiddenUI(true)
        
        downloadProgressBar.isHidden = true
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI", completion: nil)
            return
        }
        
        title.isHidden = state
        detail.isHidden = state
        
        icons.isHidden = state
        
        downloadButton.isHidden = state
        
        if (tagsButton != nil) {
            tagsButton.isHidden = state
        }
    }
    
    func updateDownloadButton()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:updateDownloadButton", completion: nil)
            return
        }
        
        guard (mediaItem?.audioDownload != nil) else {
            return
        }
        
        guard (downloadButton != nil) else {
            return
        }
        
        guard let hasAudio = mediaItem?.hasAudio, hasAudio else {
            downloadButton.isHidden = true
            return
        }
        
        switch self.mediaItem!.audioDownload!.state {
        case .none:
            self.downloadButton.setTitle(Constants.FA.DOWNLOAD, for: UIControlState.normal)
            break
            
        case .downloaded:
            self.downloadButton.setTitle(Constants.FA.DOWNLOADED, for: UIControlState.normal)
            break
            
        case .downloading:
            self.downloadButton.setTitle(Constants.FA.DOWNLOADING, for: UIControlState.normal)
            break
        }
    }
    
    func setupText()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:setupText", completion: nil)
            return
        }
        
        clear()

        let titleString = NSMutableAttributedString()
        
        if let searchHit = mediaItem?.searchHit(searchText).formattedDate, searchHit, let formattedDate = mediaItem?.formattedDate {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = formattedDate.lowercased().range(of: searchText!.lowercased()) {
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
            titleString.append(NSAttributedString(string:mediaItem!.formattedDate!, attributes: Constants.Fonts.Attributes.normal))
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        titleString.append(NSAttributedString(string: mediaItem!.service!, attributes: Constants.Fonts.Attributes.normal))
        
        if let searchHit = mediaItem?.searchHit(searchText).speaker, searchHit, let speaker = mediaItem?.speaker {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = speaker.lowercased().range(of: searchText!.lowercased()) {
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
            titleString.append(NSAttributedString(string:mediaItem!.speaker!, attributes: Constants.Fonts.Attributes.normal))
        }
        
        self.title.attributedText = titleString // NSAttributedString(string: "\(mediaItem!.formattedDate!) \(mediaItem!.service!) \(mediaItem!.speaker!)", attributes: normal)
        
        let detailString = NSMutableAttributedString()
        
        var title:String?
        
        if (searchText == nil) && (mediaItem?.title?.range(of: " (Part ") != nil) {
            // This causes searching for "(Part " to present a blank title.
            let first = mediaItem!.title!.substring(to: (mediaItem!.title!.range(of: " (Part")?.upperBound)!)
            let second = mediaItem!.title!.substring(from: (mediaItem!.title!.range(of: " (Part ")?.upperBound)!)
            title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
        } else {
            title = mediaItem?.title
        }
        
        if let searchHit = mediaItem?.searchHit(searchText).title, searchHit {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = title?.lowercased().range(of: searchText!.lowercased()) {
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
            if let title = title {
                detailString.append(NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold))
            }
        }
        
        if let searchHit = mediaItem?.searchHit(searchText).scriptureReference, searchHit, let scriptureReference = mediaItem?.scriptureReference {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = scriptureReference.lowercased().range(of: searchText!.lowercased()) {
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
            if let scriptureReference = mediaItem?.scriptureReference {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: scriptureReference,   attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem!.searchHit(searchText).className {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = mediaItem?.className?.lowercased().range(of: searchText!.lowercased()) {
                before = mediaItem?.className?.substring(to: range.lowerBound)
                string = mediaItem?.className?.substring(with: range)
                after = mediaItem?.className?.substring(from: range.upperBound)
                
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
            if let className = mediaItem?.className {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: className, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem!.searchHit(searchText).eventName {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = mediaItem?.eventName?.lowercased().range(of: searchText!.lowercased()) {
                before = mediaItem?.eventName?.substring(to: range.lowerBound)
                string = mediaItem?.eventName?.substring(with: range)
                after = mediaItem?.eventName?.substring(from: range.upperBound)
                
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
            if let eventName = mediaItem?.eventName {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: eventName, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        self.detail.attributedText = detailString
    }
    
    func stopEditing()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:stopEditing", completion: nil)
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
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:updateUI", completion: nil)
            return
        }
        
        guard (mediaItem != nil) else {
            isHiddenUI(true)
            print("No mediaItem for cell!")
            return
        }

        if isEditing {
            // tableView.isEditing must be done on the main thread.
            (vc as? MediaTableViewController)?.tableView?.isEditing = false
            (vc as? MediaViewController)?.tableView.isEditing = false
        }

        if (detail.text != nil) || (detail.attributedText != nil) {
            isHiddenUI(false)
        }

        updateTagsButton()
        
        updateDownloadButton()
        
        setupProgressBarForAudio()

        setupIcons()

        setupText()
    }
    
    var searchText:String? {
        willSet {
            
        }
        didSet {
            updateUI()
        }
    }
    
    var mediaItem:MediaItem? {
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
            
            if tagsToolbar == nil {
                setupTagsToolbar()
            }
            
            if downloadToolbar == nil {
                setupDownloadButtonToolbar()
            }
            
            updateUI()
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var icons: UILabel!
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBAction func downloadAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:downloadAction", completion: nil)
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }
        
        guard !self.isEditing else {
            return
        }
        
//        print("Download!")
        
        if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            vc?.dismiss(animated: true, completion: nil)
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.delegate = self
            
            if let barButtonItem = downloadToolbar?.items?.first {
                navigationController.popoverPresentationController?.barButtonItem = barButtonItem
            } else {
                navigationController.popoverPresentationController?.sourceView = self
                navigationController.popoverPresentationController?.sourceRect = downloadButton.frame
            }
            
            //                        popover.navigationItem.title = Constants.Actions
            
//            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self.vc as? PopoverTableViewControllerDelegate
            popover.purpose = .selectingCellAction
            
            popover.selectedMediaItem = mediaItem
            
            var strings = [String]()
            
            if mediaItem!.hasAudio {
                switch mediaItem!.audioDownload!.state {
                case .none:
                    strings.append(Constants.Strings.Download_Audio)
                    break
                    
                case .downloading:
                    strings.append(Constants.Strings.Cancel_Audio_Download)
                    break
                case .downloaded:
                    strings.append(Constants.Strings.Delete_Audio_Download)
                    break
                }
            }
            
            popover.section.strings = strings
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = vc
            
            vc?.present(navigationController, animated: true, completion: nil)
        }
        
        updateUI()
    }
    
    @IBOutlet weak var tagsButton: UIButton!
    @IBAction func tagsAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:tagsAction", completion: nil)
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }
        
        guard mediaItem!.hasTags else {
            return
        }
        
        guard !self.isEditing else {
            return
        }
        
        if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            vc?.dismiss(animated: true, completion: nil)
            
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.delegate = self
            
            if let barButtonItem = tagsToolbar?.items?.first {
                navigationController.popoverPresentationController?.barButtonItem = barButtonItem
            } else {
                navigationController.popoverPresentationController?.sourceView = self
                navigationController.popoverPresentationController?.sourceRect = tagsButton.frame
            }
            
            popover.navigationItem.title = Constants.Strings.Show // Show MediaItems Tagged With
            
            popover.delegate = self.vc as? MediaTableViewController
            popover.purpose = .selectingTags
            
            popover.section.strings = mediaItem!.tagsArray
            popover.section.strings?.insert(Constants.Strings.All,at: 0)
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = vc

            vc?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func addSubview(_ view: UIView)
    {
        super.addSubview(view)
        
        let buttonFont = UIFont(name: Constants.FA.name, size: Constants.FA.ACTION_ICONS_FONT_SIZE)
        let confirmationClass: AnyClass = NSClassFromString("UITableViewCellDeleteConfirmationView")!
        
        // replace default font in swipe buttons
        let s = subviews.flatMap({$0}).filter { $0.isKind(of: confirmationClass) }
        
        for sub in s {
            for button in sub.subviews {
                if let b = button as? UIButton {
                    b.titleLabel?.font = buttonFont
                }
            }
        }
    }

    func updateTagsButton()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:updateTagsButton", completion: nil)
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }
        
        guard (tagsButton != nil) else {
            return
        }
        
        self.tagsButton.isHidden = !self.mediaItem!.hasTags
        self.tagsButton.isEnabled = globals.search.complete
        
        if (self.mediaItem!.hasTags) {
            if (self.mediaItem?.self.tagsSet?.count > 1) {
                self.tagsButton.setTitle(Constants.FA.TAGS, for: UIControlState.normal)
            } else {
                self.tagsButton.setTitle(Constants.FA.TAG, for: UIControlState.normal)
            }
        } else {
            self.tagsButton.isHidden = true
        }
    }
    
    func setupTagsToolbar()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:setupTagsToolbar", completion: nil)
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }
        
        guard (tagsButton != nil) else {
            return
        }

        self.tagsToolbar = UIToolbar(frame: self.tagsButton.frame)
        self.tagsToolbar?.setItems([UIBarButtonItem(title: nil, style: .plain, target: self, action: nil)], animated: false)
        self.tagsToolbar?.isHidden = true
        
        self.tagsToolbar?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        self.addSubview(self.tagsToolbar!)
        
        let first = self.tagsToolbar
        let second = self.tagsButton
        
        let centerX = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        self.addConstraint(centerY)
        
        //        let width = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        //        self.addConstraint(width)
        //
        //        let height = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        //        self.addConstraint(height)
        
        self.setNeedsLayout()
    }
    
    func setupDownloadButtonToolbar()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:setupDownloadButtonToolbar", completion: nil)
            return
        }
        
        guard (mediaItem?.audioDownload != nil) else {
            return
        }

        guard (downloadButton != nil) else {
            return
        }
        
        self.downloadToolbar = UIToolbar(frame: self.downloadButton.frame)
        self.downloadToolbar?.setItems([UIBarButtonItem(title: nil, style: .plain, target: self, action: nil)], animated: false)
        self.downloadToolbar?.isHidden = true
        
        self.downloadToolbar?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        self.addSubview(self.downloadToolbar!)
        
        let first = self.downloadToolbar
        let second = self.downloadButton
        
        let centerX = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        self.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        self.addConstraint(centerY)
        
        self.setNeedsLayout()
    }
    
    var tagsToolbar: UIToolbar?
    
    var downloadToolbar: UIToolbar?
    
    func setupIcons()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:setupIcons", completion: nil)
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        if (searchText != nil) {
            let attrString = NSMutableAttributedString()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) {
                if let state = globals.mediaPlayer.state {
                    switch state {
                    case .paused:
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAY, attributes: Constants.FA.Fonts.Attributes.icons))
                        break
                        
                    case .playing:
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAYING, attributes: Constants.FA.Fonts.Attributes.icons))
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
            
            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                } else {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                }
            }

            if (mediaItem!.hasNotes) {
                if (globals.search.transcripts || ((vc as? LexiconIndexViewController) != nil)) && mediaItem!.searchHit(searchText).transcriptHTML {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                } else {
//                    print(searchText!)
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.FA.Fonts.Attributes.icons))
                }
            }
            
            if (mediaItem!.hasSlides) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.SLIDES, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            if (mediaItem!.hasVideo) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            if (mediaItem!.hasAudio) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            self.icons.attributedText = attrString
        } else {
            var string = String()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) {
                if let state = globals.mediaPlayer.state {
                    switch state {
                    case .paused:
                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAY
                        break
                        
                    case .playing:
                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAYING
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

            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAGS
                } else {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAG
                }
            }
            
            if (mediaItem!.hasNotes) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT
            }
            
            if (mediaItem!.hasSlides) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.SLIDES
            }
            
            if (mediaItem!.hasVideo) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.VIDEO
            }
            
            if (mediaItem!.hasAudio) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.AUDIO
            }
            
            self.icons.text = string
        }
    }
    
    func setupProgressBarForAudio()
    {
        guard Thread.isMainThread else {
            alert(viewController:vc!,title: "Not Main Thread", message: "MediaTableViewCell:setupProgressBarForAudio", completion: nil)
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
