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
    
    func autoEditAllAudioTranscripts(viewController:UIViewController)
    {
        autoEditAllTranscripts(viewController:viewController,purpose:Purpose.audio)
    }
    
    func autoEditAllVideoTranscripts(viewController:UIViewController)
    {
        autoEditAllTranscripts(viewController:viewController,purpose:Purpose.video)
    }
    
    func autoEditAllTranscripts(viewController:UIViewController,purpose:String)
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
    
    func removeAllAudioTranscripts(viewController:UIViewController)
    {
        removeAllTranscripts(viewController:viewController,purpose:Purpose.audio)
    }
    
    func removeAllVideoTranscripts(viewController:UIViewController)
    {
        removeAllTranscripts(viewController:viewController,purpose:Purpose.video)
    }
    
    func removeAllTranscripts(viewController:UIViewController,purpose:String)
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
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.remove(alert: true)
            
            if let text = mediaItem.text {
                Alerts.shared.alert(title: "Transcript Removed",message: "The transcript for\n\n\(text) (\(transcript.transcriptPurpose))\n\nhas been removed.")
            }
        }
    }
    
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
    
    func downloadingAll(name:String) -> Bool
    {
        return mediaQueue.operations.filter({ (operation:Operation) -> Bool in
            return (operation as? CancelableOperation)?.tag == Constants.Strings.Download_All + Constants.SINGLE_SPACE + name
        }).count > 0
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
    
    func deleteAllVideoDownloads()
    {
        deleteAllDownloads(purpose: Purpose.video, name: Constants.Strings.Video)
    }
    
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

    func addAllToFavorites()
    {
        list?.forEach({ (mediaItem) in
            mediaItem.addToFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Added to Favorites",message: multiPartName)
    }

    func removeAllFromFavorites()
    {
        list?.forEach({ (mediaItem) in
            mediaItem.removeFromFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Removed to Favorites",message: multiPartName)
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
    
    func downloadAllVideo()
    {
        downloadAll(purpose: Purpose.video, name: Constants.Strings.Video)
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
    
    var listDidSet : (()->(Void))?

    init(_ list:[MediaItem]? = nil)
    {
        self.list = list
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
                
                if (mediaItem.audioURL == nil) {
                    print("No Audio file for: \(String(describing: mediaItem.title)) can't test for PDF's")
                } else {
                    if let title = mediaItem.title, let id = mediaItem.mediaCode, let notesURL = mediaItem.notes?.url {
                        if ((try? Data(contentsOf: notesURL)) != nil) {
                            print("Transcript DOES exist for: \(title) ID:\(id)")
                        } else {
                            
                        }
                    }
                    
                    if let title = mediaItem.title, let id = mediaItem.mediaCode, let slidesURL = mediaItem.slides?.url {
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

