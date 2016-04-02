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
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate { //, NSURLSessionDownloadDelegate {

    var window: UIWindow?
    
    /* Not ready for release

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
    {
        // This should be rationalized with the code in MyTableViewController to have one function (somewhere) so we aren't duplicating it.

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
        //and in MyTableViewController, to pull the series, book, or sermon from the query string.
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
        
        if (!Globals.loadedEnoughToDeepLink) {
            Globals.deepLinkWaiting = true
            Globals.deepLink.path = path
            Globals.deepLink.searchString = searchString
            Globals.deepLink.sorting = sorting
            Globals.deepLink.grouping = grouping
            Globals.deepLink.tag = sermonTag
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
                if let sermonSeries = seriesSectionsFromSermons(Globals.sermons) {
                    for sermonSeries in sermonSeries {
//                        println("sermonSeries: \(sermonSeries)")
                        if (sermonSeries == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //It is a series
                            seriesSelected = sermonSeries
                            break
                        }
                    }
                    
                    if (seriesSelected != nil) {
                        var sermonsInSelectedSeries = sermonsInSermonSeries(Globals.sermons,series: seriesSelected!)

                        if (sermonsInSelectedSeries?.count > 0) {
                            if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedSeries![0]) {
                                firstSermonInSeries = Globals.sermons![firstSermonIndex]
                                //                            println("firstSermon: \(firstSermon)")
                            }
                        }
                    }
                }
                
                if (seriesSelected == nil) {
                    // Is it a sermon?
                    for sermon in Globals.sermons! {
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
                    if let sermonBooks = bookSectionsFromSermons(Globals.sermons) {
                        for sermonBook in sermonBooks {
                            //                        println("sermonBook: \(sermonBook)")
                            if (sermonBook == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                                //It is a series
                                bookSelected = sermonBook
                                break
                            }
                        }
                        
                        if (bookSelected != nil) {
                            var sermonsInSelectedBook = sermonsInBook(Globals.sermons,book: bookSelected!)
                            
                            if (sermonsInSelectedBook?.count > 0) {
                                if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedBook![0]) {
                                    firstSermonInBook = Globals.sermons![firstSermonIndex]
                                    //                            println("firstSermon: \(firstSermon)")
                                }
                            }
                        }
                    }
                }
            }
            
            if (sorting != nil) {
                Globals.sorting = sorting!
            }
            if (grouping != nil) {
                Globals.grouping = grouping!
            }
            
            if (sermonTag != nil) {
                var taggedSermons = [Sermon]()
                
                if (sermonTag != Constants.ALL) {
                    Globals.sermonTagsSelected = sermonTag!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)
//                    println("\(Globals.sermonTagsSelected)")
                    Globals.showing = Constants.TAGGED
                    
                    for sermon in Globals.sermons! {
                        if (sermon.tags?.rangeOfString(Globals.sermonTagsSelected!) != nil) {
                            taggedSermons.append(sermon)
                        }
                    }
                    
                    Globals.taggedSermons = taggedSermons.count > 0 ? taggedSermons : nil
                } else {
                    Globals.showing = Constants.ALL
                    Globals.sermonTagsSelected = nil
                }
            }
            
            //In case Globals.searchActive is true at the start we need to cancel it.
            Globals.searchActive = false
            Globals.searchSermons = nil
            
            if (searchString != nil) {
                Globals.searchActive = true
                Globals.searchSermons = nil
                
                if let sermons = Globals.sermonsToSearch {
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
                    
                    Globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
                }
            }
            
            Globals.sermonsNeed.groupsSetup = true
            sortAndGroupSermons()

            var tvc:MyTableViewController?
            
            //iPad
            if let rvc = self.window?.rootViewController as? UISplitViewController {
                //            println("rvc = UISplitViewController")
                if let nvc = rvc.viewControllers[0] as? UINavigationController {
                    //                println("nvc = UINavigationController")
                    tvc = nvc.topViewController as? MyTableViewController
                }
                if let nvc = rvc.viewControllers[1] as? UINavigationController {
                    //                println("nvc = UINavigationController")
                    if let myvc = nvc.topViewController as? MyViewController {
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
                if let _ = nvc.topViewController as? MyViewController {
//                    print("myvc = MyViewController")
                    nvc.popToRootViewControllerAnimated(true)
                }
                tvc = nvc.topViewController as? MyTableViewController
            }
            
            if (tvc != nil) {
                // All of the scrolling below becomes a problem in portrait on an iPad as the master view controller TVC may not be visible
                // AND when it is made visible it is setup to first scroll to current selection.
                
                //                println("tvc = MyTableViewController")
                
                //            tvc.performSegueWithIdentifier("Show Sermon", sender: tvc)
                
                tvc!.tableView.reloadData()
                
                if (Globals.sermonTagsSelected != nil) {
                    tvc!.searchBar.placeholder = Globals.sermonTagsSelected!
                    
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
        if (Globals.mpPlayer?.contentURL != NSURL(string: Constants.LIVE_STREAM_URL)) {
//            print("mpPlayerLoadStateDidChange")
            
            let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
//            if playable {
//                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable")
//            }
//            
//            if playthrough {
//                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough")
//            }
            
            //        print("\(loadstate)")
            //        print("\(playable)")
            //        print("\(playthrough)")
            
            if (playable || playthrough) {
//                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough OK")
                if !Globals.sermonLoaded {
                    print("mpPlayerLoadStateDidChange with sermonPlaying NOT LOADED and playable || playthrough!")

                    if (Globals.sermonPlaying != nil) && Globals.sermonPlaying!.hasCurrentTime() {
                        if (Int(Float(Globals.sermonPlaying!.currentTime!)!) == Int(Float(Globals.mpPlayer!.duration))) { // !Globals.loadingFromLive && 
                            print("mpPlayerLoadStateDidChange Globals.sermonPlaying!.currentTime reset to 0!")
                            Globals.sermonPlaying!.currentTime = Constants.ZERO
                        } else {
                            
//                            print(Globals.sermonPlaying!.currentTime!)
//                            print(Float(Globals.sermonPlaying!.currentTime!)!)
                            
                            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
                        }
                    } else {
                        print("mpPlayerLoadStateDidChange selectedSermon has NO currentTime!")
                        Globals.sermonPlaying?.currentTime = Constants.ZERO
                        Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                    }
                    
                    setupPlayingInfoCenter()
                    
                    Globals.sermonLoaded = true
                    
                    if (Globals.playOnLoad) {
                        Globals.playerPaused = false
                        
                        Globals.mpPlayer?.play()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                        })
                    } else {
                        Globals.playOnLoad = true
//                        Globals.playerPaused = true
                    }
                } else {
                    print("mpPlayerLoadStateDidChange with sermonPlaying LOADED and playable || playthrough!")
                }
            }
            
            if !(playable || playthrough) && (Globals.mpPlayerStateTime?.state == .playing) && (Globals.mpPlayerStateTime?.timeElapsed > Constants.MIN_PLAY_TIME) {
//                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough NOT OK")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                })
            }
            
//            switch Globals.mpPlayer!.playbackState {
//            case .Playing:
//                print("mpPlayerLoadStateDidChange.Playing")
//                break
//                
//            case .SeekingBackward:
//                print("mpPlayerLoadStateDidChange.SeekingBackward")
//                break
//                
//            case .SeekingForward:
//                print("mpPlayerLoadStateDidChange.SeekingForward")
//                break
//                
//            case .Stopped:
//                print("mpPlayerLoadStateDidChange.Stopped")
//                break
//                
//            case .Interrupted:
//                print("mpPlayerLoadStateDidChange.Interrupted")
//                break
//                
//            case .Paused:
//                print("mpPlayerLoadStateDidChange.Paused")
//                break
//            }
        }
    }
    
    func playerTimer()
    {
        if (Globals.mpPlayer != nil) && (Globals.mpPlayer?.contentURL != NSURL(string: Constants.LIVE_STREAM_URL)) {
            let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
//            if playable && debug {
//                print("playTimer.MPMovieLoadState.Playable")
//            }
//            
//            if playthrough && debug {
//                print("playTimer.MPMovieLoadState.Playthrough")
//            }
            
            if (Globals.mpPlayer!.fullscreen) {
                Globals.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
            } else {
                Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            }
            
            if (Globals.mpPlayer?.currentPlaybackRate > 0) {
                updateCurrentTimeWhilePlaying()
            }
            
            switch Globals.mpPlayerStateTime!.state {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                switch Globals.mpPlayer!.playbackState {
                case .SeekingBackward:
//                    print("playTimer.playing.SeekingBackward")
                    Globals.mpPlayerStateTime!.state = .seekingBackward
                    break
                    
                case .SeekingForward:
//                    print("playTimer.playing.SeekingForward")
                    Globals.mpPlayerStateTime!.state = .seekingForward
                    break
                    
                default:
                    if (UIApplication.sharedApplication().applicationState != UIApplicationState.Background) {
                        if (Globals.mpPlayer!.duration > 0) && (Globals.mpPlayer!.currentPlaybackTime > 0) &&
                            (Int(Float(Globals.mpPlayer!.currentPlaybackTime)) == Int(Float(Globals.mpPlayer!.duration))) {
                                Globals.mpPlayer?.pause()
                                Globals.playerPaused = true
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                                })
                                
                                if (Globals.sermonPlaying?.currentTime != Globals.mpPlayer!.duration.description) {
                                    Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
                                }
                        } else {
                            Globals.mpPlayer?.play()
                        }
                        
                        if !(playable || playthrough) { // Globals.mpPlayer?.currentPlaybackRate == 0
//                            print("playTimer.Playthrough or Playing NOT OK")
                            if (Globals.mpPlayerStateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
                                Globals.sermonLoaded = true
                                Globals.playerPaused = true
                                Globals.mpPlayer?.pause()
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                                })
                                
                                let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                                errorAlert.show()
                            }
                        }
                        if (playable || playthrough) {
//                            print("playTimer.Playthrough or Playing OK")
                        }
                    } else {
                        if Globals.sermonPlaying?.playing == Constants.VIDEO {
                            Globals.mpPlayer?.pause()
                            
                            updateCurrentTimeExact()

                            Globals.playerPaused = true

                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                        }
                    }
                    break
                }
                break
                
            case .paused:
//                print("paused")
                
                if !Globals.sermonLoaded {
                    if (Globals.mpPlayerStateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
                        Globals.sermonLoaded = true
                        
                        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        }
                    }
                }
                
                switch Globals.mpPlayer!.playbackState {
                case .Paused:
//                    print("playTimer.paused.Paused")
                    break
                    
                default:
                    Globals.mpPlayer?.pause()
                    break
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                switch Globals.mpPlayer!.playbackState {
                case .Playing:
//                    print("playTimer.seekingForward.Playing")
                    Globals.mpPlayerStateTime!.state = .playing
                    break
                    
                case .Paused:
//                    print("playTimer.seekingForward.Paused")
                    Globals.mpPlayerStateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                switch Globals.mpPlayer!.playbackState {
                case .Playing:
//                    print("playTimer.seekingBackward.Playing")
                    Globals.mpPlayerStateTime!.state = .playing
                    break
                    
                case .Paused:
//                    print("playTimer.seekingBackward.Paused")
                    Globals.mpPlayerStateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
            }
            
            if (Globals.mpPlayer != nil) {
                switch Globals.mpPlayer!.playbackState {
                case .Interrupted:
//                    print("playTimer.Interrupted")
                    break
                    
                case .Paused:
//                    print("playTimer.Paused")
                    break
                    
                case .Playing:
//                    print("playTimer.Playing")
                    break
                    
                case .SeekingBackward:
//                    print("playTimer.SeekingBackward")
                    break
                    
                case .SeekingForward:
//                    print("playTimer.SeekingForward")
                    break
                    
                case .Stopped:
//                    print("playTimer.Stopped")
                    break
                }
            }
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(cache)
        
        startAudio()
        
        addAccessoryEvents()
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        Globals.playerObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.PLAYER_TIMER_INTERVAL, target: self, selector: #selector(AppDelegate.playerTimer), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(UIApplication.sharedApplication().delegate!, selector: #selector(AppDelegate.mpPlayerLoadStateDidChange), name: MPMoviePlayerLoadStateDidChangeNotification, object: nil)

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

        setupPlayingInfoCenter()

        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            updateCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
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
        
        for sermon in Globals.sermonRepository.list! {
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

