//
//  MediaCategory.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaCategory {
    // Make thread safe?
    var dicts:[String:String]?
    
    var filename:String? {
        get {
            guard let selectedID = selectedID else {
                return nil
            }
            
            return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID +  Constants.JSON.FILENAME_EXTENSION
        }
    }
    
    var url:String? {
        get {
            guard let selectedID = selectedID else {
                return nil
            }
            
            return Constants.JSON.URL.CATEGORY + selectedID // CATEGORY + selectedID!
        }
    }
    
    // Make thread safe?
    var names:[String]? {
        get {
            guard let dicts = dicts else {
                return nil
            }
            
            return Array(dicts.keys).sorted()
            
            //                return dicts?.keys.map({ (key:String) -> String in
            //                    return key
            //                }).sorted()
        }
    }
    
    // This doesn't work if we someday allow multiple categories to be selected at the same time - unless the string contains multiple categories, as with tags.
    // In that case it would need to be an array.  Not a big deal, just a change.
    var selected:String? {
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
    
    var selectedID:String? {
        get {
            if let selected = selected {
                return dicts?[selected] ?? "1" // Sermons are category 1
            } else {
                return nil
            }
        }
    }
    
    // Make thread safe?
    var settings = ThreadSafeDictionaryOfDictionaries<String>(name: "CATEGORY" + "SETTINGS") // [String:[String:String]]? // = Settings() // ThreadSafeDictionary<[String:String]>
    
    // Using a generic does not include the methods for save and saveBackground.
    // Those would have to be part of the initialization configuration
    
//    class Settings {
//        var storage : [String:[String:String]]?
//
//        init(storage:[String:[String:String]]?)
//        {
//            self.storage = storage
//        }
//
//        // Make it threadsafe
//        let queue = DispatchQueue(label: "Settings")
//
//        subscript(key:String?) -> [String:String]? {
//            get {
//                return queue.sync {
//                    guard let key = key else {
//                        return nil
//                    }
//
//                    return storage?[key]
//                }
//            }
//            set {
//                queue.sync {
//                    guard let key = key else {
//                        return
//                    }
//
//                    if storage == nil, newValue != nil {
//                        storage = [String:[String:String]]()
//                    }
//
//                    storage?[key] = newValue
//                }
//            }
//        }
//
//        var allowSave = true
//
//        func saveBackground()
//        {
//            guard allowSave else {
//                return
//            }
//
//            print("saveSettingsBackground")
//
//            DispatchQueue.global(qos: .background).async { // [weak self] in
//                self.save()
//            }
//        }
//
//        func save()
//        {
//            guard allowSave else {
//                return
//            }
//
//            print("saveSettings")
//            let defaults = UserDefaults.standard
//            defaults.set(storage, forKey: Constants.SETTINGS.CATEGORY)
//            defaults.synchronize()
//        }
//    }
    
    var allowSaveSettings = true
    
    func saveSettingsBackground()
    {
        guard allowSaveSettings else {
            return
        }
        
        print("saveSettingsBackground")
        
        DispatchQueue.global(qos: .background).async { // [weak self] in
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

    subscript(key:String) -> String? {
        get {
            if let selected = selected {
                return settings[selected]?[key]
            } else {
                return nil
            }
        }
        set {
            guard let selected = selected else {
                print("selected == nil!")
                return
            }
            
//            if settings == nil {
//                settings = ThreadSafeDictionaryOfDictionaries<String>(name: "CATEGORY" + "SETTINGS") // [String:[String:String]]()
//            }
            
//            guard (settings != nil) else {
//                print("settings == nil!")
//                return
//            }
            
//            if (settings?[selected] == nil) {
//                settings?[selected] = [String:String]()
//            }
            if (settings[selected,key] != newValue) {
                settings[selected,key] = newValue
                
                // For a high volume of activity this can be very expensive.
                saveSettingsBackground()
            }
        }
    }
    
    var tag:String? {
        get {
            return self[Constants.SETTINGS.COLLECTION]
        }
        set {
            self[Constants.SETTINGS.COLLECTION] = newValue
        }
    }
    
    var playing:String? {
        get {
            return self[Constants.SETTINGS.MEDIA_PLAYING]
        }
        set {
            self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
        }
    }
    
    var selectedInMaster:String? {
        get {
            return self[Constants.SETTINGS.SELECTED_MEDIA.MASTER]
        }
        set {
            self[Constants.SETTINGS.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String? {
        get {
            return self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL]
        }
        set {
            self[Constants.SETTINGS.SELECTED_MEDIA.DETAIL] = newValue
        }
    }
}

