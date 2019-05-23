//
//  Section.swift
//  CBC
//
//  Created by Steve Leeke on 8/14/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

/**
 Class for handling sections in tableView for PopoverTableViewController(Protocol).
 */
class Section
{
    var sorting = false
    {
        didSet {
//            Thread.onMainThread {
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SORTING_CHANGED), object: self.tableView)
//            }
            if !sorting {
                stringsAction?(strings,sorting)
            }
        }
    }
    
    // What is this use for?
    var cancelSearchfunction : ((String?,[String]?)->[String]?)?
    {
        willSet {
            
        }
        didSet {
            
        }
    }
 
    // Why is this just called function?
    var function : ((String?,[String]?)->[String]?)?
    {
        willSet {
            
        }
        didSet {
            
        }
    }
    
    var method : String? = Constants.Sort.Alphabetical
    {
        willSet {
            
        }
        didSet {
            
        }
    }
    
    // Gets called in the didSet for strings
    var stringsAction : (([String]?,Bool) -> (Void))?
    
    init(tableView : UITableView?,stringsAction : (([String]?,Bool) -> (Void))?)
    {
        self.tableView = tableView
        self.stringsAction = stringsAction
    }
    
    func clear()
    {
        headerStrings = nil
        indexStrings = nil
        indexes = nil
        counts = nil
    }
    
    deinit {
        debug(self)
    }
    
    // Given a string returns the indexPath
    // THIS MUST MAKE ASSUMPTIONS ABOUT DUPLICATE STRINGS
    // LIKE RETURNING THE INDEXPATH TO THE FIRST FOUND
    func indexPath(from string:String?) -> IndexPath?
    {
        guard let indexes = self.indexes else {
            return nil
        }
        
        guard let counts = self.counts else {
            return nil
        }
        
        guard counts.count == indexes.count else {
            return nil
        }
        
        guard var string = string else {
            return nil
        }
        
        if let range = string.range(of: " (") {
            string = String(string[..<range.lowerBound]) //.uppercased()
        }
        
        guard let index = strings?.firstIndex(where: { (str:String) -> Bool in
            var match = str
            
            if let range = str.range(of: " (") {
                match = String(str[..<range.lowerBound]) //.uppercased()
            }
            
            return match == string
        }) else {
            return nil
        }
        
        if counts.count == indexes.count {
            var section = 0
            
            while index >= (indexes[section] + counts[section]) {
                section += 1
            }
            
            let row = index - indexes[section]
            
            return IndexPath(row: row, section: section)
        }
        
        return nil
    }
    
    // Returns the string for a given IndexPath
    func string(from indexPath:IndexPath) -> String?
    {
        return strings?[index(indexPath)]
    }
    
    // Given an IndexPath returns the index into the array of strings
    func index(_ indexPath:IndexPath) -> Int
    {
        var index = 0
        
        if showIndex || showHeaders {
            if indexPath.section >= 0, indexPath.section < indexes?.count {
                if let sectionIndex = indexes?[indexPath.section] {
                    index = sectionIndex + indexPath.row
                }
            }
        } else {
            index = indexPath.row
        }
        
        return index
    }
    
    // So the section can manipulate the tableView
    weak var tableView : UITableView?
    
    // Created problems.  Didn't solve any.
//    var useInsertions = false
//    var insertions : [IndexPath]?
//    {
//        didSet {
//            guard useInsertions else { // This is probably never true.
//                return
//            }
//
//            guard let insertions = insertions else {
//                return
//            }
//            Thread.onMainThread {
//                self.tableView?.insertRows(at: insertions, with: .automatic)
//            }
//        }
//    }
    
    // Make thread safe?
    // Where is this used instead of strings?
    // Why was it created?
    var stringIndex:[String:[String]]?
    {
//        willSet {
//            guard !sorting else {
//                return
//            }
//
//            var insertions = [IndexPath]()
//
//            guard var newStringIndex = newValue else {
//                return
//            }
//
//            guard let stringIndex = stringIndex else {
//                let newSections = Array(newStringIndex.keys)
//
//                for newSection in 0..<newSections.count {
//                    let indexPath = IndexPath(row: 0, section: newSection)
//                    insertions.append(indexPath)
//                    if let newRows = newStringIndex[newSections[newSection]] {
//                        for newRow in 0..<newRows.count {
//                            let indexPath = IndexPath(row: newRow, section: newSection)
//                            insertions.append(indexPath)
//                        }
//                    }
//                }
//                self.insertions = insertions.count > 0 ? insertions : nil
//                return
//            }
//
//            let sections = Array(stringIndex.keys)
//
//            let newSections = Array(newStringIndex.keys)
//
//            // Assumption is that strings are a strict superset
//            for section in 0..<sections.count {
//                if sections[section] != newSections[section] {
//                    let indexPath = IndexPath(row: 0, section: section)
//                    insertions.append(indexPath)
//                    if let newRows = newStringIndex[newSections[section]] {
//                        for newRow in 0..<newRows.count {
//                            let indexPath = IndexPath(row: newRow, section: section)
//                            insertions.append(indexPath)
//                        }
//                        newStringIndex[newSections[section]] = nil
//                    }
//                    continue
//                }
//
//                guard let rows = stringIndex[sections[section]] else {
//                    continue
//                }
//
//                for row in 0..<rows.count {
//                    // need a stringsComparison function to strip frequency counts for lexicon updates
//                    if stringIndex[sections[section]]?[row] != newStringIndex[sections[section]]?[row] {
//                        let indexPath = IndexPath(row: row, section: section)
//                        insertions.append(indexPath)
//                        newStringIndex[sections[section]]?.remove(at: row)
//                    }
//                }
//            }
//
//            self.insertions = insertions.count > 0 ? insertions : nil
//        }
        
        didSet {
            var counter = 0
            
            var counts = [Int]()
            var indexes = [Int]()
            
            var strings = [String]()
            
            if let keys = stringIndex?.keys.sorted() {
                for key in keys {
                    indexes.append(counter)
                    
                    if let count = self.stringIndex?[key]?.count {
                        counts.append(count)
                        counter += count
                    }
                    
                    if let values = self.stringIndex?[key] {
                        for value in values {
                            strings.append(value)
                        }
                    }
                }
            }
            
            // This is a hack that doesn't provide any thread safety.
            self.strings = strings.count > 0 ? strings : nil
            self.headerStrings = stringIndex?.keys.sorted()
            self.counts = counts.count > 0 ? counts : nil
            self.indexes = indexes.count > 0 ? indexes : nil
        }
    }
    
    // Make thread safe?
    var strings:[String]?
    {
//        willSet {
//            guard !sorting else {
//                return
//            }
//            
//            var insertions = [IndexPath]()
//            
//            guard var newStrings = newValue else {
//                return
//            }
//            
//            // Assumption is that strings are a strict superset
//            guard newStrings.count > strings?.count else {
//                return
//            }
//            
//            guard let strings = strings else {
//                for index in 0..<newStrings.count {
//                    // need a stringsComparison function to strip frequency counts for lexicon updates
//                    let indexPath = IndexPath(row: index, section: 0)
//                    insertions.append(indexPath)
//                }
//                self.insertions = insertions.count > 0 ? insertions : nil
//                return
//            }
//            
//            for index in 0..<strings.count {
//                // need a stringsComparison function to strip frequency counts for lexicon updates
//                if strings[index].components(separatedBy: " ").first != newStrings[index].components(separatedBy: " ").first {
//                    let indexPath = IndexPath(row: index, section: 0)
//                    insertions.append(indexPath)
//                    newStrings.remove(at: index)
//                }
//            }
//            self.insertions = insertions.count > 0 ? insertions : nil
//        }
        
        didSet {
            stringsAction?(strings,sorting)
            
            guard let strings = strings else {
                counts = nil
                indexes = nil
                headerStrings = nil
                indexStrings = nil
                return
            }
            
            guard showIndex else {
                counts = [strings.count]
                indexes = [0]
                return
            }
            
            indexStrings = strings.map({ (string:String) -> String in
                return indexStringsTransform?(string.uppercased()) ?? string.uppercased()
            })
        }
    }
    
    // Make it thread safe?
//    lazy var queue : DispatchQueue = { [weak self] in
//        return DispatchQueue(label: UUID().uuidString)
//    }()
//    
//    var strings:[String]?
//    {
//        get {
//            return queue.sync {
//                return _strings
//            }
//        }
//        set {
//            queue.sync {
//                _strings = newValue
//            }
//        }
//    }

    var showIndex = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }
    
    // Make thread safe?
    // These are what is actually shown in the index?
    var indexHeaders:[String]?
    
    // Make thread safe?
    // These are how the strings are indexed?
    var indexStrings:[String]?
    {
        didSet {
            guard showIndex else {
                return
            }
            
            guard let strings = strings, strings.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            guard let indexStrings = indexStrings, indexStrings.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            let a = "A"
            
            if let indexHeadersTransform = indexHeadersTransform {
                indexHeaders = Array(Set(
                    indexStrings.compactMap({ (string:String) -> String? in
                        return indexHeadersTransform(string)
                    })
                ))
            } else {
                indexHeaders = Array(Set(indexStrings
                    .map({ (string:String) -> String in
                        if string.count >= a.count {
                            return String(string[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
                        } else {
                            return string
                        }
                    })
                ))
            }
            
            if let indexSort = indexSort {
                indexHeaders = indexHeaders?.sorted(by: {
                    return indexSort($0,$1)
                })
            } else {
                indexHeaders = indexHeaders?.sorted()
            }
            
            if indexHeaders?.count == 0 {
                indexHeaders = nil
                counts = nil
                indexes = nil
            } else {
                var stringIndex = [String:[String]]()
                
                for indexString in indexStrings {
                    var header : String?
                    
                    if indexHeadersTransform == nil {
                        if indexString.count >= a.count { // endIndex
                            header = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)])
                        }
                    } else {
                        header = indexHeadersTransform?(indexString)
                    }
                    
                    if let header = header {
                        if stringIndex[header] == nil {
                            stringIndex[header] = [String]()
                        }
                        stringIndex[header]?.append(indexString)
                    }
                }
                
                var counter = 0
                
                var counts = [Int]()
                var indexes = [Int]()
                var keys = [String]()
                
                if let indexSort = indexSort {
                    keys = stringIndex.keys.sorted(by: {
                        return indexSort($0,$1)
                    })
                } else {
                    keys = stringIndex.keys.sorted()
                }
                
                for key in keys {
                    if let segment = stringIndex[key] {
                        indexes.append(counter)
                        counts.append(segment.count)
                        
                        counter += segment.count
                    }
                }
                
                self.counts = counts.count > 0 ? counts : nil
                self.indexes = indexes.count > 0 ? indexes : nil
                
                if self.counts?.count != self.indexes?.count {
                    print("counts.count != indexes.count")
                }
            }
        }
    }
    
    // Getting from strings to indexStrings use this?
    var indexStringsTransform:((String?)->String?)?
    
    // Getting from indexStrings to headerStrings use this?
    var indexHeadersTransform:((String?)->String?)?
    
    // How to sort the index (and therefore the headers)
    var indexSort:((String?,String?)->Bool)?
    
    var showHeaders = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }
    
    // What is the difference between headerStrings and headers?
    // They are both string arrays.
    
    // THe difference is that headers is the front for choosing between
    // headerStrings and indexHeaders as headers.
    
    // Make thread safe?
    var headerStrings:[String]?
    
    // Make thread safe?
    var headers:[String]?
    {
        get {
            // CANNOT show both headers and index.
            // By implication if only the index is shown
            // the headers shown become the first letter
            // of the indexStrings?
            if showHeaders && showIndex {
                print("ERROR: showIndex && showHeaders")
                return nil
            }
            
            if showHeaders {
                return headerStrings
            }
            
            if showIndex {
                return indexHeaders
            }
            
            return nil
        }
    }
    
    // Make thread safe?
    var counts:[Int]?
    var indexes:[Int]?
}
