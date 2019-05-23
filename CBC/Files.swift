//
//  Files.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Dictionary backed class that has properties for file urls.
 
 Properties:
 - slides
 - transcript
 - outline
 - html
 */

class Files : Storage
{
    var slides : String?
    {
        get {
            return self[Field.slides] as? String
        }
    }
    
    var notes : String?
    {
        get {
            return self[Field.notes] as? String
        }
    }
    
    var notesHTML : String?
    {
        get {
            return self[Field.notes_html] as? String
        }
    }
    
    var transcript : String?
    {
        get {
            return self[Field.transcript] as? String
        }
    }
    
    var transcriptHTML : String?
    {
        get {
            return self[Field.transcript_html] as? String
        }
    }
    
    var outline : String?
    {
        get {
            return self[Field.outline] as? String
        }
    }
}

