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

func startAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    } catch let error as NSError {
        print("failed to setCategory(AVAudioSessionCategoryPlayback): \(error.localizedDescription)")
    }
    
    //        do {
    //            try audioSession.setActive(true)
    //        } catch let error as NSError {
    //            print("failed to audioSession.setActive(true): \(error.localizedDescription)")
    //        }
    
    UIApplication.shared.beginReceivingRemoteControlEvents()
}

func stopAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setActive(false)
    } catch let error as NSError {
        print("failed to audioSession.setActive(false): \(error.localizedDescription)")
    }
}

func open(scheme: String?,cannotOpen:(()->(Void))?)
{
    guard let scheme = scheme else {
        return
    }
    
    guard let url = URL(string: scheme) else {
        return
    }
    
    guard UIApplication.shared.canOpenURL(url) else { // Reachability.isConnectedToNetwork() &&
        cannotOpen?()
        return
    }
    
    if #available(iOS 10, *) {
        //UIApplicationOpenURLOptionUniversalLinksOnly:
        //Use a boolean value set to true (YES) to only open the URL if it is a valid universal link with an application configured to open it.
        //If there is no application configured or the user disabled using it to open the link the completion handler is called with false (NO).
        
//        let options = [UIApplicationOpenURLOptionUniversalLinksOnly : true]

        UIApplication.shared.open(url, options: [:],
                                  completionHandler: {
                                    (success) in
                                    print("Open \(scheme): \(success)")
        })
    } else {
        let success = UIApplication.shared.openURL(url)
        print("Open \(scheme): \(success)")
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
    guard let path = cachesURL()?.path else {
        return nil
    }
    
    var files = [String]()
    
    let fileManager = FileManager.default

    do {
        let array = try fileManager.contentsOfDirectory(atPath: path)
        
        for string in array {
            if let range = string.range(of: fileType) {
                if fileType == String(string[range.lowerBound...]) {
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
    guard let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE) else {
        return
    }
    
    let fileManager = FileManager.default
    
    if let filename = Globals.shared.mediaCategory.filename, let jsonFileURL = cachesURL()?.appendingPathComponent(filename) {
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
            do {
                // Copy File From Bundle To Documents Directory
                try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
            } catch let error as NSError {
                print("failed to copy mediaItems.json: \(error.localizedDescription)")
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItem(atPath: jsonBundlePath)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItem(atPath: jsonFileURL.path)
                
                if  let jsonBundleModDate = jsonBundleAttributes[FileAttributeKey.modificationDate] as? Date,
                    let jsonDocumentsModDate = jsonDocumentsAttributes[FileAttributeKey.modificationDate] as? Date {
                    if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
                        //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                        print("JSON in Documents is newer than JSON in bundle")
                    }
                    
                    if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                        print("JSON in Documents is the same date as JSON in bundle")
                        if  let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as? Int,
                            let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as? Int {
                            if (jsonBundleFileSize != jsonDocumentsFileSize) {
                                print("Same dates different file sizes")
                                //We have a problem.
                            } else {
                                print("Same dates same file sizes")
                                //Do nothing, they are the same.
                            }
                        }
                    }
                    
                    if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
                        print("JSON in bundle is newer than JSON in Documents")
                        //copy the bundle into Documents directory
                        do {
                            // Copy File From Bundle To Documents Directory
                            try fileManager.removeItem(atPath: jsonFileURL.path)
                            try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
                        } catch let error as NSError {
                            print("failed to copy mediaItems.json: \(error.localizedDescription)")
                        }
                    }
                }
            } catch let error as NSError {
                print("failed to get json file attributes: \(error.localizedDescription)")
            }
        }
    }
}

func jsonFromURL(url:String) -> Any?
{
    guard Globals.shared.reachability.isReachable, let url = URL(string: url) else {
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
        print("able to read json from the URL.")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            print(json)
            return json
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
    } catch let error as NSError {
        NSLog(error.localizedDescription)
    }

    return nil
}

func jsonFromFileSystem(filename:String?) -> Any?
{
    guard let filename = filename else {
        return nil
    }
    
    guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
        return nil
    }
    
    do {
        let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
        print("able to read json from the URL.")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return nil
        }
    } catch let error as NSError {
        print("Network unavailable: json could not be read from the file system.")
        NSLog(error.localizedDescription)
        return nil
    }
}

var jsonQueue : OperationQueue! = {
    let operationQueue = OperationQueue()
    operationQueue.name = "JSON"
    operationQueue.qualityOfService = .background
    operationQueue.maxConcurrentOperationCount = 1
    return operationQueue
}()

func jsonFromURL(url:String,filename:String) -> Any?
{
    guard Globals.shared.reachability.isReachable, let url = URL(string: url) else {
        return jsonFromFileSystem(filename: filename)
    }

    if let json = jsonFromFileSystem(filename: filename) {
        // Causes deadlock in refresh
//        operationQueue.cancelAllOperations()
//        operationQueue.waitUntilAllOperationsAreFinished()

        jsonQueue.addOperation {
            do {
                let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
                print("able to read json from the URL.")
                
                do {
                    if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                        try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
                    }
                    
                    print("able to write json to the file system")
                } catch let error as NSError {
                    print("unable to write json to the file system.")
                    NSLog(error.localizedDescription)
                }
            } catch let error {
                NSLog(error.localizedDescription)
            }
        }

        return json
    } else {
        do {
            let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
            print("able to read json from the URL.")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                do {
                    if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                        try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
                    }
                    
                    print("able to write json to the file system")
                } catch let error as NSError {
                    print("unable to write json to the file system.")
                    
                    NSLog(error.localizedDescription)
                }
                //            print(json)
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return jsonFromFileSystem(filename: filename)
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return jsonFromFileSystem(filename: filename)
        }
    }
}

func stringWithoutPrefixes(_ fromString:String?) -> String?
{
    guard let fromString = fromString else {
        return nil
    }
    
    if let range = fromString.range(of: "A is "), range.lowerBound == "a".startIndex {
        return fromString
    }
    
    let sourceString = fromString.replacingOccurrences(of: Constants.DOUBLE_QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
//    print(sourceString)
    
    let prefixes = ["A ","An ","The "] // "And ",
    
    var sortString = sourceString
    
    for prefix in prefixes {
        if (sourceString.endIndex >= prefix.endIndex) && (String(sourceString[..<prefix.endIndex]).lowercased() == prefix.lowercased()) {
            sortString = String(sourceString[prefix.endIndex...])
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
    guard let grouping = grouping else {
        return nil
    }
    
    var strings:[String]?
    
    switch grouping {
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
    guard let mediaItems = mediaItems else {
        return nil
    }
 
    guard let sorting = sorting else {
        return nil
    }
    
    return Array(
            Set(
                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                    assert(mediaItem.fullDate != nil) // We're assuming this gets ALL mediaItems.
                    return mediaItem.fullDate != nil
                }).map({ (mediaItem:MediaItem) -> Int in
                    let calendar = Calendar.current
                    if let fullDate = mediaItem.fullDate {
                        if let year = (calendar as NSCalendar).components(.year, from: fullDate).year {
                            return year
                        }
                    }
                    
                    return -1
                })
            )
            ).sorted(by: { (first:Int, second:Int) -> Bool in
                switch sorting {
                case SORTING.CHRONOLOGICAL:
                    return first < second
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return first > second
                    
                default:
                    break
                }
                
                return false
            })
}

func stringMarkedBySearchWithHTML(string:String?,searchText:String?,wholeWordsOnly:Bool) -> String?
{
    guard let string = string, !string.isEmpty else {
        return nil
    }
    
    guard let searchText = searchText, !searchText.isEmpty else {
        return nil
    }
    
    func mark(_ input:String) -> String
    {
        var string = input
        
        var stringBefore:String = Constants.EMPTY_STRING
        var stringAfter:String = Constants.EMPTY_STRING
        var newString:String = Constants.EMPTY_STRING
        var foundString:String = Constants.EMPTY_STRING

        while (string.lowercased().range(of: searchText.lowercased()) != nil) {
            guard let range = string.lowercased().range(of: searchText.lowercased()) else {
                break
            }
            
            stringBefore = String(string[..<range.lowerBound])
            stringAfter = String(string[range.upperBound...])
            
            var skip = false
            
            if wholeWordsOnly {
                if stringBefore == "" {
                    if  let characterBefore:Character = newString.last,
                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                        if CharacterSet.letters.contains(unicodeScalar) { // !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        }
                        
                        if searchText.count == 1 {
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                skip = true
                            }
                        }
                    }
                } else {
                    if  let characterBefore:Character = stringBefore.last,
                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                        if CharacterSet.letters.contains(unicodeScalar) { // !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        }
                        
                        if searchText.count == 1 {
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                skip = true
                            }
                        }
                    }
                }
                
                if let characterAfter:Character = stringAfter.first {
                    if let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) {
//                        !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                        skip = true
                    } else {
//                            if characterAfter == "." {
//                                if let afterFirst = stringAfter[String(String(characterAfter).endIndex...]).first,
//                                    let unicodeScalar = UnicodeScalar(String(afterFirst)) {
//                                    if !CharacterSet.whitespacesAndNewlines.contains(unicodeScalar) && !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
//                                        skip = true
//                                    }
//                                }
//                            }
                    }

                    //                            print(characterAfter)
                    
                    // What happens with other types of apostrophes?
                    if stringAfter.endIndex >= "'s".endIndex {
                        if (String(stringAfter[..<"'s".endIndex]) == "'s") {
                            skip = false
                        }
                        if (String(stringAfter[..<"'t".endIndex]) == "'t") {
                            skip = false
                        }
                        if (String(stringAfter[..<"'d".endIndex]) == "'d") {
                            skip = false
                        }
                    }
                }
                if let characterBefore:Character = stringBefore.last {
                    if let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) {
//                        !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                        skip = true
                    }
                }
            }
            
            foundString = String(string[range.lowerBound...])
            if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
                foundString = String(foundString[..<newRange.upperBound])
            }
            
            if !skip {
                foundString = "<mark>" + foundString + "</mark>"
            }
            
            newString = newString + stringBefore + foundString
            
            stringBefore = stringBefore + foundString
            
            string = stringAfter
        }
        
        newString = newString + stringAfter
        
        return newString == Constants.EMPTY_STRING ? string : newString
    }
    
    let htmlString = "<!DOCTYPE html><html><body>" + mark(string) + "</body></html>"
    
    return htmlString
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
    guard let scripture = scripture else {
        return nil
    }
    
    var verses = [Int]()

    var string = scripture.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if (string == Constants.EMPTY_STRING) {
        return []
    }
    
    guard let colon = string.range(of: ":") else {
        return []
    }
//        let hyphen = string?.range(of: "-")
//        let comma = string?.range(of: ",")
    
    //Is not correct for books with only one chapter
    // e.g. ["Philemon","Jude","2 John","3 John"]

    string = String(string[colon.upperBound...])
    
    var chars = Constants.EMPTY_STRING
    
    var seenHyphen = false
    var seenComma = false
    
    var startVerse = 0
    var endVerse = 0
    
    var breakOut = false
    
    for character in string {
        if breakOut {
            break
        }
        switch character {
        case "–":
            fallthrough
        case "-":
            seenHyphen = true
            if (startVerse == 0) {
                if let num = Int(chars) {
                    startVerse = num
                }
            }
            chars = Constants.EMPTY_STRING
            break
            
        case "(":
            breakOut = true
            break
            
        case ",":
            seenComma = true
            if let num = Int(chars) {
                verses.append(num)
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
        if let num = Int(chars) {
            startVerse = num
        }
    }
    if (startVerse != 0) {
        if (endVerse == 0) {
            if let num = Int(chars) {
                endVerse = num
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
        if let num = Int(chars) {
            verses.append(num)
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
    guard let book = book else {
        return nil
    }
    
    var chaptersAndVerses = [Int:[Int]]()
    
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0

    startChapter = 1
    
    switch testament(book) {
    case Constants.Old_Testament:
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
            endChapter = Constants.OLD_TESTAMENT_CHAPTERS[index]
        }
        break
        
    case Constants.New_Testament:
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
            endChapter = Constants.NEW_TESTAMENT_CHAPTERS[index]
        }
        break
        
    default:
        break
    }
    
    for chapter in startChapter...endChapter {
        startVerse = 1
        
        switch testament(book) {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
            }
            break
            
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
            }
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
    guard let book = book else {
        return nil
    }
 
    var verses = [Int]()
    
    let startVerse = 1
    var endVerse = 0
    
    switch testament(book) {
    case Constants.Old_Testament:
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
            index < Constants.OLD_TESTAMENT_VERSES.count,
            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
        }
        break
    case Constants.New_Testament:
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
        switch testament(book) {
        case Constants.Old_Testament:
//            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
//                print(index,Constants.OLD_TESTAMENT_VERSES.count,Constants.OLD_TESTAMENT_VERSES[index].count)
//            }
            break
        case Constants.New_Testament:
//            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
//                print(index,Constants.NEW_TESTAMENT_VERSES.count,Constants.NEW_TESTAMENT_VERSES[index].count)
//            }
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

    guard let book = book else {
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
    
    if let chars = string {
        for char in chars {
            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: ":,-").contains(unicodeScalar) {
                tokens.append(token)
                token = Constants.EMPTY_STRING
                
                tokens.append(String(char))
            } else {
                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: "0123456789").contains(unicodeScalar) {
                    token.append(char)
                }
            }
        }
    }
    
    if token != Constants.EMPTY_STRING {
        tokens.append(token)
    }
    
    debug("Done w/ parsing and creating tokens")
    
    if tokens.count > 0 {
        var startVerses = Constants.NO_CHAPTER_BOOKS.contains(book)
        
        if let first = tokens.first, let number = Int(first) {
            tokens.remove(at: 0)
            if Constants.NO_CHAPTER_BOOKS.contains(book) {
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
                                                
                                                switch testament(book) {
                                                case Constants.Old_Testament:
                                                    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                                        chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                    }
                                                    break
                                                case Constants.New_Testament:
                                                    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                                    
                                    switch testament(book) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    index >= 0,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count,
                                    startChapter >= 1
                                {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.NEW_TESTAMENT_VERSES.count,
                                    index >= 0,
                                    startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count,
                                    startChapter >= 1
                                {
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
                                    
                                    switch testament(book) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                                
                                switch testament(book) {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][currentChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][currentChapter - 1]
                                    }
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
                                        
                                        switch testament(book) {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
    
    guard let scriptureReference = scriptureReference else {
        return nil
    }
    
    var chapters = [Int]()
    
    var colonCount = 0
    
    let string = scriptureReference.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if (string == Constants.EMPTY_STRING) {
        return nil
    }
    
    //        print("\(string!)")
    
    let colon = string.range(of: ":")
    let hyphen = string.range(of: "-")
    let comma = string.range(of: ",")
    
    //        print(scripture,string)
    
    if (colon == nil) && (hyphen == nil) &&  (comma == nil) {
        if let num = Int(string) {
            chapters = [num]
        }
    } else {
        var chars = Constants.EMPTY_STRING
        
        var seenColon = false
        var seenHyphen = false
        var seenComma = false
        
        var startChapter = 0
        var endChapter = 0
        
        var breakOut = false
        
        for character in string {
            if breakOut {
                break
            }
            switch character {
            case ":":
                if !seenColon {
                    seenColon = true
                    if let num = Int(chars) {
                        if (startChapter == 0) {
                            startChapter = num
                        } else {
                            endChapter = num
                        }
                    }
                } else {
                    if (seenHyphen) {
                        if let num = Int(chars) {
                            endChapter = num
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
                        if let num = Int(chars) {
                            startChapter = num
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
                    if let num = Int(chars) {
                        chapters.append(num)
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
                    if let num = Int(chars) {
                        endChapter = num
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
                    if let num = Int(chars) {
                        chapters.append(num)
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
    guard let scriptureReference = scriptureReference else {
        return nil
    }
    
    var books = [String]()
    
    var string = scriptureReference
//        print(string)
    
    var otBooks = [String]()
    
    for book in Constants.OLD_TESTAMENT_BOOKS {
        if let range = string.range(of: book) {
            otBooks.append(book)
            
            let before = String(string[..<range.lowerBound])
            let after = String(string[range.upperBound...])
            
            string = before + Constants.SINGLE_SPACE + after
        }
    }
    
    for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
        if let range = string.range(of: book) {
            books.append(book)
            
            let before = String(string[..<range.lowerBound])
            let after = String(string[range.upperBound...])
            
            string = before + Constants.SINGLE_SPACE + after
        }
    }
    
    let ntBooks = books.reversed()

    books = otBooks
    books.append(contentsOf: ntBooks)
    
    string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)

//        print(string)
    
    // Only works for "<book> - <book>"
    
    if (string == "-") {
        if books.count == 2 {
            let book1 = scriptureReference.range(of: books[0])
            let book2 = scriptureReference.range(of: books[1])
            let hyphen = scriptureReference.range(of: "-")

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
    
//    print(books)
    return books.count > 0 ? books.sorted() { scriptureReference.range(of: $0)?.lowerBound < scriptureReference.range(of: $1)?.lowerBound } : nil // redundant
}

func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
{
    guard let mediaItem = mediaItem else {
        return nil
    }
    
    guard let multiPartSort = mediaItem.multiPartSort else {
        return nil
    }
    
    var multiPartMediaItems:[MediaItem]?
    
    if mediaItem.hasMultipleParts {
        if (Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
            let seriesMediaItems = Globals.shared.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                return mediaItem.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem.multiPartName) : (testMediaItem.id == mediaItem.id)
            })
            multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: SORTING.CHRONOLOGICAL)
        } else {
            multiPartMediaItems = Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]
        }
    } else {
        multiPartMediaItems = [mediaItem]
    }
    
    return multiPartMediaItems
}

func mediaItemsInBook(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
{
    guard let book = book else {
        return nil
    }
    
    return mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
        if let books = mediaItem.books {
            return books.contains(book)
        } else {
            return false
        }
    }).sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
        if let firstDate = first.fullDate, let secondDate = second.fullDate {
            if (firstDate.isEqualTo(secondDate)) {
                return first.service < second.service
            } else {
                return firstDate.isOlderThan(secondDate)
            }
        } else {
            return false // Arbitrary
        }
    })
}

func booksFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    var bookSet = Set<String>()
    
    for mediaItem in mediaItems {
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
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    var bookSectionSet = Set<String>()
    
    for mediaItem in mediaItems {
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
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(
                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.hasMultipleParts
                }).map({ (mediaItem:MediaItem) -> String in
                    return mediaItem.multiPartName ?? Constants.Strings.None
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(
                mediaItems.map({ (mediaItem:MediaItem) -> String in
                    if let multiPartSection = mediaItem.multiPartSection {
                        return multiPartSection
                    } else {
                        return "ERROR"
                    }
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?,withTitles:Bool) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(
                mediaItems.map({ (mediaItem:MediaItem) -> String in
                    if mediaItem.hasMultipleParts {
                        return mediaItem.multiPartName!
                    } else {
                        return withTitles ? (mediaItem.title ?? "No Title") : Constants.Strings.Individual_Media
                    }
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func bookNumberInBible(_ book:String?) -> Int?
{
    guard let book = book else {
        return nil
    }

    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
        return index
    }
    
    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
        return Constants.OLD_TESTAMENT_BOOKS.count + index
    }
    
    return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
}

func tokenCountsFromString(_ string:String?) -> [(String,Int)]?
{
    guard !Globals.shared.isRefreshing else {
        return nil
    }
    
    guard let string = string else {
        return nil
    }
    
    var tokenCounts = [(String,Int)]()
    
    if let tokens = tokensFromString(string) {
        for token in tokens {
            var count = 0
            var string = string
            
            while let range = string.range(of: token, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                count += 1
                string = String(string[range.upperBound...])
            }
            
            tokenCounts.append((token,count))
            
            if Globals.shared.isRefreshing {
                break
            }
        }
    }
    
    return tokenCounts.count > 0 ? tokenCounts : nil
}

func tokensFromString(_ string:String?) -> [String]?
{
    guard !Globals.shared.isRefreshing else {
        return nil
    }
    
    guard let string = string else {
        return nil
    }
    
    var tokens = Set<String>()
    
    var str = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\r\n", with: " ")
    
    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = String(str[..<range.lowerBound])
    }
    
    //        print(name)
    //        print(string)
    
    var token = Constants.EMPTY_STRING

    func processToken()
    {
//        guard (token.endIndex > String.Index(encodedOffset: 2)) else { // "XX".endIndex
//            token = Constants.EMPTY_STRING
//            return
//        }
        
        let excludedWords = [String]() //["and", "are", "can", "for", "the"]
        
        for word in excludedWords {
            if token.lowercased() == word.lowercased() {
                token = Constants.EMPTY_STRING
                break
            }
        }
        
//        if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
//            token = Constants.EMPTY_STRING
//        }
        
//        if token.lowercased() != "it's" {
//            if let range = token.lowercased().range(of: "'s") {
//                token = String(token[..<range.lowerBound])
//            }
//        }
        
        if token != token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars)) {
            //                print("\(token)")
            token = token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars))
            //                print("\(token)")
        }
        
        if token != Constants.EMPTY_STRING {
            tokens.insert(token.uppercased())
            token = Constants.EMPTY_STRING
        }
    }
    
    for index in str.indices {
        //        print(char)
        
        let char = str[index]
        
        let remainder = String(str[index...])
        
        let suffix = remainder.endIndex >= "'s".endIndex ? remainder[..<"'s".endIndex] : ""
//        print(suffix)
        
        let next = remainder.endIndex > "'s".endIndex ? remainder[suffix.endIndex] : nil
//        print(next)
        
        var skip = false
        
        // What happens with other types of apostrophes?
        if suffix.lowercased() == "'s" {
            skip = true
        }
        
        if suffix.lowercased() == "'t" {
            skip = true
        }
        
        if suffix.lowercased() == "'d" {
            skip = true
        }
        
        if let next = next, let unicodeScalar = UnicodeScalar(String(next)) {
            skip = skip && !CharacterSet.letters.contains(unicodeScalar)
        }
        
//        print(skip)
        
        if let unicodeScalar = UnicodeScalar(String(char)) {
            if !CharacterSet.letters.contains(unicodeScalar), !skip {
//            if CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
                //                print(token)
                processToken()
            } else {
//                if !CharacterSet(charactersIn: Constants.Strings.NumberChars).contains(unicodeScalar) {
//                    if !CharacterSet(charactersIn: Constants.Strings.TrimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
                        // DO NOT WANT LEADING CHARS IN SET
                        //                        print(token)
                        token.append(char)
                        //                        print(token)
//                    }
//                }
            }
        }
        
        if Globals.shared.isRefreshing {
            break
        }
    }
    
    if token != Constants.EMPTY_STRING {
        processToken()
    }
    
    let tokenArray = Array(tokens).sorted() {
        $0.lowercased() < $1.lowercased()
    }
    
    return tokenArray.count > 0 ? tokenArray : nil
}

func lemmasInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lemma.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
            //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nameTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameType.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func lexicalTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lexicalClass.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
            //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func tokenTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
            //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nameTypesAndLexicalTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameTypeOrLexicalClass.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
            //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func tokensAndCountsInString(_ string:String?) -> [String:Int]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [String:Int]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther] //, .joinNames
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length) // string.utf16.count
    
    //    tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: options) { tag, tokenRange, sentenceRange, stop in
    //        let token = (string as NSString).substring(with: tokenRange)
    //        print(tag,token)
    //        tokens.append(token)
    ////        //                                let sentence = (string as NSString).substring(with: sentenceRange)
    ////        print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
    //    }
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range).uppercased()
            
            if CharacterSet.letters.intersection(CharacterSet(charactersIn: token)) == CharacterSet(charactersIn: token) {
                if let count = tokens[token] {
                    tokens[token] = count + 1
                } else {
                    tokens[token] = 1
                }
            }
            
//            if tag == "Word", Int(token) == nil {
//            }
            
            //        print("\(token): \(tag)") // \n\(sentence)\n
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func tokensAndCountsFromString(_ string:String?) -> [String:Int]?
{
    guard !Globals.shared.isRefreshing else {
        return nil
    }
    
    guard let string = string else {
        return nil
    }
    
    var tokens = [String:Int]()
    
    var str = string // .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) //.replacingOccurrences(of: "\r\n", with: " ")
    
    // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = String(str[..<range.lowerBound])
    }
    
    //        print(name)
    //        print(string)
    
//    var startIndex : String.Index?
    
    var token = Constants.EMPTY_STRING
//    {
//        didSet {
//            if token == Constants.EMPTY_STRING {
//                startIndex = nil
//            }
//        }
//    }
    
    func processToken()
    {
        token = token.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Only if we want to eliminate everything 2 characters and shorter.
//        guard (token.endIndex > String.Index(encodedOffset: 2)) else {
////            print(token)
//            token = Constants.EMPTY_STRING
//            return
//        }
        
        let excludedWords = [String]() // ["and", "are", "can", "for", "the"]
        
        for word in excludedWords {
            if token.lowercased() == word.lowercased() {
                token = Constants.EMPTY_STRING
                break
            }
        }
        
//        if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
//            token = Constants.EMPTY_STRING
//        }
        
//        print(token)
        
//        if token.lowercased() != "it's" {
//            if let range = token.lowercased().range(of: "'s") {
//                token = String(token[..<range.lowerBound])
//            }
//        }
        
        if token != token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars)) {
//                print("\(token)")
            token = token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars))
//                print("\(token)")
        }
        
//        print(token)
        
        if token != Constants.EMPTY_STRING {
//                print(token.uppercased())
            if let count = tokens[token.uppercased()] {
                tokens[token.uppercased()] = count + 1
            } else {
                tokens[token.uppercased()] = 1
            }
            
            token = Constants.EMPTY_STRING
        }
    }
    
    for index in str.indices {
        //        print(char)
        
        let char = str[index]

        let remainder = String(str[index...])
        
        let suffix = remainder.endIndex >= "'s".endIndex ? remainder[..<"'s".endIndex] : ""
//        print(suffix)
        
        let next = remainder.endIndex > "'s".endIndex ? remainder[suffix.endIndex] : nil
//        print(next)

        var skip = false
        
        // What happens with other types of apostrophes?
        if suffix.lowercased() == "'s" {
            skip = true
        }
        
        if suffix.lowercased() == "'t" {
            skip = true
        }
        
        if suffix.lowercased() == "'d" {
            skip = true
        }
        
        if let next = next, let unicodeScalar = UnicodeScalar(String(next)) {
            skip = skip && !CharacterSet.letters.contains(unicodeScalar)
        }
        
//        print(skip)
        
        if let unicodeScalar = UnicodeScalar(String(char)) {
            if !CharacterSet.letters.contains(unicodeScalar), !skip {
//            if CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
//                print(token)
                processToken()
                
//                var charBefore:Character?
//                var charAfter:Character?
//
//                var charNext:Character?
//
//                if let startIndex = startIndex, startIndex > str.startIndex {
//                    let before = str.index(startIndex,offsetBy: -1)
//                    charBefore = str[before]
//                }
//
//                if let startIndex = startIndex, startIndex < str.index(str.endIndex,offsetBy: -token.count) {
//                    let after = str.index(startIndex,offsetBy: token.count)
//                    charAfter = str[after]
//                }
//
//                if index < str.index(str.endIndex,offsetBy: -1) {
//                    let next = str.index(index,offsetBy: 1)
//                    charNext = str[next]
//                }
//
//                var process = true
//
//                if token.count == 1 {
//                    if String(char) != "." {
//                        if let charBefore = charBefore, let before = UnicodeScalar(String(charBefore)) {
//                            if !CharacterSet(charactersIn: Constants.Strings.TrimChars).contains(before) {
//                                process = false
//                            }
//                        }
//                    } else {
//                        if let charBefore = charBefore, let before = UnicodeScalar(String(charBefore)) {
//                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(before) {
//                                process = false
//                            }
//                        }
//
//                        if let charAfter = charAfter, let after = UnicodeScalar(String(charAfter)) {
//                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(after) {
//                                process = false
//                            }
//                        }
//
//                        if let charNext = charNext, let next = UnicodeScalar(String(charNext)) {
//                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(next) {
//                                process = false
//                            }
//                        }
//                    }
//                }
//
//                if process {
//                    processToken()
//                } else {
//                    print(char,charNext,token,charBefore,charAfter)
//                    token = Constants.EMPTY_STRING
//                }
            } else {
                token.append(char)
//                if !CharacterSet(charactersIn: Constants.Strings.NumberChars).contains(unicodeScalar) {
//                    if !CharacterSet(charactersIn: Constants.Strings.TrimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
//                        // DO NOT WANT LEADING CHARS IN SET
////                        print(token)
//
////                        if token == Constants.EMPTY_STRING {
////                            startIndex = index
////                        }
//
//                        token.append(char)
////                        print(token)
//                    }
//                }
            }
        }

        if Globals.shared.isRefreshing {
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
    guard let name = name else {
        return nil
    }
    
    if let firstName = firstNameFromName(name), let range = name.range(of: firstName) {
        return String(name[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } else {
        return name
    }
}

func century(_ strings:String?) -> String?
{
    guard let string = strings?.components(separatedBy: "\n").first else {
        return nil
    }
    
    if let number = Int(string) {
        let value = number/100 * 100
        return "\(value == 0 ? 1 : value)"
    }

    return nil
}

func firstNameFromName(_ name:String?) -> String?
{
    guard let name = name else {
        return nil
    }
    
    var firstName:String?
    
    var string:String?
    
    if let title = titleFromName(name) {
        string = String(name[title.endIndex...])
    } else {
        string = name
    }
    
    if let string = string?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
        var newString = Constants.EMPTY_STRING
        
        for char in string {
            if String(char) == Constants.SINGLE_SPACE {
                firstName = newString
                break
            }
            newString.append(char)
        }
    }

//        print(name)
//        print(string)
    
    return firstName
}

func titleFromName(_ name:String?) -> String?
{
    guard let name = name else {
        return nil
    }
    
    var title = Constants.EMPTY_STRING
    
    if name.range(of: ". ") != nil {
        for char in name {
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
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasClassName
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.classSection ?? Constants.Strings.None
            })
            )
            ).sorted()
}

func speakerSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasSpeaker
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speakerSection ?? Constants.Strings.None
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
}

func speakersFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return
        Array(
            Set(mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasSpeaker
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speaker ?? Constants.Strings.None
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
}

func sortMediaItemsChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
//        print($0.dateService,$1.dateService)
        return $0.dateService < $1.dateService
        
        // VERY Computationally Expensive
//        guard let firstDate = $0.fullDate, let secondDate = $1.fullDate else {
//            return false // arbitrary
//        }
//
//        if (firstDate.isEqualTo(secondDate)) {
//            if ($0.service == $1.service) {
//                return $0.part < $1.part
//            } else {
//                 return $0.service < $1.service
//            }
//        } else {
//            return firstDate.isOlderThan(secondDate)
//        }
    }
}

func sortMediaItemsReverseChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
//        print($0.dateService,$1.dateService)
        return $0.dateService > $1.dateService
        
        // VERY Computationally Expensive
//        guard let firstDate = $0.fullDate, let secondDate = $1.fullDate else {
//            return false // arbitrary
//        }
//
//        if (firstDate.isEqualTo(secondDate)) {
//            if ($0.service == $1.service) {
//                return $0.part > $1.part
//            } else {
//                return $0.service > $1.service
//            }
//        } else {
//            return firstDate.isNewerThan(secondDate)
//        }
    }
}

func sortMediaItemsByYear(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
{
    guard let sorting = sorting else {
        return nil
    }
    
    var sortedMediaItems:[MediaItem]?

    switch sorting {
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
    guard let sorting = sorting else {
        return false // arbitrary
    }
    
    guard let firstDate = first.fullDate else {
        return false // arbitrary
    }
    
    guard let secondDate = second.fullDate else {
        return false // arbitrary
    }
    
    var result = false

    switch sorting {
    case SORTING.CHRONOLOGICAL:
        if (firstDate.isEqualTo(secondDate)) {
            result = (first.service < second.service)
        } else {
            result = firstDate.isOlderThan(secondDate)
        }
        break
    
    case SORTING.REVERSE_CHRONOLOGICAL:
        if (firstDate.isEqualTo(secondDate)) {
            result = (first.service > second.service)
        } else {
            result = firstDate.isNewerThan(secondDate)
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
    guard let mediaItems = Globals.shared.mediaRepository.list else {
        print("Testing the availability of mediaItem PDF's - no list")
        return
    }
    
    var counter = 1

    if (testExisting) {
        print("Testing the availability of mediaItem PDFs that we DO have in the mediaItemDicts - start")
        
        for mediaItem in mediaItems {
            if (showTesting) {
                print("Testing: \(counter) \(mediaItem.title ?? mediaItem.description)")
            } else {
//                    print(".", terminator: Constants.EMPTY_STRING)
            }
            
            if let title = mediaItem.title, let notes = mediaItem.notes, let notesURL = mediaItem.notesURL {
                if ((try? Data(contentsOf: notesURL)) == nil) {
                    print("Transcript DOES NOT exist for: \(title) PDF: \(notes)")
                } else {
                    
                }
            }
            
            if let title = mediaItem.title, let slides = mediaItem.slides, let slidesURL = mediaItem.slidesURL {
                if ((try? Data(contentsOf: slidesURL)) == nil) {
                    print("Slides DO NOT exist for: \(title) PDF: \(slides)")
                } else {
                    
                }
            }
            
            counter += 1
        }
        
        print("\nTesting the availability of mediaItem PDFs that we DO have in the mediaItemDicts - end")
    }

    if (testMissing) {
        print("Testing the availability of mediaItem PDFs that we DO NOT have in the mediaItemDicts - start")
        
        counter = 1
        for mediaItem in mediaItems {
            if (showTesting) {
                print("Testing: \(counter) \(mediaItem.title ?? mediaItem.description)")
            } else {
//                    print(".", terminator: Constants.EMPTY_STRING)
            }
            
            if (mediaItem.audio == nil) {
                print("No Audio file for: \(String(describing: mediaItem.title)) can't test for PDF's")
            } else {
                if let title = mediaItem.title, let id = mediaItem.id, let notesURL = mediaItem.notesURL {
                    if ((try? Data(contentsOf: notesURL)) != nil) {
                        print("Transcript DOES exist for: \(title) ID:\(id)")
                    } else {
                        
                    }
                }
                
                if let title = mediaItem.title, let id = mediaItem.id, let slidesURL = mediaItem.slidesURL {
                    if ((try? Data(contentsOf: slidesURL)) != nil) {
                        print("Slides DO exist for: \(title) ID: \(id)")
                    } else {
                        
                    }
                }
            }
            
            counter += 1
        }
        
        print("\nTesting the availability of mediaItem PDFs that we DO NOT have in the mediaItemDicts - end")
    }
}

func testMediaItemsTagsAndSeries()
{
    print("Testing for mediaItem series and tags the same - start")
    defer {
        print("Testing for mediaItem series and tags the same - end")
    }

    if let mediaItems = Globals.shared.mediaRepository.list {
        for mediaItem in mediaItems {
            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                if (mediaItem.multiPartName == mediaItem.tags) {
                    print("Multiple Part Name and Tags the same in: \(mediaItem.title ?? mediaItem.description) Multiple Part Name:\(mediaItem.multiPartName ?? mediaItem.description) Tags:\(mediaItem.tags ?? mediaItem.description)")
                }
            }
        }
    }
}

func testMediaItemsForAudio()
{
    print("Testing for audio - start")
    defer {
        print("Testing for audio - end")
    }
    
    guard let list = Globals.shared.mediaRepository.list else {
        print("Testing for audio - list empty")
        return
    }
    
    for mediaItem in list {
        if (!mediaItem.hasAudio) {
            print("Audio missing in: \(mediaItem.title ?? mediaItem.description)")
        } else {

        }
    }
    
}

func testMediaItemsForSpeaker()
{
    print("Testing for speaker - start")
    defer {
        print("Testing for speaker - end")
    }

    guard let list = Globals.shared.mediaRepository.list else {
        print("Testing for speaker - no list")
        return
    }
    
    for mediaItem in list {
        if (!mediaItem.hasSpeaker) {
            print("Speaker missing in: \(mediaItem.title ?? mediaItem.description)")
        }
    }
}

func testMediaItemsForSeries()
{
    print("Testing for mediaItems with \"(Part \" in the title but no series - start")
    defer {
        print("Testing for mediaItems with \"(Part \" in the title but no series - end")
    }

    guard let list = Globals.shared.mediaRepository.list else {
        print("Testing for speaker - no list")
        return
    }
    
    for mediaItem in list {
        if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
            print("Series missing in: \(mediaItem.title ?? mediaItem.description)")
        }
    }
}

func tagsSetFromTagsString(_ tagsString:String?) -> Set<String>?
{
    guard let tagsString = tagsString else {
        return nil
    }
    
    let array = tagsString.components(separatedBy: Constants.TAGS_SEPARATOR)
    
    return array.count > 0 ? Set(array) : nil
    
//    var tags = tagsString
//    var tag:String
//    var setOfTags = Set<String>()
//
//    while let range = tags.range(of: Constants.TAGS_SEPARATOR) {
//        tag = String(tags[..<range.lowerBound])
//        setOfTags.insert(tag)
//        tags = String(tags[range.upperBound...])
//    }
//
//    if !tags.isEmpty {
//        setOfTags.insert(tags)
//    }
//
//    return setOfTags.count > 0 ? setOfTags : nil
}

func tagsArrayToTagsString(_ tagsArray:[String]?) -> String?
{
    guard let tagsArray = tagsArray else {
        return nil
    }

    return tagsArray.count > 0 ? tagsArray.joined(separator: Constants.TAGS_SEPARATOR) : nil
    
//    var tagString:String?
//
//    for tag in tagsArray {
//        tagString = (tagString != nil ? tagString! + Constants.TAGS_SEPARATOR : "") + tag
//    }
//
//    return tagString
}

func tagsArrayFromTagsString(_ tagsString:String?) -> [String]?
{
    guard let tagsString = tagsString else {
        return nil
    }
    
    let array = tagsString.components(separatedBy: Constants.TAGS_SEPARATOR) 

    return array.count > 0 ? array : nil
    
//    var arrayOfTags:[String]?
//
//    if let tags = tagsSetFromTagsString(tagsString) {
//        arrayOfTags = Array(tags) //.sort() { $0 < $1 } // .sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) } // Not sorted
//    }
//
//    return arrayOfTags
}

func mediaItemsWithTag(_ mediaItems:[MediaItem]?,tag:String?) -> [MediaItem]?
{
    guard let tag = tag else {
        return nil
    }
    
    return
        mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
            if let tagSet = mediaItem.tagsSet {
                return tagSet.contains(tag)
            } else {
                return false
            }
        })
}

func tagsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }

    var tagsSet = Set<String>()
    
    for mediaItem in mediaItems {
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
        Thread.onMainThread {
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        }
    } else {
        showSendMailErrorAlert(viewController: viewController)
    }
}

//func presentHTMLModal(viewController:UIViewController, mediaItem:MediaItem?, style: UIModalPresentationStyle, title: String?, htmlString: String?)
//{
//    presentHTMLModal(viewController:viewController, dismiss:true, mediaItem:mediaItem, style:style, title:title, htmlString:htmlString)
//}

func presentHTMLModal(viewController:UIViewController, dismiss:Bool = true, mediaItem:MediaItem?, style: UIModalPresentationStyle, title: String?, htmlString: String?)
{
    guard let htmlString = htmlString else {
        return
    }
    
    guard let storyboard = viewController.storyboard else {
        return
    }
    
    if let navigationController = storyboard.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? WebViewController {
        if dismiss {
            Thread.onMainThread {
                viewController.dismiss(animated: true, completion: nil)
            }
        }
        
        navigationController.modalPresentationStyle = style
        
        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
        
        popover.navigationItem.title = title
        
        popover.search = true
        popover.mediaItem = mediaItem
        
        popover.html.string = htmlString
        popover.content = .html

        popover.navigationController?.isNavigationBarHidden = false
        
        Thread.onMainThread {
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
}

func stripCount(string:String?) -> String?
{
    guard let string = string else {
        return nil
    }
    
    if let range = string.range(of: " (") {
        let string = String(string[..<range.lowerBound])
        
        return string
    }
    
    return nil
}

func count(string:String?) -> Int?
{
    guard let string = string else {
        return nil
    }
    
    if let range = string.range(of: " (") {
        let string = String(string[range.upperBound...])
        
        if let range = string.range(of: ")") {
            let string = String(string[..<range.lowerBound])
            return Int(string)
        }
    }
    
    return nil
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
        let newStrings = strings.sorted(by: { (first:String, second:String) -> Bool in
            if let rangeFirst = first.range(of: " ("), let rangeSecond = second.range(of: " (") {
                let left = String(first[rangeFirst.upperBound...])
                let right = String(second[rangeSecond.upperBound...])
                
                let first = String(first[..<rangeFirst.lowerBound])
                let second = String(second[..<rangeSecond.lowerBound])
                
                if let rangeLeft = left.range(of: ")"), let rangeRight = right.range(of: ")") {
                    let left = String(left[..<rangeLeft.lowerBound])
                    let right = String(right[..<rangeRight.lowerBound])
                    
//                    print(first,left,second,right)
                    
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
        return newStrings
        
    default:
        return nil
    }
}

//func process(viewController:UIViewController,work:(()->(Any?))?,completion:((Any?)->())?)
//{
//    process(viewController:viewController,disableEnable:true,hideSubviews:false,work:work,completion:completion)
//}

func process(viewController:UIViewController,disableEnable:Bool = true,hideSubviews:Bool = false,work:(()->(Any?))?,completion:((Any?)->())?)
{
    guard (work != nil) && (completion != nil) else {
        return
    }
    
    guard let loadingViewController = viewController.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
        return
    }

    guard let container = loadingViewController.view else {
        return
    }
    
    guard let view = viewController.view else {
        return
    }
    
    Thread.onMainThread {
        if disableEnable {
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
        }
        
        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        if hideSubviews {
            for view in container.subviews {
                view.isHidden = true
            }
        }
        
        view.addSubview(container)
        
        DispatchQueue.global(qos: .background).async {
            let data = work?()
            
            Thread.onMainThread {
                if container != viewController.view {
                    container.removeFromSuperview()
                }
                
                if disableEnable {
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
                }
                
                completion?(data)
            }
        }
    }
}

func mailHTML(viewController:UIViewController,to: [String],subject: String, htmlString:String)
{
    let mailComposeViewController = MFMailComposeViewController()
    
    // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
    
    mailComposeViewController.setToRecipients(to)
    mailComposeViewController.setSubject(subject)
    
    mailComposeViewController.setMessageBody(htmlString, isHTML: true)
    
    if MFMailComposeViewController.canSendMail() {
        Thread.onMainThread {
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        }
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
//    pic.showsPageRange = true
    pic.showsPaperSelectionForLoadedPapers = true

    if let html = html {
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72.0 // 72=1" margins
        formatter.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
//        pic.printFormatter = formatter

        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer
        
        pi.orientation = orientation
    }

    if data != nil {
        pic.printingItem = data
    }
    
    Thread.onMainThread {
        if let barButtonItem = viewController.navigationItem.rightBarButtonItem {
            pic.present(from: barButtonItem, animated: true, completionHandler: nil)
        }
    }
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
    guard UIPrintInteractionController.isPrintingAvailable, let documentURL = documentURL else {
        return
    }
    
    process(viewController: viewController, work: {
        return NSData(contentsOf: documentURL)
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

func pageOrientation(viewController:UIViewController,portrait:(()->(Void))?,landscape:(()->(Void))?,cancel:(()->(Void))?)
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
            
            // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
            mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
            
            mailComposeViewController.setToRecipients([])
            mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
            
            if let body = itemsToMail[0] as? String {
                mailComposeViewController.setMessageBody(body, isHTML: true)
            }
            
            viewController.present(mailComposeViewController, animated: true, completion: nil)
        }
    })
}

func hmsToSeconds(string:String?) -> Double?
{
    guard var str = string?.replacingOccurrences(of: ",", with: ".") else {
        return nil
    }
    
//    guard var str = string else {
//        return nil
//    }
    
//    var milliseconds : Double = 0
//
//    if let range = str.range(of: ","), let ms = Int(String(str[range.upperBound...])) {
//        milliseconds = Double(ms)/1000
//        str = String(str[..<range.lowerBound])
//    }
    
    var numbers = [Double]()
    
    repeat {
        if let index = str.range(of: ":") {
            let numberString = String(str[..<index.lowerBound])
            
            if let number = Double(numberString) {
                numbers.append(number)
            }

            str = String(str[index.upperBound...])
        }
    } while str.range(of: ":") != nil

    if !str.isEmpty {
        if let number = Double(str) {
            numbers.append(number)
        }
    }

    var seconds = 0.0
    var counter = 0.0
    
    for number in numbers.reversed() {
        seconds = seconds + (counter != 0 ? number * pow(60.0,counter) : number)
        counter += 1
    }
    
//    seconds += milliseconds
    
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
    let fraction = timeNow - Double(Int(timeNow))
    
    var hms:String
    
    if (hours > 0) {
        hms = "\(String(format: "%02d",hours)):"
    } else {
        hms = "00:" //Constants.EMPTY_STRING
    }
    
    // \(String(format: "%.3f",fraction)
    // .trimmingCharacters(in: CharacterSet(charactersIn: "0."))
    
    hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
    
    return hms
}

//func popoverHTML(_ viewController:UIViewController,mediaItem:MediaItem?,title:String?,barButtonItem:UIBarButtonItem?,sourceView:UIView?,sourceRectView:UIView?,htmlString:String?)
//{
//    popoverHTML(viewController,mediaItem:mediaItem,transcript:nil,title:title,barButtonItem:barButtonItem,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
//}

func popoverHTML(_ viewController:UIViewController, mediaItem:MediaItem? = nil, transcript:VoiceBase? = nil, title:String? = nil, barButtonItem:UIBarButtonItem? = nil, sourceView:UIView? = nil, sourceRectView:UIView? = nil, htmlString:String?)
{
    guard Thread.isMainThread else {
        alert(viewController:viewController,title: "Not Main Thread", message: "functions:popoverHTML", completion: nil)
        return
    }
    
    guard let storyboard = viewController.storyboard else {
        return
    }
    
    guard htmlString != nil else {
        return
    }

    if let navigationController = storyboard.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? WebViewController {
        if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
            let hClass = viewController.traitCollection.horizontalSizeClass

            if hClass == .compact {
                navigationController.modalPresentationStyle = .overFullScreen
            } else {
                // I don't think this ever happens: collapsed and regular
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
            }
        } else {
            let vClass = viewController.traitCollection.verticalSizeClass
            
            if vClass == .compact {
                navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
            } else {
                if viewController.splitViewController?.displayMode == .primaryHidden {
                    if !UIApplication.shared.isRunningInFullScreen() {
                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                    } else {
                        navigationController.modalPresentationStyle = .formSheet // Used to be .popover
                    }
                } else {
                    if !UIApplication.shared.isRunningInFullScreen() {
                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                    } else {
                        navigationController.modalPresentationStyle = .formSheet //.overCurrentContext // Used to be .popover
                    }
                }
            }
            
//            navigationController.popoverPresentationController?.permittedArrowDirections = .any
//            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
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
        popover.html.string = insertHead(stripHead(htmlString),fontSize: popover.html.fontSize)
        
        popover.search = true
        popover.mediaItem = mediaItem
        popover.transcript = transcript

        popover.content = .html
        
        popover.navigationController?.isNavigationBarHidden = false
        
        Thread.onMainThread {
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
}

//func shareHTML(viewController:UIViewController,htmlString:String?)
//{
//    guard Thread.isMainThread else {
//        alert(viewController:viewController,title: "Not Main Thread", message: "functions:shareHTML", completion: nil)
//        return
//    }
//
//    guard let htmlString = htmlString else {
//        return
//    }
//
//    let print = UIMarkupTextPrintFormatter(markupText: htmlString)
//    let margin:CGFloat = 0.5 * 72
//    print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
//
//    let activityViewController = UIActivityViewController(activityItems:[stripHTML(htmlString),htmlString,print], applicationActivities: nil)
//
//    // exclude some activity types from the list (optional)
//
//    activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
//
//    activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem
//
//    // present the view controller
//    Thread.onMainThread {
//        viewController.present(activityViewController, animated: true, completion: nil)
//    }
//}

//func shareMediaItems(viewController:UIViewController,mediaItems:[MediaItem]?,stringFunction:(([MediaItem]?)->String?)?)
//{
//    guard (mediaItems != nil) && (stringFunction != nil) else {
//        return
//    }
//    
//    process(viewController: viewController, work: {
//        return stringFunction?(mediaItems)
//    }, completion: { (data:Any?) in
//        shareHTML(viewController: viewController, htmlString: data as? String)
//    })
//}

//func setupMediaItemsHTML(_ mediaItems:[MediaItem]?) -> String?
//{
//    return setupMediaItemsHTML(mediaItems,includeURLs:true,includeColumns:true)
//}

func stripHead(_ string:String?) -> String?
{
    guard let string = string else {
        return nil
    }
    
    var bodyString = string
    
    while bodyString.range(of: "<head>") != nil {
        if let startRange = bodyString.range(of: "<head>") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</head>") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                let string = to + from
                
                if let range = string.range(of: string) {
                    let from = String(bodyString[range.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
    }
    
    return bodyString
}

func insertMenuHead(_ string:String?,fontSize:Int) -> String?
{
    guard let filePath = Bundle.main.resourcePath else {
        return nil
    }

    guard let headContent = try? String(contentsOfFile: filePath + "/head.txt", encoding: String.Encoding.utf8) else {
        return nil
    }

    guard let styleContent = try? String(contentsOfFile: filePath + "/style.txt", encoding: String.Encoding.utf8) else {
        return nil
    }

    let head = "<html><head><style>body{font: -apple-system-body;font-size:\(fontSize)pt;}td{font-size:\(fontSize)pt;}mark{background-color:silver}\(styleContent)</style>\(headContent)</head>"
    
    return string?.replacingOccurrences(of: "<html>", with: head)
}

func insertHead(_ string:String?,fontSize:Int) -> String?
{
    var head = "<html><head><title>CBC Media</title><meta name=\"viewport\" content=\"width=device-width,initial-size=1.0\"/>"
    
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
    
//    print(string?.replacingOccurrences(of: "<html>", with: head))
    
    return string?.replacingOccurrences(of: "<html>", with: head)
}

func stripLinks(_ string:String?) -> String?
{
    guard let string = string else {
        return nil
    }
    
    var bodyString = string
    
    while bodyString.range(of: "<div>Locations") != nil {
        if let startRange = bodyString.range(of: "<div>Locations") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</div>") {
                let to = String(bodyString[..<startRange.lowerBound])
                
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                
                let string = to + from

                if let range = string.range(of: string) {
                    let from = String(bodyString[range.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
    }
    
//    bodyString = bodyString.replacingOccurrences(of: "<a href=\"#index\">Index</a><br/><br/>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "<a href=\"#index\">Index</a><br/>", with: "")

    while bodyString.range(of: "<a") != nil {
        if let startRange = bodyString.range(of: "<a") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])

                let string = to + from
                
                if let range = string.range(of: string) {
                    let from = String(bodyString[range.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
    }
    
    bodyString = bodyString.replacingOccurrences(of: "</a>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "(Return to Top)", with: "")

    return bodyString
}

func stripHTML(_ string:String?) -> String?
{
    guard let string = string else {
        return nil
    }
    
//    return insertHead(string.html2String,fontSize: Constants.FONT_SIZE)
    
    guard var bodyString = stripLinks(stripHead(string)) else {
        return nil
    }
    
    bodyString = bodyString.replacingOccurrences(of: "<!DOCTYPE html>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "<html>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "<body>", with: "")

    while bodyString.range(of: "<p ") != nil {
        if let startRange = bodyString.range(of: "<p ") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])

                bodyString = to + "\n\n" + String(bodyString[(to + from).endIndex...])
                //                    let string = to + from
                //                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
                //                        bodyString = to + from
                //                    }
            }
        }
    }
    
    while bodyString.range(of: "<br ") != nil {
        if let startRange = bodyString.range(of: "<br ") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                
                bodyString = to + String(bodyString[(to + from).endIndex...])
//                    let string = to + from
//                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
//                        bodyString = to + from
//                    }
            }
        }
    }
    
    while bodyString.range(of: "<span ") != nil {
        if let startRange = bodyString.range(of: "<span ") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                bodyString = to + String(bodyString[(to + from).endIndex...])
                
//                    let string = to + from
//                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
//                        bodyString = to + from
//                    }
            }
        }
    }
    
    while bodyString.range(of: "<font") != nil {
        if let startRange = bodyString.range(of: "<font") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                bodyString = to + String(bodyString[(to + from).endIndex...])
//                    let string = to + from
//                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
//                        bodyString = to + from
//                    }
            }
        }
    }
    
//    while bodyString.range(of: "<sup") != nil {
//        if let startRange = bodyString.range(of: "<sup") {
//            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
//                if let to = String(bodyString?[..<startRange.lowerBound]), let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound]) {
//                    if let from = String(bodyString[(to + from).endIndex...]) {
//                        bodyString = to + from
//                    }
////                    let string = to + from
////                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
////                        bodyString = to + from
////                    }
//                }
//            }
//        }
//    }
    
    while bodyString.range(of: "<sup>") != nil {
        if let startRange = bodyString.range(of: "<sup>") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</sup>") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])

                bodyString = to + String(bodyString[(to + from).endIndex...])
                    
//                    let string = to + from
//                    if let range = string.range(of: string), let from = String(bodyString[range.upperBound...]) {
//                        bodyString = to + from
//                    }
            }
        }
    }
    
    bodyString = bodyString.replacingOccurrences(of: "&rsquo;", with: "'")
    bodyString = bodyString.replacingOccurrences(of: "&rdquo;", with: "\"")
    bodyString = bodyString.replacingOccurrences(of: "&lsquo;", with: "'")
    bodyString = bodyString.replacingOccurrences(of: "&ldquo;", with: "\"")
    
    bodyString = bodyString.replacingOccurrences(of: "&mdash;", with: "-")
    bodyString = bodyString.replacingOccurrences(of: "&ndash;", with: "-")
    
    bodyString = bodyString.replacingOccurrences(of: "&nbsp;", with: " ")
    
    bodyString = bodyString.replacingOccurrences(of: "&ccedil;", with: "C")
    
    bodyString = bodyString.replacingOccurrences(of: "<br/>", with: "\n")
    bodyString = bodyString.replacingOccurrences(of: "</br>", with: "\n")
    
    bodyString = bodyString.replacingOccurrences(of: "<span>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<table>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<center>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<tr>", with: "")

    while bodyString.range(of: "<td") != nil {
        if let startRange = bodyString.range(of: "<td") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                
                let string = to + from
                if let range = string.range(of: string) {
                    let from = String(bodyString[range.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
    }
    
    bodyString = bodyString.replacingOccurrences(of: "</td>", with: Constants.SINGLE_SPACE)
    
    bodyString = bodyString.replacingOccurrences(of: "</tr>", with: "\n")
    
    bodyString = bodyString.replacingOccurrences(of: "</table>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "</center>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "</span>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "</font>", with: "")
    
//    bodyString = bodyString?.replacingOccurrences(of: "</sup>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "</body>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</html>", with: "")

    bodyString = bodyString.replacingOccurrences(of: "<em>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</em>", with: "")

    bodyString = bodyString.replacingOccurrences(of: "<div>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</div>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<mark>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</mark>", with: "")

    bodyString = bodyString.replacingOccurrences(of: "<i>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</i>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<p>", with: "\n\n")
    bodyString = bodyString.replacingOccurrences(of: "</p>", with: "")
    
    bodyString = bodyString.replacingOccurrences(of: "<b>", with: "")
    bodyString = bodyString.replacingOccurrences(of: "</b>", with: "")

//        print(bodyString)

//    return bodyString // why in the world were we putting the head back in?  So it works w/ WebViewController
    return insertHead(bodyString,fontSize: Constants.FONT_SIZE)
}

func setupMediaItemsHTMLGlobal(includeURLs:Bool,includeColumns:Bool) -> String?
{
    guard (Globals.shared.media.active?.list != nil) else {
        return nil
    }
    
    guard let grouping = Globals.shared.grouping else {
        return nil
    }
    
    guard let sorting = Globals.shared.sorting else {
        return nil
    }
    
    var bodyString = "<!DOCTYPE html><html><body>"
    
    bodyString = bodyString + "The following media "
    
    if Globals.shared.media.active?.list?.count > 1 {
        bodyString = bodyString + "are"
    } else {
        bodyString = bodyString + "is"
    }
    
    if includeURLs {
        bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
    } else {
        bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
    }

    if let category = Globals.shared.mediaCategory.selected {
        bodyString = bodyString + "Category: \(category)<br/>"
    }

    if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
        bodyString = bodyString + "Collection: \(tag)<br/>"
    }
    
    if Globals.shared.search.valid, let searchText = Globals.shared.search.text {
        bodyString = bodyString + "Search: \(searchText)<br/>"
    }
    
    if let grouping = translate(grouping) {
        bodyString = bodyString + "Grouped: By \(grouping)<br/>"
    }

    if let sorting = translate(sorting) {
        bodyString = bodyString + "Sorted: \(sorting)<br/>"
    }
    
    if let keys = Globals.shared.media.active?.section?.indexStrings {
        var count = 0
        for key in keys {
            if let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
                count += mediaItems.count
            }
        }

        bodyString = bodyString + "Total: \(count)<br/>"

        if includeURLs, (keys.count > 1) {
            bodyString = bodyString + "<br/>"
            bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
        }
        
        if includeColumns {
            bodyString = bodyString + "<table>"
        }
        
        for key in keys {
            if  let name = Globals.shared.media.active?.groupNames?[grouping]?[key],
                let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
                    if let speaker = mediaItem.speaker {
                        if let count = speakerCounts[speaker] {
                            speakerCounts[speaker] = count + 1
                        } else {
                            speakerCounts[speaker] = 1
                        }
                    }
                }
                
                let speakerCount = speakerCounts.keys.count
                
                let tag = key.replacingOccurrences(of: " ", with: "")

                if includeColumns {
                    if includeURLs {
                        bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>" //  name=\"\(tag)\" name=\"\(tag)\"
                    } else {
                        bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>"
                    }
                } else {
                    if includeURLs {
                        bodyString = bodyString + "<br/>" //  name=\"\(tag)\" name=\"\(tag)\"
                    } else {
                        bodyString = bodyString + "<br/>"
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString + "<tr>"
                    bodyString = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
                }
                
                if includeURLs, (keys.count > 1) {
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + " (\(mediaItems.count))" + "</a>"
                } else {
                    bodyString = bodyString + name + " (\(mediaItems.count))"
                }
                
                if speakerCount == 1 {
                    if let speaker = mediaItems[0].speaker, name != speaker {
                        bodyString = bodyString + " by " + speaker
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString + "</td>"
                    bodyString = bodyString + "</tr>"
                } else {
                    bodyString = bodyString + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["date","title","scripture"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if Globals.shared.grouping != GROUPING.CLASS {
                        if mediaItem.hasClassName {
                            order.append("class")
                        }
                    }
                    
                    if Globals.shared.grouping != GROUPING.EVENT {
                        if mediaItem.hasEventName {
                            order.append("event")
                        }
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString + "<br/>"
                    }
                }
            }
        }
        
        if includeColumns {
            bodyString = bodyString + "</table>"
        }
        
        bodyString = bodyString + "<br/>"
        
        if includeURLs, keys.count > 1 {
            bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
            
            switch grouping {
            case GROUPING.CLASS:
                fallthrough
            case GROUPING.SPEAKER:
                fallthrough
            case GROUPING.TITLE:
                let a = "A"
                
                if let indexTitles = Globals.shared.media.active?.section?.indexStrings {
                    let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                        if string.endIndex >= a.endIndex {
                            if let string = stringWithoutPrefixes(string) {
                                return String(string[..<a.endIndex]).uppercased()
                            }
                            
                            return "ERROR"
                        } else {
                            return string
                        }
                    }))).sorted() { $0 < $1 }
                    
                    var stringIndex = [String:[String]]()
                    
                    if let indexStrings = Globals.shared.media.active?.section?.indexStrings {
                        for indexString in indexStrings {
                            let key = String(indexString[..<a.endIndex]).uppercased()
                            
                            if stringIndex[key] == nil {
                                stringIndex[key] = [String]()
                            }

                            stringIndex[key]?.append(indexString)
                        }
                    }
                    
                    var index:String?
                    
                    for title in titles {
                        let link = "<a href=\"#\(title)\">\(title)</a>"
                        index = ((index != nil) ? index! + " " : "") + link
                    }
                    
                    bodyString = bodyString + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                    
                    if let index = index {
                        bodyString = bodyString + index + "<br/>"
                    }
                    
                    for title in titles {
                        bodyString = bodyString + "<br/>"
                        bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                        
                        if let keys = stringIndex[title] {
                            for key in keys {
                                if let title = Globals.shared.media.active?.groupNames?[grouping]?[key],
                                    let count = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count {
                                    let tag = key.replacingOccurrences(of: " ", with: "")
                                    bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                                }
                            }
                        }
                        
                        bodyString = bodyString + "</div>"
                    }
                    
                    bodyString = bodyString + "</div>"
                }
                break
                
            default:
                for key in keys {
                    if let title = Globals.shared.media.active?.groupNames?[grouping]?[key],
                        let count = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count {
                        let tag = key.replacingOccurrences(of: " ", with: "")
                        bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                    }
                }
                break
            }
            
            bodyString = bodyString + "</div>"
        }
    }
    
    bodyString = bodyString + "</body></html>"
    
//    print(insertHead(bodyString,fontSize: Constants.FONT_SIZE) as Any)
    
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
    guard let string = string else {
        return nil
    }
    
    switch string {
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
        
    case GROUPING.EVENT:
        return Grouping.Event
        
    default:
        return "ERROR"
    }
}

func setupMediaItemsHTML(_ mediaItems:[MediaItem]?,includeURLs:Bool = true,includeColumns:Bool = true) -> String?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    var mediaListSort = [String:[MediaItem]]()
    
    for mediaItem in mediaItems {
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

    var bodyString = "<!DOCTYPE html><html><body>"
    
    bodyString = bodyString + "The following media "
    
    if mediaItems.count > 1 {
        bodyString = bodyString + "are"
    } else {
        bodyString = bodyString + "is"
    }
    
    if includeURLs {
        bodyString = bodyString + " from <a target=\"_blank\" href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
    } else {
        bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
    }
    
    if let category = Globals.shared.mediaCategory.selected {
        bodyString = bodyString + "Category: \(category)<br/><br/>"
    }
    
    if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
        bodyString = bodyString + "Collection: \(tag)<br/><br/>"
    }
    
    if Globals.shared.search.valid, let searchText = Globals.shared.search.text {
        bodyString = bodyString + "Search: \(searchText)<br/><br/>"
    }
    
    let keys = Array(mediaListSort.keys).sorted() {
        stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
    }
    
//    .map({ (string:String) -> String in
//        return string
//    }).sorted() {
//        stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
//    }
    
    if includeURLs, (keys.count > 1) {
        bodyString = bodyString + "<a href=\"#index\">Index</a><br/><br/>"
    }
    
    var lastKey:String?
    
    if includeColumns {
        bodyString  = bodyString + "<table>"
    }
    
    for key in keys {
        if let mediaItems = mediaListSort[key] {
            switch mediaItems.count {
            case 1:
                if let mediaItem = mediaItems.first {
                    if let string = mediaItem.bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs:includeURLs, includeColumns:includeColumns) {
                        bodyString = bodyString + string
                    }
                    
                    if includeColumns {
                        bodyString  = bodyString + "<tr>"
                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
                    }
                    
                    bodyString = bodyString + "<br/>"
                    
                    if includeColumns {
                        bodyString  = bodyString + "</td>"
                        bodyString  = bodyString + "</tr>"
                    }
                }
                break
                
            default:
                if let lastKey = lastKey, let count = mediaListSort[lastKey]?.count, count == 1 {
                    if includeColumns {
                        bodyString  = bodyString + "<tr>"
                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">" // valign=\"baseline\"
                    }
                    
                    bodyString = bodyString + "<br/>"
                    
                    if includeColumns {
                        bodyString  = bodyString + "</td>"
                        bodyString  = bodyString + "</tr>"
                    }
                }
                
                var speakerCounts = [String:Int]()
                
                for mediaItem in mediaItems {
                    if let speaker = mediaItem.speaker {
                        if let count = speakerCounts[speaker] {
                            speakerCounts[speaker] = count + 1
                        } else {
                            speakerCounts[speaker] = 1
                        }
                    }
                }
                
                let speakerCount = speakerCounts.keys.count
                
                if includeColumns {
                    bodyString  = bodyString + "<tr>"
                    bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
                }
                
                if includeURLs, (keys.count > 1) {
                    let tag = key.replacingOccurrences(of: " ", with: "")
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + key + "</a>"
                } else {
                    bodyString = bodyString + key
                }

                if speakerCount == 1, let speaker = mediaItems[0].speaker, key != speaker {
                    bodyString = bodyString + " by " + speaker
                }
                
                if includeColumns {
                    bodyString  = bodyString + "</td>"
                    bodyString  = bodyString + "</tr>"
                } else {
                    bodyString = bodyString + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["date","title","scripture"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString + "<br/>"
                    }
                }

                if !includeColumns {
                    bodyString = bodyString + "<br/>"
                }
              
                break
            }
        }
        
        lastKey = key
    }
    
    if includeColumns {
        bodyString  = bodyString + "</table>"
    }
    
    bodyString = bodyString + "<br/>"
    
    if includeURLs, (keys.count > 1) {
        bodyString = bodyString + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
        
        for key in keys {
            bodyString = bodyString + "<a href=\"#\(key.replacingOccurrences(of: " ", with: ""))\">\(key)</a><br/>"
        }
    
        bodyString = bodyString + "</div>"
    }

    bodyString = bodyString + "</body></html>"
    
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

func networkUnavailable(_ viewController:UIViewController,_ message:String?)
{
    alert(viewController:viewController,title:Constants.Network_Error,message:message,completion:nil)
}

func alert(viewController:UIViewController,title:String?,message:String?,completion:(()->(Void))?)
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
    
    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

func alert(viewController:UIViewController,title:String?,message:String?,actions:[AlertAction]?)
{
    guard Thread.isMainThread else {
        print("Not Main Thread","functions:alert")
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
                alertAction.handler?()
            })
            alert.addAction(action)
        }
    } else {
        let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
    }
    
    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
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
        (action : UIAlertAction!) -> Void in
        searchAction?(alert)
    })
    alert.addAction(search)
    
    let clear = UIAlertAction(title: "Clear", style: UIAlertActionStyle.destructive, handler: {
        (action : UIAlertAction!) -> Void in
        alert.textFields?[0].text = ""
        searchAction?(alert)
    })
    alert.addAction(clear)
    
    let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
        (action : UIAlertAction!) -> Void in
    })
    alert.addAction(cancel)

    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

func firstSecondCancel(viewController:UIViewController,title:String?,message:String?,
                       firstTitle:String?,   firstAction:(()->(Void))?, firstStyle: UIAlertActionStyle,
                       secondTitle:String?,  secondAction:(()->(Void))?, secondStyle: UIAlertActionStyle,
                       cancelAction:(()->(Void))?)
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
    
    let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        cancelAction?()
    })
    alert.addAction(cancelAction)
    
    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

struct AlertAction {
    let title : String
    let style : UIAlertActionStyle
    let handler : (()->(Void))?
}

func alertActionsCancel(viewController:UIViewController,title:String?,message:String?,alertActions:[AlertAction]?,cancelAction:(()->(Void))?)
{
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    if let alertActions = alertActions {
        for alertAction in alertActions {
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                alertAction.handler?()
            })
            alert.addAction(action)
        }
    }
    
    let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        cancelAction?()
    })
    alert.addAction(cancelAction)
    
    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

func alertActionsOkay(viewController:UIViewController,title:String?,message:String?,alertActions:[AlertAction]?,okayAction:(()->(Void))?)
{
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    if let alertActions = alertActions {
        for alertAction in alertActions {
            let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                alertAction.handler?()
            })
            alert.addAction(action)
        }
    }
    
    let okayAlertAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
        okayAction?()
    })
    alert.addAction(okayAlertAction)
    
    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

