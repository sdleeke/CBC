//
//  extensions.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import PDFKit
import MessageUI
import NaturalLanguage
import AVFoundation
import AudioToolbox

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension FourCharCode
{
    // Create a String representation of a FourCC
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

extension Set
{
    var array: [Element]
    {
        return Array(self)
    }
}

extension Array where Element : Hashable
{
    var set: Set<Element>
    {
        return Set(self)
    }
}

extension UIView
{
    var image : UIImage?
    {
        var snapShotImage : UIImage?
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        
        let success = drawHierarchy(in: bounds, afterScreenUpdates: false)
        
        if (success) {
            snapShotImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        
        UIGraphicsEndImageContext()
        
        return snapShotImage
    }
}

extension UIApplication
{
    func open(scheme: String?,cannotOpen:(()->(Void))?)
    {
        guard let scheme = scheme else {
            return
        }
        
        guard let url = URL(string: scheme) else {
            return
        }
        
        guard self.canOpenURL(url) else { // Reachability.isConnectedToNetwork() &&
            cannotOpen?()
            return
        }
        
        if #available(iOS 10, *) {
            self.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                                      completionHandler: {
                                        (success) in
                                        print("Open \(scheme): \(success)")
            })
        } else {
            let success = UIApplication.shared.openURL(url)
            print("Open \(scheme): \(success)")
        }
    }
}

extension FileManager
{
    var documentsURL : URL?
    {
        get {
            return self.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
    
    var cachesURL : URL?
    {
        get {
            return self.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }

//    func filesOfTypeInCache(_ fileType:String) -> [String]?
//    {
//        guard let path = self.cachesURL?.path else {
//            return nil
//        }
//
//        var files = [String]()
//
//        do {
//            let array = try self.contentsOfDirectory(atPath: path)
//
//            for string in array {
//                if let range = string.range(of: fileType) {
//                    if fileType == String(string[range.lowerBound...]) {
//                        files.append(string)
//                    }
//                }
//            }
//        } catch let error {
//            NSLog("failed to get files in caches directory: \(error.localizedDescription)")
//        }
//
//        return files.count > 0 ? files : nil
//    }
//
//    func filesOfNameInCache(_ filename:String) -> [String]?
//    {
//        guard let path = self.cachesURL?.path else {
//            return nil
//        }
//
//        var files = [String]()
//
//        do {
//            let array = try self.contentsOfDirectory(atPath: path)
//
//            for string in array {
//                if let range = string.range(of: filename) {
//                    if filename == String(string[..<range.upperBound]) {
//                        files.append(string)
//                    }
//                }
//            }
//        } catch let error {
//            NSLog("failed to get files in caches directory: \(error.localizedDescription)")
//        }
//
//        return files.count > 0 ? files : nil
//    }
//
//    func deleteFilesOfNameInCache(_ filename:String) -> [String]?
//    {
//        guard let path = self.cachesURL?.path else {
//            return nil
//        }
//
//        var files = [String]()
//
//        do {
//            let array = try self.contentsOfDirectory(atPath: path)
//
//            for string in array {
//                if let range = string.range(of: filename) {
//                    if filename == String(string[..<range.upperBound]) {
//                        files.append(string)
//
//                        var fileURL = path.url
//
//                        fileURL?.appendPathComponent(string, isDirectory: false)
//
//                        if let fileURL = fileURL {
//                            do {
//                                try self.removeItem(at: fileURL)
//                            } catch let error {
//                                NSLog("failed to delete \(fileURL.lastPathComponent) error: \(error.localizedDescription)")
//                            }
//                        }
//                    }
//                }
//            }
//        } catch let error {
//            NSLog("failed to get files in caches directory: \(error.localizedDescription)")
//        }
//
//        return files.count > 0 ? files : nil
//    }
}

extension Set where Element == String
{
    var tagsString: String?
    {
//        guard let tagsSet = tagsSet else {
//            return nil
//        }
        
        let array = self.array.sorted { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        }
        
        guard array.count > 0 else {
            return nil
        }
        
        return array.joined(separator: Constants.SEPARATOR)
    }
}

extension Array where Element == MediaItem
{
    var voiceBaseMediaItems : Int
    {
        get {
            return self.reduce(0, { (count, mediaItem) -> Int in
                return count + mediaItem.transcripts.values.reduce(0, { (count, transcript) -> Int in
                    return count + (transcript.mediaID != nil ? 1 : 0)
                })
            })
        }
    }
    
    func sort(book:String?) -> [MediaItem]?
    {
        var list:[MediaItem]?
        
        list = self.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBooksChaptersVerses   = first.scripture?.booksChaptersVerses?.copy(for: book)
            let secondBooksChaptersVerses  = second.scripture?.booksChaptersVerses?.copy(for: book)
            
            if firstBooksChaptersVerses == secondBooksChaptersVerses {
                if let firstDate = first.fullDate, let secondDate = second.fullDate {
                    if firstDate.isEqualTo(secondDate) {
                        if first.service == second.service {
                            return first.speaker?.lastName < second.speaker?.lastName
                        } else {
                            return first.service < second.service
                        }
                    } else {
                        return firstDate.isOlderThan(secondDate)
                    }
                } else {
                    return false
                }
            } else {
                return firstBooksChaptersVerses < secondBooksChaptersVerses
            }
        })
        
        return list
    }
    
    var sortChronologically : [MediaItem]?
    {
        return self.sorted() {
            return $0.dateService < $1.dateService
        }
    }
    
    var sortReverseChronologically : [MediaItem]?
    {
        return self.sorted() {
            return $0.dateService > $1.dateService
        }
    }
    
    func sortByYear(sorting:String?) -> [MediaItem]?
    {
        guard let sorting = sorting else {
            return nil
        }
        
        var sortedMediaItems:[MediaItem]?
        
        switch sorting {
        case SORTING.CHRONOLOGICAL:
            sortedMediaItems = self.sortChronologically
            break
            
        case SORTING.REVERSE_CHRONOLOGICAL:
            sortedMediaItems = self.sortReverseChronologically
            break
            
        default:
            break
        }
        
        return sortedMediaItems
    }

    func withTag(tag:String?) -> [MediaItem]?
    {
        guard let tag = tag else {
            return nil
        }
        
        return
            self.filter({ (mediaItem:MediaItem) -> Bool in
                if let tagSet = mediaItem.tagsSet {
                    return tagSet.contains(tag)
                } else {
                    return false
                }
            })
    }
    
    func inBook(_ book:String?) -> [MediaItem]?
    {
        guard let book = book else {
            return nil
        }
        
        return self.filter({ (mediaItem:MediaItem) -> Bool in
            if let books = mediaItem.scripture?.books {
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
    
    var books : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }

        let mediaItems = self
        
        var bookSet = Set<String>()
        
        for mediaItem in mediaItems {
            if let books = mediaItem.scripture?.books {
                for book in books {
                    bookSet.insert(book)
                }
            }
        }
        
//        let array = Array(bookSet) as [String]
        
        return bookSet.array.sorted(by: { (first:String, second:String) -> Bool in
            var result = false
            
            if (first.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                if first.bookNumberInBible == second.bookNumberInBible {
                    result = first < second
                } else {
                    result = first.bookNumberInBible < second.bookNumberInBible
                }
            } else
                if (first.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    result = true
                } else
                    if (first.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                        result = false
                    } else
                        if (first.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            result = first < second
            }
            
            return result
        })
    }
    
    var bookSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }

        let mediaItems = self
        
        var bookSectionSet = Set<String>()
        
        for mediaItem in mediaItems {
            for bookSection in mediaItem.bookSections {
                bookSectionSet.insert(bookSection)
            }
        }
        
//        let array = Array(bookSectionSet) as [String]

        return bookSectionSet.array.sorted(by: { (first:String, second:String) -> Bool in
            var result = false
            if (first.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                if first.bookNumberInBible == second.bookNumberInBible {
                    result = first < second
                } else {
                    result = first.bookNumberInBible < second.bookNumberInBible
                }
            } else
                if (first.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    result = true
                } else
                    if (first.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                        result = false
                    } else
                        if (first.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (second.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            result = first < second
            }
            return result
        })
    }
    
    var series : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        let mediaItems = Set(self.filter({ (mediaItem:MediaItem) -> Bool in
            return mediaItem.hasMultipleParts
        }).map({ (mediaItem:MediaItem) -> String in
            return mediaItem.multiPartName ?? Constants.Strings.None
        }))

        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
        
//                    self.filter({ (mediaItem:MediaItem) -> Bool in
//                        return mediaItem.hasMultipleParts
//                    }).map({ (mediaItem:MediaItem) -> String in
//                        return mediaItem.multiPartName ?? Constants.Strings.None
//                    })
    }
    
    var seriesSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        let mediaItems = Set(self.map({ (mediaItem:MediaItem) -> String in
            if let multiPartSection = mediaItem.multiPartSection {
                return multiPartSection
            } else {
                return "ERROR"
            }
        }))

        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })

//                    self.map({ (mediaItem:MediaItem) -> String in
//                        if let multiPartSection = mediaItem.multiPartSection {
//                            return multiPartSection
//                        } else {
//                            return "ERROR"
//                        }
//                    })
    }
    
    func seriesSections(withTitles:Bool) -> [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }

        let mediaItems = Set(self.map({ (mediaItem:MediaItem) -> String in
            if mediaItem.hasMultipleParts {
                return mediaItem.multiPartName!
            } else {
                return withTitles ? (mediaItem.title ?? "No Title") : Constants.Strings.Individual_Media
            }
        }))
        
        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
        
//                    self.map({ (mediaItem:MediaItem) -> String in
//                        if mediaItem.hasMultipleParts {
//                            return mediaItem.multiPartName!
//                        } else {
//                            return withTitles ? (mediaItem.title ?? "No Title") : Constants.Strings.Individual_Media
//                        }
//                    })
    }

    func html(includeURLs:Bool = true,includeColumns:Bool = true, test:(()->(Bool))? = nil) -> String?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }

        guard test?() != true else {
            return nil
        }
        
        let mediaItems = self
        
        var mediaListSort = [String:[MediaItem]]()
        
        for mediaItem in mediaItems {
            guard test?() != true else {
                return nil
            }
            
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
        
        bodyString += "The following media "
        
        if mediaItems.count > 1 {
            bodyString += "are"
        } else {
            bodyString += "is"
        }
        
        if includeURLs {
            bodyString += " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
            
            //        bodyString += " from <a target=\"_blank\" href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        //    if let category = Globals.shared.mediaCategory.selected {
        //        bodyString += "Category: \(category)<br/><br/>"
        //    }
        //
        //    if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
        //        bodyString += "Collection: \(tag)<br/><br/>"
        //    }
        //
        //    if Globals.shared.search.isValid, let searchText = Globals.shared.search.text {
        //        bodyString += "Search: \(searchText)<br/><br/>"
        //    }
        
        let keys = mediaListSort.keys.sorted() {
            $0.withoutPrefixes < $1.withoutPrefixes
        }
        
        if includeURLs, (keys.count > 1) {
            bodyString += "<a href=\"#index\">Index</a><br/><br/>"
        }
        
        //    var lastKey:String?
        
        if includeColumns {
            bodyString  = bodyString + "<table>"
        }
        
        for key in keys {
            guard test?() != true else {
                return nil
            }
            
            if let mediaItems = mediaListSort[key]?.sorted(by: { (first, second) -> Bool in
                return first.date < second.date
            }) {
                if includeColumns {
                    bodyString  = bodyString + "<tr>"
                    bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                }
                
                bodyString += "<br/>"
                
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
                                bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
                                bodyString  = bodyString + "</td>"
                                bodyString  = bodyString + "</tr>"
                            }
                            bodyString += string
                        }
                    }
                    break
                    
                default:
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
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
                        bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + key + "</a>"
                    } else {
                        bodyString += key
                    }
                    
                    if speakerCount == 1, let speaker = mediaItems[0].speaker, key != speaker {
                        bodyString += " by " + speaker
                    }
                    
                    if mediaItems.count > 1 {
                        bodyString += " (\(mediaItems.count))"
                    }

                    if includeColumns {
                        bodyString += "</td>"
                        bodyString += "</tr>"
                    } else {
                        bodyString += "<br/>"
                    }
                    
                    for mediaItem in mediaItems {
                        guard test?() != true else {
                            return nil
                        }
                        
                        var order = ["date","title","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString += string
                        }
                        
                        if !includeColumns {
                            bodyString += "<br/>"
                        }
                    }
                    
                    if !includeColumns {
                        bodyString += "<br/>"
                    }
                    
                    //                if let lastKey = lastKey, let count = mediaListSort[lastKey]?.count, count == 1 {
                    //                    if includeColumns {
                    //                        bodyString  = bodyString + "<tr>"
                    //                        bodyString  = bodyString + "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
                    //                    }
                    //
                    //                    bodyString += "<br/>"
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
        
        bodyString += "<br/>"
        
        if includeURLs, (keys.count > 1) {
            //        if let indexTitles = keys {
            
            let a = "a"
            
            let titles = keys.map({ (string:String) -> String in
                if string.count >= a.count { // endIndex
                    return String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
                } else {
                    return string
                }
            }).set.array.sorted() { $0 < $1 }
            
            var stringIndex = [String:[String]]()
            
            for string in keys {
                guard test?() != true else {
                    return nil
                }
                
                let key = String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
                
                if stringIndex[key] == nil {
                    stringIndex[key] = [String]()
                }
                
                stringIndex[key]?.append(string)
            }
            
            bodyString += "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
            //        bodyString += "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
            
            var index:String?
            
            for title in titles {
                let link = "<a href=\"#\(title)\">\(title)</a>"
                index = ((index != nil) ? index! + " " : "") + link
            }
            
            bodyString += "<div><a id=\"sections\" name=\"sections\">Sections</a> "
            
            if let index = index {
                bodyString += index + "<br/>"
            }
            
            for title in titles {
                guard test?() != true else {
                    return nil
                }
                
                bodyString += "<br/>"
                
                let tag = title.asTag
                if let count = stringIndex[title]?.count {
                    bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title)</a> (\(count))<br/>"
                } else {
                    bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">\(title)</a><br/>"
                }
                
                if let entries = stringIndex[title] {
                    for entry in entries {
                        let tag = entry.asTag
                        bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(entry)</a><br/>"
                    }
                }
                
                bodyString += "</div>"
            }
            
            bodyString += "</div>"
            //        }
            
            //        bodyString += "<div><a id=\"index\" name=\"index\">Index</a><br/><br/>"
            //
            //        for key in keys {
            //            bodyString += "<a href=\"#\(key.asTag)\">\(key)</a><br/>"
            //        }
            //
            //        bodyString += "</div>"
        }
        
        bodyString += "</body></html>"
        
        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
    }

//    func htmlGlobal(grouping:String,sorting:String,category:String,tag:String?,search:String?,includeURLs:Bool,includeColumns:Bool) -> String?
//    {
////        guard (Globals.shared.media.active?.mediaList?.list != nil) else {
////            return nil
////        }
//        
////        guard let grouping = Globals.shared.grouping else {
////            return nil
////        }
////
////        guard let sorting = Globals.shared.sorting else {
////            return nil
////        }
//        
//        var bodyString = "<!DOCTYPE html><html><body>"
//        
//        bodyString += "The following media "
//        
//        if self.count > 1 {
//            bodyString += "are"
//        } else {
//            bodyString += "is"
//        }
//        
//        if includeURLs {
//            bodyString += " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
//        } else {
//            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
//        }
//
//        bodyString += "Category: \(category)<br/>"
//
////        if let category = Globals.shared.mediaCategory.selected {
////            bodyString += "Category: \(category)<br/>"
////        }
//        
//        if let tag = tag {
//            bodyString += "Collection: \(tag)<br/>"
//        }
//        
////        if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
////            bodyString += "Collection: \(tag)<br/>"
////        }
//        
//        if let searchText = search {
//            bodyString += "Search: \(searchText)<br/>"
//        }
//        
////        if Globals.shared.search.isValid, let searchText = Globals.shared.search.text {
////            bodyString += "Search: \(searchText)<br/>"
////        }
//        
//        bodyString += "Grouped: By \(grouping.translate)<br/>"
//        
//        bodyString += "Sorted: \(sorting.translate)<br/>"
//        
//        if let keys = Globals.shared.media.active?.section?.indexStrings {
//            var count = 0
//            for key in keys {
//                if let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
//                    count += mediaItems.count
//                }
//            }
//            
//            bodyString += "Total: \(count)<br/>"
//            
//            if includeURLs, (keys.count > 1) {
//                bodyString += "<br/>"
//                bodyString += "<a href=\"#index\">Index</a><br/>"
//            }
//            
//            if includeColumns {
//                bodyString += "<table>"
//            }
//            
//            for key in keys {
//                if  let name = Globals.shared.media.active?.groupNames?[grouping]?[key],
//                    let mediaItems = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting] {
//                    var speakerCounts = [String:Int]()
//                    
//                    for mediaItem in mediaItems {
//                        if let speaker = mediaItem.speaker {
//                            if let count = speakerCounts[speaker] {
//                                speakerCounts[speaker] = count + 1
//                            } else {
//                                speakerCounts[speaker] = 1
//                            }
//                        }
//                    }
//                    
//                    let speakerCount = speakerCounts.keys.count
//                    
//                    let tag = key.asTag
//                    
//                    if includeColumns {
//                        if includeURLs {
//                            bodyString += "<tr><td colspan=\"7\"><br/></td></tr>"
//                        } else {
//                            bodyString += "<tr><td colspan=\"7\"><br/></td></tr>"
//                        }
//                    } else {
//                        if includeURLs {
//                            bodyString += "<br/>"
//                        } else {
//                            bodyString += "<br/>"
//                        }
//                    }
//                    
//                    if includeColumns {
//                        bodyString += "<tr>"
//                        bodyString += "<td style=\"vertical-align:baseline;\" colspan=\"7\">"
//                    }
//                    
//                    if includeURLs, (keys.count > 1) {
//                        bodyString += "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + "</a>" //  + " (\(mediaItems.count))"
//                    } else {
//                        bodyString += name + " (\(mediaItems.count))"
//                    }
//                    
//                    if speakerCount == 1 {
//                        if var speaker = mediaItems[0].speaker, name != speaker {
//                            if let speakerTitle = mediaItems[0].speakerTitle {
//                                speaker += ", \(speakerTitle)"
//                            }
//                            bodyString += " by " + speaker
//                        }
//                    }
//                    
//                    if includeColumns {
//                        bodyString += "</td>"
//                        bodyString += "</tr>"
//                    } else {
//                        bodyString += "<br/>"
//                    }
//                    
//                    for mediaItem in mediaItems {
//                        var order = ["date","title","scripture"]
//                        
//                        if speakerCount > 1 {
//                            order.append("speaker")
//                        }
//                        
//                        if Globals.shared.grouping != GROUPING.CLASS {
//                            if mediaItem.hasClassName {
//                                order.append("class")
//                            }
//                        }
//                        
//                        if Globals.shared.grouping != GROUPING.EVENT {
//                            if mediaItem.hasEventName {
//                                order.append("event")
//                            }
//                        }
//                        
//                        if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
//                            bodyString += string
//                        }
//                        
//                        if !includeColumns {
//                            bodyString += "<br/>"
//                        }
//                    }
//                }
//            }
//            
//            if includeColumns {
//                bodyString += "</table>"
//            }
//            
//            bodyString += "<br/>"
//            
//            if includeURLs, keys.count > 1 {
//                bodyString += "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
//                
//                switch grouping {
//                case GROUPING.CLASS:
//                    fallthrough
//                case GROUPING.SPEAKER:
//                    fallthrough
//                case GROUPING.TITLE:
//                    let a = "A"
//                    
//                    if let indexTitles = Globals.shared.media.active?.section?.indexStrings {
//                        let titles = Array(Set(indexTitles.map({ (string:String) -> String in
//                            if string.count >= a.count { // endIndex
//                                return String(string.withoutPrefixes[..<String.Index(utf16Offset: a.count, in: string)]).uppercased()
//                            } else {
//                                return string
//                            }
//                        }))).sorted() { $0 < $1 }
//                        
//                        var stringIndex = [String:[String]]()
//                        
//                        if let indexStrings = Globals.shared.media.active?.section?.indexStrings {
//                            for indexString in indexStrings {
//                                let key = String(indexString[..<String.Index(utf16Offset: a.count, in: indexString)]).uppercased()
//                                
//                                if stringIndex[key] == nil {
//                                    stringIndex[key] = [String]()
//                                }
//                                
//                                stringIndex[key]?.append(indexString)
//                            }
//                        }
//                        
//                        var index:String?
//                        
//                        for title in titles {
//                            let link = "<a href=\"#\(title)\">\(title)</a>"
//                            index = ((index != nil) ? index! + " " : "") + link
//                        }
//                        
//                        bodyString += "<div><a id=\"sections\" name=\"sections\">Sections</a> "
//                        
//                        if let index = index {
//                            bodyString += index + "<br/>"
//                        }
//                        
//                        for title in titles {
//                            bodyString += "<br/>"
//                            if let count = stringIndex[title]?.count { // Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count
//                                bodyString += "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a> (\(count))<br/>"
//                            } else {
//                                bodyString += "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
//                            }
//                            
//                            if let keys = stringIndex[title] {
//                                for key in keys {
//                                    if let title = Globals.shared.media.active?.groupNames?[grouping]?[key] {
//                                        let tag = key.asTag
//                                        bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title)</a><br/>" // (\(count))
//                                    }
//                                }
//                            }
//                            
//                            bodyString += "</div>"
//                        }
//                        
//                        bodyString += "</div>"
//                    }
//                    break
//                    
//                default:
//                    for key in keys {
//                        if let title = Globals.shared.media.active?.groupNames?[grouping]?[key],
//                            let count = Globals.shared.media.active?.groupSort?[grouping]?[key]?[sorting]?.count {
//                            let tag = key.asTag
//                            bodyString += "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
//                        }
//                    }
//                    break
//                }
//                
//                bodyString += "</div>"
//            }
//        }
//        
//        bodyString += "</body></html>"
//        
//        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
//    }
}

extension Array where Element == UIViewController
{
    func containsBelow(_ containedViewController:UIViewController) -> Bool
    {
        for viewController in self {
            if viewController == containedViewController {
                return true
            }
            
            if let navCon = (viewController as? UINavigationController) {
                if navCon.viewControllers.containsBelow(containedViewController) == true {
                    return true
                }
            }
        }
        
        return false
    }
}

extension Array where Element == String
{
    func timingHTML(_ headerHTML:String?, test:(()->(Bool))? = nil) -> String?
    {
        var htmlString = "<!DOCTYPE html><html><body>"
        
        var transcriptSegmentHTML = String()
        
        transcriptSegmentHTML += "<table>"
        
        transcriptSegmentHTML += "<tr style=\"vertical-align:bottom;\"><td><b>#</b></td><td><b>Gap</b></td><td><b>Start Time</b></td><td><b>End Time</b></td><td><b>Span</b></td><td><b>Recognized Speech</b></td></tr>"
        
            var priorEndTime : Double?
            
            for transcriptSegmentComponent in self {
                guard test?() != true else {
                    return nil
                }
                
                var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                
                if transcriptSegmentArray.count > 2  {
                    let count = transcriptSegmentArray.removeFirst()
                    let timeWindow = transcriptSegmentArray.removeFirst()
                    let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
                    
                    if  let start = times.first,
                        let end = times.last,
                        let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                        let text = String(transcriptSegmentComponent[range.upperBound...])
                        
                        var gap = String()
                        var duration = String()
                        
                        if let startTime = start.hmsToSeconds, let endTime = end.hmsToSeconds {
                            let durationTime = endTime - startTime
                            duration = String(format:"%.3f",durationTime)
                            
                            if let peTime = priorEndTime {
                                let gapTime = startTime - peTime
                                gap = String(format:"%.3f",gapTime)
                            }
                        }
                        
                        priorEndTime = end.hmsToSeconds
                        
                        let row = "<tr style=\"vertical-align:top;\"><td>\(count)</td><td>\(gap)</td><td>\(start)</td><td>\(end)</td><td>\(duration)</td><td>\(text.replacingOccurrences(of: "\n", with: " "))</td></tr>"
                        transcriptSegmentHTML = transcriptSegmentHTML + row
                    }
                }
            }
        
        transcriptSegmentHTML = transcriptSegmentHTML + "</table>"
        
        htmlString = htmlString + (headerHTML ?? "") + transcriptSegmentHTML + "</body></html>"

        return htmlString
    }
    
    func additions(to array1:[String]?) -> [(Int,String)]?
    {
        guard let array1 = array1 else {
            return self.enumerated().map({ (arg0) -> (Int,String) in
//                let (offset, element) = arg0
                return arg0
            })
        }
        
        var array2 = self as [String]
        
        var diff = [(Int,String)]()
        
        for (index, element) in array1.enumerated() {
//            var first:String? = array2[index]
//            var second:String? = array1[index]
//
//            if let separator = separator {
//                if let range = first?.range(of: separator), let string = first {
//                    first = String(string[..<range.lowerBound])
//                }
//
//                if let range = second?.range(of: separator), let string = second {
//                    second = String(string[..<range.lowerBound])
//                }
//            }
//
//            if first != second {

            if array2[index] != array1[index] {
                array2.remove(at: index)
                diff.append((index,element))
            }
        }

        return diff.count > 0 ? diff : nil
    }
    
    func sort(method:String?) -> [String]?
    {
//        guard let strings = strings else {
//            return nil
//        }

        let strings = self
        
        guard let method = method else {
            return nil
        }
        
        switch method {
        case Constants.Sort.Alphabetical:
            return strings.sorted()
            
        case Constants.Sort.Length:
            return strings.sorted(by: { (first:String, second:String) -> Bool in
                guard let firstCount = first.components(separatedBy: Constants.SINGLE_SPACE).first?.count else {
                    return false
                }
                
                guard let secondCount = second.components(separatedBy: Constants.SINGLE_SPACE).first?.count else {
                    return true
                }
                
                if firstCount == secondCount {
                    return first < second
                } else {
                    return firstCount > secondCount
                }
            })
            
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

    var tagsString : String?
    {
//        guard let tagsArray = tagsArray else {
//            return nil
//        }
        
        return self.count > 0 ? self.joined(separator: Constants.SEPARATOR) : nil
    }
    
    var tableHTML : String?
    {
        return tableHTML()
    }
    
    func tableHTML(title:String? = nil, searchText:String? = nil, test:(()->(Bool))? = nil) -> String?
    {
        guard test?() != true else {
            return nil
        }
        
        var bodyHTML:String! = "<!DOCTYPE html>"
        
        bodyHTML += "<html><body>"

        let words = self.sorted()
        
//            guard let words = self.sorted() else {
//                bodyHTML += "</body></html>"
//                return bodyHTML
//            }
        
        //            var hyphenWords = [String]()
        //
        //            for wordRoot in wordRoots {
        //                if let words = wordRoot.hyphenWords(nil) {
        //                    hyphenWords.append(contentsOf: words)
        //                }
        //            }
        
        var wordsHTML = ""
        var indexHTML = ""
        
        //            let words = hyphenWords.sorted(by: { (lhs:String, rhs:String) -> Bool in
        //                return lhs < rhs
        //            })
        
        var roots = [String:Int]()
        
        var keys : [String] {
            get {
                return roots.keys.sorted()
            }
        }

        for word in words {
//        words.forEach({ (word:String) in
            guard test?() != true else {
                return nil
            }
            
            let key = String(word[..<String.Index(utf16Offset: 1, in: word)])
            //                    let key = String(word[..<String.Index(encodedOffset: 1)])
            if let count = roots[key] {
                roots[key] = count + 1
            } else {
                roots[key] = 1
            }
        }

        if let title = title {
            bodyHTML += title
            bodyHTML += "<br/>"
        }
        
        bodyHTML += "<p>Index to \(words.count.formatted) Words</p>"

//        bodyHTML += "<div>Word Index (\(words.count))<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)

        if let searchText = searchText?.uppercased() {
            bodyHTML += "Search Text: \(searchText)<br/><br/>" //  (<a id=\"wordsIndex\" name=\"wordsIndex\" href=\"#top\">Return to Top</a>)
        }
    
        var index : String?
        
        for root in roots.keys.sorted() {
            guard test?() != true else {
                return nil
            }
            
            let tag = root.asTag
            
            let link = "<a id=\"wordIndex\(tag)\" name=\"wordIndex\(tag)\" href=\"#words\(tag)\">\(root)</a>"
            index = ((index != nil) ? index! + " " : "") + link
        }
        
        indexHTML += "<div><a id=\"wordSections\" name=\"wordSections\">Sections</a> "
        
        if let index = index {
            indexHTML += index + "<br/>"
        }
        
        indexHTML += "<br/>"
        
        wordsHTML = "<style>.index { margin: 0 auto; } .words { list-style: none; column-count: 2; margin: 0 auto; padding: 0; } .back { list-style: none; font-size: 10px; margin: 0 auto; padding: 0; }</style>"
        
        wordsHTML += "<div class=\"index\">"
        
        wordsHTML += "<ul class=\"words\">"
        
        var section = 0
        
        let tag = keys[section].asTag
        
        wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
        
        for word in words {
            guard test?() != true else {
                return nil
            }
            
            let first = String(word[..<String.Index(utf16Offset: 1, in: word)])
            
            if first != keys[section] {
                // New Section
                section += 1
                
                wordsHTML += "</ul>"
                
                wordsHTML += "<br/>"
                
                wordsHTML += "<ul class=\"words\">"
                
                let tag = keys[section].asTag
                
                wordsHTML += "<a id=\"words\(tag)\" name=\"words\(tag)\" href=#wordIndex\(tag)>" + keys[section] + "</a>" + " (\(roots[keys[section]]!))"
            }
            
            wordsHTML += "<li>"
            
            if let searchText = searchText {
                wordsHTML += word.markSearchHTML(searchText)
            } else {
                wordsHTML += word
            }

            wordsHTML += "</li>"
        }
        
        wordsHTML += "</ul>"
        
        wordsHTML += "</div>"
        
        wordsHTML += "</div>"
        
        bodyHTML += indexHTML + wordsHTML + "</body></html>"
        
        return bodyHTML
    }
}

extension String
{
    var translateTestament : String
    {
        var translation = Constants.EMPTY_STRING
        
        switch self {
        case Constants.OT:
            translation = Constants.Old_Testament
            break
            
        case Constants.NT:
            translation = Constants.New_Testament
            break
            
        case Constants.Old_Testament:
            translation = Constants.OT
            break
            
        case Constants.New_Testament:
            translation = Constants.NT
            break
            
        default:
            break
        }
        
        return translation
    }
    
    var translate : String
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        switch self {
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
}

extension String
{
    func verses(book:String,chapter:Int) -> [Int]
    {
        var versesForChapter = [Int]()
        
        if let verses = self.booksChaptersVerses?[book]?[chapter] {
            versesForChapter = verses
        }
        
        return versesForChapter
    }
    
    func chaptersAndVerses(book:String) -> [Int:[Int]]
    {
        var chaptersAndVerses = [Int:[Int]]()
        
        if let cav = self.booksChaptersVerses?[book] {
            chaptersAndVerses = cav
        }
        
        return chaptersAndVerses
    }

    var booksChaptersVerses : BooksChaptersVerses?
    {
//        if self.booksChaptersVerses != nil {
//            return self.booksChaptersVerses
//        }
        
//        guard (scripture != nil) else {
//            return nil
//        }
        
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }
        
        let scriptureReference = self
        
        guard let books = books else { // booksFromScriptureReference(scriptureReference)
            return nil
        }
        
        let booksChaptersVerses = BooksChaptersVerses()
        
        //        let separator = ";"
        //        let scriptures = scriptureReference.components(separatedBy: separator)
        
        var ranges = [Range<String.Index>]()
        var scriptures = [String]()
        
        for book in books {
            if let range = scriptureReference.range(book) {
                ranges.append(range)
            }
            //            if let range = scriptureReference.lowercased().range(of: book.lowercased()) {
            //                ranges.append(range)
            //            } else {
            //                var bk = book
            //
            //                repeat {
            //                    if let range = scriptureReference.range(of: bk.lowercased()) {
            //                        ranges.append(range)
            //                        break
            //                    } else {
            //                        bk.removeLast()
            //                        if bk.last == " " {
            //                            break
            //                        }
            //                    }
            //                } while bk.count > 2
            //            }
        }
        
        if books.count == ranges.count {
            var lastRange : Range<String.Index>?
            
            for range in ranges {
                if let lastRange = lastRange {
                    scriptures.append(String(scriptureReference[lastRange.lowerBound..<range.lowerBound]))
                }
                
                lastRange = range
            }
            
            if let lastRange = lastRange {
                scriptures.append(String(scriptureReference[lastRange.lowerBound..<scriptureReference.endIndex]))
            }
        } else {
            // BUMMER
        }
        
        //        var scriptures = [String]()
        //
        //        var string = scriptureReference
        //
        //        while let range = string.range(of: separator) {
        //            scriptures.append(String(string[..<range.lowerBound]))
        //            string = String(string[range.upperBound...])
        //        }
        //
        //        scriptures.append(string)
        
        //        var lastBook:String?
        
        for scripture in scriptures {
            //            var book = booksFromScriptureReference(scripture)?.first
            //
            //            if book == nil {
            //                book = lastBook
            //            } else {
            //                lastBook = book
            //            }
            
            if let book = scripture.books?.first {
                var reference : String?
                
                if let range = scripture.range(book) {
                    reference = String(scripture[range.upperBound...])
                }
                
                //                var bk = book
                //
                //                repeat {
                //                    if let range = scripture.lowercased().range(of: bk.lowercased()) {
                //                        reference = String(scripture[range.upperBound...])
                //                        break
                //                    } else {
                //                        bk.removeLast()
                //                        if bk.last == " " {
                //                            break
                //                        }
                //                    }
                //                } while bk.count > 2
                
                // What if a reference includes the book more than once?
                booksChaptersVerses[book] = reference?.chaptersAndVerses(book)
                
                if let chapters = booksChaptersVerses[book]?.keys {
                    for chapter in chapters {
                        if booksChaptersVerses[book]?[chapter] == nil {
                            print(description,book,chapter)
                        }
                    }
                }
            }
        }
        
        return booksChaptersVerses.count > 0 ? booksChaptersVerses : nil
    }
    
    func chapters(_ thisBook:String) -> [Int]?
    {
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }
        
        let scriptureReference = self
        
        guard !Constants.NO_CHAPTER_BOOKS.contains(thisBook) else {
            return [1]
        }
        
        var chaptersForBook:[Int]?
        
        guard let books = scriptureReference.books else {
            return nil
        }
        
        switch books.count {
        case 0:
            break
            
        case 1:
            if thisBook == books.first {
                if Constants.NO_CHAPTER_BOOKS.contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scriptureReference
                    
                    if (string.range(of: ";") == nil) {
                        if let range = scriptureReference.range(of: thisBook) {
                            chaptersForBook = String(string[range.upperBound...]).chapters
                        } else {
                            // ???
                        }
                    } else {
                        while let range = string.range(of: ";") {
                            var subString = String(string[..<range.lowerBound])
                            
                            if let range = subString.range(of: thisBook) {
                                subString = String(subString[range.upperBound...])
                            }
                            if let chapters = subString.chapters {
                                chaptersForBook?.append(contentsOf: chapters)
                            }
                            
                            string = String(string[range.upperBound...])
                        }
                        
                        if let range = string.range(of: thisBook) {
                            string = String(string[range.upperBound...])
                        }
                        if let chapters = string.chapters {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            } else {
                // THIS SHOULD NOT HAPPEN
            }
            break
            
        default:
            var scriptures = [String]()
            
            var string = scriptureReference
            
            let separator = ";"
            
            while let range = string.range(of: separator) {
                scriptures.append(String(string[..<range.lowerBound]))
                string = String(string[range.upperBound...])
            }
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if let range = scripture.range(of: thisBook) {
                    if let chapters = String(scripture[range.upperBound...]).chapters {
                        if chaptersForBook == nil {
                            chaptersForBook = chapters
                        } else {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            }
            break
        }
        
        return chaptersForBook
    }
    
    func versesForChapter(_ chapter:Int) -> [Int]?
    {
//        guard let book = book else {
//            return nil
//        }

        let book = self
        
        var verses = [Int]()
        
        let startVerse = 1
        var endVerse = 0
        
        switch book.testament {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                index < Constants.OLD_TESTAMENT_VERSES.count,
                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
            }
            break
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
            switch book.testament {
            case Constants.Old_Testament:
                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                    debug(index,Constants.OLD_TESTAMENT_VERSES.count,Constants.OLD_TESTAMENT_VERSES[index].count)
                }
                break
            case Constants.New_Testament:
                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
                    debug(index,Constants.NEW_TESTAMENT_VERSES.count,Constants.NEW_TESTAMENT_VERSES[index].count)
                }
                break
            default:
                break
            }
        }
        
        return verses.count > 0 ? verses : nil
    }
    
    func chaptersAndVerses(_ book:String?) -> [Int:[Int]]?
    {
        // This can only comprehend a range of chapters or a range of verses from a single book.
        
        guard let book = book else {
            return nil
        }

        let reference = self
        
        guard (reference.range(of: ".") == nil) else {
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
        
        let string = reference.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
//        if (string == nil) || (string == Constants.EMPTY_STRING) {
        if string.isEmpty {
            // Now we have a book w/ no chapter or verse references
            // FILL in all chapters and all verses and return
            return book.chaptersAndVerses
        }
        
        var token = Constants.EMPTY_STRING
        
//        if let chars = string {
            for char in string {
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
//        }
        
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
                return book.chaptersAndVerses
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
                                chaptersAndVerses[currentChapter] = book.versesForChapter(currentChapter)
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
                                    chaptersAndVerses[currentChapter] = book.versesForChapter(currentChapter)
                                    
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
                                                    
                                                    switch book.testament {
                                                    case Constants.Old_Testament:
                                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                        }
                                                        break
                                                    case Constants.New_Testament:
                                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                
                                switch book.testament {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                        startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                        
                                        switch book.testament {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                
                                switch book.testament {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                        index >= 0,
                                        startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count,
                                        startChapter >= 1
                                    {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                        
                                        switch book.testament {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                    
                                    switch book.testament {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                                    
                                    switch book.testament {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][currentChapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
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
                                            
                                            switch book.testament {
                                            case Constants.Old_Testament:
                                                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                                    chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                }
                                                break
                                            case Constants.New_Testament:
                                                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
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
                            chaptersAndVerses[chapter] = book.versesForChapter(chapter)
                            
                            if chaptersAndVerses[chapter] == nil {
                                print(book as Any,reference as Any)
                            }
                        }
                    }
                } else {
                    chaptersAndVerses[startChapter] = book.versesForChapter(startChapter)
                    
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
            return book.chaptersAndVerses
        }
        
        return chaptersAndVerses.count > 0 ? chaptersAndVerses : nil
    }
    
    var chapters : [Int]?
    {
        // This can only comprehend a range of chapters or a range of verses from a single book.
        
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }

        let scriptureReference = self
        
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
    
    var books : [String]?
    {
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }

        let scriptureReference = self
        
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
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first),
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first) {
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.count - 1
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                        let firstIndex = 0
                        if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: first),
                            let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
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
    
    var testament : String
    {
        if (Constants.OLD_TESTAMENT_BOOKS.contains(self)) {
            return Constants.Old_Testament
        } else
            if (Constants.NEW_TESTAMENT_BOOKS.contains(self)) {
                return Constants.New_Testament
        }
        
        return Constants.EMPTY_STRING
    }
    
    var verses : [Int]?
    {
//        guard let scripture = scripture else {
//            return nil
//        }
        
        var verses = [Int]()
        
        var string = self.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
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

    var chaptersAndVerses : [Int:[Int]]?
    {
//        guard let book = book else {
//            return nil
//        }
        
        let book = self
        
        var chaptersAndVerses = [Int:[Int]]()
        
        var startChapter = 0
        var endChapter = 0
        var startVerse = 0
        var endVerse = 0
        
        startChapter = 1
        
        switch book.testament {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                endChapter = Constants.OLD_TESTAMENT_CHAPTERS[index]
            }
            break
            
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
                endChapter = Constants.NEW_TESTAMENT_CHAPTERS[index]
            }
            break
            
        default:
            break
        }
        
        for chapter in startChapter...endChapter {
            startVerse = 1
            
            switch book.testament {
            case Constants.Old_Testament:
                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                }
                break
                
            case Constants.New_Testament:
                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
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
}

extension String
{
//    var toTagsSet : Set<String>?
//    {
//        guard var tags = tags else {
//            return nil
//        }
//
//        var tag:String
//        var tagsSet = Set<String>()
//
//        while (tags.range(of: Constants.SEPARATOR) != nil) {
//            if let range = tags.range(of: Constants.SEPARATOR) {
//                tag = String(tags[..<range.lowerBound])
//                tagsSet.insert(tag)
//                tags = String(tags[range.upperBound...])
//            } else {
//                // ???
//            }
//        }
//
//        tagsSet.insert(tags)
//
//        return tagsSet.count == 0 ? nil : tagsSet
//    }

    var tagsSet : Set<String>?
    {
//        guard let tagsString = tagsString else {
//            return nil
//        }
        
        let array = self.components(separatedBy: Constants.SEPARATOR)
        
        return array.count > 0 ? Set(array) : nil
    }
    
    var tagsArray : [String]?
    {
//        guard let tagsString = tagsString else {
//            return nil
//        }
        
        let array = self.components(separatedBy: Constants.SEPARATOR)
        
        return array.count > 0 ? array : nil
    }
}

extension UITableView
{
    func isValid(_ indexPath:IndexPath) -> Bool
    {
        guard indexPath.section >= 0 else {
            return false
        }
        
        guard indexPath.section < self.numberOfSections else {
            return false
        }
        
        guard indexPath.row >= 0 else {
            return false
        }
        
        guard indexPath.row < self.numberOfRows(inSection: indexPath.section) else {
            return false
        }
        
        return true
    }
}

extension NSAttributedString
{
    func markedBySearch(string:String?, searchText:String?, wholeWordsOnly:Bool, test : (()->Bool)?) -> NSAttributedString?
    {
        guard var workingString = string, !workingString.isEmpty else {
            return nil
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return NSAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        }
        
        guard wholeWordsOnly else {
            let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
            
//            var startingRange = Range(uncheckedBounds: (lower: workingString.startIndex, upper: workingString.endIndex))
            
            let range = NSRange(location: 0, length: workingString.utf16.count)

            if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
                regex.matches(in: workingString, options: .withTransparentBounds, range: range).forEach {
                    attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                                 range: $0.range)
                }
            }
            
//            while let range = self.string.lowercased().range(of: searchText.lowercased(), options: [], range: startingRange, locale: nil) {
//                if let test = test, test() {
//                    break
//                }
//
//                let nsRange = NSMakeRange(range.lowerBound.utf16Offset(in: searchText), searchText.count)
//
//                //            let nsRange = NSMakeRange(range.lowerBound.encodedOffset, searchText.count)
//
//                attributedText.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: nsRange)
//                startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: workingString.endIndex))
//            }
            
            return attributedText
        }
        
        let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        
        let range = NSRange(location: 0, length: workingString.utf16.count)
        
        if let regex = try? NSRegularExpression(pattern: "\\b" + searchText + "\\b", options: .caseInsensitive) {
            regex.matches(in: workingString, options: .withTransparentBounds, range: range).forEach {
                attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                             range: $0.range)
            }
        }
        
        return attributedText

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
                
                newAttrString.append(NSMutableAttributedString(string: stringBefore, attributes: Constants.Fonts.Attributes.body))
                
                newAttrString.append(foundAttrString)
                
                //                stringBefore = stringBefore + foundString
                
                workingString = stringAfter
            } else {
                break
            }
        }
        
        newAttrString.append(NSMutableAttributedString(string: stringAfter, attributes: Constants.Fonts.Attributes.body))
        
        if newAttrString.string.isEmpty, let string = string {
            newAttrString.append(NSMutableAttributedString(string: string, attributes: Constants.Fonts.Attributes.body))
        }
        
        return newAttrString
    }
}

extension Dictionary
{
    // Would be nice to know the key path of what comes back.
    func search(key:String) -> Any?
    {
        guard var currDict = self as? [String : Any]  else {
            return nil
        }
        
        if let foundValue = currDict[key] {
            return foundValue
        } else {
            for val in currDict.values {
                if let innerDict = val as? [String:Any], let result = innerDict.search(key: key) {
                    return result
                }
            }
            return nil
        }
    }
//    func search(key:String, in dict:[String:Any] = [:]) -> Any?
//    {
//        guard var currDict = self as? [String : Any]  else {
//            return nil
//        }
//
//        currDict = !dict.isEmpty ? dict : currDict
//
//        if let foundValue = currDict[key] {
//            return foundValue
//        } else {
//            for val in currDict.values {
//                if let innerDict = val as? [String:Any], let result = search(key: key, in: innerDict) {
//                    return result
//                }
//            }
//            return nil
//        }
//    }
}

//extension Dictionary
//{
//    // How do we know the Key, Value types are the same between the two dictionaries?
//    // Wouldn't we be better off using the merge methods of Dictionary?
//    func union(_ dictionary: Dictionary<Key, Value>?) -> Dictionary<Key, Value>?
//    {
//        var dict = Dictionary<Key, Value>()
//        
//        for (key, value) in self {
//            dict[key] = value
//        }
//        
//        if let dictionary = dictionary {
//            for (key, value) in dictionary {
//                if dict[key] == nil {
//                    dict[key] = value
//                } else {
//                    // collision!
//                }
//            }
//        }
//        
//        return dict.count > 0 ? dict : nil
//    }
//}

extension String
{
    func markSearchHTML(_ searchText:String?) -> String
    {
        guard let searchText = searchText?.uppercased() else {
            return self
        }
        
        var string = self.uppercased()
        
        if let range = string.range(of: searchText) {
            string = String(string[..<range.lowerBound]) + "<mark>" + searchText + "</mark>" + String(string[range.upperBound...])
        }
        
        return string
    }
    
    var stripHead : String
    {
//        guard let string = string else {
//            return nil
//        }
        
        var bodyString = self
        
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
    
    func insertHead(fontSize:Int) -> String
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
        
        return self.replacingOccurrences(of: "<html>", with: head)
    }
}

struct AlertAction
{
    let title : String
    let style : UIAlertAction.Style
    let handler : (()->(Void))?
}

extension UIViewController
{
    func alertActionsCancel(title:String?,message:String?,alertActions:[AlertAction]?,cancelAction:(()->(Void))?)
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
        
        let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
            cancelAction?()
        })
        alert.addAction(cancelAction)
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func alertActionsOkay(title:String?,message:String?,alertActions:[AlertAction]?,okayAction:(()->(Void))?)
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
        
        let okayAlertAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: { (UIAlertAction) -> Void in
            okayAction?()
        })
        alert.addAction(okayAlertAction)
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func searchAlert(title:String?,message:String?,searchText:String?,searchAction:((_ alert:UIAlertController)->(Void))?)
    {
        let alert = UIAlertController(  title: title,
                                        message: message,
                                        preferredStyle: .alert)
        alert.makeOpaque()
        
        alert.addTextField(configurationHandler: { (textField:UITextField) in
            textField.placeholder = searchText ?? "search string"
        })
        
        let search = UIAlertAction(title: "Search", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in
            searchAction?(alert)
        })
        alert.addAction(search)
        
        let clear = UIAlertAction(title: "Clear", style: UIAlertAction.Style.destructive, handler: {
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
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func yesOrNo(title:String?,message:String?,
                 yesAction:(()->(Void))?, yesStyle: UIAlertAction.Style,
                 noAction:(()->(Void))?, noStyle: UIAlertAction.Style)
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
            self.present(alert, animated: true, completion: nil)
        }
    }

    func firstSecondCancel(title:String?,message:String?,
                           firstTitle:String?,   firstAction:(()->(Void))?, firstStyle: UIAlertAction.Style,
                           secondTitle:String?,  secondAction:(()->(Void))?, secondStyle: UIAlertAction.Style,
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
        
        let cancelAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
            cancelAction?()
        })
        alert.addAction(cancelAction)
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mailText(viewController:UIViewController?,to: [String]?,subject: String?, body:String)
    {
        guard let viewController = viewController else {
            return
        }
        
        guard MFMailComposeViewController.canSendMail() else {
            self.showSendMailErrorAlert()
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
    
    func mailHTML(to: [String]?,subject: String?, htmlString:String)
    {
//        guard let viewController = viewController else {
//            return
//        }
        
        guard MFMailComposeViewController.canSendMail() else {
            showSendMailErrorAlert()
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        
        // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposeViewController.mailComposeDelegate = self as? MFMailComposeViewControllerDelegate
        
        mailComposeViewController.setToRecipients(to)
        
        if let subject = subject {
            mailComposeViewController.setSubject(subject)
        }
        
        mailComposeViewController.setMessageBody(htmlString, isHTML: true)
        
        Thread.onMainThread {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }

    func printJob(data:Data?)
    {
        guard UIPrintInteractionController.isPrintingAvailable, let data = data else {
            return
        }
        
        let pi = UIPrintInfo.printInfo()
        
        pi.outputType = UIPrintInfo.OutputType.general
        pi.jobName = Constants.Strings.Print;
        pi.duplex = UIPrintInfo.Duplex.longEdge
        
        let pic = UIPrintInteractionController.shared

        pic.printInfo = pi
        pic.showsPaperSelectionForLoadedPapers = true
        
        pic.printingItem = data // Causes orientation to be ignored
        
        Thread.onMainThread {
            if let barButtonItem = self.navigationItem.rightBarButtonItem {
                pic.present(from: barButtonItem, animated: true, completionHandler: nil)
            }
        }
    }
    
    func printTextJob(string:String?,orientation:UIPrintInfo.Orientation)
    {
        guard UIPrintInteractionController.isPrintingAvailable, let string = string else {
            return
        }
        
        let pi = UIPrintInfo.printInfo()
        
        pi.outputType = UIPrintInfo.OutputType.general
        pi.jobName = Constants.Strings.Print;
        pi.duplex = UIPrintInfo.Duplex.longEdge
        pi.orientation = orientation

        let pic = UIPrintInteractionController.shared

        pic.printInfo = pi
        pic.showsPaperSelectionForLoadedPapers = true
        
        let formatter = UISimpleTextPrintFormatter(text: string)
        let margin:CGFloat = 0.5 * 72.0 // 72=1" margins
        formatter.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        // use printFormatter or pageRenderer (below)
        //        pic.printFormatter = formatter
        
        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Thread.onMainThread {
            if let barButtonItem = self.navigationItem.rightBarButtonItem {
                pic.present(from: barButtonItem, animated: true, completionHandler: nil)
            }
        }
    }
    
    func printText(string:String?)
    {
        guard UIPrintInteractionController.isPrintingAvailable && (string != nil) else {
            return
        }
        
        pageOrientation(portrait: ({
            self.printTextJob(string:string,orientation:.portrait)
        }),
                        landscape: ({
                            self.printTextJob(string:string,orientation:.landscape)
                        }),
                        cancel: ({
                        })
        )
    }
    
    func printImageJob(image:UIImage?,orientation:UIPrintInfo.Orientation)
    {
        guard UIPrintInteractionController.isPrintingAvailable, let image = image else {
            return
        }
        
        let pi = UIPrintInfo.printInfo()
        pi.outputType = UIPrintInfo.OutputType.general
        pi.jobName = Constants.Strings.Print;
        pi.duplex = UIPrintInfo.Duplex.longEdge
        pi.orientation = orientation
        
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.showsPaperSelectionForLoadedPapers = true
        
        let imageView = UIImageView(image: image)
        
        let formatter = imageView.viewPrintFormatter()
        
        let margin:CGFloat = 0.5 * 72.0 // 72=1" margins
        
        formatter.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        // use printFormatter or pageRenderer (below)
        //        pic.printFormatter = formatter
        
        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Thread.onMainThread {
            if let barButtonItem = self.navigationItem.rightBarButtonItem {
                pic.present(from: barButtonItem, animated: true, completionHandler: nil)
            }
        }
    }
    
    func printImage(image:UIImage?)
    {
        guard UIPrintInteractionController.isPrintingAvailable && (image != nil) else {
            return
        }

        pageOrientation(
            portrait: ({
                self.printImageJob(image:image,orientation:.portrait)
            }),
            landscape: ({
                self.printImageJob(image:image,orientation:.landscape)
            }),
            cancel: ({
            })
        )
    }
    
    func printHTMLJob(html:String?,orientation:UIPrintInfo.Orientation)
    {
        guard UIPrintInteractionController.isPrintingAvailable, let html = html else {
            return
        }
        
        let pi = UIPrintInfo.printInfo()
        pi.outputType = UIPrintInfo.OutputType.general
        pi.jobName = Constants.Strings.Print;
        pi.duplex = UIPrintInfo.Duplex.longEdge
        pi.orientation = orientation
        
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.showsPaperSelectionForLoadedPapers = true
        
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72.0 // 72=1" margins
        formatter.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        // use printFormatter or pageRenderer (below)
        //        pic.printFormatter = formatter
        
        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Thread.onMainThread {
            if let barButtonItem = self.navigationItem.rightBarButtonItem {
                pic.present(from: barButtonItem, animated: true, completionHandler: nil)
            }
        }
    }
    
    func printHTML(htmlString:String?)
    {
        guard UIPrintInteractionController.isPrintingAvailable && (htmlString != nil) else {
            return
        }
        
        self.pageOrientation(
            portrait: ({
                self.printHTMLJob(html:htmlString,orientation:.portrait)
            }),
            landscape: ({
                self.printHTMLJob(html:htmlString,orientation:.landscape)
            }),
            cancel: ({
            })
        )
    }
    
    func printDocument(documentURL:URL?)
    {
        guard UIPrintInteractionController.isPrintingAvailable, let documentURL = documentURL else {
            return
        }
        
        self.process(work: {
            return NSData(contentsOf: documentURL)
        }, completion: { (data:Any?) in
            self.printJob(data: data as? Data)
        })
    }
    
    func printMediaItem(mediaItem:MediaItem?)
    {
        guard UIPrintInteractionController.isPrintingAvailable && (mediaItem != nil) else {
            return
        }
        
        self.process(work: {
            return mediaItem?.contentsHTML
        }, completion: { (data:Any?) in
            self.printHTMLJob(html:(data as? String),orientation:.portrait)
        })
    }
    
    func pageOrientation(portrait:(()->(Void))?,landscape:(()->(Void))?,cancel:(()->(Void))?)
    {
        self.firstSecondCancel(title: "Page Orientation", message: nil,
                          firstTitle: "Portrait", firstAction: portrait, firstStyle: .default,
                          secondTitle: "Landscape", secondAction: landscape, secondStyle: .default,
                          cancelAction: cancel)
    }
    
    func printMediaItems(viewController:UIViewController,mediaItems:[MediaItem]?,stringFunction:(([MediaItem]?,Bool,Bool)->String?)?,links:Bool,columns:Bool)
    {
        guard UIPrintInteractionController.isPrintingAvailable && (mediaItems != nil) && (stringFunction != nil) else {
            return
        }
        
        func processMediaItems(orientation:UIPrintInfo.Orientation)
        {
            viewController.process(work: {
                return stringFunction?(mediaItems,links,columns)
            }, completion: { (data:Any?) in
                self.printHTMLJob(html:(data as? String),orientation:orientation)
            })
        }
        
        self.pageOrientation(   portrait: ({
                                    processMediaItems(orientation:.portrait)
                                }),
                                landscape: ({
                                    processMediaItems(orientation:.landscape)
                                }),
                                cancel: ({
                                })
        )
    }
    
    func mailMediaItems(viewController:UIViewController, mediaItems:[MediaItem]?, stringFunction:(([MediaItem]?,Bool,Bool)->String?)?, links:Bool, columns:Bool, attachments:Bool)
    {
        guard (mediaItems != nil) && (stringFunction != nil) && MFMailComposeViewController.canSendMail() else {
            self.showSendMailErrorAlert()
            return
        }
        
        viewController.process(work: {
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
    
    func mailMediaItem(mediaItem:MediaItem?,stringFunction:((MediaItem?)->String?)?)
    {
        guard MFMailComposeViewController.canSendMail() else {
            self.showSendMailErrorAlert()
            return
        }
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self as? MFMailComposeViewControllerDelegate // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ONE_SUBJECT)
        
        if let bodyString = stringFunction?(mediaItem) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            Thread.onMainThread {
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func presentHTMLModal(dismiss:Bool = false, mediaItem:MediaItem?, style: UIModalPresentationStyle, title: String?, htmlString: String?)
    {
        guard let htmlString = htmlString else {
            return
        }
        
        guard let storyboard = self.storyboard else {
            return
        }
        
        guard let navigationController = storyboard.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController else {
            return
        }
        
        guard let popover = navigationController.viewControllers[0] as? WebViewController else {
            return
        }
        
        if dismiss {
            Thread.onMainThread {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        navigationController.modalPresentationStyle = style
        
        navigationController.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
        
        popover.navigationItem.title = title

        popover.search = true
        popover.mediaItem = mediaItem
        
        popover.html.string = htmlString
        popover.content = .html
        
        popover.navigationController?.isNavigationBarHidden = false
        
        Thread.onMainThread {
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func showSendMailErrorAlert()
    {
        self.alert(title: "Could Not Send Email",message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",completion:nil)
    }

    var preferredModalPresentationStyle : UIModalPresentationStyle
    {
        let vClass = self.traitCollection.verticalSizeClass
        
        if vClass == .compact {
            return .overFullScreen
        }
        
        let hClass = self.traitCollection.horizontalSizeClass
        
        if (hClass == .compact) {
            return .overCurrentContext
        }
        
        return .formSheet
    }
    
    func popoverHTML(title:String?, mediaItem:MediaItem? = nil, bodyHTML:String? = nil, headerHTML:String? = nil, barButtonItem:UIBarButtonItem? = nil, sourceView:UIView? = nil, sourceRectView:UIView? = nil, htmlString:String? = nil, search:Bool)
    {
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "functions:popoverHTML", completion: nil)
            return
        }
        
        guard let storyboard = self.storyboard else {
            return
        }
        
        if let navigationController = storyboard.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? WebViewController {
            navigationController.modalPresentationStyle = self.preferredModalPresentationStyle
            
            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                
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
                popover.html.original = htmlString.stripHead.insertHead(fontSize: popover.html.fontSize)
            }
            
            if htmlString != nil {
                popover.html.string = htmlString?.stripHead.insertHead(fontSize: popover.html.fontSize)
            } else
                
                if let bodyHTML = bodyHTML, let headerHTML = headerHTML {
                    let htmlString = "<!DOCTYPE html><html><body>" + headerHTML + bodyHTML + "</body></html>"
                    popover.html.string = htmlString.stripHead.insertHead(fontSize: popover.html.fontSize)
            }
            
            popover.search = search
            
            popover.mediaItem = mediaItem
            
            popover.bodyHTML = bodyHTML
            popover.headerHTML = headerHTML
            
            popover.content = .html
            
            popover.navigationController?.isNavigationBarHidden = false
            
            Thread.onMainThread {
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }

    func process(disableEnable:Bool = true, work:(((()->Bool)?)->(Any?))?, completion:((Any?,(()->Bool)?)->())?) // , hideSubviews:Bool = false
    {
        guard let cancelButton = self.loadingButton else {
            return
        }
        
        self.startAnimating()
        
//        guard let view = self.view else {
//            return
//        }
        
//        let operationQueue = OperationQueue()
//
//        operationQueue.name = UUID().uuidString // Assumes there is only one globally
//        operationQueue.qualityOfService = .background
//        operationQueue.maxConcurrentOperationCount = 1
//
//        let operation = CancelableOperation() { [weak self] (test:(()->Bool)?) in

        Thread.onMainThread {
            // Brute force disable
            if disableEnable {
                self.barButtonItems(isEnabled: false)
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                let data = work?({
                    return DispatchQueue.main.sync {
                        return cancelButton.tag == 1
                    }
                })
                
                Thread.onMainThread {
                    // Brute force enable => need to be set according to state in completion.
                    if disableEnable {
                        self?.barButtonItems(isEnabled: true)
                    }
                    
                    completion?(data) {
                        return cancelButton.tag == 1
                    }
                    
                    self?.stopAnimating()
                }
            }
        }

//        let monitorOperation = CancelableOperation() { [weak self] (test:(()->Bool)?) in
//            while operation.isExecuting {
//                Thread.sleep(forTimeInterval: 1.0)
//            }
//        }
//
//        monitorOperation.addDependency(operation)

//        operationQueue.addOperation(operation)
        
//        operationQueue.addOperation(monitorOperation)
    }
    
    func barButtonItems(isEnabled:Bool)
    {
        Thread.onMainThread {
            if let buttons = self.navigationItem.rightBarButtonItems {
                for button in buttons {
                    button.isEnabled = isEnabled
                }
            }
            
            if let buttons = self.navigationItem.leftBarButtonItems {
                for button in buttons {
                    button.isEnabled = isEnabled
                }
            }
            
            if let buttons = self.toolbarItems {
                for button in buttons {
                    button.isEnabled = isEnabled
                }
            }
        }
    }
    
    func process(disableEnable:Bool = true,work:(()->(Any?))?,completion:((Any?)->())?) // ,hideSubviews:Bool = false
    {
        guard (work != nil) && (completion != nil) else {
            return
        }
        
//        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
//            return
//        }
        
//        guard let container = self.loadingContainer else {
//            return
//        }

        self.startAnimating()
        
//        guard let view = self.view else {
//            return
//        }

        Thread.onMainThread { [weak self] in
            // Brute force disable
            if disableEnable {
                self?.barButtonItems(isEnabled: false)
//                if let buttons = self.navigationItem.rightBarButtonItems {
//                    for button in buttons {
//                        button.isEnabled = false
//                    }
//                }
//
//                if let buttons = self.navigationItem.leftBarButtonItems {
//                    for button in buttons {
//                        button.isEnabled = false
//                    }
//                }
//
//                if let buttons = self.toolbarItems {
//                    for button in buttons {
//                        button.isEnabled = false
//                    }
//                }
            }
            
//            container.frame = view.frame
//            container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
//
//            container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            
//            if hideSubviews {
//                for view in container.subviews {
//                    view.isHidden = true
//                }
//            }
            
//            view.addSubview(container)
            
            // Should be an OperationQueue and work should be a CancelableOperation
            DispatchQueue.global(qos: .background).async { [weak self] in
                let data = work?()
                
                Thread.onMainThread {
                    // Brute force enable => need to be set according to state in completion.
                    if disableEnable {
                        self?.barButtonItems(isEnabled: true)

//                        if let buttons = self.navigationItem.rightBarButtonItems {
//                            for button in buttons {
//                                button.isEnabled = true
//                            }
//                        }
//
//                        if let buttons = self.navigationItem.leftBarButtonItems {
//                            for button in buttons {
//                                button.isEnabled = true
//                            }
//                        }
//
//                        if let buttons = self.toolbarItems {
//                            for button in buttons {
//                                button.isEnabled = true
//                            }
//                        }
                    }
                    
                    completion?(data)

                    self?.stopAnimating()
                    
//                    if container.superview != nil { //  != viewController.view
//                        container.removeFromSuperview()
//                    }
                }
            }
        }
    }
    
    func networkUnavailable(_ message:String?)
    {
        self.alert(title:Constants.Network_Error,message:message,completion:nil)
    }
    
    func alert(title:String?,message:String?,completion:(()->(Void))?)
    {
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
            return
        }
        
        let alert = UIAlertController(title:title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.makeOpaque()
        
        let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
            completion?()
        })
        alert.addAction(action)
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func alert(title:String?,message:String?,actions:[AlertAction]?)
    {
        guard Thread.isMainThread else {
            print("Not Main Thread","functions:alert")
            return
        }
        
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
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
            let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
        }
        
        Thread.onMainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func selectWord(title:String?, purpose:PopoverPurpose, allowsSelection:Bool = true,strings:[String]? = nil, stringsFunction:(()->([String]?))? = nil, completion:((PopoverTableViewController)->())? = nil)
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
            
            popover.navigationController?.isNavigationBarHidden = false
            
            popover.navigationItem.title = title // navigationItem.title
            
            popover.delegate = self as? PopoverTableViewControllerDelegate
            popover.purpose = purpose
            
            popover.segments = true
            
            popover.section.function = { (method:String?,strings:[String]?) in
                return strings?.sort(method: method)
            }
            popover.section.method = Constants.Sort.Alphabetical
            
            popover.bottomBarButton = true
            
            popover.allowsSelection = allowsSelection
            
            var segmentActions = [SegmentAction]()
            
            segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self, weak popover] in
                guard let popover = popover else {
                    return
                }
                
                let strings = popover.section.function?(Constants.Sort.Alphabetical,popover.section.strings)
                
                if popover.segmentedControl.selectedSegmentIndex == 0 {
                    popover.section.method = Constants.Sort.Alphabetical
                    
                    popover.section.showHeaders = false
                    popover.section.showIndex = true
                    
                    popover.section.indexStringsTransform = nil
                    popover.section.indexHeadersTransform = nil
                    popover.section.indexSort = nil
                    
                    popover.section.sorting = true
                    popover.section.strings = strings
                    popover.section.sorting = false
                    
                    popover.section.stringsAction?(strings, popover.section.sorting)
                    
                    popover.tableView?.reloadData()
                }
            }))
            
            segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self, weak popover] in
                guard let popover = popover else {
                    return
                }
                
                let strings = popover.section.function?(Constants.Sort.Frequency,popover.section.strings)
                
                if popover.segmentedControl.selectedSegmentIndex == 1 {
                    popover.section.method = Constants.Sort.Frequency
                    
                    popover.section.showHeaders = false
                    popover.section.showIndex = true
                    
                    popover.section.indexStringsTransform = { (string:String?) -> String? in
                        return string?.log
                    }
                    
                    popover.section.indexHeadersTransform = { (string:String?) -> String? in
                        return string
                    }
                    
                    popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) > Int(second)
                    }
                    
                    popover.section.sorting = true
                    popover.section.strings = strings
                    popover.section.sorting = false
                    
                    popover.section.stringsAction?(strings, popover.section.sorting)
                    
                    popover.tableView?.reloadData()
                }
            }))
            
            segmentActions.append(SegmentAction(title: Constants.Sort.Length, position: 2, action: { [weak self, weak popover] in
                guard let popover = popover else {
                    return
                }
                
                let strings = popover.section.function?(Constants.Sort.Length,popover.section.strings)
                
                if popover.segmentedControl.selectedSegmentIndex == 2 {
                    popover.section.method = Constants.Sort.Length
                    
                    popover.section.showHeaders = false
                    popover.section.showIndex = true
                    
                    popover.section.indexStringsTransform = { (string:String?) -> String? in
                        return string?.components(separatedBy: Constants.SINGLE_SPACE).first?.count.description
                    }
                    
                    popover.section.indexHeadersTransform = { (string:String?) -> String? in
                        return string
                    }
                    
                    popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) > Int(second)
                    }
                    
                    popover.section.sorting = true
                    popover.section.strings = strings
                    popover.section.sorting = false
                    
                    popover.section.stringsAction?(strings, popover.section.sorting)
                    
                    popover.tableView?.reloadData()
                }
            }))
            
            popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
            
            popover.section.showIndex = true
            
            popover.search = true
            
            popover.section.strings = strings
            popover.stringsFunction = stringsFunction

            (self as? PopoverTableViewControllerDelegate)?.popover?["WORD"] = popover
            
            popover.completion = { [weak self] in
                (self as? PopoverTableViewControllerDelegate)?.popover?["WORD"] = nil
            }
            
            completion?(popover)
            
            present(navigationController, animated: true, completion: nil)
        }

    }
}

extension UIAlertController
{
    func makeOpaque()
    {
        if  let subView = view.subviews.first,
            let alertContentView = subView.subviews.first {
            alertContentView.backgroundColor = UIColor.white
            alertContentView.layer.cornerRadius = 10
            alertContentView.layer.masksToBounds = true
        }
    }
}

extension UIColor
{
    // MARK: UIColor extension
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    static func controlBlue() -> UIColor
    {
        return UIColor(red: 14, green: 122, blue: 254)
    }
}

extension Int
{
    var formatted : String
    {
        get {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: self as NSNumber) ?? self.description
        }
    }
}

extension Double
{
    var secondsToHMS : String?
    {
        get {
            guard !self.isNaN, !self.isInfinite else {
                return nil
            }
            
            let hours = max(Int(self / (60*60)),0)
            let mins = max(Int((self - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(self.truncatingRemainder(dividingBy: 60)),0)
            
            var string:String
            
            if (hours > 0) {
                string = "\(String(format: "%d",hours)):"
            } else {
                string = Constants.EMPTY_STRING
            }

            string += "\(String(format: "%02d",mins)):\(String(format: "%02d",sec))"
            
            return string
        }
    }

    var secondsToHMSms : String?
    {
        get {
            guard !self.isNaN, !self.isInfinite else {
                return nil
            }
            
            let hours = max(Int(self / (60*60)),0)
            let mins = max(Int((self - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(self.truncatingRemainder(dividingBy: 60)),0)
            let fraction = self - Double(Int(self))
            
            var string:String
            
            if (hours > 0) {
                string = "\(String(format: "%02d",hours)):"
            } else {
                string = "00:"
            }
            
            string += "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
            
            return string
        }
    }
}

extension String
{
    var singleLine : String
    {
        get {
            return self.replacingOccurrences(of: "\n", with: ", ").trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
        }
    }
    
    var asTag : String
    {
        get {
            return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? self
            
//            var string = String()
//
//            for char in self {
//                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet.alphanumerics.contains(unicodeScalar) { // !CharacterSet(charactersIn:
//                    string.append(char)
//                }
//            }
//
//            return string
        }
    }
        
    var withoutPrefixes : String
    {
        get {
            if let range = self.range(of: "A is "), range.lowerBound == "a".startIndex {
                return self
            }
            
            let sourceString = self.replacingOccurrences(of: Constants.DOUBLE_QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
            
            let prefixes = ["A ","An ","The "] // "And ",
            
            var sortString = sourceString
            
            for prefix in prefixes {
                if (sourceString.endIndex >= prefix.endIndex) && (String(sourceString[..<prefix.endIndex]).lowercased() == prefix.lowercased()) {
                    sortString = String(sourceString[prefix.endIndex...])
                    break
                }
            }
            
            return sortString
        }
    }
    
    var hmsToSeconds : Double?
    {
        get {
            guard self.range(of: ":") != nil else {
                return nil
            }
            
            var str = self.replacingOccurrences(of: ",", with: ".")
            
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
            
            return seconds
        }
    }

    var secondsToHMS : String?
    {
        get {
            guard let timeNow = Double(self) else {
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
                hms = "00:"
            }
            
            hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
            
            return hms
        }
    }
}

extension UIApplication
{
    func isRunningInFullScreen() -> Bool
    {
        if let w = self.keyWindow
        {
            let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let minScreenSize = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            
            let maxAppSize = max(w.bounds.size.width, w.bounds.size.height)
            let minAppSize = min(w.bounds.size.width, w.bounds.size.height)
            
            return maxScreenSize == maxAppSize && minScreenSize == minAppSize
        }
        
        return true
    }
}

extension UIBarButtonItem
{
    func setTitleTextAttributes(_ attributes:[NSAttributedString.Key:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControl.State.normal)
        setTitleTextAttributes(attributes, for: UIControl.State.disabled)
        setTitleTextAttributes(attributes, for: UIControl.State.highlighted)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UISegmentedControl
{
    func setTitleTextAttributes(_ attributes:[NSAttributedString.Key:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControl.State.normal)
        setTitleTextAttributes(attributes, for: UIControl.State.disabled)
        setTitleTextAttributes(attributes, for: UIControl.State.highlighted)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UIButton
{
    func setTitle(_ string:String? = nil)
    {
        setTitle(string, for: UIControl.State.normal)
        setTitle(string, for: UIControl.State.disabled)
        setTitle(string, for: UIControl.State.highlighted)
//        setTitle(string, for: UIControlState.selected)
    }
}

extension Thread
{
    static func onMainThread(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async {
                block?()
            }
        }
    }

    static func onMainThreadSync(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.sync {
                block?()
            }
        }
    }
}

extension UIViewController
{
    func setDVCLeftBarButton()
    {
        // MUST be called from the detail view ONLY
        guard let isCollapsed = splitViewController?.isCollapsed else {
            return
        }

        if isCollapsed {
            navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.navigationController?.navigationItem.backBarButtonItem
        } else {
            navigationController?.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem            
        }
    }

//    var loadingViewController:UIViewController?
//    {
//        if let loadingView = storyboard?.instantiateViewController(withIdentifier: "Loading View Controller").view {
//            self.view.addSubview(loadingView)
//        }
//    }
    
    var loadingContainer:UIView?
    {
        get {
            guard let loadingContainer = view.subviews.filter({ (view:UIView) in
                return view.tag > 100
            }).first else {
                if let loadingContainer = storyboard?.instantiateViewController(withIdentifier: "Loading View Controller").view {
                    loadingContainer.tag = 101

                    loadingContainer.frame = self.view.frame
                    loadingContainer.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
                    
                    loadingContainer.backgroundColor = UIColor.white.withAlphaComponent(0.5)
                    
                    self.view.addSubview(loadingContainer)

//                    loadingView?.isUserInteractionEnabled = false
//                    loadingActivity?.isUserInteractionEnabled = false

                    return loadingContainer
                }
                
                return nil
            }
            
            return loadingContainer
        }
    }
    
    var loadingView:UIView?
    {
        get {
            return loadingContainer?.subviews[0]
        }
    }
    
    @objc func cancelWork(_ sender:UIButton)
    {
        if sender.tag == 0 {
            sender.tag = 1
        }
    }
    
    var loadingButton:UIButton?
    {
        get {
            guard let button = loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UIButton) != nil
            }).first as? UIButton else {
                return nil
            }

            button.isHidden = false
            self.loadingContainer?.tag = 102
//            button.tag = 0
            
            button.addTarget(self, action: #selector(cancelWork(_:)), for: .touchUpInside)
            
            return button
        }
    }
    
    var loadingLabel:UILabel?
    {
        get {
            return loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UILabel) != nil
            }).first as? UILabel
        }
    }
    
    var loadingActivity:UIActivityIndicatorView?
    {
        get {
            return loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UIActivityIndicatorView) != nil
            }).first as? UIActivityIndicatorView
        }
    }
    
    func stopAnimating()
    {
//        guard loadingContainer != nil else {
//            return
//        }
//
//        guard loadingView != nil else {
//            return
//        }
//
//        guard loadingActivity != nil else {
//            return
//        }
        
        Thread.onMainThread {
//            self.loadingActivity?.stopAnimating()
//            self.loadingView?.isHidden = true
//            self.loadingContainer?.isHidden = true
            self.loadingContainer?.removeFromSuperview()
        }
    }
    
    func startAnimating(allowTouches:Bool = false)
    {
//        setupLoadingView()
        
        //        if container == nil { // loadingView
        //            setupLoadingView()
        //        }
        
//        guard loadingContainer != nil else {
//            return
//        }
//        
//        guard loadingView != nil else {
//            return
//        }
//        
//        guard loadingActivity != nil else {
//            return
//        }
        
        Thread.onMainThread {
            if allowTouches {
                self.loadingContainer?.backgroundColor = UIColor.clear
                self.loadingContainer?.tag = 102
//                self.loadingContainer?.isUserInteractionEnabled = false
            }
            
            self.loadingContainer?.isHidden = false
            self.loadingView?.isHidden = false
            self.loadingActivity?.startAnimating()
        }
    }
    
//    func setupLoadingView()
//    {
//        guard let loadingContainer = loadingContainer, !view.subviews.contains(loadingContainer) else {
//            return
//        }
//
//        //        guard (loadingView == nil) else {
//        //            return
//        //        }
//
//        //        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
//        //            return
//        //        }
//
//        //        if let view = Globals.shared.loadingViewController?.view {
//        //            container = view
//        //        }
//
//        loadingContainer.backgroundColor = UIColor.clear
//
//        loadingContainer.frame = view.frame
//        loadingContainer.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
//
//        loadingContainer.isUserInteractionEnabled = false
//
//        //        loadingView = loadingViewController.view.subviews[0]
//
//        loadingView?.isUserInteractionEnabled = false
//
//        //        if let view = loadingView.subviews[0] as? UIActivityIndicatorView {
//        //            actInd = view
//        //        }
//
//        loadingActivity?.isUserInteractionEnabled = false
//
//        view.addSubview(loadingContainer)
//    }
}

extension NSLayoutConstraint
{
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

extension UITextView
{
    func scrollRangeToVisible(_ range:Range<String.Index>)
    {
        Thread.onMainThread {
            let nsRange = NSRange(range, in: self.attributedText.string)
            self.scrollRangeToVisible(nsRange)
        }
    }
}

extension String
{
    func highlighted(_ searchText:String?) -> NSAttributedString
    {
        guard let searchText = searchText else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.body)
        }
        
        let attributedText = NSMutableAttributedString(string: self, attributes: Constants.Fonts.Attributes.body)
        
        let range = NSRange(location: 0, length: self.utf16.count)
        
        if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
            regex.matches(in: self, options: .withTransparentBounds, range: range).forEach {
                attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                             range: $0.range)
            }
        }
        
        return attributedText

//        guard let range = self.lowercased().range(of: searchText.lowercased()) else {
//            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.body)
//        }
//
//        let highlightedString = NSMutableAttributedString()
//
//        let before = String(self[..<range.lowerBound])
//        let string = String(self[range])
//        let after = String(self[range.upperBound...])
//
//        highlightedString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
//        highlightedString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
//        highlightedString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
//
//        return highlightedString
    }
    
    func boldHighlighted(_ searchText:String?) -> NSAttributedString
    {
        guard let searchText = searchText else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.bold)
        }
        
        let attributedText = NSMutableAttributedString(string: self, attributes: Constants.Fonts.Attributes.bold)
        
        let range = NSRange(location: 0, length: self.utf16.count)

        if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
            regex.matches(in: self, options: .withTransparentBounds, range: range).forEach {
                attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                             range: $0.range)
            }
        }

        return attributedText

//
//        guard let range = self.lowercased().range(of: searchText.lowercased()) else {
//            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.bold)
//        }
//
//        let highlightedString = NSMutableAttributedString()
//
//        let before = String(self[..<range.lowerBound])
//        let string = String(self[range])
//        let after = String(self[range.upperBound...])
//
//        highlightedString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.bold))
//        highlightedString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.boldHighlighted))
//        highlightedString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.bold))
//
//        return highlightedString
    }
}

extension String
{
    var bookNumberInBible : Int
    {
//        guard let book = book else {
//            return nil
//        }
        
        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: self) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: self) {
            return Constants.OLD_TESTAMENT_BOOKS.count + index
        }
        
        return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
    }

//    var books : [String]?
//    {
//        get {
//            return booksFromScriptureReference(self)
//        }
//    }
    
    func range(_ book:String) -> Range<String.Index>?
    {
        var bookRange : Range<String.Index>?
        
        var bk = book
        
        repeat {
            if let range = self.lowercased().range(of: bk.lowercased()) {
                bookRange = range
                break
            } else {
                bk.removeLast()
                if bk.last == " " {
                    break
                }
            }
        } while bk.count > 2
        
        return bookRange
    }
}

extension String
{
    var lastName : String?
    {
        guard let firstName = self.firstName else {
            return nil
        }
        
        if let range = self.range(firstName) {
            return String(self[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            return nil
        }
    }
    
    var century : String?
    {
        guard let string = self.components(separatedBy: "\n").first else {
            return nil
        }
        
        if let number = Int(string) {
            let value = number/100 * 100
            return "\(value == 0 ? 1 : value)"
        }
        
        return nil
    }
    
    var log : String?
    {
        let strings = self.components(separatedBy: " ")
        
        guard strings.count > 1 else {
            return nil
        }
        
        let string = strings[1].trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        
        if let number = Double(string) {
            let value = Int(log10(number))
            return pow(10,value+1).description
        }
        
        return nil
    }
    
    var firstName : String?
    {
//        guard let name = name else {
//            return nil
//        }
        
        var firstName:String?
        
        var string:String?
        
        if let title = self.title {
            string = String(self[title.endIndex...])
        } else {
            string = self
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
    
    var title : String?
    {
//        guard let name = name else {
//            return nil
//        }
        
        var title = Constants.EMPTY_STRING
        
        if self.range(of: ". ") != nil {
            for char in self {
                title.append(char)
                if String(char) == "." {
                    break
                }
            }
        }
        
        return title != Constants.EMPTY_STRING ? title : nil
    }
}

extension String
{
    func snip(_ start:String,_ stop:String) -> String
    {
        var bodyString = self
        
        while bodyString.range(of: start) != nil {
            if let startRange = bodyString.range(of: start) {
                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: stop) {
                    let to = String(bodyString[..<startRange.lowerBound])
                    
//                    let snippet = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
//                    print(snippet)
                    
//                    bodyString = to + String(bodyString[(to + from).endIndex...])
                    
                    let from = String(String(bodyString[startRange.lowerBound...])[endRange.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
        
        return bodyString
    }

    func snipLinks(_ start:String,_ stop:String) -> String
    {
        var bodyString = self
        
        while bodyString.range(of: start) != nil {
            if let startRange = bodyString.range(of: start) {
                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: stop) {
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
    
    var stripLinks : String
    {
//        guard let string = string else {
//            return nil
//        }
        
        var bodyString = self
        
        bodyString = bodyString.snipLinks("<div>Locations","</div>")
//        while bodyString.range(of: "<div>Locations") != nil {
//            if let startRange = bodyString.range(of: "<div>Locations") {
//                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</div>") {
//                    let to = String(bodyString[..<startRange.lowerBound])
//
//                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
//
//                    let string = to + from
//
//                    if let range = string.range(of: string) {
//                        let from = String(bodyString[range.upperBound...])
//
//                        bodyString = to + from
//                    }
//                }
//            }
//        }
        
        bodyString = bodyString.replacingOccurrences(of: "<a href=\"#index\">Index</a><br/>", with: "")
        
        bodyString = bodyString.snipLinks("<a",">")
//        while bodyString.range(of: "<a") != nil {
//            if let startRange = bodyString.range(of: "<a") {
//                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
//                    let to = String(bodyString[..<startRange.lowerBound])
//
//                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
//
//                    let string = to + from
//
//                    if let range = string.range(of: string) {
//                        let from = String(bodyString[range.upperBound...])
//
//                        bodyString = to + from
//                    }
//                }
//            }
//        }
        
        bodyString = bodyString.replacingOccurrences(of: "</a>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "(Return to Top)", with: "")
        
        return bodyString
    }
    
    var stripHTML : String
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        //        guard var bodyString = self.stripHead.stripLinks else {
        //            return nil
        //        }
        
        var bodyString = self.stripHead.stripLinks
        
        bodyString = bodyString.replacingOccurrences(of: "<!DOCTYPE html>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "<html>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "<body>", with: "")
        
        bodyString = bodyString.snip("<p class=\"copyright\">","</p>")
        
        //        while bodyString.range(of: "<p class=\"copyright\">") != nil {
        //            if let startRange = bodyString.range(of: "<p class=\"copyright\">") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</p>") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<script>","</script>")
        
        //        while bodyString.range(of: "<script>") != nil {
        //            if let startRange = bodyString.range(of: "<script>") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</script>") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<noscript>","</noscript>")
        
        //        while bodyString.range(of: "<noscript>") != nil {
        //            if let startRange = bodyString.range(of: "<noscript>") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</noscript>") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<p ",">")
        
        //        while bodyString.range(of: "<p ") != nil {
        //            if let startRange = bodyString.range(of: "<p ") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + "\n\n" + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<br ",">")
        
        //        while bodyString.range(of: "<br ") != nil {
        //            if let startRange = bodyString.range(of: "<br ") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<span ",">")
        
        //        while bodyString.range(of: "<span ") != nil {
        //            if let startRange = bodyString.range(of: "<span ") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<font ",">")
        
        //        while bodyString.range(of: "<font") != nil {
        //            if let startRange = bodyString.range(of: "<font") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<sup>","</sup>")
        
        //        while bodyString.range(of: "<sup>") != nil {
        //            if let startRange = bodyString.range(of: "<sup>") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: "</sup>") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    bodyString = to + String(bodyString[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<sup ", "</sup>")
        
        //        while string.range(of: "<sup ") != nil {
        //            if let startRange = string.range(of: "<sup ") {
        //                if let endRange = String(string[startRange.lowerBound...]).range(of: "</sup>") {
        //                    let to = String(string[..<startRange.lowerBound])
        //                    let from = String(String(string[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    string = to + String(string[(to + from).endIndex...])
        //                }
        //            }
        //        }
        
        bodyString = bodyString.snip("<h3", "</h3>")
        
        
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
        
        bodyString = bodyString.snipLinks("<td",">")
        //        while bodyString.range(of: "<td") != nil {
        //            if let startRange = bodyString.range(of: "<td") {
        //                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: ">") {
        //                    let to = String(bodyString[..<startRange.lowerBound])
        //                    let from = String(String(bodyString[startRange.lowerBound...])[..<endRange.upperBound])
        //
        //                    let string = to + from
        //                    if let range = string.range(of: string) {
        //                        let from = String(bodyString[range.upperBound...])
        //
        //                        bodyString = to + from
        //                    }
        //                }
        //            }
        //        }
        
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
        
        bodyString = bodyString.replacingOccurrences(of: "<p>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "</p>", with: "\n\n")
        
        bodyString = bodyString.replacingOccurrences(of: "<p/>", with: "\n\n")
        
        bodyString = bodyString.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        
        bodyString = bodyString.replacingOccurrences(of: "• ", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "–", with: "-")
        
        bodyString = bodyString.replacingOccurrences(of: "—", with: "-")
        
        bodyString = bodyString.replacingOccurrences(of: "…", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "<b>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "</b>", with: "")
        
        return bodyString.trimmingCharacters(in: CharacterSet(charactersIn: Constants.SINGLE_SPACE)) // .insertHead(fontSize: Constants.FONT_SIZE)
    }
    
//    func stripHTML(_ test:(()->Bool)?) -> String
//    {
//        var bodyString = self.stripHead.stripLinks
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<!DOCTYPE html>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<html>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<body>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<p class=\"copyright\">","</p>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<script>","</script>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<noscript>","</noscript>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<p ",">")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<br ",">")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<span ",">")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<font ",">")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<sup>","</sup>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<sup ", "</sup>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snip("<h3", "</h3>")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&rsquo;", with: "'")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&rdquo;", with: "\"")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&lsquo;", with: "'")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&ldquo;", with: "\"")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&mdash;", with: "-")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&ndash;", with: "-")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&nbsp;", with: " ")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "&ccedil;", with: "C")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<br/>", with: "\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</br>", with: "\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<span>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<table>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<center>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<tr>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.snipLinks("<td",">")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</td>", with: Constants.SINGLE_SPACE)
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</tr>", with: "\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</table>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</center>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</span>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</font>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</body>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</html>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<em>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</em>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<div>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</div>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<mark>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</mark>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<i>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</i>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<p>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</p>", with: "\n\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<p/>", with: "\n\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "\n\n\n", with: "\n\n")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "• ", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "–", with: "-")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "—", with: "-")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "…", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "<b>", with: "")
//        
//        if test?() == true {
//            return bodyString
//        }
//        
//        bodyString = bodyString.replacingOccurrences(of: "</b>", with: "")
//        
//        return bodyString.trimmingCharacters(in: CharacterSet(charactersIn: Constants.SINGLE_SPACE)) // .insertHead(fontSize: Constants.FONT_SIZE)
//    }
    
    func markHTML(headerHTML:String?, searchText:String?, wholeWordsOnly:Bool, lemmas:Bool = false, index:Bool, test:(()->(Bool))? = nil) -> (String?,Int)
    {
        if let headerHTML = headerHTML {
            let markedHTML = self.markHTML(searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
            return (markedHTML.0?.replacingOccurrences(of: "<body>", with: "<body>"+headerHTML+"<br/>"),markedHTML.1)
        } else {
            return self.markHTML(searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
        }
    }

    func markHTML(searchText:String?, wholeWordsOnly:Bool, lemmas:Bool = false, index:Bool, test:(()->(Bool))? = nil) -> (String?,Int)
    {
        let html = self
        
        guard !html.stripHead.isEmpty else {
            return (nil,0)
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return (html,0)
        }
        
        var searchTexts = Set<String>()
        
        if lemmas {
            if #available(iOS 12.0, *) {
                if let lemmas = html.html2String?.nlLemmas {
                    for lemma in lemmas {
                        if lemma.1.lowercased() == searchText.lowercased() {
                            searchTexts.insert(lemma.0.lowercased())
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
                if let lemmas = html.html2String?.nsLemmas {
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
            
            guard wholeWordsOnly else {
                if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
                    let range = NSRange(location: 0, length: input.utf16.count)
                    
                    let matches = regex.matches(in: input, options: .withTransparentBounds, range: range).sorted(by: { (first:NSTextCheckingResult, second:NSTextCheckingResult) -> Bool in
                        return first.range.lowerBound > second.range.lowerBound
                    })
                    
                    markCounter += matches.count
                    
                    matches.forEach { result in
                        let foundString = "<mark>" + String(string[String.Index(utf16Offset: result.range.lowerBound, in: string)..<String.Index(utf16Offset: result.range.upperBound, in: string)]) + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                        string = String(string[..<String.Index(utf16Offset: result.range.lowerBound, in: string)]) + foundString + String(string[String.Index(utf16Offset: result.range.upperBound, in: string)...])
                        markCounter -= 1
                   }

                    markCounter += matches.count

                    return string
                }
                
                return ""
            }
            
            if let regex = try? NSRegularExpression(pattern: "\\b" + searchText + "\\b", options: .caseInsensitive) {
                let range = NSRange(location: 0, length: input.utf16.count)
                
                let matches = regex.matches(in: input, options: .withTransparentBounds, range: range).sorted(by: { (first:NSTextCheckingResult, second:NSTextCheckingResult) -> Bool in
                    return first.range.lowerBound > second.range.lowerBound
                })
                
                markCounter += matches.count
                
                matches.forEach { result in
                    let foundString = "<mark>" + String(string[String.Index(utf16Offset: result.range.lowerBound, in: string)..<String.Index(utf16Offset: result.range.upperBound, in: string)]) + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                    string = String(string[..<String.Index(utf16Offset: result.range.lowerBound, in: string)]) + foundString + String(string[String.Index(utf16Offset: result.range.upperBound, in: string)...])
                    markCounter -= 1
                }
                
                markCounter += matches.count
                
                return string
            }
            
            return ""
            
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
                
                newString += stringBefore + foundString
                
                stringBefore += foundString
                
                string = stringAfter
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }
        
        searchTexts.insert(searchText.lowercased())
        
        var newString = Constants.EMPTY_STRING
        var string:String = html // ?? Constants.EMPTY_STRING
        
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
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)\(wholeWordsOnly ? "<br/>(whole words only)" : "")" //
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.\(wholeWordsOnly ? "<br/>(whole words only)" : "")<br/><br/>" // <br/> needed since markCounter == 0 so the below div isn't added.
        }
        
        // If we want an index of links to the occurrences of the searchText.
        if index {
            if markCounter > 0 {
                indexString += "<div>Locations: "
                
                for counter in 1...markCounter {
                    if counter > 1 {
                        indexString += ", "
                    }
                    indexString += "<a href=\"#\(counter)\">\(counter)</a>"
                }
                
                indexString += "</div><br/>" // <br/>
            }
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if index {
            htmlString += indexString
        }
        
        htmlString += string + "</body></html>"
        
        return (htmlString.insertHead(fontSize: Constants.FONT_SIZE),markCounter)
    }
}

extension String
{
    var tokensCounts : [(String,Int)]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }
        
//        guard let string = string else {
//            return nil
//        }
        
        var tokenCounts = [(String,Int)]()
        
        if let tokens = self.tokens {
            for token in tokens {
                var count = 0
                var string = self
                
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
    
    // Make thread safe?
    var tokensAndCounts : [String:Int]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }
        
        if #available(iOS 12.0, *) {
            return nlTaggerTokensAndCounts
        } else {
            return nsTaggerTokensAndCounts
        }
        
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [String:Int]()
        
        var str = self // .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) //.replacingOccurrences(of: "\r\n", with: " ")
        
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
    
//    var tokensAndCounts : [String:Int]?
//    {
//        get {
//            return tokensAndCountsFromString(self) // tokensAndCountsFromString // tokensAndCountsInString uses NSLinguisticTagger but that doesn't do contractions
//        }
//    }

    var tokens : [String]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }
        
//        guard let string = string else {
//            return nil
//        }
        
        if #available(iOS 12.0, *) {
            return nlTaggerTokens
        } else {
            return nsTaggerTokens
        }

        var tokens = Set<String>()
        
        var str = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\r\n", with: " ")
        
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
}

extension String
{
    func isFileType(_ fileType:String) -> Bool
    {
        let file = self
        
        if let range = file.range(of: fileType), file[range.lowerBound...] == fileType {
            return true
        } else {
            return false
        }
    }
    
    var url : URL?
    {
        get {
            return URL(string: self)
        }
    }
    
    var fileSystemURL : URL?
    {
        get {
            guard !self.isEmpty else {
                return nil
                
            }
            
            guard url != nil, self != url?.lastPathComponent else {
                if let lastPathComponent = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) {
                    return FileManager.default.cachesURL?.appendingPathComponent(lastPathComponent)
                } else {
                    return nil
                }
            }
            
//            guard  else {
//                if let lastPathComponent = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) {
//                    return cachesURL?.appendingPathComponent(lastPathComponent)
//                } else {
//                    return nil
//                }
//            }
            
            return url?.fileSystemURL
        }
    }

    func save8(filename:String?)
    {
        guard let filename = filename else {
            return
        }
        
        guard let fileSystemURL = filename.fileSystemURL else {
            return
        }
        
        do {
            try self.data8?.write(to: fileSystemURL) // (using: String.Encoding.utf16)
            print("able to write string to the file system: \(fileSystemURL.lastPathComponent)")
        } catch let error {
            print("unable to write string to the file system: \(fileSystemURL.lastPathComponent)")
            NSLog(error.localizedDescription)
        }
    }
    
    func save16(filename:String?)
    {
        guard let filename = filename else {
            return
        }
        
        guard let fileSystemURL = filename.fileSystemURL else {
            return
        }
        
        do {
            try self.data16?.write(to: fileSystemURL) // (using: String.Encoding.utf16)
            print("able to write string to the file system: \(fileSystemURL.lastPathComponent)")
        } catch let error {
            print("unable to write string to the file system: \(fileSystemURL.lastPathComponent)")
            NSLog(error.localizedDescription)
        }
    }
    
    static func load16(filename:String?) -> String?
    {
        guard let filename = filename else {
            return nil
        }
        
        guard let fileSystemURL = filename.fileSystemURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
            print("able to read string from the file system: \(fileSystemURL.lastPathComponent)")
            return data.string16 // String(data: data, encoding: String.Encoding.utf16)
        } catch let error {
            print("unable to read string from the file system: \(fileSystemURL.lastPathComponent)")
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    static func load8(filename:String?) -> String?
    {
        guard let filename = filename else {
            return nil
        }
        
        guard let fileSystemURL = filename.fileSystemURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
            print("able to read string from the file system: \(fileSystemURL.lastPathComponent)")
            return data.string8 // String(data: data, encoding: String.Encoding.utf16)
        } catch let error {
            print("unable to read string from the file system: \(fileSystemURL.lastPathComponent)")
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    var data16 : Data?
    {
        get {
            return self.data(using: String.Encoding.utf16, allowLossyConversion: false)
        }
    }
    
    var data8 : Data?
    {
        get {
            return self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        }
    }
}

extension String
{
    var html2AttributedString: NSAttributedString?
    {
        return self.data16?.html2AttributedString // (using: String.Encoding.utf16)
    }
    
    var html2String: String?
    {
        return html2AttributedString?.string
    }
}

let colors = ["LimeGreen", "Red", "Aqua", "Silver", "Fuchsia", "GreenYellow", "Yellow", "Pink", "Gold", "LightBlue", "GoldenRod", "LightCoral", "DodgerBlue", "DarkTurquoise", "DarkCyan"]

//let colors = [
////"NAVY",
//"BLUE",
//"AQUA",
//"TEAL",
//"OLIVE",
//"GREEN",
//"LIME",
//"YELLOW",
//"ORANGE",
//"RED",
////"MAROON",
//"FUCHSIA",
//"PURPLE",
////"BLACK",
//"GRAY",
//"SILVER"
//]

extension String
{
//    var nsLemmas : [(String,String,NSRange)]?
//    {
//        get {
//            return nsLemmasInString(string: self)
//        }
//    }
//
//    var nsNameTypes : [(String,String,NSRange)]?
//    {
//        get {
//            return nsNameTypesInString(string: self)
//        }
//    }
//
//    var nsLexicalTypes : [(String,String,NSRange)]?
//    {
//        get {
//            return nsLexicalTypesInString(string: self)
//        }
//    }
//
//    var nsTokenTypes : [(String,String,NSRange)]?
//    {
//        get {
//            return nsTokenTypesInString(string: self)
//        }
//    }
//
//    var nsNameTypesAndLexicalClasses : [(String,String,NSRange)]?
//    {
//        get {
//            return nsNameTypesAndLexicalClassesInString(string: self)
//        }
//    }
    
//    @available(iOS 12.0, *)
//    var nlLemmas : [(String,String,Range<String.Index>)]?
//    {
//        get {
//            return nlLemmasInString(string: self)
//        }
//    }
//
//    @available(iOS 12.0, *)
//    var nlTokenTypes : [(String,String,Range<String.Index>)]?
//    {
//        get {
//            return nlTokenTypesInString(string: self)
//        }
//    }
    
    @available(iOS 12.0, *)
    var nlLemmas : [(String,String,Range<String.Index>)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        let tagger = NLTagger(tagSchemes: [.lemma])
        
        tagger.string = self
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        
        var tokens = [(String,String,Range<String.Index>)]()
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .lemma, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range])
            if let tag = tag?.rawValue {
                tokens.append((token,tag,range))
            }
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    @available(iOS 12.0, *)
    var nlTokenTypes : [(String,String,Range<String.Index>)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        let tagger = NLTagger(tagSchemes: [.tokenType])
        
        tagger.string = self
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        
        var tokens = [(String,String,Range<String.Index>)]()
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .tokenType, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range])
            if let tag = tag?.rawValue {
                tokens.append((token,tag,range))
            }
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    @available(iOS 12.0, *)
    var nlNameTypesAndLexicalClasses : [(String,String,Range<String.Index>)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        
        tagger.string = self
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
        
        var tokens = [(String,String,Range<String.Index>)]()
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range])
            if let tag = tag?.rawValue {
                tokens.append((token,tag,range))
            }
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }

//    @available(iOS 12.0, *)
//    var nlNameTypesAndLexicalClasses : [(String,String,Range<String.Index>)]?
//    {
//        get {
//            return nlNameTypesAndLexicalClassesInString(string: self)
//        }
//    }

    // Make thread safe?
    @available(iOS 12.0, *)
    var nlTaggerTokensAndCounts : [String:Int]?
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        var tokens = [String:Int]()
        
        let tagger = NLTagger(tagSchemes: [.tokenType])
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinContractions]
        
        tagger.string = self
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .tokenType, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range]).uppercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
            
            if let count = tokens[token] {
                tokens[token] = count + 1
            } else {
                tokens[token] = 1
            }
            
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    // Make thread safe?
    @available(iOS 12.0, *)
    var nlTaggerTokens : [String]?
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        var tokens = [String]()
        
        let tagger = NLTagger(tagSchemes: [.tokenType])
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinContractions]
        
        tagger.string = self
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .tokenType, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range]).uppercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))

            tokens.append(token)
            
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    // Make thread safe?
    var nsTaggerTokensAndCounts : [String:Int]?
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        var tokens = [String:Int]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther] //, .joinNames
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length) // string.utf16.count
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        tags.forEach() { (tag:String) in
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range).uppercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
                
                if let count = tokens[token] {
                    tokens[token] = count + 1
                } else {
                    tokens[token] = 1
                }
                
                // Why do we only want words and not numbers?
                //                if CharacterSet.letters.intersection(CharacterSet(charactersIn: token)) == CharacterSet(charactersIn: token) {
                //                }
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    // Make thread safe?
    var nsTaggerTokens : [String]?
    {
        //        guard let string = string else {
        //            return nil
        //        }
        
        var tokens = [String]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther] //, .joinNames
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length) // string.utf16.count
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        tags.forEach() { (tag:String) in
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range).uppercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))

                tokens.append(token)
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var nsLemmas : [(String,String,NSRange)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length) // string.utf16.count
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lemma.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        for tag in tags {
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range)
                tokens.append((token,tag,range))
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var nsNameTypes : [(String,String,NSRange)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length) // string.utf16.count
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameType.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        for tag in tags {
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range)
                tokens.append((token,tag,range))
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var nsLexicalTypes : [(String,String,NSRange)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length)
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.lexicalClass.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        for tag in tags {
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range)
                tokens.append((token,tag,range))
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var nsTokenTypes : [(String,String,NSRange)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length)
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.tokenType.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        for tag in tags {
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range)
                tokens.append((token,tag,range))
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var nsNameTypesAndLexicalClasses : [(String,String,NSRange)]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        let range = NSRange(location: 0, length: (self as NSString).length)
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: range, scheme: NSLinguisticTagScheme.nameTypeOrLexicalClass.rawValue, options: options, tokenRanges: &ranges)
        
        var index = 0
        for tag in tags {
            if let range = ranges?[index] as? NSRange {
                let token = (self as NSString).substring(with: range)
                tokens.append((token,tag,range))
            }
            index += 1
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    func nsNameAndLexicalTypesMarkup(annotated:Bool, test:(()->(Bool))? = nil) -> String?
    {
        guard test?() != true else {
            return nil
        }
        
        guard let nameAndLexicalTypes = self.nsNameTypesAndLexicalClasses else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        var types = Set<String>()
        
        for nameAndLexicalType in nameAndLexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            types.insert(nameAndLexicalType.1)
        }
        
        let lexicalTypes = Array(types).sorted()
        
        var lexicalTypeColors = [String:String]()
        
        var count = 0
        for lexicalType in lexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            lexicalTypeColors[lexicalType] = colors[count % colors.count]
            count += 1
        }
        
        for lexicalType in lexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            if let color = lexicalTypeColors[lexicalType] {
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(lexicalType)</td></tr>"
                htmlString += "</table>"
//                htmlString += "<mark style=\"background-color:\(color);\">\(lexicalType)</mark>"
                if lexicalType != lexicalTypes.last {
                    htmlString += " "
                }
            }
        }
        htmlString += "<br/><br/>"
        
        var text = self
        
        for nameAndLexicalType in nameAndLexicalTypes.reversed() {
            guard test?() != true else {
                return nil
            }
            
            let token = nameAndLexicalType.0
            let nameOrLexicalType = nameAndLexicalType.1
            let nsRange = nameAndLexicalType.2
            
            let startIndex = text.index(text.startIndex,offsetBy: nsRange.lowerBound)
            let endIndex = text.index(text.startIndex,offsetBy: nsRange.upperBound)
            
            let before = text[..<startIndex]
            let after = text[endIndex...]
            
            if let color = lexicalTypeColors[nameOrLexicalType] {
                var htmlString = String()

                let annotate = false

                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(token)</td></tr>"
                if annotate {
                    htmlString += "<tr><td style=\"font-size:75%;background-color:\(color)\">\(nameOrLexicalType)</td></tr>"
                }
                htmlString += "</table>"

                text = before + htmlString + after
                
                //  <sup>\(nameOrLexicalType)</sup>
//                text = before + "<mark style=\"background-color:\(color);\">\(token)</mark>" + after
            } else {
                text = before + "<mark>\(token)</mark>" + after
            }
        }
        
        htmlString += text.replacingOccurrences(of: "\n\n", with: "<br/><br/>")
        htmlString += "</body></html>"
        
        return htmlString.insertHead(fontSize:Constants.FONT_SIZE)
    }
    
    var nsNameAndLexicalTypesMarkup : String?
    {
        get {
            return nsNameAndLexicalTypesMarkup(annotated:false)
        }
    }
    
    @available(iOS 12.0, *)
    func nlNameAndLexicalTypesMarkup(annotated:Bool, test:(()->(Bool))? = nil) -> String?
    {
        guard test?() != true else {
            return nil
        }
        
        guard let nameAndLexicalTypes = self.nlNameTypesAndLexicalClasses else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        var types = Set<String>()
        
        for nameAndLexicalType in nameAndLexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            types.insert(nameAndLexicalType.1)
        }
        
        let lexicalTypes = Array(types).sorted()

        var lexicalTypeColors = [String:String]()
        
        var count = 0
        for lexicalType in lexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            lexicalTypeColors[lexicalType] = colors[count % colors.count]
            count += 1
        }
        
        guard lexicalTypes.count > 1 else {
            return nil
        }
        
//        htmlString += "<table>"
//        htmlString += "<tr>"
        for lexicalType in lexicalTypes {
//            htmlString += "<td>"
            
            guard test?() != true else {
                return nil
            }
            
            if let color = lexicalTypeColors[lexicalType] {
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(lexicalType)</td></tr>"
                htmlString += "</table>"
                //                    htmlString += "<mark style=\"background-color:\(color);\">\(lexicalType)</mark>"
                if lexicalType != lexicalTypes.last {
                    htmlString += " "
                }
            }
//            htmlString += "</td>"
        }
//        htmlString += "</tr>"
//        htmlString += "</table>"
        
        htmlString += "<br/><br/>"
        
        var text = ""
        
        var last = self.startIndex
        
        for nameAndLexicalType in nameAndLexicalTypes {
            guard test?() != true else {
                return nil
            }
            
            let token = nameAndLexicalType.0
            let nameOrLexicalType = nameAndLexicalType.1
            let range = nameAndLexicalType.2

            let before = self[last..<range.lowerBound]

            last = range.upperBound
            
//            let before = self[..<range.lowerBound]
//            let after = self[range.upperBound...]
            
            if let color = lexicalTypeColors[nameOrLexicalType] {
                var htmlString = String()
                
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(token)</td></tr>"
                if annotated {
                    htmlString += "<tr><td style=\"font-size:75%;background-color:\(color)\">\(nameOrLexicalType)</td></tr>"
                }
                htmlString += "</table>"
                
                text = text + before + htmlString
                
//                text = "\(before)\(htmlString)\(after)"
                
                //  <sup>\(nameOrLexicalType)</sup> style=\"background-color:\(color);\"
                //                    text = before + "<mark style=\"background-color:\(color);\">\(token)</mark>" + after
            } else {
//                text = "\(before)<mark>\(token)</mark>\(after)"
            }
        }
        
        text += self[last...]
        
        htmlString += text.replacingOccurrences(of: "\n\n", with: "<br/><br/>")
        htmlString += "</body></html>"
        
        return htmlString.insertHead(fontSize:Constants.FONT_SIZE)
    }
    
    @available(iOS 12.0, *)
    var nlNameAndLexicalTypesMarkup : String?
    {
        get {
            return nlNameAndLexicalTypesMarkup(annotated:false)
        }
    }
}

extension URLSession
{
    // Downside - .failure does NOT get to look at the http response
    func dataTask(with request: URLRequest, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask
    {
        return dataTask(with: request) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            
            result(.success((response, data)))
        }
    }
    
    // Downside - .failure does NOT get to look at the http response
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask
    {
        return dataTask(with: url) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            
            result(.success((response, data)))
        }
    }
    
    // Usage
//    let foo = URLSession.shared.dataTask(with: url) { (result) in
//        switch result {
//        case .success(let response, let data):
//            // Handle Data and Response
//            break
//        case .failure(let error):
//            // Handle Error
//            break
//        }
//    }
}

extension URL
{
    var isVBR : Bool
    {
        get {
            var audioFile = AudioFileID(bitPattern: 0)
            
            var result = OSStatus()
            
            result = AudioFileOpenURL(self as CFURL, .readPermission, kAudioFileMP3Type, &audioFile)

            var audioFormat = AudioStreamBasicDescription()
            
            var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            
            guard let audioFileID = audioFile else {
                return false
            }
            
            result = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &size, &audioFormat)
            
            var vbrSize = UInt32(MemoryLayout<AudioFormatPropertyID>.size) // UInt32(MemoryLayout<[AudioValueRange]>.size)

            // kAudioFormatProperty_FormatIsVBR
//            result = AudioFormatGetPropertyInfo(kAudioFormatProperty_AvailableEncodeBitRates, UInt32(MemoryLayout<AudioFormatID>.size), &audioFormat.mFormatID, &vbrSize);

            var vbrInfo = AudioFormatPropertyID(bitPattern: 0) // [AudioValueRange]()
            
//            vbrInfo.reserveCapacity(100)
//            vbrInfo.append(AudioValueRange())

            // UInt32(MemoryLayout<AudioFormatID>.size)
            // audioFormat.mFormatID
            result = AudioFormatGetProperty(kAudioFormatProperty_FormatIsVBR, size, &audioFormat, &vbrSize, &vbrInfo);
            
            return result == noErr ? vbrInfo != 0 : false //
            
//            OSStatus result = noErr;
//            UInt32 size;
//
//
//            AudioFileID audioFile;
//            AudioStreamBasicDescription audioFormat;
//            AudioFormatPropertyID vbrInfo;
//
//            // Open audio file.
//            let result = AudioFileOpenURL( (__bridge CFURLRef)originalURL, kAudioFileReadPermission, 0, &audioFile );
//            if( result != noErr )
//            {
//                NSLog( @"Error in AudioFileOpenURL: %d", (int)result );
//                return;
//            }
//
//            // Get data format
//            size = sizeof( audioFormat );
//            result = AudioFileGetProperty( audioFile, kAudioFilePropertyDataFormat, &size, &audioFormat );
//            if( result != noErr )
//            {
//                NSLog( @"Error in AudioFileGetProperty: %d", (int)result );
//                return;
//            }
//
//            // Get vbr info
//            size = sizeof( vbrInfo );
//            result = AudioFormatGetProperty( kAudioFormatProperty_FormatIsVBR, sizeof(audioFormat), &audioFormat, &size, &vbrInfo);
//
//            if( result != noErr )
//            {
//                NSLog( @"Error getting vbr info: %d", (int)result );
//                return;
//            }
//
//            NSLog(@"%@ is VBR: %d", originalURL.lastPathComponent, vbrInfo);
        }
    }

//    func files(ofType fileType:String) -> [String]?
//    {
//        //        guard let path = self.path else {
//        //            return nil
//        //        }
//
//        guard let isDirectory = try? FileWrapper(url: self, options: []).isDirectory, isDirectory else {
//            return nil
//        }
//
//        var files = [String]()
//
//        do {
//              // contentsOfDirectory is a MASSIVE MEMORY LEAK
//            let array = try FileManager.default.contentsOfDirectory(atPath: path)
//
//            for string in array {
//                //                if let range = string.range(of: fileType) {
//                if let range = string.range(of: "." + fileType) {
//                    if fileType == String(string[range.lowerBound...]) {
//                        files.append(string)
//                    }
//                }
//            }
//        } catch let error {
//            NSLog("failed to get files in caches directory: \(error.localizedDescription)")
//        }
//
//        return files.count > 0 ? files : nil
//    }
    
    func files(startingWith filename:String? = nil,ofType fileType:String? = nil,notOfType notFileType:String? = nil) -> [String]?
    {
//        guard let path = path else {
//            return nil
//        }
        
        ////////////////////////////////////////////////////////////////////
        // THIS CAN BE A HUGE MEMORY LEAK IF NOT USED IN AN AUTORELEASEPOOL
        ////////////////////////////////////////////////////////////////////

        guard (filename != nil) || (fileType != nil) || (notFileType != nil) else {
            return nil
        }
        
        if fileType != nil, notFileType != nil, fileType == notFileType {
            return nil
        }
        
        guard let isDirectory = try? FileWrapper(url: self, options: []).isDirectory, isDirectory else {
            return nil
        }

        var files = [String]()
        
        // contentsOfDirectory causes a massive memory leak
        // is this a typical problem when trying to use methods that throw in an extension?
//        let array = try? FileManager.default.contentsOfDirectory(atPath: path)

        // autoreleasepool helps but still a HUGE MEMORY LEAK
//        return autoreleasepool {
//            var files = [String]()
//
//            let path = self.path
//
//            let enumerator = FileManager.default.enumerator(atPath: path)
//
//            while let file = enumerator?.nextObject() as? FileWrapper {
//                if let name = file.filename, let range = name.range(of: filename) {
//                    if filename == String(name[..<range.upperBound]) {
//                        files.append(name)
//                    }
//                }
//            }
//
//            return files.count > 0 ? files : nil
//        }

        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: path)

            for string in array {
                var fileNameCandidate : String?
                var fileTypeCandidate : String?
                var notFileTypeCandidate : String?
                
                if let filename = filename, let range = string.range(of: filename) {
                    if filename == String(string[..<range.upperBound]) {
                        fileNameCandidate = string
                    }
                }
                
                if let fileType = fileType, let range = string.range(of: "." + fileType.trimmingCharacters(in: CharacterSet(charactersIn: "."))) {
                    if fileType == String(string[range.lowerBound...]) {
                        fileTypeCandidate = string
                    }
                }
                
                if let notFileType = notFileType, let range = string.range(of: "." + notFileType.trimmingCharacters(in: CharacterSet(charactersIn: "."))) {
                    if notFileType == String(string[range.lowerBound...]) {
                        notFileTypeCandidate = string
                    }
                }

                if filename == nil, notFileType != nil, notFileTypeCandidate == nil {
                    fileNameCandidate = string
                }
                
                if fileType == nil, notFileType != nil, notFileTypeCandidate == nil {
                    fileNameCandidate = string
                }
                
                if let fileNameCandidate = fileNameCandidate {
                    if let fileTypeCandidate = fileTypeCandidate {
                        if fileNameCandidate == fileTypeCandidate {
                            if notFileTypeCandidate == nil {
                                files.append(string)
                            }
                        }
                    } else {
                        if notFileTypeCandidate == nil {
                            files.append(string)
                        }
                    }
                } else {
                    if fileTypeCandidate != nil {
                        if notFileTypeCandidate == nil {
                            files.append(string)
                        }
                    }
                }
            }
        } catch let error {
//            NSLog("Error: \(error.localizedDescription)")
//            NSLog("Failed to get files in directory: \(self.path)")
            print("failed to get files in directory \(self.path): \(error.localizedDescription)") // remove
        }

        return files.count > 0 ? files : nil
    }
    
//    func delete(startingWith filename:String, block:Bool) -> [String]?
//    {
//        let files = self.files(startingWith:filename)
//        
//        files?.forEach({ (string:String) in
//            var fileURL = self
//            fileURL.appendPathComponent(string)
//            fileURL.delete(block: block)
//        })
//        
//        return files
//    }
    
//    func delete(startingWith filename:String) -> [String]?
//    {
////        guard let path = self.cachesURL?.path else {
////            return nil
////        }
//        
//        guard let isDirectory = try? FileWrapper(url: self, options: []).isDirectory, isDirectory else {
//            return nil
//        }
//        
//        var files = [String]()
//        
//        do {
//            let array = try FileManager.default.contentsOfDirectory(atPath: path)
//            
//            for string in array {
//                if let range = string.range(of: filename) {
//                    if filename == String(string[..<range.upperBound]) {
//                        files.append(string)
//                        
//                        var fileURL = path.url
//                        
//                        fileURL?.appendPathComponent(string, isDirectory: false)
//                        
//                        if let fileURL = fileURL {
//                            do {
//                                try FileManager.default.removeItem(at: fileURL)
//                            } catch let error {
//                                NSLog("failed to delete \(fileURL.lastPathComponent) error: \(error.localizedDescription)")
//                            }
//                        }
//                    }
//                }
//            }
//        } catch let error {
//            NSLog("failed to get files in caches directory: \(error.localizedDescription)")
//        }
//        
//        return files.count > 0 ? files : nil
//    }

    var fileSystemURL : URL?
    {
        return self.lastPathComponent.fileSystemURL
    }

    var fileSize:Int?
    {
        guard let fileSystemURL = fileSystemURL else {
            return nil
        }
        
        guard fileSystemURL.exists else {
            debug("File does not exist at \(fileSystemURL.absoluteString)")
            return 0
        }

        // Either of the following work
        
//        let fileAttributes = try? FileManager.default.attributesOfItem(atPath: fileSystemURL.path)
//
//        if let num = fileAttributes?[FileAttributeKey.size] as? Int {
//            return num
//        }

        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL.path)

            if let num = fileAttributes[FileAttributeKey.size] as? Int {
                return num
            }
        } catch let error {
//            debug("failed to get file attributes for \(fileSystemURL): \(error.localizedDescription)")
//            NSLog("Error: \(error.localizedDescription)")
//            NSLog("Failed to get file attributes for: \(fileSystemURL)")
            print("failed to get file attributes for \(fileSystemURL): \(error.localizedDescription)") // remove
        }
        
        return nil
    }
    
    var exists : Bool
    {
        get {
            if let fileSystemURL = fileSystemURL {
                return FileManager.default.fileExists(atPath: fileSystemURL.path)
            } else {
                return false
            }
        }
    }

    var copy : URL?
    {
        guard let fileSystemURL = self.fileSystemURL else {
            return nil
        }
        
//        fileSystemURL.delete()
        
        do {
            try FileManager.default.copyItem(at: self, to: fileSystemURL)
            return fileSystemURL
        } catch let error {
            print("failed to copy \(self.absoluteString): \(error.localizedDescription)") // remove
            return nil
        }
    }
    
    var string16 : String?
    {
        do {
            let string = try String(contentsOfFile: self.path, encoding: String.Encoding.utf16)
            return string
        } catch let error {
            print("failed to load string from \(self.absoluteString): \(error.localizedDescription)") // remove
            return nil
        }
    }
    
    var string8 : String?
    {
        do {
            let string = try String(contentsOfFile: self.path, encoding: String.Encoding.utf8)
            return string
        } catch let error {
            print("failed to load string from \(self.absoluteString): \(error.localizedDescription)") // remove
            return nil
        }
    }
    
    var data : Data?
    {
        get {
            // DO NOT DO THIS AS THE URL MAY POINT TO LOCAL STORAGE
//            guard Globals.shared.reachability.isReachable else {
//                return nil
//            }
            
            do {
                let data = try Data(contentsOf: self)
                debug("Data read from \(self.absoluteString)")
                return data
            } catch let error {
                NSLog(error.localizedDescription)
                print("Data not read from \(self.absoluteString)")
                return nil
            }
        }
    }
    
    @available(iOS 11.0, *)
    var pdf : PDFDocument?
    {
        get {
            guard let data = data else {
                return nil
            }
            
            return PDFDocument(data: data)
        }
    }
    
    func delete(block:Bool)
    {
        let op = {
            // Check if file exists and if so, delete it.
            
            guard let fileSystemURL = self.fileSystemURL else {
                print("fileSystemURL doesn't exist for: \(self.absoluteString)")
                return
            }
            
            guard fileSystemURL.exists else {
                print("item doesn't exist: \(self.absoluteString)")
                return
            }
            
            do {
                try FileManager.default.removeItem(at: fileSystemURL)
            } catch let error {
                print("failed to delete \(self.absoluteString): \(error.localizedDescription)")
            }
        }
        
        if block {
            op()
        } else {
            // As an extension, no way to put this in an OpQueue
            DispatchQueue.global(qos: .background).async {
                op()
            }
        }
    }
    
    func image(block:((UIImage)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    var image : UIImage?
    {
        get {
            guard let data = data else {
                return nil
            }
            
            return UIImage(data: data)
        }
    }
}

extension UIImage
{
    func save(to url: URL?) -> UIImage?
    {
        guard let url = url else {
            return nil
        }
        
        do {
            try self.jpegData(compressionQuality: 1.0)?.write(to: url, options: [.atomic])
            print("Image saved to \(url.absoluteString)")
        } catch let error {
            NSLog(error.localizedDescription)
            print("Image not saved to \(url.absoluteString)")
        }
        
        return self
    }
    
    func resize(scale:CGFloat) -> UIImage?
    {
        let toScaleSize = CGSize(width: scale * self.size.width, height: scale * self.size.height)
        
        UIGraphicsBeginImageContextWithOptions(toScaleSize, true, self.scale)
        
        self.draw(in: CGRect(x: 0, y: 0, width: scale * self.size.width, height: scale * self.size.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    @available(iOS 11.0, *)
    var page : PDFPage?
    {
        get {
            return PDFPage(image: self)
        }
    }
    
    @available(iOS 11.0, *)
    var pdf : PDFDocument?
    {
        get {
            guard let page = page else {
                return nil
            }
            
            let pdf = PDFDocument()
            pdf.insert(page, at: 0)
            
            return pdf
        }
    }
    

}

extension Data
{
    func save(to url: URL?) -> Data?
    {
        guard let url = url else {
            return nil
        }
        
        do {
            try self.write(to: url)
            return self
        } catch let error {
            NSLog("Data write error: \(url.absoluteString)",error.localizedDescription)
            return nil
        }
    }
    
    var json : Any?
    {
        get {
            do {
                let json = try JSONSerialization.jsonObject(with: self, options: [])
                return json
            } catch let error {
                NSLog("JSONSerialization error", error.localizedDescription)
                return nil
            }
        }
    }
    
    var html2AttributedString: NSAttributedString?
    {
        get {
            do {
                return try NSAttributedString(data: self, options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf16.rawValue], documentAttributes: nil)
            } catch {
                print("error:", error)
                return  nil
            }
        }
    }
    
    var html2String: String?
    {
        get {
            return html2AttributedString?.string
        }
    }
    
    var string16 : String?
    {
        get {
            return String.init(data: self, encoding: String.Encoding.utf16)
        }
    }
    
    var string8 : String?
    {
        get {
            return String.init(data: self, encoding: String.Encoding.utf8)
        }
    }
    
    var image : UIImage?
    {
        get {
            return UIImage(data: self)
        }
    }
    
    @available(iOS 11.0, *)
    var pdf : PDFDocument?
    {
        get {
            return !self.isEmpty ? PDFDocument(data: self) : nil
        }
    }
}

@available(iOS 11.0, *)
extension PDFDocument
{
    var data : Data?
    {
        get {
            return self.dataRepresentation()
        }
    }
}

extension Date
{
    //MARK: Date extension
    
    // VERY Computationally Expensive
    init?(dateString:String)
    {
        let dateStringFormatter = DateFormatter()
        
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let d = dateStringFormatter.date(from: dateString) else {
            return nil
        }
        
        self = Date(timeInterval:0, since:d)
    }
    
    // VERY Computationally Expensive
    init?(string:String)
    {
        let dateStringFormatter = DateFormatter()

        dateStringFormatter.dateFormat = "MMM dd, yyyy"

        var text = string
        
        if let range = string.range(of: " AM"), string.endIndex == range.upperBound {
            text = String(string[..<range.lowerBound])
        }
        
        if let range = string.range(of: " PM"), string.endIndex == range.upperBound {
            text = String(string[..<range.lowerBound])
        }

        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard var d = dateStringFormatter.date(from: text) else {
            return nil
        }

        if let range = string.range(of: " PM"), string.endIndex == range.upperBound {
            d += 12*60*60
        }

        self = Date(timeInterval:0, since:d)
    }
    
    // VERY Computationally Expensive
    var ymd : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy-MM-dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var mdyhm : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            dateStringFormatter.amSymbol = "AM"
            dateStringFormatter.pmSymbol = "PM"
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var mdy : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var year : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var month : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    // VERY Computationally Expensive
    var day : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
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


