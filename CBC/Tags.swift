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
            Globals.shared.mediaCategory.tag = newValue

            guard !Globals.shared.isLoading, Globals.shared.mediaRepository.list != nil else {
                return
            }
            
            guard let newValue = newValue else {
                return
            }

            guard (Globals.shared.media.tagged[newValue] == nil) else {
                return
            }
            
            guard Globals.shared.media.all != nil else {
                //This is filtering, i.e. searching all mediaItems => s/b in background
                Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                    return mediaItem.category == Globals.shared.mediaCategory.selected
                }), tag: newValue))
                return
            }

            Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[newValue.withoutPrefixes])
        }
    }
}

