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
    
}

class MediaTableViewCell: UITableViewCell
{
//    var downloadObserver:Timer?

    weak var vc:UIViewController?
    
//    override func willTransition(to state: UITableViewCellStateMask)
//    {
//        switch state.rawValue {
//        case 2:
//            DispatchQueue.main.async(execute: { () -> Void in
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.EDITING), object: self.tv)
//            })
//            break
//        
//        default:
//            DispatchQueue.main.async(execute: { () -> Void in
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_EDITING), object: self.tv)
//            })
//            break
//        }
//        
////        print(state.rawValue)
//    }
    
    @IBOutlet weak var countLabel: UILabel!
    
    func clear()
    {
        DispatchQueue.main.async {
            self.title.attributedText = nil
            self.detail.attributedText = nil
        }
    }
    
    func hideUI()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:hideUI")
            return
        }
        
        isHiddenUI(true)
        
        downloadProgressBar.isHidden = true
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI")
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
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:updateDownloadButton")
            return
        }
        
        guard (mediaItem?.audioDownload != nil) else {
            return
        }
        
        guard (downloadButton != nil) else {
            return
        }
        
        DispatchQueue.main.async {
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
    }
    
    func setupText()
    {
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
        
        DispatchQueue.main.async {
            //                print(titleString.string)
            self.title.attributedText = titleString // NSAttributedString(string: "\(mediaItem!.formattedDate!) \(mediaItem!.service!) \(mediaItem!.speaker!)", attributes: normal)
        }
        
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

        
        
        //        if (globals.search.active && ((vc as? MediaTableViewController) != nil)) || ((vc as? LexiconIndexViewController) != nil) {
//        if searchText != nil {
//        } else {
//            DispatchQueue.main.async {
//                if let formattedDate = self.mediaItem?.formattedDate {
//                    self.title.text = formattedDate
//                }
//                if let service = self.mediaItem?.service {
//                    if let isEmpty = self.title.text?.isEmpty, !isEmpty {
//                        self.title.text?.append(Constants.SINGLE_SPACE)
//                    }
//                    self.title.text?.append(service)
//                }
//                if let speaker = self.mediaItem?.speaker {
//                    if let isEmpty = self.title.text?.isEmpty, !isEmpty {
//                        self.title.text?.append(Constants.SINGLE_SPACE)
//                    }
//                    self.title.text?.append(speaker)
//                }
//                //                self.title.text = "\(self.mediaItem!.formattedDate!) \(self.mediaItem!.service!) \(self.mediaItem!.speaker!)"
//            }
//            
//            //            print(mediaItem?.title)
//            
//            if var title = mediaItem?.title {
//                if (title.range(of: " (Part ") != nil) {
//                    let first = title.substring(to: (title.range(of: " (Part")?.upperBound)!)
//                    let second = title.substring(from: (title.range(of: " (Part ")?.upperBound)!)
//                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
//                    
//                    title = combined
//                }
//                
//                DispatchQueue.main.async {
//                    self.detail.text = title
//                    
//                    if let scriptureReference = self.mediaItem?.scriptureReference {
//                        if let isEmpty = self.detail.text?.isEmpty, !isEmpty {
//                            self.detail.text?.append("\n")
//                        }
//                        self.detail.text?.append(scriptureReference)
//                    }
//                    
//                    if let className = self.mediaItem?.className {
//                        if let isEmpty = self.detail.text?.isEmpty, !isEmpty {
//                            self.detail.text?.append("\n")
//                        }
//                        self.detail.text?.append(className)
//                    }
//                    
//                    if let eventName = self.mediaItem?.eventName {
//                        if let isEmpty = self.detail.text?.isEmpty, !isEmpty {
//                            self.detail.text?.append("\n")
//                        }
//                        self.detail.text?.append(eventName)
//                    }
//                }
//                
//                //                if let _ = vc as? MediaTableViewController {
//                //                    if globals.grouping != Grouping.CLASS, let className = mediaItem?.className {
//                //                        DispatchQueue.main.async {
//                //                            self.detail.text = self.detail.text! + "\n" + className
//                //                        }
//                //                    }
//                //                } else {
//                //                    if let className = mediaItem?.className {
//                //                        DispatchQueue.main.async {
//                //                            self.detail.text = self.detail.text! + "\n" + className
//                //                        }
//                //                    }
//                //                }
//                
//                
//                //                    if globals.mediaCategory.selected == "All Media" {
//                //                        detail.text = "\(mediaItem!.category!)\n" + detail.text!
//                //                    }
//            }
//        }
    }
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:updateUI")
            return
        }
        
        guard (mediaItem != nil) else {
            isHiddenUI(true)
            print("No mediaItem for cell!")
            return
        }

        updateTagsButton()
        
        updateDownloadButton()
        
        setupProgressBarForAudio()

        setupIcons()

        setupText()
        
        if (detail.text != nil) || (detail.attributedText != nil) {
            isHiddenUI(false)
        }
    }
    
    var searchText:String? {
        didSet {
            updateUI()
        }
    }
    
    var mediaItem:MediaItem? {
        didSet {
//            DispatchQueue.main.async {
//                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateTagsButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_CELL_TAG), object: nil)
//            }
            
            if (oldValue != nil) {
//                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                })
            }
            
            if (mediaItem != nil) {
//                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                })
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
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:downloadAction")
            return
        }
        
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
            
            popover.section.strings = strings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            popover.vc = vc
            
            vc?.present(navigationController, animated: true, completion: nil)
        }
        
        updateUI()
    }
    
    @IBOutlet weak var tagsButton: UIButton!
    @IBAction func tagsAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:tagsAction")
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
            
            popover.navigationItem.title = Constants.Show // Show MediaItems Tagged With
            
            popover.delegate = self.vc as? MediaTableViewController
            popover.purpose = .selectingTags
            
            popover.section.strings = mediaItem!.tagsArray
            popover.section.strings?.insert(Constants.All,at: 0)
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
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
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:updateTagsButton")
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }
        
        guard (tagsButton != nil) else {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
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
        })
    }
    
    func setupTagsToolbar()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupTagsToolbar")
            return
        }
        
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
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupDownloadButtonToolbar")
            return
        }
        
        guard (mediaItem?.audioDownload != nil) else {
            return
        }

        guard (downloadButton != nil) else {
            return
        }
        
//        DispatchQueue.main.async(execute: { () -> Void in
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
//        })
    }
    
    var tagsToolbar: UIToolbar?
    
    var downloadToolbar: UIToolbar?
    
    func setupIcons()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        if (searchText != nil) {
            let attrString = NSMutableAttributedString()
            
//            let normal = [ NSFontAttributeName: UIFont(name: "FontAwesome", size: 12.0)! ]
//            
//            let highlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
//                                NSFontAttributeName: UIFont(name: "FontAwesome", size: 12.0)! ]
            
            if (globals.mediaPlayer.mediaItem == mediaItem) && (globals.mediaPlayer.state == .playing) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAYING, attributes: Constants.Fonts.Attributes.normal))
            }

            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.Fonts.Attributes.highlighted))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.Fonts.Attributes.normal))
                    }
                } else {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.Fonts.Attributes.highlighted))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.Fonts.Attributes.normal))
                    }
                }
            }

            if (mediaItem!.hasNotes) {
                if globals.search.transcripts && mediaItem!.searchHit(searchText).transcriptHTML {
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.Fonts.Attributes.highlighted))
                } else {
//                    print(searchText!)
                    attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT, attributes: Constants.Fonts.Attributes.normal))
                }
            }
            
            if (mediaItem!.hasSlides) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.SLIDES, attributes: Constants.Fonts.Attributes.normal))
            }
            
            if (mediaItem!.hasVideo) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: Constants.Fonts.Attributes.normal))
            }
            
            if (mediaItem!.hasAudio) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: Constants.Fonts.Attributes.normal))
            }
            
            DispatchQueue.main.async {
                self.icons.attributedText = attrString
            }
        } else {
            var string = String()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) && (globals.mediaPlayer.state == .playing) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.PLAYING
            }
            
//            if let books = mediaItem?.books {
//                string = string + Constants.SINGLE_SPACE + Constants.FA.SCRIPTURE
//            }
            
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
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupProgressBarForAudio")
            return
        }
        
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
