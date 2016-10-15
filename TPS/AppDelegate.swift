//
//  AppDelegate.swift
//  TPS
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate, UISplitViewControllerDelegate {

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else { return false }
        if topAsDetailController.selectedSermon == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    var window: UIWindow?
    
    func mpPlayerLoadStateDidChange()
    {
        globals.mpPlayerLoadStateDidChange()
    }
    
    func playerTimer()
    {
        globals.playerTimer()
    }
    
    func startAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
            NSLog("failed to setCategory(AVAudioSessionCategoryPlayback)")
        }
        
        do {
            //        audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error:nil)
            try audioSession.setActive(true)
        } catch _ {
            NSLog("failed to audioSession.setActive(true)")
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        globals = Globals()
        
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        
        startAudio()
        
        globals.addAccessoryEvents()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        globals.player.observer = Timer.scheduledTimer(timeInterval: Constants.PLAYER_TIMER_INTERVAL, target: self, selector: #selector(AppDelegate.playerTimer), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.mpPlayerLoadStateDidChange), name: NSNotification.Name.MPMoviePlayerLoadStateDidChange, object: nil)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        NSLog("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        NSLog("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        NSLog("applicationWillEnterForeground")

        globals.setupPlayingInfoCenter()

        if (globals.player.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            if (globals.player.loaded) {
                globals.updateCurrentTimeExact()
            }
            globals.player.paused = true
        } else {
            globals.player.paused = false
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
        })
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        println("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        NSLog("applicationWillTerminate")
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        NSLog("application:handleEventsForBackgroundURLSession")
        
        /*
        In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
        */
        
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        
        var filename:String?
        
        filename = identifier.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        for sermon in globals.sermonRepository.list! {
            if let download = sermon.downloads.filter({ (key:String, value:Download) -> Bool in
                //                NSLog("handleEventsForBackgroundURLSession: \(filename) \(key)")
                return value.task?.taskDescription == filename
            }).first?.1 {
                download.session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
                download.completionHandler = completionHandler
                break
            }
        }
    }
}

