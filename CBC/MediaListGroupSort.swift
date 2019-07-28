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

/*
//Group//String//Sort
//[String:[String:[String:[MediaItem]]]]
typealias MediaGroupSort = ThreadSafeDN<[MediaItem]> // ictionaryOfDictionariesOfDictionaries

//Group//String//Name
//[String:[String:String]]
typealias MediaGroupNames = ThreadSafeDN<String> // ictionaryOfDictionaries

typealias Words = ThreadSafeDN<[MediaItem:Int]> // ictionary
*/

/**

 A version of Section for MediaListGroupSort
 
 */

class MLGSSection
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
    
    init?(_ mediaListGroupSort:MediaListGroupSort?)
    {
        guard mediaListGroupSort != nil else {
            return nil
        }
        
        self.mediaListGroupSort = mediaListGroupSort
    }
    
    deinit {
        debug(self)
    }
    
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    // thread safe?
    lazy var headerStrings:[String]? = {
        return queue.sync {
            return mediaListGroupSort?.sectionTitles(grouping: grouping,sorting: sorting)
        }
    }()
    
    lazy var counts:[Int]? = {
        return queue.sync {
            return mediaListGroupSort?.sectionCounts(grouping: grouping,sorting: sorting)
        }
    }()
    
    lazy var indexes:[Int]? = {
        return queue.sync {
            return mediaListGroupSort?.sectionIndexes(grouping: grouping,sorting: sorting)
        }
    }()
    
    lazy var indexStrings:[String]? = {
        return queue.sync {
            return mediaListGroupSort?.sectionIndexTitles(grouping: grouping,sorting: sorting)
        }
    }()
    
    lazy var mediaItems:[MediaItem]? = {
        return queue.sync {
            return mediaListGroupSort?.mediaItems(grouping: grouping,sorting: sorting)
        }
    }()
}

/**
 
 Manages all sorting and grouping of media items.

 This needs to be broken up into simpler components and reviewed for threadsafety

 Properties:
    - mediaList
    - lexicon
    - scriptureIndex
    - groupSort
    - groupNames
    - tagMediaItems
    - tagNames
 
 Methods:
    - sortGroup
    - mediaItems
 
 */

struct MediaNeed
{
    var sorting:Bool = true
    var grouping:Bool = true
}

class MediaListGroupSort // : NSObject
{
    deinit {
        debug(self)
    }
    
    var need = MediaNeed()
    
    var name : String?
    var complete = false
    var cancelled = false
    var when : Date?
    
    var groupings = Constants.groupings
    var groupingTitles = Constants.GroupingTitles

    // In case we want different sorting in different MLGS's some day?
    var sorting : String? // lazy Default<String>({ return Globals.shared.sorting })
    {
        get {
            return Globals.shared.sorting
        }
        set {
            if !need.sorting {
                // => Once set it must be reset elsewhere.
                need.sorting = (sorting != newValue)
            }
            
            Globals.shared.sorting = newValue
        }
    }
    
    // In case we want different grouping in different MLGS's some day?
    var grouping : String? // lazy Default<String>({ return Globals.shared.grouping })
    {
        get {
            return Globals.shared.grouping
        }
        set {
            if !need.grouping {
                // => Once set it must be reset elsewhere.
                need.grouping = (grouping != newValue)
            }
            
            Globals.shared.grouping = newValue
        }
    }

    // In case we want different search in different MLGS's some day?
    var search : Search! // lazy Default<Search>({ return Globals.shared.media.search })
    {
        get {
            return Globals.shared.media.search
        }
        set {
            Globals.shared.media.search = newValue
        }
    }

    // In case we want different categories in different MLGS's some day?
    var category : String? // lazy Default<String>({ return Globals.shared.media.category.selected })
    {
        get {
            return Globals.shared.media.category.selected
        }
        set {
            Globals.shared.media.category.selected = newValue
        }
    }

    // In case we want different tags selected in different MLGS's some day?
    var tag : String? // lazy Default<String>({ return Globals.shared.media.tags.selected })
    {
        get {
            return Globals.shared.media.tags.selected
        }
        set {
            Globals.shared.media.tags.selected = newValue
        }
    }

    func addTagMediaItem(mediaItem:MediaItem,sortTag:String?,tag:String?)
    {
        // Tag added but no point in updating unless...
        guard let tag = tag else {
            return
        }
        
        guard let sortTag = sortTag else {
            return
        }
        
        if tagMediaItems?[sortTag] != nil {
            if tagMediaItems?[sortTag]?.firstIndex(of: mediaItem) == nil {
                tagMediaItems?[sortTag]?.append(mediaItem)
                tagNames?[sortTag] = tag
            }
        } else {
            tagMediaItems?[sortTag] = [mediaItem]
            tagNames?[sortTag] = tag
        }
    }

    func removeTagMediaItem(mediaItem:MediaItem,sortTag:String?,tag:String?)
    {
        // Tag removed but no point in updating unless...
        guard let tag = tag else {
            return
        }
        
        guard let sortTag = sortTag else {
            return
        }

        if let index = tagMediaItems?[sortTag]?.firstIndex(of: mediaItem) {
            tagMediaItems?[sortTag]?.remove(at: index)
        }

        if tagMediaItems?[sortTag]?.count == 0 {
            tagMediaItems?[sortTag] = nil // .removeValue(forKey: sortTag)
            tagNames?[sortTag] = nil
        }
    }

    var order:String?
    {
        get {
            var string:String?

            if let sorting = sorting?.uppercased() {
                string = ((string != nil) ? string! + ":" : "") + sorting
            }

            if let grouping = grouping?.uppercased() {
                string = ((string != nil) ? string! + ":" : "") + grouping
            }

            return string
        }
    }
    
    var context:String?
    {
        get {
            guard let category = category?.uppercased(), !category.isEmpty else {
                return nil
            }
            
            var string = "CATEGORY:" + category
            
            if let tag = tag?.uppercased() {
                string += "|TAG:" + tag
            }
            
            if search.transcripts {
                string += "|TRANSCRIPTS:YES"
            }

            if search.isValid, let search = search.text?.uppercased() {
                string += "|SEARCH:" + search
            }
            
            return !string.isEmpty ? string : nil
        }
    }
    
    var contextOrder : String?
    {
        get {
            var string:String?
            
            if let context = context {
                string = ((string != nil) ? string! + ":" : "") + context
            }
            
            if let order = order {
                string = ((string != nil) ? string! + ":" : "") + order
            }
            
            return string
        }
    }
    
    lazy var html:CachedString? = { [weak self] in
        return CachedString(index: { self?.contextOrder })
    }()
    
    @objc func freeMemory()
    {
        lexicon = Lexicon(self) // Side effects?
        
        scriptureIndex = ScriptureIndex(self) // side effects?
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
//    var searches: ThreadSafeDN<MediaListGroupSort>? // [String:MediaListGroupSort]? // ictionary
    
    lazy var scriptureIndex:ScriptureIndex? = { [weak self] in
        return ScriptureIndex(self)
    }()
    
    var groupSort:ThreadSafeDN<[MediaItem]>?

    var groupNames:ThreadSafeDN<String>?
    
    var tagMediaItems : ThreadSafeDN<[MediaItem]>? // [String:[MediaItem]]?//sortTag:MediaItem // ictionary
    {
        didSet {

        }
    }

    var tagNames:ThreadSafeDN<String>? // [String:String]?//sortTag:tag // ictionary
    {
        didSet {

        }
    }
    
    // thread safe
    var mediaItemTags:[String]?
    {
        get {
            return tagMediaItems?.keys()?.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                if let tagName = self.tagNames?[string] {
                    return tagName
                } else {
                    return "ERROR"
                }
            })
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
        
        let groupedMediaItems = ThreadSafeDN<[MediaItem]>() // [String:[String:[MediaItem]]]() // ictionaryOfDictionaries
        
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
                if let books = mediaItem.scripture?.books {
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

            // Should be done in ThreadSafeDictionary - it is.
            // This is not needed because this is a dictionary of a dictionary of strings and it is smart enough to know
            // it needs a blank dicionary at the intermediate step.
//            if (groupNames?[grouping] == nil) {
//                groupNames?[grouping] = [String:String]()
//            }
            if let entries = entries {
                for entry in entries {
//                    groupNames?.set(grouping,entry.string,value:entry.name)
                    
                    groupNames?[grouping,entry.string] = entry.name
                    
//                    if (groupedMediaItems[grouping] == nil) {
//                        groupedMediaItems[grouping] = [String:[MediaItem]]()
//                    }
                    
                    if groupedMediaItems[grouping,entry.string] == nil {
                        groupedMediaItems[grouping,entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping,entry.string]?.append(mediaItem)
                    }
                }
            }
        }
        
        // Should be done in ThreadSafeDictionary - it is.
        // BUT when the type of the dictionary of dictionaries is also a dictionary and it is addressed at the lowest level, i.e. three keys
        // it doesn't know to fill in the missing blank dictionaries.
//        if (groupSort?[grouping] == nil) {
//            groupSort?[grouping] = [String:[String:[MediaItem]]]()
//        }
        if let keys = groupedMediaItems.keys(grouping) {
            for string in keys {
                // This is a third level of dictionary.  Is there any way to have a generic N-level dict of dicts?
//                if (groupSort?[grouping]?[string] == nil) {
//                    groupSort?[grouping]?[string] = [String:[MediaItem]]()
//                }
                let array = groupedMediaItems[grouping,string]?.sortChronologically
                    
                for sort in Constants.sortings {
                    // Without the above blank dictionary assignments this would fail.
                    // ]?[ Not any more
                    switch sort {
                    case SORTING.CHRONOLOGICAL:
                        groupSort?[grouping,string,sort] = array
                        break
                        
                    case SORTING.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping,string,sort] = array?.reversed()
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
        if let keys = groupSort?.keys(grouping)?.sorted(
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
                        if ($0.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && ($1.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return $0.withoutPrefixes < $1.withoutPrefixes
                        } else {
                            return $0.bookNumberInBible < $1.bookNumberInBible
                        }
                        
                    default:
                        return $0.lowercased() < $1.lowercased()
                    }
                    
                    return $0 < $1
            }) {
            for key in keys {
                if let mediaItems = groupSort?[grouping,key,sorting] { // ]?[
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
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Would be nice to group these
    //////////////////////////////////////////////////////////////////////////////////////////////
    lazy var section:MLGSSection? = { [weak self] in
        return MLGSSection(self) // section
    }()
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        return groupSort?.keys(grouping)?.sorted(by: {
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
                if ($0.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && ($1.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
                } else {
                    return $0.bookNumberInBible < $1.bookNumberInBible
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
            return groupNames?[grouping,string] // ]?[
        })
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        return groupSort?.keys(grouping)?.sorted(by: {
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
                if ($0.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && ($1.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
                } else {
                    return $0.bookNumberInBible < $1.bookNumberInBible
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            if let count = groupSort?[grouping,string,sorting]?.count { // ]?[
                return count
            } else {
                // ERROR
                return -1
            }
        })
    }
    
//    var sectionIndexes:[Int]?
//    {
//        get {
//            return sectionIndexes(grouping: grouping.value,sorting: sorting.value)
//        }
//    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        guard let grouping = grouping, let sorting = sorting else {
            return nil
        }
        
        var cumulative = 0
        
        return groupSort?.keys(grouping)?.sorted(by: {
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
                if ($0.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && ($1.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return $0.withoutPrefixes < $1.withoutPrefixes
                } else {
                    return $0.bookNumberInBible < $1.bookNumberInBible
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            if let count = groupSort?[grouping,string,sorting]?.count { // ]?[
                cumulative += count
            } else {
                // ???
            }
            
            return prior
        })
    }
    //////////////////////////////////////////////////////////////////////////////////////////////

    @objc func tagAdded(_ notification : NSNotification)
    {
        guard let mediaItem = notification.object as? MediaItem else {
            return
        }
        
        // For MLGS's that consist of mediaItems all having the same ephemeral tag,
        // nothing is done if the mediaItem didn't already have the tag because it isn't
        // in the list.  I.E. IT IS CORRUPT.
        //
        // HOWEVER, ALL MLGS's BASED ON TAGS ARE RECREATED AND, IF SHOWING, THE NEW ONE IS DISPLAYED IN ITS PLACE
        //
        // When the all MLGS is updated not only are its tagMediaItems and tagNames updated,
        // the tag MLGS is recreated and if it showing the new one is displayed
        //
        guard mediaList?.list?.contains(mediaItem) == true else {
            return
        }
        
        let tag = notification.userInfo?["TAG"] as? String
     
        addTagMediaItem(mediaItem:mediaItem,sortTag:tag?.withoutPrefixes,tag:tag)

        if let tag = tag, self.name == Constants.Strings.All {
            // THIS CAUSES THE VC (E.G. SI/LI) USING THE TAG MLGS TO KEEP IT BUT IF EXITED AND REENTERED THE NEW ONE IS USED!
            Globals.shared.media.tags.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes]) // nil if mediaItems are nil or count == 0

            // Any search in mediaItems w/ that tag must be removed and recalculated since the starting list of mediaItems has changed.
            if let keys = Globals.shared.media.search.searches?.keys() {
                for key in keys {
                    if key.tag == tag.uppercased() {
                        Globals.shared.media.search.searches?[key] = nil
                    }
                }
            }
            
            if (Globals.shared.media.tags.selected == tag) {
                Thread.onMain { [weak self] in 
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
                }
            }
        }
    }
    
    @objc func tagRemoved(_ notification : NSNotification)
    {
        guard let mediaItem = notification.object as? MediaItem else {
            return
        }
        
        // For MLGS's that consist of mediaItems all having the same ephemeral tag,
        // tagMediaItems and tagNames are updated but the list is not updated to
        // remove the mediaItem!  I.E. IT IS CORRUPT.
        //
        // HOWEVER, ALL MLGS's BASED ON TAGS ARE RECREATED AND, IF SHOWING, THE NEW ONE IS DISPLAYED IN ITS PLACE
        //
        // When the all MLGS is updated not only are its tagMediaItems and tagNames updated,
        // the tag MLGS is recreated and if it showing, the new one is displayed
        //
        guard mediaList?.list?.contains(mediaItem) == true else {
            return
        }
        
        let tag = notification.userInfo?["TAG"] as? String

        removeTagMediaItem(mediaItem:mediaItem,sortTag:tag?.withoutPrefixes,tag:tag)
        
        if let tag = tag, self.name == Constants.Strings.All { // , Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes] == nil
            // THIS CAUSES THE VC (E.G. SI/LI) USING THE TAG MLGS TO KEEP IT BUT IF EXITED AND REENTERED THE NEW ONE IS USED!
            Globals.shared.media.tags.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes]) // nil if mediaItems are nil or count == 0

            // Any search in mediaItems w/ that tag must be removed and recalculated since the starting list of mediaItems has changed.
            if let keys = Globals.shared.media.search.searches?.keys() {
                for key in keys {
                    if key.tag == tag.uppercased() {
                        Globals.shared.media.search.searches?[key] = nil
                    }
                }
            }
            
            if (Globals.shared.media.tags.selected == tag) {
                Thread.onMain { [weak self] in 
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
                }
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    // Uses notifications for adding and removing tags since mediaItems could be in multiple MLGS
    //////////////////////////////////////////////////////////////////////////////////////////////
    init(name:String? = nil, mediaItems:[MediaItem]?)
    {
        // It is VERY important that this NOT return nil if mediaItems is nil.
        // It should just return with an empty list.
//        guard mediaItems?.count > 0 else {
//            return nil
//        }
        
        self.name = name

        mediaList = MediaList(mediaItems)
        
        mediaList?.listDidSet = { [weak self] in
            self?.lexicon?.eligible = nil
            self?.scriptureIndex?.eligible = nil
        }

        groupNames = ThreadSafeDN<String>(name: "MediaGroupNames")
        groupSort = ThreadSafeDN<[MediaItem]>(name: "MediaGroupSort")
        
        sortGroup(grouping)

//        guard let mediaItems = mediaItems else {
//            return
//        }
        
        // Why isn't this done on demand?
        //
        // Because we use tagNames (and tagMediaItems.keys for sorting the tagNames)
        // in the tag menu
        //
        
        tagMediaItems = ThreadSafeDN<[MediaItem]>() // [String:[MediaItem]]() // ictionary
        tagNames = ThreadSafeDN<String>() // [String:String]() // ictionary

        mediaItems?.forEach { (mediaItem:MediaItem) in
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
        
        Thread.onMain { // [weak self] in
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        Globals.shared.queue.async { // [weak self] in // THIS IS LETHAL - WHY?
            NotificationCenter.default.addObserver(self, selector: #selector(self.tagAdded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TAG_ADDED), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.tagRemoved(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TAG_REMOVED), object: nil)
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    // Why is this in an MLGS rather than elsewhere? 
    //////////////////////////////////////////////////////////////////////////////////////////////
    func html(includeURLs:Bool,includeColumns:Bool,test:(()->(Bool))? = nil) -> String?
    {
        guard self.mediaList?.list != nil else {
            return nil
        }
        
        guard let grouping = grouping else {
            return nil
        }

        guard let sorting = sorting else {
            return nil
        }
        
        guard test?() != true else {
            return nil
        }
        
        var bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString += "The following media "
        
        if section?.mediaItems?.count > 1 {
            bodyString += "are"
        } else {
            bodyString += "is"
        }
        
        if includeURLs {
            bodyString += " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = category {
            bodyString += "Category: \(category)<br/>"
        }
        
        if let tag = tag {
            bodyString += "Tag: \(tag)<br/>"
        }
        
        if let searchText = search.text {
            bodyString += "Search: \(searchText)"
        }
        
        if search.transcripts == true {
            bodyString += " (including transcripts)"
        }

        bodyString += "<br/>"

        bodyString += "Grouped: By \(grouping.translate)<br/>"

        bodyString += "Sorted: \(sorting.translate)<br/>"
        
        if let keys = section?.indexStrings { // Globals.shared.media.active?.
            var count = 0
            for key in keys {
                guard test?() != true else {
                    return nil
                }
                
                if let mediaItems = groupSort?[grouping,key,sorting] { // ]?[
                    count += mediaItems.count
                }
            }
            
            bodyString += "Total: \(count)<br/>"
            
            if includeURLs, (keys.count > 1) {
                bodyString += "<br/>"
                bodyString += "<a href=\"#index\">Index</a><br/>"
            }
            
            if includeColumns {
                bodyString += "<table>"
            }
            
            for key in keys {
                guard test?() != true else {
                    return nil
                }
                
                if  let name = groupNames?[grouping,key], // ]?[
                    let mediaItems = groupSort?[grouping,key,sorting] { // ]?[
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
                        if let speaker = mediaItem.speaker {
                            if let count = speakerCounts[speaker] {
                                speakerCounts[speaker] = count + 1
                            } else {
                                speakerCounts[speaker] = 1
                            }
                        }
                    }
                    
                    let speakerCount = speakerCounts.keys.count
                    
                    let tag = key.asTag
                    
                    if includeColumns {
                        if includeURLs {
                            bodyString += "<tr><td colspan=\"7\"><br/></td></tr>"
                        } else {
                            bodyString += "<tr><td colspan=\"7\"><br/></td></tr>"
                        }
                    } else {
                        if includeURLs {
                            bodyString += "<br/>"
                        } else {
                            bodyString += "<br/>"
                        }
                    }
                    
                    if includeColumns {
                        bodyString += "<tr>"
                        bodyString += "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                    }
                    
                    if includeURLs, (keys.count > 1) {
                        bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + "</a>" //  + " (\(mediaItems.count))"
                    } else {
                        bodyString += name // + " (\(mediaItems.count))"
                    }
                    
                    if speakerCount == 1 {
                        if var speaker = mediaItems[0].speaker, name != speaker {
                            if let speakerTitle = mediaItems[0].speakerTitle {
                                speaker += ", \(speakerTitle)"
                            }
                            bodyString += " by " + speaker
                        }
                    }
                    
                    if mediaItems.count > 1 {
                        bodyString += " (\(mediaItems.count))"
                    }
                    
                    if includeColumns {
                        bodyString += "</td>"
                        bodyString += "</tr>"
                    } else {
                        bodyString += "<br/>"
                    }
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
                        var order = ["date","title","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        if grouping != GROUPING.CLASS { // Globals.shared.
                            if mediaItem.hasClassName {
                                order.append("class")
                            }
                        }
                        
                        if grouping != GROUPING.EVENT { // Globals.shared.
                            if mediaItem.hasEventName {
                                order.append("event")
                            }
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString += string
                        }
                        
                        if !includeColumns {
                            bodyString += "<br/>"
                        }
                    }
                }
            }
            
            if includeColumns {
                bodyString += "</table>"
            }
            
            bodyString += "<br/>"
            
            if includeURLs, keys.count > 1 {
                bodyString += "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
                
                switch grouping {
                case GROUPING.CLASS:
                    fallthrough
                case GROUPING.SPEAKER:
                    fallthrough
                case GROUPING.TITLE:
                    let a = "A"
                    
                    if let indexTitles = section?.indexStrings {
                        let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                            if string.count >= a.count { // endIndex
                                return String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
                            } else {
                                return string
                            }
                        }))).sorted() { $0 < $1 }
                        
                        var stringIndex = [String:[String]]()
                        
                        if let indexStrings = section?.indexStrings {
                            for indexString in indexStrings {
                                guard test?() != true else {
                                    return nil
                                }
                                
                                let key = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)]).uppercased()
                                
                                if stringIndex[key] == nil {
                                    stringIndex[key] = [String]()
                                }
                                
                                stringIndex[key]?.append(indexString)
                            }
                        }
                        
                        var index:String?
                        
                        for title in titles {
                            let link = "<a href=\"#\(title)\">\(title)</a>"
                            index = ((index != nil) ? index! + " " : "") + link
                        }
                        
                        bodyString += "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                        
                        if let index = index {
                            bodyString += index + "<br/>"
                        }
                        
                        for title in titles {
                            guard test?() != true else {
                                return nil
                            }
                            
                            bodyString += "<br/>"
                            if let count = stringIndex[title]?.count { // Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count
                                bodyString += "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a> (\(count))<br/>"
                            } else {
                                bodyString += "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                            }
                            
                            if let keys = stringIndex[title] {
                                for key in keys {
                                    if let title = groupNames?[grouping,key] { // ]?[
                                        let tag = key.asTag
                                        bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a><br/>" // (\(count))
                                    }
                                }
                            }
                            
                            bodyString += "</div>"
                        }
                        
                        bodyString += "</div>"
                    }
                    break
                    
                default:
                    for key in keys {
                        if let title = groupNames?[grouping,key], // ]?[
                            let count = groupSort?[grouping,key,sorting]?.count { // ]?[
                            let tag = key.asTag
                            bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a> (\(count))<br/>"
                        }
                    }
                    break
                }
                
                bodyString += "</div>"
            }
        }
        
        bodyString += "</body></html>"
        
        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
    }
}

