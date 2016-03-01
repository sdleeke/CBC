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

struct Globals {
    static var finished = 0
    static var progress = 0
    
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
    
    static var refreshing:Bool = false
    static var loading:Bool = false
    
    static var searchActive:Bool = false
    static var searchText:String?
    
    static var showing:String? = Constants.ALL
    
    static var gotoPlayingPaused:Bool = false
    static var showingAbout:Bool = false
    
    static var mpPlayer:MPMoviePlayerController?
    
    static var playerPaused:Bool = true {
        didSet {
            print("playerPaused")
        }
    }
    
    static var sermonLoaded:Bool = false
    
    static var sliderObserver: NSTimer?
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


    // These are hidden behind custom accessors in Sermon
    static var seriesViewSplits:[String:String]?
    static var sermonSettings:[String:[String:String]]?

    static var sermonRepository:[Sermon]?
    
    struct sermons {
        //All sermons
        static var all:SermonsListGroupSort?
        
        //The sermons from a search
        static var search:SermonsListGroupSort? // These could be in a cache, one for each search
        
        static var hiddenTagged:SermonsListGroupSort?

        //The sermons with the selected tags, although now we only support one tag being selected
        static var tagged:SermonsListGroupSort? { // These could be in a cache, one for each tag
            get {
                if hiddenTagged == nil {
                    if (Globals.showing == Constants.TAGGED) && (Globals.sermonTagsSelected != nil) {
                        if Globals.sermons.all == nil {
                            hiddenTagged = SermonsListGroupSort(sermons: taggedSermonsFromTagSelected(Globals.sermonRepository, tagSelected: Globals.sermonTagsSelected))
                        } else {
                            hiddenTagged = SermonsListGroupSort(sermons: Globals.sermons.all?.tagSermons?[stringWithoutPrefixes(Globals.sermonTagsSelected!)!])
                        }
                    } else {
                        hiddenTagged = nil
                    }
                }
                return hiddenTagged
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
//                if (Globals.sermons.tagged == nil) {
//                    if Globals.sermons.all == nil {
//                        Globals.sermons.tagged = SermonsListGroupSort(sermons: taggedSermonsFromTagSelected(Globals.sermonRepository, tagSelected: Globals.sermonTagsSelected))
//                    } else {
//                        Globals.sermons.tagged = SermonsListGroupSort(sermons: Globals.sermons.all?.tagSermons?[stringWithoutPrefixes(Globals.sermonTagsSelected!)!])
//                    }
//                }
                sermons = Globals.sermons.tagged?.list
                break
                
            case Constants.ALL:
                if Globals.sermons.all == nil {
                    Globals.sermons.all = SermonsListGroupSort(sermons: Globals.sermonRepository)
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
    
//    static var sermonsSortingOrGrouping:Bool = false
    
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
