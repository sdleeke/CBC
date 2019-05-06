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
class Media
{
    var search = Search()
    
    deinit {
        debug(self)
    }
    
    var goto:String?
    
    var need = MediaNeed()
    
    // Globals.shared.mediaCategory.selected as the key
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

        return MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes])
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
}

