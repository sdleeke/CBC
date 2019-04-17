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
    deinit {
        debug(self)
    }
    
    var master:MediaItem?
    {
        get {
            // This returns according to the currently selected category.
            
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInMaster {
                selectedMediaItem = Globals.shared.mediaRepository.index[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            if let relevantHistoryFirst = Globals.shared.relevantHistoryFirst {
                if newValue?.id != relevantHistoryFirst.id {
                    Globals.shared.addToHistory(newValue)
                }
            } else {
                Globals.shared.addToHistory(newValue)
            }

            if let category = newValue?.category {
                // Set according to mediaItem category not whatever is selected.
                Globals.shared.mediaCategory.settings[category,Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue?.id
                // For a high volume of activity this can be very expensive.
                Globals.shared.mediaCategory.saveSettingsBackground()

//                Globals.shared.mediaCategory.selectedInMaster = newValue?.id
                
//                var selectedInMaster:String?
//                {
//                    get {
//                        return self[Constants.SETTINGS.SELECTED_MEDIA.MASTER]
//                    }
//                    set {
//                        self[Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue
//                    }
//                }
            }
        }
    }
    
    var detail:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = UserDefaults.standard.string(forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL) {
                selectedMediaItem = Globals.shared.mediaRepository.index[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        set {
            if let relevantHistoryFirst = Globals.shared.relevantHistoryFirst {
                if newValue?.id != relevantHistoryFirst.id {
                    Globals.shared.addToHistory(newValue)
                }
            } else {
                Globals.shared.addToHistory(newValue)
            }

//            if (selectedMediaItem != mediaItems?[indexPath.row]) || (Globals.shared.history == nil) {
//                Globals.shared.addToHistory(mediaItems?[indexPath.row])
//            }
            
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.id, forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL)
            }
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

