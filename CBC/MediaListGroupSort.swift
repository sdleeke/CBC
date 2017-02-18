//
//  MediaListGroupSort.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class BooksChaptersVerses : Swift.Comparable {
    var data:[String:[Int:[Int]]]?
    
    func bookChaptersVerses(book:String?) -> BooksChaptersVerses?
    {
        guard (book != nil) else {
            return self
        }
        
        let bcv = BooksChaptersVerses()
        
        bcv[book!] = data?[book!]
        
        //        print(bcv[book!])
        
        return bcv
    }
    
    func numberOfVerses() -> Int
    {
        var count = 0
        
        if let books = data?.keys.sorted(by: { bookNumberInBible($0) < bookNumberInBible($1) }) {
            for book in books {
                if let chapters = data?[book]?.keys.sorted() {
                    for chapter in chapters {
                        if let verses = data?[book]?[chapter] {
                            count += verses.count
                        }
                    }
                }
            }
        }
        
        return count
    }
    
    subscript(key:String) -> [Int:[Int]]? {
        get {
            return data?[key]
        }
        set {
            if data == nil {
                data = [String:[Int:[Int]]]()
            }
            
            data?[key] = newValue
        }
    }
    
    static func ==(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        let lhsBooks = lhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        let rhsBooks = rhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if (lhsBooks == nil) && (rhsBooks == nil) {
        } else
            if (lhsBooks != nil) && (rhsBooks == nil) {
                return false
            } else
                if (lhsBooks == nil) && (rhsBooks != nil) {
                    return false
                } else {
                    if lhsBooks?.count != rhsBooks?.count {
                        return false
                    } else {
                        //                        print(lhsBooks)
                        for index in 0...(lhsBooks!.count - 1) {
                            if lhsBooks?[index] != rhsBooks?[index] {
                                return false
                            }
                        }
                        for book in lhsBooks! {
                            let lhsChapters = lhs[book]?.keys.sorted()
                            let rhsChapters = rhs[book]?.keys.sorted()
                            
                            if (lhsChapters == nil) && (rhsChapters == nil) {
                            } else
                                if (lhsChapters != nil) && (rhsChapters == nil) {
                                    return false
                                } else
                                    if (lhsChapters == nil) && (rhsChapters != nil) {
                                        return false
                                    } else {
                                        if lhsChapters?.count != rhsChapters?.count {
                                            return false
                                        } else {
                                            for index in 0...(lhsChapters!.count - 1) {
                                                if lhsChapters?[index] != rhsChapters?[index] {
                                                    return false
                                                }
                                            }
                                            for chapter in lhsChapters! {
                                                let lhsVerses = lhs[book]?[chapter]?.sorted()
                                                let rhsVerses = rhs[book]?[chapter]?.sorted()
                                                
                                                if (lhsVerses == nil) && (rhsVerses == nil) {
                                                } else
                                                    if (lhsVerses != nil) && (rhsVerses == nil) {
                                                        return false
                                                    } else
                                                        if (lhsVerses == nil) && (rhsVerses != nil) {
                                                            return false
                                                        } else {
                                                            if lhsVerses?.count != rhsVerses?.count {
                                                                return false
                                                            } else {
                                                                for index in 0...(lhsVerses!.count - 1) {
                                                                    if lhsVerses?[index] != rhsVerses?[index] {
                                                                        return false
                                                                    }
                                                                }
                                                            }
                                                }
                                            }
                                        }
                            }
                        }
                    }
        }
        
        return true
    }
    
    static func !=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs == rhs)
    }
    
    static func <=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return (lhs < rhs) || (lhs == rhs)
    }
    
    static func <(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        let lhsBooks = lhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        let rhsBooks = rhs.data?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if (lhsBooks == nil) && (rhsBooks == nil) {
            return false
        } else
            if (lhsBooks != nil) && (rhsBooks == nil) {
                return false
            } else
                if (lhsBooks == nil) && (rhsBooks != nil) {
                    return true
                } else {
                    for lhsBook in lhsBooks! {
                        for rhsBook in rhsBooks! {
                            if lhsBook == rhsBook {
                                let lhsChapters = lhs[lhsBook]?.keys.sorted()
                                let rhsChapters = rhs[rhsBook]?.keys.sorted()
                                
                                if (lhsChapters == nil) && (rhsChapters == nil) {
                                    return lhsBooks?.count < rhsBooks?.count
                                } else
                                    if (lhsChapters != nil) && (rhsChapters == nil) {
                                        return true
                                    } else
                                        if (lhsChapters == nil) && (rhsChapters != nil) {
                                            return false
                                        } else {
                                            for lhsChapter in lhsChapters! {
                                                for rhsChapter in rhsChapters! {
                                                    if lhsChapter == rhsChapter {
                                                        let lhsVerses = lhs[lhsBook]?[lhsChapter]?.sorted()
                                                        let rhsVerses = rhs[rhsBook]?[rhsChapter]?.sorted()
                                                        
                                                        if (lhsVerses == nil) && (rhsVerses == nil) {
                                                            return lhsChapters?.count < rhsChapters?.count
                                                        } else
                                                            if (lhsVerses != nil) && (rhsVerses == nil) {
                                                                return true
                                                            } else
                                                                if (lhsVerses == nil) && (rhsVerses != nil) {
                                                                    return false
                                                                } else {
                                                                    for lhsVerse in lhsVerses! {
                                                                        for rhsVerse in rhsVerses! {
                                                                            if lhsVerse == rhsVerse {
                                                                                return lhs.numberOfVerses() < rhs.numberOfVerses()
                                                                            } else {
                                                                                return lhsVerse < rhsVerse
                                                                            }
                                                                        }
                                                                    }
                                                        }
                                                    } else {
                                                        return lhsChapter < rhsChapter
                                                    }
                                                }
                                            }
                                }
                            } else {
                                return bookNumberInBible(lhsBook) < bookNumberInBible(rhsBook)
                            }
                        }
                    }
        }
        
        return false
    }
    
    static func >=(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs < rhs)
    }
    
    static func >(lhs: BooksChaptersVerses, rhs: BooksChaptersVerses) -> Bool
    {
        return !(lhs < rhs) && !(lhs == rhs)
    }
}

class ScriptureIndex {
    var creating = false
    var completed = false
    
    weak var mediaListGroupSort:MediaListGroupSort?
    
    init(_ mlgs:MediaListGroupSort?)
    {
        self.mediaListGroupSort = mlgs
    }
    
    var sectionsIndex = [String:[String:[MediaItem]]]()
    
    var sections:[String:[MediaItem]]?
        {
        get {
            return context != nil ? sectionsIndex[context!] : nil
        }
        set {
            guard (context != nil) else {
                return
            }
            sectionsIndex[context!] = newValue
        }
    }
    
    lazy var html:CachedString? = {
        [unowned self] in
        return CachedString(index:self.index)
        }()
    
    func index() -> String? {
        return context
    }
    
    var context:String? {
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
    
    //    var htmlStrings = [String:String]()
    //
    //    var htmlString:String? {
    //        get {
    //            return index != nil ? htmlStrings[index!] : nil
    //        }
    //        set {
    //            if index != nil {
    //                htmlStrings[index!] = newValue
    //            }
    //        }
    //    }
    //
    //    var index:String? {
    //        get {
    //            var index:String?
    //
    //            if let selectedTestament = self.selectedTestament {
    //                index = selectedTestament
    //            }
    //
    //            if index != nil, let selectedBook = self.selectedBook {
    //                index = index! + ":" + selectedBook
    //            }
    //
    //            if index != nil, selectedChapter > 0 {
    //                index = index! + ":\(selectedChapter)"
    //            }
    //
    //            if index != nil, selectedVerse > 0 {
    //                index = index! + ":\(selectedVerse)"
    //            }
    //
    //            return index
    //        }
    //    }
    
    var sorted = [String:Bool]()
    
    //Test
    var byTestament = [String:[MediaItem]]()
    
    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()
    
    var selectedTestament:String? = Constants.OT
    
    var selectedBook:String? {
        didSet {
            if selectedBook == nil {
                selectedChapter = 0
                selectedVerse = 0
            }
        }
    }
    
    var selectedChapter:Int = 0 {
        didSet {
            if selectedChapter == 0 {
                selectedVerse = 0
            }
        }
    }
    
    var selectedVerse:Int = 0
    
    var eligible:[MediaItem]? {
        get {
            if let list = mediaListGroupSort?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.books != nil
            }), list.count > 0 {
                return list
            } else {
                return nil
            }
        }
    }
    
    func build()
    {
        guard !completed else {
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            })
            return
        }
        
        guard !creating else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            //            self.progress = 0
            //            self.finished = 0
            self.creating = true
            
            if let list = self.mediaListGroupSort?.list {
                //                self.finished += Float(self.list!.count)
                
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self)
                })
                
                for mediaItem in list {
                    if globals.isRefreshing || globals.isLoading {
                        break
                    }
                    
                    let booksChaptersVerses = mediaItem.booksAndChaptersAndVerses()
                    if let books = booksChaptersVerses?.data?.keys {
                        //                        self.finished += Float(mediaItem.books!.count)
                        for book in books {
                            if globals.isRefreshing || globals.isLoading {
                                break
                            }
                            
                            //                            print("\(mediaItem)")
                            if self.byTestament[testament(book)] != nil {
                                if !self.byTestament[testament(book)]!.contains(mediaItem) {
                                    self.byTestament[testament(book)]?.append(mediaItem)
                                }
                            } else {
                                self.byTestament[testament(book)] = [mediaItem]
                            }
                            
                            if self.byBook[testament(book)] == nil {
                                self.byBook[testament(book)] = [String:[MediaItem]]()
                            }
                            if self.byBook[testament(book)]?[book] != nil {
                                if !self.byBook[testament(book)]![book]!.contains(mediaItem) {
                                    self.byBook[testament(book)]?[book]?.append(mediaItem)
                                }
                            } else {
                                self.byBook[testament(book)]?[book] = [mediaItem]
                            }
                            
                            if let chapters = booksChaptersVerses?[book]?.keys {
                                //                                self.finished += Float(chapters.count)
                                for chapter in chapters {
                                    if globals.isRefreshing || globals.isLoading {
                                        break
                                    }
                                    
                                    if self.byChapter[testament(book)] == nil {
                                        self.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self.byChapter[testament(book)]?[book] == nil {
                                        self.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
                                    }
                                    if self.byChapter[testament(book)]?[book]?[chapter] != nil {
                                        if !self.byChapter[testament(book)]![book]![chapter]!.contains(mediaItem) {
                                            self.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
                                        }
                                    } else {
                                        self.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
                                    }
                                    
                                    if let verses = booksChaptersVerses?[book]?[chapter] {
                                        //                                        self.finished += Float(verses.count)
                                        for verse in verses {
                                            if globals.isRefreshing || globals.isLoading {
                                                break
                                            }
                                            
                                            if self.byVerse[testament(book)] == nil {
                                                self.byVerse[testament(book)] = [String:[Int:[Int:[MediaItem]]]]()
                                            }
                                            if self.byVerse[testament(book)]?[book] == nil {
                                                self.byVerse[testament(book)]?[book] = [Int:[Int:[MediaItem]]]()
                                            }
                                            if self.byVerse[testament(book)]?[book]?[chapter] == nil {
                                                self.byVerse[testament(book)]?[book]?[chapter] = [Int:[MediaItem]]()
                                            }
                                            if self.byVerse[testament(book)]?[book]?[chapter]?[verse] != nil {
                                                if !self.byVerse[testament(book)]![book]![chapter]![verse]!.contains(mediaItem) {
                                                    self.byVerse[testament(book)]?[book]?[chapter]?[verse]?.append(mediaItem)
                                                }
                                            } else {
                                                self.byVerse[testament(book)]?[book]?[chapter]?[verse] = [mediaItem]
                                            }
                                            
                                            //                                            self.progress += 1
                                        }
                                    }
                                    
                                    //                                    self.progress += 1
                                }
                            }
                            
                            //                            self.progress += 1
                        }
                    }
                    
                    //                    self.progress += 1
                }
            }

            self.creating = false
            self.completed = true
            
            if let selectedTestament = self.selectedTestament {
                let testament = translateTestament(selectedTestament)
                
                switch selectedTestament {
                case Constants.OT:
                    if (self.byTestament[testament] == nil) {
                        self.selectedTestament = Constants.NT
                    }
                    break
                    
                case Constants.NT:
                    if (self.byTestament[testament] == nil) {
                        self.selectedTestament = Constants.OT
                    }
                    break
                    
                default:
                    break
                }
            }

            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self)
            })

            //            self.updateSearchResults()
        })
    }
}

//Group//String//Sort
typealias MediaGroupSort = [String:[String:[String:[MediaItem]]]]

//Group//String//Name
typealias MediaGroupNames = [String:[String:String]]

class StringNode {
    var string:String?
    
    init(_ string:String?)
    {
        self.string = string
    }
    
    var wordEnding = false
    
    var stringNodes:[StringNode]?
    
    var isLeaf:Bool {
        get {
            return stringNodes == nil
        }
    }
    
    func depthBelow(_ cumulative:Int) -> Int
    {
        if isLeaf {
            return cumulative
        } else {
            var depthsBelow = [Int]()
            
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                depthsBelow.append(stringNode.depthBelow(cumulative + 1))
            }
            
            if let last = depthsBelow.sorted().last {
//                print(depthsBelow)
//                print(depthsBelow.sorted())
//                print("\n")
                return last
            } else {
                return 0
            }
        }
    }
    
    func printStrings(_ cumulativeString:String?)
    {
//        guard string != nil else {
//            return
//        }
        
        if string != nil {
            print(string!)
        }
        
//        if wordEnding {
//            print("\n")
//        }
        
        guard stringNodes != nil else {
            return
        }
        
        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
            if let string = stringNode.string {
                print(string,"\n")
            } else {
                print("NO STRING!\n")
            }
        }

        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
            if cumulativeString != nil {
                if string != nil {
                    stringNode.printStrings(cumulativeString!+string!+"-")
                } else {
                    stringNode.printStrings(cumulativeString!+"-")
                }
            } else {
                if string != nil {
                    stringNode.printStrings(string!+"-")
                } else {
                    stringNode.printStrings(nil)
                }
            }
        }
    }
    
    func printWords(_ cumulativeString:String?)
    {
        //        guard string != nil else {
        //            return
        //        }
        
        if wordEnding {
            if cumulativeString != nil {
                if string != nil {
                    print(cumulativeString!+string!)
                } else {
                    print(cumulativeString!)
                }
            } else {
                if string != nil {
                    print(string!)
                }
            }
            
            //            print("\n")
        }
        
        guard stringNodes != nil else {
            return
        }
        
        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
            //            print(string!+"-")
            if cumulativeString != nil {
                if string != nil {
                    stringNode.printWords(cumulativeString!+string!+"-")
                } else {
                    stringNode.printWords(cumulativeString!+"-")
                }
            } else {
                if string != nil {
                    stringNode.printWords(string!+"-")
                } else {
                    stringNode.printWords(nil)
                }
            }
        }
    }
    
//    func htmlWords(_ cumulativeString:String?,htmlString:String?) -> String?
//    {
//        //        guard string != nil else {
//        //            return
//        //        }
//        
//        var newHTMLString:String?
//        
//        if wordEnding {
//            if cumulativeString != nil {
//                if string != nil {
//                    newHTMLString = htmlString! + "<tr>" + cumulativeString! + string! + "</tr>"
//                } else {
//                    newHTMLString = htmlString! + "<tr>" + cumulativeString! + "</tr>"
//                }
//            } else {
//                if string != nil {
//                    newHTMLString = htmlString! + "<tr>" + string! + "</tr>"
//                }
//            }
//        } else {
//            if cumulativeString != nil {
//                if string != nil {
//                    newHTMLString = htmlString! + "<tr>" + cumulativeString! + string! + "</tr>"
//                } else {
//                    newHTMLString = htmlString! + "<tr>" + cumulativeString! + "</tr>"
//                }
//            } else {
//                if string != nil {
//                    newHTMLString = htmlString! + "<tr>" + string! + "</tr>"
//                }
//            }
//        }
//        
//        guard stringNodes != nil else {
//            return newHTMLString
//        }
//        
//        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
//            //            print(string!+"-")
//            if cumulativeString != nil {
//                if string != nil {
//                    newHTMLString = stringNode.htmlWords(cumulativeString! + "<td>" + string! + "</td>",htmlString: newHTMLString)
//                } else {
//                    newHTMLString = stringNode.htmlWords(cumulativeString! + "<td></td>",htmlString: newHTMLString)
//                }
//            } else {
//                if string != nil {
//                    newHTMLString = stringNode.htmlWords("</td>" + string! + "</td>",htmlString: newHTMLString)
//                } else {
//                    newHTMLString = stringNode.htmlWords("<td></td>",htmlString: newHTMLString)
//                }
//            }
//        }
//        
//        return newHTMLString
//    }
    
//    func htmlWords(_ cumulativeHTML:String?) -> String?
//    {
//        //        guard string != nil else {
//        //            return
//        //        }
//
//        var html:String?
//        
//        if wordEnding {
//            if cumulativeHTML != nil {
//                if string != nil {
//                    html = cumulativeHTML! + string! + "</td></tr>"
//                } else {
//                    html = cumulativeHTML! + "</tr>"
//                }
//            } else {
//                if string != nil {
//                    html = "<tr><td>" + string! + "</td></tr>"
//                } else {
//                    // This means both the cumulative string and string are nil, i.e. root.
//                }
//            }
//        } else {
//            if cumulativeHTML != nil {
//                if string != nil {
//                    html = cumulativeHTML! + string!
//                }
//            } else {
//                if string != nil {
//                    html = string
//                }
//            }
//        }
//        
//        guard stringNodes != nil else {
//            if html != nil {
//                if wordEnding {
//                    return html
//                } else {
//                    // THIS SHOULD NEVER HAPPEN.
//                    return html! + "</tr>"
//                }
//            } else {
//                return nil
//            }
//        }
//        
//        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
//            //            print(string!+"-")
//            if let string = stringNode.htmlWords(html) {
//                html = html != nil ? html! + string : string
//            }
//        }
//        
//        return html
//    }
    
    func addStringNode(_ newString:String?)
    {
        guard (newString != nil) else {
            return
        }

        guard (stringNodes != nil) else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            stringNodes = [newNode]
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            return
        }

        var fragment = newString
        
        var foundNode:StringNode?
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                if stringNode.string?.endIndex >= fragment!.endIndex, stringNode.string?.substring(to: fragment!.endIndex) == fragment {
                    foundNode = stringNode
                    break
                }
            }
            
            if foundNode != nil {
                break
            }
            
            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))
            
            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if foundNode != nil {
            foundNode?.addString(newString)
        } else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            stringNodes?.append(newNode)
        }
    }
    
    func addString(_ newString:String?)
    {
        guard let stringEmpty = newString?.isEmpty, !stringEmpty else {
            return
        }

        guard (string != nil) else {
            addStringNode(newString)
            return
        }
        
        guard (string != newString) else {
            wordEnding = true
            
            var found = false
            
            if var stringNodes = stringNodes {
                for stringNode in stringNodes {
                    if stringNode.string == Constants.WORD_ENDING {
                        found = true
                        break
                    }
                }
                
                if !found {
                    stringNodes.append(StringNode(Constants.WORD_ENDING))
                }
            } else {
                stringNodes = [StringNode(Constants.WORD_ENDING)]
            }
            
            return
        }
        
        var fragment = newString
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            if string?.endIndex >= fragment!.endIndex, string?.substring(to: fragment!.endIndex) == fragment {
                break
            }

            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))

            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if !isEmpty {
            let stringRemainder = string?.substring(from: fragment!.endIndex)

            let newStringRemainder = newString?.substring(from: fragment!.endIndex)
            
            if let isEmpty = stringRemainder?.isEmpty, !isEmpty {
                let newNode = StringNode(stringRemainder)
                newNode.stringNodes = stringNodes
                
                newNode.wordEnding = wordEnding
                
                if !wordEnding, let index = stringNodes?.index(where: { (stringNode:StringNode) -> Bool in
                    return stringNode.string == Constants.WORD_ENDING
                }) {
                    stringNodes?.remove(at: index)
                }
                
                wordEnding = false
                
                string = fragment
                stringNodes = [newNode]
            }
            
            if let isEmpty = newStringRemainder?.isEmpty, !isEmpty {
                addStringNode(newStringRemainder)
            } else {
                wordEnding = true
            }
        } else {
            // No match!?!?!
        }
    }
    
    func addStrings(_ strings:[String]?)
    {
        guard strings != nil else {
            return
        }
        
        for string in strings! {
            addString(string)
        }
    }
}

typealias Words = [String:[MediaItem:Int]]

class StringTree {
    weak var lexicon:Lexicon!
    
    init(lexicon:Lexicon?)
    {
        self.lexicon = lexicon
    }
    
    lazy var root:StringNode! = {
        return StringNode(nil)
    }()
    
    var building = false
    var completed = false

    func build()
    {
        guard !building else {
            return
        }
        
        building = true
        
        DispatchQueue.global(qos: .background).async {
            self.root = StringNode(nil)
            self.root.addStrings(self.lexicon.tokens)
            
            self.building = false
            self.completed = true
            
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.lexicon)
            })
        }
    }
}

class Lexicon : NSObject {
    weak var mediaListGroupSort:MediaListGroupSort?
    
    init(_ mlgs:MediaListGroupSort?){
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
        didSet {
            var strings = [String]()
            
            if let keys = self.words?.keys.sorted() {
                for word in keys {
                    if let count = self.words?[word]?.count {
                        strings.append("\(word) (\(count))")
                    }
                }
            }
            
            section.strings = strings
            
            section.indexStrings = section.strings?.map({ (string:String) -> String in
                return string.uppercased()
            })
            
            //            print(tokens)
            //            print(gcr)
            //            print(gcw)
            
            //            if let strings = self.strings {
            //                let array = Array(Set(strings))
            //
            //            }
            
//            print("Before section.build: ",Date())
            self.section.build()
            
//            print("Before buildStringTree: ",Date())
//            DispatchQueue.global(qos: .background).async {
//                self.buildStringTree()
//            }
//            print("After buildStringTree: ",Date())
            
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self)
            })
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
                words!.flatMap({ (tuple:(key: String, value: [MediaItem : Int])) -> [MediaItem] in
                    // .map is required below to return an array of MediaItem, otherwise it returns a LazyMapCollection and I haven't figured that out.
                    return tuple.value.keys.map({ (mediaItem:MediaItem) -> MediaItem in
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
    
    func occurences(_ word:String?) -> Int? // nil => not found
    {
        guard word != nil else {
            return nil
        }
        
        return words?[word!]?.values.map({ (count:Int) -> Int in
            return count
        }).reduce(0, +)
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
        
        if let list = eligible {
            creating = true
            
            DispatchQueue.global(qos: .background).async {
                var dict = Words()
                
                var date = Date()
                
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self)
                })
                
                for mediaItem in list {
                    if mediaItem.hasNotesHTML {
                        mediaItem.loadNotesTokens()
                        
                        if let notesTokens = mediaItem.notesTokens {
                            for token in notesTokens {
                                if dict[token.0] == nil {
                                    dict[token.0] = [mediaItem:token.1]
                                } else {
                                    dict[token.0]?[mediaItem] = token.1
                                }

                                if globals.isRefreshing || globals.isLoading {
                                    break
                                }
                            }
                        }
                        
                        if globals.isRefreshing || globals.isLoading {
                            break
                        }
                        
                        //                        var strings = [String]()
                        //
                        //                        let words = dict.keys.sorted()
                        //                        for word in words {
                        //                            if let count = dict[word]?.count {
                        //                                strings.append("\(word) (\(count))")
                        //                            }
                        //                        }
                        
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
                }
                
                self.words = dict.count > 0 ? dict : nil
                
                self.creating = false
                
                if !globals.isRefreshing && !globals.isLoading {
                    self.completed = true
                }

//                print(self.root.depthBelow(0))
                
//                self.mediaListGroupSort?.lexicon?.addStrings(self.mediaListGroupSort?.lexicon?.tokens)
//                self.mediaListGroupSort?.lexicon?.root.printStrings(nil)
//                self.mediaListGroupSort?.lexicon?.root.printWords(nil)
//
//                print(self.mediaListGroupSort?.lexicon?.tokens)
//                print(self.mediaListGroupSort?.lexicon?.gcw)
//                print(self.mediaListGroupSort?.lexicon?.gcr)

                //        print(dict)
                DispatchQueue(label: "CBC").async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self)
                })
            }
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
                        if dict[token.0] == nil {
                            dict[token.0] = [mediaItem:token.1]
                        } else {
                            dict[token.0]?[mediaItem] = token.1
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
                        if first.1 == second.1 {
                            return first.0.fullDate!.isOlderThan(second.0.fullDate!)
                        } else {
                            return first.1 > second.1
                        }
                    }) {
                        for mediaItem in mediaItems {
                            string = string + "(\(mediaItem.0,mediaItem.1))\n"
                        }
                    }
                }
            }
            
            return string
        }
    }
}


class MediaListGroupSort {
    @objc func freeMemory()
    {
        lexicon = nil
        
        guard searches != nil else {
            return
        }
        
        if !globals.search.active {
            searches = nil
        } else {
            // Is this risky, to try and delete all but the current search?
            if let keys = searches?.keys {
                for key in keys {
                    //                    print(key,globals.search.text)
                    if key != globals.search.text {
                        searches?[key] = nil
                    } else {
                        //                        print(key,globals.search.text)
                    }
                }
            }
        }
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: globals.contextOrder)
    }()
    
    var list:[MediaItem]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:MediaItem]()
                
                for mediaItem in list! {
                    index![mediaItem.id!] = mediaItem
                    
                    if let className = mediaItem.className {
                        if classes == nil {
                            classes = [className]
                        } else {
                            classes?.append(className)
                        }
                    }
                    
                    if let eventName = mediaItem.eventName {
                        if events == nil {
                            events = [eventName]
                        } else {
                            events?.append(eventName)
                        }
                    }
                }
            }
        }
    }
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    var classes:[String]?
    var events:[String]?
    
    lazy var lexicon:Lexicon? = {
        [unowned self] in
        return Lexicon(self)
    }()
    
    var searches:[String:MediaListGroupSort]? // Hierarchical means we could search within searches - but not right now.
    
    lazy var scriptureIndex:ScriptureIndex? = {
        [unowned self] in
        return ScriptureIndex(self)
    }()
    
    var groupSort:MediaGroupSort?
    var groupNames:MediaGroupNames?
    
    var tagMediaItems:[String:[MediaItem]]?//sortTag:MediaItem
    var tagNames:[String:String]?//sortTag:tag
    
    var proposedTags:[String]? {
        get {
            var possibleTags = [String:Int]()
            
            if let tags = mediaItemTags {
                for tag in tags {
                    var possibleTag = tag
                    
                    if possibleTag.range(of: "-") != nil {
                        while possibleTag.range(of: "-") != nil {
                            let range = possibleTag.range(of: "-")
                            
                            let candidate = possibleTag.substring(to: range!.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }

                            possibleTag = possibleTag.substring(from: range!.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        if !possibleTag.isEmpty {
                            let candidate = possibleTag.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }
                        }
                    }
                }
            }
            
            let proposedTags:[String] = possibleTags.keys.map { (string:String) -> String in
                return string
            }
            return proposedTags.count > 0 ? proposedTags : nil
        }
    }
    
    var mediaItemTags:[String]? {
        get {
            return tagMediaItems?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                return self.tagNames![string]!
            })
        }
    }
    
    var mediaItems:[MediaItem]? {
        get {
            return mediaItems(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        guard (list != nil) else {
            return
        }
        
        //        var strings:[String]?
        //        var names:[String]?
        
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
//        globals.finished += list!.count
        
        for mediaItem in list! {
            var entries:[(string:String,name:String)]?
            
            switch grouping! {
            case Grouping.YEAR:
                entries = [(mediaItem.yearString,mediaItem.yearString)]
                break
                
            case Grouping.TITLE:
                entries = [(mediaItem.multiPartSectionSort,mediaItem.multiPartSection)]
                break
                
            case Grouping.BOOK:
                // Need to update this for the fact that mediaItems can have more than one book.
                if let books = mediaItem.books {
                    for book in books {
                        if entries == nil {
                            entries = [(book,book)]
                        } else {
                            entries?.append((book,book))
                        }
                    }
                }
                if entries == nil {
                    if let scriptureReference = mediaItem.scriptureReference?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                        entries = [(scriptureReference,scriptureReference)]
                    } else {
                        entries = [(Constants.None,Constants.None)]
                    }
                }
                //                if entries?.count > 1 {
                //                    print(mediaItem,entries!)
                //                }
                break
                
            case Grouping.SPEAKER:
                entries = [(mediaItem.speakerSectionSort,mediaItem.speakerSection)]
                break
                
            case Grouping.CLASS:
                entries = [(mediaItem.classSectionSort,mediaItem.classSection)]
                break
                
            case Grouping.EVENT:
                entries = [(mediaItem.eventSectionSort,mediaItem.eventSection)]
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping!] == nil) {
                groupNames?[grouping!] = [String:String]()
            }
            
            if entries != nil {
                for entry in entries! {
                    groupNames?[grouping!]?[entry.string] = entry.name
                    
                    if (groupedMediaItems[grouping!] == nil) {
                        groupedMediaItems[grouping!] = [String:[MediaItem]]()
                    }
                    
                    if groupedMediaItems[grouping!]?[entry.string] == nil {
                        groupedMediaItems[grouping!]?[entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping!]?[entry.string]?.append(mediaItem)
                    }
                    
//                    globals.progress += 1
                }
            }
        }
        
//        if (groupedMediaItems[grouping!] != nil) {
//            globals.finished += groupedMediaItems[grouping!]!.keys.count
//        }
        
        if (groupSort?[grouping!] == nil) {
            groupSort?[grouping!] = [String:[String:[MediaItem]]]()
        }
        if (groupedMediaItems[grouping!] != nil) {
            for string in groupedMediaItems[grouping!]!.keys {
                if (groupSort?[grouping!]?[string] == nil) {
                    groupSort?[grouping!]?[string] = [String:[MediaItem]]()
                }
                for sort in Constants.sortings {
                    let array = sortMediaItemsChronologically(groupedMediaItems[grouping!]?[string])
                    
                    switch sort {
                    case Sorting.CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array
                        break
                        
                    case Sorting.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array?.reversed()
                        break
                        
                    default:
                        break
                    }
                    
//                    globals.progress += 1
                }
            }
        }
    }
    
    func mediaItems(grouping:String?,sorting:String?) -> [MediaItem]?
    {
        var groupedSortedMediaItems:[MediaItem]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sorted(
                by: {
                    switch grouping! {
                    case Grouping.YEAR:
                        switch sorting! {
                        case Sorting.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Sorting.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case Grouping.BOOK:
                        if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                        } else {
                            return bookNumberInBible($0) < bookNumberInBible($1)
                        }
                        
//                    case Grouping.SPEAKER:
//                        return $0 < $1
//                        
//                    case Grouping.TITLE:
//                        return $0.lowercased() < $1.lowercased()
                        
                    default:
                        return $0.lowercased() < $1.lowercased()
                    }
                    
                    return $0 < $1
            }) {
                let mediaItems = groupSort?[grouping!]?[key]?[sorting!]
                
                if (groupedSortedMediaItems == nil) {
                    groupedSortedMediaItems = mediaItems
                } else {
                    groupedSortedMediaItems?.append(contentsOf: mediaItems!)
                }
            }
        }
        
        return groupedSortedMediaItems
    }
    
    struct Section {
        weak var mlgs:MediaListGroupSort?
        
        init(_ mlgs:MediaListGroupSort?)
        {
            self.mlgs = mlgs
        }
        
        var titles:[String]? {
            get {
                return mlgs?.sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var counts:[Int]? {
            get {
                return mlgs?.sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexes:[Int]? {
            get {
                return mlgs?.sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexTitles:[String]? {
            get {
                return mlgs?.sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
    }
    
    lazy var section:Section? = {
        [unowned self] in
        return Section(self)
        }()
    
    //    var sectionIndexTitles:[String]? {
    //        get {
    //            return sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    //
    //    var sectionTitles:[String]? {
    //        get {
    //            return sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    //
    //    var sectionCounts:[Int]? {
    //        get {
    //            return sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
    //        }
    //    }
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        })
    }
    
    func sectionTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return sectionIndexTitles(grouping: grouping,sorting: sorting)?.map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            return groupSort![grouping!]![string]![sorting!]!.count
        })
    }
    
    var sectionIndexes:[Int]? {
        get {
            return sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        var cumulative = 0
        
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            cumulative += groupSort![grouping!]![string]![sorting!]!.count
            
            return prior
        })
    }
    
    init(mediaItems:[MediaItem]?)
    {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaListGroupSort.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        guard (mediaItems != nil) else {
            //            globals.finished = 1
            //            globals.progress = 1
            return
        }
        
//        globals.finished = 0
//        globals.progress = 0
        
        list = mediaItems
        
        groupNames = MediaGroupNames()
        groupSort = MediaGroupSort()
        
        sortGroup(globals.grouping)
        
//        globals.finished += list!.count

        tagMediaItems = [String:[MediaItem]]()
        tagNames = [String:String]()

        for mediaItem in list! {
            if let tags =  mediaItem.tagsSet {
                for tag in tags {
                    let sortTag = stringWithoutPrefixes(tag)
                    
                    if sortTag == "" {
                        print(sortTag)
                    }

                    if tagMediaItems?[sortTag!] == nil {
                        tagMediaItems?[sortTag!] = [mediaItem]
                    } else {
                        tagMediaItems?[sortTag!]?.append(mediaItem)
                    }
                    tagNames?[sortTag!] = tag
                }
            }
//            globals.progress += 1
        }
    }
}

