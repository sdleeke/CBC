//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell, UIPopoverPresentationControllerDelegate {

//    var downloadObserver:Timer?

    weak var vc:UIViewController?
    
    override func willTransition(to state: UITableViewCellStateMask)
    {
        switch state.rawValue {
        case 2:
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.EDITING), object: nil)
            })
            break
        
        default:
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_EDITING), object: nil)
            })
            break
        }
        
//        print(state.rawValue)
    }
    
    func isHiddenUI(_ state:Bool)
    {
        func set(_ state:Bool)
        {
            title.isHidden = state
            detail.isHidden = state
            
            icons.isHidden = state
            
            downloadButton.isHidden = state
            
            if (tagsButton != nil) {
                tagsButton.isHidden = state
            }
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            set(state)
        })
    }
    
    func updateUI()
    {
        guard (mediaItem != nil) else {
            isHiddenUI(true)
            print("No mediaItem for cell!")
            return
        }

        updateTagsButton()
        
        setupProgressBarForAudio()

        setupIcons()

        if globals.search.active && !globals.search.lexicon && ((vc as? MediaTableViewController) != nil) {
            let titleString = NSMutableAttributedString()
            
            let normal = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body) ]
            
            let bold = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline) ]
            
            let highlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
                                NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body) ]
            
            let boldHighlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
                                NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline) ]
            
            if let searchHit = mediaItem?.searchHit?.formattedDate, searchHit, let formattedDate = mediaItem?.formattedDate {
                var string:String?
                var before:String?
                var after:String?
                
                if let range = formattedDate.lowercased().range(of: globals.search.text!.lowercased()) {
                    before = formattedDate.substring(to: range.lowerBound)
                    string = formattedDate.substring(with: range)
                    after = formattedDate.substring(from: range.upperBound)
                    
                    if let before = before {
                        titleString.append(NSAttributedString(string: before,   attributes: bold))
                    }
                    if let string = string {
                        titleString.append(NSAttributedString(string: string,   attributes: boldHighlighted))
                    }
                    if let after = after {
                        titleString.append(NSAttributedString(string: after,   attributes: bold))
                    }
                }
            } else {
                titleString.append(NSAttributedString(string:mediaItem!.formattedDate!, attributes: bold))
            }
            
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            titleString.append(NSAttributedString(string: mediaItem!.service!, attributes: bold))

            if let searchHit = mediaItem?.searchHit?.speaker, searchHit, let speaker = mediaItem?.speaker {
                var string:String?
                var before:String?
                var after:String?
                
                if let range = speaker.lowercased().range(of: globals.search.text!.lowercased()) {
                    before = speaker.substring(to: range.lowerBound)
                    string = speaker.substring(with: range)
                    after = speaker.substring(from: range.upperBound)
                    
                    if !titleString.string.isEmpty {
                        titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
                    }

                    if let before = before {
                        titleString.append(NSAttributedString(string: before,   attributes: bold))
                    }
                    if let string = string {
                        titleString.append(NSAttributedString(string: string,   attributes: boldHighlighted))
                    }
                    if let after = after {
                        titleString.append(NSAttributedString(string: after,   attributes: bold))
                    }
                }
            } else {
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
                }
                titleString.append(NSAttributedString(string:mediaItem!.speaker!, attributes: bold))
            }

            DispatchQueue.main.async {
//                print(titleString.string)
                self.title.attributedText = titleString // NSAttributedString(string: "\(mediaItem!.formattedDate!) \(mediaItem!.service!) \(mediaItem!.speaker!)", attributes: normal)
            }
            
            let detailString = NSMutableAttributedString()
            
            var title:String?
            
            if (mediaItem?.title?.range(of: " (Part ") != nil) {
                let first = mediaItem!.title!.substring(to: (mediaItem!.title!.range(of: " (Part")?.upperBound)!)
                let second = mediaItem!.title!.substring(from: (mediaItem!.title!.range(of: " (Part ")?.upperBound)!)
                title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
            } else {
                title = mediaItem?.title
            }

            if let searchHit = mediaItem?.searchHit?.title, searchHit {
                var string:String?
                var before:String?
                var after:String?
                
                if let range = title?.lowercased().range(of: globals.search.text!.lowercased()) {
                    before = title?.substring(to: range.lowerBound)
                    string = title?.substring(with: range)
                    after = title?.substring(from: range.upperBound)
                    
                    if let before = before {
                        detailString.append(NSAttributedString(string: before,   attributes: normal))
                    }
                    if let string = string {
                        detailString.append(NSAttributedString(string: string,   attributes: highlighted))
                    }
                    if let after = after {
                        detailString.append(NSAttributedString(string: after,   attributes: normal))
                    }
                }
            } else {
                if let title = title {
                    detailString.append(NSAttributedString(string: title,   attributes: normal))
                }
            }
            
            if let searchHit = mediaItem?.searchHit?.scriptureReference, searchHit, let scriptureReference = mediaItem?.scriptureReference {
                var string:String?
                var before:String?
                var after:String?
                
                if let range = scriptureReference.lowercased().range(of: globals.search.text!.lowercased()) {
                    before = scriptureReference.substring(to: range.lowerBound)
                    string = scriptureReference.substring(with: range)
                    after = scriptureReference.substring(from: range.upperBound)
                    
                    if !detailString.string.isEmpty {
                        detailString.append(NSAttributedString(string: "\n"))
                    }
                    if let before = before {
                        detailString.append(NSAttributedString(string: before,   attributes: normal))
                    }
                    if let string = string {
                        detailString.append(NSAttributedString(string: string,   attributes: highlighted))
                    }
                    if let after = after {
                        detailString.append(NSAttributedString(string: after,   attributes: normal))
                    }
                }
            } else {
                if let scriptureReference = mediaItem?.scriptureReference {
                    if !detailString.string.isEmpty {
                        detailString.append(NSAttributedString(string: "\n"))
                    }
                    detailString.append(NSAttributedString(string: scriptureReference,   attributes: normal))
                }
            }
            
//            if let _ = vc as? MediaTableViewController {
//                if globals.grouping != Grouping.CLASS {
//                    if mediaItem!.searchHit!.className {
//                        var string:String?
//                        var before:String?
//                        var after:String?
//                        
//                        if let range = mediaItem?.className?.lowercased().range(of: globals.search.text!.lowercased()) {
//                            before = mediaItem?.className?.substring(to: range.lowerBound)
//                            string = mediaItem?.className?.substring(with: range)
//                            after = mediaItem?.className?.substring(from: range.upperBound)
//                            
//                            detailString.append(NSAttributedString(string: "\n" + before!,   attributes: normal))
//                            detailString.append(NSAttributedString(string: string!,   attributes: highlighted))
//                            detailString.append(NSAttributedString(string: after!,    attributes: normal))
//                        }
//                    } else {
//                        detailString.append(NSAttributedString(string: "\n" + mediaItem!.className!, attributes: normal))
//                    }
//                }
//            } else {
//                if mediaItem!.searchHit!.className {
//                    var string:String?
//                    var before:String?
//                    var after:String?
//                    
//                    if let range = mediaItem?.className?.lowercased().range(of: globals.search.text!.lowercased()) {
//                        before = mediaItem?.className?.substring(to: range.lowerBound)
//                        string = mediaItem?.className?.substring(with: range)
//                        after = mediaItem?.className?.substring(from: range.upperBound)
//                        
//                        detailString.append(NSAttributedString(string: "\n" + before!,   attributes: normal))
//                        detailString.append(NSAttributedString(string: string!,   attributes: highlighted))
//                        detailString.append(NSAttributedString(string: after!,    attributes: normal))
//                    }
//                } else {
//                    detailString.append(NSAttributedString(string: "\n" + mediaItem!.className!, attributes: normal))
//                }
//            }

            if mediaItem!.searchHit!.className {
                var string:String?
                var before:String?
                var after:String?
                
                if let range = mediaItem?.className?.lowercased().range(of: globals.search.text!.lowercased()) {
                    before = mediaItem?.className?.substring(to: range.lowerBound)
                    string = mediaItem?.className?.substring(with: range)
                    after = mediaItem?.className?.substring(from: range.upperBound)
                    
                    if !detailString.string.isEmpty {
                        detailString.append(NSAttributedString(string: "\n"))
                    }
                    if let before = before {
                        detailString.append(NSAttributedString(string: before,   attributes: normal))
                    }
                    if let string = string {
                        detailString.append(NSAttributedString(string: string,   attributes: highlighted))
                    }
                    if let after = after {
                        detailString.append(NSAttributedString(string: after,   attributes: normal))
                    }
                }
            } else {
                if let className = mediaItem?.className {
                    if !detailString.string.isEmpty {
                        detailString.append(NSAttributedString(string: "\n"))
                    }
                    detailString.append(NSAttributedString(string: className, attributes: normal))
                }
            }

            DispatchQueue.main.async {
//                print(detailString.string)
                self.detail.attributedText = detailString
            }
            
//                if (mediaItem?.title?.range(of: " (Part ") != nil) {
//                    let first = mediaItem!.title!.substring(to: (mediaItem!.title!.range(of: " (Part")?.upperBound)!)
//                    let second = mediaItem!.title!.substring(from: (mediaItem!.title!.range(of: " (Part ")?.upperBound)!)
//                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
//                    detail.text = "\(combined)\n\(mediaItem!.scriptureReference!)"
//                } else {
//                    detail.text = "\(mediaItem!.title!)\n\(mediaItem!.scriptureReference!)"
//                }
        } else {
            DispatchQueue.main.async {
                if let formattedDate = self.mediaItem?.formattedDate {
                    self.title.text = formattedDate
                }
                if let service = self.mediaItem?.service {
                    if let isEmpty = self.title.text?.isEmpty, !isEmpty {
                        self.title.text?.append(Constants.SINGLE_SPACE)
                    }
                    self.title.text?.append(service)
                }
                if let speaker = self.mediaItem?.speaker {
                    if let isEmpty = self.title.text?.isEmpty, !isEmpty {
                        self.title.text?.append(Constants.SINGLE_SPACE)
                    }
                    self.title.text?.append(speaker)
                }
//                self.title.text = "\(self.mediaItem!.formattedDate!) \(self.mediaItem!.service!) \(self.mediaItem!.speaker!)"
            }
            
            //            print(mediaItem?.title)
            
            if var title = mediaItem?.title {
                if (title.range(of: " (Part ") != nil) {
                    let first = title.substring(to: (title.range(of: " (Part")?.upperBound)!)
                    let second = title.substring(from: (title.range(of: " (Part ")?.upperBound)!)
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one

                    title = combined
                }

                DispatchQueue.main.async {
                    self.detail.text = title
                    
                    if let scriptureReference = self.mediaItem?.scriptureReference {
                        if let isEmpty = self.detail.text?.isEmpty, !isEmpty {
                            self.detail.text?.append("\n")
                        }
                        self.detail.text?.append(scriptureReference)
                    }
                    
                    if let className = self.mediaItem?.className {
                        if let isEmpty = self.detail.text?.isEmpty, !isEmpty {
                            self.detail.text?.append("\n")
                        }
                        self.detail.text?.append(className)
                    }
                }

//                if let _ = vc as? MediaTableViewController {
//                    if globals.grouping != Grouping.CLASS, let className = mediaItem?.className {
//                        DispatchQueue.main.async {
//                            self.detail.text = self.detail.text! + "\n" + className
//                        }
//                    }
//                } else {
//                    if let className = mediaItem?.className {
//                        DispatchQueue.main.async {
//                            self.detail.text = self.detail.text! + "\n" + className
//                        }
//                    }
//                }
                
                
//                    if globals.mediaCategory.selected == "All Media" {
//                        detail.text = "\(mediaItem!.category!)\n" + detail.text!
//                    }
            }
        }

        if (detail.text != nil) || (detail.attributedText != nil) {
            isHiddenUI(false)
        }
    }
    
//    func endEdit()
//    {
//        DispatchQueue.main.async {
//            self.setEditing(false, animated: true)
//        }
//    }
    
    var mediaItem:MediaItem? {
        didSet {
            if mediaItem != oldValue {
//                DispatchQueue.main.async {
//                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateTagsButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_CELL_TAG), object: nil)
//                }
                
                if (oldValue != nil) {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                }
                
                if (mediaItem != nil) {
                    DispatchQueue(label: "CBC").async(execute: { () -> Void in
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    })
                    
                    DispatchQueue.main.async {
                        if self.tagsButton != nil {
                            if (self.mediaItem!.hasTags) {
                                if (self.mediaItem?.self.tagsSet?.count > 1) {
                                    self.tagsButton.setTitle(Constants.FA.TAGS, for: UIControlState())
                                } else {
                                    self.tagsButton.setTitle(Constants.FA.TAG, for: UIControlState())
                                }
                            } else {
                                self.tagsButton.isHidden = true
                            }
                        }
                        
                        if self.downloadButton != nil {
                            switch self.mediaItem!.audioDownload!.state {
                            case .none:
                                self.downloadButton.setTitle(Constants.FA.DOWNLOAD, for: UIControlState())
                                break
                                
                            case .downloaded:
                                self.downloadButton.setTitle(Constants.FA.DOWNLOADED, for: UIControlState())
                                break
                                
                            case .downloading:
                                self.downloadButton.setTitle(Constants.FA.DOWNLOADING, for: UIControlState())
                                break
                            }
                        }
                    }
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
        guard (mediaItem != nil) else {
            return
        }
        
        guard !self.isEditing else {
            return
        }
        
//        print("Download!")
//        if (Reachability.isConnectedToNetwork()) {
        
        if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            vc?.dismiss(animated: true, completion: nil)
            
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
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self.vc as? PopoverTableViewControllerDelegate
            popover.purpose = .selectingCellAction
            
            popover.selectedMediaItem = mediaItem
            
            var strings = [String]()
            
            if mediaItem!.hasAudio {
                switch mediaItem!.audioDownload!.state {
                case .none:
                    strings.append(Constants.Download_Audio)
                    break
                    
                case .downloading:
                    strings.append(Constants.Cancel_Audio_Download)
                    break
                case .downloaded:
                    strings.append(Constants.Delete_Audio_Download)
                    break
                }
            }
            
            popover.strings = strings
            
            popover.showIndex = false
            popover.showSectionHeaders = false
            
            popover.vc = vc
            
            vc?.present(navigationController, animated: true, completion: nil)
        }
        
        updateUI()
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    @IBOutlet weak var tagsButton: UIButton!
    @IBAction func tagsAction(_ sender: UIButton)
    {
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
            
            popover.navigationItem.title = Constants.Show // Show MediaItems Tagged With
            
            popover.delegate = self.vc as? MediaTableViewController
            popover.purpose = .selectingTags
            
            popover.strings = mediaItem!.tagsArray
            popover.strings?.insert(Constants.All,at: 0)
            
            popover.showIndex = false
            popover.showSectionHeaders = false
            
            popover.vc = vc

            vc?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func addSubview(_ view: UIView) {
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
        guard (tagsButton != nil) else {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.tagsButton.isHidden = !self.mediaItem!.hasTags
            self.tagsButton.isEnabled = globals.search.complete
            
            if globals.search.lexicon {
                self.tagsButton.isEnabled = false
                self.tagsButton.isHidden = true
            }
        })
    }
    
    func setupTagsToolbar()
    {
        guard (mediaItem != nil) else {
            return
        }
        
        guard (tagsButton != nil) else {
            return
        }

        DispatchQueue.main.async(execute: { () -> Void in
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
        })
    }
    
    func setupDownloadButtonToolbar()
    {
        guard (mediaItem?.audioDownload != nil) else {
            return
        }

        guard (downloadButton != nil) else {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
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
            
            //        let width = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            //        self.addConstraint(width)
            //
            //        let height = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            //        self.addConstraint(height)
            
            self.setNeedsLayout()
        })
    }
    
    var tagsToolbar: UIToolbar?
    
    var downloadToolbar: UIToolbar?
    
    func setupIcons()
    {
        if globals.search.active && ((vc as? MediaTableViewController) != nil) {
            let attrString = NSMutableAttributedString()
            
            let normal = [ NSFontAttributeName: UIFont(name: "FontAwesome", size: 12.0)! ]
            
            let highlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
                                NSFontAttributeName: UIFont(name: "FontAwesome", size: 12.0)! ]
            
            if (globals.mediaPlayer.mediaItem == mediaItem) && (globals.mediaPlayer.state == .playing) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAYING, attributes: normal))
            }

            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    if !globals.search.lexicon, mediaItem!.searchHit!.tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: highlighted))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: normal))
                    }
                } else {
                    if !globals.search.lexicon, mediaItem!.searchHit!.tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: highlighted))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: normal))
                    }
                }
            }

            if (mediaItem!.hasNotes) {
                if mediaItem!.searchHit!.transcriptHTML {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: highlighted))
                } else {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: normal))
                }
            }
            
            if (mediaItem!.hasSlides) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.SLIDES, attributes: normal))
            }
            
            if (mediaItem!.hasVideo) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: normal))
            }
            
            if (mediaItem!.hasAudio) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: normal))
            }
            
            DispatchQueue.main.async {
                self.icons.attributedText = attrString
            }
        } else {
            var string = String()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) && (globals.mediaPlayer.state == .playing) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.PLAYING
            }
            
            //        if (mediaItem!.scriptureReference != Constants.Selected_Scriptures) {
            //            string = string + Constants.SINGLE_SPACE + Constants.FA.BOOK
            //        }
            
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
            
            DispatchQueue.main.async {
                self.icons.text = string
            }
        }
    }
    
    func setupProgressBarForAudio()
    {
        guard let download = mediaItem?.audioDownload else {
            return
        }
        
        DispatchQueue.main.async {
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