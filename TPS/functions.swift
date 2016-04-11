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

//typealias GroupTuple = (indexes: [Int]?, counts: [Int]?)

func documentsURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
}

func cachesURL() -> NSURL?
{
    let fileManager = NSFileManager.defaultManager()
    return fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first
}

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
//                print("Deleting: \(name)")
//                try fileManager.removeItemAtPath(path + name)
//            }
//        }
//    } catch _ {
//        print("failed to remove temp files")
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
//            print("failed to remove old json file")
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
//            print("failed to promote new json file from tmp to final")
//            
//            do {
//                try fileManager.moveItemAtURL(oldURL!, toURL: destinationURL!)
//            } catch _ {
//                print("failed to move json file back from old to current")
//            }
//        }
//    } catch _ {
//        print("failed to move current json file to old")
//    }
//}

func jsonDataFromURL() -> JSON
{
    if let url = NSURL(string: Constants.JSON_URL_PREFIX + Constants.CBC_SHORT.lowercaseString + "." + Constants.SERMONS_JSON_FILENAME) {
        do {
            let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }
    
    return nil
}

func jsonDataFromBundle() -> JSON
{
    if let path = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE) {
        do {
            let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from file, make sure that file contains valid json.")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } else {
        print("Invalid filename/path.")
    }

    return nil
}

func removeJSONFromFileSystemDirectory()
{
    if let jsonFileSystemURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        do {
            try NSFileManager.defaultManager().removeItemAtPath(jsonFileSystemURL.path!)
        } catch _ {
            print("failed to copy sermons.json")
        }
    }
}

func jsonToFileSystemDirectory()
{
    let fileManager = NSFileManager.defaultManager()
    
    let jsonBundlePath = NSBundle.mainBundle().pathForResource(Constants.JSON_ARRAY_KEY, ofType: Constants.JSON_TYPE)
    
    if let jsonFileURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        // Check if file exist
        if (!fileManager.fileExistsAtPath(jsonFileURL.path!)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileURL.path!)
                } catch _ {
                    print("failed to copy sermons.json")
                }
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItemAtPath(jsonBundlePath!)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItemAtPath(jsonFileURL.path!)
                
                let jsonBundleModDate = jsonBundleAttributes[NSFileModificationDate] as! NSDate
                let jsonDocumentsModDate = jsonDocumentsAttributes[NSFileModificationDate] as! NSDate
                
                if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
                    //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                    print("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                    print("JSON in Documents is the same date as JSON in bundle")
                    let jsonBundleFileSize = jsonBundleAttributes[NSFileSize] as! Int
                    let jsonDocumentsFileSize = jsonDocumentsAttributes[NSFileSize] as! Int
                    
                    if (jsonBundleFileSize != jsonDocumentsFileSize) {
                        print("Same dates different file sizes")
                        //We have a problem.
                    } else {
                        print("Same dates same file sizes")
                        //Do nothing, they are the same.
                    }
                }
                
                if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
                    print("JSON in bundle is newer than JSON in Documents")
                    //copy the bundle into Documents directory
                    do {
                        // Copy File From Bundle To Documents Directory
                        try fileManager.removeItemAtPath(jsonFileURL.path!)
                        try fileManager.copyItemAtPath(jsonBundlePath!,toPath: jsonFileURL.path!)
                    } catch _ {
                        print("failed to copy sermons.json")
                    }
                }
            } catch _ {
                print("failed to get json file attributes")
            }
        }
    }
}

func jsonDataFromDocumentsDirectory() -> JSON
{
    jsonToFileSystemDirectory()
    
    if let jsonURL = cachesURL()?.URLByAppendingPathComponent(Constants.SERMONS_JSON_FILENAME) {
        if let data = NSData(contentsOfURL: jsonURL) {
            let json = JSON(data: data)
            if json != JSON.null {
                return json
            } else {
                print("could not get json from data, make sure the file contains valid json.")
            }
        } else {
            print("could not get data from the json file.")
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
////            print("jsonInBundleModDate: \(jsonInBundleModDate)")
////            print("jsonInDocumentsModDate: \(jsonInDocumentsModDate)")
//            
//            if (jsonInDocumentsModDate.isOlderThan(jsonInBundleModDate)) {
//                //The JSON in the Bundle is newer, we need to use it instead of the archive
//                print("JSON in Documents is older than JSON in Bundle")
//                return nil
//            }
//            
//            if (jsonInDocumentsModDate.isEqualTo(jsonInBundleModDate)) {
//                //This is normal since JSON in Documents is copied from JSON in Bundle.  Do nothing.
//                print("JSON in Bundle and in Documents are the same date")
//            }
//            
//            if (jsonInDocumentsModDate.isNewerThan(jsonInBundleModDate)) {
//                //The JSON in Documents is newer, we need to see if it is newer than the archive.
//                print("JSON in Documents is newer than JSON in Bundle")
//            }
//        } catch _ {
//            print("failed to get json file attributes")
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
////            print("archiveInDocumentsModDate: \(archiveInDocumentsModDate)")
//            
//            if (jsonInDocumentsModDate.isNewerThan(archiveInDocumentsModDate)) {
//                //Do nothing, the json in Documents is newer, i.e. it was downloaded after the archive was created.
//                print("JSON in Documents is newer than Archive in Documents")
//                return nil
//            }
//            
//            if (archiveInDocumentsModDate.isEqualTo(jsonInDocumentsModDate)) {
//                //Should never happen since archive is created from JSON
//                print("JSON in Documents is the same date as Archive in Documents")
//                return nil
//            }
//            
//            if (archiveInDocumentsModDate.isNewerThan(jsonInDocumentsModDate)) {
//                print("Archive in Documents is newer than JSON in Documents")
//                
//                let data = NSData(contentsOfURL: NSURL(fileURLWithPath: archiveFileSystemURL!.path!))
//                if (data != nil) {
//                    let sermons = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [Sermon]
//                    if sermons != nil {
//                        return sermons
//                    } else {
//                        print("could not get sermons from archive.")
//                    }
//                } else {
//                    print("could not get data from archive.")
//                }
//            }
//        } catch _ {
//            print("failed to get json file attributes")
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
//            print("Finished saving the sermon archive.")
//        }
//    }
//}

func loadSermonDicts() -> [[String:String]]?
{
    var sermonDicts = [[String:String]]()
    
    let json = jsonDataFromDocumentsDirectory()
    
    if json != JSON.null {
        //                print("json:\(json)")
        
        let sermons = json[Constants.JSON_ARRAY_KEY]
        
        for i in 0..<sermons.count {
            
            var dict = [String:String]()
            
            for (key,value) in sermons[i] {
                dict["\(key)"] = "\(value)"
            }
            
            sermonDicts.append(dict)
        }
        
        return sermonDicts.count > 0 ? sermonDicts : nil
    } else {
        print("could not get json from file, make sure that file contains valid json.")
    }
    
    return nil
}

extension NSDate
{
    convenience
    init(dateString:String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "MM/dd/yyyy"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let d = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval:0, sinceDate:d)
    }
    
    func isNewerThan(dateToCompare : NSDate) -> Bool
    {
        return (self.compare(dateToCompare) == NSComparisonResult.OrderedDescending) && (self.compare(dateToCompare) != NSComparisonResult.OrderedSame)
    }
    
    
    func isOlderThan(dateToCompare : NSDate) -> Bool
    {
        return (self.compare(dateToCompare) == NSComparisonResult.OrderedAscending) && (self.compare(dateToCompare) != NSComparisonResult.OrderedSame)
    }
    

    func isEqualTo(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedSame
    }

    func addDays(daysToAdd : Int) -> NSDate
    {
        let secondsInDays : NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd : Int) -> NSDate
    {
        let secondsInHours : NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}

func stringWithoutPrefixes(fromString:String?) -> String?
{
    var sortString = fromString

    let quote:String = "\""
    let prefixes = ["A ","An ","And ","The "]
    
    if (fromString?.endIndex >= quote.endIndex) && (fromString?.substringToIndex(quote.endIndex) == quote) {
        sortString = fromString!.substringFromIndex(quote.endIndex)
    }
    
    for prefix in prefixes {
        if (fromString?.endIndex >= prefix.endIndex) && (fromString?.substringToIndex(prefix.endIndex) == prefix) {
            sortString = fromString!.substringFromIndex(prefix.endIndex)
            break
        }
    }

    return sortString
}

func sortSermons(sermons:[Sermon]?, sorting:String?, grouping:String?) -> [Sermon]?
{
    var result:[Sermon]?
    
    switch grouping! {
    case Constants.YEAR:
        result = sortSermonsByYear(sermons,sorting: sorting)
        break
        
    case Constants.SERIES:
        result = sortSermonsBySeries(sermons,sorting: sorting)
        break
        
    case Constants.BOOK:
        result = sortSermonsByBook(sermons,sorting: sorting)
        break
        
    case Constants.SPEAKER:
        result = sortSermonsBySpeaker(sermons,sorting: sorting)
        break
        
    default:
        result = nil
        break
    }
    
    return result
}


func sermonSections(sermons:[Sermon]?,sorting:String?,grouping:String?) -> [String]?
{
    var strings:[String]?
    
    switch grouping! {
    case Constants.YEAR:
        strings = yearsFromSermons(sermons, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case Constants.SERIES:
        strings = seriesSectionsFromSermons(sermons)
        break
        
    case Constants.BOOK:
        strings = bookSectionsFromSermons(sermons)
        break
        
    case Constants.SPEAKER:
        strings = speakerSectionsFromSermons(sermons)
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func yearsFromSermons(sermons:[Sermon]?, sorting: String?) -> [Int]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    assert(sermon.fullDate != nil) // We're assuming this gets ALL sermons.
                    return sermon.fullDate != nil
                }).map({ (sermon:Sermon) -> Int in
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components(.Year, fromDate: sermon.fullDate!)
                    return components.year
                })
            )
            ).sort({ (first:Int, second:Int) -> Bool in
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


func testament(book:String) -> String
{
    if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
        return Constants.Old_Testament
    } else
        if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
            return Constants.New_Testament
    }
    
    return ""
}

func chaptersFromScripture(scripture:String?) -> [Int]
{
    var chapters = [Int]()
    
    var colonCount = 0
    
    if (scripture != nil) {
        let string = scripture?.stringByReplacingOccurrencesOfString(Constants.SINGLE_SPACE_STRING, withString: Constants.EMPTY_STRING)
        
        //        if (string!.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
        //            string = string?.substringFromIndex(string!.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
        //        } else {
        //            return []
        //        }
        
        if (string == "") {
            return []
        }
        
        //        print("\(string!)")
        
        let colon = string!.rangeOfString(":")
        let hyphen = string!.rangeOfString("-")
        let comma = string!.rangeOfString(",")
        
        if (colon == nil) && (hyphen == nil) &&  (comma == nil) {
            chapters = [Int(string!)!]
        } else {
            var chars = ""
            
            var seenColon = false
            var seenHyphen = false
            var seenComma = false
            
            var startChapter = 0
            var endChapter = 0
            
            for character in string!.characters {
                switch character {
                case ":":
                    if !seenColon {
                        seenColon = true
                        if (startChapter == 0) {
                            startChapter = Int(chars)!
                        } else {
                            endChapter = Int(chars)!
                        }
                    } else {
                        if (seenHyphen) {
                            endChapter = Int(chars)!
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
                    if !seenColon {
                        // This is a chapter not a verse
                        if (startChapter == 0) {
                            startChapter = Int(chars)!
                        }
                    }
                    chars = ""
                    break
                    
                case ",":
                    seenComma = true
                    if !seenColon {
                        // This is a chapter not a verse
                        chapters.append(Int(chars)!)
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
            if (colonCount == 1) {
                chapters.append(startChapter)
            }
            if (startChapter != 0) && (endChapter == 0) && (colonCount == 0) {
                endChapter = Int(chars)!
                chars = ""
            }
            if (startChapter != 0) && (endChapter != 0) {
                for chapter in startChapter...endChapter {
                    chapters.append(chapter)
                }
            }
            
            //            if (colon != nil) {
            //                let stringToColon = string?.substringToIndex(colon!.startIndex)
            //
            //                print("stringToColon: \(stringToColon)")
            //
            //                chapters = [Int(stringToColon!)!]
            //
            //                let stringFromColon = string?.substringFromIndex(colon!.endIndex)
            //
            //                print("stringFromColon: \(stringFromColon)")
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
            //                    //                            print("\(chapters)")
            //                    //                            print("\(chapters)")
            //                }
            //                if (comma != nil) {
            //                    let stringToComma = string?.substringToIndex(comma!.startIndex)
            //                    let startingChapter = Int(stringToComma!)!
            //                    chapters = [startingChapter]
            //
            //                    let stringFromComma = string?.substringFromIndex(comma!.endIndex)
            //                    let endingChapter = Int(stringFromComma!)!
            //                    chapters.append(endingChapter)
            //                    //                            print("\(chapters)")
            //                    //                            print("\(chapters)")
            //                }
            //            }
        }
    }
    
//    if (colonCount > 1) || (chapters.count > 1) {
//        print("\(scripture)")
//        print("\(chapters)")
////        print("ERROR")
//    }
    
    //    print("\(scripture)")
    //    print("\(chapters)")
    
    return chapters
}

func booksFromScripture(scripture:String?) -> [String]
{
    var books = [String]()
    
    if (scripture != nil) {
        var string:String?
        
        string = scripture
        
        for book in Constants.OLD_TESTAMENT_BOOKS {
            if string?.rangeOfString(book) != nil {
                books.append(book)
                string = string!.substringToIndex(string!.rangeOfString(book)!.startIndex) + " " + string!.substringFromIndex(string!.rangeOfString(book)!.endIndex)
            }
        }
        
        string = scripture
        
        for book in Constants.NEW_TESTAMENT_BOOKS.reverse() {
            if string?.rangeOfString(book) != nil {
                books.append(book)
                string = string!.substringToIndex(string!.rangeOfString(book)!.startIndex) + " " + string!.substringFromIndex(string!.rangeOfString(book)!.endIndex)
            }
        }
    }
    
    return books
}

func sermonsInSermonSeries(sermon:Sermon?) -> [Sermon]?
{
    var sermonsInSeries:[Sermon]?
    
    if (sermon != nil) {
        if (sermon!.hasSeries()) {
            if (globals.sermons.all?.groupSort?[Constants.SERIES]?[sermon!.seriesSort!]?[Constants.CHRONOLOGICAL] == nil) {
                let seriesSermons = globals.sermonRepository.list?.filter({ (testSermon:Sermon) -> Bool in
                    return sermon!.hasSeries() ? (testSermon.series == sermon!.series) : (testSermon.id == sermon!.id)
                })
                sermonsInSeries = sortSermonsByYear(seriesSermons, sorting: Constants.CHRONOLOGICAL)
            } else {
                sermonsInSeries = globals.sermons.all?.groupSort?[Constants.SERIES]?[sermon!.seriesSort!]?[Constants.CHRONOLOGICAL]
            }
        } else {
            sermonsInSeries = [sermon!]
        }
    }
    
    return sermonsInSeries
}

func sermonsInBook(sermons:[Sermon]?,book:String?) -> [Sermon]?
{
    return sermons?.filter({ (sermon:Sermon) -> Bool in
        return sermon.book == book
    }).sort({ (first:Sermon, second:Sermon) -> Bool in
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            return first.service < second.service
        } else {
            return first.fullDate!.isOlderThan(second.fullDate!)
        }
    })
}

func booksFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasBook()
            }).map({ (sermon:Sermon) -> String in
                return sermon.book!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
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

func bookSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.hasBook() ? sermon.book! : sermon.scripture != nil ? sermon.scripture! : Constants.None
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
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

func seriesFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.filter({ (sermon:Sermon) -> Bool in
                    return sermon.hasSeries()
                }).map({ (sermon:Sermon) -> String in
                    return sermon.series!
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    return sermon.seriesSection!
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}

func seriesSectionsFromSermons(sermons:[Sermon]?,withTitles:Bool) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(
                sermons!.map({ (sermon:Sermon) -> String in
                    if (sermon.hasSeries()) {
                        return sermon.series!
                    } else {
                        return withTitles ? sermon.title! : Constants.Individual_Sermons
                    }
                })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
        : nil
}


func bookNumberInBible(book:String?) -> Int?
{
    if (book != nil) {
        if let index = Constants.OLD_TESTAMENT_BOOKS.indexOf(book!) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT_BOOKS.indexOf(book!) {
            return Constants.OLD_TESTAMENT_BOOKS.count + index
        }
        
        return Constants.OLD_TESTAMENT_BOOKS.count + Constants.NEW_TESTAMENT_BOOKS.count + 1 // Not in the Bible.  E.g. Selected Scriptures
    } else {
        return nil
    }
}


func lastNameFromName(name:String?) -> String?
{
    if var lastname = name {
        while (lastname.rangeOfString(Constants.SINGLE_SPACE_STRING) != nil) {
            lastname = lastname.substringFromIndex(lastname.rangeOfString(Constants.SINGLE_SPACE_STRING)!.endIndex)
        }
        return lastname
    }
    return nil
}

func speakerSectionsFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.map({ (sermon:Sermon) -> String in
                return sermon.speakerSection!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func speakersFromSermons(sermons:[Sermon]?) -> [String]?
{
    return sermons != nil ?
        Array(
            Set(sermons!.filter({ (sermon:Sermon) -> Bool in
                return sermon.hasSpeaker()
            }).map({ (sermon:Sermon) -> String in
                return sermon.speaker!
            })
            )
            ).sort({ (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
        : nil
}

func sortSermonsChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            return $0.service < $1.service
        } else {
            return $0.fullDate!.isOlderThan($1.fullDate!)
        }
    }
}

func sortSermonsReverseChronologically(sermons:[Sermon]?) -> [Sermon]?
{
    return sermons?.sort() {
        if ($0.fullDate!.isEqualTo($1.fullDate!)) {
            return $0.service > $1.service
        } else {
            return $0.fullDate!.isNewerThan($1.fullDate!)
        }
    }
}

func sortSermonsByYear(sermons:[Sermon]?,sorting:String?) -> [Sermon]?
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

func compareSermonDates(first first:Sermon, second:Sermon, sorting:String?) -> Bool
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

func sortSermonsBySeries(sermons:[Sermon]?,sorting:String?) -> [Sermon]?
{
    return sermons?.sort() {
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

func sortSermonsBySpeaker(sermons:[Sermon]?,sorting: String?) -> [Sermon]?
{
    return sermons?.sort() {
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

func sortSermonsByBook(sermons:[Sermon]?, sorting:String?) -> [Sermon]?
{
    return sermons?.sort() {
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


func testSermonsPDFs(testExisting testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
    var counter = 1

    if (testExisting) {
        print("Testing the availability of sermon transcripts and slides that we DO have in the sermonDicts - start")
        
        if let sermons = globals.sermonRepository.list {
            for sermon in sermons {
                if (showTesting) {
                    print("Testing: \(counter) \(sermon.title!)")
                } else {
                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.notes != nil) {
                    if (NSData(contentsOfURL: sermon.notesURL!) == nil) {
                        print("Transcript DOES NOT exist for: \(sermon.title!) PDF: \(sermon.notes!)")
                    } else {
                        
                    }
                }
                
                if (sermon.slides != nil) {
                    if (NSData(contentsOfURL: sermon.slidesURL!) == nil) {
                        print("Slides DO NOT exist for: \(sermon.title!) PDF: \(sermon.slides!)")
                    } else {
                        
                    }
                }
                
                counter += 1
            }
        }
        
        print("\nTesting the availability of sermon transcripts and slides that we DO have in the sermonDicts - end")
    }

    if (testMissing) {
        print("Testing the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - start")
        
        counter = 1
        if let sermons = globals.sermonRepository.list {
            for sermon in sermons {
                if (showTesting) {
                    print("Testing: \(counter) \(sermon.title!)")
                } else {
                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (sermon.audio == nil) {
                    print("No Audio file for: \(sermon.title) can't test for PDF's")
                } else {
                    if (sermon.notes == nil) {
                        let testString = "tp150705a"
                        let testNotes = Constants.TRANSCRIPT_PREFIX + sermon.audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
                        //                print("Notes file s/b: \(testNotes)")
                        let notesURL = Constants.BASE_PDF_URL + testNotes
                        //                print("<a href=\"\(notesURL)\" target=\"_blank\">\(sermon.title!) Notes</a><br/>")
                        
                        if (NSData(contentsOfURL: NSURL(string: notesURL)!) != nil) {
                            print("Transcript DOES exist for: \(sermon.title!) PDF: \(testNotes)")
                        } else {
                            
                        }
                    }
                    
                    if (sermon.slides == nil) {
                        let testString = "tp150705a"
                        let testSlides = sermon.audio!.substringToIndex(testString.endIndex) + Constants.PDF_FILE_EXTENSION
                        //                print("Slides file s/b: \(testSlides)")
                        let slidesURL = Constants.BASE_PDF_URL + testSlides
                        //                print("<a href=\"\(slidesURL)\" target=\"_blank\">\(sermon.title!) Slides</a><br/>")
                        
                        if (NSData(contentsOfURL: NSURL(string: slidesURL)!) != nil) {
                            print("Slides DO exist for: \(sermon.title!) PDF: \(testSlides)")
                        } else {
                            
                        }
                    }
                }
                
                counter += 1
            }
        }
        
        print("\nTesting the availability of sermon transcripts and slides that we DO NOT have in the sermonDicts - end")
    }
}

func testSermonsTagsAndSeries()
{
    print("Testing for sermon series and tags the same - start")
    
    if let sermons = globals.sermonRepository.list {
        for sermon in sermons {
            if (sermon.hasSeries()) && (sermon.hasTags()) {
                if (sermon.series == sermon.tags) {
                    print("Series and Tags the same in: \(sermon.title!) Series:\(sermon.series!) Tags:\(sermon.tags!)")
                }
            }
        }
    }
    
    print("Testing for sermon series and tags the same - end")
}

func testSermonsForAudio()
{
    print("Testing for audio - start")
    
    for sermon in globals.sermonRepository.list! {
        if (!sermon.hasAudio()) {
            print("Audio missing in: \(sermon.title!)")
        } else {

        }
    }
    
    print("Testing for audio - end")
}

func testSermonsForSpeaker()
{
    print("Testing for speaker - start")
    
    for sermon in globals.sermonRepository.list! {
        if (!sermon.hasSpeaker()) {
            print("Speaker missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for speaker - end")
}

func testSermonsForSeries()
{
    print("Testing for sermons with \"(Part \" in the title but no series - start")
    
    for sermon in globals.sermonRepository.list! {
        if (sermon.title?.rangeOfString("(Part ", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil) && sermon.hasSeries() {
            print("Series missing in: \(sermon.title!)")
        }
    }
    
    print("Testing for sermons with \"(Part \" in the title but no series - end")
}

func testSermonsBooksAndSeries()
{
    print("Testing for sermon series and book the same - start")

    for sermon in globals.sermonRepository.list! {
        if (sermon.hasSeries()) && (sermon.hasBook()) {
            if (sermon.series == sermon.book) {
                print("Series and Book the same in: \(sermon.title!) Series:\(sermon.series!) Book:\(sermon.book!)")
            }
        }
    }

    print("Testing for sermon series and book the same - end")
}

func tagsSetFromTagsString(tagsString:String?) -> Set<String>?
{
    var tags = tagsString
    var tag:String
    var setOfTags = Set<String>()
    
    while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
        tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
        setOfTags.insert(tag)
        tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
    }
    
    if (tags != nil) {
        setOfTags.insert(tags!)
    }
    
    return setOfTags.count > 0 ? setOfTags : nil
}

func tagsArrayToTagsString(tagsArray:[String]?) -> String?
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

func tagsArrayFromTagsString(tagsString:String?) -> [String]?
{
    var arrayOfTags:[String]?
    
    if let tags = tagsSetFromTagsString(tagsString) {
        arrayOfTags = Array(tags) //.sort() { $0 < $1 } // .sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) } // Not sorted
    }
    
    return arrayOfTags
}

func sermonsWithTag(sermons:[Sermon]?,tag:String?) -> [Sermon]?
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

func tagsFromSermons(sermons:[Sermon]?) -> [String]?
{
    if sermons != nil {
        var tagsSet = Set<String>()

        for sermon in sermons! {
            if let tags = sermon.tagsSet {
                tagsSet.unionInPlace(tags)
            }
        }
        
        var tagsArray = Array(tagsSet).sort({ stringWithoutPrefixes($0) < stringWithoutPrefixes($1) })

        tagsArray.append(Constants.All)
        
    //    print("Tag Set: \(tagsSet)")
    //    print("Tag Array: \(tagsArray)")
        
        return tagsArray.count > 0 ? tagsArray : nil
    }
    
    return nil
}

func sermonsFromSermonDicts(sermonDicts:[[String:String]]?) -> [Sermon]?
{
    if (sermonDicts != nil) {
        return sermonDicts?.map({ (sermonDict:[String : String]) -> Sermon in
            Sermon(dict: sermonDict)
        })
    }
    
    return nil
}


