//
//  Sermon.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

                            //Group//String//Sort
typealias SermonGroupSort = [String:[String:[String:[Sermon]]]]

                             //Group//String//Name
typealias SermonGroupNames = [String:[String:String]]

class SermonsListGroupSort {
    var list:[Sermon]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:Sermon]()
                
                for sermon in list! {
                    index![sermon.id!] = sermon
                }
            }
        }
    }
    var index:[String:Sermon]? //Sermons indexed by ID.
    
    var groupSort:SermonGroupSort?
    var groupNames:SermonGroupNames?
    
    var tagSermons:[String:[Sermon]]?//sortTag:Sermon
    var tagNames:[String:String]?//sortTag:tag
    
    var sermonTags:[String]? {
        get {
            return tagSermons?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                return self.tagNames![string]!
            })
        }
    }
    
//    func archiveList() -> [String]?
//    {
//        return list?.map({ (sermon:Sermon) -> String in
//            return "\(globals.sermonRepository.list!.indexOf(sermon)!)"
//        })
//    }
//    
//    func unarchiveList(sermons:[String]?)
//    {
//        list = sermons?.map({ (index:String) -> Sermon in
//            return globals.sermonRepository.list![Int(index)!]
//        })
//    }
//    
//    func archiveGroupSort() -> [String:[String:[String:[String]]]]?
//    {
//        var dict = [String:[String:[String:[String]]]]()
//        
//        for groupKey in groupSort!.keys {
//            dict[groupKey] = [String:[String:[String]]]()
//            for groupNameKey in groupSort![groupKey]!.keys {
//                dict[groupKey]![groupNameKey] = [String:[String]]()
//                for sortKey in groupSort![groupKey]![groupNameKey]!.keys {
//                    dict[groupKey]![groupNameKey]![sortKey] = groupSort![groupKey]![groupNameKey]![sortKey]?.map({ (sermon:Sermon) -> String in
//                        return sermon.id!
//                    })
//                }
//            }
//            
//        }
//        return dict
//    }
//    
//    func unarchiveGroupSort(gs:[String:[String:[String:[String]]]]?)
//    {
//        groupSort = [String:[String:[String:[Sermon]]]]()
//        
//        for groupKey in gs!.keys {
//            groupSort?[groupKey] = [String:[String:[Sermon]]]()
//            for groupNameKey in gs![groupKey]!.keys {
//                groupSort?[groupKey]![groupNameKey] = [String:[Sermon]]()
//                for sortKey in gs![groupKey]![groupNameKey]!.keys {
//                    groupSort?[groupKey]![groupNameKey]![sortKey] = gs![groupKey]![groupNameKey]![sortKey]?.filter({ (index:String) -> Bool in
//                        return globals.sermonRepository.index![index] != nil
//                    }).map({ (index:String) -> Sermon in
//                        return globals.sermonRepository.index![index]!
//                    })
//                }
//            }
//        }
//    }
//    
//    func archiveGroupNames() -> [String:[String:String]]?
//    {
//        return groupNames
//    }
//    
//    func unarchiveGroupNames(gn:[String:[String:String]]?)
//    {
//        groupNames = gn
//    }
//    
//    func archiveTagSermons() -> [String:[String]]?
//    {
//        var dict = [String:[String]]()
//        
//        for key in tagSermons!.keys {
//            dict[key] = tagSermons?[key]?.map({ (sermon:Sermon) -> String in
//                return sermon.id!
//            })
//        }
//        
//        return dict
//    }
//    
//    func unarchiveTagSermons(ts:[String:[String]]?)
//    {
//        tagSermons = [String:[Sermon]]()
//        
//        for key in ts!.keys {
//            tagSermons?[key] = ts?[key]?.filter({ (index:String) -> Bool in
//                return globals.sermonRepository.index![index] != nil
//            }).map({ (index:String) -> Sermon in
//                return globals.sermonRepository.index![index]!
//            })
//        }
//    }
//    
//    func archiveTagNames() -> [String:String]?
//    {
//        return tagNames
//    }
//    
//    func unarchiveTagNames(tn:[String:String]?)
//    {
//        tagNames = tn
//    }
    
    var sermons:[Sermon]? {
        get {
            return sermons(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        if (list == nil) {
            return
        }
        
        var string:String?
        var name:String?
        
        var groupedSermons = [String:[String:[Sermon]]]()
        
        globals.finished += list!.count
        
        for sermon in list! {
            switch grouping! {
            case Grouping.YEAR:
                string = sermon.yearString
                name = string
                break
                
            case Grouping.TITLE:
                string = sermon.seriesSectionSort
                name = sermon.seriesSection
                break
                
            case Grouping.BOOK:
                string = sermon.bookSection
                name = sermon.bookSection
                break
                
            case Grouping.SPEAKER:
                string = sermon.speakerSectionSort
                name = sermon.speakerSection
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping!] == nil) {
                groupNames?[grouping!] = [String:String]()
            }
            
            groupNames?[grouping!]?[string!] = name!
            
            if (groupedSermons[grouping!] == nil) {
                groupedSermons[grouping!] = [String:[Sermon]]()
            }
            
            if groupedSermons[grouping!]?[string!] == nil {
                groupedSermons[grouping!]?[string!] = [sermon]
            } else {
                groupedSermons[grouping!]?[string!]?.append(sermon)
            }
            
            globals.progress += 1
        }
        
        if (groupedSermons[grouping!] != nil) {
            globals.finished += groupedSermons[grouping!]!.keys.count
        }
        
        if (groupSort?[grouping!] == nil) {
            groupSort?[grouping!] = [String:[String:[Sermon]]]()
        }
        if (groupedSermons[grouping!] != nil) {
            for string in groupedSermons[grouping!]!.keys {
                if (groupSort?[grouping!]?[string] == nil) {
                    groupSort?[grouping!]?[string] = [String:[Sermon]]()
                }
                for sort in Constants.sortings {
                    let array = sortSermonsChronologically(groupedSermons[grouping!]?[string])
                    
                    switch sort {
                    case Constants.CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array
                        break
                        
                    case Constants.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array?.reversed()
                        break
                        
                    default:
                        break
                    }
                    
                    globals.progress += 1
                }
            }
        }
    }
    
    func sermons(grouping:String?,sorting:String?) -> [Sermon]?
    {
        var groupedSortedSermons:[Sermon]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        NSLog("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sorted(
                by: {
                    switch grouping! {
                    case Grouping.YEAR:
                        switch sorting! {
                        case Constants.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Constants.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case Grouping.BOOK:
                        if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                        } else {
                            return bookNumberInBible($0) < bookNumberInBible($1)
                        }
                        
                    default:
                        break
                    }
                    
                    return $0 < $1
            }) {
                let sermons = groupSort?[grouping!]?[key]?[sorting!]
                if (groupedSortedSermons == nil) {
                    groupedSortedSermons = sermons
                } else {
                    groupedSortedSermons?.append(contentsOf: sermons!)
                }
            }
        }
        
        return groupedSortedSermons
    }
    
    var sectionIndexTitles:[String]? {
        get {
            return sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    var sectionTitles:[String]? {
        get {
            return sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        })
    }
    
    var sectionCounts:[Int]? {
        get {
            return sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            return groupSort![grouping!]![string]![sorting!]!.count
        })
    }
    
    var sectionIndexes:[Int]? {
        get {
            return sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        var cumulative = 0
        
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            cumulative += groupSort![grouping!]![string]![sorting!]!.count
            
            return prior
        })
    }
    
    init(sermons:[Sermon]?)
    {
        if (sermons != nil) {
            globals.finished = 0
            globals.progress = 0
            
            list = sermons
            
            groupNames = SermonGroupNames()
            groupSort = SermonGroupSort()
            tagSermons = [String:[Sermon]]()
            tagNames = [String:String]()
            
            sortGroup(globals.grouping)

            globals.finished += list!.count
            
            for sermon in list! {
                if let tags =  sermon.tagsSet {
                    for tag in tags {
                        let sortTag = stringWithoutPrefixes(tag)
                        if tagSermons?[sortTag!] == nil {
                            tagSermons?[sortTag!] = [sermon]
                        } else {
                            tagSermons?[sortTag!]?.append(sermon)
                        }
                        tagNames?[sortTag!] = tag
                    }
                }
                globals.progress += 1
            }
        } else {
            globals.finished = 1
            globals.progress = 1
        }
    }
}

enum State {
    case downloading
    case downloaded
    case none
}

var debug = false

class Download {
    weak var sermon:Sermon?
    
    var purpose:String?
    
    var downloadURL:URL?
    var fileSystemURL:URL? {
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:URLSession? // We're using a session for each download.  Not sure is the best but it works for TWU.
    
    var task:URLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    
    var state:State = .none {
        didSet {
            if state != oldValue {
                if (purpose == Purpose.audio) {
                    if state == .downloaded {
                        sermon?.addTag(Constants.Downloaded)
                    } else {
                        sermon?.removeTag(Constants.Downloaded)
                    }
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    // The following must appear AFTER we change the state
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: self.sermon)
                })
            }
        }
    }
    
    var completionHandler: ((Void) -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
//            print(fileSystemURL!.path!)
//            print(FileManager.default.fileExists(atPath: fileSystemURL!.path!))
            return FileManager.default.fileExists(atPath: fileSystemURL!.path)
        } else {
            return false
        }
    }
    
    var fileSize:Int
    {
        var size = 0
        
        if fileSystemURL != nil {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL!.path)
                size = fileAttributes[FileAttributeKey.size] as! Int
            } catch _ {
                NSLog("failed to get file attributes for \(fileSystemURL!)")
            }
        }
        
        return size
    }
    
    func download()
    {
        if (state == .none) {
            state = .downloading
            
            if (downloadURL == nil) {
                NSLog("\(sermon?.title)")
                NSLog("\(purpose)")
                NSLog("\(fileSystemURL)")
            }
            
            let downloadRequest = URLRequest(url: downloadURL!)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            let configuration = URLSessionConfiguration.background(withIdentifier: Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent)
            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            session = URLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
            
            session?.sessionDescription = self.fileSystemURL!.lastPathComponent
            
            task = session?.downloadTask(with: downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
        }
    }
    
    func deleteDownload()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (FileManager.default.fileExists(atPath: fileSystemURL!.path)){
                do {
                    try FileManager.default.removeItem(at: fileSystemURL!)
                } catch _ {
                    NSLog("failed to delete download")
                }
            }
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }

    func cancelOrDeleteDownload()
    {
        switch state {
        case .downloading:
            cancelDownload()
            break
            
        case .downloaded:
            deleteDownload()
            break
            
        default:
            break
        }
    }
    
    func cancelDownload()
    {
        if (active) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            task?.cancel()
            task = nil
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
}

class Sermon : NSObject, URLSessionDownloadDelegate {
    var dict:[String:String]?
    
    var singleLoaded = false

    init(dict:[String:String]?)
    {
        super.init()
//        NSLog("\(dict)")
        self.dict = dict
    }
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Purpose.audio
        download.downloadURL = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Purpose.audio] = download
        return download
        }()
    
    lazy var videoDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Purpose.video
        download.downloadURL = self.videoURL
        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Purpose.video] = download
        return download
        }()
    
    lazy var slidesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Purpose.slides
        download.downloadURL = self.slidesURL
        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Purpose.slides] = download
        return download
        }()
    
    lazy var notesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Purpose.notes
        download.downloadURL = self.notesURL
        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Purpose.notes] = download
        return download
        }()
    
    lazy var outlineDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Purpose.outline
        download.downloadURL = self.outlineURL
        download.fileSystemURL = self.outlineFileSystemURL
        self.downloads[Purpose.outline] = download
        return download
        }()
    
//    required convenience init?(coder decoder: NSCoder)
//    {
//        guard
//            
//            let dict = decoder.decodeObjectForKey(Constants.DICT) as? [String:String]
//            
//            else {
//                return nil
//            }
//        
//        self.init(dict: dict)
//    }
//    
//    func encodeWithCoder(coder: NSCoder) {
//        coder.encodeObject(self.dict, forKey: Constants.DICT)
//    }
    
    var id:String! {
        get {
            // This should be constructed from the speaker (first and last initial), date, and service. E.g. tp160501a
            // BUT it doesn't work for gs == Guest Speaker
//            if speaker != nil {
//                let firstName = speaker!.substringToIndex(speaker!.rangeOfString(" ")!.startIndex)
//                let lastName = speaker!.substringFromIndex(speaker!.rangeOfString(" ")!.endIndex)
//                
//                let firstInitial = firstName.lowercaseString.substringToIndex("a".endIndex)
//                let lastInitial = lastName.lowercaseString.substringToIndex("a".endIndex)
//                
//                let calendar = NSCalendar.currentCalendar()
//                
//                let year = String(format: "%02d",calendar.components(.Year, fromDate: fullDate!).year % 1000)
//                let month = String(format: "%02d",calendar.components(.Month, fromDate: fullDate!).month)
//                let day = String(format: "%02d",calendar.components(.Day, fromDate: fullDate!).day)
//
//                let service = self.service!.lowercaseString.substringToIndex("a".endIndex)
//                
//                let idString = firstInitial + lastInitial + year + month + day + service
//                
////                print(idString)
//            }
            
            return dict![Field.id]
            
//            if dict?[Constants.ID] != nil {
//                return dict?[Constants.ID]
//            } else {
//                if let cd = audio?.range(of: "CD") {
//                    return audio?.substring(to: cd.lowerBound)
//                } else {
//                    return audio?.substring(to: audio!.range(of: Constants.MP3_FILENAME_EXTENSION)!.lowerBound)
//                }
//            }
        }
    }
    
    var sermonsInSeries:[Sermon]? {
        get {
            if (hasSeries) {
                var seriesSermons:[Sermon]?
                
                if (globals.sermons.all?.groupSort?[Grouping.TITLE]?[seriesSort!]?[Constants.CHRONOLOGICAL] == nil) {
                    seriesSermons = globals.sermonRepository.list?.filter({ (testSermon:Sermon) -> Bool in
                        let sameSeries = hasSeries ? (testSermon.series == series) : (testSermon.id == id)
                        let sameCategory = hasCategory ? (testSermon.category == category) : (testSermon.id == id)
                        
                        return sameSeries && sameCategory
                    })

                } else {
                    seriesSermons = globals.sermons.all?.groupSort?[Grouping.TITLE]?[seriesSort!]?[Constants.CHRONOLOGICAL]?.filter({ (testSermon:Sermon) -> Bool in
                        let sameSeries = hasSeries ? (testSermon.series == series) : (testSermon.id == id)
                        let sameCategory = hasCategory ? (testSermon.category == category) : (testSermon.id == id)
                        
                        return sameSeries && sameCategory
                    })
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
                if id.range(of: "s")?.lowerBound == "flYYMMDD".endIndex {
                    if let range = id.range(of: "s") {
                        let simpleID = id.substring(to: range.upperBound)
//                        print(simpleID)
                        return sortSermonsByYear(seriesSermons?.filter({ (testSermon:Sermon) -> Bool in
                            return testSermon.id.substring(to: range.upperBound) == simpleID
                        }),sorting: Constants.CHRONOLOGICAL)
                    }
                    
                    return nil
                } else {
                    return sortSermonsByYear(seriesSermons, sorting: Constants.CHRONOLOGICAL)
                }
            } else {
                return [self]
            }
        }
    }
    
    func sermonsInCollection(_ tag:String) -> [Sermon]?
    {
        var sermons:[Sermon]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            sermons = globals.sermons.all?.tagSermons?[tag]
        }
        
        return sermons
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
    
    var isPlaying:Bool {
        get {
            return globals.player.mpPlayer?.contentURL == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String? {
        get {
            if (dict![Field.playing] == nil) {
                if let playing = settings?[Field.playing] {
                    dict![Field.playing] = playing
                } else {
                    dict![Field.playing] = Playing.audio
                }
            }
            return dict![Field.playing]
        }
        
        set {
            if newValue != dict![Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.player.playing == self {
                    globals.player.stateTime = nil //?.dateEntered = NSDate()
                }
                
                dict![Field.playing] = newValue
                settings?[Field.playing] = newValue
            }
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Field.showing] == nil) {
                if let showing = settings?[Field.showing] {
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
            dict![Field.showing] = newValue
            settings?[Field.showing] = newValue
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
        return (currentTime != nil) && (currentTime != "nan")
    }
    
    var currentTime:String? {
        get {
            if let current_time = settings?[Constants.CURRENT_TIME+playing!] {
                dict![Constants.CURRENT_TIME+playing!] = current_time
            } else {
                dict![Constants.CURRENT_TIME+playing!] = "\(0)"
            }
//            print(dict![Constants.CURRENT_TIME+playing!])
            return dict![Constants.CURRENT_TIME+playing!]
        }
        
        set {
            dict![Constants.CURRENT_TIME+playing!] = newValue
            settings?[Constants.CURRENT_TIME+playing!] = newValue
        }
    }
    
    var seriesID:String! {
        get {
            if (series != nil) {
                return series!
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
        return yearString
    }
    
    var yearString:String! {
        if (year != nil) {
            return "\(year!)"
        } else {
            return "None"
        }
    }

    func singleJSONFromURL() -> JSON
    {
        do {
            let data = try Data(contentsOf: URL(string: Constants.SINGLE_JSON_URL + self.id!)!, options: NSData.ReadingOptions.mappedIfSafe)
            
            let json = JSON(data: data)
            if json != JSON.null {
                
                print(json)
                return json
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
    func loadSingleDict() -> [String:String]?
    {
        var sermonDicts = [[String:String]]()
        
        let json = singleJSONFromURL() // jsonDataFromDocumentsDirectory()
        
        if json != JSON.null {
            //            NSLog("json:\(json)")
            
            let sermons = json[Constants.JSON_SINGLE_ARRAY_KEY]
            
            for i in 0..<sermons.count {
                
                var dict = [String:String]()
                
                for (key,value) in sermons[i] {
                    dict["\(key)"] = "\(value)"
                }
                
                sermonDicts.append(dict)
            }
            
            print(sermonDicts)
            
            return sermonDicts.count > 0 ? sermonDicts[0] : nil
        } else {
            NSLog("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func loadSingle()
    {
        print(date,title)
        
        if !singleLoaded && globals.loadSingles {
            self.singleLoaded = true
            DispatchQueue.global(qos: .default).async { () -> Void in
                if let sermonDict = self.loadSingleDict() {
                    self.dict![Field.audio] = sermonDict[Field.audio]
                    self.dict![Field.video] = sermonDict[Field.video]
                    self.dict![Field.notes] = sermonDict[Field.notes]
                    self.dict![Field.slides] = sermonDict[Field.slides]
                    
                    DispatchQueue.main.async { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: self)
                    }
                } else {
                    NSLog("loadSingle failure")
                }
            }
        }
    }
    
    var date:String? {
        get {
            return dict![Field.date]?.substring(to: dict![Field.date]!.range(of: " ")!.lowerBound) // last two characters // dict![Field.title]
        }
    }
    
    var service:String? {
        get {
            return dict![Field.date]?.substring(from: dict![Field.date]!.range(of: " ")!.upperBound) // last two characters // dict![Field.title]
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
    
    var scripture:String? {
        get {
            return dict![Field.scripture]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return hasSpeaker ? speakerSort! : Constants.None
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
                if let speakerSort = settings?[Field.speaker_sort] {
                    dict![Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"
                    
                    if var speakerSort = speaker {
                        while (speakerSort.range(of: Constants.SINGLE_SPACE_STRING) != nil) {
                            speakerSort = speakerSort.substring(from: speakerSort.range(of: Constants.SINGLE_SPACE_STRING)!.upperBound)
                        }
                        dict![Field.speaker_sort] = speakerSort
//                        settings?[Field.speaker_sort] = speakerSort
                    } else {
                        NSLog("NO SPEAKER")
                    }
                }
            }
            if dict![Field.speaker_sort] == nil {
                NSLog("Speaker sort is NIL")
            }
            return dict![Field.speaker_sort]
        }
    }
    
    var seriesSectionSort:String! {
        get {
            return hasSeries ? seriesSort! : stringWithoutPrefixes(title)! // Constants.Individual_Sermons
        }
    }
    
    var seriesSection:String! {
        get {
            return hasSeries ? series! : title! // Constants.Individual_Sermons
        }
    }
    
    // this saves calculated values in defaults between sessions
    var seriesSort:String? {
        get {
            if dict![Field.series_sort] == nil {
                if let seriesSort = settings?[Field.series_sort] {
                    dict![Field.series_sort] = seriesSort
                } else {
                    if let seriesSort = stringWithoutPrefixes(series) {
                        dict![Field.series_sort] = seriesSort
//                        settings?[Constants.SERIES_SORT] = seriesSort
                    } else {
                        NSLog("seriesSort is nil")
                    }
                }
            }
            return dict![Field.series_sort]
        }
    }
    
    var series:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if (dict![Field.series] == nil) {
                if (title?.range(of: Constants.SERIES_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let seriesString = title!.substring(to: (title?.range(of: Constants.SERIES_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.lowerBound)!)
                    dict![Field.series] = seriesString
                }
            }
            
            return dict![Field.series]
        }
    }
    
    var part:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if hasSeries && (dict![Field.part] == nil) {
                if (title?.range(of: Constants.SERIES_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let partString = title!.substring(from: (title?.range(of: Constants.SERIES_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.upperBound)!)
//                    print(partString)
                    dict![Field.part] = partString.substring(to: partString.range(of: ")")!.lowerBound)
                }
            }
            
//            print(dict![Field.part])
            return dict![Field.part]
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            if let tags = settings?[Field.tags] {
                if dict![Field.tags] != nil {
                    return dict![Field.tags]! + Constants.TAGS_SEPARATOR + tags
                } else {
                    return tags
                }
            } else {
                return dict![Field.tags]
            }
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
        let tags = tagsArrayFromTagsString(settings![Field.tags])
        
        if tags?.index(of: tag) == nil {
            if (settings?[Field.tags] == nil) {
                settings?[Field.tags] = tag
            } else {
                settings?[Field.tags] = settings![Field.tags]! + Constants.TAGS_SEPARATOR + tag
            }
            
            let sortTag = stringWithoutPrefixes(tag)
            
            if globals.sermons.all!.tagSermons![sortTag!] != nil {
                if globals.sermons.all!.tagSermons![sortTag!]!.index(of: self) == nil {
                    globals.sermons.all!.tagSermons![sortTag!]!.append(self)
                    globals.sermons.all!.tagNames![sortTag!] = tag
                }
            } else {
                globals.sermons.all!.tagSermons![sortTag!] = [self]
                globals.sermons.all!.tagNames![sortTag!] = tag
            }
            
            if (globals.tags.selected == tag) {
                globals.sermons.tagged = SermonsListGroupSort(sermons: globals.sermons.all?.tagSermons?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_SERMON_LIST_NOTIFICATION), object: globals.sermons.tagged)
                })
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: self)
            })
        }
    }
    
    func removeTag(_ tag:String)
    {
        if (settings?[Field.tags] != nil) {
            var tags = tagsArrayFromTagsString(settings![Field.tags])
            
            if tags?.index(of: tag) != nil {
                tags?.remove(at: tags!.index(of: tag)!)
                settings?[Field.tags] = tagsArrayToTagsString(tags)
                
                let sortTag = stringWithoutPrefixes(tag)
                
                if let index = globals.sermons.all?.tagSermons?[sortTag!]?.index(of: self) {
                    globals.sermons.all?.tagSermons?[sortTag!]?.remove(at: index)
                }
                
                if (globals.tags.selected == tag) {
                    globals.sermons.tagged = SermonsListGroupSort(sermons: globals.sermons.all?.tagSermons?[sortTag!])
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_SERMON_LIST_NOTIFICATION), object: globals.sermons.tagged)
                    })
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: self)
                })
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
    
    var tagsSet:Set<String>? {
        get {
            var tag:String
            var tags = self.tags
            var tagsSet = Set<String>()
            
            while (tags?.range(of: Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substring(to: tags!.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
                tagsSet.insert(tag)
                tags = tags!.substring(from: tags!.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            
            return tagsSet.count == 0 ? nil : tagsSet
        }
    }
    
    var tagsArray:[String]? {
        get {
            return tagsSet == nil ? nil : Array(tagsSet!).sorted() { $0 < $1 }
        }
    }
    
    //    Slides: Constants.BASE_MEDIA_URL+{year}/{mediacode}slides.pdf
    //    Outline: Constants.BASE_MEDIA_URL+{year}/{mediacode}outline.pdf
    //    Transcript: Constants.BASE_MEDIA_URL+{year}/{mediacode}transcript.pdf

    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio {
                dict![Field.audio] = Constants.BASE_MEDIA_URL + "\(year!)/\(id!)" + Constants.MP3_FILENAME_EXTENSION
            }
            
            if (dict?[Field.audio] == nil) {
                loadSingle()
            }
            
//            print(dict![Field.audio])
            
            return dict![Field.audio]
        }
        
//        set {
//            dict![Field.audio] = newValue
//            dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
//            }
//        }
    }
    
    var video:String? {
        get {
            if (dict?[Field.video] == nil) && hasVideo {
                loadSingle()
            }
            return dict![Field.video]
        }
        
//        set {
//            dict![Field.video] = newValue
//            dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
//            }
//        }
    }
    
    // These are read-write
    
    // this supports set values that are saved in defaults between sessions
    var notes:String? {
        get {
            if (dict![Field.notes] == nil) && hasNotes { // \(year!)
                dict![Field.notes] = Constants.BASE_MEDIA_URL + "\(year!)/\(id!)" + Field.notes + Constants.PDF_FILE_EXTENSION
            }

            if dict![Field.notes] == nil {
                loadSingle()

//                if let notes = settings?[Field.notes] {
//                    dict![Field.notes] = notes
//                } else {
//                    // do nothing
//                }
            }
//            print(dict![Field.notes])
            return dict![Field.notes]
        }
        
//        set {
//            dict![Field.notes] = newValue
////            settings?[Field.notes] = newValue
//            dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
//            }
//        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if (dict![Field.slides] == nil) && hasSlides { // \(year!)
                dict![Field.slides] = Constants.BASE_MEDIA_URL + "\(year!)/\(id!)" + Field.slides + Constants.PDF_FILE_EXTENSION
            }
            
            if dict![Field.slides] == nil {
                loadSingle()
                
                //                if let slides = settings?[Field.slides] {
                //                    dict![Field.slides] = slides
                //                } else {
                //                    // do nothing
                //                }
            }
            return dict![Field.slides]
        }
        
        //        set {
        //            dict![Field.slides] = newValue
        ////            settings?[Field.slides] = newValue
        //            dispatch_async(dispatch_get_main_queue()) { () -> Void in
        //                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
        //            }
        //        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String? {
        get {
            if (dict![Field.outline] == nil) && hasSlides { // \(year!)
                dict![Field.outline] = Constants.BASE_MEDIA_URL + "\(year!)/\(id!)" + Field.outline + Constants.PDF_FILE_EXTENSION
            }
            
            if dict![Field.outline] == nil {
                loadSingle()
                
                //                if let slides = settings?[Field.slides] {
                //                    dict![Field.slides] = slides
                //                } else {
                //                    // do nothing
                //                }
            }
            return dict![Field.outline]
        }
        
        //        set {
        //            dict![Field.slides] = newValue
        ////            settings?[Field.slides] = newValue
        //            dispatch_async(dispatch_get_main_queue()) { () -> Void in
        //                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
        //            }
        //        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript

    var files:String? {
        get {
            return dict![Field.files]
        }
    }
    
    var hasAudio:Bool {
        get {
            return files != nil ? files!.contains("A") : false
        }
    }
    
    var hasVideo:Bool {
        get {
            return files != nil ? files!.contains("V") : false
        }
    }
    
    var hasSlides:Bool {
        get {
            return files != nil ? files!.contains("S") : false
        }
    }
    
    var hasNotes:Bool {
        get {
            return files != nil ? files!.contains("T") : false
        }
    }
    
    var hasOutline:Bool {
        get {
            return files != nil ? files!.contains("O") : false
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
//            print(video)
            return video != nil ? URL(string: video!) : nil
            
//            if video != nil {
//                let videoURL = Constants.BASE_VIDEO_URL_PREFIX + video!
//                
////                if video!.rangeOfString(".sd.") != nil {
////                    videoURL = videoURL + Constants.BASE_SD_VIDEO_URL_POSTFIX
////                } else
////                
////                if video!.rangeOfString(".hd.") != nil {
////                    videoURL = videoURL + Constants.BASE_HD_VIDEO_URL_POSTFIX
////                }
//
//                return NSURL(string: videoURL)
//            } else {
//                return nil
//            }
        }
    }
    
    var notesURL:URL? {
        get {
//            print(notes)
            return notes != nil ? URL(string: notes!) : nil
            
//            if (notes != nil) {
//                return NSURL(string: Constants.BASE_PDF_URL + notes!)
//            } else {
//                return nil
//            }
        }
    }
    
    var slidesURL:URL? {
        get {
//            if (title == "Our Eternal Home is the New Earth") {
//                print(slides)
//            }
//            
//            print(slides)
            return slides != nil ? URL(string: slides!) : nil
            
            //            if (slides != nil) {
            //                return NSURL(string: Constants.BASE_PDF_URL + slides!)
            //            } else {
            //                return nil
            //            }
        }
    }
    
    var outlineURL:URL? {
        get {
//            print(outline)
            return outline != nil ? URL(string: outline!) : nil
            
            //            if (slides != nil) {
            //                return NSURL(string: Constants.BASE_PDF_URL + slides!)
            //            } else {
            //                return nil
            //            }
        }
    }
    
    var audioFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.MP3_FILENAME_EXTENSION)

//            if (audio != nil) {
//                return cachesURL()?.URLByAppendingPathComponent(id! + Constants.MP3_FILENAME_EXTENSION)
//            } else {
//                return nil
//            }
        }
    }
    
    var videoFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.MP4_FILENAME_EXTENSION)

//            if video != nil {
//                return cachesURL()?.URLByAppendingPathComponent(id! + Constants.MP4_FILENAME_EXTENSION)
//            } else {
//                return nil
//            }
        }
    }
    
    var slidesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.slides + Constants.PDF_FILE_EXTENSION)

//            if (slides != nil) {
//                return cachesURL()?.URLByAppendingPathComponent(id! + ".slides")
//            } else {
//                return nil
//            }
        }
    }
    
    var notesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.notes + Constants.PDF_FILE_EXTENSION)

//            if (notes != nil) {
//                return cachesURL()?.URLByAppendingPathComponent(id! + ".transcript")
//            } else {
//                return nil
//            }
        }
    }
    
    var outlineFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.outline + Constants.PDF_FILE_EXTENSION)
            
            //            if (notes != nil) {
            //                return cachesURL()?.URLByAppendingPathComponent(id! + ".transcript")
            //            } else {
            //                return nil
            //            }
        }
    }
    
    var bookSection:String! {
        get {
            return hasBook ? book! : hasScripture ? scripture! : Constants.None
        }
    }
    
    var testament:String? {
        if (hasBook) {
            if (Constants.OLD_TESTAMENT_BOOKS.contains(book!)) {
                return Constants.Old_Testament
            }
            if (Constants.NEW_TESTAMENT_BOOKS.contains(book!)) {
                return Constants.New_Testament
            }
        } else {
            return nil
        }
        
        return nil
    }
    
    func chapters(_ thisBook:String) -> [Int]
    {
        var chaptersForBook = [Int]()
        
        let books = booksFromScripture(scripture)
        
        switch books.count {
        case 0:
            break
            
        case 1:
            if book == books.first {
                if ["Philemon","Jude","2 John","3 John"].contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scripture!
                    
                    if (string.range(of: ";") == nil) {
                        chaptersForBook = chaptersFromScripture(string.substring(from: scripture!.range(of: thisBook)!.upperBound))
                    } else {
                        repeat {
                            var subString = string.substring(to: string.range(of: ";")!.lowerBound)
                            
                            if (subString.range(of: thisBook) != nil) {
                                subString = subString.substring(from: subString.range(of: thisBook)!.upperBound)
                            }
                            chaptersForBook.append(contentsOf: chaptersFromScripture(subString))
                            
                            string = string.substring(from: string.range(of: ";")!.upperBound)
                        } while (string.range(of: ";") != nil)
                        
                        //                        print(string)
                        if (string.range(of: thisBook) != nil) {
                            string = string.substring(from: string.range(of: thisBook)!.upperBound)
                        }
                        chaptersForBook.append(contentsOf: chaptersFromScripture(string))
                    }
                }
            }
            break
            
        default:
            var scriptures = [String]()
            
            var string = scripture!
            
            let separator = ";"
            
            repeat {
                if string.range(of: separator) != nil {
                    scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                    string = string.substring(from: string.range(of: separator)!.upperBound)
                }
            } while (string.range(of: separator) != nil)
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if (scripture.range(of: thisBook) != nil) {
                    chaptersForBook.append(contentsOf: chaptersFromScripture(scripture.substring(from: scripture.range(of: thisBook)!.upperBound)))
                }
            }
            break
        }
        
//        if chaptersForBook.count > 1 {
//            NSLog("\(scripture)")
//            NSLog("\(chaptersForBook)")
//        }
        
        return chaptersForBook
    }
    
    var books:[String]? {
        get {
            return booksFromScripture(scripture)
        }
    } //Derived from scripture
    
    var book:String? {
        get {
            if (dict![Field.book] == nil) {
                if let bookTitle = settings?[Field.book] {
                    dict![Field.book] = bookTitle
                } else {
                    if (scripture == Constants.Selected_Scriptures) {
//                        dict![Field.book] = Constants.Selected_Scriptures
                    } else {
                        if scripture != nil {
                            if (dict![Field.book] == nil) {
                                for bookTitle in Constants.OLD_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                            dict![Field.book] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Field.book] == nil) {
                                for bookTitle in Constants.NEW_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                            dict![Field.book] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Field.book] != nil) {
//                                settings?[Field.book] = dict![Field.book]
                            }
                        }
                    }
                }
            }
            
            return dict![Field.book]
        }
    }//Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if (self.hasDate()) {
            return Date(dateString:self.date!)
        } else {
            return nil
        }
    }()//Derived from date
    
    var text : String? {
        get {
            var string:String?
            
            if hasDate() {
                string = date
            } else {
                string = "No Date"
            }
            
            if hasSpeaker {
                string = string! + " \(speaker!)"
            }
            
            if hasTitle() {
                if (title!.range(of: ", Part ") != nil) {
                    let first = title!.substring(to: (title!.range(of: " (Part")?.upperBound)!)
                    let second = title!.substring(from: (title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture {
                string = string! + "\n\(scripture!)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var sermonString = "Sermon: "
        
        if (date != nil) {
            sermonString = "\(sermonString) \(date!)"
        }
        
        if (service != nil) {
            sermonString = "\(sermonString) \(service!)"
        }
        
        if (title != nil) {
            sermonString = "\(sermonString) \(title!)"
        }
        
        if (speaker != nil) {
            sermonString = "\(sermonString) \(speaker!)"
        }
        
        return sermonString
    }
    
    struct Settings {
        var sermon:Sermon?
        
        init(sermon:Sermon?) {
            if (sermon == nil) {
                NSLog("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.settings?[sermon!.id]?[key]
            }
            set {
                if (sermon != nil) {
                    if (globals.settings != nil) {
                        if (globals.settings?[sermon!.id] == nil) {
                            globals.settings?[sermon!.id] = [String:String]()
                        }
                        if (globals.settings?[sermon!.id]?[key] != newValue) {
                            //                        NSLog("\(sermon)")
                            globals.settings?[sermon!.id]?[key] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        NSLog("globals.settings == nil in Settings!")
                    }
                } else {
                    NSLog("sermon == nil in Settings!")
                }
            }
        }
    }
    
    lazy var settings:Settings? = {
        return Settings(sermon:self)
    }()
    
    struct SeriesSettings {
        var sermon:Sermon?
        
        init(sermon:Sermon?) {
            if (sermon == nil) {
                NSLog("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.viewSplits?[sermon!.seriesID]
            }
            set {
                if (sermon != nil) {
                    if (globals.viewSplits != nil) {
                        if (globals.viewSplits?[sermon!.seriesID] != newValue) {
                            globals.viewSplits?[sermon!.seriesID] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        NSLog("globals.viewSplits == nil in SeriesSettings!")
                    }
                } else {
                    NSLog("sermon == nil in SeriesSettings!")
                }
            }
        }
    }
    
    lazy var seriesSettings:SeriesSettings? = {
        return SeriesSettings(sermon:self)
    }()
    
    var viewSplit:String? {
        get {
            return seriesSettings?[seriesID]
        }
        set {
            seriesSettings?[seriesID] = newValue
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }

        if (download != nil) {
            if debug {
                NSLog("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
                
                NSLog("session: \(session.sessionDescription)")
                NSLog("downloadTask: \(downloadTask.taskDescription)")
                
                if (download?.fileSystemURL != nil) {
                    NSLog("path: \(download!.fileSystemURL!.path)")
                    NSLog("filename: \(download!.fileSystemURL!.lastPathComponent)")
                    
                    if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                        NSLog("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
                    }
                } else {
                    NSLog("No fileSystemURL")
                }
                
                NSLog("bytes written: \(totalBytesWritten)")
                NSLog("bytes expected to write: \(totalBytesExpectedToWrite)")
            }
            
            if (download?.state == .downloading) {
                download?.totalBytesWritten = totalBytesWritten
                download?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                NSLog("ERROR NOT DOWNLOADING")
            }
        } else {
            NSLog("ERROR NO DOWNLOAD")
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        })
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
        
        if (download != nil) {
            if (download!.fileSystemURL != nil) {
                if debug {
                    NSLog("URLSession:downloadTask:didFinishDownloadingToURL:")
                    
                    NSLog("session: \(session.sessionDescription)")
                    NSLog("downloadTask: \(downloadTask.taskDescription)")
                    
                    NSLog("purpose: \(download!.purpose!)")
                    
                    NSLog("path: \(download!.fileSystemURL!.path)")
                    NSLog("filename: \(download!.fileSystemURL!.lastPathComponent)")
                    
                    if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                        NSLog("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
                    }
                    
                    NSLog("bytes written: \(download!.totalBytesWritten)")
                    NSLog("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
                }
                
                let fileManager = FileManager.default
                
                // Check if file exists
                if (fileManager.fileExists(atPath: download!.fileSystemURL!.path)){
                    do {
                        try fileManager.removeItem(at: download!.fileSystemURL!)
                    } catch _ {
                        NSLog("failed to remove duplicate download")
                    }
                }
                
                //            NSLog("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
                
                do {
                    if (download?.state == .downloading) {
                        if debug {
                            NSLog("\(location)")
                        }
                        try fileManager.copyItem(at: location, to: download!.fileSystemURL!)
                        try fileManager.removeItem(at: location)
                        download?.state = .downloaded
                    }
                } catch _ {
                    NSLog("failed to copy temp download file")
                    download?.state = .none
                }
            } else {
                NSLog("NO FILE SYSTEM URL!")
            }
        } else {
            NSLog("NO DOWNLOAD FOUND!")
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
        
        if (download != nil) {
            if debug {
                NSLog("URLSession:task:didCompleteWithError:")
                
                NSLog("session: \(session.sessionDescription)")
                NSLog("task: \(task.taskDescription)")
                
                NSLog("purpose: \(download!.purpose!)")
                
                if (download?.fileSystemURL != nil) {
                    NSLog("path: \(download!.fileSystemURL!.path)")
                    NSLog("filename: \(download!.fileSystemURL!.lastPathComponent)")
                    
                    if (task.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                        NSLog("task.taskDescription != download!.fileSystemURL.lastPathComponent")
                    }
                } else {
                    NSLog("No fileSystemURL")
                }
                
                NSLog("bytes written: \(download!.totalBytesWritten)")
                NSLog("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
            }
            
           if (error != nil) {
                NSLog("with error: \(error!.localizedDescription)")
                download?.state = .none
            }
        } else {
            NSLog("NO DOWNLOAD FOUND!")
        }

        //        NSLog("Download error: \(error)")
        //
        //        if (download?.totalBytesExpectedToWrite == 0) {
        //            download?.state = .none
        //        } else {
        //            NSLog("Download succeeded for: \(session.description)")
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
        
        if (download != nil) {
            if debug {
                NSLog("URLSession:didBecomeInvalidWithError:")
                
                NSLog("session: \(session.sessionDescription)")

                NSLog("purpose: \(download!.purpose!)")
                
                if (download?.fileSystemURL != nil) {
                    NSLog("path: \(download!.fileSystemURL!.path)")
                    NSLog("filename: \(download!.fileSystemURL!.lastPathComponent)")
                } else {
                    NSLog("No fileSystemURL")
                }
                
                NSLog("bytes written: \(download!.totalBytesWritten)")
                NSLog("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
            }
            
            if (error != nil) {
                NSLog("with error: \(error!.localizedDescription)")
            }
        } else {
            NSLog("NO DOWNLOAD FOUND!")
        }
        
        download?.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        NSLog("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var filename:String?
        
        filename = session.configuration.identifier!.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                NSLog("\(filename) \(key)")
            return value.task?.taskDescription == filename
        }).first?.1 {
            download.completionHandler?()
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
            return (self.scripture != nil) && (self.scripture != Constants.EMPTY_STRING)
        }
    }
    
    var hasSeries:Bool
        {
        get {
            return (self.series != nil) && (self.series != Constants.EMPTY_STRING)
        }
    }
    
    var hasCategory:Bool
        {
        get {
            return (self.category != nil) && (self.category != Constants.EMPTY_STRING)
        }
    }
    
    var hasBook:Bool
    {
        get {
            return (self.book != nil) && (self.book != Constants.EMPTY_STRING)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
        }
    }
    
//    func hasNotesOrSlides() -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(),hasSlides())
//    }
    
//    func hasNotes() -> Bool
//    {
//        return (self.notes != nil) && (self.notes != Constants.EMPTY_STRING)
//    }
    
    var showingNotes:Bool
    {
        get {
            return (showing == Showing.notes)
        }
    }
    
//    func hasSlides() -> Bool
//    {
//        return (self.slides != nil) && (self.slides != Constants.EMPTY_STRING)
//    }
    
    var showingSlides:Bool
    {
        get {
            return (showing == Showing.slides)
        }
    }
    
//    func hasNotesOrSlides(check:Bool) -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(check),hasSlides(check))
//    }
    
    func checkNotes() -> Bool
    {
        if !hasNotes { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: notesURL!)) != nil) {
//                notes = testNotes
                NSLog("Transcript DOES exist for: \(title!)")
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
                NSLog("Slides DO exist for: \(title!)")
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
            return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            return hasTags ? tagsSet!.contains(Constants.Favorites) : false
        }
    }
}
