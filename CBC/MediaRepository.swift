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
    func clearCache()
    {
        list?.forEach({ (mediaItem) in
            mediaItem.clearCache()
        })
    }
    
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

    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MLGS:" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func cancelAllDownloads()
    {
        operationQueue.addOperation {
            self.list?.forEach({ (mediaItem) in
                mediaItem.downloads.values.forEach({ (download) in
                    download.cancel()
                })
            })
        }
    }
    
    func deleteAllDownloads()
    {
        operationQueue.addOperation {
            self.list?.forEach({ (mediaItem) in
                mediaItem.downloads.values.forEach({ (download) in
                    download.delete()
                })
            })
        }
    }
    
    func downloadAllAudio()
    {
        guard let list = list else {
            return
        }
        
        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
            for mediaItem in list {
                if test?() == true {
                    break
                }
                
                if mediaItem.audioDownload?.exists == true  {
                    continue
                }
                
                _ = mediaItem.audioDownload?.download()
                
                while mediaItem.audioDownload?.state == .downloading {
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func downloadAllVideo()
    {
        guard let list = list else {
            return
        }
        
        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
            for mediaItem in list {
                if test?() == true {
                    break
                }
                
                if mediaItem.videoDownload?.exists == true  {
                    continue
                }
                
                _ = mediaItem.audioDownload?.download()
                
                while mediaItem.audioDownload?.state == .downloading {
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func downloadAllNotes()
    {
        guard let list = list else {
            return
        }
        
        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
            for mediaItem in list {
                if test?() == true {
                    break
                }
                
                if mediaItem.notesDownload?.exists == true {
                    continue
                }
                
                _ = mediaItem.notesDownload?.downloadURL?.data?.save(to: mediaItem.notesDownload?.fileSystemURL)
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func downloadAllSlides()
    {
        guard let list = list else {
            return
        }
        
        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
            for mediaItem in list {
                if test?() == true {
                    break
                }
                
                if mediaItem.slidesDownload?.exists == true {
                    continue
                }
                
                _ = mediaItem.slidesDownload?.downloadURL?.data?.save(to: mediaItem.slidesDownload?.fileSystemURL)
            }
        }
        
        operationQueue.addOperation(operation)
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

