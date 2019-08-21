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
 
    var newAPI = false
    
    var _searchHistory:[String]?
    {
        didSet {
            guard _searchHistory?.isEmpty == false else {
                UserDefaults.standard.removeObject(forKey: "Search History")
                return
            }
            
            UserDefaults.standard.set(_searchHistory, forKey: "Search History")
        }
    }
    var searchHistory:[String]?
    {
        get {
            if _searchHistory == nil {
                _searchHistory = UserDefaults.standard.array(forKey: "Search History") as? [String]
            }
            
            if _searchHistory == nil {
                _searchHistory = [String]()
            }
            
            return _searchHistory
        }
        set {
            _searchHistory = newValue
        }
    }

    var streamEntry:StreamEntry?
    {
        get {
            return StreamEntry(UserDefaults.standard.object(forKey: Constants.SETTINGS.LIVE) as? [String:Any])
        }
    }
    
    var streaming:Streaming?
    {
        get {
            return Streaming(streamEntry?["streaming"] as? [String:Any])
        }
    }
    
    var streamingURL:URL?
    {
        get {
            return ((streaming?["files"] as? [String:Any])?["video"] as? String)?.url
        }
    }
    
    var settings = Settings()

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
    
//    // flag whether machine generated transcripts are allowed
//    var allowMGTs = true
//
//    // Timer to keep checking on whether VoiceBase is available
//    var checkVoiceBaseTimer : Timer?
//
//    // Shadow property for voicebase availability.
//    private var _isVoiceBaseAvailable : Bool? // = false
//    {
//        didSet {
//            guard _isVoiceBaseAvailable != oldValue else {
//                return
//            }
//
//            guard let _isVoiceBaseAvailable = _isVoiceBaseAvailable else {
//                return
//            }
//
//            if !_isVoiceBaseAvailable {
//                if checkVoiceBaseTimer == nil {
//                    checkVoiceBaseTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.ckVBA), userInfo:nil, repeats:true)
//                }
//            } else {
//                checkVoiceBaseTimer?.invalidate()
//                checkVoiceBaseTimer = nil
//            }
//
//            // Why?
//            Thread.onMain { [weak self] in 
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
//            }
//        }
//    }
//    var isVoiceBaseAvailable : Bool? // = false
//    {
//        get {
//            guard allowMGTs else {
//                return false
//            }
//
//            guard reachability.isReachable else {
//                return false
//            }
//
//            return _isVoiceBaseAvailable ?? false // checkingVoiceBaseAvailability
//        }
//        set {
//            _isVoiceBaseAvailable = newValue
//        }
//    }
//
//    // This is critical since we make a VB call to see if VB is available so we need to ignore the isVBAvailable nil or false
//    var checkingVoiceBaseAvailability = false
//    
//    func checkVoiceBaseAvailability(completion:(()->(Void))? = nil)
//    {
//        isVoiceBaseAvailable = nil
//
//        guard reachability.isReachable else {
//            isVoiceBaseAvailable = false
//            completion?()
//            return
//        }
//        
//        // Tell the world we are checking
//        checkingVoiceBaseAvailability = true
//        
//        VoiceBase.all(completion: { [weak self] (json:[String : Any]?) -> (Void) in
//            self?.isVoiceBaseAvailable = true
//            completion?()
//        }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
//            self?.isVoiceBaseAvailable = false
//            completion?()
//        })
//        
//        // Tell the world we are done checking
//        checkingVoiceBaseAvailability = false
//    }
//    
//    @objc func ckVBA()
//    {
//        checkVoiceBaseAvailability()
//    }
//
//    private var _voiceBaseAPIKey : String?
//    {
//        didSet {
//            if let key = _voiceBaseAPIKey, !key.isEmpty {
//                UserDefaults.standard.set(key, forKey: Constants.Strings.VoiceBase_API_Key)
//
//                // Do we need to notify VoiceBase objects?
//                // No, because if it was nil before there shouldn't be anything on VB.com
//                // No, because if it was not nil before then they either the new KEY is good or bad.
//                // If bad, then it will fail.  If good, then they will finish.
//                // So, nothing needs to be done.
//            } else {
//                isVoiceBaseAvailable = false
//                UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
//            }
//            
//            UserDefaults.standard.synchronize()
//            
//            if isVoiceBaseAvailable == true {
//                checkVoiceBaseAvailability()
//            }
//        }
//    }
//    var voiceBaseAPIKey : String?
//    {
//        get {
//            if _voiceBaseAPIKey == nil {
//                if let key = UserDefaults.standard.string(forKey: Constants.Strings.VoiceBase_API_Key), !key.isEmpty {
//                    if key == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE" {
//                        UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
//                    } else {
//                        _voiceBaseAPIKey = key
//                    }
//                }
//            }
//            
//            #if targetEnvironment(simulator)
//            // Simulator
//            return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE"
//            #else
//            // Device
//            if UIDevice.current.name.contains("Leeke-") {
//                return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE"
//            }
//            #endif
//            
//            return _voiceBaseAPIKey
//        }
//        set {
//            _voiceBaseAPIKey = newValue
//        }
//    }

//    private var _voiceBaseAPIKey : String?
//    {
//        didSet {
//            checkVoiceBaseAvailability()
//        }
//    }
//    var voiceBaseAPIKey : String?
//    {
//        get {
//            if let key = UserDefaults.standard.string(forKey: Constants.Strings.VoiceBase_API_Key) {
//                if key.isEmpty {
//                    return nil
//                }
//
//                return key
//            } else {
//                return nil
//            }
//        }
//        set {
//            if let key = newValue {
//                if !key.isEmpty {
//                    UserDefaults.standard.set(newValue, forKey: Constants.Strings.VoiceBase_API_Key)
//                } else {
//                    isVoiceBaseAvailable = false
//                    UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
//                }
//
//                // Do we need to notify VoiceBase objects?
//                // No, because if it was nil before there shouldn't be anything on VB.com
//                // No, because if it was not nil before then they either the new KEY is good or bad.
//                // If bad, then it will fail.  If good, then they will finish.
//                // So, nothing needs to be done.
//            } else {
//                isVoiceBaseAvailable = false
//                UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
//            }
//
//            UserDefaults.standard.synchronize()
//
//            _voiceBaseAPIKey = newValue
//        }
//    }
    
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

            VoiceBase.checkAvailability()
//            media.stream.loadLive(completion: nil)
        }
        
        // Don't include the list because we want to be warned at th start that there is no network connection
        if priorReachabilityStatus != .notReachable, !reachability.isReachable { // , mediaRepository.list != nil
            let title = "No Network Connection"
            var message = "Without a network connection only media previously downloaded will be available."
            
            if reachability.isOnWWANFlagSet {
                message += "\n\n"
                message += "Cellular data appears to be turned off."
            }

            Alerts.shared.alert(title: title,message: message)

            VoiceBase.isAvailable = false
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
            
            Thread.onMain { [weak self] in 
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMain { [weak self] in 
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
//    var groupings = Constants.groupings
//    var groupingTitles = Constants.GroupingTitles
    
    var _grouping:String?
    {
        willSet {
            
        }
        didSet {
            let defaults = UserDefaults.standard
            if (_grouping != nil) {
                defaults.set(_grouping,forKey: Constants.SETTINGS.GROUPING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.GROUPING)
            }
            defaults.synchronize()
        }
    }
    var grouping:String? // = GROUPING.YEAR
    {
        get {
            if _grouping == nil {
                if let groupingString = UserDefaults.standard.string(forKey: Constants.SETTINGS.GROUPING), !groupingString.isEmpty {
                    _grouping = groupingString
                } else {
                    _grouping = GROUPING.YEAR
                }
            }
            
            return _grouping
        }        
        set {
            _grouping = newValue
        }
    }

    var _sorting:String?
    {
        willSet {
            
        }
        didSet {
            let defaults = UserDefaults.standard
            if (_sorting != nil) {
                defaults.set(_sorting,forKey: Constants.SETTINGS.SORTING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.SORTING)
            }
            defaults.synchronize()
        }
    }
    var sorting:String? // = SORTING.REVERSE_CHRONOLOGICAL
    {
        get {
            if _sorting == nil {
                if let sortingString = UserDefaults.standard.string(forKey: Constants.SETTINGS.SORTING), !sortingString.isEmpty {
                    _sorting = sortingString
                } else {
                    _sorting = SORTING.REVERSE_CHRONOLOGICAL
                }
            }
            
            return _sorting
        }
        set {
            _sorting = newValue
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////

//    /////////////////////////////////////////////////////////////////////////////////////
//    // Would like to group these settings
//    /////////////////////////////////////////////////////////////////////////////////////
//    var autoAdvance:Bool
//    {
//        get {
//            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.AUTO_ADVANCE)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.AUTO_ADVANCE)
//            UserDefaults.standard.synchronize()
//        }
//    }
//    
//    var cacheDownloads:Bool
//    {
//        get {
//            if UserDefaults.standard.object(forKey: Constants.SETTINGS.CACHE_DOWNLOADS) == nil {
//                if #available(iOS 9.0, *) {
//                    UserDefaults.standard.set(true, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
//                } else {
//                    UserDefaults.standard.set(false, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
//                }
//            }
//            
//            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
//            UserDefaults.standard.synchronize()
//        }
//    }
//    /////////////////////////////////////////////////////////////////////////////////////

    var isRefreshing:Bool   = false
    var isLoading:Bool      = false
    
    var contextTitle:String?
    {
        get {
            guard let mediaCategory = media.category.selected, !mediaCategory.isEmpty else {
                return nil
            }
            
            var string = mediaCategory // Category:
                
            if let tag = media.tags.selected, !tag.isEmpty {
                string += ", " + tag  // Collection:
            }
            
            if media.search.isValid, let search = media.search.text, !search.isEmpty {
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

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TRIED TO DO THIS W/IN MediaPlayer class and could not get it to work.
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReset(_:)),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: nil)
    }
    
    @objc func handleReset(_ notification: Notification)
    {
        mediaPlayer.reload()
    }
    
    @objc func handleInterruption(_ notification:Notification)
    {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            mediaPlayer.pause()
            break
            
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                    mediaPlayer.play()
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
            break
            
        @unknown default:
            break
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    var mediaPlayerInit = true
    lazy var mediaPlayer:MediaPlayer! = {
        let player = MediaPlayer()

        addNotifications()

        if let playing = media.category.playing, !playing.isEmpty {
            // This ONLY works if media.repository.index is loaded before this is instantiated.
            player.mediaItem = media.repository.index[playing]
        } else {
            player.mediaItem = nil
        }

        mediaPlayerInit = false
        return player
    }()
    
    ////////////////////////////////////////////////////////////////////////////
    // SETTINGS
    ////////////////////////////////////////////////////////////////////////////
    lazy var multiPartSettings : ThreadSafeDN<String>! = // [String:[String:String]]? // ictionaryOfDictionaries
        {
            let multiPartSettings = ThreadSafeDN<String>(name: "MULTIPARTSETTINGS")
            
            if let multiPartSettingsDictionary = UserDefaults.standard.dictionary(forKey: Constants.SETTINGS.MULTI_PART_MEDIA) {
                multiPartSettings.update(storage: multiPartSettingsDictionary)
            }
            
            return multiPartSettings
    }()

    lazy var mediaItemSettings : ThreadSafeDN<String>! = // [String:[String:String]]? // ictionaryOfDictionaries
        {
            let mediaItemSettings = ThreadSafeDN<String>(name: "MEDIAITEMSETTINGS")
            
            if let mediaItemSettingsDictionary = UserDefaults.standard.dictionary(forKey: Constants.SETTINGS.MEDIA) {
                mediaItemSettings.update(storage: mediaItemSettingsDictionary)
            }
            
            return mediaItemSettings
    }()
    
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
    ////////////////////////////////////////////////////////////////////////////
   
    lazy var mediaQueue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()

    lazy var _media : Media? = {
        let media = Media()
        
        media.search.text = UserDefaults.standard.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
        media.search.isActive = !(media.search.text?.isEmpty ?? true)
        
        return media
    }()
    
    var media : Media!
    {
        get {
            return mediaQueue.sync {
                return _media
            }
        }
        set {
            mediaQueue.sync {
                _media = newValue
            }
        }
    }
    
    func freeMemory()
    {
        // Free memory in classes
        Thread.onMain { [weak self] in 
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
    
//    func loadSettings()
//    {
//        let defaults = UserDefaults.standard
//
//        guard let settingsVersion = defaults.string(forKey: Constants.SETTINGS.VERSION.KEY) else {
//            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
//            clearSettings()
//            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
//            defaults.synchronize()
//            return
//        }
//
//        if (media.tags.selected == Constants.Strings.New) {
//            media.tags.selected = nil
//        }
//
////        media.search.text = defaults.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
////        media.search.isActive = media.search.text != nil
//
////        if let playing = media.category.playing {
////            mediaPlayer.mediaItem = media.repository.index[playing]
////        } else {
////            mediaPlayer.mediaItem = nil
////        }
//
//        if settingsVersion == Constants.SETTINGS.VERSION.NUMBER {
////            if let mediaItemSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.MEDIA) {
////                mediaItemSettings.update(storage: mediaItemSettingsDictionary)
////            }
////
////            if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.MULTI_PART_MEDIA) {
////                multiPartSettings.update(storage: seriesSettingsDictionary)
////            }
////
////            if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.CATEGORY) {
////                media.category.settings.update(storage: categorySettingsDictionary)
////            }
//
////            if let sortingString = defaults.string(forKey: Constants.SETTINGS.SORTING) {
////                sorting = sortingString
////            } else {
////                sorting = SORTING.REVERSE_CHRONOLOGICAL
////            }
//
////            if let groupingString = defaults.string(forKey: Constants.SETTINGS.GROUPING) {
////                grouping = groupingString
////            } else {
////                grouping = GROUPING.YEAR
////            }
//
//            //
//
////            if let historyArray = defaults.array(forKey: Constants.SETTINGS.HISTORY) {
//////                history = historyArray as? [String]
////                media.history.list.update(storage: historyArray as? [String])
////            }
//        } else {
//            //This is where we should map the old version on to the new one and preserve the user's information.
//            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
//            defaults.synchronize()
//        }
//    }
    
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
//            if let download = mediaItem.downloads?[purpose], download.isDownloaded {
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
        
        Thread.onMain { [weak self] in 
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
            if let timeElapsed = Globals.shared.mediaPlayer.stateTime?.timeElapsed {
                if timeElapsed < 0.5 { // 1.0
                    print("STOP HITTING THE PLAY PAUSE BUTTON SO QUICKLY!")
                    return MPRemoteCommandHandlerStatus.commandFailed
                }
            }
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
                    return MPRemoteCommandHandlerStatus.success
                } else {
                    return MPRemoteCommandHandlerStatus.commandFailed
                }
            })
        } else {
            // Fallback on earlier versions
        }
        
//        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().seekForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("seekForwardCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().seekBackwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("seekBackwardCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("previousTrackCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("nextTrackCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().changePlaybackRateCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().changePlaybackRateCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("changePlaybackRateCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().ratingCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().ratingCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("ratingCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().likeCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().likeCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("likeCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().dislikeCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().dislikeCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("dislikeCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
//
//        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = true
//        MPRemoteCommandCenter.shared().bookmarkCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            print("bookmarkCommand")
//
//            return MPRemoteCommandHandlerStatus.success
//        })
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
