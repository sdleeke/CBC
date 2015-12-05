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
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioSessionDelegate, NSURLSessionDownloadDelegate {

    var window: UIWindow?
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
    }
    
    func testSermonsAudioFiles()
    {
        print("Testing the availability of sermon audio that we DO have in the sermonDicts - start")
        
        //This function doesn't work when the session and downloadTasks array aren't in Globals.  Not sure why.
        //Also tried to put the downloadTask partial downloading in the first loop where the download task is created
        //and couldn't get it to work.  That failure may have been related to not using Globals for session and downloadTasks.  I don't know.
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
        
        var counter = 1
        var downloadTasks = [NSURLSessionDownloadTask]()
        
        for sermon in Globals.sermons! {
            print("Testing \(counter) \(sermon.title!)")
            
            if (sermon.hasAudio()) {
                print("No Audio file for: \(sermon.title)")
            } else {
                let audioURL = Constants.BASE_AUDIO_URL + sermon.audio!
                let downloadRequest = NSMutableURLRequest(URL: NSURL(string: audioURL)!)

                var downloadTask : NSURLSessionDownloadTask
                downloadTask = session.downloadTaskWithRequest(downloadRequest)
                downloadTask.taskDescription = sermon.date! + Constants.SINGLE_SPACE_STRING + sermon.service! + Constants.SINGLE_SPACE_STRING + sermon.title!

                //Don't do this here as we need the complete list of sermons tasks for downloading so we can find the one that fails to download
                //                downloadTask.resume()
                downloadTasks.append(downloadTask)
            }
            
            counter++
        }

        counter = 1
        for downloadTask in downloadTasks {
            downloadTask.resume()
            
            var whileCount = 1
            repeat {
                //Stop as soon as we konw we can download from the file.
                //Which means that if we can't download we'll be stuck in this loop and we'll know which one
                //didn't download by finding the last println before the hang and finding that in the
                //list of downloadTasks being created and it will be the next one that failed.
                
                //If the download stops, sleep more.
                NSThread.sleepForTimeInterval(0.5 * Double(whileCount))
                
                whileCount++
            } while (downloadTask.countOfBytesReceived == 0) || (downloadTask.countOfBytesExpectedToReceive == 0)
            
            //Let the user know
            print("Downloaded \(counter) \(downloadTask.countOfBytesReceived) of \(downloadTask.countOfBytesExpectedToReceive) for \(downloadTask.taskDescription)")
            
            //Then cancel the task and go on to the next
            downloadTask.cancel()
            
            counter++
        }
        
        session.invalidateAndCancel()
        
        print("Testing the availability of sermon audio that we DO have in the sermonDicts - end")
    }
    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        let player = notification.object as! MPMoviePlayerController
        
        /* Enough data has been buffered for playback to continue uninterrupted. */
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        let loadvalue:UInt8 = UInt8(MPMovieLoadState.PlaythroughOK.rawValue)
        
        // If there is a sermon that was playing before and we want to start back at the same place,
        // the PlayPause button must NOT be active until loadState & PlaythroughOK == 1.
        
        //        println("\(loadstate)")
        //        println("\(loadvalue)")
        
        if ((loadstate & loadvalue) == (1<<1)) {
            print("AppDelegate mpPlayerLoadStateDidChange.MPMovieLoadState.PlaythroughOK")
            //should be called only once, only for  first time audio load.
            if(!Globals.sermonLoaded) {
                print("\(Globals.sermonPlaying!.currentTime!)")
                print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
                
                let defaults = NSUserDefaults.standardUserDefaults()
                if let currentTime = defaults.stringForKey(Constants.CURRENT_TIME) {
                    Globals.sermonPlaying!.currentTime = currentTime
                }

                print("\(Globals.sermonPlaying!.currentTime!)")
                print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")

                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
                
                var myvc:MyViewController?
                
                //iPad
                if let rvc = self.window?.rootViewController as? UISplitViewController {
                    //            println("rvc = UISplitViewController")
                    if let nvc = rvc.viewControllers[1] as? UINavigationController {
                        myvc = nvc.topViewController as? MyViewController
                    }
                }
                
                //iPhone
                if let rvc = self.window?.rootViewController as? UINavigationController {
                    //            println("rvc = UINavigationController")
                    myvc = rvc.topViewController as? MyViewController
                }
                
                if (myvc != nil) {
                    //                    println("myvc = MyViewController")
                    myvc!.spinner.stopAnimating()
                }
                
                Globals.sermonLoaded = true
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }


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
            
            Globals.sermonsNeedGroupsSetup = true
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
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let cache = NSURLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(cache)
        
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        
        do {
            //        audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error:nil)
            try audioSession.setActive(true)
        } catch _ {
        }

        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        let sermonDicts = loadSermonDicts()
        Globals.sermons = sermonsFromSermonDicts(sermonDicts)
        Globals.sermonTags = tagsFromSermons(Globals.sermons)
        
        if Globals.testing {
            testSermonsTagsAndSeries()
            
            testSermonsBooksAndSeries()

            testSermonsForSeries()
           
            //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
            testSermonsPDFs(testExisting: false, testMissing: true, showTesting: false)

            //Test whether the audio starts to download
            //If we can download at all, we assume we can download it all, which allows us to test all sermons to see if they can be downloaded/played.
            testSermonsAudioFiles()
        }

        loadDefaults()

        Globals.sermonsNeedGroupsSetup = true
        sortAndGroupSermons()
        
        setupSermonPlaying()

        return true
    }

    func setupSermonPlaying()
    {
        setupPlayer(Globals.sermonPlaying)
        
        if (!Globals.sermonLoaded) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        println("applicationWillResignActive")
        setupPlayingInfoCenter()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        println("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        println("applicationWillEnterForeground")

        setupPlayingInfoCenter()

        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            updateUserDefaultsCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
        //iPad
        if let rvc = self.window?.rootViewController as? UISplitViewController {
            if let nvc = rvc.viewControllers[1] as? UINavigationController {
                if let myvc = nvc.topViewController as? MyViewController {
                    myvc.setupPlayPauseButton()
                }
            }
        }
        
        //iPhone
        if let rvc = self.window?.rootViewController as? UINavigationController {
            if let myvc = rvc.topViewController as? MyViewController {
                myvc.setupPlayPauseButton()
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        println("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        println("applicationWillTerminate")
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
        
        for sermon in Globals.sermons! {
            if (sermon.audio == filename) {
                sermon.download.session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
                sermon.download.completionHandler = completionHandler
                //Do we need to recreate the downloadTask for this session?
            }
        }
    }
}

