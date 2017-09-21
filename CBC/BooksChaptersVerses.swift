//
//  BooksChaptersVerses.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class BooksChaptersVerses : Swift.Comparable {
    var data:[String:[Int:[Int]]]?
    
    func bookChaptersVerses(book:String?) -> BooksChaptersVerses?
    {
        guard let book = book else {
            return self
        }
        
        let bcv = BooksChaptersVerses()
        
        bcv[book] = data?[book]
        
        //        print(bcv[book])
        
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
            // JUST ADDED
            if (lhsBooks?.count == 0) && (rhsBooks?.count == 0) {
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
                            if let count = lhsBooks?.count {
                                for index in 0...(count - 1) {
                                    if lhsBooks?[index] != rhsBooks?[index] {
                                        return false
                                    }
                                }
                            }
                            if let books = lhsBooks {
                                for book in books {
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
                                                    if let count = lhsChapters?.count {
                                                        for index in 0...(count - 1) {
                                                            if lhsChapters?[index] != rhsChapters?[index] {
                                                                return false
                                                            }
                                                        }
                                                    }
                                                    if let chapters = lhsChapters {
                                                        for chapter in chapters {
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
                                                                            if let count = lhsVerses?.count {
                                                                                for index in 0...(count - 1) {
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
                    if let lhsBooks = lhsBooks, let rhsBooks = rhsBooks {
                        for lhsBook in lhsBooks {
                            for rhsBook in rhsBooks {
                                if lhsBook == rhsBook {
                                    let lhsChapters = lhs[lhsBook]?.keys.sorted()
                                    let rhsChapters = rhs[rhsBook]?.keys.sorted()
                                    
                                    if (lhsChapters == nil) && (rhsChapters == nil) {
                                        return lhsBooks.count < rhsBooks.count
                                    } else
                                        if (lhsChapters != nil) && (rhsChapters == nil) {
                                            return true
                                        } else
                                            if (lhsChapters == nil) && (rhsChapters != nil) {
                                                return false
                                            } else {
                                                if let lhsChapters = lhsChapters, let rhsChapters = rhsChapters {
                                                    for lhsChapter in lhsChapters {
                                                        for rhsChapter in rhsChapters {
                                                            if lhsChapter == rhsChapter {
                                                                let lhsVerses = lhs[lhsBook]?[lhsChapter]?.sorted()
                                                                let rhsVerses = rhs[rhsBook]?[rhsChapter]?.sorted()
                                                                
                                                                if (lhsVerses == nil) && (rhsVerses == nil) {
                                                                    return lhsChapters.count < rhsChapters.count
                                                                } else
                                                                    if (lhsVerses != nil) && (rhsVerses == nil) {
                                                                        return true
                                                                    } else
                                                                        if (lhsVerses == nil) && (rhsVerses != nil) {
                                                                            return false
                                                                        } else {
                                                                            if let lhsVerses = lhsVerses, let rhsVerses = rhsVerses {
                                                                                for lhsVerse in lhsVerses {
                                                                                    for rhsVerse in rhsVerses {
                                                                                        if lhsVerse == rhsVerse {
                                                                                            return lhs.numberOfVerses() < rhs.numberOfVerses()
                                                                                        } else {
                                                                                            return lhsVerse < rhsVerse
                                                                                        }
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
                                    }
                                } else {
                                    return bookNumberInBible(lhsBook) < bookNumberInBible(rhsBook)
                                }
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
