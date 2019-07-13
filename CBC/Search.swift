//
//  Search.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Manages everything search related for the Media class.
 
 */

class Search
{
    weak var media : Media?
    
    init(_ media:Media?)
    {
        self.media = media
    }
    
    deinit {
        debug(self)
    }

    lazy var searches : ThreadSafeDN<MediaListGroupSort>? = { // [String:MediaListGroupSort]? // ictionary
        return ThreadSafeDN<MediaListGroupSort>(name: "SEARCH" + UUID().uuidString)
    }()
    
    var candidates : MediaListGroupSort?
    {
        get {
            var toSearch:MediaListGroupSort?
            
            if let showing = media?.tags.showing {
                switch showing {
                case Constants.TAGGED:
                    if let selected = media?.tags.selected {
                        toSearch = media?.tags.tagged[selected]
                    }
                    break
                    
                case Constants.ALL:
                    toSearch = media?.all
                    break
                    
                default:
                    break
                }
            }
            
            return toSearch
        }
    }
    
    var current:MediaListGroupSort?
    {
        get {
            guard let context = media?.active?.context else { // text
                return nil
            }
            
            return searches?[context] // Globals.shared.media.toSearch?.
        }
        
        set {
            guard let context = media?.active?.context else { // text
                return
            }
            
            searches?[context] = newValue // Globals.shared.media.toSearch?.
        }
    }

    var isActive:Bool = false
    {
        willSet {
            
        }
        didSet {

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
            return !(text?.isEmpty ?? true)
        }
    }
    
    var _text:String?
    {
        willSet {
            
        }
        didSet {
            guard _text != oldValue else {
                return
            }
            
            guard !Globals.shared.isLoading else {
                return
            }
            
            if isExtant {
                UserDefaults.standard.set(_text, forKey: Constants.SEARCH_TEXT)
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                UserDefaults.standard.synchronize()
            }
        }
    }
    var text:String?
    {
        get {
            return _text
        }
        set {
            _text = newValue
        }
    }

    // In case we want different transcripts search switch in different MLGS's some day?
    var transcripts : Bool // lazy Default<Bool>({ return Globals.shared.settings.transcripts })
    {
        get {
            return Globals.shared.settings.transcripts
        }
        set {
            Globals.shared.settings.transcripts = newValue
        }
    }
//    var transcripts:Bool
//    {
//        get {
//            return UserDefaults.standard.bool(forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SETTINGS.SEARCH_TRANSCRIPTS)
//            UserDefaults.standard.synchronize()
//        }
//    }
}

