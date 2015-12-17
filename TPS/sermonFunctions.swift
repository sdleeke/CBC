//
//  sermonFunctions.swift
//  TPS
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

typealias GroupTuple = (indexes: [Int]?, counts: [Int]?)

func documentsURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
}

func checkFile(url:NSURL?) -> Bool
{
    var result = false
    
    if (url != nil) && Reachability.isConnectedToNetwork() {
        let downloadRequest = NSMutableURLRequest(URL: url!)
        
        let session:NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)
        
        let downloadTask = session.downloadTaskWithRequest(downloadRequest)
        downloadTask.taskDescription = url?.lastPathComponent
        
        downloadTask.resume()
        
        var count = 0
        repeat {
            NSThread.sleepForTimeInterval(Constants.CHECK_FILE_SLEEP_INTERVAL)
            if (downloadTask.countOfBytesReceived > 0) && (downloadTask.countOfBytesExpectedToReceive > 0) {
                result = true
                break
            } else {
                count++
            }
            print("Downloaded \(count) \(downloadTask.countOfBytesReceived) of \(downloadTask.countOfBytesExpectedToReceive) for \(downloadTask.taskDescription)")
        } while (count < Constants.CHECK_FILE_MAX_ITERATIONS) && (downloadTask.countOfBytesExpectedToReceive != -1)
        
        downloadTask.cancel()
        
        session.invalidateAndCancel()
    }
    
    return result
}

func checkFileInBackground(url:NSURL?,completion: (() -> Void)?)
{
    if (url != nil) && Reachability.isConnectedToNetwork() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            var result = false
            
            let downloadRequest = NSMutableURLRequest(URL: url!)
            
            let session:NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)
            
            let downloadTask = session.downloadTaskWithRequest(downloadRequest)
            downloadTask.taskDescription = url?.lastPathComponent
            
            downloadTask.resume()
            
            var count = 0
            repeat {
                NSThread.sleepForTimeInterval(Constants.CHECK_FILE_SLEEP_INTERVAL)
                if (downloadTask.countOfBytesReceived > 0) && (downloadTask.countOfBytesExpectedToReceive > 0) {
                    result = true
                    break
                } else {
                    count++
                }
                print("Downloaded \(count) \(downloadTask.countOfBytesReceived) of \(downloadTask.countOfBytesExpectedToReceive) for \(downloadTask.taskDescription)")
            } while (count < Constants.CHECK_FILE_MAX_ITERATIONS) && (downloadTask.countOfBytesExpectedToReceive != -1)
            
            downloadTask.cancel()
            
            session.invalidateAndCancel()
            
            if (result) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion?()
                })
            }
        })
    }
}

func removeTempFiles()
{
    // Clean up temp directory for cancelled downloads
    let fileManager = NSFileManager.defaultManager()
    let path = NSTemporaryDirectory()
    do {
        let array = try fileManager.contentsOfDirectoryAtPath(path)
        
        for name in array {
            if (name.rangeOfString(Constants.TMP_FILENAME_EXTENSION)?.endIndex == name.endIndex) {
                print("Deleting: \(name)")
                try fileManager.removeItemAtPath(path + name)
            }
        }
    } catch _ {
    }
}

func jsonDataFromURL() -> JSON
{
    if let url = NSURL(string: Constants.JSON_URL_PREFIX + Constants.CBC_SHORT.lowercaseString + "." + Constants.SERMONS_JSON_FILENAME) {
        do {
            let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }
    
    return nil
}

func jsonDataFromBundle() -> JSON
{
    if let path = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE) {
        do {
            let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }

    return nil
}

func jsonToDocumentsDirectory()
{
    let fileManager = NSFileManager.defaultManager()
    
    let jsonBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE)
    
    if let jsonDocumentsURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        // Check if file exist
        if (!fileManager.fileExistsAtPath(jsonDocumentsURL.path!)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonDocumentsURL.path!)
                } catch _ {
                    print("failed to copy sermons.json")
                }
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItemAtPath(jsonBundlePath!)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonDocumentsURL.path!)
                
                let jsonBundleModDate = jsonBundleAttributes[NSFileModificationDate] as! NSDate
                let jsonDocumentsModDate = jsonDocumentsAttributes[NSFileModificationDate] as! NSDate
                
                if (jsonDocumentsModDate.isNewerThanDate(jsonBundleModDate)) {
                    //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                    print("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonBundleModDate.isEqualToDate(jsonDocumentsModDate)) {
                    let jsonBundleFileSize = jsonBundleAttributes[NSFileSize] as! Int
                    let jsonDocumentsFileSize = jsonDocumentsAttributes[NSFileSize] as! Int
                    
                    if (jsonBundleFileSize != jsonDocumentsFileSize) {
                        print("Same dates different file sizes")
                        //We have a problem.
                    } else {
                        print("Same dates same file sizes")
                        //Do nothing, they are the same.
                    }
                }
                
                if (jsonBundleModDate.isNewerThanDate(jsonDocumentsModDate)) {
                    print("JSON in bundle is newer than JSON in Documents")
                    //copy the bundle into Documents directory
                    do {
                        // Copy File From Bundle To Documents Directory
                        try fileManager.removeItemAtPath(jsonDocumentsURL.path!)
                        try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonDocumentsURL.path!)
                    } catch _ {
                        print("failed to copy sermons.json")
                    }
                }
            } catch _ {
                
            }
        }
    }
}

func jsonDataFromDocumentsDirectory() -> JSON
{
    jsonToDocumentsDirectory()
    
    if let jsonURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        if let data = NSData(contentsOfURL: jsonURL) {
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from data, make sure the file contains valid json.")
            }
        } else {
            print("could not get data from the json file.")
        }
    }
    
    return nil
}

func sermonsFromDocumentsDirectoryArchive() -> [Sermon]?
{
    // JSON is newer than Archive, reutrn nil.  That will force the archive to be rebuilt from the JSON.
    
    let fileManager = NSFileManager.defaultManager()
    
    let archiveInDocumentsURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE)
    let archiveExistsInDocuments = fileManager.fileExistsAtPath(archiveInDocumentsURL!.path!)
    
    if !archiveExistsInDocuments {
        return nil
    }
    
    let jsonInDocumentsURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME)
    let jsonExistsInDocuments = fileManager.fileExistsAtPath(jsonInDocumentsURL!.path!)
    
    if (!jsonExistsInDocuments) {
        // This should not happen since JSON should have been copied before the first archive was created.
        // Since we don't understand this state, return nil
        return nil
    }
    
    let jsonInBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE)
    let jsonExistsInBundle = fileManager.fileExistsAtPath(jsonInBundlePath!)
    
    if (jsonExistsInDocuments && jsonExistsInBundle) {
        // Need to see if jsonInBundle is newer
        
        do {
            let jsonInBundleAttributes = try fileManager.attributesOfItemAtPath(jsonInBundlePath!)
            let jsonInDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonInDocumentsURL!.path!)
            
            let jsonInBundleModDate = jsonInBundleAttributes[NSFileModificationDate] as! NSDate
            let jsonInDocumentsModDate = jsonInDocumentsAttributes[NSFileModificationDate] as! NSDate
            
//            print("jsonInBundleModDate: \(jsonInBundleModDate)")
//            print("jsonInDocumentsModDate: \(jsonInDocumentsModDate)")
            
            if (jsonInDocumentsModDate.isOlderThanDate(jsonInBundleModDate)) {
                //The JSON in the Bundle is newer, we need to use it instead of the archive
                print("JSON in Documents is newer than JSON in Bundle")
                return nil
            }
            
            if (jsonInDocumentsModDate.isEqualToDate(jsonInBundleModDate)) {
                //Should never happen since JSON in Documents is created from JSON
                print("JSON in Bundle and in Documents are the same date")
//                return nil
            }
        } catch _ {
            
        }
    }
    
    if (archiveExistsInDocuments && jsonExistsInDocuments) {
        do {
            let jsonInDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonInDocumentsURL!.path!)
            let archiveInDocumentsAttributes = try fileManager.attributesOfItemAtPath(archiveInDocumentsURL!.path!)
            
            let jsonInDocumentsModDate = jsonInDocumentsAttributes[NSFileModificationDate] as! NSDate
            let archiveInDocumentsModDate = archiveInDocumentsAttributes[NSFileModificationDate] as! NSDate
            
//            print("archiveInDocumentsModDate: \(archiveInDocumentsModDate)")
            
            if (archiveInDocumentsModDate.isOlderThanDate(jsonInDocumentsModDate)) {
                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the archive was created.
                print("JSON is newer than Archive in Documents")
                return nil
            }
            
            if (archiveInDocumentsModDate.isEqualToDate(jsonInDocumentsModDate)) {
                //Should never happen since archive is created from JSON
                print("JSON is the same date as Archive in Documents")
//                return nil
            }
            
            print("Archive is newer than JSON in Documents")
            
            let data = NSData(contentsOfURL: NSURL(fileURLWithPath: archiveInDocumentsURL!.path!))
            if (data != nil) {
                let sermons = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [Sermon]
                if sermons != nil {
                    return sermons
                } else {
                    print("could not get sermons from archive.")
                }
            } else {
                print("could not get data from archive.")
            }
        } catch _ {
            
        }
    }
    
    return nil
}

func sermonsToDocumentsDirectoryArchive(sermons:[Sermon]?)
{
    if (sermons != nil) {
        if let archive = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE) {
            NSKeyedArchiver.archivedDataWithRootObject(sermons!).writeToURL(archive, atomically: true)
            print("Finished saving the sermon archive.")
        }
    }
}

func loadSermonDicts() -> [[String:String]]?
{
    var sermonDicts = [[String:String]]()
    
    let json = jsonDataFromDocumentsDirectory()
    
    if json != JSON.null {
        //                print("json:\(json)")
        
        let sermons = json[Constants.JSON_ARRAY_KEY]
        
        for i in 0..<sermons.count {
            
            var dict = [String:String]()
            
            for (key,value) in sermons[i] {
                dict["\(key)"] = "\(value)"
            }
            
            sermonDicts.append(dict)
        }
        
        return sermonDicts.count > 0 ? sermonDicts : nil
    } else {
        print("could not get json from file, make sure that file contains valid json.")
    }
    
    return nil
}

func cancelAllDownloads()
{
    if (Globals.sermons != nil) {
        for sermon in Globals.sermons! {
            if sermon.download.active {
                sermon.download.task?.cancel()
                sermon.download.task = nil
                
                sermon.download.totalBytesWritten = 0
                sermon.download.totalBytesExpectedToWrite = 0
                
                sermon.download.state = .none
            }
        }
    }
}

func loadDefaults()
{
    loadSermonSettings()

    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let sorting = defaults.stringForKey(Constants.SORTING) {
        Globals.sorting = sorting
    } else {
        Globals.sorting = Constants.REVERSE_CHRONOLOGICAL
    }
    
    if let grouping = defaults.stringForKey(Constants.GROUPING) {
        Globals.grouping = grouping
    } else {
        Globals.grouping = Constants.YEAR
    }
    
    Globals.sermonTagsSelected = defaults.stringForKey(Constants.COLLECTION)
    if (Globals.sermonTagsSelected != nil) {
        switch Globals.sermonTagsSelected! {
        case Constants.All:
            Globals.showing = Constants.ALL
            break
            
        default:
            Globals.showing = Constants.TAGGED
            break
        }
    } else {
        Globals.showing = Constants.ALL
    }

    var indexOfSermon:Int?
    
    if let dict = defaults.dictionaryForKey(Constants.SERMON_PLAYING) {
        indexOfSermon = Globals.sermons?.indexOf({ (sermon:Sermon) -> Bool in
            return (sermon.title == (dict[Constants.TITLE] as! String)) &&
                (sermon.date == (dict[Constants.DATE] as! String)) &&
                (sermon.service == (dict[Constants.SERVICE] as! String)) &&
                (sermon.speaker == (dict[Constants.SPEAKER] as! String))
        })
    }
    
    if (indexOfSermon != nil) {
        Globals.sermonLoaded = false
        Globals.sermonPlaying = Globals.sermons?[indexOfSermon!]
    } else {
        Globals.sermonLoaded = true
    }
}

func updateUserDefaultsCurrentTimeWhilePlaying()
{
    assert(Globals.mpPlayer != nil,"Globals.mpPlayer should not be nil if we're trying to update the currentTime in userDefaults")

    var timeNow:Float = 0.0
    
    if (Globals.mpPlayer != nil) {
        if (Globals.mpPlayer?.playbackState == .Playing) {
            if (Globals.mpPlayer!.currentPlaybackTime > 0) && (Globals.mpPlayer!.currentPlaybackTime <= Globals.mpPlayer!.duration) {
                timeNow = Float(Globals.mpPlayer!.currentPlaybackTime)
            }
        }
    }

    if ((timeNow > 0) && (Int(timeNow) % 10) == 0) {
        if (Globals.sermonPlaying != nil) {
            Globals.sermonPlaying?.currentTime = timeNow.description
            
            let defaults = NSUserDefaults.standardUserDefaults()
            
            //                print("\(timeNow.description)")
            defaults.setObject(timeNow.description,forKey: Constants.CURRENT_TIME)
            defaults.synchronize()
            
            saveSermonSettings()
        }
    }
}

func setupSermonPlayingUserDefaults()
{
    assert(Globals.sermonPlaying != nil,"Globals.sermonPlaying should not be nil if we're trying to update the userDefaults for the sermon that is playing")
    
    if (Globals.sermonPlaying != nil) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setObject(Globals.sermonPlaying?.dict, forKey: Constants.SERMON_PLAYING)
        
        defaults.setObject(Constants.ZERO, forKey: Constants.CURRENT_TIME)
        
        defaults.synchronize()
    }
}

func setupPlayer(sermon:Sermon?)
{
    if (sermon != nil) {
        var sermonURL:String?
        
        switch sermon!.playing! {
        case Constants.AUDIO:
            if (sermon!.audio != nil) {
                sermonURL = Constants.BASE_AUDIO_URL + sermon!.audio!
            } else {
                //Error
            }
            break
        
        case Constants.VIDEO:
            if (sermon!.video != nil) {
                sermonURL = Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX
            } else {
                //Error
            }
            break
            
        default:
            break
        }
        
        //        print("playNewSermon: \(sermonURL)")

        var url = NSURL(string:sermonURL!)
        var networkRequired = true
        
        if (sermon?.playing == Constants.AUDIO) {
            let fileURL = documentsURL()?.URLByAppendingPathComponent(sermon!.audio!)
            if (NSFileManager.defaultManager().fileExistsAtPath(fileURL!.path!)){
                url = fileURL
                networkRequired = false
            }
        }
        
        if !networkRequired || (networkRequired && Reachability.isConnectedToNetwork()) {
            Globals.sermonLoaded = false
            
            Globals.mpPlayer = MPMoviePlayerController(contentURL: url)
            
            Globals.mpPlayer?.shouldAutoplay = false
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            Globals.mpPlayer?.prepareToPlay()
            
            setupPlayingInfoCenter()
            
            Globals.playerPaused = true
            Globals.sermonLoaded = false
        } else {
            Globals.sermonLoaded = true
        }
    }
}

func setupPlayerAtEnd(sermon:Sermon?)
{
    setupPlayer(sermon)

    if (Globals.mpPlayer != nil) {
        Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
        Globals.mpPlayer?.pause()
        sermon?.currentTime = Float(Globals.mpPlayer!.duration).description
    }
}

func updateUserDefaultsCurrentTimeExact()
{
    if (Globals.mpPlayer != nil) {
        updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
    }
}

func updateUserDefaultsCurrentTimeExact(seekToTime:Float)
{
    if (seekToTime >= 0) {
        let defaults = NSUserDefaults.standardUserDefaults()
        //        print("\(seekToTime.description)")
        defaults.setObject(seekToTime.description,forKey: Constants.CURRENT_TIME)
        defaults.synchronize()
        
        Globals.sermonPlaying?.currentTime = seekToTime.description
    }
}

func remoteControlEvent(event: UIEvent) {
    print("remoteControlReceivedWithEvent")
    
    switch event.subtype {
    case UIEventSubtype.RemoteControlStop:
        print("RemoteControlStop")
        Globals.mpPlayer?.stop()
        Globals.playerPaused = true
        break
        
    case UIEventSubtype.RemoteControlPlay:
        print("RemoteControlPlay")
        Globals.mpPlayer?.play()
        Globals.playerPaused = false
        setupPlayingInfoCenter()
        break
        
    case UIEventSubtype.RemoteControlPause:
        print("RemoteControlPause")
        Globals.mpPlayer?.pause()
        Globals.playerPaused = true
        updateUserDefaultsCurrentTimeExact()
        break
        
    case UIEventSubtype.RemoteControlTogglePlayPause:
        print("RemoteControlTogglePlayPause")
        if (Globals.playerPaused) {
            Globals.mpPlayer?.play()
        } else {
            Globals.mpPlayer?.pause()
            updateUserDefaultsCurrentTimeExact()
        }
        Globals.playerPaused = !Globals.playerPaused
        break
        
    case UIEventSubtype.RemoteControlPreviousTrack:
        print("RemoteControlPreviousTrack")
        break
        
    case UIEventSubtype.RemoteControlNextTrack:
        print("RemoteControlNextTrack")
        break
        
        //The lock screen time elapsed/remaining don't track well with seeking
        //But at least this has them moving in the right direction.
        
    case UIEventSubtype.RemoteControlBeginSeekingBackward:
        print("RemoteControlBeginSeekingBackward")
        Globals.mpPlayer?.beginSeekingBackward()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
        
    case UIEventSubtype.RemoteControlEndSeekingBackward:
        print("RemoteControlEndSeekingBackward")
        Globals.mpPlayer?.endSeeking()
        updateUserDefaultsCurrentTimeExact()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
        
    case UIEventSubtype.RemoteControlBeginSeekingForward:
        print("RemoteControlBeginSeekingForward")
        Globals.mpPlayer?.beginSeekingForward()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
        
    case UIEventSubtype.RemoteControlEndSeekingForward:
        print("RemoteControlEndSeekingForward")
        Globals.mpPlayer?.endSeeking()
        updateUserDefaultsCurrentTimeExact()
//        updatePlayingInfoCenter()
        setupPlayingInfoCenter()
        break
        
    default:
        print("None")
        break
    }
}

func updatePlayingInfoCenter()
{
    if (Globals.sermonPlaying != nil) {
        //        let imageName = "\(Globals.coverArtPreamble)\(Globals.seriesPlaying!.name)\(Globals.coverArtPostamble)"
        //    print("\(imageName)")
        
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.duration),            forKey: MPMediaItemPropertyPlaybackDuration)
        sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.currentPlaybackTime), forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
        sermonInfo.updateValue(NSNumber(float: Globals.mpPlayer!.currentPlaybackRate),  forKey: MPNowPlayingInfoPropertyPlaybackRate)
        
        //    print("\(sermonInfo.count)")
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
}

func setupPlayingInfoCenter()
{
    if (Globals.sermonPlaying != nil) {
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue(Globals.sermonPlaying!.title!,                                               forKey: MPMediaItemPropertyTitle)

        if (Globals.sermonPlaying!.speaker != nil) {
            sermonInfo.updateValue(Globals.sermonPlaying!.speaker!,                                             forKey: MPMediaItemPropertyArtist)
        }

        sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:Constants.COVER_ART_IMAGE)!),                   forKey: MPMediaItemPropertyArtwork)

        if (Globals.sermonPlaying!.hasSeries()) {
            sermonInfo.updateValue(Globals.sermonPlaying!.series!,                                          forKey: MPMediaItemPropertyAlbumTitle)

            if (Globals.sermonPlaying!.speaker != nil) {
                sermonInfo.updateValue(Globals.sermonPlaying!.speaker!,                                         forKey: MPMediaItemPropertyAlbumArtist)
            }

            if let sermonsInSeries = Globals.sermons?.filter({ (sermon:Sermon) -> Bool in
                return (sermon.hasSeries()) && (sermon.series == Globals.sermonPlaying!.series)
            }).sort({ $0.title < $1.title }) {
//                print("\(sermonsInSeries.indexOf(Globals.sermonPlaying!))")
//                print("\(Globals.sermonPlaying!)")
//                print("\(sermonsInSeries)")
                sermonInfo.updateValue(sermonsInSeries.indexOf(Globals.sermonPlaying!)!,                        forKey: MPMediaItemPropertyAlbumTrackNumber)
                sermonInfo.updateValue(sermonsInSeries.count,                                                   forKey: MPMediaItemPropertyAlbumTrackCount)
            }
        }
        
        if (Globals.mpPlayer != nil) {
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
            sermonInfo.updateValue(NSNumber(double: Globals.mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
            
            sermonInfo.updateValue(NSNumber(float:Globals.mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
        }
        
        //    print("\(sermonInfo.count)")
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
}

extension NSDate
{
    convenience
    init(dateString:String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "MM/dd/yyyy"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let d = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval:0, sinceDate:d)
    }
    
    func isNewerThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isNewer = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
        {
            isNewer = true
        }
        
        //Return Result
        return isNewer
    }
    
    
    func isOlderThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isOlder = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
        {
            isOlder = true
        }
        
        //Return Result
        return isOlder
    }
    

// Claims to be a redeclaration, but I can't find the other.
//    func isEqualToDate(dateToCompare : NSDate) -> Bool
//    {
//        //Declare Variables
//        var isEqualTo = false
//
//        //Compare Values
//        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame
//        {
//            isEqualTo = true
//        }
//
//        //Return Result
//        return isEqualTo
//    }


    func addDays(daysToAdd : Int) -> NSDate
    {
        let secondsInDays : NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    
    func addHours(hoursToAdd : Int) -> NSDate
    {
        let secondsInHours : NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

func saveSermonSettings()
{
//    print("\(Globals.sermonSettings)")
    
    let defaults = NSUserDefaults.standardUserDefaults()
//    print("\(Globals.sermonSettings)")
    defaults.setObject(Globals.sermonSettings,forKey: Constants.SERMON_SETTINGS_KEY)
//    print("\(Globals.seriesViewSplits)")
    defaults.setObject(Globals.seriesViewSplits, forKey: Constants.SERIES_VIEW_SPLITS_KEY)
    defaults.synchronize()
}

func loadSermonSettings()
{
    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let settingsDictionary = defaults.dictionaryForKey(Constants.SERMON_SETTINGS_KEY) {
//        print("\(settingsDictionary)")
        Globals.sermonSettings = settingsDictionary as? [String:[String:String]]
    }
    
    if (Globals.sermonSettings == nil) {
        Globals.sermonSettings = [String:[String:String]]()
    }
    
    if let viewSplitsDictionary = defaults.dictionaryForKey(Constants.SERIES_VIEW_SPLITS_KEY) {
//        print("\(viewSplitsDictionary)")
        Globals.seriesViewSplits = viewSplitsDictionary as? [String:String]
    }
    
    if (Globals.seriesViewSplits == nil) {
        Globals.seriesViewSplits = [String:String]()
    }

//    print("\(Globals.sermonSettings)")
}

func stringWithoutLeadingTheOrAOrAn(fromString:String?) -> String?
{
    let quote:String = "\""
    let a:String = "A "
    let an:String = "An "
    let the:String = "The "
    
    var sortString = fromString
    
    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substringToIndex(quote.endIndex) == quote) {
        sortString = fromString!.substringFromIndex(quote.endIndex)
    }
    
    if (fromString?.endIndex >= a.endIndex) && (fromString?.substringToIndex(a.endIndex) == a) {
        sortString = fromString!.substringFromIndex(a.endIndex)
    } else
        if (fromString?.endIndex >= an.endIndex) && (fromString?.substringToIndex(an.endIndex) == an) {
            sortString = fromString!.substringFromIndex(an.endIndex)
        } else
            if (fromString?.endIndex >= the.endIndex) && (fromString?.substringToIndex(the.endIndex) == the) {
                sortString = fromString!.substringFromIndex(the.endIndex)
    }
    
    return sortString
}


func clearSermonsForDisplay()
{
    Globals.display.sermons = nil
    Globals.display.section.titles = nil
    Globals.display.section.indexes = nil
    Globals.display.section.counts = nil
}


func setupSermonsForDisplay()
{
    Globals.display.sermons = Globals.activeSermons
    
    Globals.display.section.titles = Globals.section.titles
    Globals.display.section.indexes = Globals.section.indexes
    Globals.display.section.counts = Globals.section.counts
}


func loadCacheEntries() -> SortGroupCache?
{
    var sortGroupCache = SortGroupCache()
    
    let fileManager = NSFileManager.defaultManager()
    let url = documentsURL()
//    do {
//        let array = try fileManager.contentsOfDirectoryAtPath(url!.path!)
//        
//        //Get the one we need now.
//        let name = Globals.sortGroupCacheKey + Constants.CACHE_ARCHIVE
//        
//        if array.indexOf(name) != nil {
//            let filename = url!.URLByAppendingPathComponent(name)
//            //                print("\(filename)\n\n")
//            
//            let key = name.substringToIndex(name.rangeOfString(Constants.CACHE_ARCHIVE)!.startIndex)
//            
//            let data = NSData(contentsOfURL: filename)
//            if (data != nil) {
//                if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [String:[String]] {
//                    //                        print("\(name)\n\n")
//                    
//                    let sections = dict[Constants.CACHE_SECTIONS]
//                    //                        print("\(sections!)\n\n")
//                    
//                    let indexes = dict[Constants.CACHE_INDEXES]?.map({ (value:String) -> Int in
//                        return Int(value)!
//                    })
//                    //                        print("\(indexes!)\n\n")
//                    
//                    let counts = dict["counts"]?.map({ (value:String) -> Int in
//                        return Int(value)!
//                    })
//                    //                        print("\(counts!)\n\n")
//                    
//                    let sermonReferences = dict[Constants.CACHE_SERMON_INDEXES]?.map({ (index:String) -> Sermon in
//                        return Globals.sermons![Int(index)!]
//                    })
//                    //                        print("\(sermonReferences!)\n\n")
//                    
//                    print("Restoring cache entry: \(key)\n\n")
//                    
//                    sortGroupCache[key] = (sermons: sermonReferences, sections: sections, indexes: indexes, counts: counts)
//                } else {
//                    print("Could not get cache entry from archive for: \(key)\n\n")
//                }
//            } else {
//                print("Could not get data from cache archive file: \(filename)\n\n")
//            }
//        }
//    } catch _ {
//    }
    
    // Load the rest in the background.
    // Except this creates cases where one we're looking for isn't loaded until it too late
    // So load in the main thread.  It is fast.
    
    // NO BECAUSE THIS CAN DELAY CACHE ENTRIES THAT USERS SWITCH TO.
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
        print("Starting to restore the cache")
        do {
            let array = try fileManager.contentsOfDirectoryAtPath(url!.path!)
            
            for name in array {
                if (name.rangeOfString(Constants.CACHE_ARCHIVE)?.endIndex == name.endIndex) {
                    let filename = url!.URLByAppendingPathComponent(name)
                    //                print("\(filename)\n\n")
                    
                    let key = name.substringToIndex(name.rangeOfString(Constants.CACHE_ARCHIVE)!.startIndex)
                    if (sortGroupCache[key] == nil) {
                        let data = NSData(contentsOfURL: filename)
                        if (data != nil) {
                            if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [String:[String]] {
                                //                        print("\(name)\n\n")
                                
                                let sections = dict[Constants.CACHE_SECTIONS]
                                //                        print("\(sections!)\n\n")
                                
                                let indexes = dict[Constants.CACHE_INDEXES]?.map({ (value:String) -> Int in
                                    return Int(value)!
                                })
                                //                        print("\(indexes!)\n\n")
                                
                                let counts = dict[Constants.CACHE_COUNTS]?.map({ (value:String) -> Int in
                                    return Int(value)!
                                })
                                //                        print("\(counts!)\n\n")
                                
                                let sermonReferences = dict[Constants.CACHE_SERMON_INDEXES]?.map({ (index:String) -> Sermon in
                                    return Globals.sermons![Int(index)!]
                                })
                                //                        print("\(sermonReferences!)\n\n")
                                
                                let key = name.substringToIndex(name.rangeOfString(Constants.CACHE_ARCHIVE)!.startIndex)
                                print("Restoring cache entry: \(key)\n\n")
                                
                                sortGroupCache[key] = (sermons: sermonReferences, sections: sections, indexes: indexes, counts: counts)
                            } else {
                                print("could not get cache entry from archive.")
                            }
                        } else {
                            print("could not get data from cache archive file.")
                        }
                    }
                }
            }
        } catch _ {
        }
        print("Finished restoring the cache")
//    })
    
    return sortGroupCache.count > 0 ? sortGroupCache : nil
}

func saveCacheEntry(key key:String,sermons:[Sermon]?,sections:[String]?,indexes:[Int]?,counts:[Int]?)
{
    print("Saving the cache archive: \(key)")
    
    var dict = [String:[String]]()
    
    dict[Constants.CACHE_SECTIONS] = sections
    //    print("\(sections)")
    
    dict[Constants.CACHE_INDEXES] = indexes?.map({ (value:Int) -> String in
        return "\(value)"
    })
    
    dict[Constants.CACHE_COUNTS] = counts?.map({ (value:Int) -> String in
        return "\(value)"
    })
    
    dict[Constants.CACHE_SERMON_INDEXES] = sermons?.map({ (sermon:Sermon) -> String in
        if let index = Globals.sermons!.indexOf(sermon) {
            return "\(index)"
        } else {
            return "" // This happens when the Globals.sermons array has changed, which invalidates the cache entry
        }
    }).filter({ (string:String) -> Bool in
        return string != "" // This filters out the invalid sermon indexes
    })
    
    // This prevents us from saving cache entries w/ invalid sermon indexes.
    if dict[Constants.CACHE_SERMON_INDEXES]?.count == sermons?.count {
        if let archive = documentsURL()?.URLByAppendingPathComponent(key+Constants.CACHE_ARCHIVE) {
            NSKeyedArchiver.archivedDataWithRootObject(dict).writeToURL(archive, atomically: true)
            print("Finished saving the cache archive: \(key)")
        }
    } else {
        print("sermonIndexes failure - Globals.sermons array has changed, likely due to downloading new JSON.")
        print("Did NOT save the cache archive: \(key)")
    }
}

func fillSortAndGroupCache()
{
    /*
        This must be done so the SortGroupTuples that is stored in the SortGroupCache area created serially.
        Otherwise there are inexplicable crashes in Globals.sermonSettings that probably have to do with simultaneous
        access not being thread safe.  I wish I understood this better.
    */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
        print("Starting to fill the cache")

        let sermons = Globals.activeSermons

        let showing = Globals.showing
        let tag = Globals.sermonTagsSelected
        
        let sortings = [Constants.CHRONOLOGICAL, Constants.REVERSE_CHRONOLOGICAL]
        let groupings = [Constants.YEAR, Constants.SERIES, Constants.BOOK, Constants.SPEAKER]
        
        var key:String?
        
        let searchKey = Globals.searchActive ? (Globals.searchText != nil ? "search"+Globals.searchText! : "search") : ""

        for sorting in sortings {
            for grouping in groupings {
                switch showing! {
                case Constants.TAGGED:
                    key = searchKey + showing! + tag! + sorting + grouping
                    break
                    
                case Constants.ALL:
                    key = searchKey + showing! + sorting + grouping
                    break
                    
                default:
                    break
                }
                
                key = key?.stringByReplacingOccurrencesOfString(" ", withString: "_", options: NSStringCompareOptions.LiteralSearch, range: nil)

//                print("cache entry:\(key!)")

                if (Globals.sortGroupCache?[key!] == nil) && (Globals.sortGroupCacheState?[key!] == nil) {
                    print("Creating cache entry:\(key!)")
                    
                    Globals.sortGroupCacheState?[key!] = Constants.CACHE_ENTRY_IN_PROCESS
                    
                    let sermonList = sortSermons(sermons, sorting: sorting, grouping: grouping)
                    let groupTuple = groupSermons(sermonList, grouping: grouping)
                    let sections = sermonSections(sermonList, sorting: sorting, grouping: grouping)
                    Globals.sortGroupCache?[key!] = (sermons: sermonList, sections: sections, indexes: groupTuple?.indexes, counts: groupTuple?.counts)
                    
                    Globals.sortGroupCacheState?[key!] = Constants.CACHE_ENTRY_COMPLETE
                    
                    saveCacheEntry(key: key!, sermons: sermonList, sections: sections, indexes: groupTuple?.indexes, counts: groupTuple?.counts)
                } else {
                    print("Already filled cache entry: \(key!)")
                }
            }
        }
        print("Finished filling the cache.")
    })
}


func sortAndGroupSermons()
{
    Globals.sermonsSortingOrGrouping = true
    
    // This indexing in the background potentially creates errant indexes when it is running and new JSON is dowloaded, creating a new sermons array
    // and starting a new background indexing process while the prior one is running.  We can't guarantee in which order the indexing will finish and that the results
    // of the first, which is now out of date, own't overwrite the results of the second.
    
    // Instead we just save them after they are created, as they are created by the user, in the main thread.
    
    // It also appears to create collissions w/ Globals.sermonSettings (accessed through sermon.settings) when a cache entry is being created in the foreground.
    
//    fillSortAndGroupCache()
    
    print("Looking for cache entry: \(Globals.sortGroupCacheKey)")
    if let sortGroupTuple = Globals.sortGroupCache?[Globals.sortGroupCacheKey] {
        print("Found cache entry: \(Globals.sortGroupCacheKey)")
        Globals.activeSermons = sortGroupTuple.sermons
        Globals.section.titles = sortGroupTuple.sections
        Globals.section.indexes = sortGroupTuple.indexes
        Globals.section.counts = sortGroupTuple.counts
    } else {
        print("Didn't find cache entry: \(Globals.sortGroupCacheKey)")
        
        Globals.sortGroupCacheState?[Globals.sortGroupCacheKey] = Constants.CACHE_ENTRY_IN_PROCESS
        
        if (Globals.sermonsNeed.groupsSetup) {
            print("Setting up groups for cache entry: \(Globals.sortGroupCacheKey)")
            setupSermonGroups()
            Globals.sermonsNeed.grouping = true
            Globals.sermonsNeed.groupsSetup = false
        }
        
        if Globals.sermonsNeed.grouping {
            Globals.activeSermons = sortSermons(Globals.activeSermons,sorting: Globals.sorting, grouping: Globals.grouping)
            if let groupTuple = groupSermons(Globals.activeSermons, grouping: Globals.grouping) {
                Globals.section.indexes = groupTuple.indexes
                Globals.section.counts = groupTuple.counts
            }

            Globals.section.titles = sermonSectionTitles()
            
            Globals.sermonsNeed.grouping = false
        } else {
            if Globals.sermonsNeed.sorting {
                Globals.activeSermons = sortSermons(Globals.activeSermons,sorting: Globals.sorting, grouping: Globals.grouping)
                if (Globals.grouping == Constants.YEAR) {
                    if let groupTuple = groupSermons(Globals.activeSermons, grouping: Globals.grouping) {
                        Globals.section.indexes = groupTuple.indexes
                        Globals.section.counts = groupTuple.counts
                    }

                    switch Globals.sorting! {
                    case Constants.REVERSE_CHRONOLOGICAL:
                        Globals.section.titles?.sortInPlace() { $1 < $0 }
                        break
                    case Constants.CHRONOLOGICAL:
                        Globals.section.titles?.sortInPlace() { $0 < $1 }
                        break
                        
                    default:
                        break
                    }
                }
                
                Globals.sermonsNeed.sorting = false
            }
        }
 
        if (Globals.sortGroupCache?[Globals.sortGroupCacheKey] == nil) {
            Globals.sortGroupCache?[Globals.sortGroupCacheKey] = (sermons: Globals.activeSermons, sections: Globals.section.titles, indexes: Globals.section.indexes, counts: Globals.section.counts)
            
            Globals.sortGroupCacheState?[Globals.sortGroupCacheKey] = Constants.CACHE_ENTRY_COMPLETE
            
            // Need to make sure this gets saved.
            saveCacheEntry(key: Globals.sortGroupCacheKey, sermons: Globals.activeSermons, sections: Globals.section.titles, indexes: Globals.section.indexes, counts: Globals.section.counts)
        } else {
            Globals.sortGroupCacheState?[Globals.sortGroupCacheKey] = Constants.CACHE_ENTRY_COMPLETE
        }
    }
    
    setupSermonsForDisplay()
    
    Globals.sermonsSortingOrGrouping = false
}


func sortSermons(sermons:[Sermon]?, sorting:String?, grouping:String?) -> [Sermon]?
{
    var result:[Sermon]?
    
    switch grouping! {
    case Constants.YEAR:
        result = sortSermonsByYear(sermons,sorting: sorting)
        break
        
    case Constants.SERIES:
        result = sortSermonsBySeries(sermons,sorting: sorting)
        break
        
    case Constants.BOOK:
        result = sortSermonsByBook(sermons,sorting: sorting)
        break
        
    case Constants.SPEAKER:
        result = sortSermonsBySpeaker(sermons,sorting: sorting)
        break
        
    default:
        result = nil
        break
    }
    
    return result
}


func setupSermonGroups() {
    let sermons = Globals.activeSermons
    
    Globals.sermonSectionTitles.years = yearsFromSermons(sermons, sorting: Globals.sorting)
    Globals.sermonSectionTitles.series = seriesSectionsFromSermons(sermons)
    Globals.sermonSectionTitles.books = bookSectionsFromSermons(sermons)
    Globals.sermonSectionTitles.speakers = speakerSectionsFromSermons(sermons)
}


func sermonSections(sermons:[Sermon]?,sorting:String?,grouping:String?) -> [String]?
{
    var strings:[String]?
    
    switch grouping! {
    case Constants.YEAR:
        strings = yearsFromSermons(sermons, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Constants.SERIES:
        strings = seriesSectionsFromSermons(sermons)
        break
        
    case Constants.BOOK:
        strings = bookSectionsFromSermons(sermons)
        break
        
    case Constants.SPEAKER:
        strings = speakerSectionsFromSermons(sermons)
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func sermonSectionTitles() -> [String]?
{
    var strings:[String]?
    
    switch Globals.grouping! {
    case Constants.YEAR:
        switch Globals.sorting! {
        case Constants.REVERSE_CHRONOLOGICAL:
            Globals.sermonSectionTitles.years?.sortInPlace() { $1 < $0 }
            break
        case Constants.CHRONOLOGICAL:
            Globals.sermonSectionTitles.years?.sortInPlace() { $0 < $1 }
            break
        default:
            break
        }
        
        strings = Globals.sermonSectionTitles.years?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Constants.SERIES:
        strings = Globals.sermonSectionTitles.series
        break
        
    case Constants.BOOK:
        strings = Globals.sermonSectionTitles.books
        break
        
    case Constants.SPEAKER:
        strings = Globals.sermonSectionTitles.speakers
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func groupSermons(sermons:[Sermon]?,grouping:String?) -> GroupTuple?
{
    var groupTuple:GroupTuple?
    
    switch grouping! {
    case Constants.YEAR:
        groupTuple = groupSermonsByYear(sermons)
        break
        
    case Constants.SERIES:
        groupTuple = groupSermonsBySeries(sermons)
        break
        
    case Constants.BOOK:
        groupTuple = groupSermonsByBook(sermons)
        break
        
    case Constants.SPEAKER:
        groupTuple = groupSermonsBySpeaker(sermons)
        break
        
    default:
        groupTuple = nil
        break
    }
    
    return groupTuple
}

func yearsFromSermons(sermons:[Sermon]?, sorting: String?) -> [Int]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    assert(sermon.fullDate != nil) // We're assuming this gets ALL sermons.
                    return sermon.fullDate != nil
                }).map({ (sermon:Sermon) -> Int in
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components(.Year, fromDate: sermon.fullDate!)
                    return components.year
                })
            )
            ).sort({ (first:Int, second:Int) -> Bool in
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return first < second
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return first > second
                    
                default:
                    break
                }
                
                return false
            })
        : nil
}


func groupSermonsByYear(sermonsToGroup:[Sermon]?) -> GroupTuple?
{
    if let sermons = sermonsToGroup {
        var sermonSectionIndexes = [Int]()
        var sermonSectionCounts = [Int]()

        //This assumes the sermons have been sorted.
        var section:String?
        
        var index:Int = 0
        var counter:Int = 0
        
        for sermon in sermons {
            let calendar = NSCalendar.currentCalendar()
            var components:NSDateComponents
            
            components = calendar.components(.Year, fromDate: sermon.fullDate!)
            
            if (section == nil) {
                section = "\(components.year)"
                sermonSectionIndexes.append(index)
            }
            
            if (section != "\(components.year)") {
                section = "\(components.year)"
                sermonSectionIndexes.append(index)
                sermonSectionCounts.append(counter)
                counter = 1
            } else {
                counter++
            }
            
            index++
        }
        sermonSectionCounts.append(counter)
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

func sermonsInSermonSeries(sermons:[Sermon]?,series:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.series == series
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThanDate(second.fullDate!)
        }
    })
}

func sermonsInBook(sermons:[Sermon]?,book:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.book == book
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThanDate(second.fullDate!)
        }
    })
}

func booksFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasBook()
            }).map({ (sermon:Sermon) -> String in
                return sermon.book!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    result = bookNumberInBible(first) < bookNumberInBible(second)
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }
                return result
            })
        : nil
}

func bookSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.hasBook() ? sermon.book! : sermon.scripture != nil ? sermon.scripture! : Constants.None
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    result = bookNumberInBible(first) < bookNumberInBible(second)
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }
                return result
            })
        : nil
}

func seriesFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    return sermon.hasSeries()
                }).map({ (sermon:Sermon) -> String in
                    return sermon.series!
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutLeadingTheOrAOrAn(first) < stringWithoutLeadingTheOrAOrAn(second)
            })
        : nil
}

func seriesSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    return sermon.seriesSection!
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutLeadingTheOrAOrAn(first) < stringWithoutLeadingTheOrAOrAn(second)
            })
        : nil
}

func seriesSectionsFromSermons(sermons:[Sermon]?,withTitles:Bool) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    if (sermon.hasSeries()) {
                        return sermon.series!
                    } else {
                        return withTitles ? sermon.title! : Constants.Individual_Sermons
                    }
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutLeadingTheOrAOrAn(first) < stringWithoutLeadingTheOrAOrAn(second)
            })
        : nil
}

func groupSermonsBySeries(sermonsToGroup:[Sermon]?) -> GroupTuple?
{
    if let sermons = sermonsToGroup {
        var sermonSectionIndexes = [Int]()
        var sermonSectionCounts = [Int]()
        
        //This assumes the sermons have been sorted.
        var section:String?
        
        var index:Int = 0
        var counter:Int = 0
        
        for sermon in sermons {
            //            print("\(sermon)")
            
            if (section == nil) {
                section = sermon.seriesSection
                sermonSectionIndexes.append(index)
                //                print("nil starts the first section! Section \(sermonSectionIndexes.count) at Index: \(index)")
            }
            
            if (section != sermon.seriesSection) {
                section = sermon.seriesSection
                sermonSectionCounts.append(counter)
                sermonSectionIndexes.append(index)
                //                print("new section! Section \(sermonSectionIndexes.count) at Index: \(index) Last section count: \(counter)")
                counter = 1
            } else {
                counter++
            }
            
            index++
        }
        sermonSectionCounts.append(counter)
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

func bookNumberInBible(book:String?) -> Int?
{
    if (book != nil) {
        if let index = Constants.OLD_TESTAMENT.indexOf(book!) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT.indexOf(book!) {
            return Constants.OLD_TESTAMENT.count + index
        }
        
        return nil // Constants.OLD_TESTAMENT.count + Constants.NEW_TESTAMENT.count+1 // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
}

func groupSermonsByBook(sermonsToGroup:[Sermon]?) -> GroupTuple?
{
    if let sermons = sermonsToGroup {
        var sermonSectionIndexes = [Int]()
        var sermonSectionCounts = [Int]()
        
        //This assumes the sermons have been sorted.
        var section:String?
        
        var index:Int = 0
        var counter:Int = 0
        
        for sermon in sermons {
            if (section == nil) {
                section = sermon.bookSection
                sermonSectionIndexes.append(index)
            }
            
            if (section != sermon.bookSection) {
                section = sermon.bookSection
                sermonSectionIndexes.append(index)
                sermonSectionCounts.append(counter)
                counter = 1
            } else {
                counter++
            }
            
            index++
        }
        sermonSectionCounts.append(counter)
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

func lastNameFromName(name:String?) -> String?
{
    if var lastname = name {
        while (lastname.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
            lastname = lastname.substringFromIndex(lastname.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
        }
        return lastname
    }
    return nil
}

func speakerSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.speakerSection!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func speakersFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasSpeaker()
            }).map({ (sermon:Sermon) -> String in
                return sermon.speaker!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func groupSermonsBySpeaker(sermonsToGroup:[Sermon]?) -> GroupTuple?
{
    if let sermons = sermonsToGroup {
        var sermonSectionIndexes = [Int]()
        var sermonSectionCounts = [Int]()
        
        //This assumes the sermons have been sorted.
        var section:String?
        
        var index:Int = 0
        var counter:Int = 0
        
        for sermon in sermons {
            if (section == nil) {
                section = sermon.speakerSection
                sermonSectionIndexes.append(index)
            }
            
            if (section != sermon.speakerSection) {
                section = sermon.speakerSection
                sermonSectionIndexes.append(index)
                sermonSectionCounts.append(counter)
                counter = 1
            } else {
                counter++
            }
            
            index++
        }
        sermonSectionCounts.append(counter)
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

func sortSermonsChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
            return $0.service < $1.service
        } else {
            return $0.fullDate!.isOlderThanDate($1.fullDate!)
        }
    }
}

func sortSermonsReverseChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
            return $0.service > $1.service
        } else {
            return $0.fullDate!.isNewerThanDate($1.fullDate!)
        }
    }
}

func sortSermonsByYear(sermons:[Sermon]?,sorting:String?) -> [Sermon]?
{
    var sortedSermons:[Sermon]?

    switch sorting! {
    case Constants.CHRONOLOGICAL:
        sortedSermons = sortSermonsChronologically(sermons)
        break
        
    case Constants.REVERSE_CHRONOLOGICAL:
        sortedSermons = sortSermonsReverseChronologically(sermons)
        break
        
    default:
        break
    }
    
    return sortedSermons
}

func compareSermonDates(first first:Sermon, second:Sermon, sorting:String?) -> Bool
{
    var result = false

    switch sorting! {
    case Constants.CHRONOLOGICAL:
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            result = (first.service < second.service)
        } else {
            result = first.fullDate!.isOlderThanDate(second.fullDate!)
        }
        break
    
    case Constants.REVERSE_CHRONOLOGICAL:
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            result = (first.service > second.service)
        } else {
            result = first.fullDate!.isNewerThanDate(second.fullDate!)
        }
        break
        
    default:
        break
    }

    return result
}

func sortSermonsBySeries(sermons:[Sermon]?,sorting:String?) -> [Sermon]?
{
    return sermons?.sort() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.seriesSectionSort != second.seriesSectionSort) {
            result = first.seriesSectionSort < second.seriesSectionSort
        } else {
            result = compareSermonDates(first: first,second: second, sorting: sorting)
        }

        return result
    }
}

func sortSermonsBySpeaker(sermons:[Sermon]?,sorting: String?) -> [Sermon]?
{
    return sermons?.sort() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.speakerSectionSort != second.speakerSectionSort) {
            result = first.speakerSectionSort < second.speakerSectionSort
        } else {
            result = compareSermonDates(first: first,second: second, sorting: sorting)
        }
        
        return result
    }
}

func sortSermonsByBook(sermons:[Sermon]?, sorting:String?) -> [Sermon]?
{
    return sermons?.sort() {
        let first = bookNumberInBible($0.book)
        let second = bookNumberInBible($1.book)
        
        var result = false
        
        if (first != nil) && (second != nil) {
            if (first != second) {
                result = first < second
            } else {
                result = compareSermonDates(first: $0,second: $1, sorting: sorting)
            }
        } else
            if (first != nil) && (second == nil) {
                result = true
            } else
                if (first == nil) && (second != nil) {
                    result = false
                } else
                    if (first == nil) && (second == nil) {
                        if ($0.bookSection != $1.bookSection) {
                            result = $0.bookSection < $1.bookSection
                        } else {
                            result = compareSermonDates(first: $0,second: $1, sorting: sorting)
                        }
        }
        
        return result
    }
}


func testSermonsPDFs(testExisting testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
    var counter = 1

    if (testExisting) {
        print("Testing the availability of sermon transcripts and slides that we DO have in the sermonDicts - start")
        
        if let sermons = Globals.sermons {
            for sermon in sermons {
                if (showTesting) {
                    print("Testing: \(counter) \(sermon.title!)")
                } else {
                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.notes != nil) {
                    let notesURL = Constants.BASE_PDF_URL + sermon.notes!
                    
                    if (NSData(contentsOfURL: NSURL(string: notesURL)!) == nil) {
                        print("Transcript DOES NOT exist for: \(sermon.title!) PDF: \(sermon.notes!)")
                    } else {
                        
                    }
                }
                
                if (sermon.slides != nil) {
                    let slidesURL = Constants.BASE_PDF_URL + sermon.slides!
                    
                    if (NSData(contentsOfURL: NSURL(string: slidesURL)!) == nil) {
                        print("Slides DO NOT exist for: \(sermon.title!) PDF: \(sermon.slides!)")
                    } else {
                        
                    }
                }
                
                counter++
            }
        }
        
        print("\nTesting the availability of sermon transcripts and slides that we DO have in the sermonDicts - end")
    }

    if (testMissing) {
        print("Testing the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - start")
        
        counter = 1
        if let sermons = Globals.sermons {
            for sermon in sermons {
                if (showTesting) {
                    print("Testing: \(counter) \(sermon.title!)")
                } else {
                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.audio == nil) {
                    print("No Audio file for: \(sermon.title) can't test for PDF's")
                } else {
                    if (sermon.notes == nil) {
                        let testString = "tp150705a"
                        let testNotes = Constants.TRANSCRIPT_PREFIX + sermon.audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
                        //                print("Notes file s/b: \(testNotes)")
                        let notesURL = Constants.BASE_PDF_URL + testNotes
                        //                print("<a href=\"\(notesURL)\" target=\"_blank\">\(sermon.title!) Notes</a><br/>")
                        
                        if (NSData(contentsOfURL: NSURL(string: notesURL)!) != nil) {
                            print("Transcript DOES exist for: \(sermon.title!) PDF: \(testNotes)")
                        } else {
                            
                        }
                    }
                    
                    if (sermon.slides == nil) {
                        let testString = "tp150705a"
                        let testSlides = sermon.audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
                        //                print("Slides file s/b: \(testSlides)")
                        let slidesURL = Constants.BASE_PDF_URL + testSlides
                        //                print("<a href=\"\(slidesURL)\" target=\"_blank\">\(sermon.title!) Slides</a><br/>")
                        
                        if (NSData(contentsOfURL: NSURL(string: slidesURL)!) != nil) {
                            print("Slides DO exist for: \(sermon.title!) PDF: \(testSlides)")
                        } else {
                            
                        }
                    }
                }
                
                counter++
            }
        }
        
        print("\nTesting the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - end")
    }
}

func testSermonsTagsAndSeries()
{
    print("Testing for sermon series and tags the same - start")
    
    if let sermons = Globals.sermons {
        for sermon in sermons {
            if (sermon.hasSeries()) && (sermon.hasTags()) {
                if (sermon.series == sermon.tags) {
                    print("Series and Tags the same in: \(sermon.title!) Series:\(sermon.series!) Tags:\(sermon.tags!)")
                }
            }
        }
    }
    
    print("Testing for sermon series and tags the same - end")
}

func testSermonsForAudio()
{
    print("Testing for audio - start")
    
    for sermon in Globals.sermons! {
        if (!sermon.hasAudio()) {
            print("Audio missing in: \(sermon.title!)")
        } else {

        }
    }
    
    print("Testing for audio - end")
}

func testSermonsForSpeaker()
{
    print("Testing for speaker - start")
    
    for sermon in Globals.sermons! {
        if (!sermon.hasSpeaker()) {
            print("Speaker missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for speaker - end")
}

func testSermonsForSeries()
{
    print("Testing for sermons with \"(Part \" in the title but no series - start")
    
    for sermon in Globals.sermons! {
        if (sermon.title?.rangeOfString("(Part ", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil) && sermon.hasSeries() {
            print("Series missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for sermons with \"(Part \" in the title but no series - end")
}

func testSermonsBooksAndSeries()
{
    print("Testing for sermon series and book the same - start")

    for sermon in Globals.sermons! {
        if (sermon.hasSeries()) && (sermon.hasBook()) {
            if (sermon.series == sermon.book) {
                print("Series and Book the same in: \(sermon.title!) Series:\(sermon.series!) Book:\(sermon.book!)")
            }
        }
    }

    print("Testing for sermon series and book the same - end")
}

func tagsArrayFromTagsString(tagsString:String?) -> [String]?
{
    var arrayOfTags = [String]()
    
    var tags = tagsString
    var tag:String
    var setOfTags = Set<String>()
    
    while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
        tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
        setOfTags.insert(tag)
        tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
    }
    
    if (tags != nil) {
        setOfTags.insert(tags!)
    }
    
    //        print("\(tagsSet)")
    arrayOfTags = Array(setOfTags)
    arrayOfTags.sortInPlace() { $0 < $1 }
    
    return arrayOfTags.count > 0 ? arrayOfTags : nil
}

func taggedSermonsFromTagSelected(sermonsWithTags:[Sermon]?,tagSelected:String?) -> [Sermon]?
{
    if let sermons = sermonsWithTags {
        var taggedSermons = [Sermon]()
        
        for sermon in sermons {
            var tags = sermon.tags
            var tag:String
            var tagsSet = Set<String>()
            
            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            
            //        print("\(tagsSet)")
            for tag in tagsSet {
                if (tag == tagSelected) {
                    taggedSermons.append(sermon)
                }
            }
        }

        return taggedSermons.count > 0 ? taggedSermons : nil
    }
    
    return nil
}

func tagsFromSermons(sermons:[Sermon]?) -> [String]?
{
    if sermons != nil {
        var tagsSet = Set<String>()
        var tagsArray = [String]()
        
        for sermon in sermons! {
            var tags = sermon.tags
            var tag:String

            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
        }
        
        for tag in tagsSet {
            tagsArray.append(tag)
        }
        
        tagsArray.sortInPlace() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) }
        
        tagsArray.append(Constants.All)
        
    //    print("Tag Set: \(tagsSet)")
    //    print("Tag Array: \(tagsArray)")
        
        return tagsArray.count > 0 ? tagsArray : nil
    }
    
    return nil
}

func sermonsFromSermonDicts(sermonDicts:[[String:String]]?) -> [Sermon]?
{
    if (sermonDicts != nil) {
        return sermonDicts?.map({ (sermonDict:[String : String]) -> Sermon in
            Sermon(dict: sermonDict)
        })
    }
    
    return nil
}

func addAccessoryEvents()
{
    MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlPause")
        
        Globals.mpPlayer?.pause()
        
        Globals.playerPaused = true
        updateUserDefaultsCurrentTimeExact()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().stopCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlPlay")
        
        Globals.mpPlayer?.play()
        
        Globals.playerPaused = false
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        print("RemoteControlTogglePlayPause")
        if (Globals.playerPaused) {
            Globals.mpPlayer?.play()
        } else {
            Globals.mpPlayer?.pause()
            updateUserDefaultsCurrentTimeExact()
        }
        Globals.playerPaused = !Globals.playerPaused
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.beginSeekingBackward()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.beginSeekingForward()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime -= NSTimeInterval(Constants.SKIP_TIME_INTERVAL)
        updateUserDefaultsCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime += NSTimeInterval(Constants.SKIP_TIME_INTERVAL)
        updateUserDefaultsCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = false
    
    MPRemoteCommandCenter.sharedCommandCenter().changePlaybackRateCommand.enabled = false
    
    MPRemoteCommandCenter.sharedCommandCenter().ratingCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().likeCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().dislikeCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().bookmarkCommand.enabled = false
}


