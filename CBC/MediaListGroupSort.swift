//
//  MediaListGroupSort.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class BooksChaptersVerses : Swift.Comparable {
    var data:[String:[Int:[Int]]]?
    
    func bookChaptersVerses(book:String?) -> BooksChaptersVerses?
    {
        guard (book != nil) else {
            return self
        }
        
        let bcv = BooksChaptersVerses()
        
        bcv[book!] = data?[book!]
        
        //        print(bcv[book!])
        
        return bcv
    }
    
    func numberOfVerses() -> Int
    {
        var count = 0
        
        if let books = data?.keys.sorted(by: { bookNumberInBible($0) < bookNumberInBible($1) }) {
            for book in books {
                if let chapters = data?[book]?.keys.sorted() {
                    for chapter in chapters {
                        if let verses = data?[book]?[chapter] {
                            count += verses.count
                        }
                    }
                }
            }
        }
        
        return count
    }
    
    subscript(key:String) -> [Int:[Int]]? {
        get {
            return data?[key]
        }
        set {
            if data == nil {
                data = [String:[Int:[Int]]]()
            }
            
            data?[key] = newValue
        }
    }
    
    static func ==(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        let lhsBooks = lhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        let rhsBooks = rhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if (lhsBooks == nil) && (rhsBooks == nil) {
        } else
            if (lhsBooks != nil) && (rhsBooks == nil) {
                return false
            } else
                if (lhsBooks == nil) && (rhsBooks != nil) {
                    return false
                } else {
                    if lhsBooks?.count != rhsBooks?.count {
                        return false
                    } else {
                        //                        print(lhsBooks)
                        for index in 0...(lhsBooks!.count - 1) {
                            if lhsBooks?[index] != rhsBooks?[index] {
                                return false
                            }
                        }
                        for book in lhsBooks! {
                            let lhsChapters = lhs[book]?.keys.sorted()
                            let rhsChapters = rhs[book]?.keys.sorted()
                            
                            if (lhsChapters == nil) && (rhsChapters == nil) {
                            } else
                                if (lhsChapters != nil) && (rhsChapters == nil) {
                                    return false
                                } else
                                    if (lhsChapters == nil) && (rhsChapters != nil) {
                                        return false
                                    } else {
                                        if lhsChapters?.count != rhsChapters?.count {
                                            return false
                                        } else {
                                            for index in 0...(lhsChapters!.count - 1) {
                                                if lhsChapters?[index] != rhsChapters?[index] {
                                                    return false
                                                }
                                            }
                                            for chapter in lhsChapters! {
                                                let lhsVerses = lhs[book]?[chapter]?.sorted()
                                                let rhsVerses = rhs[book]?[chapter]?.sorted()
                                                
                                                if (lhsVerses == nil) && (rhsVerses == nil) {
                                                } else
                                                    if (lhsVerses != nil) && (rhsVerses == nil) {
                                                        return false
                                                    } else
                                                        if (lhsVerses == nil) && (rhsVerses != nil) {
                                                            return false
                                                        } else {
                                                            if lhsVerses?.count != rhsVerses?.count {
                                                                return false
                                                            } else {
                                                                for index in 0...(lhsVerses!.count - 1) {
                                                                    if lhsVerses?[index] != rhsVerses?[index] {
                                                                        return false
                                                                    }
                                                                }
                                                            }
                                                }
                                            }
                                        }
                            }
                        }
                    }
        }
        
        return true
    }
    
    static func !=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs == rhs)
    }
    
    static func <=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return (lhs < rhs) || (lhs == rhs)
    }
    
    static func <(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        let lhsBooks = lhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        let rhsBooks = rhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if (lhsBooks == nil) && (rhsBooks == nil) {
            return false
        } else
            if (lhsBooks != nil) && (rhsBooks == nil) {
                return false
            } else
                if (lhsBooks == nil) && (rhsBooks != nil) {
                    return true
                } else {
                    for lhsBook in lhsBooks! {
                        for rhsBook in rhsBooks! {
                            if lhsBook == rhsBook {
                                let lhsChapters = lhs[lhsBook]?.keys.sorted()
                                let rhsChapters = rhs[rhsBook]?.keys.sorted()
                                
                                if (lhsChapters == nil) && (rhsChapters == nil) {
                                    return lhsBooks?.count < rhsBooks?.count
                                } else
                                    if (lhsChapters != nil) && (rhsChapters == nil) {
                                        return true
                                    } else
                                        if (lhsChapters == nil) && (rhsChapters != nil) {
                                            return false
                                        } else {
                                            for lhsChapter in lhsChapters! {
                                                for rhsChapter in rhsChapters! {
                                                    if lhsChapter == rhsChapter {
                                                        let lhsVerses = lhs[lhsBook]?[lhsChapter]?.sorted()
                                                        let rhsVerses = rhs[rhsBook]?[rhsChapter]?.sorted()
                                                        
                                                        if (lhsVerses == nil) && (rhsVerses == nil) {
                                                            return lhsChapters?.count < rhsChapters?.count
                                                        } else
                                                            if (lhsVerses != nil) && (rhsVerses == nil) {
                                                                return true
                                                            } else
                                                                if (lhsVerses == nil) && (rhsVerses != nil) {
                                                                    return false
                                                                } else {
                                                                    for lhsVerse in lhsVerses! {
                                                                        for rhsVerse in rhsVerses! {
                                                                            if lhsVerse == rhsVerse {
                                                                                return lhs.numberOfVerses() < rhs.numberOfVerses()
                                                                            } else {
                                                                                return lhsVerse < rhsVerse
                                                                            }
                                                                        }
                                                                    }
                                                        }
                                                    } else {
                                                        return lhsChapter < rhsChapter
                                                    }
                                                }
                                            }
                                }
                            } else {
                                return bookNumberInBible(lhsBook) < bookNumberInBible(rhsBook)
                            }
                        }
                    }
        }
        
        return false
    }
    
    static func >=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs < rhs)
    }
    
    static func >(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs < rhs) && !(lhs == rhs)
    }
}

class ScriptureIndex {
    var creating = false
    var completed = false
    
    weak var mediaListGroupSort:MediaListGroupSort?
    
    init(_ mlgs:MediaListGroupSort?)
    {
        self.mediaListGroupSort = mlgs
    }
    
    var sectionsIndex = [String:[String:[MediaItem]]]()
    
    var sections:[String:[MediaItem]]?
        {
        get {
            return context != nil ? sectionsIndex[context!] : nil
        }
        set {
            guard (context != nil) else {
                return
            }
            sectionsIndex[context!] = newValue
        }
    }
    
    lazy var html:CachedString? = {
        [unowned self] in
        return CachedString(index:self.index)
        }()
    
    func index() -> String? {
        return context
    }
    
    var context:String? {
        get {
            var index:String?
            
            if let selectedTestament = self.selectedTestament {
                index = selectedTestament
            }
            
            if index != nil, let selectedBook = self.selectedBook {
                index = index! + ":" + selectedBook
            }
            
            if index != nil, selectedChapter > 0 {
                index = index! + ":\(selectedChapter)"
            }
            
            if index != nil, selectedVerse > 0 {
                index = index! + ":\(selectedVerse)"
            }
            
            return index
        }
    }
    
    //    var htmlStrings = [String:String]()
    //
    //    var htmlString:String? {
    //        get {
    //            return index != nil ? htmlStrings[index!] : nil
    //        }
    //        set {
    //            if index != nil {
    //                htmlStrings[index!] = newValue
    //            }
    //        }
    //    }
    //
    //    var index:String? {
    //        get {
    //            var index:String?
    //
    //            if let selectedTestament = self.selectedTestament {
    //                index = selectedTestament
    //            }
    //
    //            if index != nil, let selectedBook = self.selectedBook {
    //                index = index! + ":" + selectedBook
    //            }
    //
    //            if index != nil, selectedChapter > 0 {
    //                index = index! + ":\(selectedChapter)"
    //            }
    //
    //            if index != nil, selectedVerse > 0 {
    //                index = index! + ":\(selectedVerse)"
    //            }
    //
    //            return index
    //        }
    //    }
    
    var sorted = [String:Bool]()
    
    //Test
    var byTestament = [String:[MediaItem]]()
    
    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()
    
    var selectedTestament:String? = Constants.OT
    
    var selectedBook:String? {
        didSet {
            if selectedBook == nil {
                selectedChapter = 0
                selectedVerse = 0
            }
        }
    }
    
    var selectedChapter:Int = 0 {
        didSet {
            if selectedChapter == 0 {
                selectedVerse = 0
            }
        }
    }
    
    var selectedVerse:Int = 0
    
    var eligible:[MediaItem]? {
        get {
            if let list = mediaListGroupSort?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.books != nil
            }), list.count > 0 {
                return list
            } else {
                return nil
            }
        }
    }
    
    func build()
    {
        guard !completed else {
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            })
            return
        }
        
        guard !creating else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            //            self.progress = 0
            //            self.finished = 0
            self.creating = true
            
            if let list = self.mediaListGroupSort?.list {
                //                self.finished += Float(self.list!.count)
                
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self)
                })
                
                for mediaItem in list {
                    if globals.isRefreshing || globals.isLoading {
                        break
                    }
                    
                    let booksChaptersVerses = mediaItem.booksAndChaptersAndVerses()
                    if let books = booksChaptersVerses?.data?.keys {
                        //                        self.finished += Float(mediaItem.books!.count)
                        for book in books {
                            if globals.isRefreshing || globals.isLoading {
                                break
                            }
                            
                            //                            print("\(mediaItem)")
                            if self.byTestament[testament(book)] != nil {
                                if !self.byTestament[testament(book)]!.contains(mediaItem) {
                                    self.byTestament[testament(book)]?.append(mediaItem)
                                }
                            } else {
                                self.byTestament[testament(book)] = [mediaItem]
                            }
                            
                            if self.byBook[testament(book)] == nil {
                                self.byBook[testament(book)] = [String:[MediaItem]]()
                            }
                            if self.byBook[testament(book)]?[book] != nil {
                                if !self.byBook[testament(book)]![book]!.contains(mediaItem) {
                                    self.byBook[testament(book)]?[book]?.append(mediaItem)
                                }
                            } else {
                                self.byBook[testament(book)]?[book] = [mediaItem]
                            }
                            
                            if let chapters = booksChaptersVerses?[book]?.keys {
                                //                                self.finished += Float(chapters.count)
                                for chapter in chapters {
                                    if globals.isRefreshing || globals.isLoading {
                                        break
                                    }
                                    
                                    if self.byChapter[testament(book)] == nil {
                                        self.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self.byChapter[testament(book)]?[book] == nil {
                                        self.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
                                    }
                                    if self.byChapter[testament(book)]?[book]?[chapter] != nil {
                                        if !self.byChapter[testament(book)]![book]![chapter]!.contains(mediaItem) {
                                            self.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
                                        }
                                    } else {
                                        self.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
                                    }
                                    
                                    if let verses = booksChaptersVerses?[book]?[chapter] {
                                        //                                        self.finished += Float(verses.count)
                                        for verse in verses {
                                            if globals.isRefreshing || globals.isLoading {
                                                break
                                            }
                                            
                                            if self.byVerse[testament(book)] == nil {
                                                self.byVerse[testament(book)] = [String:[Int:[Int:[MediaItem]]]]()
                                            }
                                            if self.byVerse[testament(book)]?[book] == nil {
                                                self.byVerse[testament(book)]?[book] = [Int:[Int:[MediaItem]]]()
                                            }
                                            if self.byVerse[testament(book)]?[book]?[chapter] == nil {
                                                self.byVerse[testament(book)]?[book]?[chapter] = [Int:[MediaItem]]()
                                            }
                                            if self.byVerse[testament(book)]?[book]?[chapter]?[verse] != nil {
                                                if !self.byVerse[testament(book)]![book]![chapter]![verse]!.contains(mediaItem) {
                                                    self.byVerse[testament(book)]?[book]?[chapter]?[verse]?.append(mediaItem)
                                                }
                                            } else {
                                                self.byVerse[testament(book)]?[book]?[chapter]?[verse] = [mediaItem]
                                            }
                                            
                                            //                                            self.progress += 1
                                        }
                                    }
                                    
                                    //                                    self.progress += 1
                                }
                            }
                            
                            //                            self.progress += 1
                        }
                    }
                    
                    //                    self.progress += 1
                }
            }

            self.creating = false
            self.completed = true
            
            if let selectedTestament = self.selectedTestament {
                let testament = translateTestament(selectedTestament)
                
                switch selectedTestament {
                case Constants.OT:
                    if (self.byTestament[testament] == nil) {
                        self.selectedTestament = Constants.NT
                    }
                    break
                    
                case Constants.NT:
                    if (self.byTestament[testament] == nil) {
                        self.selectedTestament = Constants.OT
                    }
                    break
                    
                default:
                    break
                }
            }

            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            })

            //            self.updateSearchResults()
        })
    }
}

//Group//String//Sort
typealias MediaGroupSort = [String:[String:[String:[MediaItem]]]]

//Group//String//Name
typealias MediaGroupNames = [String:[String:String]]

typealias Words = [String:[(MediaItem,Int)]]

class Lexicon : NSObject {
    weak var mediaListGroupSort:MediaListGroupSort?
    
    init(_ mlgs:MediaListGroupSort?){
        self.mediaListGroupSort = mlgs
    }
    
    var words:Words? {
        didSet {
//            print(words?.count)
        }
    }
    
    var creating = false
    var pauseUpdates = false
    var completed = false

    var entries:[MediaItem]? {
        get {
            var mediaItemSet = Set<MediaItem>()
            
            if let list:[[MediaItem]] = words?.values.map({ (array:[(MediaItem,Int)]) -> [MediaItem] in
                return array.map({ (tuple:(MediaItem,Int)) -> MediaItem in
                    return tuple.0
                })
            }) {
                for mediaItemList in list {
                    mediaItemSet = mediaItemSet.union(Set(mediaItemList))
                }
            }
            
            return mediaItemSet.count > 0 ? Array(mediaItemSet) : nil
        }
    }
    
    var eligible:[MediaItem]? {
        get {
            if let list = mediaListGroupSort?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasNotesHTML
            }), list.count > 0 {
                return list
            } else {
                return nil
            }
        }
    }
    
    func build()
    {
        guard !creating else {
            return
        }
        
        guard (words == nil) else {
            return
        }
        
        if let list = eligible {
            creating = true
            
            DispatchQueue.global(qos: .background).async {
                var dict = Words()
                
                var date:Date?
                
                for mediaItem in list {
                    if mediaItem.hasNotesHTML {
                        DispatchQueue(label: "CBC").async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self)
                        })
                        
                        mediaItem.loadNotesTokens()
                        
                        if let notesTokens = mediaItem.notesTokens {
                            for token in notesTokens {
                                if dict[token.0] == nil {
                                    dict[token.0] = [(mediaItem,token.1)]
                                } else {
                                    dict[token.0]?.append((mediaItem,token.1))
                                }

                                if globals.isRefreshing || globals.isLoading {
                                    break
                                }
                            }
                        }
                        
                        if globals.isRefreshing || globals.isLoading {
                            break
                        }
                        
                        //                        var strings = [String]()
                        //
                        //                        let words = dict.keys.sorted()
                        //                        for word in words {
                        //                            if let count = dict[word]?.count {
                        //                                strings.append("\(word) (\(count))")
                        //                            }
                        //                        }
                        
                        if !self.pauseUpdates {
                            self.words = dict.count > 0 ? dict : nil
                            
                            if let interval = date?.timeIntervalSinceNow {
                                if interval < -1 {
                                    DispatchQueue(label: "CBC").async(execute: { () -> Void in
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
                                    })
                                }
                            } else {
                                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
                                })
                            }
                            
                            date = Date()
                        }
                    }
                    
                    if globals.isRefreshing || globals.isLoading {
                        break
                    }
                }
                
                self.words = dict.count > 0 ? dict : nil
                
                self.creating = false
                self.completed = true
                
                //        print(dict)
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self)
                })
            }
        }
    }
    
    func load()
    {
        guard (words == nil) else {
            return
        }
        
        var dict = Words()
        
        if let list = eligible {
            for mediaItem in list {
                mediaItem.loadNotesTokens()
                
                if let notesTokens = mediaItem.notesTokens {
                    for token in notesTokens {
                        if dict[token.0] == nil {
                            dict[token.0] = [(mediaItem,token.1)]
                        } else {
                            dict[token.0]?.append((mediaItem,token.1))
                        }
                    }
                }
            }
        }
        
        //        print(dict)
        
        words = dict.count > 0 ? dict : nil
    }
    
    override var description:String {
        get {
            load()
            
            var string = String()
            
            if let keys = words?.keys.sorted() {
                for key in keys {
                    string = string + key + "\n"
                    if let mediaItems = words?[key]?.sorted(by: { (first, second) -> Bool in
                        if first.1 == second.1 {
                            return first.0.fullDate!.isOlderThan(second.0.fullDate!)
                        } else {
                            return first.1 > second.1
                        }
                    }) {
                        for mediaItem in mediaItems {
                            string = string + "(\(mediaItem.0,mediaItem.1))\n"
                        }
                    }
                }
            }
            
            return string
        }
    }
}


class MediaListGroupSort {
    @objc func freeMemory()
    {
        lexicon = nil
        
        guard searches != nil else {
            return
        }
        
        if !globals.search.active {
            searches = nil
        } else {
            // Is this risky, to try and delete all but the current search?
            if let keys = searches?.keys {
                for key in keys {
                    //                    print(key,globals.search.text)
                    if key != globals.search.text {
                        searches?[key] = nil
                    } else {
                        //                        print(key,globals.search.text)
                    }
                }
            }
        }
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: globals.contextOrder)
    }()
    
    var list:[MediaItem]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:MediaItem]()
                
                for mediaItem in list! {
                    index![mediaItem.id!] = mediaItem
                    
                    if let className = mediaItem.className {
                        if classes == nil {
                            classes = [className]
                        } else {
                            classes?.append(className)
                        }
                    }
                }
            }
        }
    }
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    var classes:[String]?
    
    lazy var lexicon:Lexicon? = {
        [unowned self] in
        return Lexicon(self)
    }()
    
    var searches:[String:MediaListGroupSort]? // Hierarchical means we could search within searches - but not right now.
    
    lazy var scriptureIndex:ScriptureIndex? = {
        [unowned self] in
        return ScriptureIndex(self)
    }()
    
    var groupSort:MediaGroupSort?
    var groupNames:MediaGroupNames?
    
    var tagMediaItems:[String:[MediaItem]]?//sortTag:MediaItem
    var tagNames:[String:String]?//sortTag:tag
    
    var mediaItemTags:[String]? {
        get {
            return tagMediaItems?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                return self.tagNames![string]!
            })
        }
    }
    
    var mediaItems:[MediaItem]? {
        get {
            return mediaItems(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        guard (list != nil) else {
            return
        }
        
        //        var strings:[String]?
        //        var names:[String]?
        
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
        globals.finished += list!.count
        
        for mediaItem in list! {
            var entries:[(string:String,name:String)]?
            
            switch grouping! {
            case Grouping.YEAR:
                entries = [(mediaItem.yearString,mediaItem.yearString)]
                break
                
            case Grouping.TITLE:
                entries = [(mediaItem.multiPartSectionSort,mediaItem.multiPartSection)]
                break
                
            case Grouping.BOOK:
                // Need to update this for the fact that mediaItems can have more than one book.
                if let books = mediaItem.books {
                    for book in books {
                        if entries == nil {
                            entries = [(book,book)]
                        } else {
                            entries?.append((book,book))
                        }
                    }
                }
                if entries == nil {
                    if let scriptureReference = mediaItem.scriptureReference?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                        entries = [(scriptureReference,scriptureReference)]
                    } else {
                        entries = [(Constants.None,Constants.None)]
                    }
                }
                //                if entries?.count > 1 {
                //                    print(mediaItem,entries!)
                //                }
                break
                
            case Grouping.SPEAKER:
                entries = [(mediaItem.speakerSectionSort,mediaItem.speakerSection)]
                break
                
            case Grouping.CLASS:
                entries = [(mediaItem.classSectionSort,mediaItem.classSection)]
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping!] == nil) {
                groupNames?[grouping!] = [String:String]()
            }
            
            if entries != nil {
                for entry in entries! {
                    groupNames?[grouping!]?[entry.string] = entry.name
                    
                    if (groupedMediaItems[grouping!] == nil) {
                        groupedMediaItems[grouping!] = [String:[MediaItem]]()
                    }
                    
                    if groupedMediaItems[grouping!]?[entry.string] == nil {
                        groupedMediaItems[grouping!]?[entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping!]?[entry.string]?.append(mediaItem)
                    }
                    
                    globals.progress += 1
                }
            }
        }
        
        if (groupedMediaItems[grouping!] != nil) {
            globals.finished += groupedMediaItems[grouping!]!.keys.count
        }
        
        if (groupSort?[grouping!] == nil) {
            groupSort?[grouping!] = [String:[String:[MediaItem]]]()
        }
        if (groupedMediaItems[grouping!] != nil) {
            for string in groupedMediaItems[grouping!]!.keys {
                if (groupSort?[grouping!]?[string] == nil) {
                    groupSort?[grouping!]?[string] = [String:[MediaItem]]()
                }
                for sort in Constants.sortings {
                    let array = sortMediaItemsChronologically(groupedMediaItems[grouping!]?[string])
                    
                    switch sort {
                    case Sorting.CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array
                        break
                        
                    case Sorting.REVERSE_CHRONOLOGICAL:
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
    
    func mediaItems(grouping:String?,sorting:String?) -> [MediaItem]?
    {
        var groupedSortedMediaItems:[MediaItem]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sorted(
                by: {
                    switch grouping! {
                    case Grouping.YEAR:
                        switch sorting! {
                        case Sorting.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Sorting.REVERSE_CHRONOLOGICAL:
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
                        
//                    case Grouping.SPEAKER:
//                        return $0 < $1
//                        
//                    case Grouping.TITLE:
//                        return $0.lowercased() < $1.lowercased()
                        
                    default:
                        return $0.lowercased() < $1.lowercased()
                    }
                    
                    return $0 < $1
            }) {
                let mediaItems = groupSort?[grouping!]?[key]?[sorting!]
                
                if (groupedSortedMediaItems == nil) {
                    groupedSortedMediaItems = mediaItems
                } else {
                    groupedSortedMediaItems?.append(contentsOf: mediaItems!)
                }
            }
        }
        
        return groupedSortedMediaItems
    }
    
    struct Section {
        weak var mlgs:MediaListGroupSort?
        
        init(_ mlgs:MediaListGroupSort?)
        {
            self.mlgs = mlgs
        }
        
        var titles:[String]? {
            get {
                return mlgs?.sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var counts:[Int]? {
            get {
                return mlgs?.sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexes:[Int]? {
            get {
                return mlgs?.sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexTitles:[String]? {
            get {
                return mlgs?.sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
    }
    
    lazy var section:Section? = {
        [unowned self] in
        var section = Section(self)
        return section
        }()
    
    //    var sectionIndexTitles:[String]? {
    //        get {
    //            return sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    //
    //    var sectionTitles:[String]? {
    //        get {
    //            return sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    //
    //    var sectionCounts:[Int]? {
    //        get {
    //            return sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
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
    
    func sectionTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return sectionIndexTitles(grouping: grouping,sorting: sorting)?.map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
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
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
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
    
    init(mediaItems:[MediaItem]?)
    {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaListGroupSort.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        guard (mediaItems != nil) else {
            //            globals.finished = 1
            //            globals.progress = 1
            return
        }
        
        globals.finished = 0
        globals.progress = 0
        
        list = mediaItems
        
        groupNames = MediaGroupNames()
        groupSort = MediaGroupSort()
        
        sortGroup(globals.grouping)
        
        globals.finished += list!.count

        tagMediaItems = [String:[MediaItem]]()
        tagNames = [String:String]()

        for mediaItem in list! {
            if let tags =  mediaItem.tagsSet {
                for tag in tags {
                    let sortTag = stringWithoutPrefixes(tag)
                    if tagMediaItems?[sortTag!] == nil {
                        tagMediaItems?[sortTag!] = [mediaItem]
                    } else {
                        tagMediaItems?[sortTag!]?.append(mediaItem)
                    }
                    tagNames?[sortTag!] = tag
                }
            }
            globals.progress += 1
        }
    }
}

