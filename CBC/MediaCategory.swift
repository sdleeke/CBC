//
//  MediaCategory.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaCategory
{
//    var dicts = ThreadSafeDN<String>() // :[String:String]? // ictionary
//
//    var filename:String?
//    {
//        get {
//            guard let selectedID = selectedID else {
//                return nil
//            }
//
//            return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID + Constants.JSON.FILENAME_EXTENSION
//        }
//    }
//
//    var url:String?
//    {
//        get {
//            guard let selectedID = selectedID else {
//                return nil
//            }
//
//            return Constants.JSON.URL.CATEGORY + selectedID
//        }
//    }
//
//    var names:[String]?
//    {
//        get {
////            guard let dicts = dicts else {
////                return nil
////            }
//
//            guard let keys = dicts.keys() else {
//                return nil
//            }
//
//            guard keys.count > 0 else {
//                return nil
//            }
//
//            return Array(keys).sorted()
//        }
//    }
    
    // This doesn't work if we someday allow multiple categories to be selected at the same time - unless the string contains multiple categories, as with tags.
    // In that case it would need to be an array.  Not a big deal, just a change.
    var selected:String?
    {
        get {
            if UserDefaults.standard.object(forKey: Constants.MEDIA_CATEGORY) == nil {
                UserDefaults.standard.set(Constants.Strings.Sermons, forKey: Constants.MEDIA_CATEGORY)
            }
            
            return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
        }
        set {
            if newValue != nil {
                UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.MEDIA_CATEGORY)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
//    var selectedID:String?
//    {
//        get {
//            if let selected = selected {
//                return dicts[selected] // ?? "1" // Sermons are category 1
//            } else {
//                return nil
//            }
//        }
//    }
    
    var settings = ThreadSafeDN<String>(name: "CATEGORY" + "SETTINGS") // [String:[String:String]]? // ictionaryOfDictionaries
    
    var allowSaveSettings = true
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaCategorySettings" // Assumes there is only one globally
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    func saveSettingsBackground()
    {
        guard allowSaveSettings else {
            return
        }
        
        print("saveSettingsBackground")
        
        operationQueue.addOperation {
            self.saveSettings()
        }
    }
    
    func saveSettings()
    {
        guard allowSaveSettings else {
            return
        }
        
        print("saveSettings")
        let defaults = UserDefaults.standard
        defaults.set(settings.copy, forKey: Constants.SETTINGS.CATEGORY)
        defaults.synchronize()
    }

    subscript(key:String) -> String?
    {
        get {
            if let selected = selected {
                return settings[selected,key] // ]?[
            } else {
                return nil
            }
        }
        set {
            guard let selected = selected else {
                print("selected == nil!")
                return
            }
            
            if (settings[selected,key] != newValue) {
                settings[selected,key] = newValue
                
                // For a high volume of activity this can be very expensive.
                saveSettingsBackground()
            }
        }
    }
    
    var tag:String?
    {
        get {
            return self[Constants.SETTINGS.COLLECTION]
        }
        set {
            self[Constants.SETTINGS.COLLECTION] = newValue
        }
    }
    
    var playing:String?
    {
        get {
            return self[Constants.SETTINGS.MEDIA_PLAYING]
        }
        set {
            self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
        }
    }
    
    var selectedInMaster:String?
    {
        get {
            return self[Constants.SETTINGS.SELECTED_MEDIA.MASTER]
        }
        set {
            self[Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String?
    {
        get {
            return self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL]
        }
        set {
            self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL] = newValue
        }
    }
}

