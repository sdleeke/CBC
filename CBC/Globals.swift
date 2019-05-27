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

/**

 Singleton shared to access global properties and methods
 
 Properties:
    - rootViewController/splitViewController/storyboard
    - VoiceBase availability
    - reachability
    - sorting
    - grouping
    - settings
    - media player
    - Media
    - history
    - motion events
 */

class Globals : NSObject
{
    static var shared = Globals()
    
    private var rootViewController : UIViewController?
    {
        get {
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }
    
    var splitViewController : UISplitViewController?
    {
        get {
            return rootViewController as? UISplitViewController
        }
    }
    
//    var storyboard : UIStoryboard?
//    {
//        get {
//            return rootViewController?.storyboard
//        }
//    }
    
//    var purge = false
    
    // Global queue for activity that should not be on the main queue
    var queue = DispatchQueue(label: "CBC")
    
    // flag whether machine generated transcripts are allowed
    var allowMGTs = true

    // Timer to keep checking on whether VoiceBase is available
    var checkVoiceBaseTimer : Timer?

    // Shadow property for voicebase availability.
    private var _isVoiceBaseAvailable : Bool? // = false
    {
        didSet {
            guard _isVoiceBaseAvailable != oldValue else {
                return
            }

            guard let _isVoiceBaseAvailable = _isVoiceBaseAvailable else {
                return
            }

            if !_isVoiceBaseAvailable {
                if checkVoiceBaseTimer == nil {
                    checkVoiceBaseTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.ckVBA), userInfo:nil, repeats:true)
                }
            } else {
                checkVoiceBaseTimer?.invalidate()
                checkVoiceBaseTimer = nil
            }

            // Why?
            Thread.onMain {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
            }
        }
    }
    var isVoiceBaseAvailable : Bool? // = false
    {
        get {
            guard allowMGTs else {
                return false
            }

            guard reachability.isReachable else {
                return false
            }

            return _isVoiceBaseAvailable ?? false // checkingVoiceBaseAvailability
        }
        set {
            _isVoiceBaseAvailable = newValue
        }
    }

    // This is critical since we make a VB call to see if VB is available so we need to ignore the isVBAvailable nil or false
    var checkingVoiceBaseAvailability = false
    
    func checkVoiceBaseAvailability(completion:(()->(Void))? = nil)
    {
        isVoiceBaseAvailable = nil

        guard reachability.isReachable else {
            isVoiceBaseAvailable = false
            completion?()
            return
        }
        
        // Tell the world we are checking
        checkingVoiceBaseAvailability = true
        
        VoiceBase.all(completion: { [weak self] (json:[String : Any]?) -> (Void) in
            self?.isVoiceBaseAvailable = true
            completion?()
        }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
            self?.isVoiceBaseAvailable = false
            completion?()
        })
        
        // Tell the world we are done checking
        checkingVoiceBaseAvailability = false
    }
    
    @objc func ckVBA()
    {
        checkVoiceBaseAvailability()
    }

    private var _voiceBaseAPIKey : String?
    {
        didSet {
            checkVoiceBaseAvailability()
        }
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
    
//    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool
//    {
//        return true
//    }
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
//    {
//        completionHandler(true)
//    }
//
//    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error)
//    {
//        NSLog("failedToStartPictureInPictureWithError \(error.localizedDescription)")
//        mediaPlayer.pip = .stopped
//    }
//
//    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController)
//    {
//        print("playerViewControllerWillStopPictureInPicture")
//        mediaPlayer.stoppingPIP = true
//    }
//
//    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController)
//    {
//        print("playerViewControllerDidStopPictureInPicture")
//        mediaPlayer.pip = .stopped
//        mediaPlayer.stoppingPIP = false
//    }
//
//    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController)
//    {
//        print("playerViewControllerWillStartPictureInPicture")
//        mediaPlayer.startingPIP = true
//    }
//
//    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController)
//    {
//        print("playerViewControllerDidStartPictureInPicture")
//        mediaPlayer.pip = .started
//        mediaPlayer.startingPIP = false
//    }
    
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

        // Do include the list because we don't want to be warned at the start that there is a network connection
        if priorReachabilityStatus == .notReachable, reachability.isReachable, media.repository.list != nil {
            Alerts.shared.alert(title: "Network Connection Restored",message: "")

            checkVoiceBaseAvailability()
//            media.stream.loadLive(completion: nil)
        }
        
        // Don't include the list because we want to be warned at th start that there is no network connection
        if priorReachabilityStatus != .notReachable, !reachability.isReachable { // , mediaRepository.list != nil
            let title = "No Network Connection"
            var message = "Without a network connection only audio, slides, and transcripts previously downloaded will be available."
            
            if reachability.isOnWWANFlagSet {
                message += "\n\n"
                message += "Cellular data appears to be turned off."
            }

            Alerts.shared.alert(title: title,message: message)

            isVoiceBaseAvailable = false
        }
        
        priorReachabilityStatus = reachability.currentReachabilityStatus
    }
    
    override init()
    {
        super.init()
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMain {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMain {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

//    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
//    var scrolledToMediaItemLastSelected = false

    /////////////////////////////////////////////////////////////////////////////////////
    // would like to group these somehow
    /////////////////////////////////////////////////////////////////////////////////////
    var groupings = Constants.groupings
    var groupingTitles = Constants.GroupingTitles
    
    var grouping:String? = GROUPING.YEAR
    {
        willSet {
            
        }
        didSet {
            // This assumes it only changes ONCE.  I.e. another call w/ the new value and it will be false.
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
            // This assumes it only changes ONCE.  I.e. another call w/ the new value it will be false.
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
    /////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////
    // Would like to group these settings
    /////////////////////////////////////////////////////////////////////////////////////
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
    /////////////////////////////////////////////////////////////////////////////////////

    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var contextTitle:String?
    {
        get {
            guard let mediaCategory = media.category.selected, !mediaCategory.isEmpty else {
                return nil
            }
            
            var string = mediaCategory // Category:
                
            if let tag = media.tags.selected {
                string += ", " + tag  // Collection:
            }
            
            if media.search.isValid, let search = media.search.text {
                string += ", " + "\"\(search)\""  // Search:
            }
            
            if media.search.transcripts {
                string += " (including transcripts)"  // Search:
            }
            
            return string
        }
    }
    
//    func context() -> String?
//    {
//        return contextString
//    }
    
//    func searchText() -> String?
//    {
//        return media.search.text
//    }
    
//    var orderString:String?
//    {
//        get {
//            var string:String?
//
//            if let sorting = sorting {
//                string = ((string != nil) ? string! + ":" : "") + sorting
//            }
//
//            if let grouping = grouping {
//                string = ((string != nil) ? string! + ":" : "") + grouping
//            }
//
//            return string
//        }
//    }
    
//    var contextString:String?
//    {
//        get {
//            guard let mediaCategory = mediaCategory.selected else {
//                return nil
//            }
//            
//            var string = mediaCategory
//
//            if let tag = media.tags.selected {
//                string = (!string.isEmpty ? string + ":" : "") + tag
//            }
//
//            if media.search.isValid, let search = media.search.text {
//                string = (!string.isEmpty ? string + ":" : "") + search
//            }
//
//            return !string.isEmpty ? string : nil
//        }
//    }
    
//    func contextOrder() -> String?
//    {
//        var string:String?
//
//        if let context = contextString {
//            string = ((string != nil) ? string! + ":" : "") + context
//        }
//
//        if let order = orderString {
//            string = ((string != nil) ? string! + ":" : "") + order
//        }
//
//        return string
//    }

    var mediaPlayer = MediaPlayer()
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    
    ////////////////////////////////////////////////////////////////////////////
    // Would like to group these
    ////////////////////////////////////////////////////////////////////////////
    var multiPartSettings = ThreadSafeDN<String>(name: "MULTIPARTSETTINGS") // [String:[String:String]]? // ictionaryOfDictionaries

    var mediaItemSettings = ThreadSafeDN<String>(name: "MEDIAITEMSETTINGS") // [String:[String:String]]? // ictionaryOfDictionaries
    ////////////////////////////////////////////////////////////////////////////
   
    var media = Media()
    
    func freeMemory()
    {
        // Free memory in classes
        Thread.onMain {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }

        URLCache.shared.removeAllCachedResponses()
    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "GlobalSettings" // Assumes there is only one globally
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    func saveSettingsBackground()
    {
        guard allowSaveSettings else {
            return
        }

        print("saveSettingsBackground")
        
        operationQueue.addOperation {
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
        defaults.set(mediaItemSettings.copy,forKey: Constants.SETTINGS.MEDIA)
        defaults.set(multiPartSettings.copy, forKey: Constants.SETTINGS.MULTI_PART_MEDIA)
        defaults.synchronize()
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
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
                media.category.settings.update(storage: categorySettingsDictionary)
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

            media.search.text = defaults.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
            media.search.isActive = media.search.text != nil

            if let playing = media.category.playing {
                mediaPlayer.mediaItem = media.repository.index[playing]
            } else {
                mediaPlayer.mediaItem = nil
            }

            if let historyArray = defaults.array(forKey: Constants.SETTINGS.HISTORY) {
//                history = historyArray as? [String]
                media.history.list.update(storage: historyArray as? [String])
            }
        } else {
            //This is where we should map the old version on to the new one and preserve the user's information.
            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
            defaults.synchronize()
        }
    }
    
//    func cancelAllDownloads()
//    {
//        guard let list = mediaRepository.list else {
//            return
//        }
//
//        for mediaItem in list {
//            for download in mediaItem.downloads.values {
//                if download.active {
//                    download.task?.cancel()
//                    download.task = nil
//
//                    download.totalBytesWritten = 0
//                    download.totalBytesExpectedToWrite = 0
//
//                    download.state = .none
//                }
//            }
//        }
//    }

//    func totalCacheSize() -> Int
//    {
//        return cacheSize(Purpose.audio) + cacheSize(Purpose.video) + cacheSize(Purpose.notes) + cacheSize(Purpose.slides)
//    }
//    
//    func cacheSize(_ purpose:String) -> Int
//    {
//        guard let list = mediaRepository.list else {
//            return 0
//        }
//        
//        var totalFileSize = 0
//        
//        for mediaItem in list {
//            if let download = mediaItem.downloads[purpose], download.isDownloaded {
//                totalFileSize += download.fileSize
//            }
//        }
//
//        return totalFileSize
//    }

    func motionEnded(_ motion: UIEvent.EventSubtype, event: UIEvent?)
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
        
        Thread.onMain {
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

extension Globals : AVPlayerViewControllerDelegate
{
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
        NSLog("failedToStartPictureInPictureWithError \(error.localizedDescription)")
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
}
