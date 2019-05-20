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
    
    lazy var selected : SelectedMediaItem! = {
        return SelectedMediaItem(self)
    }()

    var category = MediaCategory()
    
//    var categories = MediaCategories() // MediaCategory()
    
    var stream = MediaStream()
    
    var categories = ThreadSafeDN<Category>() // [String:String]?
    
    var teachers = ThreadSafeDN<Teacher>() // [String:String]?
    
    var groups = ThreadSafeDN<Group>() // [String:String]?
    
    var repository = MediaList()

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
    
    // Globals.shared.media.category.selected as the key
    // That way work can be saved when a category is changed.
    var cache = ThreadSafeDN<MediaListGroupSort>()
    
    //All mediaItems
    var all:MediaListGroupSort?
    {
        didSet {
            // WHY?
//            all?.lexicon?.eligible = nil
//            all?.scriptureIndex?.eligible = nil
        }
    }
    
    // Is tagged really necessary?
    // It's the same as:
    
    func tagged(tag:String?) -> MediaListGroupSort?
    {
        guard let tag = tag else {
            return nil
        }

        return MediaListGroupSort(mediaItems: all?.tagMediaItems?[tag.withoutPrefixes])
    }
    
    // The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = ThreadSafeDN<MediaListGroupSort>(name: UUID().uuidString + "TAGGED") // [String:MediaListGroupSort]() // ictionary
    
    var tags = Tags()
    
    var toSearch:MediaListGroupSort?
    {
        get {
            var toSearch:MediaListGroupSort?
            
            if let showing = tags.showing {
                switch showing {
                case Constants.TAGGED:
                    if let selected = tags.selected {
                        toSearch = tagged[selected]
                    }
                    break
                    
                case Constants.ALL:
                    toSearch = all
                    break
                    
                default:
                    break
                }
            }
            
            return toSearch
        }
    }
    
    var active:MediaListGroupSort?
    {
        get {
            var active:MediaListGroupSort?
            
            if let showing = tags.showing {
                switch showing {
                case Constants.TAGGED:
                    if let selected = tags.selected {
                        active = tagged[selected]
                    }
                    break
                    
                case Constants.ALL:
                    active = all
                    break
                    
                default:
                    break
                }
            }
            
            // Globals.shared.
            if search.isActive {
                if let context = active?.context, let search = search.searches?[context] { // Globals.shared.
                    active = search // active?
                }
//                if let searchText = search.text?.uppercased() { // Globals.shared.
//                    active = search.searches?[searchText] // active?
//                }
            }
            
            return active
        }
    }
    
    var history = ThreadSafeArray<String>() // :[String]?
    
    // thread safe
    var relevantHistory:[String]?
    {
        get {
            // This is a problem for grouping these.
            guard let index = all?.mediaList?.index else {
                return nil
            }
            
            return history.reversed?.filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.SEPARATOR) {
                    let mediaItemID = String(string[range.upperBound...])
                    return index[mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    var relevantHistoryFirst : MediaItem?
    {
        get {
            if let first = relevantHistory?.first {
                let components = first.components(separatedBy: Constants.SEPARATOR)
                
                if components.count == 2 {
                    let id = components[1]
                    
                    // This is a problem for grouping these.
                    return repository.index[id]
                }
            }
            
            return nil
        }
    }
    
    // thread safe
    var relevantHistoryList:[String]?
    {
        get {
            guard let index = all?.mediaList?.index else {
                return nil
            }
            
            return relevantHistory?.map({ (string:String) -> String in
                if  let range = string.range(of: Constants.SEPARATOR),
                    let mediaItem = index[String(string[range.upperBound...])],
                    let text = mediaItem.text {
                    return text
                }
                
                return ("ERROR")
            })
        }
    }
    
    func addToHistory(_ mediaItem:MediaItem? = nil)
    {
        guard let mediaItem = mediaItem else {
            print("mediaItem NIL!")
            return
        }
        
        guard mediaItem.mediaCode != nil else {
            print("mediaItem ID NIL!")
            return
        }
        
        let entry = "\(Date())" + Constants.SEPARATOR + mediaItem.mediaCode
        
        //        if history == nil {
        //            history = [entry]
        //        } else {
        //            history?.append(entry)
        //        }
        
        history.append(entry)
        
        let defaults = UserDefaults.standard
        defaults.set(history.copy, forKey: Constants.SETTINGS.HISTORY)
        defaults.synchronize()
    }

}

