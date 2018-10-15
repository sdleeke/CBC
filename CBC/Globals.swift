//
//  Globals.shared.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit
import CoreData

class Globals : NSObject, AVPlayerViewControllerDelegate
{
    static var shared = Globals()
    
    var rootViewController : UIViewController!
    {
        get {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }
    
    var splitViewController : UISplitViewController!
    {
        get {
            return rootViewController as? UISplitViewController
        }
    }
    
    var storyboard : UIStoryboard!
    {
        get {
            return rootViewController?.storyboard
        }
    }
    
    var purge = false
    
    var queue = DispatchQueue(label: "CBC")
    
    var allowMGTs = true
    
    var isVoiceBaseAvailable : Bool // = false
    {
        get {
            guard allowMGTs else {
                return false
            }
            
            guard Globals.shared.reachability.isReachable else {
                return false
            }
            
            return _isVoiceBaseAvailable ?? checkingAvailability
        }
        set {
            _isVoiceBaseAvailable = newValue
        }
    }
    private var _isVoiceBaseAvailable : Bool? // = false
    {
        didSet {
            guard _isVoiceBaseAvailable != oldValue else {
                return
            }
            
            // Why?
            Thread.onMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
            }
        }
    }

    var checkingAvailability = false
    
    func checkVoiceBaseAvailability()
    {
        checkVoiceBaseAvailability(completion:nil)
    }
    
    func checkVoiceBaseAvailability(completion:(()->(Void))?)
    {
        _isVoiceBaseAvailable = nil

        guard reachability.isReachable else {
            isVoiceBaseAvailable = false
            return
        }
        
        checkingAvailability = true
        
        VoiceBase.all(completion: { (json:[String : Any]?) -> (Void) in
            self.isVoiceBaseAvailable = true
            completion?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.isVoiceBaseAvailable = false
            completion?()
        })
        
        checkingAvailability = false
    }
    
    var voiceBaseAPIKey : String?
    {
        get {
            if let key = UserDefaults.standard.string(forKey: Constants.Strings.VoiceBase_API_Key) {
                if key.isEmpty {
                    return nil
                }
                
                return key
            } else {
                return nil
            }
        }
        set {
            if let key = newValue {
                if !key.isEmpty {
                    UserDefaults.standard.set(newValue, forKey: Constants.Strings.VoiceBase_API_Key)
                } else {
                    isVoiceBaseAvailable = false
                    UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
                }
                
                // Do we need to notify VoiceBase objects?
                // No, because if it was nil before there shouldn't be anything on VB.com
                // No, because if it was not nil before then they either the new KEY is good or bad.
                // If bad, then it will fail.  If good, then they will finish.
                // So, nothing needs to be done.
            } else {
                isVoiceBaseAvailable = false
                UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
            }

            UserDefaults.standard.synchronize()
            
            _voiceBaseAPIKey = newValue
        }
    }
    var _voiceBaseAPIKey : String?
    {
        didSet {
            checkVoiceBaseAvailability()
        }
    }
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool
    {
        return true
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
    {
        completionHandler(true)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error)
    {
        print("failedToStartPictureInPictureWithError \(error.localizedDescription)")
        mediaPlayer.pip = .stopped
    }
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        print("playerViewControllerWillStopPictureInPicture")
        mediaPlayer.stoppingPIP = true
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        print("playerViewControllerDidStopPictureInPicture")
        mediaPlayer.pip = .stopped
        mediaPlayer.stoppingPIP = false
    }

    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        print("playerViewControllerWillStartPictureInPicture")
        mediaPlayer.startingPIP = true
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        print("playerViewControllerDidStartPictureInPicture")
        mediaPlayer.pip = .started
        mediaPlayer.startingPIP = false
    }
    
    var allowSaveSettings = true
    
    let reachability = Reachability(hostname: "www.countrysidebible.org")!
    
    var priorReachabilityStatus : Reachability.NetworkStatus?
    
    func reachabilityTransition()
    {
        if let priorReachabilityStatus = priorReachabilityStatus {
            switch priorReachabilityStatus {
            case .notReachable:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Not Reachable -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Not Reachable -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Not Reachable -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
                
            case .reachableViaWLAN:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Reachable via WLAN, e.g. WiFi or Bluetooth -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
                
            case .reachableViaWWAN:
                switch reachability.currentReachabilityStatus {
                case .notReachable:
                    print("Reachable via WWAN, e.g. Cellular -> Not Reachable")
                    break
                    
                case .reachableViaWLAN:
                    print("Reachable via WWAN, e.g. Cellular -> Reachable via WLAN, e.g. WiFi or Bluetooth")
                    break
                    
                case .reachableViaWWAN:
                    print("Reachable via WWAN, e.g. Cellular -> Reachable via WWAN, e.g. Cellular")
                    break
                }
                break
            }
        } else {
            switch reachability.currentReachabilityStatus {
            case .notReachable:
                print("Not Reachable")
                break
                
            case .reachableViaWLAN:
                print("Reachable via WLAN, e.g. WiFi or Bluetooth")
                break
                
            case .reachableViaWWAN:
                print("Reachable via WWAN, e.g. Cellular")
                break
            }
        }
        
        if priorReachabilityStatus == .notReachable, reachability.isReachable, mediaRepository.list != nil {
            Alerts.shared.alert(title: "Network Connection Restored",message: "")

            checkVoiceBaseAvailability()
        }
        
        if priorReachabilityStatus != .notReachable, !reachability.isReachable, mediaRepository.list != nil {
            Alerts.shared.alert(title: "No Network Connection",message: "Without a network connection only audio, slides, and transcripts previously downloaded will be available.")
            
            isVoiceBaseAvailable = false
        }
        
        priorReachabilityStatus = reachability.currentReachabilityStatus
    }
    
    deinit {
        
    }
    
    override init()
    {
        super.init()
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
    var scrolledToMediaItemLastSelected = false

    var groupings = Constants.groupings
    var groupingTitles = Constants.GroupingTitles
    
    var grouping:String? = GROUPING.YEAR
    {
        willSet {
            
        }
        didSet {
            media.need.grouping = (grouping != oldValue)
            
            let defaults = UserDefaults.standard
            if (grouping != nil) {
                defaults.set(grouping,forKey: Constants.SETTINGS.GROUPING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.GROUPING)
            }
            defaults.synchronize()
        }
    }
    
    var sorting:String? = SORTING.REVERSE_CHRONOLOGICAL
    {
        willSet {
            
        }
        didSet {
            media.need.sorting = (sorting != oldValue)
            
            let defaults = UserDefaults.standard
            if (sorting != nil) {
                defaults.set(sorting,forKey: Constants.SETTINGS.SORTING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    var autoAdvance:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool
    {
        get {
            if UserDefaults.standard.object(forKey: Constants.SETTINGS.CACHE_DOWNLOADS) == nil {
                if #available(iOS 9.0, *) {
                    UserDefaults.standard.set(true, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
                } else {
                    UserDefaults.standard.set(false, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
                }
            }
            
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var search = Search()
    
    var contextTitle:String?
    {
        get {
            var string:String?
            
            if let mediaCategory = mediaCategory.selected, !mediaCategory.isEmpty {
                string = mediaCategory // Category:
                
                if let tag = media.tags.selected {
                    string = (string != nil ? string! + ", " : "") + tag  // Collection:
                }
                
                if self.search.valid, let search = self.search.text {
                    string = (string != nil ? string! + ", " : "") + "\"\(search)\""  // Search:
                }
            }
            
            return string
        }
    }
    
    func context() -> String?
    {
        return contextString
    }
    
    func searchText() -> String?
    {
        return search.text
    }
    
    var contextString:String?
    {
        get {
            var string:String?
            
            if let mediaCategory = mediaCategory.selected {
                string = mediaCategory
                
                if let tag = media.tags.selected {
                    string = ((string != nil) ? string! + ":" : "") + tag
                }
                
                if self.search.valid, let search = self.search.text {
                    string = ((string != nil) ? string! + ":" : "") + search
                }
            }
            
            return string
        }
    }

    func contextOrder() -> String?
    {
        var string:String?
        
        if let context = contextString {
            string = ((string != nil) ? string! + ":" : "") + context
        }
        
        if let order = orderString {
            string = ((string != nil) ? string! + ":" : "") + order
        }
        
        return string
    }

    var orderString:String?
    {
        get {
            var string:String?
            
            if let sorting = sorting {
                string = ((string != nil) ? string! + ":" : "") + sorting
            }
            
            if let grouping = grouping {
                string = ((string != nil) ? string! + ":" : "") + grouping
            }
            
            return string
        }
    }

    var mediaPlayer = MediaPlayer()

    var selectedMediaItem = SelectedMediaItem()
    
    var mediaCategory = MediaCategory()
    
    var mediaStream = MediaStream()
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    
    var multiPartSettings = ThreadSafeDictionaryOfDictionaries<String>(name: "MULTIPARTSETTINGS") // [String:[String:String]]?

    var mediaItemSettings = ThreadSafeDictionaryOfDictionaries<String>(name: "MEDIAITEMSETTINGS") // [String:[String:String]]?

    // Make thread safe?
    var history:[String]?
    
    // Make thread safe?
    var relevantHistory:[String]?
    {
        get {
            guard let index = mediaRepository.index else {
                return nil
            }
            
            return history?.reversed().filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.TAGS_SEPARATOR) {
                    let mediaItemID = String(string[range.upperBound...])
                    return index[mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    // Make thread safe?
    var relevantHistoryList:[String]?
    {
        get {
            return relevantHistory?.map({ (string:String) -> String in
                if  let range = string.range(of: Constants.TAGS_SEPARATOR),
                    let mediaItem = mediaRepository.index?[String(string[range.upperBound...])],
                    let text = mediaItem.text {
                    return text
                }

                return ("ERROR")
            })
        }
    }

    var mediaRepository = MediaRepository()

    var media = Media()
    
    func freeMemory()
    {
        // Free memory in classes
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }

        URLCache.shared.removeAllCachedResponses()
    }
    
    func saveSettingsBackground()
    {
        guard allowSaveSettings else {
            return
        }

        print("saveSettingsBackground")
        
        DispatchQueue.global(qos: .background).async { // [weak self] in
            self.saveSettings()
        }
    }
    
    func saveSettings()
    {
        guard allowSaveSettings else {
            return
        }
        
        print("saveSettings")
        let defaults = UserDefaults.standard
        //    print("\(settings)")
        defaults.set(mediaItemSettings.copy,forKey: Constants.SETTINGS.MEDIA)
        //    print("\(seriesViewSplits)")
        defaults.set(multiPartSettings.copy, forKey: Constants.SETTINGS.MULTI_PART_MEDIA)
        defaults.synchronize()
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
        //    print("\(settings)")
        defaults.removeObject(forKey: Constants.SETTINGS.MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.MULTI_PART_MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.CATEGORY)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        guard let settingsVersion = defaults.string(forKey: Constants.SETTINGS.VERSION.KEY) else {
            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
            clearSettings()
            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
            defaults.synchronize()
            return
        }
        
        if settingsVersion == Constants.SETTINGS.VERSION.NUMBER {
            if let mediaItemSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.MEDIA) {
                mediaItemSettings.update(storage: mediaItemSettingsDictionary)
            }
            
            if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.MULTI_PART_MEDIA) {
                multiPartSettings.update(storage: seriesSettingsDictionary)
            }
            
            if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.CATEGORY) {
                mediaCategory.settings.update(storage: categorySettingsDictionary)
            }
            
            if let sortingString = defaults.string(forKey: Constants.SETTINGS.SORTING) {
                sorting = sortingString
            } else {
                sorting = SORTING.REVERSE_CHRONOLOGICAL
            }
            
            if let groupingString = defaults.string(forKey: Constants.SETTINGS.GROUPING) {
                grouping = groupingString
            } else {
                grouping = GROUPING.YEAR
            }
            
            if (media.tags.selected == Constants.Strings.New) {
                media.tags.selected = nil
            }

            if media.tags.showing == Constants.TAGGED, let tag = mediaCategory.tag, media.tagged[tag] == nil {
                if media.all == nil {
                    //This is filtering, i.e. searching all mediaItems => s/b in background
                    media.tagged[tag] = MediaListGroupSort(mediaItems: mediaItemsWithTag(mediaRepository.list, tag: media.tags.selected))
                } else {
                    if let sortTag = media.tags.selected?.withoutPrefixes {
                        media.tagged[tag] = MediaListGroupSort(mediaItems: media.all?.tagMediaItems?[sortTag])
                    }
                }
            }

            search.text = defaults.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
            search.active = search.text != nil

            if let playing = mediaCategory.playing {
                mediaPlayer.mediaItem = mediaRepository.index?[playing]
            } else {
                mediaPlayer.mediaItem = nil
            }

            if let historyArray = defaults.array(forKey: Constants.SETTINGS.HISTORY) {
                //        print("\(settingsDictionary)")
                history = historyArray as? [String]
            }
        } else {
            //This is where we should map the old version on to the new one and preserve the user's information.
            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
            defaults.synchronize()
        }
    }
    
    func cancelAllDownloads()
    {
        guard let list = mediaRepository.list else {
            return
        }

        for mediaItem in list {
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
    
    func addToHistory(_ mediaItem:MediaItem? = nil)
    {
        guard let mediaItem = mediaItem else {
            print("mediaItem NIL!")
            return
        }
        
        let entry = "\(Date())" + Constants.TAGS_SEPARATOR + mediaItem.id
        
        if history == nil {
            history = [entry]
        } else {
            history?.append(entry)
        }
        
        //        print(history)
        
        let defaults = UserDefaults.standard
        defaults.set(history, forKey: Constants.SETTINGS.HISTORY)
        defaults.synchronize()
    }

    func totalCacheSize() -> Int
    {
        return cacheSize(Purpose.audio) + cacheSize(Purpose.video) + cacheSize(Purpose.notes) + cacheSize(Purpose.slides)
    }
    
    func cacheSize(_ purpose:String) -> Int
    {
        guard let list = mediaRepository.list else {
            return 0
        }
        
        var totalFileSize = 0
        
        for mediaItem in list {
            if let download = mediaItem.downloads[purpose], download.isDownloaded {
                totalFileSize += download.fileSize
            }
        }

        return totalFileSize
    }

    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?)
    {
        guard (UIDevice.current.userInterfaceIdiom == .phone) else {
            return
        }

        guard motion == .motionShake else {
            return
        }
        
        guard mediaPlayer.mediaItem != nil else {
            return
        }
        
        if mediaPlayer.isPaused {
            mediaPlayer.play()
        } else {
            mediaPlayer.pause()
        }
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
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
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds - 15)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        //        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipForward")
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds + 15)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
    
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                print("MPChangePlaybackPositionCommand")
                
                if let time = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                    self.mediaPlayer.seek(to: time)
                }
                
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

