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
    
    lazy var stringTree:StringTree! = {
        [unowned self] in
        return StringTree(lexicon: self)
        }()
    
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
            guard tokens != nil else {
                return nil
            }
            
            var roots = [String:Int]()
            
            if let tokens = tokens {
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
                
//                section.buildIndex()
                
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
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
            guard words != nil else {
                return nil
            }
            
            // Both use a lot of memory for the array(s) unless there is some smart compiler optimiation going on behind the scenes.
            
            // Both create a list of lists of MediaItems potentially on the order of #words * #mediaitems (coudl be in the (tens of) thousands) that has many repetitions of the same mediaItem and then eliminates redundancies w/ Set
            
            // But flatMap is more compact.  I believe, however, that the use of flatMap is only possible because Words is no longer a dictionary of tuples but a dictionary of dictionaries and a dictionary is a collection and flatMap operates on collections, whereas a tuple is not a collection so flatMap is only possible becase of the change to using collections entirely.
            
            // Using flatMap
            return Array(Set(
                words!.flatMap({ (mediaItemFrequency:(key: String, value: [MediaItem : Int])) -> [MediaItem] in
                    // .map is required below to return an array of MediaItem, otherwise it returns a LazyMapCollection and I haven't figured that out.
                    return mediaItemFrequency.value.keys.map({ (mediaItem:MediaItem) -> MediaItem in
                        return mediaItem
                    })
                })
            ))
            
            // Using map - creates a list of lists of MediaItems no longer than the active list of MediaItems and then collapses them w/ Set.
            //            var mediaItemSet = Set<MediaItem>()
            //
            //            if let list:[[MediaItem]] = words?.values.map({ (dict:[MediaItem:Int]) -> [MediaItem] in
            //                return dict.map({ (mediaItem:MediaItem,count:Int) -> MediaItem in
            //                    return mediaItem
            //                })
            //            }) {
            //                for mediaItemList in list {
            //                    mediaItemSet = mediaItemSet.union(Set(mediaItemList))
            //                }
            //            }
            //
            //            return mediaItemSet.count > 0 ? Array(mediaItemSet) : nil
            
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
        guard word != nil else {
            return nil
        }
        
        return words?[word!]?.count
    }
    
    func occurrences(_ word:String?) -> Int? // nil => not found
    {
        guard word != nil else {
            return nil
        }
        
        return words?[word!]?.values
            //            .map({ (count:Int) -> Int in
            //            return count
            //        })
            .reduce(0, +)
    }
    
    func build()
    {
        guard !creating else {
            return
        }
        
        //        guard !completed else {
        //            return
        //        }
        
        guard (words == nil) else {
            return
        }
        
        if var list = eligible {
            creating = true
            
            DispatchQueue.global(qos: .background).async {
                var dict = Words()
                
                var date = Date()
                
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
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
                            if date.timeIntervalSinceNow < -2 {
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
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
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
                            return first.key.fullDate!.isOlderThan(second.key.fullDate!)
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

