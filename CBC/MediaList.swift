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
    
    func updateCacheSize()
    {
        operationQueue.addOperation {
            _ = self.list?.reduce(0, { (result, mediaItem) -> Int in
                return result + mediaItem.cacheSize
            })
        }
    }
    
    func alignAllAudio(viewController:UIViewController)
    {
        alignAll(viewController:viewController,purpose:Purpose.audio)
    }
    
    func alignAllVideo(viewController:UIViewController)
    {
        alignAll(viewController:viewController,purpose:Purpose.video)
    }
    
    func alignAll(viewController:UIViewController,purpose:String)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.aligning == false else {
                continue
            }
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.selectAlignmentSource(viewController: viewController)
        }
    }
    
    func autoEditAllAudio(viewController:UIViewController)
    {
        autoEditAll(viewController:viewController,purpose:Purpose.audio)
    }
    
    func autoEditAllVideo(viewController:UIViewController)
    {
        autoEditAll(viewController:viewController,purpose:Purpose.video)
    }
    
    func autoEditAll(viewController:UIViewController,purpose:String)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.aligning == false else {
                continue
            }
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.autoEdit(viewController:viewController)
        }
    }
    
//    func alignAllVideo(viewController:UIViewController)
//    {
//        guard let mediaItems = list else {
//            return
//        }
//
//        for mediaItem in mediaItems {
//            guard mediaItem.videoTranscript?.transcribing == false else {
//                continue
//            }
//
//            guard mediaItem.videoTranscript?.aligning == false else {
//                continue
//            }
//
//            guard mediaItem.videoTranscript?.completed == true else {
//                continue
//            }
//
//            mediaItem.videoTranscript?.selectAlignmentSource(viewController: viewController)
//        }
//    }

    func transcribeAllAudio(viewController:UIViewController)
    {
        transcribeAll(viewController:viewController,purpose:Purpose.audio)
    }
    
    func transcribeAllVideo(viewController:UIViewController)
    {
        transcribeAll(viewController:viewController,purpose:Purpose.video)
    }
    
    func transcribeAll(viewController:UIViewController,purpose:String)
    {
        guard let mediaItems = list else {
            return
        }
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.completed == false else {
                continue
            }
            
            transcript.getTranscript(alert: true)
            transcript.alert(viewController: viewController)
        }
    }
    
//    func transcribeAllVideo(viewController:UIViewController)
//    {
//        guard let mediaItems = list else {
//            return
//        }
//
//        for mediaItem in mediaItems {
//            guard mediaItem.videoTranscript?.transcribing == false else {
//                continue
//            }
//
//            guard mediaItem.videoTranscript?.completed == false else {
//                continue
//            }
//
//            mediaItem.videoTranscript?.getTranscript(alert: true)
//            mediaItem.videoTranscript?.alert(viewController: viewController)
//        }
//    }
    
    func toTranscribe(purpose:String) -> Int?
    {
        return list?.filter({ (mediaItem) -> Bool in
            return (mediaItem.transcripts[purpose]?.transcribing == false) && (mediaItem.transcripts[purpose]?.completed == false)
        }).count
    }
    
    var transcribedAudio : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.completed == true)
            }).count
        }
    }
    
    var transcribedVideo : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.completed == true)
            }).count
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
    
    func toAlign(purpose:String) -> Int?
    {
        return list?.filter({ (mediaItem) -> Bool in
            return (mediaItem.transcripts[purpose]?.transcribing == false) &&       (mediaItem.transcripts[purpose]?.completed == false) &&
                (mediaItem.transcripts[purpose]?.aligning == false)
        }).count
    }
    
    var toAlignAudio : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.transcribing == false) && (mediaItem.audioTranscript?.completed == true) &&
                    (mediaItem.audioTranscript?.aligning == false)
            }).count
        }
    }
    
    var toAlignVideo : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.transcribing == false) && (mediaItem.videoTranscript?.completed == true) &&
                    (mediaItem.videoTranscript?.aligning == false)
            }).count
        }
    }
    
    func downloads(purpose:String) -> Int?
    {
        guard Globals.shared.reachability.isReachable else {
            return nil
        }
        
        return list?.filter({ (mediaItem) -> Bool in
            return (mediaItem.downloads[purpose]?.active == false) &&
                (mediaItem.downloads[purpose]?.exists == false)
        }).count
    }
    
    var audioDownloads : Int?
    {
        get {
            guard Globals.shared.reachability.isReachable else {
                return nil
            }

            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == false) &&
                    (mediaItem.audioDownload?.exists == false)
            }).count
        }
    }
    
    func downloading(purpose:String) -> Int?
    {
        return list?.filter({ (mediaItem) -> Bool in
            return mediaItem.downloads[purpose]?.active == true
        }).count
    }
    
    var audioDownloading : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == true)
            }).count
        }
    }
    
    func downloaded(purpose:String) -> Int?
    {
        return list?.filter({ (mediaItem) -> Bool in
            return mediaItem.downloads[purpose]?.exists == true
        }).count
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
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
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
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
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
            guard Globals.shared.reachability.isReachable else {
                return nil
            }

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
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
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
    
    func deleteAllDownloads(purpose:String,name:String)
    {
        operationQueue.addOperation {
            var message = ""
            
            if let multiPartName = self.multiPartName {
                message += multiPartName + "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            Alerts.shared.alert(title: "Deleting All \(name) Downloads", message: message)
            
            self.list?.forEach({ (mediaItem) in
                mediaItem.downloads[purpose]?.delete(block:true)
            })
            
            if self.audioDownloaded == 0 {
                Alerts.shared.alert(title: "All \(name) Downloads Deleted", message: self.multiPartName)
            }
        }
    }
    
    func deleteAllAudioDownloads()
    {
        deleteAllDownloads(purpose: Purpose.audio, name: Constants.Strings.Audio)
    }
    
//    func deleteAllAudioDownloads()
//    {
//        operationQueue.addOperation {
//            var message = ""
//
//            if let multiPartName = self.multiPartName {
//                message += multiPartName + "\n\n"
//            }
//
//            message += "You will be notified when it is complete."
//
//            Alerts.shared.alert(title: "Deleting All Audio Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.audioDownload?.delete(block:true)
//            })
//
//            if self.audioDownloaded == 0 {
//                Alerts.shared.alert(title: "All Audio Downloads Deleted", message: self.multiPartName)
//            }
//        }
//    }
    
    func deleteAllVideoDownloads()
    {
        deleteAllDownloads(purpose: Purpose.video, name: Constants.Strings.Video)
    }
    
//    func deleteAllVideoDownloads()
//    {
//        operationQueue.addOperation {
//            var message = ""
//
//            if let multiPartName = self.multiPartName {
//                message += multiPartName + "\n\n"
//            }
//
//            message += "You will be notified when it is complete."
//
//            Alerts.shared.alert(title: "Deleting All Video Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.videoDownload?.delete(block:true)
//            })
//
//            if self.videoDownloaded == 0 {
//                Alerts.shared.alert(title: "All Video Downloads Deleted", message: self.multiPartName)
//            }
//        }
//    }
    
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
    
    func cancelAllDownloads(purpose:String,name:String)
    {
        let notifyOperation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
            var message = ""
            
            if let multiPartName = self?.multiPartName {
                message += multiPartName + "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            Alerts.shared.alert(title: "Cancelling All \(name) Downloads", message: message)
            
            self?.list?.forEach({ (mediaItem) in
                mediaItem.downloads[purpose]?.cancel()
            })
            
            if self?.downloading(purpose:purpose) == 0 {
                Alerts.shared.alert(title: "All \(name) Downloads Cancelled", message: self?.multiPartName)
            }
        }
        
        for operation in mediaQueue.operations {
            guard let operation = operation as? CancellableOperation else {
                continue
            }
            
            notifyOperation.addDependency(operation)
            
            if operation.tag == purpose {
                operation.cancel()
            }
        }
        
        mediaQueue.addOperation(notifyOperation)
    }
    
    func cancelAllAudioDownloads()
    {
        cancelAllDownloads(purpose:Purpose.audio,name:Constants.Strings.Audio)
    }
    
//    func cancelAllAudioDownloads()
//    {
//        for operation in mediaQueue.operations {
//            guard let operation = operation as? CancellableOperation else {
//                continue
//            }
//
//            if operation.tag == Purpose.audio {
//                operation.cancel()
//            }
//        }
//
//        operationQueue.addOperation {
//            var message = ""
//
//            if let multiPartName = self.multiPartName {
//                message += multiPartName + "\n\n"
//            }
//
//            message += "You will be notified when it is complete."
//
//            Alerts.shared.alert(title: "Cancelling All Audio Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.audioDownload?.cancel()
//            })
//
//            if self.audioDownloading == 0 {
//                Alerts.shared.alert(title: "All Audio Downloads Cancelled", message: self.multiPartName)
//            }
//        }
//    }
    
    func cancellAllVideoDownloads()
    {
        cancelAllDownloads(purpose:Purpose.video,name:Constants.Strings.Video)
    }
    
//    func cancellAllVideoDownloads()
//    {
//        for operation in mediaQueue.operations {
//            guard let operation = operation as? CancellableOperation else {
//                continue
//            }
//
//            if operation.tag == Purpose.video {
//                operation.cancel()
//            }
//        }
//
//        operationQueue.addOperation {
//            var message = ""
//
//            if let multiPartName = self.multiPartName {
//                message += multiPartName + "\n\n"
//            }
//
//            message += "You will be notified when it is complete."
//
//            Alerts.shared.alert(title: "Cancelling All Video Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.videoDownload?.cancel()
//            })
//
//            if self.videoDownloading == 0 {
//                Alerts.shared.alert(title: "All Video Downloads Cancelled", message: self.multiPartName)
//            }
//        }
//    }

    func downloadAll(purpose:String,name:String)
    {
        guard let list = list else {
            return
        }
        
        var message = "This may take a considerable amount of time.  You will be notified when it is complete."
        
        if let multiPartName = multiPartName {
            message = "\(multiPartName)\n\n\(message)"
        }
        
        Alerts.shared.alert(title: "Downloading All \(name)", message: message)
        
        let monitorOperation = CancellableOperation(tag:purpose) { [weak self] (test:(()->(Bool))?) in
            while self?.notesDownloading > 0 {
                if test?() == true {
                    break
                }
                
                Thread.sleep(forTimeInterval: 1.0)
            }
            
            if self?.downloading(purpose:purpose) == 0 {
                if self?.downloads(purpose: purpose) == 0 {
                    Alerts.shared.alert(title: "All \(name) Downloads Complete", message:self?.multiPartName)
                } else {
                    Alerts.shared.alert(title: "Some \(name) Downloads Failed to Complete", message:self?.multiPartName)
                }
            }
        }
        
        for mediaItem in list {
            let download = mediaItem.downloads[purpose]
            
            if download?.exists == true  {
                continue
            }
            
            let operation = CancellableOperation(tag:purpose) { [weak self] (test:(()->(Bool))?) in
                _ = download?.download(background: true)
                
                while download?.state == .downloading {
                    if test?() == true {
                        download?.cancel()
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
            
            monitorOperation.addDependency(operation)
            
            mediaQueue.addOperation(operation)
        }
        
        mediaQueue.addOperation(monitorOperation)
    }
    
    func downloadAllNotes()
    {
        downloadAll(purpose:Purpose.notes,name:Constants.Strings.Notes)
    }
    
//    func downloadAllNotes()
//    {
//        guard let list = list else {
//            return
//        }
//
//        //        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
//        //            for mediaItem in list {
//        //                if test?() == true {
//        //                    break
//        //                }
//        //
//        //                let download = mediaItem.notesDownload
//        //
//        //                if download?.exists == true {
//        //                    continue
//        //                }
//        //
//        //                _ = download?.download()
//        //
//        //                while download?.state == .downloading {
//        //                    if test?() == true {
//        //                        download?.cancel()
//        //                        break
//        //                    }
//        //
//        //                    Thread.sleep(forTimeInterval: 1.0)
//        //                }
//        //            }
//        //            if self?.notesDownloads == 0 {
//        //                Alerts.shared.alert(title: "All " + (Globals.shared.mediaCategory.notesName ?? "") + " Downloads Complete")
//        //            }
//        //        }
//        //
//        //        operationQueue.addOperation(operation)
//
//        Alerts.shared.alert(title: "Downloading All Notes", message: "This may take a considerable amount of time.  You will be notified when it is complete.")
//
//        let monitorOperation = CancellableOperation(tag:Purpose.notes) { [weak self] (test:(()->(Bool))?) in
//            while self?.notesDownloading > 0 {
//                if test?() == true {
//                    break
//                }
//
//                Thread.sleep(forTimeInterval: 1.0)
//            }
//
//            if self?.notesDownloading == 0 {
//                if self?.notesDownloads == 0 {
//                    Alerts.shared.alert(title: "All Notes Downloads Complete")
//                } else {
//                    Alerts.shared.alert(title: "Some Notes Downloads Failed to Complete")
//                }
//            }
//        }
//
//        for mediaItem in list {
//            let download = mediaItem.notesDownload
//
//            if download?.exists == true  {
//                continue
//            }
//
//            let operation = CancellableOperation(tag:Purpose.notes) { [weak self] (test:(()->(Bool))?) in
//                _ = download?.download(background: true)
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
//
//            monitorOperation.addDependency(operation)
//
//            operationQueue.addOperation(operation)
//        }
//
//        operationQueue.addOperation(monitorOperation)
//    }

    func downloadAllSlides()
    {
        downloadAll(purpose: Purpose.slides, name: Constants.Strings.Slides)
    }

//    func downloadAllSlides()
//    {
//        guard let list = list else {
//            return
//        }
//
//        //        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
//        //            for mediaItem in list {
//        //                if test?() == true {
//        //                    break
//        //                }
//        //
//        //                let download = mediaItem.slidesDownload
//        //
//        //                if download?.exists == true {
//        //                    continue
//        //                }
//        //
//        //                _ = download?.download()
//        //
//        //                while download?.state == .downloading {
//        //                    if test?() == true {
//        //                        download?.cancel()
//        //                        break
//        //                    }
//        //
//        //                    Thread.sleep(forTimeInterval: 1.0)
//        //                }
//        //            }
//        //            if self?.slidesDownloads == 0 {
//        //                Alerts.shared.alert(title: "All Slide Downloads Complete")
//        //            }
//        //        }
//        //
//        //        operationQueue.addOperation(operation)
//
//        Alerts.shared.alert(title: "Downloading All Slides", message: "This may take a considerable amount of time.  You will be notified when it is complete.")
//
//        let monitorOperation = CancellableOperation(tag:Purpose.slides) { [weak self] (test:(()->(Bool))?) in
//            while self?.slidesDownloading > 0 {
//                if test?() == true {
//                    break
//                }
//
//                Thread.sleep(forTimeInterval: 1.0)
//            }
//
//            if self?.slidesDownloading == 0 {
//                if self?.slidesDownloads == 0 {
//                    Alerts.shared.alert(title: "All Slides Downloads Complete", message: self?.multiPartName)
//                } else {
//                    Alerts.shared.alert(title: "Some Slides Downloads Failed to Complete", message: self?.multiPartName)
//                }
//            }
//        }
//
//        for mediaItem in list {
//            let download = mediaItem.slidesDownload
//
//            if download?.exists == true  {
//                continue
//            }
//
//            let operation = CancellableOperation(tag:Purpose.slides) { [weak self] (test:(()->(Bool))?) in
//                _ = download?.download(background: true)
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
//
//            monitorOperation.addDependency(operation)
//
//            operationQueue.addOperation(operation)
//        }
//
//        operationQueue.addOperation(monitorOperation)
//    }

    lazy var mediaQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaList:Media" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
        return operationQueue
    }()

    // ALL operations stop on dealloc, including DOWNLOADING.
    deinit {
        operationQueue.cancelAllOperations()
        mediaQueue.cancelAllOperations()
    }

    func addAllToFavorites()
    {
        list?.forEach({ (mediaItem) in
            mediaItem.addToFavorites()
        })
    }

    func removeAllFromFavorites()
    {
//        guard let list = list else {
//            break
//        }

        list?.forEach({ (mediaItem) in
            mediaItem.removeFromFavorites()
        })
        // This blocks this thread until it finishes.
//        Globals.shared.queue.sync {
//            for mediaItem in mediaItems {
//                mediaItem.addTag(Constants.Strings.Favorites)
//            }
//        }
    }

    var multiPartName : String?
    {
        get {
            guard let set = list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.multiPartName != nil
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.multiPartName!
            }) else {
                return nil
            }

            guard Set(set).count == 1 else {
                return nil
            }

            return set.first
        }
    }
    
    func downloadAllAudio()
    {
        downloadAll(purpose: Purpose.audio, name: Constants.Strings.Audio)
    }
    
//    func downloadAllAudio()
//    {
//        guard let list = list else {
//            return
//        }
//
//        var message = ""
//
//        if let multiPartName = multiPartName {
//            message += multiPartName + "\n\n"
//        }
//
//        message += "This may take a considerable amount of time.  You will be notified when it is complete."
//
//        Alerts.shared.alert(title: "Downloading All Audio", message: message)
//
//        let monitorOperation = CancellableOperation(tag:Purpose.audio) { [weak self] (test:(()->(Bool))?) in
//            while self?.audioDownloading > 0 {
//                if test?() == true {
//                    break
//                }
//
//                Thread.sleep(forTimeInterval: 1.0)
//            }
//
//            if self?.audioDownloading == 0 {
//                if self?.audioDownloads == 0 {
//                    Alerts.shared.alert(title: "All Audio Downloads Complete", message: self?.multiPartName)
//                } else {
//                    Alerts.shared.alert(title: "Some Audio Downloads Failed to Complete", message: self?.multiPartName)
//                }
//            }
//        }
//
//        for mediaItem in list {
//            let download = mediaItem.audioDownload
//
//            if download?.exists == true  {
//                continue
//            }
//
//            let operation = CancellableOperation(tag:Purpose.audio) { [weak self] (test:(()->(Bool))?) in
//                _ = download?.download(background: true)
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
//
//            monitorOperation.addDependency(operation)
//
//            mediaQueue.addOperation(operation)
//        }
//
//        mediaQueue.addOperation(monitorOperation)
//    }
    
    func downloadAllVideo()
    {
        downloadAll(purpose: Purpose.video, name: Constants.Strings.Video)
    }
    
//    func downloadAllVideo()
//    {
//        guard let list = list else {
//            return
//        }
//
//        Alerts.shared.alert(title: "Downloading All Video", message: "This may take a considerable amount of time.  You will be notified when it is complete.")
//
//        let monitorOperation = CancellableOperation(tag:Purpose.video) { [weak self] (test:(()->(Bool))?) in
//            while self?.videoDownloading > 0 {
//                if test?() == true {
//                    break
//                }
//
//                Thread.sleep(forTimeInterval: 1.0)
//            }
//
//            if self?.videoDownloading == 0 {
//                if self?.videoDownloads == 0 {
//                    Alerts.shared.alert(title: "All Video Downloads Complete", message: self?.multiPartName)
//                } else {
//                    Alerts.shared.alert(title: "Some Video Downloads Failed to Complete", message: self?.multiPartName)
//                }
//            }
//        }
//
//        for mediaItem in list {
//            let download = mediaItem.videoDownload
//
//            if download?.exists == true  {
//                continue
//            }
//
//            let operation = CancellableOperation(tag:Purpose.video) { [weak self] (test:(()->(Bool))?) in
//                _ = download?.download(background: true)
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
//
//            monitorOperation.addDependency(operation)
//
//            mediaQueue.addOperation(operation)
//        }
//
//        mediaQueue.addOperation(monitorOperation)
//    }
    
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

    init(_ list:[MediaItem]? = nil)
    {
        self.list = list
        updateIndex() // didSets are not called during init
    }
    
    func updateIndex()
    {
//        index = nil
//        classes = nil
//        events = nil

        index.clear()
        classes.clear()
        events.clear()
        
        guard let list = list, list.count > 0 else {
            return
        }
        
//        index = [String:MediaItem]()
//        classes = [String]()
//        events = [String]()

        for mediaItem in list {
            if let id = mediaItem.id {
                index[id] = mediaItem
            }
            
            if mediaItem.hasClassName, let className = mediaItem.className {
//                if classes == nil {
//                    classes = [className]
//                } else {
//                    classes?.append(className)
//                }
                classes.append(className)
            }
            
            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
//                if events == nil {
//                    events = [eventName]
//                } else {
//                    events?.append(eventName)
//                }
                events.append(eventName)
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
//            index = nil
//            classes = nil
//            events = nil
//
            index.clear()
            classes.clear()
            events.clear()
            
            didSet?()
            
            updateIndex()
            updateCacheSize()
        }
    }
    
    // Make thread safe?
    var index = ThreadSafeDictionary<MediaItem>() // :[String:MediaItem]? //MediaItems indexed by ID.
    var classes = ThreadSafeArray<String>() // :[String]?
    var events = ThreadSafeArray<String>() // :[String]?
}

