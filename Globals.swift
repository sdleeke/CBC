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

// Consider replacing Sorting, Grouping, and Showing with String? and Constants

//enum Sorting {
//    case chronological          // Constants.CHRONOLOGICAL
//    case reverseChronological   // Constants.REVERSE_CHRONOLOGICAL
//}
//
//enum Grouping {
//    case year       // Constants.YEAR
//    case series     // Constants.SERIES
//    case book       // Constants.BOOK
//    case speaker    // Constants.SPEAKER
//}
//
//enum Showing {
//    case all         // Constants.ALL_SERMONS
//    case tagged      // Constants.TAGGED_SERMONS
//}

struct DeepLink {
    var path:String?
    var sorting:String?
    var grouping:String?
    var searchString:String?
    var tag:String?
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
            Globals.sermonsNeedGrouping = (grouping != oldValue)
        }
    }
    
    static var sorting:String? = Constants.REVERSE_CHRONOLOGICAL {
        didSet {
            Globals.sermonsNeedSorting = (sorting != oldValue)
        }
    }
    
    static var searchActive:Bool = false
    
    static var showing:String? = Constants.ALL
    
    static var gotoPlayingPaused:Bool = false
    static var showingAbout:Bool = false
    
    static var mpPlayer:MPMoviePlayerController?
    
    static var playerPaused:Bool = true
    static var sermonLoaded:Bool = false
    
    static var sliderObserver: NSTimer?
    static var playObserver: NSTimer?
    
    //    static var endPlayObserver: AnyObject?
    
    static var testing:Bool = false
    
    static var sermonPlaying:Sermon?
    
    static var seriesViewSplits:[String:String]?
    static var sermonSettings:[String:String]?
    
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
    static var sortGroupCache:SortGroupCache?
    
    static var sermonYears:[Int]?
    static var sermonSeries:[String]?
    static var sermonBooks:[String]?
    static var sermonSpeakers:[String]?
    
    static var sermonsSortingOrGrouping:Bool = false
    static var sermonsNeedSorting:Bool = true
    static var sermonsNeedGrouping:Bool = true
    static var sermonsNeedGroupsSetup:Bool = true {
        didSet {
            if (sermonsNeedGroupsSetup == true) {
                sortGroupCache = nil
            }
        }
    }
    
    //These are the tags from all sermons
    static var sermonTags:[String]?
    
    static var sermonSections:[String]?
    static var sermonSectionCounts:[Int]?
    static var sermonSectionIndexes:[Int]?
    
    struct display {
        static var sermons:[Sermon]?
        static var sections:[String]?
        static var sectionCounts:[Int]?
        static var sectionIndexes:[Int]?
    }
}
