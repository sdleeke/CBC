//
//  MediaRepository.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

/**
 
 Handles lists of media items, maintains an index to them, performs bulk operations.
 
 */

class MediaList // : Sequence
{
    var count : Int?
    {
        return list?.count
    }
    
    lazy var checkIn : CheckIn = {
        return CheckIn()
    }()
    
    func deleteAllVoiceBaseMedia(alert:Bool,detailedAlert:Bool)
    {
        guard let list = list?.filter({ (mediaItem:MediaItem) -> Bool in
            return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                return transcript.mediaID != nil
            }).count > 0
        }) else {
            Alerts.shared.alert(title: "No VoiceBase Media Were Deleted", message:self.list?.multiPartName)
            return
        }
        
        checkIn.reset()
        checkIn.total = list.reduce(0, { (result, mediaItem) -> Int in
            return result + mediaItem.transcripts.values.filter({ (voiceBase:VoiceBase) -> Bool in
                return voiceBase.mediaID != nil
            }).count
        })
        
        let monitorOperation = CancelableOperation() { [weak self] (test:(()->Bool)?) in
            // How do I know all of the deletions were successful?
            
            guard let checkIn = self?.checkIn else {
                return
            }
            
            while ((checkIn.success + checkIn.failure) < checkIn.total) {
                Thread.sleep(forTimeInterval: 1.0)
            }

            var preamble = String()
            
            if checkIn.success == checkIn.total, checkIn.failure == 0 {
                preamble = "All "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.list?.multiPartName)
            }
            
            if checkIn.failure == checkIn.total, checkIn.success == 0 {
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.list?.multiPartName)
                
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Found\n(\(checkIn.failure) of \(checkIn.total))", message:self?.list?.multiPartName)
            }
            
            if checkIn.failure > 0, checkIn.failure < checkIn.total, checkIn.success > 0, checkIn.success < checkIn.total {
                preamble = "Some "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.list?.multiPartName)
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Not Found\n(\(checkIn.failure) of \(checkIn.total))", message:self?.list?.multiPartName)
            }
        }
        
        list.forEach({ (mediaItem:MediaItem) in
            mediaItem.transcripts.values.forEach({ (voiceBase:VoiceBase) in
                if voiceBase.mediaID != nil {
                    let operation = CancelableOperation() { [weak self] (test:(()->Bool)?) in
                        voiceBase.delete(alert:detailedAlert,
                                         completion: { [weak self] (json:[String:Any]?) in
                                            if let success = self?.checkIn.success {
                                                self?.checkIn.success = success + 1
                                            }
                            },
                                         onError: { [weak self] (json:[String:Any]?) in
                                            if let failure = self?.checkIn.failure {
                                                self?.checkIn.failure = failure + 1
                                            }
                            }
                        )
                    }
                    
                    monitorOperation.addDependency(operation)
                    
                    /////////////////////////////////////////////////////////////////////////////////////////////////////////
                    // Will NOT work if opQueue's maxConcurrentOperationCount == 1 WHY??? (>1, i.e. 2 or more it works fine.)
                    // could it be that because delete() creates a dataTask that it needs a way to run that task on this
                    // same opQueue, which it can't if the maxConcurrent is 1 and the op that calls delete() is running,
                    // meaning both are blocked because the second, the dataTask, is.
                    /////////////////////////////////////////////////////////////////////////////////////////////////////////
                    mediaQueue.addOperation(operation)
                }
            })
        })
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Will NOT work if opQueue's maxConcurrentOperationCount == 1 WHY??? (>1, i.e. 2 or more it works fine.)
        // could it be that because delete() creates a dataTask that it needs a way to run that task on this
        // same opQueue, which it can't if the maxConcurrent is 1 and the op that calls delete() is running,
        // meaning both are blocked because the second, the dataTask, is.
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        mediaQueue.addOperation(monitorOperation)
    }
    
    func clearCache(block:Bool)
    {
        list?.forEach({ (mediaItem) in
            mediaItem.clearCache(block:block)
        })
    }
    
    var cacheSize : Int?
    {
        get {
            // THIS IS COMPUTATIONALLY EXPENSIVE TO CALL
            return list?.reduce(0, { (result, mediaItem) -> Int in
                return result + mediaItem.cacheSize
            })
        }
    }
    
    func cacheSize(_ purpose:String) -> Int?
    {
        // THIS IS COMPUTATIONALLY EXPENSIVE TO CALL
        return list?.reduce(0, { (result, mediaItem) -> Int in
            return result + mediaItem.cacheSize(purpose)
        })
    }
    
    func updateCacheSize()
    {
        operationQueue.addOperation { [weak self] in
            _ = self?.list?.reduce(0, { (result, mediaItem) -> Int in
                return result + mediaItem.cacheSize
            })
        }
    }

    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaList" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    func deleteAllDownloads(alert:Bool)
    {
        operationQueue.addOperation {
            self.list?.forEach({ (mediaItem) in
                // Could be audio, video, slides, or notes
                mediaItem.downloads?.values.forEach({ (download) in
                    download.delete(block:true)
                })
            })
            
            if alert {
                Alerts.shared.alert(title: "All Downloads Deleted", message: self.list?.multiPartName)
            }
        }
    }
    
    func deleteAllDownloads(purpose:String,name:String)
    {
        operationQueue.addOperation {
            var message = ""
            
            if let multiPartName = self.list?.multiPartName {
                message += multiPartName + "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            Alerts.shared.alert(title: "Deleting All \(name) Downloads", message: message)
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.downloads?[purpose]?.delete(block:true)
            })
            
            if self.list?.audioDownloaded == 0 {
                Alerts.shared.alert(title: "All \(name) Downloads Deleted", message: self.list?.multiPartName)
            } else {
                Alerts.shared.alert(title: "Some \(name) Downloads Were Not Deleted", message: self.list?.multiPartName)
            }
        }
    }
    
    func deleteAllAudioDownloads()
    {
        deleteAllDownloads(purpose: Purpose.audio, name: Constants.Strings.Audio)
    }
    
    func deleteAllVideoDownloads()
    {
        deleteAllDownloads(purpose: Purpose.video, name: Constants.Strings.Video)
    }
    
    func cancelAllDownloads()
    {
        operationQueue.addOperation {
            self.list?.forEach({ (mediaItem) in
                // Could be audio, video, slides, or notes
                mediaItem.downloads?.values.forEach({ (download) in
                    download.cancel()
                })
            })
        }
    }
    
    func cancelAllDownloads(purpose:String,name:String)
    {
        let notifyOperation = CancelableOperation { [weak self] (test:(()->Bool)?) in
            var message = ""
            
            if let multiPartName = self?.list?.multiPartName {
                message += multiPartName + "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            Alerts.shared.alert(title: "Canceling All \(name) Downloads", message: message)
            
            self?.list?.forEach({ (mediaItem) in
                mediaItem.downloads?[purpose]?.cancel()
            })
            
            if self?.list?.downloading(purpose:purpose) == 0 {
                Alerts.shared.alert(title: "All \(name) Downloads Canceled", message: self?.list?.multiPartName)
            }
        }
        
        for operation in mediaQueue.operations {
            guard let operation = operation as? CancelableOperation else {
                continue
            }
            
            if (operation.tag == purpose) || (operation.tag == Constants.Strings.Download_All + Constants.SINGLE_SPACE + name) {
                notifyOperation.addDependency(operation)
                operation.cancel()
            }
        }
        
        mediaQueue.addOperation(notifyOperation)
    }
    
    func cancelAllAudioDownloads()
    {
        cancelAllDownloads(purpose:Purpose.audio,name:Constants.Strings.Audio)
    }
    
    func cancellAllVideoDownloads()
    {
        cancelAllDownloads(purpose:Purpose.video,name:Constants.Strings.Video)
    }
    
    func downloadAll(purpose:String,name:String)
    {
        guard let list = list else {
            return
        }
        
        var message = "This may take a considerable amount of time.  You will be notified when it is complete."
        
        if let multiPartName = list.multiPartName {
            message = "\(multiPartName)\n\n\(message)"
        }
        
        Alerts.shared.alert(title: "Downloading All \(name)", message: message)
        
        let monitorOperation = CancelableOperation(tag:purpose) { [weak self] (test:(()->Bool)?) in
            while self?.list?.notesDownloading > 0 {
                if let test = test, test() {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.list?.downloading(purpose:purpose) == 0 {
                if self?.list?.downloads(purpose: purpose) == 0 {
                    Alerts.shared.alert(title: "All \(name) Downloads Complete", message:list.multiPartName)
                } else {
                    Alerts.shared.alert(title: "Some \(name) Downloads Failed to Complete", message:list.multiPartName)
                }
            }
        }
        
        for mediaItem in list {
            let download = mediaItem.downloads?[purpose]
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancelableOperation(tag:purpose) { [weak self] (test:(()->Bool)?) in
                _ = download?.download(background: true)
                
                while download?.state == .downloading {
                    if let test = test, test() {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            monitorOperation.addDependency(operation)
            
            mediaQueue.addOperation(operation)
        }
        
        monitorOperation.tag = Constants.Strings.Download_All + Constants.SINGLE_SPACE + name
        
        mediaQueue.addOperation(monitorOperation)
    }
    
    func downloadAllNotes()
    {
        downloadAll(purpose:Purpose.notes,name:Constants.Strings.Notes)
    }

    func downloadAllSlides()
    {
        downloadAll(purpose: Purpose.slides, name: Constants.Strings.Slides)
    }

    func downloadingAll(name:String) -> Bool
    {
        return mediaQueue.operations.filter({ (operation:Operation) -> Bool in
            return (operation as? CancelableOperation)?.tag == Constants.Strings.Download_All + Constants.SINGLE_SPACE + name
        }).count > 0
    }
    
    private lazy var mediaQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaList:Media" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
        return operationQueue
    }()

    // ALL operations stop on dealloc, including DOWNLOADING.
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
        mediaQueue.cancelAllOperations()
    }

    func downloadAllAudio()
    {
        downloadAll(purpose: Purpose.audio, name: Constants.Strings.Audio)
    }
    
    func downloadAllVideo()
    {
        downloadAll(purpose: Purpose.video, name: Constants.Strings.Video)
    }
    
    subscript(key:Int) -> MediaItem?
    {
        get {
            if key >= 0,key < list?.count {
                return list?[key]
            }

            return nil
        }
        set {
            guard let newValue = newValue else {
                if key >= 0,key < list?.count {
                    list?.remove(at: key)
                }
                return
            }

            if list == nil {
                list = [MediaItem]()
            }

            if key >= 0,key < list?.count {
                list?[key] = newValue
            }

            if key == list?.count {
                list?.append(newValue)
            }
        }
    }
    
    var listDidSet : (()->(Void))?

    init(_ list:[MediaItem]? = nil)
    {
        self.list = list
        updateIndex() // didSets are not called during init
    }
    
    init(_ list:[MediaItem?]? = nil)
    {
        self.list = list?.compactMap({ (mediaItem:MediaItem?) -> MediaItem? in
            return mediaItem
        })
        updateIndex() // didSets are not called during init
    }
    
    func updateIndex()
    {
        index.clear()
        classes.clear()
        events.clear()
        
        guard let list = list, list.count > 0 else {
            return
        }
        
        for mediaItem in list {
            if let id = mediaItem.mediaCode {
                index[id] = mediaItem
            }
            
            if mediaItem.hasClassName, let className = mediaItem.className {
                classes.append(className)
            }
            
            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                events.append(eventName)
            }
        }
    }
    
    var list:[MediaItem]?
    { //Not in any specific order
        willSet {
            
        }
        didSet {
            index.clear()
            classes.clear()
            events.clear()
            
            listDidSet?()
            
            updateIndex()
        }
    }
    
    var index = ThreadSafeDN<MediaItem>() // :[String:MediaItem]? //MediaItems indexed by ID.
    var classes = ThreadSafeArray<String>() // :[String]?
    var events = ThreadSafeArray<String>() // :[String]?
}

