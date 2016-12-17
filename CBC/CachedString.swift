//
//  CachedString.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation

class CachedString {
    @objc func freeMemory()
    {
        cache = [String:String]()
    }
    
    var index:(()->String?)?
    
    var cache = [String:String]()
    
    // if index DOES NOT produce the full key
    subscript(key:String?) -> String? {
        get {
            guard key != nil else {
                return nil
            }
            
            if let index = self.index?() {
                return cache[index+":"+key!]
            } else {
                return cache[key!]
            }
        }
        set {
            guard key != nil else {
                return
            }
            
            if let index = self.index?() {
                cache[index+":"+key!] = newValue
            } else {
                cache[key!] = newValue
            }
        }
    }
    
    // if index DOES produce the full key
    var string:String? {
        get {
            if let index = self.index?() {
                return cache[index]
            } else {
                return nil
            }
        }
        set {
            if let index = self.index?() {
                cache[index] = newValue
            }
        }
    }
    
    init(index:(()->String?)?)
    {
        self.index = index
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(CachedString.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
}
