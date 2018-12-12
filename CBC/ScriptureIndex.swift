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
            return sections?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
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
        
//        DispatchQueue.global(qos: .userInitiated).async{  [weak self] in
        operationQueue.addOperation {  [weak self] in
//            self?.creating = true
            
            if let mediaList = self?.mediaListGroupSort?.mediaList?.list {
                Globals.shared.queue.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self)
                }
                
                for mediaItem in mediaList {
                    if Globals.shared.isRefreshing || Globals.shared.isLoading {
                        break
                    }
                    
                    let booksChaptersVerses = mediaItem.booksAndChaptersAndVerses()
                    if let books = booksChaptersVerses?.data?.keys {
                        for book in books {
                            if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                break
                            }
                            
                            if let contains = self?.byTestament[testament(book)]?.contains(mediaItem) {
                                if !contains {
                                    self?.byTestament[testament(book)]?.append(mediaItem)
                                }
                            } else {
                                self?.byTestament[testament(book)] = [mediaItem]
                            }
                            
                            if self?.byBook[testament(book)] == nil {
                                self?.byBook[testament(book)] = [String:[MediaItem]]()
                            }
                            if let contains = self?.byBook[testament(book)]?[book]?.contains(mediaItem) {
                                if !contains {
                                    self?.byBook[testament(book)]?[book]?.append(mediaItem)
                                }
                            } else {
                                self?.byBook[testament(book)]?[book] = [mediaItem]
                            }
                            
                            if let chapters = booksChaptersVerses?[book]?.keys {
                                for chapter in chapters {
                                    if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                        break
                                    }
                                    
                                    if self?.byChapter[testament(book)] == nil {
                                        self?.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self?.byChapter[testament(book)]?[book] == nil {
                                        self?.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
                                    }
                                    if let contains = self?.byChapter[testament(book)]?[book]?[chapter]?.contains(mediaItem) {
                                        if !contains {
                                            self?.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
                                        }
                                    } else {
                                        self?.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
                                    }
                                    
                                    if let verses = booksChaptersVerses?[book]?[chapter] {
                                        for verse in verses {
                                            if Globals.shared.isRefreshing || Globals.shared.isLoading {
                                                break
                                            }
                                            
                                            if self?.byVerse[testament(book)] == nil {
                                                self?.byVerse[testament(book)] = [String:[Int:[Int:[MediaItem]]]]()
                                            }
                                            if self?.byVerse[testament(book)]?[book] == nil {
                                                self?.byVerse[testament(book)]?[book] = [Int:[Int:[MediaItem]]]()
                                            }
                                            if self?.byVerse[testament(book)]?[book]?[chapter] == nil {
                                                self?.byVerse[testament(book)]?[book]?[chapter] = [Int:[MediaItem]]()
                                            }
                                            if let contains = self?.byVerse[testament(book)]?[book]?[chapter]?[verse]?.contains(mediaItem) {
                                                if !contains {
                                                    self?.byVerse[testament(book)]?[book]?[chapter]?[verse]?.append(mediaItem)
                                                }
                                            } else {
                                                self?.byVerse[testament(book)]?[book]?[chapter]?[verse] = [mediaItem]
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
                let testament = translateTestament(selectedTestament)
                
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
        }
    }
}

