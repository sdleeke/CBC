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

struct SearchHit {
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
    
    var title:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.title?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var formattedDate:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.formattedDate?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var speaker:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.speaker?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var scriptureReference:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.scriptureReference?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var className:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.className?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var eventName:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.eventName?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var tags:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.tags?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var transcriptHTML:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            
//            guard globals.search.transcripts else {
//                return false
//            }
            
            return mediaItem?.notesHTML?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
}

extension MediaItem : URLSessionDownloadDelegate
{
    // MARK: URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR")
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            download?.cancel()
            return
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        if let purpose = download?.purpose {
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })

            //            print(totalBytesWritten,totalBytesExpectedToWrite,Float(totalBytesWritten) / Float(totalBytesExpectedToWrite),Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100))
            
            let progress = totalBytesExpectedToWrite > 0 ? Int((Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100) % 100 : 0
            
            let current = download!.totalBytesExpectedToWrite > 0 ? Int((Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite)) * 100) % 100 : 0
            
            //            print(progress,current)
            
            switch purpose {
            case Purpose.audio:
                if progress > current {
                    //                    print(Constants.NOTIFICATION.MEDIA_UPDATE_CELL)
                    //                    DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: download?.mediaItem)
                    })
                }
                break
                
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                if progress > current {
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: download)
                    })
                }
                break
                
            default:
                break
            }
            
            debug("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            debug("session: \(String(describing: session.sessionDescription))")
            debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
            
            if (download?.fileSystemURL != nil) {
                debug("path: \(download!.fileSystemURL!.path)")
                debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
                
                if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                    debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
                }
            } else {
                debug("No fileSystemURL")
            }
            
            debug("bytes written: \(totalBytesWritten)")
            debug("bytes expected to write: \(totalBytesExpectedToWrite)")
            
            if (download?.state == .downloading) {
                download?.totalBytesWritten = totalBytesWritten
                download?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                print("ERROR NOT DOWNLOADING")
            }
        } else {
            print("ERROR NO DOWNLOAD")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }
        
        guard let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR")
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            download?.cancel()
            return
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard (download!.fileSystemURL != nil) else {
            print("NO FILE SYSTEM URL!")
            return
        }
        
        debug("URLSession:downloadTask:didFinishDownloadingToURL:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("downloadTask: \(String(describing: downloadTask.taskDescription))")
        
        debug("purpose: \(download!.purpose!)")
        
        debug("path: \(download!.fileSystemURL!.path)")
        debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        
        if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
            debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        let fileManager = FileManager.default
        
        // Check if file exists
        //            print("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
        
        do {
            if (download?.state == .downloading) && (download!.totalBytesExpectedToWrite != -1) {
                if (fileManager.fileExists(atPath: download!.fileSystemURL!.path)){
                    do {
                        try fileManager.removeItem(at: download!.fileSystemURL!)
                    } catch _ {
                        print("failed to remove duplicate download")
                    }
                }
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: download!.fileSystemURL!)
                try fileManager.removeItem(at: location)
                download?.state = .downloaded
            } else {
                // Nothing was downloaded
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                })
                download?.state = .none
            }
        } catch _ {
            print("failed to copy temp download file")
            download?.state = .none
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }

        guard let statusCode = (task.response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            print("DOWNLOAD ERROR:",task.taskDescription as Any,(task.response as? HTTPURLResponse)?.statusCode as Any)
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: download)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            download?.cancel()
            return
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        debug("URLSession:task:didCompleteWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        debug("task: \(String(describing: task.taskDescription))")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
            
            if (task.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                debug("task.taskDescription != download!.fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
            //            download?.state = .none
            
            switch download!.purpose! {
            case Purpose.slides:
                fallthrough
            case Purpose.notes:
                DispatchQueue.main.async(execute: { () -> Void in
                    //                    print(download?.mediaItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: download)
                })
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
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        debug("URLSession:didBecomeInvalidWithError:")
        
        debug("session: \(String(describing: session.sessionDescription))")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
        }
        
        download?.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var filename:String?
        
        filename = session.configuration.identifier!.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                print("\(filename) \(key)")
            return value.task?.taskDescription == filename
        }).first?.1 {
            download.completionHandler?()
        }
    }
}

class MediaItem : NSObject {
    var dict:[String:String]?
    
    var booksChaptersVerses:BooksChaptersVerses?
    
    var notesTokens:[String:Int]? //[(String,Int)]?
    
    var singleLoaded = false

    func freeMemory()
    {
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
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaItem.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.audio
        download.downloadURL = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Purpose.audio] = download
        return download
        }()
    
    lazy var videoDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.video
        download.downloadURL = self.videoURL
        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Purpose.video] = download
        return download
        }()
    
    lazy var slidesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.slides
        download.downloadURL = self.slidesURL
        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Purpose.slides] = download
        return download
        }()
    
    lazy var notesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.notes
        download.downloadURL = self.notesURL
        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Purpose.notes] = download
        return download
        }()
    
    lazy var outlineDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.outline
        download.downloadURL = self.outlineURL
        download.fileSystemURL = self.outlineFileSystemURL
        self.downloads[Purpose.outline] = download
        return download
        }()
    
    var id:String! {
        get {
            return dict![Field.id]
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in id.characters {
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
            
            let code = afterDate.substring(to: "x".endIndex)
            
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
//            let tags = tagsSet?.subtracting(Constants.Constant_Tags)
            
            if (hasMultipleParts) {
                var mediaItemParts:[MediaItem]?
//                print(multiPartSort)
                if (globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL] == nil) {
                    mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                        if testMediaItem.hasMultipleParts {
//                            var tagsMatch = false
//                            
//                            let testTags = testMediaItem.tagsSet?.subtracting(Constants.Constant_Tags)
//                            
//                            if tags != nil {
//                                if testTags != nil {
//                                    // THIS IS A TERRIBLE APPROACH.  We need a way to determine if mediaItems are in the same multi-part set of mediaItems based on not tags but something else.
//                                    // OTHERWISE mediaItems w/ the same multiPartName in different years (i.e. different "series") show up in the same list!
//                                    
//                                    // Requiring they all be in the same year or even sequential Sundays is also problematic!
//                                    
//                                    // AND IF THEY HAVE THE SAME JSON tag we can't tell them apart!
//                                    
//                                    tagsMatch = tags!.intersection(testTags!).count > 0
//                                    
//                                        //                                    for tag in tags! {
//                                        //    //                                    if multiPartName!.contains("Trilemma") && testMediaItem.multiPartName!.contains("Trilemma") {
//                                        //    //                                        print(self)
//                                        //    //                                        print(testMediaItem)
//                                        //    //                                        print(tagsMatch)
//                                        //    //                                        print(multiPartName,testMediaItem.multiPartName)
//                                        //    //                                        print(category,testMediaItem.category)
//                                        //    //                                    }
//                                        //                                        
//                                        //                                        if let contains = testTags?.contains(tag), contains {
//                                        //                                            tagsMatch = true
//                                        //                                            break
//                                        //                                        }
//                                        //                                    }
//                                } else {
//                                    tagsMatch = tags!.isEmpty
//                                }
//                            } else {
//                                tagsMatch = true
//                            }
                            
//                            if multiPartName!.contains("Faithful God;") && testMediaItem.multiPartName!.contains("Faithful God;") {
//                                print(self)
//                                print(testMediaItem)
//                                print(tags,testTags,tagsMatch)
//                                print(multiPartName,testMediaItem.multiPartName)
//                                print(category,testMediaItem.category)
//                            }
                            
                            // tagsMatch && 
                            
                            return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                        } else {
                            return false
                        }
                    })
                } else {
                    mediaItemParts = globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
//                print(mediaItemParts)
                
                // Filter for conference series
                
                if conferenceCode != nil {
                    mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.conferenceCode == conferenceCode
                    }),sorting: Sorting.CHRONOLOGICAL)
                } else {
                    if hasClassName {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                            //                        print(classCode,testMediaItem.classCode)
                            return testMediaItem.classCode == classCode
                        }),sorting: Sorting.CHRONOLOGICAL)
                    } else {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts,sorting: Sorting.CHRONOLOGICAL)
                    }
                }
                
                // Filter for multiple series of the same name
                var mediaList = [MediaItem]()
                
                if mediaItemParts?.count > 1 {
                    var number = 0
                    
                    for mediaItem in mediaItemParts! {
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
        
        if hasSpeaker {
            array.append(speaker!)
        }
        
        if hasMultipleParts {
            array.append(multiPartName!)
        } else {
            array.append(title!)
        }
        
        if books != nil {
            array.append(contentsOf: books!)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if tagsArray != nil {
            for tag in tagsArray! {
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
        
        if books != nil {
            set = set.union(Set(books!))
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
        var mediaItems:[MediaItem]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            mediaItems = globals.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL? {
        get {
            var url:URL?
            
            switch playing! {
            case Playing.audio:
                url = audioFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = audioURL
                }
                break
                
            case Playing.video:
                url = videoFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = videoURL
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
            if (dict![Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict![Field.playing] = playing
                } else {
                    dict![Field.playing] = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                }
            }
            
            if !hasAudio && (dict![Field.playing] == Playing.audio) {
                dict![Field.playing] = hasVideo ? Playing.video : nil
            }

            if !hasVideo && (dict![Field.playing] == Playing.video) {
                dict![Field.playing] = hasAudio ? Playing.video : nil
            }
            
            return dict![Field.playing]
        }
        
        set {
            if newValue != dict![Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict![Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var wasShowing:String? = Showing.slides //This is an arbitrary choice
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict![Field.showing] = showing
                } else {
                    if (hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.notes
                    }
                    if (hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.none
                    }
                }
            }
            return dict![Field.showing]
        }
        
        set {
            if newValue != Showing.video {
                wasShowing = newValue
            }
            dict![Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var download:Download? {
        get {
            if showing != nil {
                return downloads[showing!]
            } else {
                return nil
            }
        }
    }
    
    var atEnd:Bool {
        get {
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] {
                dict![Constants.SETTINGS.AT_END+playing!] = atEnd
            } else {
                dict![Constants.SETTINGS.AT_END+playing!] = "NO"
            }
            return dict![Constants.SETTINGS.AT_END+playing!] == "YES"
        }
        
        set {
            dict![Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
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
    
    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (Float(currentTime!) != nil)
    }
    
    var currentTime:String? {
        get {
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = current_time
            } else {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = "\(0)"
            }
//            print(dict![Constants.SETTINGS.CURRENT_TIME+playing!])
            return dict![Constants.SETTINGS.CURRENT_TIME+playing!]
        }
        
        set {
            dict![Constants.SETTINGS.CURRENT_TIME+playing!] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] = newValue 
            }
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName!
            } else {
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if (fullDate != nil) {
                return (Calendar.current as NSCalendar).components(.year, from: fullDate!).year
            }
            return nil
        }
    }
    
    var yearSection:String!
    {
        get {
            return yearString
        }
    }
    
    var yearString:String! {
        get {
            if (year != nil) {
                return "\(year!)"
            } else {
                return "None"
            }
        }
    }

    func singleJSONFromURL() -> JSON
    {
        do {
            let data = try Data(contentsOf: URL(string: Constants.JSON.URL.SINGLE + self.id!)!) // , options: NSData.ReadingOptions.mappedIfSafe
            
            let json = JSON(data: data)
            if json != JSON.null {
                
//                print(json)
                
                return json
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
    func loadSingleDict() -> [String:String]?
    {
        var mediaItemDicts = [[String:String]]()
        
        let json = singleJSONFromURL() // jsonDataFromDocumentsDirectory()
        
        if json != JSON.null {
            print("single json:\(json)")
            
            let mediaItems = json[Constants.JSON.ARRAY_KEY.SINGLE_ENTRY]
            
            for i in 0..<mediaItems.count {
                
                var dict = [String:String]()
                
                for (key,value) in mediaItems[i] {
                    dict["\(key)"] = "\(value)"
                }
                
                mediaItemDicts.append(dict)
            }
            
//            print(mediaItemDicts)
            
            return mediaItemDicts.count > 0 ? mediaItemDicts[0] : nil
        } else {
            print("could not get json from URL, make sure that URL contains valid json.")
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
        
        guard (dict![Field.notes_HTML] == nil) else {
            return
        }
        
        if let mediaItemDict = self.loadSingleDict() {
            if var notesHTML = mediaItemDict[Field.notes_HTML] {
                notesHTML = notesHTML.replacingOccurrences(of: "&rsquo;", with: "'")
                notesHTML = notesHTML.replacingOccurrences(of: "&rdquo;", with: "\"")
                notesHTML = notesHTML.replacingOccurrences(of: "&lsquo;", with: "'")
                notesHTML = notesHTML.replacingOccurrences(of: "&ldquo;", with: "\"")
                
                dict![Field.notes_HTML] = notesHTML
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

        notesTokens = tokensAndCountsFromString(stripHTML(notesHTML))
    }
    
    func formatDate(_ format:String?) -> String? {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(for: fullDate)
    }
    
    var formattedDate:String? {
        get {
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String? {
        get {
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String? {
        get {
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String? {
        get {
            return formatDate("yyyy")
        }
    }
    
    var date:String? {
        get {
            return dict![Field.date]?.substring(to: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.lowerBound) // last two characters // dict![Field.title]
        }
    }
    
    var service:String? {
        get {
            return dict![Field.date]?.substring(from: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.upperBound) // last two characters // dict![Field.title]
        }
    }
    
    var title:String? {
        get {
            return dict![Field.title]
        }
    }
    
    var category:String? {
        get {
            return dict![Field.category]
        }
    }
    
    var scriptureReference:String? {
        get {
            return dict![Field.scripture]
        }
    }
    
    lazy var scripture:Scripture? = {
        [unowned self] in
        return Scripture(reference:self.scriptureReference)
    }()
    
    var classSectionSort:String! {
        get {
            return classSection.lowercased()
        }
    }
    
    var classSection:String! {
        get {
            return hasClassName ? className! : Constants.None
        }
    }
    
    var className:String? {
        get {
            return dict![Field.className]
        }
    }
    
    var eventSectionSort:String! {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String! {
        get {
            return hasEventName ? eventName! : Constants.None
        }
    }
    
    var eventName:String? {
        get {
            return dict![Field.eventName]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return speakerSort!.lowercased()
        }
    }
    
    var speakerSection:String! {
        get {
            return hasSpeaker ? speaker! : Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict![Field.speaker]
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict![Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict![Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if hasSpeaker {
                        if !speaker!.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = (speakerSort != nil) ? speakerSort! + "," + firstName : firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
//                    print(speaker)
//                    print(speakerSort)
                    
                    dict![Field.speaker_sort] = speakerSort != nil ? speakerSort : Constants.None
                }
            }

            return dict![Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            return hasMultipleParts ? multiPartSort!.lowercased() : stringWithoutPrefixes(title)!.lowercased() // Constants.Individual_Media
        }
    }
    
    var multiPartSection:String! {
        get {
            return hasMultipleParts ? multiPartName! : title! // Constants.Individual_Media
        }
    }
    
    // this saves calculated values in defaults between sessions
    var multiPartSort:String? {
        get {
            if dict![Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict![Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict![Field.multi_part_name_sort] = multiPartSort
//                        settings?[Field.series_sort] = multiPartSort
                    } else {
//                        print("multiPartSort is nil")
                    }
                }
            }
            return dict![Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        get {
            if (dict![Field.multi_part_name] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let seriesString = title!.substring(to: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.lowerBound)!).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    dict![Field.multi_part_name] = seriesString
                }
            }
            
            return dict![Field.multi_part_name]
        }
    }
    
    var part:String? {
        get {
            if hasMultipleParts && (dict![Field.part] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let partString = title!.substring(from: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.upperBound)!)
//                    print(partString)
                    dict![Field.part] = partString.substring(to: partString.range(of: ")")!.lowerBound)
                }
            }
            
//            print(dict![Field.part])
            return dict![Field.part]
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
                        let range = possibleTag.range(of: "-")
                        
                        let candidate = possibleTag.substring(to: range!.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if (Int(candidate) == nil) && !tags.contains(candidate) {
                            if let count = possibleTags[candidate] {
                                possibleTags[candidate] =  count + 1
                            } else {
                                possibleTags[candidate] =  1
                            }
                        }
                        
                        possibleTag = possibleTag.substring(from: range!.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
        
        let proposedTags:[String] = possibleTags.keys.map { (string:String) -> String in
            return string
        }
        return proposedTags.count > 0 ? tagsArrayToTagsString(proposedTags) : nil
    }
    
    var dynamicTags:String? {
        get {
            var dynamicTags:String?
            
            if hasClassName {
                dynamicTags = dynamicTags != nil ? dynamicTags! + "|" + className! : className!
            }
            
            if hasEventName {
                dynamicTags = dynamicTags != nil ? dynamicTags! + "|" + eventName! : eventName!
            }
            
            return dynamicTags
        }
    }
    
    var constantTags:String? {
        get {
            var constantTags:String?
            
            if hasSlides {
                constantTags = constantTags != nil ? constantTags! + "|" + Constants.Slides : Constants.Slides
            }
            
            if hasNotes {
                constantTags = constantTags != nil ? constantTags! + "|" + Constants.Transcript : Constants.Transcript
            }
            
            if hasNotesHTML {
                constantTags = constantTags != nil ? constantTags! + "|" + Constants.Lexicon : Constants.Lexicon
            }
            
            if hasVideo {
                constantTags = constantTags != nil ? constantTags! + "|" + Constants.Video : Constants.Video
            }

            return constantTags
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            let jsonTags = dict?[Field.tags]
            
            let savedTags = mediaItemSettings?[Field.tags]
            
            //                if let books = self.books {
            //                    for book in books {
            //                        tags = tags != nil ? tags! + "|Book:" + book : "Book:" + book
            //                    }
            //                }
//            if dict![Field.tags] == nil {
//                
//                
//                dict![Field.tags] = savedTags != nil ? savedTags! + (dynamicTags != nil ? "|" + dynamicTags! : "") : dynamicTags
//            }
            
            var tags:String?

            tags = tags != nil ? tags! + (jsonTags != nil ? "|" + jsonTags! : "") : (jsonTags != nil ? jsonTags : nil)
            
            tags = tags != nil ? tags! + (savedTags != nil ? "|" + savedTags! : "") : (savedTags != nil ? savedTags : nil)
            
            tags = tags != nil ? tags! + (dynamicTags != nil ? "|" + dynamicTags! : "") : (dynamicTags != nil ? dynamicTags : nil)
            
            tags = tags != nil ? tags! + (constantTags != nil ? "|" + constantTags! : "") : (constantTags != nil ? constantTags : nil)
            
            if let proposedTags = proposedTags(jsonTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(savedTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(dynamicTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
//            print(tags)
            
            return tags
        }
//        set {
//            var tag:String
//            var tags = newValue
//            var tagsSet = Set<String>()
//            
//            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
//                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
//                tagsSet.insert(tag)
//                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
//            }
//            
//            if (tags != nil) {
//                tagsSet.insert(tags!)
//            }

//            settings?[Field.tags] = newValue
//            dict![Field.tags] = newValue
//        }
    }
    
    func addTag(_ tag:String)
    {
        let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
        
//        print(tags)
        
        if tags?.index(of: tag) == nil {
            if (mediaItemSettings?[Field.tags] == nil) {
                mediaItemSettings?[Field.tags] = tag
            } else {
                mediaItemSettings?[Field.tags] = mediaItemSettings![Field.tags]! + Constants.TAGS_SEPARATOR + tag
            }
            
//            let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
//            print(tags)

            let sortTag = stringWithoutPrefixes(tag)
            
            if globals.media.all!.tagMediaItems![sortTag!] != nil {
                if globals.media.all!.tagMediaItems![sortTag!]!.index(of: self) == nil {
                    globals.media.all!.tagMediaItems![sortTag!]!.append(self)
                    globals.media.all!.tagNames![sortTag!] = tag
                }
            } else {
                globals.media.all!.tagMediaItems![sortTag!] = [self]
                globals.media.all!.tagNames![sortTag!] = tag
            }
            
            if (globals.media.tags.selected == tag) {
                globals.media.tagged[globals.media.tags.selected!] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                })
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            }
        }
    }
    
    func removeTag(_ tag:String)
    {
        if (mediaItemSettings?[Field.tags] != nil) {
            var tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
            
//            print(tags)
            
            while tags?.index(of: tag) != nil {
                tags?.remove(at: tags!.index(of: tag)!)
            }
            
//            print(tags)
            
            mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
            
            let sortTag = stringWithoutPrefixes(tag)
            
            if let index = globals.media.all?.tagMediaItems?[sortTag!]?.index(of: self) {
                globals.media.all?.tagMediaItems?[sortTag!]?.remove(at: index)
            }
            
            if globals.media.all?.tagMediaItems?[sortTag!]?.count == 0 {
                _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag!)
            }
            
            if (globals.media.tags.selected == tag) {
                globals.media.tagged[globals.media.tags.selected!] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                })
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            }
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        var tags:String?
        
        if tagsSet != nil {
            for tag in tagsSet! {
                if tags == nil {
                    tags = tag
                } else {
                    tags = tags! + Constants.TAGS_SEPARATOR + tag
                }
            }
        }
        
        return tags
    }
    
    func tagsToSet(_ tags:String?) -> Set<String>?
    {
        guard var tags = tags else {
            return nil
        }
        
        var tag:String
        var tagsSet = Set<String>()
        
        while (tags.range(of: Constants.TAGS_SEPARATOR) != nil) {
            tag = tags.substring(to: tags.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
            tagsSet.insert(tag)
            tags = tags.substring(from: tags.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
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
            return tagsSet == nil ? nil : Array(tagsSet!).sorted() {
//                let range0 = $0.range(of: "Book:")
//                let range1 = $1.range(of: "Book:")
//                
//                if (range0 != nil) && (range1 != nil) {
//                    return bookNumberInBible($0.substring(from: range0!.upperBound)) < bookNumberInBible($1.substring(from: range1!.upperBound))
//                } else {
                    return $0 < $1
//                }
            }
        }
    }
    
    //    Slides: Constants.BASE_MEDIA_URL+{year}/{mediacode}slides.pdf
    //    Outline: Constants.BASE_MEDIA_URL+{year}/{mediacode}outline.pdf
    //    Transcript: Constants.BASE_MEDIA_URL+{year}/{mediacode}transcript.pdf

    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio {
                dict![Field.audio] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Constants.FILENAME_EXTENSION.MP3
            }
            
//            print(dict![Field.audio])
            
            return dict![Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict![Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict![Field.m3u8]
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
            
            guard video != nil else {
                return nil
            }
            
            guard video!.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = video?.substring(from: Constants.BASE_URL.VIDEO_PREFIX.endIndex)
//            print(tail)
            
            let id = tail?.substring(to: tail!.range(of: ".m")!.lowerBound)
//            print(id)

            return id
        }
    }
    
    var externalVideo:String? {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    var notes:String? {
        get {
            if (dict![Field.notes] == nil) && hasNotes { // \(year!)
                dict![Field.notes] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }

            //            print(dict![Field.notes])
            return dict![Field.notes]
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
        
        if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
            // If we pull this with a different wholeWordsOnly than before we'll get the wrong answer...so don't reuse it.
//            if searchMarkedFullNotesHTML?[searchText] != nil {
//                return searchMarkedFullNotesHTML?[searchText]
//            }
        } else {
            let string = "No Occurrences of \"\(searchText!)\" were found.<br/>"
            
            if let newString = fullNotesHTML?.replacingOccurrences(of: "<body>", with: "<body>" + string) {
                return newString
            } else {
                return nil
            }
        }

        var markCounter = 0

        func mark(_ input:String) -> String
        {
            var string = input

            var stringBefore:String = Constants.EMPTY_STRING
            var stringAfter:String = Constants.EMPTY_STRING
            var newString:String = Constants.EMPTY_STRING
            var foundString:String = Constants.EMPTY_STRING

            while (string.lowercased().range(of: searchText!.lowercased()) != nil) {
                //                print(string)
                
                if let range = string.lowercased().range(of: searchText!.lowercased()) {
                    stringBefore = string.substring(to: range.lowerBound)
                    stringAfter = string.substring(from: range.upperBound)
                    
                    var skip = false
                    
                    let tokenDelimiters = "$\"' :-!;,.()?&/<>[]"
                    
                    if wholeWordsOnly {
                        if let characterAfter:Character = stringAfter.characters.first {
                            if !CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterAfter))!) {
                                skip = true
                            }
                        }
                        if let characterBefore:Character = stringBefore.characters.last {
                            if !CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterBefore))!) {
                                skip = true
                            }
                        }
                    }

                    foundString = string.substring(from: range.lowerBound)
                    let newRange = foundString.lowercased().range(of: searchText!.lowercased())
                    foundString = foundString.substring(to: newRange!.upperBound)

                    if !skip {
                        markCounter += 1
                        foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                    }

                    newString = newString + stringBefore + foundString
                    
                    stringBefore = stringBefore + foundString
                    
                    string = stringAfter
                } else {
                    break
                }
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }

        var newString:String = Constants.EMPTY_STRING
        var string:String = notesHTML! // stripHead(fullNotesHTML)!
        
        while let searchRange = string.range(of: "<") {
            let searchString = string.substring(to: searchRange.lowerBound)
//            print(searchString)
            
            // mark search string
            newString = newString + mark(searchString)
            
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
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText!)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText!)\" were found.<br/>"
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
            
//            newString = newString.replacingOccurrences(of: "<body>", with: "<body>"+indexString)
        }
        
//        newString = newString + stringAfter
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if index {
            htmlString = htmlString + indexString
        }

        htmlString = htmlString + headerHTML! + newString + "</body></html>"

        searchMarkedFullNotesHTML?[searchText] = insertHead(htmlString,fontSize: Constants.FONT_SIZE) // insertHead(newString,fontSize: Constants.FONT_SIZE)
        
        return searchMarkedFullNotesHTML?[searchText]
    }
    
    var headerHTML:String? {
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
            header = header + "Available online at <a href=\"\(websiteURL!)\">www.countrysidebible.org</a></br>"
            
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
            guard (notesHTML != nil) else {
                return nil
            }

            return insertHead("<!DOCTYPE html><html><body>" + headerHTML! + notesHTML! + "</body></html>",fontSize: Constants.FONT_SIZE)
        }
    }
    
    var notesHTML:String? {
        get {
            //            print(dict![Field.notes])
            return dict![Field.notes_HTML]
        }
        set {
            dict![Field.notes_HTML] = newValue
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if (dict![Field.slides] == nil) && hasSlides { // \(year!)
                dict![Field.slides] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }

            return dict![Field.slides]
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String? {
        get {
            if (dict![Field.outline] == nil) && hasSlides { // \(year!)
                dict![Field.outline] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.outline + Constants.FILENAME_EXTENSION.PDF
            }
            
            return dict![Field.outline]
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict![Field.files]
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
//            print(audio)
            return audio != nil ? URL(string: audio!) : nil
        }
    }
    
    var videoURL:URL? {
        get {
            return video != nil ? URL(string: video!) : nil
        }
    }
    
    var notesURL:URL? {
        get {
//            print(notes)
            return notes != nil ? URL(string: notes!) : nil
        }
    }
    
    var slidesURL:URL? {
        get {
//            print(slides)
            return slides != nil ? URL(string: slides!) : nil
        }
    }
    
    var outlineURL:URL? {
        get {
//            print(outline)
            return outline != nil ? URL(string: outline!) : nil
        }
    }
    
    var audioFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP3)
        }
    }
    
    var mp4FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP4)
        }
    }
    
    var m3u8FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.M3U8)
        }
    }
    
    var videoFileSystemURL:URL? {
        get {
            return m3u8FileSystemURL
        }
    }
    
    var slidesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.slides + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var notesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.notes + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var outlineFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.outline + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var bookSections:[String]
    {
        get {
            if books == nil {
//                print(scripture)
//                if hasScripture {
//                    print([scripture!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)])
//                } else {
//                    print([Constants.None])
//                }
            }
            return books != nil ? books! : (hasScripture ? [scriptureReference!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)] : [Constants.None])
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
        
//        print(scripture!)
        
        let booksAndChaptersAndVerses = BooksChaptersVerses()
        
        let books = booksFromScriptureReference(scriptureReference)
        
        guard (books != nil) else {
            return nil
        }

        var scriptures = [String]()
        
        var string = scriptureReference!
        
        let separator = ";"
        
        while (string.range(of: separator) != nil) {
            scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
            string = string.substring(from: string.range(of: separator)!.upperBound)
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
        guard !Constants.NO_CHAPTER_BOOKS.contains(thisBook) else {
            return [1]
        }
        
        var chaptersForBook:[Int]?
        
        let books = booksFromScriptureReference(scriptureReference)
        
        guard (books != nil) else {
            return nil
        }

        switch books!.count {
        case 0:
            break
            
        case 1:
            if thisBook == books!.first {
                if Constants.NO_CHAPTER_BOOKS.contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scriptureReference!
                    
                    if (string.range(of: ";") == nil) {
                        chaptersForBook = chaptersFromScriptureReference(string.substring(from: scriptureReference!.range(of: thisBook)!.upperBound))
                    } else {
                        while (string.range(of: ";") != nil) {
                            var subString = string.substring(to: string.range(of: ";")!.lowerBound)
                            
                            if (subString.range(of: thisBook) != nil) {
                                subString = subString.substring(from: subString.range(of: thisBook)!.upperBound)
                            }
                            if let chapters = chaptersFromScriptureReference(subString) {
                                chaptersForBook?.append(contentsOf: chapters)
                            }
                            
                            string = string.substring(from: string.range(of: ";")!.upperBound)
                        }
                        
                        //                        print(string)
                        if (string.range(of: thisBook) != nil) {
                            string = string.substring(from: string.range(of: thisBook)!.upperBound)
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
            
            var string = scriptureReference!
            
            let separator = ";"
            
            while (string.range(of: separator) != nil) {
                scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                string = string.substring(from: string.range(of: separator)!.upperBound)
            }
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if (scripture.range(of: thisBook) != nil) {
                    if let chapters = chaptersFromScriptureReference(scripture.substring(from: scripture.range(of: thisBook)!.upperBound)) {
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
    } //Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if (self.hasDate()) {
            return Date(dateString:self.date!)
        } else {
            return nil
        }
    }()//Derived from date
    
    var contents:String? {
        get {
            return stripHTML(bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs: false, includeColumns: false))

            // Don't need these now that there is a web page for each sermon.
            //    if let audioURL = mediaItem?.audioURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + audioURL + "\">Audio</a>)"
            //    }
            //
            //    if let externalVideo = mediaItem?.externalVideo {
            //        bodyString = bodyString! + " (<a href=\"" + externalVideo + "\">Video</a>) "
            //    }
            //
            //    if let slidesURL = mediaItem?.slidesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + slidesURL + "\">Slides</a>)"
            //    }
            //
            //    if let notesURL = mediaItem?.notesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + notesURL + "\">Transcript</a>) "
            //    }
        }
    }

    var contentsHTML:String? {
        get {
            var bodyString = "<!DOCTYPE html><html><body>"
            
            if let string = bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs: true, includeColumns: true) {
                bodyString = bodyString + string
            }
            
            // Don't need these now that there is a web page for each sermon.
            //    if let audioURL = mediaItem?.audioURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + audioURL + "\">Audio</a>)"
            //    }
            //
            //    if let externalVideo = mediaItem?.externalVideo {
            //        bodyString = bodyString! + " (<a href=\"" + externalVideo + "\">Video</a>) "
            //    }
            //
            //    if let slidesURL = mediaItem?.slidesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + slidesURL + "\">Slides</a>)"
            //    }
            //
            //    if let notesURL = mediaItem?.notesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + notesURL + "\">Transcript</a>) "
            //    }
            
            bodyString = bodyString + "</body></htm>"
            
            return bodyString
        }
    }
    
    func bodyHTML(order:[String],token: String?,includeURLs:Bool,includeColumns:Bool) -> String?
    {
        var bodyString:String?
        
        if includeColumns {
            bodyString = "<tr>"
            
            for item in order {
                switch item.lowercased() {
                case "date":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let month = formattedDateMonth {
                        bodyString = bodyString! + month
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"baseline\" align=\"right\">"
                    if let day = formattedDateDay {
                        bodyString  = bodyString! + day + ","
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"baseline\" align=\"right\">"
                    if let year = formattedDateYear {
                        bodyString  = bodyString! + year
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let service = self.service {
                        bodyString  = bodyString! + service
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "title":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            bodyString = bodyString! + "<a href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = bodyString! + title
                        }
                    }
                    bodyString = bodyString! + "</td>"
                    break

                case "scripture":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let scriptureReference = self.scriptureReference {
                        bodyString = bodyString! + scriptureReference
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "speaker":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let speaker = self.speaker {
                        bodyString = bodyString! + speaker
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "class":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let className = self.className {
                        bodyString = bodyString! + className
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "event":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
                    if let eventName = self.eventName {
                        bodyString = bodyString! + eventName
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "count":
                    bodyString = bodyString! + "<td valign=\"baseline\">"
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
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + title
                        }
                    }
                    break

                case "scripture":
                    if let scriptureReference = self.scriptureReference {
                        bodyString  = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + scriptureReference
                    }
                    break
                    
                case "speaker":
                    if let speaker = self.speaker {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + speaker
                    }
                    break
                    
                case "class":
                    if let className = self.className {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + className
                    }
                    break
                    
                case "event":
                    if let eventName = self.eventName {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + eventName
                    }
                    break
                    
                case "count":
                    if let token = token, let count = self.notesTokens?[token] {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + "(\(count))"
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
            var string:String?
            
            if hasDate() {
                string = formattedDate
            } else {
                string = "No Date"
            }
            
            if let service = service {
                string = string! + " \(service)"
            }
            
            if let speaker = speaker {
                string = string! + " \(speaker)"
            }
            
            if hasTitle() {
                if (title!.range(of: " (Part ") != nil) {
                    let first = title!.substring(to: (title!.range(of: " (Part")?.upperBound)!)
                    let second = title!.substring(from: (title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture {
                string = string! + "\n\(scriptureReference!)"
            }
            
            if hasClassName {
                string = string! + "\n\(className!)"
            }
            
            if hasEventName {
                string = string! + "\n\(eventName!)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var mediaItemString = "MediaItem: "
        
        if (category != nil) {
            mediaItemString = "\(mediaItemString) \(category!)"
        }
        
        if (id != nil) {
            mediaItemString = "\(mediaItemString) \(id!)"
        }
        
        if (date != nil) {
            mediaItemString = "\(mediaItemString) \(date!)"
        }
        
        if (service != nil) {
            mediaItemString = "\(mediaItemString) \(service!)"
        }
        
        if (title != nil) {
            mediaItemString = "\(mediaItemString) \(title!)"
        }
        
        if (scripture != nil) {
            mediaItemString = "\(mediaItemString) \(scripture!)"
        }
        
        if (speaker != nil) {
            mediaItemString = "\(mediaItemString) \(speaker!)"
        }
        
        return mediaItemString
    }
    
    struct MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.mediaItemSettings?[mediaItem!.id]?[key]
            }
            set {
                if (mediaItem != nil) {
                    if globals.mediaItemSettings == nil {
                        globals.mediaItemSettings = [String:[String:String]]()
                    }
                    if (globals.mediaItemSettings != nil) {
                        if (globals.mediaItemSettings?[mediaItem!.id] == nil) {
                            globals.mediaItemSettings?[mediaItem!.id] = [String:String]()
                        }
                        if (globals.mediaItemSettings?[mediaItem!.id]?[key] != newValue) {
                            //                        print("\(mediaItem)")
                            globals.mediaItemSettings?[mediaItem!.id]?[key] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        print("globals.settings == nil in Settings!")
                    }
                } else {
                    print("mediaItem == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        [unowned self] in
        return MediaItemSettings(mediaItem:self)
    }()
    
    struct MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.multiPartSettings?[mediaItem!.seriesID]?[key]
            }
            set {
                guard (mediaItem != nil) else {
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
                
                if (globals.multiPartSettings?[mediaItem!.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem!.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem!.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem!.seriesID]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    globals.saveSettingsBackground()
                }
            }
        }
    }
    
    lazy var multiPartSettings:MultiPartSettings? = {
        [unowned self] in
        return MultiPartSettings(mediaItem:self)
    }()
    
    var viewSplit:String? {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var slideSplit:String? {
        get {
            return multiPartSettings?[Constants.SLIDE_SPLIT]
        }
        set {
            multiPartSettings?[Constants.SLIDE_SPLIT] = newValue
        }
    }
    
    func hasDate() -> Bool
    {
        return (date != nil) && (date != Constants.EMPTY_STRING)
    }
    
    func hasTitle() -> Bool
    {
        return (title != nil) && (title != Constants.EMPTY_STRING)
    }
    
//    func hasAudio() -> Bool
//    {
//        return (audio != nil) && (audio != Constants.EMPTY_STRING)
//    }
    
    func playingAudio() -> Bool
    {
        return (playing == Playing.audio)
    }
    
//    func hasVideo() -> Bool
//    {
//        return (video != nil) && (video != Constants.EMPTY_STRING)
//    }
    
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
            guard let isEmpty = scriptureReference?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.scriptureReference != nil) && (self.scriptureReference != Constants.EMPTY_STRING)
        }
    }
    
    var hasClassName:Bool
        {
        get {
            guard let isEmpty = className?.isEmpty else {
                return false
            }
            
            return !isEmpty
            //            return (self.className != nil) && (self.className != Constants.EMPTY_STRING)
        }
    }
    
    var hasEventName:Bool
        {
        get {
            guard let isEmpty = eventName?.isEmpty else {
                return false
            }
            
            return !isEmpty
            //            return (self.eventName != nil) && (self.eventName != Constants.EMPTY_STRING)
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            guard let isEmpty = multiPartName?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.multiPartName != nil) && (self.multiPartName != Constants.EMPTY_STRING)
        }
    }
    
    var hasCategory:Bool
        {
        get {
            guard let isEmpty = category?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.category != nil) && (self.category != Constants.EMPTY_STRING)
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
            guard let isEmpty = speaker?.isEmpty else {
                return false
            }
            
            if isEmpty {
                print("speaker is empty")
            }
            
            return !isEmpty
//            return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
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
        if !hasNotes { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: notesURL!)) != nil) {
//                notes = testNotes
                print("Transcript DOES exist for: \(title!)")
            }
        }
        
        return hasNotes
    }
    
    func hasNotes(_ check:Bool) -> Bool
    {
        return check ? checkNotes() : hasNotes
    }
    
    func checkSlides() -> Bool
    {
        if !hasSlides { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: slidesURL!)) != nil) {
//                slides = testSlides
                print("Slides DO exist for: \(title!)")
            } else {
                
            }
        }
        
        return hasSlides
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
//            return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            return hasTags ? tagsSet!.contains(Constants.Favorites) : false
        }
    }
}
