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
        Globals.shared.groupings = Constants.groupings
        Globals.shared.groupingTitles = Constants.GroupingTitles
        
        if active?.mediaList?.classes.count > 0 {
            Globals.shared.groupings.append(GROUPING.CLASS)
            Globals.shared.groupingTitles.append(Grouping.Class)
        }
        
        if active?.mediaList?.events.count > 0 {
            Globals.shared.groupings.append(GROUPING.EVENT)
            Globals.shared.groupingTitles.append(Grouping.Event)
        }
        
        if let grouping = Globals.shared.grouping, !Globals.shared.groupings.contains(grouping) {
            Globals.shared.grouping = GROUPING.YEAR
        }

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

