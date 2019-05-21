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

    var audioDownloads : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == false) && (mediaItem.audioDownload?.exists == false)
            }).count
        }
    }
    
    var videoDownloads : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.videoDownload?.active == false) && (mediaItem.videoDownload?.exists == false)
            }).count
        }
    }
    
    var slidesDownloads : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.active == false) && (mediaItem.slidesDownload?.exists == false)
            }).count
        }
    }
    
    var notesDownloads : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.active == false) && (mediaItem.notesDownload?.exists == false)
            }).count
        }
    }
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MLGS:" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 2 // Slides and Notes
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
        mediaQueue.cancelAllOperations()
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
    
    lazy var mediaQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MLGS-MEDIA:" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
        return operationQueue
    }()

    func downloadAllAudio()
    {
        guard let list = list else {
            return
        }

        for mediaItem in list {
            let download = mediaItem.audioDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            mediaQueue.addOperation(operation)
        }
    }
    
    func downloadAllVideo()
    {
        guard let list = list else {
            return
        }
        
        for mediaItem in list {
            let download = mediaItem.videoDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            mediaQueue.addOperation(operation)
        }
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
                
                let download = mediaItem.notesDownload
                
                if download?.exists == true  {
                    continue
                }
                
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
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
                
                let download = mediaItem.slidesDownload
                                
                if download?.exists == true  {
                    continue
                }
                
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
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

