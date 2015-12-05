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

func removeTempFiles()
{
    // Clean up temp directory for cancelled downloads
    let fileManager = NSFileManager.defaultManager()
    let path = NSTemporaryDirectory()
    do {
        let array = try fileManager.contentsOfDirectoryAtPath(path)
        
        for name in array {
            if (name.rangeOfString(Constants.TMP_FILE_EXTENSION)?.endIndex == name.endIndex) {
                print("Deleting: \(name)")
                try fileManager.removeItemAtPath(path + name)
            }
        }
    } catch _ {
    }
}

func jsonDataFromURL() -> JSON
{
    if let url = NSURL(string: Constants.JSON_URL_PREFIX + Constants.CBC_SHORT.lowercaseString + "." + Constants.SERMONS_JSON) {
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
    if let path = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: "json") {
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
    
    //Get documents directory URL
    let jsonDocumentsURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON)
    
    let jsonBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: "json")
    
    // Check if file exist
    if (!fileManager.fileExistsAtPath(jsonDocumentsURL!.path!)){
        if (jsonBundlePath != nil) {
            do {
                // Copy File From Bundle To Documents Directory
                try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonDocumentsURL!.path!)
            } catch _ {
                print("failed to copy sermons.json")
            }
        }
    } else {
        //    fileManager.removeItemAtPath(destination)
        // Which is newer, the bundle file or the file in the Documents folder?
        do {
            let jsonBundleAttributes = try fileManager.attributesOfItemAtPath(jsonBundlePath!)
            
//            print("srcAttributes")
//            for (key,value) in srcAttributes {
//                print("Key: \(key) Value: \(value)")
//            }

            let destAttributes = try fileManager.attributesOfItemAtPath(jsonDocumentsURL!.path!)
            
//            print("destAttributes")
//            for (key,value) in destAttributes {
//                print("Key: \(key) Value: \(value)")
//            }

            let jsonBundleModDate = jsonBundleAttributes[NSFileModificationDate] as! NSDate
            let destModDate = destAttributes[NSFileModificationDate] as! NSDate
            
            if (jsonBundleModDate.isLessThanDate(destModDate)) {
                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                print("JSON in Documents is newer than JSON in bundle")
            }
            
            if (jsonBundleModDate.isEqualToDate(destModDate)) {
                let jsonBundleFileSize = jsonBundleAttributes[NSFileSize] as! Int
                let destFileSize = destAttributes[NSFileSize] as! Int
                
                if (jsonBundleFileSize != destFileSize) {
                    print("Same dates different file sizes")
                    //We have a problem.
                } else {
                    print("Same dates same file sizes")
                    //Do nothing, they are the same.
                }
            }
            
            if (jsonBundleModDate.isGreaterThanDate(destModDate)) {
                print("JSON in bundle is newer than JSON in Documents")
                //copy the bundle into Documents directory
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.removeItemAtPath(jsonDocumentsURL!.path!)
                    try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonDocumentsURL!.path!)
                } catch _ {
                    print("failed to copy sermons.json")
                }
            }
        } catch _ {
            
        }
        
    }
}

func jsonDataFromDocumentsDirectory() -> JSON
{
    jsonToDocumentsDirectory()
    
    if let jsonURL = documentsURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON) {
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

func loadSermonDicts() -> [[String:String]]?
{
    //    var json = jsonDataFromURL()
    //    if (json == nil) {
    //        json = jsonDataFromBundle()
    //    }

    var sermonDicts = [[String:String]]()
    
    let json = jsonDataFromDocumentsDirectory()
    
    if json != JSON.null {
        //                print("json:\(json)")
        
        let sermons = json[Constants.JSON_ARRAY_KEY]
        
        for i in 0..<sermons.count {
            //                    print("sermon: \(sermons[i])")
            
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

    var indexOfSermon = -1
    
    if let dict = defaults.dictionaryForKey(Constants.SERMON_PLAYING) {
        for index in 0..<Globals.sermons!.count {
            if (Globals.sermons![index].title == (dict[Constants.TITLE] as! String)) &&
                (Globals.sermons![index].date == (dict[Constants.DATE] as! String)) &&
                (Globals.sermons![index].service == (dict[Constants.SERVICE] as! String)) &&
                (Globals.sermons![index].speaker == (dict[Constants.SPEAKER] as! String)) {
                    indexOfSermon = index
                    break
            }
        }
    }
    
    if (indexOfSermon > -1) {
        Globals.sermonLoaded = false
        Globals.sermonPlaying = Globals.sermons?[indexOfSermon]
    } else {
        Globals.sermonLoaded = true
    }
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
            sermonURL = Constants.BASE_AUDIO_URL + sermon!.audio!
            break
        
        case Constants.VIDEO:
            sermonURL = Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX
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
//        let imageName = "\(Globals.coverArtPreamble)\(Globals.seriesPlaying!.name)\(Globals.coverArtPostamble)"
        //    print("\(imageName)")
        
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

            if let sermons = Globals.sermons {
                var sermonsInSeries = [Sermon]()
                
                for sermon in sermons {
                    if (sermon.series == Globals.sermonPlaying?.series) {
                        sermonsInSeries.append(sermon)
                    }
                }
                sermonsInSeries.sortInPlace() { $0.title < $1.title }
                
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
    
    func isGreaterThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
        {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    
    func isLessThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
        {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    
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
    defaults.setObject(Globals.sermonSettings,forKey: Constants.SERMON_SETTINGS_KEY)
//    print("\(Globals.sermonSettings)")
    defaults.setObject(Globals.seriesViewSplits, forKey: Constants.SERIES_VIEW_SPLITS_KEY)
//    print("\(Globals.seriesViewSplits)")
    defaults.synchronize()
}

func loadSermonSettings()
{
    let defaults = NSUserDefaults.standardUserDefaults()
    
    if let settingsDictionary = defaults.dictionaryForKey(Constants.SERMON_SETTINGS_KEY) {
//        print("\(settingsDictionary)")
        Globals.sermonSettings = settingsDictionary as? [String:String]
    } else {
        Globals.sermonSettings = [String:String]()
    }
    
    if let viewSplitsDictionary = defaults.dictionaryForKey(Constants.SERIES_VIEW_SPLITS_KEY) {
//        print("\(viewSplitsDictionary)")
        Globals.seriesViewSplits = viewSplitsDictionary as? [String:String]
    } else {
        Globals.seriesViewSplits = [String:String]()
    }

//    print("\(Globals.sermonSettings)")
}

func stringWithoutLeadingTheOrAOrAn(fromString:String?) -> String?
{
    let a:String = "A "
    let an:String = "An "
    let the:String = "The "
    
    var sortString = fromString
    
    if (fromString?.endIndex >= a.endIndex) && (fromString?.substringToIndex(a.endIndex) == a) {
        sortString = fromString!.substringFromIndex(a.endIndex)
    } else
        if (fromString?.endIndex >= an.endIndex) && (fromString?.substringToIndex(an.endIndex) == an) {
            sortString = fromString!.substringFromIndex(an.endIndex)
        } else
            if (fromString?.endIndex >= the.endIndex) && (fromString?.substringToIndex(the.endIndex) == the) {
                sortString = fromString!.substringFromIndex(the.endIndex)
//        print("\(titleSort)")
    }
    
    return sortString
}


func fillSortAndGroupCache()
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
        if (Globals.sortGroupCache == nil) {
            Globals.sortGroupCache = SortGroupCache()
        }
        
        let sermons = Globals.activeSermons
        
        let sortings = [Constants.CHRONOLOGICAL, Constants.REVERSE_CHRONOLOGICAL]
        let groupings = [Constants.YEAR, Constants.SERIES, Constants.BOOK, Constants.SPEAKER]
        
        for sorting in sortings {
            for grouping in groupings {
                if (Globals.sortGroupCache?[sorting + grouping] == nil) {
                    let sermonList = sortSermons(sermons, sorting: sorting, grouping: grouping)
                    let groupTuple = groupSermons(sermonList, grouping: grouping)
                    let sections = sermonSections(sermonList, sorting: sorting, grouping: grouping)
                    if (Globals.sortGroupCache?[sorting + grouping] == nil) {
                        Globals.sortGroupCache?[sorting + grouping] = (sermons: sermonList, sections: sections, indexes: groupTuple?.indexes, counts: groupTuple?.counts)
                    }
                }
            }
        }
    })
}


func sortAndGroupSermons() {
    if let sortGroupTuple = Globals.sortGroupCache?[Globals.sorting! + Globals.grouping!] {
        Globals.activeSermons = sortGroupTuple.sermons
        Globals.sermonSections = sortGroupTuple.sections
        Globals.sermonSectionIndexes = sortGroupTuple.indexes
        Globals.sermonSectionCounts = sortGroupTuple.counts
    } else {
        if (Globals.sortGroupCache == nil) {
            Globals.sortGroupCache = SortGroupCache()
        }
        if (Globals.sermonsNeedGroupsSetup) {
            setupSermonGroups()
            Globals.sermonsNeedGrouping = true
            Globals.sermonsNeedGroupsSetup = false
            fillSortAndGroupCache()
        }
        
        if Globals.sermonsNeedGrouping {
            Globals.activeSermons = sortSermons(Globals.activeSermons,sorting: Globals.sorting, grouping: Globals.grouping)
            if let groupTuple = groupSermons(Globals.activeSermons, grouping: Globals.grouping) {
                Globals.sermonSectionIndexes = groupTuple.indexes
                Globals.sermonSectionCounts = groupTuple.counts
            }

            Globals.sermonSections = sermonSections()
            
            Globals.sermonsNeedGrouping = false
        } else {
            if Globals.sermonsNeedSorting {
                Globals.activeSermons = sortSermons(Globals.activeSermons,sorting: Globals.sorting, grouping: Globals.grouping)
                if (Globals.grouping == Constants.YEAR) {
                    if let groupTuple = groupSermons(Globals.activeSermons, grouping: Globals.grouping) {
                        Globals.sermonSectionIndexes = groupTuple.indexes
                        Globals.sermonSectionCounts = groupTuple.counts
                    }

                    var sections:[Int]?
                    
                    switch Globals.sorting! {
                    case Constants.REVERSE_CHRONOLOGICAL:
                        sections = Globals.sermonYears?.sort({ $1 < $0 })
                        break
                    case Constants.CHRONOLOGICAL:
                        sections = Globals.sermonYears?.sort({ $0 < $1 })
                        break
                        
                    default:
                        sections = nil
                        break
                    }

                    Globals.sermonSections = sections?.map() { (year) in
                        return "\(year)"
                    }
                }
                
                Globals.sermonsNeedSorting = false
            }
        }
 
        //typealias SortGroupTuple = (sermons: [Sermon]?, sections: [String]?, indexes: [Int]?, counts: [Int]?)

        Globals.sortGroupCache?[Globals.sorting! + Globals.grouping!] = (sermons: Globals.activeSermons, sections: Globals.sermonSections, indexes: Globals.sermonSectionIndexes, counts: Globals.sermonSectionCounts)
    }
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
    
    Globals.sermonYears = yearsFromSermons(sermons, sorting: Globals.sorting)
    Globals.sermonSeries = seriesSectionsFromSermons(sermons)
    Globals.sermonBooks = bookSectionsFromSermons(sermons)
    Globals.sermonSpeakers = speakerSectionsFromSermons(sermons)
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


func sermonSections() -> [String]?
{
    var strings:[String]?
    
    switch Globals.grouping! {
    case Constants.YEAR:
        switch Globals.sorting! {
        case Constants.REVERSE_CHRONOLOGICAL:
            Globals.sermonYears?.sortInPlace() { $1 < $0 }
            break
        case Constants.CHRONOLOGICAL:
            Globals.sermonYears?.sortInPlace() { $0 < $1 }
            break
        default:
            break
        }
        
        strings = Globals.sermonYears?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Constants.SERIES:
        strings = Globals.sermonSeries
        break
        
    case Constants.BOOK:
        strings = Globals.sermonBooks
        break
        
    case Constants.SPEAKER:
        strings = Globals.sermonSpeakers
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

//func sortAndGroupSermonsAbsolute() {
//    sortSermons()
//    Globals.priorSorting = Globals.sorting
//    groupSermons()
//    Globals.priorGrouping = Globals.grouping
//}
//
//func sortAndGroupSermonsOld() {
//    switch Globals.grouping! {
//    case Constants.YEAR:
//        if (Globals.searchActive) {
//            Globals.searchSermons = sortSermonsByYear(Globals.searchSermons)
//            groupSermonsByYear(Globals.searchSermons)
//        } else {
//            switch Globals.showing! {
//            case Constants.TAGGED:
//                Globals.taggedSermons = sortSermonsByYear(Globals.taggedSermons)
//                groupSermonsByYear(Globals.taggedSermons)
//                break
//                
//            case Constants.ALL:
//                Globals.sermons = sortSermonsByYear(Globals.sermons)
//                groupSermonsByYear(Globals.sermons)
//                break
//            }
//        }
//        break
//        
//    case Constants.SERIES:
//        if (Globals.searchActive) {
//            Globals.searchSermons = sortSermonsBySeries(Globals.searchSermons)
//            groupSermonsBySeries(Globals.searchSermons)
//        } else {
//            switch Globals.showing! {
//            case Constants.TAGGED:
//                Globals.taggedSermons = sortSermonsBySeries(Globals.taggedSermons)
//                groupSermonsBySeries(Globals.taggedSermons)
//                break
//                
//            case Constants.ALL:
//                Globals.sermons = sortSermonsBySeries(Globals.sermons)
//                groupSermonsBySeries(Globals.sermons)
//                break
//            }
//        }
//        break
//        
//    case Constants.BOOK:
//        if (Globals.searchActive) {
//            Globals.searchSermons = sortSermonsByBook(Globals.searchSermons)
//            groupSermonsByBook(Globals.searchSermons)
//        } else {
//            switch Globals.showing! {
//            case Constants.TAGGED:
//                Globals.taggedSermons = sortSermonsByBook(Globals.taggedSermons)
//                groupSermonsByBook(Globals.taggedSermons)
//                break
//                
//            case Constants.ALL:
//                Globals.sermons = sortSermonsByBook(Globals.sermons)
//                groupSermonsByBook(Globals.sermons)
//                break
//            }
//        }
//        break
//        
//    case Constants.SPEAKER:
//        if (Globals.searchActive) {
//            Globals.searchSermons = sortSermonsBySpeaker(Globals.searchSermons)
//            groupSermonsBySpeaker(Globals.searchSermons)
//        } else {
//            switch Globals.showing! {
//            case Constants.TAGGED:
//                Globals.taggedSermons = sortSermonsBySpeaker(Globals.taggedSermons)
//                groupSermonsBySpeaker(Globals.taggedSermons)
//                break
//                
//            case Constants.ALL:
//                Globals.sermons = sortSermonsBySpeaker(Globals.sermons)
//                groupSermonsBySpeaker(Globals.sermons)
//                break
//            }
//        }
//        break
//    }
//}


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
//
//    var sections:[Int]?
//
//    if let sermons = sermonsToGroup {
//        var sermonYearsSet = Set<Int>()
//        var sermonYearsArray = [Int]()
//        
//        for sermon in sermons {
//            
//            let calendar = NSCalendar.currentCalendar()
//            let components = calendar.components(.Year, fromDate: sermon.fullDate!)
//            
//            sermonYearsSet.insert(components.year)
//        }
//        
//        for year in sermonYearsSet {
//            sermonYearsArray.append(year)
//        }
//        
//        switch sorting! {
//        case Constants.REVERSE_CHRONOLOGICAL:
//            //            print("groupSermonsByYear reverseChronological")
//            sections = sermonYearsArray.sort({ $1 < $0 })
//            break
//        case Constants.CHRONOLOGICAL:
//            //            print("groupSermonsByYear chronological")
//            sections = sermonYearsArray.sort({ $0 < $1 })
//            break
//            
//        default:
//            sections = nil
//            break
//        }
//    }
//    
//    return sections
//}


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
        
        //        for year in sermonSections {
        //            var counter:Int = 0
        //
        //            let calendar = NSCalendar.currentCalendar()
        //            var components:NSDateComponents
        //
        //            for index in 0..<sermons.count {
        //                components = calendar.components(.Year, fromDate: sermons[index].fullDate!)
        //
        //                if (year == "\(components.year)") {
        //                    if (counter == 0) {
        //                        sermonSectionIndexes.append(index)
        //                    }
        //                    counter++
        //                }
        //            }
        //            
        //            sermonSectionCounts.append(counter)
        //        }
        
        //    print("sermonSections: \(Globals.sermonSections)")
        //    print("sermonSectionIndexes: \(Globals.sermonSectionIndexes)")
        //    print("sermonSectionCounts: \(Globals.sermonSectionCounts)")
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

//Only used in deepLinking
func sermonsInSermonSeries(sermons:[Sermon]?,series:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.series == series
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isLessThanDate(second.fullDate!)
        }
    })
}
//    var sermonArray = [Sermon]()
//    
//    if (sermons != nil) {
//        for sermon in sermons! {
//            if (sermon.series == series) {
//                //Found one
//                sermonArray.append(sermon)
//            }
//        }
//        
//        //Why are we sorting oldest to newest rather than how the user wants to see things?
//        
//        //return the array sorted oldest to newest
//        if (sermonArray.count > 0) {
//            sermonArray.sortInPlace() {
//                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//                    return $0.service == Constants.MORNING_SERVICE
//                } else {
//                    return $0.fullDate!.isLessThanDate($1.fullDate!)
//                }
//            }
//        }
//        
//        //Not according to the current sorting
//        //    if (sermonArray.count > 0) {
//        //        switch Globals.sorting! {
//        //        case Constants.CHRONOLOGICAL:
//        //            sermonArray.sort() {
//        //                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//        //                    return $0.service == Constants.MORNING_SERVICE
//        //                } else {
//        //                    return $0.fullDate!.isLessThanDate($1.fullDate!)
//        //                }
//        //            }
//        //            break
//        //
//        //        case Constants.REVERSE_CHRONOLOGICAL:
//        //            sermonArray.sort() {
//        //                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//        //                    return $0.service == Constants.EVENING_SERVICE
//        //                } else {
//        //                    return $0.fullDate!.isGreaterThanDate($1.fullDate!)
//        //                }
//        //            }
//        //            break
//        //        }
//        //    }
//    }
//    
//    return sermonArray.count > 0 ? sermonArray : nil
//}

//Only used in deepLinking
func sermonsInBook(sermons:[Sermon]?,book:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.book == book
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            return first.service == Constants.MORNING_SERVICE
        } else {
            return first.fullDate!.isLessThanDate(second.fullDate!)
        }
    })

//    var sermonArray = [Sermon]()
//    
//    if (sermons != nil) {
//        for sermon in sermons! {
//            if (sermon.book == book) {
//                //Found one
//                sermonArray.append(sermon)
//            }
//        }
//        
//        //Why are we sorting oldest to newest rather than how the user wants to see things?
//        
//        //return the array sorted oldest to newest
//        if (sermonArray.count > 0) {
//            sermonArray.sortInPlace() {
//                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//                    return $0.service == Constants.MORNING_SERVICE
//                } else {
//                    return $0.fullDate!.isLessThanDate($1.fullDate!)
//                }
//            }
//        }
//        
//        //Not according to the current sorting
//        //    if (sermonArray.count > 0) {
//        //        switch Globals.sorting! {
//        //        case Constants.CHRONOLOGICAL:
//        //            sermonArray.sort() {
//        //                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//        //                    return $0.service == Constants.MORNING_SERVICE
//        //                } else {
//        //                    return $0.fullDate!.isLessThanDate($1.fullDate!)
//        //                }
//        //            }
//        //            break
//        //
//        //        case Constants.REVERSE_CHRONOLOGICAL:
//        //            sermonArray.sort() {
//        //                if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
//        //                    return $0.service == Constants.EVENING_SERVICE
//        //                } else {
//        //                    return $0.fullDate!.isGreaterThanDate($1.fullDate!)
//        //                }
//        //            }
//        //            break
//        //        }
//        //    }
//    }
//    
//    return sermonArray.count > 0 ? sermonArray : nil
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
                return bookNumberInBible(first) < bookNumberInBible(second)
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
//    var bookSet = Set<String>()
////    var bookArray = [String]()
//
//    if (sermons != nil) {
//        for sermon in sermons! {
//            if (sermon.hasBook()) {
//                bookSet.insert(sermon.book!)
//            } else {
//                //Shouldn't be necessary since the book function already does this
//                bookSet.insert(Constants.Selected_Scriptures)
//            }
//        }
//        
////        for book in bookSet {
////            bookArray.append(book)
////        }
//        
//        return Array(bookSet).sort() { bookNumberInBible($0) < bookNumberInBible($1) }
//    }
//    
//    return nil
//}

func seriesSectionsFromSermons(sermons:[Sermon]?,withTitles:Bool) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
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
//    var seriesSet = Set<String>()
////    var seriesArray:[String]?
//    
//    if (sermons != nil) {
//        for sermon in sermons! {
//            if (sermon.hasSeries()) {
//                seriesSet.insert(sermon.series!)
//            } else {
//                if withTitles {
//                    seriesSet.insert(sermon.title!)
//                } else {
//                    seriesSet.insert(Constants.Individual_Sermons)
//                }
//            }
//        }
//        
//        if withTitles {
//            seriesSet.insert(Constants.Individual_Sermons)
//        }
//
////        for series in seriesSet {
////            seriesArray.append(series)
////        }
////
////        if withTitles {
////            seriesArray.append(Constants.Individual_Sermons)
////        }
//
//        return Array(seriesSet).sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) }
//    }
//    
//    return nil
//}

func seriesFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
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
            Set(sermons!.map({ (sermon:Sermon) -> String in
                if (sermon.hasSeries()) {
                    return sermon.series!
                } else {
                    return Constants.Individual_Sermons
                }
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutLeadingTheOrAOrAn(first) < stringWithoutLeadingTheOrAOrAn(second)
            })
        : nil
}
//    if let sermons = sermonsToGroup {
//        var sermonSeriesSet = Set<String>()
////        var sermonSeriesArray = [String]()
//        
//        for sermon in sermons {
//            //        print("\(sermon.series)")
//            if (sermon.hasSeries()) {
//                sermonSeriesSet.insert(sermon.series!)
//            } else {
//                //print("None: \(sermon.title)")
//                sermonSeriesSet.insert(Constants.Individual_Sermons)
//            }
//        }
//        
////        for series in sermonSeriesSet {
////            sermonSeriesArray.append(series)
////        }
//        
//        return Array(sermonSeriesSet).sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) }
//    }
//    
//    return nil
//}

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
        
        //        print("Last section! Section \(sermonSectionIndexes.count) at Index: \(index-1) Last section count: \(counter)")
        
        //        for series in Globals.sermonSeries! {
        //            var counter:Int = 0
        //
        //            for index in 0..<sermons.count {
        //                if (!sermons[index].hasSeries()) {
        //                    if (series == Constants.Individual_Sermons) {
        //                        if (counter == 0) {
        //                            sermonSectionIndexes.append(index)
        //                        }
        //                        counter++
        //                    }
        //                } else
        //                    if (sermons[index].series == series) {
        //                        if (counter == 0) {
        //                            sermonSectionIndexes.append(index)
        //                        }
        //                        counter++
        //                }
        //            }
        //            
        //            sermonSectionCounts.append(counter)
        //        }
        
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

//func booksFromSermons(sermonsToGroup:[Sermon]?) -> [String]?
//{
//    if let sermons = sermonsToGroup {
//        var sermonBooksSet = Set<String>()
//        var sermonBooksArray = [String]()
//        
//        for sermon in sermons {
//            if (sermon.hasBook()) {
//                sermonBooksSet.insert(sermon.book!)
//            } else {
//                //Shouldn't be necessary since the book function already does this
//                sermonBooksSet.insert(Constants.Selected_Scriptures)
//            }
//        }
//        
//        //    print("\(sermonBooks)")
//        
//        for book in sermonBooksSet {
//            //        print("\(book)")
//            sermonBooksArray.append(book)
//        }
//        
//        return sermonBooksArray.sort() { bookNumberInBible($0) < bookNumberInBible($1) }
//        
//        //    print("sermonBooks \(Globals.sermonBooks)")
//        //    print("sermonSections \(Globals.sermonSections)")
//    }
//    
//    return nil
//}

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
        
        //        for book in Globals.sermonBooks! {
        //            var counter:Int = 0
        //
        //            for index in 0..<sermons.count {
        //                if (book == sermons[index].book) {
        //                    if (counter == 0) {
        //                        sermonSectionIndexes.append(index)
        //                    }
        //                    counter++
        //                }
        //            }
        //            
        //            sermonSectionCounts.append(counter)
        //        }
        
        //    print("sermonSectionIndexes \(Globals.sermonSectionIndexes)")
        //    print("sermonSectionCounts \(Globals.sermonSectionCounts)")
        
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
                if (sermon.hasSpeaker()) {
                    return sermon.speaker!
                } else {
                    return Constants.None
                }
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
        
        //        for speaker in Globals.sermonSpeakers! {
        //            var counter:Int = 0
        //
        //            for index in 0..<sermons.count {
        //                if (speaker == sermons[index].speaker) {
        //                    if (counter == 0) {
        //                        sermonSectionIndexes.append(index)
        //                    }
        //                    counter++
        //                }
        //            }
        //            
        //            sermonSectionCounts.append(counter)
        //        }
        
        return (indexes: sermonSectionIndexes, counts: sermonSectionCounts)
    }
    
    return nil
}

func sortSermonsChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
            return $0.service == Constants.MORNING_SERVICE
        } else {
            return $0.fullDate!.isLessThanDate($1.fullDate!)
        }
    }
}

func sortSermonsReverseChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
            return $0.service == Constants.EVENING_SERVICE
        } else {
            return $0.fullDate!.isGreaterThanDate($1.fullDate!)
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
            result = (first.service == Constants.MORNING_SERVICE)
        } else {
            result = first.fullDate!.isLessThanDate(second.fullDate!)
        }
        break
    
    case Constants.REVERSE_CHRONOLOGICAL:
        if (first.fullDate!.isEqualToDate(second.fullDate!)) {
            result = (first.service == Constants.EVENING_SERVICE)
        } else {
            result = first.fullDate!.isGreaterThanDate(second.fullDate!)
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

//        if (first.hasSeries() && second.hasSeries()) {
//            result = (first.seriesSort < second.seriesSort)
//        } else
//            if (!first.hasSeries() && second.hasSeries()) {
//                result = (first.seriesSection < second.seriesSort)
//            } else
//                if (first.hasSeries() && !second.hasSeries()) {
//                    result = (first.seriesSort < second.seriesSection)
//                } else
//                    if (!first.hasSeries() && !second.hasSeries()) {
//                        if (first.seriesSection != second.seriesSection) {
//                            result = first.seriesSection < second.seriesSection
//                        } else {
//                            result = compareSermonDates(first: first,second: second, sorting: sorting)
//                        }
//        }

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
        
//        if (first.hasSpeaker() && second.hasSpeaker()) {
//            result = (first.speakerSort < second.speakerSort)
//        } else
//            if (!first.hasSpeaker() && second.hasSpeaker()) {
//                result = first.speakerSection < second.speakerSort
//            } else
//                if (first.hasSpeaker() && !second.hasSpeaker()) {
//                    result = first.speakerSort < second.speakerSection
//                } else
//                    if (!first.hasSpeaker() && !second.hasSpeaker()) {
//                        if (first.speakerSection != second.speakerSection) {
//                            result = first.speakerSection < second.speakerSection
//                        } else {
//                            result = compareSermonDates(first: first,second: second, sorting: sorting)
//                        }
//        }

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
//        var result = false
//        
//        let first = $0
//        let second = $1
//        
//        if (!first.hasBook() && !second.hasBook()) {
//            result = compareSermonDates(first: first,second: second, sorting: sorting)
//        } else
//            if (!first.hasBook()) {
//                result = false
//            } else
//                if (!second.hasBook()) {
//                    result = true
//                } else
//                    if (first.book == second.book) {
//                        result = compareSermonDates(first: first,second: second, sorting: sorting)
//                    } else {
//                        result = (bookNumberInBible(first.book!) < bookNumberInBible(second.book!))
//        }
        
        return result
    }
}


func testSermonsPDFs(testExisting testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
//    var fileManager = NSFileManager.defaultManager()
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
                    
                    //            if (!fileManager.fileExistsAtPath(notesURL)) {
                    
                    if (NSData(contentsOfURL: NSURL(string: notesURL)!) == nil) {
                        print("Transcript DOES NOT exist for: \(sermon.title!) PDF: \(sermon.notes!)")
                    } else {
                        
                    }
                }
                
                if (sermon.slides != nil) {
                    let slidesURL = Constants.BASE_PDF_URL + sermon.slides!
                    
                    //            if (!fileManager.fileExistsAtPath(slidesURL)) {
                    
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
                        
        //                if (fileManager.fileExistsAtPath(notesURL)) {
                        
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
                        
        //                if (fileManager.fileExistsAtPath(slidesURL)) {
                        
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
    
    let bar:String = Constants.TAGS_SEPARATOR
    
    while (tags?.rangeOfString(bar) != nil) {
        tag = tags!.substringToIndex(tags!.rangeOfString(bar)!.startIndex)
        setOfTags.insert(tag)
        tags = tags!.substringFromIndex(tags!.rangeOfString(bar)!.endIndex)
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
            
            let bar:String = Constants.TAGS_SEPARATOR
            
            while (tags?.rangeOfString(bar) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(bar)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(bar)!.endIndex)
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

            let bar:String = Constants.TAGS_SEPARATOR

            while (tags?.rangeOfString(bar) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(bar)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(bar)!.endIndex)
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
    //    print("\(Globals.sermonDicts.count)")
    var sermons = [Sermon]()
    
    for sermonDict in sermonDicts! {
        let sermon = Sermon()

        sermon.dict = sermonDict
        
//        if (sermon.date != nil) {
//            sermon.fullDate = NSDate(dateString:sermon.date!)
//        } else {
//            print("NO DATE \(sermon.title!)")
//        }

//        sermon.bookFromScripture()
        
//        if sermon.isDownloaded() {
//            sermon.download.state = .downloaded
//        }

        //        print("\(sermon)")
        
        sermons.append(sermon)
    }
    
    return sermons.count > 0 ? sermons : nil
    
    //
    //    print("\(Globals.sermons.count)")
    //    for index in 0..<Globals.sermons.count {
    //        print("\(Globals.sermons[index].title!)")
    //    }
}
