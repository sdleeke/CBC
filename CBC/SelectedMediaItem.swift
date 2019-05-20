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
 
 All updates history list for media items selected.
 
 */

class SelectedMediaItem
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
            
            if let selectedMediaItemID = media?.category.selectedInMaster {
                selectedMediaItem = media?.repository.index[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            if let relevantHistoryFirst = media?.relevantHistoryFirst {
                if newValue?.mediaCode != relevantHistoryFirst.mediaCode {
                    media?.addToHistory(newValue)
                }
            } else {
                media?.addToHistory(newValue)
            }

            media?.category.selectedInMaster = newValue?.mediaCode

//            if let category = newValue?.category {
//                // Set according to mediaItem category not whatever is selected.
//                Globals.shared.media.category.settings[category,Constants.SETTINGS.SELECTED_MEDIA.MASTER]
//                // For a high volume of activity this can be very expensive.
////                Globals.shared.media.category.saveSettingsBackground()
//
////                Globals.shared.media.category.selectedInMaster = newValue?.mediaCode
//
////                var selectedInMaster:String?
////                {
////                    get {
////                        return self[Constants.SETTINGS.SELECTED_MEDIA.MASTER]
////                    }
////                    set {
////                        self[Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue
////                    }
////                }
//            }
        }
    }
    
    var detail:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = media?.category.selectedInDetail {
                selectedMediaItem = media?.repository.index[selectedMediaItemID]
            }
            
//            if let selectedMediaItemID = UserDefaults.standard.string(forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL) {
//                selectedMediaItem = Globals.shared.media.repository.index[selectedMediaItemID]
//            }
            
            return selectedMediaItem
        }
        set {
            if let relevantHistoryFirst = media?.relevantHistoryFirst {
                if newValue?.mediaCode != relevantHistoryFirst.mediaCode {
                    media?.addToHistory(newValue)
                }
            } else {
                media?.addToHistory(newValue)
            }

            media?.category.selectedInDetail = newValue?.mediaCode

//            if (selectedMediaItem != mediaItems?[indexPath.row]) || (Globals.shared.history == nil) {
//                Globals.shared.addToHistory(mediaItems?[indexPath.row])
//            }
            
//            if let newValue = newValue {
//                UserDefaults.standard.set(newValue.mediaCode, forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL)
//            } else {
//                UserDefaults.standard.removeObject(forKey: Constants.SETTINGS.SELECTED_MEDIA.DETAIL)
//            }
//            UserDefaults.standard.synchronize()
        }

//        get {
//            var selectedMediaItem:MediaItem?
//
//            if let selectedMediaItemID = Globals.shared.media.category.selectedInDetail {
//                selectedMediaItem = Globals.shared.media.repository.index?[selectedMediaItemID]
//            }
//
//            return selectedMediaItem
//        }
//
//        set {
//            Globals.shared.media.category.selectedInDetail = newValue?.mediaCode
//        }
    }
}

