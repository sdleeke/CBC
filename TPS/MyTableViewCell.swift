//
//  MyTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MyTableViewCell: UITableViewCell {

    var downloadObserver:NSTimer?

    func updateUI()
    {
        if (sermon != nil) {
            if (sermon!.download.state == .downloading) && (downloadObserver == nil) {
                downloadObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateUI", userInfo: nil, repeats: true)
            }
            
            if (sermon!.download.state == .downloaded) && (downloadObserver != nil) {
                downloadObserver?.invalidate()
                downloadObserver = nil
            }
            
            setupDownloadButton()
            setupProgressBar()
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
            NSNotificationCenter.defaultCenter().removeObserver(self)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: sermon)

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
                switch sermon!.download.state {
                case .none:
                    downloadAudio()
                    break
                case .downloading:
                    let alert = UIAlertController(title: Constants.Cancel_Audio_Download,
                        message: Constants.EMPTY_STRING,
                        preferredStyle: UIAlertControllerStyle.ActionSheet)
                    
                    var action : UIAlertAction
                    
                    action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        self.cancelDownload()
                    })
                    alert.addAction(action)
                    
                    action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.Popover
                    alert.popoverPresentationController?.sourceView = self
                    alert.popoverPresentationController?.sourceRect = downloadButton.frame
                    
                    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                    break
                case .downloaded:
                    let alert = UIAlertController(title: Constants.Delete_Audio_Download,
                        message: Constants.EMPTY_STRING,
                        preferredStyle: UIAlertControllerStyle.ActionSheet)
                    
                    var action : UIAlertAction
                    
                    action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        self.deleteDownload()
                    })
                    alert.addAction(action)
                    
                    action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.Popover
                    alert.popoverPresentationController?.sourceView = self
                    alert.popoverPresentationController?.sourceRect = downloadButton.frame
                    
                    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                    break
                }
                updateUI()
            }
//        } else {
//            self.networkUnavailable("Unable to download audio.")
//        }
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            alert.popoverPresentationController?.sourceView = self
            alert.popoverPresentationController?.sourceRect = downloadButton.frame
            
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func setupDownloadButton()
    {
        if sermon != nil {
//            var attributes:[String:AnyObject]?
            
            //If we don't set the color we get gray text at times.  Not sure entirely why, assume it has something to do with
            //when buttons, etc. are "enabled" or not.
            
//            attributes = [NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_DOWNLOAD_FONT_SIZE)!,NSForegroundColorAttributeName:Constants.iosBlueColor] //
            
            switch sermon!.download.state {
            case .none:
                downloadButton.setTitle(Constants.FA_DOWNLOAD, forState: UIControlState.Normal)
//                downloadButton.setAttributedTitle(NSMutableAttributedString(string: Constants.FA_DOWNLOAD,attributes: attributes), forState: downloadButton.state)//UIControlState.Normal
                break
                
            case .downloaded:
                downloadButton.setTitle(Constants.FA_DOWNLOADED, forState: UIControlState.Normal)
//                downloadButton.setAttributedTitle(NSMutableAttributedString(string: Constants.FA_DOWNLOADED,attributes: attributes), forState: UIControlState.Normal)
                break
                
            case .downloading:
                downloadButton.setTitle(Constants.FA_DOWNLOADING, forState: UIControlState.Normal)
//                downloadButton.setAttributedTitle(NSMutableAttributedString(string: Constants.FA_DOWNLOADING,attributes: attributes), forState: UIControlState.Normal)
                break
            }
        }
    }
    
    func setupIcons()
    {
        var tsva = String()
        
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
        
//        let attributes = [NSFontAttributeName : UIFont(name: Constants.FontAwesome, size: Constants.FA_ICONS_FONT_SIZE)!]
//
//        icons.attributedText = NSMutableAttributedString(string: tsva,attributes: attributes)
  
        icons.text = tsva
    }
    
    func setupProgressBar()
    {
        if sermon != nil {
            switch sermon!.download.state {
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
                if (sermon!.download.totalBytesExpectedToWrite > 0) {
                    downloadProgressBar.progress = Float(sermon!.download.totalBytesWritten) / Float(sermon!.download.totalBytesExpectedToWrite)
                } else {
                    downloadProgressBar.progress = 0
                }
                break
            }
        }
    }
    
    func deleteDownload()
    {
        sermon?.deleteDownload()
    }
    
    func cancelDownload()
    {
        // It may complete downloading before the user clicks okay.
        
        switch sermon!.download.state {
        case .downloading:
            sermon?.cancelDownload()
            break
            
        case .downloaded:
            sermon?.deleteDownload()
            break
            
        default:
            break
        }
    }
    
    func downloadAudio()
    {
        sermon?.downloadAudio()
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
