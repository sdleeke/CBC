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
    
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    @IBAction func cacheAction(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: Constants.CACHE_DOWNLOADS)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if !sender.on {
            NSURLCache.sharedURLCache().removeAllCachedResponses()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                do {
                    let fileManager = NSFileManager.defaultManager()
                    for sermon in Globals.sermonRepository.list! {
                        if sermon.isDownloaded(sermon.notesInFileSystemURL) {
                            try fileManager.removeItemAtURL(sermon.notesInFileSystemURL!)
                            sermon.notesDownload?.state = .none
                        }
                        if sermon.isDownloaded(sermon.slidesInFileSystemURL) {
                            try fileManager.removeItemAtURL(sermon.slidesInFileSystemURL!)
                            sermon.slidesDownload?.state = .none
                        }
                    }
                } catch _ {
                }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 9.0, *) {
            cacheSwitch.enabled = true
        } else {
            cacheSwitch.enabled = false
        }
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
