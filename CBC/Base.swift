//
//  Base.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract dictionary backed class
 
 - Properties:
     - id
     - name
 
 */

class Base : Storage
{
    var id : String? // New API: Int?
    {
        get {
            return self[Field.id] as? String // New API: Int
        }
    }
    
    var name : String?
    {
        get {
            return self[Field.name] as? String
        }
    }
}

/**
 
 Abstract dictionary backed class with id/name
 
 */

class Series : Base
{
    
}

/**
 
 Abstract dictionary backed class with id/name
 
 */

class Event : Base
{
    
}

