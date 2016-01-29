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
        }
    }
    
    static var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            Globals.sermonsNeed.sorting = (sorting != oldValue)
        }
    }
    
    static var searchActive:Bool = false
    static var searchText:String?
    
    static var showing:String? = Constants.ALL
    
    static var gotoPlayingPaused:Bool = false
    static var showingAbout:Bool = false
    
    static var mpPlayer:MPMoviePlayerController?
    
    static var playerPaused:Bool = true
    static var sermonLoaded:Bool = false
    
    static var sliderObserver: NSTimer?
    static var playObserver: NSTimer?
    static var seekingObserver: NSTimer?

    static var testing:Bool = false
    
    static var sermonPlaying:Sermon?
    
    static var seriesViewSplits:[String:String]?
    
    //This is now a dictionary of dictionaries
    static var sermonSettings:[String:[String:String]]?

    static var sermonRepository:[Sermon]?
    
    struct sermons {
        //All sermons
        static var all:SermonsListGroupSort?
        
        //The sermons from a search
        static var search:SermonsListGroupSort? // These could be in a cache, one for each search
        
        //The sermons with the selected tags, although now we only support one tag being selected
        static var tagged:SermonsListGroupSort? // These could be in a cache, one for each tag
    }

    static var sermonTagsSelected:String?
    
    static var sermonsToSearch:[Sermon]? {
        get {
            var sermons:[Sermon]?
            
            switch Globals.showing! {
            case Constants.TAGGED:
                if (Globals.sermons.tagged == nil) {
                    Globals.sermons.tagged = SermonsListGroupSort(sermons: taggedSermonsFromTagSelected(Globals.sermonRepository, tagSelected: Globals.sermonTagsSelected))
                }
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
                    Globals.sermons.tagged = newValue
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
