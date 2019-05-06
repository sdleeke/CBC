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
    deinit {
        debug(self)
    }

    lazy var searches : ThreadSafeDN<MediaListGroupSort>? = { // [String:MediaListGroupSort]? // ictionary
        return ThreadSafeDN<MediaListGroupSort>(name: "SEARCH" + UUID().uuidString)
    }()
    
    var current:MediaListGroupSort?
    {
        get {
            guard let context = Globals.shared.media.active?.context else { // text
                return nil
            }
            
            return searches?[context] // Globals.shared.media.toSearch?.
        }
        
        set {
            guard let context = Globals.shared.media.active?.context else { // text
                return
            }
            
            searches?[context] = newValue // Globals.shared.media.toSearch?.
        }
    }

//    var complete:Bool
//    {
//        get {
//            guard let text = text else {
//                return false
//            }
//
//            return Globals.shared.media.toSearch?.searches?[text]?.complete ?? false
//        }
//
//        set {
//            guard let text = text else {
//                return
//            }
//
//            Globals.shared.media.toSearch?.searches?[text]?.complete = newValue
//        }
//    }
    
//    var cancelled:Bool
//    {
//        get {
//            guard let text = text else {
//                return false
//            }
//
//            return Globals.shared.media.toSearch?.searches?[text]?.cancelled ?? false
//        }
//
//        set {
//            guard let text = text else {
//                return
//            }
//
//            Globals.shared.media.toSearch?.searches?[text]?.cancelled = newValue
//        }
//    }
    
//    var results:MediaListGroupSort?
//    {
//        get {
//            guard let text = text else {
//                return nil
//            }
//            
//            return Globals.shared.media.toSearch?.searches?[text]
//        }
//        
//        set {
//            guard let text = text else {
//                return
//            }
//            
//            Globals.shared.media.toSearch?.searches?[text] = newValue
//        }
//    }

//    var complete:Bool = true
//    var cancelled:Bool = false

    var isActive:Bool = false
    {
        willSet {
            
        }
        didSet {
            if !isActive {
//                complete = true
            }
        }
    }
    
    var isValid:Bool
    {
        get {
            return isActive && isExtant
        }
    }
    
    var isExtant:Bool
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
            
            if isExtant {
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
            // Globals.shared.media.toSearch?.
//            searches = ThreadSafeDN<MediaListGroupSort>(name: UUID().uuidString + "SEARCH") // [String:MediaListGroupSort]() // ictionary
            
            searches?.clear()
            
            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
}

