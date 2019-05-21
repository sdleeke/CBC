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

/**

 Simple class to handle whether a tag is selected and if so,
 the creation of the list of mediaItems that have it.
 
 Properties:
    - showing
    - selected
 
 */

class Tags
{
//    weak var globals:Globals!
    
    deinit {
        debug(self)
    }
    
    var showing:String?
    {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String?
    {
        get {
            return Globals.shared.media.category.tag
        }
        set {
            Globals.shared.media.category.tag = newValue

            guard !Globals.shared.isLoading, Globals.shared.media.repository.list != nil else {
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
                Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                    return mediaItem.category == Globals.shared.media.category.selected
                }).withTag(tag: newValue))
                return
            }

            Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[newValue.withoutPrefixes])
        }
    }
}

