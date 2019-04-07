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
    private weak var mediaListGroupSort:MediaListGroupSort?
    
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
    
    var words:Words?
    {
        willSet {

        }
        didSet {

        }
    }
    
    var wordsHTML : String?
    {
        get{
            var bodyHTML:String! = "<!DOCTYPE html>" //setupMediaItemsHTML(self?.mediaListGroupSort?.mediaItems, includeURLs: true, includeColumns: true)?.replacingOccurrences(of: "</body></html>", with: "") //
            
            bodyHTML += "<html><body>"
            
            var wordsHTML = ""
            var indexHTML = ""
            
            if let words = tokens?.sorted(by: { (lhs:String, rhs:String) -> Bool in
                return lhs < rhs
            }) {
                var roots = [String:Int]()
                
                var keys : [String] {
                    get {
                        return roots.keys.sorted()
                    }
                }
                
                words.forEach({ (word:String) in
                    let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                    let key = String(word[..<String.Index(encodedOffset: 1)])
                    if let count = roots[key] {
                        roots[key] = count + 1
                    } else {
                        roots[key] = 1
                    }
                })
                
                bodyHTML += "<br/>"
                
                //                    bodyHTML += "<p>Index to \(words.count) Words</p>"
                bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
                
                //                    indexHTML = "<table>"
                //
                //                    indexHTML += "<tr>"
                
                var index : String?
                
                for root in roots.keys.sorted() {
                    let link = "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=\"#words\(root)\">\(root)</a>"
                    index = ((index != nil) ? index! + " " : "") + link
                }
                
                indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
                
                if let index = index {
                    indexHTML += index + "<br/>"
                }
                
                //                    indexHTML = indexHTML + "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a></div>"
                //                    for root in roots.keys.sorted() {
                //                        indexHTML += "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=#words\(root)>" + root + "</a>" // "<td>" + + "</td>"
                //                    }
                
                //                    indexHTML += "</tr>"
                //
                //                    indexHTML += "</table>"
                
                indexHTML += "<br/>"
                
                wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
                
                wordsHTML += "<div class=\"index\">"
                
                wordsHTML += "<ul class=\"words\">"
                
                //                    wordsHTML += "<tr><td></td></tr>"
                
                //                    indexHTML += "<style>.word{ float: left; margin: 5px; padding: 5px; width:300px; } .wrap{ width:1000px; column-count: 3; column-gap:20px; }</style>"
                
                var section = 0
                
                //                    wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
                
                let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]

                wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
                
                for word in words {
                    let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                    let first = String(word[..<String.Index(encodedOffset: 1)])
                    
                    if first != keys[section] {
                        // New Section
                        section += 1
                        //                            wordsHTML += "<tr><td></td></tr>"
                        
                        //                            wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
                        
                        wordsHTML += "</ul>"
                        
                        wordsHTML += "<br/>"
                        
                        wordsHTML += "<ul class=\"words\">"
                        
                        let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]

                        wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
                    }
                    
                    //                        wordsHTML += "<tr><td>" + word + "</td></tr>"
                    
                    //                        wordsHTML += "<li>" + word + "</li>"
                    wordsHTML += "<li>"
                    wordsHTML += word
                    
                    // Word Frequency and Links Back to Documents
                    //                        if let entries = words?[word]?.sorted(by: { (first:(key: MediaItem, value: Int), second:(key: MediaItem, value: Int)) -> Bool in
                    //                            first.key.title?.withoutPrefixes < second.key.title?.withoutPrefixes
                    //                        }) {
                    //                            var count = 0
                    //                            for entry in entries {
                    //                                count += entry.value
                    //                            }
                    //                            wordsHTML += " (\(count))"
                    //
                    //                            wordsHTML += "<ul>"
                    //                            var i = 1
                    //                            for entry in entries {
                    //                                if let tag = entry.key.title?.asTag {
                    //                                    wordsHTML += "<li class\"back\">"
                    //                                    wordsHTML += "<a href=#\(tag)>\(entry.key.title!)</a> (\(entry.value))"
                    //                                    wordsHTML += "</li>"
                    //                                }
                    //                                i += 1
                    //                            }
                    //                            wordsHTML += "</ul>"
                    //                        }
                    
                    wordsHTML += "</li>"
                }
                
                wordsHTML += "</ul>"
                
                wordsHTML += "</div>"
                
                wordsHTML += "</div>"
            }
            
            bodyHTML += indexHTML + wordsHTML + "</body></html>"
            
            return bodyHTML
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
    
//    lazy var eligible = { [weak self] in
//        return Shadowed<[MediaItem]>(get: { () -> ([MediaItem]?) in
//            if let list = self.mediaListGroupSort?.mediaList?.list?.filter({ (mediaItem:MediaItem) -> Bool in
//                return mediaItem.hasNotesText
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
            if _eligible == nil, startingUp || (oldValue != nil)  { // , oldValue != nil
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
            // Nothing words is thread safe
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
        operationQueue.name = "Lexicon" + UUID().uuidString
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
        
        let operation = CancellableOperation { [weak self] (test:(()->Bool)?) in
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
}

