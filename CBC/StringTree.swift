//
//  StringTree.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

// Crucial for Word Picker that this be a struct so that it is passed by value, not reference; i.e. a copy is made.
// That means all of the stringNodes are frozen when it is passed by value so that Expanded Views are always complete as of that moment and
// are not affected by changes to the tree while the expanded view is being prepared.
////////////
// So why is it a class?
////////////

class StringTree
{
    var callBacks = CallBacks()
//    var start : (()->())?
//    var update : (()->())?
//    var complete : (()->())?
    
    lazy var root:StringNode! = { [weak self] in
        return StringNode(nil)
    }()
    
    var incremental = false
    var building = false
//    {
//        get {
//            return operationQueue.operationCount > 0
//        }
//    }
    var completed = false
    {
        didSet {
            
        }
    }
    
    weak var lexicon : Lexicon?
    {
        didSet {

        }
    }
    
    var stringsFunction:(()->[String]?)?
    {
        didSet {
            
        }
    }
    
    // lexicon: Lexicon?,
    convenience init(stringsFunction:(()->[String]?)?, incremental: Bool)
    {
        self.init()
        
//        self.lexicon = lexicon
        
        self.stringsFunction = stringsFunction
        
//        if incremental {
//            lexicon?.callBacks.register(id: "STRINGTREE",   callBack: CallBack(
//                start: { [weak self] in
//
//                },
//                update: { [weak self] in
//                    self?.completed = false
//                    self?.build(strings: self?.stringsFunction?())
//                },
//                complete: { [weak self] in
//                    self?.completed = false
//                    self?.build(strings: self?.stringsFunction?())
//                }
//            ))
//        }

        self.incremental = incremental
    }

    var words : [String]?
    {
        get {
            guard let wordRoots = root?.stringNodes else {
                return nil
            }
            
            var words = [String]()
            
            for wordRoot in wordRoots {
                if let rootWords = wordRoot.words(nil) {
                    words.append(contentsOf: rootWords)
                }
            }
            
            return words.count > 0 ? words : nil
        }
    }
    
    var hyphenWords : [String]?
    {
        get {
            guard let wordRoots = root?.stringNodes else {
                return nil
            }
            
            var hyphenWords = [String]()
            
            for wordRoot in wordRoots {
                if let rootHyphenWords = wordRoot.hyphenWords(nil) {
                    hyphenWords.append(contentsOf: rootHyphenWords)
                }
            }
            
            return hyphenWords.count > 0 ? hyphenWords : nil
        }
    }
    
    var wordsHTML : String?
    {
        get{
            return hyphenWords?.sorted().tableHTML
            
//            var bodyHTML:String! = "<!DOCTYPE html>"
//            
//            bodyHTML += "<html><body>"
//            
//            guard let words = hyphenWords?.sorted() else {
//                bodyHTML += "</body></html>"
//                return bodyHTML
//            }
//            
////            var hyphenWords = [String]()
////
////            for wordRoot in wordRoots {
////                if let words = wordRoot.hyphenWords(nil) {
////                    hyphenWords.append(contentsOf: words)
////                }
////            }
//            
//            var wordsHTML = ""
//            var indexHTML = ""
//            
////            let words = hyphenWords.sorted(by: { (lhs:String, rhs:String) -> Bool in
////                return lhs < rhs
////            })
//            
//            var roots = [String:Int]()
//            
//            var keys : [String] {
//                get {
//                    return roots.keys.sorted()
//                }
//            }
//            
//            words.forEach({ (word:String) in
//                let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                //                    let key = String(word[..<String.Index(encodedOffset: 1)])
//                if let count = roots[key] {
//                    roots[key] = count + 1
//                } else {
//                    roots[key] = 1
//                }
//            })
//            
//            bodyHTML += "<br/>"
//            
//            bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
//            
//            var index : String?
//            
//            for root in roots.keys.sorted() {
//                let tag = root.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? root
//                
//                let link = "<a id=\"wordIndex\(tag)\" name=\"wordIndex\(tag)\" href=\"#words\(tag)\">\(root)</a>"
//                index = ((index != nil) ? index! + " " : "") + link
//            }
//            
//            indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
//            
//            if let index = index {
//                indexHTML += index + "<br/>"
//            }
//            
//            indexHTML += "<br/>"
//            
//            wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
//            
//            wordsHTML += "<div class=\"index\">"
//            
//            wordsHTML += "<ul class=\"words\">"
//            
//            var section = 0
//            
//            let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
//            
//            wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
//            
//            for word in words {
//                let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
//                
//                if first != keys[section] {
//                    // New Section
//                    section += 1
//                    
//                    wordsHTML += "</ul>"
//                    
//                    wordsHTML += "<br/>"
//                    
//                    wordsHTML += "<ul class=\"words\">"
//                    
//                    let tag = keys[section].addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? keys[section]
//                    
//                    wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
//                }
//                
//                wordsHTML += "<li>"
//                
//                wordsHTML += word
//                
//                wordsHTML += "</li>"
//            }
//            
//            wordsHTML += "</ul>"
//            
//            wordsHTML += "</div>"
//            
//            wordsHTML += "</div>"
//            
//            bodyHTML += indexHTML + wordsHTML + "</body></html>"
//            
//            return bodyHTML
        }
    }

    var expandedHTML : String?
    {
        get {
            var bodyHTML = "<!DOCTYPE html>"
            
            bodyHTML += "<html><body>"
            
            guard let roots = root?.stringNodes else {
                bodyHTML += "</body></html>"
                return bodyHTML
            }
            
            var total = 0
            for root in roots {
                if let count = root.htmlWords(nil)?.count {
                    total += count
                }
            }
            bodyHTML += "<p>Index to \(total) Words</p>"
            
            bodyHTML += "<table><tr>"
            
            for root in roots {
                if let string = root.string, let tag = root.string?.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) {
                    bodyHTML += "<td>" + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=#\(tag)>" + string + "</a>" + "</td>"
                }
            }
            
            bodyHTML += "</tr></table>"
            
            bodyHTML += "<table>"
            
            for root in roots {
                if let rows = root.htmlWords(nil) {
                    if let string = root.string, let tag = root.string?.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) {
                        bodyHTML += "<tr><td>" + "<br/>" +  "<a id=\"\(tag)\" name=\"\(tag)\" href=#index\(tag)>" + string + "</a>" + " (\(rows.count))" + "</td></tr>"
                    }
                    
                    for row in rows {
                        bodyHTML += "<tr>" + row + "</tr>"
                    }
                }
            }
            
            bodyHTML += "</table>"

            bodyHTML += "</body></html>"
            
            return bodyHTML.insertHead(fontSize: Constants.FONT_SIZE)
        }
    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "StringTree" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        lexicon?.callBacks.unregister(id: "STRINGTREE")
        operationQueue.cancelAllOperations()
    }
    
    func build(strings:[String]?)
    {
//        guard !building else {
//            return
//        }
        
        guard let strings = strings?.sorted(), strings.count > 0 else {
            return
        }

        if incremental {
            operationQueue.cancelAllOperations()
            operationQueue.waitUntilAllOperationsAreFinished()

//            DispatchQueue.global(qos: .background).async { [weak self] in
            let op = CancelableOperation(tag: "StringTree") { [weak self] (test:(() -> Bool)?) in
                self?.callBacks.start()
                
//                self?.root = StringNode(nil) // Faster?

                // Walking the tree over and over again is slower than recreating it each time?
                // No and starting over each time is visually awful, the wheels empty each time.
                
                if self?.root == nil {
                    self?.root = StringNode(nil)
                }

                // BUT we're losing words somewhere if Lexicon updates picker incrementally
                // in this case the lexicon updating is updating the stringTree which is updating the picker
                
                // If lexicon is allowed to finish and then the picker is opened no words are lost
                // in this case stringTree build is NEVER updated (i.e. restarted) but the stringTree still udpates the picker.
                
                // Is activeWords in LIVC to blame?
                
                var date : Date?
                
                for string in strings {
                    if test?() == true {
                        break
                    }
                    
                    self?.root.addString(string)
                    
                    if (date == nil) || (date?.timeIntervalSinceNow <= -3) { // Any more frequent and the UI becomes unresponsive.
                        self?.callBacks.update()
                        //                        Globals.shared.queue.async {
                        //                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                        //                        }
                        
                        date = Date()
                    }
                }
                
                if test?() == true {
                    self?.building = false
                    self?.completed = false
                    return
                }
                
                self?.building = false
                self?.completed = true
                
                self?.callBacks.complete()
                //                Globals.shared.queue.async {
                //                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                //                }
            }
            
            operationQueue.addOperation(op)
        } else {
            if !building {
                building = true
                
                // This blocks
                self.root = StringNode(nil)
                
                self.root.addStrings(strings)
                
                self.building = false
                self.completed = true
            }
        }
    }
}

