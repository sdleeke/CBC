//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell, UIPopoverPresentationControllerDelegate {

    var downloadObserver:NSTimer?

    weak var vc:UIViewController?

    func updateUI()
    {
        if (sermon != nil) {
            if (sermon!.audioDownload?.state == .downloading) && (downloadObserver == nil) {
                downloadObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.DOWNLOADING_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewCell.updateUI), userInfo: nil, repeats: true)
            }

            if (sermon!.audioDownload?.state == .downloaded) && (downloadObserver != nil) {
                downloadObserver?.invalidate()
                downloadObserver = nil
            }
            
            setupTagsButton()

            setupDownloadButtonForAudio()
            setupProgressBarForAudio()
    
            setupIcons()
            
            title.text = "\(sermon!.date!) \(sermon!.service!) \(sermon!.speaker!)"
            
            if (sermon?.title != nil) {
                if (sermon!.title!.rangeOfString(" (Part") != nil) {
                    let first = sermon!.title!.substringToIndex((sermon!.title!.rangeOfString(" (Part")?.endIndex)!)
                    let second = sermon!.title!.substringFromIndex((sermon!.title!.rangeOfString(" (Part ")?.endIndex)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    detail.text = "\(combined)\n\(sermon!.scripture!)"
                } else {
                    detail.text = "\(sermon!.title!)\n\(sermon!.scripture!)"
                }
            }
        } else {
            print("No sermon for cell!")
        }
    }
    
    var sermon:Sermon? {
        didSet {
            if (oldValue != nil) {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: oldValue)
            }
            
            if (sermon != nil) {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: sermon)
            }

            updateUI()
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var icons: UILabel!
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBAction func downloadAction(sender: UIButton)
    {
//        print("Download!")
//        if (Reachability.isConnectedToNetwork()) {
        
            if (sermon != nil) {
                
                if let navigationController = vc?.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismissViewControllerAnimated(true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .Popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .Any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = downloadButton.frame
                        
                        popover.navigationItem.title = Constants.Actions
                        //                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
                        popover.delegate = self.vc as? PopoverTableViewControllerDelegate
                        popover.purpose = .selectingCellAction

                        popover.selectedSermon = sermon
                        
                        var strings = [String]()
                        
                        if sermon!.hasAudio() {
                            switch sermon!.audioDownload!.state {
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
                        
                        vc?.presentViewController(navigationController, animated: true, completion: nil)
                    }
                }

                updateUI()
            }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    @IBOutlet weak var tagsButton: UIButton!
    @IBAction func tagsAction(sender: UIButton)
    {
        if (sermon != nil) {
            if (sermon!.hasTags()) {
                if let navigationController = vc?.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismissViewControllerAnimated(true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .Popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .Any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = tagsButton.frame
                        
                        popover.navigationItem.title = "Show Sermons Tagged With"
                        //                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
                        popover.delegate = self.vc as? MediaTableViewController
                        popover.purpose = .selectingTags
                        
                        popover.strings = sermon!.tagsArray
                        popover.strings?.append(Constants.All)
                        popover.strings?.sortInPlace()
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false
                        
                        vc?.presentViewController(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            vc?.dismissViewControllerAnimated(true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = downloadButton.frame
            
            vc?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func setupTagsButton()
    {
        if (tagsButton != nil) {
            if (sermon!.hasTags()) {
                tagsButton.hidden = false
                
                if (sermon?.tagsSet?.count > 1) {
                    tagsButton.setTitle(Constants.FA_TAGS, forState: UIControlState.Normal)
                } else {
                    tagsButton.setTitle(Constants.FA_TAG, forState: UIControlState.Normal)
                }
            } else {
                tagsButton.hidden = true
            }
        }
    }
    
    func setupDownloadButtonForAudio()
    {
        if sermon != nil {
            switch sermon!.audioDownload!.state {
            case .none:
                downloadButton.setTitle(Constants.FA_DOWNLOAD, forState: UIControlState.Normal)
                break
                
            case .downloaded:
                downloadButton.setTitle(Constants.FA_DOWNLOADED, forState: UIControlState.Normal)
                break
                
            case .downloading:
                downloadButton.setTitle(Constants.FA_DOWNLOADING, forState: UIControlState.Normal)
                break
            }
        }
    }
    
    func setupIcons()
    {
        var tsva = String()
        
        if (sermon!.hasTags()) {
            if (sermon?.tagsSet?.count > 1) {
                tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TAGS
            } else {
                tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TAG
            }
        }
        
        if (sermon!.hasNotes()) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TRANSCRIPT
        }
        
        if (sermon!.hasSlides()) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_SLIDES
        }
        
        if (sermon!.hasVideo()) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_VIDEO
        }
        
        if (sermon!.hasAudio()) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_AUDIO
        }
  
        icons.text = tsva
    }
    
    func setupProgressBarForAudio()
    {
        if sermon != nil {
            switch sermon!.audioDownload!.state {
            case .none:
                downloadProgressBar.hidden = true
                downloadProgressBar.progress = 0
                break
                
            case .downloaded:
                downloadProgressBar.hidden = true
                downloadProgressBar.progress = 1
                break
                
            case .downloading:
                downloadProgressBar.hidden = false
                if (sermon!.audioDownload!.totalBytesExpectedToWrite > 0) {
                    downloadProgressBar.progress = Float(sermon!.audioDownload!.totalBytesWritten) / Float(sermon!.audioDownload!.totalBytesExpectedToWrite)
                } else {
                    downloadProgressBar.progress = 0
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

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
