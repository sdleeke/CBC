//
//  Globals.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

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
                dateEntered = Date()
            }
        }
    }
    
    var dateEntered:Date?
    var timeElapsed:TimeInterval {
        get {
            return Date().timeIntervalSince(dateEntered!)
        }
    }
    
    init()
    {
        dateEntered = Date()
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
            NSLog(stateName!)
        }
    }
}

class Player {
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
    
    var observer: Timer?
    
    var playing:Sermon? {
        didSet {
            if playing == nil {
                mpPlayer = nil
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            }
            
            let defaults = UserDefaults.standard
            if playing != nil {
                defaults.set(playing?.dict, forKey: Constants.SERMON_PLAYING)
            } else {
                defaults.removeObject(forKey: Constants.SERMON_PLAYING)
            }
            defaults.synchronize()
        }
    }
    
    func logMPPlayerState()
    {
        if (mpPlayer != nil) {
            var stateName:String?
            
            switch mpPlayer!.playbackState {
            case .interrupted:
                stateName = "Interrupted"
                break

            case .paused:
                stateName = "Paused"
                break
                
            case .playing:
                stateName = "Playing"
                break
                
            case .seekingForward:
                stateName = "SeekingForward"
                break
                
            case .seekingBackward:
                stateName = "SeekingBackward"
                break
                
            case .stopped:
                stateName = "Stopped"
                break
            }
            
            if (stateName != nil) {
                NSLog(stateName!)
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
                        NSLog("DUPLICATE SERMON ID: \(sermon)")
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

struct Tags {
    var showing:String? = Constants.ALL
    
    var selected:String? {
        didSet {
            if (selected != nil) {
                if (selected != oldValue) || (globals.sermons.tagged == nil) {
                    if globals.sermons.all == nil {
                        //This is filtering, i.e. searching all sermons => s/b in background
                        globals.sermons.tagged = SermonsListGroupSort(sermons: sermonsWithTag(globals.sermonRepository.list, tag: selected))
                    } else {
                        globals.sermons.tagged = SermonsListGroupSort(sermons: globals.sermons.all?.tagSermons?[stringWithoutPrefixes(selected!)!])
                    }
                }
            } else {
                globals.sermons.tagged = nil
            }

            if (selected != oldValue) {
                globals.sermonRepository.scriptureIndex = nil
            }

            let defaults = UserDefaults.standard
            if selected != nil {
                defaults.set(selected, forKey: Constants.COLLECTION)
            } else {
                defaults.removeObject(forKey: Constants.COLLECTION)
            }
            defaults.synchronize()
        }
    }
}

var globals:Globals!

class Globals {
    var finished = 0
    var progress = 0
    
    var loadSingles = true
    
    var allowSaveSettings = true

    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
    var scrolledToSermonLastSelected = false
    
    var grouping:String? = Grouping.YEAR {
        didSet {
            sermonsNeed.grouping = (grouping != oldValue)
            
            let defaults = UserDefaults.standard
            if (grouping != nil) {
                defaults.set(grouping,forKey: Constants.GROUPING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.GROUPING)
            }
            defaults.synchronize()
        }
    }
    
    var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            sermonsNeed.sorting = (sorting != oldValue)
            
            let defaults = UserDefaults.standard
            if (sorting != nil) {
                defaults.set(sorting,forKey: Constants.SORTING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    var autoAdvance:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool {
        get {
//            print(UserDefaults.standard.object(forKey: Constants.CACHE_DOWNLOADS))
            
            if UserDefaults.standard.object(forKey: Constants.CACHE_DOWNLOADS) == nil {
                if #available(iOS 9.0, *) {
                    UserDefaults.standard.set(true, forKey: Constants.CACHE_DOWNLOADS)
                } else {
                    UserDefaults.standard.set(false, forKey: Constants.CACHE_DOWNLOADS)
                }
            }
            
            return UserDefaults.standard.bool(forKey: Constants.CACHE_DOWNLOADS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.CACHE_DOWNLOADS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var refreshing:Bool = false
    var loading:Bool = false
    
    var searchActive:Bool = false
    var searchText:String? {
        didSet {
            if (searchText != oldValue) {
                globals.sermonRepository.scriptureIndex = nil
                
                if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
                    UserDefaults.standard.set(searchText, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    sermons.search = nil
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    var gotoPlayingPaused:Bool = false
    var showingAbout:Bool = false

    var player = Player()
    
    var selectedSermon:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = UserDefaults.standard
            if let selectedSermonID = defaults.string(forKey: Constants.SELECTED_SERMON_KEY) {
                selectedSermon = sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    var selectedSermonDetail:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = UserDefaults.standard
            if let selectedSermonID = defaults.string(forKey: Constants.SELECTED_SERMON_DETAIL_KEY) {
                selectedSermon = sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    var sermonCategoryDicts:[String:String]?
    
    var sermonCategories:[String]? {
        get {
            return sermonCategoryDicts?.keys.map({ (key:String) -> String in
                return key
            }).sorted()
        }
    }

    var sermonCategory:String? {
        get {
            //            print(UserDefaults.standard.object(forKey: Constants.CACHE_DOWNLOADS))
            
            if UserDefaults.standard.object(forKey: Constants.MEDIA_CATEGORY) == nil {
                UserDefaults.standard.set("Sermons", forKey: Constants.MEDIA_CATEGORY)
            }
            
            return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
            UserDefaults.standard.synchronize()
        }
    }
    
    var sermonCategoryID:String? {
        get {
            return globals.sermonCategoryDicts?[globals.sermonCategory!]
        }
    }
    
    // These are hidden behind custom accessors in Sermon
    var viewSplits:[String:String]?
    var settings:[String:[String:String]]?
    
    var history:[String]?

    var sermonRepository = SermonRepository()
    
    var sermons = Sermons()
    
    var tags = Tags()
    
    var sermonsToSearch:[Sermon]? {
        get {
            var sermons:[Sermon]?
            
            switch tags.showing! {
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
                
                switch tags.showing! {
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
                switch tags.showing! {
                case Constants.TAGGED:
//                    sermons.tagged = newValue
                    NSLog("ERROR: setting active while TAGGED.")
                    break
                    
                case Constants.ALL:
                    sermons.all = newValue
                    globals.sermonRepository.scriptureIndex = nil
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
            NSLog("saveSettingsBackground")
            
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            NSLog("saveSettings")
            let defaults = UserDefaults.standard
            //    NSLog("\(settings)")
            defaults.set(settings,forKey: Constants.SETTINGS_KEY)
            //    NSLog("\(seriesViewSplits)")
            defaults.set(viewSplits, forKey: Constants.VIEW_SPLITS_KEY)
            defaults.synchronize()
        }
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
        //    NSLog("\(settings)")
        defaults.removeObject(forKey: Constants.SETTINGS_KEY)
        defaults.removeObject(forKey: Constants.VIEW_SPLITS_KEY)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        if let settingsVersion = defaults.string(forKey: Constants.SETTINGS_VERSION_KEY) {
            if settingsVersion == Constants.SETTINGS_VERSION {
                if let settingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS_KEY) {
                    //        NSLog("\(settingsDictionary)")
                    settings = settingsDictionary as? [String:[String:String]]
                }
                
                if let viewSplitsDictionary = defaults.dictionary(forKey: Constants.VIEW_SPLITS_KEY) {
                    //        NSLog("\(viewSplitsDictionary)")
                    viewSplits = viewSplitsDictionary as? [String:String]
                }

                if let sortingString = defaults.string(forKey: Constants.SORTING) {
                    sorting = sortingString
                } else {
                    sorting = Constants.REVERSE_CHRONOLOGICAL
                }
                
                if let groupingString = defaults.string(forKey: Constants.GROUPING) {
                    grouping = groupingString
                } else {
                    grouping = Grouping.YEAR
                }
                
                tags.selected = defaults.string(forKey: Constants.COLLECTION)
                
                if (tags.selected == Constants.New) {
                    tags.selected = nil
                }
                
                if (tags.selected != nil) {
                    switch tags.selected! {
                    case Constants.All:
                        tags.selected = nil
                        tags.showing = Constants.ALL
                        break
                        
                    default:
                        tags.showing = Constants.TAGGED
                        break
                    }
                } else {
                    tags.showing = Constants.ALL
                }

                searchText = defaults.string(forKey: Constants.SEARCH_TEXT)
                globals.searchActive = searchText != nil

                var indexOfSermon:Int?
                
                if let dict = defaults.dictionary(forKey: Constants.SERMON_PLAYING) as? [String:String] {
//                    print(dict)
                    indexOfSermon = sermonRepository.list?.index(where: { (sermon:Sermon) -> Bool in
//                        print(sermon.title,Sermon(dict: dict).title)
//                        print(sermon.date,Sermon(dict: dict).date)
//                        print(sermon.service,Sermon(dict: dict).service)
//                        print(sermon.speaker,Sermon(dict: dict).speaker)
                        return (sermon.title == Sermon(dict: dict).title) &&
                            (sermon.date == Sermon(dict: dict).date) &&
                            (sermon.service == Sermon(dict: dict).service) &&
                            (sermon.speaker == Sermon(dict: dict).speaker)
                    })
                }
                
                if (indexOfSermon != nil) {
                    player.playing = sermonRepository.list?[indexOfSermon!]
                }
                
                if let historyArray = defaults.array(forKey: Constants.HISTORY) {
                    //        NSLog("\(settingsDictionary)")
                    history = historyArray as? [String]
                }
            } else {
                //This is where we should map the old version on to the new one and preserve the user's information.
                defaults.set(Constants.SETTINGS_VERSION, forKey: Constants.SETTINGS_VERSION_KEY)
                defaults.synchronize()
            }
        } else {
            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
            globals.clearSettings()
            defaults.set(Constants.SETTINGS_VERSION, forKey: Constants.SETTINGS_VERSION_KEY)
            defaults.synchronize()
        }
        
        if settings == nil {
            settings = [String:[String:String]]()
        }
        
        if viewSplits == nil {
            viewSplits = [String:String]()
        }
        
        //    NSLog("\(settings)")
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
            if (player.mpPlayer?.playbackState == .playing) {
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
    
    func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                                          message: message,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            //        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func setupPlayer(_ sermon:Sermon?)
    {
        if (sermon != nil) {
            player.loaded = false
            player.loadFailed = false
            
            player.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL as URL!)
            
            player.mpPlayer?.shouldAutoplay = false
            player.mpPlayer?.controlStyle = MPMovieControlStyle.none
            player.mpPlayer?.prepareToPlay()
            
            player.stateTime = nil
            
            player.paused = true
        }
    }
    
    func setupPlayerAtEnd(_ sermon:Sermon?)
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
        if (player.mpPlayer?.contentURL != nil) && (player.mpPlayer?.contentURL != URL(string:Constants.LIVE_STREAM_URL)) {
            updateCurrentTimeExact(player.mpPlayer!.currentPlaybackTime)
        }
    }
    
    func updateCurrentTimeExact(_ seekToTime:TimeInterval)
    {
        if (seekToTime == 0) {
            NSLog("seekToTime == 0")
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
        
        sermonInfo.updateValue("Live Broadcast" as AnyObject,forKey: MPMediaItemPropertyTitle)
        
        sermonInfo.updateValue("Countryside Bible Church" as AnyObject,forKey: MPMediaItemPropertyArtist)
        
        sermonInfo.updateValue("Live Broadcast" as AnyObject,forKey: MPMediaItemPropertyAlbumTitle)
        
        sermonInfo.updateValue("Countryside Bible Church" as AnyObject,forKey: MPMediaItemPropertyAlbumArtist)
        
        sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:Constants.COVER_ART_IMAGE)!),forKey: MPMediaItemPropertyArtwork)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = sermonInfo
    }
    
    func setupPlayingInfoCenter()
    {
        if player.mpPlayer?.contentURL != URL(string: Constants.LIVE_STREAM_URL) {
            if (player.playing != nil) {
                var sermonInfo = [String:AnyObject]()
                
                sermonInfo.updateValue(player.playing!.title! as AnyObject,                                               forKey: MPMediaItemPropertyTitle)
                
                if (player.playing!.speaker != nil) {
                    sermonInfo.updateValue(player.playing!.speaker! as AnyObject,                                             forKey: MPMediaItemPropertyArtist)
                }
                
                sermonInfo.updateValue(MPMediaItemArtwork(image: UIImage(named:Constants.COVER_ART_IMAGE)!),                   forKey: MPMediaItemPropertyArtwork)
                
                if (player.playing!.hasSeries) {
                    sermonInfo.updateValue(player.playing!.series! as AnyObject,                                          forKey: MPMediaItemPropertyAlbumTitle)
                    
                    if (player.playing!.speaker != nil) {
                        sermonInfo.updateValue(player.playing!.speaker! as AnyObject,                                         forKey: MPMediaItemPropertyAlbumArtist)
                    }
                    
                    if let sermonsInSeries = sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                        return (sermon.hasSeries) && (sermon.series == player.playing!.series)
                    }).sorted(by: { $0.title < $1.title }) {
                        //                NSLog("\(sermonsInSeries.indexOf(player.playing!))")
                        //                NSLog("\(player.playing!)")
                        //                NSLog("\(sermonsInSeries)")
                        if sermonsInSeries.index(of: player.playing!) != nil {
                            sermonInfo.updateValue(sermonsInSeries.index(of: player.playing!)! as AnyObject,                forKey: MPMediaItemPropertyAlbumTrackNumber)
                        }

                        sermonInfo.updateValue(sermonsInSeries.count as AnyObject,                                          forKey: MPMediaItemPropertyAlbumTrackCount)
                    }
                }
                
                if (player.mpPlayer != nil) {
                    sermonInfo.updateValue(NSNumber(value: player.mpPlayer!.duration as Double),                                forKey: MPMediaItemPropertyPlaybackDuration)
                    sermonInfo.updateValue(NSNumber(value: player.mpPlayer!.currentPlaybackTime as Double),                     forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
                    
                    sermonInfo.updateValue(NSNumber(value: player.mpPlayer!.currentPlaybackRate as Float),                       forKey: MPNowPlayingInfoPropertyPlaybackRate)
                }
                
                //    NSLog("\(sermonInfo.count)")
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = sermonInfo
            }
        }
    }
    
    func addToHistory(_ sermon:Sermon?)
    {
        if (sermon != nil) {
            let entry = "\(Date())" + Constants.TAGS_SEPARATOR + sermon!.id!
            
            if history == nil {
                history = [entry]
            } else {
                history?.append(entry)
            }
            
            //        print(history)
            
            let defaults = UserDefaults.standard
            defaults.set(history, forKey: Constants.HISTORY)
            defaults.synchronize()
        } else {
            NSLog("Sermon NIL!")
        }
    }
    
    func totalCacheSize() -> Int64
    {
        return cacheSize(Purpose.audio) + cacheSize(Purpose.video) + cacheSize(Purpose.notes) + cacheSize(Purpose.slides)
    }
    
    func cacheSize(_ purpose:String) -> Int64
    {
        var totalFileSize:Int64 = 0
        
        for sermon in sermonRepository.list! {
            if let download = sermon.downloads[purpose] {
                if download.isDownloaded() {
                    totalFileSize += download.fileSize
                }
            }
        }
        
        return totalFileSize
    }
    
    func mpPlayerLoadStateDidChange()
    {
        if (player.mpPlayer?.contentURL != URL(string: Constants.LIVE_STREAM_URL)) {
            //            NSLog("mpPlayerLoadStateDidChange")
            
            let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.playthroughOK.rawValue)) > 0
            
            //            if playable {
            //                NSLog("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable")
            //            }
            //
            //            if playthrough {
            //                NSLog("mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough")
            //            }
            
            //        NSLog("\(loadstate)")
            //        NSLog("\(playable)")
            //        NSLog("\(playthrough)")
            
            if (playable || playthrough) {
                //                NSLog("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough OK")
                if !player.loaded {
                    NSLog("mpPlayerLoadStateDidChange with sermonPlaying NOT LOADED and playable || playthrough!")
                    
                    if (player.playOnLoad) {
                        if (player.playing != nil) && player.playing!.hasCurrentTime() {
                            if (Int(Float(player.playing!.currentTime!)!) == Int(Float(player.mpPlayer!.duration))) { // !loadingFromLive &&
                                NSLog("mpPlayerLoadStateDidChange player.playing!.currentTime reset to 0!")
//                                print(player.mpPlayer!.duration)
//                                print(player.playing!.currentTime!)
                                player.playing!.currentTime = Constants.ZERO
                            } else {
    //                            print(player.playing!.currentTime!)
    //                            print(Float(player.playing!.currentTime!)!)
    
                                NSLog("mpPlayerLoadStateDidChange player.mpPlayer?.currentPlaybackTime = player.playing!.currentTime")
                                player.mpPlayer?.currentPlaybackTime = TimeInterval(Float(player.playing!.currentTime!)!)
                            }
                        } else {
                            NSLog("mpPlayerLoadStateDidChange selectedSermon has NO currentTime!")
                            player.playing?.currentTime = Constants.ZERO
                            player.mpPlayer?.currentPlaybackTime = TimeInterval(0)
                        }
                        player.paused = false
                        player.mpPlayer?.play()
                    } else {
                        if (player.playing != nil) && player.playing!.hasCurrentTime() {
                            player.mpPlayer?.currentPlaybackTime = TimeInterval(Float(player.playing!.currentTime!)!)
                        } else {
                            NSLog("mpPlayerLoadStateDidChange selectedSermon has NO currentTime!")
                            player.playing?.currentTime = Constants.ZERO
                            player.mpPlayer?.currentPlaybackTime = TimeInterval(0)
                        }
                    }
                    
                    player.loaded = true
                    
                    setupPlayingInfoCenter()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                    })
                } else {
                    NSLog("mpPlayerLoadStateDidChange with sermonPlaying LOADED and playable || playthrough!")
                }
            }
            
            if !(playable || playthrough) && (player.stateTime?.state == .playing) && (player.stateTime?.timeElapsed > Constants.MIN_PLAY_TIME) {
                //                NSLog("mpPlayerLoadStateDidChange.MPMovieLoadState.Playable or Playthrough NOT OK")
                player.paused = true
                player.mpPlayer?.pause()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                })
            }
            
            //            switch player.mpPlayer!.playbackState {
            //            case .Playing:
            //                NSLog("mpPlayerLoadStateDidChange.Playing")
            //                break
            //
            //            case .SeekingBackward:
            //                NSLog("mpPlayerLoadStateDidChange.SeekingBackward")
            //                break
            //
            //            case .SeekingForward:
            //                NSLog("mpPlayerLoadStateDidChange.SeekingForward")
            //                break
            //
            //            case .Stopped:
            //                NSLog("mpPlayerLoadStateDidChange.Stopped")
            //                break
            //
            //            case .Interrupted:
            //                NSLog("mpPlayerLoadStateDidChange.Interrupted")
            //                break
            //
            //            case .Paused:
            //                NSLog("mpPlayerLoadStateDidChange.Paused")
            //                break
            //            }
        }
    }
    
    func playerTimer()
    {
        let playerEnabled = (player.mpPlayer != nil) && (player.mpPlayer?.contentURL != URL(string: Constants.LIVE_STREAM_URL))
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = playerEnabled
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = playerEnabled
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = playerEnabled
        
        if playerEnabled {
            let loadstate:UInt8 = UInt8(player.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.playthroughOK.rawValue)) > 0
            
            //            if playable && debug {
            //                NSLog("playTimer.MPMovieLoadState.Playable")
            //            }
            //
            //            if playthrough && debug {
            //                NSLog("playTimer.MPMovieLoadState.Playthrough")
            //            }
            
            if (player.mpPlayer!.isFullscreen) {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.embedded // Fullscreen
            } else {
                player.mpPlayer?.controlStyle = MPMovieControlStyle.none
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
                case .seekingBackward:
                    player.stateTime!.state = .seekingBackward
                    break
                    
                case .seekingForward:
                    player.stateTime!.state = .seekingForward
                    break
                    
                case .paused:
                    updateCurrentTimeExact()
                    player.paused = true
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                    })
//                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
//                    } else {
//                        player.mpPlayer?.play()
//                    }
                    break
                    
                default:
                    if !(playable || playthrough) { // player.mpPlayer?.currentPlaybackRate == 0
//                        NSLog("playTimer.Playthrough or Playing NOT OK")
                        if (player.stateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
                            //                            sermonLoaded = false
                            player.paused = true
                            player.mpPlayer?.pause()
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                            })
                            
                            let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
                            errorAlert.show()
                        } else {
                            // Wait so the player can keep trying.
                        }
                    } else {
//                        NSLog("playTimer.Playthrough or Playing OK")
                        if (player.mpPlayer!.duration > 0) && (player.mpPlayer!.currentPlaybackTime > 0) &&
                            (Int(Float(player.mpPlayer!.currentPlaybackTime)) == Int(Float(player.mpPlayer!.duration))) {
                            player.mpPlayer?.pause()
                            player.paused = true
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
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
                        
//                        if (UIApplication.shared.applicationState == UIApplicationState.active) {
//                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
//                            errorAlert.show()
//                        }
                    }
                }
                
                switch player.mpPlayer!.playbackState {
                case .playing:
                    player.paused = false
                    break
                    
                case .paused:
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
                case .playing:
                    player.stateTime!.state = .playing
                    break
                    
                case .paused:
                    player.stateTime!.state = .playing
                    break
                    
                default:
                    break
                }
                break
                
            case .seekingBackward:
                switch player.mpPlayer!.playbackState {
                case .playing:
                    player.stateTime!.state = .playing
                    break
                    
                case .paused:
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
//                    NSLog("playTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    NSLog("playTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    NSLog("playTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    NSLog("playTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    NSLog("playTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    NSLog("playTimer.Stopped")
//                    break
//                }
//            }
        }
    }
    
    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .motionShake) {
            if (player.playing != nil) {
                if (player.paused) {
                    player.mpPlayer?.play()
                } else {
                    player.mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                player.paused = !player.paused
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                })
            }
        }
    }
    
    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlPause")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.pause()
                    self.player.paused = true
                    self.updateCurrentTimeExact()
                    self.setupPlayingInfoCenter()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                    })
                } else {
                    // Shouldn't be able to happen.
                }
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlStop")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.updateCurrentTimeExact()
                }
                
                self.player.mpPlayer?.stop()
                self.player.paused = true
                
                self.setupPlayingInfoCenter()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                })
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlPlay")
            if (self.player.playing != nil) {
                if self.player.loaded {
                    self.player.mpPlayer?.play()
                    self.player.paused = false
                    
                    self.setupPlayingInfoCenter()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlTogglePlayPause")
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
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)
                    })
                } else {
                    // Need to play new sermon which may take a new notification.
                }
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
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
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlSkipBackward")
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime -= TimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlSkipForward")
            if (self.player.playing != nil) && self.player.loaded {
                self.player.mpPlayer?.currentPlaybackTime += TimeInterval(15)
                self.updateCurrentTimeExact()
                self.setupPlayingInfoCenter()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().ratingCommand.isEnabled = false
        MPRemoteCommandCenter.shared().likeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().dislikeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = false
    }
}

