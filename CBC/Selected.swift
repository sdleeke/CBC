//
//  SelectedMediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Simple class to track the media item selected in master and detail views for the current category
 
 Updates history list for media items selected.
 
 */

class Selected
{
    weak var media : Media?
    
    init(_ media:Media?)
    {
        self.media = media
    }
    
    deinit {
        debug(self)
    }
    
    var master:MediaItem?
    {
        get {
            // This returns according to the currently selected category.
            
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = media?.category.selectedInMaster, !selectedMediaItemID.isEmpty {
                selectedMediaItem = media?.repository.index[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            if let relevantHistoryFirst = media?.history.relevantFirst {
                if newValue?.mediaCode != relevantHistoryFirst.mediaCode {
                    media?.history.add(newValue)
                }
            } else {
                media?.history.add(newValue)
            }

            media?.category.selectedInMaster = newValue?.mediaCode
        }
    }
    
    var detail:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = media?.category.selectedInDetail, !selectedMediaItemID.isEmpty {
                selectedMediaItem = media?.repository.index[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        set {
            if let relevantHistoryFirst = media?.history.relevantFirst {
                if newValue?.mediaCode != relevantHistoryFirst.mediaCode {
                    media?.history.add(newValue)
                }
            } else {
                media?.history.add(newValue)
            }

            media?.category.selectedInDetail = newValue?.mediaCode
        }
    }
}

