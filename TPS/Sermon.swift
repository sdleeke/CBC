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
    var list:[Sermon]? //Not in any specific order
    
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
    
    func archiveList() -> [String]?
    {
        return list?.map({ (sermon:Sermon) -> String in
            return "\(Globals.sermonRepository!.indexOf(sermon)!)"
        })
    }
    
    func unarchiveList(sermons:[String]?)
    {
        list = sermons?.map({ (index:String) -> Sermon in
            return Globals.sermonRepository![Int(index)!]
        })
    }
    
    func archiveGroupSort() -> [String:[String:[String:[String]]]]?
    {
        var dict = [String:[String:[String:[String]]]]()
        
        for groupKey in groupSort!.keys {
            dict[groupKey] = [String:[String:[String]]]()
            for groupNameKey in groupSort![groupKey]!.keys {
                dict[groupKey]![groupNameKey] = [String:[String]]()
                for sortKey in groupSort![groupKey]![groupNameKey]!.keys {
                    dict[groupKey]![groupNameKey]![sortKey] = groupSort![groupKey]![groupNameKey]![sortKey]?.map({ (sermon:Sermon) -> String in
                        return "\(Globals.sermonRepository!.indexOf(sermon)!)"
                    })
                }
            }
            
        }
        return dict
    }
    
    func unarchiveGroupSort(gs:[String:[String:[String:[String]]]]?)
    {
        groupSort = [String:[String:[String:[Sermon]]]]()
        
        for groupKey in gs!.keys {
            groupSort?[groupKey] = [String:[String:[Sermon]]]()
            for groupNameKey in gs![groupKey]!.keys {
                groupSort?[groupKey]![groupNameKey] = [String:[Sermon]]()
                for sortKey in gs![groupKey]![groupNameKey]!.keys {
                    groupSort?[groupKey]![groupNameKey]![sortKey] = gs![groupKey]![groupNameKey]![sortKey]?.map({ (index:String) -> Sermon in
                        return Globals.sermonRepository![Int(index)!]
                    })
                }
            }
        }
    }
    
    func archiveGroupNames() -> [String:[String:String]]?
    {
        return groupNames
    }
    
    func unarchiveGroupNames(gn:[String:[String:String]]?)
    {
        groupNames = gn
    }
    
    func archiveTagSermons() -> [String:[String]]?
    {
        var dict = [String:[String]]()
        
        for key in tagSermons!.keys {
            dict[key] = tagSermons?[key]?.map({ (sermon:Sermon) -> String in
                return "\(Globals.sermonRepository!.indexOf(sermon)!)"
            })
        }
        
        return dict
    }
    
    func unarchiveTagSermons(ts:[String:[String]]?)
    {
        tagSermons = [String:[Sermon]]()
        
        for key in ts!.keys {
            tagSermons?[key] = ts?[key]?.map({ (index:String) -> Sermon in
                return Globals.sermonRepository![Int(index)!]
            })
        }
    }
    
    func archiveTagNames() -> [String:String]?
    {
        return tagNames
    }
    
    func unarchiveTagNames(tn:[String:String]?)
    {
        tagNames = tn
    }
    
    var sermons:[Sermon]? {
        get {
            return sermons(grouping: Globals.grouping,sorting: Globals.sorting)
        }
    }
    
    func sermons(grouping grouping:String?,sorting:String?) -> [Sermon]?
    {
        var groupedSortedSermons:[Sermon]?
        
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
            return sectionTitles(grouping: Globals.grouping,sorting: Globals.sorting)
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
            return sectionCounts(grouping: Globals.grouping,sorting: Globals.sorting)
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
            return sectionIndexes(grouping: Globals.grouping,sorting: Globals.sorting)
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
//        Globals.sermonsSortingOrGrouping = true
        
        list = sermons
        
        // Put the sermons into the dictionaries.
        
        groupNames = SermonGroupNames()
        groupSort = SermonGroupSort()
        tagSermons = [String:[Sermon]]()
        tagNames = [String:String]()

        if (list != nil) {
            var groupedSermons = [String:[String:[Sermon]]]()
            
            Globals.finished = list!.count * (Constants.groupings.count + 1)
            Globals.progress = 0
            
            for sermon in sermons! {
                for group in Constants.groupings {
                    var string:String?
                    var name:String?
                    
                    switch group {
                    case Constants.YEAR:
                        string = "\(sermon.year)"
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
                    
                    if (groupNames?[group] == nil) {
                        groupNames?[group] = [String:String]()
                    }
                    
                    groupNames?[group]?[string!] = name!
                    
                    if (groupedSermons[group] == nil) {
                        groupedSermons[group] = [String:[Sermon]]()
                    }
                    
                    if groupedSermons[group]?[string!] == nil {
                        groupedSermons[group]?[string!] = [sermon]
                    } else {
                        groupedSermons[group]?[string!]?.append(sermon)
                    }
                    
                    Globals.progress++
                }
            }
            
            //        print("\(groupedSermons)")

            for group in Constants.groupings {
                Globals.finished += groupedSermons[group]!.keys.count
            }
            for group in Constants.groupings {
                if (groupedSermons[group] != nil) {
                    if (groupSort?[group] == nil) {
                        groupSort?[group] = [String:[String:[Sermon]]]()
                    }
                    for string in groupedSermons[group]!.keys {
                        if (groupSort?[group]?[string] == nil) {
                            groupSort?[group]?[string] = [String:[Sermon]]()
                        }
                        for sort in Constants.sortings {
                            switch sort {
                            case Constants.CHRONOLOGICAL:
                                groupSort?[group]?[string]?[sort] = sortSermonsChronologically(groupedSermons[group]?[string])
                                break
                                
                            case Constants.REVERSE_CHRONOLOGICAL:
                                groupSort?[group]?[string]?[sort] = sortSermonsReverseChronologically(groupedSermons[group]?[string])
                                break
                                
                            default:
                                break
                            }
                        }
                        
                        Globals.progress++
                    }
                }
            }
            
            for sermon in sermons! {
                if let tags =  sermon.tagsSet {
                    for tag in tags {
                        let sortTag = stringWithoutLeadingTheOrAOrAn(tag)
                        if tagSermons?[sortTag!] == nil {
                            tagSermons?[sortTag!] = [sermon]
                        } else {
                            tagSermons?[sortTag!]?.append(sermon)
                        }
                        tagNames?[sortTag!] = tag
                    }
                }
                
                Globals.progress++
            }
        } else {
            Globals.finished = 1
            Globals.progress = 1
        }
        
//        Globals.sermonsSortingOrGrouping = false
    }
}

enum State {
    case downloading
    case downloaded
    case none
}

struct Download {
    var location:NSURL?

    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:NSURLSession? // We're using a session for each download.  Not sure is the best but it works for TWU.
    
    var task:NSURLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    
    var state:State = .none
    
    var completionHandler: ((Void) -> (Void))?
}

class Sermon : NSObject, NSURLSessionDownloadDelegate {
    var dict:[String:String]?

//    struct Dict {
//        var sermon:Sermon?
//        
//        private let queue = dispatch_queue_create("com.leeke.sermon.dict", nil)
//        func with(queue: dispatch_queue_t, f: Void -> Void) {
//            dispatch_sync(queue, f)
//        }
//        
//        init(sermon:Sermon?) {
//            if (sermon == nil) {
//                print("nil sermon in dict init!")
//            }
//            self.sermon = sermon
//        }
//        
//        subscript(key:String) -> String? {
//            get {
//                var value:String?
//                with(queue) {
//                    value = self.sermon?.dictionary?[key]
//                }
//                return value
//            }
//            set {
//                with(queue) {
//                    if (self.sermon?.dictionary == nil) {
//                        self.sermon?.dictionary = [String:String]()
//                    }
//                    if (newValue != nil) {
//                        if (self.sermon != nil) {
//                            //                        print("\(Globals.sermonSettings!)")
//                            //                        print("\(sermon!)")
//                            //                        print("\(newValue!)")
//                            self.sermon?.dictionary?[key] = newValue
//                        } else {
//                            print("sermon == nil in Dict!")
//                        }
//                    } else {
//                        print("newValue == nil in dict!")
//                    }
//                }
//            }
//        }
//    }
//
//    lazy var dict:Dict? = {
//        return Dict(sermon:self)
//    }()

    init(dict:[String:String]?)
    {
//        print("\(dict)")
        self.dict = dict
    }
    
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
            dict![Constants.PLAYING] = newValue
            settings?[Constants.PLAYING] = newValue
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

    // this supports settings values that are saved in defaults between sessions
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
    
    // These are read-only
    var keyBase:String! {
        get {
            if (title == nil) {
                print("\(title)")
            }
            if (date == nil) {
                print("\(date)")
            }
//            print("\(title! + date!)")
            return title! + date!
        }
    }
    
    var seriesKeyBase:String! {
        get {
            if (series != nil) {
                return series!
            } else {
                return keyBase
            }
        }
    }
    
    var year:Int! {
        get {
            return NSCalendar.currentCalendar().components(.Year, fromDate: fullDate!).year
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
                        settings?[Constants.SPEAKER_SORT] = speakerSort
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
                    if let seriesSort = stringWithoutLeadingTheOrAOrAn(series) {
                        dict![Constants.SERIES_SORT] = seriesSort
                        settings?[Constants.SERIES_SORT] = seriesSort
                    } else {
                        print("seriesSort is nil")
                    }
                }
            }
            return dict![Constants.SERIES_SORT]
        }
    }
    
    var series:String? {
        get {
            return dict![Constants.SERIES]
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            if let tags = settings?[Constants.TAGS] {
                dict![Constants.TAGS] = tags
            } else {
                // do nothing
            }
            return dict![Constants.TAGS]
        }
        set {
            var tag:String
            var tags = newValue
            var tagsSet = Set<String>()
            
            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
                tagsSet.insert(tag)
                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            if (!tagsSet.contains(Constants.New)) {
                settings?[Constants.TAGS] = newValue
            } else {
                dict![Constants.TAGS] = newValue
            }
        }
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
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
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
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
        }
    }
    
    var bookSection:String! {
        get {
            return hasBook() ? book! : hasScripture() ? scripture! : Constants.None
        }
    }
    
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
                                for bookTitle in Constants.OLD_TESTAMENT {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                            dict![Constants.BOOK] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Constants.BOOK] == nil) {
                                for bookTitle in Constants.NEW_TESTAMENT {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substringToIndex(bookTitle.endIndex) == bookTitle) {
                                            dict![Constants.BOOK] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Constants.BOOK] != nil) {
                                settings?[Constants.BOOK] = dict![Constants.BOOK]
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
        
        // Not sure this thread safe serial queue code matters.  NO problems w/ GTY but nothing but problems
        // in TPS w/ fillSortGroupCache() creating cache entries in the background.
        
//        private let queue = dispatch_queue_create("com.leeke.sermon.settings", nil)
//        func with(queue: dispatch_queue_t, f: Void -> Void) {
//            dispatch_sync(queue, f)
//        }
        
        init(sermon:Sermon?) {
            if (sermon == nil) {
                print("nil sermon in Settings init!")
            }
            self.sermon = sermon
        }
        
        subscript(key:String) -> String? {
            get {
                var value:String?
//                with(queue) {
                    value = Globals.sermonSettings?[self.sermon!.keyBase]?[key]
//                }
                return value
            }
            set {
//                with(queue) {
                    if (Globals.sermonSettings?[self.sermon!.keyBase] == nil) {
                        Globals.sermonSettings?[self.sermon!.keyBase] = [String:String]()
                    }
                    if (newValue != nil) {
                        if (self.sermon != nil) {
    //                        print("\(Globals.sermonSettings!)")
    //                        print("\(sermon!)")
    //                        print("\(newValue!)")
                            Globals.sermonSettings?[self.sermon!.keyBase]?[key] = newValue
                        } else {
                            print("sermon == nil in Settings!")
                        }
                    } else {
                        print("newValue == nil in Settings!")
                    }
//                }
            }
        }
    }
    
    lazy var settings:Settings? = {
        return Settings(sermon:self)
    }()
    
//    func settingForKey(key:String) -> String?
//    {
//        return Globals.sermonSettings?[keyBase]?[key]
//    }
//    
//    func settingForKey(key:String = [String?)
//    {
//        if (Globals.sermonSettings?[keyBase] == nil) {
//            Globals.sermonSettings?[keyBase] = [String:String]()
//        }
//        Globals.sermonSettings?[keyBase]?[key] = value
//    }
    
    lazy var download:Download! = {
        [unowned self] in
        var download = Download()
        download.state = self.isDownloaded() ? .downloaded : .none
        return download
    }()
    
    func isDownloaded() -> Bool
    {
        if (hasAudio()) {
            if let fileURL = documentsURL()?.URLByAppendingPathComponent(audio!) {
                return NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!)
            }
        }

        return false
    }
    
    func deleteDownload()
    {
        if (hasAudio()) {
            if let fileURL = documentsURL()?.URLByAppendingPathComponent(audio!) {
                // Check if file exists and if so, delete it.
                if (NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!)){
                    do {
                        try NSFileManager.defaultManager().removeItemAtURL(fileURL)
                    } catch _ {
                    }
                }
            }
        }
        
        download.totalBytesWritten = 0
        download.totalBytesExpectedToWrite = 0
        
        download.state = .none
        
        // The following must appear AFTER we change the state
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
    }
    
    func cancelDownload()
    {
        if (download.active) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            download.task?.cancel()
            download.task = nil
            
            download.totalBytesWritten = 0
            download.totalBytesExpectedToWrite = 0
            
            download.state = .none
            
            // The following must appear AFTER we change the state
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
        }
    }
    
    func downloadAudio()
    {
        if (hasAudio()) && (download.state == .none) {
            download.state = .downloading
            
            let filename = audio! //String(format: Constants.FILENAME_FORMAT, id)
            let audioURL = "\(Constants.BASE_AUDIO_URL)\(filename)"
            let downloadRequest = NSMutableURLRequest(URL: NSURL(string: audioURL)!)
            
            let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(Constants.DOWNLOAD_IDENTIFIER + filename)
            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            download.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            
            download.task = download.session?.downloadTaskWithRequest(downloadRequest)
            download.task?.taskDescription = filename
            
            download.task?.resume()
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            // The following must appear AFTER we change the state
            NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: self)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        let filename = downloadTask.taskDescription!
        
        if (download.state == .downloading) {
            download.totalBytesWritten = totalBytesWritten
            download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        }
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        let fileManager = NSFileManager.defaultManager()
        
        //Get documents directory URL
        let destinationURL = documentsURL()?.URLByAppendingPathComponent(filename)
        // Check if file exists
        if (fileManager.fileExistsAtPath(destinationURL!.path!)){
            do {
                try fileManager.removeItemAtURL(destinationURL!)
            } catch _ {
                print("failed to remove file")
            }
        }
        
        do {
            if (download.state == .downloading) {
                try fileManager.copyItemAtURL(location, toURL: destinationURL!)
                try fileManager.removeItemAtURL(location)
                download.state = .downloaded
            }
        } catch _ {
            print("failed to copy temp audio download file")
            download.state = .none
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (download.task == task) {
            if (error != nil) {
                print("Download failed for: \(session.description)")
                download.state = .none
            } else {
                print("Download succeeded for: \(session.description)")
                if (download.state == .downloading) {
                    download.state = .downloaded
                }
            }
            
            // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
            // that are needed - e.g. the JSON!  We need to find a way to delete only the temp file created by this download task.
            //        removeTempFiles()
            
            let filename = task.taskDescription
            print("filename: \(filename!) error: \(error)")
        }
        
        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            Globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        session.invalidateAndCancel()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if (download.session == session) {
            download.session = nil
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        var filename:String?
        
        filename = session.configuration.identifier!.substringFromIndex(Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let downloadSermon = Globals.sermonRepository?.filter({ (sermon:Sermon) -> Bool in
            return sermon.audio == filename
        }).first {
            downloadSermon.download.completionHandler?()
        }
//        for sermon in Globals.sermonRepository! {
//            if (sermon.audio == filename) {
//                sermon.download.completionHandler?()
//            }
//        }
    }
    
    func hasDate() -> Bool
    {
        return (date != nil) && (date != Constants.EMPTY_STRING)
    }
    
    func hasAudio() -> Bool
    {
        return (audio != nil) && (audio != Constants.EMPTY_STRING)
    }
    
    func hasVideo() -> Bool
    {
        return (video != nil) && (video != Constants.EMPTY_STRING)
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
    
    func hasNotesOrSlides() -> (hasNotes:Bool,hasSlides:Bool)
    {
        return (hasNotes(),hasSlides())
    }
    
    func hasNotes() -> Bool
    {
        return (self.notes != nil) && (self.notes != Constants.EMPTY_STRING)
    }
    
    func hasSlides() -> Bool
    {
        return (self.slides != nil) && (self.slides != Constants.EMPTY_STRING)
    }
    
    func hasNotesOrSlides(check:Bool) -> (hasNotes:Bool,hasSlides:Bool)
    {
        return (hasNotes(check),hasSlides(check))
    }
    
    func checkNotes() -> Bool
    {
        if !hasNotes() && Reachability.isConnectedToNetwork() {
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
        if !hasSlides() && Reachability.isConnectedToNetwork() {
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

}
