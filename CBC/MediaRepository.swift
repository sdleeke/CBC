//
//  MediaRepository.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaRepository
{
    var list:[MediaItem]? // Not in any specific order
    {
        willSet {
            
        }
        didSet {
            guard let list = list else {
                return
            }
            
            index = nil
            for mediaItem in list {
                if let id = mediaItem.id {
                    if index == nil {
                        index = [String:MediaItem]()
                    }
                    if index?[id] == nil {
                        index?[id] = mediaItem
                    } else {
                        print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
            }
        }
    }
    
    // Make thread safe?
    var index:[String:MediaItem]?
}

