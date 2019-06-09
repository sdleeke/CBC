//
//  Media.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

struct MediaNeed
{
    var sorting:Bool = true
    var grouping:Bool = true
}

// Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
// Problems went away when I switched to class

/**

 Handles everything related to media except the AVPlayer.

 Properties:
    - json - media json
    - category, track selected category and master/detail media items selected for that category
    - stream - live events
    - teachers - speakers
    - groups - sub-categories
    - repository - a list of all media
    - search - everything about searches
    - metaData - from new API: tells where media is stored
    - needs - whether the media list needs sorting or grouping
    - all - all mediaItems for the selected catgory
    - tagged - mediaItems that have the selected tag
             - stored by tag
    - tags - the selectd tag
    - toSearch - mediaItems to search in the given context
    - active - the current list of mediaItems to be displayed to the user
    - history
 */

class Media
{
    var json = JSON()
    
    lazy var selected : Selected! = {
        return Selected(self)
    }()

    lazy var history : History! = {
        return History(self)
    }()
    
    var stream = MediaStream()
    
    var categories = ThreadSafeDN<Category>() // [String:String]?
    
    var teachers = ThreadSafeDN<Teacher>() // [String:String]?
    
    var groups = ThreadSafeDN<Group>() // [String:String]?
    
    var repository = MediaList()

    lazy var category:MediaCategory! = {
        return MediaCategory(self)
    }()
    
    lazy var search : Search! = {
        return Search(self)
    }()
    
    var metadata : [String:Any]?
    
    var url : String?
    {
        get {
            return metadata?["s3MediaUrl"] as? String
        }
    }
    
    deinit {
        debug(self)
    }
    
    var goto:String?
    
    var need = MediaNeed()
    
    // Globals.shared.media.category.selected is the key
    // That way work can be saved when a category is changed.
    var cache = ThreadSafeDN<MediaListGroupSort>()
    
    //All mediaItems
    var all:MediaListGroupSort?
    {
        didSet {

        }
    }
    
    lazy var tags:Tags! = {
        return Tags(media:self)
    }()
    
    var active:MediaListGroupSort?
    {
        get {
            var active:MediaListGroupSort?
            
            if let showing = tags.showing {
                switch showing {
                case Constants.TAGGED:
                    if let selected = tags.selected {
                        active = tags.tagged[selected]
                    }
                    break
                    
                case Constants.ALL:
                    active = all
                    break
                    
                default:
                    break
                }
            }
            
            if search.isActive {
                if let context = active?.context, let search = search.searches?[context] {
                    active = search
                }
            }
            
            return active
        }
    }
}

