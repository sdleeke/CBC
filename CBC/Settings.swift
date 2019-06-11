//
//  Settings.swift
//  Podscribe
//
//  Created by Steve Leeke on 6/11/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

class Settings
{
    var transcripts:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var autoAdvance:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool
    {
        get {
            if UserDefaults.standard.object(forKey: Constants.SETTINGS.CACHE_DOWNLOADS) == nil {
                if #available(iOS 9.0, *) {
                    UserDefaults.standard.set(true, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
                } else {
                    UserDefaults.standard.set(false, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
                }
            }
            
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.CACHE_DOWNLOADS)
            UserDefaults.standard.synchronize()
        }
    }
}
