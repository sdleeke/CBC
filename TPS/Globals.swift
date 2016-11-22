//
//  Globals.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var mediaItem:MediaItem? {
        didSet {
            startTime = mediaItem?.currentTime
        }
    }
    
    var state:PlayerState = .none {
        didSet {
            if (state != oldValue) {
                dateEntered = Date()
            }
        }
    }
    
    var startTime:String?
    
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
    
    convenience init(_ mediaItem:MediaItem?)
    {
        self.init()
        self.mediaItem = mediaItem
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

class MediaPlayer {
    var sliderTimerReturn:Any? = nil
    var playerTimerReturn:Any? = nil
    
    var observerActive = false
//    var playerObserver:Timer?

    var url : URL? {
        get {
            return (currentItem?.asset as? AVURLAsset)?.url
        }
    }
    
    private var controller:AVPlayerViewController? = AVPlayerViewController()
    
    private var stateTime:PlayerStateTime?
    
    var showsPlaybackControls:Bool{
        get {
            return controller != nil ? controller!.showsPlaybackControls : false
        }
        set {
            controller?.showsPlaybackControls = newValue
        }
    }
    
    init()
    {
        controller?.showsPlaybackControls = false
        
        if #available(iOS 10.0, *) {
            controller?.updatesNowPlayingInfoCenter = false
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOS 9.0, *) {
            controller?.allowsPictureInPicturePlayback = true
        } else {
            // Fallback on earlier versions
        }
    }
    
//    func stopIfPlaying()
//    {
//        if isPlaying {
//            stop()
//        } else {
//            print("Player NOT playing.")
//        }
//    }
    
//    func pauseIfPlaying()
//    {
//        if isPlaying {
//            pause()
//        } else {
//            print("Player NOT playing.")
//        }
//    }
    
    func play()
    {
        if url != nil {
            switch url!.absoluteString {
            case Constants.URL.LIVE_STREAM:
                player?.play()
                break
                
            default:
                if loaded {
                    if (mediaItem != stateTime?.mediaItem) || (stateTime?.mediaItem == nil) {
                        stateTime = PlayerStateTime(mediaItem)
                    }
                    
                    stateTime?.startTime = mediaItem?.currentTime
                    
                    stateTime?.state = .playing
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    })
                    
                    player?.play()
                    
                    globals.setupPlayingInfoCenter()
                }
                break
            }
        }
    }
    
    func pause()
    {
        if url != nil {
            switch url!.absoluteString {
            case Constants.URL.LIVE_STREAM:
                player?.pause()
                break
                
            default:
                player?.pause()
                
                updateCurrentTimeExact()
                
                if (mediaItem != stateTime?.mediaItem) || (stateTime?.mediaItem == nil) {
                    stateTime = PlayerStateTime(mediaItem)
                }
                
                stateTime?.state = .paused
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                })
                
                globals.setupPlayingInfoCenter()
                break
            }
        }
    }
    
    func stop()
    {
        if url != nil {
            switch url!.absoluteString {
            case Constants.URL.LIVE_STREAM:
                player?.pause()
                break
                
            default:
                player?.pause()
                
                updateCurrentTimeExact()
         
                if (mediaItem != stateTime?.mediaItem) || (stateTime?.mediaItem == nil) {
                    stateTime = PlayerStateTime(mediaItem)
                }
                
                stateTime?.state = .stopped
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    
                    self.mediaItem = nil // This is unique to stop()
                })
                
                globals.setupPlayingInfoCenter()
                break
            }
        }
    }
    
    func updateCurrentTimeExactWhilePlaying()
    {
        if isPlaying {
            updateCurrentTimeExact()
        }
    }
    
    func updateCurrentTimeExact()
    {
        if (url != nil) && (url != URL(string:Constants.URL.LIVE_STREAM)) {
            if loaded && (currentTime != nil) {
                var time = currentTime!.seconds
                if time >= duration!.seconds {
                    time = duration!.seconds
                }
                if time < 0 {
                    time = 0
                }
                updateCurrentTimeExact(time)
            } else {
                print("Player NOT loaded or has no currentTime.")
            }
        } else {
            print("Player has no URL or is LIVE STREAM.")
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
            mediaItem?.currentTime = seekToTime.description
        } else {
            print("seekeToTime < 0")
        }
    }
    
    func seek(to: Double?)
    {
        if to != nil {
            if url != nil {
                switch url!.absoluteString {
                case Constants.URL.LIVE_STREAM:
                    break
                    
                default:
                    if loaded {
                        var seek = to!
                        
                        if seek > currentItem!.duration.seconds {
                            seek = currentItem!.duration.seconds
                        }
                        
                        if seek < 0 {
                            seek = 0
                        }

                        player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution))

                        mediaItem?.currentTime = seek.description
                        stateTime?.startTime = seek.description
                        
                        globals.setupPlayingInfoCenter()
                    }
                    break
                }
            }
        }
    }
    
    var currentTime:CMTime? {
        get {
            return player?.currentTime()
        }
    }
    
    var currentItem:AVPlayerItem? {
        get {
            return player?.currentItem
        }
    }
    
    var player:AVPlayer? {
        get {
            return controller?.player
        }
        set {
            globals.unobservePlayer()

            controller?.player = newValue
        }
    }
    
    var duration:CMTime? {
        get {
            return currentItem?.duration
        }
    }
    
    var state:PlayerState? {
        get {
            return stateTime?.state
        }
    }
    
    var startTime:String? {
        get {
            return stateTime?.startTime
        }
        set {
            stateTime?.startTime = newValue
        }
    }
    
    var rate:Float? {
        get {
            return player?.rate
        }
    }
    
    var view:UIView? {
        get {
            return controller?.view
        }
    }
    
    var isPlaying:Bool {
        get {
            return stateTime?.state == .playing
        }
    }
    
    var isPaused:Bool {
        get {
            return stateTime?.state == .paused
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    func unload()
    {
        loaded = false
        loadFailed = false
    }
    
    var observer: Timer?
    
    var mediaItem:MediaItem? {
        didSet {
            globals.mediaCategory.playing = mediaItem?.id
            
            if mediaItem == nil {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                player = nil
                stateTime = nil
            }
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
}

struct MediaNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

struct Display {
    var mediaItems:[MediaItem]?
    
    var sectionTitles:[String]?
    var sectionCounts:[Int]?
    var sectionIndexes:[Int]?
}

struct MediaRepository {
    var list:[MediaItem]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:MediaItem]()
                
                for mediaItem in list! {
                    if index![mediaItem.id!] == nil {
                        index![mediaItem.id!] = mediaItem
                    } else {
                        NSLog("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
            }
        }
    }

    var index:[String:MediaItem]?
}

struct Media {
    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems from a search, by search
//    var searches:[String:MediaListGroupSort]?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged:MediaListGroupSort?
}

struct Tags {
    var showing:String? = Constants.ALL
    
    var selected:String? {
        didSet {
            if (selected != nil) {
                if (selected != oldValue) || (globals.media.tagged == nil) {
                    if globals.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        globals.media.tagged = MediaListGroupSort(mediaItems: mediaItemsWithTag(globals.mediaRepository.list, tag: selected))
                    } else {
                        globals.media.tagged = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[stringWithoutPrefixes(selected!)!])
                    }
                }
            } else {
                globals.media.tagged = nil
            }

            let defaults = UserDefaults.standard
            if selected != nil {
                defaults.set(selected, forKey: Constants.SETTINGS.KEY.COLLECTION)
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.KEY.COLLECTION)
            }
            defaults.synchronize()
        }
    }
}

struct MediaCategory {
    var dicts:[String:String]?
    
    var names:[String]? {
        get {
            return dicts?.keys.map({ (key:String) -> String in
                return key
            }).sorted()
        }
    }
    
    // This doesn't work if we someday allow multiple categories to be selected at the same time - unless the string contains multiple categories, as with tags.
    // In that case it would need to be an array.  Not a big deal, just a change.
    var selected:String? {
        get {
            //            print(UserDefaults.standard.object(forKey: Constants.CACHE_DOWNLOADS))
            
            if UserDefaults.standard.object(forKey: Constants.MEDIA_CATEGORY) == nil {
                UserDefaults.standard.set(Constants.Sermons, forKey: Constants.MEDIA_CATEGORY)
            }
            
            return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
        }
        set {
            if selected != nil {
                UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.MEDIA_CATEGORY)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    var selectedID:String? {
        get {
            return dicts?[selected!]
        }
    }

    var settings:[String:[String:String]]?

    var allowSaveSettings = true
    
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
            defaults.set(settings, forKey: Constants.SETTINGS.KEY.CATEGORY)
            defaults.synchronize()
        }
    }
    
    subscript(key:String) -> String? {
        get {
            if (selected != nil) {
                return settings?[selected!]?[key]
            } else {
                return nil
            }
        }
        set {
            if (selected != nil) {
                if settings == nil {
                    settings = [String:[String:String]]()
                }
                if (settings != nil) {
                    if (settings?[selected!] == nil) {
                        settings?[selected!] = [String:String]()
                    }
                    if (settings?[selected!]?[key] != newValue) {
                        settings?[selected!]?[key] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        saveSettingsBackground()
                    }
                } else {
                    NSLog("settings == nil!")
                }
            } else {
                NSLog("selected == nil!")
            }
        }
    }
    
    var playing:String? {
        get {
            if selected != nil {
                return self[Constants.SETTINGS.MEDIA_PLAYING]
            } else {
                return nil
            }
        }
        set {
            self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
        }
    }

    var selectedInMaster:String? {
        get {
            if selected != nil {
                return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER]
            } else {
                return nil
            }
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String? {
        get {
            if selected != nil {
                return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL]
            } else {
                return nil
            }
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL] = newValue
        }
    }
}

struct SelectedMediaItem {
    var master:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
//            let defaults = UserDefaults.standard
//            if let selectedMediaItemID = defaults.string(forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER) {
//                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
//            }
            //            defaults.synchronize()

            if let selectedMediaItemID = globals.mediaCategory.selectedInMaster {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
    }
    
    var detail:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
//            let defaults = UserDefaults.standard
//            if let selectedMediaItemID = defaults.string(forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL) {
//                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
//            }
            //            defaults.synchronize()
            
            //            print(selectedMediaItem)

            if let selectedMediaItemID = globals.mediaCategory.selectedInDetail {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }

            return selectedMediaItem
        }
    }
}

var globals:Globals!

class Globals : NSObject {
    var finished = 0
    var progress = 0
    
    var loadSingles = true
    
    var allowSaveSettings = true
    
    let reachability = Reachability()!
    
//    func reachabilityChanged(note: NSNotification)
//    {
//        let reachability = note.object as! Reachability
//        
//        if reachability.isReachable {
//            if reachability.isReachableViaWiFi {
//                print("Reachable via WiFi")
//            } else {
//                print("Reachable via Cellular")
//            }
//        } else {
//            print("Network not reachable")
//        }
//    }

    override init()
    {
        super.init()
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async() {
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async() {
                print("Not reachable")
            }
        }
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
    var scrolledToMediaItemLastSelected = false
    
    var grouping:String? = Grouping.YEAR {
        didSet {
            mediaNeed.grouping = (grouping != oldValue)
            
            let defaults = UserDefaults.standard
            if (grouping != nil) {
                defaults.set(grouping,forKey: Constants.SETTINGS.KEY.GROUPING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.KEY.GROUPING)
            }
            defaults.synchronize()
        }
    }
    
    var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            mediaNeed.sorting = (sorting != oldValue)
            
            let defaults = UserDefaults.standard
            if (sorting != nil) {
                defaults.set(sorting,forKey: Constants.SETTINGS.KEY.SORTING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.KEY.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    var searchTranscripts:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            globals.search?.searches = nil
            
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var autoAdvance:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool {
        get {
//            print(UserDefaults.standard.object(forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS))

            if UserDefaults.standard.object(forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS) == nil {
                if #available(iOS 9.0, *) {
                    UserDefaults.standard.set(true, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
                } else {
                    UserDefaults.standard.set(false, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
                }
            }
            
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var searchComplete:Bool = true
    var searchActive:Bool = false
    var searchText:String? {
        didSet {
            if (searchText != oldValue) {
                if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
                    UserDefaults.standard.set(searchText, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    var gotoPlayingPaused:Bool = false
    var showingAbout:Bool = false

    var mediaPlayer = MediaPlayer()

    var selectedMediaItem = SelectedMediaItem()
    
    var mediaCategory = MediaCategory()
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    var multiPartSettings:[String:[String:String]]?
    var mediaItemSettings:[String:[String:String]]?
    
    var history:[String]?

    var mediaRepository = MediaRepository()
    
    var media = Media()
    
    var tags = Tags()
    
    var active:MediaListGroupSort? {
        get {
            var mediaItems:MediaListGroupSort?
            
            switch tags.showing! {
            case Constants.TAGGED:
                mediaItems = self.media.tagged
                break
                
            case Constants.ALL:
                mediaItems = self.media.all
                break
                
            default:
                break
            }
            
            if globals.searchActive {
                if (globals.searchText != nil) && (globals.searchText != Constants.EMPTY_STRING) {
                    mediaItems = mediaItems?.searches?[globals.searchText!]
                }
            }
            
            return mediaItems
        }
    }
    
    var search:MediaListGroupSort? {
        get {
            var mediaItems:MediaListGroupSort?
            
            switch tags.showing! {
            case Constants.TAGGED:
                mediaItems = self.media.tagged
                break
                
            case Constants.ALL:
                mediaItems = self.media.all
                break
                
            default:
                break
            }
            
            return mediaItems
        }
    }
    
    var mediaNeed = MediaNeed()
    
    var display = Display()
    
    func clearDisplay()
    {
        display.mediaItems = nil

        display.sectionTitles = nil
        display.sectionIndexes = nil
        display.sectionCounts = nil
    }
    
    func setupDisplay()
    {
//        print("setupDisplay")

        display.mediaItems = active?.mediaItems
        
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
            defaults.set(mediaItemSettings,forKey: Constants.SETTINGS.KEY.MEDIA)
            //    NSLog("\(seriesViewSplits)")
            defaults.set(multiPartSettings, forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
            defaults.synchronize()
        }
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
        //    NSLog("\(settings)")
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.CATEGORY)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        if let settingsVersion = defaults.string(forKey: Constants.SETTINGS.VERSION.KEY) {
            if settingsVersion == Constants.SETTINGS.VERSION.NUMBER {
                if let mediaItemSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MEDIA) {
                    //        NSLog("\(settingsDictionary)")
                    mediaItemSettings = mediaItemSettingsDictionary as? [String:[String:String]]
                }
                
                if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA) {
                    //        NSLog("\(viewSplitsDictionary)")
                    multiPartSettings = seriesSettingsDictionary as? [String:[String:String]]
                }
                
                if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.CATEGORY) {
                    //        NSLog("\(viewSplitsDictionary)")
                    mediaCategory.settings = categorySettingsDictionary as? [String:[String:String]]
                }
                
                if let sortingString = defaults.string(forKey: Constants.SETTINGS.KEY.SORTING) {
                    sorting = sortingString
                } else {
                    sorting = Constants.REVERSE_CHRONOLOGICAL
                }
                
                if let groupingString = defaults.string(forKey: Constants.SETTINGS.KEY.GROUPING) {
                    grouping = groupingString
                } else {
                    grouping = Grouping.YEAR
                }
                
                tags.selected = defaults.string(forKey: Constants.SETTINGS.KEY.COLLECTION)
                
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
                searchActive = searchText != nil

//                var indexOfMediaItem:Int?
//                
//                if let dict = defaults.dictionary(forKey: Constants.SETTINGS.MEDIA_PLAYING) as? [String:String] {
////                    print(dict)
//
//                    let mediaItemToMatch = MediaItem(dict: dict)
//                    
//                    indexOfMediaItem = mediaRepository.list?.index(where: { (mediaItem:MediaItem) -> Bool in
////                        print(mediaItem.title,mediaItemToMatch.title)
////                        print(mediaItem.date,mediaItemToMatch.date)
////                        print(mediaItem.service,mediaItemToMatch.service)
////                        print(mediaItem.speaker,mediaItemToMatch.speaker)
//                        return  (mediaItem.title   == mediaItemToMatch.title)     &&
//                                (mediaItem.date    == mediaItemToMatch.date)      &&
//                                (mediaItem.service == mediaItemToMatch.service)   &&
//                                (mediaItem.speaker == mediaItemToMatch.speaker)
//                    })
//                }
//                
//                mediaPlayer.mediaItem = indexOfMediaItem != nil ? mediaRepository.list?[indexOfMediaItem!] : nil
                
                mediaPlayer.mediaItem = mediaCategory.playing != nil ? mediaRepository.index?[mediaCategory.playing!] : nil

                if let historyArray = defaults.array(forKey: Constants.HISTORY) {
                    //        NSLog("\(settingsDictionary)")
                    history = historyArray as? [String]
                }
            } else {
                //This is where we should map the old version on to the new one and preserve the user's information.
                defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
                defaults.synchronize()
            }
        } else {
            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
            clearSettings()
            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
            defaults.synchronize()
        }
        
//        if category.settings == nil {
//            category.settings = [String:[String:String]]()
//        }
//        
//        if mediaItemSettings == nil {
//            mediaItemSettings = [String:[String:String]]()
//        }
//        
//        if multiPartSettings == nil {
//            multiPartSettings = [String:[String:String]]()
//        }
        
        //    NSLog("\(settings)")
    }
    
    func cancelAllDownloads()
    {
        if (mediaRepository.list != nil) {
            for mediaItem in mediaRepository.list! {
                for download in mediaItem.downloads.values {
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
    
    func updateCurrentTimeForPlaying()
    {
        assert(mediaPlayer.player != nil,"mediaPlayer.player should not be nil if we're trying to update the currentTime in userDefaults")
        
        if mediaPlayer.loaded && (mediaPlayer.duration != nil) {
            var timeNow = 0.0
            
            if (mediaPlayer.currentTime!.seconds > 0) && (mediaPlayer.currentTime!.seconds <= mediaPlayer.duration!.seconds) {
                timeNow = mediaPlayer.currentTime!.seconds
            }
            
            if ((timeNow > 0) && (Int(timeNow) % 10) == 0) {
                if Int(Float(mediaPlayer.mediaItem!.currentTime!)!) != Int(mediaPlayer.currentTime!.seconds) {
                    mediaPlayer.mediaItem?.currentTime = mediaPlayer.currentTime!.seconds.description
                }
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
    
//    private var GlobalPlayerContext = 0
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
//        guard context == &GlobalPlayerContext else {
//            super.observeValue(forKeyPath: keyPath,
//                               of: object,
//                               change: change,
//                               context: context)
//            return
//        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                //                print(player?.currentItem?.duration.value)
                //                print(player?.currentItem?.duration.timescale)
                //                print(player?.currentItem?.duration.seconds)
                if !mediaPlayer.loaded && (mediaPlayer.mediaItem != nil) && (mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM)) {
                    mediaPlayer.loaded = true

                    if mediaPlayer.mediaItem!.hasCurrentTime() {
                        if mediaPlayer.mediaItem!.atEnd {
                            mediaPlayer.seek(to: mediaPlayer.duration!.seconds)
                        } else {
                            mediaPlayer.seek(to: Double(mediaPlayer.mediaItem!.currentTime!)!)
                        }
                    } else {
                        mediaPlayer.mediaItem?.currentTime = Constants.ZERO
                        mediaPlayer.seek(to: 0)
                    }
                    
                    if mediaPlayer.playOnLoad {
                        if mediaPlayer.mediaItem!.atEnd {
                            mediaPlayer.mediaItem!.currentTime = Constants.ZERO
                            mediaPlayer.seek(to: 0)
                            mediaPlayer.mediaItem?.atEnd = false
                        }
                        mediaPlayer.playOnLoad = false
                        mediaPlayer.play()
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
                    })
                }
                
                if (mediaPlayer.url != nil) {
                    switch mediaPlayer.url!.absoluteString {
                    case Constants.URL.LIVE_STREAM:
                        setupLivePlayingInfoCenter()
                        break
                        
                    default:
                        setupPlayingInfoCenter()
                        break
                    }
                }
                break
                
            case .failed:
                // Player item failed. See error.
                networkUnavailable("Media failed to load.")
                mediaPlayer.loadFailed = true
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
                })
                break
                
            case .unknown:
                // Player item is not yet ready.
                if #available(iOS 10.0, *) {
                    print(mediaPlayer.player!.reasonForWaitingToPlay!)
                } else {
                    // Fallback on earlier versions
                }
                break
            }
        }
    }
    
    func setupLivePlayingInfoCenter()
    {
        if mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
            var nowPlayingInfo = [String:Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle]         = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyArtist]        = "Countryside Bible Church"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle]    = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist]   = "Countryside Bible Church"
            
            if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(image: image)
            }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func setupPlayingInfoCenter()
    {
        if mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) { //  && (mediaPlayer.mediaItem?.playing == Playing.audio)
            if (mediaPlayer.mediaItem != nil) {
                var nowPlayingInfo = [String:Any]()
                
                nowPlayingInfo[MPMediaItemPropertyTitle]     = mediaPlayer.mediaItem?.title
                nowPlayingInfo[MPMediaItemPropertyArtist]    = mediaPlayer.mediaItem?.speaker
                
                if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                } else {
                    print("no artwork!")
                }
                
                if mediaPlayer.mediaItem!.hasMultipleParts {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mediaPlayer.mediaItem?.multiPartName
                    nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = mediaPlayer.mediaItem?.speaker

                    if let index = mediaPlayer.mediaItem?.multiPartMediaItems?.index(of: mediaPlayer.mediaItem!) {
                        nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber]  = index + 1
                    } else {
                        print(mediaPlayer.mediaItem," not found in ",mediaPlayer.mediaItem?.multiPartMediaItems)
                    }

                    nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount]   = mediaPlayer.mediaItem?.multiPartMediaItems?.count
                }
                
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration]          = mediaPlayer.duration?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime]  = mediaPlayer.currentTime?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate]         = mediaPlayer.rate
                
                //    NSLog("\(mediaItemInfo.count)")
                
//                print(nowPlayingInfo)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                })
            }
        }
    }
    
    func didPlayToEnd()
    {
//        print("didPlayToEnd",globals.mediaPlayer.mediaItem)
        
//        print(mediaPlayer.currentTime?.seconds)
//        print(mediaPlayer.duration?.seconds)
        
        mediaPlayer.pause()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        })

        if let duration = mediaPlayer.duration?.seconds {
            if let currentTime = mediaPlayer.currentTime?.seconds {
                mediaPlayer.mediaItem?.atEnd = currentTime >= (duration - 1)
                if (mediaPlayer.mediaItem != nil) && !mediaPlayer.mediaItem!.atEnd {
                    reloadPlayer(globals.mediaPlayer.mediaItem)
                }
            } else {
                mediaPlayer.mediaItem?.atEnd = true
            }
        } else {
            mediaPlayer.mediaItem?.atEnd = true
        }
        
        if autoAdvance && (mediaPlayer.mediaItem != nil) && mediaPlayer.mediaItem!.atEnd && (mediaPlayer.mediaItem?.multiPartMediaItems != nil) {
            if (mediaPlayer.mediaItem?.playing == Playing.audio) {
                let mediaItems = mediaPlayer.mediaItem?.multiPartMediaItems
                if let index = mediaItems?.index(of: mediaPlayer.mediaItem!) {
                    if index < (mediaItems!.count - 1) {
                        if let nextMediaItem = mediaItems?[index + 1] {
                            nextMediaItem.playing = Playing.audio
                            nextMediaItem.currentTime = Constants.ZERO
                            mediaPlayer.mediaItem = nextMediaItem
                            
                            setupPlayer(nextMediaItem,playOnLoad:true)
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
                            })
                        }
                    }
                }
            }
        }
    }
    
    func observePlayer()
    {
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.playerObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(Globals.playerTimer), userInfo: nil, repeats: true)
//        })
        
        if (mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            unobservePlayer()
            
            mediaPlayer.player?.currentItem?.addObserver(self,
                                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                                         options: [.old, .new],
                                                         context: nil) // &GlobalPlayerContext
            mediaPlayer.observerActive = true
            
            mediaPlayer.playerTimerReturn = mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
                self?.playerTimer()
            })

            DispatchQueue.main.async {
                NotificationCenter.default.addObserver(self, selector: #selector(Globals.didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            }

            mediaPlayer.pause()
        }
    }
    
    func unobservePlayer()
    {
//        self.playerObserver?.invalidate()
//        self.playerObserver = nil
        
        if mediaPlayer.playerTimerReturn != nil {
            mediaPlayer.player?.removeTimeObserver(mediaPlayer.playerTimerReturn!)
            mediaPlayer.playerTimerReturn = nil
        }
        
        if mediaPlayer.observerActive {
            mediaPlayer.player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
            mediaPlayer.observerActive = false
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func startAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        } catch _ {
            NSLog("failed to setCategory(AVAudioSessionCategoryPlayback)")
            NSLog("failed to audioSession.setActive(true)")
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func stopAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch _ {
            NSLog("failed to audioSession.setActive(false)")
        }
    }
    
    func setupPlayer(url:URL?,playOnLoad:Bool)
    {
        if (url != nil) {
            mediaPlayer.unload()
            
            mediaPlayer.playOnLoad = playOnLoad
            mediaPlayer.showsPlaybackControls = false

            unobservePlayer()
            
            mediaPlayer.player = AVPlayer(url: url!)

            // Just replacing the item will not cause a timeout when the player can't load.
//            if mediaPlayer.player == nil {
//                mediaPlayer.player = AVPlayer(url: url!)
//            } else {
//                mediaPlayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
//            }
            
            mediaPlayer.player?.actionAtItemEnd = .pause
            
            observePlayer()
            
            MPRemoteCommandCenter.shared().playCommand.isEnabled = (mediaPlayer.player != nil) && (mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM))
            MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = (mediaPlayer.player != nil) && (mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM))
            MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = (mediaPlayer.player != nil) && (mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM))
        }
    }
    
    func setupPlayer(_ mediaItem:MediaItem?,playOnLoad:Bool)
    {
        if (mediaItem != nil) {
            setupPlayer(url: mediaItem!.playingURL,playOnLoad: playOnLoad)
        }
    }
    
    func reloadPlayer(_ mediaItem:MediaItem?)
    {
        if (mediaItem != nil) {
            reloadPlayer(url: mediaItem!.playingURL)
        }
    }
    
    func reloadPlayer(url:URL?)
    {
        if (url != nil) {
            mediaPlayer.unload()
            
            unobservePlayer()
            
            mediaPlayer.player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
            
            observePlayer()
        }
    }
    
    func setupPlayerAtEnd(_ mediaItem:MediaItem?)
    {
        setupPlayer(mediaItem,playOnLoad:false)
        
        if (mediaPlayer.duration != nil) {
            mediaPlayer.pause()
            mediaPlayer.seek(to: mediaPlayer.duration?.seconds)
            mediaItem?.currentTime = Float(mediaPlayer.duration!.seconds).description
            mediaItem?.atEnd = true
        }
    }
    
    func addToHistory(_ mediaItem:MediaItem?)
    {
        if (mediaItem != nil) {
            let entry = "\(Date())" + Constants.TAGS_SEPARATOR + mediaItem!.id!
            
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
            NSLog("mediaItem NIL!")
        }
    }
    
    func totalCacheSize() -> Int64
    {
        return cacheSize(Purpose.audio) + cacheSize(Purpose.video) + cacheSize(Purpose.notes) + cacheSize(Purpose.slides)
    }
    
    func cacheSize(_ purpose:String) -> Int64
    {
        var totalFileSize:Int64 = 0
        
        if mediaRepository.list != nil {
            for mediaItem in mediaRepository.list! {
                if let download = mediaItem.downloads[purpose] {
                    if download.isDownloaded() {
                        totalFileSize += download.fileSize
                    }
                }
            }
        }
        
        return totalFileSize
    }
    
    func playerTimer()
    {
        // This function does not get called when the media is not playing.

//        print(MPNowPlayingInfoCenter.default().nowPlayingInfo)
        
//        if (globals.mediaPlayer.url != nil) {
//            switch globals.mediaPlayer.url!.absoluteString {
//            case Constants.URL.LIVE_STREAM:
//                globals.setupLivePlayingInfoCenter()
//                break
//                
//            default:
//                globals.setupPlayingInfoCenter()
//                break
//            }
//        }

        if (mediaPlayer.state != nil) && (mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM)) {
            if (mediaPlayer.rate > 0) {
                updateCurrentTimeForPlaying()
            }
            
//            mediaPlayer.logPlayerState()
            
            switch mediaPlayer.state! {
            case .none:
                break
                
            case .playing:
//                if !mediaPlayer.loaded && !mediaPlayer.loadFailed {
//                    if (mediaPlayer.stateTime!.timeElapsed > Constants.MIN_PLAY_TIME) {
//                        mediaPlayer.pause()
//                        
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
//                        })
//                        
//                        let errorAlert = UIAlertView(title: "Unable to Play Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
//                        errorAlert.show()
//                    } else {
//                        // Wait so the player can keep trying.
//                    }
//                }
                break
                
            case .paused:
//                if !mediaPlayer.loaded && !mediaPlayer.loadFailed {
//                    if (mediaPlayer.stateTime!.timeElapsed > Constants.MIN_LOAD_TIME) {
//                        mediaPlayer.loadFailed = true
//                        
//                        if (UIApplication.shared.applicationState == UIApplicationState.active) {
//                            let errorAlert = UIAlertView(title: "Unable to Load Content", message: "Please check your network connection and try to play it again.", delegate: self, cancelButtonTitle: "OK")
//                            errorAlert.show()
//                        }
//                    }
//                }
                break
                
            case .stopped:
                break
                
            case .seekingForward:
                break
                
            case .seekingBackward:
                break
            }
        }
    }
    
    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?) {
        if (motion == .motionShake) {
            if (mediaPlayer.mediaItem != nil) {
                if mediaPlayer.isPaused {
                    mediaPlayer.play()
                } else {
                    mediaPlayer.pause()
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                })
            }
        }
    }
    
    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlPlay")
            self.mediaPlayer.play()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlPause")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlTogglePlayPause")
            if self.mediaPlayer.isPaused {
                self.mediaPlayer.play()
            } else {
                self.mediaPlayer.pause()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlStop")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlSkipBackward")
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds - 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        //        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            NSLog("RemoteControlSkipForward")
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds + 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                NSLog("MPChangePlaybackPositionCommand")
                self.mediaPlayer.seek(to: (event as! MPChangePlaybackPositionCommandEvent).positionTime)
                return MPRemoteCommandHandlerStatus.success
            })
        } else {
            // Fallback on earlier versions
        }
        
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

