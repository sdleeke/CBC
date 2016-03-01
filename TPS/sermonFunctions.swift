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

//typealias GroupTuple = (indexes: [Int]?, counts: [Int]?)

func documentsURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
}

func cachesURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first
}

func checkFile(url:NSURL?) -> Bool
{
    var result = false
    
    if (url != nil) { //  && Reachability.isConnectedToNetwork()
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
    if (url != nil) { //  && Reachability.isConnectedToNetwork()
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
    
    if let jsonFileURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        // Check if file exist
        if (!fileManager.fileExistsAtPath(jsonFileURL.path!)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileURL.path!)
                } catch _ {
                    print("failed to copy sermons.json")
                }
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItemAtPath(jsonBundlePath!)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonFileURL.path!)
                
                let jsonBundleModDate = jsonBundleAttributes[NSFileModificationDate] as! NSDate
                let jsonDocumentsModDate = jsonDocumentsAttributes[NSFileModificationDate] as! NSDate
                
                if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
                    //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                    print("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                    print("JSON in Documents is the same date as JSON in bundle")
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
                
                if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
                    print("JSON in bundle is newer than JSON in Documents")
                    //copy the bundle into Documents directory
                    do {
                        // Copy File From Bundle To Documents Directory
                        try fileManager.removeItemAtPath(jsonFileURL.path!)
                        try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileURL.path!)
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
    
    if let jsonURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
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

func sermonsFromArchive() -> [Sermon]?
{
    // JSON is newer than Archive, reutrn nil.  That will force the archive to be rebuilt from the JSON.
    
    let fileManager = NSFileManager.defaultManager()
    
    let archiveFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE)
    let archiveExistsInFileSystem = fileManager.fileExistsAtPath(archiveFileSystemURL!.path!)
    
    if !archiveExistsInFileSystem {
        return nil
    }
    
    let jsonFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME)
    let jsonExistsInFileSystem = fileManager.fileExistsAtPath(jsonFileSystemURL!.path!)
    
    if (!jsonExistsInFileSystem) {
        // This should not happen since JSON should have been copied before the first archive was created.
        // Since we don't understand this state, return nil
        return nil
    }
    
    let jsonInBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE)
    let jsonExistsInBundle = fileManager.fileExistsAtPath(jsonInBundlePath!)
    
    if (jsonExistsInFileSystem && jsonExistsInBundle) {
        // Need to see if jsonInBundle is newer
        
        do {
            let jsonInBundleAttributes = try fileManager.attributesOfItemAtPath(jsonInBundlePath!)
            let jsonInFileSystemAttributes = try fileManager.attributesOfItemAtPath(jsonFileSystemURL!.path!)
            
            let jsonInBundleModDate = jsonInBundleAttributes[NSFileModificationDate] as! NSDate
            let jsonInDocumentsModDate = jsonInFileSystemAttributes[NSFileModificationDate] as! NSDate
            
//            print("jsonInBundleModDate: \(jsonInBundleModDate)")
//            print("jsonInDocumentsModDate: \(jsonInDocumentsModDate)")
            
            if (jsonInDocumentsModDate.isOlderThan(jsonInBundleModDate)) {
                //The JSON in the Bundle is newer, we need to use it instead of the archive
                print("JSON in Documents is older than JSON in Bundle")
                return nil
            }
            
            if (jsonInDocumentsModDate.isEqualTo(jsonInBundleModDate)) {
                //This is normal since JSON in Documents is copied from JSON in Bundle.  Do nothing.
                print("JSON in Bundle and in Documents are the same date")
            }
            
            if (jsonInDocumentsModDate.isNewerThan(jsonInBundleModDate)) {
                //The JSON in Documents is newer, we need to see if it is newer than the archive.
                print("JSON in Documents is newer than JSON in Bundle")
            }
        } catch _ {
            
        }
    }
    
    if (archiveExistsInFileSystem && jsonExistsInFileSystem) {
        do {
            let jsonInDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonFileSystemURL!.path!)
            let archiveInDocumentsAttributes = try fileManager.attributesOfItemAtPath(archiveFileSystemURL!.path!)
            
            let jsonInDocumentsModDate = jsonInDocumentsAttributes[NSFileModificationDate] as! NSDate
            let archiveInDocumentsModDate = archiveInDocumentsAttributes[NSFileModificationDate] as! NSDate
            
//            print("archiveInDocumentsModDate: \(archiveInDocumentsModDate)")
            
            if (jsonInDocumentsModDate.isNewerThan(archiveInDocumentsModDate)) {
                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the archive was created.
                print("JSON in Documents is newer than Archive in Documents")
                return nil
            }
            
            if (archiveInDocumentsModDate.isEqualTo(jsonInDocumentsModDate)) {
                //Should never happen since archive is created from JSON
                print("JSON in Documents is the same date as Archive in Documents")
                return nil
            }
            
            if (archiveInDocumentsModDate.isNewerThan(jsonInDocumentsModDate)) {
                print("Archive in Documents is newer than JSON in Documents")
                
                let data = NSData(contentsOfURL: NSURL(fileURLWithPath: archiveFileSystemURL!.path!))
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
            }
        } catch _ {
            
        }
    }
    
    return nil
}

func sermonsToArchive(sermons:[Sermon]?)
{
    if (sermons != nil) {
        if let archive = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE) {
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
    if (Globals.sermonRepository != nil) {
        for sermon in Globals.sermonRepository! {
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

    if (Globals.sermonTagsSelected == Constants.New) {
        Globals.sermonTagsSelected = nil
    }
    
    if (Globals.sermonTagsSelected != nil) {
        switch Globals.sermonTagsSelected! {
        case Constants.All:
            Globals.sermonTagsSelected = nil
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
        indexOfSermon = Globals.sermonRepository?.indexOf({ (sermon:Sermon) -> Bool in
            return (sermon.title == (dict[Constants.TITLE] as! String)) &&
                (sermon.date == (dict[Constants.DATE] as! String)) &&
                (sermon.service == (dict[Constants.SERVICE] as! String)) &&
                (sermon.speaker == (dict[Constants.SPEAKER] as! String))
        })
    }
    
    if (indexOfSermon != nil) {
        Globals.sermonLoaded = false
        Globals.sermonPlaying = Globals.sermonRepository?[indexOfSermon!]
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
        Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.currentPlaybackTime.description
//        saveSermonSettingsBackground()
    }
}

//func setupSermonPlayingUserDefaults()
//{
//    assert(Globals.sermonPlaying != nil,"Globals.sermonPlaying should not be nil if we're trying to update the userDefaults for the sermon that is playing")
//    
//    if (Globals.sermonPlaying != nil) {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        defaults.setObject(Globals.sermonPlaying?.dict, forKey: Constants.SERMON_PLAYING)
//        defaults.synchronize()
//    }
//}

func networkUnavailable(message:String?)
{
    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
        UIApplication.sharedApplication().keyWindow?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        
        let alert = UIAlertController(title:Constants.Network_Error,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}

func removeSliderObserver() {
    if (Globals.sliderObserver != nil) {
        Globals.sliderObserver!.invalidate()
        Globals.sliderObserver = nil
    }
}

//func removePlayObserver() {
//    if (Globals.playObserver != nil) {
//        Globals.playObserver!.invalidate()
//        Globals.playObserver = nil
//    }
//}

func setupPlayer(sermon:Sermon?)
{
    if (sermon != nil) {
        Globals.sermonLoaded = false

        Globals.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
        Globals.mpPlayer?.shouldAutoplay = false
        Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
        Globals.mpPlayer?.prepareToPlay()
        
        setupPlayingInfoCenter()
        
        Globals.playerPaused = true
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

func updateCurrentTimeExact()
{
    if (Globals.mpPlayer != nil) {
        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            updateCurrentTimeExact(Globals.mpPlayer!.currentPlaybackTime)
        }
    }
}

func updateCurrentTimeExact(seekToTime:NSTimeInterval)
{
    if (seekToTime >= 0) {
        Globals.sermonPlaying?.currentTime = seekToTime.description
//        saveSermonSettingsBackground()
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

            if let sermonsInSeries = Globals.sermonRepository?.filter({ (sermon:Sermon) -> Bool in
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
    
    func isNewerThan(dateToCompare : NSDate) -> Bool
    {
        return (self.compare(dateToCompare) == NSComparisonResult.OrderedDescending) && (self.compare(dateToCompare) != NSComparisonResult.OrderedSame)
    }
    
    
    func isOlderThan(dateToCompare : NSDate) -> Bool
    {
        return (self.compare(dateToCompare) == NSComparisonResult.OrderedAscending) && (self.compare(dateToCompare) != NSComparisonResult.OrderedSame)
    }
    

    func isEqualTo(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedSame
    }

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

func saveSermonSettingsBackground()
{
//    print("saveSermonSettingsBackground")
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
        saveSermonSettings()
    }
}

func saveSermonSettings()
{
//    print("saveSermonSettings")
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

func stringWithoutPrefixes(fromString:String?) -> String?
{
    var sortString = fromString

    let quote:String = "\""
    let prefixes = ["A ","An ","And ","The "]
    
    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substringToIndex(quote.endIndex) == quote) {
        sortString = fromString!.substringFromIndex(quote.endIndex)
    }
    
    for prefix in prefixes {
        if (fromString?.endIndex >= prefix.endIndex) && (fromString?.substringToIndex(prefix.endIndex) == prefix) {
            sortString = fromString!.substringFromIndex(prefix.endIndex)
            break
        }
    }

    return sortString
}


func clearSermonsForDisplay()
{
    Globals.display.sermons = nil
    Globals.display.sectionTitles = nil
    Globals.display.sectionIndexes = nil
    Globals.display.sectionCounts = nil
}


func setupSermonsForDisplay()
{
    Globals.display.sermons = Globals.active?.sermons
    
    Globals.display.sectionTitles = Globals.active?.sectionTitles
    Globals.display.sectionIndexes = Globals.active?.sectionIndexes
    Globals.display.sectionCounts = Globals.active?.sectionCounts
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


//func sermonsInSermonSeries(sermons:[Sermon]?,series:String?) -> [Sermon]?
//{
//    if (series != nil) {
//        if let seriesSort = stringWithoutPrefixes(series) {
//            return Globals.sermons.all?.groupSort?[Constants.SERIES]?[seriesSort]?[Constants.CHRONOLOGICAL]
//        } else {
//            return nil
//        }
//    }
//    
//    return nil
//    //
//    //    return sermons?.filter({ (sermon:Sermon) -> Bool in
//    //        return sermon.series == series
//    //    }).sort({ (first:Sermon, second:Sermon) -> Bool in
//    //        if (first.fullDate!.isEqualTo(second.fullDate!)) {
//    //            return first.id < second.id
//    //        } else {
//    //            return first.fullDate!.isOlderThan(second.fullDate!)
//    //        }
//    //    })
//}

func sermonsInSermonSeries(sermon:Sermon?) -> [Sermon]?
{
    var sermonsInSeries:[Sermon]?
    
    if (sermon != nil) {
        if (sermon!.hasSeries()) {
            if (Globals.sermons.all == nil) {
                let seriesSermons = Globals.sermonRepository?.filter({ (testSermon:Sermon) -> Bool in
                    return sermon!.hasSeries() ? (testSermon.series == sermon!.series) : (testSermon.keyBase == sermon!.keyBase)
                })
                sermonsInSeries = sortSermonsByYear(seriesSermons, sorting: Constants.CHRONOLOGICAL)
            } else {
                sermonsInSeries = Globals.sermons.all?.groupSort?[Constants.SERIES]?[sermon!.seriesSort!]?[Constants.CHRONOLOGICAL]
            }
        } else {
            sermonsInSeries = [sermon!]
        }
    }
    
    return sermonsInSeries
}

func sermonsInBook(sermons:[Sermon]?,book:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.book == book
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThan(second.fullDate!)
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
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
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
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
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
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
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
        
        return Constants.OLD_TESTAMENT.count + Constants.NEW_TESTAMENT.count + 1 // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
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

func sortSermonsChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            return $0.service < $1.service
        } else {
            return $0.fullDate!.isOlderThan($1.fullDate!)
        }
    }
}

func sortSermonsReverseChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            return $0.service > $1.service
        } else {
            return $0.fullDate!.isNewerThan($1.fullDate!)
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
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            result = (first.service < second.service)
        } else {
            result = first.fullDate!.isOlderThan(second.fullDate!)
        }
        break
    
    case Constants.REVERSE_CHRONOLOGICAL:
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            result = (first.service > second.service)
        } else {
            result = first.fullDate!.isNewerThan(second.fullDate!)
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
        
        if let sermons = Globals.sermonRepository {
            for sermon in sermons {
                if (showTesting) {
                    print("Testing: \(counter) \(sermon.title!)")
                } else {
                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.notes != nil) {
                    if (NSData(contentsOfURL: sermon.notesURL!) == nil) {
                        print("Transcript DOES NOT exist for: \(sermon.title!) PDF: \(sermon.notes!)")
                    } else {
                        
                    }
                }
                
                if (sermon.slides != nil) {
                    if (NSData(contentsOfURL: sermon.slidesURL!) == nil) {
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
        if let sermons = Globals.sermonRepository {
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
    
    if let sermons = Globals.sermonRepository {
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
    
    for sermon in Globals.sermonRepository! {
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
    
    for sermon in Globals.sermonRepository! {
        if (!sermon.hasSpeaker()) {
            print("Speaker missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for speaker - end")
}

func testSermonsForSeries()
{
    print("Testing for sermons with \"(Part \" in the title but no series - start")
    
    for sermon in Globals.sermonRepository! {
        if (sermon.title?.rangeOfString("(Part ", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil) && sermon.hasSeries() {
            print("Series missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for sermons with \"(Part \" in the title but no series - end")
}

func testSermonsBooksAndSeries()
{
    print("Testing for sermon series and book the same - start")

    for sermon in Globals.sermonRepository! {
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
    if (tagSelected != nil) {
        return Globals.sermons.all?.tagSermons?[stringWithoutPrefixes(tagSelected)!]
    } else {
        return nil
    }
}

func tagsFromSermons(sermons:[Sermon]?) -> [String]?
{
    if sermons != nil {
        var tagsSet = Set<String>()

        for sermon in sermons! {
            if let tags = sermon.tagsSet {
                tagsSet.unionInPlace(tags)
            }
        }
        
        var tagsArray = Array(tagsSet).sort({ stringWithoutPrefixes($0) < stringWithoutPrefixes($1) })

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
        updateCurrentTimeExact()
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
            updateCurrentTimeExact()
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
        updateCurrentTimeExact()
        setupPlayingInfoCenter()
        return MPRemoteCommandHandlerStatus.Success
    }
    
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = false
    MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        Globals.mpPlayer?.currentPlaybackTime += NSTimeInterval(Constants.SKIP_TIME_INTERVAL)
        updateCurrentTimeExact()
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


