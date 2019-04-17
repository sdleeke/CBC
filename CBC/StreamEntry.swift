//
//  StreamEntry.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class StreamEntry
{
    deinit {
        debug(self)
    }
    
    init?(_ storage:[String:Any]?)
    {
        guard storage != nil else {
            return nil
        }
        
        self.storage = storage
    }
    
    // Make thread safe?
    var storage : [String:Any]?
    
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

    var id : Int?
    {
        get {
            return self["id"] as? Int
        }
    }
    
    var start : Int?
    {
        get {
            return self["start"] as? Int
        }
    }
    
    var startDate : Date?
    {
        get {
            if let start = start {
                return Date(timeIntervalSince1970: TimeInterval(start))
            } else {
                return nil
            }
        }
    }
    
    var end : Int?
    {
        get {
            return self["end"] as? Int
        }
    }
    
    var endDate : Date?
    {
        get {
            if let end = end {
                return Date(timeIntervalSince1970: TimeInterval(end))
            } else {
                return nil
            }
        }
    }
    
    var name : String?
    {
        get {
            return self["name"] as? String
        }
    }
    
    var date : String?
    {
        get {
            return self["date"] as? String
        }
    }
    
    var text : String?
    {
        get {
            if let name = name, let start = startDate?.mdyhm, let end = endDate?.mdyhm {
                return "\(name)\nStart: \(start)\nEnd: \(end)"
            } else {
                return nil
            }
        }
    }
}
