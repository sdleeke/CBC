//
//  Display.swift
//  CBC
//
//  Created by Steve Leeke on 10/15/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Display
{
    var mediaItems:[MediaItem]?
    var section = Section(stringsAction: nil)
    
    func setup(_ active:MediaListGroupSort? = nil)
    {
        mediaItems = active?.mediaItems
        
        section.showHeaders = true
        
        section.headerStrings = active?.section?.headerStrings
        section.indexStrings = active?.section?.indexStrings
        section.indexes = active?.section?.indexes
        section.counts = active?.section?.counts
    }
    
    func clear()
    {
        mediaItems = nil
        
        section.clear()
    }
}

