//
//  Globals.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

//struct DeepLink {
//    var path:String?
//    var sorting:String?
//    var grouping:String?
//    var searchString:String?
//    var tag:String?
//}

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
}

//class Player {
//    var stateTime:PlayerStateTime?
//    
//    var loaded:Bool = false
//    
//    var paused:Bool = true {
//        didSet {
//            if (paused != oldValue) || (Globals.sermonPlaying != stateTime?.sermon) || (stateTime?.sermon == nil) {
//                stateTime = PlayerStateTime()
//                
//                stateTime?.sermon = Globals.sermonPlaying
//                
//                if paused {
//                    stateTime?.state = .paused
//                } else {
//                    stateTime?.state = .playing
//                }
//            }
//        }
//    }
//
//    var playerObserver:NSTimer?
//
//    var mpPlayer:MPMoviePlayerController?
//    
////    init()
////    {
////        stateTime = PlayerStateTime()
////    }
//    
//    func mpPlayerLoadStateDidChange(notification:NSNotification)
//    {
//        let player = notification.object as! MPMoviePlayerController
//        
//        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
//        
//        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
//        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
//        
//        //        print("\(loadstate)")
//        //        print("\(playable)")
//        //        print("\(playthrough)")
//        
//        if (playable || playthrough) && !loaded && (Globals.sermonPlaying != nil) {
//            //            print("\(Globals.sermonPlaying!.currentTime!)")
//            //            print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
//            
//            // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
//            if Globals.sermonPlaying!.hasCurrentTime() {
//                if (Int(Float(Globals.sermonPlaying!.currentTime!)!) == Int(mpPlayer!.duration)) { // !loadingFromLive &&
//                    Globals.sermonPlaying?.currentTime = Constants.ZERO
//                }
//            } else {
//                Globals.sermonPlaying?.currentTime = Constants.ZERO
//            }
//            
//            mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
//            
//            updateCurrentTimeExact()
//            setupPlayingInfoCenter()
//            
////            spinner.stopAnimating()
//            loaded = true
//            
////            if !loadingFromLive {
//                mpPlayer?.play()
////            }
//            
////            playPauseButton.enabled = true
////            slider.enabled = true
//            
//            NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: mpPlayer)
//        }
//        
//        //For playing
//        if (mpPlayer != nil) {
//            switch mpPlayer!.playbackState {
//            case .Interrupted:
//                print("MVC.mpPlayerLoadStateDidChange.Interrupted")
//                break
//                
//            case .Paused:
//                print("MVC.mpPlayerLoadStateDidChange.Paused")
//                break
//                
//            case .Playing:
//                print("MVC.mpPlayerLoadStateDidChange.Playing")
//                //Why do we need the following?
////                spinner.stopAnimating()
////                spinner.hidden = true
//                setupPlayingInfoCenter()
//                NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: mpPlayer)
//                break
//                
//            case .SeekingBackward:
//                print("MVC.mpPlayerLoadStateDidChange.SeekingBackward")
//                break
//                
//            case .SeekingForward:
//                print("MVC.mpPlayerLoadStateDidChange.SeekingForward")
//                break
//                
//            case .Stopped:
//                print("MVC.mpPlayerLoadStateDidChange.Stopped")
//                //Why do we need the following?
//                if !Globals.player!.paused {
//                    mpPlayer?.play()
//                }
//                break
//            }
//        }
//    }
//}

struct Globals {
    static var finished = 0
    static var progress = 0
    
    static var saveSettings = true

    // So that the selected cell is scrolled to only on startup, not every time the master view controller appears.
    static var scrolledToSermonLastSelected = false
    
//    static var loadedEnoughToDeepLink = false
//    static var deepLinkWaiting = false
//    static var deepLink = DeepLink()
    
    static var grouping:String? = Constants.YEAR {
        didSet {
            Globals.sermonsNeed.grouping = (grouping != oldValue)
            
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
    
    static var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            Globals.sermonsNeed.sorting = (sorting != oldValue)
            
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
    
    static var autoAdvance:Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.AUTO_ADVANCE)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    static var cacheDownloads:Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.CACHE_DOWNLOADS)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    static var refreshing:Bool = false
    static var loading:Bool = false
//    static var loadingFromLive = false
    
    static var searchActive:Bool = false
    static var searchText:String?
    
    static var showing:String? = Constants.ALL
    
    static var gotoPlayingPaused:Bool = false
    static var showingAbout:Bool = false
    
//    static var player:Player?
    
    static var mpPlayer:MPMoviePlayerController?
    static var mpPlayerStateTime : PlayerStateTime?
    
    static var playerPaused:Bool = true {
        didSet {
            if (playerPaused != oldValue) || (sermonPlaying != mpPlayerStateTime?.sermon) || (mpPlayerStateTime?.sermon == nil) {
                mpPlayerStateTime = PlayerStateTime()
                mpPlayerStateTime?.sermon = sermonPlaying
                
                if playerPaused {
                    mpPlayerStateTime?.state = .paused
                } else {
                    mpPlayerStateTime?.state = .playing
                }
            }
        }
    }

    static var playOnLoad:Bool = false
    static var sermonLoaded:Bool = false
    
//    static var sliderObserver: NSTimer?
    static var playerObserver: NSTimer?
    static var seekingObserver: NSTimer?
    
//    static var playObserver: NSTimer?

    static var testing:Bool = false
    
    static var sermonPlaying:Sermon? {
        didSet {
            let defaults = NSUserDefaults.standardUserDefaults()
            if sermonPlaying != nil {
                defaults.setObject(sermonPlaying?.dict, forKey: Constants.SERMON_PLAYING)
            } else {
                defaults.removeObjectForKey(Constants.SERMON_PLAYING)
            }
            defaults.synchronize()
        }
    }

    static var selectedSermon:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let selectedSermonID = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
                selectedSermon = Globals.sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    static var selectedSermonDetail:Sermon? {
        get {
            var selectedSermon:Sermon?
            
            let defaults = NSUserDefaults.standardUserDefaults()
            if let selectedSermonID = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
                selectedSermon = Globals.sermonRepository.index?[selectedSermonID]
            }
            defaults.synchronize()
            
            return selectedSermon
        }
    }
    
    // These are hidden behind custom accessors in Sermon
    static var seriesViewSplits:[String:String]?
    static var sermonSettings:[String:[String:String]]?
    
    static var sermonHistory:[String]?
    
    struct sermonRepository {
        static var list:[Sermon]? { //Not in any specific order
            didSet {
                if (list != nil) {
                    index = [String:Sermon]()
                    
                    for sermon in list! {
                        index![sermon.id!] = sermon
                    }
                    
                    scriptureIndex = nil
                }
            }
        }
        static var index:[String:Sermon]?
        static var scriptureIndex:ScriptureIndex?
    }
    
    struct sermons {
        //All sermons
        static var all:SermonsListGroupSort?
        
        //The sermons from a search
        static var search:SermonsListGroupSort? // These could be in a cache, one for each search
        
        static var hiddenTagged:SermonsListGroupSort?

        //The sermons with the selected tags, although now we only support one tag being selected
        static var tagged:SermonsListGroupSort? { // These could be in a cache, one for each tag
            get {
                if self.hiddenTagged == nil {
                    if (Globals.showing == Constants.TAGGED) && (Globals.sermonTagsSelected != nil) {
                        if Globals.sermons.all == nil {
                            self.hiddenTagged = SermonsListGroupSort(sermons: sermonsWithTag(Globals.sermonRepository.list, tag: Globals.sermonTagsSelected))
                        } else {
                            self.hiddenTagged = SermonsListGroupSort(sermons: Globals.sermons.all?.tagSermons?[stringWithoutPrefixes(Globals.sermonTagsSelected!)!])
                        }
                    } else {
                        self.hiddenTagged = nil
                    }
                }
                return self.hiddenTagged
            }
        }
    }

    static var sermonTagsSelected:String? {
        didSet {
            if sermonTagsSelected != oldValue {
                sermons.hiddenTagged = nil
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
    
    static var sermonsToSearch:[Sermon]? {
        get {
            var sermons:[Sermon]?
            
            switch Globals.showing! {
            case Constants.TAGGED:
                sermons = Globals.sermons.tagged?.list
                break
                
            case Constants.ALL:
                if Globals.sermons.all == nil {
                    Globals.sermons.all = SermonsListGroupSort(sermons: Globals.sermonRepository.list)
                }
                sermons = Globals.sermons.all?.list
                break
                
            default:
                break
            }
            
            return sermons
        }
    }
    
    static var activeSermons:[Sermon]? {
        get {
            return Globals.active?.sermons
        }
        
        set {
            Globals.active = SermonsListGroupSort(sermons: newValue)
        }
    }
    
    static var active:SermonsListGroupSort? {
        get {
            if (Globals.searchActive) {
                return Globals.sermons.search
            } else {
                var sermons:SermonsListGroupSort?
                
                switch Globals.showing! {
                case Constants.TAGGED:
                    sermons = Globals.sermons.tagged
                    break
                
                case Constants.ALL:
                    sermons = Globals.sermons.all
                    break
                
                default:
                    break
                }
                
                return sermons
            }
        }
        
        set {
            if (Globals.searchActive) {
                Globals.sermons.search = newValue
            } else {
                switch Globals.showing! {
                case Constants.TAGGED:
//                    Globals.sermons.tagged = newValue
                    print("ERROR: setting active while TAGGED.")
                    break
                    
                case Constants.ALL:
                    Globals.sermons.all = newValue
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    struct sermonsNeed {
        static var sorting:Bool = true
        static var grouping:Bool = true
    }
    
    struct display {
        static var sermons:[Sermon]?
        
        static var sectionTitles:[String]?
        static var sectionCounts:[Int]?
        static var sectionIndexes:[Int]?
    }
}
