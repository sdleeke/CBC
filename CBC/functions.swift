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
import NaturalLanguage

func startAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    } catch let error {
        NSLog("failed to setCategory(AVAudioSessionCategoryPlayback): \(error.localizedDescription)")
    }
    
    UIApplication.shared.beginReceivingRemoteControlEvents()
}

func stopAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setActive(false)
    } catch let error {
        NSLog("failed to audioSession.setActive(false): \(error.localizedDescription)")
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

var documentsURL : URL?
{
    get {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}

var cachesURL : URL?
{
    get {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
}

func filesOfTypeInCache(_ fileType:String) -> [String]?
{
    guard let path = cachesURL?.path else {
        return nil
    }
    
    var files = [String]()
    
    do {
        let array = try FileManager.default.contentsOfDirectory(atPath: path)
        
        for string in array {
            if let range = string.range(of: fileType) {
                if fileType == String(string[range.lowerBound...]) {
                    files.append(string)
                }
            }
        }
    } catch let error {
        NSLog("failed to get files in caches directory: \(error.localizedDescription)")
    }
    
    return files.count > 0 ? files : nil
}

//func jsonToFileSystemDirectory(key:String)
//{
//    guard let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE) else {
//        return
//    }
//    
//    let fileManager = FileManager.default
//    
//    if let filename = Globals.shared.mediaCategory.filename, let jsonFileURL = filename.fileSystemURL {
//        // Check if file exist
//        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
//            do {
//                // Copy File From Bundle To Documents Directory
//                try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
//            } catch let error {
//                NSLog("failed to copy mediaItems.json: \(error.localizedDescription)")
//            }
//        } else {
//            // Which is newer, the bundle file or the file in the Documents folder?
//            do {
//                let jsonBundleAttributes = try fileManager.attributesOfItem(atPath: jsonBundlePath)
//                
//                let jsonDocumentsAttributes = try fileManager.attributesOfItem(atPath: jsonFileURL.path)
//                
//                if  let jsonBundleModDate = jsonBundleAttributes[FileAttributeKey.modificationDate] as? Date,
//                    let jsonDocumentsModDate = jsonDocumentsAttributes[FileAttributeKey.modificationDate] as? Date {
//                    if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
//                        //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
//                        print("JSON in Documents is newer than JSON in bundle")
//                    }
//                    
//                    if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
//                        print("JSON in Documents is the same date as JSON in bundle")
//                        if  let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as? Int,
//                            let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as? Int {
//                            if (jsonBundleFileSize != jsonDocumentsFileSize) {
//                                print("Same dates different file sizes")
//                                //We have a problem.
//                            } else {
//                                print("Same dates same file sizes")
//                                //Do nothing, they are the same.
//                            }
//                        }
//                    }
//                    
//                    if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
//                        print("JSON in bundle is newer than JSON in Documents")
//                        //copy the bundle into Documents directory
//                        do {
//                            // Copy File From Bundle To Documents Directory
//                            try fileManager.removeItem(atPath: jsonFileURL.path)
//                            try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
//                        } catch let error {
//                            NSLog("failed to copy mediaItems.json: \(error.localizedDescription)")
//                        }
//                    }
//                }
//            } catch let error {
//                NSLog("failed to get json file attributes: \(error.localizedDescription)")
//            }
//        }
//    }
//}

//func jsonFromURL(url:String) -> Any?
//{
//    guard Globals.shared.reachability.isReachable, let url = URL(string: url) else {
//        return nil
//    }
//
//    guard let data = url.data else {
//        return nil
//    }
//
//    print("able to read json from the URL.")
//
//    return data.json
////    do {
////        let json = try JSONSerialization.jsonObject(with: data, options: [])
////        return json
////    } catch let error {
////        NSLog("JSONSerialization error", error.localizedDescription)
////        return nil
////    }
//}

//func jsonFromFileSystem(filename:String?) -> Any?
//{
//    guard let filename = filename else {
//        return nil
//    }
//
//    guard let jsonFileSystemURL = filename.fileSystemURL else {
//        return nil
//    }
//
//    return jsonFileSystemURL.data?.json
//
////    do {
////        let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
////        print("able to read json from the URL.")
////
////        return data.json
//////        do {
//////            let json = try JSONSerialization.jsonObject(with: data, options: [])
//////            return json
//////        } catch let error {
//////            NSLog("JSONSerialization error", error.localizedDescription)
//////            return nil
//////        }
////    } catch let error {
////        print("Network unavailable: json could not be read from the file system.")
////        NSLog("Unable to read json from \(jsonFileSystemURL.absoluteString).", error.localizedDescription)
////        return nil
////    }
//}

//    if let json = filename?.fileSystemURL?.data?.json {
//        // waitUntilAllOperationsAreFinished causes deadlock in refresh
//        jsonQueue.addOperation {
//            urlString?.url?.data?.save(filename?.fileSystemURL)
//
////            print("able to read json from the URL.")
////
////            guard let jsonFileSystemURL = filename.fileSystemURL else {
////                NSLog("jsonFileSystemURL failure: \(filename)")
////                return
////            }
////
////            do {
////                try data.write(to: jsonFileSystemURL)
////                print("able to write json to the file system")
////            } catch let error {
////                print("unable to write json to the file system.")
////                NSLog("unable to write json to \(jsonFileSystemURL)", error.localizedDescription)
////            }
//        }
//
//        return json
//    } else {
//        guard let data = url.data else {
//            return nil
//        }
//
//        guard let json = data.json else {
//            return nil
//        }
//
//        // Don't save until we know we can get JSON.
//        data.save(to: filename.fileSystemURL)
//
//        return json
//
////        do {
////            let data = try Data(contentsOf: url)
////            print("able to read json from the URL.")
////
////            do {
////                let json = try JSONSerialization.jsonObject(with: data, options: [])
////
////                do {
////                    if let jsonFileSystemURL = cachesURL?.appendingPathComponent(filename) {
////                        try data.write(to: jsonFileSystemURL)
////                    }
////
////                    print("able to write json to the file system")
////                } catch let error {
////                    print("unable to write json to the file system.")
////
////                    NSLog(error.localizedDescription)
////                }
////
////                return json
////            } catch let error {
////                NSLog(error.localizedDescription)
////                return jsonFromFileSystem(filename: filename)
////            }
////        } catch let error {
////            NSLog(error.localizedDescription)
////            return jsonFromFileSystem(filename: filename)
////        }
//    }
//}

func stringWithoutPrefixes(_ fromString:String?) -> String?
{
    guard let fromString = fromString else {
        return nil
    }

    return fromString.withoutPrefixes
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

func stringMarkedBySearchAsAttributedString(attributedString:NSAttributedString!, string:String?, searchText:String?, wholeWordsOnly:Bool, test : (()->(Bool))?) -> NSAttributedString?
{
    guard var workingString = string, !workingString.isEmpty else {
        return nil
    }
    
    guard let searchText = searchText, !searchText.isEmpty else {
        return NSAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.normal)
    }
    
    guard wholeWordsOnly else {
        let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.normal)
        
        var startingRange = Range(uncheckedBounds: (lower: workingString.startIndex, upper: workingString.endIndex))
        
        while let range = attributedString.string.lowercased().range(of: searchText.lowercased(), options: [], range: startingRange, locale: nil) {
            if let test = test, test() {
                break
            }
            
            let nsRange = NSMakeRange(range.lowerBound.encodedOffset, searchText.count)
            
            attributedText.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.yellow, range: nsRange)
            startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: workingString.endIndex))
        }
        
        return attributedText
    }
    
    let newAttrString       = NSMutableAttributedString()
    var foundAttrString     = NSAttributedString()
    
    var stringBefore:String = Constants.EMPTY_STRING
    var stringAfter:String = Constants.EMPTY_STRING
    var foundString:String = Constants.EMPTY_STRING
    
    while (workingString.lowercased().range(of: searchText.lowercased()) != nil) {
        if let test = test, test() {
            break
        }
        
        if let range = workingString.lowercased().range(of: searchText.lowercased()) {
            stringBefore = String(workingString[..<range.lowerBound])
            stringAfter = String(workingString[range.upperBound...])
            
            var skip = false
            
            if wholeWordsOnly {
                if stringBefore == "" {
                    if  let characterBefore:Character = newAttrString.string.last,
                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                        if CharacterSet.letters.contains(unicodeScalar) { // }!CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        }
                        
                        if searchText.count == 1 {
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
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
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
                                skip = true
                            }
                        }
                    }
                }
                
                if let characterAfter:Character = stringAfter.first {
                    if let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) { // !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar)
                        skip = true
                    }
                    
                    if let unicodeScalar = UnicodeScalar(String(characterAfter)) {
                        if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(unicodeScalar) {
                            if stringAfter.endIndex > stringAfter.startIndex {
                                let nextChar = stringAfter[stringAfter.index(stringAfter.startIndex, offsetBy:1)]
                                
                                if let unicodeScalar = UnicodeScalar(String(nextChar)) {
                                    skip = CharacterSet.letters.contains(unicodeScalar)
                                }
                            }
                        }
                    }
                }
                
                if let characterBefore:Character = stringBefore.last {
                    if let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) { // !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar)
                        skip = true
                    }
                }
            }
            
            foundString = String(workingString[range.lowerBound...])
            if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
                foundString = String(foundString[..<newRange.upperBound])
            }
            
            if !skip {
                foundAttrString = NSAttributedString(string: foundString, attributes: Constants.Fonts.Attributes.highlighted)
            }
            
            newAttrString.append(NSMutableAttributedString(string: stringBefore, attributes: Constants.Fonts.Attributes.normal))
            
            newAttrString.append(foundAttrString)
            
            //                stringBefore = stringBefore + foundString
            
            workingString = stringAfter
        } else {
            break
        }
    }
    
    newAttrString.append(NSMutableAttributedString(string: stringAfter, attributes: Constants.Fonts.Attributes.normal))
    
    if newAttrString.string.isEmpty, let string = string {
        newAttrString.append(NSMutableAttributedString(string: string, attributes: Constants.Fonts.Attributes.normal))
    }
    
    return newAttrString
}

func markHTML(html:String?, searchText:String?, wholeWordsOnly:Bool, lemmas:Bool = false, index:Bool) -> (String?,Int)
{
    guard (stripHead(html) != nil) else {
        return (nil,0)
    }
    
    guard let searchText = searchText, !searchText.isEmpty else {
        return (html,0)
    }
    
    var searchTexts = Set<String>()
    
    if lemmas {
        if #available(iOS 12.0, *) {
            if let lemmas = html?.html2String?.nlLemmas {
                for lemma in lemmas {
                    if lemma.1.lowercased() == searchText.lowercased() {
                        searchTexts.insert(lemma.0.lowercased())
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            if let lemmas = html?.html2String?.nsLemmas {
                for lemma in lemmas {
                    if lemma.1.lowercased() == searchText.lowercased() {
                        searchTexts.insert(lemma.0.lowercased())
                    }
                }
            }
        }
    }
    
    var markCounter = 0
    
    func mark(_ input:String,searchText:String?) -> String
    {
        guard let searchText = searchText, !searchText.isEmpty else {
            return input
        }
        
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
                        if CharacterSet.letters.contains(unicodeScalar) {
                            skip = true
                        }
                        
                        if searchText.count == 1 {
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
                                skip = true
                            }
                        }
                    }
                } else {
                    if  let characterBefore:Character = stringBefore.last,
                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                        if CharacterSet.letters.contains(unicodeScalar) {
                            skip = true
                        }
                        
                        if searchText.count == 1 {
                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
                                skip = true
                            }
                        }
                    }
                }
                
                if let characterAfter:Character = stringAfter.first {
                    if  let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) {
                        skip = true
                    } else {

                    }
                    
                    if let unicodeScalar = UnicodeScalar(String(characterAfter)) {
                        if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(unicodeScalar) {
                            if stringAfter.endIndex > stringAfter.startIndex {
                                let nextChar = stringAfter[stringAfter.index(stringAfter.startIndex, offsetBy:1)]
                                
                                if let unicodeScalar = UnicodeScalar(String(nextChar)) {
                                    skip = CharacterSet.letters.contains(unicodeScalar)
                                }
                            }
                        }
                    }
                }
                
                if let characterBefore:Character = stringBefore.last {
                    if  let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) {
                        skip = true
                    }
                }
            }
            
            foundString = String(string[range.lowerBound...])
            if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
                foundString = String(foundString[..<newRange.upperBound])
            }
            
            if !skip {
                markCounter += 1
                foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
            }
            
            newString = newString + stringBefore + foundString
            
            stringBefore = stringBefore + foundString
            
            string = stringAfter
        }
        
        newString = newString + stringAfter
        
        return newString == Constants.EMPTY_STRING ? string : newString
    }
    
    searchTexts.insert(searchText.lowercased())
    
    var newString = Constants.EMPTY_STRING
    var string:String = html ?? Constants.EMPTY_STRING

    for searchText in Array(searchTexts).sorted() {
        // TERRIBLE way to detect HTML
        if string.range(of: "<") != nil {
            while let searchRange = string.range(of: "<") {
                let searchString = String(string[..<searchRange.lowerBound])
                //            print(searchString)
                
                // mark search string
                newString = newString + mark(searchString.replacingOccurrences(of: "&nbsp;", with: " "), searchText: searchText)
                
                let remainder = String(string[searchRange.lowerBound...])
                
                if let htmlRange = remainder.range(of: ">") {
                    let html = String(remainder[..<htmlRange.upperBound])
                    //                print(html)
                    
                    newString = newString + html
                    
                    string = String(remainder[htmlRange.upperBound...])
                }
            }
        } else {
            // mark search string
            newString = mark(string.replacingOccurrences(of: "&nbsp;", with: " "),searchText:searchText)
        }
        
        string = newString
        newString = Constants.EMPTY_STRING
    }

    var indexString:String!
    
    if markCounter > 0 {
        indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)" // <br/>
    } else {
        indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.<br/>" // <br/> needed since markCounter == 0 so the below div isn't added.
    }
    
    // If we want an index of links to the occurrences of the searchText.
    if index {
        if markCounter > 0 {
            indexString = indexString + "<div>Locations: "
            
            for counter in 1...markCounter {
                if counter > 1 {
                    indexString = indexString + ", "
                }
                indexString = indexString + "<a href=\"#\(counter)\">\(counter)</a>"
            }
            
            indexString = indexString + "<br/></div>" // <br/>
        }
    }
    
    var htmlString = "<!DOCTYPE html><html><body>"
    
    if index {
        htmlString = htmlString + indexString
    }
    
    htmlString = htmlString + string + "</body></html>"
    
    return (insertHead(htmlString,fontSize: Constants.FONT_SIZE),markCounter)
}

func markBodyHTML(bodyHTML:String?, headerHTML:String?, searchText:String?, wholeWordsOnly:Bool, lemmas:Bool = false, index:Bool) -> (String?,Int)
{
    if let headerHTML = headerHTML {
        let markedHTML = markHTML(html: bodyHTML, searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
            
        return (markedHTML.0?.replacingOccurrences(of: "<body>", with: "<body>"+headerHTML+"<br/>"),markedHTML.1)
    } else {
        return markHTML(html: bodyHTML, searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
    }
    
////    guard let headerHTML = headerHTML else {
////        return nil
////    }
//
//    guard (stripHead(bodyHTML) != nil) else {
//        return nil
//    }
//
//    guard let searchText = searchText, !searchText.isEmpty else {
//        return bodyHTML
//    }
//
//    var searchTexts = Set<String>()
//
//    if lemmas {
//        if #available(iOS 12.0, *) {
//            if let lemmas = bodyHTML.html2String?.nlLemmas {
//                for lemma in lemmas {
//                    if lemma.1.lowercased() == searchText.lowercased() {
//                        searchTexts.insert(lemma.0.lowercased())
//                    }
//                }
//            }
//        } else {
//            // Fallback on earlier versions
//            if let lemmas = bodyHTML.html2String?.nsLemmas {
//                for lemma in lemmas {
//                    if lemma.1.lowercased() == searchText.lowercased() {
//                        searchTexts.insert(lemma.0.lowercased())
//                    }
//                }
//            }
//        }
//    }
//
//    var markCounter = 0
//
//    func mark(_ input:String,searchText:String?) -> String
//    {
//        guard let searchText = searchText, !searchText.isEmpty else {
//            return input
//        }
//
//        var string = input
//
//        var stringBefore:String = Constants.EMPTY_STRING
//        var stringAfter:String = Constants.EMPTY_STRING
//        var newString:String = Constants.EMPTY_STRING
//        var foundString:String = Constants.EMPTY_STRING
//
//        while (string.lowercased().range(of: searchText.lowercased()) != nil) {
//            guard let range = string.lowercased().range(of: searchText.lowercased()) else {
//                break
//            }
//
//            stringBefore = String(string[..<range.lowerBound])
//            stringAfter = String(string[range.upperBound...])
//
//            var skip = false
//
//            if wholeWordsOnly {
//                if stringBefore == "" {
//                    if  let characterBefore:Character = newString.last,
//                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
//                        if CharacterSet.letters.contains(unicodeScalar) {
//                            skip = true
//                        }
//
//                        if searchText.count == 1 {
//                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
//                                skip = true
//                            }
//                        }
//                    }
//                } else {
//                    if  let characterBefore:Character = stringBefore.last,
//                        let unicodeScalar = UnicodeScalar(String(characterBefore)) {
//                        if CharacterSet.letters.contains(unicodeScalar) {
//                            skip = true
//                        }
//
//                        if searchText.count == 1 {
//                            if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
//                                skip = true
//                            }
//                        }
//                    }
//                }
//
//                if  let characterAfter:Character = stringAfter.first,
//                    let unicodeScalar = UnicodeScalar(String(characterAfter)) {
//                    if CharacterSet.letters.contains(unicodeScalar) {
//                        skip = true
//                    } else {
//
//                    }
//
//                    if let unicodeScalar = UnicodeScalar(String(characterAfter)) {
//                        if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(unicodeScalar) {
//                            if stringAfter.endIndex > stringAfter.startIndex {
//                                let nextChar = stringAfter[stringAfter.index(stringAfter.startIndex, offsetBy:1)]
//
//                                if let unicodeScalar = UnicodeScalar(String(nextChar)) {
//                                    skip = CharacterSet.letters.contains(unicodeScalar)
//                                }
//                            }
//                        }
//                    }
//                }
//                if let characterBefore:Character = stringBefore.last {
//                    if let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) {
//                        //                            !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
//                        skip = true
//                    }
//                }
//            }
//
//            foundString = String(string[range.lowerBound...])
//            if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
//                foundString = String(foundString[..<newRange.upperBound])
//            } else {
//
//            }
//
//            if !skip {
//                markCounter += 1
//                foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
//            }
//
//            newString = newString + stringBefore + foundString
//
//            stringBefore = stringBefore + foundString
//
//            string = stringAfter
//        }
//
//        newString = newString + stringAfter
//
//        return newString == Constants.EMPTY_STRING ? string : newString
//    }
//
//    searchTexts.insert(searchText.lowercased())
//
//    var newString = Constants.EMPTY_STRING
//    var string = bodyHTML
//
//    for searchText in Array(searchTexts).sorted() {
//        if string.html2String != string {
//            // This assumes the bodyHTML is, in fact, HTML, i.e. with tags.
//            // THIS IS A LOUSY WAY TO FIND TAGS.
//            while let searchRange = string.range(of: "<") {
//                let searchString = String(string[..<searchRange.lowerBound])
//                //            print(searchString)
//
//                // mark search string
//                newString = newString + mark(searchString.replacingOccurrences(of: "&nbsp;", with: " "),searchText:searchText)
//
//                let remainder = String(string[searchRange.lowerBound...])
//
//                if let htmlRange = remainder.range(of: ">") {
//                    let html = String(remainder[..<htmlRange.upperBound])
//                    //                print(html)
//
//                    newString = newString + html
//
//                    string = String(remainder[htmlRange.upperBound...])
//                }
//            }
//        } else {
//            // mark search string
//            newString = mark(string.replacingOccurrences(of: "&nbsp;", with: " "),searchText:searchText)
//        }
//
//        string = newString
//        newString = Constants.EMPTY_STRING
//    }
//
//    var indexString:String!
//
//    if markCounter > 0 {
//        indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)<br/>"
//    } else {
//        indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.<br/>"
//    }
//
//    // If we want an index of links to the occurrences of the searchText.
//    if index {
//        if markCounter > 0 {
//            indexString = indexString + "<div>Locations: "
//
//            for counter in 1...markCounter {
//                if counter > 1 {
//                    indexString = indexString + ", "
//                }
//                indexString = indexString + "<a href=\"#\(counter)\">\(counter)</a>"
//            }
//
//            indexString = indexString + "<br/><br/></div>"
//        }
//    }
//
//    var htmlString = "<!DOCTYPE html><html><body>"
//
//    if index {
//        htmlString = htmlString + indexString
//    }
//
//    if let headerHTML = headerHTML {
//        htmlString = htmlString + headerHTML + string + "</body></html>"
//    } else {
//        htmlString = htmlString + string + "</body></html>"
//    }
//
//    return insertHead(htmlString,fontSize: Constants.FONT_SIZE) // insertHead(newString,fontSize: Constants.FONT_SIZE)
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
            if endVerse >= startVerse {
                for verse in startVerse...endVerse {
                    verses.append(verse)
                }
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

func debug(_ any:Any...)
{
//    print(any)
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
        
        if endVerse >= startVerse {
            for verse in startVerse...endVerse {
                if chaptersAndVerses[chapter] == nil {
                    chaptersAndVerses[chapter] = [verse]
                } else {
                    chaptersAndVerses[chapter]?.append(verse)
                }
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
            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
                debug(index,Constants.OLD_TESTAMENT_VERSES.count,Constants.OLD_TESTAMENT_VERSES[index].count)
            }
            break
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
                debug(index,Constants.NEW_TESTAMENT_VERSES.count,Constants.NEW_TESTAMENT_VERSES[index].count)
            }
            break
        default:
            break
        }
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
    
//    guard (reference?.range(of: "&") == nil) else {
//        return nil
//    }
    
    var chaptersAndVerses = [Int:[Int]]()
    
    var tokens = [String]()
    
    var currentChapter = 0
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0
    
    let string = reference?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if (string == nil) || (string == Constants.EMPTY_STRING) {
        // Now we have a book w/ no chapter or verse references
        // FILL in all chapters and all verses and return
        return chaptersAndVersesForBook(book)
    }
    
    var token = Constants.EMPTY_STRING
    
    if let chars = string {
        for char in chars {
            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: "&:,-").contains(unicodeScalar) {
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
                    
                case "&":
                    if !startVerses {
                        if let first = tokens.first, let number = Int(first) {
                            tokens.remove(at: 0)                            
                            currentChapter = number
                            chaptersAndVerses[currentChapter] = versesForBookChapter(book,currentChapter)
                        }
                    }
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
                                                        if endVerse >= startVerse {
                                                            for verse in startVerse...endVerse {
                                                                chaptersAndVerses[chapter]?.append(verse)
                                                            }
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
                                            if endVerse >= startVerse {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[currentChapter]?.append(verse)
                                                }
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
                                if endVerse >= startVerse {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[startChapter]?.append(verse)
                                    }
                                }
                            }
                            
                            debug("Done w/ startChapter")
                            
                            startVerse = 0
                            
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
                                            if endVerse >= startVerse {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[chapter]?.append(verse)
                                                }
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
                                        if endVerse >= startVerse {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[endChapter]?.append(verse)
                                            }
                                        }
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
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
                                if endVerse >= startVerse {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[startChapter]?.append(verse)
                                    }
                                }
                            }
                            
                            debug("Done w/ startChapter")
                            
                            startVerse = 0
                            
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
                                            if endVerse >= startVerse {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[chapter]?.append(verse)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            debug("Done w/ chapters between startChapter and endChapter")
                            
                            debug("Now add the verses from the endChapter")
                            
                            if endChapter > startChapter {
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
                                        if endVerse >= startVerse {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[endChapter]?.append(verse)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            debug("Done w/ verses")
                            
                            startVerse = 0
                            
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
                                    if endVerse >= startVerse {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[currentChapter]?.append(verse)
                                        }
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
                                
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
                                                if endVerse >= startVerse {
                                                    for verse in startVerse...endVerse {
                                                        chaptersAndVerses[chapter]?.append(verse)
                                                    }
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
                                        if endVerse >= startVerse {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[currentChapter]?.append(verse)
                                            }
                                        }
                                    }
                                    
                                    debug("Done w/ verses")
                                    
                                    startVerse = 0
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
                                    if endVerse >= startVerse {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[currentChapter]?.append(verse)
                                        }
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
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
        
        debug(book,reference)
        
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
                if endVerse >= startVerse {
                    for verse in startVerse...endVerse {
                        chaptersAndVerses[currentChapter]?.append(verse)
                    }
                }
            } else {
                chaptersAndVerses[currentChapter] = [startVerse]
            }
            startVerse = 0
            endVerse = 0
        }
    } else {
        return chaptersAndVersesForBook(book)
    }

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
    
    let colon = string.range(of: ":")
    let hyphen = string.range(of: "-")
    let comma = string.range(of: ",")
    
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
    
    return chapters.count > 0 ? chapters : nil
}

func booksFromScriptureReference(_ scriptureReference:String?) -> [String]?
{
    guard let scriptureReference = scriptureReference else {
        return nil
    }
    
    guard scriptureReference.lowercased() != Constants.Strings.Selected_Scriptures.lowercased() else {
        return nil
    }
    
    var books = [String]()
    
    var string = scriptureReference.lowercased()
//        print(string)
    
    var otBooks = [String]()
    
    for book in Constants.OLD_TESTAMENT_BOOKS {
        repeat {
            if let range = string.range(of: book.lowercased()) {
                otBooks.append(book)
                
                let before = String(string[..<range.lowerBound])
                let after = String(string[range.upperBound...])
                
                string = before + Constants.SINGLE_SPACE + after
            }
        } while string.range(of: book.lowercased()) != nil
    }
    
    for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
        repeat {
            if let range = string.range(of: book.lowercased()) {
                books.append(book)
                
                let before = String(string[..<range.lowerBound])
                let after = String(string[range.upperBound...])
                
                string = before + Constants.SINGLE_SPACE + after
            }
        } while string.range(of: book.lowercased()) != nil
    }
    
    let ntBooks = books.reversed()

    books = otBooks
    books.append(contentsOf: ntBooks)
    
    if books.count == 0 {
        for book in Constants.OLD_TESTAMENT_BOOKS {
            repeat {
                if let range = string.range(book) {
                    otBooks.append(book)
                    
                    let before = String(string[..<range.lowerBound])
                    let after = String(string[range.upperBound...])
                    
                    string = before + Constants.SINGLE_SPACE + after
                }
            } while string.range(of: book.lowercased()) != nil

//            var bk = book
//
//            repeat {
//                if let range = string.range(of: bk.lowercased()) {
//                    otBooks.append(book)
//
//                    let before = String(string[..<range.lowerBound])
//                    let after = String(string[range.upperBound...])
//
//                    string = before + Constants.SINGLE_SPACE + after
//                    break
//                } else {
//                    bk.removeLast()
//                    if bk.last == " " {
//                        break
//                    }
//                }
//            } while bk.count > 2
        }
        
        for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
            repeat {
                if let range = string.range(book) {
                    books.append(book)

                    let before = String(string[..<range.lowerBound])
                    let after = String(string[range.upperBound...])
                    
                    string = before + Constants.SINGLE_SPACE + after
                }
            } while string.range(of: book.lowercased()) != nil

//            var bk = book
//            
//            repeat {
//                if let range = string.range(of: bk.lowercased()) {
//                    books.append(book)
//                    
//                    let before = String(string[..<range.lowerBound])
//                    let after = String(string[range.upperBound...])
//                    
//                    string = before + Constants.SINGLE_SPACE + after
//                    break
//                } else {
//                    bk.removeLast()
//                    if bk.last == " " {
//                        break
//                    }
//                }
//            } while bk.count > 2
        }
        
        let ntBooks = books.reversed()
        
        books = otBooks
        books.append(contentsOf: ntBooks)
    }
    
    string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    // Only works for "<book> - <book>"
    
    if (string == "-") {
        if books.count == 2 {
            let book1 = scriptureReference.range(of: books[0])
            let book2 = scriptureReference.range(of: books[1])
            let hyphen = scriptureReference.range(of: "-")

            if ((book1?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book2?.lowerBound)) ||
                ((book2?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book1?.lowerBound)) {
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
    
    return books.count > 0 ? books.sorted() { scriptureReference.range(of: $0)?.lowerBound < scriptureReference.range(of: $1)?.lowerBound } : nil
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
                return first.withoutPrefixes < second.withoutPrefixes
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
                return first.withoutPrefixes < second.withoutPrefixes
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
                return first.withoutPrefixes < second.withoutPrefixes
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
    
    var token = Constants.EMPTY_STRING

    func processToken()
    {
        let excludedWords = [String]() //["and", "are", "can", "for", "the"]
        
        for word in excludedWords {
            if token.lowercased() == word.lowercased() {
                token = Constants.EMPTY_STRING
                break
            }
        }
        
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
        var skip = false
        
        let char = str[index]
        
        if let charUnicodeScalar = UnicodeScalar(String(char)) {
            if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(charUnicodeScalar) {
                if str.endIndex > str.index(index, offsetBy:1) {
                    let nextChar = str[str.index(index, offsetBy:1)]
                    
                    if let unicodeScalar = UnicodeScalar(String(nextChar)) {
                        skip = CharacterSet.letters.contains(unicodeScalar)
                    }
                }
            }
        }

        if let unicodeScalar = UnicodeScalar(String(char)) {
            if !CharacterSet.letters.contains(unicodeScalar), !skip {
                processToken()
            } else {
                token.append(char)
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

func nsLemmasInString(string:String?) -> [(String,String,NSRange)]?
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
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lemma.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nsNameTypesInString(string:String?) -> [(String,String,NSRange)]?
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
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameType.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nsLexicalTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length)
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lexicalClass.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nsTokenTypesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length)
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

func nsNameTypesAndLexicalClassesInString(string:String?) -> [(String,String,NSRange)]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [(String,String,NSRange)]()
    
    let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
    let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    
    let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
    tagger.string = string
    
    let range = NSRange(location: 0, length: (string as NSString).length)
    
    var ranges : NSArray?
    
    let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameTypeOrLexicalClass.rawValue, options: options, tokenRanges: &ranges)
    
    var index = 0
    for tag in tags {
        if let range = ranges?[index] as? NSRange {
            let token = (string as NSString).substring(with: range)
            tokens.append((token,tag,range))
        }
        index += 1
    }
    
    return tokens.count > 0 ? tokens : nil
}

@available(iOS 12.0, *)
func nlLemmasInString(string:String?) -> [(String,String,Range<String.Index>)]?
{
    guard let string = string else {
        return nil
    }
    
    let tagger = NLTagger(tagSchemes: [.lemma])
    
    tagger.string = string
    
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
    
    var tokens = [(String,String,Range<String.Index>)]()
    
    tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .lemma, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
        let token = String(string[range])
        if let tag = tag?.rawValue {
            tokens.append((token,tag,range))
        }
        return true
    }
    
    return tokens.count > 0 ? tokens : nil
}

@available(iOS 12.0, *)
func nlTokenTypesInString(string:String?) -> [(String,String,Range<String.Index>)]?
{
    guard let string = string else {
        return nil
    }
    
    let tagger = NLTagger(tagSchemes: [.tokenType])
    
    tagger.string = string
    
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
    
    var tokens = [(String,String,Range<String.Index>)]()
    
    tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .tokenType, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
        let token = String(string[range])
        if let tag = tag?.rawValue {
            tokens.append((token,tag,range))
        }
        return true
    }
    
    return tokens.count > 0 ? tokens : nil
}

@available(iOS 12.0, *)
func nlNameTypesAndLexicalClassesInString(string:String?) -> [(String,String,Range<String.Index>)]?
{
    guard let string = string else {
        return nil
    }
    
    let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
    
    tagger.string = string
    
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
    
    var tokens = [(String,String,Range<String.Index>)]()
    
    tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
        let token = String(string[range])
        if let tag = tag?.rawValue {
            tokens.append((token,tag,range))
        }
        return true
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
    
    var token = Constants.EMPTY_STRING
    
    func processToken()
    {
        token = token.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let excludedWords = [String]() // ["and", "are", "can", "for", "the"]
        
        for word in excludedWords {
            if token.lowercased() == word.lowercased() {
                token = Constants.EMPTY_STRING
                break
            }
        }
        
        if token != token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars)) {
            token = token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars))
        }
        
        if token != Constants.EMPTY_STRING {
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
        
        var skip = false
        
        let char = str[index]
        
        if let charUnicodeScalar = UnicodeScalar(String(char)) {
            if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(charUnicodeScalar) {
                if str.endIndex > str.index(index, offsetBy:1) {
                    let nextChar = str[str.index(index, offsetBy:1)]
                    
                    if let unicodeScalar = UnicodeScalar(String(nextChar)) {
                        skip = CharacterSet.letters.contains(unicodeScalar)
                    }
                }
            }
        }

        if let unicodeScalar = UnicodeScalar(String(char)) {
            if !CharacterSet.letters.contains(unicodeScalar), !skip {
                processToken()
            } else {
                token.append(char)
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
        return $0.dateService < $1.dateService
    }
}

func sortMediaItemsReverseChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        return $0.dateService > $1.dateService
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
            
            if let title = mediaItem.title, let notesURLString = mediaItem.notesURLString, let notesURL = mediaItem.notesURL {
                if ((try? Data(contentsOf: notesURL)) == nil) {
                    print("Transcript DOES NOT exist for: \(title) PDF: \(notesURLString)")
                } else {
                    
                }
            }
            
            if let title = mediaItem.title, let slidesURLString = mediaItem.slidesURLString, let slidesURL = mediaItem.slidesURL {
                if ((try? Data(contentsOf: slidesURL)) == nil) {
                    print("Slides DO NOT exist for: \(title) PDF: \(slidesURLString)")
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
}

func tagsArrayToTagsString(_ tagsArray:[String]?) -> String?
{
    guard let tagsArray = tagsArray else {
        return nil
    }

    return tagsArray.count > 0 ? tagsArray.joined(separator: Constants.TAGS_SEPARATOR) : nil
}

func tagsArrayFromTagsString(_ tagsString:String?) -> [String]?
{
    guard let tagsString = tagsString else {
        return nil
    }
    
    let array = tagsString.components(separatedBy: Constants.TAGS_SEPARATOR) 

    return array.count > 0 ? array : nil
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

//func tagsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//
//    var tagsSet = Set<String>()
//    
//    for mediaItem in mediaItems {
//        if let tags = mediaItem.tagsSet {
//            tagsSet.formUnion(tags)
//        }
//    }
//    
//    var tagsArray = Array(tagsSet).sorted(by: { $0.withoutPrefixes < $1.withoutPrefixes })
//    
//    tagsArray.append(Constants.Strings.All)
//    
//    return tagsArray.count > 0 ? tagsArray : nil
//}

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

func process(viewController:UIViewController?,disableEnable:Bool = true,hideSubviews:Bool = false,work:(()->(Any?))?,completion:((Any?)->())?)
{
    guard let viewController = viewController else {
        return
    }
    
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
        
        // Should be an OperationQueue and work should be a CancellableOperation
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

func mailText(viewController:UIViewController?,to: [String]?,subject: String?, body:String)
{
    guard let viewController = viewController else {
        return
    }
    
    guard MFMailComposeViewController.canSendMail() else {
        showSendMailErrorAlert(viewController: viewController)
        return
    }

    let mailComposeViewController = MFMailComposeViewController()
    
    // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
    
    mailComposeViewController.setToRecipients(to)
    
    if let subject = subject {
        mailComposeViewController.setSubject(subject)
    }
    
    mailComposeViewController.setMessageBody(body, isHTML: false)
    
    Thread.onMainThread {
        viewController.present(mailComposeViewController, animated: true, completion: nil)
    }
}

func mailHTML(viewController:UIViewController?,to: [String]?,subject: String?, htmlString:String)
{
    guard let viewController = viewController else {
        return
    }
    
    guard MFMailComposeViewController.canSendMail() else {
        showSendMailErrorAlert(viewController: viewController)
        return
    }
    
    let mailComposeViewController = MFMailComposeViewController()
    
    // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    mailComposeViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
    
    mailComposeViewController.setToRecipients(to)
    
    if let subject = subject {
        mailComposeViewController.setSubject(subject)
    }
    
    mailComposeViewController.setMessageBody(htmlString, isHTML: true)
    
    Thread.onMainThread {
        viewController.present(mailComposeViewController, animated: true, completion: nil)
    }
}

func printTextJob(viewController:UIViewController,data:Data?,string:String?,orientation:UIPrintInfoOrientation)
{
    guard UIPrintInteractionController.isPrintingAvailable, !((string != nil) && (data != nil)), (string != nil) || (data != nil) else {
        return
    }
    
    let pi = UIPrintInfo.printInfo()
    pi.outputType = UIPrintInfoOutputType.general
    pi.jobName = Constants.Strings.Print;
    pi.duplex = UIPrintInfoDuplex.longEdge
    
    let pic = UIPrintInteractionController.shared
    pic.printInfo = pi
    pic.showsPaperSelectionForLoadedPapers = true
    
    if let string = string {
        let formatter = UISimpleTextPrintFormatter(text: string)
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

func printText(viewController:UIViewController,string:String?)
{
    guard UIPrintInteractionController.isPrintingAvailable && (string != nil) else {
        return
    }
    
    pageOrientation(viewController: viewController,
                    portrait: ({
                        printTextJob(viewController: viewController,data:nil,string:string,orientation:.portrait)
                    }),
                    landscape: ({
                        printTextJob(viewController: viewController,data:nil,string:string,orientation:.landscape)
                    }),
                    cancel: ({
                    })
    )
}

func printHTMLJob(viewController:UIViewController,data:Data?,html:String?,orientation:UIPrintInfoOrientation)
{
    guard UIPrintInteractionController.isPrintingAvailable, !((html != nil) && (data != nil)), (html != nil) || (data != nil) else {
        return
    }
    
    let pi = UIPrintInfo.printInfo()
    pi.outputType = UIPrintInfoOutputType.general
    pi.jobName = Constants.Strings.Print;
    pi.duplex = UIPrintInfoDuplex.longEdge
    pi.orientation = orientation

    let pic = UIPrintInteractionController.shared
    pic.printInfo = pi
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
                        printHTMLJob(viewController: viewController,data:nil,html:htmlString,orientation:.portrait)
                    }),
                    landscape: ({
                        printHTMLJob(viewController: viewController,data:nil,html:htmlString,orientation:.landscape)
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
        printHTMLJob(viewController: viewController, data: data as? Data, html: nil, orientation: .portrait)
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
        printHTMLJob(viewController:viewController,data:nil,html:(data as? String),orientation:.portrait)
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
            printHTMLJob(viewController:viewController,data:nil,html:(data as? String),orientation:orientation)
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

//func hmsToSeconds(string:String?) -> Double?
//{
//    guard var str = string?.replacingOccurrences(of: ",", with: ".") else {
//        return nil
//    }
//    
//    var numbers = [Double]()
//    
//    repeat {
//        if let index = str.range(of: ":") {
//            let numberString = String(str[..<index.lowerBound])
//            
//            if let number = Double(numberString) {
//                numbers.append(number)
//            }
//
//            str = String(str[index.upperBound...])
//        }
//    } while str.range(of: ":") != nil
//
//    if !str.isEmpty {
//        if let number = Double(str) {
//            numbers.append(number)
//        }
//    }
//
//    var seconds = 0.0
//    var counter = 0.0
//    
//    for number in numbers.reversed() {
//        seconds = seconds + (counter != 0 ? number * pow(60.0,counter) : number)
//        counter += 1
//    }
//    
//    return seconds
//}
//
//func secondsToHMS(seconds:String?) -> String?
//{
//    guard let seconds = seconds else {
//        return nil
//    }
//    
//    guard let timeNow = Double(seconds) else {
//        return nil
//    }
//    
//    let hours = max(Int(timeNow / (60*60)),0)
//    let mins = max(Int((timeNow - (Double(hours) * 60*60)) / 60),0)
//    let sec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
//    let fraction = timeNow - Double(Int(timeNow))
//    
//    var hms:String
//    
//    if (hours > 0) {
//        hms = "\(String(format: "%02d",hours)):"
//    } else {
//        hms = "00:" //Constants.EMPTY_STRING
//    }
//    
//    // \(String(format: "%.3f",fraction)
//    // .trimmingCharacters(in: CharacterSet(charactersIn: "0."))
//    
//    hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
//    
//    return hms
//}

func preferredModalPresentationStyle(viewController:UIViewController) -> UIModalPresentationStyle
{
    let vClass = viewController.traitCollection.verticalSizeClass
    
    if vClass == .compact {
        return .overFullScreen
    }

    let hClass = viewController.traitCollection.horizontalSizeClass
    
    if (hClass == .compact) {
        return .overCurrentContext
    }
    
    return .formSheet
}

func popoverHTML(_ viewController:UIViewController, title:String?, mediaItem:MediaItem? = nil, bodyHTML:String? = nil, headerHTML:String? = nil, barButtonItem:UIBarButtonItem? = nil, sourceView:UIView? = nil, sourceRectView:UIView? = nil, htmlString:String? = nil, search:Bool)
{
    guard Thread.isMainThread else {
        alert(viewController:viewController,title: "Not Main Thread", message: "functions:popoverHTML", completion: nil)
        return
    }
    
    guard let storyboard = viewController.storyboard else {
        return
    }

    if let navigationController = storyboard.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
        let popover = navigationController.viewControllers[0] as? WebViewController {
        navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
        
        if navigationController.modalPresentationStyle == .popover {
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
            
            if sourceView != nil {
                navigationController.popoverPresentationController?.sourceView = sourceView
                
                if let frame = sourceRectView?.frame {
                    navigationController.popoverPresentationController?.sourceRect = frame
                }
            }
            
            if barButtonItem != nil {
                navigationController.popoverPresentationController?.barButtonItem = barButtonItem
            }
        }
        
        if title != nil {
            popover.navigationItem.title = title
        }
        
        popover.html.fontSize = 12
        
        if let bodyHTML = bodyHTML, let headerHTML = headerHTML {
            let htmlString = "<!DOCTYPE html><html><body>" + headerHTML + bodyHTML + "</body></html>"
            popover.html.original = insertHead(stripHead(htmlString),fontSize: popover.html.fontSize)
        }
        
        if htmlString != nil {
            popover.html.string = insertHead(stripHead(htmlString),fontSize: popover.html.fontSize)
        } else

        if let bodyHTML = bodyHTML, let headerHTML = headerHTML {
            let htmlString = "<!DOCTYPE html><html><body>" + headerHTML + bodyHTML + "</body></html>"
            popover.html.string = insertHead(stripHead(htmlString),fontSize: popover.html.fontSize)
        }
        
        popover.search = search
        
        popover.mediaItem = mediaItem
        
        popover.bodyHTML = bodyHTML
        popover.headerHTML = headerHTML

        popover.content = .html
        
        popover.navigationController?.isNavigationBarHidden = false
        
        Thread.onMainThread {
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }
}

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
            }
        }
    }
    
    while bodyString.range(of: "<br ") != nil {
        if let startRange = bodyString.range(of: "<br ") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                
                bodyString = to + String(bodyString[(to + from).endIndex...])
            }
        }
    }
    
    while bodyString.range(of: "<span ") != nil {
        if let startRange = bodyString.range(of: "<span ") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                bodyString = to + String(bodyString[(to + from).endIndex...])
            }
        }
    }

    while bodyString.range(of: "<font") != nil {
        if let startRange = bodyString.range(of: "<font") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
                bodyString = to + String(bodyString[(to + from).endIndex...])
            }
        }
    }

    while bodyString.range(of: "<sup>") != nil {
        if let startRange = bodyString.range(of: "<sup>") {
            if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</sup>") {
                let to = String(bodyString[..<startRange.lowerBound])
                let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])

                bodyString = to + String(bodyString[(to + from).endIndex...])
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
    
    return insertHead(bodyString,fontSize: Constants.FONT_SIZE)
}

func setupMediaItemsHTMLGlobal(includeURLs:Bool,includeColumns:Bool) -> String?
{
    guard (Globals.shared.media.active?.mediaList?.list != nil) else {
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
    
    if Globals.shared.media.active?.mediaList?.list?.count > 1 {
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
                
                let tag = key.asTag

                if includeColumns {
                    if includeURLs {
                        bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>"
                    } else {
                        bodyString = bodyString + "<tr><td colspan=\"7\"><br/></td></tr>"
                    }
                } else {
                    if includeURLs {
                        bodyString = bodyString + "<br/>"
                    } else {
                        bodyString = bodyString + "<br/>"
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString + "<tr>"
                    bodyString = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                }
                
                if includeURLs, (keys.count > 1) {
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + "</a>" //  + " (\(mediaItems.count))"
                } else {
                    bodyString = bodyString + name + " (\(mediaItems.count))"
                }
                
                if speakerCount == 1 {
                    if var speaker = mediaItems[0].speaker, name != speaker {
                        if let speakerTitle = mediaItems[0].speakerTitle {
                            speaker += ", \(speakerTitle)"
                        }
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
                            return String(string.withoutPrefixes[..<a.endIndex]).uppercased()
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
                        if let count = stringIndex[title]?.count { // Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count
                            bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a> (\(count))<br/>"
                        } else {
                            bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                        }
                        
                        if let keys = stringIndex[title] {
                            for key in keys {
                                if let title = Globals.shared.media.active?.groupNames?[grouping]?[key] {
                                    let tag = key.asTag
                                    bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a><br/>" // (\(count))
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
                        let tag = key.asTag
                        bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                    }
                }
                break
            }
            
            bodyString = bodyString + "</div>"
        }
    }
    
    bodyString = bodyString + "</body></html>"
    
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
        if let multiPartName = mediaItem.multiPartName?.withoutPrefixes {
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
        bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"

//        bodyString = bodyString + " from <a target=\"_blank\" href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
    } else {
        bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
    }
    
//    if let category = Globals.shared.mediaCategory.selected {
//        bodyString = bodyString + "Category: \(category)<br/><br/>"
//    }
//
//    if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
//        bodyString = bodyString + "Collection: \(tag)<br/><br/>"
//    }
//
//    if Globals.shared.search.valid, let searchText = Globals.shared.search.text {
//        bodyString = bodyString + "Search: \(searchText)<br/><br/>"
//    }
    
    let keys = Array(mediaListSort.keys).sorted() {
        $0.withoutPrefixes < $1.withoutPrefixes
    }
    
    if includeURLs, (keys.count > 1) {
        bodyString = bodyString + "<a href=\"#index\">Index</a><br/><br/>"
    }
    
//    var lastKey:String?
    
    if includeColumns {
        bodyString  = bodyString + "<table>"
    }
    
    for key in keys {
        if let mediaItems = mediaListSort[key]?.sorted(by: { (first, second) -> Bool in
            return first.date < second.date
        }) {
            if includeColumns {
                bodyString  = bodyString + "<tr>"
                bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
            }
            
            bodyString = bodyString + "<br/>"
            
            if includeColumns {
                bodyString  = bodyString + "</td>"
                bodyString  = bodyString + "</tr>"
            }
            
            switch mediaItems.count {
            case 1:
                if let mediaItem = mediaItems.first {
                    if let string = mediaItem.bodyHTML(order: ["date","title","scripture","speaker"], token: nil, includeURLs:includeURLs, includeColumns:includeColumns) {
                        let tag = key.asTag
                        if includeURLs, keys.count > 1 {
                            bodyString  = bodyString + "<tr>"
                            bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                            bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
                            bodyString  = bodyString + "</td>"
                            bodyString  = bodyString + "</tr>"
                        }
                        bodyString = bodyString + string
                    }
                }
                break
                
            default:
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
                    bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                }
                
                if includeURLs, keys.count > 1 {
                    let tag = key.asTag
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
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
              
//                if let lastKey = lastKey, let count = mediaListSort[lastKey]?.count, count == 1 {
//                    if includeColumns {
//                        bodyString  = bodyString + "<tr>"
//                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                    }
//
//                    bodyString = bodyString + "<br/>"
//
//                    if includeColumns {
//                        bodyString  = bodyString + "</td>"
//                        bodyString  = bodyString + "</tr>"
//                    }
//                }
                break
            }
        }
        
//        lastKey = key
    }
    
    if includeColumns {
        bodyString  = bodyString + "</table>"
    }
    
    bodyString = bodyString + "<br/>"
    
    if includeURLs, (keys.count > 1) {
//        if let indexTitles = keys {
        
        let a = "a"
        
        let titles = Array(Set(keys.map({ (string:String) -> String in
            if string.endIndex >= a.endIndex {
                return String(string.withoutPrefixes[..<a.endIndex]).uppercased()
            } else {
                return string
            }
        }))).sorted() { $0 < $1 }
        
        var stringIndex = [String:[String]]()
        
        for string in keys {
            let key = String(string.withoutPrefixes[..<a.endIndex]).uppercased()
            
            if stringIndex[key] == nil {
                stringIndex[key] = [String]()
            }
            
            stringIndex[key]?.append(string)
        }

        bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
//        bodyString = bodyString + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
        
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
            
            let tag = title.asTag
            if let count = stringIndex[title]?.count {
                bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title) (\(count))</a><br/>"
            } else {
                bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title)</a><br/>"
            }
            
            if let entries = stringIndex[title] {
                for entry in entries {
                    let tag = entry.asTag
                    bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(entry)</a><br/>"
                }
            }
            
            bodyString = bodyString + "</div>"
        }
        
        bodyString = bodyString + "</div>"
//        }
        
//        bodyString = bodyString + "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
//
//        for key in keys {
//            bodyString = bodyString + "<a href=\"#\(key.asTag)\">\(key)</a><br/>"
//        }
//
//        bodyString = bodyString + "</div>"
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

func yesOrNo(viewController:UIViewController,title:String?,message:String?,
                       yesAction:(()->(Void))?, yesStyle: UIAlertActionStyle,
                       noAction:(()->(Void))?, noStyle: UIAlertActionStyle)
{
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)
    alert.makeOpaque()
    
    let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: yesStyle, handler: { (UIAlertAction) -> Void in
        yesAction?()
    })
    alert.addAction(yesAction)

    let noAction = UIAlertAction(title: Constants.Strings.No, style: noStyle, handler: { (UIAlertAction) -> Void in
        noAction?()
    })
    alert.addAction(noAction)

    Thread.onMainThread {
        viewController.present(alert, animated: true, completion: nil)
    }
}

func firstSecondCancel(viewController:UIViewController,title:String?,message:String?,
                       firstTitle:String?,   firstAction:(()->(Void))?, firstStyle: UIAlertActionStyle,
                       secondTitle:String?,  secondAction:(()->(Void))?, secondStyle: UIAlertActionStyle,
                       cancelAction:(()->(Void))? = nil)
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

