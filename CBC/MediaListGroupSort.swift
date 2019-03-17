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
    var _sorting : String?
    {
        didSet {
            
        }
    }
    var sorting : String?
    {
        get {
            return _sorting ?? Globals.shared.sorting
        }
        set {
            _sorting = newValue
        }
    }
    
    var _grouping : String?
    {
        didSet {
            
        }
    }
    var grouping : String?
    {
        get {
            return _grouping ?? Globals.shared.grouping
        }
        set {
            _grouping = newValue
        }
    }
    
    var _search : Search!
    {
        didSet {
            // Will this happen when it is a property of Search that is being set?  No.
        }
    }
    var search : Search!
    {
        get {
            return _search ?? Globals.shared.search
        }
        set {
            if _search == nil {
                _search = Search()
            }
            
            _search = newValue
        }
    }
    
    var orderString:String?
    {
        get {
            var string:String?
            
            if let sorting = sorting {
                string = ((string != nil) ? string! + ":" : "") + sorting
            }
            
            if let grouping = grouping {
                string = ((string != nil) ? string! + ":" : "") + grouping
            }
            
            return string
        }
    }
    
    var _category : String?
    {
        didSet {
            
        }
    }
    var category : String?
    {
        get {
            return _category ?? Globals.shared.mediaCategory.selected
        }
        set {
            _category = newValue
        }
    }
    
    var _tagSelected : String?
    {
        didSet {
            
        }
    }
    var tagSelected : String?
    {
        get {
            return _tagSelected ?? Globals.shared.media.tags.selected
        }
        set {
            _tagSelected = newValue
        }
    }
    
    var contextString:String?
    {
        get {
            guard let category = category else {
                return nil
            }
            
            var string = category
            
            if let tag = tagSelected {
                string = (!string.isEmpty ? string + ":" : "") + tag
            }
            
            if search.valid, let search = search.text {
                string = (!string.isEmpty ? string + ":" : "") + search
            }
            
            return !string.isEmpty ? string : nil
        }
    }
    
    func contextOrder() -> String?
    {
        var string:String?
        
        if let context = contextString {
            string = ((string != nil) ? string! + ":" : "") + context
        }
        
        if let order = orderString {
            string = ((string != nil) ? string! + ":" : "") + order
        }
        
        return string
    }
    
    lazy var html:CachedString? = { [weak self] in
        return CachedString(index: contextOrder)
    }()
    
    @objc func freeMemory()
    {
        lexicon = Lexicon(self) // Side effects?
        
        scriptureIndex = ScriptureIndex(self) // side effects?
        
        guard searches != nil else {
            return
        }
        
        if !search.active {
            searches = nil
        } else {
            // Is this risky, to try and delete all but the current search?  Don't think so as searches is thread safe.
            if let keys = searches?.keys {
                for key in keys {
                    if key != search.text {
                        searches?[key] = nil
                    } else {

                    }
                }
            }
        }
    }
    
    var mediaList:MediaList?
    {
        didSet {
            
        }
    }
    
    lazy var lexicon:Lexicon? = { [weak self] in
        return Lexicon(self) // lexicon
    }()
    
    // Hierarchical means we could search within searches - but not right now.
    var searches: ThreadSafeDictionary<MediaListGroupSort>? // [String:MediaListGroupSort]?
    
    lazy var scriptureIndex:ScriptureIndex? = { [weak self] in
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
//    var proposedTags:[String]?
//    {
//        get {
//            var possibleTags = [String:Int]()
//            
//            if let tags = mediaItemTags {
//                for tag in tags {
//                    var possibleTag = tag
//                    
//                    if possibleTag.range(of: "-") != nil {
//                        while let range = possibleTag.range(of: "-") {
//                            let candidate = String(possibleTag[..<range.lowerBound]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                            
//                            if (Int(candidate) == nil) && !tags.contains(candidate) {
//                                if let count = possibleTags[candidate] {
//                                    possibleTags[candidate] =  count + 1
//                                } else {
//                                    possibleTags[candidate] =  1
//                                }
//                            }
//
//                            possibleTag = String(possibleTag[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                        }
//                        
//                        if !possibleTag.isEmpty {
//                            let candidate = possibleTag.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//
//                            if (Int(candidate) == nil) && !tags.contains(candidate) {
//                                if let count = possibleTags[candidate] {
//                                    possibleTags[candidate] =  count + 1
//                                } else {
//                                    possibleTags[candidate] =  1
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            
//            let proposedTags = [String](possibleTags.keys)
//                
//            return proposedTags.count > 0 ? proposedTags : nil
//        }
//    }
    
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
            return mediaItems(grouping: grouping,sorting: sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        guard let grouping = grouping else {
            return
        }
        
        guard let mediaList = mediaList?.list else {
            return
        }
        
        // Make thread safe?
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
        for mediaItem in mediaList {
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

            // Should be done in ThreadSafeDictionary
            if (groupNames?[grouping] == nil) {
                groupNames?[grouping] = [String:String]()
            }
            if let entries = entries {
                for entry in entries {
//                    groupNames?.set(grouping,entry.string,value:entry.name)
                    
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
        
        // Should be done in ThreadSafeDictionary
        if (groupSort?[grouping] == nil) {
            groupSort?[grouping] = [String:[String:[MediaItem]]]()
        }
        if let keys = groupedMediaItems[grouping]?.keys {
            for string in keys {
                // This is a third level of dictionary.  Is there any way to have a generic N-level dict of dicts?
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
        private weak var mediaListGroupSort:MediaListGroupSort?
        
        var sorting : String?
        {
            get {
                return mediaListGroupSort?.sorting
            }
        }
        
        var grouping : String?
        {
            get {
                return mediaListGroupSort?.grouping
            }
        }
        
        init(_ mediaListGroupSort:MediaListGroupSort?)
        {
            self.mediaListGroupSort = mediaListGroupSort
        }
        
        deinit {
            
        }
        
        var headerStrings:[String]?
        {
            get {
                return mediaListGroupSort?.sectionTitles(grouping: grouping,sorting: sorting)
            }
        }
        
        var counts:[Int]?
        {
            get {
                return mediaListGroupSort?.sectionCounts(grouping: grouping,sorting: sorting)
            }
        }
        
        var indexes:[Int]?
        {
            get {
                return mediaListGroupSort?.sectionIndexes(grouping: grouping,sorting: sorting)
            }
        }
        
        var indexStrings:[String]?
        {
            get {
                return mediaListGroupSort?.sectionIndexTitles(grouping: grouping,sorting: sorting)
            }
        }
    }
    
    lazy var section:Section? = { [weak self] in
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
            return sectionIndexes(grouping: grouping,sorting: sorting)
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
    
    init(mediaItems:[MediaItem]?)
    {
        Thread.onMainThread {
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        mediaList = MediaList(mediaItems)
        
        mediaList?.didSet = { [weak self] in
            self?.lexicon?.eligible = nil
            self?.scriptureIndex?.eligible = nil
        }

//        index = [String:MediaItem]()
//
//        for mediaItem in mediaItems {
//            if let id = mediaItem.id {
//                index?[id] = mediaItem
//            }
//
//            if mediaItem.hasClassName, let className = mediaItem.className {
//                if classes == nil {
//                    classes = [className]
//                } else {
//                    classes?.append(className)
//                }
//            }
//
//            if mediaItem.hasEventName, let eventName = mediaItem.eventName {
//                if events == nil {
//                    events = [eventName]
//                } else {
//                    events?.append(eventName)
//                }
//            }
//        }

        groupNames = MediaGroupNames(name: "MediaGroupNames")
        groupSort = MediaGroupSort(name: "MediaGroupSort")
        
        sortGroup(grouping)

        guard let mediaItems = mediaItems else {
            return
        }
        
        // Why isn't this done on demand?
        //
        // Because we use tagNames (and tagMediaItems.keys for sorting the tagNames)
        // in the tag menu
        //
        
        tagMediaItems = [String:[MediaItem]]()
        tagNames = [String:String]()

        mediaItems.forEach { (mediaItem:MediaItem) in
            mediaItem.tagsSet?.forEach({ (tag:String) in
                let sortTag = tag.withoutPrefixes
                
                if !sortTag.isEmpty {
                    if tagMediaItems?[sortTag] == nil {
                        tagMediaItems?[sortTag] = [mediaItem]
                    } else {
                        tagMediaItems?[sortTag]?.append(mediaItem)
                    }
                    tagNames?[sortTag] = tag
                }
            })
        }
//        for mediaItem in mediaItems {
//            if let tags =  mediaItem.tagsSet {
//                for tag in tags {
//                    let sortTag = tag.withoutPrefixes
//                    
//                    if !sortTag.isEmpty {
//                        if tagMediaItems?[sortTag] == nil {
//                            tagMediaItems?[sortTag] = [mediaItem]
//                        } else {
//                            tagMediaItems?[sortTag]?.append(mediaItem)
//                        }
//                        tagNames?[sortTag] = tag
//                    }
//                }
//            }
//        }
    }
}

