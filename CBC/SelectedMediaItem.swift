//
//  SelectedMediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SelectedMediaItem
{
    var master:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInMaster {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            if newValue?.category == Globals.shared.mediaCategory.selected {
                Globals.shared.mediaCategory.selectedInMaster = newValue?.id
            }
        }
    }
    
    var detail:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = UserDefaults.standard.string(forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL) {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        set {
            UserDefaults.standard.set(newValue?.id, forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL)
            UserDefaults.standard.synchronize()
        }

//        get {
//            var selectedMediaItem:MediaItem?
//
//            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInDetail {
//                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
//            }
//
//            return selectedMediaItem
//        }
//
//        set {
//            Globals.shared.mediaCategory.selectedInDetail = newValue?.id
//        }
    }
}

