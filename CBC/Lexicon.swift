//
//  Lexicon.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class Lexicon : NSObject // Why an NSObject?
{
    private weak var mediaListGroupSort:MediaListGroupSort?
    
    // Not much use since user can search words table in LIVC and this is supposed to
    // reflect only the words in search result.  => stringTree s/b in LIVC, not lexicon
    // and change whenever activeWords changes.
//    lazy var stringTree : StringTree? = { [weak self] in
//        return StringTree(lexicon:self, stringsFunction: { [weak self] in
//            return self?.stringsFunction?()
//        }, incremental:true)
//    }()
    
    @objc func freeMemory()
    {
        words = nil
        eligible = nil
        stringTrees = [String:StringTree]()
    }
    
    private var stringTrees = [String:StringTree]()
    func stringTree(_ searchText:String?) -> StringTree?
    {
        guard let activeWordsString = activeWords(searchText:searchText)?.sorted().joined() else {
            return nil
        }
        
        if stringTrees[activeWordsString] == nil {
            stringTrees[activeWordsString] = StringTree(stringsFunction: { [weak self] in
                return self?.stringsFunction?()
                }, incremental:true)
        }
        
        return stringTrees[activeWordsString]
    }
    var stringTreeFunction:(()->StringTree?)?
    {
        didSet {
            
        }
    }
    
    private var incremental = false // FUTURE USE

    var callBacks = CallBacks()
    
    var selected:String?
    
    init(_ mediaListGroupSort:MediaListGroupSort?)
    {
        super.init()

        self.mediaListGroupSort = mediaListGroupSort
        
        Thread.onMainThread {
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var tokens:[String]?
    {
        get {
            return words?.keys()?.sorted()
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
    
//    var wordsHTML : String?
//    {
//        get{
//            return tokens?.sorted().tableHTML
//
////            var bodyHTML:String! = "<!DOCTYPE html>" //setupMediaItemsHTML(self?.mediaListGroupSort?.mediaItems, includeURLs: true, includeColumns: true)?.replacingOccurrences(of: "</body></html>", with: "") //
////
////            bodyHTML += "<html><body>"
////
////            var wordsHTML = ""
////            var indexHTML = ""
////
////            if let words = tokens?.sorted(by: { (lhs:String, rhs:String) -> Bool in
////                return lhs < rhs
////            }) {
////                var roots = [String:Int]()
////
////                var keys : [String] {
////                    get {
////                        return roots.keys.sorted()
////                    }
////                }
////
////                words.forEach({ (word:String) in
////                    let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
//////                    let key = String(word[..<String.Index(encodedOffset: 1)])
////                    if let count = roots[key] {
////                        roots[key] = count + 1
////                    } else {
////                        roots[key] = 1
////                    }
////                })
////
////                bodyHTML += "<br/>"
////
////                //                    bodyHTML += "<p>Index to \(words.count) Words</p>"
////                bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
////
////                //                    indexHTML = "<table>"
////                //
////                //                    indexHTML += "<tr>"
////
////                var index : String?
////
////                for root in roots.keys.sorted() {
////                    let link = "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=\"#words\(root)\">\(root)</a>"
////                    index = ((index != nil) ? index! + " " : "") + link
////                }
////
////                indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
////
////                if let index = index {
////                    indexHTML += index + "<br/>"
////                }
////
////                //                    indexHTML = indexHTML + "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a></div>"
////                //                    for root in roots.keys.sorted() {
////                //                        indexHTML += "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=#words\(root)>" + root + "</a>" // "<td>" + + "</td>"
////                //                    }
////
////                //                    indexHTML += "</tr>"
////                //
////                //                    indexHTML += "</table>"
////
////                indexHTML += "<br/>"
////
////                wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
////
////                wordsHTML += "<div class=\"index\">"
////
////                wordsHTML += "<ul class=\"words\">"
////
////                //                    wordsHTML += "<tr><td></td></tr>"
////
////                //                    indexHTML += "<style>.word{ float: left; margin: 5px; padding: 5px; width:300px; } .wrap{ width:1000px; column-count: 3; column-gap:20px; }</style>"
////
////                var section = 0
////
////                //                    wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
////
////                let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
////
////                wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
////
////                for word in words {
////                    let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
//////                    let first = String(word[..<String.Index(encodedOffset: 1)])
////
////                    if first != keys[section] {
////                        // New Section
////                        section += 1
////                        //                            wordsHTML += "<tr><td></td></tr>"
////
////                        //                            wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
////
////                        wordsHTML += "</ul>"
////
////                        wordsHTML += "<br/>"
////
////                        wordsHTML += "<ul class=\"words\">"
////
////                        let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
////
////                        wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
////                    }
////
////                    //                        wordsHTML += "<tr><td>" + word + "</td></tr>"
////
////                    //                        wordsHTML += "<li>" + word + "</li>"
////                    wordsHTML += "<li>"
////                    wordsHTML += word
////
////                    // Word Frequency and Links Back to Documents
////                    //                        if let entries = words?[word]?.sorted(by: { (first:(key: MediaItem, value: Int), second:(key: MediaItem, value: Int)) -> Bool in
////                    //                            first.key.title?.withoutPrefixes < second.key.title?.withoutPrefixes
////                    //                        }) {
////                    //                            var count = 0
////                    //                            for entry in entries {
////                    //                                count += entry.value
////                    //                            }
////                    //                            wordsHTML += " (\(count))"
////                    //
////                    //                            wordsHTML += "<ul>"
////                    //                            var i = 1
////                    //                            for entry in entries {
////                    //                                if let tag = entry.key.title?.asTag {
////                    //                                    wordsHTML += "<li class\"back\">"
////                    //                                    wordsHTML += "<a href=#\(tag)>\(entry.key.title!)</a> (\(entry.value))"
////                    //                                    wordsHTML += "</li>"
////                    //                                }
////                    //                                i += 1
////                    //                            }
////                    //                            wordsHTML += "</ul>"
////                    //                        }
////
////                    wordsHTML += "</li>"
////                }
////
////                wordsHTML += "</ul>"
////
////                wordsHTML += "</div>"
////
////                wordsHTML += "</div>"
////            }
////
////            bodyHTML += indexHTML + wordsHTML + "</body></html>"
////
////            return bodyHTML
//        }
//    }
    
    var building:Bool // = false
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
//            guard let words = words else {
//                return nil
//            }
            
            let entries = words?.values()?.flatMap({ (dict:[MediaItem : Int]) -> [MediaItem] in
                return Set(dict.keys).array
            }).set.array
            
            return entries
            
//            flatMap({ (mediaItemFrequency:(key: String, value: Any)) -> [MediaItem] in
//                if let keys = (mediaItemFrequency.value as? [MediaItem:Int])?.keys {
//                    return Set(keys).array
//                } else {
//                    return []
//                }
//            }).set.array
            
//            return Array(Set(
//                words.copy?.flatMap({ (mediaItemFrequency:(key: String, value: )) -> [MediaItem] in
//                    return Array(mediaItemFrequency.value.keys)
//                }) ?? []
//            ))
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

//    func update()
//    {
//        Globals.shared.queue.async {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
//        }
//    }
    
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
//        creating = false
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
            callBacks.complete()
            return
        }
        
        guard !building else {
            return
        }
        
        let operation = CancelableOperation { [weak self] (test:(()->Bool)?) in
//            defer {
//                self?.creating = false
//            }
            
//            self?.creating = true
            
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
            
//            Globals.shared.queue.async {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self)
//            }

            self?.callBacks.start()
            
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
                            mediaItem.notesTokens?.clear() // Save memory - load on demand.
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
                    self?.callBacks.update()

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

//            self?.callBacks.update() // Not necessary
//            self?.update?()
            
            if !Globals.shared.isRefreshing && !Globals.shared.isLoading {
                self?.completed = true
            }

//            Globals.shared.queue.async {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self)
//            }
            
            self?.callBacks.complete()
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
        guard let searchText = searchText else {
            return words?.keys()?.sorted()
        }
        
        return words?.keys()?.filter({ (string:String) -> Bool in
            return string.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }).sorted()
    }
    
//    func activeWordsString(_ searchText:String?) -> String?
//    {
//        return activeWords(searchText)?.sorted().joined()
//    }
    
//    func activeWordsHTML(_ searchText:String?) -> String?
//    {
//        return activeWords(searchText)?.sorted().tableHTML(searchText:searchText)
//
////        var bodyHTML:String! = "<!DOCTYPE html>" //setupMediaItemsHTML(self?.mediaListGroupSort?.mediaItems, includeURLs: true, includeColumns: true)?.replacingOccurrences(of: "</body></html>", with: "") //
////
////        bodyHTML += "<html><body>"
////
////        var wordsHTML = ""
////        var indexHTML = ""
////
////        if let words = activeWords(searchText)?.sorted(by: { (lhs:String, rhs:String) -> Bool in
////            return lhs < rhs
////        }) {
////            var roots = [String:Int]()
////
////            var keys : [String] {
////                get {
////                    return roots.keys.sorted()
////                }
////            }
////
////            words.forEach({ (word:String) in
////                let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
////                //                    let key = String(word[..<String.Index(encodedOffset: 1)])
////                if let count = roots[key] {
////                    roots[key] = count + 1
////                } else {
////                    roots[key] = 1
////                }
////            })
////
////            bodyHTML += "<br/>"
////
////            //                    bodyHTML += "<p>Index to \(words.count) Words</p>"
////            bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
////
////            if let searchText = searchText?.uppercased() {
////                bodyHTML += "Search Text: \(searchText)<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
////            }
////
////            //                    indexHTML = "<table>"
////            //
////            //                    indexHTML += "<tr>"
////
////            var index : String?
////
////            for root in roots.keys.sorted() {
////                let tag = root.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? root
////
////                let link = "<a id=\"wordIndex\(tag)\" name=\"wordIndex\(tag)\" href=\"#words\(tag)\">\(root)</a>"
////                index = ((index != nil) ? index! + " " : "") + link
////            }
////
////            indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
////
////            if let index = index {
////                indexHTML += index + "<br/>"
////            }
////
////            //                    indexHTML = indexHTML + "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a></div>"
////            //                    for root in roots.keys.sorted() {
////            //                        indexHTML += "<a id=\"wordIndex\(root)\" name=\"wordIndex\(root)\" href=#words\(root)>" + root + "</a>" // "<td>" + + "</td>"
////            //                    }
////
////            //                    indexHTML += "</tr>"
////            //
////            //                    indexHTML += "</table>"
////
////            indexHTML += "<br/>"
////
////            wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
////
////            wordsHTML += "<div class=\"index\">"
////
////            wordsHTML += "<ul class=\"words\">"
////
////            //                    wordsHTML += "<tr><td></td></tr>"
////
////            //                    indexHTML += "<style>.word{ float: left; margin: 5px; padding: 5px; width:300px; } .wrap{ width:1000px; column-count: 3; column-gap:20px; }</style>"
////
////            var section = 0
////
////            //                    wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
////
////            let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
////
////            wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
////
////            for word in words {
////                let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
////                //                    let first = String(word[..<String.Index(encodedOffset: 1)])
////
////                if first != keys[section] {
////                    // New Section
////                    section += 1
////                    //                            wordsHTML += "<tr><td></td></tr>"
////
////                    //                            wordsHTML += "<tr><td>" + "<a id=\"\(keys[section])\" name=\"\(keys[section])\" href=#index\(keys[section])>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))</td></tr>"
////
////                    wordsHTML += "</ul>"
////
////                    wordsHTML += "<br/>"
////
////                    wordsHTML += "<ul class=\"words\">"
////
////                    let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
////
////                    wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
////                }
////
////                //                        wordsHTML += "<tr><td>" + word + "</td></tr>"
////
////                //                        wordsHTML += "<li>" + word + "</li>"
////                wordsHTML += "<li>"
////
////                if let searchText = searchText {
////                    wordsHTML += word.markSearchHTML(searchText)
////                } else {
////                    wordsHTML += word
////                }
////
////                // Word Frequency and Links Back to Documents
////                //                        if let entries = words?[word]?.sorted(by: { (first:(key: MediaItem, value: Int), second:(key: MediaItem, value: Int)) -> Bool in
////                //                            first.key.title?.withoutPrefixes < second.key.title?.withoutPrefixes
////                //                        }) {
////                //                            var count = 0
////                //                            for entry in entries {
////                //                                count += entry.value
////                //                            }
////                //                            wordsHTML += " (\(count))"
////                //
////                //                            wordsHTML += "<ul>"
////                //                            var i = 1
////                //                            for entry in entries {
////                //                                if let tag = entry.key.title?.asTag {
////                //                                    wordsHTML += "<li class\"back\">"
////                //                                    wordsHTML += "<a href=#\(tag)>\(entry.key.title!)</a> (\(entry.value))"
////                //                                    wordsHTML += "</li>"
////                //                                }
////                //                                i += 1
////                //                            }
////                //                            wordsHTML += "</ul>"
////                //                        }
////
////                wordsHTML += "</li>"
////            }
////
////            wordsHTML += "</ul>"
////
////            wordsHTML += "</div>"
////
////            wordsHTML += "</div>"
////        }
////
////        bodyHTML += indexHTML + wordsHTML + "</body></html>"
////
////        return bodyHTML
//    }
}

