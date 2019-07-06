//
//  Lexicon.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

/**

 The lexicon of the words in some set of documents (e.g. HTML transcripts) in a containing MLGS
 
 Is assumed to be built incrementally and uses callbacks to update an view controllers, e.g. LIVC's, that
 present it.
 
 */

class Lexicon : NSObject // Why an NSObject?
{
    private weak var mediaListGroupSort:MediaListGroupSort?
    
    @objc func freeMemory()
    {
        words = nil
        eligible = nil
        stringTrees = [String:StringTree]()
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // THIS IS ALL DRIVEN BY THE DESIRE TO RETAIN STRINGTREE'S PARTIAL OR COMPLETE BETWEEN LIVC'S
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // The stringTree is a function of the activeWords, i.e. the search results (or all if no search), in
    // the PTVC embedded in the LIVC that is showing this Lexicon.
    private var stringTrees = [String:StringTree]()
    func stringTree(_ searchText:String?) -> StringTree?
    {
        // The problem with this is that activeWordsString is NOT the same at all points in time if
        // the lexicon is being built!  Meaning, the stringTree handed back will change or be new depending
        // upon when you ask for it!
        //
        // The only time this returns the same thing is AFTER the lexicon is completed.
//        guard let activeWordsString = activeWords(searchText:searchText)?.sorted().joined() else {
//            return nil
//        }
        
        if stringTrees[searchText ?? ""] == nil {
            stringTrees[searchText ?? ""] = StringTree(stringsFunction: { [weak self] in
                                                            return self?.stringsFunction?()
                                                        }, incremental:true)
        }
        
        return stringTrees[searchText ?? ""]
    }
    
    // This is required because the searchText that defines the active words is contained in the PTVC embedded
    // in the LIVC that is showing this, so this must be set, weakly, in the LIVC to reference the embedded PTVC.
    var stringTreeFunction:(()->StringTree?)?
    {
        didSet {
            
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
//    private var incremental = false // FUTURE USE meaning Lexicons may NOT be incremenal some day?  Because right now they are!

    var callBacks = CallBacks()
    
    var selected:String?
    
    init(_ mediaListGroupSort:MediaListGroupSort?)
    {
        super.init()

        self.mediaListGroupSort = mediaListGroupSort
        
        Thread.onMain { [weak self] in 
            NotificationCenter.default.addObserver(self, selector: #selector(self?.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var tokens:[String]?
    {
        get {
            return words?.keys()?.sorted()
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // These are not used and I'm not sure what they are good for or why they were created.
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Greatest common words, meaning words that appear in themself and the greatest number of other words.
    // This exploits the fact that tokens is sorted alphabetically which means that the following
    // string(s) will contain the prior string if any do, and they will do so sequentially and when
    // the sequence stops it will never restart.
    //
    // The array returned is of words that are contained at least twice, once in itself and at least once
    // in another word.  Any word that contains a prior word will not appear in the results.
    var gcw:[String]?
    {
        get {
            var words = [String:Int]()
            
            if let tokens = tokens {
                if var currentToken = tokens.first {
                    for token in tokens {
                        if let range = token.range(of: currentToken), range.lowerBound == token.startIndex {
                            if (token != tokens.first) {
                                if let count = words[currentToken] {
                                    words[currentToken] = count + 1
                                } else {
                                    words[currentToken] = 2 // Itself plus at least one to get here.
                                }
                            }
                        } else {
                            currentToken = token
                        }
                    }
                }
            }
            
            return words.count > 0 ? words.keys.sorted() : nil
        }
    }
    
    // Greatest, meaning LONGEST, common roots
    //
    var gcr:[String]?
    {
        get {
            guard let tokens = tokens else {
                return nil
            }
            
            var roots = [String:Int]()
            
            // Look for all possible roots
            for token in tokens {
                var string = String()
                
                for character in token {
                    string.append(character)
                    
                    if let count = roots[string] {
                        roots[string] = count + 1
                    } else {
                        roots[string] = 1
                    }
                }
            }

            // Only take roots that are in at least 2 words
            let candidates = roots.keys.filter({ (root:String) -> Bool in
                if let count = roots[root] {
                    return count > 1
                } else {
                    return false
                }
            }).sorted()

            // Then weed out any that appear within another, e.g. if FR and FRO both have >1 then only keep FRO.
            var finalRoots = candidates
            
            if var currentCandidate = candidates.first {
                for candidate in candidates {
                    if candidate != candidates.first {
                        if currentCandidate.endIndex <= candidate.endIndex {
                            if String(candidate[..<currentCandidate.endIndex]) == currentCandidate {
                                if let index = finalRoots.firstIndex(of: currentCandidate) {
                                    finalRoots.remove(at: index)
                                }
                            }
                        }
                        
                        currentCandidate = candidate
                    }
                }
            }
            
            return finalRoots.count > 0 ? finalRoots : nil
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    var words:ThreadSafeDN<[MediaItem:Int]>?
    {
        willSet {

        }
        didSet {

        }
    }
    
    var building:Bool
    {
        get {
            return operationQueue.operationCount > 0
        }
    }

    var pauseUpdates = false
    var completed = false
    
    var entries:[MediaItem]?
    {
        get {
            let entries = words?.values()?.flatMap({ (dict:[MediaItem : Int]) -> [MediaItem] in
                return Set(dict.keys).array
            }).set.array
            
            return entries
        }
    }

    // Replace with Fetch?
    var startingUp = true
    private var _eligible:[MediaItem]?
    {
        didSet {
            if _eligible == nil, startingUp || (oldValue != nil)  {
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
                return mediaItem.hasNotesText
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

    func documents(_ word:String?) -> Int? // nil => not found
    {
        guard let word = word else {
            return nil
        }
        
        return words?[word]?.count
    }
    
    func occurrences(_ word:String?) -> Int? // nil => not found
    {
        guard let word = word else {
            return nil
        }
        
        return words?[word]?.values.reduce(0, +)
    }
    
    var stringsFunction:(()->[String]?)?
    {
        didSet {
            
        }
    }
    
    // thread safe?
    var strings : [String]?
    {
        get {
            // What happens if build() inserts a new key while this is happening?
            // Nothing words is thread safe
            return words?.keys()?.sorted()
        }
    }
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Lexicon" + UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    func stop()
    {
        operationQueue.cancelAllOperations()
    }
    
    var halt : Bool
    {
        get {
            return Globals.shared.isRefreshing || Globals.shared.isLoading
        }
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
        
//        let op = CancelableOperation { [weak self] (test:(()->Bool)?) in
        operationQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            if let test = test, test() {
                return
            }
            
            if self?.halt == true {
                return
            }

            var firstUpdate = true
            
            guard var list = self?.eligible else {
                print("NIL ELIGIBLE MEDIALIST FOR LEXICON INDEX")
                return
            }
            
            if self?.words == nil {
                self?.words = ThreadSafeDN<[MediaItem:Int]>(name: UUID().uuidString + Constants.Strings.Words)
            }
            
            var date = Date()
            
            self?.callBacks.execute("start")
            
            repeat {
                guard let mediaItem = list.first else { // One chance to load tokens per media item
                    break
                }
                
                if let test = test, test() {
                    return
                }
                
                if self?.halt == true {
                    return
                }

                // Made an ORDER OF MAGNITUDE difference in memory usage!
                autoreleasepool {
                    if let notesTokens = mediaItem.notesTokens?.result {
                        // Try indefinitely to load all media items
                        list.removeFirst()
                        
                        for token in notesTokens {
                            if self?.words?[token.key] == nil {
                                self?.words?[token.key] = [mediaItem:token.value]
                            } else {
                                self?.words?[token.key]?[mediaItem] = token.value
                            }

                            if let test = test, test() {
                                return
                            }

                            if self?.halt == true {
                                return
                            }
                        }
                    } else {
                        print("NO NOTES TOKENS!")
                    }
                }

                if let test = test, test() {
                    return
                }

                if self?.halt == true {
                    return
                }
                
                if firstUpdate || (date.timeIntervalSinceNow <= -5) {
                    self?.callBacks.execute("update")

                    date = Date()

                    firstUpdate = false
                }
                
                if let test = test, test() {
                    return
                }
                
                if self?.halt == true {
                    return
                }
            } while list.count > 0
            
            if let test = test, test() {
                return
            }
            
            if self?.halt == true {
                return
            }

            if !Globals.shared.isRefreshing && !Globals.shared.isLoading {
                self?.completed = true
            }

            self?.callBacks.execute("complete")
        }
//        operationQueue.addOperation(op)
    }
    
    func load()
    {
        guard (words == nil) else {
            return
        }
        
        let dict = ThreadSafeDN<[MediaItem:Int]>(name: UUID().uuidString + Constants.Strings.Words)
        
        if let list = eligible {
            for mediaItem in list {
                if let notesTokens = mediaItem.notesTokens?.result {
                    for token in notesTokens {
                        if dict[token.key] == nil {
                            dict[token.key] = [mediaItem:token.value]
                        } else {
                            dict[token.key]?[mediaItem] = token.value
                        }
                    }
                }
            }
        }
        
        words = dict.count > 0 ? dict : nil
    }
    
    var statistics : String
    {
        get {
            var string = String()
            
            if let keys = words?.keys()?.sorted(), let values = words?.values() {
                var mediaItems = 0
                
                var minMediaItems:Int?
                var maxMediaItems:Int?
                
                for value in values {
                    mediaItems += value.keys.count
                    
                    minMediaItems = min(minMediaItems ?? value.keys.count,value.keys.count)
                    maxMediaItems = max(maxMediaItems ?? value.keys.count,value.keys.count)
                }
                
                string += "Number of (Media item, frequency) pairs: \(mediaItems)\n"
                string += "Average number of media items per unique word: \(Double(mediaItems) / Double(keys.count))"
                string += "Minimum number of media items for a unique word: \(minMediaItems ?? 0)"
                string += "Maximum number of media items for a unique word: \(maxMediaItems ?? 0)"
            }
            
            return string
        }
    }
    
    override var description:String
    {
        get {
            load()
            
            var string = String()
            
            if let keys = words?.keys()?.sorted() {
                for key in keys {
                    string += key + "\n"
                    if let mediaItems = words?[key]?.sorted(by: { (first, second) -> Bool in
                        if first.value == second.value {
                            if let firstDate = first.key.fullDate, let secondDate = second.key.fullDate {
                                return firstDate.isOlderThan(secondDate)
                            } else {
                                return false // arbitrary
                            }
                        } else {
                            return first.value > second.value
                        }
                    }) {
                        for mediaItem in mediaItems {
                            string += "(\(mediaItem.key),\(mediaItem.value))\n"
                        }
                    }
                }
            }
            
            return string
        }
    }
    
    func activeWords(searchText:String?) -> [String]?
    {
        // The problem with this is that activeWords is NOT the same at all points in time if
        // the lexicon is being built!  Meaning, the array handed back will change depending
        // upon when you ask for it!
        //
        // The only time this returns the same thing is AFTER the lexicon is completed.
        guard let searchText = searchText else {
            return words?.keys()?.sorted()
        }

        return words?.keys()?.filter({ (string:String) -> Bool in
            return string.range(of:searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }).sorted()
    }
}

