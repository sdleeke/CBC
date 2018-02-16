//
//  SelectedMediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SelectedMediaItem {
    weak var globals:Globals!
    
    var master:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = globals.mediaCategory.selectedInMaster {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            globals.mediaCategory.selectedInMaster = newValue?.id
        }
    }
    
    var detail:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = globals.mediaCategory.selectedInDetail {
                selectedMediaItem = globals.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            globals.mediaCategory.selectedInDetail = newValue?.id
        }
    }
}

