//
//  StreamEntry.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Use for live events.
 
 */

class StreamEntry : Base
{
    var start : Int?
    {
        get {
            return self["start"] as? Int ?? Streaming(self["streaming"] as? [String:Any])?.startTs
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
            return self["end"] as? Int ?? Streaming(self["streaming"] as? [String:Any])?.endTs
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
    
    var date : String?
    {
        get {
            return self["date"] as? String
        }
    }
    
    var title : String?
    {
        get {
            if let name = name {
                return name
            }
            
            var string = ""
            
//            if let category = Category(self["category"] as? [String:Any])?.name {
//                string = category
//            }

            if let title = self["title"] as? String {
                string = string.isEmpty ? title : string + ": " + title
            }

            if let teacher = Teacher(self["teacher"] as? [String:Any])?.name {
                string = string.isEmpty ? teacher : string + ": " + teacher
            }

            return !string.isEmpty ? string : nil
        }
    }
    
    var text : String?
    {
        get {
            if let title = title, let start = startDate?.mdyhm, let end = endDate?.mdyhm {
                return "\(title)\nStart: \(start)\nEnd: \(end)"
            } else {
                return nil
            }
        }
    }
}
