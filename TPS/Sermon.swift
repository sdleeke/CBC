//
//  Sermon.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

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
            return tagSermons?.keys.sort({ $0 < $1 }).map({ (string:String) -> String in
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
    
    func sortGroup(grouping:String?)
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
            case Constants.YEAR:
                string = sermon.yearString
                name = string
                break
                
            case Constants.SERIES:
                string = sermon.seriesSectionSort
                name = sermon.seriesSection
                break
                
            case Constants.BOOK:
                string = sermon.bookSection
                name = sermon.bookSection
                break
                
            case Constants.SPEAKER:
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
                        groupSort?[grouping!]?[string]?[sort] = array?.reverse()
                        break
                        
                    default:
                        break
                    }
                    
                    globals.progress += 1
                }
            }
        }
    }
    
    func sermons(grouping grouping:String?,sorting:String?) -> [Sermon]?
    {
        var groupedSortedSermons:[Sermon]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sort(
                {
                    switch grouping! {
                    case Constants.YEAR:
                        switch sorting! {
                        case Constants.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Constants.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case Constants.BOOK:
                        return bookNumberInBible($0) < bookNumberInBible($1)
                        
                    default:
                        break
                    }
                    
                    return $0 < $1
            }) {
                let sermons = groupSort?[grouping!]?[key]?[sorting!]
                if (groupedSortedSermons == nil) {
                    groupedSortedSermons = sermons
                } else {
                    groupedSortedSermons?.appendContentsOf(sermons!)
                }
            }
        }
        
        return groupedSortedSermons
    }
    
    var sectionTitles:[String]? {
        get {
            return sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionTitles(grouping grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sort({
            switch grouping! {
            case Constants.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Constants.BOOK:
                return bookNumberInBible($0) < bookNumberInBible($1)
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    var sectionCounts:[Int]? {
        get {
            return sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionCounts(grouping grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sort({
            switch grouping! {
            case Constants.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Constants.BOOK:
                return bookNumberInBible($0) < bookNumberInBible($1)
                
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
    
    func sectionIndexes(grouping grouping:String?,sorting:String?) -> [Int]?
    {
        var cumulative = 0
        
        return groupSort?[grouping!]?.keys.sort({
            switch grouping! {
            case Constants.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Constants.BOOK:
                return bookNumberInBible($0) < bookNumberInBible($1)
                
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

class Download {
    weak var sermon:Sermon?
    
    var purpose:String?
    
    var url:NSURL?
    var fileSystemURL:NSURL? {
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:NSURLSession? // We're using a session for each download.  Not sure is the best but it works for TWU.
    
    var task:NSURLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    
    var state:State = .none {
        didSet {
            if state != oldValue {
                if (purpose == Constants.AUDIO) {
                    if state == .downloaded {
                        sermon?.addTag(Constants.Downloaded)
                    } else {
                        sermon?.removeTag(Constants.Downloaded)
                    }
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // The following must appear AFTER we change the state
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self.sermon)
                })
            }
        }
    }
    
    var completionHandler: ((Void) -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
            return NSFileManager.defaultManager().fileExistsAtPath(fileSystemURL!.path!)
        } else {
            return false
        }
    }
    
    var fileSize:Int
    {
        var size = 0
        
        if fileSystemURL != nil {
            do {
                let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(fileSystemURL!.path!)
                size = fileAttributes[NSFileSize] as! Int
            } catch _ {
                print("failed to get file attributes for \(fileSystemURL!)")
            }
        }
        
        return size
    }
    
    func download()
    {
        if (state == .none) {
            state = .downloading
            
            let downloadRequest = NSMutableURLRequest(URL: url!)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent!)
            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            session = NSURLSession(configuration: configuration, delegate: sermon, delegateQueue: nil)
            
            task = session?.downloadTaskWithRequest(downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            })
        }
    }
    
    func deleteDownload()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (NSFileManager.defaultManager().fileExistsAtPath(fileSystemURL!.path!)){
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(fileSystemURL!)
                } catch _ {
                    print("failed to delete download")
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

class Sermon : NSObject, NSURLSessionDownloadDelegate {
    var dict:[String:String]?

    init(dict:[String:String]?)
    {
//        print("\(dict)")
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
        download.purpose = Constants.AUDIO
        download.url = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Constants.AUDIO] = download
        return download
        }()
    
    lazy var videoDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Constants.VIDEO
        download.url = self.videoURL
        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Constants.VIDEO] = download
        return download
        }()
    
    lazy var slidesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Constants.SLIDES
        download.url = self.slidesURL
        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Constants.SLIDES] = download
        return download
        }()
    
    lazy var notesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.sermon = self
        download.purpose = Constants.NOTES
        download.url = self.notesURL
        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Constants.NOTES] = download
        return download
        }()

    required convenience init?(coder decoder: NSCoder)
    {
        guard
            
            let dict = decoder.decodeObjectForKey(Constants.DICT) as? [String:String]
            
            else {
                return nil
            }
        
        self.init(dict: dict)
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.dict, forKey: Constants.DICT)
    }
    
    var id:String! {
        get {
            if dict?[Constants.ID] != nil {
                return dict?[Constants.ID]
            } else {
                if let cd = audio?.rangeOfString("CD") {
                    return audio?.substringToIndex(cd.startIndex)
                } else {
                    return audio?.substringToIndex(audio!.rangeOfString(Constants.MP3_FILENAME_EXTENSION)!.startIndex)
                }
            }
        }
    }
    
    var sermonsInSeries:[Sermon]? {
        get {
            if (hasSeries()) {
                if (globals.sermons.all?.groupSort?[Constants.SERIES]?[seriesSort!]?[Constants.CHRONOLOGICAL] == nil) {
                    let seriesSermons = globals.sermonRepository.list?.filter({ (testSermon:Sermon) -> Bool in
                        return hasSeries() ? (testSermon.series == series) : (testSermon.id == id)
                    })
                    return sortSermonsByYear(seriesSermons, sorting: Constants.CHRONOLOGICAL)
                } else {
                    return globals.sermons.all?.groupSort?[Constants.SERIES]?[seriesSort!]?[Constants.CHRONOLOGICAL]
                }
            } else {
                return [self]
            }
        }
    }
    
    func sermonsInCollection(tag:String) -> [Sermon]?
    {
        var sermons:[Sermon]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            sermons = globals.sermons.all?.tagSermons?[tag]
        }
        
        return sermons
    }

    var playingURL:NSURL? {
        get {
            var url:NSURL?
            
            switch playing! {
            case Constants.AUDIO:
                url = audioFileSystemURL
                if (!NSFileManager.defaultManager().fileExistsAtPath(url!.path!)){
                    url = audioURL
                }
                break
                
            case Constants.VIDEO:
                url = videoFileSystemURL
                if (!NSFileManager.defaultManager().fileExistsAtPath(url!.path!)){
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
            if (dict![Constants.PLAYING] == nil) {
                if let playing = settings?[Constants.PLAYING] {
                    dict![Constants.PLAYING] = playing
                } else {
                    dict![Constants.PLAYING] = Constants.AUDIO
                }
            }
            return dict![Constants.PLAYING]
        }
        
        set {
            if newValue != dict![Constants.PLAYING] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.player.playing == self {
                    globals.player.stateTime = nil //?.dateEntered = NSDate()
                }
                
                dict![Constants.PLAYING] = newValue
                settings?[Constants.PLAYING] = newValue
            }
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Constants.SHOWING] == nil) {
                if let showing = settings?[Constants.SHOWING] {
                    dict![Constants.SHOWING] = showing
                } else {
                    if (hasSlides() && hasNotes()) {
                        dict![Constants.SHOWING] = Constants.SLIDES
                    }
                    if (!hasSlides() && hasNotes()) {
                        dict![Constants.SHOWING] = Constants.NOTES
                    }
                    if (hasSlides() && !hasNotes()) {
                        dict![Constants.SHOWING] = Constants.SLIDES
                    }
                    if (!hasSlides() && !hasNotes()) {
                        dict![Constants.SHOWING] = Constants.NONE
                    }
                }
            }
            return dict![Constants.SHOWING]
        }
        
        set {
            dict![Constants.SHOWING] = newValue
            settings?[Constants.SHOWING] = newValue
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
    
    var url:NSURL? {
        get {
            return download?.url
        }
    }
    
    var fileSystemURL:NSURL? {
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
                return NSCalendar.currentCalendar().components(.Year, fromDate: fullDate!).year
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
    
    var date:String? {
        get {
            return dict![Constants.DATE]
        }
    }
    
    var service:String? {
        get {
            return dict![Constants.SERVICE]
        }
    }
    
    var title:String? {
        get {
            return dict![Constants.TITLE]
        }
    }
    
    var scripture:String? {
        get {
            return dict![Constants.SCRIPTURE]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return hasSpeaker() ? speakerSort! : Constants.None
        }
    }
    
    var speakerSection:String! {
        get {
            return hasSpeaker() ? speaker! : Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict![Constants.SPEAKER]
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict![Constants.SPEAKER_SORT] == nil {
                if let speakerSort = settings?[Constants.SPEAKER_SORT] {
                    dict![Constants.SPEAKER_SORT] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"
                    
                    if var speakerSort = speaker {
                        while (speakerSort.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
                            speakerSort = speakerSort.substringFromIndex(speakerSort.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
                        }
                        dict![Constants.SPEAKER_SORT] = speakerSort
//                        settings?[Constants.SPEAKER_SORT] = speakerSort
                    } else {
                        print("NO SPEAKER")
                    }
                }
            }
            if dict![Constants.SPEAKER_SORT] == nil {
                print("Speaker sort is NIL")
            }
            return dict![Constants.SPEAKER_SORT]
        }
    }
    
    var seriesSectionSort:String! {
        get {
            return hasSeries() ? seriesSort! : Constants.Individual_Sermons
        }
    }
    
    var seriesSection:String! {
        get {
            return hasSeries() ? series! : Constants.Individual_Sermons
        }
    }
    
    // this saves calculated values in defaults between sessions
    var seriesSort:String? {
        get {
            if dict![Constants.SERIES_SORT] == nil {
                if let seriesSort = settings?[Constants.SERIES_SORT] {
                    dict![Constants.SERIES_SORT] = seriesSort
                } else {
                    if let seriesSort = stringWithoutPrefixes(series) {
                        dict![Constants.SERIES_SORT] = seriesSort
//                        settings?[Constants.SERIES_SORT] = seriesSort
                    } else {
                        print("seriesSort is nil")
                    }
                }
            }
            return dict![Constants.SERIES_SORT]
        }
    }
    
    var series:String? {
//        get {
//            return dict![Constants.SERIES]
//        }
        get {
            if (title?.rangeOfString(Constants.SERIES_INDICATOR_SINGULAR, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil) {
                let seriesString = title!.substringToIndex((title?.rangeOfString(Constants.SERIES_INDICATOR_SINGULAR, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)!.startIndex)!)
                dict![Constants.SERIES] = seriesString
            }

            return dict![Constants.SERIES]
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            if let tags = settings?[Constants.TAGS] {
                if dict![Constants.TAGS] != nil {
                    return dict![Constants.TAGS]! + Constants.TAGS_SEPARATOR + tags
                } else {
                    return tags
                }
            } else {
                return dict![Constants.TAGS]
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

//            settings?[Constants.TAGS] = newValue
//            dict![Constants.TAGS] = newValue
//        }
    }
    
    func addTag(tag:String)
    {
        let tags = tagsArrayFromTagsString(settings![Constants.TAGS])
        if tags?.indexOf(tag) == nil {
            if (settings?[Constants.TAGS] == nil) {
                settings?[Constants.TAGS] = tag
            } else {
                settings?[Constants.TAGS] = settings![Constants.TAGS]! + Constants.TAGS_SEPARATOR + tag
            }
            
            if globals.sermons.all!.tagSermons![stringWithoutPrefixes(tag)!] != nil {
                if globals.sermons.all!.tagSermons![stringWithoutPrefixes(tag)!]!.indexOf(self) == nil {
                    globals.sermons.all!.tagSermons![stringWithoutPrefixes(tag)!]!.append(self)
                    globals.sermons.all!.tagNames![stringWithoutPrefixes(tag)!] = tag
                }
            } else {
                globals.sermons.all!.tagSermons![stringWithoutPrefixes(tag)!] = [self]
                globals.sermons.all!.tagNames![stringWithoutPrefixes(tag)!] = tag
            }
            
            if (globals.sermonTagsSelected == tag) {
                globals.sermons.tagged = SermonsListGroupSort(sermons: globals.sermons.all?.tagSermons?[stringWithoutPrefixes(globals.sermonTagsSelected!)!])
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_SERMON_LIST_NOTIFICATION, object: globals.sermons.tagged)
                })
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
            })
        }
    }
    
    func removeTag(tag:String)
    {
        if (settings?[Constants.TAGS] != nil) {
            var tags = tagsArrayFromTagsString(settings![Constants.TAGS])
            if tags?.indexOf(tag) != nil {
                tags?.removeAtIndex(tags!.indexOf(tag)!)
                settings?[Constants.TAGS] = tagsArrayToTagsString(tags)

                if let index = globals.sermons.all?.tagSermons?[stringWithoutPrefixes(tag)!]?.indexOf(self) {
                    globals.sermons.all?.tagSermons?[stringWithoutPrefixes(tag)!]?.removeAtIndex(index)
                }
                
                if (globals.sermonTagsSelected == tag) {
                    globals.sermons.tagged = SermonsListGroupSort(sermons: globals.sermons.all?.tagSermons?[stringWithoutPrefixes(globals.sermonTagsSelected!)!])
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_SERMON_LIST_NOTIFICATION, object: globals.sermons.tagged)
                    })
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
                })
            }
        }
    }
    
    func tagsSetToString(tagsSet:Set<String>?) -> String?
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
            
            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            
            return tagsSet.count == 0 ? nil : tagsSet
        }
    }
    
    var tagsArray:[String]? {
        get {
            return tagsSet == nil ? nil : Array(tagsSet!).sort() { $0 < $1 }
        }
    }
    
    var audio:String? {
        get {
            return dict![Constants.AUDIO]
        }
    }
    
    var video:String? {
        get {
            return dict![Constants.VIDEO]
        }
    }
    
    // These are read-write
    
    // this supports set values that are saved in defaults between sessions
    var notes:String? {
        get {
            if dict![Constants.NOTES] == nil {
                if let notes = settings?[Constants.NOTES] {
                    dict![Constants.NOTES] = notes
                } else {
                    // do nothing
                }
            }
            return dict![Constants.NOTES]
        }
        set {
            dict![Constants.NOTES] = newValue
            settings?[Constants.NOTES] = newValue
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
            }
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if dict![Constants.SLIDES] == nil {
                if let slides = settings?[Constants.SLIDES] {
                    dict![Constants.SLIDES] = slides
                } else {
                    // do nothing
                }
            }
            return dict![Constants.SLIDES]
        }
        set {
            dict![Constants.SLIDES] = newValue
            settings?[Constants.SLIDES] = newValue
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
            }
        }
    }
    
    var audioURL:NSURL? {
        get {
            if (audio != nil) {
                return NSURL(string: Constants.BASE_AUDIO_URL + audio!)
            } else {
                return nil
            }
        }
    }
    
    var videoURL:NSURL? {
        get {
            if video != nil {
                let videoURL = Constants.BASE_VIDEO_URL_PREFIX + video!
                
//                if video!.rangeOfString(".sd.") != nil {
//                    videoURL = videoURL + Constants.BASE_SD_VIDEO_URL_POSTFIX
//                } else
//                
//                if video!.rangeOfString(".hd.") != nil {
//                    videoURL = videoURL + Constants.BASE_HD_VIDEO_URL_POSTFIX
//                }

                return NSURL(string: videoURL)
            } else {
                return nil
            }
        }
    }
    
    var notesURL:NSURL? {
        get {
            if (notes != nil) {
                return NSURL(string: Constants.BASE_PDF_URL + notes!)
            } else {
                return nil
            }
        }
    }
    
    var slidesURL:NSURL? {
        get {
            if (slides != nil) {
                return NSURL(string: Constants.BASE_PDF_URL + slides!)
            } else {
                return nil
            }
        }
    }

    var audioFileSystemURL:NSURL? {
        get {
            if (audio != nil) {
                return cachesURL()?.URLByAppendingPathComponent(audio!)
            } else {
                return nil
            }
        }
    }
    
    var videoFileSystemURL:NSURL? {
        get {
            if video != nil {
                return cachesURL()?.URLByAppendingPathComponent(id! + Constants.MP4_FILENAME_EXTENSION)
            } else {
                return nil
            }
        }
    }
    
    var slidesFileSystemURL:NSURL? {
        get {
            if (slides != nil) {
                return cachesURL()?.URLByAppendingPathComponent(slides!)
            } else {
                return nil
            }
        }
    }
    
    var notesFileSystemURL:NSURL? {
        get {
            if (notes != nil) {
                return cachesURL()?.URLByAppendingPathComponent(notes!)
            } else {
                return nil
            }
        }
    }
    
    var bookSection:String! {
        get {
            return hasBook() ? book! : hasScripture() ? scripture! : Constants.None
        }
    }
    
    var testament:String? {
        if (hasBook()) {
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
    
    func chapters(thisBook:String) -> [Int]
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
                    
                    if (string.rangeOfString(";") == nil) {
                        chaptersForBook = chaptersFromScripture(string.substringFromIndex(scripture!.rangeOfString(thisBook)!.endIndex))
                    } else {
                        repeat {
                            var subString = string.substringToIndex(string.rangeOfString(";")!.startIndex)
                            
                            if (subString.rangeOfString(thisBook) != nil) {
                                subString = subString.substringFromIndex(subString.rangeOfString(thisBook)!.endIndex)
                            }
                            chaptersForBook.appendContentsOf(chaptersFromScripture(subString))
                            
                            string = string.substringFromIndex(string.rangeOfString(";")!.endIndex)
                        } while (string.rangeOfString(";") != nil)
                        
                        //                        print(string)
                        if (string.rangeOfString(thisBook) != nil) {
                            string = string.substringFromIndex(string.rangeOfString(thisBook)!.endIndex)
                        }
                        chaptersForBook.appendContentsOf(chaptersFromScripture(string))
                    }
                }
            }
            break
            
        default:
            var scriptures = [String]()
            
            var string = scripture!
            
            let separator = ";"
            
            repeat {
                if string.rangeOfString(separator) != nil {
                    scriptures.append(string.substringToIndex(string.rangeOfString(separator)!.startIndex))
                    string = string.substringFromIndex(string.rangeOfString(separator)!.endIndex)
                }
            } while (string.rangeOfString(separator) != nil)
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if (scripture.rangeOfString(thisBook) != nil) {
                    chaptersForBook.appendContentsOf(chaptersFromScripture(scripture.substringFromIndex(scripture.rangeOfString(thisBook)!.endIndex)))
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
            return booksFromScripture(scripture)
        }
    } //Derived from scripture
    
    var book:String? {
        get {
            if (dict![Constants.BOOK] == nil) {
                if let bookTitle = settings?[Constants.BOOK] {
                    dict![Constants.BOOK] = bookTitle
                } else {
                    if (scripture == Constants.Selected_Scriptures) {
//                        dict![Constants.BOOK] = Constants.Selected_Scriptures
                    } else {
                        if scripture != nil {
                            if (dict![Constants.BOOK] == nil) {
                                for bookTitle in Constants.OLD_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                            dict![Constants.BOOK] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Constants.BOOK] == nil) {
                                for bookTitle in Constants.NEW_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                            dict![Constants.BOOK] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Constants.BOOK] != nil) {
//                                settings?[Constants.BOOK] = dict![Constants.BOOK]
                            }
                        }
                    }
                }
            }
            
            return dict![Constants.BOOK]
        }
    }//Derived from scripture
    
    lazy var fullDate:NSDate?  = {
        [unowned self] in
        if (self.hasDate()) {
            return NSDate(dateString:self.date!)
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
            
            if hasSpeaker() {
                string = string! + " \(speaker!)"
            }
            
            if hasTitle() {
                if (title!.rangeOfString(", Part ") != nil) {
                    let first = title!.substringToIndex((title!.rangeOfString(" (Part")?.endIndex)!)
                    let second = title!.substringFromIndex((title!.rangeOfString(" (Part ")?.endIndex)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture() {
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
                print("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.settings?[sermon!.id]?[key]
            }
            set {
                if (sermon != nil) {
                    if (globals.settings == nil) {
                        globals.settings = [String:[String:String]]()
                    }
                    if (globals.settings?[sermon!.id] == nil) {
                        globals.settings?[sermon!.id] = [String:String]()
                    }
                    if (globals.settings?[sermon!.id]?[key] != newValue) {
//                        print("\(sermon)")
                        globals.settings?[sermon!.id]?[key] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        globals.saveSettingsBackground()
                    }
                } else {
                    print("sermon == nil in Settings!")
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
                print("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.viewSplits?[sermon!.seriesID]
            }
            set {
                if (sermon != nil) {
                    if (globals.viewSplits == nil) {
                        globals.viewSplits = [String:String]()
                    }
                    if (globals.viewSplits?[sermon!.seriesID] != newValue) {
                        globals.viewSplits?[sermon!.seriesID] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        globals.saveSettingsBackground()
                    }
                } else {
                    print("sermon == nil in Settings!")
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
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
        
//        let filename = downloadTask.taskDescription!
        
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }

        if (download != nil) {
            if (download?.state == .downloading) {
                download?.totalBytesWritten = totalBytesWritten
                download?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                print("ERROR NOT DOWNLOADING")
            }
            
            if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
            }
            
            print("filename: \(download!.fileSystemURL!.lastPathComponent!) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        } else {
            print("ERROR NO DOWNLOAD")
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        })
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
//        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }
        
        if (download != nil) {
            print("purpose: \(download!.purpose!)")
            print("filename: \(download!.fileSystemURL!.lastPathComponent!)")
            print("bytes written: \(download!.totalBytesWritten)")
            print("bytes expected to write: \(download!.totalBytesExpectedToWrite)")

            if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                print("downloadTask.taskDescription != fileSystemURL.lastPathComponent")
            }
            
            let fileManager = NSFileManager.defaultManager()
            
            // Check if file exists
            if (fileManager.fileExistsAtPath(download!.fileSystemURL!.path!)){
                do {
                    try fileManager.removeItemAtURL(download!.fileSystemURL!)
                } catch _ {
                    print("failed to remove duplicate download")
                }
            }
            
            //            print("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
            
            do {
                if (download?.state == .downloading) {
                    try fileManager.copyItemAtURL(location, toURL: download!.fileSystemURL!)
                    try fileManager.removeItemAtURL(location)
                    download?.state = .downloaded
                }
            } catch _ {
                print("failed to copy temp download file")
                download?.state = .none
            }
        } else {
            print("NO DOWNLOAD FOUND!")
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
//    func removeTempFiles()
//    {
//        // Clean up temp directory for cancelled downloads
//        let fileManager = NSFileManager.defaultManager()
//        let path = NSTemporaryDirectory()
//        do {
//            let array = try fileManager.contentsOfDirectoryAtPath(path)
//            
//            for string in array {
//                print("Deleting: \(string)")
//                try fileManager.removeItemAtPath(path + string)
//            }
//        } catch _ {
//            print("failed to remove temp file")
//        }
//    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        print("URLSession:task:didCompleteWithError:")
        
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        if (download != nil) {
            print("purpose: \(download!.purpose!)")
            print("filename: \(download!.fileSystemURL!.lastPathComponent!)")
            print("bytes written: \(download!.totalBytesWritten)")
            print("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
            
            if (error != nil) {
                print("with error: \(error!.localizedDescription)")
                download?.state = .none
            }
        } else {
            print("NO DOWNLOAD FOUND!")
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
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("URLSession:didBecomeInvalidWithError:")
        
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        if (download != nil) {
            print("purpose: \(download!.purpose!)")
            print("filename: \(download!.fileSystemURL!.lastPathComponent!)")
            print("bytes written: \(download!.totalBytesWritten)")
            print("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
            
            if (error != nil) {
                print("with error: \(error!.localizedDescription)")
            }
        } else {
            print("NO DOWNLOAD FOUND!")
        }
        
        download?.session = nil
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        var filename:String?
        
        filename = session.configuration.identifier!.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                print("\(filename) \(key)")
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
    
    func hasAudio() -> Bool
    {
        return (audio != nil) && (audio != Constants.EMPTY_STRING)
    }
    
    func playingAudio() -> Bool
    {
        return (playing == Constants.AUDIO)
    }
    
    func hasVideo() -> Bool
    {
        return (video != nil) && (video != Constants.EMPTY_STRING)
    }
    
    func playingVideo() -> Bool
    {
        return (playing == Constants.VIDEO)
    }
    
    func showingVideo() -> Bool
    {
        return (showing == Constants.VIDEO)
    }
    
    func hasScripture() -> Bool
    {
        return (self.scripture != nil) && (self.scripture != Constants.EMPTY_STRING)
    }
    
    func hasSeries() -> Bool
    {
        return (self.series != nil) && (self.series != Constants.EMPTY_STRING)
    }
    
    func hasBook() -> Bool
    {
        return (self.book != nil) && (self.book != Constants.EMPTY_STRING)
    }
    
    func hasSpeaker() -> Bool
    {
        return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
    }
    
//    func hasNotesOrSlides() -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(),hasSlides())
//    }
    
    func hasNotes() -> Bool
    {
        return (self.notes != nil) && (self.notes != Constants.EMPTY_STRING)
    }
    
    func showingNotes() -> Bool
    {
        return (showing == Constants.NOTES)
    }
    
    func hasSlides() -> Bool
    {
        return (self.slides != nil) && (self.slides != Constants.EMPTY_STRING)
    }
    
    func showingSlides() -> Bool
    {
        return (showing == Constants.SLIDES)
    }
    
//    func hasNotesOrSlides(check:Bool) -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(check),hasSlides(check))
//    }
    
    func checkNotes() -> Bool
    {
        if !hasNotes() { //  && Reachability.isConnectedToNetwork()
            let testString = "tp150705a"
            let testNotes = Constants.TRANSCRIPT_PREFIX + audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
            //                print("Notes file s/b: \(testNotes)")
            let notesURL = Constants.BASE_PDF_URL + testNotes
            //                print("<a href=\"\(notesURL)\" target=\"_blank\">\(sermon.title!) Notes</a><br/>")
            
            if (NSData(contentsOfURL: NSURL(string: notesURL)!) != nil) {
                notes = testNotes
                print("Transcript DOES exist for: \(title!) PDF: \(testNotes)")
            }
        }
        
        return hasNotes()
    }
    
    func hasNotes(check:Bool) -> Bool
    {
        return check ? checkNotes() : hasNotes()
    }
    
    func checkSlides() -> Bool
    {
        if !hasSlides() { //  && Reachability.isConnectedToNetwork()
            let testString = "tp150705a"
            let testSlides = audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
            //                print("Slides file s/b: \(testSlides)")
            let slidesURL = Constants.BASE_PDF_URL + testSlides
            //                print("<a href=\"\(slidesURL)\" target=\"_blank\">\(sermon.title!) Slides</a><br/>")
            
            if (NSData(contentsOfURL: NSURL(string: slidesURL)!) != nil) {
                slides = testSlides
                print("Slides DO exist for: \(title!) PDF: \(testSlides)")
            } else {
                
            }
        }
        
        return hasSlides()
    }
    
    func hasSlides(check:Bool) -> Bool
    {
        return check ? checkSlides() : hasSlides()
    }
    
    func hasTags() -> Bool
    {
        return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
    }
    
    func hasFavoritesTag() -> Bool
    {
        return hasTags() ? tagsSet!.contains(Constants.Favorites) : false
    }
}
