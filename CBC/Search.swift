//
//  Search.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Search
{
    var complete:Bool = true
    
    var active:Bool = false
    {
        willSet {
            
        }
        didSet {
            if !active {
                complete = true
            }
        }
    }
    
    var valid:Bool
    {
        get {
            return active && extant
        }
    }
    
    var extant:Bool
    {
        get {
            if let isEmpty = text?.isEmpty {
                return !isEmpty
            } else {
                return false
            }
        }
    }
    
    var text:String?
    {
        willSet {
            
        }
        didSet {
            guard text != oldValue else {
                return
            }
            
            guard !Globals.shared.isLoading else {
                return
            }
            
            if extant {
                UserDefaults.standard.set(text, forKey: Constants.SEARCH_TEXT)
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    var transcripts:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            // Setting to nil can cause a crash.
            Globals.shared.media.toSearch?.searches = ThreadSafeDictionary<MediaListGroupSort>(name: UUID().uuidString + "SEARCH") // [String:MediaListGroupSort]()
            
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
}

