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
    var cacheSize : Int?
    {
        get {
            return list?.reduce(0, { (result, mediaItem) -> Int in
                return result + mediaItem.cacheSize
            })
        }
    }
    
    func cacheSize(_ purpose:String) -> Int?
    {
        return list?.reduce(0, { (result, mediaItem) -> Int in
            return result + mediaItem.cacheSize(purpose)
        })
    }
    
    func cancelAllDownloads()
    {
        guard let list = list else {
            return
        }
        
        for mediaItem in list {
            for download in mediaItem.downloads.values {
                if download.active {
                    download.task?.cancel()
                    download.task = nil
                    
                    download.totalBytesWritten = 0
                    download.totalBytesExpectedToWrite = 0
                    
                    download.state = .none
                }
            }
        }
    }
    
    func loadTokenCountMarkCountMismatches()
    {
        guard let list = list else {
            return
        }
        
        list.forEach { (mediaItem) in
            mediaItem.loadTokenCountMarkCountMismatches()
        }
    }
    
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

