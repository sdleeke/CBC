//
//  Streaming.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Dictionary backed class for streaming entries
 
 */

class Streaming : Storage
{
    var liveNow : Bool?
    {
        get {
            return self["liveNow"] as? Bool
        }
    }
    
    var start : String?
    {
        get {
            return self["start"] as? String
        }
    }
    
    var startDate : Date?
    {
        get {
            if let start = start, !start.isEmpty {
                return Date(y_m_d: start)
            } else {
                return nil
            }
        }
    }
    
    var end : String?
    {
        get {
            return self["end"] as? String
        }
    }
    
    var endDate : Date?
    {
        get {
            if let end = end, !end.isEmpty {
                return Date(y_m_d: end)
            } else {
                return nil
            }
        }
    }
    
    var startTs : Int?
    {
        get {
            return self["startTs"] as? Int
        }
    }
    
    var endTs : Int?
    {
        get {
            return self["endTs"] as? Int
        }
    }
}
