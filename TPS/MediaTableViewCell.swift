//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MediaTableViewCell: UITableViewCell, UIPopoverPresentationControllerDelegate {

    var downloadObserver:Timer?

    weak var vc:UIViewController?

    func updateUI()
    {
        if (sermon != nil) {
            if (sermon!.audioDownload?.state == .downloading) && (downloadObserver == nil) {
                downloadObserver = Timer.scheduledTimer(timeInterval: Constants.DOWNLOADING_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewCell.updateUI), userInfo: nil, repeats: true)
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
            
//            print(sermon?.title)
            
            if (sermon?.title != nil) {
                if (sermon!.title!.range(of: " (Part ") != nil) {
                    let first = sermon!.title!.substring(to: (sermon!.title!.range(of: " (Part")?.upperBound)!)
                    let second = sermon!.title!.substring(from: (sermon!.title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    detail.text = "\(combined)\n\(sermon!.scripture!)"
                } else {
                    detail.text = "\(sermon!.title!)\n\(sermon!.scripture!)"
                }
                
                if globals.sermonCategory == "All Media" {
                    detail.text = "\(sermon!.category!)\n" + detail.text!
                }
            }
        } else {
            NSLog("No sermon for cell!")
        }
    }
    
    var sermon:Sermon? {
        didSet {
            if (oldValue != nil) {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: oldValue)
            }
            
            if (sermon != nil) {
                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: sermon)
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
        
            if (sermon != nil) {
                
                if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = downloadButton.frame
                        
                        popover.navigationItem.title = Constants.Actions
                        //                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
                        popover.delegate = self.vc as? PopoverTableViewControllerDelegate
                        popover.purpose = .selectingCellAction

                        popover.selectedSermon = sermon
                        
                        var strings = [String]()
                        
                        if sermon!.hasAudio {
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
        if (sermon != nil) {
            if (sermon!.hasTags) {
                if let navigationController = vc?.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        vc?.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = self
                        navigationController.popoverPresentationController?.sourceRect = tagsButton.frame
                        
                        popover.navigationItem.title = "Show Series" // Show Sermons Tagged With
                        //                        popover.preferredContentSize = CGSizeMake(300, 500)
                        
                        popover.delegate = self.vc as? MediaTableViewController
                        popover.purpose = .selectingTags
                        
                        popover.strings = sermon!.tagsArray
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
            if (sermon!.hasTags) {
                tagsButton.isHidden = false
                
                if (sermon?.tagsSet?.count > 1) {
                    tagsButton.setTitle(Constants.FA_TAGS, for: UIControlState())
                } else {
                    tagsButton.setTitle(Constants.FA_TAG, for: UIControlState())
                }
            } else {
                tagsButton.isHidden = true
            }
        }
    }
    
    func setupDownloadButtonForAudio()
    {
        if sermon != nil {
            switch sermon!.audioDownload!.state {
            case .none:
                downloadButton.setTitle(Constants.FA_DOWNLOAD, for: UIControlState())
                break
                
            case .downloaded:
                downloadButton.setTitle(Constants.FA_DOWNLOADED, for: UIControlState())
                break
                
            case .downloading:
                downloadButton.setTitle(Constants.FA_DOWNLOADING, for: UIControlState())
                break
            }
        }
    }
    
    func setupIcons()
    {
        var tsva = String()
        
        if (sermon!.hasTags) {
            if (sermon?.tagsSet?.count > 1) {
                tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TAGS
            } else {
                tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TAG
            }
        }
        
        if (sermon!.hasNotes) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_TRANSCRIPT
        }
        
        if (sermon!.hasSlides) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_SLIDES
        }
        
        if (sermon!.hasVideo) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_VIDEO
        }
        
        if (sermon!.hasAudio) {
            tsva = tsva + Constants.SINGLE_SPACE_STRING + Constants.FA_AUDIO
        }
  
        icons.text = tsva
    }
    
    func setupProgressBarForAudio()
    {
        if sermon != nil {
            switch sermon!.audioDownload!.state {
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
