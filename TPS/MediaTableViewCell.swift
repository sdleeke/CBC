//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell, UIPopoverPresentationControllerDelegate {

    var downloadObserver:Timer?

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

    func updateUI()
    {
        if (mediaItem != nil) {
            if (mediaItem!.audioDownload?.state == .downloading) && (downloadObserver == nil) {
                downloadObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.DOWNLOADING, target: self, selector: #selector(MediaTableViewCell.updateUI), userInfo: nil, repeats: true)
            }

            if (mediaItem!.audioDownload?.state == .downloaded) && (downloadObserver != nil) {
                downloadObserver?.invalidate()
                downloadObserver = nil
            }
            
            setupTagsButton()

            setupDownloadButtonForAudio()
            setupProgressBarForAudio()
    
            setupIcons()
            
            title.text = "\(mediaItem!.date!) \(mediaItem!.service!) \(mediaItem!.speaker!)"
            
//            print(mediaItem?.title)
            
            if (mediaItem?.title != nil) {
                if (mediaItem!.title!.range(of: " (Part ") != nil) {
                    let first = mediaItem!.title!.substring(to: (mediaItem!.title!.range(of: " (Part")?.upperBound)!)
                    let second = mediaItem!.title!.substring(from: (mediaItem!.title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    detail.text = "\(combined)\n\(mediaItem!.scripture!)"
                } else {
                    detail.text = "\(mediaItem!.title!)\n\(mediaItem!.scripture!)"
                }
//                
//                if globals.mediaCategory.selected == "All Media" {
//                    detail.text = "\(mediaItem!.category!)\n" + detail.text!
//                }
            }
        } else {
            NSLog("No mediaItem for cell!")
        }
    }
    
    var mediaItem:MediaItem? {
        didSet {
            if (oldValue != nil) {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
            }
            
            if (mediaItem != nil) {
                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: mediaItem)
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
//        NSLog("Download!")
//        if (Reachability.isConnectedToNetwork()) {
        
            if (mediaItem != nil) {
                
                if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = downloadButton.frame
                        
//                        popover.navigationItem.title = Constants.Actions
//                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
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
                        
                        vc?.present(navigationController, animated: true, completion: nil)
                    }
                }

                updateUI()
            }
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
        if (mediaItem != nil) {
            if (mediaItem!.hasTags) {
                if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = tagsButton.frame
                        
                        popover.navigationItem.title = Constants.Show // Show MediaItems Tagged With
                        //                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
                        popover.delegate = self.vc as? MediaTableViewController
                        popover.purpose = .selectingTags
                        
                        popover.strings = mediaItem!.tagsArray
                        popover.strings?.append(Constants.All)
                        popover.strings?.sort()
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false
                        
                        vc?.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            vc?.dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.popover
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = downloadButton.frame
            
            vc?.present(alert, animated: true, completion: nil)
        }
    }
    
    func setupTagsButton()
    {
        if (tagsButton != nil) {
            if (mediaItem!.hasTags) {
                tagsButton.isHidden = false
                
                if (mediaItem?.tagsSet?.count > 1) {
                    tagsButton.setTitle(Constants.FA.TAGS, for: UIControlState())
                } else {
                    tagsButton.setTitle(Constants.FA.TAG, for: UIControlState())
                }
            } else {
                tagsButton.isHidden = true
            }
        }
    }
    
    func setupDownloadButtonForAudio()
    {
        if mediaItem != nil {
            switch mediaItem!.audioDownload!.state {
            case .none:
                downloadButton.setTitle(Constants.FA.DOWNLOAD, for: UIControlState())
                break
                
            case .downloaded:
                downloadButton.setTitle(Constants.FA.DOWNLOADED, for: UIControlState())
                break
                
            case .downloading:
                downloadButton.setTitle(Constants.FA.DOWNLOADING, for: UIControlState())
                break
            }
        }
    }
    
    func setupIcons()
    {
        var tsva = String()
        
        if (globals.mediaPlayer.mediaItem == mediaItem) && (globals.mediaPlayer.state == .playing) {
            tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.PLAYING
        }
        
        if (mediaItem!.hasTags) {
            if (mediaItem?.tagsSet?.count > 1) {
                tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.TAGS
            } else {
                tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.TAG
            }
        }
        
        if (mediaItem!.hasNotes) {
            tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.TRANSCRIPT
        }
        
        if (mediaItem!.hasSlides) {
            tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.SLIDES
        }
        
        if (mediaItem!.hasVideo) {
            tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.VIDEO
        }
        
        if (mediaItem!.hasAudio) {
            tsva = tsva + Constants.SINGLE_SPACE + Constants.FA.AUDIO
        }
  
        icons.text = tsva
    }
    
    func setupProgressBarForAudio()
    {
        if mediaItem != nil {
            switch mediaItem!.audioDownload!.state {
            case .none:
                downloadProgressBar.isHidden = true
                downloadProgressBar.progress = 0
                break
                
            case .downloaded:
                downloadProgressBar.isHidden = true
                downloadProgressBar.progress = 1
                break
                
            case .downloading:
                downloadProgressBar.isHidden = false
                if (mediaItem!.audioDownload!.totalBytesExpectedToWrite > 0) {
                    downloadProgressBar.progress = Float(mediaItem!.audioDownload!.totalBytesWritten) / Float(mediaItem!.audioDownload!.totalBytesExpectedToWrite)
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
