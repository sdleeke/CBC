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

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else { return false }
        if topAsDetailController.selectedSermon == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
    var window: UIWindow?
    
    /* Not ready for release

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
    {
        // This should be rationalized with the code in MediaTableViewController to have one function (somewhere) so we aren't duplicating it.

//        let host = url.host
//        let scheme = url.scheme
//        let path = url.path
        
//        println("Host: \(url.host) Scheme: \(url.scheme) Path: \(url.path) Query: \(url.query)")
//        println("BaseURL: \(url.baseURL) PathComponents: \(url.pathComponents)")
//        println("AbsoluteURL: \(url.absoluteURL) PathExtension: \(url.pathExtension) RelativePath: \(url.relativePath)")

        var sermonTag:String?
        
        if (url.host != nil) && (url.host != Constants.EMPTY_STRING) {
            sermonTag = url.host
        }
        
//        println("tag: \(sermonTag)")
        
        var query = url.query
        var valueSet = Set<String>()
        
        if (query != nil) {
            let amp:String = "&"
            var value:String?
            
            while (query?.rangeOfString(amp) != nil) {
                value = query!.substringToIndex(query!.rangeOfString(amp)!.startIndex)
                valueSet.insert(value!)
                query = query!.substringFromIndex(query!.rangeOfString(amp)!.endIndex)
            }
        }
        
//        println("query: \(query)")

        if (query != nil) {
            valueSet.insert(query!)
        }
        
//        println("valueSet: \(valueSet)")
        
        var parameterArray = [(String,String)]()

        var sorting:String?
        var grouping:String?
        var searchString:String?
        
        let equals:String = "="
        for value in valueSet {
            let parameter = value.substringToIndex(value.rangeOfString(equals)!.startIndex)
            let setting = value.substringFromIndex(value.rangeOfString(equals)!.endIndex)
            parameterArray.append((parameter,setting))
            
            switch parameter.substringToIndex("a".endIndex) {
            case "q":
                searchString = setting
                break
                
            case "s":
                switch setting.substringToIndex("a".endIndex) {
                case "c":
                    sorting = Constants.CHRONOLOGICAL
                    break
                    
                case "r":
                    sorting = Constants.REVERSE_CHRONOLOGICAL
                    break
                    
                default:
                    break
                }
                break
                
            case "g":
                switch setting.substringToIndex("a".endIndex) {
                case "y":
                    grouping = Constants.YEAR
                    break
                    
                case "s":
                    grouping = Constants.SERIES
                    break
                    
                case "b":
                    grouping = Constants.BOOK
                    break
                    
                default:
                    break
                }
                break
                
            default:
                break
            }

//            println("parameter: \(parameter) setting: \(setting)")
        }
        
//        println("parameterArray: \(parameterArray)")

        //We only support one path component, a series name, a sermon title, or a book of the Bible
        //We do NOT support specifying what that path component is, we have to simply try to find the series, sermon, or book
        //If that least to more than one of those being found, then the order of search will determine which is selected, which 
        //doesn't seem like a good idea.
        //
        //Seems like it would be better to explicitly define the path.  E.g. the urls can only start with either cbc://all? or cbc://<tag>?
        //and then use sermon= (which would have to be distinguished form sorting since they both start with "s") and book= and series=
        //to distinguish them.
        //
        //If we want to go the explicit definition path rather than implicit, then we'll have to rework all of this code (in both places, here
        //and in MediaTableViewController, to pull the series, book, or sermon from the query string.
        //
        //One reason the single path component model is better is that it means that only one (assuming order of search breaks any ties) will ever
        //be found.  With explicit definition we could have all three and then have to make a decision about what that means.  They might or might not
        //be compatible.  E.g. the sermon might or might not appear in the series or book, the series might or might appear in the book, the sermon
        //might or might not be part of a series.
        //
        //Leave it alone for now.  The odds of a conflict between a sermon title, series name, and book are pretty slim since sermon titles, while they 
        //may include a series name (which, in fact, they will if they are part of a series), they also include more, e.g. " (Part n)", and if they 
        //include a book name they will almost certainly include more, but perhaps not.  Let's save that problem for later.
        //
        //Note that to find a sermon by date a search query could be used.  Lots of things could be done to this, but it works for series, sermons, and books
        //right now, an that is enough.
        
        var path:String?
        
        if (url.pathComponents?.count >= 2) {
            path = url.pathComponents![1] as String
        }
        
        if (!globals.loadedEnoughToDeepLink) {
            globals.deepLinkWaiting = true
            globals.deepLink.path = path
            globals.deepLink.searchString = searchString
            globals.deepLink.sorting = sorting
            globals.deepLink.grouping = grouping
            globals.deepLink.tag = sermonTag
        } else {
            var sermonSelected:Sermon?

            var seriesSelected:String?
            var firstSermonInSeries:Sermon?
            
            var bookSelected:String?
            var firstSermonInBook:Sermon?
            
//            var seriesIndexPath = NSIndexPath()
            
            if (path != nil) {
//                println("path: \(path)")
                
                // Is it a series?
                if let sermonSeries = seriesSectionsFromSermons(globals.sermons) {
                    for sermonSeries in sermonSeries {
//                        println("sermonSeries: \(sermonSeries)")
                        if (sermonSeries == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //It is a series
                            seriesSelected = sermonSeries
                            break
                        }
                    }
                    
                    if (seriesSelected != nil) {
                        var sermonsInSelectedSeries = sermonsInSermonSeries(globals.sermons,series: seriesSelected!)

                        if (sermonsInSelectedSeries?.count > 0) {
                            if let firstSermonIndex = globals.sermons!.indexOf(sermonsInSelectedSeries![0]) {
                                firstSermonInSeries = globals.sermons![firstSermonIndex]
                                //                            println("firstSermon: \(firstSermon)")
                            }
                        }
                    }
                }
                
                if (seriesSelected == nil) {
                    // Is it a sermon?
                    for sermon in globals.sermons! {
                        if (sermon.title == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //Found it
                            sermonSelected = sermon
                            break
                        }
                    }
                    //                        println("\(sermonSelected)")
                }

                if (seriesSelected == nil) && (sermonSelected == nil) {
                        // Is it a book?
                    if let sermonBooks = bookSectionsFromSermons(globals.sermons) {
                        for sermonBook in sermonBooks {
                            //                        println("sermonBook: \(sermonBook)")
                            if (sermonBook == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                                //It is a series
                                bookSelected = sermonBook
                                break
                            }
                        }
                        
                        if (bookSelected != nil) {
                            var sermonsInSelectedBook = sermonsInBook(globals.sermons,book: bookSelected!)
                            
                            if (sermonsInSelectedBook?.count > 0) {
                                if let firstSermonIndex = globals.sermons!.indexOf(sermonsInSelectedBook![0]) {
                                    firstSermonInBook = globals.sermons![firstSermonIndex]
                                    //                            println("firstSermon: \(firstSermon)")
                                }
                            }
                        }
                    }
                }
            }
            
            if (sorting != nil) {
                globals.sorting = sorting!
            }
            if (grouping != nil) {
                globals.grouping = grouping!
            }
            
            if (sermonTag != nil) {
                var taggedSermons = [Sermon]()
                
                if (sermonTag != Constants.ALL) {
                    globals.sermonTagsSelected = sermonTag!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)
//                    println("\(globals.sermonTagsSelected)")
                    globals.showing = Constants.TAGGED
                    
                    for sermon in globals.sermons! {
                        if (sermon.tags?.rangeOfString(globals.sermonTagsSelected!) != nil) {
                            taggedSermons.append(sermon)
                        }
                    }
                    
                    globals.taggedSermons = taggedSermons.count > 0 ? taggedSermons : nil
                } else {
                    globals.showing = Constants.ALL
                    globals.sermonTagsSelected = nil
                }
            }
            
            //In case globals.searchActive is true at the start we need to cancel it.
            globals.searchActive = false
            globals.searchSermons = nil
            
            if (searchString != nil) {
                globals.searchActive = true
                globals.searchSermons = nil
                
                if let sermons = globals.sermonsToSearch {
                    var searchSermons = [Sermon]()
                    
                    for sermon in sermons {
                        if (
                            ((sermon.title?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                ((sermon.date?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                ((sermon.series?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                ((sermon.scripture?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                ((sermon.tags?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                            )
                        {
                            searchSermons.append(sermon)
                        }
                    }
                    
                    globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
                }
            }
            
            globals.sermonsNeed.groupsSetup = true
            sortAndGroupSermons()

            var tvc:MediaTableViewController?
            
            //iPad
            if let rvc = self.window?.rootViewController as? UISplitViewController {
                //            println("rvc = UISplitViewController")
                if let nvc = rvc.viewControllers[0] as? UINavigationController {
                    //                println("nvc = UINavigationController")
                    tvc = nvc.topViewController as? MediaTableViewController
                }
                if let nvc = rvc.viewControllers[1] as? UINavigationController {
                    //                println("nvc = UINavigationController")
                    if let myvc = nvc.topViewController as? MediaViewController {
                        if (sorting != nil) {
                            //Sort the sermonsInSeries
                            myvc.sortSermonsInSeries()
                        }
                    }
                }
            }
            
            //iPhone
            if let nvc = self.window?.rootViewController as? UINavigationController {
                //            println("rvc = UINavigationController")
                if let _ = nvc.topViewController as? MediaViewController {
//                    print("myvc = MediaViewController")
                    nvc.popToRootViewControllerAnimated(true)
                }
                tvc = nvc.topViewController as? MediaTableViewController
            }
            
            if (tvc != nil) {
                // All of the scrolling below becomes a problem in portrait on an iPad as the master view controller TVC may not be visible
                // AND when it is made visible it is setup to first scroll to current selection.
                
                //                println("tvc = MediaTableViewController")
                
                //            tvc.performSegueWithIdentifier("Show Sermon", sender: tvc)
                
                tvc!.tableView.reloadData()
                
                if (globals.sermonTagsSelected != nil) {
                    tvc!.searchBar.placeholder = globals.sermonTagsSelected!
                    
                    //Show the search bar
                    tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
                } else {
                    tvc!.searchBar.placeholder = nil
                }
                
                if (searchString != nil) {
                    tvc!.searchBar.text = searchString!
                    tvc!.searchBar.showsCancelButton = true
                    
                    //Show the search bar
                    tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
                } else {
                    tvc!.searchBar.text = nil
                    tvc!.searchBar.showsCancelButton = false
                }
                
                //It should never occur that more than one of the following conditionals are true
                
                if (firstSermonInSeries != nil) {
                    tvc?.selectOrScrollToSermon(firstSermonInSeries, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                }
                
                if (firstSermonInBook != nil) {
                    tvc?.selectOrScrollToSermon(firstSermonInBook, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                }
                
                if (sermonSelected != nil) {
                    tvc?.selectOrScrollToSermon(sermonSelected, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                }
            }
        }
        
        return true
    }
    
    */
    
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
            print("failed to setCategory(AVAudioSessionCategoryPlayback)")
        }
        
        do {
            //        audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error:nil)
            try audioSession.setActive(true)
        } catch _ {
            print("failed to audioSession.setActive(true)")
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        globals = Globals()
        
        let cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(cache)
        
        startAudio()
        
        globals.addAccessoryEvents()
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        globals.player.observer = NSTimer.scheduledTimerWithTimeInterval(Constants.PLAYER_TIMER_INTERVAL, target: self, selector: #selector(AppDelegate.playerTimer), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.mpPlayerLoadStateDidChange), name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        print("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("applicationWillEnterForeground")

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
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
        })
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        println("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("applicationWillTerminate")
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void)
    {
        print("application:handleEventsForBackgroundURLSession")
        
        /*
        In iOS, when a background transfer completes or requires credentials, if your app is no longer running, iOS automatically relaunches your app in the background and calls the application:handleEventsForBackgroundURLSession:completionHandler: method on your app’s UIApplicationDelegate object. This call provides the identifier of the session that caused your app to be launched. Your app should store that completion handler, create a background configuration object with the same identifier, and create a session with that configuration object. The new session is automatically reassociated with ongoing background activity. Later, when the session finishes the last background download task, it sends the session delegate a URLSessionDidFinishEventsForBackgroundURLSession: message. Your session delegate should then call the stored completion handler.
        */
        
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        configuration.sessionSendsLaunchEvents = true
        
        var filename:String?
        
        filename = identifier.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        for sermon in globals.sermonRepository.list! {
            if let download = sermon.downloads.filter({ (key:String, value:Download) -> Bool in
                //                print("handleEventsForBackgroundURLSession: \(filename) \(key)")
                return value.task?.taskDescription == filename
            }).first?.1 {
                download.session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
                download.completionHandler = completionHandler
                break
            }
        }
    }
}

