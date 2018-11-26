//
//  Download.swift
//  CBC
//
//  Created by Steve Leeke on 12/15/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case downloading
    case downloaded
    case none
}

extension Download : URLSessionDownloadDelegate
{
    // MARK: URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        debug("urlSession:didWriteData")
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
            
            let title = "Download Failed (\(downloadPurpose))"
            
            if state != .none {
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let taskDescription = downloadTask.taskDescription, let index = taskDescription.range(of: ".") {
                    let id = String(taskDescription[..<index.lowerBound])
                    if let mediaItem = Globals.shared.mediaRepository.index?[id] {
                        Alerts.shared.alert(title: title, message: mediaItem.title)
                    }
                } else {
                    Alerts.shared.alert(title: title, message: nil)
                }
            } else {
                print("previously dealt with")
            }
            
            cancel()
            return
        }
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if let purpose = purpose {
            switch purpose {
            case Purpose.audio:
                if bytesWritten > 0 {
                    Thread.onMainThread {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    }
                }
                break
                
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                if bytesWritten > 0 {
                    Thread.onMainThread {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self)
                    }
                }
                break
                
            default:
                break
            }
        }
        
        debug("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
        
        if let fileSystemURL = fileSystemURL {
            debug("path: \(fileSystemURL.path)")
            debug("filename: \(fileSystemURL.lastPathComponent)")
            
            if (downloadTask.taskDescription != fileSystemURL.lastPathComponent) {
                debug("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(totalBytesWritten)")
        debug("bytes expected to write: \(totalBytesExpectedToWrite)")
        
        if (state == .downloading) {
            self.totalBytesWritten = totalBytesWritten
            self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        } else {
            print("ERROR NOT DOWNLOADING")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        debug("urlSession:didFinishDownloadingTo \(location.lastPathComponent)")

        guard let statusCode = (task?.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR",(task?.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite as Any)
            
            let title = "Download Failed (\(downloadPurpose))"
            
            if state != .none {
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let taskDescription = downloadTask.taskDescription, let index = taskDescription.range(of: ".") {
                    let id = String(taskDescription[..<index.lowerBound])
                    
                    if let mediaItem = Globals.shared.mediaRepository.index?[id] {
                        Alerts.shared.alert(title: title, message: mediaItem.title)
                    }
                } else {
                    Alerts.shared.alert(title: title, message: nil)
                }
            } else {
                print("previously dealth with")
            }
            
            cancel()
            return
        }
        
        guard let fileSystemURL = fileSystemURL else {
            print("NO FILE SYSTEM URL!")
            return
        }
        
        debug("URLSession:downloadTask:didFinishDownloadingToURL:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
        
        if let purpose = purpose {
            debug("purpose: \(purpose)")
        }
        
        debug("path: \(fileSystemURL.path)")
        debug("filename: \(fileSystemURL.lastPathComponent)")
        
        if (downloadTask.taskDescription != fileSystemURL.lastPathComponent) {
            debug("task.taskDescription != fileSystemURL.lastPathComponent")
        }
        
        debug("bytes written: \(totalBytesWritten)")
        debug("bytes expected to write: \(totalBytesExpectedToWrite)")
        
        let fileManager = FileManager.default
        
        do {
            if (state == .downloading) { //  && (download!.totalBytesExpectedToWrite != -1)
                fileSystemURL.delete(block:true)
//                if (fileManager.fileExists(atPath: fileSystemURL.path)){
//                    do {
//                        try fileManager.removeItem(at: fileSystemURL)
//                    } catch let error {
//                        print("failed to remove duplicate download: \(error.localizedDescription)")
//                    }
//                }
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: fileSystemURL)
                
                location.delete(block:true)
//                try fileManager.removeItem(at: location)
                
                state = .downloaded
            } else {
                // Nothing was downloaded
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
                }
                
                state = .none
            }
        } catch let error {
            print("failed to copy temp download file: \(error.localizedDescription)")
            state = .none
        }
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        debug("urlSession:didCompleteWithError")
        
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            error == nil else {
                print("DOWNLOAD ERROR:",task.taskDescription as Any,(task.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite as Any)
                
                if let error = error {
                    print("with error: \(error.localizedDescription)")
                }
                
                let title = "Download Failed (\(downloadPurpose))"
                
                if state != .none {
                    Thread.onMainThread {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    if let taskDescription = task.taskDescription, let index = taskDescription.range(of: ".") {
                        let id = String(taskDescription[..<index.lowerBound])
                        
                        if let message = Globals.shared.mediaRepository.index?[id]?.title {
                            if let error = error {
                                Alerts.shared.alert(title: title, message: message + "\nError: \(error.localizedDescription)")
                            } else {
                                Alerts.shared.alert(title: title, message: message)
                            }
                        }
                    } else {
                        if let error = error {
                            Alerts.shared.alert(title: title, message: "Error: \(error.localizedDescription)")
                        } else {
                            Alerts.shared.alert(title: title, message: nil)
                        }
                    }
                } else {
                    print("previously dealt with")
                }
                
                cancel()
                
                return
        }
        
        debug("URLSession:task:didCompleteWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("task: \(String(describing: task.taskDescription))")
        
        if let purpose = purpose {
            debug("purpose: \(purpose)")
        }
        
        if let fileSystemURL = fileSystemURL {
            debug("path: \(fileSystemURL.path)")
            debug("filename: \(fileSystemURL.lastPathComponent)")
            
            if (task.taskDescription != fileSystemURL.lastPathComponent) {
                debug("task.taskDescription != download!.fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(totalBytesWritten)")
        debug("bytes expected to write: \(totalBytesExpectedToWrite)")
        
        if let error = error, let purpose = purpose {
            print("with error: \(error.localizedDescription)")
            
            switch purpose {
            case Purpose.slides:
                fallthrough
            case Purpose.notes:
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.download)
                }
                break
                
            default:
                break
            }
        }
        
        session.invalidateAndCancel()
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        debug("URLSession:didBecomeInvalidWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        
        if let purpose = purpose {
            debug("purpose: \(purpose)")
        }
        
        if let fileSystemURL = fileSystemURL {
            debug("path: \(fileSystemURL.path)")
            debug("filename: \(fileSystemURL.lastPathComponent)")
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(totalBytesWritten)")
        debug("bytes expected to write: \(totalBytesExpectedToWrite)")
        
        if let error = error {
            print("with error: \(error.localizedDescription)")
        }
        
        self.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        guard let identifier = session.configuration.identifier else {
            return
        }
        
        let filename = String(identifier[Constants.DOWNLOAD_IDENTIFIER.endIndex...])

        if task?.taskDescription == filename {
            completionHandler?()
        }
    }
}

class Download : NSObject
{
    init(mediaItem:MediaItem?,purpose:String?,downloadURL:URL?,fileSystemURL:URL?)
    {
        self.mediaItem = mediaItem
        self.purpose = purpose
        self.downloadURL = downloadURL
        self.fileSystemURL = fileSystemURL
        
        if let fileSystemURL = fileSystemURL {
            if FileManager.default.fileExists(atPath: fileSystemURL.path) {
                self.state = .downloaded
            }
        }
    }
    
    deinit {
        
    }
    
    weak var mediaItem:MediaItem?
    
    var purpose:String?
    
    var downloadPurpose:String
    {
        get {
            var downloadPurpose:String!
            
            if let purpose = purpose {
                switch purpose {
                case Purpose.audio:
                    downloadPurpose = Constants.Strings.Audio
                    break
                    
                case Purpose.video:
                    downloadPurpose = Constants.Strings.Video
                    break
                    
                case Purpose.slides:
                    downloadPurpose = Constants.Strings.Slides
                    break
                    
                case Purpose.notes:
                    downloadPurpose = Constants.Strings.Transcript
                    break
                    
                default:
                    downloadPurpose = "ERROR"
                    break
                }
            }
            
            return downloadPurpose.lowercased()
        }
    }
    
    var downloadURL:URL?
    
    var fileSystemURL:URL?
    {
        willSet {
            
        }
        didSet {
            state = exists ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:URLSession? // We're using a session for each download.  Not sure is the best but it works.
    
    var task:URLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }

    @objc func downloadFailed()
    {
        Alerts.shared.alert(title: "Network Error",message: "Download failed.")
    }

    var state:State = .none {
        willSet {
            
        }
        didSet {
            guard state != oldValue else {
                return
            }
            
            switch state {
            case .downloading:
                Thread.onMainThread {
                    // The following must appear AFTER we change the state
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADING), object: self)
                }
                break
                
            case .downloaded:
                fileSize = fileSystemURL?.fileSize
                
                Thread.onMainThread {
                    // The following must appear AFTER we change the state
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self)
                }
                break
                
            case .none:
                break
            }

            guard let purpose = purpose else {
                return
            }
            
            switch purpose {
            case Purpose.audio:
                switch state {
                case .downloading:
                    break
                    
                case .downloaded:
                    // This blocks this thread until it finishes.
                    Globals.shared.queue.sync {
                        self.mediaItem?.addTag(Constants.Strings.Downloaded)
                    }
                    break
                    
                case .none:
                    // This blocks this thread until it finishes.
                    Globals.shared.queue.sync {
                        self.mediaItem?.removeTag(Constants.Strings.Downloaded)
                    }
                    break
                }
                
                Thread.onMainThread {
                    // The following must appear AFTER we change the state
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                }
                break
                
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                switch state {
                case .downloading:
                    break
                    
                case .downloaded:
                    Thread.onMainThread {
                        // The following must appear AFTER we change the state
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.mediaItem)
                    }
                    break
                    
                case .none:
                    break
                }
                break
                
            default:
                break
            }
        }
    }
    
    var completionHandler: (() -> (Void))?
    
    var exists : Bool
    {
        get {
            if let fileSystemURL = fileSystemURL {
                return FileManager.default.fileExists(atPath: fileSystemURL.path)
            } else {
                return false
            }
        }
    }
    
    func download()
    {
        guard state != .downloading else {
            return
        }
        
        guard fileSystemURL?.exists == false else {
            return
        }
        
        guard let downloadURL = downloadURL else {
            print(mediaItem?.title as Any)
            print(purpose as Any)
            print(fileSystemURL as Any)
            return
        }
        
        guard (state == .none) else {
            return
        }
        
        state = .downloading

        let downloadRequest = URLRequest(url: downloadURL)
        
        let configuration = URLSessionConfiguration.default // background(withIdentifier: id + purpose)
        
        // This allows the downloading to continue even if the app goes into the background or terminates.
        //            let configuration = URLSessionConfiguration.background(withIdentifier: Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent)
        //            configuration.sessionSendsLaunchEvents = true
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session?.reset() {}
        
        session?.sessionDescription = fileSystemURL?.lastPathComponent
        
        task = session?.downloadTask(with: downloadRequest)
        task?.taskDescription = fileSystemURL?.lastPathComponent
        
        task?.resume()
        
        Thread.onMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
    
//    lazy var fileSize:Shadowed<Int> = {
//        return Shadowed<Int>(get:{
//            return self.fileSystemURL?.fileSize
//        })
//    }()

    private var _fileSize : Int?
    {
        didSet {
            
        }
    }
    var fileSize : Int?
    {
        get {
            guard state == .downloaded else {
                return 0
            }
            
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
            }

            return fileSize
        }
        set {
            _fileSize = newValue
        }
    }
    
//    var fileSize:Int
//    {
//        var size = 0
//
//        guard let fileSystemURL = fileSystemURL else {
//            return size
//        }
//
//        guard fileSystemURL.downloaded else {
//            return size
//        }
//
//        do {
//            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL.path)
//
//            if let num = fileAttributes[FileAttributeKey.size] as? Int {
//                size = num
//            }
//        } catch let error {
//            print("failed to get file attributes for \(fileSystemURL): \(error.localizedDescription)")
//        }
//
//        return size
//    }
    
//    var fileSize : Int?
//    {
//        get {
//            return fileSystemURL?.fileSize
//        }
//    }
    
    func delete(block:Bool)
    {
        guard state == .downloaded else {
            return
        }
        
        fileSize = nil
        fileSystemURL?.delete(block:block)
        
//        // Check if file exists and if so, delete it.
//        if (FileManager.default.fileExists(atPath: fileSystemURL.path)){
//            do {
//                try FileManager.default.removeItem(at: fileSystemURL)
//            } catch let error {
//                print("failed to delete download: \(error.localizedDescription)")
//            }
//        }
        
        state = .none // MUST delete file first as state change updates UI.
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
    }
    
    func cancelOrDelete()
    {
        switch state {
        case .downloading:
            cancel()
            break
            
        case .downloaded:
            delete(block:true)
            break
            
        default:
            break
        }
    }
    
    func cancel()
    {
        guard active else {
            return
        }

        state = .none
        
        task?.cancel()
        task = nil
        
        totalBytesWritten = 0
        totalBytesExpectedToWrite = 0
    }
}

