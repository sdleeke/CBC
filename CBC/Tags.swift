//
//  Tags.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

// Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
// Problems went away when I switched to class

class Tags
{
    weak var globals:Globals!
    
    var showing:String? {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String? {
        get {
            return globals.mediaCategory.tag
        }
        set {
            if let newValue = newValue {
                if (globals.media.tagged[newValue] == nil) {
                    if globals.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        globals.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(globals.mediaRepository.list, tag: newValue))
                    } else {
                        if let key = stringWithoutPrefixes(newValue), let mediaItems = globals.media.all?.tagMediaItems?[key] {
                            globals.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItems)
                        }
                    }
                }
            } else {
                
            }
            
            globals.mediaCategory.tag = newValue
        }
    }
}

