//
//  MediaTeacher.swift
//  CBC
//
//  Created by Steve Leeke on 3/28/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 - Properties:
     - status: this is a title that indicates their status, e.g. Pastor-Teacher or Staff Pastor.
     - Paragraphs: fetch properties about transcript paragraphs characterisitics use in setting paragraph boundaries automatically.
 
 */

class Teacher : Suffix
{
    var status : String?
    {
        get {
            return self[Field.status] as? String
        }
    }
}
