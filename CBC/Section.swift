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
    func indexPath(from string:String?) -> IndexPath?
    {
        guard counts?.count == indexes?.count else {
            return nil
        }
        
        guard let string = string else {
            return nil
        }
        
        guard let index = strings?.index(of: string) else {
            return nil
        }
        
        if counts?.count == indexes?.count {
            var section = 0
            
            while index >= (indexes![section] + counts![section]) {
                section += 1
            }
            
            if let sectionIndex = indexes?[section] {
                
                let row = index - sectionIndex
                
                return IndexPath(row: row, section: section)
            }
        }
        
        return nil
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
    
    var strings:[String]? {
        willSet {
            
        }
        didSet {
            guard strings != nil else {
                self.counts = nil
                self.indexes = nil
                self.headerStrings = nil
                return
            }

            guard showIndex else {
                self.counts = [strings!.count]
                self.indexes = [0]
                return
            }
            
            indexStrings = strings?.map({ (string:String) -> String in
                return indexStringsTransform != nil ? indexStringsTransform!(string.uppercased())! : string.uppercased()
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
    var indexHeaders:[String]?
    var indexStrings:[String]?
    {
        didSet {
            guard showIndex else {
                return
            }
            
            guard strings?.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            guard indexStrings?.count > 0 else {
                indexHeaders = nil
                counts = nil
                indexes = nil
                
                return
            }
            
            let a = "A"
            
            if indexHeadersTransform == nil {
                indexHeaders = Array(Set(indexStrings!
                    .map({ (string:String) -> String in
                        if string.endIndex >= a.endIndex {
                            return string.substring(to: a.endIndex).uppercased()
                        } else {
                            return string
                        }
                    })
                )) // .sorted()
            } else {
                indexHeaders = Array(Set(
                    indexStrings!.map({ (string:String) -> String in
                        return indexHeadersTransform!(string)!
                    })
                )) // .sorted()
            }

            if indexSort != nil {
                indexHeaders = indexHeaders?.sorted(by: {
                    return indexSort!($0,$1)
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
                
                for indexString in indexStrings! {
                    var header : String?
                    
                    if indexHeadersTransform == nil {
                        if indexString.endIndex >= a.endIndex {
                            header = indexString.substring(to: a.endIndex)
                        }
                    } else {
                        header = indexHeadersTransform?(indexString)
                    }
                    
                    //                    print(header)
                    
                    if let header = header {
                        if stringIndex[header] == nil {
                            stringIndex[header] = [String]()
                        }
                        //                print(testString,string)
                        stringIndex[header]?.append(indexString)
                    }
                }
                
                var counter = 0
                
                var counts = [Int]()
                var indexes = [Int]()
                var keys = [String]()
                
                if indexSort != nil {
                    keys = stringIndex.keys.sorted(by: {
                        return indexSort!($0,$1)
                    })
                } else {
                    keys = stringIndex.keys.sorted()
                }
                
                for key in keys {
                    //                print(stringIndex[key]!)
                    
                    indexes.append(counter)
                    counts.append(stringIndex[key]!.count)
                    
                    counter += stringIndex[key]!.count
                }
                
                self.counts = counts.count > 0 ? counts : nil
                self.indexes = indexes.count > 0 ? indexes : nil
                
                if self.counts?.count != self.indexes?.count {
                    print("counts.count != indexes.count")
                }
            }
        }
    }
    var indexStringsTransform:((String?)->String?)? = stringWithoutPrefixes
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
    var headerStrings:[String]?
    
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
    
    var counts:[Int]?
    var indexes:[Int]?
    
    //    func buildHeaders()
    //    {
    //        guard strings?.count > 0 else {
    //            indexHeaders = nil
    //            counts = nil
    //            indexes = nil
    //
    //            return
    //        }
    //
    //        if showIndex {
    //            guard indexStrings?.count > 0 else {
    //                indexHeaders = nil
    //                counts = nil
    //                indexes = nil
    //
    //                return
    //            }
    //        }
    //
    //        indexHeaders = Array(Set(indexStrings!
    //            .map({ (string:String) -> String in
    //                return string
    //            })
    //        )).sorted() { $0 < $1 }
    //
    //        if indexHeaders?.count == 0 {
    //            indexHeaders = nil
    //            counts = nil
    //            indexes = nil
    //        } else {
    //            var stringIndex = [String:[String]]()
    //
    //            for headerString in headerStrings! {
    //                // if string s/b in headerString section
    ////                stringIndex[headerString]?.append(string)
    //            }
    //
    //            var counter = 0
    //
    //            var counts = [Int]()
    //            var indexes = [Int]()
    //
    //            for key in stringIndex.keys.sorted() {
    //                indexes.append(counter)
    //                counts.append(stringIndex[key]!.count)
    //
    //                counter += stringIndex[key]!.count
    //            }
    //
    //            self.counts = counts.count > 0 ? counts : nil
    //            self.indexes = indexes.count > 0 ? indexes : nil
    //        }
    //    }
    
    //    func buildIndex()
    //    {
    //        guard showIndex else {
    //            return
    //        }
    //
    //        guard strings?.count > 0 else {
    //            indexHeaders = nil
    //            counts = nil
    //            indexes = nil
    //
    //            return
    //        }
    //
    //        guard indexStrings?.count > 0 else {
    //            indexHeaders = nil
    //            counts = nil
    //            indexes = nil
    //
    //            return
    //        }
    //
    //        let a = "A"
    //
    ////        indexHeaders = Array(Set(indexStrings!
    ////            .map({ (string:String) -> String in
    ////                if string.endIndex >= a.endIndex {
    ////                    return string.substring(to: a.endIndex).uppercased()
    ////                } else {
    ////                    return string
    ////                }
    ////            })
    ////
    ////        )).sorted() { $0 < $1 }
    //
    //        if indexHeaders?.count == 0 {
    //            indexHeaders = nil
    //            counts = nil
    //            indexes = nil
    //        } else {
    //            var stringIndex = [String:[String]]()
    //
    //            for indexString in indexStrings! {
    //                if indexString.endIndex >= a.endIndex {
    //                    if stringIndex[indexString.substring(to: a.endIndex)] == nil {
    //                        stringIndex[indexString.substring(to: a.endIndex)] = [String]()
    //                    }
    //                    //                print(testString,string)
    //                    stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
    //                }
    //            }
    //
    //            var counter = 0
    //
    //            var counts = [Int]()
    //            var indexes = [Int]()
    //            
    //            for key in stringIndex.keys.sorted() {
    //                //                print(stringIndex[key]!)
    //                
    //                indexes.append(counter)
    //                counts.append(stringIndex[key]!.count)
    //                
    //                counter += stringIndex[key]!.count
    //            }
    //            
    //            self.counts = counts.count > 0 ? counts : nil
    //            self.indexes = indexes.count > 0 ? indexes : nil
    //        }
    //    }
}
