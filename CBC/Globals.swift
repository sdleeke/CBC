//
//  Globals.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

extension UIBarButtonItem {
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UISegmentedControl {
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UIButton {
    func setTitle(_ string:String?)
    {
        setTitle(string, for: UIControlState.normal)
        setTitle(string, for: UIControlState.disabled)
        setTitle(string, for: UIControlState.selected)
    }
}

extension Thread {
    static func onMainThread(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                block?()
            })
        }
    }
}

extension UIViewController {
    func setDVCLeftBarButton()
    {
        // MUST be called from the detail view ONLY
        if let isCollapsed = splitViewController?.isCollapsed {
            if isCollapsed {
                navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.navigationController?.navigationItem.backBarButtonItem
            } else {
                navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            }
        }
    }
}

struct Alert {
    let category : String?
    let title : String
    let message : String?
    let attributedText : NSAttributedString?
    let actions : [AlertAction]?
}

class StreamEntry {
    init?(_ dict:[String:Any]?)
    {
        guard dict != nil else {
            return nil
        }
        
        self.dict = dict
    }
    
    var dict : [String:Any]?
    
    var id : Int? {
        get {
            return dict?["id"] as? Int
        }
    }
    
    var start : Int? {
        get {
            return dict?["start"] as? Int
        }
    }
    
    var startDate : Date? {
        get {
            if let start = start {
                return Date(timeIntervalSince1970: TimeInterval(start))
            } else {
                return nil
            }
        }
    }
    
    var end : Int? {
        get {
            return dict?["end"] as? Int
        }
    }
    
    var endDate : Date? {
        get {
            if let end = end {
                return Date(timeIntervalSince1970: TimeInterval(end))
            } else {
                return nil
            }
        }
    }
    
    var name : String? {
        get {
            return dict?["name"] as? String
        }
    }
    
    var date : String? {
        get {
            return dict?["date"] as? String
        }
    }
    
    var text : String? {
        get {
            if let name = name, let start = startDate?.mdyhm, let end = endDate?.mdyhm {
                return "\(name)\nStart: \(start)\nEnd: \(end)"
            } else {
                return nil
            }
        }
    }
}

var globals:Globals!

class Globals : NSObject, AVPlayerViewControllerDelegate
{
    var queue = DispatchQueue(label: "CBC")
    
    var allowMGTs : Bool
    {
        get {
            return isVoiceBaseAvailable ?? false
        }
    }
    
    var isVoiceBaseAvailable : Bool? // = false
    {
        didSet {
            guard isVoiceBaseAvailable != oldValue else {
                return
            }
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
            }
        }
    }
    
    func checkVoiceBaseAvailability()
    {
        VoiceBase.all(completion: { (json:[String : Any]?) -> (Void) in
            self.isVoiceBaseAvailable = true
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.isVoiceBaseAvailable = false
        })
    }
    
    var voiceBaseAPIKey : String? {
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
            isVoiceBaseAvailable = nil
            checkVoiceBaseAvailability()
        }
    }
    
    var splitViewController:UISplitViewController!
    
    func alertViewer()
    {
        for alert in alerts {
            print(alert)
        }

        guard UIApplication.shared.applicationState == UIApplicationState.active else {
            return
        }
        
        if let alert = alerts.first {
            let alertVC = UIAlertController(title:alert.title,
                                          message:alert.message,
                                          preferredStyle: .alert)
            alertVC.makeOpaque()
            
            if let attributedText = alert.attributedText {
                alertVC.addTextField(configurationHandler: { (textField:UITextField) in
                    textField.isUserInteractionEnabled = false
                    textField.textAlignment = .center
                    textField.attributedText = attributedText
                    textField.adjustsFontSizeToFitWidth = true
                })
            }
            
            if let alertActions = alert.actions {
                for alertAction in alertActions {
                    let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                        alertAction.action?()
                    })
                    alertVC.addAction(action)
                }
            } else {
                let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alertVC.addAction(action)
            }
            
            Thread.onMainThread() {
                self.splitViewController.present(alertVC, animated: true, completion: {
                    if self.alerts.count > 0 {
                        self.alerts.remove(at: 0)
                    }
                })
            }
        }
    }

    var alerts = [Alert]()
    
    var alertTimer : Timer?
    
    func alert(title:String,message:String?)
    {
        if !alerts.contains(where: { (alert:Alert) -> Bool in
            return (alert.title == title) && (alert.message == message)
        }) {
            alerts.append(Alert(category: nil, title: title, message: message, attributedText: nil, actions: nil))
        } else {
            // This is happening - how?
            print("DUPLICATE ALERT")
        }
    }
    
    func alert(category:String?,title:String,message:String?,attributedText:NSAttributedString?,actions:[AlertAction]?)
    {
        alerts.append(Alert(category:category,title: title, message: nil, attributedText: attributedText, actions: actions))
    }
    
    func alert(title:String,message:String?,actions:[AlertAction]?)
    {
        alerts.append(Alert(category:nil,title: title, message: message, attributedText: nil, actions: actions))
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
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        print("playerViewControllerWillStopPictureInPicture")
        mediaPlayer.stoppingPIP = true
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        print("playerViewControllerDidStopPictureInPicture")
        mediaPlayer.pip = .stopped
        mediaPlayer.stoppingPIP = false
    }

    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        print("playerViewControllerWillStartPictureInPicture")
        mediaPlayer.startingPIP = true
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        print("playerViewControllerDidStartPictureInPicture")
        mediaPlayer.pip = .started
        mediaPlayer.startingPIP = false
    }
    
    var loadSingles = true
    
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
        
        if priorReachabilityStatus == .notReachable, reachability.isReachable, globals.mediaRepository.list != nil {
            alert(title: "Network Connection Restored",message: "")

            isVoiceBaseAvailable = nil

            checkVoiceBaseAvailability()
        }
        
        if priorReachabilityStatus != .notReachable, !reachability.isReachable, globals.mediaRepository.list != nil {
            alert(title: "No Network Connection",message: "Without a network connection only audio, slides, and transcripts previously downloaded will be available.")
            
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
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            Thread.onMainThread() {
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
    
    var grouping:String? = GROUPING.YEAR {
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
    
    var sorting:String? = SORTING.REVERSE_CHRONOLOGICAL {
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
    
    var autoAdvance:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool {
        get {
//            print(UserDefaults.standard.object(forKey: Constants.SETTINGS.CACHE_DOWNLOADS))

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
    
    class Search {
        weak var globals:Globals!
        
        var complete:Bool = true
        
        var active:Bool = false {
            willSet {
                
            }
            didSet {
                if !active {
                    complete = true
                }
            }
        }
        
        var valid:Bool {
            get {
                return active && extant
            }
        }
        
        var extant:Bool {
            get {
                // Same result, just harder to read and understand quickly
//                return !(text?.isEmpty ?? false)
                
                if let isEmpty = text?.isEmpty {
                    return !isEmpty
                } else {
                    return false
                }
            }
        }
        
        var text:String? {
            willSet {
                
            }
            didSet {
                guard text != oldValue else {
                    return
                }
                
                guard !globals.isLoading else {
                    return
                }
                
                if extant {
                    UserDefaults.standard.set(text, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
        
        var transcripts:Bool {
            get {
                return UserDefaults.standard.bool(forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
            }
            set {
                // Setting to nil can cause a crash.
                globals.media.toSearch?.searches = [String:MediaListGroupSort]()
                
                UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    lazy var search:Search! = {
        [unowned self] in
        var search = Search()
        search.globals = self
        return search
    }()
    
    var contextTitle:String? {
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
    
    func context() -> String? {
        return contextString
    }
    
    func searchText() -> String? {
        return search.text
    }
    
    var contextString:String? {
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

    func contextOrder() -> String? {
        var string:String?
        
        if let context = contextString {
            string = ((string != nil) ? string! + ":" : "") + context
        }
        
        if let order = orderString {
            string = ((string != nil) ? string! + ":" : "") + order
        }
        
        return string
    }

    var orderString:String? {
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
    
//    var gotoPlayingPaused:Bool = false

    var mediaPlayer = MediaPlayer()

    class SelectedMediaItem {
        weak var globals:Globals!
        
        var master:MediaItem? {
            get {
                var selectedMediaItem:MediaItem?
                
                if let selectedMediaItemID = globals.mediaCategory.selectedInMaster {
                    selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
                }
                
                return selectedMediaItem
            }
            
            set {
                globals.mediaCategory.selectedInMaster = newValue?.id
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
            
            set {
                globals.mediaCategory.selectedInDetail = newValue?.id
            }
        }
    }
    
    lazy var selectedMediaItem:SelectedMediaItem! = {
        [unowned self] in
        let selectedMediaItem = SelectedMediaItem()
        selectedMediaItem.globals = self
        return selectedMediaItem
    }()

    class MediaCategory {
        var dicts:[String:String]?
        
        var filename:String? {
            get {
                guard let selectedID = selectedID else {
                    return nil
                }
                
                return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID +  Constants.JSON.FILENAME_EXTENSION
            }
        }
        
        var url:String? {
            get {
                guard let selectedID = selectedID else {
                    return nil
                }
                
                return Constants.JSON.URL.CATEGORY + selectedID // CATEGORY + selectedID!
            }
        }
        
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
                    UserDefaults.standard.set(Constants.Strings.Sermons, forKey: Constants.MEDIA_CATEGORY)
                }
                
                return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
            }
            set {
                if newValue != nil {
                    UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.MEDIA_CATEGORY)
                }
                
                UserDefaults.standard.synchronize()
            }
        }
        
        var selectedID:String? {
            get {
                if let selected = selected {
                    return dicts?[selected] ?? "1" // Sermons are category 1
                } else {
                    return nil
                }
            }
        }
        
        var settings:[String:[String:String]]?
        
        var allowSaveSettings = true
        
        func saveSettingsBackground()
        {
            if allowSaveSettings {
                print("saveSettingsBackground")
                
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.saveSettings()
                }
            }
        }
        
        func saveSettings()
        {
            if allowSaveSettings {
                print("saveSettings")
                let defaults = UserDefaults.standard
                defaults.set(settings, forKey: Constants.SETTINGS.CATEGORY)
                defaults.synchronize()
            }
        }
        
        subscript(key:String) -> String? {
            get {
                if let selected = selected {
                    return settings?[selected]?[key]
                } else {
                    return nil
                }
            }
            set {
                guard let selected = selected else {
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
                
                if (settings?[selected] == nil) {
                    settings?[selected] = [String:String]()
                }
                if (settings?[selected]?[key] != newValue) {
                    settings?[selected]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    saveSettingsBackground()
                }
            }
        }
        
        var tag:String? {
            get {
                return self[Constants.SETTINGS.COLLECTION]
            }
            set {
                self[Constants.SETTINGS.COLLECTION] = newValue
            }
        }
        
        var playing:String? {
            get {
                return self[Constants.SETTINGS.MEDIA_PLAYING]
            }
            set {
                self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
            }
        }
        
        var selectedInMaster:String? {
            get {
                return self[Constants.SETTINGS.SELECTED_MEDIA.MASTER]
            }
            set {
                self[Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue
            }
        }
        
        var selectedInDetail:String? {
            get {
                return self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL]
            }
            set {
                self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL] = newValue
            }
        }
    }
    
    var mediaCategory = MediaCategory()
    
    var streamEntries:[[String:Any]]?
    
    var streamStrings:[String]?
    {
        get {
            return streamEntries?.filter({ (dict:[String : Any]) -> Bool in
                return StreamEntry(dict)?.startDate > Date()
            }).map({ (dict:[String : Any]) -> String in
                if let string = StreamEntry(dict)?.text {
                    return string
                } else {
                    return "ERROR"
                }
            })
        }
    }
    
    var streamStringIndex:[String:[String]]?
    {
        get {
            var streamStringIndex = [String:[String]]()
            
            let now = Date().addHours(1) // for ease of testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start, let text = streamEntry?.text {
                        // All streaming to start 5 minutes before the scheduled start time
                        if ((now.timeIntervalSince1970 + 5*60) >= Double(start)) && (now <= streamEntry?.endDate) {
                            if streamStringIndex[Constants.Strings.Playing] == nil {
                                streamStringIndex[Constants.Strings.Playing] = [String]()
                            }
                            streamStringIndex[Constants.Strings.Playing]?.append(text)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamStringIndex[Constants.Strings.Upcoming] == nil {
                                    streamStringIndex[Constants.Strings.Upcoming] = [String]()
                                }
                                streamStringIndex[Constants.Strings.Upcoming]?.append(text)
                            }
                        }
                    }
                }
                
                if streamStringIndex[Constants.Strings.Playing]?.count == 0 {
                    streamStringIndex[Constants.Strings.Playing] = nil
                }
                
                return streamStringIndex.count > 0 ? streamStringIndex : nil
            } else {
                return nil
            }
        }
    }
    
    var streamEntryIndex:[String:[[String:Any]]]?
    {
        get {
            var streamEntryIndex = [String:[[String:Any]]]()
            
            let now = Date().addHours(1) // for ease of testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start {
                        // All streaming to start 5 minutes before the scheduled start time
                        if ((now.timeIntervalSince1970 + 5*60) >= Double(start)) && (now <= streamEntry?.endDate) {
                            if streamEntryIndex[Constants.Strings.Playing] == nil {
                                streamEntryIndex[Constants.Strings.Playing] = [[String:Any]]()
                            }
                            streamEntryIndex[Constants.Strings.Playing]?.append(event)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamEntryIndex[Constants.Strings.Upcoming] == nil {
                                    streamEntryIndex[Constants.Strings.Upcoming] = [[String:Any]]()
                                }
                                streamEntryIndex[Constants.Strings.Upcoming]?.append(event)
                            }
                        }
                    }
                }
                
                if streamEntryIndex[Constants.Strings.Playing]?.count == 0 {
                    streamEntryIndex[Constants.Strings.Playing] = nil
                }
                
                return streamEntryIndex.count > 0 ? streamEntryIndex : nil
            } else {
                return nil
            }
        }
    }
    
    var streamSorted:[[String:Any]]?
    {
        get {
            return streamEntries?.sorted(by: { (firstDict: [String : Any], secondDict: [String : Any]) -> Bool in
                return StreamEntry(firstDict)?.startDate <= StreamEntry(secondDict)?.startDate
            })
        }
    }
    
    var streamCategories:[String:[[String:Any]]]?
    {
        get {
            var streamCategories = [String:[[String:Any]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let name = StreamEntry(streamEntry)?.name {
                        if streamCategories[name] == nil {
                            streamCategories[name] = [[String:Any]]()
                        }
                        streamCategories[name]?.append(streamEntry)
                    }
                }
                
                return streamCategories.count > 0 ? streamCategories : nil
            } else {
                return nil
            }
        }
    }
                       // Year // Month // Day // Event
    var streamSchedule:[String:[String:[String:[[String:Any]]]]]?
    {
        get {
            var streamSchedule = [String:[String:[String:[[String:Any]]]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let startDate = StreamEntry(streamEntry)?.startDate {
                        if streamSchedule[startDate.year] == nil {
                            streamSchedule[startDate.year] = [String:[String:[[String:Any]]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month] == nil {
                            streamSchedule[startDate.year]?[startDate.month] = [String:[[String:Any]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month]?[startDate.day] == nil {
                            streamSchedule[startDate.year]?[startDate.month]?[startDate.day] = [[String:Any]]()
                        }
                        streamSchedule[startDate.year]?[startDate.month]?[startDate.day]?.append(streamEntry)
                    }
                }
                
                return streamSchedule.count > 0 ? streamSchedule : nil
            } else {
                return nil
            }
        }
    }
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    var multiPartSettings:[String:[String:String]]?
    var mediaItemSettings:[String:[String:String]]?
    
    var history:[String]?
    
    var relevantHistory:[String]? {
        get {
            guard let index = mediaRepository.index else {
                return nil
            }
            
            return history?.reversed().filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.TAGS_SEPARATOR) {
                    let mediaItemID = string.substring(from: range.upperBound)
                    return index[mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    var relevantHistoryList:[String]? {
        get {
            return relevantHistory?.map({ (string:String) -> String in
                if  let range = string.range(of: Constants.TAGS_SEPARATOR),
                    let mediaItem = mediaRepository.index?[string.substring(from: range.upperBound)],
                    let text = mediaItem.text {
                    return text
                }

                return ("ERROR")
            })
        }
    }

    class MediaRepository {
        weak var globals:Globals!
        
        var list:[MediaItem]? { //Not in any specific order
            willSet {
                
            }
            didSet {
                guard let list = list else {
                    return
                }
                
                index = nil
                classes = nil
                events = nil
                
                for mediaItem in list {
                    if let id = mediaItem.id {
                        if index == nil {
                            index = [String:MediaItem]()
                        }
                        if index?[id] == nil {
                            index?[id] = mediaItem
                        } else {
                            print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                        }
                    }
                    
                    if mediaItem.hasClassName, let className = mediaItem.className {
                        if classes == nil {
                            classes = [className]
                        } else {
                            classes?.append(className)
                        }
                    }
                    
                    if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                        if events == nil {
                            events = [eventName]
                        } else {
                            events?.append(eventName)
                        }
                    }
                }
                
                globals.groupings = Constants.groupings
                globals.groupingTitles = Constants.GroupingTitles
                
                if classes?.count > 0 {
                    globals.groupings.append(GROUPING.CLASS)
                    globals.groupingTitles.append(Grouping.Class)
                }
                
                if events?.count > 0 {
                    globals.groupings.append(GROUPING.EVENT)
                    globals.groupingTitles.append(Grouping.Event)
                }
                
                if let grouping = globals.grouping, !globals.groupings.contains(grouping) {
                    globals.grouping = GROUPING.YEAR
                }
            }
        }
        
        var index:[String:MediaItem]?
        var classes:[String]?
        var events:[String]?
    }
    
    lazy var mediaRepository:MediaRepository! = {
        [unowned self] in
        let mediaRepository = MediaRepository()
        mediaRepository.globals = self
        return mediaRepository
    }()

    // Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
    // Problems went away when I switched to class
    
    class Media {
        weak var globals:Globals!
        
        struct MediaNeed
        {
            var sorting:Bool = true
            var grouping:Bool = true
        }
        
        var need = MediaNeed()
        
        //All mediaItems
        var all:MediaListGroupSort?
        
        //The mediaItems with the selected tags, although now we only support one tag being selected
        var tagged = [String:MediaListGroupSort]()
        
        // Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
        // Problems went away when I switched to class
        class Tags {
            weak var globals:Globals!
            
            var showing:String? {
                get {
                    return selected == nil ? Constants.ALL : Constants.TAGGED
                }
            }
            
            var selected:String? {
                get {
                    return globals.mediaCategory.tag
                }
                set {
                    if let newValue = newValue {
                        if (globals.media.tagged[newValue] == nil) {
                            if globals.media.all == nil {
                                //This is filtering, i.e. searching all mediaItems => s/b in background
                                globals.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(globals.mediaRepository.list, tag: newValue))
                            } else {
                                if let key = stringWithoutPrefixes(newValue), let mediaItems = globals.media.all?.tagMediaItems?[key] {
                                    globals.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItems)
                                }
                            }
                        }
                    } else {
                        
                    }
                    
                    globals.mediaCategory.tag = newValue
                }
            }
        }
        
        lazy var tags:Tags! = {
            [unowned self] in
            var tags = Tags()
            tags.globals = self.globals
            return tags
        }()
        
        var toSearch:MediaListGroupSort? {
            get {
                var mediaItems:MediaListGroupSort?

                if let showing = tags.showing {
                    switch showing {
                    case Constants.TAGGED:
                        if let selected = tags.selected {
                            mediaItems = tagged[selected]
                        }
                        break
                        
                    case Constants.ALL:
                        mediaItems = all
                        break
                        
                    default:
                        break
                    }
                }
                
                return mediaItems
            }
        }
        
        var active:MediaListGroupSort? {
            get {
                var mediaItems:MediaListGroupSort?
                
                if let showing = tags.showing {
                    switch showing {
                    case Constants.TAGGED:
                        if let selected = tags.selected {
                            mediaItems = tagged[selected]
                        }
                        break
                        
                    case Constants.ALL:
                        mediaItems = all
                        break
                        
                    default:
                        break
                    }
                }
                
                if globals.search.active {
                    if let searchText = globals.search.text?.uppercased() {
                        mediaItems = mediaItems?.searches?[searchText] 
                    }
                }
                
                return mediaItems
            }
        }
    }
    
    lazy var media:Media! = {
        [unowned self] in
        var media = Media()
        media.globals = self
        return media
    }()
    
    class Display {
        var mediaItems:[MediaItem]?
        var section = Section()
    }
    
    var display = Display()
    
    func freeMemory()
    {
        // Free memory in classes
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }

        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearDisplay()
    {
        display.mediaItems = nil

        display.section.headerStrings = nil
        display.section.indexStrings = nil
        display.section.indexes = nil
        display.section.counts = nil
    }
    
    func setupDisplay(_ active:MediaListGroupSort?)
    {
//        print("setupDisplay")

        display.mediaItems = active?.mediaItems
        
        display.section.showHeaders = true
        
        display.section.headerStrings = active?.section?.headerStrings
        display.section.indexStrings = active?.section?.indexStrings
        display.section.indexes = active?.section?.indexes
        display.section.counts = active?.section?.counts
    }
    
    func saveSettingsBackground()
    {
        guard allowSaveSettings else {
            return
        }

        print("saveSettingsBackground")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.saveSettings()
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
        defaults.set(mediaItemSettings,forKey: Constants.SETTINGS.MEDIA)
        //    print("\(seriesViewSplits)")
        defaults.set(multiPartSettings, forKey: Constants.SETTINGS.MULTI_PART_MEDIA)
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
                //        print("\(settingsDictionary)")
                mediaItemSettings = mediaItemSettingsDictionary as? [String:[String:String]]
            }
            
            if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.MULTI_PART_MEDIA) {
                //        print("\(viewSplitsDictionary)")
                multiPartSettings = seriesSettingsDictionary as? [String:[String:String]]
            }
            
            if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.CATEGORY) {
                //        print("\(viewSplitsDictionary)")
                mediaCategory.settings = categorySettingsDictionary as? [String:[String:String]]
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
            
//                media.tags.selected = mediaCategory.tag

            if (media.tags.selected == Constants.Strings.New) {
                media.tags.selected = nil
            }

            if media.tags.showing == Constants.TAGGED, let tag = mediaCategory.tag, media.tagged[tag] == nil {
                if media.all == nil {
                    //This is filtering, i.e. searching all mediaItems => s/b in background
                    media.tagged[tag] = MediaListGroupSort(mediaItems: mediaItemsWithTag(mediaRepository.list, tag: media.tags.selected))
                } else {
                    if let tagSelected = media.tags.selected, let sortTag = stringWithoutPrefixes(tagSelected) {
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
        
        //    print("\(settings)")
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
    
    func addToHistory(_ mediaItem:MediaItem?)
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
        
        Thread.onMainThread() {
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

