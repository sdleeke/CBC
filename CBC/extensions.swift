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

extension Set
{
    /**
     Extension of Set
     */
    var array: [Element]
    {
        // get syntax is assumed
        return Array(self)
    }
}

extension Array where Element : Hashable
{
    /**
     Extension of Array
     */
    var set: Set<Element>
    {
        // get syntax is assumed
        return Set(self)
    }
}

extension UIView
{
    /**
     Extension of UIView - returns an UIImage of the view hierarchy.
     */
    var image : UIImage?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
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
    /**
     Extension of UIApplication to open a url or execute a closure if it cannot be.
     */
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
            self.open(url, options: [:], completionHandler: { (success) in
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
    /**
     Extension of FileManager to return a URL to the documents directory.
     */
    var documentsURL : URL?
    {
        get {
            return self.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
    
    /**
     Extension of FileManager to return a URL to the caches directory.
     */
    var cachesURL : URL?
    {
        get {
            return self.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }
}

extension Set where Element == String
{
    /**
     Extension of Set of Strings to return a sorted, joined string of tags.
     */
    var tagsString: String?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
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
    /**
     Extension of Array of MediaItem to return the SpeakerNotesParagraph class for the array.
     */
    var speakerNotesParagraph : SpeakerNotesParagraph?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return SpeakerNotesParagraph(list:self)
        }
    }
    
    /**
     Extension of Array of MediaItem to return the SpeakerNotesParagraph class for the array.
     */
    func speakerNotesParagraph(name:String?) -> SpeakerNotesParagraph?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        return SpeakerNotesParagraph(name:name,list:self)
    }
    
    /**
     Extension of Array of MediaItem to return the number of VB transcripts in the array.
     */
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
    
    /**
     Extension of Array of MediaItem to return the array sorted for a specific book.
     */
    func sort(book:String?) -> [MediaItem]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        var list:[MediaItem]?
        
        list = self.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBooksChaptersVerses   = first.scripture?.booksChaptersVerses?.copy(for: book)
            let secondBooksChaptersVerses  = second.scripture?.booksChaptersVerses?.copy(for: book)
            
            if firstBooksChaptersVerses == secondBooksChaptersVerses {
                guard let firstDate = first.fullDate else {
                    return false
                }
                
                guard let secondDate = second.fullDate else {
                    return true
                }
                
                if firstDate.isEqualTo(secondDate) {
                    if first.service == second.service {
                        return first.speakerSort < second.speakerSort
                    } else {
                        return first.service < second.service
                    }
                } else {
                    return firstDate.isOlderThan(secondDate)
                }
            } else {
                return firstBooksChaptersVerses < secondBooksChaptersVerses
            }
        })
        
        return list
    }
    
    /**
     Extension of Array of MediaItem to return the array sorted chronologically.
     */
    var sortChronologically : [MediaItem]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        return self.sorted() {
            return $0.dateService < $1.dateService
        }
    }
    
    /**
     Extension of Array of MediaItem to return the array sorted reverse chronologically.
     */
    var sortReverseChronologically : [MediaItem]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        return self.sorted() {
            return $0.dateService > $1.dateService
        }
    }
    
    /**
     Extension of Array of MediaItem to return the array sorted according to the sorting.
     */
    func sortByYear(sorting:String?) -> [MediaItem]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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

    /**
     Extension of Array of MediaItem to return the MediaItems in the array with the specified tag.
     */
    func withTag(tag:String?) -> [MediaItem]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let tag = tag, !tag.isEmpty else {
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
    
    /**
     Extension of Array of MediaItem to return the MediaItems in the array whose Scripture reference includes the specified book.
     */
    func inBook(_ book:String?) -> [MediaItem]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let book = book, !book.isEmpty else {
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
    
    /**
     Extension of Array of MediaItem to return the array of books (sorted according to the order of books in the Bible) in the Scripture references in the MediaItems in the array.
     */
    var books : [String]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        let mediaItems = self
        
        var bookSet = Set<String>()
        
        for mediaItem in mediaItems {
            if let books = mediaItem.scripture?.books {
                for book in books {
                    bookSet.insert(book)
                }
            }
        }
        
        return bookSet.array.inBibleOrder
    }
    
    /**
     Extension of Array of MediaItem to return the array of unique books or None or Selected Scripture(s)
     */
    var bookSections : [String]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        let mediaItems = self
        
        var bookSectionSet = Set<String>()
        
        for mediaItem in mediaItems {
            for bookSection in mediaItem.bookSections {
                bookSectionSet.insert(bookSection)
            }
        }

        return bookSectionSet.array.inBibleOrder
    }
    
    /**
     Extension of Array of MediaItem to return the array of multiPartNames in the MediaItems
     */
    var multiPartNames : [String]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        let multiPartNames = Set(self.filter({ (mediaItem:MediaItem) -> Bool in
            return mediaItem.hasMultipleParts
        }).map({ (mediaItem:MediaItem) -> String in
            return mediaItem.multiPartName ?? Constants.Strings.None
        }))

        return multiPartNames.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
    }
    
    /**
     Extension of Array of MediaItem to return the array of multiPartSections in the MediaItems
     */
    var multiPartSections : [String]?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to
        
        guard !self.isEmpty else {
            return nil
        }
        
        let multiPartSections = Set(self.map({ (mediaItem:MediaItem) -> String in
            if let multiPartSection = mediaItem.multiPartSection {
                return multiPartSection
            } else {
                return "ERROR"
            }
        }))

        return multiPartSections.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
    }
    
    /**
     Extension of Array of MediaItem to return the array of multiPartSections in the MediaItems OR if
     a MediaItem isn't part of a multiPart the title.
     */
    func multiPartSections(withTitles:Bool) -> [String]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        let multiPartSections = Set(self.map({ (mediaItem:MediaItem) -> String in
            return mediaItem.multiPartName ?? (withTitles ? (mediaItem.title ?? "No Title") : Constants.Strings.Individual_Media)
            
//            if mediaItem.hasMultipleParts {
//                return mediaItem.multiPartName!
//            } else {
//                return withTitles ? (mediaItem.title ?? "No Title") : Constants.Strings.Individual_Media
//            }
        }))
        
        return multiPartSections.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
    }

    /**
     Extension of Array of MediaItem to return an html representation.
     */
    func html(includeURLs:Bool = true,includeColumns:Bool = true, test:(()->(Bool))? = nil) -> String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
        } else {
            bodyString += " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        let keys = mediaListSort.keys.sorted() {
            $0.withoutPrefixes < $1.withoutPrefixes
        }
        
        if includeURLs, (keys.count > 1) {
            bodyString += "<a href=\"#index\">Index</a><br/><br/>"
        }
        
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
                        if var speaker = mediaItems[0].speaker, key != speaker {
                            if let speakerTitle = mediaItems[0].speakerTitle {
                                speaker += ", \(speakerTitle)"
                            }
                            bodyString += " by " + speaker
                        }
//                        bodyString += " by " + speaker
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
                    break
                }
            }
        }
        
        if includeColumns {
            bodyString  = bodyString + "</table>"
        }
        
        bodyString += "<br/>"
        
        if includeURLs, (keys.count > 1) {
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
        }
        
        bodyString += "</body></html>"
        
        return bodyString.insertHead(fontSize: Constants.FONT_SIZE)
    }
    
    func alignAllAudioTranscripts(viewController:UIViewController)
    {
        alignAllTranscripts(viewController:viewController,purpose:Purpose.audio)
    }
    
    func alignAllVideoTranscripts(viewController:UIViewController)
    {
        alignAllTranscripts(viewController:viewController,purpose:Purpose.video)
    }
    
    func alignAllTranscripts(viewController:UIViewController,purpose:String)
    {
//        guard let mediaItems = list else {
//            return
//        }

        let mediaItems = self
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.aligning == false else {
                continue
            }
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.selectAlignmentSource(viewController: viewController)
        }
    }
    
    func autoEditAllAudioTranscripts(viewController:UIViewController)
    {
        autoEditAllTranscripts(viewController:viewController,purpose:Purpose.audio)
    }
    
    func autoEditAllVideoTranscripts(viewController:UIViewController)
    {
        autoEditAllTranscripts(viewController:viewController,purpose:Purpose.video)
    }
    
    func autoEditAllTranscripts(viewController:UIViewController,purpose:String)
    {
//        guard let mediaItems = list else {
//            return
//        }

        let mediaItems = self
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.aligning == false else {
                continue
            }
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.autoEdit(notify:false)
        }
        
        if let multiPartName = multiPartName {
            Alerts.shared.alert(title: "All Auto Edits Underway", message: "\(multiPartName)\n(\(purpose.lowercased()))")
        } else {
            if self.count == 1, let mediaItem = self.first, let title = mediaItem.title {
                Alerts.shared.alert(title: "All Auto Edits Underway", message: "\(title)\n(\(purpose.lowercased()))")
            } else {
                Alerts.shared.alert(title: "All Auto Edits Underway")
            }
        }
    }
    
    func transcribeAllAudio(viewController:UIViewController)
    {
        transcribeAll(viewController:viewController,purpose:Purpose.audio)
    }
    
    func transcribeAllVideo(viewController:UIViewController)
    {
        transcribeAll(viewController:viewController,purpose:Purpose.video)
    }
    
    func transcribeAll(viewController:UIViewController,purpose:String)
    {
//        guard let mediaItems = list else {
//            return
//        }

        let mediaItems = self
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.completed == false else {
                continue
            }
            
            transcript.getTranscript()
            transcript.alert(viewController: viewController)
        }
    }
    
    func removeAllAudioTranscripts(viewController:UIViewController)
    {
        removeAllTranscripts(viewController:viewController,purpose:Purpose.audio)
    }
    
    func removeAllVideoTranscripts(viewController:UIViewController)
    {
        removeAllTranscripts(viewController:viewController,purpose:Purpose.video)
    }
    
    func removeAllTranscripts(viewController:UIViewController,purpose:String)
    {
//        guard let mediaItems = list else {
//            return
//        }
        
        let mediaItems = self
        
        for mediaItem in mediaItems {
            guard let transcript = mediaItem.transcripts[purpose] else {
                continue
            }
            
            guard transcript.transcribing == false else {
                continue
            }
            
            guard transcript.completed == true else {
                continue
            }
            
            transcript.remove(alert: true)
            
            if let text = mediaItem.text {
                Alerts.shared.alert(title: "Transcript Removed",message: "The transcript for\n\n\(text) (\(transcript.transcriptPurpose))\n\nhas been removed.")
            }
        }
    }
    
    func toTranscribe(purpose:String) -> Int?
    {
        return self.filter({ (mediaItem) -> Bool in
            return (mediaItem.transcripts[purpose]?.transcribing == false) && (mediaItem.transcripts[purpose]?.completed == false)
        }).count
    }
    
    var transcribedAudio : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.completed == true)
            }).count
        }
    }
    
    var transcribedVideo : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.completed == true)
            }).count
        }
    }
    
    var autoEditingAudio : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.hasAudio && (mediaItem.audioTranscript?.operationQueue?.operationCount > 0)
            }).count
        }
    }
    
    var autoEditingVideo : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.hasVideo && (mediaItem.videoTranscript?.operationQueue?.operationCount > 0)
            }).count
        }
    }
    
    var toTranscribeAudio : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return  mediaItem.hasAudio &&
                        (mediaItem.audioTranscript?.transcribing == false) &&
                        (mediaItem.audioTranscript?.completed == false)
            }).count
        }
    }
    
    var toTranscribeVideo : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return  mediaItem.hasVideo &&
                        (mediaItem.videoTranscript?.transcribing == false) &&
                        (mediaItem.videoTranscript?.completed == false)
            }).count
        }
    }
    
    func toAlign(purpose:String) -> Int?
    {
        return self.filter({ (mediaItem) -> Bool in
            return  (mediaItem.transcripts[purpose]?.transcribing == false) &&
                    (mediaItem.transcripts[purpose]?.completed == false) &&
                    (mediaItem.transcripts[purpose]?.aligning == false)
        }).count
    }
    
    var toAlignAudio : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return  mediaItem.hasAudio &&
                        (mediaItem.audioTranscript?.transcribing == false) &&
                        (mediaItem.audioTranscript?.completed == true) &&
                        (mediaItem.audioTranscript?.aligning == false)
            }).count
        }
    }
    
    var toAlignVideo : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return  mediaItem.hasVideo &&
                        (mediaItem.videoTranscript?.transcribing == false) &&
                        (mediaItem.videoTranscript?.completed == true) &&
                        (mediaItem.videoTranscript?.aligning == false)
            }).count
        }
    }
    
    func downloads(purpose:String) -> Int?
    {
        guard Globals.shared.reachability.isReachable else {
            return nil
        }
        
        return self.filter({ (mediaItem) -> Bool in
            return (mediaItem.downloads[purpose]?.active == false) &&
                (mediaItem.downloads[purpose]?.exists == false)
        }).count
    }
    
    var audioDownloads : Int?
    {
        get {
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == false) &&
                    (mediaItem.audioDownload?.exists == false)
            }).count
        }
    }
    
    func downloading(purpose:String) -> Int?
    {
        return self.filter({ (mediaItem) -> Bool in
            return mediaItem.downloads[purpose]?.active == true
        }).count
    }
    
    var audioDownloading : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.audioDownload?.active == true)
            }).count
        }
    }
    
    func downloaded(purpose:String) -> Int?
    {
        return self.filter({ (mediaItem) -> Bool in
            return mediaItem.downloads[purpose]?.exists == true
        }).count
    }
    
    var audioDownloaded : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.audioDownload?.exists == true
            }).count
        }
    }
    
    var videoDownloads : Int?
    {
        get {
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.videoDownload?.active == false) && (mediaItem.videoDownload?.exists == false)
            }).count
        }
    }
    
    var videoDownloading : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.videoDownload?.active == true)
            }).count
        }
    }
    
    var videoDownloaded : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return mediaItem.videoDownload?.exists == true
            }).count
        }
    }
    
    var slidesDownloads : Int?
    {
        get {
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.active == false) && (mediaItem.slidesDownload?.exists == false)
            }).count
        }
    }
    
    var slidesDownloading : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.active == true)
            }).count
        }
    }
    
    var slidesDownloaded : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.slidesDownload?.exists == true)
            }).count
        }
    }
    
    var notesDownloads : Int?
    {
        get {
            guard Globals.shared.reachability.isReachable else {
                return nil
            }
            
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.active == false) && (mediaItem.notesDownload?.exists == false)
            }).count
        }
    }
    
    var notesDownloading : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.active == true)
            }).count
        }
    }
    
    var notesDownloaded : Int?
    {
        get {
            return self.filter({ (mediaItem) -> Bool in
                return (mediaItem.notesDownload?.exists == true)
            }).count
        }
    }
    
    func addAllToFavorites()
    {
        self.forEach({ (mediaItem) in
            mediaItem.addToFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Added to Favorites",message: multiPartName)
    }
    
    func removeAllFromFavorites()
    {
        self.forEach({ (mediaItem) in
            mediaItem.removeFromFavorites(alert:false)
        })
        Alerts.shared.alert(title: "All Removed to Favorites",message: multiPartName)
    }
    
    var multiPartName : String?
    {
        get {
//            guard let set = list?.filter({ (mediaItem:MediaItem) -> Bool in
//                return mediaItem.multiPartName != nil
//            }).map({ (mediaItem:MediaItem) -> String in
//                return mediaItem.multiPartName!
//            }) else {
//                return nil
//            }
            
            let set = self.compactMap({ (mediaItem:MediaItem) -> String? in
                return mediaItem.multiPartName
            })
            
            guard Set(set).count == 1 else {
                return nil
            }
            
            return set.first
        }
    }
    
    func loadAllDocuments()
    {
        self.forEach({ (mediaItem:MediaItem) in
            mediaItem.loadDocuments()
        })
    }
    
    func loadTokenCountMarkCountMismatches()
    {
        self.forEach { (mediaItem) in
            mediaItem.loadTokenCountMarkCountMismatches()
        }
    }

    func testMediaItemsPDFs(testExisting:Bool, testMissing:Bool, showTesting:Bool)
    {
//        guard let mediaItems = self else {
//            print("Testing the availability of mediaItem PDF's - no list")
//            return
//        }

        let mediaItems = self
        
        var counter = 1
        
        if (testExisting) {
            print("Testing the availability of mediaItem PDFs that we DO have in the mediaItemDicts - start")
            
            for mediaItem in mediaItems {
                if (showTesting) {
                    print("Testing: \(counter) \(mediaItem.title ?? mediaItem.description)")
                } else {
                    //                    print(".", terminator: Constants.EMPTY_STRING)
                }
                
                if let title = mediaItem.title, let notesURLString = mediaItem.notes, let notesURL = mediaItem.notes?.url {
                    if ((try? Data(contentsOf: notesURL)) == nil) {
                        print("Transcript DOES NOT exist for: \(title) PDF: \(notesURLString)")
                    } else {
                        
                    }
                }
                
                if let title = mediaItem.title, let slidesURLString = mediaItem.slides, let slidesURL = mediaItem.slides?.url {
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
                
                if (mediaItem.audioURL == nil) {
                    print("No Audio file for: \(String(describing: mediaItem.title)) can't test for PDF's")
                } else {
                    if let title = mediaItem.title, let id = mediaItem.mediaCode, let notesURL = mediaItem.notes?.url {
                        if ((try? Data(contentsOf: notesURL)) != nil) {
                            print("Transcript DOES exist for: \(title) ID:\(id)")
                        } else {
                            
                        }
                    }
                    
                    if let title = mediaItem.title, let id = mediaItem.mediaCode, let slidesURL = mediaItem.slides?.url {
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
        
        let mediaItems = self

        for mediaItem in mediaItems {
            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                if (mediaItem.multiPartName == mediaItem.tags) {
                    print("Multiple Part Name and Tags the same in: \(mediaItem.title ?? mediaItem.description) Multiple Part Name:\(mediaItem.multiPartName ?? mediaItem.description) Tags:\(mediaItem.tags ?? mediaItem.description)")
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
        
//        guard let list = self else {
//            print("Testing for audio - list empty")
//            return
//        }

        let list = self
        
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
        
//        guard let list = self else {
//            print("Testing for speaker - no list")
//            return
//        }

        let list = self
        
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
        
//        guard let list = self else {
//            print("Testing for speaker - no list")
//            return
//        }

        let list = self
        
        for mediaItem in list {
            if (mediaItem.title?.range(of: "(Part ", options: .caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
                print("Series missing in: \(mediaItem.title ?? mediaItem.description)")
            }
        }
    }
}

extension Array where Element == UIViewController
{
    /**
     Extension of Array of UIViewController to return a boolean value on whether or not a UIViewController is
     either in the array or in the array of viewControllers in a UINavigationController or UISplitViewController
     */
    func containsBelow(_ containedViewController:UIViewController) -> Bool
    {
        guard !self.isEmpty else {
            return false
        }
        
        for viewController in self {
            if viewController == containedViewController {
                return true
            }
            
            if let navCon = (viewController as? UINavigationController) {
                if navCon.viewControllers.containsBelow(containedViewController) == true {
                    return true
                }
            }
            
            if let svCon = (viewController as? UISplitViewController) {
                if svCon.viewControllers.containsBelow(containedViewController) == true {
                    return true
                }
            }
        }
        
        return false
    }
}

extension Array where Element == String
{
    /**
     Extension of Array of String that is assumed to be an array of books of the Bible and returns them
     sorted in the order they appear in the Bible.
     */
    var inBibleOrder : [String]?
    {
        // get syntax is assumed.
        
        guard !self.isEmpty else {
            return nil
        }
        
        return self.sorted(by: { (first:String, second:String) -> Bool in
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
    
    /**
     Extension of Array of String that is assumed to be an array of transcriptSegmentComponentss and returns a String of them joined together as a String of transcriptSegments
     */
    var transcriptSegmentsFromTranscriptSegmentComponents:String?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            var str : String?
            
            for transcriptSegmentComponent in self {
                str = (str != nil ? str! + VoiceBase.separator : "") + transcriptSegmentComponent
            }
            
            return str
        }
    }
    
    /**
     Extension of Array of String that is assumed to be an array of transcriptSegments and returns a String of them joined together as a transcript
     */
    var transcriptFromTranscriptSegments:String?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            var str : String?
            
            for transcriptSegmentComponent in self {
                var strings = transcriptSegmentComponent.components(separatedBy: "\n")
                
                if strings.count > 2 {
                    _ = strings.removeFirst() // count
                    let timing = strings.removeFirst() // time
                    
                    if let range = transcriptSegmentComponent.range(of:timing+"\n") {
                        let string = transcriptSegmentComponent[range.upperBound...]
                        str = (str != nil ? str! + " " : "") + string
                    }
                }
            }
            
            return str
        }
    }

    /**
     Extension of Array of String that is assumed to be an array of transcriptSegments and returns the one at a given time or closest to it.
     */
    func component(atTime:String?, returnClosest:Bool) -> String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let atTime = atTime else {
            return nil
        }
        
        var segment : String?
        var found = false
        var gap : Double?
        var closest : String?
        
        for transcriptSegmentComponent in self {
            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
            
            if transcriptSegmentArray.count > 2  {
                let count = transcriptSegmentArray.removeFirst()
                let timeWindow = transcriptSegmentArray.removeFirst()
                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                
                if  let start = times.first,
                    let end = times.last,
                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                    let string = "\(count)\n\(start) to \(end)\n" + text
                    
                    if (start.hmsToSeconds <= atTime.hmsToSeconds) && (atTime.hmsToSeconds <= end.hmsToSeconds) {
                        segment = transcriptSegmentComponent
                        found = true
                        gap = nil
                        break
                    } else {
                        guard let time = atTime.hmsToSeconds else {
                            continue
                        }
                        
                        guard let start = start.hmsToSeconds else {
                            continue
                        }
                        
                        guard let end = end.hmsToSeconds else { //
                            continue
                        }
                        
                        var currentGap = 0.0
                        
                        if time < start {
                            currentGap = start - time
                        }
                        if time > end {
                            currentGap = time - end
                        }
                        
                        if gap != nil {
                            if currentGap < gap {
                                gap = currentGap
                                closest = string
                            }
                        } else {
                            gap = currentGap
                            closest = string
                        }
                    }
                }
            }
        }
        
        if !found && returnClosest {
            return closest
        } else {
            return segment
        }
    }
    
    /**
     Extension of Array of String that is assumed to be an array of transcriptSegmentComponents and returns a String of them in HTML to show timing of each segment.
     */
    func timingHTML(_ headerHTML:String?, test:(()->(Bool))? = nil) -> String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    
    /**
     Extension of Array of String that is assumed to be an array of words and returns an array sorted using the method specified.
     
     Assumes each word is followed by their frequency in parentheses.
     */
    func sort(method:String?) -> [String]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        let strings = self
        
        guard let method = method else {
            return nil
        }
        
        switch method {
        case Constants.Sort.Alphabetical:
            return strings.sorted()
            
        case Constants.Sort.Length:
            return strings.sorted(by: { (first:String, second:String) -> Bool in
                let firstCount = first.word?.count ?? first.count
                
                let secondCount = second.word?.count ?? second.count
                
                if firstCount == secondCount {
                    return first < second
                } else {
                    return firstCount > secondCount
                }
            })
            
        case Constants.Sort.Frequency:
            let newStrings = strings.sorted(by: { (first:String, second:String) -> Bool in
                if first.frequency == second.frequency {
                    return first < second
                } else {
                    return first.frequency > second.frequency
                }
            })
            return newStrings
            
        default:
            return nil
        }
    }

    /**
     Extension of Array of String that is assumed to be an array of tags and returns a string of them joined or nil if the array is empty.
     */
    var tagsString : String?
    {
        get {
            return !self.isEmpty ? self.joined(separator: Constants.SEPARATOR) : nil
        }
    }
    
    /**
     Extension of Array of String that returns a default html representation.
     */
    var tableHTML : String?
    {
        get {
            return tableHTML()
        }
    }
    
    /**
     Extension of Array of String that returns an html representation.  Can be interrupted.
     */
    func tableHTML(title:String? = nil, searchText:String? = nil, test:(()->(Bool))? = nil) -> String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard test?() != true else {
            return nil
        }
        
        var bodyHTML:String! = "<!DOCTYPE html>"
        
        bodyHTML += "<html><body>"

        let words = self.sorted()
        
        var wordsHTML = ""
        var indexHTML = ""
        
        var roots = [String:Int]()
        
        var keys : [String] {
            get {
                return roots.keys.sorted()
            }
        }

        for word in words {
            guard test?() != true else {
                return nil
            }
            
            let key = String(word[..<String.Index(utf16Offset: 1, in: word)])

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

        if let searchText = searchText?.uppercased() {
            bodyHTML += "Search Text: \(searchText)<br/><br/>"
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
    /**
     Extension of String that is assumed to be a representation of NT or OT and needs to be translated to the other.
     */
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
    
    /**
     Extension of String that is assumed to be sorting or grouping and returns the user readable translation.
     */
    var translate : String
    {
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
    /**
     A String extension that assumes self is a Scripture reference.
     */
    func verses(book:String,chapter:Int) -> [Int]
    {
        var versesForChapter = [Int]()
        
        if let verses = self.booksChaptersVerses?[book]?[chapter] {
            versesForChapter = verses
        }
        
        return versesForChapter
    }
    
    /**
     A String extension that assumes self is a Scripture reference.
     */
    func chaptersAndVerses(book:String) -> [Int:[Int]]
    {
        var chaptersAndVerses = [Int:[Int]]()
        
        if let cav = self.booksChaptersVerses?[book] {
            chaptersAndVerses = cav
        }
        
        return chaptersAndVerses
    }

    /**
     A String extension that assumes self is a Scripture reference.
     */
    var booksChaptersVerses : BooksChaptersVerses?
    {
        // get syntax is assumed, not including it makes it easier to convert
        // this to a func later if we need to

        let scriptureReference = self
        
        guard let books = books else {
            return nil
        }
        
        let booksChaptersVerses = BooksChaptersVerses()
        
        var ranges = [Range<String.Index>]()
        var scriptures = [String]()
        
        for book in books {
            if let range = scriptureReference.range(book) {
                ranges.append(range)
            }
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
        
        for scripture in scriptures {
            if let book = scripture.books?.first {
                var reference : String?
                
                if let range = scripture.range(book) {
                    reference = String(scripture[range.upperBound...])
                }
                
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
    
    /**
     A String extension that assumes self is a Scripture reference.
     */
    func chapters(_ thisBook:String) -> [Int]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    
    /**
     A String extension that assumes self is a book name.
     */
    func versesForChapter(_ chapter:Int) -> [Int]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    
    /**
     A String extension that assumes self is a Scripture reference.
     
     Acceptable reference formats are:
     - John (the entire book)
     - John 1 (the entire chapter)
     - John 1-3 (three chapters)
     - John 1:1 (one verse)
     - John 1:1-3 (three verses)
     - John 1,3 (two chapters)
     - what else?
     
     This is a very complicated state machine that assumes a specific format of Scripture reference.
     */
    func chaptersAndVerses(_ book:String?) -> [Int:[Int]]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        // This can only comprehend a range of chapters or a range of verses from a single book.
        
        guard let book = book else {
            return nil
        }

        let reference = self
        
        guard (reference.range(of: ".") == nil) else {
            return nil
        }
        
        var chaptersAndVerses = [Int:[Int]]()
        
        var tokens = [String]()
        
        var currentChapter = 0
        var startChapter = 0
        var endChapter = 0
        var startVerse = 0
        var endVerse = 0
        
        let string = reference.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        if string.isEmpty {
            // Now we have a book w/ no chapter or verse references
            // FILL in all chapters and all verses and return
            return book.chaptersAndVerses
        }
        
        var token = Constants.EMPTY_STRING
        
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

        if !token.isEmpty {
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
    
    /**
     
     A String extension that assumes self is a Scripture reference.

     This can only comprehend a range of chapters or a range of verses from a single book.
     
     */
    var chapters : [Int]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard books?.count == 1 else {
            return nil
        }
        
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
    
    /**
     A String extension that assumes self is a Scripture reference.
     */
    var books : [String]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    
    /**
     A String extension that assumes self is a book and returns the testament it is in.
     */
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
    
    /**
     A String extension that assumes self is a Scripture reference and returns the verses in an array if Int.
     */
    var verses : [Int]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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

    /**
     A String extension that assumes self is a Scripture reference and returns the chapters and verses in a dictionary of Int of [Int].
     */
    var chaptersAndVerses : [Int:[Int]]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    /**
     A String extension that assumes self is a made up of tags and returns them in a set.
     */
    var tagsSet : Set<String>?
    {
        return tagsArray?.set
    }
    
    /**
     A String extension that assumes self is a made up of tags and returns them in an array.
     */
    var tagsArray : [String]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        let array = self.components(separatedBy: Constants.SEPARATOR)
        
        return array.count > 0 ? array : nil
    }
}

extension UITableView
{
    /**
     UITableView extension that checks an indexPath to make sure it is valid.
     */
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

extension Dictionary
{
    /**
     Dictionary extension that assumes the dictionary is [String:Any] and searches for a given key until found and returns the value or returns nil.
     NOTE: This method is recursive.
     
     Would be nice to know the key path of what comes back.
     */

    func search(key:String) -> Any?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
}

extension String
{
    /**
     Extension of String that <mark/>'s a searchText in self, returning the string with marking inserted.
     */
    func markSearchHTML(_ searchText:String?) -> String
    {
        guard let searchText = searchText else { // ?.uppercased()
            return self
        }
        
        var newString = self
        
        let range = NSRange(location: 0, length: newString.utf16.count)

        if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
            regex.matches(in: newString, options: .withTransparentBounds, range: range).sorted(by: { (first:NSTextCheckingResult, second:NSTextCheckingResult) -> Bool in
                return first.range.lowerBound > second.range.lowerBound // If we work from the end to the beginning through the string the ranges are always correct.
            }).forEach { match in
                let foundString = "<mark>" + String(newString[String.Index(utf16Offset: match.range.lowerBound, in: newString)..<String.Index(utf16Offset: match.range.upperBound, in: newString)]) + "</mark>"
                newString = String(newString[..<String.Index(utf16Offset: match.range.lowerBound, in: newString)]) + foundString + String(newString[String.Index(utf16Offset: match.range.upperBound, in: newString)...])
            }
        }

        return newString
    }
    
    /**
     Extension of String that is assumed to be html and returns it stripped of the <head/> block.
     */
    var stripHead : String
    {
        // get syntax is assumed.
        
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
    
    /**
     Extension of String that is assumed to be html and returns it with the new <head/> block.
     */
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

/**
 
 Enum to provide contents of an alert dialog action or text item
 
 Cases:
     - action : AlertAction
     - text : String
 
 */

enum AlertItem {
    case action(_ action:AlertAction)
    case text(_ text:String?)
}

/**

 struct to provide contents of an alert dialog action item
 
 Properties:
    - title:String? of the alert
 
 */

struct AlertAction
{
    let title : String?
    let style : UIAlertAction.Style
    let handler : (()->(Void))?
}

extension UIViewController
{
    /**
     Extension of UIViewController that blocks presentation until the Alert singleton semaphore is available.
     */
    func present(_ viewControllerToPresent: UINavigationController, animated: Bool, completion: (() -> Void)? = nil)
    {
        Alerts.shared.blockPresent(presenting: self, presented: viewControllerToPresent, animated: animated,
                                   release: { viewControllerToPresent.modalPresentationStyle != .popover },
                                   completion: completion)
    }

    /**
     Extension of UIViewController that presents an alert with completion on the Alert singleton.
     */
    func alert(title:String?,message:String? = nil,completion:(()->(Void))? = nil)
    {
        Alerts.shared.alert(title: title, message: message, actions: [AlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: { () -> (Void) in
            completion?()
        })])
    }

    /**
     Extension of UIViewController that presents an alert with actions on the Alert singleton.
     */
    func alert(title:String?,message:String?,actions:[AlertAction]?)
    {
        guard let actions = actions else {
            Alerts.shared.alert(title: title, message: message, actions: [AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: nil)])
            return
        }

        Alerts.shared.alert(title: title, message: message, actions: actions)
    }
    
    /**
     Extension of UIViewController that presents an alert with actions, and a specific cancel action, on the Alert singleton.
     */
    func alertActionsCancel(title:String?,message:String? = nil,alertActions:[AlertAction]? = nil,cancelAction:(()->(Void))? = nil)
    {
        var alertActions = alertActions ?? [AlertAction]()
        
        alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: cancelAction))

        Alerts.shared.alert(title: title, message: message, actions: alertActions)
    }
    
    /**
     Extension of UIViewController that presents an alert with actions, and a specific okay action, on the Alert singleton.
     */
    func alertActionsOkay(title:String?,message:String? = nil,alertActions:[AlertAction]? = nil,okayAction:(()->(Void))? = nil)
    {
        var alertActions = alertActions ?? [AlertAction]()

        alertActions.append(AlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: okayAction))
        
        Alerts.shared.alert(title: title, message: message, actions: alertActions)
    }
    
    /**
     Extension of UIViewController that presents an alert on the Alert singleton that includes a text field with searchText and a searchAction.
     */
    func searchAlert(title:String?,message:String? = nil,searchText:String?,searchAction:((_ alert:UIAlertController)->(Void))?)
    {
        let alert = CBCAlertController(  title: title,
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

        Alerts.shared.blockPresent(presenting: self, presented: alert, animated: true)
    }

    /**
     Extension of UIViewController that presents an alert on the Alert singleton with actions for Yes and No.
     */
    func yesOrNo(title:String?,message:String? = nil,
                 yesAction:(()->(Void))?, yesStyle: UIAlertAction.Style,
                 noAction:(()->(Void))?, noStyle: UIAlertAction.Style)
    {
        var alertActions = [AlertAction]()
        
        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: yesStyle, handler: yesAction))
        alertActions.append(AlertAction(title: Constants.Strings.No, style: noStyle, handler: noAction))

        Alerts.shared.alert(title: title, message: message, actions: alertActions)
    }

    /**
     Extension of UIViewController that presents an alert on the Alert singleton with two actions and a cancel action.
     */
    func firstSecondCancel(title:String?,message:String? = nil,
                           firstTitle:String?,   firstAction:(()->(Void))?, firstStyle: UIAlertAction.Style,
                           secondTitle:String?,  secondAction:(()->(Void))?, secondStyle: UIAlertAction.Style,
                           cancelAction:(()->(Void))? = nil)
    {
        guard let firstTitle = firstTitle else {
            return
        }

        guard let secondTitle = secondTitle else {
            return
        }

        var alertActions = [AlertAction]()
        
        alertActions.append(AlertAction(title: firstTitle, style: firstStyle, handler: firstAction))
        alertActions.append(AlertAction(title: secondTitle, style: secondStyle, handler: secondAction))
        alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: cancelAction))

        Alerts.shared.alert(title: title, message: message, actions: alertActions)
    }
    
    /**
     Extension of UIViewController that presents an mail compose view controller on the Alerts singleton for text.
     */
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

        Alerts.shared.blockPresent(presenting: self, presented: mailComposeViewController, animated: true, release: {true})
    }
    
    /**
     Extension of UIViewController that presents an mail compose view controller on the Alerts singleton for html.
     */
    func mailHTML(to: [String]?,subject: String?, htmlString:String)
    {
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

        Alerts.shared.blockPresent(presenting: self, presented: mailComposeViewController, animated: true, release: {true})
    }

    /**
     Extension of UIViewController that presents a print interaction controller using the Alerts singleton semaphore.
     */
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
        
        Alerts.shared.queue.async {
            Alerts.shared.semaphore.wait()
            
            Thread.onMain {
                if let barButtonItem = self.navigationItem.rightBarButtonItem {
                    pic.present(from: barButtonItem, animated: true, completionHandler: { (pic:UIPrintInteractionController, finished:Bool, error:Error?) in
                        Alerts.shared.semaphore.signal()
                    })
                }
            }
        }
    }
    
    /**
     Extension of UIViewController that presents a print interaction controller using the Alerts singleton semaphore.
     */
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

        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Alerts.shared.queue.async {
            Alerts.shared.semaphore.wait()
            
            Thread.onMain {
                if let barButtonItem = self.navigationItem.rightBarButtonItem {
                    pic.present(from: barButtonItem, animated: true, completionHandler: { (pic:UIPrintInteractionController, finished:Bool, error:Error?) in
                        Alerts.shared.semaphore.signal()
                    })
                }
            }
        }
    }
    
    /**
     Extension of UIViewController that print text.
     */
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
    
    /**
     Extension of UIViewController that presents a print interaction controller using the Alerts singleton semaphore.
     */
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

        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Alerts.shared.queue.async {
            Alerts.shared.semaphore.wait()
            
            Thread.onMain {
                if let barButtonItem = self.navigationItem.rightBarButtonItem {
                    pic.present(from: barButtonItem, animated: true, completionHandler: { (pic:UIPrintInteractionController, finished:Bool, error:Error?) in
                        Alerts.shared.semaphore.signal()
                    })
                }
            }
        }
    }
    
    /**
     Extension of UIViewController that prints an image.
     */
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
    
    /**
     Extension of UIViewController that presents a print interaction controller using the Alerts singleton semaphore for html.
     */
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

        let renderer = UIPrintPageRenderer()
        renderer.headerHeight = margin
        renderer.footerHeight = margin
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        pic.printPageRenderer = renderer

        Alerts.shared.queue.async {
            Alerts.shared.semaphore.wait()
            
            Thread.onMain {
                if let barButtonItem = self.navigationItem.rightBarButtonItem {
                    pic.present(from: barButtonItem, animated: true, completionHandler: { (pic:UIPrintInteractionController, finished:Bool, error:Error?) in
                        Alerts.shared.semaphore.signal()
                    })
                }
            }
        }
    }
    
    /**
     Extension of UIViewController that prints html.
     */
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
    
    /**
     Extension of UIViewController that prints a document.
     */
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
    
    /**
     Extension of UIViewController that prints a mediaItem.
     */
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
    
    /**
     Extension of UIViewController that ask user for page orientation or to cancel.
     */
    func pageOrientation(portrait:(()->(Void))?,landscape:(()->(Void))?,cancel:(()->(Void))?)
    {
        self.firstSecondCancel(title: "Page Orientation",
                          firstTitle: "Portrait", firstAction: portrait, firstStyle: .default,
                          secondTitle: "Landscape", secondAction: landscape, secondStyle: .default,
                          cancelAction: cancel)
    }
    
    /**
     Extension of UIViewController to print an array of mediaItems.
     */
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
    
    /**
     Extension of UIViewController to present a mail compose view controller with the html of an array of mediaItems.
     */
    func mailMediaItems(mediaItems:[MediaItem]?, stringFunction:(([MediaItem]?,Bool,Bool)->String?)?, links:Bool, columns:Bool, attachments:Bool)
    {
        guard (mediaItems != nil) && (stringFunction != nil) && MFMailComposeViewController.canSendMail() else {
            self.showSendMailErrorAlert()
            return
        }
        
        self.process(work: {
            if let text = stringFunction?(mediaItems,links,columns) {
                return [text]
            }
            
            return nil
        }, completion: { (data:Any?) in
            if let itemsToMail = data as? [Any] {
                let mailComposeViewController = MFMailComposeViewController()
                
                // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
                mailComposeViewController.mailComposeDelegate = self as? MFMailComposeViewControllerDelegate
                
                mailComposeViewController.setToRecipients([])
                mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
                
                if let body = itemsToMail[0] as? String {
                    mailComposeViewController.setMessageBody(body, isHTML: true)
                }
                
                Alerts.shared.blockPresent(presenting: self, presented: mailComposeViewController, animated: true, release: {true})
            }
        })
    }
    
    /**
     Extension of UIViewController to present a mail compose view controller with the html of an array of mediaItems.
     */
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
            Alerts.shared.blockPresent(presenting: self, presented: mailComposeViewController, animated: true, release: {true})
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    /**
     Extension of UIViewController to present a modal dialog of html that may be related to a mediaItem.
     */
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

        let presentingViewController = dismiss ? self.presentingViewController : self
        
        let block = {
            navigationController.modalPresentationStyle = style
            
            navigationController.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
            
            popover.navigationItem.title = title
            
            popover.search = true
            popover.mediaItem = mediaItem
            
            popover.html.string = htmlString
            popover.content = .html
            
            popover.navigationController?.isNavigationBarHidden = false
            
            presentingViewController?.present(navigationController, animated: true, completion: nil)
        }
        
        Thread.onMain {
            if dismiss {
                self.dismiss(animated: true, completion:{ block() })
            } else {
                block()
            }
        }
    }
    
    /**
     Extension of UIViewController to alert user that mail could not be sent.
     */
    func showSendMailErrorAlert()
    {
        alert(title: "Could Not Send Email",message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",completion:nil)
    }

    /**
     Extension of UIViewController to return the preferred modal presentation style based on traits.
     */
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
    
    /**
     Extension of UIViewController to show a popover of html that is optionally related to a mediaItem.
     */
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

            present(navigationController, animated: true, completion: nil)
        }
    }

    /**
     Extension of UIViewController to do work, screening the view and showing an animating activity indicator view while the work is being done.
     In this version there is a cancel button below the activity indicator that when pressed tells the work and also tells the completion
     block whether work was asked to stop.
     */
    func process(disableEnable:Bool = true, work:(((()->Bool)?)->(Any?))?, completion:((Any?,(()->Bool)?)->())?)
    {
        guard let cancelButton = self.loadingButton else {
            return
        }

        self.startAnimating()

        Thread.onMain {
            // Brute force disable
            if disableEnable {
                self.barButtonItems(isEnabled: false)
            }

            // Should be an OperationQueue but as an extension either the UIViewController has it or its global
            DispatchQueue.global(qos: .background).async { [weak self] in
                // work is Cancelable
                let data = work?({
                    return DispatchQueue.main.sync {
                        return cancelButton.tag == 1
                    }
                })

                Thread.onMain {
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
    }
    
    /**
     Extension of UIViewController to enable or disable all bar button items.
     */
    func barButtonItems(isEnabled:Bool)
    {
        Thread.onMain {
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
    
    /**
     Extension of UIViewController to do work, screening the view and showing an animating activity indicator view while the work is being done.
     */
    func process(disableEnable:Bool = true,work:(()->(Any?))?,completion:((Any?)->())?)
    {
        guard (work != nil) && (completion != nil) else {
            return
        }

        self.startAnimating()

        Thread.onMain { [weak self] in
            // Brute force disable
            if disableEnable {
                self?.barButtonItems(isEnabled: false)
            }

            // Should be an OperationQueue but as an extension either the UIViewController has it or its global
            DispatchQueue.global(qos: .background).async { [weak self] in
                let data = work?()

                Thread.onMain {
                    // Brute force enable => need to be set according to state in completion.
                    if disableEnable {
                        self?.barButtonItems(isEnabled: true)
                    }

                    completion?(data)

                    self?.stopAnimating()
                }
            }
        }
    }
    
    /**
     Extension of UIViewController to alert the user that the network is not available.
     */
    func networkUnavailable(_ message:String?)
    {
        self.alert(title:Constants.Network_Error,message:message,completion:nil)
    }
    
    /**
     Extension of UIViewController to show a popover of strings.
     */
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
                    
                    popover.section.strings = strings
                    
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
                    
                    popover.section.strings = strings
                    
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
                    
                    popover.section.strings = strings
                    
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

extension String
{
    /**
     Extension of String to return self plus the qualifing string appended w/ appropriate spacing.
     */
    func qualifier(_ qualifier:String) -> String?
    {
        guard !self.isEmpty else {
            return qualifier
        }
        
        return self + Constants.SINGLE_SPACE + qualifier
    }
    
    /**
     Extension of String to return the substring up to the pattern " (".
     This pattern is what indicates a number or a part name.
     */
    var word : String?
    {
        return self.subString(to: " (")
    }
    
    /**
     Extension of String to return the Int n that appears in the pattern " (n)".
     This patter should only occur at the end of the string.
     */
    var frequency : Int?
    {
//        guard let startRange = self.range(of: " (") else {
//            return nil
//        }
//
//        guard let endRange = self.range(of: ")", options: .caseInsensitive, range: Range<String.Index>(uncheckedBounds: (lower: startRange.lowerBound, upper: self.endIndex)), locale: nil) else {
//            return nil
//        }
//
//        guard endRange.upperBound == self.endIndex else {
//            return nil
//        }
//
//        let frequency = String(self[startRange.upperBound..<endRange.lowerBound])
//
//        return Int(frequency)
        
        // OR

        guard !self.isEmpty else {
            return nil
        }

        let strings = self.components(separatedBy: Constants.SINGLE_SPACE)

        guard strings.count > 1 else {
            return nil
        }

        guard let frequency = strings.last?.trimmingCharacters(in: CharacterSet(charactersIn: "()")) else {
            return nil
        }

        return Int(frequency)
    }
    
    /**
     Extension of String that return the string w/ \n replaced with ", "
     */
    var singleLine : String
    {
        get {
            return self.replacingOccurrences(of: "\n", with: ", ").trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
        }
    }
    
    /**
     Extension of String that return the string percent encoded, allowing only alphanumerics
     This is a bad variable name as this tag refers to the tags in html and has nothing to do with the mediaItem tags.
     */
    var asTag : String
    {
        get {
            return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? self
        }
    }
        
    /**
     Extension of String that return the string w/o leading characters that should not be used in the sorting of strings.
     */
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

extension OperationQueue
{
    func addCancelableOperation(tag:String? = nil,block:(((()->Bool)?)->())?)
    {
        self.addOperation(CancelableOperation(tag: tag, block: block))
    }
}

extension Thread
{
    static func onMain(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async {
                block?()
            }
        }
    }
    
    static func onMainSync(block:(()->(Void))?)
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

    func titleWidth(lineHeight: CGFloat) -> CGFloat
    {
        var width:CGFloat = 0.0
        
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: lineHeight)
        
        if let title = self.navigationItem.title, !title.isEmpty {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width + 20
            
            if let left = navigationItem.leftBarButtonItem?.title {
                let string = left.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                width += string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.body, context: nil).width + 20
            }
            
            if let right = navigationItem.rightBarButtonItem?.title {
                let string = right.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                width += string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.body, context: nil).width + 20
            }
        }
        
        return width
    }
    
    /**
     Extension of UIViewController that adds a loading container view with activity indicator view, label, and button
     */
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

                    return loadingContainer
                }
                
                return nil
            }
            
            return loadingContainer
        }
    }
    
    /**
     Extension of UIViewController that returns the loading view
     */
    var loadingView:UIView?
    {
        get {
            return loadingContainer?.subviews[0]
        }
    }
    
    /**
     func for the button action in the loading container view extension of UIViewController
     */
    @objc func cancelWork(_ sender:UIButton)
    {
        if sender.tag == 0 {
            sender.tag = 1
        }
    }
    
    /**
     Returns the button from the extension of UIViewController that adds the loading container view
     */
    var loadingButton:UIButton?
    {
        get {
            guard let button = loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UIButton) != nil
            }).first as? UIButton else {
                return nil
            }

            button.isHidden = false
            if self.loadingContainer?.tag < 100 {
                self.loadingContainer?.tag = 101
            }
            
            button.addTarget(self, action: #selector(cancelWork(_:)), for: .touchUpInside)
            
            return button
        }
    }
    
    /**
     Returns the label from the extension of UIViewController that adds the loading container view
     */
    var loadingLabel:UILabel?
    {
        get {
            return loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UILabel) != nil
            }).first as? UILabel
        }
    }
    
    /**
     Returns the UIActivityIndicatorView from the extension of UIViewController that adds the loading container view
     */
    var loadingActivity:UIActivityIndicatorView?
    {
        get {
            return loadingView?.subviews.filter({ (view:UIView) -> Bool in
                return (view as? UIActivityIndicatorView) != nil
            }).first as? UIActivityIndicatorView
        }
    }
    
    /**
     Removes the loading container view that was added in the extension of UIViewController above
     */
    func stopAnimating()
    {
        Thread.onMain {
            self.loadingContainer?.removeFromSuperview()
        }
    }
    
    /**
     Starts animating the activity indicator in the loading container view that was added in the extension of UIViewController above
     */
    func startAnimating(allowTouches:Bool = false)
    {
        Thread.onMain {
            if allowTouches {
                self.loadingContainer?.backgroundColor = UIColor.clear
                self.loadingContainer?.tag = 102
            }
            
            self.loadingContainer?.isHidden = false
            self.loadingView?.isHidden = false
            self.loadingActivity?.startAnimating()
        }
    }
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
    /**
     Extension of UITextView to make a specific range in the text visible
     */
    func scrollRangeToVisible(_ range:Range<String.Index>)
    {
        Thread.onMain {
            let nsRange = NSRange(range, in: self.attributedText.string)
            self.scrollRangeToVisible(nsRange)
        }
    }
}

extension String
{
    /**
     Extension of String to mark a string based on search text that may partially match a word at the end of the string.
     */
    func markTrailing(searchText:String?) -> NSAttributedString?
    {
        var workingString = self
        
        guard !workingString.isEmpty else {
            return nil
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return NSAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        }
        
        let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        
        let range = NSRange(location: 0, length: workingString.utf16.count)
        
        let words = searchText.components(separatedBy: Constants.SINGLE_SPACE).map { (substring) -> String in
            String(substring)
        }
        
        if words.count > 1 {
            var strings = [String]()
            var phrase : String?
            
            // Assemble the list of "less than the full phrase" phrases to look for.
            for i in 0..<words.count {
                if i == (words.count - 1) {
                    break
                }
                
                if phrase == nil {
                    phrase = words[i]
                } else {
                    phrase = (phrase ?? "") + " " + words[i]
                }
                
                if let phrase = phrase {
                    strings.append(phrase)
                }
            }
            
            // reverse them since we want to look for the longest first.
            strings.reverse()
            
            // Now look for them.
            var found = false
            
            for string in strings {
                if let regex = try? NSRegularExpression(pattern: "\\b" + string + "\\b", options: .caseInsensitive) {
                    let matches = regex.matches(in: workingString, options: .withTransparentBounds, range: range)
                    if matches.count > 0 {
                        for match in matches {
                            if match.range.upperBound == workingString.endIndex.utf16Offset(in: workingString) {
                                attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                                             range: match.range)
                                found = true
                                break
                            } else {
                                
                            }
                        }
                    } else {

                    }
                }
                
                if found {
                    break
                }
            }
            
            if !found {
                if let string = strings.first {
                    if let last = workingString.components(separatedBy: " ").last, last.range(of: string, options: .caseInsensitive) != nil {
                        var list = workingString.lowercased().components(separatedBy: " ")
                        list.removeLast()
                        let first = list.joined(separator: " ") + " "
                        if let firstRange = workingString.range(of: first) {
                            attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                                         range: NSRange(location: firstRange.upperBound.utf16Offset(in: workingString), length: last.count))
                            found = true
                        }
                    }
                }
            }
        }
        
        return attributedText
    }
    
    /**
     Extension of String to mark a string based on search text.  May be interrupted.
     */
    func markedBySearch(searchText:String?, wholeWordsOnly:Bool, test : (()->Bool)?) -> NSAttributedString?
    {
        var workingString = self
        
        guard !workingString.isEmpty else {
            return nil
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return NSAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        }
        
        guard wholeWordsOnly else {
            let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
            
            let range = NSRange(location: 0, length: workingString.utf16.count)
            
            if let regex = try? NSRegularExpression(pattern: searchText, options: .caseInsensitive) {
                let matches = regex.matches(in: workingString, options: .withTransparentBounds, range: range)
                    
                if matches.count > 0 {
                    matches.forEach {
                        attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                                     range: $0.range)
                    }
                } else {
                    return self.markTrailing(searchText: searchText)
                }
            }
            
            return attributedText
        }
        
        let attributedText = NSMutableAttributedString(string: workingString, attributes: Constants.Fonts.Attributes.body)
        
        let range = NSRange(location: 0, length: workingString.utf16.count)
        
        if let regex = try? NSRegularExpression(pattern: "\\b" + searchText + "\\b", options: .caseInsensitive) {
            let matches = regex.matches(in: workingString, options: .withTransparentBounds, range: range)
            
            if matches.count > 0 {
                matches.forEach {
                    attributedText.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.yellow],
                                                 range: $0.range)
                }
            } else {
                return self.markTrailing(searchText: searchText)
            }
        }
        
        return attributedText
    }
    
    /**
     Extension of String to return an attributed string that is highlighted to show searchText.
     */
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
    }
    
    /**
     Extension of String to return an attributed string that is bold highlighted to show searchText.
     */
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
    }
}

extension String
{
    /**
     Extension of String that is assuemd to be a book fo the bible and reutrns the number of that book in the Bible.
     */
    var bookNumberInBible : Int
    {
        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: self) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: self) {
            return Constants.OLD_TESTAMENT_BOOKS.count + index
        }
        
        return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
    }

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
    /**
     Extension of String that is assuemd to be a search context and returns the category.
     */
    var category : String?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return self.components(separatedBy: "|").filter({ (component:String) -> Bool in
                return component.components(separatedBy: ":").first == "CATEGORY"
            }).first?.components(separatedBy: ":").last
        }
    }
    
    /**
     Extension of String that is assuemd to be a search context and returns the tag.
     */
    var tag : String?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return self.components(separatedBy: "|").filter({ (component:String) -> Bool in
                return component.components(separatedBy: ":").first == "TAG"
            }).first?.components(separatedBy: ":").last
        }
    }
    
    /**
     Extension of String that is assuemd to be a search context and returns whether transcripts are being searched.
     */
    var transcripts : Bool
    {
        get {
            guard !self.isEmpty else {
                return false
            }
            
            return self.components(separatedBy: "|").filter({ (component:String) -> Bool in
                return component.components(separatedBy: ":").first == "TRANSCRIPTS"
            }).first != nil
        }
    }
    
    /**
     Extension of String that is assuemd to be a search context and returns the searchText.
     */
    var searchText : String?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return self.components(separatedBy: "|").filter({ (component:String) -> Bool in
                return component.components(separatedBy: ":").first == "SEARCH"
            }).first?.components(separatedBy: ":").last
        }
    }
    
    /**
     Extension of String that is assuemd to be a name and returns the lastname.
     */
    var lastName : String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let firstName = self.firstName else {
            return nil
        }
        
        if let range = self.range(firstName) {
            return String(self[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            return nil
        }
    }
    
    /**
     Extension of String that is assuemd to be a number and returns the int of it divided by 100 and times 100.
     */
    var century : String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let string = self.components(separatedBy: "\n").first else {
            return nil
        }
        
        if let number = Int(string) {
            let value = number/100 * 100
            return "\(value == 0 ? 1 : value)"
        }
        
        return nil
    }
    
    /**
     Extension of String that is assuemd to be a number and returns the log base 10 of it.
     */
    var log : String?
    {
//        guard !self.isEmpty else {
//            return nil
//        }
//
//        let strings = self.components(separatedBy: Constants.SINGLE_SPACE)
//
//        guard strings.count > 1 else {
//            return nil
//        }
//
//        guard let string = strings.last?.trimmingCharacters(in: CharacterSet(charactersIn: "()")) else {
//            return nil
//        }
        
        if let frequency = self.frequency { // Double(string)
            let value = Int(log10(Double(frequency)))
            return pow(10,value+1).description
        }
        
        return nil
    }
    
    /**
     Extension of String that is assuemd to be a name and returns the firstname.
     */
    var firstName : String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    
    /**
     Extension of String that is assuemd to be a name and returns the title.
     */
    var title : String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        let titles = ["DR."]
        
        var title = Constants.EMPTY_STRING
        
        if self.range(of: ". ") != nil {
            for char in self {
                title.append(char)
                if String(char) == "." {
                    break
                }
            }
        }
        
        if !title.isEmpty, titles.contains(title.uppercased()) {
            return title
        } else {
            return nil
        }
    }
}

extension String
{
    /**
     Extension of String that cuts a portion out and returns the modified string.
     */
    func snip(_ start:String,_ stop:String) -> String
    {
        var bodyString = self
        
        while bodyString.range(of: start) != nil {
            if let startRange = bodyString.range(of: start) {
                if let endRange = String(bodyString[startRange.lowerBound...]).range(of: stop) {
                    let to = String(bodyString[..<startRange.lowerBound])
                    
                    let from = String(String(bodyString[startRange.lowerBound...])[endRange.upperBound...])
                    
                    bodyString = to + from
                }
            }
        }
        
        return bodyString
    }

    /**
     Extension of String that removes links from a portion and returns the modified string.
     */
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
    
    /**
     Extension of String that strips links.
     */
    var stripLinks : String
    {
        var bodyString = self
        
        bodyString = bodyString.snipLinks("<div>Locations","</div>")
        
        bodyString = bodyString.replacingOccurrences(of: "<a href=\"#index\">Index</a><br/>", with: "")
        
        bodyString = bodyString.snipLinks("<a",">")
        
        bodyString = bodyString.replacingOccurrences(of: "</a>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "(Return to Top)", with: "")
        
        return bodyString
    }
    
    /**
     Extension of String that strips html.
     */
    var stripHTML : String
    {
        var bodyString = self.stripHead.stripLinks
        
        bodyString = bodyString.replacingOccurrences(of: "<!DOCTYPE html>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "<html>", with: "")
        
        bodyString = bodyString.replacingOccurrences(of: "<body>", with: "")
        
        bodyString = bodyString.snip("<p class=\"copyright\">","</p>")
        
        bodyString = bodyString.snip("<script>","</script>")
        
        bodyString = bodyString.snip("<noscript>","</noscript>")
        
        bodyString = bodyString.snip("<p ",">")
        
        bodyString = bodyString.snip("<br ",">")
        
        bodyString = bodyString.snip("<span ",">")
        
        bodyString = bodyString.snip("<font ",">")
        
        bodyString = bodyString.snip("<sup>","</sup>")
        
        bodyString = bodyString.snip("<sup ", "</sup>")
        
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
        
        return bodyString.trimmingCharacters(in: CharacterSet(charactersIn: Constants.SINGLE_SPACE))
    }
    
    /**
     Extension of String that is assumed html and marks it.  Can be interrupted.
     */
    func markHTML(headerHTML:String?, searchText:String?, wholeWordsOnly:Bool, lemmas:Bool = false, index:Bool, test:(()->(Bool))? = nil) -> (String?,Int)
    {
        if let headerHTML = headerHTML {
            let markedHTML = self.markHTML(searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
            return (markedHTML.0?.replacingOccurrences(of: "<body>", with: "<body>"+headerHTML+"<br/>"),markedHTML.1)
        } else {
            return self.markHTML(searchText: searchText, wholeWordsOnly: wholeWordsOnly, lemmas:lemmas, index: index)
        }
    }

    /**
     Extension of String that is assumed html and marks it.  Can be interrupted.
     */
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
                        if lemma.1?.lowercased() == searchText.lowercased() {
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
            
//            var stringBefore:String = Constants.EMPTY_STRING
//            var stringAfter:String = Constants.EMPTY_STRING
//            var newString:String = Constants.EMPTY_STRING
//            var foundString:String = Constants.EMPTY_STRING
//
//            while (string.lowercased().range(of: searchText.lowercased()) != nil) {
//                guard let range = string.lowercased().range(of: searchText.lowercased()) else {
//                    break
//                }
//
//                stringBefore = String(string[..<range.lowerBound])
//                stringAfter = String(string[range.upperBound...])
//
//                var skip = false
//
//                if wholeWordsOnly {
//                    if stringBefore == "" {
//                        if  let characterBefore:Character = newString.last,
//                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
//                            if CharacterSet.letters.contains(unicodeScalar) {
//                                skip = true
//                            }
//
//                            if searchText.count == 1 {
//                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
//                                    skip = true
//                                }
//                            }
//                        }
//                    } else {
//                        if  let characterBefore:Character = stringBefore.last,
//                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
//                            if CharacterSet.letters.contains(unicodeScalar) {
//                                skip = true
//                            }
//
//                            if searchText.count == 1 {
//                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES).contains(unicodeScalar) {
//                                    skip = true
//                                }
//                            }
//                        }
//                    }
//
//                    if let characterAfter:Character = stringAfter.first {
//                        if  let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) {
//                            skip = true
//                        } else {
//
//                        }
//
//                        if let unicodeScalar = UnicodeScalar(String(characterAfter)) {
//                            if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(unicodeScalar) {
//                                if stringAfter.endIndex > stringAfter.startIndex {
//                                    let nextChar = stringAfter[stringAfter.index(stringAfter.startIndex, offsetBy:1)]
//
//                                    if let unicodeScalar = UnicodeScalar(String(nextChar)) {
//                                        skip = CharacterSet.letters.contains(unicodeScalar)
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                    if let characterBefore:Character = stringBefore.last {
//                        if  let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) {
//                            skip = true
//                        }
//                    }
//                }
//
//                foundString = String(string[range.lowerBound...])
//                if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
//                    foundString = String(foundString[..<newRange.upperBound])
//                }
//
//                if !skip {
//                    markCounter += 1
//                    foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
//                }
//
//                newString += stringBefore + foundString
//
//                stringBefore += foundString
//
//                string = stringAfter
//            }
//
//            newString = newString + stringAfter
//
//            return newString == Constants.EMPTY_STRING ? string : newString
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
    /**
     Extension of String that returns an array of (token, count) pairs.
     */
    var tokensCounts : [(String,Int)]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }
        
        guard !self.isEmpty else {
            return nil
        }
        
        var tokenCounts = [(String,Int)]()
        
        if let tokens = self.tokens {
            for token in tokens {
                var count = 0
                var string = self
                
                while let range = string.range(of: token, options: .caseInsensitive, range: nil, locale: nil) {
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
    
    /**
     Extension of String that returns a dictionary of tokens and their counts.
     */
    // Make thread safe?
    var tokensAndCounts : [String:Int]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }
        
        guard !self.isEmpty else {
            return nil
        }
        
        if #available(iOS 12.0, *) {
            return nlTaggerTokensAndCounts
        } else {
            return nsTaggerTokensAndCounts
        }
        
//        var tokens = [String:Int]()
//
//        var str = self // .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) //.replacingOccurrences(of: "\r\n", with: " ")
//
//        // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
//
//        for partPreamble in Constants.PART_PREAMBLES {
//            if let range = str.range(of: partPreamble + Constants.PART_INDICATOR) {
//                str = String(str[..<range.lowerBound])
//            }
//            break
//        }
//
//        var token = Constants.EMPTY_STRING
//
//        func processToken()
//        {
//            token = token.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//
//            let excludedWords = [String]() // ["and", "are", "can", "for", "the"]
//
//            for word in excludedWords {
//                if token.lowercased() == word.lowercased() {
//                    token = Constants.EMPTY_STRING
//                    break
//                }
//            }
//
//            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars)) {
//                token = token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars))
//            }
//
//            if !token.isEmpty {
//                if let count = tokens[token.uppercased()] {
//                    tokens[token.uppercased()] = count + 1
//                } else {
//                    tokens[token.uppercased()] = 1
//                }
//
//                token = Constants.EMPTY_STRING
//            }
//        }
//
//        for index in str.indices {
//            //        print(char)
//
//            var skip = false
//
//            let char = str[index]
//
//            if let charUnicodeScalar = UnicodeScalar(String(char)) {
//                if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(charUnicodeScalar) {
//                    if str.endIndex > str.index(index, offsetBy:1) {
//                        let nextChar = str[str.index(index, offsetBy:1)]
//
//                        if let unicodeScalar = UnicodeScalar(String(nextChar)) {
//                            skip = CharacterSet.letters.contains(unicodeScalar)
//                        }
//                    }
//                }
//            }
//
//            if let unicodeScalar = UnicodeScalar(String(char)) {
//                if !CharacterSet.letters.contains(unicodeScalar), !skip {
//                    processToken()
//                } else {
//                    token.append(char)
//                }
//            }
//
//            if Globals.shared.isRefreshing {
//                break
//            }
//        }
//
//        if !token.isEmpty {
//            processToken()
//        }
//
//        return tokens.count > 0 ? tokens : nil
    }
    
    /**
     Extension of String that returns an array of tokens.
     */
    var tokens : [String]?
    {
        guard !Globals.shared.isRefreshing else {
            return nil
        }

        guard !self.isEmpty else {
            return nil
        }
        
        if #available(iOS 12.0, *) {
            return nlTaggerTokens
        } else {
            return nsTaggerTokens
        }

//        var tokens = Set<String>()
//
//        var str = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\r\n", with: " ")
//
//        for partPreamble in Constants.PART_PREAMBLES {
//            if let range = str.range(of: partPreamble + Constants.PART_INDICATOR) {
//                str = String(str[..<range.lowerBound])
//            }
//            break
//        }
//
//        var token = Constants.EMPTY_STRING
//
//        func processToken()
//        {
//            let excludedWords = [String]() //["and", "are", "can", "for", "the"]
//
//            for word in excludedWords {
//                if token.lowercased() == word.lowercased() {
//                    token = Constants.EMPTY_STRING
//                    break
//                }
//            }
//
//            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars)) {
//                //                print("\(token)")
//                token = token.trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TrimChars))
//                //                print("\(token)")
//            }
//
//            if !token.isEmpty {
//                tokens.insert(token.uppercased())
//                token = Constants.EMPTY_STRING
//            }
//        }
//
//        for index in str.indices {
//            var skip = false
//
//            let char = str[index]
//
//            if let charUnicodeScalar = UnicodeScalar(String(char)) {
//                if CharacterSet(charactersIn: Constants.RIGHT_SINGLE_QUOTE + Constants.SINGLE_QUOTE).contains(charUnicodeScalar) {
//                    if str.endIndex > str.index(index, offsetBy:1) {
//                        let nextChar = str[str.index(index, offsetBy:1)]
//
//                        if let unicodeScalar = UnicodeScalar(String(nextChar)) {
//                            skip = CharacterSet.letters.contains(unicodeScalar)
//                        }
//                    }
//                }
//            }
//
//            if let unicodeScalar = UnicodeScalar(String(char)) {
//                if !CharacterSet.letters.contains(unicodeScalar), !skip {
//                    processToken()
//                } else {
//                    token.append(char)
//                }
//            }
//
//            if Globals.shared.isRefreshing {
//                break
//            }
//        }
//
//        if !token.isEmpty {
//            processToken()
//        }
//
//        let tokenArray = Array(tokens).sorted() {
//            $0.lowercased() < $1.lowercased()
//        }
//
//        return tokenArray.count > 0 ? tokenArray : nil
    }
}

extension String
{
    /**
     Extension of String that returns the substring up to another string.
     */
    func subString(to: String) -> String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        guard let range = self.range(of: to) else {
            return nil
        }
        
        return String(self[..<range.lowerBound])
    }
    
    /**
     Extension of String that looks for a string pattern at the end of the string, i.e. a fileType (in the old model) if the string is a filename.
     */
    func isFileType(_ fileType:String) -> Bool
    {
        guard !self.isEmpty else {
            return false
        }
        
        let file = self
        
        if let range = file.range(of: fileType), file[range.lowerBound...] == fileType {
            return true
        } else {
            return false
        }
    }
    
    /**
     Extension of String that creates a URL from the string.
     */
    var url : URL?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return URL(string: self)
        }
    }

    /**
     Extension of String that creates a URL from the string.

     If the string and the lastPathComponent of the URL made from the string are the same, then use the string
     as the filename in the caches directory as the fileSystemURL, otherwise create a fileSystemURL from the url,
     which amounts to lastPathComponent of the URL as the filename in the caches directory.
     */
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
            
            return url?.fileSystemURL
        }
    }

    /**
     Extension of String that saves it in a specified file of name filename in the cache directory in utf8 format.
     */
    func save8(filename:String?)
    {
        guard !self.isEmpty else {
            return
        }
        
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
    
    /**
     Extension of String that saves it in a specified file of name filename in the cache directory in utf16 format.
     */
    func save16(filename:String?)
    {
        guard !self.isEmpty else {
            return
        }
        
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
    
    /**
     Extension of String class that loads a specified file of name filename in the cache directory in utf16 format and returns the string.
     */
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
    
    /**
     Extension of String class that loads a specified file of name filename in the cache directory in utf8 format and returns the string.
     */
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
    
    /**
     Extension of String that returns the string's data in utf16 format.
     */
    var data16 : Data?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return self.data(using: String.Encoding.utf16, allowLossyConversion: false)
        }
    }
    
    /**
     Extension of String that returns the string's data in utf8 format.
     */
    var data8 : Data?
    {
        get {
            guard !self.isEmpty else {
                return nil
            }
            
            return self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        }
    }
}

extension String
{
    var html2AttributedString: NSAttributedString?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        return self.data16?.html2AttributedString // (using: String.Encoding.utf16)
    }
    
    var html2String: String?
    {
        guard !self.isEmpty else {
            return nil
        }
        
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
    @available(iOS 12.0, *)
    var nlLemmas : [(String,String?,Range<String.Index>)]?
    {
        guard !self.isEmpty else {
            return nil
        }
        
        var tokens = [(String,String?,Range<String.Index>)]()
        
        let tagSchemes = NLTagger.availableTagSchemes(for: .word, language: .english)
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]

        let tagger = NLTagger(tagSchemes: tagSchemes)
        tagger.string = self
        
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .lemma, options: options) { (tag:NLTag?, range:Range<String.Index>) -> Bool in
            let token = String(self[range])
            tokens.append((token,tag?.rawValue,range))
            return true
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    @available(iOS 12.0, *)
    var nlTokenTypes : [(String,String,Range<String.Index>)]?
    {
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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

    // Make thread safe?
    @available(iOS 12.0, *)
    var nlTaggerTokensAndCounts : [String:Int]?
    {
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

        var tokens = [(String,String,NSRange)]()
        
        let tagSchemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let options:NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames]
        
        let tagger = NSLinguisticTagger(tagSchemes: tagSchemes, options: Int(options.rawValue))
        tagger.string = self
        
        var ranges : NSArray?
        
        let tags = tagger.tags(in: NSRange(location: 0, length: (self as NSString).length), scheme: NSLinguisticTagScheme.lemma.rawValue, options: options, tokenRanges: &ranges)
        
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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        guard !self.isEmpty else {
            return nil
        }

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
        
        for lexicalType in lexicalTypes {
            
            guard test?() != true else {
                return nil
            }
            
            if let color = lexicalTypeColors[lexicalType] {
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(lexicalType)</td></tr>"
                htmlString += "</table>"
             
                if lexicalType != lexicalTypes.last {
                    htmlString += " "
                }
            }
        }
        
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
            
            if let color = lexicalTypeColors[nameOrLexicalType] {
                var htmlString = String()
                
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(token)</td></tr>"
                if annotated {
                    htmlString += "<tr><td style=\"font-size:75%;background-color:\(color)\">\(nameOrLexicalType)</td></tr>"
                }
                htmlString += "</table>"
                
                text = text + before + htmlString
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
    /**
     Extension of URL to return files
    */
    func files(startingWith filename:String? = nil,ofType fileType:String? = nil,notOfType notFileType:String? = nil) -> [String]?
    {
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
    
    /**
     Extension of URL to return the fileSystemURL (i.e. same name but in caches directory)
     */
    var fileSystemURL : URL?
    {
        return self.lastPathComponent.fileSystemURL
    }

    /**
     Extension of URL to return the file's size
     */
    var fileSize:Int?
    {
        guard let fileSystemURL = fileSystemURL else {
            return nil
        }
        
        guard fileSystemURL.exists else {
            debug("File does not exist at \(fileSystemURL.absoluteString)")
            return 0
        }

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
    
    /**
     Extension of URL to return whether it exists
     */
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

    /**
     Extension of URL to copy a file at self into the fileSystemURL location i.e. same name in cache directory
     */
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
    
    /**
     Extension of URL to return string in file using utf16 format.
     */
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
    
    /**
     Extension of URL to return string in file using utf8 format.
     */
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
    
    /**
     Extension of URL to return data.
     */
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
    
    /**
     Extension of URL to delete file.
     */
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
    
    /**
     Extension of URL to return image and then process it in a closure.
     */
    func image(block:((UIImage)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    /**
     Extension of URL to return image.
     */
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
    /**
     Extension of UIImage to save it.
     */
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
    
    /**
     Extension of UIImage to resize it.
     */
    func resize(scale:CGFloat) -> UIImage?
    {
        let toScaleSize = CGSize(width: scale * self.size.width, height: scale * self.size.height)
        
        UIGraphicsBeginImageContextWithOptions(toScaleSize, true, self.scale)
        
        self.draw(in: CGRect(x: 0, y: 0, width: scale * self.size.width, height: scale * self.size.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    /**
     Extension of UIImage to return it in a PDFPage.
     */
    @available(iOS 11.0, *)
    var page : PDFPage?
    {
        get {
            return PDFPage(image: self)
        }
    }
    
    /**
     Extension of UIImage to return it in a PDF.
     */
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
    /**
     Extension of Data to save it to a URL.
     */
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
    
    /**
     Extension of Data to return it as json.
     */
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
    
    /**
     Extension of Data to return it as a string in utf16 format.
     */
    var string16 : String?
    {
        get {
            return String.init(data: self, encoding: String.Encoding.utf16)
        }
    }
    
    /**
     Extension of Data to return it as a string in utf8 format.
     */
    var string8 : String?
    {
        get {
            return String.init(data: self, encoding: String.Encoding.utf8)
        }
    }
    
    /**
     Extension of Data to return it as an image.
     */
    var image : UIImage?
    {
        get {
            return UIImage(data: self)
        }
    }
    
    /**
     Extension of Data to return it as a PDF.
     */
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
    /**
     Extension of PDF to return it as data.
     */
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


