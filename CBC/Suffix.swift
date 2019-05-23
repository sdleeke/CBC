//
//  Suffix.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract dictionary backed class with id/name
 
 */

class Suffix : Base
{
    var suffix : String?
    {
        get {
            return self[Field.suffix] as? String
        }
    }
}

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Category : Suffix
{
    
}

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Group : Suffix
{
    
}

