//
//  Storage.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract class for a dictionary backed class, i.e. properties are values in the dictionary
 
 - Property: storage:[String:Any]?
 
 Custom subscript that accepts String? for access.
 
 */

class Storage
{
    var storage:[String:Any]?
    
    subscript(key:String?) -> Any?
    {
        get {
            guard let key = key else {
                return nil
            }
            return storage?[key]
        }
        set {
            guard let key = key else {
                return
            }
            storage?[key] = newValue
        }
    }
    
    init?(_ storage:[String:Any]?)
    {
        guard let storage = storage else {
            return nil
        }
        
        self.storage = storage
    }
    
    deinit {
        debug(self)
    }
}

