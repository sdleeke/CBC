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
import UserNotifications

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

extension AppDelegate : UISplitViewControllerDelegate
{
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
        //        if ((primaryViewController as? UINavigationController)?.visibleViewController as? LexiconIndexViewController) != nil {
        //            primaryViewController.navigationController?.popToRootViewController(animated: false)
        //        }
        //
        //        if ((primaryViewController as? UINavigationController)?.visibleViewController as? ScriptureIndexViewController) != nil {
        //            primaryViewController.navigationController?.popToRootViewController(animated: false)
        //        }
        
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else {
            return false
        }
        
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else {
            return false
        }
        
        if topAsDetailController.selectedMediaItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        
        return false
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController?
    {
//        guard UIDevice.current.userInterfaceIdiom == .pad else {
//            return nil
//        }
        
        if let master = splitViewController.viewControllers[0] as? UINavigationController, master.viewControllers.count > 0 {
            guard let mtvc = master.viewControllers[0] as? MediaTableViewController else {
                return nil
            }
            
            if master.viewControllers.count > 1, let sivc = master.viewControllers[1] as? ScriptureIndexViewController {
                if master.visibleViewController == sivc {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        return sivc.navigationController
                    } else {
                        mtvc.navigationController?.popToRootViewController(animated: false)
                        return mtvc.navigationController
                    }
                }
            }
            
            if master.viewControllers.count > 1, let livc = master.viewControllers[1] as? LexiconIndexViewController {
                if master.visibleViewController == livc {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        return livc.navigationController
                    } else {
                        mtvc.navigationController?.popToRootViewController(animated: false)
                        return mtvc.navigationController
                    }
                }
            }
            
//            if master.viewControllers.count > 2, let mvc = master.viewControllers[2] as? MediaViewController {
//                if master.visibleViewController == mvc {
//                    return sivc
//                }
//            }
//            if master.viewControllers.count > 2, let mvc = master.viewControllers[2] as? MediaViewController {
//                if master.visibleViewController == mvc {
//                    return livc
//                }
//            }

            let nvc = master.viewControllers[master.viewControllers.count - 1] as? UINavigationController
            
            switch master.viewControllers.count {
            case 0:
                // Should not happen
                break

            case 1:
                return mtvc.navigationController
                
            case 2,3:
                if let mvc = nvc?.viewControllers[0] as? MediaViewController {
                    if master.visibleViewController == mvc {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            mtvc.navigationController?.popToRootViewController(animated: false)
                        }
                        return mtvc.navigationController
                    }
                }
                
                if let sivc = nvc?.viewControllers[0] as? ScriptureIndexViewController {
                    if master.visibleViewController == sivc {
                        return sivc.navigationController
                    }
                }
                
                if let livc = nvc?.viewControllers[0] as? LexiconIndexViewController {
                    if master.visibleViewController == livc {
                        return livc.navigationController
                    }
                }
                break
            
            default:
                // Should not happen
                break
            }
        }
        
        if let master = splitViewController.viewControllers[0] as? MediaTableViewController {
            return master.navigationController
        }

        return nil
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController?
    {
//        guard UIDevice.current.userInterfaceIdiom == .pad else {
//            return nil
//        }
        
        if let master = splitViewController.viewControllers[0] as? UINavigationController {
            switch master.viewControllers.count {
            case 0:
                // SHOULD NEVER HAPPEN
                break
                
            case 1:
                if (master.viewControllers[0] as? MediaTableViewController) != nil {

                }
                break
                
            case 2:
                if (master.viewControllers[0] as? MediaTableViewController) != nil {
                    if let viewControllers = (master.viewControllers[1] as? UINavigationController)?.viewControllers {
                        if let mvc = viewControllers[0] as? MediaViewController {
                            return mvc.navigationController
                        }
                    }
                    if let sivc = master.viewControllers[1] as? ScriptureIndexViewController {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            // do nothing
                        }
                    }
                    if let livc = master.viewControllers[1] as? LexiconIndexViewController {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            // do nothing
                        }
                    }
                }
                break
                
            case 3:
                if (master.viewControllers[0] as? MediaTableViewController) != nil {
                    if let mvc = master.viewControllers[1] as? MediaViewController {
                        // SHOULD NEVER HAPPEN
                    }
                    if let sivc = master.viewControllers[1] as? ScriptureIndexViewController {
                        if let mvc = (master.viewControllers[2] as? UINavigationController)?.viewControllers[0] as? MediaViewController {
                            return mvc.navigationController
                        }
                    }
                    if let livc = master.viewControllers[1] as? LexiconIndexViewController {
                        if let mvc = (master.viewControllers[2] as? UINavigationController)?.viewControllers[0] as? MediaViewController {
                            return mvc.navigationController
                        }
                    }
                }
                break
                
            default:
                break
            }
        }
        
        if let navigationController = splitViewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
            let mvc = navigationController.viewControllers[0] as? MediaViewController {
            // MUST be an actual dispatch as it relies on the delay since we are already on the main thread.
//            mvc.selectedMediaItem = globals.selectedMediaItem.detail
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
//            }
            print("BLANK MVC")
            return navigationController
        }
        
        return nil
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController?
    {
//        guard UIDevice.current.userInterfaceIdiom == .pad else {
//            return nil
//        }
        
        if let master = splitViewController.viewControllers[0] as? UINavigationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return master.visibleViewController?.navigationController
            } else {
                return (master.viewControllers[0] as? MediaTableViewController)?.navigationController
            }
        }
        
        if let master = splitViewController.viewControllers[0] as? MediaTableViewController {
            return master.navigationController
        }
        
        return nil
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate
{
    var window: UIWindow?
    
    func downloadFailed()
    {
        globals.alert(title: "Network Error",message: "Download failed.")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        guard let svc = window?.rootViewController as? UISplitViewController else {
            return false
        }
        
        globals = Globals()
        
        globals.checkVoiceBaseAvailability()
        
        Thread.onMainThread() {
            globals.alertTimer = Timer.scheduledTimer(timeInterval: 0.25, target: globals, selector: #selector(Globals.alertViewer), userInfo: nil, repeats: true)
        }

        globals.splitViewController = svc
        
        globals.splitViewController.delegate = self
        
        globals.splitViewController.preferredDisplayMode = .allVisible
        
        let hClass = globals.splitViewController.traitCollection.horizontalSizeClass
        let vClass = globals.splitViewController.traitCollection.verticalSizeClass
        
        if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
            if let navigationController = globals.splitViewController.viewControllers[globals.splitViewController.viewControllers.count-1] as? UINavigationController {
                navigationController.topViewController?.navigationItem.leftBarButtonItem = globals.splitViewController.displayModeButtonItem
            }
        }

        globals.addAccessoryEvents()
        
        startAudio()
        
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
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_ENTER_BACKGROUND), object: nil)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")

        if (globals.mediaPlayer.rate == 0) && globals.mediaPlayer.isPaused && (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            // Is this the way to solve the dropped connection after an extended pause?  Might not since the app might stay in the foreground, but this will probably cover teh vast majority of the cases.
            
            // Do we need to do this for audio?
            
            if (globals.mediaPlayer.mediaItem != nil) { // && globals.mediaPlayer.mediaItem!.hasVideo && (globals.mediaPlayer.mediaItem!.playing == Playing.video)
                globals.mediaPlayer.playOnLoad = false
                globals.mediaPlayer.reload()
            }
        }
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("applicationWillResignActive")
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        
        globals.mediaPlayer.setupPlayingInfoCenter()
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_TERMINATE), object: nil)
        }
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
        
        if let mediaItems = globals.mediaRepository.list {
            for mediaItem in mediaItems {
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
}

