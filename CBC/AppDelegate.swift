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
import CoreData

import Firebase

extension AppDelegate : UISplitViewControllerDelegate
{
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else {
            return false // Tells the system to try and collapse the secondary (detail) view controller.
        }
        
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else {
            return false // Tells the system to try and collapse the secondary (detail) view controller.
        }

        if topAsDetailController.selectedMediaItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            // This is what causes a collapsed split view controller to always start w/ the master view.
            return true // Tells the system to NOT do anything with the secondary (detail) view controller.
        }

        // THIS MUST BE TRUE OR EVERYTHING BREAKS ON PLUS SIZE PHONES
        return true // Tells the system to NOT do anything with the secondary (detail) view controller.
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController?
    {
        // SVC vc[0] is a navCon and it has viewControllers
        if let master = splitViewController.viewControllers[0] as? UINavigationController, master.viewControllers.count > 0 {
            // First vc in master navCon vc's better be an MTVC
            guard let mtvc = master.viewControllers[0] as? MediaTableViewController else {
                return nil
            }
            
            // If the second vc in master navCon is an SIVC *and* it is the visible vc, then
            // if it is on an iPad, return its navCon,
            // but if it is on a phone, i.e. a plus size phone, then pop to the root VC, i.e. the MTVC, and return the MTVC's navCon.
            if master.viewControllers.count > 1, let sivc = master.viewControllers[1] as? ScriptureIndexViewController, master.visibleViewController == sivc {
                // This distinction is because when horizontal the SIVC moves the tableview to the RHS of its view.
                // It is not designed to work in a short vertical view.
                // That would require the controls portion (chapter/book switches and picker) be able to collapse or scroll.
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return sivc.navigationController
                } else {
                    mtvc.navigationController?.popToRootViewController(animated: false)
                    return mtvc.navigationController
                }
            }

            // Same for LIVC
            if master.viewControllers.count > 1, let livc = master.viewControllers[1] as? LexiconIndexViewController, master.visibleViewController == livc {
                // This distinction is because when horizontal the LIVC moves the tableview to the RHS of its view.
                // It is not designed to work in a short vertical view.
                // That would require the controls portion (chapter/book switches and picker) be able to collapse or scroll.
                if UIDevice.current.userInterfaceIdiom == .pad {
                    return livc.navigationController
                } else {
                    mtvc.navigationController?.popToRootViewController(animated: false)
                    return mtvc.navigationController
                }
            }
            
            // Check for the possibility that there is a navCon view controller,
            // which will always be found in the last vc in the master's vc's,
            // which we take to be the detail vc collapsed on to the master vc's. // Is this a good assumption?
            let nvc = master.viewControllers[master.viewControllers.count - 1] as? UINavigationController
            
            switch master.viewControllers.count {
            case 0:
                // Should not happen
                break

            case 1:
                // This would only happen if the mtvc is the master's visible vc and there is no detail vc.
                // So return the mtvc's navCon
                return mtvc.navigationController
                
            case 2,3:
                // If the detail view is showing an MVC as the visible view controller then return the mtvc's navCon
                // But if on a phone, make sure to pop to the root vc before doing so.  No SIVC or LIVC can be left in the VC hierarchy.  (See above.)
                if let mvc = nvc?.viewControllers[0] as? MediaViewController {
                    if master.visibleViewController == mvc {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            mtvc.navigationController?.popToRootViewController(animated: false)
                        } else {
                            // For master.viewControllers.count == 3 this assumes SIVC/LIVC navCon is the same as the mtvc's navCon.
                            mtvc.navigationController?.popViewController(animated: false)
                        }
                        return mtvc.navigationController
                    }
                }
                
                // The following is like case 1: above in that it implies there is no MVC in the heirarchy.
                // BUT it contradicts the comment above let nvc, which implies that the nvc is the detail vc.
                
                // Since this only occurs when master.viewControllers.count > 1 (2 or 3 for our purposes)
                // WHY would master.viewControllers have ANY NVC's????
                
                // If the SIVC or LIVC is in the NVC and it is the master's visible vc, return its navCon.
                // Apparently this only occurs on iPad's and not iPhone Pluses.
                // DOES THIS EVER OCCUR?
                if let sivc = nvc?.viewControllers[0] as? ScriptureIndexViewController {
                    if master.visibleViewController == sivc, UIDevice.current.userInterfaceIdiom == .pad {
                        return sivc.navigationController
                    }
                }
                if let livc = nvc?.viewControllers[0] as? LexiconIndexViewController {
                    if master.visibleViewController == livc, UIDevice.current.userInterfaceIdiom == .pad {
                        return livc.navigationController
                    }
                }
                break
            
            default:
                // Should not happen
                break
            }
        }
        
        // In some cases the MTVC is not in a navCon in the SVC vc's, not sure why.
        // Does this ever happen?
        if let master = splitViewController.viewControllers[0] as? MediaTableViewController {
            return master.navigationController
        }

        // Out of options, let the system figure it out.
        // This should never happen.
        return nil
    }
    
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController?
    {
        // For phones this is only called by plus sized phones.
        // And in plus sized phones neither an SIVC nor an LIVC can be anywhere in the SVC vc's when the SVC is expanded
        // So neither an SIVC nor an LIVC should ever show up as the primary after collapsing
        
        // If the SVC has a navCon in first position, i.e. master
        if let master = splitViewController.viewControllers[0] as? UINavigationController {
            return master
            //            if UIDevice.current.userInterfaceIdiom == .phone {
            //                return master.visibleViewController?.navigationController
            //            } else {
            //                return master.visibleViewController?.navigationController
            //            }
            
            // Can we really do the above instead of this?
            //            if UIDevice.current.userInterfaceIdiom == .pad {
            //                // On an iPad hand back whatever is the visible vc in the master, could be an SIVC or LIVC
            //                return master.visibleViewController?.navigationController // not topViewController
            //            } else {
            //                // On an iPhone hand back only the MTVC
            //                return (master.viewControllers[0] as? MediaTableViewController)?.navigationController
            //            }
        }
        
        // If the SVC has an MTVC in first position, i.e. master
        // Does this ever happen?
        if let master = splitViewController.viewControllers[0] as? MediaTableViewController {
            return master.navigationController
        }
        
        // We can ignore SVC vc[1] since this is asking for the primary for a collapsing SVC
        return nil
    }

    func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController?
    {
        // Only calledif function below, splitViewController(seprateSecondaryFrom:) returns nil or is not overridden.
        return nil
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController?
    {
//        guard UIDevice.current.userInterfaceIdiom == .pad else {
//            return nil
//        }
        
        // The master is always a navCon - there is NEVER a vc[1] since this SVC is collapsed.
        if let master = splitViewController.viewControllers[0] as? UINavigationController, master.viewControllers.count > 0 {
            // If there is one or more, then the first one must be a MTVC.
            guard let mtvc = master.viewControllers[0] as? MediaTableViewController else {
                return nil
            }
            
            // Check for the possibility that there is a navCon view controller,
            // which will always be found in the last vc in the master's vc's,
            // which we take to be the detail vc collapsed on to the master vc's.
            let nvc = master.viewControllers[master.viewControllers.count - 1] as? UINavigationController

            switch master.viewControllers.count {
            case 0:
                // SHOULD NEVER HAPPEN
                break
                
            case 1:
                // If there is only one vc it better be an MTVC since that one should *always* be there.
                // But there is nothing to be done for the detail except punt and send a blank one (see below).
                break
                
            case 2:
                // If the second/last is a navCon
                if let mvc = nvc?.viewControllers[0] as? MediaViewController {
                    // And if the first one of that is an MVC then return it's navCon.  I don't worry about visible vc since nothing is ever in detail but MVC's.
                    return mvc.navigationController

                    // Otherwise do nothing, i.e. send back a blank MVC
                    // This assumes there would never be anything but an MVC in the navCon
                }
                
                // We're assuming that an MVC would never appear outside of a navCon
                if let mvc = master.viewControllers[1] as? MediaViewController {
                    // SHOULD NEVER HAPPEN
                }
                
                // If the second is an SIVC or LIVC then do nothing, i.e. return a blank MVC
                if let sivc = master.viewControllers[1] as? ScriptureIndexViewController {
                    // do nothing, i.e. send back a blank MVC
                }
                if let livc = master.viewControllers[1] as? LexiconIndexViewController {
                    // do nothing, i.e. send back a blank MVC
                }
                break
                
            case 3:
                // We're assuming that an MVC would never appear outside of a navCon
                if let mvc = master.viewControllers[1] as? MediaViewController {
                    // SHOULD NEVER HAPPEN - MVC's should always be in a separate NavCon from mtvc?  I.e. nvc
                }
                if let mvc = master.viewControllers[2] as? MediaViewController {
                    // SHOULD NEVER HAPPEN - MVC's should always be in a separate NavCon from mtvc?  I.e. nvc
                }
                // If the second is an SIVC or LIVC then the third should be an MVC
                // and since detail only has MVC's, again, I don't bother to check that the MVC is the visible view controller in the navCon, just return the MVC navCon
                if let sivc = master.viewControllers[1] as? ScriptureIndexViewController {
                    // We're assuming the third is always a navCon and represents the detail vc
                    if let mvc = nvc?.viewControllers[0] as? MediaViewController {
                        // So I'm not sure why we can't pass back mvc.navigationController, but it doesn't work.
                        // Instead passing back a new one does - it's just slower.
                        if let navigationController = splitViewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
                            let mvc = navigationController.viewControllers[0] as? MediaViewController {
                            // MUST be an actual dispatch as it relies on the delay since we are already on the main thread.
                            return navigationController
                        }
//                        return mvc.navigationController
                    }
                }
                if let livc = master.viewControllers[1] as? LexiconIndexViewController {
                    // We're assuming the third is always a navCon and represents the detail vc
                    if let mvc = nvc?.viewControllers[0] as? MediaViewController {
                        // So I'm not sure why we can't pass back mvc.navigationController, but it doesn't work.
                        // Instead passing back a new one does - it's just slower.
                        if let navigationController = splitViewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
                            let mvc = navigationController.viewControllers[0] as? MediaViewController {
                            // MUST be an actual dispatch as it relies on the delay since we are already on the main thread.
                            return navigationController
                        }
//                        return mvc.navigationController
                    }
                }
                break
                
            default:
                break
            }
        }
        
        // Hand back a blank MVC and let the system load it from user defaults.
        if let navigationController = splitViewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
            let mvc = navigationController.viewControllers[0] as? MediaViewController {
            // MUST be an actual dispatch as it relies on the delay since we are already on the main thread.
            return navigationController
        }
        
        // This should never happen.
        return nil
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate //, AVAudioSessionDelegate
{
    deinit {
        debug(self)
    }
    
    var window: UIWindow?
    
//    func downloadFailed()
//    {
//        Alerts.shared.alert(title: "Network Error",message: "Download failed.")
//    }
    
//    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity)
//    {
//
//    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        // What is the scheme and why do I have to be able to read it?
        guard let scheme = url.scheme else {
            Alerts.shared.alert(title: "Unable to Read Scheme", message: url.absoluteString)
            return false // We are returning failure because?
        }
        
        // What is the host and why do I have to be able to read it?
        guard let host = url.host else {
//            Alerts.shared.alert(title: "Unable to Read Host", message: url.absoluteString)
            return true // Why are we returning success?
        }

        // The first view controller in the splitViewController's viewControllers must be a navigation controller
        guard let nvc = Globals.shared.splitViewController?.viewControllers[0] as? UINavigationController else {
            return false // If not return failure
        }
        
        // THe first view controller in the navigation controller must be an MTVC
        guard let mtvc = nvc.viewControllers[0] as? MediaTableViewController else {
            return false // If not return failure
        }
 
        // Rather than using mtvc directly should we use notifications?
        
        var newTag:Bool = false
        var newCategory:Bool = false

        // Now start parsing the URL for parameters
        let components = host.components(separatedBy: "&")

        for component in components {
            // and their values
            let parts = component.components(separatedBy: "=")
            
            // Interpret the parsed information
            // NOTE: This is CASE SENSITIVE
            switch parts[0] {
            case "mediaCode":
                Globals.shared.media.goto = parts[1]
                break

            case "category":
                if Globals.shared.media.category.selected != parts[1] {
                    newCategory = true
                    Globals.shared.media.category.selected = parts[1]
                }
                break
                
            case "sorting":
                Globals.shared.sorting = parts[1]
                break
                
            case "grouping":
                Globals.shared.grouping = parts[1]
                break
                
            case "tag":
                let string = parts[1]
                        
                switch string {
                case Constants.Strings.All:
                    if (Globals.shared.media.tags.showing != Constants.ALL) {
                        newTag = true
                        Globals.shared.media.tags.selected = nil
                    }
                    break
                    
                default:
                    //Tagged
                    
                    let tagSelected = string
                    
                    newTag = (Globals.shared.media.tags.showing != Constants.TAGGED) || (Globals.shared.media.tags.selected != tagSelected)
                    
                    if (newTag) {
                        Globals.shared.media.tags.selected = tagSelected
                    }
                    break
                }
                break
                
                default:
                break
            }
        }
        
        if newCategory || newTag {
            // Why?
            Globals.shared.media.selected.detail = nil
        }
        
        guard Globals.shared.media.repository.list != nil, !Globals.shared.isLoading else {
//            Alerts.shared.alert(title: "Not ready for UI.")
            return true // We've handled it = loding or no media.
        }
        
        if newCategory {
            // Change the category
            Thread.onMain { [weak self] in 
                mtvc.mediaCategoryButton.setTitle(Globals.shared.media.category.selected)
                mtvc.tagLabel.text = nil // Effectively hides the tag(s) icon.
            }
            
            Globals.shared.media.all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                mediaItem.category == Globals.shared.media.category.selected
            }))
            
            mtvc.selectedMediaItem = Globals.shared.media.selected.master
        }
        
        if newCategory || newTag {
            // Clear the tag
            Globals.shared.media.tags.tagged.clear() // Why should newTag cause this?
            
            if let tag = Globals.shared.media.tags.selected {
                // Update the list of tagged mediaItem.
                Globals.shared.media.tags.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes])
            }
        }
        
        // If svc is collapsed, pop to the root view controller.
        // To show the change
        if let isCollapsed = mtvc.splitViewController?.isCollapsed, isCollapsed {
            Thread.onMain { [weak self] in 
                nvc.popToRootViewController(animated: false)
            }
        }

        // If new category or tag, or sorting or grouping is needed:
        if newCategory || newTag || (Globals.shared.media.active?.need.sorting == true) || (Globals.shared.media.active?.need.grouping == true) {
            Thread.onMain { [weak self] in 
                // Pop to the root view controller
                // And show the change
                nvc.popToRootViewController(animated: false)
                
                mtvc.display.clear()
                
                mtvc.tableView?.reloadData()
                
                mtvc.startAnimating()
                
                mtvc.barButtonItems(isEnabled: false)
            }
            
            if (Globals.shared.media.search.isActive) {
                // If a search is active, update the results.
                mtvc.updateSearchResults(Globals.shared.media.active?.context,completion: nil)
            }
            
            // Show the results.
            mtvc.display.setup(Globals.shared.media.active)
            
            Thread.onMain { [weak self] in 
                mtvc.tableView?.reloadData()
                
                let indexPath = IndexPath(row:0,section:0)
                if mtvc.tableView.isValid(indexPath) {
                    mtvc.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
                
                //                                    mtvc.selectOrScrollToMediaItem(mtvc.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                
                mtvc.stopAnimating()
                
                mtvc.updateUI()
                
                // Need to update the MVC cells.
                if let isCollapsed = mtvc.splitViewController?.isCollapsed, !isCollapsed {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
                }
            }
        } else {
            // No new category or tag.
            Thread.onMain { [weak self] in 
                let indexPath = IndexPath(row:0,section:0) // Top of the list.
                if mtvc.tableView.isValid(indexPath) {
                    mtvc.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                }
            }
        }

        // If the url contains a media code, segue to it.
        if let mediaCode = Globals.shared.media.goto, !mediaCode.isEmpty {
            if let mediaItem = Globals.shared.media.repository.index[mediaCode] {
                Thread.onMain { [weak self] in 
                    nvc.popToRootViewController(animated: false)
                }
                
                mtvc.selectedMediaItem = mediaItem
                mtvc.selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: .top)
                
                // Delay required for iPhone
                // Delay so UI works correctly.
                DispatchQueue.global(qos: .background).async { [weak self] in
                    Thread.onMain { [weak self] in 
                        mtvc.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    }
                }
                
                Globals.shared.media.goto = nil
            } else {
//                Alerts.shared.alert(title: "Got mediaCode to open later: \(parts[1])")
            }
        }
        
        return true
    }
    
    // This is called (at least) when the SVC is collapsed or expanded.
    // Use that to update the MVC view (e.g. how a document is shown).
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode
    {
        guard UIApplication.shared.applicationState == .active else {
            return UISplitViewController.DisplayMode.automatic
        }
        
        Thread.onMain { [weak self] in 
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
        }
        
        return UISplitViewController.DisplayMode.automatic
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        guard let svc = window?.rootViewController as? UISplitViewController else {
            return false
        }
        
        FirebaseApp.configure()

        svc.delegate = self
        svc.preferredDisplayMode = .allVisible

        VoiceBase.checkAvailability()
        
        let hClass = svc.traitCollection.horizontalSizeClass
        let vClass = svc.traitCollection.verticalSizeClass
        
        if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
            if let navigationController = svc.viewControllers[svc.viewControllers.count - 1] as? UINavigationController {
                navigationController.topViewController?.navigationItem.leftBarButtonItem = svc.displayModeButtonItem
            }
        }

        Globals.shared.addAccessoryEvents()
        
        startAudio()
        
//        Alerts.shared.alert(title: "Finished Launching")

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if Globals.shared.mediaPlayer.isPlaying, Globals.shared.mediaPlayer.mediaItem?.playing == Playing.video, Globals.shared.mediaPlayer.pip != .started {
            Globals.shared.mediaPlayer.pause()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

        // Do we need to do this for audio? NO.
        if Globals.shared.mediaPlayer.mediaItem?.playing == Playing.video, Globals.shared.mediaPlayer.rate == 0, Globals.shared.mediaPlayer.isPaused, Globals.shared.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM) {
            // Is this the way to solve the dropped connection after an extended pause?  Might not since the app might stay in the foreground, but this will probably cover teh vast majority of the cases.
            
            if (Globals.shared.mediaPlayer.mediaItem != nil) { // && Globals.shared.mediaPlayer.mediaItem!.hasVideo && (Globals.shared.mediaPlayer.mediaItem!.playing == Playing.video)
                Globals.shared.mediaPlayer.playOnLoad = false
                Globals.shared.mediaPlayer.reload()
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        Globals.shared.mediaPlayer.setupPlayingInfoCenter()
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        /*
        In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
        */
        
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        
//        var filename:String?
//        filename = String(identifier[Constants.DOWNLOAD_IDENTIFIER.endIndex...])
        
        if let range = identifier.range(of: ":") {
            let filename = String(identifier[range.upperBound...])
            
            if let mediaItems = Globals.shared.media.repository.list {
                for mediaItem in mediaItems {
                    if let download = mediaItem.downloads?.filter({ (key:String, value:Download) -> Bool in
                        //                print("handleEventsForBackgroundURLSession: \(filename) \(key)")
                        return value.task?.taskDescription == filename
                    }).first?.value {
                        download.session = URLSession(configuration: configuration, delegate: download, delegateQueue: nil)
                        download.completionHandler = completionHandler
                        break
                    }
                }
            }
        }
    }
}

