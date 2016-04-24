//
//  Globals.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var sermon:Sermon?
    
    var state:PlayerState = .none {
        didSet {
            if (state != oldValue) {
                dateEntered = NSDate()
            }
        }
    }
    
    var dateEntered:NSDate?
    var timeElapsed:NSTimeInterval {
        get {
            return NSDate().timeIntervalSinceDate(dateEntered!)
        }
    }
    
    init()
    {
        dateEntered = NSDate()
    }
    
    func log()
    {
        var stateName:String?
        
        switch state {
        case .none:
            stateName = "none"
            break
            
        case .paused:
            stateName = "paused"
            break
            
        case .playing:
            stateName = "playing"
            break
            
        case .seekingForward:
            stateName = "seekingForward"
            break
            
        case .seekingBackward:
            stateName = "seekingBackward"
            break
            
        case .stopped:
            stateName = "stopped"
            break
        }
        
        if stateName != nil {
            print(stateName!)
        }
    }
}

struct Player {
    var mpPlayer:MPMoviePlayerController?
    var stateTime : PlayerStateTime?
    
    var paused:Bool = true {
        didSet {
            if (paused != oldValue) || (playing != stateTime?.sermon) || (stateTime?.sermon == nil) {
                stateTime = PlayerStateTime()
                stateTime?.sermon = playing
                
                if paused {
                    stateTime?.state = .paused
                } else {
                    stateTime?.state = .playing
                }
            }
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    var observer: NSTimer?
    
    var playing:Sermon? {
        didSet {
            if playing == nil {
                mpPlayer = nil
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
            }
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if playing != nil {
                defaults.setObject(playing?.dict, forKey: Constants.SERMON_PLAYING)
            } else {
                defaults.removeObjectForKey(Constants.SERMON_PLAYING)
            }
            defaults.synchronize()
        }
    }
    
    func logMPPlayerState()
    {
        if (mpPlayer != nil) {
            var stateName:String?
            
            switch mpPlayer!.playbackState {
            case .Interrupted:
                stateName = "Interrupted"
                break

            case .Paused:
                stateName = "Paused"
                break
                
            case .Playing:
                stateName = "Playing"
                break
                
            case .SeekingForward:
                stateName = "SeekingForward"
                break
                
            case .SeekingBackward:
                stateName = "SeekingBackward"
                break
                
            case .Stopped:
                stateName = "Stopped"
                break
            }
            
            if (stateName != nil) {
                print(stateName!)
            }
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
}

struct SermonsNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

struct Display {
    var sermons:[Sermon]?
    
    var sectionTitles:[String]?
    var sectionCounts:[Int]?
    var sectionIndexes:[Int]?
}

struct SermonRepository {
    var list:[Sermon]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:Sermon]()
                
                for sermon in list! {
                    if index![sermon.id!] == nil {
                        index![sermon.id!] = sermon
                    } else {
                        print("DUPLICATE SERMON ID: \(sermon)")
                    }
                }
                
                scriptureIndex = nil
            }
        }
    }
    
    var index:[String:Sermon]?
    var scriptureIndex:ScriptureIndex?
}

struct Sermons {
    //All sermons
    var all:SermonsListGroupSort?
    
    //The sermons from a search
    var search:SermonsListGroupSort? // These could be in a cache, one for each search
    
//    var hiddenTagged:SermonsListGroupSort?
    
    //The sermons with the selected tags, although now we only support one tag being selected
    var tagged:SermonsListGroupSort?
}

var globals:Globals!

class Globals {
    var finished = 0
    var progress = 0
    
    var allowSaveSettings = true

    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
    var scrolledToSermonLastSelected = false
    
    var grouping:String? = Constants.YEAR {
        didSet {
            sermonsNeed.grouping = (grouping != oldValue)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if (grouping != nil) {
                defaults.setObject(grouping,forKey: Constants.GROUPING)
            } else {
                //Should not happen
                defaults.removeObjectForKey(Constants.GROUPING)
            }
            defaults.synchronize()
        }
    }
    
    var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            sermonsNeed.sorting = (sorting != oldValue)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if (sorting != nil) {
                defaults.setObject(sorting,forKey: Constants.SORTING)
            } else {
                //Should not happen
                defaults.removeObjectForKey(Constants.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    var autoAdvance:Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.AUTO_ADVANCE)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var cacheDownloads:Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.CACHE_DOWNLOADS)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var refreshing:Bool = false
    var loading:Bool = false
    
    var searchActive:Bool = false
    var searchText:String? {
        didSet {
            if (searchText != oldValue) {
                if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
                    NSUserDefaults.standardUserDefaults().setObject(searchText, forKey: Constants.SEARCH_TEXT)
                    NSUserDefaults.standardUserDefaults().synchronize()
                } else {
                    sermons.search = nil
                    NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.SEARCH_TEXT)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
        }
    }
    
    var showing:String? = Constants.ALL

    var gotoPlayingPaused:Bool = false
    var showingAbout:Bool = false

    var player = Player()
    
    var selectedSermon:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let selectedSermonID = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
                selectedSermon = sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    var selectedSermonDetail:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let selectedSermonID = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
                selectedSermon = sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    // These are hidden behind custom accessors in Sermon
    var viewSplits:[String:String]?
    var settings:[String:[String:String]]?
    
    var history:[String]?

    var sermonRepository = SermonRepository()
    
    var sermons = Sermons()
    
    var sermonTagsSelected:String? {
        didSet {
            if (sermonTagsSelected != nil) {
                if (sermonTagsSelected != oldValue) || (sermons.tagged == nil) {
                    if sermons.all == nil {
                        //This is filtering, i.e. searching all sermons => s/b in background
                        sermons.tagged = SermonsListGroupSort(sermons: sermonsWithTag(sermonRepository.list, tag: sermonTagsSelected))
                    } else {
                        sermons.tagged = SermonsListGroupSort(sermons: sermons.all?.tagSermons?[stringWithoutPrefixes(sermonTagsSelected!)!])
                    }
                }
            } else {
                sermons.tagged = nil
            }
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if sermonTagsSelected != nil {
                defaults.setObject(sermonTagsSelected, forKey: Constants.COLLECTION)
            } else {
                defaults.removeObjectForKey(Constants.COLLECTION)
            }
            defaults.synchronize()
        }
    }
    
    var sermonsToSearch:[Sermon]? {
        get {
            var sermons:[Sermon]?
            
            switch showing! {
            case Constants.TAGGED:
                sermons = self.sermons.tagged?.list
                break
                
            case Constants.ALL:
//                if self.sermons.all == nil {
//                    self.sermons.all = SermonsListGroupSort(sermons: sermonRepository.list)
//                }
                sermons = self.sermons.all?.list
                break
                
            default:
                break
            }
            
            return sermons
        }
    }
    
    var activeSermons:[Sermon]? {
        get {
            return active?.sermons
        }
        
        set {
            active = SermonsListGroupSort(sermons: newValue)
        }
    }
    
    var active:SermonsListGroupSort? {
        get {
            if (searchActive) {
                return sermons.search
            } else {
                var sermons:SermonsListGroupSort?
                
                switch showing! {
                case Constants.TAGGED:
                    sermons = self.sermons.tagged
                    break
                
                case Constants.ALL:
                    sermons = self.sermons.all
                    break
                
                default:
                    break
                }
                
                return sermons
            }
        }
        
        set {
            if (searchActive) {
                sermons.search = newValue
            } else {
                switch showing! {
                case Constants.TAGGED:
//                    sermons.tagged = newValue
                    print("ERROR: setting active while TAGGED.")
                    break
                    
                case Constants.ALL:
                    sermons.all = newValue
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    var sermonsNeed = SermonsNeed()
    
    var display = Display()
    
    func clearDisplay()
    {
        display.sermons = nil
        display.sectionTitles = nil
        display.sectionIndexes = nil
        display.sectionCounts = nil
    }
    
    func setupDisplay()
    {
        display.sermons = active?.sermons
        
        display.sectionTitles = active?.sectionTitles
        display.sectionIndexes = active?.sectionIndexes
        display.sectionCounts = active?.sectionCounts
    }
    
    func saveSettingsBackground()
    {
        if allowSaveSettings {
            print("saveSettingsBackground")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
            let defaults = NSUserDefaults.standardUserDefaults()
            //    print("\(settings)")
            defaults.setObject(settings,forKey: Constants.SETTINGS_KEY)
            //    print("\(seriesViewSplits)")
            defaults.setObject(viewSplits, forKey: Constants.VIEW_SPLITS_KEY)
            defaults.synchronize()
        }
    }
    
    func loadSettings()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let settingsVersion = defaults.stringForKey(Constants.SETTINGS_VERSION_KEY) {
            if settingsVersion == Constants.SETTINGS_VERSION {
                if let settingsDictionary = defaults.dictionaryForKey(Constants.SETTINGS_KEY) {
                    //        print("\(settingsDictionary)")
                    settings = settingsDictionary as? [String:[String:String]]
                }
                
                if let viewSplitsDictionary = defaults.dictionaryForKey(Constants.VIEW_SPLITS_KEY) {
                    //        print("\(viewSplitsDictionary)")
                    viewSplits = viewSplitsDictionary as? [String:String]
                }

                if let sortingString = defaults.stringForKey(Constants.SORTING) {
                    sorting = sortingString
                } else {
                    sorting = Constants.REVERSE_CHRONOLOGICAL
                }
                
                if let groupingString = defaults.stringForKey(Constants.GROUPING) {
                    grouping = groupingString
                } else {
                    grouping = Constants.YEAR
                }
                
                sermonTagsSelected = defaults.stringForKey(Constants.COLLECTION)
                
                if (sermonTagsSelected == Constants.New) {
                    sermonTagsSelected = nil
                }
                
                if (sermonTagsSelected != nil) {
                    switch sermonTagsSelected! {
                    case Constants.All:
                        sermonTagsSelected = nil
                        showing = Constants.ALL
                        break
                        
                    default:
                        showing = Constants.TAGGED
                        break
                    }
                } else {
                    showing = Constants.ALL
                }

                searchText = defaults.stringForKey(Constants.SEARCH_TEXT)
                globals.searchActive = searchText != nil

                var indexOfSermon:Int?
                
                if let dict = defaults.dictionaryForKey(Constants.SERMON_PLAYING) {
                    indexOfSermon = sermonRepository.list?.indexOf({ (sermon:Sermon) -> Bool in
                        return (sermon.title == (dict[Constants.TITLE] as! String)) &&
                            (sermon.date == (dict[Constants.DATE] as! String)) &&
                            (sermon.service == (dict[Constants.SERVICE] as! String)) &&
                            (sermon.speaker == (dict[Constants.SPEAKER] as! String))
                    })
                }
                
                if (indexOfSermon != nil) {
                    player.playing = sermonRepository.list?[indexOfSermon!]
                }
                
                if let historyArray = defaults.arrayForKey(Constants.HISTORY) {
                    //        print("\(settingsDictionary)")
                    history = historyArray as? [String]
                }
            } else {
                //This is where we should map the old version on to the new one and preserve the user's information.
                defaults.setObject(Constants.SETTINGS_VERSION, forKey: Constants.SETTINGS_VERSION_KEY)
                defaults.synchronize()
            }
        } else {
            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
            defaults.setObject(Constants.SETTINGS_VERSION, forKey: Constants.SETTINGS_VERSION_KEY)
            defaults.synchronize()
        }
        
        if settings == nil {
            settings = [String:[String:String]]()
        }
        
        if viewSplits == nil {
            viewSplits = [String:String]()
        }
        
        //    print("\(settings)")
    }
    
    func cancelAllDownloads()
    {
        if (sermonRepository.list != nil) {
            for sermon in sermonRepository.list! {
                for download in sermon.downloads.values {
                    if download.active {
                        download.task?.cancel()
                        download.task = nil
                        
                        download.totalBytesWritten = 0
                        download.totalBytesExpectedToWrite = 0
                        
                        download.state = .none
                    }
                }
            }
        }
    }
    
    func updateCurrentTimeWhilePlaying()
    {
        assert(player.mpPlayer != nil,"player.mpPlayer should not be nil if we're trying to update the currentTime in userDefaults")
        
        var timeNow:Float = 0.0
        
        if (player.mpPlayer != nil) {
            if (player.mpPlayer?.playbackState == .Playing) {
                if (player.mpPlayer!.currentPlaybackTime > 0) && (player.mpPlayer!.currentPlaybackTime <= player.mpPlayer!.duration) {
                    timeNow = Float(player.mpPlayer!.currentPlaybackTime)
                }
            }
        }
        
        if ((timeNow > 0) && (Int(timeNow) % 10) == 0) {
            if Int(Float(player.playing!.currentTime!)!) != Int(player.mpPlayer!.currentPlaybackTime) {
                player.playing?.currentTime = player.mpPlayer!.currentPlaybackTime.description
            }
        }
    }
    
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
    
    func setupPlayer(sermon:Sermon?)
    {
        if (sermon != nil) {
            player.loaded = false
            player.loadFailed = false
            
            player.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
            
            player.mpPlayer?.shouldAutoplay = false
            player.mpPlayer?.controlStyle = MPMovieControlStyle.None
            player.mpPlayer?.prepareToPlay()
            
            player.stateTime = nil
            
            player.paused = true
        }
    }
    
    func setupPlayerAtEnd(sermon:Sermon?)
    {
        setupPlayer(sermon)
        
        if (player.mpPlayer != nil) {
            player.mpPlayer?.currentPlaybackTime = player.mpPlayer!.duration
            player.mpPlayer?.pause()
            sermon?.currentTime = Float(player.mpPlayer!.duration).description
        }
    }
    
    func updateCurrentTimeExact()
    {
        if (player.mpPlayer?.contentURL != nil) && (player.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            updateCurrentTimeExact(player.mpPlayer!.currentPlaybackTime)
        }
    }
    
    func updateCurrentTimeExact(seekToTime:NSTimeInterval)
    {
        if (seekToTime == 0) {
            print("seekToTime == 0")
        }
        
        //    print(seekToTime)
        //    print(seekToTime.description)
        
        if (seekToTime >= 0) {
            player.playing?.currentTime = seekToTime.description
        }
    }
    
    func setupLivePlayingInfoCenter()
    {
        var sermonInfo = [String:AnyObject]()
        
        sermonInfo.updateValue("Live Broadcast",forKey: MPMediaItemPropertyTitle)
        
        sermonInfo.updateValue("Countryside Bible Church",forKey: MPMediaItemPropertyArtist)
        
        sermonInfo.updateValue("Live Broadcast",forKey: MPMediaItemPropertyAlbumTitle)
        
        sermonInfo.updateValue("Countryside Bible Church",forKey: MPMediaItemPropertyAlbumArtist)
        
        sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:Constants.COVER_ART_IMAGE)!),forKey: MPMediaItemPropertyArtwork)
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
    }
    
    func setupPlayingInfoCenter()
    {
        if player.mpPlayer?.contentURL != NSURL(string: Constants.LIVE_STREAM_URL) {
            if (player.playing != nil) {
                var sermonInfo = [String:AnyObject]()
                
                sermonInfo.updateValue(player.playing!.title!,                                               forKey: MPMediaItemPropertyTitle)
                
                if (player.playing!.speaker != nil) {
                    sermonInfo.updateValue(player.playing!.speaker!,                                             forKey: MPMediaItemPropertyArtist)
                }
                
                sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:Constants.COVER_ART_IMAGE)!),                   forKey: MPMediaItemPropertyArtwork)
                
                if (player.playing!.hasSeries()) {
                    sermonInfo.updateValue(player.playing!.series!,                                          forKey: MPMediaItemPropertyAlbumTitle)
                    
                    if (player.playing!.speaker != nil) {
                        sermonInfo.updateValue(player.playing!.speaker!,                                         forKey: MPMediaItemPropertyAlbumArtist)
                    }
                    
                    if let sermonsInSeries = sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                        return (sermon.hasSeries()) && (sermon.series == player.playing!.series)
                    }).sort({ $0.title < $1.title }) {
                        //                print("\(sermonsInSeries.indexOf(player.playing!))")
                        //                print("\(player.playing!)")
                        //                print("\(sermonsInSeries)")
                        sermonInfo.updateValue(sermonsInSeries.indexOf(player.playing!)!,                        forKey: MPMediaItemPropertyAlbumTrackNumber)
                        sermonInfo.updateValue(sermonsInSeries.count,                                                   forKey: MPMediaItemPropertyAlbumTrackCount)
                    }
                }
                
                if (player.mpPlayer != nil) {
                    sermonInfo.updateValue(NSNumber(double: player.mpPlayer!.duration),                                forKey: MPMediaItemPropertyPlaybackDuration)
                    sermonInfo.updateValue(NSNumber(double: player.mpPlayer!.currentPlaybackTime),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
                    
                    sermonInfo.updateValue(NSNumber(float:player.mpPlayer!.currentPlaybackRate),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
                }
                
                //    print("\(sermonInfo.count)")
                
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = sermonInfo
            }
        }
    }
    
    func addToHistory(sermon:Sermon?)
    {
        if (sermon != nil) {
            let entry = "\(NSDate())" + Constants.TAGS_SEPARATOR + "\(sermon!.id)"
            
            if history == nil {
                history = [entry]
            } else {
                history?.append(entry)
            }
            
            //        print(history)
            
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(history, forKey: Constants.HISTORY)
            defaults.synchronize()
        } else {
            print("Sermon NIL!")
        }
    }
    
    func totalCacheSize() -> Int64
    {
        return cacheSize(Constants.AUDIO) + cacheSize(Constants.VIDEO) + cacheSize(Constants.NOTES) + cacheSize(Constants.SLIDES)
    }
    
    func cacheSize(purpose:String) -> Int64
    {
        var totalFileSize:Int64 = 0
        
        for sermon in sermonRepository.list! {
            if let download = sermon.download(purpose) {
                if download.isDownloaded() {
                    totalFileSize += download.fileSize
                }
            }
        }
        
        return totalFileSize
    }
    
    func mpPlayerLoadStateDidChange()
    {
        if (player.mpPlayer?.contentURL != NSURL(string: Constants.LIVE_STREAM_URL)) {
            //            print("mpPlayerLoadStateDidChange")
            
            let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
            
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
                if !player.loaded {
                    print("mpPlayerLoadStateDidChange with sermonPlaying NOT LOADED and playable || playthrough!")
                    
                    if (player.playing != nil) && player.playing!.hasCurrentTime() {
                        if (Int(Float(player.playing!.currentTime!)!) == Int(Float(player.mpPlayer!.duration))) { // !loadingFromLive &&
                            print("mpPlayerLoadStateDidChange player.playing!.currentTime reset to 0!")
                            player.playing!.currentTime = Constants.ZERO
                        } else {
                            
                            //                            print(player.playing!.currentTime!)
                            //                            print(Float(player.playing!.currentTime!)!)
                            
                            player.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(player.playing!.currentTime!)!)
                        }
                    } else {
                        print("mpPlayerLoadStateDidChange selectedSermon has NO currentTime!")
                        player.playing?.currentTime = Constants.ZERO
                        player.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                    }
                    
                    player.loaded = true
                    
                    if (player.playOnLoad) {
                        player.paused = false
                        player.mpPlayer?.play()
                    }
                    
                    setupPlayingInfoCenter()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
                } else {
                    print("mpPlayerLoadStateDidChange with sermonPlaying LOADED and playable || playthrough!")
                }
            }
            
            if !(playable || playthrough) && (player.stateTime?.state == .playing) && (player.stateTime?.timeElapsed > Constants.MIN_PLAY_TIME) {
                //                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough NOT OK")
                player.paused = true
                player.mpPlayer?.pause()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                })
            }
            
            //            switch player.mpPlayer!.playbackState {
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
        let playerEnabled = (player.mpPlayer != nil) && (player.mpPlayer?.contentURL != NSURL(string: Constants.LIVE_STREAM_URL))
        
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = playerEnabled
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = playerEnabled
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = playerEnabled
        
        if playerEnabled {
            let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
            //            if playable && debug {
            //                print("playTimer.MPMovieLoadState.Playable")
            //            }
            //
            //            if playthrough && debug {
            //                print("playTimer.MPMovieLoadState.Playthrough")
            //            }
            
            if (player.mpPlayer!.fullscreen) {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
            } else {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.None
            }
            
            if (player.mpPlayer?.currentPlaybackRate > 0) {
                updateCurrentTimeWhilePlaying()
            }
            
//            player.logPlayerState()
//            player.logMPPlayerState()
            
            switch player.stateTime!.state {
            case .none:
                break
                
            case .playing:
                switch player.mpPlayer!.playbackState {
                case .SeekingBackward:
                    player.stateTime!.state = .seekingBackward
                    break
                    
                case .SeekingForward:
                    player.stateTime!.state = .seekingForward
                    break
                    
                case .Paused:
                    updateCurrentTimeExact()
                    player.paused = true
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
//                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
//                    } else {
//                        player.mpPlayer?.play()
//                    }
                    break
                    
                default:
                    if !(playable || playthrough) { // player.mpPlayer?.currentPlaybackRate == 0
//                        print("playTimer.Playthrough or Playing NOT OK")
                        if (player.stateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
                            //                            sermonLoaded = false
                            player.paused = true
                            player.mpPlayer?.pause()
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                            
                            let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        } else {
                            // Wait so the player can keep trying.
                        }
                    } else {
//                        print("playTimer.Playthrough or Playing OK")
                        if (player.mpPlayer!.duration > 0) && (player.mpPlayer!.currentPlaybackTime > 0) &&
                            (Int(Float(player.mpPlayer!.currentPlaybackTime)) == Int(Float(player.mpPlayer!.duration))) {
                            player.mpPlayer?.pause()
                            player.paused = true
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                            })
                            
                            if (player.playing?.currentTime != player.mpPlayer!.duration.description) {
                                player.playing?.currentTime = player.mpPlayer!.duration.description
                            }
//                        } else {
//                            player.mpPlayer?.play()
                        }
                    }
                    break
                }
                break
                
            case .paused:
                if !player.loaded && !player.loadFailed {
                    if (player.stateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
                        player.loadFailed = true
                        
                        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        }
                    }
                }
                
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    player.paused = false
                    break
                    
                case .Paused:
                    break
                    
                default:
                    player.mpPlayer?.pause()
                    break
                }
                break
                
            case .stopped:
                break
                
            case .seekingForward:
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    player.stateTime!.state = .playing
                    break
                    
                case .Paused:
                    player.stateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
                
            case .seekingBackward:
                switch player.mpPlayer!.playbackState {
                case .Playing:
                    player.stateTime!.state = .playing
                    break
                    
                case .Paused:
                    player.stateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
            }
            
//            if (player.mpPlayer != nil) {
//                switch player.mpPlayer!.playbackState {
//                case .Interrupted:
//                    print("playTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    print("playTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    print("playTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    print("playTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    print("playTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    print("playTimer.Stopped")
//                    break
//                }
//            }
        }
    }
    
    func motionEnded(motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .MotionShake) {
            if (player.playing != nil) {
                if (player.paused) {
                    player.mpPlayer?.play()
                } else {
                    player.mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                player.paused = !player.paused
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                })
            }
        }
    }
    
    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.pause()
                    self.player.paused = true
                    self.updateCurrentTimeExact()
                    self.setupPlayingInfoCenter()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
                } else {
                    // Shouldn't be able to happen.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().stopCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlStop")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.updateCurrentTimeExact()
                }
                
                self.player.mpPlayer?.stop()
                self.player.paused = true
                
                self.setupPlayingInfoCenter()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                })
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPlay")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.play()
                    self.player.paused = false
                    
                    self.setupPlayingInfoCenter()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().togglePlayPauseCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    if (self.player.paused) {
                        self.player.mpPlayer?.play()
                    } else {
                        self.player.mpPlayer?.pause()
                        self.updateCurrentTimeExact()
                    }
                    self.player.paused = !self.player.paused
                    self.setupPlayingInfoCenter()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.player.mpPlayer?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.player.mpPlayer?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipBackward")
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime -= NSTimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.enabled = true
        MPRemoteCommandCenter.sharedCommandCenter().skipForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipForward")
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime += NSTimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        
        MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().changePlaybackRateCommand.enabled = false
        
        MPRemoteCommandCenter.sharedCommandCenter().ratingCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().likeCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().dislikeCommand.enabled = false
        MPRemoteCommandCenter.sharedCommandCenter().bookmarkCommand.enabled = false
    }
}

