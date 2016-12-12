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

class CachedString {
    @objc func freeMemory()
    {
        cache = [String:String]()
    }
    
    var index:(()->String?)?
    
    var cache = [String:String]()
    
    // if index DOES NOT produce the full key
    subscript(key:String?) -> String? {
        get {
            guard key != nil else {
                return nil
            }
            
            if let index = self.index?() {
                return cache[index+":"+key!]
            } else {
                return cache[key!]
            }
        }
        set {
            guard key != nil else {
                return
            }

            if let index = self.index?() {
                cache[index+":"+key!] = newValue
            } else {
                cache[key!] = newValue
            }
        }
    }
    
    // if index DOES produce the full key
    var string:String? {
        get {
            if let index = self.index?() {
                return cache[index]
            } else {
                return nil
            }
        }
        set {
            if let index = self.index?() {
                cache[index] = newValue
            }
        }
    }
    
    init(index:@escaping (()->String?))
    {
        self.index = index

        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(CachedString.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
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
            print(stateName!)
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
        guard (url != nil) else {
            return
        }

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
            }
            break
        }

        setupPlayingInfoCenter()
    }
    
    func pause()
    {
        guard (url != nil) else {
            return
        }

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
            break
        }

        setupPlayingInfoCenter()
    }
    
    func stop()
    {
        guard (url != nil) else {
            return
        }

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
            break
        }

        setupPlayingInfoCenter()
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
            print("seekToTime == 0")
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
        guard (to != nil) else {
            return
        }

        guard (url != nil) else {
            return
        }

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
                
                setupPlayingInfoCenter()
            }
            break
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

            if sliderTimerReturn != nil {
                player?.removeTimeObserver(sliderTimerReturn!)
                sliderTimerReturn = nil
            }
            
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
    
//    var observer: Timer?
    
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
    
    func setupPlayingInfoCenter()
    {
        if url == URL(string: Constants.URL.LIVE_STREAM) {
            var nowPlayingInfo = [String:Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle]         = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyArtist]        = "Countryside Bible Church"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle]    = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist]   = "Countryside Bible Church"
            
            if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(image: image)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            })
        } else {
            if let mediaItem = self.mediaItem {
                var nowPlayingInfo = [String:Any]()
                
                nowPlayingInfo[MPMediaItemPropertyTitle]     = mediaItem.title
                nowPlayingInfo[MPMediaItemPropertyArtist]    = mediaItem.speaker
                
                if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                } else {
                    print("no artwork!")
                }
                
                if mediaItem.hasMultipleParts {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mediaItem.multiPartName
                    nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = mediaItem.speaker
                    
                    if let index = mediaItem.multiPartMediaItems?.index(of: mediaItem) {
                        nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber]  = index + 1
                    } else {
                        print(mediaItem as Any," not found in ",mediaItem.multiPartMediaItems as Any)
                    }
                    
                    nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount]   = mediaItem.multiPartMediaItems?.count
                }
                
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration]          = duration?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime]  = currentTime?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate]         = rate
                
                //    print("\(mediaItemInfo.count)")
                
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
}

struct MediaNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

struct Display {
    var mediaItems:[MediaItem]?
    var section = Section()
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
                        print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
            }
        }
    }

    var index:[String:MediaItem]?
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

struct Media {
    var need = MediaNeed()

    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged:MediaListGroupSort?
    
    var tags = Tags()
    
    var toSearch:MediaListGroupSort? {
        get {
            var mediaItems:MediaListGroupSort?
            
            switch tags.showing! {
            case Constants.TAGGED:
                mediaItems = tagged
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            return mediaItems
        }
    }
    
    var active:MediaListGroupSort? {
        get {
            var mediaItems:MediaListGroupSort?
            
            switch tags.showing! {
            case Constants.TAGGED:
                mediaItems = tagged
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            if globals.search.valid {
                mediaItems = mediaItems?.searches?[globals.search.text!]
            }
            
            return mediaItems
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
            print("saveSettingsBackground")
            
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
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
            guard (selected != nil) else {
                print("selected == nil!")
                return
            }

            if settings == nil {
                settings = [String:[String:String]]()
            }
            
            guard (settings != nil) else {
                print("settings == nil!")
                return
            }

            if (settings?[selected!] == nil) {
                settings?[selected!] = [String:String]()
            }
            if (settings?[selected!]?[key] != newValue) {
                settings?[selected!]?[key] = newValue
                
                // For a high volume of activity this can be very expensive.
                saveSettingsBackground()
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
            
            if let selectedMediaItemID = globals.mediaCategory.selectedInMaster {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
    }
    
    var detail:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = globals.mediaCategory.selectedInDetail {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }

            return selectedMediaItem
        }
    }
}

struct Search {
    var complete:Bool = true
    var active:Bool = false
    
    var valid:Bool {
        get {
            return active && (text != nil) && (text != Constants.EMPTY_STRING)
        }
    }
    
    var text:String? {
        didSet {
            if (text != nil) {
                active = (active && (text == Constants.EMPTY_STRING)) || (text != Constants.EMPTY_STRING)
            } else {
                active = false
            }
            
            if (text != oldValue) {
                if valid {
                    UserDefaults.standard.set(text, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    var transcripts:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            globals.media.toSearch?.searches = nil
            
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
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
            media.need.grouping = (grouping != oldValue)
            
//            if (grouping != oldValue) {
//                media.active?.html.string = nil
//            }
            
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
            media.need.sorting = (sorting != oldValue)
            
//            if (sorting != oldValue) {
//                media.active?.html.string = nil
//            }
            
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
    
    var search = Search()
    
//    var searchComplete:Bool = true
//    var searchActive:Bool = false
//    var searchText:String? {
//        didSet {
//            if (searchText != nil) {
//                searchActive = (searchActive && (searchText == Constants.EMPTY_STRING)) || (searchText != Constants.EMPTY_STRING)
//            } else {
//                searchActive = false
//            }
//            
//            if (searchText != oldValue) {
//                if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
//                    UserDefaults.standard.set(searchText, forKey: Constants.SEARCH_TEXT)
//                    UserDefaults.standard.synchronize()
//                } else {
//                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
//                    UserDefaults.standard.synchronize()
//                }
//            }
//        }
//    }
    
    var contextTitle:String? {
        get {
            var string:String?
            
            if let mediaCategory = globals.mediaCategory.selected {
                string = mediaCategory // Category:
                
                if let tag = globals.media.tags.selected {
                    string = string! + ", " + tag  // Collection:
                }
                
                if globals.search.valid, let search = globals.search.text {
                    string = string! + ", \"\(search)\""  // Search:
                }
            }
            
            return string
        }
    }
    
    func context() -> String? {
        return contextString
    }
    
    var contextString:String? {
        get {
            var string:String?
            
            if let mediaCategory = globals.mediaCategory.selected {
                string = mediaCategory
                
                if let tag = globals.media.tags.selected {
                    string = (string != nil) ? string! + ":" + tag : tag
                }
                
                if globals.search.valid, let search = globals.search.text {
                    string = (string != nil) ? string! + ":" + search : search
                }
            }
            
            return string
        }
    }

    func contextOrder() -> String? {
        var string:String?
        
        if let context = contextString {
            string = (string != nil) ? string! + ":" + context : context
        }
        
        if let order = orderString {
            string = (string != nil) ? string! + ":" + order : order
        }
        
        return string
    }

    var orderString:String? {
        get {
            var string:String?
            
            if let sorting = globals.sorting {
                string = (string != nil) ? string! + ":" + sorting : sorting
            }
            
            if let grouping = globals.grouping {
                string = (string != nil) ? string! + ":" + grouping : grouping
            }
            
            return string
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
    
    var relevantHistory:[String]? {
        get {
            return globals.history?.reversed().filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.TAGS_SEPARATOR) {
                    let mediaItemID = string.substring(from: range.upperBound)
                    return globals.mediaRepository.index![mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    var relevantHistoryList:[String]? {
        get {
            var list = [String]()
            
            if let historyList = relevantHistory {
                for history in historyList {
                    var mediaItemID:String
                    
                    if let range = history.range(of: Constants.TAGS_SEPARATOR) {
                        mediaItemID = history.substring(from: range.upperBound)
                        
                        if let mediaItem = globals.mediaRepository.index![mediaItemID] {
                            if let text = mediaItem.text {
                                list.append(text)
                            } else {
                                print(mediaItem.text)
                            }
                        } else {
                            print(mediaItemID)
                        }
                    } else {
                        print("no range")
                    }
                }
            } else {
                print("no historyList")
            }
            
            return list.count > 0 ? list : nil
        }
    }

    var mediaRepository = MediaRepository()
    
    var media = Media()
    
    var display = Display()
    
    func freeMemory()
    {
        // Free memory in classes
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }

        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearDisplay()
    {
        display.mediaItems = nil

        display.section.titles = nil
        display.section.indexes = nil
        display.section.counts = nil
    }
    
    func setupDisplay()
    {
//        print("setupDisplay")

        display.mediaItems = media.active?.mediaItems
        
        display.section.titles = media.active?.section?.titles
        display.section.indexes = media.active?.section?.indexes
        display.section.counts = media.active?.section?.counts
    }
    
    func saveSettingsBackground()
    {
        if allowSaveSettings {
            print("saveSettingsBackground")
            
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
            let defaults = UserDefaults.standard
            //    print("\(settings)")
            defaults.set(mediaItemSettings,forKey: Constants.SETTINGS.KEY.MEDIA)
            //    print("\(seriesViewSplits)")
            defaults.set(multiPartSettings, forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
            defaults.synchronize()
        }
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
        //    print("\(settings)")
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
                    //        print("\(settingsDictionary)")
                    mediaItemSettings = mediaItemSettingsDictionary as? [String:[String:String]]
                }
                
                if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA) {
                    //        print("\(viewSplitsDictionary)")
                    multiPartSettings = seriesSettingsDictionary as? [String:[String:String]]
                }
                
                if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.CATEGORY) {
                    //        print("\(viewSplitsDictionary)")
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
                
                media.tags.selected = defaults.string(forKey: Constants.SETTINGS.KEY.COLLECTION)
                
                if (media.tags.selected == Constants.New) {
                    media.tags.selected = nil
                }
                
                if (media.tags.selected != nil) {
                    switch media.tags.selected! {
                    case Constants.All:
                        media.tags.selected = nil
                        media.tags.showing = Constants.ALL
                        break
                        
                    default:
                        media.tags.showing = Constants.TAGGED
                        break
                    }
                } else {
                    media.tags.showing = Constants.ALL
                }

                search.text = defaults.string(forKey: Constants.SEARCH_TEXT)
                search.active = search.text != nil

                mediaPlayer.mediaItem = mediaCategory.playing != nil ? mediaRepository.index?[mediaCategory.playing!] : nil

                if let historyArray = defaults.array(forKey: Constants.HISTORY) {
                    //        print("\(settingsDictionary)")
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
        
        //    print("\(settings)")
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
//                
//                if (mediaPlayer.url != nil) {
//                    switch mediaPlayer.url!.absoluteString {
//                    case Constants.URL.LIVE_STREAM:
//                        setupLivePlayingInfoCenter()
//                        break
//                        
//                    default:
//                        setupPlayingInfoCenter()
//                        break
//                    }
//                }
                
                mediaPlayer.setupPlayingInfoCenter()
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
    
    func didPlayToEnd()
    {
//        print("didPlayToEnd",globals.mediaPlayer.mediaItem)
        
//        print(mediaPlayer.currentTime?.seconds)
//        print(mediaPlayer.duration?.seconds)
        
        mediaPlayer.pause()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        })

        if let duration = mediaPlayer.duration?.seconds,
            let currentTime = mediaPlayer.currentTime?.seconds {
            mediaPlayer.mediaItem?.atEnd = currentTime >= (duration - 1)
            if (mediaPlayer.mediaItem != nil) && !mediaPlayer.mediaItem!.atEnd {
                reloadPlayer(globals.mediaPlayer.mediaItem)
            }
        } else {
            mediaPlayer.mediaItem?.atEnd = true
        }
        
        if autoAdvance && (mediaPlayer.mediaItem != nil) && mediaPlayer.mediaItem!.atEnd && (mediaPlayer.mediaItem?.multiPartMediaItems != nil) {
            if mediaPlayer.mediaItem?.playing == Playing.audio,
                let mediaItems = mediaPlayer.mediaItem?.multiPartMediaItems,
                let index = mediaItems.index(of: mediaPlayer.mediaItem!),
                index < (mediaItems.count - 1) {
                let nextMediaItem = mediaItems[index + 1]
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
    
    func observePlayer()
    {
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.playerObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(Globals.playerTimer), userInfo: nil, repeats: true)
//        })
        
        guard (mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            return
        }
        
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
            print("failed to setCategory(AVAudioSessionCategoryPlayback)")
            print("failed to audioSession.setActive(true)")
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func stopAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch _ {
            print("failed to audioSession.setActive(false)")
        }
    }
    
    func setupPlayer(url:URL?,playOnLoad:Bool)
    {
        guard (url != nil) else {
            return
        }
        
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
        guard (mediaItem != nil) else {
            print("mediaItem NIL!")
            return
        }

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
                if let download = mediaItem.downloads[purpose], download.isDownloaded() {
                    totalFileSize += download.fileSize
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
            print("RemoteControlPlay")
            self.mediaPlayer.play()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if self.mediaPlayer.isPaused {
                self.mediaPlayer.play()
            } else {
                self.mediaPlayer.pause()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlStop")
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
            print("RemoteControlSkipBackward")
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds - 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        //        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipForward")
            self.mediaPlayer.seek(to: self.mediaPlayer.currentTime!.seconds + 15)
            return MPRemoteCommandHandlerStatus.success
        })
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                print("MPChangePlaybackPositionCommand")
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

