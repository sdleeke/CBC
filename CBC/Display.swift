//
//  Display.swift
//  CBC
//
//  Created by Steve Leeke on 10/15/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**
 For managing the list of mediaItems displayed in the MTVC.
 */

class Display
{
    deinit {
        debug(self)
    }
    
    var mediaItems:[MediaItem]?
    var section = Section(tableView:nil, stringsAction:nil)
    
    func setup(_ active:MediaListGroupSort? = nil)
    {
        active?.groupings = Constants.groupings
        active?.groupingTitles = Constants.GroupingTitles
        
        if active?.mediaList?.classes.count > 0 {
            active?.groupings.append(GROUPING.CLASS)
            active?.groupingTitles.append(Grouping.Class)
        }
        
        if active?.mediaList?.events.count > 0 {
            active?.groupings.append(GROUPING.EVENT)
            active?.groupingTitles.append(Grouping.Event)
        }
        
        if let grouping = active?.grouping, active?.groupings.contains(grouping) == false {
            active?.grouping = GROUPING.YEAR
        }

        // Why is the section being recreated?
        active?.section = MLGSSection(active)
        
        mediaItems = active?.section?.mediaItems

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

