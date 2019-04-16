//
//  ScriptureIndex.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class ScriptureIndex
{
    var callBacks = CallBacks()
    
//    var start : (()->())?
//    var update : (()->())?
//    var complete : (()->())?
    
    var creating : Bool // = false
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
    
//    var index : String?
//    {
//        get {
//            return context
//        }
//    }
    
    var context:String?
    {
        get {
            var index:String?
            
            if let selectedTestament = scripture.selected.testament {
                index = selectedTestament
            }
            
            if index != nil, let selectedBook = scripture.selected.book {
                index = index! + ":" + selectedBook
            }
            
            if index != nil, scripture.selected.chapter > 0 {
                index = index! + ":\(scripture.selected.chapter)"
            }
            
            if index != nil, scripture.selected.verse > 0 {
                index = index! + ":\(scripture.selected.verse)"
            }
            
            return index
        }
    }
    
    // Make thread safe?
    var sorted = [String:Bool]()
    
    // Make thread safe?

    //Test
    var byTestament = [String:[MediaItem]]()
    
    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()
    
    lazy var scripture:Scripture! = { [weak self] in
        return Scripture(reference: nil)
    }()
//    var selected = Selected()

//    var selectedTestament:String? = Constants.OT
//    
//    var selectedBook:String?
//    {
//        willSet {
//            
//        }
//        didSet {
//            if selectedBook == nil {
//                selectedChapter = 0
//                selectedVerse = 0
//            }
//        }
//    }
//    
//    var selectedChapter:Int = 0
//    {
//        willSet {
//            
//        }
//        didSet {
//            if selectedChapter == 0 {
//                selectedVerse = 0
//            }
//        }
//    }
//    
//    var selectedVerse:Int = 0

//    lazy var eligible:Shadowed<[MediaItem]> = { [weak self] in
//        return Shadowed<[MediaItem]>(get: { () -> ([MediaItem]?) in
//            if let list = self.mediaListGroupSort?.mediaList?.list?.filter({ (mediaItem:MediaItem) -> Bool in
//                return mediaItem.books != nil
//            }), list.count > 0 {
//                return list
//            } else {
//                return nil
//            }
//        })
//    }()
    
    // Replace with Fetch?
    var startingUp = true
    private var _eligible:[MediaItem]?
    {
        didSet {
            if _eligible == nil, startingUp || (oldValue != nil) { // , oldValue != nil
                startingUp = false
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
                            if let selectedTestament = scripture.selected.testament {
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
        operationQueue.cancelAllOperations()
    }
    
    func build()
    {
        guard !completed else {
            callBacks.complete()
//            Globals.shared.queue.async {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
//            }
            return
        }
        
        guard !creating else {
            return
        }
        
//        let start = Date().timeIntervalSince1970

//        DispatchQueue.global(qos: .userInitiated).async{  [weak self] in
//        operationQueue.addOperation {  [weak self] in
        let op = CancelableOperation { [weak self] (test:(() -> (Bool))?) in
//            self?.creating = true
            
            if let mediaList = self?.mediaListGroupSort?.mediaList?.list {
                self?.callBacks.start()
//                Globals.shared.queue.async {
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self)
//                }
                
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
                    
                    self?.callBacks.update()
                }
            }
            
//            self?.creating = false
            self?.completed = true
            
            if let selectedTestament = self?.scripture.selected.testament {
                let testament = selectedTestament.translateTestament
                
                switch selectedTestament {
                case Constants.OT:
                    if (self?.byTestament[testament] == nil) {
                        self?.scripture.selected.testament = Constants.NT
                    }
                    break
                    
                case Constants.NT:
                    if (self?.byTestament[testament] == nil) {
                        self?.scripture.selected.testament = Constants.OT
                    }
                    break
                    
                default:
                    break
                }
            }
            
            self?.callBacks.complete()
//            Globals.shared.queue.async {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
//            }
            
//            let end = Date().timeIntervalSince1970
//
//            print(end - start)
        }
        
        operationQueue.addOperation(op)
    }

    func html(includeURLs:Bool, includeColumns:Bool) -> String?
    {
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        var bodyItems = [String:[MediaItem]]()
        
        for mediaItem in mediaItems {
            if let books = mediaItem.scripture?.books {
                for book in books {
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
        
        bodyString = bodyString + "<div>"
        
        bodyString = bodyString + "The following media "
        
        if mediaItems.count > 1 {
            bodyString = bodyString + "are"
        } else {
            bodyString = bodyString + "is"
        }
        
        if includeURLs {
            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = mediaListGroupSort?.category.value {
            bodyString = bodyString + "Category: \(category)<br/><br/>"
        }
        
        if let tag = mediaListGroupSort?.tagSelected.value {
            bodyString = bodyString + "Collection: \(tag)<br/><br/>"
        }
        
        if let text = mediaListGroupSort?.search.value?.text {
            bodyString = bodyString + "Search: \(text)<br/><br/>"
        }
        
        bodyString = bodyString + "</div>"
        
        if let selectedTestament = scripture?.selected.testament {
            var indexFor = selectedTestament.translateTestament
            
            if let selectedBook = scripture?.selected.book {
                indexFor = selectedBook
                
                if let chapter = scripture?.selected.chapter, chapter > 0 {
                    indexFor = indexFor + " \(chapter)"
                    
                    if let verse = scripture?.selected.verse, verse > 0 {
                        indexFor = indexFor + ":\(verse)"
                    }
                }
            }
            
            bodyString = bodyString + "\(indexFor) Scripture Index<br/>"
        }
        
        bodyString = bodyString + "Items are grouped and sorted by Scripture reference.<br/>"
        
        bodyString = bodyString + "Total: \(mediaItems.count)<br/>"
        
        let books = bodyItems.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString + "<br/>"
            bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
        }
        
        if includeColumns {
            bodyString  = bodyString + "<table>"
        }
        
        for book in books {
            let tag = book.asTag
            
            if includeColumns {
                bodyString  = bodyString + "<tr><td><br/></td></tr>"
                bodyString  = bodyString + "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
            }
            
            if let mediaItems = bodyItems[book] {
                if includeURLs && (books.count > 1) {
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + book + " (\(mediaItems.count))" + "</a>"
                } else {
                    bodyString = bodyString + book
                }
                
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
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
                    bodyString = bodyString + " by \(speakers[0])"
                }
                
                if includeColumns {
                    bodyString  = bodyString + "</td>"
                    bodyString  = bodyString + "</tr>"
                } else {
                    bodyString = bodyString + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["scripture","title","date"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString + "<br/>"
                    }
                }
            }
        }
        
        if includeColumns {
            bodyString  = bodyString + "</table>"
        }
        
        bodyString = bodyString + "<br/>"
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
            
            for book in books {
                if let count = bodyItems[book]?.count {
                    bodyString = bodyString + "<a href=\"#\(book.asTag)\">\(book) (\(count))</a><br/>"
                }
            }
            
            bodyString = bodyString + "</div>"
        }
        
        bodyString = bodyString + "</body></html>"
        
        return bodyString.insertHead(fontSize:Constants.FONT_SIZE)
    }
}

