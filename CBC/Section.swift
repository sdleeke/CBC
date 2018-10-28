//
//  Section.swift
//  CBC
//
//  Created by Steve Leeke on 8/14/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class Section
{
    var stringsAction : (([String]?) -> (Void))?
    
    init(stringsAction : (([String]?) -> (Void))?)
    {
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
        
    }
    
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
        
        guard let index = strings?.index(where: { (str:String) -> Bool in
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
    
    func string(from indexPath:IndexPath) -> String?
    {
        return strings?[index(indexPath)]
    }
    
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
    
    // Make thread safe?
    var stringIndex:[String:[String]]?
    {
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
            
            self.strings = strings.count > 0 ? strings : nil
            self.headerStrings = stringIndex?.keys.sorted()
            self.counts = counts.count > 0 ? counts : nil
            self.indexes = indexes.count > 0 ? indexes : nil
        }
    }
    
    // Make thread safe?
    var strings:[String]?
    {
        willSet {
            
        }
        didSet {
            stringsAction?(strings)
            
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
    
    var showIndex = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }

    // Make thread safe?
    var indexHeaders:[String]?

    // Make thread safe?
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
                        if string.endIndex >= a.endIndex {
                            return String(string[..<a.endIndex]).uppercased()
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
                        if indexString.endIndex >= a.endIndex {
                            header = String(indexString[..<a.endIndex])
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
    var indexStringsTransform:((String?)->String?)?
    var indexHeadersTransform:((String?)->String?)?
    
    var indexSort:((String?,String?)->Bool)?
    
    var showHeaders = false
    {
        didSet {
            if showIndex && showHeaders {
                print("ERROR: showIndex && showHeaders")
            }
        }
    }

    // Make thread safe?
    var headerStrings:[String]?
    
    // Make thread safe?
    var headers:[String]?
    {
        get {
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
