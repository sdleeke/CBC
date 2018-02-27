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
    init?(_ dict:[String:Any]?)
    {
        guard dict != nil else {
            return nil
        }
        
        self.dict = dict
    }
    
    var dict : [String:Any]?
    
    var id : Int?
    {
        get {
            return dict?["id"] as? Int
        }
    }
    
    var start : Int?
    {
        get {
            return dict?["start"] as? Int
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
            return dict?["end"] as? Int
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
            return dict?["name"] as? String
        }
    }
    
    var date : String?
    {
        get {
            return dict?["date"] as? String
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
