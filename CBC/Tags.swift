//
//  Tags.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Simple class to handle whether a tag is selected and if so,
 the creation of the list of mediaItems that have it.
 
 Properties:
    - showing
    - selected

 Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
 Problems went away when I switched to class.

 */

class Tags
{
    weak var media:Media?
    
    init(media:Media?)
    {
        self.media = media
    }
    
    deinit {
        debug(self)
    }
    
    // Is tagged really necessary?
    // It's the same as:
    
    func tagged(tag:String?) -> MediaListGroupSort?
    {
        guard let tag = tag else {
            return nil
        }
        
        return MediaListGroupSort(mediaItems: media?.all?.tagMediaItems?[tag.withoutPrefixes])
    }
    
    // The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = ThreadSafeDN<MediaListGroupSort>(name: UUID().uuidString + "TAGGED") // [String:MediaListGroupSort]() // ictionary
    
    var showing:String?
    {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String?
    {
        get {
            return media?.category.tag
        }
        set {
            media?.category.tag = newValue

            guard !Globals.shared.isLoading, media?.repository.list != nil else {
                return
            }
            
            guard let newValue = newValue else {
                return
            }

            guard (tagged[newValue] == nil) else {
                return
            }
            
            guard media?.all != nil else {
                //This is filtering, i.e. searching all mediaItems => s/b in background
                tagged[newValue] = MediaListGroupSort(mediaItems: media?.repository.list?.filter({ (mediaItem) -> Bool in
                    return mediaItem.category == media?.category.selected
                }).withTag(tag: newValue))
                return
            }

            tagged[newValue] = MediaListGroupSort(mediaItems: media?.all?.tagMediaItems?[newValue.withoutPrefixes])
            
            _ = tagged[newValue]?.lexicon?.eligible
            _ = tagged[newValue]?.scriptureIndex?.eligible
        }
    }
}

