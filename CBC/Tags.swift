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
//    weak var globals:Globals!
    
    var showing:String?
    {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String?
    {
        get {
            return Globals.shared.mediaCategory.tag
        }
        set {
            if let newValue = newValue {
                if (Globals.shared.media.tagged[newValue] == nil) {
                    if Globals.shared.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                                return mediaItem.category == Globals.shared.mediaCategory.selected
                            }), tag: newValue))
                    } else {
                        if let mediaItems = Globals.shared.media.all?.tagMediaItems?[newValue.withoutPrefixes] {
                            Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItems)
                        }
                    }
                }
            } else {
                
            }
            
            Globals.shared.mediaCategory.tag = newValue
        }
    }
}

