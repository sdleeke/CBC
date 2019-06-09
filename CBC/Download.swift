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

/**
 Handles downloading of everything from audio/video to documents.
 */
extension Download : URLSessionDownloadDelegate
{
    // MARK: URLSessionDownloadDelegate
    
    func downloadFailed(error:Error? = nil)
    {
        print("DOWNLOAD ERROR:",error?.localizedDescription ?? "",(task?.response as? HTTPURLResponse)?.statusCode ?? 0,totalBytesExpectedToWrite)
        
        guard state != .none else {
            print("previously dealt with")
            return
        }
        
        Thread.onMain {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        let title = "Download Failed (\(downloadPurpose))"
        
        if let taskDescription = task?.taskDescription, let index = taskDescription.range(of: ".") {
            let id = String(taskDescription[..<index.lowerBound])
            
            if let mediaItem = Globals.shared.media.repository.index[id] {
                Alerts.shared.alert(title: title, message: mediaItem.title)
            }
        } else {
            Alerts.shared.alert(title: title)
        }
        
        cancel()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        debug("urlSession:didWriteData")
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            totalBytesExpectedToWrite != -1 else {
            downloadFailed()
            return
        }
        
        Thread.onMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if let purpose = purpose {
            switch purpose {
            case Purpose.audio:
                if bytesWritten > 0 {
                    Thread.onMain {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    }
                }
                break
                
            case Purpose.outline:
                fallthrough
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                if bytesWritten > 0 {
                    Thread.onMain {
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

        if let statusCode = (task?.response as? HTTPURLResponse)?.statusCode, statusCode >= 400 {
            downloadFailed()
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
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: fileSystemURL)
                
                location.delete(block:true)
                
                state = .downloaded
            } else {
                // Nothing was downloaded
                Thread.onMain {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self)
                }
                
                state = .none
            }
        } catch let error {
            print("failed to copy temp download file: \(error.localizedDescription)")
            state = .none
        }
        
        Thread.onMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        debug("urlSession:didCompleteWithError")
        
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            error == nil else {
            return
        }

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
        
        if error != nil {
            downloadFailed(error:error)
        }
        
        session.invalidateAndCancel()
        
        Thread.onMain {
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
        
        if let range = identifier.range(of: ":") {
            let filename = String(identifier[range.upperBound...])
            
            if task?.taskDescription == filename {
                Thread.onMain {
                    self.completionHandler?()
                }
            }
        }
    }
}

class Download : NSObject, Size
{
    init(mediaItem:MediaItem?,purpose:String?,downloadURL:URL?) // ,fileSystemURL:URL?
    {
        super.init()
        
        self.mediaItem = mediaItem
        self.purpose = purpose
        self.downloadURL = downloadURL
        
        if let fileSystemURL = fileSystemURL {
            if FileManager.default.fileExists(atPath: fileSystemURL.path) {
                self.state = .downloaded
            }
        }
    }
    
    deinit {
        debug(self)
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
    
    var id:String?
    
    var downloadURL:URL?
    
    var fileSystemURL:URL?
    {
        get {
            return downloadURL?.fileSystemURL
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

    var state:State = .none {
        willSet {
            
        }
        didSet {
            guard state != oldValue else {
                return
            }
            
            switch state {
            case .downloading:
                Thread.onMain {
                    // The following must appear AFTER we change the state
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADING), object: self)
                }
                break
                
            case .downloaded:
                fileSize = fileSystemURL?.fileSize
                
                Thread.onMain {
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
            case Purpose.video:
                break
                
            case Purpose.audio:
                switch state {
                case .downloading:
                    self.mediaItem?.removeTag(Constants.Strings.Downloaded)
                    self.mediaItem?.addTag(Constants.Strings.Downloading)
                    break
                    
                case .downloaded:
                    self.mediaItem?.removeTag(Constants.Strings.Downloading)
                    self.mediaItem?.addTag(Constants.Strings.Downloaded)
                    break
                    
                case .none:
                    self.mediaItem?.removeTag(Constants.Strings.Downloading)
                    self.mediaItem?.removeTag(Constants.Strings.Downloaded)
                    break
                }
                
                Thread.onMain {
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
                    Thread.onMain {
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
    
    func download(background:Bool)
    {
        guard (state == .none) else {
            return
        }
        
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
        
        state = .downloading

        let downloadRequest = URLRequest(url: downloadURL)

        var configuration : URLSessionConfiguration?
        
        id = Constants.DOWNLOAD_IDENTIFIER + Date().timeIntervalSinceReferenceDate.description + ":"

        if background, let id = id, let lastPathComponent = fileSystemURL?.lastPathComponent {
//            configuration = .background(withIdentifier: Constants.IDENTIFIER.DOWNLOAD + lastPathComponent)
            
            configuration = .background(withIdentifier: id + lastPathComponent)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            configuration?.sessionSendsLaunchEvents = true
        } else {
            configuration = .default
        }
        
        if let configuration = configuration {
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

            session?.sessionDescription = self.fileSystemURL?.lastPathComponent
            
            session?.reset() {
                if let task = self.session?.downloadTask(with: downloadRequest) {
                    self.task = task
                    
                    task.taskDescription = self.fileSystemURL?.lastPathComponent
                    task.resume()
                    
                    Thread.onMain {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                }
            }
        }
    }
    
    // Slow when replaced w/ struct or class
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard state == .downloaded else {
                return nil
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
    
    func delete(block:Bool)
    {
        guard state == .downloaded else {
            return
        }
        
        fileSize = nil
        fileSystemURL?.delete(block:block)
        
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

