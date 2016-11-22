//
//  functions.swift
//  TPS
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

//typealias GroupTuple = (indexes: [Int]?, counts: [Int]?)

func documentsURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
}

func cachesURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
}

func filesOfTypeInCache(_ fileType:String) -> [String]?
{
    var files = [String]()
    
    let fileManager = FileManager.default
    let path = cachesURL()?.path
    do {
        let array = try fileManager.contentsOfDirectory(atPath: path!)
        
        for string in array {
            if string.range(of: fileType) != nil {
                if fileType == string.substring(from: string.range(of: fileType)!.lowerBound) {
                    files.append(string)
                }
            }
        }
    } catch _ {
        NSLog("failed to get files in caches directory")
    }
    
    return files.count > 0 ? files : nil
}

//    func removeTempFiles()
//    {
//        // Clean up temp directory for cancelled downloads
//        let fileManager = NSFileManager.defaultManager()
//        let path = NSTemporaryDirectory()
//        do {
//            let array = try fileManager.contentsOfDirectoryAtPath(path)
//
//            for string in array {
//                NSLog("Deleting: \(string)")
//                try fileManager.removeItemAtPath(path + string)
//            }
//        } catch _ {
//            NSLog("failed to remove temp file")
//        }
//    }

//func removeTempFiles()
//{
//    // Clean up temp directory for cancelled downloads
//    let fileManager = NSFileManager.defaultManager()
//    let path = NSTemporaryDirectory()
//    do {
//        let array = try fileManager.contentsOfDirectoryAtPath(path)
//        
//        for name in array {
//            if (name.rangeOfString(Constants.TMP_FILENAME_EXTENSION)?.endIndex == name.endIndex) {
//                NSLog("Deleting: \(name)")
//                try fileManager.removeItemAtPath(path + name)
//            }
//        }
//    } catch _ {
//        NSLog("failed to remove temp files")
//    }
//}

//func promoteTempJSON()
//{
//    let fileManager = NSFileManager.defaultManager()
//    
//    let sourceURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME + Constants.TMP_FILENAME_EXTENSION)
//    let destinationURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME)
//    let oldURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME + ".old")
//    
//    // Check if file exists
//    if (fileManager.fileExistsAtPath(oldURL!.path!)){
//        do {
//            try fileManager.removeItemAtURL(oldURL!)
//        } catch _ {
//            NSLog("failed to remove old json file")
//        }
//    }
//    
//    do {
//        try fileManager.moveItemAtURL(destinationURL!, toURL: oldURL!)
//        
//        do {
//            try fileManager.moveItemAtURL(sourceURL!, toURL: destinationURL!)
//            //        try fileManager.copyItemAtURL(sourceURL!, toURL: destinationURL!)
//            //        try fileManager.removeItemAtURL(sourceURL!)
//        } catch _ {
//            NSLog("failed to promote new json file from tmp to final")
//            
//            do {
//                try fileManager.moveItemAtURL(oldURL!, toURL: destinationURL!)
//            } catch _ {
//                NSLog("failed to move json file back from old to current")
//            }
//        }
//    } catch _ {
//        NSLog("failed to move current json file to old")
//    }
//}

//func jsonDataFromURL() -> JSON
//{
//    if let url = NSURL(string: Constants.JSON_URL_PREFIX + Constants.CBC.SHORT.lowercaseString + "." + Constants.SERMONS_JSON_FILENAME) {
//        do {
//            let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
//            let json = JSON(data: data)
//            if json != JSON.null {
//                return json
//            } else {
//                NSLog("could not get json from file, make sure that file contains valid json.")
//            }
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//        }
//    } else {
//        NSLog("Invalid filename/path.")
//    }
//    
//    return nil
//}

//func jsonDataFromBundle(key:String) -> JSON // Constants.JSON_SERMONS_ARRAY_KEY
//{
//    if let path = Bundle.main.path(forResource: key, ofType: Constants.JSON_TYPE) {
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
//            let json = JSON(data: data)
//            if json != JSON.null {
//                return json
//            } else {
//                NSLog("could not get json from file, make sure that file contains valid json.")
//            }
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//        }
//    } else {
//        NSLog("Invalid filename/path.")
//    }
//
//    return nil
//}

func removeJSONFromFileSystemDirectory()
{
    if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(Constants.JSON.FILENAME.MEDIA) {
        do {
            try FileManager.default.removeItem(atPath: jsonFileSystemURL.path)
        } catch _ {
            NSLog("failed to copy mediaItems.json")
        }
    }
}

func jsonToFileSystemDirectory(key:String)
{
    let fileManager = FileManager.default
    
    let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE)
    
    if let jsonFileURL = cachesURL()?.appendingPathComponent(Constants.JSON.FILENAME.MEDIA) {
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItem(atPath: jsonBundlePath!,toPath: jsonFileURL.path)
                } catch _ {
                    NSLog("failed to copy mediaItems.json")
                }
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItem(atPath: jsonBundlePath!)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItem(atPath: jsonFileURL.path)
                
                let jsonBundleModDate = jsonBundleAttributes[FileAttributeKey.modificationDate] as! Date
                let jsonDocumentsModDate = jsonDocumentsAttributes[FileAttributeKey.modificationDate] as! Date
                
                if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
                    //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                    NSLog("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                    NSLog("JSON in Documents is the same date as JSON in bundle")
                    let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as! Int
                    let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as! Int
                    
                    if (jsonBundleFileSize != jsonDocumentsFileSize) {
                        NSLog("Same dates different file sizes")
                        //We have a problem.
                    } else {
                        NSLog("Same dates same file sizes")
                        //Do nothing, they are the same.
                    }
                }
                
                if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
                    NSLog("JSON in bundle is newer than JSON in Documents")
                    //copy the bundle into Documents directory
                    do {
                        // Copy File From Bundle To Documents Directory
                        try fileManager.removeItem(atPath: jsonFileURL.path)
                        try fileManager.copyItem(atPath: jsonBundlePath!,toPath: jsonFileURL.path)
                    } catch _ {
                        NSLog("failed to copy mediaItems.json")
                    }
                }
            } catch _ {
                NSLog("failed to get json file attributes")
            }
        }
    }
}

func jsonDataFromDocumentsDirectory() -> JSON
{
    jsonToFileSystemDirectory(key:Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES)
    
    if let jsonURL = cachesURL()?.appendingPathComponent(Constants.JSON.FILENAME.MEDIA) {
        if let data = try? Data(contentsOf: jsonURL) {
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                NSLog("could not get json from data, make sure the file contains valid json.")
            }
        } else {
            NSLog("could not get data from the json file.")
        }
    }
    
    return nil
}

func jsonDataFromCachesDirectory() -> JSON
{
    if let jsonURL = cachesURL()?.appendingPathComponent(Constants.JSON.FILENAME.MEDIA) {
        if let data = try? Data(contentsOf: jsonURL) {
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                NSLog("could not get json from data, make sure the file contains valid json.")
            }
        } else {
            NSLog("could not get data from the json file.")
        }
    }
    
    return nil
}

extension Date
{
    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: dateString)!
        self = Date(timeInterval:0, since:d)
    }
    
    func isNewerThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedDescending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    
    
    func isOlderThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedAscending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    

    func isEqualTo(_ dateToCompare : Date) -> Bool
    {
        return self.compare(dateToCompare) == ComparisonResult.orderedSame
    }

    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

func stringWithoutPrefixes(_ fromString:String?) -> String?
{
    if let range = fromString?.range(of: "A is ") {
        if range.lowerBound == "a".startIndex {
            return fromString
        }
    }
    
//    if let range = fromString?.range(of: "And the ") {
//        if range.lowerBound == "a".startIndex {
//            return fromString
//        }
//    }
    
    let sourceString = fromString?.replacingOccurrences(of: Constants.QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
//    print(sourceString)
    
    let prefixes = ["A ","An ","The "] // "And ",
    
//    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substring(to: quote.endIndex) == quote) {
//        sortString = sourceString!.substring(from: quote.endIndex)
//    }

    var sortString = sourceString
    
    for prefix in prefixes {
        if (sourceString?.endIndex >= prefix.endIndex) && (sourceString?.substring(to: prefix.endIndex) == prefix) {
            sortString = sourceString!.substring(from: prefix.endIndex)
            break
        }
    }

//    print(sortString)
    return sortString
}

func sortMediaItems(_ mediaItems:[MediaItem]?, sorting:String?, grouping:String?) -> [MediaItem]?
{
    var result:[MediaItem]?
    
    switch grouping! {
    case Grouping.YEAR:
        result = sortMediaItemsByYear(mediaItems,sorting: sorting)
        break
        
    case Grouping.TITLE:
        result = sortMediaItemsBySeries(mediaItems,sorting: sorting)
        break
        
    case Grouping.BOOK:
        result = sortMediaItemsByBook(mediaItems,sorting: sorting)
        break
        
    case Grouping.SPEAKER:
        result = sortMediaItemsBySpeaker(mediaItems,sorting: sorting)
        break
        
    default:
        result = nil
        break
    }
    
    return result
}


func mediaItemSections(_ mediaItems:[MediaItem]?,sorting:String?,grouping:String?) -> [String]?
{
    var strings:[String]?
    
    switch grouping! {
    case Grouping.YEAR:
        strings = yearsFromMediaItems(mediaItems, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Grouping.TITLE:
        strings = seriesSectionsFromMediaItems(mediaItems,withTitles: true)
        break
        
    case Grouping.BOOK:
        strings = bookSectionsFromMediaItems(mediaItems)
        break
        
    case Grouping.SPEAKER:
        strings = speakerSectionsFromMediaItems(mediaItems)
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func yearsFromMediaItems(_ mediaItems:[MediaItem]?, sorting: String?) -> [Int]?
{
    return mediaItems != nil ?
        Array(
            Set(
                mediaItems!.filter({ (mediaItem:MediaItem) -> Bool in
                    assert(mediaItem.fullDate != nil) // We're assuming this gets ALL mediaItems.
                    return mediaItem.fullDate != nil
                }).map({ (mediaItem:MediaItem) -> Int in
                    let calendar = Calendar.current
                    let components = (calendar as NSCalendar).components(.year, from: mediaItem.fullDate! as Date)
                    return components.year!
                })
            )
            ).sorted(by: { (first:Int, second:Int) -> Bool in
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return first < second
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return first > second
                    
                default:
                    break
                }
                
                return false
            })
        : nil
}


func testament(_ book:String) -> String
{
    if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
        return Constants.Old_Testament
    } else
        if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
            return Constants.New_Testament
    }
    
    return Constants.EMPTY_STRING
}

func chaptersFromScripture(_ scripture:String?) -> [Int]
{
    // This can only comprehend a range of chapters or a range of verses from a single book.
    
    var chapters = [Int]()
    
    var colonCount = 0
    
    if (scripture != nil) {
        let string = scripture?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        //        if (string!.rangeOfString(Constants.SINGLE_SPACE) != nil) {
        //            string = string?.substringFromIndex(string!.rangeOfString(Constants.SINGLE_SPACE)!.endIndex)
        //        } else {
        //            return []
        //        }
        
        if (string == Constants.EMPTY_STRING) {
            return []
        }
        
        //        NSLog("\(string!)")
        
        let colon = string!.range(of: ":")
        let hyphen = string!.range(of: "-")
        let comma = string!.range(of: ",")
        
//        print(scripture,string)
        
        if (colon == nil) && (hyphen == nil) &&  (comma == nil) {
            if (Int(string!) != nil) {
                chapters = [Int(string!)!]
            }
        } else {
            var chars = Constants.EMPTY_STRING
            
            var seenColon = false
            var seenHyphen = false
            var seenComma = false
            
            var startChapter = 0
            var endChapter = 0
            
            var breakOut = false
            
            for character in string!.characters {
                if breakOut {
                    break
                }
                switch character {
                case ":":
                    if !seenColon {
                        seenColon = true
                        if (Int(chars) != nil) {
                            if (startChapter == 0) {
                                startChapter = Int(chars)!
                            } else {
                                endChapter = Int(chars)!
                            }
                        }
                    } else {
                        if (seenHyphen) {
                            if (Int(chars) != nil) {
                                endChapter = Int(chars)!
                            }
                        } else {
                            //Error
                        }
                    }
                    colonCount += 1
                    chars = Constants.EMPTY_STRING
                    break
                    
                case "–":
                    fallthrough
                case "-":
                    seenHyphen = true
                    if colonCount == 0 {
                        // This is a chapter not a verse
                        if (startChapter == 0) {
                            if Int(chars) != nil {
                                startChapter = Int(chars)!
                            }
                        }
                    }
                    chars = Constants.EMPTY_STRING
                    break
                    
                case "(":
                    breakOut = true
                    break
                    
                case ",":
                    seenComma = true
                    if !seenColon {
                        // This is a chapter not a verse
                        if (Int(chars) != nil) {
                            chapters.append(Int(chars)!)
                        }
                        chars = Constants.EMPTY_STRING
                    } else {
                        // Could be chapter or a verse
                        chars = Constants.EMPTY_STRING
                    }
                    break
                    
                default:
                    chars.append(character)
                    //                    print(chars)
                    break
                }
            }
            if (startChapter != 0) {
                if (endChapter == 0) {
                    if (colonCount == 0) {
                        if (Int(chars) != nil) {
                            endChapter = Int(chars)!
                        }
                        chars = Constants.EMPTY_STRING
                    }
                }
                if (endChapter != 0) {
                    for chapter in startChapter...endChapter {
                        chapters.append(chapter)
                    }
                } else {
                    chapters.append(startChapter)
                }
            }
            if seenComma {
                if Int(chars) != nil {
                    if !seenColon {
                        // This is a chapter not a verse
                        chapters.append(Int(chars)!)
                    }
                }
            }
            
            //            if (colon != nil) {
            //                let stringToColon = string?.substringToIndex(colon!.startIndex)
            //
            //                NSLog("stringToColon: \(stringToColon)")
            //
            //                chapters = [Int(stringToColon!)!]
            //
            //                let stringFromColon = string?.substringFromIndex(colon!.endIndex)
            //
            //                NSLog("stringFromColon: \(stringFromColon)")
            //            } else {
            //                if (hyphen != nil) {
            //                    let stringToHyphen = string?.substringToIndex(hyphen!.startIndex)
            //                    let startingChapter = Int(stringToHyphen!)!
            //
            //                    let stringFromHyphen = string?.substringFromIndex(hyphen!.endIndex)
            //                    let endingChapter = Int(stringFromHyphen!)!
            //
            //                    for index in startingChapter...endingChapter {
            //                        chapters.append(index)
            //                    }
            //                    //                            NSLog("\(chapters)")
            //                    //                            NSLog("\(chapters)")
            //                }
            //                if (comma != nil) {
            //                    let stringToComma = string?.substringToIndex(comma!.startIndex)
            //                    let startingChapter = Int(stringToComma!)!
            //                    chapters = [startingChapter]
            //
            //                    let stringFromComma = string?.substringFromIndex(comma!.endIndex)
            //                    let endingChapter = Int(stringFromComma!)!
            //                    chapters.append(endingChapter)
            //                    //                            NSLog("\(chapters)")
            //                    //                            NSLog("\(chapters)")
            //                }
            //            }
        }
    }
    
//    if (colonCount > 1) || (chapters.count > 1) {
//        NSLog("\(scripture)")
//        NSLog("\(chapters)")
////        NSLog("ERROR")
//    }
    
//    NSLog("\(scripture)")
//    NSLog("\(chapters)")
    
    return chapters
}

func booksFromScripture(_ scripture:String?) -> [String]
{
    var books = [String]()
    
    if (scripture != nil) {
        var string:String?
        
        string = scripture
//        print(string)
        
        var otBooks = [String]()
        
        for book in Constants.OLD_TESTAMENT_BOOKS {
            if string?.range(of: book) != nil {
                otBooks.append(book)
                string = string!.substring(to: string!.range(of: book)!.lowerBound) + " " + string!.substring(from: string!.range(of: book)!.upperBound)
            }
        }
        
//        string = scripture
        
        for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
            if string?.range(of: book) != nil {
                books.append(book)
                string = string!.substring(to: string!.range(of: book)!.lowerBound) + " " + string!.substring(from: string!.range(of: book)!.upperBound)
            }
        }
        
        let ntBooks = books.reversed()

        books = otBooks
        books.append(contentsOf: ntBooks)
        
        string = string?.replacingOccurrences(of: " ", with: Constants.EMPTY_STRING)

//        print(string)
        if string == "-" {
            if books.count == 2 {
                let first = books[0]
                let last = books[1]
                
//                print(first)
//                print(last)
                
                books = [String]()
                
                if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.OLD_TESTAMENT_BOOKS.contains(last) {
                    if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: first) {
                        if let lastIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                }
                
                if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                    if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: first) {
                        if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                }
            }
        }
    }
    
//    print(books)
    return books
}

func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
{
    var multiPartMediaItems:[MediaItem]?
    
    if (mediaItem != nil) {
        if (mediaItem!.hasMultipleParts) {
            if (globals.media.all?.groupSort?[Grouping.TITLE]?[mediaItem!.multiPartSort!]?[Constants.CHRONOLOGICAL] == nil) {
                let seriesMediaItems = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return mediaItem!.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem!.multiPartName) : (testMediaItem.id == mediaItem!.id)
                })
                multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: Constants.CHRONOLOGICAL)
            } else {
                multiPartMediaItems = globals.media.all?.groupSort?[Grouping.TITLE]?[mediaItem!.multiPartSort!]?[Constants.CHRONOLOGICAL]
            }
        } else {
            multiPartMediaItems = [mediaItem!]
        }
    }
    
    return multiPartMediaItems
}

func mediaItemsInBook(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
{
    return mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
        return mediaItem.book == book
    }).sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThan(second.fullDate!)
        }
    })
}

func booksFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(mediaItems!.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasBook
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.book!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    result = bookNumberInBible(first) < bookNumberInBible(second)
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }
                return result
            })
        : nil
}

func bookSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(mediaItems!.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.hasBook ? mediaItem.book! : mediaItem.scripture != nil ? mediaItem.scripture! : Constants.None
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    result = bookNumberInBible(first) < bookNumberInBible(second)
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }
                return result
            })
        : nil
}

func seriesFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(
                mediaItems!.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.hasMultipleParts
                }).map({ (mediaItem:MediaItem) -> String in
                    return mediaItem.multiPartName!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(
                mediaItems!.map({ (mediaItem:MediaItem) -> String in
                    return mediaItem.multiPartSection!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?,withTitles:Bool) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(
                mediaItems!.map({ (mediaItem:MediaItem) -> String in
                    if (mediaItem.hasMultipleParts) {
                        return mediaItem.multiPartName!
                    } else {
                        return withTitles ? mediaItem.title! : Constants.Individual_Media
                    }
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func bookNumberInBible(_ book:String?) -> Int?
{
    if (book != nil) {
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!) {
            return Constants.OLD_TESTAMENT_BOOKS.count + index
        }
        
        return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
}

func tokensFromString(_ string:String?) -> [String]?
{
    var tokens:[String]?
    
    if (string != nil) {
        var str = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if let range = str?.range(of: Constants.PART_INDICATOR_SINGULAR) {
            str = str?.substring(to: range.lowerBound)
        }
        
        //        print(name)
        //        print(string)
        
        var token = Constants.EMPTY_STRING
        
        func processToken()
        {
            if (token.endIndex > "XX".endIndex) {
                // "Q", "A", "I", "at", "or", "to", "of", "in", "on",  "be", "is", "vs", "us", "An"
                for word in ["are", "can", "And", "The", "for"] {
                    if token.lowercased() == word.lowercased() {
                        token = Constants.EMPTY_STRING
                        break
                    }
                }
                
                if let range = token.range(of: "'s") {
                    token = token.substring(to: range.lowerBound)
                }
                
                if let range = token.range(of: "'") {
                    if range.upperBound == token.endIndex {
                        token = token.substring(to: range.lowerBound)
                    }
                }
                
                if token != Constants.EMPTY_STRING {
                    if tokens == nil {
                        tokens = [token]
                    } else {
                        tokens?.append(token)
                    }
                    token = Constants.EMPTY_STRING
                }
            } else {
                token = Constants.EMPTY_STRING
            }
        }
        
        for char in str!.characters {
            if CharacterSet(charactersIn: " :-!;,.()?&").contains(UnicodeScalar(String(char))!) {
                processToken()
            } else {
                if !CharacterSet(charactersIn: "$0123456789").contains(UnicodeScalar(String(char))!) {
                    token.append(char)
                }
            }
        }

        if token != Constants.EMPTY_STRING {
            processToken()
        }
    }
    
    return tokens
}

func lastNameFromName(_ name:String?) -> String?
{
    if var lastname = name {
        while (lastname.range(of: Constants.SINGLE_SPACE) != nil) {
            lastname = lastname.substring(from: lastname.range(of: Constants.SINGLE_SPACE)!.upperBound)
        }
        return lastname
    }
    return nil
}

func firstNameFromName(_ name:String?) -> String?
{
    var firstName:String?
    
    var string:String?
    
    if (name != nil) {
        if let title = titleFromName(name) {
            string = name?.substring(from: title.endIndex)
        } else {
            string = name
        }
        
        string = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
//        print(name)
//        print(string)
        
        var newString = Constants.EMPTY_STRING
        
        for char in string!.characters {
            if String(char) == " " {
                firstName = newString
                break
            }
            newString.append(char)
        }
    }
    
    return firstName
}

func titleFromName(_ name:String?) -> String?
{
    var title = Constants.EMPTY_STRING
    
    if (name != nil) && (name?.range(of: ". ") != nil) {
        for char in name!.characters {
            title.append(char)
            if String(char) == "." {
                break
            }
        }
    }
    
    return title != Constants.EMPTY_STRING ? title : nil
}

func speakerSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(mediaItems!.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speakerSection!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func speakersFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(mediaItems!.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasSpeaker
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speaker!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func sortMediaItemsChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            if ($0.service == $1.service) {
                return $0.part < $1.part
            } else {
                 return $0.service < $1.service
            }
        } else {
            return $0.fullDate!.isOlderThan($1.fullDate!)
        }
    }
}

func sortMediaItemsReverseChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            if ($0.service == $1.service) {
                return $0.part > $1.part
            } else {
                return $0.service > $1.service
            }
        } else {
            return $0.fullDate!.isNewerThan($1.fullDate!)
        }
    }
}

func sortMediaItemsByYear(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
{
    var sortedMediaItems:[MediaItem]?

    switch sorting! {
    case Constants.CHRONOLOGICAL:
        sortedMediaItems = sortMediaItemsChronologically(mediaItems)
        break
        
    case Constants.REVERSE_CHRONOLOGICAL:
        sortedMediaItems = sortMediaItemsReverseChronologically(mediaItems)
        break
        
    default:
        break
    }
    
    return sortedMediaItems
}

func compareMediaItemDates(first:MediaItem, second:MediaItem, sorting:String?) -> Bool
{
    var result = false

    switch sorting! {
    case Constants.CHRONOLOGICAL:
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            result = (first.service < second.service)
        } else {
            result = first.fullDate!.isOlderThan(second.fullDate!)
        }
        break
    
    case Constants.REVERSE_CHRONOLOGICAL:
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            result = (first.service > second.service)
        } else {
            result = first.fullDate!.isNewerThan(second.fullDate!)
        }
        break
        
    default:
        break
    }

    return result
}

func sortMediaItemsBySeries(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.multiPartSectionSort != second.multiPartSectionSort) {
            result = first.multiPartSectionSort < second.multiPartSectionSort
        } else {
            result = compareMediaItemDates(first: first,second: second, sorting: sorting)
        }

        return result
    }
}

func sortMediaItemsBySpeaker(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.speakerSectionSort != second.speakerSectionSort) {
            result = first.speakerSectionSort < second.speakerSectionSort
        } else {
            result = compareMediaItemDates(first: first,second: second, sorting: sorting)
        }
        
        return result
    }
}

func sortMediaItemsByBook(_ mediaItems:[MediaItem]?, sorting:String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        let first = bookNumberInBible($0.book)
        let second = bookNumberInBible($1.book)
        
        var result = false
        
        if (first != nil) && (second != nil) {
            if (first != second) {
                result = first < second
            } else {
                result = compareMediaItemDates(first: $0,second: $1, sorting: sorting)
            }
        } else
            if (first != nil) && (second == nil) {
                result = true
            } else
                if (first == nil) && (second != nil) {
                    result = false
                } else
                    if (first == nil) && (second == nil) {
                        if ($0.bookSection != $1.bookSection) {
                            result = $0.bookSection < $1.bookSection
                        } else {
                            result = compareMediaItemDates(first: $0,second: $1, sorting: sorting)
                        }
        }
        
        return result
    }
}


func testMediaItemsPDFs(testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
    var counter = 1

    if (testExisting) {
        NSLog("Testing the availability of mediaItem transcripts and slides that we DO have in the mediaItemDicts - start")
        
        if let mediaItems = globals.mediaRepository.list {
            for mediaItem in mediaItems {
                if (showTesting) {
                    NSLog("Testing: \(counter) \(mediaItem.title!)")
                } else {
//                    NSLog(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (mediaItem.notes != nil) {
                    if ((try? Data(contentsOf: mediaItem.notesURL! as URL)) == nil) {
                        NSLog("Transcript DOES NOT exist for: \(mediaItem.title!) PDF: \(mediaItem.notes!)")
                    } else {
                        
                    }
                }
                
                if (mediaItem.slides != nil) {
                    if ((try? Data(contentsOf: mediaItem.slidesURL! as URL)) == nil) {
                        NSLog("Slides DO NOT exist for: \(mediaItem.title!) PDF: \(mediaItem.slides!)")
                    } else {
                        
                    }
                }
                
                counter += 1
            }
        }
        
        NSLog("\nTesting the availability of mediaItem transcripts and slides that we DO have in the mediaItemDicts - end")
    }

    if (testMissing) {
        NSLog("Testing the availability of mediaItem transcripts and slides that we DO NOT have in the mediaItemDicts - start")
        
        counter = 1
        if let mediaItems = globals.mediaRepository.list {
            for mediaItem in mediaItems {
                if (showTesting) {
                    NSLog("Testing: \(counter) \(mediaItem.title!)")
                } else {
//                    NSLog(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (mediaItem.audio == nil) {
                    NSLog("No Audio file for: \(mediaItem.title) can't test for PDF's")
                } else {
                    if (mediaItem.notes == nil) {
                        if ((try? Data(contentsOf: mediaItem.notesURL!)) != nil) {
                            NSLog("Transcript DOES exist for: \(mediaItem.title!) ID:\(mediaItem.id)")
                        } else {
                            
                        }
                    }
                    
                    if (mediaItem.slides == nil) {
                        if ((try? Data(contentsOf: mediaItem.slidesURL!)) != nil) {
                            NSLog("Slides DO exist for: \(mediaItem.title!) ID: \(mediaItem.id)")
                        } else {
                            
                        }
                    }
                }
                
                counter += 1
            }
        }
        
        NSLog("\nTesting the availability of mediaItem transcripts and slides that we DO NOT have in the mediaItemDicts - end")
    }
}

func testMediaItemsTagsAndSeries()
{
    NSLog("Testing for mediaItem series and tags the same - start")
    
    if let mediaItems = globals.mediaRepository.list {
        for mediaItem in mediaItems {
            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                if (mediaItem.multiPartName == mediaItem.tags) {
                    NSLog("Multiple Part Name and Tags the same in: \(mediaItem.title!) Multiple Part Name:\(mediaItem.multiPartName!) Tags:\(mediaItem.tags!)")
                }
            }
        }
    }
    
    NSLog("Testing for mediaItem series and tags the same - end")
}

func testMediaItemsForAudio()
{
    NSLog("Testing for audio - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasAudio) {
            NSLog("Audio missing in: \(mediaItem.title!)")
        } else {

        }
    }
    
    NSLog("Testing for audio - end")
}

func testMediaItemsForSpeaker()
{
    NSLog("Testing for speaker - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasSpeaker) {
            NSLog("Speaker missing in: \(mediaItem.title!)")
        }
    }
    
    NSLog("Testing for speaker - end")
}

func testMediaItemsForSeries()
{
    NSLog("Testing for mediaItems with \"(Part \" in the title but no series - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
            NSLog("Series missing in: \(mediaItem.title!)")
        }
    }
    
    NSLog("Testing for mediaItems with \"(Part \" in the title but no series - end")
}

func testMediaItemsBooksAndSeries()
{
    NSLog("Testing for mediaItem series and book the same - start")

    for mediaItem in globals.mediaRepository.list! {
        if (mediaItem.hasMultipleParts) && (mediaItem.hasBook) {
            if (mediaItem.multiPartName == mediaItem.book) {
                NSLog("Multiple Part Name and Book the same in: \(mediaItem.title!) Multiple Part Name:\(mediaItem.multiPartName!) Book:\(mediaItem.book!)")
            }
        }
    }

    NSLog("Testing for mediaItem series and book the same - end")
}

func tagsSetFromTagsString(_ tagsString:String?) -> Set<String>?
{
    var tags = tagsString
    var tag:String
    var setOfTags = Set<String>()
    
    while (tags?.range(of: Constants.TAGS_SEPARATOR) != nil) {
        tag = tags!.substring(to: tags!.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
        setOfTags.insert(tag)
        tags = tags!.substring(from: tags!.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
    }
    
    if (tags != nil) {
        setOfTags.insert(tags!)
    }
    
    return setOfTags.count > 0 ? setOfTags : nil
}

func tagsArrayToTagsString(_ tagsArray:[String]?) -> String?
{
    if tagsArray != nil {
        var tagString:String?
        
        for tag in tagsArray! {
            if tagString == nil {
                tagString = tag
            } else {
                tagString = tagString! + Constants.TAGS_SEPARATOR + tag
            }
        }
        
        return tagString
    } else {
        return nil
    }
}

func tagsArrayFromTagsString(_ tagsString:String?) -> [String]?
{
    var arrayOfTags:[String]?
    
    if let tags = tagsSetFromTagsString(tagsString) {
        arrayOfTags = Array(tags) //.sort() { $0 < $1 } // .sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) } // Not sorted
    }
    
    return arrayOfTags
}

func mediaItemsWithTag(_ mediaItems:[MediaItem]?,tag:String?) -> [MediaItem]?
{
    return tag != nil ?
        mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
            if let tagSet = mediaItem.tagsSet {
                return tagSet.contains(tag!)
            } else {
                return false
            }
        }) : nil
}

func tagsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    if mediaItems != nil {
        var tagsSet = Set<String>()

        for mediaItem in mediaItems! {
            if let tags = mediaItem.tagsSet {
                tagsSet.formUnion(tags)
            }
        }
        
        var tagsArray = Array(tagsSet).sorted(by: { stringWithoutPrefixes($0) < stringWithoutPrefixes($1) })

        tagsArray.append(Constants.All)
        
    //    NSLog("Tag Set: \(tagsSet)")
    //    NSLog("Tag Array: \(tagsArray)")
        
        return tagsArray.count > 0 ? tagsArray : nil
    }
    
    return nil
}



