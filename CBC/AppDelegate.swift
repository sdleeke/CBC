//
//  AppDelegate.swift
//  CBC
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

extension UIApplication
{
    func isRunningInFullScreen() -> Bool
    {
        if let w = self.keyWindow
        {
            let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let minScreenSize = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let maxAppSize = max(w.bounds.size.width, w.bounds.size.height)
            let minAppSize = min(w.bounds.size.width, w.bounds.size.height)
            return maxScreenSize == maxAppSize && minScreenSize == minAppSize
        }
        
        return true
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate, UISplitViewControllerDelegate
{

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else { return false }
        if topAsDetailController.selectedMediaItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    var window: UIWindow?
    
    func downloadFailed()
    {
        networkUnavailable("Download failed.")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        
        globals = Globals()
        
//        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        
        globals.addAccessoryEvents()
        
        globals.startAudio()
        
//        DispatchQueue.main.async {
//            NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.downloadFailed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: nil)
//        }
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
        
        if globals.mediaPlayer.isPlaying && (globals.mediaPlayer.mediaItem?.playing == Playing.video) && (globals.mediaPlayer.pip != .started) {
            globals.mediaPlayer.pause()
        }
        
//        globals.mediaPlayer.view?.isHidden = true
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_ENTER_BACKGROUND), object: nil)
        })
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")

        if (globals.mediaPlayer.rate == 0) && globals.mediaPlayer.isPaused && (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            // Is this the way to solve the dropped connection after an extended pause?  Might not since the app might stay in the foreground, but this will probably cover teh vast majority of the cases.
            if (globals.mediaPlayer.mediaItem != nil) && globals.mediaPlayer.mediaItem!.hasVideo && (globals.mediaPlayer.mediaItem!.playing == Playing.video) {
                // This assumes that the player is paused because it is playing video and it is coming out of the background.  This may prove to be false.  Be careful.
                globals.mediaPlayer.playOnLoad = false
                globals.reloadPlayer()
            }
        }
        
//        if (globals.mediaPlayer.url != nil) {
//            switch globals.mediaPlayer.url!.absoluteString {
//            case Constants.URL.LIVE_STREAM:
//                globals.setupLivePlayingInfoCenter()
//                break
//                
//            default:
//                globals.setupPlayingInfoCenter()
//                break
//            }
//        }

        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        })
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("applicationWillResignActive")
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        })
        
        //        if globals.mediaPlayer.rate == 0 {
        //            if globals.mediaPlayer.isPlaying {
        //                //It is paused, possibly not by us, but by the system
        //                globals.mediaPlayer.pause()
        //            }
        //        }
        //
        //        if globals.mediaPlayer.isPlaying {
        //            if globals.mediaPlayer.mediaItem?.playing == Playing.video {
        //                globals.mediaPlayer.pause()
        //            }
        //        } else {
        //
        //        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        
        if #available(iOS 10.0, *) {
            if let timeControlStatus = globals.mediaPlayer.player?.timeControlStatus {
                switch timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    print("timeControlStatus:waitingToPlayAtSpecifiedRate")
                    if let state = globals.mediaPlayer.state {
                        switch state {
                            case .playing:
                                // Do nothing
                                break
                                
                            case .paused:
                                // ???
                                break
                                
                            default:
                                break
                        }
                    }
                    break
                    
                case .playing:
                    print("timeControlStatus:playing")
                    if let state = globals.mediaPlayer.state {
                        switch state {
                        case .playing:
                            // Do nothing
                            break
                            
                        case .paused:
                            // ???
                            break
                            
                        default:
                            break
                        }
                    }
                    break
                    
                case .paused:
                    print("timeControlStatus:paused")
                    if let state = globals.mediaPlayer.state {
                        switch state {
                        case .playing:
                            globals.mediaPlayer.pause()
                            break
                            
                        case .paused:
                            // Do nothing
                            break
                            
                        default:
                            break
                        }
                    }
                    break
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        
//        if (globals.mediaPlayer.rate == 0) && globals.mediaPlayer.isPaused && (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
//            //It is paused, possibly not by us, but by the system
////            if globals.mediaPlayer.isPlaying {
////                globals.mediaPlayer.pause() // IfPlaying
////                
//////                if let currentTime = globals.mediaPlayer.mediaItem?.currentTime, let time = Double(currentTime) {
//////                    let newCurrentTime = (time - Constants.BACK_UP_TIME) < 0 ? 0 : time - Constants.BACK_UP_TIME
//////                    globals.mediaPlayer.mediaItem?.currentTime = (Double(newCurrentTime) - 1).description
//////                }
////                
////                DispatchQueue.main.async(execute: { () -> Void in
////                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
////                })
////            }
//            
//            // Is this the way to solve the dropped connection after an extended pause?  Might not since the app might stay in the foreground, but this will probably cover teh vast majority of the cases.
//            if (globals.mediaPlayer.mediaItem != nil) && globals.mediaPlayer.mediaItem!.hasVideo && (globals.mediaPlayer.mediaItem!.playing == Playing.video) {
//                // This assumes that the player is paused because it is playing video and it is coming out of the background.  This may prove to be false.  Be careful.
//                globals.mediaPlayer.playOnLoad = false
//                globals.reloadPlayer()
//            }
//        }
        
//        if (globals.mediaPlayer.rate != 0) && (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
//            if globals.mediaPlayer.isPaused {
//                globals.mediaPlayer.pause()
//                
//                DispatchQueue.main.async(execute: { () -> Void in
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
//                })
//            }
//        }
        
        globals.mediaPlayer.setupPlayingInfoCenter()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        })
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("applicationWillTerminate")
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_TERMINATE), object: nil)
        })
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        print("application:handleEventsForBackgroundURLSession")
        
        /*
        In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
        */
        
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        
        var filename:String?
        
        filename = identifier.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        for mediaItem in globals.mediaRepository.list! {
            if let download = mediaItem.downloads.filter({ (key:String, value:Download) -> Bool in
                //                print("handleEventsForBackgroundURLSession: \(filename) \(key)")
                return value.task?.taskDescription == filename
            }).first?.value {
                download.session = URLSession(configuration: configuration, delegate: mediaItem, delegateQueue: nil)
                download.completionHandler = completionHandler
                break
            }
        }
    }
}

