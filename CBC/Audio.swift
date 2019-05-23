//
//  Audio.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract dictionary backed class for audio
 
 Parameters:
 - mp3 url
 - duration
 - file size
 */

class Audio : Storage
{
    var mp3 : String?
    {
        return self[Field.mp3] as? String
    }
    
    var duration : String?
    {
        return self[Field.duration] as? String
    }
    
    var filesize : Int?
    {
        get {
            guard let filesize = self[Field.filesize] as? String else {
                return nil
            }
            
            return Int(filesize)
        }
    }
}
