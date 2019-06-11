//
//  ScriptureIndex.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

/**
 Scripture Index to all the mediaItems in an MLGS.
 */

class ScriptureIndex
{
    var callBacks = CallBacks()
    
    var building : Bool
    {
        get {
            return operationQueue.operationCount > 0
        }
    }
    var completed = false
    
    private weak var mediaListGroupSort:MediaListGroupSort?
    
    init(_ mediaListGroupSort:MediaListGroupSort?)
    {
        self.mediaListGroupSort = mediaListGroupSort
    }
    
    // Make thread safe?
    var sectionsIndex = [String:[String:[MediaItem]]]()
    
    // Make thread safe?
    var sections:[String:[MediaItem]]?
    {
        get {
            guard let context = context else {
                return nil
            }
            
            return sectionsIndex[context]
        }
        set {
            guard let context = context else {
                return
            }
            
            sectionsIndex[context] = newValue
        }
    }
    
    var sectionTitles : [String]?
    {
        get {
            return sections?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
        }
    }
    
    lazy var html:CachedString? = { [weak self] in // unowned self MIGHT BE needed because we are capturing self in a function that is used by the object owned by self.
        return CachedString(index: {
            return self?.context
        })
    }()
    
    var context:String?
    {
        get {
            var index:String?
            
            if let selectedTestament = scripture.picked.testament {
                index = selectedTestament
            }
            
            if index != nil, let selectedBook = scripture.picked.book {
                index = index! + ":" + selectedBook
            }
            
            if index != nil, scripture.picked.chapter > 0 {
                index = index! + ":\(scripture.picked.chapter)"
            }
            
            if index != nil, scripture.picked.verse > 0 {
                index = index! + ":\(scripture.picked.verse)"
            }
            
            return index
        }
    }
    
    // The mediaItems in a ScriptureIndex do not change during its life
    // But in a SIVC we need to keep track of whether the by*'s below
    // are sorted properly so we don't have sort to be sure each time
    // the user changes the testament, book, chapter, (or someday verse) controls
    //
    // They are here instead of in the SIVC so we can reuse them if the
    // user enters a SIVC for this SI again.
    
    // Make thread safe?
    var isSorted = [String:Bool]()
    
    //////////////////////////////////////////////////////////////
    // Must make thread safe before incrementally updating SIVC
    //////////////////////////////////////////////////////////////

    //Test
    var byTestament = [String:[MediaItem]]()
    
    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()
    //////////////////////////////////////////////////////////////

    lazy var scripture:Scripture! = { [weak self] in
        return Scripture(reference: nil)
    }()
    
    // Replace with Fetch?
    var startingUp = true
    private var _eligible:[MediaItem]?
    {
        didSet {
            if _eligible == nil, startingUp || (oldValue != nil) {
                startingUp = false
                
                // Force a recalculation if newValue is nil and oldValue is not nil
                // This characteristic is used by MLGS (that contains a Lexicon and a ScriptureIndex)
                // Such that when the MLGS.mediaList.list is set these are calculated.
                _ = eligible
            }
        }
    }
    var eligible:[MediaItem]?
    {
        get {
            guard _eligible == nil else {
                return _eligible
            }
            
            if let list = mediaListGroupSort?.mediaList?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.scripture?.books != nil
            }), list.count > 0 {
                _eligible = list
            } else {
                _eligible = nil
            }
            
            return _eligible
        }
        set {
            _eligible = newValue
        }
    }
    
    var mediaItems:[MediaItem]?
    {
        willSet {
            
        }
        didSet {
            guard self.sections == nil else {
                return
            }
            
            var sections = [String:[MediaItem]]()
            
            if let mediaItems = mediaItems {
                for mediaItem in mediaItems {
                    if let books = mediaItem.scripture?.books {
                        for book in books {
                            if let selectedTestament = scripture.picked.testament {
                                if selectedTestament.translateTestament == book.testament {
                                    if sections[book] == nil {
                                        sections[book] = [mediaItem]
                                    } else {
                                        sections[book]?.append(mediaItem)
                                    }
                                } else {
                                    // THIS SHOULD NEVER HAPPEN
                                }
                            }
                        }
                    }
                }
            }
            
            for book in sections.keys {
                sections[book] = sections[book]?.sort(book:book)
            }
            
            self.sections = sections
        }
    }

    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "ScriptureIndex" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    func build()
    {
        guard !completed else {
            callBacks.execute("complete")
            return
        }
        
        guard !building else {
            return
        }
        
//        let op = CancelableOperation { [weak self] (test:(() -> (Bool))?) in
        operationQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            if let mediaList = self?.mediaListGroupSort?.mediaList?.list {
                self?.callBacks.execute("start")

                for mediaItem in mediaList {
                    if Globals.shared.isRefreshing || Globals.shared.isLoading {
                        break
                    }
                    
                    if let test = test, test() {
                        break
                    }
                    
                    let booksChaptersVerses = mediaItem.scripture?.booksChaptersVerses
                    if let books = booksChaptersVerses?.books {
                        for book in books {
                            if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                break
                            }
                            
                            if let test = test, test() {
                                break
                            }
                            
                            if let contains = self?.byTestament[book.testament]?.contains(mediaItem) {
                                if !contains {
                                    self?.byTestament[book.testament]?.append(mediaItem)
                                }
                            } else {
                                self?.byTestament[book.testament] = [mediaItem]
                            }
                            
                            // Can't we build these later?
                            if self?.byBook[book.testament] == nil {
                                self?.byBook[book.testament] = [String:[MediaItem]]()
                            }
                            if let contains = self?.byBook[book.testament]?[book]?.contains(mediaItem) {
                                if !contains {
                                    self?.byBook[book.testament]?[book]?.append(mediaItem)
                                }
                            } else {
                                self?.byBook[book.testament]?[book] = [mediaItem]
                            }
                            
                            // Can't we build these later?
                            if let chapters = booksChaptersVerses?[book]?.keys {
                                for chapter in chapters {
                                    if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                        break
                                    }
                                    
                                    if let test = test, test() {
                                        break
                                    }
                                    
                                    if self?.byChapter[book.testament] == nil {
                                        self?.byChapter[book.testament] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self?.byChapter[book.testament]?[book] == nil {
                                        self?.byChapter[book.testament]?[book] = [Int:[MediaItem]]()
                                    }
                                    if let contains = self?.byChapter[book.testament]?[book]?[chapter]?.contains(mediaItem) {
                                        if !contains {
                                            self?.byChapter[book.testament]?[book]?[chapter]?.append(mediaItem)
                                        }
                                    } else {
                                        self?.byChapter[book.testament]?[book]?[chapter] = [mediaItem]
                                    }
                                    
                                    if let verses = booksChaptersVerses?[book]?[chapter] {
                                        for verse in verses {
                                            if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                                break
                                            }
                                            
                                            if let test = test, test() {
                                                break
                                            }
                                            
                                            if self?.byVerse[book.testament] == nil {
                                                self?.byVerse[book.testament] = [String:[Int:[Int:[MediaItem]]]]()
                                            }
                                            if self?.byVerse[book.testament]?[book] == nil {
                                                self?.byVerse[book.testament]?[book] = [Int:[Int:[MediaItem]]]()
                                            }
                                            if self?.byVerse[book.testament]?[book]?[chapter] == nil {
                                                self?.byVerse[book.testament]?[book]?[chapter] = [Int:[MediaItem]]()
                                            }
                                            if let contains = self?.byVerse[book.testament]?[book]?[chapter]?[verse]?.contains(mediaItem) {
                                                if !contains {
                                                    self?.byVerse[book.testament]?[book]?[chapter]?[verse]?.append(mediaItem)
                                                }
                                            } else {
                                                self?.byVerse[book.testament]?[book]?[chapter]?[verse] = [mediaItem]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    self?.callBacks.execute("update")
                }
            }
            
            self?.completed = true
            
            if let selectedTestament = self?.scripture.picked.testament {
                let testament = selectedTestament.translateTestament
                
                switch selectedTestament {
                case Constants.OT:
                    if (self?.byTestament[testament] == nil) {
                        self?.scripture.picked.testament = Constants.NT
                    }
                    break
                    
                case Constants.NT:
                    if (self?.byTestament[testament] == nil) {
                        self?.scripture.picked.testament = Constants.OT
                    }
                    break
                    
                default:
                    break
                }
            }
            
            self?.callBacks.execute("complete")
        }
        
//        operationQueue.addOperation(op)
    }

    func html(includeURLs:Bool, includeColumns:Bool, test:(()->(Bool))? = nil) -> String?
    {
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        guard test?() != true else {
            return nil
        }
        
        var bodyItems = [String:[MediaItem]]()
        
        for mediaItem in mediaItems {
            guard test?() != true else {
                return nil
            }
            
            if let books = mediaItem.scripture?.books {
                for book in books {
                    guard test?() != true else {
                        return nil
                    }
                    
                    if let okay = sectionTitles?.contains(book) {
                        if okay {
                            if bodyItems[book] == nil {
                                bodyItems[book] = [mediaItem]
                            } else {
                                bodyItems[book]?.append(mediaItem)
                            }
                        }
                    }
                }
            }
        }
        
        var bodyString:String!
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString += "<div>"
        
        bodyString += "The following media "
        
        if mediaItems.count > 1 {
            bodyString += "are"
        } else {
            bodyString += "is"
        }
        
        if includeURLs {
            bodyString += " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = mediaListGroupSort?.category.value {
            bodyString += "Category: \(category)<br/>"
        }
        
        if let tag = mediaListGroupSort?.tag.value {
            bodyString += "Tag: \(tag)<br/>"
        }
        
        if let text = mediaListGroupSort?.search.value?.text {
            bodyString += "Search: \(text)"
        }
        
        if mediaListGroupSort?.search.value?.transcripts.value == true {
            bodyString += " (including transcripts)"
        }
        
        bodyString += "<br/><br/>"
        
        bodyString += "</div>"
        
        if let selectedTestament = scripture?.picked.testament {
            var indexFor = selectedTestament.translateTestament
            
            if let selectedBook = scripture?.picked.book {
                indexFor = selectedBook
                
                if let chapter = scripture?.picked.chapter, chapter > 0 {
                    indexFor = indexFor + " \(chapter)"
                    
                    if let verse = scripture?.picked.verse, verse > 0 {
                        indexFor = indexFor + ":\(verse)"
                    }
                }
            }
            
            bodyString += "\(indexFor) Scripture Index<br/>"
        }
        
        bodyString += "Items are grouped and sorted by Scripture reference.<br/>"
        
        bodyString += "Total: \(mediaItems.count)<br/>"
        
        let books = bodyItems.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
        
        if includeURLs, (books.count > 1) {
            bodyString += "<br/>"
            bodyString += "<a href=\"#index\">Index</a><br/>"
        }
        
        if includeColumns {
            bodyString  = bodyString + "<table>"
        }
        
        for book in books {
            guard test?() != true else {
                return nil
            }
            
            let tag = book.asTag
            
            if includeColumns {
                bodyString += "<tr><td><br/></td></tr>"
                bodyString += "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
            }
            
            if let mediaItems = bodyItems[book] {
                if includeURLs && (books.count > 1) {
                    bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + book + "</a>" //  + " (\(mediaItems.count))"
                } else {
                    bodyString += book
                }
                
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
                    guard test?() != true else {
                        return nil
                    }
                    
                    if let speaker = mediaItem.speaker {
                        guard let count = speakerCounts[speaker] else {
                            speakerCounts[speaker] = 1
                            continue
                        }
                        
                        speakerCounts[speaker] = count + 1
                    }
                }
                
                let speakerCount = speakerCounts.keys.count
                
                let speakers = Array(speakerCounts.keys)
                
                if speakerCount == 1{
                    bodyString += " by \(speakers[0])"
                }
                
                if mediaItems.count > 1 {
                    bodyString += " (\(mediaItems.count))"
                }
                
                if includeColumns {
                    bodyString  = bodyString + "</td>"
                    bodyString  = bodyString + "</tr>"
                } else {
                    bodyString += "<br/>"
                }
                
                for mediaItem in mediaItems {
                    guard test?() != true else {
                        return nil
                    }
                    
                    var order = ["scripture","title","date"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
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
            bodyString  = bodyString + "</table>"
        }
        
        bodyString += "<br/>"
        
        if includeURLs, (books.count > 1) {
            bodyString += "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
            
            for book in books {
                guard test?() != true else {
                    return nil
                }
                
                if let count = bodyItems[book]?.count {
                    bodyString += "<a href=\"#\(book.asTag)\">\(book)</a> (\(count))<br/>"
                }
            }
            
            bodyString += "</div>"
        }
        
        bodyString += "</body></html>"
        
        return bodyString.insertHead(fontSize:Constants.FONT_SIZE)
    }
}

