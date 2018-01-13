//
//  MediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit


class SearchHit {
    var mediaItem:MediaItem?
    
    //        init()
    //        {
    //            self.mediaItem = mediaItem
    //        }
    
    var searchText:String?
    
    init(_ mediaItem:MediaItem?,_ searchText:String?)
    {
        self.mediaItem = mediaItem
        self.searchText = searchText
    }
    
    deinit {
        
    }
    
    var title:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasTitle, let searchText = searchText else {
                return false
            }
            return mediaItem.title?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var formattedDate:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.formattedDate?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var speaker:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasSpeaker, let searchText = searchText else {
                return false
            }
            return mediaItem.speaker?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var scriptureReference:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.scriptureReference?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var className:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasClassName, let searchText = searchText else {
                return false
            }
            return mediaItem.className?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var eventName:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasEventName, let searchText = searchText else {
                return false
            }
            return mediaItem.eventName?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var tags:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.tags?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var transcriptHTML:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            
//            guard globals.search.transcripts else {
//                return false
//            }
            
            return mediaItem.notesHTML?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
}

extension MediaItem : URLSessionDownloadDelegate
{
    // MARK: URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        var downloadFound:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                downloadFound = downloads[key]
                break
            }
        }
        
        guard let download = downloadFound else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,totalBytesExpectedToWrite)
                
            let title = "Download Failed (\(download.downloadPurpose))"
                
            if download.state != .none {
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let index = downloadTask.taskDescription?.range(of: "."),
                    let id = downloadTask.taskDescription?.substring(to: index.lowerBound),
                    let mediaItem = globals.mediaRepository.index?[id] {
                    globals.alert(title: title, message: mediaItem.title)
                } else {
                    globals.alert(title: title, message: nil)
                }
            } else {
                print("previously dealt with")
            }
            
            download.cancel()
            return
        }
        
        if let purpose = download.purpose {
            Thread.onMainThread() {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }

            //            print(totalBytesWritten,totalBytesExpectedToWrite,Float(totalBytesWritten) / Float(totalBytesExpectedToWrite),Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100))
            
            let progress = totalBytesExpectedToWrite > 0 ? Int((Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100) % 100 : 0
            
            let current = download.totalBytesExpectedToWrite > 0 ? Int((Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite)) * 100) % 100 : 0
            
            //            print(progress,current)
            
            switch purpose {
            case Purpose.audio:
                if progress > current {
                    //                    print(Constants.NOTIFICATION.MEDIA_UPDATE_CELL)
                    //                    globals.queue.async(execute: { () -> Void in
                    Thread.onMainThread() {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: download.mediaItem)
                    }
                }
                break
                
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                if progress > current {
                    Thread.onMainThread() {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: download)
                    }
                }
                break
                
            default:
                break
            }
            
            debug("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            debug("session: \(String(describing: session.sessionDescription))")
            debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
            
            if let fileSystemURL = download.fileSystemURL {
                debug("path: \(fileSystemURL.path)")
                debug("filename: \(fileSystemURL.lastPathComponent)")
                
                if (downloadTask.taskDescription != fileSystemURL.lastPathComponent) {
                    debug("downloadTask.taskDescription != download.fileSystemURL.lastPathComponent")
                }
            } else {
                debug("No fileSystemURL")
            }
            
            debug("bytes written: \(totalBytesWritten)")
            debug("bytes expected to write: \(totalBytesExpectedToWrite)")
            
            if (download.state == .downloading) {
                download.totalBytesWritten = totalBytesWritten
                download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                print("ERROR NOT DOWNLOADING")
            }
        } else {
            print("ERROR NO DOWNLOAD")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        var downloadFound:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                downloadFound = downloads[key]
                break
            }
        }
        
        guard let download = downloadFound else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR",(downloadTask.response as? HTTPURLResponse)?.statusCode as Any,download.totalBytesExpectedToWrite as Any)
            
            let title = "Download Failed (\(download.downloadPurpose))"

            if download.state != .none {
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let index = downloadTask.taskDescription?.range(of: "."),
                    let id = downloadTask.taskDescription?.substring(to: index.lowerBound),
                    let mediaItem = globals.mediaRepository.index?[id] {
                    globals.alert(title: title, message: mediaItem.title)
                } else {
                    globals.alert(title: title, message: nil)
                }
            } else {
                print("previously dealth with")
            }
            
            download.cancel()
            return
        }
        
        guard let fileSystemURL = download.fileSystemURL else {
            print("NO FILE SYSTEM URL!")
            return
        }
        
        debug("URLSession:downloadTask:didFinishDownloadingToURL:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
        
        if let purpose = download.purpose {
            debug("purpose: \(purpose)")
        }
        
        debug("path: \(fileSystemURL.path)")
        debug("filename: \(fileSystemURL.lastPathComponent)")
        
        if (downloadTask.taskDescription != fileSystemURL.lastPathComponent) {
            debug("downloadTask.taskDescription != download.fileSystemURL.lastPathComponent")
        }
        
        debug("bytes written: \(download.totalBytesWritten)")
        debug("bytes expected to write: \(download.totalBytesExpectedToWrite)")
        
        let fileManager = FileManager.default
        
        // Check if file exists
        //            print("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
        
        do {
            if (download.state == .downloading) { //  && (download!.totalBytesExpectedToWrite != -1)
                if (fileManager.fileExists(atPath: fileSystemURL.path)){
                    do {
                        try fileManager.removeItem(at: fileSystemURL)
                    } catch let error as NSError {
                        print("failed to remove duplicate download: \(error.localizedDescription)")
                    }
                }
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: fileSystemURL)
                try fileManager.removeItem(at: location)
                
                download.state = .downloaded
            } else {
                // Nothing was downloaded
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                }
                
                download.state = .none
            }
        } catch let error as NSError {
            print("failed to copy temp download file: \(error.localizedDescription)")
            download.state = .none
        }
        
        Thread.onMainThread() {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        var downloadFound:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                downloadFound = downloads[key]
                break
            }
        }

        guard let download = downloadFound else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400,
            error == nil else {
            print("DOWNLOAD ERROR:",task.taskDescription as Any,(task.response as? HTTPURLResponse)?.statusCode as Any,download.totalBytesExpectedToWrite as Any)
            
            if let error = error {
                print("with error: \(error.localizedDescription)")
            }
                
            let title = "Download Failed (\(download.downloadPurpose))"

            if download.state != .none {
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let index = task.taskDescription?.range(of: "."),
                    let id = task.taskDescription?.substring(to: index.lowerBound),
                    let message = globals.mediaRepository.index?[id]?.title {
                    if let error = error {
                        globals.alert(title: title, message: message + "\nError: \(error.localizedDescription)")
                    } else {
                        globals.alert(title: title, message: message)
                    }
                } else {
                    if let error = error {
                        globals.alert(title: title, message: "Error: \(error.localizedDescription)")
                    } else {
                        globals.alert(title: title, message: nil)
                    }
                }
            } else {
                print("previously dealt with")
            }
            
            download.cancel()
                
            return
        }
        
        debug("URLSession:task:didCompleteWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("task: \(String(describing: task.taskDescription))")
        
        if let purpose = download.purpose {
            debug("purpose: \(purpose)")
        }
        
        if let fileSystemURL = download.fileSystemURL {
            debug("path: \(fileSystemURL.path)")
            debug("filename: \(fileSystemURL.lastPathComponent)")
            
            if (task.taskDescription != fileSystemURL.lastPathComponent) {
                debug("task.taskDescription != download!.fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download.totalBytesWritten)")
        debug("bytes expected to write: \(download.totalBytesExpectedToWrite)")
        
        if let error = error, let purpose = download.purpose {
            print("with error: \(error.localizedDescription)")
            //            download?.state = .none
            
            switch purpose {
            case Purpose.slides:
                fallthrough
            case Purpose.notes:
                Thread.onMainThread() {
                    //                    print(download?.mediaItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: download)
                }
                break
                
            default:
                break
            }
        }
        
        //        print("Download error: \(error)")
        //
        //        if (download?.totalBytesExpectedToWrite == 0) {
        //            download?.state = .none
        //        } else {
        //            print("Download succeeded for: \(session.description)")
        ////            download?.state = .downloaded // <- This caused a very spurious error.  Let this state chagne happen in didFinishDownloadingToURL!
        //        }
        
        // This may delete temp files other than the one we just downloaded, so don't do it.
        //        removeTempFiles()
        
        session.invalidateAndCancel()
        
        Thread.onMainThread() {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        var downloadFound:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                downloadFound = downloads[key]
                break
            }
        }
        
        guard let download = downloadFound else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        debug("URLSession:didBecomeInvalidWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        
        if let purpose = download.purpose {
            debug("purpose: \(purpose)")
        }
        
        if let fileSystemURL = download.fileSystemURL {
            debug("path: \(fileSystemURL.path)")
            debug("filename: \(fileSystemURL.lastPathComponent)")
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download.totalBytesWritten)")
        debug("bytes expected to write: \(download.totalBytesExpectedToWrite)")
        
        if let error = error {
            print("with error: \(error.localizedDescription)")
        }
        
        download.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        guard let filename = session.configuration.identifier?.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex) else {
            return
        }
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                print("\(filename) \(key)")
            return value.task?.taskDescription == filename
        }).first?.1 {
            download.completionHandler?()
        }
    }
}

extension MediaItem : UIActivityItemSource
{
    func share(viewController:UIViewController)
    {
        guard let series = setupMediaItemsHTML(self.multiPartMediaItems) else {
            return
        }
        
        let print = UIMarkupTextPrintFormatter(markupText: series)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = UIActivityViewController(activityItems:[self,print] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.

        activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem

        // present the view controller
        Thread.onMainThread() {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any?
    {
        guard let text = self.text else {
            return nil
        }
        
        guard let series = setupMediaItemsHTML(self.multiPartMediaItems) else {
            return nil
        }
        
        if activityType == UIActivityType.mail {
            return series
        } else if activityType == UIActivityType.print {
            return series
        }

        var string : String!
        
        if let path = self.websiteURL?.absoluteString {
            string = text + "\n\n" + path
        } else {
            string = text
        }

        return string
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        return self.text ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String
    {
        if activityType == UIActivityType.mail {
            return "public.text"
        } else if activityType == UIActivityType.print {
            return "public.text"
        }
        
        return "public.plain-text"
    }
}

class MediaItem : NSObject
{
    static func ==(lhs: MediaItem, rhs: MediaItem) -> Bool
    {
        return lhs.id == rhs.id
    }
    
    var dict:[String:String]?
    
    var booksChaptersVerses:BooksChaptersVerses?
    
    var notesTokens:[String:Int]? //[(String,Int)]?
    
    var singleLoaded = false

    func freeMemory()
    {
        // What are the side effects of this?
        
        notesHTML = nil
        notesTokens = nil
        
        booksChaptersVerses = nil
    }
    
    init(dict:[String:String]?)
    {
        super.init()
        
//        print("\(dict)")

        self.dict = dict
        
//        self.searchHit = SearchHit(mediaItem: self)
        
        Thread.onMainThread() {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaItem.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    deinit {
        
    }
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasAudio else {
            return nil
        }
        let download = Download(mediaItem:self,purpose:Purpose.audio,downloadURL:self.audioURL,fileSystemURL:self.audioFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        var download = Download()
//        download.mediaItem = self
//        download.purpose = Purpose.audio
//        download.downloadURL = self.audioURL
//        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Purpose.audio] = download
        return download
    }()
    
    lazy var videoDownload:Download? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasVideo else {
            return nil
        }
        let download = Download(mediaItem:self,purpose:Purpose.video,downloadURL:self.videoURL,fileSystemURL:self.videoFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        var download = Download()
//        download.mediaItem = self
//        download.purpose = Purpose.video
//        download.downloadURL = self.videoURL
//        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Purpose.video] = download
        return download
    }()
    
    lazy var slidesDownload:Download? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasSlides else {
            return nil
        }
        let download = Download(mediaItem:self,purpose:Purpose.slides,downloadURL:self.slidesURL,fileSystemURL:self.slidesFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        var download = Download()
//        download.mediaItem = self
//        download.purpose = Purpose.slides
//        download.downloadURL = self.slidesURL
//        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Purpose.slides] = download
        return download
    }()
    
    lazy var notesDownload:Download? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasNotes else {
            return nil
        }
        let download = Download(mediaItem:self,purpose:Purpose.notes,downloadURL:self.notesURL,fileSystemURL:self.notesFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        var download = Download()
//        download.mediaItem = self
//        download.purpose = Purpose.notes
//        download.downloadURL = self.notesURL
//        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Purpose.notes] = download
        return download
    }()
    
    lazy var outlineDownload:Download? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasOutline else {
            return nil
        }
        let download = Download(mediaItem:self,purpose:Purpose.outline,downloadURL:self.outlineURL,fileSystemURL:self.outlineFileSystemURL)
        // NEVER EVER DO THIS.  Causes LOTS of bad behavior since didSets will NOT happen in an init but they WILL happen below.
//        var download = Download()
//        download.mediaItem = self
//        download.purpose = Purpose.outline
//        download.downloadURL = self.outlineURL
//        download.fileSystemURL = self.outlineFileSystemURL
        self.downloads[Purpose.outline] = download
        return download
    }()
    
    var id:String! {
        get {
            // Potential crash if nil
            return dict?[Field.id]
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in id {
                if Int(String(char)) != nil {
                    break
                }
                chars.append(char)
            }
            
            return chars
        }
    }
    
    var serviceCode:String {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            let afterDate = afterClassCode.substring(from: ymd.endIndex)
            
            let code = afterDate.substring(to: String.Index(encodedOffset: 1)) // "x".endIndex
            
            //        print(code)
            
            return code
        }
    }
    
    var conferenceCode:String? {
        get {
            if serviceCode == "s" {
                let afterClassCode = id.substring(from: classCode.endIndex)
                
                var string = id.substring(to: classCode.endIndex)
                
                let ymd = "YYMMDD"
                
                string = string + afterClassCode.substring(to: ymd.endIndex)
                
                let s = "s"
                
                let code = string + s
                
                //            print(code)
                
                return code
            }
            
            return nil
        }
    }
    
    var repeatCode:String? {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            var string = id.substring(to: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            string = string + afterClassCode.substring(to: ymd.endIndex) + serviceCode
            
            let code = id.substring(from: string.endIndex)
            
            if code != Constants.EMPTY_STRING  {
                //            print(code)
                return code
            } else {
                return nil
            }
        }
    }
    
    var multiPartMediaItems:[MediaItem]? {
        get {
            if (hasMultipleParts) {
                var mediaItemParts:[MediaItem]?
//                print(multiPartSort)
                if let multiPartSort = multiPartSort, (globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
                    mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                        if testMediaItem.hasMultipleParts {
                            return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                        } else {
                            return false
                        }
                    })
                } else {
                    if let multiPartSort = multiPartSort {
                        mediaItemParts = globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                            return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                        })
                    }
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
//                print(mediaItemParts)
                
                // Filter for conference series
                
                if conferenceCode != nil {
                    mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.conferenceCode == conferenceCode
                    }),sorting: SORTING.CHRONOLOGICAL)
                } else {
                    if hasClassName {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                            //                        print(classCode,testMediaItem.classCode)
                            return testMediaItem.classCode == classCode
                        }),sorting: SORTING.CHRONOLOGICAL)
                    } else {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts,sorting: SORTING.CHRONOLOGICAL)
                    }
                }
                
                // Filter for multiple series of the same name
                var mediaList = [MediaItem]()
                
                if mediaItemParts?.count > 1 {
                    var number = 0
                    
                    if let mediaItemParts = mediaItemParts {
                        for mediaItem in mediaItemParts {
                            if let part = mediaItem.part, let partNumber = Int(part) {
                                if partNumber > number {
                                    mediaList.append(mediaItem)
                                    number = partNumber
                                } else {
                                    if (mediaList.count > 0) && mediaList.contains(self) {
                                        break
                                    } else {
                                        mediaList = [mediaItem]
                                        number = partNumber
                                    }
                                }
                            }
                        }
                    }
                    
                    return mediaList.count > 0 ? mediaList : nil
                } else {
                    return mediaItemParts
                }
            } else {
                return [self]
            }
        }
    }
    
    func searchStrings() -> [String]?
    {
        var array = [String]()
        
        if let speaker = speaker {
            array.append(speaker)
        }
        
        if hasMultipleParts {
            if let multiPartName = multiPartName {
                array.append(multiPartName)
            }
        } else {
            if let title = title {
                array.append(title)
            }
        }
        
        if let books = books {
            array.append(contentsOf: books)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if let tagsArray = tagsArray {
            for tag in tagsArray {
                if let tokens = tokensFromString(tag) {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = firstNameFromName(speaker) {
                set.insert(firstname)
            }

            if let lastname = lastNameFromName(speaker) {
                set.insert(lastname)
            }
        }
        
        if let books = books {
            set = set.union(Set(books))
        }
        
        if let titleTokens = tokensFromString(title) {
            set = set.union(Set(titleTokens))
        }
        
        return set.count > 0 ? Array(set).map({ (string:String) -> String in
                return string.uppercased()
            }).sorted() : nil
    }
    
    func searchHit(_ searchText:String?) -> SearchHit
    {
        return SearchHit(self,searchText)
    }
    
    func search(_ searchText:String?) -> Bool
    {
        let searchHit = SearchHit(self,searchText)
        
        return searchHit.title || searchHit.formattedDate || searchHit.speaker || searchHit.scriptureReference || searchHit.className || searchHit.eventName || searchHit.tags
    }
        
    func searchFullNotesHTML(_ searchText:String?) -> Bool
    {
        if hasNotesHTML {
            loadNotesHTML()
            
            return SearchHit(self,searchText).transcriptHTML
        } else {
            return false
        }
    }

    func mediaItemsInCollection(_ tag:String) -> [MediaItem]?
    {
        guard let tagsSet = tagsSet else {
            return nil
        }
        
        guard tagsSet.contains(tag) else {
            return nil
        }
        
        return globals.media.all?.tagMediaItems?[tag]
    }

    var playingURL:URL? {
        get {
            var url:URL?

            guard let playing = playing else {
                return nil
            }

            switch playing {
            case Playing.audio:
                url = audioURL
                if let path = audioFileSystemURL?.path, FileManager.default.fileExists(atPath: path) {
                    url = audioFileSystemURL
                }
                break
                
            case Playing.video:
                url = videoURL
                if let path = videoFileSystemURL?.path, FileManager.default.fileExists(atPath: path){
                    url = videoFileSystemURL
                }
                break
                
            default:
                break
            }
            
            return url
        }
    }
    
    var isInMediaPlayer:Bool {
        get {
            return (self == globals.mediaPlayer.mediaItem)
        }
    }
    
    var isLoaded:Bool {
        get {
            return isInMediaPlayer && globals.mediaPlayer.loaded
        }
    }
    
    var isPlaying:Bool {
        get {
            return globals.mediaPlayer.url == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String? {
        get {
            if (dict?[Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict?[Field.playing] = playing
                } else {
                    // Avoid simultaneous read and write in dict.
                    let playing = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                    dict?[Field.playing] = playing
                }
            }
            
            if !hasAudio && (dict?[Field.playing] == Playing.audio) {
                // Avoid simultaneous read and write in dict.
                let playing = hasVideo ? Playing.video : nil
                dict?[Field.playing] = playing
            }

            if !hasVideo && (dict?[Field.playing] == Playing.video) {
                // Avoid simultaneous read and write in dict.
                let playing = hasAudio ? Playing.audio : nil
                dict?[Field.playing] = playing
            }
            
            return dict?[Field.playing]
        }
        
        set {
            if newValue != dict?[Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict?[Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var wasShowing:String? 
    {
        didSet {
            print("")
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict?[Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict?[Field.showing] = showing
                } else {
                    if (hasSlides && hasNotes) {
                        dict?[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes) {
                        dict?[Field.showing] = Showing.notes
                    }
                    if (hasSlides && !hasNotes) {
                        dict?[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes) {
                        dict?[Field.showing] = Showing.none
                    }
                }
            }
            
            // Backwards compatible fix
            if dict?[Field.showing] == "none" {
                dict?[Field.showing] = "NONE"
            }
            
            return dict?[Field.showing]
        }
        
        set {
            guard newValue != nil else {
                dict?[Field.showing] = Showing.none
                mediaItemSettings?[Field.showing] = Showing.none
                return
            }
            
            if (newValue != Showing.video) {
                wasShowing = newValue
            } else {
                if wasShowing == nil {
                    if hasSlides {
                        wasShowing = Showing.slides
                    } else
                    if hasNotes {
                        wasShowing = Showing.notes
                    } else {
                        wasShowing = Showing.none
                    }
                }
            }
            
            dict?[Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var download:Download? {
        get {
            guard let showing = showing else {
                return nil
            }
            
            return downloads[showing]
        }
    }
    
    var atEnd:Bool {
        get {
            guard let playing = playing else {
                return false
            }
            
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing] {
                dict?[Constants.SETTINGS.AT_END+playing] = atEnd
            } else {
                dict?[Constants.SETTINGS.AT_END+playing] = "NO"
            }
            return dict?[Constants.SETTINGS.AT_END+playing] == "YES"
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            dict?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
        }
    }
    
    var webLink : String? {
        get {
            if let body = bodyHTML(order: ["title","scripture","speaker"], token: nil, includeURLs: false, includeColumns: false), let urlString = websiteURL?.absoluteString {
                return body + "\n\n" + urlString
            } else {
                return nil
            }
        }
    }
    
    var websiteURL:URL? {
        get {
            return URL(string: Constants.CBC.SINGLE_WEBSITE + id)
        }
    }
    
    var downloadURL:URL? {
        get {
            return download?.downloadURL
        }
    }
    
    var fileSystemURL:URL? {
        get {
            return download?.fileSystemURL
        }
    }
    
    var hasCurrentTime : Bool
    {
        get {
            guard let currentTime = currentTime else {
                return false // arbitrary
            }
            
            return (Float(currentTime) != nil)
        }
    }
    
    var currentTime:String? {
        get {
            guard let playing = playing else {
                return nil
            }
            
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] {
                dict?[Constants.SETTINGS.CURRENT_TIME+playing] = current_time
            } else {
                dict?[Constants.SETTINGS.CURRENT_TIME+playing] = "\(0)"
            }

            return dict?[Constants.SETTINGS.CURRENT_TIME+playing]
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            dict?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            
            mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts, let multiPartName = multiPartName {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName
            } else {
                // Potential crash if nil
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if let range = date?.range(of: "-"), let year = date?.substring(to: range.lowerBound) {
                return Int(year)
            } else {
                return nil
            }
        }
    }
    
    var yearSection:String?
    {
        get {
            return yearString
        }
    }
    
    var yearString:String! {
        get {
            if let range = date?.range(of: "-"), let year = date?.substring(to: range.lowerBound) {
                return year
            } else {
                return Constants.Strings.None
            }
        }
    }

    func singleJSONFromURL() -> [[String:String]]?
    {
        guard globals.reachability.isReachable else {
            return nil
        }
        
        guard let id = id else {
            return nil
        }
        
        guard let url = URL(string: Constants.JSON.URL.SINGLE + id) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return (json as? [String:Any])?["singleEntry"] as? [[String:String]]
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
    func loadNotesHTML()
    {
        guard !globals.isRefreshing else {
            return
        }

        guard hasNotesHTML else {
            return
        }
        
        guard (dict?[Field.notes_HTML] == nil) else {
            return
        }
        
        if let mediaItemDict = self.singleJSONFromURL()?[0] {
            if var notesHTML = mediaItemDict[Field.notes_HTML] {
                notesHTML = notesHTML.replacingOccurrences(of: "&rsquo;", with: "'")
                notesHTML = notesHTML.replacingOccurrences(of: "&rdquo;", with: "\"")
                notesHTML = notesHTML.replacingOccurrences(of: "&lsquo;", with: "'")
                notesHTML = notesHTML.replacingOccurrences(of: "&ldquo;", with: "\"")
                
                dict?[Field.notes_HTML] = notesHTML
            }
        } else {
            print("loadSingle failure")
        }
    }
    
    func loadNotesTokens()
    {
        guard hasNotesHTML else {
            return
        }
        
        guard (notesTokens == nil) else {
            return
        }
        
        loadNotesHTML()

        notesTokens = tokensAndCountsFromString(stripHTML(notesHTML)) // notesHTML?.html2String // not sure one is much faster than the other, but html2String is Apple's conversion, the other mine.
    }
    
    // VERY Computationally Expensive
    func formatDate(_ format:String?) -> String?
    {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(for: fullDate)
    }
    
    var formattedDate:String? {
        get {
            // VERY Computationally Expensive
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String? {
        get {
            // VERY Computationally Expensive
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String? {
        get {
            // VERY Computationally Expensive
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String? {
        get {
            // VERY Computationally Expensive
            return formatDate("yyyy")
        }
    }
    
    var dateService:String? {
        get {
            return dict?[Field.date]
        }
    }
    
    var date:String? {
        get {
            if let date = dict?[Field.date], let range = date.range(of: Constants.SINGLE_SPACE) {
                return date.substring(to: range.lowerBound) // last two characters // dict?[Field.title]
            } else {
                return nil
            }
        }
    }
    
    var service:String? {
        get {
            if let date = dict?[Field.date], let range = date.range(of: Constants.SINGLE_SPACE) {
                return date.substring(from: range.upperBound) // last two characters // dict?[Field.title]
            } else {
                return nil
            }
        }
    }
    
    var title:String? {
        get {
            guard let title = dict?[Field.title], !title.isEmpty else {
                return Constants.Strings.None
            }
            
            return title
        }
    }
    
    var category:String? {
        get {
            return dict?[Field.category]
        }
    }
    
    var scriptureReference:String? {
        get {
            guard let scriptureReference = dict?[Field.scripture]?.replacingOccurrences(of: "Psalm ", with: "Psalms "), !scriptureReference.isEmpty else {
                return Constants.Strings.Selected_Scriptures
            }
            
            return scriptureReference
        }
    }
    
    lazy var scripture:Scripture? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return Scripture(reference:self.scriptureReference)
    }()
    
    var classSectionSort:String! {
        get {
            return classSection.lowercased()
        }
    }
    
    var classSection:String! {
        get {
            guard let className = className, !className.isEmpty else {
                return Constants.Strings.None
            }
            
            return className
        }
    }
    
    var className:String? {
        get {
            guard let className = dict?[Field.className], !className.isEmpty else {
                return Constants.Strings.None
            }
            
            return className
        }
    }
    
    var eventSectionSort:String! {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String! {
        get {
            guard let eventName = eventName, !eventName.isEmpty else {
                return Constants.Strings.None
            }
            
            return eventName
        }
    }
    
    var eventName:String? {
        get {
            guard let eventName = dict?[Field.eventName], !eventName.isEmpty else {
                return Constants.Strings.None
            }
            
            return eventName
        }
    }
    
    var speakerSectionSort:String! {
        get {
            guard hasSpeaker, let speakerSort = speakerSort else {
                return "ERROR"
            }
            
            return speakerSort.lowercased()
        }
    }
    
    var speakerSection:String! {
        get {
            guard let speaker = speaker, !speaker.isEmpty else {
                return Constants.Strings.None
            }

            return speaker
        }
    }
    
    var speaker:String? {
        get {
            guard let speaker = dict?[Field.speaker], !speaker.isEmpty else {
                return Constants.Strings.None
            }

            return speaker
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict?[Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict?[Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if hasSpeaker, let speaker = speaker {
                        if !speaker.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = ((speakerSort != nil) ? speakerSort! + "," : "") + firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
//                    print(speaker)
//                    print(speakerSort)
                    
                    dict?[Field.speaker_sort] = speakerSort ?? Constants.Strings.None
                }
            }

            return dict?[Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            if hasMultipleParts {
                if let sort = multiPartSort?.lowercased() {
                    return sort
                } else {
                    return "ERROR"
                }
            } else {
                if let sort = stringWithoutPrefixes(title)?.lowercased() {
                    return sort
                } else {
                    return "ERROR"
                }
            }
        }
    }
    
    var multiPartSection:String! {
        get {
            return multiPartName ?? (title ?? Constants.Strings.None)
        }
    }
    
    var multiPartSort:String? {
        get {
            if dict?[Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict?[Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict?[Field.multi_part_name_sort] = multiPartSort
                    } else {
//                        print("multiPartSort is nil")
                    }
                }
            }
            return dict?[Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        get {
            if (dict?[Field.multi_part_name] == nil) {
                if let range = title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    if let seriesString = title?.substring(to: range.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                        dict?[Field.multi_part_name] = seriesString
                    }
                }
            }
            
            return dict?[Field.multi_part_name]
        }
    }
    
    var part:String? {
        get {
            if hasMultipleParts && (dict?[Field.part] == nil) {
                if let range = title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    if let partString = title?.substring(from: range.upperBound) {
                        //                    print(partString)
                        if let range = partString.range(of: ")") {
                            dict?[Field.part] = partString.substring(to: range.lowerBound)
                        }
                    }
                }
            }
            
//            print(dict?[Field.part])
            return dict?[Field.part]
        }
    }
    
    func proposedTags(_ tags:String?) -> String?
    {
        var possibleTags = [String:Int]()
        
        if let tags = tagsArrayFromTagsString(tags) {
            for tag in tags {
                var possibleTag = tag
                
                if possibleTag.range(of: "-") != nil {
                    while possibleTag.range(of: "-") != nil {
                        if let range = possibleTag.range(of: "-") {
                            let candidate = possibleTag.substring(to: range.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }
                            
                            possibleTag = possibleTag.substring(from: range.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        } else {
                            // ???
                        }
                    }
                    
                    if !possibleTag.isEmpty {
                        let candidate = possibleTag.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if (Int(candidate) == nil) && !tags.contains(candidate) {
                            if let count = possibleTags[candidate] {
                                possibleTags[candidate] =  count + 1
                            } else {
                                possibleTags[candidate] =  1
                            }
                        }
                    }
                }
            }
        }
        
        let proposedTags = [String](possibleTags.keys)
        
//            .map { (string:String) -> String in
//            return string
//        }
        
        return proposedTags.count > 0 ? tagsArrayToTagsString(proposedTags) : nil
    }
    
    var dynamicTags:String? {
        get {
            var dynamicTags:String?
            
            // These are expected to be mutually exclusive.
            
            if hasClassName {
                dynamicTags = (dynamicTags != nil ? dynamicTags! + "|" : "") + className!
            }
            
            if hasEventName {
                dynamicTags = (dynamicTags != nil ? dynamicTags! + "|" : "") + eventName!
            }
            
            return dynamicTags
        }
    }
    
    var constantTags:String? {
        get {
            var constantTags:String?
            
            if hasSlides {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Slides
            }
            
            if hasNotes {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Transcript
            }
            
            if hasNotesHTML {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Lexicon
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + "HTML Transcript"
            }

            if hasVideo {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Video
            }
            
            // Invoke separately so both lazy variables are instantiated.
            if audioTranscript?.transcript != nil {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + "Machine Generated Transcript"
            }
            
            if videoTranscript?.transcript != nil {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + "Machine Generated Transcript"
            }
            
            return constantTags
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            let jsonTags = dict?[Field.tags]
            
            let savedTags = mediaItemSettings?[Field.tags]
            
            var tags:String?

            tags = tags != nil ? tags! + (jsonTags != nil ? "|" + jsonTags! : "") : jsonTags
            
            tags = tags != nil ? tags! + (savedTags != nil ? "|" + savedTags! : "") : savedTags
            
            if let dynamicTags = self.dynamicTags {
                tags = tags != nil ? (tags! + "|" + dynamicTags) : dynamicTags
            }

            if let constantTags = self.constantTags {
                tags = tags != nil ? (tags! + "|" + constantTags) : constantTags
            }
            
            // What does proposedTags() do?
            // It looks for tags with hyphens - why?
            if let proposedTags = proposedTags(jsonTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(savedTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(dynamicTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(constantTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            // This coalesces the tags so there are no duplicates
            if let tagsArray = tagsArrayFromTagsString(tags), let tagsString = tagsSetToString(Set(tagsArray)) {
//                print(tagsString)
                return tagsString // tags
            } else {
                return nil
            }
        }
    }
    
    func addTag(_ tag:String)
    {
        guard mediaItemSettings != nil else {
            return
        }
        
        guard globals.media.all != nil else {
            return
        }
        
        let tags = tagsArrayFromTagsString(mediaItemSettings?[Field.tags])
        
//        print(tags as Any)
        
        guard tags?.index(of: tag) == nil else {
            return
        }
        
        if (mediaItemSettings?[Field.tags] == nil) {
            mediaItemSettings?[Field.tags] = tag
        } else {
            if let tags = mediaItemSettings?[Field.tags] {
                mediaItemSettings?[Field.tags] = tags + Constants.TAGS_SEPARATOR + tag
            }
        }
        
        if let sortTag = stringWithoutPrefixes(tag) {
            if globals.media.all?.tagMediaItems?[sortTag] != nil {
                if globals.media.all?.tagMediaItems?[sortTag]?.index(of: self) == nil {
                    globals.media.all?.tagMediaItems?[sortTag]?.append(self)
                    globals.media.all?.tagNames?[sortTag] = tag
                }
            } else {
                globals.media.all?.tagMediaItems?[sortTag] = [self]
                globals.media.all?.tagNames?[sortTag] = tag
            }
            
            globals.media.tagged[tag] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag])
        }

        if (globals.media.tags.selected == tag) {
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
            }
        }
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
        }
    }
    
    func removeTag(_ tag:String)
    {
        guard mediaItemSettings?[Field.tags] != nil else {
            return
        }
        
        guard globals.media.all != nil else {
            return
        }
        
        var tags = tagsArrayFromTagsString(mediaItemSettings?[Field.tags])
        
//            print(tags)
        
        while tags?.index(of: tag) != nil {
            if let index = tags?.index(of: tag) {
                tags?.remove(at: index)
            }
        }
        
//            print(tags)
        
        mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
        
        if let sortTag = stringWithoutPrefixes(tag) {
            if let index = globals.media.all?.tagMediaItems?[sortTag]?.index(of: self) {
                globals.media.all?.tagMediaItems?[sortTag]?.remove(at: index)
            }
            
            if globals.media.all?.tagMediaItems?[sortTag]?.count == 0 {
                _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag)
            }
            
            globals.media.tagged[tag] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag])
        }
        
        if (globals.media.tags.selected == tag) {
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
            }
        }
        
        Thread.onMainThread() {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        guard let tagsSet = tagsSet else {
            return nil
        }
        
        let array = Array(tagsSet).sorted { (first:String, second:String) -> Bool in
            return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
        }
        
        guard array.count > 0 else {
            return nil
        }
        
        return array.joined(separator: Constants.TAGS_SEPARATOR)
        
//        var tags:String?
//        
//        if let tagsSet = tagsSet {
//            for tag in tagsSet {
//                if tags == nil {
//                    tags = tag
//                } else {
//                    tags = tags! + Constants.TAGS_SEPARATOR + tag
//                }
//            }
//        }
//        
//        return tags
    }
    
    func tagsToSet(_ tags:String?) -> Set<String>?
    {
        guard var tags = tags else {
            return nil
        }
        
        var tag:String
        var tagsSet = Set<String>()
        
        while (tags.range(of: Constants.TAGS_SEPARATOR) != nil) {
            if let range = tags.range(of: Constants.TAGS_SEPARATOR) {
                tag = tags.substring(to: range.lowerBound)
                tagsSet.insert(tag)
                tags = tags.substring(from: range.upperBound)
            } else {
                // ???
            }
        }
        
        tagsSet.insert(tags)
        
        return tagsSet.count == 0 ? nil : tagsSet
    }
    
    var tagsSet:Set<String>? {
        get {
            return tagsToSet(self.tags)
        }
    }
    
    var tagsArray:[String]? {
        get {
            guard let tagsSet = tagsSet else {
                return nil
            }
            
            return Array(tagsSet).sorted() {
                return $0 < $1
            }
        }
    }
    
    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio, let year = year, let id = id {
                dict?[Field.audio] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Constants.FILENAME_EXTENSION.MP3
            }
            
//            print(dict?[Field.audio])
            
            return dict?[Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict?[Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict?[Field.m3u8]
        }
    }
    
    var video:String? {
        get {
            return m3u8
        }
    }
    
    var videoID:String? {
        get {
//            print(video)
            
            guard let video = video else {
                return nil
            }
            
            guard video.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = video.substring(from: Constants.BASE_URL.VIDEO_PREFIX.endIndex)
//            print(tail)
            
            if let range = tail.range(of: ".m") {
                return tail.substring(to: range.lowerBound)
            } else {
                return nil
            }
        }
    }
    
    var externalVideo:String? {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    var notes:String? {
        get {
            if (dict?[Field.notes] == nil), hasNotes, let year = year, let id = id {
                dict?[Field.notes] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }

            //            print(dict?[Field.notes])
            return dict?[Field.notes]
        }
    }
    
    lazy var searchMarkedFullNotesHTML:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func markedFullNotesHTML(searchText:String?,wholeWordsOnly:Bool,index:Bool) -> String?
    {
        guard (stripHead(fullNotesHTML) != nil) else {
            return nil
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return fullNotesHTML
        }

        var markCounter = 0

        func mark(_ input:String) -> String
        {
            var string = input
            
            var stringBefore:String = Constants.EMPTY_STRING
            var stringAfter:String = Constants.EMPTY_STRING
            var newString:String = Constants.EMPTY_STRING
            var foundString:String = Constants.EMPTY_STRING
            
            while (string.lowercased().range(of: searchText.lowercased()) != nil) {
                guard let range = string.lowercased().range(of: searchText.lowercased()) else {
                    break
                }
                
                stringBefore = string.substring(to: range.lowerBound)
                stringAfter = string.substring(from: range.upperBound)
                
                var skip = false
                
                if wholeWordsOnly {
                    if stringBefore == "" {
                        if  let characterBefore:Character = newString.last,
                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                                skip = true
                            }
                            
                            if searchText.count == 1 {
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                    skip = true
                                }
                            }
                        }
                    } else {
                        if  let characterBefore:Character = stringBefore.last,
                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                                skip = true
                            }
                            
                            if searchText.count == 1 {
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                    skip = true
                                }
                            }
                        }
                    }
                    
                    if  let characterAfter:Character = stringAfter.first,
                        let unicodeScalar = UnicodeScalar(String(characterAfter)) {
                        if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        } else {
                            //                            if characterAfter == "." {
                            //                                if let afterFirst = stringAfter.substring(from: String(characterAfter).endIndex).first,
                            //                                    let unicodeScalar = UnicodeScalar(String(afterFirst)) {
                            //                                    if !CharacterSet.whitespacesAndNewlines.contains(unicodeScalar) && !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
                            //                                        skip = true
                            //                                    }
                            //                                }
                            //                            }
                        }
                        
                        //                            print(characterAfter)
                        
                        // What happens with other types of apostrophes?
                        if stringAfter.endIndex >= "'s".endIndex {
                            if (stringAfter.substring(to: "'s".endIndex) == "'s") {
                                skip = true
                            }
                            if (stringAfter.substring(to: "'t".endIndex) == "'t") {
                                skip = true
                            }
                            if (stringAfter.substring(to: "'d".endIndex) == "'d") {
                                skip = true
                            }
                        }
                    }
                    if let characterBefore:Character = stringBefore.last {
                        if let unicodeScalar = UnicodeScalar(String(characterBefore)),
                            !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        }
                    }
                }
                
                foundString = string.substring(from: range.lowerBound)
                if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
                    foundString = foundString.substring(to: newRange.upperBound)
                } else {
                    // ???
                }
                
                if !skip {
                    markCounter += 1
                    foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                }
                
                newString = newString + stringBefore + foundString
                
                stringBefore = stringBefore + foundString
                
                string = stringAfter
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }

        var newString:String = Constants.EMPTY_STRING
        var string:String = notesHTML ?? Constants.EMPTY_STRING
        
        while let searchRange = string.range(of: "<") {
            let searchString = string.substring(to: searchRange.lowerBound)
//            print(searchString)
            
            // mark search string
            newString = newString + mark(searchString.replacingOccurrences(of: "&nbsp;", with: " "))
            
            let remainder = string.substring(from: searchRange.lowerBound)

            if let htmlRange = remainder.range(of: ">") {
                let html = remainder.substring(to: htmlRange.upperBound)
//                print(html)
                
                newString = newString + html
                
                string = remainder.substring(from: htmlRange.upperBound)
            }
        }
        
        var indexString:String!
            
        if markCounter > 0 {
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.<br/>"
        }
        
        // If we want an index of links to the occurrences of the searchText.
        if index {
            if markCounter > 0 {
                indexString = indexString + "<div>Locations: "
                
                for counter in 1...markCounter {
                    if counter > 1 {
                        indexString = indexString + ", "
                    }
                    indexString = indexString + "<a href=\"#\(counter)\">\(counter)</a>"
                }
                
                indexString = indexString + "<br/><br/></div>"
            }
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if index {
            htmlString = htmlString + indexString
        }

        htmlString = htmlString + headerHTML + newString + "</body></html>"

        searchMarkedFullNotesHTML?[searchText] = insertHead(htmlString,fontSize: Constants.FONT_SIZE) // insertHead(newString,fontSize: Constants.FONT_SIZE)
        
        return searchMarkedFullNotesHTML?[searchText]
    }
    
    var headerHTML:String {
        get {
            var header = "<center><b>"
            
            if let string = title {
                header = header + string + "</br>"
            }
            
            if let string = scriptureReference {
                header = header + string + "</br>"
            }
            
            if let string = formattedDate {
                header = header + string + "</br>"
            }
            
            if let string = speaker {
                header = header + "<i>by " + string + "</i></br>"
            }
            
            header = header + "<i>Countryside Bible Church</i></br>"
            
            header = header + "</br>"
            
            if let websiteURL = websiteURL {
                header = header + "Available online at <a href=\"\(websiteURL)\">www.countrysidebible.org</a></br>"
            } else {
                header = header + "Available online at <a href=\"http://www.countrysidebible.org\">www.countrysidebible.org</a></br>"
            }
            
            if let string = yearString {
                header = header + "Copyright \(string).  All rights reserved.</br>"
            } else {
                header = header + "Copyright, all rights reserved.</br>"
            }
            
            header = header + "<i>Unedited transcript for personal use only.</i>"
            
            header = header + "</b></center>"

            return header
        }
    }
    
    var fullNotesHTML:String? {
        get {
            guard let notesHTML = notesHTML else {
                return nil
            }

            return insertHead("<!DOCTYPE html><html><body>" + headerHTML + notesHTML + "</body></html>",fontSize: Constants.FONT_SIZE)
        }
    }
    
    var notesHTML:String? {
        get {
            //            print(dict?[Field.notes])
            return dict?[Field.notes_HTML]
        }
        set {
            dict?[Field.notes_HTML] = newValue
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if (dict?[Field.slides] == nil) && hasSlides, let year = year, let id = id {
                dict?[Field.slides] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }

            return dict?[Field.slides]
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String? {
        get {
            if (dict?[Field.outline] == nil), hasSlides, let year = year, let id = id {
                dict?[Field.outline] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.outline + Constants.FILENAME_EXTENSION.PDF
            }
            
            return dict?[Field.outline]
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict?[Field.files]
        }
    }
    
    var hasAudio:Bool {
        get {
            if let contains = files?.contains("A") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasVideo:Bool {
        get {
            if let contains = files?.contains("V") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasSlides:Bool {
        get {
            if let contains = files?.contains("S") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasNotes:Bool {
        get {
            if let contains = files?.contains("T") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasNotesHTML:Bool {
        get {
//            print(files)
            
            if let contains = files?.contains("H") {
                return contains && hasNotes
            } else {
                return false
            }
        }
    }
    
    var hasOutline:Bool {
        get {
            if let contains = files?.contains("O") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var audioURL:URL? {
        get {
            if let audio = audio {
                return URL(string: audio)
            } else {
                return nil
            }
        }
    }
    
    var videoURL:URL? {
        get {
            if let video = video {
                return URL(string: video)
            } else {
                return nil
            }
        }
    }
    
    var notesURL:URL? {
        get {
            if let notes = notes {
                return URL(string: notes)
            } else {
                return nil
            }
        }
    }
    
    var slidesURL:URL? {
        get {
            if let slides = slides {
                return URL(string: slides)
            } else {
                return nil
            }
        }
    }
    
    var outlineURL:URL? {
        get {
            if let outline = outline {
                return URL(string: outline)
            } else {
                return nil
            }
        }
    }
    
    var audioFileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + Constants.FILENAME_EXTENSION.MP3)
            } else {
                return nil
            }
        }
    }
    
    var mp4FileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + Constants.FILENAME_EXTENSION.MP4)
            } else {
                return nil
            }
        }
    }
    
    var m3u8FileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + Constants.FILENAME_EXTENSION.M3U8)
            } else {
                return nil
            }
        }
    }
    
    var videoFileSystemURL:URL? {
        get {
            return m3u8FileSystemURL
        }
    }
    
    var slidesFileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + "." + Field.slides + Constants.FILENAME_EXTENSION.PDF)
            } else {
                return nil
            }
        }
    }
    
    var notesFileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + "." + Field.notes + Constants.FILENAME_EXTENSION.PDF)
            } else {
                return nil
            }
        }
    }
    
    var outlineFileSystemURL:URL? {
        get {
            if let id = id {
                return cachesURL()?.appendingPathComponent(id + "." + Field.outline + Constants.FILENAME_EXTENSION.PDF)
            } else {
                return nil
            }
        }
    }
    
    var bookSections:[String]
    {
        get {
            if let books = books {
                return books
            }
            
            guard hasScripture, let scriptureReference = scriptureReference else {
                return [Constants.Strings.None]
            }
            
            return [scriptureReference.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)]
        }
    }
    
    func verses(book:String,chapter:Int) -> [Int]
    {
        var versesForChapter = [Int]()
        
        if let bacv = booksAndChaptersAndVerses(), let verses = bacv[book]?[chapter] {
            versesForChapter = verses
        }
        
        return versesForChapter
    }
    
    func chaptersAndVerses(book:String) -> [Int:[Int]]
    {
        var chaptersAndVerses = [Int:[Int]]()
        
        if let bacv = booksAndChaptersAndVerses(), let cav = bacv[book] {
            chaptersAndVerses = cav
        }
        
        return chaptersAndVerses
    }
    
    func booksAndChaptersAndVerses() -> BooksChaptersVerses?
    {
        // PUT THIS BACK LATER
        if self.booksChaptersVerses != nil {
            return self.booksChaptersVerses
        }
        
        guard (scripture != nil) else {
            return nil
        }
        
        guard let scriptureReference = scriptureReference else {
            return nil
        }
        
//        print(scripture!)
        
        let booksAndChaptersAndVerses = BooksChaptersVerses()
        
        let books = booksFromScriptureReference(scriptureReference)
        
        guard (books != nil) else {
            return nil
        }

        var scriptures = [String]()
        
        var string = scriptureReference
        
        let separator = ";"
        
        while let range = string.range(of: separator) {
            scriptures.append(string.substring(to: range.lowerBound))
            string = string.substring(from: range.upperBound)
        }
        
        scriptures.append(string)

        var lastBook:String?
        
        for scripture in scriptures {
            var book = booksFromScriptureReference(scripture)?.first
            
            if book == nil {
                book = lastBook
            } else {
                lastBook = book
            }
            
            if let book = book {
                var reference = scripture
                
                if let range = scripture.range(of: book) {
                    reference = scripture.substring(from: range.upperBound)
                }
                
//                print(book,reference)
                
                // What if a reference includes the book more than once?
                booksAndChaptersAndVerses[book] = chaptersAndVersesFromScripture(book:book,reference:reference)
                
                if let chapters = booksAndChaptersAndVerses[book]?.keys {
                    for chapter in chapters {
                        if booksAndChaptersAndVerses[book]?[chapter] == nil {
                            print(description,book,chapter)
                        }
                    }
                }
            }
        }
        
//        print(scripture!)
//        print(booksAndChaptersAndVerses)
        
        self.booksChaptersVerses = booksAndChaptersAndVerses.data?.count > 0 ? booksAndChaptersAndVerses : nil
        
        return self.booksChaptersVerses
    }
    
    func chapters(_ thisBook:String) -> [Int]?
    {
        guard let scriptureReference = scriptureReference else {
            return nil
        }
        
        guard !Constants.NO_CHAPTER_BOOKS.contains(thisBook) else {
            return [1]
        }
        
        var chaptersForBook:[Int]?
        
        guard let books = booksFromScriptureReference(scriptureReference) else {
            return nil
        }

        switch books.count {
        case 0:
            break
            
        case 1:
            if thisBook == books.first {
                if Constants.NO_CHAPTER_BOOKS.contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scriptureReference
                    
                    if (string.range(of: ";") == nil) {
                        if let range = scriptureReference.range(of: thisBook) {
                            chaptersForBook = chaptersFromScriptureReference(string.substring(from: range.upperBound))
                        } else {
                            // ???
                        }
                    } else {
                        while let range = string.range(of: ";") {
                            var subString = string.substring(to: range.lowerBound)
                            
                            if let range = subString.range(of: thisBook) {
                                subString = subString.substring(from: range.upperBound)
                            }
                            if let chapters = chaptersFromScriptureReference(subString) {
                                chaptersForBook?.append(contentsOf: chapters)
                            }
                            
                            string = string.substring(from: range.upperBound)
                        }
                        
                        //                        print(string)
                        if let range = string.range(of: thisBook) {
                            string = string.substring(from: range.upperBound)
                        }
                        if let chapters = chaptersFromScriptureReference(string) {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            } else {
                // THIS SHOULD NOT HAPPEN
            }
            break
            
        default:
            var scriptures = [String]()
            
            var string = scriptureReference
            
            let separator = ";"
            
            while let range = string.range(of: separator) {
                scriptures.append(string.substring(to: range.lowerBound))
                string = string.substring(from: range.upperBound)
            }
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if let range = scripture.range(of: thisBook) {
                    if let chapters = chaptersFromScriptureReference(scripture.substring(from: range.upperBound)) {
                        if chaptersForBook == nil {
                            chaptersForBook = chapters
                        } else {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            }
            break
        }
        
//        if chaptersForBook.count > 1 {
//            print("\(scripture)")
//            print("\(chaptersForBook)")
//        }
        
        return chaptersForBook
    }
    
    var books:[String]? {
        get {
            return booksFromScriptureReference(scriptureReference)
        }
    }
    
    var fullDate:Date? {
        get {
            if let date = date {
                return Date(dateString:date)
            } else {
                return nil
            }
        }
    }
    
    var contents:String? {
        get {
            return stripHTML(bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs: false, includeColumns: false))
        }
    }

    var contentsHTML:String? {
        get {
            var bodyString = "<!DOCTYPE html><html><body>"
            
            if let string = bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs: true, includeColumns: true) {
                bodyString = bodyString + string
            }
            
            bodyString = bodyString + "</body></htm>"
            
            return bodyString
        }
    }

    var transcripts = [String:VoiceBase]()
    
    lazy var audioTranscript:VoiceBase? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasAudio else {
            return nil
        }
    
        let voicebase = VoiceBase(mediaItem:self,purpose:Purpose.audio) // CRITICAL: This initializer sets mediaID and completed from settings.

        if let purpose = voicebase.purpose {
            self.transcripts[purpose] = voicebase
        }
        return voicebase
    }()
    
    lazy var videoTranscript:VoiceBase? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self.hasVideo else {
            return nil
        }
        
        let voicebase = VoiceBase(mediaItem:self,purpose:Purpose.video) // CRITICAL: This initializer sets mediaID and completed from settings.

        if let purpose = voicebase.purpose {
            self.transcripts[purpose] = voicebase
        }
        return voicebase
    }()
    
    func bodyHTML(order:[String],token: String?,includeURLs:Bool,includeColumns:Bool) -> String?
    {
        var bodyString:String?
        
        if includeColumns {
            bodyString = "<tr>"
            
            for item in order {
                switch item.lowercased() {
                case "date":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if let month = formattedDateMonth {
                        bodyString = bodyString! + month
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;text-align:right;\">" //valign=\"baseline\" align=\"right\"
                    if let day = formattedDateDay {
                        bodyString  = bodyString! + day + ","
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;text-align:right;\">" //  valign=\"baseline\" align=\"right\"
                    if let year = formattedDateYear {
                        bodyString  = bodyString! + year
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if let service = self.service {
                        bodyString  = bodyString! + service
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "title":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            bodyString = bodyString! + "<a target=\"_blank\" href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = bodyString! + title
                        }
                    }
                    bodyString = bodyString! + "</td>"
                    break

                case "scripture":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if let scriptureReference = self.scriptureReference {
                        bodyString = bodyString! + scriptureReference
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "speaker":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if hasSpeaker, let speaker = self.speaker {
                        bodyString = bodyString! + speaker
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "class":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if hasClassName, let className = self.className {
                        bodyString = bodyString! + className
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "event":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if hasEventName, let eventName = self.eventName {
                        bodyString = bodyString! + eventName
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "count":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">" //  valign=\"baseline\"
                    if let token = token, let count = self.notesTokens?[token] {
                        bodyString = bodyString! + "(\(count))"
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                default:
                    break
                }
            }
            
            bodyString = bodyString! + "</tr>"
        } else {
            for item in order {
                switch item.lowercased() {
                case "date":
                    if let date = formattedDate {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + date
                    }
                    
                    if let service = self.service {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + service
                    }
                    break

                case "title":
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + "<a href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + title //  + Constants.SINGLE_SPACE
                        }
                    }
                    break

                case "scripture":
                    if let scriptureReference = self.scriptureReference {
                        bodyString  = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + scriptureReference // Constants.SINGLE_SPACE +
                    }
                    break
                    
                case "speaker":
                    if hasSpeaker, let speaker = self.speaker {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + speaker // Constants.SINGLE_SPACE +
                    }
                    break
                    
                case "class":
                    if hasClassName, let className = self.className {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + className // Constants.SINGLE_SPACE +
                    }
                    break
                    
                case "event":
                    if hasEventName, let eventName = self.eventName {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + eventName // Constants.SINGLE_SPACE +
                    }
                    break
                    
                case "count":
                    if let token = token, let count = self.notesTokens?[token] {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + "(\(count))" // Constants.SINGLE_SPACE +
                    }
                    break

                default:
                    break
                }
            }
        }
        
        return bodyString
    }
    
    var text : String? {
        get {
            guard var string = hasDate ? formattedDate : "No Date" else {
                return nil
            }
            
            if let service = service {
                string = string + " \(service)"
            }
            
            if hasSpeaker, let speaker = speaker {
                string = string + "\n\(speaker)"
            }
            
            if hasTitle, let title = title {
                if let rangeTo = title.range(of: " (Part"), let rangeFrom = title.range(of: " (Part "), rangeFrom.lowerBound == rangeTo.lowerBound {
                    let first = title.substring(to: rangeTo.upperBound)
                    let second = title.substring(from: rangeFrom.upperBound)
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                    string = string + "\n\(combined)"
                } else {
                    string = string + "\n\(title)"
                }
            }
            
            if let scriptureReference = scriptureReference {
                string = string + "\n\(scriptureReference)"
            }
            
            if hasClassName, let className = className {
                string = string + "\n\(className)"
            }
            
            if hasEventName, let eventName = eventName {
                string = string + "\n\(eventName)"
            }
            
            return string
        }
    }
    
    var json : String {
        var mediaItemString = "{"

            mediaItemString = "\(mediaItemString)\"metadata\":{"

                if let category = category {
                    mediaItemString = "\(mediaItemString)\"category\":\"\(category)\","
                }
                
                if let id = id {
                    mediaItemString = "\(mediaItemString)\"id\":\"\(id)\","
                }
                
                if let date = date {
                    mediaItemString = "\(mediaItemString)\"date\":\"\(date)\","
                }
                
                if let service = service {
                    mediaItemString = "\(mediaItemString)\"service\":\"\(service)\","
                }
                
                if let title = title {
                    mediaItemString = "\(mediaItemString)\"title\":\"\(title)\","
                }
                
                if let scripture = scripture {
                    mediaItemString = "\(mediaItemString)\"scripture\":\"\(scripture.description)\","
                }
                
                if let speaker = speaker {
                    mediaItemString = "\(mediaItemString)\"speaker\":\"\(speaker)\""
                }
            
            mediaItemString = "\(mediaItemString)}"
        
        mediaItemString = "\(mediaItemString)}"
        
        return mediaItemString
    }
    
    override var description : String {
        return json
    }
    
    class MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        deinit {
            
        }
        
        subscript(key:String) -> String? {
            get {
                guard let mediaItem = mediaItem else {
                    return nil
                }
                
                return globals.mediaItemSettings?[mediaItem.id]?[key]
            }
            set {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in Settings!")
                    return
                }
                
                if globals.mediaItemSettings == nil {
                    globals.mediaItemSettings = [String:[String:String]]()
                }
                if (globals.mediaItemSettings != nil) {
                    if (globals.mediaItemSettings?[mediaItem.id] == nil) {
                        globals.mediaItemSettings?[mediaItem.id] = [String:String]()
                    }
                    if (globals.mediaItemSettings?[mediaItem.id]?[key] != newValue) {
                        //                        print("\(mediaItem)")
                        globals.mediaItemSettings?[mediaItem.id]?[key] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        globals.saveSettingsBackground()
                    }
                } else {
                    print("globals.settings == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return MediaItemSettings(mediaItem:self)
    }()
    
    class MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        deinit {
            
        }
        
        subscript(key:String) -> String? {
            get {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in SeriesSettings!")
                    return nil
                }
                
                return globals.multiPartSettings?[mediaItem.seriesID]?[key]
            }
            set {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in SeriesSettings!")
                    return
                }
                
                if globals.multiPartSettings == nil {
                    globals.multiPartSettings = [String:[String:String]]()
                }
                
                guard (globals.multiPartSettings != nil) else {
                    print("globals.viewSplits == nil in SeriesSettings!")
                    return
                }
                
                if (globals.multiPartSettings?[mediaItem.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem.seriesID]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    globals.saveSettingsBackground()
                }
            }
        }
    }
    
    lazy var multiPartSettings:MultiPartSettings? = {
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return MultiPartSettings(mediaItem:self)
    }()
    
    var verticalSplit:String? {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var horizontalSplit:String? {
        get {
            return multiPartSettings?[Constants.SLIDE_SPLIT]
        }
        set {
            multiPartSettings?[Constants.SLIDE_SPLIT] = newValue
        }
    }
    
    var hasDate : Bool
    {
        guard let isEmpty = date?.isEmpty else {
            return false
        }
        
        return !isEmpty
    }
    
    var hasTitle : Bool
    {
        guard let title = title else {
            return false
        }
        
        return !title.isEmpty && (title != Constants.Strings.None)
    }
    
    var playingAudio : Bool
    {
        return (playing == Playing.audio)
    }
    
    var playingVideo:Bool
    {
        get {
            return (playing == Playing.video)
        }
    }
    
    var showingVideo:Bool
    {
        get {
            return (showing == Showing.video)
        }
    }
    
    var hasScripture:Bool
        {
        get {
            guard let scriptureReference = scriptureReference else {
                return false
            }
            
            return !scriptureReference.isEmpty && (scriptureReference != Constants.Strings.None)
        }
    }
    
    var hasClassName:Bool
        {
        get {
            guard let className = className else {
                return false
            }
            
            return !className.isEmpty && (className != Constants.Strings.None)
        }
    }
    
    var hasEventName:Bool
        {
        get {
            guard let eventName = eventName else {
                return false
            }
            
            return !eventName.isEmpty && (eventName != Constants.Strings.None)
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            guard let isEmpty = multiPartName?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasCategory:Bool
        {
        get {
            guard let isEmpty = category?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasBook:Bool
    {
        get {
            return (self.books != nil)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            guard let speaker = speaker else {
                return false
            }
            
            return !speaker.isEmpty && (speaker != Constants.Strings.None)

//            guard let isEmpty = ?.isEmpty else {
//                return false
//            }
//            
//            if isEmpty {
//                print("speaker is empty")
//            }
//            
//            return !isEmpty
        }
    }
    
    var showingNotes:Bool
    {
        get {
            return (showing == Showing.notes)
        }
    }
    
    var showingSlides:Bool
    {
        get {
            return (showing == Showing.slides)
        }
    }
    
    func checkNotes() -> Bool
    {
        guard hasNotes else {
            return false
        }
        
        guard let notesURL = notesURL else {
            return false
        }
        
        guard globals.reachability.isReachable else {
            return false
        }
        
        return (try? Data(contentsOf: notesURL)) != nil
    }
    
    func hasNotes(_ check:Bool) -> Bool
    {
        return check ? checkNotes() : hasNotes
    }
    
    func checkSlides() -> Bool
    {
        guard hasSlides else {
            return false
        }
        
        guard let slidesURL = slidesURL else {
            return false
        }
        
        guard globals.reachability.isReachable else {
            return false
        }

        return (try? Data(contentsOf: slidesURL)) != nil
    }
    
    func hasSlides(_ check:Bool) -> Bool
    {
        return check ? checkSlides() : hasSlides
    }
    
    var hasTags:Bool
    {
        get {
            guard let isEmpty = tags?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            guard hasTags else {
                return false
            }
            
            guard let tagsSet = tagsSet else {
                return false
            }
            
            return tagsSet.contains(Constants.Strings.Favorites)
        }
    }

    func editActions(viewController: UIViewController) -> [AlertAction]?
    {
        var actions = [AlertAction]()
        
        var scripture:AlertAction!
        var share:AlertAction!
        var openOnCBC:AlertAction!
        var favorites:AlertAction!
        var download:AlertAction!
        var transcript:AlertAction!
        var words:AlertAction!
        var search:AlertAction!
        var tags:AlertAction!
        var voiceBase:AlertAction!
        var topics:AlertAction!
        
        if hasAudio, let audioDownload = audioDownload {
            var title = ""
            var style = UIAlertActionStyle.default
            
            switch audioDownload.state {
            case .none:
                title = Constants.Strings.Download_Audio
                break
                
            case .downloading:
                title = Constants.Strings.Cancel_Audio_Download
                break
            case .downloaded:
                title = Constants.Strings.Delete_Audio_Download
                style = UIAlertActionStyle.destructive
                break
            }
            
            download = AlertAction(title: title, style: style, handler: {
                switch title {
                case Constants.Strings.Download_Audio:
                    audioDownload.download()
                    Thread.onMainThread(block: {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: audioDownload)
                    })
                    break
                    
                case Constants.Strings.Delete_Audio_Download:
                    var alertActions = [AlertAction]()

                    let yesAction = AlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                        () -> Void in
                        audioDownload.delete()
                    })
                    alertActions.append(yesAction)
                    
                    let noAction = AlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                        () -> Void in
                        
                    })
                    alertActions.append(noAction)
                    
                    let cancel = AlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        () -> Void in
                        
                    })
                    alertActions.append(cancel)
                    
//                    present(alert, animated: true, completion: nil)
                    
                    globals.alert(title: "Confirm Deletion of Audio Download", message: nil, actions: alertActions)
                    break
                    
                case Constants.Strings.Cancel_Audio_Download:
                    switch audioDownload.state {
                    case .downloading:
                        audioDownload.cancel()
                        break
                        
                    case .downloaded:
                        var alertActions = [AlertAction]()
                        
//                            let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
//                                                            message: nil,
//                                                            preferredStyle: .alert)
//                            alert.makeOpaque()
                        
                        let yesAction = AlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                            () -> Void in
                            self.audioDownload?.delete()
                        })
                        alertActions.append(yesAction)
                        
                        let noAction = AlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                            () -> Void in
                            
                        })
                        alertActions.append(noAction)
                        
                        let cancel = AlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            () -> Void in
                            
                        })
                        alertActions.append(cancel)
                        
//                            self.present(alert, animated: true, completion: nil)
                        
                        globals.alert(title: "Confirm Deletion of Audio Download", message: nil, actions: alertActions)
                        break
                        
                    default:
                        break
                    }
                
                default:
                    break
                }
            })
        }
        
        var title:String
        
        if hasFavoritesTag {
            title = Constants.Strings.Remove_From_Favorites
        } else {
            title = Constants.Strings.Add_to_Favorites
        }
        
        favorites = AlertAction(title: title, style: .default) {
            switch title {
            case Constants.Strings.Add_to_Favorites:
                // This blocks this thread until it finishes.
                globals.queue.sync {
                    self.addTag(Constants.Strings.Favorites)
                }
                break
                
            case Constants.Strings.Remove_From_Favorites:
                // This blocks this thread until it finishes.
                globals.queue.sync {
                    self.removeTag(Constants.Strings.Favorites)
                }
                break
                
            default:
                break
            }
        }
        
        openOnCBC = AlertAction(title: Constants.Strings.Open_on_CBC_Website, style: .default) {
            if let url = self.websiteURL {
                open(scheme: url.absoluteString) {
                    globals.alert(title: "Network Error",message: "Unable to open: \(url)")
//                    networkUnavailable(self,"Unable to open: \(url)")
                }
            }
        }
        
        share = AlertAction(title: Constants.Strings.Share, style: .default) {
            self.share(viewController: viewController)
            //            shareHTML(viewController: self, htmlString: mediaItem.webLink)
        }
        
        tags = AlertAction(title: Constants.Strings.Tags, style: .default) {
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }
            
            if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = mtvc
                
                navigationController.popoverPresentationController?.barButtonItem = mtvc.tagsButton
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                
                popover.navigationItem.title = Constants.Strings.Show // Show MediaItems Tagged With
                
                popover.delegate = mtvc
                popover.purpose = .selectingTags
                
                popover.stringSelected = globals.media.tags.selected ?? Constants.Strings.All
                
                popover.section.strings = self.tagsArray
                popover.section.strings?.insert(Constants.Strings.All,at: 0)
                
                popover.vc = mtvc
                
                mtvc.present(navigationController, animated: true, completion: nil)
            }
        }
        
        search = AlertAction(title: Constants.Strings.Search, style: .default) {
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }
            
            if let searchStrings = self.searchStrings(),
                let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                viewController.dismiss(animated: true, completion: {
                    mtvc.presentingVC = nil
                })
                
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = mtvc
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.sourceView = mtvc.view
                navigationController.popoverPresentationController?.sourceRect = mtvc.searchBar.frame
                
                popover.navigationItem.title = Constants.Strings.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = mtvc
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = self
                
                popover.section.strings = searchStrings
                
                popover.vc = mtvc.splitViewController
                
                mtvc.present(navigationController, animated: true, completion:{
                    mtvc.presentingVC = navigationController
                })
            }
        }
        
        words = AlertAction(title: Constants.Strings.Words, style: .default) {
            guard self.hasNotesHTML else {
                return
            }
            
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }
            
            func transcriptTokens()
            {
                guard Thread.isMainThread else {
                    alert(viewController:viewController,title: "Not Main Thread", message: "MediaTableViewController:transcriptTokens", completion: nil)
                    return
                }
                
                guard let tokens = self.notesTokens?.map({ (string:String,count:Int) -> String in
                    return "\(string) (\(count))"
                }).sorted() else {
                    networkUnavailable(viewController,"HTML transcript vocabulary unavailable.")
                    return
                }
                
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    mtvc.dismiss(animated: true, completion: {
                        mtvc.presentingVC = nil
                    })
                    
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = mtvc
                    
                    popover.navigationItem.title = Constants.Strings.Search
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.parser = { (string:String) -> [String] in
                        return [string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)]
                    }
                    
                    popover.delegate = mtvc
                    popover.purpose = .selectingCellSearch
                    
                    popover.selectedMediaItem = self
                    
                    popover.section.showIndex = true
                    
                    popover.section.strings = tokens
                    
                    popover.vc = viewController.splitViewController
                    
                    popover.segments = true
                    
                    popover.sort.function = sort
                    popover.sort.method = Constants.Sort.Alphabetical
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: {
                        let strings = popover.sort.function?(Constants.Sort.Alphabetical,popover.section.strings)
                        if popover.segmentedControl.selectedSegmentIndex == 0 {
                            popover.sort.method = Constants.Sort.Alphabetical
                            popover.section.strings = strings
                            popover.section.showIndex = true
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                        let strings = popover.sort.function?(Constants.Sort.Frequency,popover.section.strings)
                        if popover.segmentedControl.selectedSegmentIndex == 1 {
                            popover.sort.method = Constants.Sort.Frequency
                            popover.section.strings = strings
                            popover.section.showIndex = false
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    popover.search = popover.section.strings?.count > 10
                    
                    mtvc.present(navigationController, animated: true, completion: {
                        mtvc.presentingVC = navigationController
                    })
                }
            }
            
            if self.notesTokens == nil {
                guard globals.reachability.isReachable else {
                    networkUnavailable(viewController,"HTML transcript words unavailable.")
                    return
                }
                
                process(viewController: mtvc, work: { () -> (Any?) in
                    self.loadNotesTokens()
                }, completion: { (data:Any?) in
                    transcriptTokens()
                })
            } else {
                transcriptTokens()
            }
        }
        
        transcript = AlertAction(title: Constants.Strings.Transcript, style: .default) {
//            let sourceView = cell?.subviews[0]
//            let sourceRectView = cell?.subviews[0]
            
            if self.notesHTML != nil {
                var htmlString:String?

                if let lexiconIndexViewController = viewController as? LexiconIndexViewController {
                    htmlString = self.markedFullNotesHTML(searchText:lexiconIndexViewController.searchText, wholeWordsOnly: true,index: true)
                } else {
                    htmlString = self.fullNotesHTML
                }
                
                popoverHTML(viewController,mediaItem:self,title:nil,barButtonItem:nil,sourceView:viewController.view,sourceRectView:viewController.view,htmlString:htmlString)
            } else {
                guard globals.reachability.isReachable else {
                    globals.alert(title: "Network Error",message: "HTML transcript unavailable.")
                    return
                }
                
                process(viewController: globals.splitViewController, work: { () -> (Any?) in
                    self.loadNotesHTML()
                    
                    return self.fullNotesHTML
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(viewController,mediaItem:self,title:nil,barButtonItem:nil,sourceView:viewController.view,sourceRectView:viewController.view,htmlString:htmlString)
                    } else {
                        globals.alert(title: "Network Error",message: "HTML transcript unavailable.")
                    }
                })
            }
        }
        
        scripture = AlertAction(title: Constants.Strings.Scripture, style: .default) {
//            let sourceView = cell?.subviews[0]
//            let sourceRectView = cell?.subviews[0]
            
            if let reference = self.scriptureReference {
                if self.scripture?.html?[reference] != nil {
                    popoverHTML(viewController,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:viewController.view,sourceRectView:viewController.view,htmlString:self.scripture?.html?[reference])
                } else {
                    guard globals.reachability.isReachable else {
                        networkUnavailable(viewController,"Scripture text unavailable.")
//                        globals.alert(title: "Network Error",message: "Scripture text unavailable.")
                        return
                    }
                    
                    process(viewController: viewController, work: { () -> (Any?) in
                        self.scripture?.load()
                        return self.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(viewController,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:viewController.view,sourceRectView:viewController.view,htmlString:htmlString)
                        } else {
                            networkUnavailable(viewController,"Scripture text unavailable.")
                        }
                    })
                }
            }
        }
        
        voiceBase = AlertAction(title: "VoiceBase", style: .default) {
            var alertActions = [AlertAction]()
            
            if let actions = self.audioTranscript?.recognizeAlertActions(viewController:viewController) {
                alertActions.append(actions)
            }
            if let actions = self.videoTranscript?.recognizeAlertActions(viewController:viewController) {
                alertActions.append(actions)
            }
            
            // At most, only ONE of the following TWO will be added.
            if  var vc = viewController as? PopoverTableViewControllerDelegate,
                let actions = self.audioTranscript?.keywordAlertActions(viewController:viewController, completion: { (popover:PopoverTableViewController)->(Void) in
                vc.popover = popover
            }) {
//                let mvc = viewController as? MediaViewController // self == mvc?.selectedMediaItem,
                
                if self == globals.mediaPlayer.mediaItem, self.playing == Playing.audio, self.audioTranscript?.keywords != nil {
                    alertActions.append(actions)
                }
            }
            if  var vc = viewController as? PopoverTableViewControllerDelegate,
                let actions = self.videoTranscript?.keywordAlertActions(viewController:viewController, completion: { (popover:PopoverTableViewController)->(Void) in
                vc.popover = popover
            }) {
//                let mvc = viewController as? MediaViewController // self == mvc?.selectedMediaItem, 
                
                if self == globals.mediaPlayer.mediaItem, self.playing == Playing.video, self.videoTranscript?.keywords != nil {
                    alertActions.append(actions)
                }
            }
            
            var message = "Machine Generated Transcript"
            
            if let text = self.text {
                message += "\n\n\(text)"
            }
            
            alertActionsCancel( viewController: viewController,
                                title: "VoiceBase",
                                message: message,
                                alertActions: alertActions,
                                cancelAction: nil)
        }
        
        topics = AlertAction(title: "List", style: .default) {
            if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = "Topics"
                
                popover.selectedMediaItem = self
                
                popover.search = true
                
                popover.delegate = viewController as? PopoverTableViewControllerDelegate
                popover.purpose = .selectingTopic
                popover.section.strings = self.audioTranscript?.topics?.sorted()
                
                viewController.present(navigationController, animated: true, completion: {
                    (viewController as? MediaTableViewController)?.popover = popover
                    (viewController as? MediaViewController)?.popover = popover
                })
            }
        }
        
        if books != nil {
            actions.append(scripture)
        }

        if (viewController as? MediaTableViewController) != nil {
            if hasTags {
                actions.append(tags)
            }
            
            actions.append(search)

            if hasNotesHTML {
                actions.append(words)
            }
        }
        
        if hasNotesHTML {
            actions.append(transcript)
        }
        
        actions.append(favorites)
        
        actions.append(openOnCBC)

        actions.append(share)
        
        if hasAudio && (download != nil) {
            actions.append(download)
        }
        
        if globals.allowMGTs {
            actions.append(voiceBase)
        }
        
        return actions.count > 0 ? actions : nil
    }
}
