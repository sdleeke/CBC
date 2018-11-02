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

//Group//String//Sort
//[String:[String:[String:[MediaItem]]]]
typealias MediaGroupSort = ThreadSafeDictionaryOfDictionaries<[String:[MediaItem]]>

//Group//String//Name
//[String:[String:String]]
typealias MediaGroupNames = ThreadSafeDictionaryOfDictionaries<String>

typealias Words = ThreadSafeDictionary<[MediaItem:Int]>

// This needs to be broken up into simpler components and reviewed for threadsafety
class MediaListGroupSort
{
    @objc func freeMemory()
    {
        lexicon = Lexicon(self) // Side effects?
        
        scriptureIndex = ScriptureIndex(self) // side effects?
        
        guard searches != nil else {
            return
        }
        
        if !Globals.shared.search.active {
            searches = nil
        } else {
            // Is this risky, to try and delete all but the current search?
            if let keys = searches?.keys {
                for key in keys {
                    if key != Globals.shared.search.text {
                        searches?[key] = nil
                    } else {

                    }
                }
            }
        }
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: Globals.shared.contextOrder)
    }()
    
    var list:[MediaItem]?
    { //Not in any specific order
        willSet {
            
        }
        didSet {
            guard let list = list else {
                return
            }
            
            index = [String:MediaItem]()
            
            for mediaItem in list {
                if let id = mediaItem.id {
                    index?[id] = mediaItem
                }
                
                if mediaItem.hasClassName, let className = mediaItem.className {
                    if classes == nil {
                        classes = [className]
                    } else {
                        classes?.append(className)
                    }
                }
                
                if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                    if events == nil {
                        events = [eventName]
                    } else {
                        events?.append(eventName)
                    }
                }
            }
        }
    }

    // Make thread safe?
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    var classes:[String]?
    var events:[String]?
    
    lazy var lexicon:Lexicon? = {
        return Lexicon(self) // lexicon
    }()
    
    // Hierarchical means we could search within searches - but not right now.
    var searches: ThreadSafeDictionary<MediaListGroupSort>? // [String:MediaListGroupSort]?
    
    lazy var scriptureIndex:ScriptureIndex? = {
        return ScriptureIndex(self)
    }()
    
    var groupSort:MediaGroupSort?
    {
        didSet {
            
        }
    }
    var groupNames:MediaGroupNames?
    {
        didSet {
            
        }
    }
    
    // Make thread safe?
    var tagMediaItems:[String:[MediaItem]]?//sortTag:MediaItem
    {
        didSet {
            
        }
    }

    // Make thread safe?
    var tagNames:[String:String]?//sortTag:tag
    {
        didSet {
            
        }
    }
    
    // Make thread safe?
    var proposedTags:[String]?
    {
        get {
            var possibleTags = [String:Int]()
            
            if let tags = mediaItemTags {
                for tag in tags {
                    var possibleTag = tag
                    
                    if possibleTag.range(of: "-") != nil {
                        while let range = possibleTag.range(of: "-") {
                            let candidate = String(possibleTag[..<range.lowerBound]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }

                            possibleTag = String(possibleTag[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
                
            return proposedTags.count > 0 ? proposedTags : nil
        }
    }
    
    // Make thread safe?
    var mediaItemTags:[String]?
    {
        get {
            return tagMediaItems?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                if let tagName = self.tagNames?[string] {
                    return tagName
                } else {
                    return "ERROR"
                }
            })
        }
    }
    
    // Make thread safe?
    var mediaItems:[MediaItem]?
    {
        get {
            return mediaItems(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        guard let grouping = grouping else {
            return
        }
        
        guard let list = list else {
            return
        }
        
        // Make thread safe?
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
        for mediaItem in list {
            var entries:[(string:String,name:String)]?
            
            switch grouping {
            case GROUPING.YEAR:
                entries = [(mediaItem.yearString,mediaItem.yearString)]
                break
                
            case GROUPING.TITLE:
                entries = [(mediaItem.multiPartSectionSort,mediaItem.multiPartSection)]
                break
                
            case GROUPING.BOOK:
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
                        entries = [(Constants.Strings.None,Constants.Strings.None)]
                    }
                }
                break
                
            case GROUPING.SPEAKER:
                entries = [(mediaItem.speakerSectionSort,mediaItem.speakerSection)]
                break
                
            case GROUPING.CLASS:
                entries = [(mediaItem.classSectionSort,mediaItem.classSection)]
                break
                
            case GROUPING.EVENT:
                entries = [(mediaItem.eventSectionSort,mediaItem.eventSection)]
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping] == nil) {
                groupNames?[grouping] = [String:String]()
            }
            if let entries = entries {
                for entry in entries {
                    groupNames?[grouping]?[entry.string] = entry.name
                    
                    if (groupedMediaItems[grouping] == nil) {
                        groupedMediaItems[grouping] = [String:[MediaItem]]()
                    }
                    
                    if groupedMediaItems[grouping]?[entry.string] == nil {
                        groupedMediaItems[grouping]?[entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping]?[entry.string]?.append(mediaItem)
                    }
                }
            }
        }
        
        if (groupSort?[grouping] == nil) {
            groupSort?[grouping] = [String:[String:[MediaItem]]]()
        }
        if let keys = groupedMediaItems[grouping]?.keys {
            for string in keys {
                if (groupSort?[grouping]?[string] == nil) {
                    groupSort?[grouping]?[string] = [String:[MediaItem]]()
                }
                for sort in Constants.sortings {
                    let array = sortMediaItemsChronologically(groupedMediaItems[grouping]?[string])
                    
                    switch sort {
                    case SORTING.CHRONOLOGICAL:
                        groupSort?[grouping]?[string]?[sort] = array
                        break
                        
                    case SORTING.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping]?[string]?[sort] = array?.reversed()
                        break
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func mediaItems(grouping:String?,sorting:String?) -> [MediaItem]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        var groupedSortedMediaItems:[MediaItem]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if let keys = groupSort?[grouping]?.keys.sorted(
                by: {
                    switch grouping {
                    case GROUPING.YEAR:
                        switch sorting {
                        case SORTING.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case SORTING.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case GROUPING.BOOK:
                        if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return $0.withoutPrefixes < $1.withoutPrefixes
                        } else {
                            return bookNumberInBible($0) < bookNumberInBible($1)
                        }
                        
                    default:
                        return $0.lowercased() < $1.lowercased()
                    }
                    
                    return $0 < $1
            }) {
            for key in keys {
                if let mediaItems = groupSort?[grouping]?[key]?[sorting] {
                    if (groupedSortedMediaItems == nil) {
                        groupedSortedMediaItems = mediaItems
                    } else {
                        groupedSortedMediaItems?.append(contentsOf: mediaItems)
                    }
                }
            }
        }
        
        return groupedSortedMediaItems
    }
    
    class Section
    {
        weak var mediaListGroupSort:MediaListGroupSort?
        
        init(_ mediaListGroupSort:MediaListGroupSort?)
        {
            self.mediaListGroupSort = mediaListGroupSort
        }
        
        deinit {
            
        }
        
        var headerStrings:[String]?
        {
            get {
                return mediaListGroupSort?.sectionTitles(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
            }
        }
        
        var counts:[Int]?
        {
            get {
                return mediaListGroupSort?.sectionCounts(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
            }
        }
        
        var indexes:[Int]?
        {
            get {
                return mediaListGroupSort?.sectionIndexes(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
            }
        }
        
        var indexStrings:[String]?
        {
            get {
                return mediaListGroupSort?.sectionIndexTitles(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
            }
        }
    }
    
    lazy var section:Section? = {
        return Section(self) // section
    }()
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        return groupSort?[grouping]?.keys.sorted(by: {
            switch grouping {
            case GROUPING.YEAR:
                switch sorting {
                case SORTING.CHRONOLOGICAL:
                    return $0 < $1
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case GROUPING.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
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
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        return sectionIndexTitles(grouping: grouping,sorting: sorting)?.compactMap({ (string:String) -> String? in
            return groupNames?[grouping]?[string]
        })
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        return groupSort?[grouping]?.keys.sorted(by: {
            switch grouping {
            case GROUPING.YEAR:
                switch sorting {
                case SORTING.CHRONOLOGICAL:
                    return $0 < $1
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case GROUPING.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            if let count = groupSort?[grouping]?[string]?[sorting]?.count {
                return count
            } else {
                // ERROR
                return -1
            }
        })
    }
    
    var sectionIndexes:[Int]?
    {
        get {
            return sectionIndexes(grouping: Globals.shared.grouping,sorting: Globals.shared.sorting)
        }
    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        var cumulative = 0
        
        return groupSort?[grouping]?.keys.sorted(by: {
            switch grouping {
            case GROUPING.YEAR:
                switch sorting {
                case SORTING.CHRONOLOGICAL:
                    return $0 < $1
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case GROUPING.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            if let count = groupSort?[grouping]?[string]?[sorting]?.count {
                cumulative += count
            } else {
                // ???
            }
            
            return prior
        })
    }
    
    deinit {
        
    }
    
    init(mediaItems:[MediaItem]?)
    {
        Thread.onMainThread {
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        guard let mediaItems = mediaItems else {
            return
        }
        
        list = mediaItems

        index = [String:MediaItem]()
        
        for mediaItem in mediaItems {
            if let id = mediaItem.id {
                index?[id] = mediaItem
            }
            
            if mediaItem.hasClassName, let className = mediaItem.className {
                if classes == nil {
                    classes = [className]
                } else {
                    classes?.append(className)
                }
            }
            
            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                if events == nil {
                    events = [eventName]
                } else {
                    events?.append(eventName)
                }
            }
        }

        groupNames = MediaGroupNames(name: "MediaGroupNames")
        groupSort = MediaGroupSort(name: "MediaGroupSort")
        
        sortGroup(Globals.shared.grouping)

        // Why isn't this done on demand?
        //
        // Because we use tagNames (and tagMediaItems.keys for sorting the tagNames)
        // in the tag menu
        //
        tagMediaItems = [String:[MediaItem]]()
        tagNames = [String:String]()

        for mediaItem in mediaItems {
            if let tags =  mediaItem.tagsSet {
                for tag in tags {
                    let sortTag = tag.withoutPrefixes
                    
                    if !sortTag.isEmpty {
                        if tagMediaItems?[sortTag] == nil {
                            tagMediaItems?[sortTag] = [mediaItem]
                        } else {
                            tagMediaItems?[sortTag]?.append(mediaItem)
                        }
                        tagNames?[sortTag] = tag
                    }
                }
            }
        }
    }
}

