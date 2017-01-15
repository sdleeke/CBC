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
typealias MediaGroupSort = [String:[String:[String:[MediaItem]]]]

//Group//String//Name
typealias MediaGroupNames = [String:[String:String]]


typealias Lexicon = [String:[(MediaItem,Int)]]


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
                }
            }
        }
    }
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    
    var lexicon:Lexicon? {
        didSet {
            print("lexicon set")
        }
    }
    
    var creatingLexicon = false
    
    func createLexicon()
    {
        if !creatingLexicon, lexicon == nil, let list = list {
            creatingLexicon = true
            
            DispatchQueue.global(qos: .background).async {
                var dict = Lexicon()
                
//                var count = 0
                
                var total = 0
                
                for mediaItem in list {
                    if mediaItem.hasNotesHTML {
                        total += 1
                    }
                }
                
                for mediaItem in list {
                    if mediaItem.hasNotesHTML {
                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: nil)
                        })
                        
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
                        
                        var strings = [String]()
                        
                        let words = dict.keys.sorted()
                        for word in words {
                            if let count = dict[word]?.count {
                                strings.append("\(word) (\(count))")
                            }
                        }
                        
//                        count += 1

                        self.lexicon = dict.count > 0 ? dict : nil

                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: nil)
                        })
                    }
                }
                
                self.lexicon = dict.count > 0 ? dict : nil
                
                //        print(dict)
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_FINISHED), object: nil)
                })
                
                self.creatingLexicon = false
            }
        }
    }
    
    func printLexicon()
    {
        loadLexicon()
        
        if let keys = lexicon?.keys.sorted() {
            for key in keys {
                print(key)
                if let mediaItems = lexicon?[key]?.sorted(by: { (first, second) -> Bool in
                    if first.1 == second.1 {
                        return first.0.fullDate!.isOlderThan(second.0.fullDate!)
                    } else {
                        return first.1 > second.1
                    }
                }) {
                    for mediaItem in mediaItems {
                        print(mediaItem.0,mediaItem.1)
                    }
                    print("")
                }
            }
        }
    }
    
    func loadLexicon()
    {
        guard (lexicon == nil) else {
            return
        }
        
        var dict = Lexicon()
        
        if let list = list {
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
        
        lexicon = dict.count > 0 ? dict : nil
    }
    
    var searches:[String:MediaListGroupSort]? // Hierarchical means we could search within searches - but not right now.
    
    var scriptureIndex:ScriptureIndex?
    
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
                        
                    case Grouping.SPEAKER:
                        return $0 < $1
                        
                    case Grouping.TITLE:
                        return $0.lowercased() < $1.lowercased()
                        
                    default:
                        break
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
        
        init(mlgs:MediaListGroupSort?)
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
        var section = Section(mlgs:self)
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

