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
    var goto:String?
    
    var need = MediaNeed()
    
    //All mediaItems
    var all:MediaListGroupSort?
    {
        didSet {
            all?.lexicon?.eligible = nil
            all?.scriptureIndex?.eligible = nil
        }
    }
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = ThreadSafeDictionary<MediaListGroupSort>(name: UUID().uuidString + "TAGGED") // [String:MediaListGroupSort]()
    
    var tags = Tags()
    
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
            
            if Globals.shared.search.active {
                if let searchText = Globals.shared.search.text?.uppercased() {
                    mediaItems = mediaItems?.searches?[searchText]
                }
            }
            
            return mediaItems
        }
    }
}

