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
        return CachedString(index:self?.index)
    }()
    
    func index() -> String?
    {
        return context
    }
    
    var context:String?
    {
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
    
    var selectedTestament:String? = Constants.OT
    
    var selectedBook:String?
    {
        willSet {
            
        }
        didSet {
            if selectedBook == nil {
                selectedChapter = 0
                selectedVerse = 0
            }
        }
    }
    
    var selectedChapter:Int = 0 {
        willSet {
            
        }
        didSet {
            if selectedChapter == 0 {
                selectedVerse = 0
            }
        }
    }
    
    var selectedVerse:Int = 0

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
                return mediaItem.books != nil
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
            Globals.shared.queue.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            }
            return
        }
        
        guard !creating else {
            return
        }
        
        let start = Date().timeIntervalSince1970

//        DispatchQueue.global(qos: .userInitiated).async{  [weak self] in
//        operationQueue.addOperation {  [weak self] in
        let op = CancellableOperation { [weak self] (test:(() -> (Bool))?) in
//            self?.creating = true
            
            if let mediaList = self?.mediaListGroupSort?.mediaList?.list {
                Globals.shared.queue.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self)
                }
                
                for mediaItem in mediaList {
                    if Globals.shared.isRefreshing || Globals.shared.isLoading {
                        break
                    }
                    
                    if let test = test, test() {
                        break
                    }
                    
                    let booksChaptersVerses = mediaItem.booksAndChaptersAndVerses()
                    if let books = booksChaptersVerses?.data?.keys {
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
                }
            }
            
//            self?.creating = false
            self?.completed = true
            
            if let selectedTestament = self?.selectedTestament {
                let testament = selectedTestament.translateTestament
                
                switch selectedTestament {
                case Constants.OT:
                    if (self?.byTestament[testament] == nil) {
                        self?.selectedTestament = Constants.NT
                    }
                    break
                    
                case Constants.NT:
                    if (self?.byTestament[testament] == nil) {
                        self?.selectedTestament = Constants.OT
                    }
                    break
                    
                default:
                    break
                }
            }
            
            Globals.shared.queue.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            }
            
            let end = Date().timeIntervalSince1970
            
            print(end - start)
        }
        
        operationQueue.addOperation(op)
    }
}

