//
//  Video.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Abstract dictionary backed class for video
 
 - Properties:
     - mp4 url
     - m3u8 url
     - poster url
 
 */

class Video : Storage
{
    var mp4 : String?
    {
        return self[Field.vimeo_mp4] as? String
    }
    
    var m3u8 : String?
    {
        return self[Field.vimeo_m3u8] as? String
    }
    
    var poster : String?
    {
        return self[Field.poster] as? String
    }
}
