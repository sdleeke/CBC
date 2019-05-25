//
//  StringTree.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Handle parsing strings into their shared parts in a hierarchy.

 */

class StringTree
{
    var callBacks = CallBacks()
    
    lazy var root:StringNode! = { [weak self] in
        return StringNode(nil)
    }()
    
    var incremental = false
    
    var building:Bool
    {
        get {
            return operationQueue.operationCount > 0
        }
    }
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
    
    convenience init(stringsFunction:(()->[String]?)?, incremental: Bool)
    {
        self.init()
        
        self.stringsFunction = stringsFunction

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
            
            bodyHTML += "<p>Index to \(total.formatted) Words</p>"

            bodyHTML += "<table><tr>"
            
            for root in roots {
                if let string = root.string, let tag = root.string?.asTag {
                    bodyHTML += "<td>" + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=#\(tag)>" + string + "</a>" + "</td>"
                }
            }
            
            bodyHTML += "</tr></table>"
            
            bodyHTML += "<table>"
            
            for root in roots {
                if let rows = root.htmlWords(nil) {
                    if let string = root.string, let tag = root.string?.asTag {
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
        lexicon?.callBacks.unregister("STRINGTREE")
        operationQueue.cancelAllOperations()
    }
    
    func build(strings:[String]?)
    {
        guard !completed else {
            callBacks.execute("complete")
            return
        }

        // incremental stops prior build and starts a new one
//        guard !building else {
//            return
//        }
        
        guard let strings = strings?.sorted(), strings.count > 0 else {
            return
        }

        if incremental {
            operationQueue.cancelAllOperations()
            operationQueue.waitUntilAllOperationsAreFinished()

            let op = CancelableOperation(tag: "StringTree") { [weak self] (test:(() -> Bool)?) in
                self?.callBacks.execute("start")

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
                        return
                    }
                    
                    self?.root.addString(string)
                    
                    if (date == nil) || (date?.timeIntervalSinceNow <= -3) { // Any more frequent and the UI becomes unresponsive.
                        self?.callBacks.execute("update")
                        
                        date = Date()
                    }
                }
                
                if test?() == true {
                    return
                }
                
                self?.completed = true
                
                self?.callBacks.execute("complete")
            }
            
            operationQueue.addOperation(op)
        } else {
            // This blocks
            self.root = StringNode(nil)
            
            self.root.addStrings(strings)

            self.completed = true
        }
    }
}

