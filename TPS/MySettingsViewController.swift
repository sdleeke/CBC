//
//  MySettingsViewController.swift
//  TWU
//
//  Created by Steve Leeke on 2/18/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class MySettingsViewController: UIViewController {

    @IBOutlet weak var autoAdvanceSwitch: UISwitch!
    
    @IBAction func autoAdvanceAction(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: Constants.AUTO_ADVANCE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBOutlet weak var audioSizeLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    @IBAction func cacheAction(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: Constants.CACHE_DOWNLOADS)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if !sender.on {
            NSURLCache.sharedURLCache().removeAllCachedResponses()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                for sermon in Globals.sermonRepository.list! {
                    sermon.notesDownload?.deleteDownload()
                    sermon.slidesDownload?.deleteDownload()
                }

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateCacheSize()
                })
            })
        }
    }
    
//    @IBAction func doneAction(sender: UIButton) {
//        dismissViewControllerAnimated(true, completion: nil)
//    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        autoAdvanceSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)
        cacheSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS)
    }
    
    func updateCacheSize()
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            let sizeOfCache = cacheSize(Constants.SLIDES) + cacheSize(Constants.NOTES)
            
            var size:Float = Float(sizeOfCache)
            
            var count = 0
            
            repeat {
                size /= 1024
                count++
            } while size > 1024
            
            var sizeLabel:String!
            
            switch count {
            case 0:
                sizeLabel = "bytes"
                break
                
            case 1:
                sizeLabel = "KB"
                break
                
            case 2:
                sizeLabel = "MB"
                break
                
            case 3:
                sizeLabel = "GB"
                break
                
            default:
                sizeLabel = "ERROR"
                break
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cacheSizeLabel.text = "\(String(format: "%0.1f",size)) \(sizeLabel) in use"
            })
        })
    }
    
    func updateAudioSize()
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            let sizeOfAudio = cacheSize(Constants.AUDIO)
            
            var size:Float = Float(sizeOfAudio)
            
            var count = 0
            
            repeat {
                size /= 1024
                count++
            } while size > 1024
            
            var sizeLabel:String!
            
            switch count {
            case 0:
                sizeLabel = "bytes"
                break
                
            case 1:
                sizeLabel = "KB"
                break
                
            case 2:
                sizeLabel = "MB"
                break
                
            case 3:
                sizeLabel = "GB"
                break
                
            default:
                sizeLabel = "ERROR"
                break
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.audioSizeLabel.text = "Audio Storage: \(String(format: "%0.1f",size)) \(sizeLabel) in use"
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 9.0, *) {
            cacheSwitch.enabled = true
        } else {
            cacheSwitch.enabled = false
        }

        cacheSizeLabel.text = "Updating..."
        audioSizeLabel.text = "Audio Storage: updating..."

        updateCacheSize()
        updateAudioSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
