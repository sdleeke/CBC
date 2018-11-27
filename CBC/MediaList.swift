//
//  MediaRepository.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class MediaList // : Sequence
{
    func clearCache(block:Bool)
    {
        list?.forEach({ (mediaItem) in
            mediaItem.clearCache(block:block)
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
//            return result + (mediaItem.downloads[purpose]?.fileSize ?? 0)
            return result + mediaItem.cacheSize(purpose)
        })
    }
    
    func alignAllAudio(viewController:UIViewController)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard mediaItem.audioTranscript?.transcribing == false else {
                continue
            }
            
            guard mediaItem.audioTranscript?.aligning == false else {
                continue
            }
            
            guard mediaItem.audioTranscript?.completed == true else {
                continue
            }
            
            mediaItem.audioTranscript?.selectAlignmentSource(viewController: viewController)
        }
    }
    
    func alignAllVideo(viewController:UIViewController)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard mediaItem.videoTranscript?.transcribing == false else {
                continue
            }
            
            guard mediaItem.videoTranscript?.aligning == false else {
                continue
            }
            
            guard mediaItem.videoTranscript?.completed == true else {
                continue
            }
            
            mediaItem.videoTranscript?.selectAlignmentSource(viewController: viewController)
        }
    }
    
    func transcribeAllAudio(viewController:UIViewController)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard mediaItem.audioTranscript?.transcribing == false else {
                continue
            }
            
            guard mediaItem.audioTranscript?.completed == false else {
                continue
            }
            
            mediaItem.audioTranscript?.getTranscript(alert: true)
            mediaItem.audioTranscript?.alert(viewController: viewController)
        }
    }
    
    func transcribeAllVideo(viewController:UIViewController)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard mediaItem.videoTranscript?.transcribing == false else {
                continue
            }
            
            guard mediaItem.videoTranscript?.completed == false else {
                continue
            }
            
            mediaItem.videoTranscript?.getTranscript(alert: true)
            mediaItem.videoTranscript?.alert(viewController: viewController)
        }
    }
    
    var toTranscribeAudio : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.transcribing == false) && (mediaItem.audioTranscript?.completed == false)
            }).count
        }
    }
    
    var toTranscribeVideo : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.transcribing == false) && (mediaItem.videoTranscript?.completed == false)
            }).count
        }
    }
    
    var toAlignAudio : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.transcribing == false) && (mediaItem.audioTranscript?.completed == true) && (mediaItem.audioTranscript?.aligning == false)
            }).count
        }
    }
    
    var toAlignVideo : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.transcribing == false) && (mediaItem.videoTranscript?.completed == true) && (mediaItem.videoTranscript?.aligning == false)
            }).count
        }
    }
    
    var audioDownloads : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == false) && (mediaItem.audioDownload?.exists == false)
            }).count
        }
    }
    
    var audioDownloading : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == true)
            }).count
        }
    }
    
    var audioDownloaded : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.audioDownload?.exists == true
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
    
    var videoDownloading : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.videoDownload?.active == true)
            }).count
        }
    }
    
    var videoDownloaded : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.videoDownload?.exists == true
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
    
    var slidesDownloading : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.active == true)
            }).count
        }
    }
    
    var slidesDownloaded : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.exists == true)
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
    
    var notesDownloading : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.active == true)
            }).count
        }
    }
    
    var notesDownloaded : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.exists == true)
            }).count
        }
    }
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaList" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3
        return operationQueue
    }()
    
    func cancelAllDownloads()
    {
        operationQueue.addOperation {
            self.list?.forEach({ (mediaItem) in
                // Could be audio, video, slides, or notes
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
                // Could be audio, video, slides, or notes
                mediaItem.downloads.values.forEach({ (download) in
                    download.delete(block:true)
                })
            })
        }
    }
    
    func deleteAllAudioDownloads()
    {
        operationQueue.addOperation {
            Alerts.shared.alert(title: "Deleting All Audio Downloads", message: "You will be notified when it is complete.")
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.audioDownload?.delete(block:true)
            })
            
            if self.audioDownloaded == 0 {
                Alerts.shared.alert(title: "All Audio Downloads Deleted")
            }
        }
    }
    
    func deleteAllVideoDownloads()
    {
        operationQueue.addOperation {
            Alerts.shared.alert(title: "Deleting All Video Downloads", message: "You will be notified when it is complete.")
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.videoDownload?.delete(block:true)
            })
            
            if self.videoDownloaded == 0 {
                Alerts.shared.alert(title: "All Video Downloads Deleted")
            }
        }
    }
    
    func cancelAllAudioDownloads()
    {
        for operation in mediaQueue.operations {
            guard let operation = operation as? CancellableOperation else {
                continue
            }
            
            if operation.tag == Purpose.audio {
                operation.cancel()
            }
        }
        
        operationQueue.addOperation {
            Alerts.shared.alert(title: "Cancelling All Audio Downloads", message: "You will be notified when it is complete.")
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.audioDownload?.cancel()
            })
            
            if self.audioDownloading == 0 {
                Alerts.shared.alert(title: "All Audio Downloads Cancelled")
            }
        }
    }
    
    func cancellAllVideoDownloads()
    {
        for operation in mediaQueue.operations {
            guard let operation = operation as? CancellableOperation else {
                continue
            }
            
            if operation.tag == Purpose.video {
                operation.cancel()
            }
        }

        operationQueue.addOperation {
            Alerts.shared.alert(title: "Cancelling All Video Downloads", message: "You will be notified when it is complete.")
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.videoDownload?.cancel()
            })
            
            if self.videoDownloading == 0 {
                Alerts.shared.alert(title: "All Video Downloads Cancelled")
            }
        }
    }
    
    func downloadAllNotes()
    {
        guard let list = list else {
            return
        }
        
        //        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
        //            for mediaItem in list {
        //                if test?() == true {
        //                    break
        //                }
        //
        //                let download = mediaItem.notesDownload
        //
        //                if download?.exists == true {
        //                    continue
        //                }
        //
        //                _ = download?.download()
        //
        //                while download?.state == .downloading {
        //                    if test?() == true {
        //                        download?.cancel()
        //                        break
        //                    }
        //
        //                    Thread.sleep(forTimeInterval: 1.0)
        //                }
        //            }
        //            if self?.notesDownloads == 0 {
        //                Alerts.shared.alert(title: "All " + (Globals.shared.mediaCategory.notesName ?? "") + " Downloads Complete")
        //            }
        //        }
        //
        //        operationQueue.addOperation(operation)
        
        Alerts.shared.alert(title: "Downloading All Notes", message: "This may take a considerable amount of time.  You will be notified when it is complete.")
        
        for mediaItem in list {
            let download = mediaItem.notesDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation(tag:Purpose.notes) { [weak self] (test:(()->(Bool))?) in
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            operationQueue.addOperation(operation)
        }
        
        let operation = CancellableOperation(tag:Purpose.notes) { [weak self] (test:(()->(Bool))?) in
            while self?.notesDownloading > 0 {
                if test?() == true {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.notesDownloading == 0 {
                Alerts.shared.alert(title: "All Notes Downloads Complete")
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    func downloadAllSlides()
    {
        guard let list = list else {
            return
        }
        
        //        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
        //            for mediaItem in list {
        //                if test?() == true {
        //                    break
        //                }
        //
        //                let download = mediaItem.slidesDownload
        //
        //                if download?.exists == true {
        //                    continue
        //                }
        //
        //                _ = download?.download()
        //
        //                while download?.state == .downloading {
        //                    if test?() == true {
        //                        download?.cancel()
        //                        break
        //                    }
        //
        //                    Thread.sleep(forTimeInterval: 1.0)
        //                }
        //            }
        //            if self?.slidesDownloads == 0 {
        //                Alerts.shared.alert(title: "All Slide Downloads Complete")
        //            }
        //        }
        //
        //        operationQueue.addOperation(operation)
        
        Alerts.shared.alert(title: "Downloading All Slides", message: "This may take a considerable amount of time.  You will be notified when it is complete.")
        
        for mediaItem in list {
            let download = mediaItem.slidesDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation(tag:Purpose.slides) { [weak self] (test:(()->(Bool))?) in
                _ = download?.download()
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            operationQueue.addOperation(operation)
        }
        
        let operation = CancellableOperation(tag:Purpose.slides) { [weak self] (test:(()->(Bool))?) in
            while self?.slidesDownloading > 0 {
                if test?() == true {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.slidesDownloading == 0 {
                Alerts.shared.alert(title: "All Slides Downloads Complete")
            }
        }
        
        operationQueue.addOperation(operation)
    }
    
    lazy var mediaQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaList:Media" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
        mediaQueue.cancelAllOperations()
    }
    
    func downloadAllAudio()
    {
        guard let list = list else {
            return
        }
        
        Alerts.shared.alert(title: "Downloading All Audio", message: "This may take a considerable amount of time.  You will be notified when it is complete.")

        for mediaItem in list {
            let download = mediaItem.audioDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation(tag:Purpose.audio) { [weak self] (test:(()->(Bool))?) in
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
        
        let operation = CancellableOperation(tag:Purpose.audio) { [weak self] (test:(()->(Bool))?) in
            while self?.audioDownloading > 0 {
                if test?() == true {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.audioDownloading == 0 {
                Alerts.shared.alert(title: "All Audio Downloads Complete")
            }
        }
        
        mediaQueue.addOperation(operation)
    }
    
    func downloadAllVideo()
    {
        guard let list = list else {
            return
        }
        
        Alerts.shared.alert(title: "Downloading All Video", message: "This may take a considerable amount of time.  You will be notified when it is complete.")

        for mediaItem in list {
            let download = mediaItem.videoDownload
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation(tag:Purpose.video) { [weak self] (test:(()->(Bool))?) in
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
        
        let operation = CancellableOperation(tag:Purpose.video) { [weak self] (test:(()->(Bool))?) in
            while self?.videoDownloading > 0 {
                if test?() == true {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.videoDownloading == 0 {
                Alerts.shared.alert(title: "All Video Downloads Complete")
            }
        }
        
        mediaQueue.addOperation(operation)
    }
    
    func loadAllDocuments()
    {
        list?.forEach({ (mediaItem:MediaItem) in
            mediaItem.loadDocuments()
        })
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
    
    var didSet : (()->(Void))?

    init(_ list:[MediaItem]?)
    {
        self.list = list
        updateIndex() // didSets are not called during init
    }
    
    func updateIndex()
    {
        index = nil
        
        guard let list = list, list.count > 0 else {
            return
        }
        
        index = [String:MediaItem]()
        
        for mediaItem in list {
            if let id = mediaItem.id {
                index?[id] = mediaItem
            }
            
            if mediaItem.hasClassName, let className = mediaItem.className {
                if classes == nil {
                    classes = [className]
                } else {
                    classes?.append(className)
                }
            }
            
            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                if events == nil {
                    events = [eventName]
                } else {
                    events?.append(eventName)
                }
            }
        }
    }
    
//    func update(_ list:[MediaItem]?)
//    {
//        self.list = list
//    }
    
//    var count : Int
//    {
//        guard let list = list else {
//            return 0
//        }
//
//        return list.count
//    }
    
//    func filter(_ block:((MediaItem)->Bool)) -> [MediaItem]?
//    {
//        return list?.filter({ (mediaItem) -> Bool in
//            return block(mediaItem)
//        })
//    }
    
    var list:[MediaItem]?
    { //Not in any specific order
        willSet {
            
        }
        didSet {
            didSet?()
            updateIndex()
        }
    }
    
    // Make thread safe?
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    var classes:[String]?
    var events:[String]?
}

