//
//  sermonFunctions.swift
//  TPS
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
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
//    if let url = NSURL(string: Constants.JSON_URL_PREFIX + Constants.CBC_SHORT.lowercaseString + "." + Constants.SERMONS_JSON_FILENAME) {
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
    if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        do {
            try FileManager.default.removeItem(atPath: jsonFileSystemURL.path)
        } catch _ {
            NSLog("failed to copy sermons.json")
        }
    }
}

func jsonToFileSystemDirectory(key:String) // Constants.JSON_SERMONS_ARRAY_KEY
{
    let fileManager = FileManager.default
    
    let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON_TYPE)
    
    if let jsonFileURL = cachesURL()?.appendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItem(atPath: jsonBundlePath!,toPath: jsonFileURL.path)
                } catch _ {
                    NSLog("failed to copy sermons.json")
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
                        NSLog("failed to copy sermons.json")
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
    jsonToFileSystemDirectory(key:Constants.JSON_SERMONS_ARRAY_KEY)
    
    if let jsonURL = cachesURL()?.appendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
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
    if let jsonURL = cachesURL()?.appendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
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

//func sermonsFromArchive() -> [Sermon]?
//{
//    // JSON is newer than Archive, reutrn nil.  That will force the archive to be rebuilt from the JSON.
//    
//    let fileManager = NSFileManager.defaultManager()
//    
//    let archiveFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE)
//    let archiveExistsInFileSystem = fileManager.fileExistsAtPath(archiveFileSystemURL!.path!)
//    
//    if !archiveExistsInFileSystem {
//        return nil
//    }
//    
//    let jsonFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME)
//    let jsonExistsInFileSystem = fileManager.fileExistsAtPath(jsonFileSystemURL!.path!)
//    
//    if (!jsonExistsInFileSystem) {
//        // This should not happen since JSON should have been copied before the first archive was created.
//        // Since we don't understand this state, return nil
//        return nil
//    }
//    
//    let jsonInBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE)
//    let jsonExistsInBundle = fileManager.fileExistsAtPath(jsonInBundlePath!)
//    
//    if (jsonExistsInFileSystem && jsonExistsInBundle) {
//        // Need to see if jsonInBundle is newer
//        
//        do {
//            let jsonInBundleAttributes = try fileManager.attributesOfItemAtPath(jsonInBundlePath!)
//            let jsonInFileSystemAttributes = try fileManager.attributesOfItemAtPath(jsonFileSystemURL!.path!)
//            
//            let jsonInBundleModDate = jsonInBundleAttributes[NSFileModificationDate] as! NSDate
//            let jsonInDocumentsModDate = jsonInFileSystemAttributes[NSFileModificationDate] as! NSDate
//            
////            NSLog("jsonInBundleModDate: \(jsonInBundleModDate)")
////            NSLog("jsonInDocumentsModDate: \(jsonInDocumentsModDate)")
//            
//            if (jsonInDocumentsModDate.isOlderThan(jsonInBundleModDate)) {
//                //The JSON in the Bundle is newer, we need to use it instead of the archive
//                NSLog("JSON in Documents is older than JSON in Bundle")
//                return nil
//            }
//            
//            if (jsonInDocumentsModDate.isEqualTo(jsonInBundleModDate)) {
//                //This is normal since JSON in Documents is copied from JSON in Bundle.  Do nothing.
//                NSLog("JSON in Bundle and in Documents are the same date")
//            }
//            
//            if (jsonInDocumentsModDate.isNewerThan(jsonInBundleModDate)) {
//                //The JSON in Documents is newer, we need to see if it is newer than the archive.
//                NSLog("JSON in Documents is newer than JSON in Bundle")
//            }
//        } catch _ {
//            NSLog("failed to get json file attributes")
//        }
//    }
//    
//    if (archiveExistsInFileSystem && jsonExistsInFileSystem) {
//        do {
//            let jsonInDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonFileSystemURL!.path!)
//            let archiveInDocumentsAttributes = try fileManager.attributesOfItemAtPath(archiveFileSystemURL!.path!)
//            
//            let jsonInDocumentsModDate = jsonInDocumentsAttributes[NSFileModificationDate] as! NSDate
//            let archiveInDocumentsModDate = archiveInDocumentsAttributes[NSFileModificationDate] as! NSDate
//            
////            NSLog("archiveInDocumentsModDate: \(archiveInDocumentsModDate)")
//            
//            if (jsonInDocumentsModDate.isNewerThan(archiveInDocumentsModDate)) {
//                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the archive was created.
//                NSLog("JSON in Documents is newer than Archive in Documents")
//                return nil
//            }
//            
//            if (archiveInDocumentsModDate.isEqualTo(jsonInDocumentsModDate)) {
//                //Should never happen since archive is created from JSON
//                NSLog("JSON in Documents is the same date as Archive in Documents")
//                return nil
//            }
//            
//            if (archiveInDocumentsModDate.isNewerThan(jsonInDocumentsModDate)) {
//                NSLog("Archive in Documents is newer than JSON in Documents")
//                
//                let data = NSData(contentsOfURL: NSURL(fileURLWithPath: archiveFileSystemURL!.path!))
//                if (data != nil) {
//                    let sermons = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [Sermon]
//                    if sermons != nil {
//                        return sermons
//                    } else {
//                        NSLog("could not get sermons from archive.")
//                    }
//                } else {
//                    NSLog("could not get data from archive.")
//                }
//            }
//        } catch _ {
//            NSLog("failed to get json file attributes")
//        }
//    }
//    
//    return nil
//}
//
//func sermonsToArchive(sermons:[Sermon]?)
//{
//    if (sermons != nil) {
//        if let archive = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_ARCHIVE) {
//            NSKeyedArchiver.archivedDataWithRootObject(sermons!).writeToURL(archive, atomically: true)
//            NSLog("Finished saving the sermon archive.")
//        }
//    }
//}

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
    let quote:String = "\""
    
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
    
    let sourceString = fromString?.replacingOccurrences(of: quote, with: "").replacingOccurrences(of: "...", with: "")
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

func sortSermons(_ sermons:[Sermon]?, sorting:String?, grouping:String?) -> [Sermon]?
{
    var result:[Sermon]?
    
    switch grouping! {
    case Grouping.YEAR:
        result = sortSermonsByYear(sermons,sorting: sorting)
        break
        
    case Grouping.TITLE:
        result = sortSermonsBySeries(sermons,sorting: sorting)
        break
        
    case Grouping.BOOK:
        result = sortSermonsByBook(sermons,sorting: sorting)
        break
        
    case Grouping.SPEAKER:
        result = sortSermonsBySpeaker(sermons,sorting: sorting)
        break
        
    default:
        result = nil
        break
    }
    
    return result
}


func sermonSections(_ sermons:[Sermon]?,sorting:String?,grouping:String?) -> [String]?
{
    var strings:[String]?
    
    switch grouping! {
    case Grouping.YEAR:
        strings = yearsFromSermons(sermons, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Grouping.TITLE:
        strings = seriesSectionsFromSermons(sermons,withTitles: true)
        break
        
    case Grouping.BOOK:
        strings = bookSectionsFromSermons(sermons)
        break
        
    case Grouping.SPEAKER:
        strings = speakerSectionsFromSermons(sermons)
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func yearsFromSermons(_ sermons:[Sermon]?, sorting: String?) -> [Int]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    assert(sermon.fullDate != nil) // We're assuming this gets ALL sermons.
                    return sermon.fullDate != nil
                }).map({ (sermon:Sermon) -> Int in
                    let calendar = Calendar.current
                    let components = (calendar as NSCalendar).components(.year, from: sermon.fullDate! as Date)
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
    
    return ""
}

func chaptersFromScripture(_ scripture:String?) -> [Int]
{
    // This can only comprehend a range of chapters or a range of verses from a single book.
    
    var chapters = [Int]()
    
    var colonCount = 0
    
    if (scripture != nil) {
        let string = scripture?.replacingOccurrences(of: Constants.SINGLE_SPACE_STRING, with: Constants.EMPTY_STRING)
        
        //        if (string!.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
        //            string = string?.substringFromIndex(string!.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
        //        } else {
        //            return []
        //        }
        
        if (string == "") {
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
            var chars = ""
            
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
                    chars = ""
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
                    chars = ""
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
                        chars = ""
                    } else {
                        // Could be chapter or a verse
                        chars = ""
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
                        chars = ""
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
        
        string = string?.replacingOccurrences(of: " ", with: "")

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

func sermonsInSermonSeries(_ sermon:Sermon?) -> [Sermon]?
{
    var sermonsInSeries:[Sermon]?
    
    if (sermon != nil) {
        if (sermon!.hasSeries) {
            if (globals.sermons.all?.groupSort?[Grouping.TITLE]?[sermon!.seriesSort!]?[Constants.CHRONOLOGICAL] == nil) {
                let seriesSermons = globals.sermonRepository.list?.filter({ (testSermon:Sermon) -> Bool in
                    return sermon!.hasSeries ? (testSermon.series == sermon!.series) : (testSermon.id == sermon!.id)
                })
                sermonsInSeries = sortSermonsByYear(seriesSermons, sorting: Constants.CHRONOLOGICAL)
            } else {
                sermonsInSeries = globals.sermons.all?.groupSort?[Grouping.TITLE]?[sermon!.seriesSort!]?[Constants.CHRONOLOGICAL]
            }
        } else {
            sermonsInSeries = [sermon!]
        }
    }
    
    return sermonsInSeries
}

func sermonsInBook(_ sermons:[Sermon]?,book:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.book == book
    }).sorted(by: { (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThan(second.fullDate!)
        }
    })
}

func booksFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasBook
            }).map({ (sermon:Sermon) -> String in
                return sermon.book!
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

func bookSectionsFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.hasBook ? sermon.book! : sermon.scripture != nil ? sermon.scripture! : Constants.None
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

func seriesFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    return sermon.hasSeries
                }).map({ (sermon:Sermon) -> String in
                    return sermon.series!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    return sermon.seriesSection!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromSermons(_ sermons:[Sermon]?,withTitles:Bool) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    if (sermon.hasSeries) {
                        return sermon.series!
                    } else {
                        return withTitles ? sermon.title! : Constants.Individual_Sermons
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


func lastNameFromName(_ name:String?) -> String?
{
    if var lastname = name {
        while (lastname.range(of: Constants.SINGLE_SPACE_STRING) != nil) {
            lastname = lastname.substring(from: lastname.range(of: Constants.SINGLE_SPACE_STRING)!.upperBound)
        }
        return lastname
    }
    return nil
}

func speakerSectionsFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.speakerSection!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func speakersFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasSpeaker
            }).map({ (sermon:Sermon) -> String in
                return sermon.speaker!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func sortSermonsChronologically(_ sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sorted() {
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

func sortSermonsReverseChronologically(_ sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sorted() {
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

func sortSermonsByYear(_ sermons:[Sermon]?,sorting:String?) -> [Sermon]?
{
    var sortedSermons:[Sermon]?

    switch sorting! {
    case Constants.CHRONOLOGICAL:
        sortedSermons = sortSermonsChronologically(sermons)
        break
        
    case Constants.REVERSE_CHRONOLOGICAL:
        sortedSermons = sortSermonsReverseChronologically(sermons)
        break
        
    default:
        break
    }
    
    return sortedSermons
}

func compareSermonDates(first:Sermon, second:Sermon, sorting:String?) -> Bool
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

func sortSermonsBySeries(_ sermons:[Sermon]?,sorting:String?) -> [Sermon]?
{
    return sermons?.sorted() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.seriesSectionSort != second.seriesSectionSort) {
            result = first.seriesSectionSort < second.seriesSectionSort
        } else {
            result = compareSermonDates(first: first,second: second, sorting: sorting)
        }

        return result
    }
}

func sortSermonsBySpeaker(_ sermons:[Sermon]?,sorting: String?) -> [Sermon]?
{
    return sermons?.sorted() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.speakerSectionSort != second.speakerSectionSort) {
            result = first.speakerSectionSort < second.speakerSectionSort
        } else {
            result = compareSermonDates(first: first,second: second, sorting: sorting)
        }
        
        return result
    }
}

func sortSermonsByBook(_ sermons:[Sermon]?, sorting:String?) -> [Sermon]?
{
    return sermons?.sorted() {
        let first = bookNumberInBible($0.book)
        let second = bookNumberInBible($1.book)
        
        var result = false
        
        if (first != nil) && (second != nil) {
            if (first != second) {
                result = first < second
            } else {
                result = compareSermonDates(first: $0,second: $1, sorting: sorting)
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
                            result = compareSermonDates(first: $0,second: $1, sorting: sorting)
                        }
        }
        
        return result
    }
}


func testSermonsPDFs(testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
    var counter = 1

    if (testExisting) {
        NSLog("Testing the availability of sermon transcripts and slides that we DO have in the sermonDicts - start")
        
        if let sermons = globals.sermonRepository.list {
            for sermon in sermons {
                if (showTesting) {
                    NSLog("Testing: \(counter) \(sermon.title!)")
                } else {
//                    NSLog(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.notes != nil) {
                    if ((try? Data(contentsOf: sermon.notesURL! as URL)) == nil) {
                        NSLog("Transcript DOES NOT exist for: \(sermon.title!) PDF: \(sermon.notes!)")
                    } else {
                        
                    }
                }
                
                if (sermon.slides != nil) {
                    if ((try? Data(contentsOf: sermon.slidesURL! as URL)) == nil) {
                        NSLog("Slides DO NOT exist for: \(sermon.title!) PDF: \(sermon.slides!)")
                    } else {
                        
                    }
                }
                
                counter += 1
            }
        }
        
        NSLog("\nTesting the availability of sermon transcripts and slides that we DO have in the sermonDicts - end")
    }

    if (testMissing) {
        NSLog("Testing the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - start")
        
        counter = 1
        if let sermons = globals.sermonRepository.list {
            for sermon in sermons {
                if (showTesting) {
                    NSLog("Testing: \(counter) \(sermon.title!)")
                } else {
//                    NSLog(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.audio == nil) {
                    NSLog("No Audio file for: \(sermon.title) can't test for PDF's")
                } else {
                    if (sermon.notes == nil) {
                        if ((try? Data(contentsOf: sermon.notesURL!)) != nil) {
                            NSLog("Transcript DOES exist for: \(sermon.title!) ID:\(sermon.id)")
                        } else {
                            
                        }
                    }
                    
                    if (sermon.slides == nil) {
                        if ((try? Data(contentsOf: sermon.slidesURL!)) != nil) {
                            NSLog("Slides DO exist for: \(sermon.title!) ID: \(sermon.id)")
                        } else {
                            
                        }
                    }
                }
                
                counter += 1
            }
        }
        
        NSLog("\nTesting the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - end")
    }
}

func testSermonsTagsAndSeries()
{
    NSLog("Testing for sermon series and tags the same - start")
    
    if let sermons = globals.sermonRepository.list {
        for sermon in sermons {
            if (sermon.hasSeries) && (sermon.hasTags) {
                if (sermon.series == sermon.tags) {
                    NSLog("Series and Tags the same in: \(sermon.title!) Series:\(sermon.series!) Tags:\(sermon.tags!)")
                }
            }
        }
    }
    
    NSLog("Testing for sermon series and tags the same - end")
}

func testSermonsForAudio()
{
    NSLog("Testing for audio - start")
    
    for sermon in globals.sermonRepository.list! {
        if (!sermon.hasAudio) {
            NSLog("Audio missing in: \(sermon.title!)")
        } else {

        }
    }
    
    NSLog("Testing for audio - end")
}

func testSermonsForSpeaker()
{
    NSLog("Testing for speaker - start")
    
    for sermon in globals.sermonRepository.list! {
        if (!sermon.hasSpeaker) {
            NSLog("Speaker missing in: \(sermon.title!)")
        }
    }
    
    NSLog("Testing for speaker - end")
}

func testSermonsForSeries()
{
    NSLog("Testing for sermons with \"(Part \" in the title but no series - start")
    
    for sermon in globals.sermonRepository.list! {
        if (sermon.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && sermon.hasSeries {
            NSLog("Series missing in: \(sermon.title!)")
        }
    }
    
    NSLog("Testing for sermons with \"(Part \" in the title but no series - end")
}

func testSermonsBooksAndSeries()
{
    NSLog("Testing for sermon series and book the same - start")

    for sermon in globals.sermonRepository.list! {
        if (sermon.hasSeries) && (sermon.hasBook) {
            if (sermon.series == sermon.book) {
                NSLog("Series and Book the same in: \(sermon.title!) Series:\(sermon.series!) Book:\(sermon.book!)")
            }
        }
    }

    NSLog("Testing for sermon series and book the same - end")
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

func sermonsWithTag(_ sermons:[Sermon]?,tag:String?) -> [Sermon]?
{
    return tag != nil ?
        sermons?.filter({ (sermon:Sermon) -> Bool in
            if let tagSet = sermon.tagsSet {
                return tagSet.contains(tag!)
            } else {
                return false
            }
        }) : nil
}

func tagsFromSermons(_ sermons:[Sermon]?) -> [String]?
{
    if sermons != nil {
        var tagsSet = Set<String>()

        for sermon in sermons! {
            if let tags = sermon.tagsSet {
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



