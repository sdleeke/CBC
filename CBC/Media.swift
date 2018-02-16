//
//  Media.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

// Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
// Problems went away when I switched to class

struct MediaNeed
{
    var sorting:Bool = true
    var grouping:Bool = true
}

class Media
{
    weak var globals:Globals!
    
    var need = MediaNeed()
    
    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = [String:MediaListGroupSort]()
    
    lazy var tags:Tags! = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
        //            [unowned self] in
        var tags = Tags()
        tags.globals = self.globals
        return tags
    }()
    
    var toSearch:MediaListGroupSort?
    {
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
    
    var active:MediaListGroupSort?
    {
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

