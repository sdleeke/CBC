//
//  MediaRepository.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class CheckIn
{
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()

    func reset()
    {
        total = 0
        success = 0
        failure = 0
    }
    
    var total = 0
    
    var _success = 0
    var success : Int
    {
        get {
            return queue.sync {
                return _success
            }
        }
        set {
            queue.sync {
                _success = newValue
            }
        }
    }

    var _failure = 0
    var failure : Int
    {
        get {
            return queue.sync {
                return _failure
            }
        }
        set {
            queue.sync {
                _failure = newValue
            }
        }
    }
}

class MediaList // : Sequence
{
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
            Alerts.shared.alert(title: "No VoiceBase Media Were Deleted", message:self.multiPartName)
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
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.multiPartName)
            }
            
            if checkIn.failure == checkIn.total, checkIn.success == 0 {
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.multiPartName)
                
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Found\n(\(checkIn.failure) of \(checkIn.total))", message:self?.multiPartName)
            }
            
            if checkIn.failure > 0, checkIn.failure < checkIn.total, checkIn.success > 0, checkIn.success < checkIn.total {
                preamble = "Some "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:self?.multiPartName)
                
                preamble = "Several "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Not Found\n(\(checkIn.failure) of \(checkIn.total))", message:self?.multiPartName)
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
    
//    func voiceBaseMedia(completion:(([String:Any]?)->())?,onError:(([String:Any]?)->())?)
//    {
//        list?.forEach({ (mediaItem:MediaItem) in
//            mediaItem.transcripts.values.forEach({ (voiceBase:VoiceBase) in
//                voiceBase.details(completion:completion,onError:onError)
//            })
//        })
//    }
    
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
//            return result + (mediaItem.downloads[purpose]?.fileSize ?? 0)
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
            
            transcript.autoEdit(notify:false)
        }
        
        if let multiPartName = multiPartName {
            Alerts.shared.alert(title: "All Auto Edits Underway", message: "\(multiPartName)\n(\(purpose.lowercased()))")
        } else {
            if list?.count == 1, let mediaItem = list?.first, let title = mediaItem.title {
                Alerts.shared.alert(title: "All Auto Edits Underway", message: "\(title)\n(\(purpose.lowercased()))")
            } else {
                Alerts.shared.alert(title: "All Auto Edits Underway")
            }
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
            
            transcript.getTranscript()
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
    
    var autoEditingAudio : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.operationQueue?.operationCount > 0)
            }).count
        }
    }
    
    var autoEditingVideo : Int?
    {
        get {
            return list?.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.operationQueue?.operationCount > 0)
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
                mediaItem.downloads.values.forEach({ (download) in
                    download.delete(block:true)
                })
            })
            
            if alert {
                Alerts.shared.alert(title: "All Downloads Deleted", message: self.multiPartName)
            }
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
            } else {
                Alerts.shared.alert(title: "Some \(name) Downloads Were Not Deleted", message: self.multiPartName)
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
        let notifyOperation = CancelableOperation { [weak self] (test:(()->Bool)?) in
            var message = ""
            
            if let multiPartName = self?.multiPartName {
                message += multiPartName + "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            Alerts.shared.alert(title: "Canceling All \(name) Downloads", message: message)
            
            self?.list?.forEach({ (mediaItem) in
                mediaItem.downloads[purpose]?.cancel()
            })
            
            if self?.downloading(purpose:purpose) == 0 {
                Alerts.shared.alert(title: "All \(name) Downloads Canceled", message: self?.multiPartName)
            }
        }
        
        for operation in mediaQueue.operations {
            guard let operation = operation as? CancelableOperation else {
                continue
            }
            
            if operation.tag == purpose {
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
    
//    func cancelAllAudioDownloads()
//    {
//        for operation in mediaQueue.operations {
//            guard let operation = operation as? CancelableOperation else {
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
//            Alerts.shared.alert(title: "Canceling All Audio Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.audioDownload?.cancel()
//            })
//
//            if self.audioDownloading == 0 {
//                Alerts.shared.alert(title: "All Audio Downloads Canceled", message: self.multiPartName)
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
//            guard let operation = operation as? CancelableOperation else {
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
//            Alerts.shared.alert(title: "Canceling All Video Downloads", message: message)
//
//            self.list?.forEach({ (mediaItem) in
//                mediaItem.videoDownload?.cancel()
//            })
//
//            if self.videoDownloading == 0 {
//                Alerts.shared.alert(title: "All Video Downloads Canceled", message: self.multiPartName)
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
        
        let monitorOperation = CancelableOperation(tag:purpose) { [weak self] (test:(()->Bool)?) in
            while self?.notesDownloading > 0 {
                if let test = test, test() {
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
//        //        let operation = CancelableOperation { [weak self] (test:(()->Bool)?) in
//        //            for mediaItem in list {
//        //                if let test = test, test() {
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
//        //                    if let test = test, test() {
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
//        let monitorOperation = CancelableOperation(tag:Purpose.notes) { [weak self] (test:(()->Bool)?) in
//            while self?.notesDownloading > 0 {
//                if let test = test, test() {
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
//            let operation = CancelableOperation(tag:Purpose.notes) { [weak self] (test:(()->Bool)?) in
//                _ = download?.download(background: true)
//
//                while download?.state == .downloading {
//                    if let test = test, test() {
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
//        //        let operation = CancelableOperation { [weak self] (test:(()->Bool)?) in
//        //            for mediaItem in list {
//        //                if let test = test, test() {
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
//        //                    if let test = test, test() {
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
//        let monitorOperation = CancelableOperation(tag:Purpose.slides) { [weak self] (test:(()->Bool)?) in
//            while self?.slidesDownloading > 0 {
//                if let test = test, test() {
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
//            let operation = CancelableOperation(tag:Purpose.slides) { [weak self] (test:(()->Bool)?) in
//                _ = download?.download(background: true)
//
//                while download?.state == .downloading {
//                    if let test = test, test() {
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

    private lazy var mediaQueue : OperationQueue! = {
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
            mediaItem.addToFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Added to Favorites",message: multiPartName)
    }

    func removeAllFromFavorites()
    {
//        guard let list = list else {
//            break
//        }

        list?.forEach({ (mediaItem) in
            mediaItem.removeFromFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Removed to Favorites",message: multiPartName)
        
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
//        let monitorOperation = CancelableOperation(tag:Purpose.audio) { [weak self] (test:(()->Bool)?) in
//            while self?.audioDownloading > 0 {
//                if let test = test, test() {
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
//            let operation = CancelableOperation(tag:Purpose.audio) { [weak self] (test:(()->Bool)?) in
//                _ = download?.download(background: true)
//
//                while download?.state == .downloading {
//                    if let test = test, test() {
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
//        let monitorOperation = CancelableOperation(tag:Purpose.video) { [weak self] (test:(()->Bool)?) in
//            while self?.videoDownloading > 0 {
//                if let test = test, test() {
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
//            let operation = CancelableOperation(tag:Purpose.video) { [weak self] (test:(()->Bool)?) in
//                _ = download?.download(background: true)
//
//                while download?.state == .downloading {
//                    if let test = test, test() {
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
    
    var listDidSet : (()->(Void))?

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
            
            listDidSet?()
            
            updateIndex()
//            updateCacheSize()
        }
    }
    
    var index = ThreadSafeDN<MediaItem>() // :[String:MediaItem]? //MediaItems indexed by ID.
    var classes = ThreadSafeArray<String>() // :[String]?
    var events = ThreadSafeArray<String>() // :[String]?

//    func setupMediaItemsHTMLGlobal(includeURLs:Bool,includeColumns:Bool) -> String?
//    {
//        guard (Globals.shared.media.active?.mediaList?.list != nil) else {
//            return nil
//        }
//        
//        guard let grouping = Globals.shared.grouping else {
//            return nil
//        }
//        
//        guard let sorting = Globals.shared.sorting else {
//            return nil
//        }
//        
//        var bodyString = "<!DOCTYPE html><html><body>"
//        
//        bodyString = bodyString + "The following media "
//        
//        if Globals.shared.media.active?.mediaList?.list?.count > 1 {
//            bodyString = bodyString + "are"
//        } else {
//            bodyString = bodyString + "is"
//        }
//        
//        if includeURLs {
//            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
//        } else {
//            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
//        }
//        
//        if let category = Globals.shared.mediaCategory.selected {
//            bodyString = bodyString + "Category: \(category)<br/>"
//        }
//        
//        if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
//            bodyString = bodyString + "Collection: \(tag)<br/>"
//        }
//        
//        if Globals.shared.search.isValid, let searchText = Globals.shared.search.text {
//            bodyString = bodyString + "Search: \(searchText)<br/>"
//        }
//        
//        bodyString = bodyString + "Grouped: By \(grouping.translate)<br/>"
//
//        bodyString = bodyString + "Sorted: \(sorting.translate)<br/>"
//
//        if let keys = Globals.shared.media.active?.section?.indexStrings {
//            var count = 0
//            for key in keys {
//                if let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
//                    count += mediaItems.count
//                }
//            }
//            
//            bodyString = bodyString + "Total: \(count)<br/>"
//            
//            if includeURLs, (keys.count > 1) {
//                bodyString = bodyString + "<br/>"
//                bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
//            }
//            
//            if includeColumns {
//                bodyString = bodyString + "<table>"
//            }
//            
//            for key in keys {
//                if  let name = Globals.shared.media.active?.groupNames?[grouping]?[key],
//                    let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
//                    var speakerCounts = [String:Int]()
//                    
//                    for mediaItem in mediaItems {
//                        if let speaker = mediaItem.speaker {
//                            if let count = speakerCounts[speaker] {
//                                speakerCounts[speaker] = count + 1
//                            } else {
//                                speakerCounts[speaker] = 1
//                            }
//                        }
//                    }
//                    
//                    let speakerCount = speakerCounts.keys.count
//                    
//                    let tag = key.asTag
//                    
//                    if includeColumns {
//                        if includeURLs {
//                            bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>"
//                        } else {
//                            bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>"
//                        }
//                    } else {
//                        if includeURLs {
//                            bodyString = bodyString + "<br/>"
//                        } else {
//                            bodyString = bodyString + "<br/>"
//                        }
//                    }
//                    
//                    if includeColumns {
//                        bodyString = bodyString + "<tr>"
//                        bodyString = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                    }
//                    
//                    if includeURLs, (keys.count > 1) {
//                        bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + "</a>" //  + " (\(mediaItems.count))"
//                    } else {
//                        bodyString = bodyString + name + " (\(mediaItems.count))"
//                    }
//                    
//                    if speakerCount == 1 {
//                        if var speaker = mediaItems[0].speaker, name != speaker {
//                            if let speakerTitle = mediaItems[0].speakerTitle {
//                                speaker += ", \(speakerTitle)"
//                            }
//                            bodyString = bodyString + " by " + speaker
//                        }
//                    }
//                    
//                    if includeColumns {
//                        bodyString = bodyString + "</td>"
//                        bodyString = bodyString + "</tr>"
//                    } else {
//                        bodyString = bodyString + "<br/>"
//                    }
//                    
//                    for mediaItem in mediaItems {
//                        var order = ["date","title","scripture"]
//                        
//                        if speakerCount > 1 {
//                            order.append("speaker")
//                        }
//                        
//                        if Globals.shared.grouping != GROUPING.CLASS {
//                            if mediaItem.hasClassName {
//                                order.append("class")
//                            }
//                        }
//                        
//                        if Globals.shared.grouping != GROUPING.EVENT {
//                            if mediaItem.hasEventName {
//                                order.append("event")
//                            }
//                        }
//                        
//                        if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
//                            bodyString = bodyString + string
//                        }
//                        
//                        if !includeColumns {
//                            bodyString = bodyString + "<br/>"
//                        }
//                    }
//                }
//            }
//            
//            if includeColumns {
//                bodyString = bodyString + "</table>"
//            }
//            
//            bodyString = bodyString + "<br/>"
//            
//            if includeURLs, keys.count > 1 {
//                bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
//                
//                switch grouping {
//                case GROUPING.CLASS:
//                    fallthrough
//                case GROUPING.SPEAKER:
//                    fallthrough
//                case GROUPING.TITLE:
//                    let a = "A"
//                    
//                    if let indexTitles = Globals.shared.media.active?.section?.indexStrings {
//                        let titles = Array(Set(indexTitles.map({ (string:String) -> String in
//                            if string.count >= a.count { // endIndex
//                                return String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
//                            } else {
//                                return string
//                            }
//                        }))).sorted() { $0 < $1 }
//                        
//                        var stringIndex = [String:[String]]()
//                        
//                        if let indexStrings = Globals.shared.media.active?.section?.indexStrings {
//                            for indexString in indexStrings {
//                                let key = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)]).uppercased()
//                                
//                                if stringIndex[key] == nil {
//                                    stringIndex[key] = [String]()
//                                }
//                                
//                                stringIndex[key]?.append(indexString)
//                            }
//                        }
//                        
//                        var index:String?
//                        
//                        for title in titles {
//                            let link = "<a href=\"#\(title)\">\(title)</a>"
//                            index = ((index != nil) ? index! + " " : "") + link
//                        }
//                        
//                        bodyString = bodyString + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
//                        
//                        if let index = index {
//                            bodyString = bodyString + index + "<br/>"
//                        }
//                        
//                        for title in titles {
//                            bodyString = bodyString + "<br/>"
//                            if let count = stringIndex[title]?.count { // Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count
//                                bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a> (\(count))<br/>"
//                            } else {
//                                bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
//                            }
//                            
//                            if let keys = stringIndex[title] {
//                                for key in keys {
//                                    if let title = Globals.shared.media.active?.groupNames?[grouping]?[key] {
//                                        let tag = key.asTag
//                                        bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a><br/>" // (\(count))
//                                    }
//                                }
//                            }
//                            
//                            bodyString = bodyString + "</div>"
//                        }
//                        
//                        bodyString = bodyString + "</div>"
//                    }
//                    break
//                    
//                default:
//                    for key in keys {
//                        if let title = Globals.shared.media.active?.groupNames?[grouping]?[key],
//                            let count = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count {
//                            let tag = key.asTag
//                            bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
//                        }
//                    }
//                    break
//                }
//                
//                bodyString = bodyString + "</div>"
//            }
//        }
//        
//        bodyString = bodyString + "</body></html>"
//        
//        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
//    }
    
//    func translateTestament(_ testament:String) -> String
//    {
//        var translation = Constants.EMPTY_STRING
//
//        switch testament {
//        case Constants.OT:
//            translation = Constants.Old_Testament
//            break
//
//        case Constants.NT:
//            translation = Constants.New_Testament
//            break
//
//        default:
//            break
//        }
//
//        return translation
//    }
//
//    func translate(_ string:String?) -> String?
//    {
//        guard let string = string else {
//            return nil
//        }
//
//        switch string {
//        case SORTING.CHRONOLOGICAL:
//            return Sorting.Oldest_to_Newest
//
//        case SORTING.REVERSE_CHRONOLOGICAL:
//            return Sorting.Newest_to_Oldest
//
//        case GROUPING.YEAR:
//            return Grouping.Year
//
//        case GROUPING.TITLE:
//            return Grouping.Title
//
//        case GROUPING.BOOK:
//            return Grouping.Book
//
//        case GROUPING.SPEAKER:
//            return Grouping.Speaker
//
//        case GROUPING.CLASS:
//            return Grouping.Class
//
//        case GROUPING.EVENT:
//            return Grouping.Event
//
//        default:
//            return "ERROR"
//        }
//    }
    
//    func setupMediaItemsHTML(_ mediaItems:[MediaItem]?,includeURLs:Bool = true,includeColumns:Bool = true) -> String?
//    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
//        
//        var mediaListSort = [String:[MediaItem]]()
//        
//        for mediaItem in mediaItems {
//            if let multiPartName = mediaItem.multiPartName?.withoutPrefixes {
//                if mediaListSort[multiPartName] == nil {
//                    mediaListSort[multiPartName] = [mediaItem]
//                } else {
//                    mediaListSort[multiPartName]?.append(mediaItem)
//                }
//            } else {
//                if let title = mediaItem.title {
//                    if mediaListSort[title] == nil {
//                        mediaListSort[title] = [mediaItem]
//                    } else {
//                        mediaListSort[title]?.append(mediaItem)
//                    }
//                }
//            }
//        }
//        
//        var bodyString = "<!DOCTYPE html><html><body>"
//        
//        bodyString = bodyString + "The following media "
//        
//        if mediaItems.count > 1 {
//            bodyString = bodyString + "are"
//        } else {
//            bodyString = bodyString + "is"
//        }
//        
//        if includeURLs {
//            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
//            
//            //        bodyString = bodyString + " from <a target=\"_blank\" href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
//        } else {
//            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
//        }
//        
//        //    if let category = Globals.shared.mediaCategory.selected {
//        //        bodyString = bodyString + "Category: \(category)<br/><br/>"
//        //    }
//        //
//        //    if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
//        //        bodyString = bodyString + "Collection: \(tag)<br/><br/>"
//        //    }
//        //
//        //    if Globals.shared.search.isValid, let searchText = Globals.shared.search.text {
//        //        bodyString = bodyString + "Search: \(searchText)<br/><br/>"
//        //    }
//        
//        let keys = Array(mediaListSort.keys).sorted() {
//            $0.withoutPrefixes < $1.withoutPrefixes
//        }
//        
//        if includeURLs, (keys.count > 1) {
//            bodyString = bodyString + "<a href=\"#index\">Index</a><br/><br/>"
//        }
//        
//        //    var lastKey:String?
//        
//        if includeColumns {
//            bodyString  = bodyString + "<table>"
//        }
//        
//        for key in keys {
//            if let mediaItems = mediaListSort[key]?.sorted(by: { (first, second) -> Bool in
//                return first.date < second.date
//            }) {
//                if includeColumns {
//                    bodyString  = bodyString + "<tr>"
//                    bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                }
//                
//                bodyString = bodyString + "<br/>"
//                
//                if includeColumns {
//                    bodyString  = bodyString + "</td>"
//                    bodyString  = bodyString + "</tr>"
//                }
//                
//                switch mediaItems.count {
//                case 1:
//                    if let mediaItem = mediaItems.first {
//                        if let string = mediaItem.bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs:includeURLs, includeColumns:includeColumns) {
//                            let tag = key.asTag
//                            if includeURLs, keys.count > 1 {
//                                bodyString  = bodyString + "<tr>"
//                                bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                                bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
//                                bodyString  = bodyString + "</td>"
//                                bodyString  = bodyString + "</tr>"
//                            }
//                            bodyString = bodyString + string
//                        }
//                    }
//                    break
//                    
//                default:
//                    var speakerCounts = [String:Int]()
//                    
//                    for mediaItem in mediaItems {
//                        if let speaker = mediaItem.speaker {
//                            if let count = speakerCounts[speaker] {
//                                speakerCounts[speaker] = count + 1
//                            } else {
//                                speakerCounts[speaker] = 1
//                            }
//                        }
//                    }
//                    
//                    let speakerCount = speakerCounts.keys.count
//                    
//                    if includeColumns {
//                        bodyString  = bodyString + "<tr>"
//                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                    }
//                    
//                    if includeURLs, keys.count > 1 {
//                        let tag = key.asTag
//                        bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
//                    } else {
//                        bodyString = bodyString + key
//                    }
//                    
//                    if speakerCount == 1, let speaker = mediaItems[0].speaker, key != speaker {
//                        bodyString = bodyString + " by " + speaker
//                    }
//                    
//                    if includeColumns {
//                        bodyString  = bodyString + "</td>"
//                        bodyString  = bodyString + "</tr>"
//                    } else {
//                        bodyString = bodyString + "<br/>"
//                    }
//                    
//                    for mediaItem in mediaItems {
//                        var order = ["date","title","scripture"]
//                        
//                        if speakerCount > 1 {
//                            order.append("speaker")
//                        }
//                        
//                        if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
//                            bodyString = bodyString + string
//                        }
//                        
//                        if !includeColumns {
//                            bodyString = bodyString + "<br/>"
//                        }
//                    }
//                    
//                    if !includeColumns {
//                        bodyString = bodyString + "<br/>"
//                    }
//                    
//                    //                if let lastKey = lastKey, let count = mediaListSort[lastKey]?.count, count == 1 {
//                    //                    if includeColumns {
//                    //                        bodyString  = bodyString + "<tr>"
//                    //                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                    //                    }
//                    //
//                    //                    bodyString = bodyString + "<br/>"
//                    //
//                    //                    if includeColumns {
//                    //                        bodyString  = bodyString + "</td>"
//                    //                        bodyString  = bodyString + "</tr>"
//                    //                    }
//                    //                }
//                    break
//                }
//            }
//            
//            //        lastKey = key
//        }
//        
//        if includeColumns {
//            bodyString  = bodyString + "</table>"
//        }
//        
//        bodyString = bodyString + "<br/>"
//        
//        if includeURLs, (keys.count > 1) {
//            //        if let indexTitles = keys {
//            
//            let a = "a"
//            
//            let titles = Array(Set(keys.map({ (string:String) -> String in
//                if string.count >= a.count { // endIndex
//                    return String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
//                } else {
//                    return string
//                }
//            }))).sorted() { $0 < $1 }
//            
//            var stringIndex = [String:[String]]()
//            
//            for string in keys {
//                let key = String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
//                
//                if stringIndex[key] == nil {
//                    stringIndex[key] = [String]()
//                }
//                
//                stringIndex[key]?.append(string)
//            }
//            
//            bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
//            //        bodyString = bodyString + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
//            
//            var index:String?
//            
//            for title in titles {
//                let link = "<a href=\"#\(title)\">\(title)</a>"
//                index = ((index != nil) ? index! + " " : "") + link
//            }
//            
//            bodyString = bodyString + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
//            
//            if let index = index {
//                bodyString = bodyString + index + "<br/>"
//            }
//            
//            for title in titles {
//                bodyString = bodyString + "<br/>"
//                
//                let tag = title.asTag
//                if let count = stringIndex[title]?.count {
//                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title) (\(count))</a><br/>"
//                } else {
//                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title)</a><br/>"
//                }
//                
//                if let entries = stringIndex[title] {
//                    for entry in entries {
//                        let tag = entry.asTag
//                        bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(entry)</a><br/>"
//                    }
//                }
//                
//                bodyString = bodyString + "</div>"
//            }
//            
//            bodyString = bodyString + "</div>"
//            //        }
//            
//            //        bodyString = bodyString + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
//            //
//            //        for key in keys {
//            //            bodyString = bodyString + "<a href=\"#\(key.asTag)\">\(key)</a><br/>"
//            //        }
//            //
//            //        bodyString = bodyString + "</div>"
//        }
//        
//        bodyString = bodyString + "</body></html>"
//        
//        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
//    }
    
    func testMediaItemsPDFs(testExisting:Bool, testMissing:Bool, showTesting:Bool)
    {
        guard let mediaItems = list else {
            print("Testing the availability of mediaItem PDF's - no list")
            return
        }
        
        var counter = 1
        
        if (testExisting) {
            print("Testing the availability of mediaItem PDFs that we DO have in the mediaItemDicts - start")
            
            for mediaItem in mediaItems {
                if (showTesting) {
                    print("Testing: \(counter) \(mediaItem.title ?? mediaItem.description)")
                } else {
                    //                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if let title = mediaItem.title, let notesURLString = mediaItem.notes, let notesURL = mediaItem.notes?.url {
                    if ((try? Data(contentsOf: notesURL)) == nil) {
                        print("Transcript DOES NOT exist for: \(title) PDF: \(notesURLString)")
                    } else {
                        
                    }
                }
                
                if let title = mediaItem.title, let slidesURLString = mediaItem.slides, let slidesURL = mediaItem.slides?.url {
                    if ((try? Data(contentsOf: slidesURL)) == nil) {
                        print("Slides DO NOT exist for: \(title) PDF: \(slidesURLString)")
                    } else {
                        
                    }
                }
                
                counter += 1
            }
            
            print("\nTesting the availability of mediaItem PDFs that we DO have in the mediaItemDicts - end")
        }
        
        if (testMissing) {
            print("Testing the availability of mediaItem PDFs that we DO NOT have in the mediaItemDicts - start")
            
            counter = 1
            for mediaItem in mediaItems {
                if (showTesting) {
                    print("Testing: \(counter) \(mediaItem.title ?? mediaItem.description)")
                } else {
                    
                }
                
                if (mediaItem.audio == nil) {
                    print("No Audio file for: \(String(describing: mediaItem.title)) can't test for PDF's")
                } else {
                    if let title = mediaItem.title, let id = mediaItem.id, let notesURL = mediaItem.notes?.url {
                        if ((try? Data(contentsOf: notesURL)) != nil) {
                            print("Transcript DOES exist for: \(title) ID:\(id)")
                        } else {
                            
                        }
                    }
                    
                    if let title = mediaItem.title, let id = mediaItem.id, let slidesURL = mediaItem.slides?.url {
                        if ((try? Data(contentsOf: slidesURL)) != nil) {
                            print("Slides DO exist for: \(title) ID: \(id)")
                        } else {
                            
                        }
                    }
                }
                
                counter += 1
            }
            
            print("\nTesting the availability of mediaItem PDFs that we DO NOT have in the mediaItemDicts - end")
        }
    }
    
    func testMediaItemsTagsAndSeries()
    {
        print("Testing for mediaItem series and tags the same - start")
        defer {
            print("Testing for mediaItem series and tags the same - end")
        }
        
        if let mediaItems = list {
            for mediaItem in mediaItems {
                if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                    if (mediaItem.multiPartName == mediaItem.tags) {
                        print("Multiple Part Name and Tags the same in: \(mediaItem.title ?? mediaItem.description) Multiple Part Name:\(mediaItem.multiPartName ?? mediaItem.description) Tags:\(mediaItem.tags ?? mediaItem.description)")
                    }
                }
            }
        }
    }
    
    func testMediaItemsForAudio()
    {
        print("Testing for audio - start")
        defer {
            print("Testing for audio - end")
        }
        
        guard let list = list else {
            print("Testing for audio - list empty")
            return
        }
        
        for mediaItem in list {
            if (!mediaItem.hasAudio) {
                print("Audio missing in: \(mediaItem.title ?? mediaItem.description)")
            } else {
                
            }
        }
        
    }
    
    func testMediaItemsForSpeaker()
    {
        print("Testing for speaker - start")
        defer {
            print("Testing for speaker - end")
        }
        
        guard let list = list else {
            print("Testing for speaker - no list")
            return
        }
        
        for mediaItem in list {
            if (!mediaItem.hasSpeaker) {
                print("Speaker missing in: \(mediaItem.title ?? mediaItem.description)")
            }
        }
    }
    
    func testMediaItemsForSeries()
    {
        print("Testing for mediaItems with \"(Part \" in the title but no series - start")
        defer {
            print("Testing for mediaItems with \"(Part \" in the title but no series - end")
        }
        
        guard let list = list else {
            print("Testing for speaker - no list")
            return
        }
        
        for mediaItem in list {
            if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
                print("Series missing in: \(mediaItem.title ?? mediaItem.description)")
            }
        }
    }

}

