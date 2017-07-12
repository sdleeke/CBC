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

extension UIViewController {
    func setDVCLeftBarButton()
    {
        // MUST be called from the detail view ONLY
        if  //let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
            //let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
            let count = self.splitViewController?.viewControllers.count {
            if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                if let isCollapsed = splitViewController?.isCollapsed {
                    if isCollapsed {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
//                        if UIDevice.current.userInterfaceIdiom == .phone {
//                        }
                    } else {
                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                    }
                }
//                switch UIDevice.current.userInterfaceIdiom {
//                case .phone:
//                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                    } else {
//                    }
//                    break
//                    
//                case .pad:
//                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                        navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                    } else {
//                        navigationController?.topViewController?.navigationItem.leftBarButtonItem = nil
//                    }
//                    break
//                    
//                default:
//                    break
//                }
            }
        }
    }
}

struct MediaNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

class Section {
    var strings:[String]? {
        willSet {
            
        }
        didSet {
            guard showIndex else {
                return
            }
            
            indexStrings = strings?.map({ (string:String) -> String in
                return indexTransform != nil ? indexTransform!(string.uppercased())! : string.uppercased()
            })
        }
    }
    
    var showIndex = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }
    var indexHeaders:[String]?
    var indexStrings:[String]?
    {
        didSet {
            guard showIndex else {
                return
            }
            
            guard strings?.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            guard indexStrings?.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            let a = "A"
            
            indexHeaders = Array(Set(indexStrings!
                .map({ (string:String) -> String in
                    if string.endIndex >= a.endIndex {
                        return string.substring(to: a.endIndex).uppercased()
                    } else {
                        return string
                    }
                })
                
            )).sorted() { $0 < $1 }

            if indexHeaders?.count == 0 {
                indexHeaders = nil
                counts = nil
                indexes = nil
            } else {
                var stringIndex = [String:[String]]()
                
                for indexString in indexStrings! {
                    if indexString.endIndex >= a.endIndex {
                        if stringIndex[indexString.substring(to: a.endIndex)] == nil {
                            stringIndex[indexString.substring(to: a.endIndex)] = [String]()
                        }
                        //                print(testString,string)
                        stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
                    }
                }
                
                var counter = 0
                
                var counts = [Int]()
                var indexes = [Int]()
                
                for key in stringIndex.keys.sorted() {
                    //                print(stringIndex[key]!)
                    
                    indexes.append(counter)
                    counts.append(stringIndex[key]!.count)
                    
                    counter += stringIndex[key]!.count
                }
                
                self.counts = counts.count > 0 ? counts : nil
                self.indexes = indexes.count > 0 ? indexes : nil
            }
        }
    }
    var indexTransform:((String?)->String?)? = stringWithoutPrefixes

    var showHeaders = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }
    var headerStrings:[String]?
    
    var headers:[String]?
    {
        get {
            if showHeaders && showIndex {
                print("ERROR: showIndex && showHeaders")
                return nil
            }
            
            if showHeaders {
                return headerStrings
            }

            if showIndex {
                return indexHeaders
            }
            
            return nil
        }
    }
    
    var counts:[Int]?
    var indexes:[Int]?

//    func buildHeaders()
//    {
//        guard strings?.count > 0 else {
//            indexHeaders = nil
//            counts = nil
//            indexes = nil
//            
//            return
//        }
//        
//        if showIndex {
//            guard indexStrings?.count > 0 else {
//                indexHeaders = nil
//                counts = nil
//                indexes = nil
//                
//                return
//            }
//        }
//        
//        indexHeaders = Array(Set(indexStrings!
//            .map({ (string:String) -> String in
//                return string
//            })
//        )).sorted() { $0 < $1 }
//        
//        if indexHeaders?.count == 0 {
//            indexHeaders = nil
//            counts = nil
//            indexes = nil
//        } else {
//            var stringIndex = [String:[String]]()
//            
//            for headerString in headerStrings! {
//                // if string s/b in headerString section
////                stringIndex[headerString]?.append(string)
//            }
//            
//            var counter = 0
//            
//            var counts = [Int]()
//            var indexes = [Int]()
//            
//            for key in stringIndex.keys.sorted() {
//                indexes.append(counter)
//                counts.append(stringIndex[key]!.count)
//                
//                counter += stringIndex[key]!.count
//            }
//            
//            self.counts = counts.count > 0 ? counts : nil
//            self.indexes = indexes.count > 0 ? indexes : nil
//        }
//    }

//    func buildIndex()
//    {
//        guard showIndex else {
//            return
//        }
//        
//        guard strings?.count > 0 else {
//            indexHeaders = nil
//            counts = nil
//            indexes = nil
//            
//            return
//        }
//        
//        guard indexStrings?.count > 0 else {
//            indexHeaders = nil
//            counts = nil
//            indexes = nil
//            
//            return
//        }
//
//        let a = "A"
//        
////        indexHeaders = Array(Set(indexStrings!
////            .map({ (string:String) -> String in
////                if string.endIndex >= a.endIndex {
////                    return string.substring(to: a.endIndex).uppercased()
////                } else {
////                    return string
////                }
////            })
////            
////        )).sorted() { $0 < $1 }
//
//        if indexHeaders?.count == 0 {
//            indexHeaders = nil
//            counts = nil
//            indexes = nil
//        } else {
//            var stringIndex = [String:[String]]()
//            
//            for indexString in indexStrings! {
//                if indexString.endIndex >= a.endIndex {
//                    if stringIndex[indexString.substring(to: a.endIndex)] == nil {
//                        stringIndex[indexString.substring(to: a.endIndex)] = [String]()
//                    }
//                    //                print(testString,string)
//                    stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
//                }
//            }
//            
//            var counter = 0
//            
//            var counts = [Int]()
//            var indexes = [Int]()
//            
//            for key in stringIndex.keys.sorted() {
//                //                print(stringIndex[key]!)
//                
//                indexes.append(counter)
//                counts.append(stringIndex[key]!.count)
//                
//                counter += stringIndex[key]!.count
//            }
//            
//            self.counts = counts.count > 0 ? counts : nil
//            self.indexes = indexes.count > 0 ? indexes : nil
//        }
//    }
}

struct Display {
    var mediaItems:[MediaItem]?
    var section = Section()
}

struct MediaRepository {
    var list:[MediaItem]? { //Not in any specific order
        willSet {
            
        }
        didSet {
            index = nil
            classes = nil
            events = nil
            
            if (list != nil) {
                for mediaItem in list! {
                    if let id = mediaItem.id {
                        if index == nil {
                            index = [String:MediaItem]()
                        }
                        if index![id] == nil {
                            index![id] = mediaItem
                        } else {
                            print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                        }
                    }
                    
                    if let className = mediaItem.className {
                        if classes == nil {
                            classes = [className]
                        } else {
                            classes?.append(className)
                        }
                    }
                    
                    if let eventName = mediaItem.eventName {
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
    }

    var index:[String:MediaItem]?
    var classes:[String]?
    var events:[String]?
}

struct Tags {
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
            if (newValue != nil) {
                if (globals.media.tagged[newValue!] == nil) {
                    if globals.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        globals.media.tagged[newValue!] = MediaListGroupSort(mediaItems: mediaItemsWithTag(globals.mediaRepository.list, tag: newValue))
                    } else {
                        globals.media.tagged[newValue!] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[stringWithoutPrefixes(newValue!)!])
                    }
                }
            } else {

            }
            
            globals.mediaCategory.tag = newValue
        }
    }
}

struct Media {
    var need = MediaNeed()

    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = [String:MediaListGroupSort]()
    
    var tags = Tags()
    
    var toSearch:MediaListGroupSort? {
        get {
            var mediaItems:MediaListGroupSort?
            
            switch tags.showing! {
            case Constants.TAGGED:
                mediaItems = tagged[tags.selected!]
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
                mediaItems = tagged[tags.selected!]
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
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

struct MediaCategory {
    var dicts:[String:String]?
    
    var filename:String? {
        get {
            return selectedID != nil ? Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID! +  Constants.JSON.FILENAME_EXTENSION : nil
        }
    }
    
    var url:String? {
        get {
            return selectedID != nil ? Constants.JSON.URL.CATEGORY + selectedID! : nil // CATEGORY + selectedID!
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
            return dicts?[selected!] ?? "1" // Sermons are category 1
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
    
    var tag:String? {
        get {
            return self[Constants.SETTINGS.KEY.COLLECTION]
        }
        set {
            self[Constants.SETTINGS.KEY.COLLECTION] = newValue
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
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER]
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String? {
        get {
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL]
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

struct Search {
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
            return (text != nil) && (text != Constants.EMPTY_STRING)
        }
    }
    
    var text:String? {
        willSet {
            
        }
        didSet {
            if (text != oldValue) && !globals.isLoading {
                if extant { //  && !lexicon
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
            // Setting to nil can cause a crash.
            globals.media.toSearch?.searches = [String:MediaListGroupSort]()
            
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
}

var globals:Globals!

struct Alert {
    var title : String
    var message : String?
    var actions : [AlertAction]?
}

class Globals : NSObject, AVPlayerViewControllerDelegate
{
    var allowMGTs : Bool {
        return voiceBaseAPIKey != nil
    }
    
    var voiceBaseAPIKey : String? {
        get {
            return UserDefaults.standard.string(forKey: Constants.VOICEBASE_API_KEY)
        }
        set {
            if newValue != nil {
                UserDefaults.standard.set(newValue, forKey: Constants.VOICEBASE_API_KEY)
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.VOICEBASE_API_KEY)
                UserDefaults.standard.synchronize()
            }
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
                                          preferredStyle: UIAlertControllerStyle.alert)
            
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
            
            DispatchQueue.main.async(execute: { () -> Void in
                globals.splitViewController.present(alertVC, animated: true, completion: {
                    self.alerts.remove(at: 0)
                })
            })
        }
    }

    var alerts = [Alert]()
    
    var alertTimer : Timer?
    
    func alert(title:String,message:String?)
    {
        if !alerts.contains(where: { (alert:Alert) -> Bool in
            return (alert.title == title) && (alert.message == message)
        }) {
            alerts.append(Alert(title: title, message: message, actions: nil))
        } else {
            print("DUPLICATE ALERT")
        }
    }
    
    func alert(title:String,message:String?,actions:[AlertAction]?)
    {
        alerts.append(Alert(title: title, message: message, actions: actions))
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
    
//    func reachabilityChanged(note: NSNotification)
//    {
//        let reachability = note.object as! Reachability
//        
//        if reachability.isReachable {
//            if reachability.isReachableViaWLAN {
//                print("Reachable via WiFi")
//            } else {
//                print("Reachable via Cellular")
//            }
//        } else {
//            print("Network not reachable")
//        }
//    }
    
    var reachabilityStatus : Reachability.NetworkStatus?
    
    func reachabilityTransition()
    {
        if self.reachabilityStatus != nil {
            switch self.reachabilityStatus! {
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
        
        if (reachabilityStatus == .notReachable) && (reachability.currentReachabilityStatus != .notReachable) {
            globals.alert(title: "Network Connection Restored",message: "")
        }
        
        if (reachabilityStatus != .notReachable) && (reachability.currentReachabilityStatus == .notReachable) {
            globals.alert(title: "No Network Connection",message: "Without a network connection only audio, slides, and transcripts previously downloaded will be available.")
        }
        
        reachabilityStatus = reachability.currentReachabilityStatus
    }
    
    override init()
    {
        super.init()
        
        DispatchQueue.main.async(execute: { () -> Void in
            globals.alertTimer = Timer.scheduledTimer(timeInterval: 0.25, target: globals, selector: #selector(Globals.alertViewer), userInfo: nil, repeats: true)
        })

        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            DispatchQueue.main.async() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            }
        }
        
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.reachabilityTransition()
            
            DispatchQueue.main.async() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
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

    var groupings = Constants.groupings
    var groupingTitles = Constants.GroupingTitles
    
    var grouping:String? = GROUPING.YEAR {
        willSet {
            
        }
        didSet {
            media.need.grouping = (grouping != oldValue)
            
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
    
    var sorting:String? = SORTING.REVERSE_CHRONOLOGICAL {
        willSet {
            
        }
        didSet {
            media.need.sorting = (sorting != oldValue)
            
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
    
    func searchText() -> String? {
        return globals.search.text
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
                                print(mediaItem.text as Any)
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

        display.section.headerStrings = nil
        display.section.indexHeaders = nil
        display.section.indexes = nil
        display.section.counts = nil
    }
    
    func setupDisplay(_ active:MediaListGroupSort?)
    {
//        print("setupDisplay")

        display.mediaItems = active?.mediaItems
        
        display.section.showHeaders = true
        
        display.section.headerStrings = active?.section?.titles
        display.section.indexHeaders = active?.section?.indexTitles
        display.section.indexes = active?.section?.indexes
        display.section.counts = active?.section?.counts
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
                    sorting = SORTING.REVERSE_CHRONOLOGICAL
                }
                
                if let groupingString = defaults.string(forKey: Constants.SETTINGS.KEY.GROUPING) {
                    grouping = groupingString
                } else {
                    grouping = GROUPING.YEAR
                }
                
//                media.tags.selected = mediaCategory.tag

                if (media.tags.selected == Constants.Strings.New) {
                    media.tags.selected = nil
                }

                if media.tags.showing == Constants.TAGGED, media.tagged[mediaCategory.tag!] == nil {
                    if media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        media.tagged[mediaCategory.tag!] = MediaListGroupSort(mediaItems: mediaItemsWithTag(mediaRepository.list, tag: media.tags.selected))
                    } else {
                        media.tagged[mediaCategory.tag!] = MediaListGroupSort(mediaItems: media.all?.tagMediaItems?[stringWithoutPrefixes(media.tags.selected!)!])
                    }
                }

                search.text = defaults.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
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
    
    func startAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("failed to setCategory(AVAudioSessionCategoryPlayback): \(error.localizedDescription)")
        }
        
//        do {
//            try audioSession.setActive(true)
//        } catch let error as NSError {
//            print("failed to audioSession.setActive(true): \(error.localizedDescription)")
//        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func stopAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch let error as NSError {
            print("failed to audioSession.setActive(false): \(error.localizedDescription)")
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

    func totalCacheSize() -> Int
    {
        return cacheSize(Purpose.audio) + cacheSize(Purpose.video) + cacheSize(Purpose.notes) + cacheSize(Purpose.slides)
    }
    
    func cacheSize(_ purpose:String) -> Int
    {
        var totalFileSize = 0
        
        if mediaRepository.list != nil {
            for mediaItem in mediaRepository.list! {
                if let download = mediaItem.downloads[purpose], download.isDownloaded() {
                    totalFileSize += download.fileSize
                }
            }
        }
        
        return totalFileSize
    }

    func motionEnded(_ motion: UIEventSubtype, event: UIEvent?)
    {
        guard (UIDevice.current.userInterfaceIdiom == .phone) else {
            return
        }

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

