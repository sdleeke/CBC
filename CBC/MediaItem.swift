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

/**
 Handle settings for mediaItems that are parts of a sequence
 */
class MultiPartSettings
{
    private weak var mediaItem:MediaItem?
    
    init(mediaItem:MediaItem?) {
        if (mediaItem == nil) {
            print("nil mediaItem in Settings init!")
        }
        self.mediaItem = mediaItem
    }
    
    deinit {
        debug(self)
    }
    
    subscript(key:String) -> String?
    {
        get {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in SeriesSettings!")
                return nil
            }
            
            return Globals.shared.multiPartSettings[mediaItem.seriesID,key]
        }
        set {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in SeriesSettings!")
                return
            }
            
            if (Globals.shared.multiPartSettings[mediaItem.seriesID,key] != newValue) {
                //                        print("\(mediaItem)")
                Globals.shared.multiPartSettings[mediaItem.seriesID,key] = newValue
                
                // For a high volume of activity this can be very expensive.
                Globals.shared.saveSettingsBackground()
            }
        }
    }
}

/**
 Handle settings for a mediaItem
 */
class MediaItemSettings
{
    private weak var mediaItem:MediaItem?
    
    init(mediaItem:MediaItem?) {
        if (mediaItem == nil) {
            print("nil mediaItem in Settings init!")
        }
        self.mediaItem = mediaItem
    }
    
    deinit {
        debug(self)
    }
    
    subscript(key:String) -> String?
    {
        get {
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard mediaItem.mediaCode != nil else {
                return nil
            }
            
            return Globals.shared.mediaItemSettings[mediaItem.mediaCode,key]
        }
        set {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in Settings!")
                return
            }
            
            guard mediaItem.mediaCode != nil else {
                print("mediaItem.mediaCode == nil in Settings!")
                return
            }
            
            if (Globals.shared.mediaItemSettings[mediaItem.mediaCode,key] != newValue) {
                //                        print("\(mediaItem)")
                Globals.shared.mediaItemSettings[mediaItem.mediaCode,key] = newValue
                
                // For a high volume of activity this can be very expensive.
                Globals.shared.saveSettingsBackground()
            }
        }
    }
}

extension MediaItem : UIActivityItemSource
{
    func share(viewController:UIViewController)
    {
        guard let html = Globals.shared.media.multiPartMediaItems(self)?.html() else {
            return
        }
        
        let print = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = CBCActivityViewController(activityItems:[self,print] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.

        activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem

        // present the view controller
        Alerts.shared.blockPresent(presenting: viewController, presented: activityViewController, animated: true)
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        guard let text = self.text else {
            return nil
        }
        
        guard let html = Globals.shared.media.multiPartMediaItems(self)?.html() else {
            return nil
        }
        
        if activityType == UIActivity.ActivityType.mail {
            return html
        } else if activityType == UIActivity.ActivityType.print {
            return html
        }

        var string : String!
        
        if let path = self.websiteURL?.absoluteString {
            string = text + "\n\n" + path
        } else {
            string = text
        }

        return string
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return self.text?.singleLine ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        if activityType == UIActivity.ActivityType.mail {
            return "public.text"
        } else if activityType == UIActivity.ActivityType.print {
            return "public.text"
        }
        
        return "public.plain-text"
    }
}

// Must be @objc funcs but Swift doesn't allow that declaration here.
//protocol Downloader
//{
//    func downloaded(_ notification : NSNotification)
//    func downloadFailed(_ notification : NSNotification)
//}

/**
 Handles everything to do with an individual mediaItem
 */
class MediaItem : NSObject //, Downloader
{
    var percentComplete = [String:Double]()
    {
        didSet {
            if percentComplete != oldValue {
                Thread.onMain {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PERCENT_COMPLETE), object: self)
                }
            }
        }
    }
    
    var _multiPartMediaItems:[MediaItem?]?
    {
        didSet {
            
        }
    }
    var multiPartMediaItems:[MediaItem?]?
    {
        get {
            guard hasMultipleParts else {
                return [self]
            }
            
            guard _multiPartMediaItems == nil else {
                return _multiPartMediaItems
            }
            
            var mediaItemParts:[MediaItem]?
            
            if let multiPartSort = multiPartSort, (Globals.shared.media.all?.groupSort?[GROUPING.TITLE,multiPartSort,SORTING.CHRONOLOGICAL] == nil) { // ]?[
                mediaItemParts = Globals.shared.media.repository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                    if testMediaItem.hasMultipleParts {
                        return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                    } else {
                        return false
                    }
                })
            } else {
                if let multiPartSort = multiPartSort {
                    mediaItemParts = Globals.shared.media.all?.groupSort?[GROUPING.TITLE,multiPartSort,SORTING.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in // ]?[
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })
                }
            }
            
            // Filter for conference series
            
            // Second sort by title is necessary if they all fall on the same day!
            if conferenceCode != nil {
                mediaItemParts = mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return testMediaItem.conferenceCode == conferenceCode
                }).sortByYear(sorting: SORTING.CHRONOLOGICAL)?.sorted(by: { (first, second) -> Bool in
                    first.title?.withoutPrefixes < second.title?.withoutPrefixes
                })
            } else {
                if hasClassName {
                    mediaItemParts = mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.className == className
                    }).sortByYear(sorting: SORTING.CHRONOLOGICAL)?.sorted(by: { (first, second) -> Bool in
                        first.title?.withoutPrefixes < second.title?.withoutPrefixes
                    })
                } else {
                    mediaItemParts = mediaItemParts?.sortByYear(sorting: SORTING.CHRONOLOGICAL)?.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
                        // In case we have multiple parts on the same day, e.g. Tom's expository preaching seminars.
                        if first.date == second.date {
                            if let first = first.part, let second = second.part {
                                return first < second
                            }
                        }

                        return false
                    })
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
                
                _multiPartMediaItems = mediaList.count > 0 ? mediaList : nil
            } else {
                _multiPartMediaItems = mediaItemParts
            }
            
            return _multiPartMediaItems
        }
    }
    
    var notesName:String?
    {
        get {
            guard let category = category else {
                return nil
            }
            
            if category == "Sermons" {
                return Constants.Strings.Transcript
            } else {
                return Constants.Strings.Notes
            }
        }
    }
    
    var notesNames : String?
    {
        get {
            guard let category = category else {
                return nil
            }
            
            if category == "Sermons" {
                return Constants.Strings.Transcript + "s"
            } else {
                return Constants.Strings.Notes
            }
        }
    }
    
    lazy var documents : ThreadSafeDN<Document>! = { [weak self] in
        let documents = ThreadSafeDN<Document>(name:mediaCode+"Documents")
        
        if hasNotes {
            let document = Document(purpose: Purpose.notes, mediaItem: self)
            documents[mediaCode,Purpose.notes] = document
        }
        
        if hasOutline {
            let document = Document(purpose: Purpose.outline, mediaItem: self)
            documents[mediaCode,Purpose.outline] = document
        }
        
        if hasSlides {
            let document = Document(purpose: Purpose.slides, mediaItem: self)
            documents[mediaCode,Purpose.slides] = document
        }

        return documents
    }()
    
    var cacheSize : Int
    {
        get {
            guard let cachesURL = FileManager.default.cachesURL else {
                return 0
            }
            
            // without this autoreleasepool closure THIS IS A MASSIVE MEMORY LEAK
            return autoreleasepool {
                var totalCacheSize = 0
                
                // THIS IS COMPUTATIONALLY EXPENSIVE TO CALL
                cachesURL.files(startingWith:mediaCode,notOfType:Constants.FILENAME_EXTENSION.MP3)?.forEach({ (string:String) in
                    var fileURL = cachesURL
                    fileURL.appendPathComponent(string)
                    totalCacheSize += fileURL.fileSize ?? 0
                })
                
                return totalCacheSize
            }
        }
    }

    func cacheSize(_ purpose:String) -> Int
    {
        return downloads?[purpose]?.fileSize ?? 0
    }
    
    var hasCacheFiles : Bool
    {
        get {
            for fileType in Constants.cacheFileTypes {
                if (mediaCode + fileType).fileSystemURL?.exists ?? false {
                    return true
                }
            }
            
            return false
        }
    }
    
    func clearCache(block:Bool,completion:(()->())? = nil)
    {
        guard let mediaCode = mediaCode else {
            return
        }
        
        guard let cachesURL = FileManager.default.cachesURL else {
            return
        }
        
        // Really should delete anything that matches what comes before "." in lastPathComponent,
        // which in this case is id (which is mediaCode)
        // BUT all we're doing is looking for files that START with id, lots more could follow, not just "."
  
        try? autoreleasepool {
            let files = try FileManager.default.contentsOfDirectory(atPath: cachesURL.path)
            
            // It would be safer if our filenames had the APP_ID in them or we had our own folder in the caches directory
            // If some other app has files w/ these filename extensions (really just filenames that end with these strings)
            // in the cache, we will be deleting them.
            for file in files {
                for fileType in Constants.cacheFileTypes {
                    // This assumes all filename use a common patter: id + fileType
                    if file.isFileType(mediaCode + fileType) {
                        var fileURL = cachesURL
                        fileURL.appendPathComponent(file)
                        fileURL.delete(block: true)
                    }
                }
            }
        }
        
        completion?()
    }
    
    @objc func downloaded(_ notification : NSNotification)
    {
        guard let download = notification.object as? Download else {
            return
        }
        
        guard let purpose = download.purpose else {
            return
        }
        
        guard let mediaItem = download.mediaItem else {
            return
        }
        
        guard let document = mediaItem.documents[mediaItem.mediaCode,purpose] else {
            return
        }
        
        // fill cache
        document.fetchData.fill()
        
        Thread.onMain {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: download)
        }
    }
    
    @objc func downloadFailed(_ notification : NSNotification)
    {
        guard let download = notification.object as? Download else {
            return
        }
        
        Thread.onMain {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: download)
        }
    }
    
    func loadDocument(purpose:String)
    {
//        if documents?[mediaCode,purpose] == nil {
//            let document = Document(purpose: purpose, mediaItem: self)
//            documents?[mediaCode,purpose] = document
//        }

        guard let document = documents?[mediaCode,purpose] else {
            return
        }
        
        if Globals.shared.settings.cacheDownloads {
            guard document.download?.exists == true else {
                if document.download?.state != .downloading {
                    document.download?.download(background: false)
                }
                
                Thread.onMain {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloaded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: document.download)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: document.download)
                }
                return
            }
        }
        
        // fill cache
        document.fetchData.fill()
    }

    func loadDocuments()
    {
        // documents[mediaCode] doesn't work because it returns a Document not an Any.
        guard let documents = documents.storage[mediaCode] as? [String:Document] else {
            return
        }
        
        documents.keys.forEach { (purpose:String) in
            loadDocument(purpose: purpose)
        }
        
//        if hasNotes {
//            loadDocument(purpose: Purpose.notes)
//        }
//
//        if hasOutline {
//            loadDocument(purpose: Purpose.outline)
//        }
//
//        if hasSlides {
//            loadDocument(purpose: Purpose.slides)
//        }
    }
    
    static func ==(lhs: MediaItem, rhs: MediaItem) -> Bool
    {
        return lhs.mediaCode == rhs.mediaCode
    }
    
    var storage : ThreadSafeDN<Any>? = { // [String:String]? // ictionary
        return ThreadSafeDN<Any>() // Can't be id because that becomes recursive.
    }()
    
    subscript(key:String?) -> Any?
    {
        get {
            guard let key = key else {
                return nil
            }
            return storage?[key]
        }
        set {
            guard let key = key else {
                return
            }

            storage?[key] = newValue
        }
    }
    
    var singleLoaded = false

    @objc func freeMemory()
    {
        // What are the side effects of this?
        seriesImage?.clearImageCache()
        
        documents = ThreadSafeDN<Document>(name:mediaCode + "Documents") // ictionaryOfDictionaries

        notesHTML?.clear()
        notesTokens?.clear()
    }
    
    init(storage:[String:Any]?)
    {
        super.init()
        
        if let storage = storage {
            self.storage?.update(storage:storage)
        }
        
        Thread.onMain {
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    // Make thread safe?
    lazy var downloads:[String:Download]? = {
        var downloads = [String:Download]()

        if hasAudio {
            downloads[Purpose.audio] = audioDownload
        }

        if hasVideo {
            downloads[Purpose.video] = videoDownload
        }
        
        if hasSlides {
            downloads[Purpose.slides] = slidesDownload
        }
        
        if hasNotes {
            downloads[Purpose.notes] = notesDownload
        }
        
        if hasOutline {
            downloads[Purpose.outline] = outlineDownload
        }
        
        return downloads.count > 0 ? downloads : nil
    }()
    
    lazy var audioDownload:Download? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasAudio == true else {
            return nil
        }

        let download = Download(mediaItem:self,purpose:Purpose.audio,downloadURL:self?.audioURL?.url) // ,fileSystemURL:self.audioFileSystemURL
        // NEVER EVER set properties here unless you know the didSets not trigger bad behavior
        return download
    }()
    
    lazy var videoDownload:Download? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasVideo == true else {
            return nil
        }

        let download = Download(mediaItem:self,purpose:Purpose.video,downloadURL:self?.videoURL?.url) // ,fileSystemURL:self.videoFileSystemURL
        // NEVER EVER set properties here unless you know the didSets not trigger bad behavior
        return download
    }()
    
    lazy var slidesDownload:Download? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasSlides == true else {
            return nil
        }
        
        let download = Download(mediaItem:self,purpose:Purpose.slides,downloadURL:self?.slides?.url) // ,fileSystemURL:self.slidesFileSystemURL
        // NEVER EVER set properties here unless you know the didSets not trigger bad behavior
        return download
    }()
    
    lazy var notesDownload:Download? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasNotes == true else {
            return nil
        }
        
        let download = Download(mediaItem:self,purpose:Purpose.notes,downloadURL:self?.notes?.url) // ,fileSystemURL:self.notesFileSystemURL
        // NEVER EVER set properties here unless you know the didSets not trigger bad behavior
        return download
    }()
    
    lazy var outlineDownload:Download? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasOutline == true else {
            return nil
        }
        
        let download = Download(mediaItem:self,purpose:Purpose.outline,downloadURL:self?.outline?.url) // ,fileSystemURL:self.outlineFileSystemURL
        // NEVER EVER set properties here unless you know the didSets not trigger bad behavior
        return download
    }()
    
//    var id:String!
//    {
//        get {
//            // Potential crash if nil
//            return mediaCode
//        }
//    }
    
    var mediaCode:String!
    {
        get {
            // Potential crash if nil
            return self[Field.mediaCode] as? String
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in mediaCode {
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
            let afterClassCode = String(mediaCode[classCode.endIndex...])
            
            let ymd = "YYMMDD"
            
            let afterDate = String(afterClassCode[ymd.endIndex...])
            
            let code = String(afterDate[..<String.Index(utf16Offset: 1, in: afterDate)])
            
            return code
        }
    }
    
    var conferenceCode:String?
    {
        get {
            guard serviceCode == "s" else {
                return nil
            }

            let afterClassCode = String(mediaCode[classCode.endIndex...])
            
            var string = String(mediaCode[..<classCode.endIndex])
            
            let ymd = "YYMMDD"
            
            string += String(afterClassCode[..<ymd.endIndex])
            
            let s = "s"
            
            let code = string + s
            
            return code
        }
    }
    
    var repeatCode:String?
    {
        get {
            let afterClassCode = String(mediaCode[classCode.endIndex...])
            
            var string = String(mediaCode[..<classCode.endIndex])
            
            let ymd = "YYMMDD"
            
            string += String(afterClassCode[..<ymd.endIndex]) + serviceCode
            
            let code = String(mediaCode[string.endIndex...])
            
            if !code.isEmpty  {
                return code
            } else {
                return nil
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
        
        if let books = scripture?.books {
            array.append(contentsOf: books)
        }
        
        if let titleTokens = title?.tokens {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if let tagsArray = tagsArray {
            for tag in tagsArray {
                if let tokens = tag.tokens {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = speaker?.firstName {
                set.insert(firstname)
            }

            if let lastname = speaker?.lastName {
                set.insert(lastname)
            }
        }
        
        if let books = scripture?.books {
            set = set.union(Set(books))
        }
        
        if let titleTokens = title?.tokens {
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
        
    func searchNotes(_ searchText:String?) -> Bool
    {
        return SearchHit(self,searchText).transcript
    }

    func mediaItemsInCollection(_ tag:String) -> [MediaItem]?
    {
        guard let tagsSet = tagsSet else {
            return nil
        }
        
        guard tagsSet.contains(tag) else {
            return nil
        }
        
        return Globals.shared.media.all?.tagMediaItems?[tag]
    }

    var playingURL:URL?
    {
        get {
            var url:URL?

            guard let playing = playing else {
                return nil
            }

            switch playing {
            case Playing.audio:
                url = audioURL?.url
                if let path = audioFilename?.fileSystemURL?.path, FileManager.default.fileExists(atPath: path) {
                    url = audioFilename?.fileSystemURL
                }
                break
                
            case Playing.video:
                url = videoURL?.url
                if let path = videoFilename?.fileSystemURL?.path, FileManager.default.fileExists(atPath: path){
                    url = videoFilename?.fileSystemURL
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
            return (self == Globals.shared.mediaPlayer.mediaItem)
        }
    }
    
    var isLoaded:Bool {
        get {
            return isInMediaPlayer && Globals.shared.mediaPlayer.loaded
        }
    }
    
    var isPlaying:Bool {
        get {
            return Globals.shared.mediaPlayer.url == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String?
    {
        get {
            if (self[Field.playing] as? String == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    self[Field.playing] = playing
                } else {
                    // Avoid simultaneous read and write in dict.
                    let playing = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                    self[Field.playing] = playing

                    // this saves calculated values in defaults between sessions
                    mediaItemSettings?[Field.playing] = playing
                }
            }

            // ERROR CHECKING
            if !hasAudio && (self[Field.playing] as? String == Playing.audio) {
                // Avoid simultaneous read and write in dict.
                let playing = hasVideo ? Playing.video : nil
                self[Field.playing] = playing

                // this saves calculated values in defaults between sessions
                mediaItemSettings?[Field.playing] = playing
            }

            // ERROR CHECKING
            if !hasVideo && (self[Field.playing] as? String == Playing.video) {
                // Avoid simultaneous read and write in dict.
                let playing = hasAudio ? Playing.audio : nil
                self[Field.playing] = playing

                // this saves calculated values in defaults between sessions
                mediaItemSettings?[Field.playing] = playing
            }
            
            // Is this ever nil?  Unless it doesn't have audio AND it doesn't have video it is ALWAYS one or the other.
            return self[Field.playing] as? String
        }
        
        set {
            if newValue != self[Field.playing] as? String {
                //Changing audio to video or vice versa clears the mediaItem in the player, which is what stop does vs. pause
                //(which also resets the state and time).
                if Globals.shared.mediaPlayer.mediaItem == self {
                    Globals.shared.mediaPlayer.stop()
                }
                
                self[Field.playing] = newValue
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
    var showing:String?
    {
        get {
            if (self[Field.showing] as? String == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    self[Field.showing] = showing
                } else {
                    if (hasSlides && hasNotes && hasOutline) {
                        self[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes && hasOutline) {
                        self[Field.showing] = Showing.notes
                    }
                    if (hasSlides && !hasNotes && hasOutline) {
                        self[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes && hasOutline) {
                        self[Field.showing] = Showing.outline
                    }
                    if (hasSlides && !hasNotes && !hasOutline) {
                        self[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes && !hasOutline) {
                        self[Field.showing] = Showing.none
                    }
                    if (hasSlides && hasNotes && !hasOutline) {
                        self[Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes && !hasOutline) {
                        self[Field.showing] = Showing.notes
                    }

                    // this saves calculated values in defaults between sessions
                    mediaItemSettings?[Field.showing] = self[Field.showing] as? String
                }
            }
            
            // Backwards compatible fix
            if self[Field.showing] as? String == "none" {
                self[Field.showing] = "NONE"
            }
            
            return self[Field.showing] as? String
        }
        
        set {
            guard newValue != nil else {
                self[Field.showing] = Showing.none
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
                        } else
                            if hasOutline {
                                wasShowing = Showing.outline
                            } else {
                                wasShowing = Showing.none
                            }
                }
            }
            
            self[Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var download:Download?
    {
        get {
            guard let showing = showing else {
                return nil
            }
            
            return downloads?[showing]
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var atEnd:Bool {
        get {
            guard let playing = playing else {
                return false
            }
            
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing] {
                self[Constants.SETTINGS.AT_END+playing] = atEnd
            } else {
                self[Constants.SETTINGS.AT_END+playing] = "NO"
            }
            return self[Constants.SETTINGS.AT_END+playing]  as? String == "YES"
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            self[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
        }
    }
    
    var webLink : String?
    {
        get {
            if let body = bodyHTML(order: ["title","scripture","speaker"], token: nil, includeURLs: false, includeColumns: false), let urlString = websiteURL?.absoluteString {
                return body + "\n\n" + urlString
            } else {
                return nil
            }
        }
    }
    
    var websiteURL:URL?
    {
        get {
            // if SINGLE_WEBSITE == SINGLE_WEBSITE_OLD but we are using the new API then we need old mediaCode for this to work
            return URL(string: Constants.CBC.SINGLE_WEBSITE + mediaCode)
        }
    }
    
    var downloadURL:URL?
    {
        get {
            return download?.downloadURL
        }
    }
    
    var fileSystemURL:URL?
    {
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
    
    // this supports settings values that are saved in defaults between sessions
    var currentTime:String?
    {
        get {
            guard let playing = playing else {
                return nil
            }
            
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] {
                self[Constants.SETTINGS.CURRENT_TIME+playing] = current_time
            } else {
                self[Constants.SETTINGS.CURRENT_TIME+playing] = "\(0)"
            }

            return self[Constants.SETTINGS.CURRENT_TIME+playing] as? String
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            print(newValue)
            self[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            
            mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
        }
    }
    
    var seriesID:String!
    {
        get {
            if let series = self[Field.series] as? String, !series.isEmpty, hasMultipleParts, let multiPartName = multiPartName {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName
            }
            
            if let seriesDict = self[Field.series] as? [String:Any], let id = Series(seriesDict)?.id {
                return id.description
            }
            
            // Potential crash if nil
            return mediaCode
        }
    }
    
    var year:Int?
    {
        get {
            if let date = date, let range = date.range(of: "-") {
                let year = String(date[..<range.lowerBound])
                
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
    
    var yearString:String!
    {
        get {
            if let date = date, let range = date.range(of: "-") {
                let year = String(date[..<range.lowerBound])
                
                return year
            } else {
                return Constants.Strings.None
            }
        }
    }

    func singleJSONFromURL() -> [[String:String]]?
    {
        guard Globals.shared.reachability.isReachable else {
            return nil
        }
        
        guard let mediaCode = mediaCode else {
            return nil
        }
        
        guard let url = URL(string: Constants.JSON.URL.SINGLE + mediaCode) else {
            return nil
        }
        
        return (url.data?.json as? [String:Any])?["singleEntry"] as? [[String:String]]
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
            
            if var string = speaker {
                if let speakerTitle = speakerTitle {
                    string += ", \(speakerTitle)"
                }

                header = header + "<i>" + string + "</i></br>"
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
    
    var notesHTMLFilename : String?
    {
        get {
            guard let mediaCode = self.mediaCode else {
                return nil
            }
            
            return mediaCode + Constants.FILENAME_EXTENSION.HTMLTranscript
        }
    }
    
    lazy var notesHTML:FetchCodable<String>? = { [weak self] in
        guard hasNotesHTML else {
            return nil
        }
        
        guard let mediaCode = self?.mediaCode else {
            return nil
        }
        
        let fetch = FetchCodable<String>(name: notesHTMLFilename)
        
        fetch.fetch = {
            guard !Globals.shared.isRefreshing else {
                return nil
            }
            
            guard self?.hasNotesHTML == true else {
                return nil
            }

            guard Globals.shared.reachability.isReachable else {
                Alerts.shared.alert(title:"HTML transcript unavailable.")
                return nil
            }

            var notesHTML : String?
            
            if Constants.JSON.URL.BASE == Constants.JSON.URL.BASE_OLD {
                if let mediaItemDict = self?.singleJSONFromURL()?[0] {
                    notesHTML = mediaItemDict[Field.notes_HTML]
                } else {
                    print("loadSingle failure")
                }
            }
            
            if Constants.JSON.URL.BASE == Constants.JSON.URL.BASE_NEW {
                if let url = Globals.shared.media.url, let year = self?.year, let transcriptURL = self?.files?.transcriptHTML {
                    notesHTML = (url + "/\(year)/" + transcriptURL).url?.data?.string8
                }
            }
            
            return notesHTML?.replacingOccurrences(of: "<pre>", with: "").replacingOccurrences(of: "</pre>", with: "").replacingOccurrences(of: "<code>", with: "").replacingOccurrences(of: "</code>", with: "").replacingOccurrences(of: "\n•", with: "<p/>•")
        }
        
        return fetch
    }()
    
    var notesTokensMarkMismatchesFilename : String?
    {
        get {
            guard let mediaCode = mediaCode else {
                return nil
            }
            
            return mediaCode + Constants.FILENAME_EXTENSION.NotesTokensMarkMismatches
        }
    }

    // Runs a comparison between token frequency as parsed from the html transcript and
    // the frequency as found when trying to mark the same token in the html.
    lazy var notesTokensMarkMismatches:FetchCodable<[String]>? = { [weak self] in
        guard let mediaCode = mediaCode else {
            return nil
        }
        
        let fetch = FetchCodable<[String]>(name: notesTokensMarkMismatchesFilename)

        fetch.didSet = { (strings:[String]?) in
            guard let strings = strings, strings.count > 0 else {
                return
            }
            
            print("Token Count vs. Mark Count Mismatch(es) Found")
            print(self?.text ?? "NO MEDIA ITEM TEXT")
            print(strings)
            print("\n\n")
        }
        
        fetch.fetch = {
            guard let notesTokens = self?.notesTokens?.result else {
                return nil
            }

            var mismatches = [String]()
            
            for notesToken in notesTokens {
                let tokenWord = notesToken.key
                let tokenCount = notesToken.value
                
                let markCount = self?.notesText?.markHTML(searchText: tokenWord, wholeWordsOnly: true, index: false).1

                if tokenCount != markCount {
                    mismatches.append("\(tokenWord) \(tokenCount) \(markCount)")
                }
            }
            // Should we return empty rather than nil?  YES.  Nil may mean fetch never stores so it never retrieves so it does the calculation over again.
            return mismatches // .count > 0 ? mismatches : nil
        }
        
        return fetch
    }()
    
    var notesTokens:FetchCodable<[String:Int]>?
    {
        get {
//            if #available(iOS 11.0, *) {
//                return notesPDFTokens
//            } else {
                return notesHTMLTokens
//            }
        }
    }
    
    var notesParagraphLengthsFilename : String?
    {
        get {
            guard let mediaCode = mediaCode else {
                return nil
            }
            
            return mediaCode + Constants.FILENAME_EXTENSION.NotesParagraphLengths
        }
    }
    
    lazy var notesParagraphLengths : FetchCodable<[Int]>? = { [weak self] in
        guard hasNotesText else {
            return nil
        }
        
        guard let mediaCode = mediaCode else {
            return nil
        }
        
        let fetch = FetchCodable<[Int]>(name: notesParagraphLengthsFilename)
        
        fetch.fetch = {
            guard let paragraphs = self?.notesParagraphs else {
                return nil
            }
            
            var lengths = [Int]()
            
            for paragraph in paragraphs {
                lengths.append(paragraph.count)
            }
            
            return lengths.count > 0 ? lengths : nil
        }
        
        return fetch
    }()
    
    var notesParagraphWordsFilename : String?
    {
        get {
            guard let mediaCode = mediaCode else {
                return nil
            }
            
            return mediaCode + Constants.FILENAME_EXTENSION.NotesParagraphWords
        }
    }

    lazy var notesParagraphWords : FetchCodable<[String:Int]>? = { [weak self] in
        guard hasNotesText else {
            return nil
        }
        
        guard let mediaCode = mediaCode else {
            return nil
        }
        
        let fetch = FetchCodable<[String:Int]>(name: notesParagraphWordsFilename)
        
        fetch.fetch = {
            guard let paragraphs = self?.notesParagraphs else {
                return nil
            }
            
            var words = [String:Int]()
            
            for paragraph in paragraphs {
                if #available(iOS 12.0, *) {
                    if let token = paragraph.nlTokenTypes?.first {
                        if let count = words[token.0.lowercased()] {
                            words[token.0.lowercased()] = count + 1
                        } else {
                            words[token.0.lowercased()] = 1
                        }
                    }
                } else {
                    // Fallback on earlier versions
                    if let token = paragraph.nsTokenTypes?.first {
                        if let count = words[token.0.lowercased()] {
                            words[token.0.lowercased()] = count + 1
                        } else {
                            words[token.0.lowercased()] = 1
                        }
                    }
                }
            }
            
            return words.count > 0 ? words : nil
        }
        
        return fetch
    }()
    
    var notesParagraphs:[String]?
    {
        get {
            let paragraphs = notesText?.components(separatedBy: "\n\n").filter({ (string) -> Bool in
                return !string.isEmpty
            })
            
            return paragraphs
        }
    }
    
    var notesText:String?
    {
        get {
//            if #available(iOS 11.0, *) {
//                return notesPDFText?.result
//            } else {
                return notesHTML?.result?.replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "\n\n").replacingOccurrences(of: "\n\n\n", with: "\n\n") // .html2String
//            }
        }
    }

    func loadTokenCountMarkCountMismatches()
    {
        self.operationQueue.addOperation {
            _ = self.notesTokensMarkMismatches?.result
        }
    }
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = mediaCode // Assumed to be globally unique, i.e. that there is only one mediaItem instance w/ this id
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    var notesHTMLTokensFilename : String?
    {
        get {
            guard let mediaCode = self.mediaCode else {
                return nil
            }
            return mediaCode + Constants.FILENAME_EXTENSION.NotesHTMLTokens
        }
    }
    
    lazy var notesHTMLTokens : FetchCodable<[String:Int]>? = { [weak self] in
        guard hasNotesText else {
            return nil
        }
        
        guard let mediaCode = self?.mediaCode else {
            return nil
        }
        
        let fetch = FetchCodable<[String:Int]>(name: notesHTMLTokensFilename)
        
        fetch.fetch = {
            guard !Globals.shared.isRefreshing else {
                return nil
            }
            
            guard self?.hasNotesHTML == true else {
                return nil
            }

            return self?.notesHTML?.result?.html2String?.tokensAndCounts // stripHTML(notesHTML) or notesHTML?.html2String // not sure one is much faster than the other, but html2String is Apple's conversion, the other mine.
        }
        
        return fetch
    }()
    
    // VERY Computationally Expensive
    func formatDate(_ format:String?) -> String?
    {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(for: fullDate)
    }
    
    var formattedDate:String?
    {
        get {
            // VERY Computationally Expensive
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String?
    {
        get {
            // VERY Computationally Expensive
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String?
    {
        get {
            // VERY Computationally Expensive
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String?
    {
        get {
            // VERY Computationally Expensive
            return formatDate("yyyy")
        }
    }
    
    var dateService:String?
    {
        get {
            return self[Field.date] as? String
        }
    }
    
    var date:String?
    {
        get {
            if let date = self[Field.date] as? String, let range = date.range(of: Constants.SINGLE_SPACE) {
                return String(date[..<range.lowerBound]) // last two characters // self[Field.title]
            } else {
                return nil
            }
        }
    }
    
    var service:String?
    {
        get {
            if let date = self[Field.date] as? String, let range = date.range(of: Constants.SINGLE_SPACE) {
                return String(date[range.upperBound...]) // last two characters // self[Field.title]
            } else {
                return nil
            }
        }
    }
    
    var published:Bool?
    {
        get {
            return self[Field.published] as? Bool
        }
    }
    
    var title:String?
    {
        get {
            guard let title = self[Field.title] as? String, !title.isEmpty else {
                return Constants.Strings.None
            }
            
            return title
        }
    }
    
    var category:String?
    {
        get {
            if let category = self[Field.category] as? String {
                return category
            }

            if let categoryDict = self[Field.category] as? [String:Any] {
                return Category(categoryDict)?.name
            }

            return nil
        }
    }

    // NEW API
//    lazy var category : Category? = {
//        return Category(storage?[Field.category] as? [String:Any])
//    }()

    var scriptureReference:String?
    {
        get {
            guard let scriptureReference = (self[Field.scripture] as? String)?.replacingOccurrences(of: "Psalm ", with: "Psalms "), !scriptureReference.isEmpty else {
                return Constants.Strings.Selected_Scriptures
            }
            
            return scriptureReference
        }
    }
    
    lazy var scripture:Scripture? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return Scripture(reference:self?.scriptureReference)
    }()
    
    var classSectionSort:String!
    {
        get {
            return classSection.lowercased()
        }
    }
    
    var classSection:String!
    {
        get {
            guard let className = className, !className.isEmpty else {
                return Constants.Strings.None
            }
            
            return className
        }
    }
    
    var className:String?
    {
        get {
            if let className = self[Field.className] as? String, !className.isEmpty {
                return className
            }
            
            if let groupName = group?.name, !groupName.isEmpty {
                return groupName
            }
            
            return Constants.Strings.None
        }
    }
    
    var eventSectionSort:String!
    {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String!
    {
        get {
            guard let eventName = eventName, !eventName.isEmpty else {
                return Constants.Strings.None
            }
            
            return eventName
        }
    }
    
    var eventName:String?
    {
        get {
            if let eventName = self[Field.eventName] as? String, !eventName.isEmpty {
                return eventName
            }
            
            if let eventDict = self[Field.eventName] as? [String:Any] {
                return Event(eventDict)?.name
            }
            
            return Constants.Strings.None
        }
    }
    
    var speakerSectionSort:String!
    {
        get {
            guard let speakerSort = speakerSort else { // hasSpeaker,
                return "ERROR"
            }
            
            return speakerSort.lowercased()
        }
    }
    
    var speakerSection:String!
    {
        get {
            guard let speaker = speaker, !speaker.isEmpty else {
                return Constants.Strings.None
            }

            return speaker
        }
    }
    
    var speakerTitle:String?
    {
        get {
            guard let speaker = speaker else {
                return nil
            }
            
            return Globals.shared.media.teachers[speaker]?.status
        }
    }
    
    var speaker:String?
    {
        get {
            if let speaker = self[Field.speaker] as? String, !speaker.isEmpty {
                return speaker
            }
            
            if let speakerDict = self[Field.speaker] as? [String:Any] {
                return Teacher(speakerDict)?.name
            }
            
            return Constants.Strings.None
        }
    }
    
    var series:String?
    {
        get {
            if let series = self[Field.series] as? String, !series.isEmpty {
                return series
            }
            
            if let seriesDict = self[Field.series] as? [String:Any] {
                return Series(seriesDict)?.name
            }
            
            return nil
        }
    }

    // NEW API
    //    lazy var series : Series? = {
    //        return Series(storage?[Field.series] as? [String:Any])
    //    }()
    
    lazy var files : Files? = {
        return Files(storage?[Field.files] as? [String:Any])
    }()
    
    lazy var group : Group? = {
        return Group(storage?[Field.group] as? [String:Any])
    }()
    
    lazy var teacher : Teacher? = {
        return Teacher(storage?[Field.teacher] as? [String:Any])
    }()
    
    var speakerSort:String?
    {
        get {
            if self[Field.speaker_sort] as? String == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    self[Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Winkle"

                    var speakerSort:String?
                    
                    if hasSpeaker, let speaker = speaker {
                        if !speaker.contains("Ministry Panel") {
                            if let lastName = speaker.lastName {
                                speakerSort = lastName
                            }
                            if let firstName = speaker.firstName {
                                speakerSort = ((speakerSort != nil) ? speakerSort! + ", " : "") + firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                    
                    self[Field.speaker_sort] = speakerSort ?? Constants.Strings.None
                }
            }

            return self[Field.speaker_sort] as? String
        }
    }
    
    var multiPartSectionSort:String!
    {
        get {
            if hasMultipleParts {
                if let sort = multiPartSort?.lowercased() {
                    return sort
                } else {
                    return "ERROR"
                }
            } else {
                if let sort = title?.withoutPrefixes.lowercased() {
                    return sort
                } else {
                    return "ERROR"
                }
            }
        }
    }
    
    var multiPartSection:String!
    {
        get {
            return multiPartName ?? (title ?? Constants.Strings.None)
        }
    }
    
    var multiPartSort:String?
    {
        get {
            if self[Field.multi_part_name_sort] as? String == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    self[Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = multiPartName?.withoutPrefixes {
                        self[Field.multi_part_name_sort] = multiPartSort
                    } else {

                    }
                }
            }
            return self[Field.multi_part_name_sort] as? String
        }
    }
    
    var multiPartName:String?
    {
        get {
            if (self[Field.multi_part_name] as? String == nil) {
                for partPreamble in Constants.PART_PREAMBLES {
                    if let title = title, let range = title.range(of: partPreamble + Constants.PART_INDICATOR, options: .caseInsensitive, range: nil, locale: nil) {
                        let seriesString = String(title[..<range.lowerBound]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        self[Field.multi_part_name] = seriesString
                        break
                    }
                }
            }
            
            return self[Field.multi_part_name] as? String
        }
    }
    
    var part:String?
    {
        get {
            guard let title = title else {
                return nil
            }
            
            if hasMultipleParts, self[Field.part] as? String == nil {
                for partPreamble in Constants.PART_PREAMBLES {
                    if let range = title.range(of: partPreamble + Constants.PART_INDICATOR, options: .caseInsensitive, range: nil, locale: nil) {
                        let partString = String(title[range.upperBound...])
                        
                        if let index = Constants.PART_PREAMBLES.firstIndex(of: partPreamble) {
                            let postAmble = Constants.PART_POSTAMBLES[index]
                            
                            if postAmble.isEmpty {
                                self[Field.part] = partString
                            } else {
                                if let range = partString.range(of: postAmble) {
                                    self[Field.part] = String(partString[..<range.lowerBound])
                                }
                            }
                            break
                        }
                    }
                }
            }

            return self[Field.part] as? String
        }
    }
    
    var dynamicTags:String?
    {
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
    
    var constantTags:String?
    {
        get {
            var constantTags:String?
            
            ///////////////////////////////////////////////////
            // Unfortunately these slow things down...
            ///////////////////////////////////////////////////
            
            // We need this to show Tom's Archives from TWU.
            if hasSpeaker, let speakerSort = speakerSort {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + speakerSort
            }

            // Compromise...
//            if let books = books {
//                for book in books {
//                    constantTags = (constantTags != nil ? constantTags! + "|" : "") + book
//                }
//            }
            
            ///////////////////////////////////////////////////
            // And to be fair the rest of this does as well
            // because they aren't tags specified by CBC
            //
            // The real problem is that we index by tag up front
            // not on demand.
            ///////////////////////////////////////////////////

            if hasSlides {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Slides
            }
            
            if hasNotes, let notesName = notesName {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + notesName
            }
            
            if hasNotesText {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Lexicon
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Transcript + " - " + Constants.Strings.HTML
            }

            if hasVideo {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Video
            }
            
            if hasOutline {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Outline
            }
            
            // Invoke separately so both lazy variables are instantiated.
            if audioTranscript?.transcript != nil {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + Constants.Strings.Audio
            }
            
            if videoTranscript?.transcript != nil {
                constantTags = (constantTags != nil ? constantTags! + "|" : "") + Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + Constants.Strings.Video
            }
            
            return constantTags
        }
    }

    var tags:String?
    {
        get {
            var tags:String?
            
            if let dynamicTags = dynamicTags {
                tags = tags != nil ? (tags! + "|" + dynamicTags) : dynamicTags
            }
            
            if let constantTags = constantTags {
                tags = tags != nil ? (tags! + "|" + constantTags) : constantTags
            }
            
            if let jsonTags = series {
                tags = tags != nil ? (tags! + "|" + jsonTags) : jsonTags
            }
            
            if let savedTags = mediaItemSettings?[Field.tags] {
                tags = tags != nil ? (tags! + "|" + savedTags) : savedTags
            }

            // Check Downloaded
            if let audioDownload = audioDownload, audioDownload.exists {
                tags = tags != nil ? (tags! + "|" + Constants.Strings.Downloaded) : Constants.Strings.Downloaded
            }

            // This coalesces the tags so there are no duplicates
            if let tagsString = tags?.tagsArray?.filter({ (string:String) -> Bool in
                // WHY? Backwards compatibility
                
                if string.contains(Constants.Strings.Machine_Generated + " " + Constants.Strings.Transcript) {
                    return false
                }
                
                if string.contains(Constants.Strings.HTML + " " + Constants.Strings.Transcript) {
                    return false
                }
                
                // Check Downloaded
                if string.contains(Constants.Strings.Downloaded) {
                    guard let audioDownload = audioDownload else {
                        return false
                    }
                    
                    return audioDownload.exists
                }
                
                return true
            }).set.tagsString {
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
        
        let tags = mediaItemSettings?[Field.tags]?.tagsArray
        
        guard tags?.firstIndex(of: tag) == nil else {
            return
        }

        if let tags = mediaItemSettings?[Field.tags] {
            mediaItemSettings?[Field.tags] = tags + Constants.SEPARATOR + tag
        } else {
            mediaItemSettings?[Field.tags] = tag
        }
        
        let sortTag = tag.withoutPrefixes
        
        guard !sortTag.isEmpty else {
            return
        }
        
        // Should this be sync? Doesn't make any difference.
        Globals.shared.queue.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TAG_ADDED), object: self, userInfo: ["TAG":tag])
        }
        
        Thread.onMain {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self)
        }
    }
    
    func removeTag(_ tag:String)
    {
        guard mediaItemSettings?[Field.tags] != nil else {
            return
        }
        
        var tags = mediaItemSettings?[Field.tags]?.tagsArray
        
        guard tags?.contains(tag) == true else {
            return
        }
        
        guard tags?.count > 0 else {
            return
        }
        
        while let index = tags?.firstIndex(of: tag) {
            tags?.remove(at: index)
        }
        
        mediaItemSettings?[Field.tags] = tags?.tagsString
        
        let sortTag = tag.withoutPrefixes
        
        guard !sortTag.isEmpty else {
            return
        }
        
        // Should this be sync? Doesn't make any difference.
        Globals.shared.queue.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TAG_REMOVED), object: self, userInfo: ["TAG":tag])
        }
        
        Thread.onMain {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self)
        }
    }
    
    var tagsSet:Set<String>?
    {
        get {
            guard var tags = tags else {
                return nil
            }
            
            var tag:String
            var tagsSet = Set<String>()
            
            while (tags.range(of: Constants.SEPARATOR) != nil) {
                if let range = tags.range(of: Constants.SEPARATOR) {
                    tag = String(tags[..<range.lowerBound])
                    tagsSet.insert(tag)
                    tags = String(tags[range.upperBound...])
                } else {
                    // ???
                }
            }
            
            tagsSet.insert(tags)
            
            return tagsSet.count == 0 ? nil : tagsSet
        }
    }
    
    var tagsArray:[String]?
    {
        get {
            guard let tagsSet = tagsSet else {
                return nil
            }
            
            return Array(tagsSet).sorted() {
                return $0 < $1
            }
        }
    }
    
    var hasPosterImage : Bool
    {
        return posterImageURL != nil
    }
    
    var posterImageURL:URL?
    {
        get {
            guard hasVideo else {
                return nil
            }
            
            guard let year = year else {
                return nil
            }
            
            if let poster = video?.poster, let url = Globals.shared.media.url {
                return (url + "/\(year)/" + poster).url
            } else {
                if let mediaCode = mediaCode {
                    return (Constants.BASE_URL.MEDIA + "\(year)/\(mediaCode)" + Constants.FILENAME_EXTENSION.poster).url // "poster.jpg"
                }
            }
            
            return nil
        }
    }

    lazy var posterImage:FetchImage? = { [weak self] in
        guard let posterImageURL = posterImageURL else {
            return nil
        }
        
        return FetchImage(url: posterImageURL)
    }()

    var hasSeriesImage : Bool
    {
        return seriesImageName != nil
    }
    
    var seriesImageName : String?
    {
        return self[Field.seriesImage] as? String
    }
    
    var seriesImageURL : URL?
    {
        guard let seriesImageName = seriesImageName else {
            return nil
        }
        
        let urlString = Constants.BASE_URL.MEDIA + "series/\(seriesImageName)"

        return urlString.url
    }

    lazy var seriesImage:FetchCachedImage? = { [weak self] in
        guard let seriesImageURL = seriesImageURL else {
            return nil
        }
        
       return FetchCachedImage(url: seriesImageURL)
    }()

    lazy var video : Video? = {
        return Video(storage?[Field.video] as? [String:Any])
    }()
    
    var mp3:String?
    {
        get {
            if let mp3 = self[Field.mp3] as? String {
                return mp3
            } else {
                if let mp3 = audio?.mp3, let year = year, let url = Globals.shared.media.url {
                    return url + "/\(year)/" + mp3
                }
            }
            
            return nil
        }
    }
    
    var mp4:String?
    {
        get {
            if let mp4 = self[Field.mp4] as? String {
                return mp4
            } else {
                return video?.mp4
            }
        }
    }
    
    var m3u8:String?
    {
        get {
            if let m3u8 = self[Field.m3u8] as? String {
                return m3u8
            } else {
                return video?.m3u8
            }
        }
    }
    
    var videoURL:String?
    {
        get {
            return m3u8
        }
    }
    
    var videoID:String?
    {
        get {
            guard let videoURL = videoURL else {
                return nil
            }
            
            guard videoURL.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = String(videoURL[Constants.BASE_URL.VIDEO_PREFIX.endIndex...])
            
            if let range = tail.range(of: ".m") {
                return String(tail[..<range.lowerBound])
            } else {
                return nil
            }
        }
    }
    
    var externalVideo:String?
    {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    var notes:String?
    {
        get {
            guard hasNotes else {
                return nil
            }
            
            guard let year = year else {
                return nil
            }
            
            if let notes = files?.notes, let url = Globals.shared.media.url {
                return url + "/\(year)/" + notes
            } else {
                if let notesFilename = notesFilename {
                    return Constants.BASE_URL.MEDIA + "\(year)/" + notesFilename
                }
            }
            
            return nil
        }
    }
    
//    @available(iOS 11.0, *)
//    lazy var notesPDFTokens:FetchCodable<[String:Int]>? = { [weak self] in
//        guard let mediaCode = self.mediaCode else {
//            return nil
//        }
//
//        let fetch = FetchCodable<[String:Int]>(name: mediaCode + "." + "PDF Text Tokens")
//
//        fetch.fetch = {
//            guard !Globals.shared.isRefreshing else {
//                return nil
//            }
//
//            guard self.hasNotes else {
//                return nil
//            }
//
//            return self.notesPDFText?.result?.tokensAndCounts
//        }
//
//        return fetch
//    }()
    
//    @available(iOS 11.0, *)
//    var fullNotesPDFHTML:String?
//    {
//        get {
//            guard let notesPDFHTML = notesPDFHTML else {
//                return nil
//            }
//
//            return insertHead("<!DOCTYPE html><html><body>" + headerHTML + "<br/>" + notesPDFHTML + "</body></html>",fontSize: Constants.FONT_SIZE)
//        }
//    }

//    @available(iOS 11.0, *)
//    var notesPDFHTML:String?
//    {
//        get {
//            guard let body = notesPDFText?.result?.replacingOccurrences(of: "\n\n", with: "<br/><br/>") else {
//                return nil
//            }
//            return "<br/>" + body
//        }
//    }
    
//    @available(iOS 11.0, *)
//    lazy var notesPDFText:FetchCodable<String>? = { [weak self] in
//        guard hasNotes else {
//            return nil
//        }
//
//        guard let mediaCode = self.mediaCode else {
//            return nil
//        }
//
//        let fetch = FetchCodable<String>(name: mediaCode + "." + "PDF Text")
//
//        fetch.fetch = {
//            guard self.hasNotes else {
//                return nil
//            }
//
//            guard let pdf = self.notesURL?.pdf else {
//                return nil
//            }
//
//            var documentText = String()
//
//            let pageCount = pdf.pageCount
//            for i in 0 ..< pageCount {
//                var pageText = String()
//
//                guard let page = pdf.page(at: i) else {
//                    continue
//                }
//
//                guard let pageContent = page.attributedString else {
//                    continue
//                }
//
//                print(pageContent)
//                print(pageContent.string)
//
//                var topRange:Range<String.Index>?
//
//                topRange = pageContent.string.lowercased().range(of: "Countryside Bible Church, Southlake, Texas".lowercased())
//
//                if topRange == nil {
//                    topRange = pageContent.string.lowercased().range(of: "Countryside Bible Church www.countrysidebible.org".lowercased())
//                }
//
//                if topRange == nil {
//                    topRange = pageContent.string.lowercased().range(of: "Countryside Bible Church".lowercased())
//                }
//
//                if topRange == nil {
//                    topRange = pageContent.string.lowercased().range(of: "Southlake Bible Church".lowercased())
//                }
//
//                if let topRange = topRange {
//                    if let bottomRange = pageContent.string.lowercased().range(of: "Available online".lowercased()) {
//                        pageText = String(pageContent.string[topRange.upperBound...bottomRange.lowerBound])
//                    } else {
//                        pageText = String(pageContent.string[topRange.upperBound...])
//                    }
//                } else {
//                    pageText = pageContent.string
//                }
//
//                print(pageText)
//                var components = pageText.components(separatedBy: "\n").filter({ (string) -> Bool in
//                    return !string.isEmpty
//                })
//
//                print(components)
//                components.removeLast() // Intended to get page number - but the first page may not work.
//
//                var string = String()
//
//                // YIKES - NOT ALL COMPONENTS (separated by \n) ARE A PARAGRAPH!!!
//                for component in components {
//                    if !string.isEmpty {
//                        // This doesn't work as there are other terminators besides '.'
//                        if string.last == "." {
//                            string += "\n\n" + component
//                        } else {
//                            string += " " + component
//                        }
//                    } else {
//                        string += component
//                    }
//                }
//
//                documentText += !documentText.isEmpty ? " " + string : string
//            }
//
//            return documentText.count > 0 ? documentText : nil
//        }
//
//        return fetch
//    }()
    
    lazy var searchMarkedFullNotesHTML:CachedString? = { [weak self] in
        return CachedString(index: nil)
    }()
        
    var fullNotesHTML:String?
    {
        get {
            guard let notesHTML = notesHTML?.result else {
                return nil
            }

            return "<!DOCTYPE html><html><body>" + headerHTML + notesHTML + "</body></html>".insertHead(fontSize: Constants.FONT_SIZE)
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String?
    {
        get {
            guard hasSlides else {
                return nil
            }
            
            guard let year = year else {
                return nil
            }
            
            if let slides = files?.slides, let url = Globals.shared.media.url {
                return url + "/\(year)/" + slides
            } else {
                if let slidesFilename = slidesFilename {
                    return Constants.BASE_URL.MEDIA + "\(year)/" + slidesFilename
                }
            }
            
            return nil
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String?
    {
        get {
            guard hasOutline else {
                return nil
            }
            
            guard let year = year else {
                return nil
            }
            
            if let outline = files?.outline, let url = Globals.shared.media.url {
                return url + "/\(year)/" + outline
            } else {
                if let outlineFilename = outlineFilename {
                    return Constants.BASE_URL.MEDIA + "\(year)/" + outlineFilename
                }
            }
            
            return nil
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var filesFlags:String?
    {
        get {
            return self[Field.files] as? String
        }
    }
    
    var hasAudio:Bool
    {
        get {
            if let contains = filesFlags?.contains("A") {
                return contains
            } else {
                return audio?.mp3 != nil
            }
        }
    }
    
    var hasVideo:Bool
    {
        get {
            if let contains = filesFlags?.contains("V") {
                return contains
            } else {
                return (video?.mp4 != nil) || (video?.m3u8 != nil)
            }
        }
    }
    
    var hasSlides:Bool
    {
        get {
            if let contains = filesFlags?.contains("S") {
                return contains
            } else {
                return files?.slides != nil
            }
        }
    }
    
    var hasNotes:Bool
    {
        get {
            if let contains = filesFlags?.contains("T") {
                return contains
            } else {
                return files?.notes != nil
            }
        }
    }
    
    var hasNotesHTML:Bool
    {
        get {
            guard hasNotes else {
                return false
            }
            //            print(files)
            
            if let contains = filesFlags?.contains("H") {
                return contains
            } else {
                return files?.notesHTML != nil
            }
        }
    }
    
    var hasNotesText:Bool
    {
        get {
//            if #available(iOS 11.0, *) {
//                return hasNotes && (notesName == Constants.Strings.Transcript)
//            } else {
                return hasNotesHTML && (notesName == Constants.Strings.Transcript)
//            }
        }
    }
    
    var hasOutline:Bool
    {
        get {
            if let contains = filesFlags?.contains("O") {
                return contains
            } else {
                return files?.outline != nil
            }
        }
    }
    
    lazy var audio : Audio? = {
        return Audio(storage?[Field.audio] as? [String:Any])
    }()
    
    var audioURL:String?
    {
        get {
            guard hasAudio else {
                return nil
            }
            
            guard let year = year else {
                return nil
            }

            if let audio = Audio(self[Field.audio] as? [String:Any]), let mp3 = audio.mp3, let url = Globals.shared.media.url {
                return url + "/\(year)/" + mp3
            } else {
                if let mediaCode = mediaCode {
                    return Constants.BASE_URL.MEDIA + "\(year)/\(mediaCode)" + Constants.FILENAME_EXTENSION.MP3
                }
            }
            
            return nil
        }
    }
    
    var audioFilename:String?
    {
        get {
            return mp3Filename
        }
    }
    
    var mp3Filename:String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.MP3
            } else {
                return nil
            }
        }
    }
    
    var mp4Filename:String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.MP4
            } else {
                return nil
            }
        }
    }
    
    var m3u8Filename:String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.M3U8
            } else {
                return nil
            }
        }
    }
    
    var videoFilename:String?
    {
        get {
            return m3u8Filename
        }
    }
    
    var slidesFilename:String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.slides
            } else {
                return nil
            }
        }
    }
    
    var notesFilename : String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.notes
            } else {
                return nil
            }
        }
    }
    
    var outlineFilename:String?
    {
        get {
            if let mediaCode = mediaCode {
                return mediaCode + Constants.FILENAME_EXTENSION.outline
            } else {
                return nil
            }
        }
    }
    
    var bookSections:[String]
    {
        get {
            if let books = scripture?.books {
                return books
            }
            
            guard hasScripture, let scriptureReference = scriptureReference else {
                return [Constants.Strings.None]
            }
            
            return [scriptureReference.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)]
        }
    }
    
    var fullDate:Date?
    {
        get {
            if let date = date {
                return Date(dateString:date)
            } else {
                return nil
            }
        }
    }
    
    var contents:String?
    {
        get {
            return bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs: false, includeColumns: false)?.stripHTML
        }
    }

    var contentsHTML:String?
    {
        get {
            var bodyString = "<!DOCTYPE html><html><body>"
            
            if let string = bodyHTML(order:["date","title","scripture","speaker"], token:nil, includeURLs:true, includeColumns:true) {
                bodyString = bodyString + string
            }
            
            bodyString = bodyString + "</body></htm>"
            
            return bodyString
        }
    }

    // Make thread safe?
    var transcripts = [String:VoiceBase]()
    
    lazy var audioTranscript:VoiceBase? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasAudio == true else {
            return nil
        }
    
        guard let voicebase = VoiceBase(mediaItem:self,purpose:Purpose.audio) else {// CRITICAL: This initializer sets mediaID and completed from settings.
            return nil
        }
        
        voicebase.initialize()
        
        if let purpose = voicebase.purpose {
            self?.transcripts[purpose] = voicebase
        }
        return voicebase
    }()
    
    lazy var videoTranscript:VoiceBase? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        guard self?.hasVideo == true else {
            return nil
        }
        
        guard let voicebase = VoiceBase(mediaItem:self,purpose:Purpose.video) else {// CRITICAL: This initializer sets mediaID and completed from settings.
            return nil
        }
        
        voicebase.initialize()
        
        if let purpose = voicebase.purpose {
            self?.transcripts[purpose] = voicebase
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
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if let month = formattedDateMonth {
                        bodyString = bodyString! + month
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;text-align:right;\">"
                    if let day = formattedDateDay {
                        bodyString  = bodyString! + day + ","
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;text-align:right;\">"
                    
                    if let year = formattedDateYear {
                        bodyString  = bodyString! + year
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if let service = self.service {
                        bodyString  = bodyString! + service
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "title":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            let tag = title.asTag
                            bodyString = bodyString! + "<a id=\"\(tag)\" name=\"\(tag)\" target=\"_blank\" href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = bodyString! + title
                        }
                    }
                    bodyString = bodyString! + "</td>"
                    break

                case "scripture":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if let scriptureReference = self.scriptureReference {
                        bodyString = bodyString! + scriptureReference
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "speaker":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if hasSpeaker, var speaker = self.speaker {
                        if let speakerTitle = speakerTitle {
                            speaker += ", \(speakerTitle)"
                        }

                        bodyString = bodyString! + speaker
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "class":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if hasClassName, let className = self.className {
                        bodyString = bodyString! + className
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "event":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if hasEventName, let eventName = self.eventName {
                        bodyString = bodyString! + eventName
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "count":
                    bodyString = bodyString! + "<td style=\"vertical-align:baseline;\">"
                    if let token = token, let count = self.notesTokens?.result?[token] {
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
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + title
                        }
                    }
                    break

                case "scripture":
                    if let scriptureReference = self.scriptureReference {
                        bodyString  = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + scriptureReference
                    }
                    break
                    
                case "speaker":
                    if hasSpeaker, let speaker = self.speaker {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + speaker
                    }
                    break
                    
                case "class":
                    if hasClassName, let className = self.className {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + className
                    }
                    break
                    
                case "event":
                    if hasEventName, let eventName = self.eventName {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + eventName
                    }
                    break
                    
                case "count":
                    if let token = token, let count = self.notesTokens?.result?[token] {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + "(\(count))"
                    }
                    break

                default:
                    break
                }
            }
        }
        
        return bodyString
    }
    
    var text : String?
    {
        get {
            guard var string = hasDate ? formattedDate : "No Date" else {
                return nil
            }
            
            if let service = service {
                string += " \(service)"
            }
            
            if hasSpeaker, let speaker = speaker {
                string += "\n\(speaker)"
            }
            
            if hasTitle, let title = title {
                var partFound = false
                for partPreamble in Constants.PART_PREAMBLES {
                    if let rangeTo = title.range(of: partPreamble + Constants.PART_INDICATOR), let rangeFrom = title.range(of: partPreamble + Constants.PART_INDICATOR), rangeFrom.lowerBound == rangeTo.lowerBound {
                        let first = String(title[..<rangeTo.upperBound])
                        let second = String(title[rangeFrom.upperBound...])
                        let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                        string += "\n\(combined)"
                        partFound = true
                        break
                    }
                }

                if !partFound {
                    string += "\n\(title)"
                }
            }
            
            if let scriptureReference = scriptureReference {
                string += "\n\(scriptureReference)"
            }
            
            if hasClassName, let className = className {
                string += "\n\(className)"
            }
            
            if hasEventName, let eventName = eventName {
                string += "\n\(eventName)"
            }
            
            return string
        }
    }
    
    var json : String {
        var mediaItemString = "{"

            mediaItemString += "\"metadata\":{"

                if let category = category {
                    mediaItemString += "\"category\":\"\(category)\","
                }
                
                if let mediaCode = mediaCode {
                    mediaItemString += "\"mediaCode\":\"\(mediaCode)\","
                }
                
                if let date = date {
                    mediaItemString += "\"date\":\"\(date)\","
                }
                
                if let service = service {
                    mediaItemString += "\"service\":\"\(service)\","
                }
                
                if let title = title {
                    mediaItemString += "\"title\":\"\(title)\","
                }
                
                if let scripture = scripture {
                    mediaItemString += "\"scripture\":\"\(scripture.description)\","
                }
                
                if let speaker = speaker {
                    mediaItemString += "\"speaker\":\"\(speaker)\""
                }
            
            mediaItemString += "}"
        
        mediaItemString += "}"
        
        return mediaItemString
    }
    
    override var description : String {
        return json
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return MediaItemSettings(mediaItem:self)
    }()
    
    lazy var multiPartSettings:MultiPartSettings? = { [weak self] in
        // unowned self is not needed unless self is capture by a closure that outlives the initialization closure.
//        [unowned self] in
        return MultiPartSettings(mediaItem:self)
    }()
    
    var verticalSplit:String?
    {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var horizontalSplit:String?
    {
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
            guard let multiPartName = multiPartName, !multiPartName.isEmpty else {
                return false
            }
            
            return !multiPartName.isEmpty
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
            return (self.scripture?.books != nil)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            guard let speaker = speaker else {
                return false
            }
            
            return !speaker.isEmpty && (speaker != Constants.Strings.None)
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
        
        guard let notesURL = notes?.url else {
            return false
        }
        
        guard Globals.shared.reachability.isReachable else {
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
        
        guard let slidesURL = slides?.url else {
            return false
        }
        
        guard Globals.shared.reachability.isReachable else {
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

    func view(viewController: UIViewController, bodyHTML:String?)
    {
        // test:(()->(Bool))?
        viewController.process(work: { [weak self] () -> (Any?) in
            var htmlString:String?
            
            if let lexiconIndexViewController = viewController as? LexiconIndexViewController {
                htmlString = bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:lexiconIndexViewController.searchText, wholeWordsOnly: true, index: true).0
            } else
                
            if let _ = viewController as? MediaTableViewController, Globals.shared.media.search.isActive, Globals.shared.media.search.transcripts.value == true {
                htmlString = bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:Globals.shared.media.search.text, wholeWordsOnly: false, index: true).0
            }
            
            return htmlString
        }, completion: { [weak self] (data:Any?) in
            let htmlString = data as? String
            
            viewController.popoverHTML(title:self?.title, mediaItem:self, bodyHTML: bodyHTML, headerHTML: self?.headerHTML, sourceView:viewController.view, sourceRectView:viewController.view, htmlString:htmlString, search:true)
        })
    }
    
    func addToFavorites(alert:Bool = true)
    {
        self.addTag(Constants.Strings.Favorites)
        
        if alert {
            Alerts.shared.alert(title: "Added to Favorites",message: self.text)
        }
    }
    
    func removeFromFavorites(alert:Bool = true)
    {
        self.removeTag(Constants.Strings.Favorites)
        
        if alert {
            Alerts.shared.alert(title: "Removed From Favorites",message: self.text)
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
        
        var clearCache:AlertAction!
        
        clearCache = AlertAction(title: Constants.Strings.Clear_Cache, style: .destructive) {
            var alertActions = [AlertAction]()
            
            let yesAction = AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: { [weak self]
                () -> Void in
                // test:(()->(Bool))?
                viewController.process(work: { () -> (Any?) in
                    self?.clearCache(block:true)
                    return nil
                }, completion: { (data:Any?) in
                    Alerts.shared.alert(title:Constants.Strings.Cache_Cleared, message: self?.text)
                })
            })
            alertActions.append(yesAction)
            
            let noAction = AlertAction(title: Constants.Strings.No, style: .default, handler: { [weak self]
                () -> Void in
                
            })
            alertActions.append(noAction)
            
            Alerts.shared.alert(title: Constants.Strings.Confirm_Clear_Cache, message: (self.text ?? "") + "\n\nThis deletes files that can be downloaded or recreated again when needed.", actions: alertActions)
        }
        
        if hasAudio, let audioDownload = audioDownload {
            var title = ""
            var style = UIAlertAction.Style.default
            
            switch audioDownload.state {
            case .none:
                title = Constants.Strings.Download_Audio
                break
                
            case .downloading:
                title = Constants.Strings.Cancel_Audio_Download
                style = UIAlertAction.Style.destructive
                break
            case .downloaded:
                title = Constants.Strings.Delete_Audio_Download
                style = UIAlertAction.Style.destructive
                break
            }
            
            download = AlertAction(title: title, style: style, handler: {
                switch title {
                case Constants.Strings.Download_Audio:
                    audioDownload.download(background: true)
                    break
                    
                case Constants.Strings.Delete_Audio_Download:
                    guard let text = self.text else {
                        break
                    }
                    
                    var alertActions = [AlertAction]()

                    let yesAction = AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { [weak self]
                        () -> Void in
                        audioDownload.delete(block:true)
                    })
                    alertActions.append(yesAction)
                    
                    let noAction = AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: { [weak self]
                        () -> Void in
                        
                    })
                    alertActions.append(noAction)
                    
                    Alerts.shared.alert(title: "Confirm Deletion of Audio Download", message: text, actions: alertActions)
                    break
                    
                case Constants.Strings.Cancel_Audio_Download:
                    switch audioDownload.state {
                    case .downloading:
                        audioDownload.cancel()
                        break
                        
                    case .downloaded:
                        guard let text = self.text else {
                            break
                        }
                        
                        var alertActions = [AlertAction]()
                        
                        let yesAction = AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { [weak self]
                            () -> Void in
                            self?.audioDownload?.delete(block:true)
                        })
                        alertActions.append(yesAction)
                        
                        let noAction = AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: { [weak self]
                            () -> Void in
                            
                        })
                        alertActions.append(noAction)
                        
                        Alerts.shared.alert(title: "Confirm Deletion of Audio Download", message: text, actions: alertActions)
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
                self.addToFavorites()
                break
                
            case Constants.Strings.Remove_From_Favorites:
                // This blocks this thread until it finishes.
                self.removeFromFavorites()
                break
                
            default:
                break
            }
        }
        
        openOnCBC = AlertAction(title: Constants.Strings.Open_on_CBC_Website, style: .default) { [weak self] in
            if let url = self?.websiteURL {
                UIApplication.shared.open(scheme: url.absoluteString) {
                    Alerts.shared.alert(title: "Network Error",message: "Unable to open: \(url)")
                }
            }
        }
        
        share = AlertAction(title: Constants.Strings.Share, style: .default) { [weak self] in
            self?.share(viewController: viewController)
        }
        
        tags = AlertAction(title: Constants.Strings.Tags, style: .default) { [weak self] in
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }
            
            if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = mtvc
                
                navigationController.popoverPresentationController?.barButtonItem = mtvc.tagsButton
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                
                popover.navigationItem.title = Constants.Strings.Show
                
                popover.delegate = mtvc
                popover.purpose = .selectingTags
                
                popover.stringSelected = Globals.shared.media.tags.selected ?? Constants.Strings.All
                
                popover.section.strings = self?.tagsArray
                popover.section.strings?.insert(Constants.Strings.All,at: 0)
                
                mtvc.popover?["TAGS"] = popover
                
                popover.completion = { [weak mtvc] in
                    mtvc?.popover?["TAGS"] = nil
                }

                mtvc.present(navigationController, animated: true, completion: nil)
            }
        }
        
        search = AlertAction(title: Constants.Strings.Search, style: .default) { [weak self] in
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }
            
            if let searchStrings = self?.searchStrings(),
                let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//                mtvc.popover?.values.forEach({ (popover:PopoverTableViewController) in
//                    popover.dismiss(animated: true, completion: nil)
//                })
                
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

                mtvc.popover?["CELLSEARCH"] = popover
                
                popover.completion = { [weak mtvc] in
                    mtvc?.popover?["CELLSEARCH"] = nil
                }
                
                mtvc.present(navigationController, animated: true, completion:nil)
            }
        }
        
        words = AlertAction(title: Constants.Strings.Word_Search, style: .default) { [weak self] in
            guard self?.hasNotesText == true else { // HTML
                return
            }
            
            guard let mtvc = viewController as? MediaTableViewController else {
                return
            }

            // test:(()->(Bool))?
            mtvc.process(work: { [weak self] () -> (Any?) in
                _ = self?.notesTokens?.result // Have to do this because transcriptTokens has UI.
            }, completion: { [weak self, weak mtvc] (data:Any?) in
                guard let tokens = self?.notesTokens?.result?.map({ (string:String,count:Int) -> String in
                    return "\(string) (\(count))"
                }).sorted() else {
                    viewController.networkUnavailable("HTML transcript vocabulary unavailable.")
                    return
                }
  
                mtvc?.selectWord(title:Constants.Strings.Search, purpose:.selectingCellSearch, strings:tokens)
//                transcriptTokens()
            })
        }

        if hasNotes, notesName == Constants.Strings.Transcript {
//            if #available(iOS 11.0, *) {
//                transcript = AlertAction(title: "HTML Transcript", style: .default) {
//                    process(viewController: viewController, work: { [weak self] () -> (Any?) in
//                        self?.notesPDFText?.load()
//                    }, completion: { [weak self] (data:Any?) in
//                        self?.view(viewController:viewController, bodyHTML:self?.notesPDFHTML)
//                    })
//                }
//            } else {
                if self.hasNotesHTML {
                    transcript = AlertAction(title: Constants.Strings.HTML_Transcript, style: .default) { [weak self] in
                        // test:(()->(Bool))?
                        viewController.process(work: { [weak self] () -> (Any?) in
                            _ = self?.notesHTML?.result
                        }, completion: { [weak self] (data:Any?) in
                            self?.view(viewController:viewController, bodyHTML:self?.notesHTML?.result)
                        })
                    }
                }
//            }
        }

        scripture = AlertAction(title: Constants.Strings.Scripture, style: .default) { [weak self] in
            guard let reference = self?.scriptureReference else {
                return
            }
            
            if self?.scripture?.html?[reference] != nil {
                viewController.popoverHTML(title:reference, bodyHTML:self?.scripture?.text(reference), sourceView:viewController.view, sourceRectView:viewController.view, htmlString:self?.scripture?.html?[reference], search:false)
            } else {
                guard Globals.shared.reachability.isReachable else {
                    viewController.networkUnavailable("Scripture text unavailable.")
                    return
                }
                
                // test:(()->(Bool))?
                viewController.process(work: { [weak self] () -> (Any?) in
                    self?.scripture?.load()
                    return self?.scripture?.html?[reference]
                }, completion: { [weak self] (data:Any?) in
                    if let htmlString = data as? String {
                        viewController.popoverHTML(title:reference, bodyHTML:self?.scripture?.text(reference), sourceView:viewController.view, sourceRectView:viewController.view, htmlString:htmlString, search:false)
                    } else {
                        Alerts.shared.alert(title:"Scripture Unavailable")
                    }
                })
            }
        }
        
        voiceBase = AlertAction(title: Constants.Strings.VoiceBase, style: .default) { [weak self] in
            var alertActions = [AlertAction]()
            
            if let actions = self?.audioTranscript?.alertActions(viewController:viewController) {
                alertActions.append(actions)
            }
            if let actions = self?.videoTranscript?.alertActions(viewController:viewController) {
                alertActions.append(actions)
            }
            
            // At most, only ONE of the following TWO will be added.
            if  var vc = viewController as? PopoverTableViewControllerDelegate,
                let actions = self?.audioTranscript?.timingIndexAlertActions(viewController:viewController, completion: { (popover:PopoverTableViewController,name:String)->(Void) in
                vc.popover?[name] = popover
            }) {
                if self == Globals.shared.mediaPlayer.mediaItem, self?.playing == Playing.audio, self?.audioTranscript?.mediaJSON != nil {
                    alertActions.append(actions)
                }
            }
            if  var vc = viewController as? PopoverTableViewControllerDelegate,
                let actions = self?.videoTranscript?.timingIndexAlertActions(viewController:viewController, completion: { (popover:PopoverTableViewController,name:String)->(Void) in
                vc.popover?[name] = popover
            }) {
                if self == Globals.shared.mediaPlayer.mediaItem, self?.playing == Playing.video, self?.videoTranscript?.mediaJSON != nil {
                    alertActions.append(actions)
                }
            }
            
            var message = Constants.Strings.Machine_Generated + " " + Constants.Strings.Transcript
            
            if let text = self?.text {
                message += "\n\n\(text)"
            }
            
            if alertActions.count > 1 {
                viewController.alertActionsCancel( title: Constants.Strings.VoiceBase,
                                                   message: message,
                                                   alertActions: alertActions,
                                                   cancelAction: nil)
            } else {
                if alertActions.count == 1 {
                    alertActions[0].handler?()
                }
            }
        }
        
        topics = AlertAction(title: "List", style: .default) { [weak self] in
            if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = "Topics"
                
                popover.selectedMediaItem = self
                
                popover.search = true
                
                popover.delegate = viewController as? PopoverTableViewControllerDelegate
                popover.purpose = .selectingTimingIndexTopic
                popover.section.strings = self?.audioTranscript?.topics?.sorted()
                
                viewController.present(navigationController, animated: true, completion: {
                    (viewController as? MediaTableViewController)?.popover?["TOPICS"] = popover
                    (viewController as? MediaViewController)?.popover?["TOPICS"] = popover
                })
            }
        }
        
        if self.scripture?.books != nil {
            actions.append(scripture)
        }

        if (viewController as? MediaTableViewController) != nil {
            if hasTags {
                actions.append(tags)
            }
            
            actions.append(search)

            if hasNotesText {
                actions.append(words)
            }
        }
        
        if hasNotes, transcript != nil {
//            if #available(iOS 11.0, *) {
//                actions.append(transcript)
//            } else {
                if hasNotesHTML {
                    actions.append(transcript)
                }
//            }
        }

        actions.append(favorites)
        
        actions.append(openOnCBC)

        actions.append(share)
        
        if hasAudio && (download != nil) {
            actions.append(download)
        }
        
        if Globals.shared.allowMGTs {
            actions.append(voiceBase)
        }

        if hasCacheFiles {
            actions.append(clearCache)
        }

        return actions.count > 0 ? actions : nil
    }
}
