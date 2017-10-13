//
//  Lexicon.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class Lexicon : NSObject {
    weak var mediaListGroupSort:MediaListGroupSort?
    
    var selected:String?
    
    init(_ mlgs:MediaListGroupSort?)
    {
        super.init()
        
        self.mediaListGroupSort = mlgs
    }
    
    var tokens:[String]? {
        get {
            return words?.keys.sorted()
        }
    }
    
    var gcw:[String]? {
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
    
    var gcr:[String]? {
        get {
            guard let tokens = tokens else {
                return nil
            }
            
            var roots = [String:Int]()
            
            for token in tokens {
                var string = String()
                
                for character in token.characters {
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
                        //                        print(candidate,currentCandidate)
                        if currentCandidate.endIndex <= candidate.endIndex {
                            if candidate.substring(to: currentCandidate.endIndex) == currentCandidate {
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
    
    var words:Words? {
        willSet {
            
        }
        didSet {
            if let keys = self.words?.keys.sorted() {
                var strings = [String]()
                
                for word in keys {
                    if let count = documents(word), let occurrences = occurrences(word) { // self.words?[word]?.count
                        strings.append("\(word) (\(occurrences) in \(count))")
                    }
                }
                
                section.strings = strings
                
                globals.queue.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
                })
            }
        }
    }
    
    var creating = false
    var pauseUpdates = false
    var completed = false
    
    var section = Section()
    
    var entries:[MediaItem]? {
        get {
            guard let words = words else {
                return nil
            }
            
            return Array(Set(
                words.flatMap({ (mediaItemFrequency:(key: String, value: [MediaItem : Int])) -> [MediaItem] in
                    // .map is required below to return an array of MediaItem, otherwise it returns a LazyMapCollection and I haven't figured that out.
                    return mediaItemFrequency.value.keys.map({ (mediaItem:MediaItem) -> MediaItem in
                        return mediaItem
                    })
                })
            ))
        }
    }
    
    var eligible:[MediaItem]? {
        get {
            if let list = mediaListGroupSort?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasNotesHTML
            }), list.count > 0 {
                return list
            } else {
                return nil
            }
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
    
    func build()
    {
        guard !creating else {
            return
        }
        
        guard (words == nil) else {
            return
        }
        
        if var list = eligible {
            creating = true
            
            DispatchQueue.global(qos: .background).async {
                var dict = Words()
                
                var date = Date()
                
                globals.queue.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self)
                })
                
                repeat {
                    if let mediaItem = list.first {
                        mediaItem.loadNotesTokens()
                        
                        if let notesTokens = mediaItem.notesTokens {
                            if let index = list.index(of: mediaItem) {
                                list.remove(at: index)
                            } else {
                                print("ERROR")
                            }
                            
                            for token in notesTokens {
                                if dict[token.key] == nil {
                                    dict[token.key] = [mediaItem:token.value]
                                } else {
                                    dict[token.key]?[mediaItem] = token.value
                                }
                                
                                if globals.isRefreshing || globals.isLoading {
                                    break
                                }
                            }
                        } else {
                            print("NO NOTES TOKENS!")
                        }
                        
                        if globals.isRefreshing || globals.isLoading {
                            break
                        }
                        
                        if !self.pauseUpdates {
                            if date.timeIntervalSinceNow <= -1 {
                                //                                print(date)
                                
                                self.words = dict.count > 0 ? dict : nil
                                
                                date = Date()
                            }
                        }
                    }
                    
                    if globals.isRefreshing || globals.isLoading {
                        break
                    }
                } while list.count > 0
                
                self.words = dict.count > 0 ? dict : nil
                
                self.creating = false
                
                if !globals.isRefreshing && !globals.isLoading {
                    self.completed = true
                }
                
                //        print(dict)
                globals.queue.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self)
                })
            }
        } else {
            print("NIL ELIGIBLE MEDIALIST FOR LEXICON INDEX")
        }
    }
    
    func load()
    {
        guard (words == nil) else {
            return
        }
        
        var dict = Words()
        
        if let list = eligible {
            for mediaItem in list {
                mediaItem.loadNotesTokens()
                
                if let notesTokens = mediaItem.notesTokens {
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
        
        //        print(dict)
        
        words = dict.count > 0 ? dict : nil
    }
    
    override var description:String {
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

