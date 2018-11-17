//
//  Lexicon.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class Lexicon : NSObject
{
    weak var mediaListGroupSort:MediaListGroupSort?
    
    var selected:String?
    
    init(_ mediaListGroupSort:MediaListGroupSort?)
    {
        super.init()

        self.mediaListGroupSort = mediaListGroupSort
    }
    
    var tokens:[String]?
    {
        get {
            return words?.keys.sorted()
        }
    }
    
    var gcw:[String]?
    {
        get {
            var words = [String:Int]()
            
            if let tokens = tokens {
                if var currentToken = tokens.first {
                    for token in tokens {
                        if token.contains(currentToken) {
                            if (token != tokens.first) {
                                if let count = words[currentToken] {
                                    words[currentToken] = count + 1
                                } else {
                                    words[currentToken] = 1
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
    
    var gcr:[String]?
    {
        get {
            guard let tokens = tokens else {
                return nil
            }
            
            var roots = [String:Int]()
            
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

            let candidates = roots.keys.filter({ (root:String) -> Bool in
                if let count = roots[root] {
                    return count > 1
                } else {
                    return false
                }
            }).sorted()
            
            var finalRoots = candidates
            
            if var currentCandidate = candidates.first {
                for candidate in candidates {
                    if candidate != candidates.first {
                        if currentCandidate.endIndex <= candidate.endIndex {
                            if String(candidate[..<currentCandidate.endIndex]) == currentCandidate {
                                if let index = finalRoots.index(of: currentCandidate) {
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
    
    var words:Words?
    {
        willSet {

        }
        didSet {

        }
    }
    
    var creating = false
    var pauseUpdates = false
    var completed = false
    
    var entries:[MediaItem]?
    {
        get {
            guard let words = words else {
                return nil
            }
            
            return Array(Set(
                words.copy?.flatMap({ (mediaItemFrequency:(key: String, value: [MediaItem : Int])) -> [MediaItem] in
                    return Array(mediaItemFrequency.value.keys)
                }) ?? []
            ))
        }
    }
    
    var _eligible:[MediaItem]?
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
    }
//    var eligible:[MediaItem]?
//    {
//        get {
//            if let list = mediaListGroupSort?.mediaList?.list?.filter({ (mediaItem:MediaItem) -> Bool in
//                return mediaItem.hasNotesText
//            }), list.count > 0 {
//                return list
//            } else {
//                return nil
//            }
//        }
//    }
    
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
    
    var strings : [String]?
    {
        get {
            // What happens if build() inserts a new key while this is happening?
            return words?.keys.sorted()
        }
    }

    func update()
    {
        Globals.shared.queue.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
        }
    }
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "LEXICON" + UUID().uuidString
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func stop()
    {
        operationQueue.cancelAllOperations()
        creating = false
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
            return
        }
        
        guard !creating else {
            return
        }
        
        creating = true
        
        let operation = CancellableOperation { [weak self] (test:(()->(Bool))?) in
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
                self?.words = Words(name: UUID().uuidString + Constants.Strings.Words)
            }
            
            var date = Date()
            
            Globals.shared.queue.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self)
            }
            
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

                let purge = Globals.shared.purge && (mediaItem.notesTokens?.cache == nil)
                
                // Made an ORDER OF MAGNITUDE difference in memory usage!
                autoreleasepool {
                    if let notesTokens = mediaItem.notesTokens?.result {
                        // Try indefinitely to load all media items
                        list.removeFirst()
                        
                        if purge {
                            mediaItem.notesTokens?.cache = nil // Save memory - load on demand.
                        }
                        
//                        print("notesTokens to add: \(notesTokens.count)")
                        
                        for token in notesTokens {
                            if self?.words?[token.key] == nil {
                                self?.words?[token.key] = [mediaItem:token.value]
                            } else {
                                self?.words?[token.key]?[mediaItem] = token.value
                            }

//                            self?.words?[token.key]?[mediaItem] = token.value

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
                
                ///////////////////////////////////////////////////////////////////////////////
                // What if the update takes longer than 10 seconds? => Need to queue updates.
                ///////////////////////////////////////////////////////////////////////////////

                // Now that updates are queued on the LIVC, we don't need this
                // but it still seems like a good idea to avoid a flurry of updates
                // even as the lexicon is continuing to change, which means if the LIVC queue
                // has a backlog the pending updates will all be the same, which is waste of update time.

//                self?.update()

                if firstUpdate || (date.timeIntervalSinceNow <= -5) {
                    self?.update()

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

            self?.update()
            
            self?.creating = false
            
            if !Globals.shared.isRefreshing && !Globals.shared.isLoading {
                self?.completed = true
            }
            
            Globals.shared.queue.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self)
            }
        }

        operationQueue.addOperation(operation)
    }
    
    func load()
    {
        guard (words == nil) else {
            return
        }
        
        let dict = Words(name: UUID().uuidString + Constants.Strings.Words)
        
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
            
            if let keys = words?.keys.sorted(), let values = words?.values {
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
            
            if let keys = words?.keys.sorted() {
                for key in keys {
                    string = string + key + "\n"
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
                            string = string + "(\(mediaItem.key,mediaItem.value))\n"
                        }
                    }
                }
            }
            
            return string
        }
    }
}

