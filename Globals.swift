//
//  Globals.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer

struct DeepLink {
    var path:String?
    var sorting:String?
    var grouping:String?
    var searchString:String?
    var tag:String?
}

struct Section {
    var titles:[String]?
    var counts:[Int]?
    var indexes:[Int]?
}

typealias SortGroupTuple = (sermons: [Sermon]?, sections: [String]?, indexes: [Int]?, counts: [Int]?)
typealias SortGroupCache = [String:SortGroupTuple]

struct Globals {
    static var scrolledToSermonLastSelected = false
    
    static var loadedEnoughToDeepLink = false
    static var deepLinkWaiting = false
    static var deepLink = DeepLink()
    
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
    
    static var testing:Bool = false
    
    static var sermonPlaying:Sermon?
    
    static var seriesViewSplits:[String:String]?
    
    //This is now a dictionary of dictionaries
    static var sermonSettings:[String:[String:String]]?

    static var sermons:[Sermon]?
    
    //The sermons with the selectd tags, although now we only support one tag being selected
    static var taggedSermons:[Sermon]?
    static var sermonTagsSelected:String?
    
    //The sermons in the search results, see updateSearchResults
    static var searchSermons:[Sermon]?
    
    static var sermonsToSearch:[Sermon]? {
        get {
            var sermons:[Sermon]?
            
            switch Globals.showing! {
            case Constants.TAGGED:
                if (Globals.taggedSermons == nil) {
                    Globals.taggedSermons = taggedSermonsFromTagSelected(Globals.sermons, tagSelected: Globals.sermonTagsSelected)
                }
                sermons = Globals.taggedSermons
                break
                
            case Constants.ALL:
                sermons = Globals.sermons
                break
                
            default:
                break
            }
            
            return sermons
        }
    }
    
    static var activeSermons:[Sermon]? {
        get {
            var sermons:[Sermon]?
        
            if (Globals.searchActive) {
                sermons = Globals.searchSermons
            } else {
                sermons = Globals.sermonsToSearch
            }
        
            return sermons
        }
        
        set {
            if (Globals.searchActive) {
                Globals.searchSermons = newValue
            } else {
                switch Globals.showing! {
                case Constants.TAGGED:
                    Globals.taggedSermons = newValue
                    break
                    
                case Constants.ALL:
                    Globals.sermons = newValue
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    //These are only used when sorting and grouping, i.e. according to what is being shown
    static var sortGroupCache:SortGroupCache? = {
        return SortGroupCache()
    }()
    
    static var sortGroupCacheKey:String {
        get {
            var key = Globals.searchActive ? (Globals.searchText != nil ? Globals.searchText! : "") : ""

            key = key + Globals.showing!

            switch Globals.showing! {
            case Constants.TAGGED:
                key = key + Globals.sermonTagsSelected!
                break
                
            case Constants.ALL:
                break
                
            default:
                break
            }
            
            key = key + Globals.sorting! + Globals.grouping!
            
            return key
        }
    }
    
    struct sermonSectionTitles {
        static var years:[Int]?
        static var series:[String]?
        static var books:[String]?
        static var speakers:[String]?
    }
    
    static var sermonsSortingOrGrouping:Bool = false
    
    struct sermonsNeed {
        static var sorting:Bool = true
        static var grouping:Bool = true
        static var groupsSetup:Bool = true
    }
    
    //These are the tags from all sermons
    static var sermonTags:[String]?

    static var section:Section! = {
        var section = Section()
        return section
    }()
    
    struct display {
        static var sermons:[Sermon]?
        static var section:Section! = {
            var section = Section()
            return section
            }()
    }
}
