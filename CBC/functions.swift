//
//  functions.swift
//  CBC
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit
import MessageUI
import UserNotifications

public extension UIDevice
{
    var isSimulator : Bool
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "i386":
            fallthrough
        case "x86_64":
            return true
            
        default:
            return false
        }
    }
    
    var deviceName : String
    {
        get {
            if UIDevice.current.isSimulator {
                return "\(UIDevice.current.name):\(UIDevice.current.modelName)"
            } else {
                return UIDevice.current.name
            }
        }
    }
    
    var modelName: String
    {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "i386":
            fallthrough
        case "x86_64":
            if let id = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                identifier = id
            }
            
        default:
            break
        }
        
        var modelName: String

        switch identifier {
        case "iPhone1,1": modelName = "iPhone"
        case "iPhone1,2": modelName = "iPhone 3G"
            
        case "iPhone2,1": modelName = "iPhone 3GS"
        
        case "iPhone3,1": modelName = "iPhone 4 (GSM)"
        case "iPhone3,2": modelName = "iPhone 4 (GSM Rev A)"
        case "iPhone3,3": modelName = "iPhone 4 (CDMA)"
        
        case "iPhone4,1": modelName = "iPhone 4S"
        
        case "iPhone5,1": modelName = "iPhone 5 (GSM)"
        case "iPhone5,2": modelName = "iPhone 5 (CDMA)"
        
        case "iPhone5,3": modelName = "iPhone 5c (GSM)"
        case "iPhone5,4": modelName = "iPhone 5c (CDMA)"
        
        case "iPhone6,1": modelName = "iPhone 5s (GSM)"
        case "iPhone6,2": modelName = "iPhone 5s (CDMA)"
            
        case "iPhone7,1": modelName = "iPhone 6 Plus"
        case "iPhone7,2": modelName = "iPhone 6"
        
        case "iPhone8,1": modelName = "iPhone 6s"
        case "iPhone8,2": modelName = "iPhone 6s Plus"
        
        case "iPhone8,4": modelName = "iPhone SE"
            
        case "iPhone9,1": modelName = "iPhone 7 (CDMA+GSM)"
        case "iPhone9,2": modelName = "iPhone 7 Plus (CDMA+GSM)"
        case "iPhone9,3": modelName = "iPhone 7 (GSM)"
        case "iPhone9,4": modelName = "iPhone 7 Plus (GSM)"
            
        case "iPod1,1": modelName = "iPod Touch 1st Generation"
        case "iPod2,1": modelName = "iPod Touch 2nd Generation"
        case "iPod3,1": modelName = "iPod Touch 3rd Generation"
        case "iPod4,1": modelName = "iPod Touch 4th Generation"
        case "iPod5,1": modelName = "iPod Touch 5th Generation"
            
        case "iPod7,1": modelName = "iPod Touch 6th Generation"
            
        case "iPad1,1": modelName = "iPad"
        
        case "iPad2,1": modelName = "iPad 2 (WiFi)"
        case "iPad2,2": modelName = "iPad 2 (WiFi+GSM)"
        case "iPad2,3": modelName = "iPad 2 (WiFi+CDMA)"
        case "iPad2,4": modelName = "iPad 2 (WiFi, revised)"
        
        case "iPad2,5": modelName = "iPad Mini (WiFi)"
        case "iPad2,6": modelName = "iPad Mini (WiFi+GSM)"
        case "iPad2,7": modelName = "iPad Mini (WiFi+GSM+CDMA)"
            
        case "iPad3,1": modelName = "iPad 3rd Generation (WiFi)"
        case "iPad3,2": modelName = "iPad 3rd Generation (WiFi+GSM+CDMA)"
        case "iPad3,3": modelName = "iPad 3rd Generation (WiFi+GSM)"
        
        case "iPad3,4": modelName = "iPad 4th Generation (WiFi)"
        case "iPad3,5": modelName = "iPad 4th Generation (WiFi+GSM)"
        case "iPad3,6": modelName = "iPad 4th Generation (WiFi+GSM+CDMA)"
            
        case "iPad4,1": modelName = "iPad Air (WiFi)"
        case "iPad4,2": modelName = "iPad Air (WiFi+Cellular)"
        case "iPad4,3": modelName = "iPad Air (revised)"
            
        case "iPad4,4": modelName = "iPad mini 2 (WiFi)"
        case "iPad4,5": modelName = "iPad mini 2 (WiFi+Cellular)"
        case "iPad4,6": modelName = "iPad mini 2 (revised)"
            
        case "iPad4,7": modelName = "iPad mini 3 (WiFi)"
        case "iPad4,8": modelName = "iPad mini 3 (WiFi+Cellular)"
        case "iPad4,9": modelName = "iPad mini 3 (China Model)"
            
        case "iPad5,1": modelName = "iPad mini 4 (WiFi)"
        case "iPad5,2": modelName = "iPad mini 4 (WiFi+Cellular)"
            
        case "iPad5,3": modelName = "iPad Air 2 (WiFi)"
        case "iPad5,4": modelName = "iPad Air 2 (WiFi+Cellular)"
            
        case "iPad6,3": modelName = "iPad Pro (9.7 inch) (WiFi)"
        case "iPad6,4": modelName = "iPad Pro (9.7 inch) (WiFi+Cellular)"
            
        case "iPad6,7": modelName = "iPad Pro (12.9 inch) (WiFi)"
        case "iPad6,8": modelName = "iPad Pro (12.9 inch) (WiFi+Cellular)"
            
        case "iPad7,3": modelName = "iPad Pro (10.5 inch) (WiFi)"
        case "iPad7,4": modelName = "iPad Pro (10.5 inch) (WiFi+Cellular)"
            
        default: modelName = "Unknown"
        }
        
        return modelName
    }
}

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
    } catch let error as NSError {
        print("failed to get files in caches directory: \(error.localizedDescription)")
    }
    
    return files.count > 0 ? files : nil
}

func jsonToFileSystemDirectory(key:String)
{
    let fileManager = FileManager.default
    
    let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE)
    
    if let filename = globals.mediaCategory.filename, let jsonFileURL = cachesURL()?.appendingPathComponent(filename) {
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
            if (jsonBundlePath != nil) {
                do {
                    // Copy File From Bundle To Documents Directory
                    try fileManager.copyItem(atPath: jsonBundlePath!,toPath: jsonFileURL.path)
                } catch let error as NSError {
                    print("failed to copy mediaItems.json: \(error.localizedDescription)")
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
                    print("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                    print("JSON in Documents is the same date as JSON in bundle")
                    let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as! Int
                    let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as! Int
                    
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
                        try fileManager.removeItem(atPath: jsonFileURL.path)
                        try fileManager.copyItem(atPath: jsonBundlePath!,toPath: jsonFileURL.path)
                    } catch let error as NSError {
                        print("failed to copy mediaItems.json: \(error.localizedDescription)")
                    }
                }
            } catch let error as NSError {
                print("failed to get json file attributes: \(error.localizedDescription)")
            }
        }
    }
}

func jsonDataFromDocumentsDirectory() -> JSON
{
    jsonToFileSystemDirectory(key:Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES)
    
    if let filename = globals.mediaCategory.filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
        if let data = try? Data(contentsOf: jsonURL) {
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

func jsonDataFromCachesDirectory(filename:String?) -> JSON
{
    if let filename = filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
        if let data = try? Data(contentsOf: jsonURL) {
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

extension Date
{
    //MARK: Date extension

    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: dateString)!
        self = Date(timeInterval:0, since:d)
    }
    
    init(string:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "MMM dd, yyyy"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: string)!
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
    if let range = fromString?.range(of: "A is "), range.lowerBound == "a".startIndex {
        return fromString
    }
    
    let sourceString = fromString?.replacingOccurrences(of: Constants.QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
//    print(sourceString)
    
    let prefixes = ["A ","An ","The "] // "And ",
    
    var sortString = sourceString
    
    for prefix in prefixes {
        if (sourceString?.endIndex >= prefix.endIndex) && (sourceString?.substring(to: prefix.endIndex).lowercased() == prefix.lowercased()) {
            sortString = sourceString!.substring(from: prefix.endIndex)
            break
        }
    }

    if sortString == "" {
        print(sortString as Any)
    }

    return sortString
}

func mediaItemSections(_ mediaItems:[MediaItem]?,sorting:String?,grouping:String?) -> [String]?
{
    var strings:[String]?
    
    switch grouping! {
    case GROUPING.YEAR:
        strings = yearsFromMediaItems(mediaItems, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case GROUPING.TITLE:
        strings = seriesSectionsFromMediaItems(mediaItems,withTitles: true)
        break
        
    case GROUPING.BOOK:
        strings = bookSectionsFromMediaItems(mediaItems)
        break
        
    case GROUPING.SPEAKER:
        strings = speakerSectionsFromMediaItems(mediaItems)
        break
        
    case GROUPING.CLASS:
        strings = classSectionsFromMediaItems(mediaItems)
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
                case SORTING.CHRONOLOGICAL:
                    return first < second
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return first > second
                    
                default:
                    break
                }
                
                return false
            })
        : nil
}

func verifyNASB()
{
    if Constants.OLD_TESTAMENT_BOOKS.count != 39 {
        print("ERROR: ","\(Constants.OLD_TESTAMENT_BOOKS.count)")
    }
    
    for book in Constants.OLD_TESTAMENT_BOOKS {
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
            let chapters = Constants.OLD_TESTAMENT_CHAPTERS[index]
            
            let dict = Scripture(reference: "\(book) \(chapters+1):1").loadJSONVerseFromURL()
            
            let passages = (((dict?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
            
            if passages?.count != 0 {
                print("ERROR: ","\(book) \(chapters)")
                print(passages as Any)
            }
            
            if Constants.OLD_TESTAMENT_VERSES[index].count != chapters {
                print("ERROR: WRONG COUNT IN VERSES ARRAY: ",book)
            }
            
            for chapter in 0..<chapters {
                let verses = Constants.OLD_TESTAMENT_VERSES[index][chapter]
                
                let dict1 = Scripture(reference: "\(book) \(chapter+1):\(verses)").loadJSONVerseFromURL()
                
                let passages1 = (((dict1?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                let dict2 = Scripture(reference: "\(book) \(chapter+1):\(verses + 1)").loadJSONVerseFromURL()
                
                let passages2 = (((dict2?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                if (passages1?.count != 1) || (passages2?.count != 0) {
                    print("ERROR: ","\(book) \(chapter+1):\(verses)")
                    print(passages1 as Any)
                    print(passages2 as Any)
                }
            }
        }
    }
    
    if Constants.NEW_TESTAMENT_BOOKS.count != 27 {
        print("ERROR: ","\(Constants.NEW_TESTAMENT_BOOKS.count)")
    }
    
    for book in Constants.NEW_TESTAMENT_BOOKS {
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
            let chapters = Constants.NEW_TESTAMENT_CHAPTERS[index]
            
            let dict = Scripture(reference: "\(book) \(chapters+1):1").loadJSONVerseFromURL()
            
            let passages = (((dict?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
            
            if passages?.count != 0 {
                print("ERROR: ","\(book) \(chapters)")
                print(passages as Any)
            }
            
            if Constants.NEW_TESTAMENT_VERSES[index].count != chapters {
                print("ERROR: WRONG COUNT IN VERSES ARRAY: ",book)
            }
            
            for chapter in 0..<chapters {
                let verses = Constants.NEW_TESTAMENT_VERSES[index][chapter]
                
                let dict1 = Scripture(reference: "\(book) \(chapter+1):\(verses)").loadJSONVerseFromURL()
                
                let passages1 = (((dict1?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                let dict2 = Scripture(reference: "\(book) \(chapter+1):\(verses + 1)").loadJSONVerseFromURL()
                
                let passages2 = (((dict2?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                if (passages1?.count != 1) || (passages2?.count != 0) {
                    print("ERROR: ","\(book) \(chapter+1):\(verses)")
                    print(passages1 as Any)
                    print(passages2 as Any)
                }
            }
        }
    }
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

func versessFromScripture(_ scripture:String?) -> [Int]?
{
    var verses = [Int]()

    if (scripture != nil) {
        var string = scripture?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        if (string == Constants.EMPTY_STRING) {
            return []
        }
        
        let colon = string?.range(of: ":")
//        let hyphen = string?.range(of: "-")
//        let comma = string?.range(of: ",")
        
        //Is not correct for books with only one chapter
        // e.g. ["Philemon","Jude","2 John","3 John"]
        if colon == nil {
            return []
        }

        string = string?.substring(from: colon!.upperBound)
        
        var chars = Constants.EMPTY_STRING
        
        var seenHyphen = false
        var seenComma = false
        
        var startVerse = 0
        var endVerse = 0
        
        var breakOut = false
        
        for character in string!.characters {
            if breakOut {
                break
            }
            switch character {
            case "–":
                fallthrough
            case "-":
                seenHyphen = true
                if (startVerse == 0) {
                    if Int(chars) != nil {
                        startVerse = Int(chars)!
                    }
                }
                chars = Constants.EMPTY_STRING
                break
                
            case "(":
                breakOut = true
                break
                
            case ",":
                seenComma = true
                if (Int(chars) != nil) {
                    verses.append(Int(chars)!)
                }
                chars = Constants.EMPTY_STRING
                break
                
            default:
                chars.append(character)
//                print(chars)
                break
            }
        }
        if !seenHyphen {
            if Int(chars) != nil {
                startVerse = Int(chars)!
            }
        }
        if (startVerse != 0) {
            if (endVerse == 0) {
                if (Int(chars) != nil) {
                    endVerse = Int(chars)!
                }
                chars = Constants.EMPTY_STRING
            }
            if (endVerse != 0) {
                for verse in startVerse...endVerse {
                    verses.append(verse)
                }
            } else {
                verses.append(startVerse)
            }
        }
        if seenComma {
            if Int(chars) != nil {
                verses.append(Int(chars)!)
            }
        }
    }
    
    return verses.count > 0 ? verses : nil
}

func debug(_ string:String)
{
//    print(string)
}

func chaptersAndVersesForBook(_ book:String?) -> [Int:[Int]]?
{
    guard (book != nil) else {
        return nil
    }
    
    var chaptersAndVerses = [Int:[Int]]()
    
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0

    startChapter = 1
    
    switch testament(book!) {
    case Constants.Old_Testament:
        endChapter = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.index(of: book!)!]
        break
        
    case Constants.New_Testament:
        endChapter = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.index(of: book!)!]
        break
        
    default:
        break
    }
    
    for chapter in startChapter...endChapter {
        startVerse = 1
        
        switch testament(book!) {
        case Constants.Old_Testament:
            endVerse = Constants.OLD_TESTAMENT_VERSES[Constants.OLD_TESTAMENT_BOOKS.index(of: book!)!][chapter - 1]
            break
            
        case Constants.New_Testament:
            endVerse = Constants.NEW_TESTAMENT_VERSES[Constants.NEW_TESTAMENT_BOOKS.index(of: book!)!][chapter - 1]
            break
            
        default:
            break
        }
        
        for verse in startVerse...endVerse {
            if chaptersAndVerses[chapter] == nil {
                chaptersAndVerses[chapter] = [verse]
            } else {
                chaptersAndVerses[chapter]?.append(verse)
            }
        }
    }
    
    return chaptersAndVerses
}

func versesForBookChapter(_ book:String?,_ chapter:Int) -> [Int]?
{
    guard book != nil else {
        return nil
    }
 
    var verses = [Int]()
    
    let startVerse = 1
    var endVerse = 0
    
    switch testament(book!) {
    case Constants.Old_Testament:
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
            index < Constants.OLD_TESTAMENT_VERSES.count,
            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
        }
        break
    case Constants.New_Testament:
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
            index < Constants.NEW_TESTAMENT_VERSES.count,
            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
            endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
        }
        break
    default:
        break
    }
    
    if startVerse == endVerse {
        verses.append(startVerse)
    } else {
        if endVerse >= startVerse {
            for verse in startVerse...endVerse {
                verses.append(verse)
            }
        }
    }
    
    if verses.count == 0 {
        switch testament(book!) {
        case Constants.Old_Testament:
//            let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!)
//            print(Constants.OLD_TESTAMENT_BOOKS.index(of: book!)!,Constants.OLD_TESTAMENT_VERSES.count,Constants.OLD_TESTAMENT_VERSES[index!].count)
            break
        case Constants.New_Testament:
//            let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!)
//            print(Constants.NEW_TESTAMENT_BOOKS.index(of: book!)!,Constants.NEW_TESTAMENT_VERSES.count,Constants.NEW_TESTAMENT_VERSES[index!].count)
            break
        default:
            break
        }
//        print(book!,index,chapter)
    }
    
    return verses.count > 0 ? verses : nil
}

func chaptersAndVersesFromScripture(book:String?,reference:String?) -> [Int:[Int]]?
{
    // This can only comprehend a range of chapters or a range of verses from a single book.

    guard (book != nil) else {
        return nil
    }
    
    guard (reference?.range(of: ".") == nil) else {
        return nil
    }
    
    guard (reference?.range(of: "&") == nil) else {
        return nil
    }
    
    var chaptersAndVerses = [Int:[Int]]()
    
    var tokens = [String]()
    
    var currentChapter = 0
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0
    
    //        print(book!,reference!)
    
    let string = reference?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if (string == nil) || (string == Constants.EMPTY_STRING) {
//        print(book,reference)
        
        // Now we have a book w/ no chapter or verse references
        // FILL in all chapters and all verses and return
        
        return chaptersAndVersesForBook(book)
    }
    
//    print(string)
    
    var token = Constants.EMPTY_STRING
    
    for char in string!.characters {
        if CharacterSet(charactersIn: ":,-").contains(UnicodeScalar(String(char))!) {
            tokens.append(token)
            token = Constants.EMPTY_STRING
            
            tokens.append(String(char))
        } else {
            if CharacterSet(charactersIn: "0123456789").contains(UnicodeScalar(String(char))!) {
                token.append(char)
            }
        }
    }
    
    if token != Constants.EMPTY_STRING {
        tokens.append(token)
    }
    
    debug("Done w/ parsing and creating tokens")
    
    if tokens.count > 0 {
        var startVerses = Constants.NO_CHAPTER_BOOKS.contains(book!)
        
        if let first = tokens.first, let number = Int(first) {
            tokens.remove(at: 0)
            if Constants.NO_CHAPTER_BOOKS.contains(book!) {
                currentChapter = 1
                startVerse = number
            } else {
                currentChapter = number
                startChapter = number
            }
        } else {
            return chaptersAndVersesForBook(book)
        }
        
        repeat {
            if let first = tokens.first {
                tokens.remove(at: 0)
                
                switch first {
                case ":":
                    debug(": Verses follow")
                    
                    startVerses = true
                    break
                    
                case ",":
                    if !startVerses {
                        debug(", Look for chapters")
                        
                        if let first = tokens.first, let number = Int(first) {
                            tokens.remove(at: 0)

                            if tokens.first == ":" {
                                tokens.remove(at: 0)
                                startChapter = number
                                currentChapter = number
                            } else {
                                currentChapter = number
                                chaptersAndVerses[currentChapter] = versesForBookChapter(book,currentChapter)
                                
                                if chaptersAndVerses[currentChapter] == nil {
                                    print(book as Any,reference as Any)
                                }
                            }
                        }
                    } else {
                        debug(", Look for verses")

                        if startVerse > 0 {
                            if chaptersAndVerses[currentChapter] == nil {
                                chaptersAndVerses[currentChapter] = [Int]()
                            }
                            chaptersAndVerses[currentChapter]?.append(startVerse)
                            
                            startVerse = 0
                        }

                        if let first = tokens.first, let number = Int(first) {
                            tokens.remove(at: 0)
                            
                            if let first = tokens.first {
                                switch first {
                                case ":":
                                    tokens.remove(at: 0)
                                    startVerses = true
                                    
                                    startChapter = number
                                    currentChapter = number
                                    break
                                    
                                case "-":
                                    tokens.remove(at: 0)
                                    if endVerse > 0, number < endVerse {
                                        // This is a chapter!
                                        startVerse = 0
                                        endVerse = 0
                                        
                                        startChapter = number
                                        
                                        if let first = tokens.first, let number = Int(first) {
                                            tokens.remove(at: 0)
                                            endChapter = number

                                            for chapter in startChapter...endChapter {
                                                startVerse = 1
                                                
                                                switch testament(book!) {
                                                case Constants.Old_Testament:
                                                    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                                        chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                    }
                                                    break
                                                case Constants.New_Testament:
                                                    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                                        index < Constants.NEW_TESTAMENT_VERSES.count,
                                                        chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                                    }
                                                    break
                                                default:
                                                    break
                                                }
                                                
                                                if endVerse >= startVerse {
                                                    if chaptersAndVerses[chapter] == nil {
                                                        chaptersAndVerses[chapter] = [Int]()
                                                    }
                                                    if startVerse == endVerse {
                                                        chaptersAndVerses[chapter]?.append(startVerse)
                                                    } else {
                                                        for verse in startVerse...endVerse {
                                                            chaptersAndVerses[chapter]?.append(verse)
                                                        }
                                                    }
                                                }
                                            }

                                            startChapter = 0
                                        }
                                    } else {
                                        startVerse = number
                                        if let first = tokens.first, let number = Int(first) {
                                            tokens.remove(at: 0)
                                            endVerse = number
                                            if chaptersAndVerses[currentChapter] == nil {
                                                chaptersAndVerses[currentChapter] = [Int]()
                                            }
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[currentChapter]?.append(verse)
                                            }
                                            startVerse = 0
                                        }
                                    }
                                    break
                                    
                                default:
                                    if chaptersAndVerses[currentChapter] == nil {
                                        chaptersAndVerses[currentChapter] = [Int]()
                                    }
                                    chaptersAndVerses[currentChapter]?.append(number)
                                    break
                                }
                            } else {
                                if chaptersAndVerses[currentChapter] == nil {
                                    chaptersAndVerses[currentChapter] = [Int]()
                                }
                                chaptersAndVerses[currentChapter]?.append(number)
                            }
                            
                            if tokens.first == nil {
                                startChapter = 0
                            }
                        }

//                        if tokens.first == ":" {
//                            tokens.remove(at: 0)
//                            startVerses = true
//                            
//                            if let number = Int(first) {
//                                startChapter = number
//                                currentChapter = number
//                            }
//                        } else {
//                        }
                    }
                    break
                    
                case "-":
                    if !startVerses {
                        debug("- Look for chapters")
                        
                        if let first = tokens.first, let chapter = Int(first) {
                            debug("Reference is split across chapters")
                            tokens.remove(at: 0)
                            endChapter = chapter
                        }
                        
                        debug("See if endChapter has verses")
                        
                        if tokens.first == ":" {
                            tokens.remove(at: 0)
                            
                            debug("First get the endVerse for the startChapter in the reference")
                            
                            startVerse = 1
                            
                            switch testament(book!) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.NEW_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            default:
                                break
                            }
                            
                            debug("Add the remaining verses for the startChapter")
                            
                            if chaptersAndVerses[startChapter] == nil {
                                chaptersAndVerses[startChapter] = [Int]()
                            }
                            if startVerse == endVerse {
                                chaptersAndVerses[startChapter]?.append(startVerse)
                            } else {
                                for verse in startVerse...endVerse {
                                    chaptersAndVerses[startChapter]?.append(verse)
                                }
                            }
                            
                            debug("Done w/ startChapter")
                            
                            startVerse = 0
//                            endVerse = 0
                            
                            debug("Now determine whether there are any chapters between the first and the last in the reference")
                            
                            if (endChapter - startChapter) > 1 {
                                let start = startChapter + 1
                                let end = endChapter - 1
                                
                                debug("If there are, add those verses")
                                
                                for chapter in start...end {
                                    startVerse = 1
                                    
                                    switch testament(book!) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                            index < Constants.NEW_TESTAMENT_VERSES.count,
                                            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    default:
                                        break
                                    }
                                    
                                    if endVerse >= startVerse {
                                        if chaptersAndVerses[chapter] == nil {
                                            chaptersAndVerses[chapter] = [Int]()
                                        }
                                        if startVerse == endVerse {
                                            chaptersAndVerses[chapter]?.append(startVerse)
                                        } else {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[chapter]?.append(verse)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            debug("Done w/ chapters between startChapter and endChapter")

                            debug("Now add the verses from the endChapter")

                            debug("First find the end verse")
                            
                            if let first = tokens.first, let number = Int(first) {
                                tokens.remove(at: 0)
                                
                                startVerse = 1
                                endVerse = number
                                
                                if endVerse >= startVerse {
                                    if chaptersAndVerses[endChapter] == nil {
                                        chaptersAndVerses[endChapter] = [Int]()
                                    }
                                    if startVerse == endVerse {
                                        chaptersAndVerses[endChapter]?.append(startVerse)
                                    } else {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[endChapter]?.append(verse)
                                        }
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
//                                endVerse = 0
                            }
                            
                            debug("Done w/ endChapter")
                        } else {
                            startVerse = 1
                            
                            switch testament(book!) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.NEW_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            default:
                                break
                            }
                            
                            debug("Add the verses for the startChapter")
                            
                            if chaptersAndVerses[startChapter] == nil {
                                chaptersAndVerses[startChapter] = [Int]()
                            }
                            if startVerse == endVerse {
                                chaptersAndVerses[startChapter]?.append(startVerse)
                            } else {
                                for verse in startVerse...endVerse {
                                    chaptersAndVerses[startChapter]?.append(verse)
                                }
                            }
                            
                            debug("Done w/ startChapter")
                            
                            startVerse = 0
//                            endVerse = 0
                            
                            debug("Now determine whether there are any chapters between the first and the last in the reference")
                            
                            if (endChapter - startChapter) > 1 {
                                let start = startChapter + 1
                                let end = endChapter - 1
                                
                                debug("If there are, add those verses")
                                
                                for chapter in start...end {
                                    startVerse = 1
                                    
                                    switch testament(book!) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                            index < Constants.NEW_TESTAMENT_VERSES.count,
                                            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    default:
                                        break
                                    }
                                    
                                    if endVerse >= startVerse {
                                        if chaptersAndVerses[chapter] == nil {
                                            chaptersAndVerses[chapter] = [Int]()
                                        }
                                        if startVerse == endVerse {
                                            chaptersAndVerses[chapter]?.append(startVerse)
                                        } else {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[chapter]?.append(verse)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            debug("Done w/ chapters between startChapter and endChapter")
                            
                            debug("Now add the verses from the endChapter")
                            
                            startVerse = 1
                            
                            switch testament(book!) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                    index < Constants.NEW_TESTAMENT_VERSES.count,
                                    endChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][endChapter - 1]
                                }
                                break
                            default:
                                break
                            }
                            
                            if endVerse >= startVerse {
                                if chaptersAndVerses[endChapter] == nil {
                                    chaptersAndVerses[endChapter] = [Int]()
                                }
                                if startVerse == endVerse {
                                    chaptersAndVerses[endChapter]?.append(startVerse)
                                } else {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[endChapter]?.append(verse)
                                    }
                                }
                            }
                            
                            debug("Done w/ verses")
                            
                            startVerse = 0
//                            endVerse = 0
                            
                            debug("Done w/ endChapter")
                        }
                        
                        debug("Done w/ chapters")
                        
                        startChapter = 0
                        endChapter = 0
                        
                        currentChapter = 0
                    } else {
                        debug("- Look for verses")
                        
                        if let first = tokens.first,let number = Int(first) {
                            tokens.remove(at: 0)
                            
                            debug("See if reference is split across chapters")
                            
                            if tokens.first == ":" {
                                tokens.remove(at: 0)
                                
                                debug("Reference is split across chapters")
                                debug("First get the endVerse for the first chapter in the reference")
                                
                                switch testament(book!) {
                                case Constants.Old_Testament:
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[Constants.OLD_TESTAMENT_BOOKS.index(of: book!)!][currentChapter - 1]
                                    break
                                case Constants.New_Testament:
                                    endVerse = Constants.NEW_TESTAMENT_VERSES[Constants.NEW_TESTAMENT_BOOKS.index(of: book!)!][currentChapter - 1]
                                    break
                                default:
                                    break
                                }
                                
                                debug("Add the remaining verses for the first chapter")
                                
                                if chaptersAndVerses[currentChapter] == nil {
                                    chaptersAndVerses[currentChapter] = [Int]()
                                }
                                if startVerse == endVerse {
                                    chaptersAndVerses[currentChapter]?.append(startVerse)
                                } else {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[currentChapter]?.append(verse)
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
//                                endVerse = 0
                                
                                debug("Now determine whehter there are any chapters between the first and the last in the reference")
                                
                                currentChapter = number
                                endChapter = number
                                
                                if (endChapter - startChapter) > 1 {
                                    let start = startChapter + 1
                                    let end = endChapter - 1
                                    
                                    debug("If there are, add those verses")
                                    
                                    for chapter in start...end {
                                        startVerse = 1
                                        
                                        switch testament(book!) {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!),
                                                index < Constants.NEW_TESTAMENT_VERSES.count,
                                                chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        default:
                                            break
                                        }

                                        if endVerse >= startVerse {
                                            if chaptersAndVerses[chapter] == nil {
                                                chaptersAndVerses[chapter] = [Int]()
                                            }
                                            if startVerse == endVerse {
                                                chaptersAndVerses[chapter]?.append(startVerse)
                                            } else {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[chapter]?.append(verse)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                debug("Now add the verses from the last chapter")
                                debug("First find the end verse")
                                
                                if let first = tokens.first, let number = Int(first) {
                                    tokens.remove(at: 0)
                                    
                                    startVerse = 1
                                    endVerse = number
                                    
                                    if chaptersAndVerses[currentChapter] == nil {
                                        chaptersAndVerses[currentChapter] = [Int]()
                                    }
                                    if startVerse == endVerse {
                                        chaptersAndVerses[currentChapter]?.append(startVerse)
                                    } else {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[currentChapter]?.append(verse)
                                        }
                                    }
                                    
                                    debug("Done w/ verses")
                                    
                                    startVerse = 0
//                                    endVerse = 0
                                }
                            } else {
                                debug("reference is not split across chapters")
                                
                                endVerse = number
                                
                                debug("\(currentChapter) \(startVerse) \(endVerse)")
                                
                                if chaptersAndVerses[currentChapter] == nil {
                                    chaptersAndVerses[currentChapter] = [Int]()
                                }
                                if startVerse == endVerse {
                                    chaptersAndVerses[currentChapter]?.append(startVerse)
                                } else {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[currentChapter]?.append(verse)
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
//                                endVerse = 0
                            }
                            
                            debug("Done w/ chapters")
                            
                            startChapter = 0
                            endChapter = 0
                        }
                    }
                    break
                    
                default:
                    debug("default")
                    
                    if let number = Int(first) {
                        if let first = tokens.first {
                            if first == ":" {
                                debug("chapter")
                                
                                startVerses = true
                                startChapter = number
                                currentChapter = number
                            } else {
                                debug("chapter or verse")
                                
                                if startVerses {
                                    debug("verse")
                                    
                                    startVerse = number
                                }
                            }
                        } else {
                            debug("no more tokens: chapter or verse")
                            
                            if startVerses {
                                debug("verse")
                                startVerse = number
                            }
                        }
                    } else {
                        // What happens in this case?
                        // We ignore it.  This is not a number or one of the text strings we recognize.
                    }
                    break
                }
            }
        } while tokens.first != nil
        
        debug("Done w/ processing tokens")
        debug("If start and end (chapter,verse) remaining, process them")
        
//        print(book!,reference!)
        
        if startChapter > 0 {
            if endChapter > 0 {
                if endChapter >= startChapter {
                    for chapter in startChapter...endChapter {
                        chaptersAndVerses[chapter] = versesForBookChapter(book,chapter)
                        
                        if chaptersAndVerses[chapter] == nil {
                            print(book as Any,reference as Any)
                        }
                    }
                }
            } else {
                chaptersAndVerses[startChapter] = versesForBookChapter(book,startChapter)
                
                if chaptersAndVerses[startChapter] == nil {
                    print(book as Any,reference as Any)
                }
            }
            startChapter = 0
            endChapter = 0
        }
        if startVerse > 0 {
            if endVerse > 0 {
                if chaptersAndVerses[currentChapter] == nil {
                    chaptersAndVerses[currentChapter] = [Int]()
                }
                for verse in startVerse...endVerse {
                    chaptersAndVerses[currentChapter]?.append(verse)
                }
            } else {
                chaptersAndVerses[currentChapter] = [startVerse]
            }
            startVerse = 0
            endVerse = 0
        }
    } else {
//        print(book,reference,string,tokens)
        return chaptersAndVersesForBook(book)
    }

//    print(chaptersAndVerses)

    return chaptersAndVerses.count > 0 ? chaptersAndVerses : nil
}

func chaptersFromScriptureReference(_ scriptureReference:String?) -> [Int]?
{
    // This can only comprehend a range of chapters or a range of verses from a single book.
    
    var chapters = [Int]()
    
    var colonCount = 0
    
    if (scriptureReference != nil) {
        let string = scriptureReference?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        if (string == Constants.EMPTY_STRING) {
            return nil
        }
        
        //        print("\(string!)")
        
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
        }
    }
    
    //    print("\(scripture)")
    //    print("\(chapters)")
    
    return chapters.count > 0 ? chapters : nil
}

func booksFromScriptureReference(_ scriptureReference:String?) -> [String]?
{
    var books = [String]()
    
    if (scriptureReference != nil) {
        var string:String?
        
        string = scriptureReference
//        print(string)
        
        var otBooks = [String]()
        
        for book in Constants.OLD_TESTAMENT_BOOKS {
            if string?.range(of: book) != nil {
                otBooks.append(book)
                string = string!.substring(to: string!.range(of: book)!.lowerBound) + Constants.SINGLE_SPACE + string!.substring(from: string!.range(of: book)!.upperBound)
            }
        }
        
        for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
            if string?.range(of: book) != nil {
                books.append(book)
                string = string!.substring(to: string!.range(of: book)!.lowerBound) + Constants.SINGLE_SPACE + string!.substring(from: string!.range(of: book)!.upperBound)
            }
        }
        
        let ntBooks = books.reversed()

        books = otBooks
        books.append(contentsOf: ntBooks)
        
        string = string?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)

//        print(string)
        
        // Only works for "<book> - <book>"
        
        if (string == "-") {
            if books.count == 2 {
                let book1 = scriptureReference?.range(of: books[0])
                let book2 = scriptureReference?.range(of: books[1])
                let hyphen = scriptureReference?.range(of: "-")

                if ((book1?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book2?.lowerBound)) ||
                    ((book2?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book1?.lowerBound)) {
                    //                print(first)
                    //                print(last)
                    
                    books = [String]()
                    
                    let first = books[0]
                    let last = books[1]
                    
                    if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.OLD_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: first),
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: first) {
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.count - 1
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                        let firstIndex = 0
                        if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: first),
                            let lastIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: last) {
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
    return books.count > 0 ? books.sorted() { scriptureReference?.range(of: $0)?.lowerBound < scriptureReference?.range(of: $1)?.lowerBound } : nil // redundant
}

func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
{
    var multiPartMediaItems:[MediaItem]?
    
    if (mediaItem != nil) {
        if (mediaItem!.hasMultipleParts) {
            if (globals.media.all?.groupSort?[GROUPING.TITLE]?[mediaItem!.multiPartSort!]?[SORTING.CHRONOLOGICAL] == nil) {
                let seriesMediaItems = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return mediaItem!.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem!.multiPartName) : (testMediaItem.id == mediaItem!.id)
                })
                multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: SORTING.CHRONOLOGICAL)
            } else {
                multiPartMediaItems = globals.media.all?.groupSort?[GROUPING.TITLE]?[mediaItem!.multiPartSort!]?[SORTING.CHRONOLOGICAL]
            }
        } else {
            multiPartMediaItems = [mediaItem!]
        }
    }
    
    return multiPartMediaItems
}

func mediaItemsInBook(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
{
    guard (book != nil) else {
        return nil
    }
    
    return mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
        if let books = mediaItem.books {
            return books.contains(book!)
        } else {
            return false
        }
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
    guard (mediaItems != nil) else {
        return nil
    }
    
    var bookSet = Set<String>()
    
    for mediaItem in mediaItems! {
        if let books = mediaItem.books {
            for book in books {
                bookSet.insert(book)
            }
        }
    }
    
    return Array(bookSet).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
        
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    if bookNumberInBible(first) == bookNumberInBible(second) {
                        result = first < second
                    } else {
                        result = bookNumberInBible(first) < bookNumberInBible(second)
                    }
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
}

func bookSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard (mediaItems != nil) else {
        return nil
    }
    
    var bookSectionSet = Set<String>()
    
    for mediaItem in mediaItems! {
        for bookSection in mediaItem.bookSections {
            bookSectionSet.insert(bookSection)
        }
    }
    
    return Array(bookSectionSet).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    if bookNumberInBible(first) == bookNumberInBible(second) {
                        result = first < second
                    } else {
                        result = bookNumberInBible(first) < bookNumberInBible(second)
                    }
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
    guard (book != nil) else {
        return nil
    }

    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!) {
        return index
    }
    
    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!) {
        return Constants.OLD_TESTAMENT_BOOKS.count + index
    }
    
    return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
}

func tokenCountsFromString(_ string:String?) -> [(String,Int)]?
{
    guard !globals.isRefreshing else {
        return nil
    }
    
    var tokenCounts = [(String,Int)]()
    
    if let tokens = tokensFromString(string) {
        for token in tokens {
            var count = 0
            var string = string
            
            while let range = string?.range(of: token, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                count += 1
                string = string?.substring(from: range.upperBound)
            }
            
            tokenCounts.append((token,count))
            
            if globals.isRefreshing {
                break
            }
        }
    }
    
    return tokenCounts.count > 0 ? tokenCounts : nil
}

func tokensFromString(_ string:String?) -> [String]?
{
    guard !globals.isRefreshing else {
        return nil
    }
    
    guard (string != nil) else {
        return nil
    }
    
    var tokens = Set<String>()
    
    var str = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    if let range = str?.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = str?.substring(to: range.lowerBound)
    }
    
    //        print(name)
    //        print(string)
    
    var token = Constants.EMPTY_STRING
    let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
    let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“

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
            
            if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
                token = Constants.EMPTY_STRING
            }
            
            if token.lowercased() != "it's" {
                if let range = token.lowercased().range(of: "'s") {
                    token = token.substring(to: range.lowerBound)
                }
            }
            
            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
                //                print("\(token)")
                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
                //                print("\(token)")
            }
            
            if token != Constants.EMPTY_STRING {
                tokens.insert(token.uppercased())
                token = Constants.EMPTY_STRING
            }
        } else {
            token = Constants.EMPTY_STRING
        }
    }
    
    for char in str!.characters {
        //        print(char)
        
        if UnicodeScalar(String(char)) != nil {
            if CharacterSet(charactersIn: breakChars).contains(UnicodeScalar(String(char))!) {
                //                print(token)
                processToken()
            } else {
                if !CharacterSet(charactersIn: "$0123456789").contains(UnicodeScalar(String(char))!) {
                    if !CharacterSet(charactersIn: trimChars).contains(UnicodeScalar(String(char))!) || (token != Constants.EMPTY_STRING) {
                        // DO NOT WANT LEADING CHARS IN SET
                        //                        print(token)
                        token.append(char)
                        //                        print(token)
                    }
                }
            }
        }
        
        if globals.isRefreshing {
            break
        }
    }
    
    if token != Constants.EMPTY_STRING {
        processToken()
    }
    
    return Array(tokens).sorted() {
        $0.lowercased() < $1.lowercased()
    }
}

func tokensAndCountsFromString(_ string:String?) -> [String:Int]?
{
    guard !globals.isRefreshing else {
        return nil
    }
    
    guard (string != nil) else {
        return nil
    }
    
    var tokens = [String:Int]()
    
    var str = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
    if let range = str?.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = str?.substring(to: range.lowerBound)
    }
    
    //        print(name)
    //        print(string)
    
    var token = Constants.EMPTY_STRING
    let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
    let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“
    
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
            
            if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
                token = Constants.EMPTY_STRING
            }
            
            if token.lowercased() != "it's" {
                if let range = token.lowercased().range(of: "'s") {
                    token = token.substring(to: range.lowerBound)
                }
            }
            
            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
//                print("\(token)")
                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
//                print("\(token)")
            }
            
            if token != Constants.EMPTY_STRING {
//                print(token.uppercased())
                if let count = tokens[token.uppercased()] {
                    tokens[token.uppercased()] = count + 1
                } else {
                    tokens[token.uppercased()] = 1
                }
                token = Constants.EMPTY_STRING
            }
        } else {
            token = Constants.EMPTY_STRING
        }
    }
    
    for char in str!.characters {
        //        print(char)
        
        if UnicodeScalar(String(char)) != nil {
            if CharacterSet(charactersIn: breakChars).contains(UnicodeScalar(String(char))!) {
//                print(token)
                processToken()
            } else {
                if !CharacterSet(charactersIn: "$0123456789").contains(UnicodeScalar(String(char))!) {
                    if !CharacterSet(charactersIn: trimChars).contains(UnicodeScalar(String(char))!) || (token != Constants.EMPTY_STRING) {
                        // DO NOT WANT LEADING CHARS IN SET
//                        print(token)
                        token.append(char)
//                        print(token)
                    }
                }
            }
        }
        
        if globals.isRefreshing {
            break
        }
    }
    
    if token != Constants.EMPTY_STRING {
        processToken()
    }
    
    return tokens.count > 0 ? tokens : nil
}

func lastNameFromName(_ name:String?) -> String?
{
    if let firstName = firstNameFromName(name), let range = name?.range(of: firstName) {
        return name?.substring(from: range.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } else {
        return name
    }
}

func century(_ strings:String?) -> String?
{
    if let string = strings?.components(separatedBy: "\n").first {
        if let number = Int(string) {
            let value = number/100 * 100
            return "\(value == 0 ? 1 : value)"
        }
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
            if String(char) == Constants.SINGLE_SPACE {
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

func classSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    return mediaItems != nil ?
        Array(
            Set(mediaItems!.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.classSection!
            })
            )
            ).sorted()
        : nil
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
    case SORTING.CHRONOLOGICAL:
        sortedMediaItems = sortMediaItemsChronologically(mediaItems)
        break
        
    case SORTING.REVERSE_CHRONOLOGICAL:
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
    case SORTING.CHRONOLOGICAL:
        if (first.fullDate!.isEqualTo(second.fullDate!)) {
            result = (first.service < second.service)
        } else {
            result = first.fullDate!.isOlderThan(second.fullDate!)
        }
        break
    
    case SORTING.REVERSE_CHRONOLOGICAL:
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

func sortMediaItemsByMultiPart(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
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

func sortMediaItemsByClass(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        var result = false
        
        let first = $0
        let second = $1
        
        if (first.classSectionSort != second.classSectionSort) {
            result = first.classSectionSort < second.classSectionSort
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

func testMediaItemsPDFs(testExisting:Bool, testMissing:Bool, showTesting:Bool)
{
    var counter = 1

    if (testExisting) {
        print("Testing the availability of mediaItem transcripts and slides that we DO have in the mediaItemDicts - start")
        
        if let mediaItems = globals.mediaRepository.list {
            for mediaItem in mediaItems {
                if (showTesting) {
                    print("Testing: \(counter) \(mediaItem.title!)")
                } else {
//                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (mediaItem.notes != nil) {
                    if ((try? Data(contentsOf: mediaItem.notesURL!)) == nil) {
                        print("Transcript DOES NOT exist for: \(mediaItem.title!) PDF: \(mediaItem.notes!)")
                    } else {
                        
                    }
                }
                
                if (mediaItem.slides != nil) {
                    if ((try? Data(contentsOf: mediaItem.slidesURL!)) == nil) {
                        print("Slides DO NOT exist for: \(mediaItem.title!) PDF: \(mediaItem.slides!)")
                    } else {
                        
                    }
                }
                
                counter += 1
            }
        }
        
        print("\nTesting the availability of mediaItem transcripts and slides that we DO have in the mediaItemDicts - end")
    }

    if (testMissing) {
        print("Testing the availability of mediaItem transcripts and slides that we DO NOT have in the mediaItemDicts - start")
        
        counter = 1
        if let mediaItems = globals.mediaRepository.list {
            for mediaItem in mediaItems {
                if (showTesting) {
                    print("Testing: \(counter) \(mediaItem.title!)")
                } else {
//                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if (mediaItem.audio == nil) {
                    print("No Audio file for: \(String(describing: mediaItem.title)) can't test for PDF's")
                } else {
                    if (mediaItem.notes == nil) {
                        if ((try? Data(contentsOf: mediaItem.notesURL!)) != nil) {
                            print("Transcript DOES exist for: \(mediaItem.title!) ID:\(mediaItem.id)")
                        } else {
                            
                        }
                    }
                    
                    if (mediaItem.slides == nil) {
                        if ((try? Data(contentsOf: mediaItem.slidesURL!)) != nil) {
                            print("Slides DO exist for: \(mediaItem.title!) ID: \(mediaItem.id)")
                        } else {
                            
                        }
                    }
                }
                
                counter += 1
            }
        }
        
        print("\nTesting the availability of mediaItem transcripts and slides that we DO NOT have in the mediaItemDicts - end")
    }
}

func testMediaItemsTagsAndSeries()
{
    print("Testing for mediaItem series and tags the same - start")
    
    if let mediaItems = globals.mediaRepository.list {
        for mediaItem in mediaItems {
            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                if (mediaItem.multiPartName == mediaItem.tags) {
                    print("Multiple Part Name and Tags the same in: \(mediaItem.title!) Multiple Part Name:\(mediaItem.multiPartName!) Tags:\(mediaItem.tags!)")
                }
            }
        }
    }
    
    print("Testing for mediaItem series and tags the same - end")
}

func testMediaItemsForAudio()
{
    print("Testing for audio - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasAudio) {
            print("Audio missing in: \(mediaItem.title!)")
        } else {

        }
    }
    
    print("Testing for audio - end")
}

func testMediaItemsForSpeaker()
{
    print("Testing for speaker - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasSpeaker) {
            print("Speaker missing in: \(mediaItem.title!)")
        }
    }
    
    print("Testing for speaker - end")
}

func testMediaItemsForSeries()
{
    print("Testing for mediaItems with \"(Part \" in the title but no series - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
            print("Series missing in: \(mediaItem.title!)")
        }
    }
    
    print("Testing for mediaItems with \"(Part \" in the title but no series - end")
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
            tagString = tagString != nil ? tagString! + Constants.TAGS_SEPARATOR + tag : tag
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
    guard (mediaItems != nil) else {
        return nil
    }

    var tagsSet = Set<String>()
    
    for mediaItem in mediaItems! {
        if let tags = mediaItem.tagsSet {
            tagsSet.formUnion(tags)
        }
    }
    
    
    var tagsArray = Array(tagsSet).sorted(by: { stringWithoutPrefixes($0) < stringWithoutPrefixes($1) })
    
    tagsArray.append(Constants.Strings.All)
    
    //    print("Tag Set: \(tagsSet)")
    //    print("Tag Array: \(tagsArray)")
    
    return tagsArray.count > 0 ? tagsArray : nil
}

func mailMediaItem(viewController:UIViewController, mediaItem:MediaItem?,stringFunction:((MediaItem?)->String?)?)
{
    guard MFMailComposeViewController.canSendMail() else {
        showSendMailErrorAlert(viewController: viewController)
        return
    }

    let mailComposeViewController = MFMailComposeViewController()
    mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    
    mailComposeViewController.setToRecipients([])
    mailComposeViewController.setSubject(Constants.EMAIL_ONE_SUBJECT)
    
    if let bodyString = stringFunction?(mediaItem) {
        mailComposeViewController.setMessageBody(bodyString, isHTML: true)
    }
    
    if MFMailComposeViewController.canSendMail() {
        DispatchQueue.main.async(execute: { () -> Void in
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        })
    } else {
        showSendMailErrorAlert(viewController: viewController)
    }
}

func presentHTMLModal(viewController:UIViewController, medaiItem:MediaItem?, style: UIModalPresentationStyle, title: String?, htmlString: String?)
{
    guard (htmlString != nil) else {
        return
    }
    
    if let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? WebViewController {
        DispatchQueue.main.async(execute: { () -> Void in
            viewController.dismiss(animated: true, completion: nil)
        })
        
        navigationController.modalPresentationStyle = style
        
        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
        
        popover.navigationItem.title = title
        
        popover.search = true
        popover.selectedMediaItem = medaiItem
        
        popover.html.string = htmlString
        popover.content = .html

        popover.navigationController?.isNavigationBarHidden = false
        
        DispatchQueue.main.async(execute: { () -> Void in
            viewController.present(navigationController, animated: true, completion: nil)
        })
    }
}

func sort(method:String?,strings:[String]?) -> [String]?
{
    guard let strings = strings else {
        return nil
    }
    
    guard let method = method else {
        return nil
    }

    switch method {
    case Constants.Sort.Alphabetical:
        return strings.sorted()
        
    case Constants.Sort.Frequency:
        return strings.sorted(by: { (first:String, second:String) -> Bool in
            if let rangeFirst = first.range(of: " ("), let rangeSecond = second.range(of: " (") {
                let left = first.substring(from: rangeFirst.upperBound)
                let right = second.substring(from: rangeSecond.upperBound)
                
                let first = first.substring(to: rangeFirst.lowerBound)
                let second = second.substring(to: rangeSecond.lowerBound)
                
                if let rangeLeft = left.range(of: ")"), let rangeRight = right.range(of: ")") {
                    let left = left.substring(to: rangeLeft.lowerBound)
                    let right = right.substring(to: rangeRight.lowerBound)
                    
                    if let left = Int(left), let right = Int(right) {
                        if left == right {
                            return first < second
                        } else {
                            return left > right
                        }
                    }
                }
                
                return false
            } else {
                return false
            }
        })
        
    default:
        return nil
    }
}

func process(viewController:UIViewController,work:(()->(Any?))?,completion:((Any?)->())?)
{
    guard (work != nil)  && (completion != nil) else {
        return
    }
    
    
    guard let loadingViewController = viewController.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
        return
    }

    DispatchQueue.main.async(execute: { () -> Void in
        if let buttons = viewController.navigationItem.rightBarButtonItems {
            for button in buttons {
                button.isEnabled = false
            }
        }
        
        if let buttons = viewController.navigationItem.leftBarButtonItems {
            for button in buttons {
                button.isEnabled = false
            }
        }
        
        if let buttons = viewController.toolbarItems {
            for button in buttons {
                button.isEnabled = false
            }
        }
        
        let view = viewController.view!
        
        let container = loadingViewController.view!
        
        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        view.addSubview(container)
        
        DispatchQueue.global(qos: .background).async {
            let data = work?()
            
            DispatchQueue.main.async(execute: { () -> Void in
                if container != viewController.view {
                    container.removeFromSuperview()
                }
                
                if let buttons = viewController.navigationItem.rightBarButtonItems {
                    for button in buttons {
                        button.isEnabled = true
                    }
                }
                
                if let buttons = viewController.navigationItem.leftBarButtonItems {
                    for button in buttons {
                        button.isEnabled = true
                    }
                }
                
                if let buttons = viewController.toolbarItems {
                    for button in buttons {
                        button.isEnabled = true
                    }
                }
                
                completion?(data)
            })
        }
    })
}

func mailHTML(viewController:UIViewController,to: [String],subject: String, htmlString:String)
{
    let mailComposeViewController = MFMailComposeViewController()
    mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    
    mailComposeViewController.setToRecipients(to)
    mailComposeViewController.setSubject(subject)
    
    mailComposeViewController.setMessageBody(htmlString, isHTML: true)
    
    if MFMailComposeViewController.canSendMail() {
        DispatchQueue.main.async(execute: { () -> Void in
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        })
    } else {
        showSendMailErrorAlert(viewController: viewController)
    }
}

func printJob(viewController:UIViewController,data:Data?,html:String?,orientation:UIPrintInfoOrientation)
{
    guard UIPrintInteractionController.isPrintingAvailable, !((html != nil) && (data != nil)), (html != nil) || (data != nil) else {
        return
    }
    
    let pi = UIPrintInfo.printInfo()
    pi.outputType = UIPrintInfoOutputType.general
    pi.jobName = Constants.Strings.Print;
    pi.duplex = UIPrintInfoDuplex.longEdge
    
    let pic = UIPrintInteractionController.shared
    pic.printInfo = pi
    pic.showsPageRange = true
    pic.showsPaperSelectionForLoadedPapers = true

    if html != nil {
        let formatter = UIMarkupTextPrintFormatter(markupText: html!)
        formatter.perPageContentInsets = UIEdgeInsets(top: 54, left: 54, bottom: 54, right: 54) // 72=1" margins
        
        pic.printFormatter = formatter
        
        pi.orientation = orientation
    }

    if data != nil {
        pic.printingItem = data
    }
    
    DispatchQueue.main.async(execute: { () -> Void in
        pic.present(from: viewController.navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
    })
}

func printHTML(viewController:UIViewController,htmlString:String?)
{
    guard UIPrintInteractionController.isPrintingAvailable && (htmlString != nil) else {
        return
    }
    
    pageOrientation(viewController: viewController,
                    portrait: ({
                        printJob(viewController: viewController,data:nil,html:htmlString,orientation:.portrait)
                    }),
                    landscape: ({
                        printJob(viewController: viewController,data:nil,html:htmlString,orientation:.landscape)
                    }),
                    cancel: ({
                    })
    )
}

func printDocument(viewController:UIViewController,documentURL:URL?)
{
    guard UIPrintInteractionController.isPrintingAvailable && (documentURL != nil) else { // && UIPrintInteractionController.canPrint(printURL!)  is too slow
        return
    }
    
    process(viewController: viewController, work: {
        return NSData(contentsOf: documentURL!)
    }, completion: { (data:Any?) in
        printJob(viewController: viewController, data: data as? Data, html: nil, orientation: .portrait)
    })
}

func printMediaItem(viewController:UIViewController, mediaItem:MediaItem?)
{
    guard UIPrintInteractionController.isPrintingAvailable && (mediaItem != nil) else {
        return
    }
    
    process(viewController: viewController, work: {
        return mediaItem?.contentsHTML
    }, completion: { (data:Any?) in
        printJob(viewController:viewController,data:nil,html:(data as? String),orientation:.portrait)
    })
}

func pageOrientation(viewController:UIViewController,portrait:((Void)->(Void))?,landscape:((Void)->(Void))?,cancel:((Void)->(Void))?)
{
    firstSecondCancel(viewController: viewController,
                      title: "Page Orientation", message: nil,
                      firstTitle: "Portrait", firstAction: portrait, firstStyle: .default,
                      secondTitle: "Landscape", secondAction: landscape, secondStyle: .default,
                      cancelAction: cancel)
}

func printMediaItems(viewController:UIViewController,mediaItems:[MediaItem]?,stringFunction:(([MediaItem]?,Bool,Bool)->String?)?,links:Bool,columns:Bool)
{
    guard UIPrintInteractionController.isPrintingAvailable && (mediaItems != nil) && (stringFunction != nil) else {
        return
    }
    
    func processMediaItems(orientation:UIPrintInfoOrientation)
    {
        process(viewController: viewController, work: {
            return stringFunction?(mediaItems,links,columns)
        }, completion: { (data:Any?) in
            printJob(viewController:viewController,data:nil,html:(data as? String),orientation:orientation)
        })
    }
    
    pageOrientation(viewController: viewController,
                    portrait: ({
                        processMediaItems(orientation:.portrait)
                    }),
                    landscape: ({
                        processMediaItems(orientation:.landscape)
                    }),
                    cancel: ({
                    })
    )
}

func showSendMailErrorAlert(viewController:UIViewController)
{
    alert(viewController:viewController,title: "Could Not Send Email",message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",completion:nil)
//    
//    let action = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
//        
//    })
//    alert.addAction(action)
//    
//    DispatchQueue.main.async(execute: { () -> Void in
//        viewController.present(alert, animated: true, completion: nil)
//    })
}


func mailMediaItems(viewController:UIViewController,mediaItems:[MediaItem]?,stringFunction:(([MediaItem]?,Bool,Bool)->String?)?,links:Bool,columns:Bool,attachments:Bool)
{
    guard (mediaItems != nil) && (stringFunction != nil) && MFMailComposeViewController.canSendMail() else {
        showSendMailErrorAlert(viewController: viewController)
        return
    }
    
    process(viewController: viewController, work: {
        if let text = stringFunction?(mediaItems,links,columns) {
            return [text]
        }
        
        return nil
    }, completion: { (data:Any?) in
        if let itemsToMail = data as? [Any] {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
            
            mailComposeViewController.setToRecipients([])
            mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
            
            mailComposeViewController.setMessageBody(itemsToMail[0] as! String, isHTML: true)
            
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        }
    })
}

func hmsToSeconds(string:String?) -> Double?
{
    guard var string = string?.replacingOccurrences(of: ",", with: ".") else {
        return nil
    }
    
    var numbers = [Double]()
    
    repeat {
        if let index = string.range(of: ":") {
            let numberString = string.substring(to: index.lowerBound)
            
            if let number = Double(numberString) {
                numbers.append(number)
            }

            string = string.substring(from: index.upperBound)
        }
    } while string.range(of: ":") != nil

    if !string.isEmpty {
        if let number = Double(string) {
            numbers.append(number)
        }
    }

    var seconds = 0.0
    var counter = 0.0
    
    for number in numbers.reversed() {
        seconds = seconds + (counter != 0 ? number * pow(60.0,counter) : number)
        counter += 1
    }
    
    return seconds
}

func secondsToHMS(seconds:String?) -> String?
{
    guard let seconds = seconds else {
        return nil
    }
    
    guard let timeNow = Double(seconds) else {
        return nil
    }
    
    let hours = max(Int(timeNow / (60*60)),0)
    let mins = max(Int((timeNow - (Double(hours) * 60*60)) / 60),0)
    let sec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
    
    var hms:String
    
    if (hours > 0) {
        hms = "\(String(format: "%d",hours)):"
    } else {
        hms = Constants.EMPTY_STRING
    }
    
    hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec))"

    return hms
}

func popoverHTML(_ viewController:UIViewController,mediaItem:MediaItem?,title:String?,barButtonItem:UIBarButtonItem?,sourceView:UIView?,sourceRectView:UIView?,htmlString:String?)
{
    guard Thread.isMainThread else {
        return
    }
    
    guard htmlString != nil else {
        return
    }
    
//    guard (barButtonItem != nil) || ((sourceView != nil) && (sourceRectView != nil)) else {
//        return
//    }
    
    
    if let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? WebViewController {
        viewController.dismiss(animated: true, completion: nil)
//        DispatchQueue.main.async(execute: { () -> Void in
//        })
        
        if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
            let hClass = viewController.traitCollection.horizontalSizeClass

            if hClass == .compact {
                navigationController.modalPresentationStyle = .fullScreen
            } else {
                // I don't think this ever happens: collapsed and regular
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
            }
        } else {
            if viewController.splitViewController?.displayMode == .primaryHidden {
                navigationController.modalPresentationStyle = .fullScreen // Used to be .popover
            } else {
                navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
            }
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
        }
        
        if sourceView != nil {
            navigationController.popoverPresentationController?.sourceView = sourceView
            
            if let frame = sourceRectView?.frame {
                navigationController.popoverPresentationController?.sourceRect = frame
            }
        }

        if barButtonItem != nil {
            navigationController.popoverPresentationController?.barButtonItem = barButtonItem
        }
        
        popover.navigationItem.title = mediaItem?.title
        
        if title != nil {
            popover.navigationItem.title = title
        }
        
        popover.html.fontSize = 12
        popover.html.string = insertHead(htmlString,fontSize: popover.html.fontSize)
        
        popover.search = true
        popover.selectedMediaItem = mediaItem
        
        popover.content = .html
        
        popover.navigationController?.isNavigationBarHidden = false
        
        viewController.present(navigationController, animated: true, completion: nil)
//        DispatchQueue.main.async(execute: { () -> Void in
//        })
    }
}

func shareHTML(viewController:UIViewController,htmlString:String?)
{
    guard Thread.isMainThread else {
        return
    }
    
    guard htmlString != nil else {
        return
    }

    let activityItems = [htmlString as Any]
    
    let activityViewController = UIActivityViewController(activityItems:activityItems , applicationActivities: nil)
    
    // exclude some activity types from the list (optional)
    
    activityViewController.excludedActivityTypes = [ .addToReadingList ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
    
    activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem

    // present the view controller
    viewController.present(activityViewController, animated: false, completion: nil)
//    DispatchQueue.main.async(execute: { () -> Void in
//    })
}

func shareMediaItems(viewController:UIViewController,mediaItems:[MediaItem]?,stringFunction:(([MediaItem]?)->String?)?)
{
    guard (mediaItems != nil) && (stringFunction != nil) else {
        return
    }
    
    process(viewController: viewController, work: {
        return stringFunction?(mediaItems)
    }, completion: { (data:Any?) in
        shareHTML(viewController: viewController, htmlString: data as? String)
    })
}

func setupMediaItemsHTML(_ mediaItems:[MediaItem]?) -> String?
{
    return setupMediaItemsHTML(mediaItems,includeURLs:true,includeColumns:true)
}

func stripHead(_ string:String?) -> String?
{
    var bodyString = string
    
    while bodyString?.range(of: "<head>") != nil {
        if let startRange = bodyString?.range(of: "<head>") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: "</head>") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    return bodyString
}

func insertMenuHead(_ string:String?,fontSize:Int) -> String?
{
    let filePath = Bundle.main.resourcePath!

    let headContent = try! String(contentsOfFile: filePath + "/head.txt", encoding: String.Encoding.utf8)

    let styleContent = try! String(contentsOfFile: filePath + "/style.txt", encoding: String.Encoding.utf8)
    
    let head = "<html><head><style>body{font: -apple-system-body;font-size:\(fontSize)pt;}td{font-size:\(fontSize)pt;}mark{background-color:silver}\(styleContent)</style>\(headContent)</head>"
    
    return string?.replacingOccurrences(of: "<html>", with: head)
}

func insertHead(_ string:String?,fontSize:Int) -> String?
{
    // <meta name=\"viewport\" content=\"width=device-width,initial-size=1.0\"/>
    
    var head = "<html><head><meta name=\"viewport\" content=\"width=device-width,initial-size=1.0\"/>"
    
    var style = "<style>"
    
    style = style + "body{font: -apple-system-body;font-size:\(fontSize)pt;}"
    
    style = style + "href{font: -apple-system-body;font-size:\(fontSize)pt;}"
    
    style = style + "td{font: -apple-system-body;font-size:\(fontSize)pt;}"
    
    style = style + "p{font: -apple-system-body;font-size:\(fontSize)pt;}"
    style = style + "p.q1{margin-top: 0em;margin-bottom: 0em;}"
    style = style + "p.q2{margin-top: 0em;margin-bottom: 0em;}"
    style = style + "p.copyright{font-size:\(fontSize-3)pt;}"

    style = style + "a{font: -apple-system-body;font-size:\(fontSize)pt;}"
    
    style = style + "mark{background-color:silver;}"
    
    style = style + "span.it{font-style: italic;}"
    style = style + "span.sc{font-size:\(fontSize-2)pt;}"
    
    style = style + "</style>"
    
    head = head + style + "</head>"
    
    return string?.replacingOccurrences(of: "<html>", with: head)
}

func stripLinks(_ string:String?) -> String?
{
    var bodyString = string
    
    while bodyString?.range(of: "<div") != nil {
        if let startRange = bodyString?.range(of: "<div") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: "</div>") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    bodyString = bodyString?.replacingOccurrences(of: "<a href=\"#index\">Index</a><br/><br/>", with: "")

    while bodyString?.range(of: "<a") != nil {
        if let startRange = bodyString?.range(of: "<a") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    bodyString = bodyString?.replacingOccurrences(of: "</a>", with: "")
    
    return bodyString
}

func stripHTML(_ string:String?) -> String?
{
    var bodyString = stripLinks(stripHead(string))
    
    bodyString = bodyString?.replacingOccurrences(of: "<!DOCTYPE html>", with: "")
    bodyString = bodyString?.replacingOccurrences(of: "<html>", with: "")
    bodyString = bodyString?.replacingOccurrences(of: "<body>", with: "")

    while bodyString?.range(of: "<p ") != nil {
        if let startRange = bodyString?.range(of: "<p ") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    while bodyString?.range(of: "<span ") != nil {
        if let startRange = bodyString?.range(of: "<span ") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    while bodyString?.range(of: "<font") != nil {
        if let startRange = bodyString?.range(of: "<font") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    while bodyString?.range(of: "<sup") != nil {
        if let startRange = bodyString?.range(of: "<sup") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    bodyString = bodyString?.replacingOccurrences(of: "&rsquo;", with: "'")
    bodyString = bodyString?.replacingOccurrences(of: "&rdquo;", with: "\"")
    bodyString = bodyString?.replacingOccurrences(of: "&lsquo;", with: "'")
    bodyString = bodyString?.replacingOccurrences(of: "&ldquo;", with: "\"")
    
    bodyString = bodyString?.replacingOccurrences(of: "&mdash;", with: "-")
    bodyString = bodyString?.replacingOccurrences(of: "&ndash;", with: "-")
    
    bodyString = bodyString?.replacingOccurrences(of: "&nbsp;", with: " ")
    
    bodyString = bodyString?.replacingOccurrences(of: "&ccedil;", with: "C")
    
    bodyString = bodyString?.replacingOccurrences(of: "<br/>", with: "\n")
    
    bodyString = bodyString?.replacingOccurrences(of: "<table>", with: "")
    
    bodyString = bodyString?.replacingOccurrences(of: "<tr>", with: "")

    while bodyString?.range(of: "<td") != nil {
        if let startRange = bodyString?.range(of: "<td") {
            if let endRange = bodyString?.substring(from: startRange.lowerBound).range(of: ">") {
                let string = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: startRange.lowerBound).substring(to: endRange.upperBound)
                bodyString = bodyString!.substring(to: startRange.lowerBound) + bodyString!.substring(from: string.range(of: string)!.upperBound)
            }
        }
    }
    
    bodyString = bodyString?.replacingOccurrences(of: "</td>", with: Constants.SINGLE_SPACE)
    
    bodyString = bodyString?.replacingOccurrences(of: "</tr>", with: "\n")
    
    bodyString = bodyString?.replacingOccurrences(of: "</table>", with: "")

    bodyString = bodyString?.replacingOccurrences(of: "</font>", with: "")
    
    bodyString = bodyString?.replacingOccurrences(of: "</sup>", with: "")
    
    bodyString = bodyString?.replacingOccurrences(of: "</body>", with: "")
    bodyString = bodyString?.replacingOccurrences(of: "</html>", with: "")

    bodyString = bodyString?.replacingOccurrences(of: "<em>", with: "")
    bodyString = bodyString?.replacingOccurrences(of: "</em>", with: "")
    
    bodyString = bodyString?.replacingOccurrences(of: "<p>", with: "")
    bodyString = bodyString?.replacingOccurrences(of: "</p>", with: "")
    
//        print(bodyString)
    
    return insertHead(bodyString,fontSize: Constants.FONT_SIZE)
}

func setupMediaItemsHTMLGlobal(includeURLs:Bool,includeColumns:Bool) -> String?
{
    var bodyString:String?
    
    guard (globals.media.active?.list != nil) else {
        return nil
    }
    
    bodyString = "<!DOCTYPE html><html><body>"
    
    bodyString = bodyString! + "The following media "
    
    if globals.media.active?.list?.count > 1 {
        bodyString = bodyString! + "are"
    } else {
        bodyString = bodyString! + "is"
    }
    
    if includeURLs {
        bodyString = bodyString! + " from <a id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
    } else {
        bodyString = bodyString! + " from " + Constants.CBC.LONG + "<br/><br/>"
    }

    if let category = globals.mediaCategory.selected {
        bodyString = bodyString! + "Category: \(category)<br/>"
    }

    if globals.media.tags.showing == Constants.TAGGED, let tag = globals.media.tags.selected {
        bodyString = bodyString! + "Collection: \(tag)<br/>"
    }
    
    if globals.search.valid, let searchText = globals.search.text {
        bodyString = bodyString! + "Search: \(searchText)<br/>"
    }
    
    bodyString = bodyString! + "Grouped: By \(translate(globals.grouping)!)<br/>"
    bodyString = bodyString! + "Sorted: \(translate(globals.sorting)!)<br/>"
    
    if let keys = globals.media.active?.section?.indexStrings {
        var count = 0
        for key in keys {
            if let mediaItems = globals.media.active?.groupSort?[globals.grouping!]?[key]?[globals.sorting!] {
                count += mediaItems.count
            }
        }

        bodyString = bodyString! + "Total: \(count)<br/>"

        bodyString = bodyString! + "<br/>"
        
        if includeURLs, (keys.count > 1) {
            bodyString = bodyString! + "<a href=\"#index\">Index</a><br/><br/>"
        }
        
        if includeColumns {
            bodyString = bodyString! + "<table>"
        }
        
        for key in keys {
            if  let name = globals.media.active?.groupNames?[globals.grouping!]?[key],
                let mediaItems = globals.media.active?.groupSort?[globals.grouping!]?[key]?[globals.sorting!] {
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
                    if mediaItem.speaker != nil {
                        if speakerCounts[mediaItem.speaker!] == nil {
                            speakerCounts[mediaItem.speaker!] = 1
                        } else {
                            speakerCounts[mediaItem.speaker!]! += 1
                        }
                    }
                }
                
                let speakerCount = speakerCounts.keys.count
                
                if includeColumns {
                    bodyString = bodyString! + "<tr>"
                    bodyString = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                }
                
                if includeURLs, (keys.count > 1) {
                    let tag = key.replacingOccurrences(of: " ", with: "")
                    bodyString = bodyString! + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + " (\(mediaItems.count))" + "</a>"
                } else {
                    bodyString = bodyString! + name + " (\(mediaItems.count))"
                }
                
                if speakerCount == 1 {
                    if let speaker = mediaItems[0].speaker, name != speaker {
                        bodyString = bodyString! + " by " + speaker
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString! + "</td>"
                    bodyString = bodyString! + "</tr>"
                } else {
                    bodyString = bodyString! + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["date","title","scripture"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if globals.grouping != GROUPING.CLASS {
                        if let className = mediaItem.className, !className.isEmpty {
                            order.append("class")
                        }
                    }
                    
                    if globals.grouping != GROUPING.EVENT {
                        if let eventName = mediaItem.eventName, !eventName.isEmpty {
                            order.append("event")
                        }
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString! + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString! + "<br/>"
                    }
                }
            }
            
            if includeColumns {
                bodyString = bodyString! + "<tr>"
                bodyString = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
            }
            
            bodyString = bodyString! + "<br/>"
            
            if includeColumns {
                bodyString = bodyString! + "</td>"
                bodyString = bodyString! + "</tr>"
            }
        }
        
        if includeColumns {
            bodyString = bodyString! + "</table>"
        }
        
        bodyString = bodyString! + "<br/>"
        
        if includeURLs, keys.count > 1 {
            bodyString = bodyString! + "<div><a id=\"index\" name=\"index\" href=\"#top\">Index</a><br/><br/>"
            
            switch globals.grouping! {
            case GROUPING.CLASS:
                fallthrough
            case GROUPING.SPEAKER:
                fallthrough
            case GROUPING.TITLE:
                let a = "A"
                
                if let indexTitles = globals.media.active?.section?.indexStrings {
                    let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                        if string.endIndex >= a.endIndex {
                            return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
                        } else {
                            return string
                        }
                    }))).sorted() { $0 < $1 }
                    
                    var stringIndex = [String:[String]]()
                    
                    for indexString in globals.media.active!.section!.indexStrings! {
                        let key = indexString.substring(to: a.endIndex).uppercased()
                        
                        if stringIndex[key] == nil {
                            stringIndex[key] = [String]()
                        }
                        //                print(testString,string)
                        stringIndex[key]?.append(indexString)
                    }
                    
//                    print(stringIndex)
                    
                    var index:String?
                    
                    for title in titles {
                        let link = "<a href=\"#\(title)\">\(title)</a>"
                        index = (index != nil) ? index! + " " + link : link
                    }
                    
                    bodyString = bodyString! + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                    
                    if index != nil {
                        bodyString = bodyString! + index! + "<br/><br/>"
                    }
                    
                    for title in titles {
                        bodyString = bodyString! + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                        
                        if let keys = stringIndex[title] {
                            for key in keys {
                                if let title = globals.media.active?.groupNames?[globals.grouping!]?[key],
                                    let count = globals.media.active?.groupSort?[globals.grouping!]?[key]?[globals.sorting!]?.count {
                                    let tag = key.replacingOccurrences(of: " ", with: "")
                                    bodyString = bodyString! + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                                }
                            }
                            bodyString = bodyString! + "<br/>"
                        }
                    }
                    
                    bodyString = bodyString! + "</div>"
                }
                break
                
            default:
                for key in keys {
                    if let title = globals.media.active?.groupNames?[globals.grouping!]?[key],
                        let count = globals.media.active?.groupSort?[globals.grouping!]?[key]?[globals.sorting!]?.count {
                        let tag = key.replacingOccurrences(of: " ", with: "")
                        bodyString = bodyString! + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                    }
                }
                break
            }
            
            bodyString = bodyString! + "</div>"
        }
    }
    
    bodyString = bodyString! + "</body></html>"
    
    return insertHead(bodyString,fontSize: Constants.FONT_SIZE)
}

func translateTestament(_ testament:String) -> String
{
    var translation = Constants.EMPTY_STRING
    
    switch testament {
    case Constants.OT:
        translation = Constants.Old_Testament
        break
        
    case Constants.NT:
        translation = Constants.New_Testament
        break
        
    default:
        break
    }
    
    return translation
}

func translate(_ string:String?) -> String?
{
    guard (string != nil) else {
        return nil
    }
    
    switch string! {
    case SORTING.CHRONOLOGICAL:
        return Sorting.Oldest_to_Newest
        
    case SORTING.REVERSE_CHRONOLOGICAL:
        return Sorting.Newest_to_Oldest

    case GROUPING.YEAR:
        return Grouping.Year
        
    case GROUPING.TITLE:
        return Grouping.Title
        
    case GROUPING.BOOK:
        return Grouping.Book
        
    case GROUPING.SPEAKER:
        return Grouping.Speaker
        
    case GROUPING.CLASS:
        return Grouping.Class
        
    default:
        return nil
    }
}

func setupMediaItemsHTML(_ mediaItems:[MediaItem]?,includeURLs:Bool,includeColumns:Bool) -> String? {
    var bodyString:String?
    
    guard (mediaItems != nil) else {
        return nil
    }
    
    var mediaListSort = [String:[MediaItem]]()
    
    for mediaItem in mediaItems! {
        if let multiPartName = mediaItem.multiPartName {
            if mediaListSort[multiPartName] == nil {
                mediaListSort[multiPartName] = [mediaItem]
            } else {
                mediaListSort[multiPartName]?.append(mediaItem)
            }
        } else {
            if let title = mediaItem.title {
                if mediaListSort[title] == nil {
                    mediaListSort[title] = [mediaItem]
                } else {
                    mediaListSort[title]?.append(mediaItem)
                }
            }
        }
    }

    bodyString = "<!DOCTYPE html><html><body>"
    
    bodyString = bodyString! + "The following media "
    
    if mediaItems!.count > 1 {
        bodyString = bodyString! + "are"
    } else {
        bodyString = bodyString! + "is"
    }
    
    if includeURLs {
        bodyString = bodyString! + " from <a href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
    } else {
        bodyString = bodyString! + " from " + Constants.CBC.LONG + "<br/><br/>"
    }
    
    if let category = globals.mediaCategory.selected {
        bodyString = bodyString! + "Category: \(category)<br/><br/>"
    }
    
    if globals.media.tags.showing == Constants.TAGGED, let tag = globals.media.tags.selected {
        bodyString = bodyString! + "Collection: \(tag)<br/><br/>"
    }
    
    if globals.search.valid, let searchText = globals.search.text {
        bodyString = bodyString! + "Search: \(searchText)<br/><br/>"
    }
    
    let keys:[String] = mediaListSort.keys.map({ (string:String) -> String in
        return string
    }).sorted() {
        stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
    }
    
    if includeURLs, (keys.count > 1) {
        bodyString = bodyString! + "<a href=\"#index\">Index</a><br/><br/>"
    }
    
    var lastKey:String?
    
    if includeColumns {
        bodyString  = bodyString! + "<table>"
    }
    
    for key in keys {
        if let mediaItems = mediaListSort[key] {
            switch mediaItems.count {
            case 1:
                if let mediaItem = mediaItems.first {
                    if let string = mediaItem.bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs:includeURLs, includeColumns:includeColumns) {
                        bodyString = bodyString! + string
                    }
                    
                    if includeColumns {
                        bodyString  = bodyString! + "<tr>"
                        bodyString  = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                    }
                    
                    bodyString = bodyString! + "<br/>"
                    
                    if includeColumns {
                        bodyString  = bodyString! + "</td>"
                        bodyString  = bodyString! + "</tr>"
                    }
                }
                break
                
            default:
                if lastKey != nil, let count = mediaListSort[lastKey!]?.count, count == 1 {
                    if includeColumns {
                        bodyString  = bodyString! + "<tr>"
                        bodyString  = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                    }
                    
                    bodyString = bodyString! + "<br/>"
                    
                    if includeColumns {
                        bodyString  = bodyString! + "</td>"
                        bodyString  = bodyString! + "</tr>"
                    }
                }
                
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
                    if mediaItem.speaker != nil {
                        if speakerCounts[mediaItem.speaker!] == nil {
                            speakerCounts[mediaItem.speaker!] = 1
                        } else {
                            speakerCounts[mediaItem.speaker!]! += 1
                        }
                    }
                }
                
                let speakerCount = speakerCounts.keys.count
                
                if includeColumns {
                    bodyString  = bodyString! + "<tr>"
                    bodyString  = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                }
                
                if includeURLs, (keys.count > 1) {
                    let tag = key.replacingOccurrences(of: " ", with: "")
                    bodyString = bodyString! + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + key + "</a>"
                } else {
                    bodyString = bodyString! + key
                }

                if speakerCount == 1, let speaker = mediaItems[0].speaker, key != speaker {
                    bodyString = bodyString! + " by " + speaker
                }
                
                if includeColumns {
                    bodyString  = bodyString! + "</td>"
                    bodyString  = bodyString! + "</tr>"
                } else {
                    bodyString = bodyString! + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["date","title","scripture"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString! + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString! + "<br/>"
                    }
                }

                if !includeColumns {
                    bodyString = bodyString! + "<br/>"
                }
              
                break
            }
        }
        
        lastKey = key
    }
    
    if includeColumns {
        bodyString  = bodyString! + "</table>"
    }
    
    bodyString = bodyString! + "<br/>"
    
    if includeURLs, (keys.count > 1) {
        bodyString = bodyString! + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
        
        for key in keys {
            bodyString = bodyString! + "<a href=\"#\(key.replacingOccurrences(of: " ", with: ""))\">\(key)</a><br/>"
        }
    
        bodyString = bodyString! + "</div>"
    }

    bodyString = bodyString! + "</body></html>"
    
    return insertHead(bodyString,fontSize: Constants.FONT_SIZE)
}

func addressStringHTML() -> String
{
    let addressString:String = "<br/>\(Constants.CBC.LONG)<br/>\(Constants.CBC.STREET_ADDRESS)<br/>\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)<br/>\(Constants.CBC.PHONE_NUMBER)<br/><a href=\"mailto:\(Constants.CBC.EMAIL)\">\(Constants.CBC.EMAIL)</a><br/>\(Constants.CBC.WEBSITE)"
    
    return addressString
}

func addressString() -> String
{
    let addressString:String = "\n\n\(Constants.CBC.LONG)\n\(Constants.CBC.STREET_ADDRESS)\n\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)\nPhone: \(Constants.CBC.PHONE_NUMBER)\nE-mail:\(Constants.CBC.EMAIL)\nWeb: \(Constants.CBC.WEBSITE)"
    
    return addressString
}

//var alerts = [UIAlertController]()

func networkUnavailable(_ viewController:UIViewController,_ message:String?)
{
    alert(viewController:viewController,title:Constants.Network_Error,message:message,completion:nil)
}

//func notification(title:String?,message:String?)
//{
//    if #available(iOS 10.0, *) {
//        let content = UNMutableNotificationContent()
//
//        content.title = title ?? ""
//        content.body = message ?? ""
//        content.sound = UNNotificationSound.default()
//        
//        // Deliver the notification in five seconds.
//        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.0, repeats: false)
//        let request = UNNotificationRequest.init(identifier: "CBC", content: content, trigger: trigger)
//        
//        // Schedule the notification.
//        let center = UNUserNotificationCenter.current()
//        center.add(request) { (error) in
//            print(error)
//        }
//        
//        print("should have been added")
//    } else {
//        // Fallback on earlier versions
//    }
//}

func alert(viewController:UIViewController,title:String?,message:String?,completion:((Void)->(Void))?)
{
    guard UIApplication.shared.applicationState == UIApplicationState.active else {
        return
    }
    
    let alert = UIAlertController(title:title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        completion?()
    })
    alert.addAction(action)
    
    DispatchQueue.main.async(execute: { () -> Void in
        viewController.present(alert, animated: true, completion: nil)
    })
}

func alert(viewController:UIViewController,title:String?,message:String?,actions:[AlertAction]?)
{
    guard Thread.isMainThread else {
        return
    }
    
    guard UIApplication.shared.applicationState == UIApplicationState.active else {
        return
    }
    
    let alert = UIAlertController(title:title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    if let alertActions = actions {
        for alertAction in alertActions {
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                alertAction.action?()
            })
            alert.addAction(action)
        }
    } else {
        let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
    }
    
    viewController.present(alert, animated: true, completion: nil)
//    DispatchQueue.main.async(execute: { () -> Void in
//    })
}

func searchAlert(viewController:UIViewController,title:String?,message:String?,searchText:String?,searchAction:((_ alert:UIAlertController)->(Void))?)
{
    let alert = UIAlertController(  title: title,
                                    message: message,
                                    preferredStyle: .alert)
    alert.makeOpaque()
    
    alert.addTextField(configurationHandler: { (textField:UITextField) in
        textField.placeholder = searchText ?? "search string"
    })
    
    let search = UIAlertAction(title: "Search", style: UIAlertActionStyle.default, handler: {
        alertItem -> Void in
        searchAction?(alert)
    })
    alert.addAction(search)
    
    let clear = UIAlertAction(title: "Clear", style: UIAlertActionStyle.destructive, handler: {
        alertItem -> Void in
        (alert.textFields![0] as UITextField).text = ""
        searchAction?(alert)
    })
    alert.addAction(clear)
    
    let cancel = UIAlertAction(title: "Cancel", style: .default, handler: {
        (action : UIAlertAction!) -> Void in
    })
    alert.addAction(cancel)

    DispatchQueue.main.async(execute: { () -> Void in
        viewController.present(alert, animated: true, completion: nil)
    })
}

//func useralert(viewController:self,title:String?,message:String?)
//{
//    if (UIApplication.shared.applicationState == UIApplicationState.active) {
//        let alert = UIAlertController(title: title,
//                                      message: message,
//                                      preferredStyle: .alert)
//        
//        let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
//            
//        })
//        alert.addAction(action)
//        
//        //        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//        
//        DispatchQueue.main.async(execute: { () -> Void in
//            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
//        })
//    }
//}

func firstSecondCancel(viewController:UIViewController,title:String?,message:String?,
                       firstTitle:String?,   firstAction:((Void)->(Void))?, firstStyle: UIAlertActionStyle,
                       secondTitle:String?,  secondAction:((Void)->(Void))?, secondStyle: UIAlertActionStyle,
                       cancelAction:((Void)->(Void))?)
{
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    if firstTitle != nil {
        let yesAction = UIAlertAction(title: firstTitle, style: firstStyle, handler: { (UIAlertAction) -> Void in
            firstAction?()
        })
        alert.addAction(yesAction)
    }
    
    if secondTitle != nil {
        let noAction = UIAlertAction(title: secondTitle, style: secondStyle, handler: { (UIAlertAction) -> Void in
            secondAction?()
        })
        alert.addAction(noAction)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        cancelAction?()
    })
    alert.addAction(cancelAction)
    
    DispatchQueue.main.async(execute: { () -> Void in
        viewController.present(alert, animated: true, completion: nil)
    })
}

struct AlertAction {
    let title : String
    let style : UIAlertActionStyle
    let action : ((Void)->(Void))?
}

func alertActionsCancel(viewController:UIViewController,title:String?,message:String?,alertActions:[AlertAction],cancelAction:((Void)->(Void))?)
{
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    for alertAction in alertActions {
        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
            alertAction.action?()
        })
        alert.addAction(action)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        cancelAction?()
    })
    alert.addAction(cancelAction)
    
    DispatchQueue.main.async(execute: { () -> Void in
        viewController.present(alert, animated: true, completion: nil)
    })
}

