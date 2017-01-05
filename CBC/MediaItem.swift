//
//  MediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class MediaItem : NSObject, URLSessionDownloadDelegate, XMLParserDelegate {
    var dict:[String:String]?
    
    var booksChaptersVerses:BooksChaptersVerses?
    
    var notesTokens:[(String,Int)]?
    
    var singleLoaded = false

    func freeMemory()
    {
        notesHTML = nil
        notesTokens = nil
        
        booksChaptersVerses = nil
    }
    
    init(dict:[String:String]?)
    {
        super.init()
//        print("\(dict)")
        self.dict = dict
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaItem.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.audio
        download.downloadURL = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Purpose.audio] = download
        return download
        }()
    
    lazy var videoDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.video
        download.downloadURL = self.videoURL
        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Purpose.video] = download
        return download
        }()
    
    lazy var slidesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.slides
        download.downloadURL = self.slidesURL
        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Purpose.slides] = download
        return download
        }()
    
    lazy var notesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.notes
        download.downloadURL = self.notesURL
        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Purpose.notes] = download
        return download
        }()
    
    lazy var outlineDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.outline
        download.downloadURL = self.outlineURL
        download.fileSystemURL = self.outlineFileSystemURL
        self.downloads[Purpose.outline] = download
        return download
        }()
    
//    required convenience init?(coder decoder: NSCoder)
//    {
//        guard
//            
//            let dict = decoder.decodeObjectForKey(Constants.DICT) as? [String:String]
//            
//            else {
//                return nil
//            }
//        
//        self.init(dict: dict)
//    }
//    
//    func encodeWithCoder(coder: NSCoder) {
//        coder.encodeObject(self.dict, forKey: Constants.DICT)
//    }
    
    var id:String! {
        get {
            return dict![Field.id]
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in id.characters {
                if Int(String(char)) != nil {
                    break
                }
                chars.append(char)
            }
            
            return chars
        }
    }
    
    var serviceCode:String {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            let afterDate = afterClassCode.substring(from: ymd.endIndex)
            
            let code = afterDate.substring(to: "x".endIndex)
            
            //        print(code)
            
            return code
        }
    }
    
    var conferenceCode:String? {
        get {
            if serviceCode == "s" {
                let afterClassCode = id.substring(from: classCode.endIndex)
                
                var string = id.substring(to: classCode.endIndex)
                
                let ymd = "YYMMDD"
                
                string = string + afterClassCode.substring(to: ymd.endIndex)
                
                let s = "s"
                
                let code = string + s
                
                //            print(code)
                
                return code
            }
            
            return nil
        }
    }
    
    var repeatCode:String? {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            var string = id.substring(to: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            string = string + afterClassCode.substring(to: ymd.endIndex) + serviceCode
            
            let code = id.substring(from: string.endIndex)
            
            if code != Constants.EMPTY_STRING  {
                //            print(code)
                return code
            } else {
                return nil
            }
        }
    }
    
    var multiPartMediaItems:[MediaItem]? {
        get {
            if (hasMultipleParts) {
                var mediaItemParts:[MediaItem]?
//                print(multiPartSort)
                if (globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL] == nil) {
                    mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })

                } else {
                    mediaItemParts = globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
                // Filter for conference series
                if conferenceCode != nil {
                    return sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.conferenceCode == conferenceCode
                    }),sorting: Sorting.CHRONOLOGICAL)
                } else {
                    return sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        //                        print(classCode,testMediaItem.classCode)
                        return testMediaItem.classCode == classCode
                    }),sorting: Sorting.CHRONOLOGICAL)
                }
            } else {
                return [self]
            }
        }
    }
    
    func searchStrings() -> [String]?
    {
        var array = [String]()
        
        if hasSpeaker {
            array.append(speaker!)
        }
        
        if hasMultipleParts {
            array.append(multiPartName!)
        } else {
            array.append(title!)
        }
        
        if books != nil {
            array.append(contentsOf: books!)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if tagsArray != nil {
            for tag in tagsArray! {
                if let tokens = tokensFromString(tag) {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = firstNameFromName(speaker) {
                set.insert(firstname)
            }

            if let lastname = lastNameFromName(speaker) {
                set.insert(lastname)
            }
        }
        
        if books != nil {
            set = set.union(Set(books!))
        }
        
        if let titleTokens = tokensFromString(title) {
            set = set.union(Set(titleTokens))
        }
        
        return set.count > 0 ? Array(set).map({ (string:String) -> String in
                return string.uppercased()
            }).sorted() : nil
    }
    
    func search(searchText:String?) -> Bool
    {
        if searchText != nil {
            return  ((title?.range(of:      searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((date?.range(of:       searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((speaker?.range(of:    searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((scripture?.range(of:  searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((tags?.range(of:       searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)

//            ((id?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
//            ((multiPartName?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||

        } else {
            return false
        }
    }
    
    
    
    func searchFullNotesHTML(searchText:String?) -> Bool
    {
        if searchText != nil {
            if hasNotesHTML {
                loadNotesHTML()
                return stripHead(fullNotesHTML)?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func mediaItemsInCollection(_ tag:String) -> [MediaItem]?
    {
        var mediaItems:[MediaItem]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            mediaItems = globals.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL? {
        get {
            var url:URL?
            
            switch playing! {
            case Playing.audio:
                url = audioFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = audioURL
                }
                break
                
            case Playing.video:
                url = videoFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = videoURL
                }
                break
                
            default:
                break
            }
            
            return url
        }
    }
    
    var isPlaying:Bool {
        get {
            return globals.mediaPlayer.url == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String? {
        get {
            if (dict![Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict![Field.playing] = playing
                } else {
                    dict![Field.playing] = Playing.audio
                }
            }
            return dict![Field.playing]
        }
        
        set {
            if newValue != dict![Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict![Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var wasShowing:String? = Showing.slides //This is an arbitrary choice
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict![Field.showing] = showing
                } else {
                    if (hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.notes
                    }
                    if (hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.none
                    }
                }
            }
            return dict![Field.showing]
        }
        
        set {
            if newValue != Showing.video {
                wasShowing = newValue
            }
            dict![Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var download:Download? {
        get {
            if showing != nil {
                return downloads[showing!]
            } else {
                return nil
            }
        }
    }
    
    var atEnd:Bool {
        get {
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] {
                dict![Constants.SETTINGS.AT_END+playing!] = atEnd
            } else {
                dict![Constants.SETTINGS.AT_END+playing!] = "NO"
            }
            return dict![Constants.SETTINGS.AT_END+playing!] == "YES"
        }
        
        set {
            dict![Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
        }
    }
    
    var webLink : String? {
        get {
            
            if let body = bodyHTML(order: ["title","scripture","speaker"], includeURLs: false, includeColumns: false), let urlString = websiteURL?.absoluteString {
                return body + "\n\n" + urlString
            } else {
                return nil
            }
        }
    }
    
    var websiteURL:URL? {
        get {
            return URL(string: Constants.CBC.SINGLE_WEBSITE + id)
        }
    }
    
    var downloadURL:URL? {
        get {
            return download?.downloadURL
        }
    }
    
    var fileSystemURL:URL? {
        get {
            return download?.fileSystemURL
        }
    }
    
    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (Float(currentTime!) != nil)
    }
    
    var currentTime:String? {
        get {
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = current_time
            } else {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = "\(0)"
            }
//            print(dict![Constants.SETTINGS.CURRENT_TIME+playing!])
            return dict![Constants.SETTINGS.CURRENT_TIME+playing!]
        }
        
        set {
            dict![Constants.SETTINGS.CURRENT_TIME+playing!] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] = newValue 
            }
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName!
            } else {
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if (fullDate != nil) {
                return (Calendar.current as NSCalendar).components(.year, from: fullDate!).year
            }
            return nil
        }
    }
    
    var yearSection:String!
    {
        get {
            return yearString
        }
    }
    
    var yearString:String! {
        get {
            if (year != nil) {
                return "\(year!)"
            } else {
                return "None"
            }
        }
    }

    func singleJSONFromURL() -> JSON
    {
        do {
            let data = try Data(contentsOf: URL(string: Constants.JSON.URL.SINGLE + self.id!)!) // , options: NSData.ReadingOptions.mappedIfSafe
            
            let json = JSON(data: data)
            if json != JSON.null {
                
                print(json)
                return json
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
    func loadSingleDict() -> [String:String]?
    {
        var mediaItemDicts = [[String:String]]()
        
        let json = singleJSONFromURL() // jsonDataFromDocumentsDirectory()
        
        if json != JSON.null {
            print("single json:\(json)")
            
            let mediaItems = json[Constants.JSON.ARRAY_KEY.SINGLE_ENTRY]
            
            for i in 0..<mediaItems.count {
                
                var dict = [String:String]()
                
                for (key,value) in mediaItems[i] {
                    dict["\(key)"] = "\(value)"
                }
                
                mediaItemDicts.append(dict)
            }
            
            print(mediaItemDicts)
            
            return mediaItemDicts.count > 0 ? mediaItemDicts[0] : nil
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func loadNotesHTML()
    {
        guard hasNotesHTML else {
            return
        }
        
        if dict![Field.notes_HTML] == nil {
            if let mediaItemDict = self.loadSingleDict() {
                dict![Field.notes_HTML] = mediaItemDict[Field.notes_HTML]
            } else {
                print("loadSingle failure")
            }
        }
    }
    
    func loadNotesTokens()
    {
        guard hasNotesHTML else {
            return
        }
        
        guard (notesTokens == nil) else {
            return
        }
        
        loadNotesHTML()

        notesTokens = tokenCountsFromString(notesHTML)
        
//        var tokens = Set<String>()
   
//        if let searchTokens = searchTokens() {
//            tokens = tokens.union(Set(searchTokens))
//        }
        
//        if let notesTokens = tokensFromString(notesHTML) {
//            tokens = tokens.union(Set(notesTokens))
//        }
//        
//        let tokenArray = Array(tokens).sorted()
        
        //                        print(tokenArray)
        
//        notesTokens = tokenArray.count > 0 ? tokenArray : nil
    }
    
    func formatDate(_ format:String?) -> String? {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(for: fullDate)
    }
    
    var formattedDate:String? {
        get {
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String? {
        get {
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String? {
        get {
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String? {
        get {
            return formatDate("yyyy")
        }
    }
    
    var date:String? {
        get {
            return dict![Field.date]?.substring(to: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.lowerBound) // last two characters // dict![Field.title]
        }
    }
    
    var service:String? {
        get {
            return dict![Field.date]?.substring(from: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.upperBound) // last two characters // dict![Field.title]
        }
    }
    
    var title:String? {
        get {
            return dict![Field.title]
        }
    }
    
    var category:String? {
        get {
            return dict![Field.category]
        }
    }
    
    var scripture:String? {
        get {
            return dict![Field.scripture]
        }
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError.localizedDescription)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
//        print(elementName)
    }

    var book:String?
    var chapter:String?
    var verse:String?
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print(elementName)
        
        if scriptureText == nil {
            scriptureText = [String:[String:[String:String]]]()
        }
        
        switch elementName {
        case "bookname":
            book = xmlString

            if scriptureText?[book!] == nil {
                scriptureText?[book!] = [String:[String:String]]()
            }
            break
            
        case "chapter":
            chapter = xmlString

            if scriptureText?[book!]?[chapter!] == nil {
                scriptureText?[book!]?[chapter!] = [String:String]()
            }
            break
            
        case "verse":
            verse = xmlString
            break
            
        case "text":
            scriptureText?[book!]?[chapter!]?[verse!] = xmlString
//            print(scriptureText)
            break
            
        default:
            break
        }

        xmlString = nil
    }

    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
//        print(elementName)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        print(string)
        xmlString = (xmlString != nil ? xmlString! + string : string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var xmlParser:XMLParser?
    var xmlString:String?
    
    var scriptureTextHTML:String? {
        get {
            guard scriptureText != nil else {
                return nil
            }
            
            var bodyString:String?
            
            bodyString = "<!DOCTYPE html><html><body>"

            bodyString = bodyString! + "Scripture: " + scripture! + "<br/>"

            if let books = scriptureText?.keys.sorted(by: {
                bookNumberInBible($0) < bookNumberInBible($1)
            }) {
                for book in books {
                    bodyString = bodyString! + book + "<br/>"
                    if let chapters = scriptureText?[book]?.keys.sorted(by: { Int($0) < Int($1) }) {
                        for chapter in chapters {
                            bodyString = bodyString! + "Chapter " + chapter + "<br/>"
                            if let verses = scriptureText?[book]?[chapter]?.keys.sorted(by: { Int($0) < Int($1) }) {
                                for verse in verses {
                                    if let text = scriptureText?[book]?[chapter]?[verse] {
                                        bodyString = bodyString! + "<sup>" + verse + "</sup>" + text + " "
                                    } // <font size=\"-1\"></font>
                                }
                                bodyString = bodyString! + "<br/>"
                            }
                        }
                    }
                }
            }
            
            bodyString = bodyString! + "</html></body>"

            return bodyString
        }
    }
    
    func loadScriptureText()
    {
        guard scripture != Constants.Selected_Scriptures else {
            return
        }
        
        guard scriptureText == nil else {
            return
        }
        
        guard xmlParser == nil else {
            return
        }
        
        if let scripture = scripture?.replacingOccurrences(of: "Psalm", with: "Psalms") {
            let urlString = "https://api.preachingcentral.com/bible.php?passage=\(scripture)&version=nasb".replacingOccurrences(of: " ", with: "%20")

            if let url = URL(string: urlString) {
                self.xmlParser = XMLParser(contentsOf: url)
                
                self.xmlParser?.delegate = self
                
                if let success = self.xmlParser?.parse(), !success {
                    xmlParser = nil
                }
            }
        }
    }
    
                       //Book //Chap  //Verse //Text
    var scriptureText:[String:[String:[String:String]]]?
    
    var className:String? {
        get {
            return dict![Field.className]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return hasSpeaker ? speakerSort! : Constants.None
        }
    }
    
    var speakerSection:String! {
        get {
            return hasSpeaker ? speaker! : Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict![Field.speaker]?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict![Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict![Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if (speaker != nil) {
                        if !speaker!.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = (speakerSort != nil) ? speakerSort! + "," + firstName : firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
//                    print(speaker)
//                    print(speakerSort)
                    
                    dict![Field.speaker_sort] = speakerSort != nil ? speakerSort : Constants.None

//                    if var speakerSort = speaker {
//                        while (speakerSort.range(of: Constants.SINGLE_SPACE) != nil) {
//                            speakerSort = speakerSort.substring(from: speakerSort.range(of: Constants.SINGLE_SPACE)!.upperBound)
//                        }
//                        dict![Field.speaker_sort] = speakerSort
////                        settings?[Field.speaker_sort] = speakerSort
//                    } else {
//                        print("NO SPEAKER")
//                    }
                }
            }
            if dict![Field.speaker_sort] == nil {
                print("Speaker sort is NIL")
            }
            return dict![Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            return hasMultipleParts ? multiPartSort!.lowercased() : stringWithoutPrefixes(title)!.lowercased() // Constants.Individual_Media
        }
    }
    
    var multiPartSection:String! {
        get {
            return hasMultipleParts ? multiPartName! : title! // Constants.Individual_Media
        }
    }
    
    // this saves calculated values in defaults between sessions
    var multiPartSort:String? {
        get {
            if dict![Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict![Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict![Field.multi_part_name_sort] = multiPartSort
//                        settings?[Field.series_sort] = multiPartSort
                    } else {
//                        print("multiPartSort is nil")
                    }
                }
            }
            return dict![Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if (dict![Field.multi_part_name] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let seriesString = title!.substring(to: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.lowerBound)!).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    dict![Field.multi_part_name] = seriesString
                }
            }
            
            return dict![Field.multi_part_name]
        }
    }
    
    var part:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if hasMultipleParts && (dict![Field.part] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let partString = title!.substring(from: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.upperBound)!)
//                    print(partString)
                    dict![Field.part] = partString.substring(to: partString.range(of: ")")!.lowerBound)
                }
            }
            
//            print(dict![Field.part])
            return dict![Field.part]
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            if let tags = mediaItemSettings?[Field.tags] {
                if dict![Field.tags] != nil {
                    return dict![Field.tags]! + Constants.TAGS_SEPARATOR + tags
                } else {
                    return tags
                }
            } else {
                var tags:String?
                
                if hasClassName {
                    tags = tags != nil ? tags! + "|" + className! : className!
                }
                
                if hasSlides {
                    tags = tags != nil ? tags! + "|" + Constants.Slides : Constants.Slides
                }
                
                if hasNotes {
                    tags = tags != nil ? tags! + "|" + Constants.Transcript : Constants.Transcript
                }
                
                if hasNotesHTML {
                    tags = tags != nil ? tags! + "|" + Constants.Lexicon : Constants.Lexicon
                }
                
                if hasVideo {
                    tags = tags != nil ? tags! + "|" + Constants.Video : Constants.Video
                }
                
//                if let books = self.books {
//                    for book in books {
//                        tags = tags != nil ? tags! + "|Book:" + book : "Book:" + book
//                    }
//                }
                
                return dict![Field.tags] != nil ? dict![Field.tags]! + (tags != nil ? "|" + tags! : "") : tags
            }
        }
//        set {
//            var tag:String
//            var tags = newValue
//            var tagsSet = Set<String>()
//            
//            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
//                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
//                tagsSet.insert(tag)
//                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
//            }
//            
//            if (tags != nil) {
//                tagsSet.insert(tags!)
//            }

//            settings?[Field.tags] = newValue
//            dict![Field.tags] = newValue
//        }
    }
    
    func addTag(_ tag:String)
    {
        let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
        
        if tags?.index(of: tag) == nil {
            if (mediaItemSettings?[Field.tags] == nil) {
                mediaItemSettings?[Field.tags] = tag
            } else {
                mediaItemSettings?[Field.tags] = mediaItemSettings![Field.tags]! + Constants.TAGS_SEPARATOR + tag
            }
            
            let sortTag = stringWithoutPrefixes(tag)
            
            if globals.media.all!.tagMediaItems![sortTag!] != nil {
                if globals.media.all!.tagMediaItems![sortTag!]!.index(of: self) == nil {
                    globals.media.all!.tagMediaItems![sortTag!]!.append(self)
                    globals.media.all!.tagNames![sortTag!] = tag
                }
            } else {
                globals.media.all!.tagMediaItems![sortTag!] = [self]
                globals.media.all!.tagNames![sortTag!] = tag
            }
            
            if (globals.media.tags.selected == tag) {
                globals.media.tagged = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                })
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            })
        }
    }
    
    func removeTag(_ tag:String)
    {
        if (mediaItemSettings?[Field.tags] != nil) {
            var tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
            
            if tags?.index(of: tag) != nil {
                tags?.remove(at: tags!.index(of: tag)!)
                mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
                
                let sortTag = stringWithoutPrefixes(tag)
                
                if let index = globals.media.all?.tagMediaItems?[sortTag!]?.index(of: self) {
                    globals.media.all?.tagMediaItems?[sortTag!]?.remove(at: index)
                }
                
                if globals.media.all?.tagMediaItems?[sortTag!]?.count == 0 {
                    _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag!)
                }
                
                if (globals.media.tags.selected == tag) {
                    globals.media.tagged = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                    })
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
                })
            }
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        var tags:String?
        
        if tagsSet != nil {
            for tag in tagsSet! {
                if tags == nil {
                    tags = tag
                } else {
                    tags = tags! + Constants.TAGS_SEPARATOR + tag
                }
            }
        }
        
        return tags
    }
    
    var tagsSet:Set<String>? {
        get {
            var tag:String
            var tags = self.tags
            var tagsSet = Set<String>()
            
            while (tags?.range(of: Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substring(to: tags!.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
                tagsSet.insert(tag)
                tags = tags!.substring(from: tags!.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            
            return tagsSet.count == 0 ? nil : tagsSet
        }
    }
    
    var tagsArray:[String]? {
        get {
            return tagsSet == nil ? nil : Array(tagsSet!).sorted() {
//                let range0 = $0.range(of: "Book:")
//                let range1 = $1.range(of: "Book:")
//                
//                if (range0 != nil) && (range1 != nil) {
//                    return bookNumberInBible($0.substring(from: range0!.upperBound)) < bookNumberInBible($1.substring(from: range1!.upperBound))
//                } else {
                    return $0 < $1
//                }
            }
        }
    }
    
    //    Slides: Constants.BASE_MEDIA_URL+{year}/{mediacode}slides.pdf
    //    Outline: Constants.BASE_MEDIA_URL+{year}/{mediacode}outline.pdf
    //    Transcript: Constants.BASE_MEDIA_URL+{year}/{mediacode}transcript.pdf

    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio {
                dict![Field.audio] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Constants.FILENAME_EXTENSION.MP3
            }
            
//            print(dict![Field.audio])
            
            return dict![Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict![Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict![Field.m3u8]
        }
    }
    
    var video:String? {
        get {
            return m3u8
        }
    }
    
    var videoID:String? {
        get {
//            print(video)
            
            guard video != nil else {
                return nil
            }
            
            guard video!.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = video?.substring(from: Constants.BASE_URL.VIDEO_PREFIX.endIndex)
//            print(tail)
            
            let id = tail?.substring(to: tail!.range(of: ".m")!.lowerBound)
//            print(id)

            return id
        }
    }
    
    var externalVideo:String? {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    var notes:String? {
        get {
            if (dict![Field.notes] == nil) && hasNotes { // \(year!)
                dict![Field.notes] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }

            //            print(dict![Field.notes])
            return dict![Field.notes]
        }
    }
    
    lazy var searchMarkedFullNotesHTML:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func markedFullNotesHTML(searchText:String?,index:Bool) -> String?
    {
        guard (stripHead(fullNotesHTML) != nil) else {
            return nil
        }
        
        if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
            if searchMarkedFullNotesHTML?[searchText] != nil {
                return searchMarkedFullNotesHTML?[searchText]
            }
        } else {
            let string = "No Occurences of \"\(searchText!)\" were found.<br/>"
            
            if let newString = fullNotesHTML?.replacingOccurrences(of: "<body>", with: "<body>" + string) {
                return newString
            } else {
                return nil
            }
        }
        
        
//        var stringBefore:String = Constants.EMPTY_STRING
//        var stringAfter:String = Constants.EMPTY_STRING

        var markCounter = 0

        func mark(_ input:String) -> String
        {
            var string = input

            var stringBefore:String = Constants.EMPTY_STRING
            var stringAfter:String = Constants.EMPTY_STRING
            var newString:String = Constants.EMPTY_STRING
            var foundString:String = Constants.EMPTY_STRING

            while (string.lowercased().range(of: searchText!.lowercased()) != nil) {
                //                print(string)
                
                if let range = string.lowercased().range(of: searchText!.lowercased()) {
                    stringBefore = string.substring(to: range.lowerBound)
                    stringAfter = string.substring(from: range.upperBound)
                    
                    foundString = string.substring(from: range.lowerBound)
                    let newRange = foundString.lowercased().range(of: searchText!.lowercased())
                    foundString = foundString.substring(to: newRange!.upperBound)
                    
                    markCounter += 1
                    foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                    
                    newString = newString + stringBefore + foundString
                    
                    stringBefore = stringBefore + foundString
                    
                    string = stringAfter
                }
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }

        var newString:String = Constants.EMPTY_STRING
        var string:String = stripHead(fullNotesHTML)!
        
        while let searchRange = string.range(of: "<") {
            let searchString = string.substring(to: searchRange.lowerBound)
//            print(searchString)
            
            // mark search string
            newString = newString + mark(searchString)
            
            let remainder = string.substring(from: searchRange.lowerBound)

            if let htmlRange = remainder.range(of: ">") {
                let html = remainder.substring(to: htmlRange.upperBound)
//                print(html)
                
                newString = newString + html
                
                string = remainder.substring(from: htmlRange.upperBound)
            }
        }
        
//        string = stripHead(fullNotesHTML)!
//        
//        if newString == string {
//            print("The same!")
//        } else {
//            print("Different!")
//            print("\n\nORIGINAL\n\n",string)
//            print("\n\nNEWSTRING\n\n",newString)
//        }
//        
//        newString = Constants.EMPTY_STRING
//        
//        while (string.lowercased().range(of: globals.search.text!.lowercased()) != nil) {
////                print(string)
//            
//            if let range = string.lowercased().range(of: globals.search.text!.lowercased()) {
//                stringBefore = string.substring(to: range.lowerBound)
//                stringAfter = string.substring(from: range.upperBound)
//                
//                foundString = string.substring(from: range.lowerBound)
//                let newRange = foundString.lowercased().range(of: globals.search.text!.lowercased())
//                foundString = foundString.substring(to: newRange!.upperBound)
//                
//                markCounter += 1
//                foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
//                
//                newString = newString + stringBefore + foundString
//                
//                stringBefore = stringBefore + foundString
//                
//                string = stringAfter
//            }
//        }

        var indexString:String!
            
        if markCounter > 0 {
            indexString = "<a id=\"locations\" name=\"locations\">Occurences</a> of \"\(searchText!)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurences</a> of \"\(searchText!)\" were found.<br/>"
        }
        
        // If we want an index of links to the occurences of the searchText.
        if index {
            if markCounter > 0 {
                indexString = indexString + "<div>Locations: "
                
                for counter in 1...markCounter {
                    if counter > 1 {
                        indexString = indexString + ", "
                    }
                    indexString = indexString + "<a href=\"#\(counter)\">\(counter)</a>"
                }
                
                indexString = indexString + "<br/><br/></div>"
            }
            
            newString = newString.replacingOccurrences(of: "<body>", with: "<body>"+indexString)
        }
        
//        newString = newString + stringAfter
        
        searchMarkedFullNotesHTML?[searchText] = insertHead(newString,fontSize: Constants.FONT_SIZE)
        
        return searchMarkedFullNotesHTML?[searchText]
        
//            var menuString = "<div class=\"dropdown\"><button onclick=\"myFunction()\" class=\"dropbtn\">Search</button><div id=\"myDropdown\" class=\"dropdown-content\">"
//            
//            for counter in 1...markCounter {
//                menuString = menuString + "<a href=\"#\(counter)\">\(counter)</a>"
//            }
//
//            menuString = menuString + "</div></div><br/>"
//
//            newString = newString.replacingOccurrences(of: "<body>", with: "<body>"+menuString)
//
//            return insertMenuHead(newString,fontSize: Constants.FONT_SIZE)
    }
    
    var headerHTML:String? {
        get {
            var header = "<center><b>"
            
            if let string = title {
                header = header + string + "</br>"
            }
            
            if let string = scripture {
                header = header + string + "</br>"
            }
            
            if let string = formattedDate {
                header = header + string + "</br>"
            }
            
            if let string = speaker {
                header = header + "<i>by " + string + "</i></br>"
            }
            
            header = header + "<i>Countryside Bible Church</i></br>"
            
            header = header + "</br>"
            header = header + "Available online at <a href=\"\(websiteURL!)\">www.countrysidebible.org</a></br>"
            
            if let string = yearString {
                header = header + "Copyright \(string).  All rights reserved.</br>"
            } else {
                header = header + "Copyright, all rights reserved.</br>"
            }
            
            header = header + "<i>Unedited transcript for personal use only.</i>"
            
            header = header + "</b></center>"

            return header
        }
    }
    
    var fullNotesHTML:String? {
        get {
            guard (notesHTML != nil) else {
                return nil
            }

            return insertHead("<!DOCTYPE html><html><body>" + headerHTML! + notesHTML! + "</body></html>",fontSize: Constants.FONT_SIZE)
        }
    }
    
    var notesHTML:String? {
        get {
            //            print(dict![Field.notes])
            return dict![Field.notes_HTML]
        }
        set {
            dict![Field.notes_HTML] = newValue
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if (dict![Field.slides] == nil) && hasSlides { // \(year!)
                dict![Field.slides] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }

            return dict![Field.slides]
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String? {
        get {
            if (dict![Field.outline] == nil) && hasSlides { // \(year!)
                dict![Field.outline] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.outline + Constants.FILENAME_EXTENSION.PDF
            }
            
            return dict![Field.outline]
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict![Field.files]
        }
    }
    
    var hasAudio:Bool {
        get {
            return files != nil ? files!.contains("A") : false
        }
    }
    
    var hasVideo:Bool {
        get {
            return files != nil ? files!.contains("V") : false
        }
    }
    
    var hasSlides:Bool {
        get {
            return files != nil ? files!.contains("S") : false
        }
    }
    
    var hasNotes:Bool {
        get {
            return files != nil ? files!.contains("T") : false
        }
    }
    
    var hasNotesHTML:Bool {
        get {
//            print(files)
            return files != nil ? files!.contains("H") : false
        }
    }
    
    var hasOutline:Bool {
        get {
            return files != nil ? files!.contains("O") : false
        }
    }
    
    var audioURL:URL? {
        get {
//            print(audio)
            return audio != nil ? URL(string: audio!) : nil
        }
    }
    
    var videoURL:URL? {
        get {
            return video != nil ? URL(string: video!) : nil
        }
    }
    
    var notesURL:URL? {
        get {
//            print(notes)
            return notes != nil ? URL(string: notes!) : nil
        }
    }
    
    var slidesURL:URL? {
        get {
//            print(slides)
            return slides != nil ? URL(string: slides!) : nil
        }
    }
    
    var outlineURL:URL? {
        get {
//            print(outline)
            return outline != nil ? URL(string: outline!) : nil
        }
    }
    
    var audioFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP3)
        }
    }
    
    var mp4FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP4)
        }
    }
    
    var m3u8FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.M3U8)
        }
    }
    
    var videoFileSystemURL:URL? {
        get {
            return m3u8FileSystemURL
        }
    }
    
    var slidesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.slides + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var notesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.notes + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var outlineFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.outline + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var bookSections:[String]
    {
        get {
            if books == nil {
//                print(scripture)
//                if hasScripture {
//                    print([scripture!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)])
//                } else {
//                    print([Constants.None])
//                }
            }
            return books != nil ? books! : (hasScripture ? [scripture!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)] : [Constants.None])
        }
    }
    

//    var bookSection:String! {
//        get {
//            return hasBook ? book! : hasScripture ? scripture! : Constants.None
//        }
//    }
    
//    var testament:String? {
//        if (hasBook) {
//            if (Constants.OLD_TESTAMENT_BOOKS.contains(book!)) {
//                return Constants.Old_Testament
//            }
//            if (Constants.NEW_TESTAMENT_BOOKS.contains(book!)) {
//                return Constants.New_Testament
//            }
//        } else {
//            return nil
//        }
//        
//        return nil
//    }
    
    func verses(book:String,chapter:Int) -> [Int]
    {
        var versesForChapter = [Int]()
        
        if let bacv = booksAndChaptersAndVerses(), let verses = bacv[book]?[chapter] {
            versesForChapter = verses
        }
        
        return versesForChapter
    }
    
    func chaptersAndVerses(book:String) -> [Int:[Int]]
    {
        var chaptersAndVerses = [Int:[Int]]()
        
        if let bacv = booksAndChaptersAndVerses(), let cav = bacv[book] {
            chaptersAndVerses = cav
        }
        
        return chaptersAndVerses
    }
    
    func booksAndChaptersAndVerses() -> BooksChaptersVerses?
    {
        if self.booksChaptersVerses != nil {
            return self.booksChaptersVerses
        }
        
        guard (scripture != nil) else {
            return nil
        }
        
//        print(scripture!)
        
        let booksAndChaptersAndVerses = BooksChaptersVerses()
        
        let books = booksFromScripture(scripture)
        
        guard (books != nil) else {
            return nil
        }

        var scriptures = [String]()
        
        var string = scripture!
        
        let separator = ";"
        
        while (string.range(of: separator) != nil) {
            scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
            string = string.substring(from: string.range(of: separator)!.upperBound)
        }
        
        scriptures.append(string)
        
        for scripture in scriptures {
            for book in books! {
                if (scripture.range(of: book) != nil) {
                    booksAndChaptersAndVerses[book] = chaptersAndVersesFromScripture(book:book,reference:scripture.substring(from: scripture.range(of: book)!.upperBound))
                    if let chapters = booksAndChaptersAndVerses[book]?.keys {
                        for chapter in chapters {
                            if booksAndChaptersAndVerses[book]?[chapter] == nil {
                                print(description,book,chapter)
                            }
                        }
                    }
                }
            }
        }
        
//        print(scripture!)
//        print(booksAndChaptersAndVerses)
        
        self.booksChaptersVerses = booksAndChaptersAndVerses.data?.count > 0 ? booksAndChaptersAndVerses : nil
        
        return self.booksChaptersVerses
    }
    
    func chapters(_ thisBook:String) -> [Int]?
    {
        guard !Constants.NO_CHAPTER_BOOKS.contains(thisBook) else {
            return [1]
        }
        
        var chaptersForBook:[Int]?
        
        let books = booksFromScripture(scripture)
        
        guard (books != nil) else {
            return nil
        }

        switch books!.count {
        case 0:
            break
            
        case 1:
            if thisBook == books!.first {
                if Constants.NO_CHAPTER_BOOKS.contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scripture!
                    
                    if (string.range(of: ";") == nil) {
                        chaptersForBook = chaptersFromScripture(string.substring(from: scripture!.range(of: thisBook)!.upperBound))
                    } else {
                        while (string.range(of: ";") != nil) {
                            var subString = string.substring(to: string.range(of: ";")!.lowerBound)
                            
                            if (subString.range(of: thisBook) != nil) {
                                subString = subString.substring(from: subString.range(of: thisBook)!.upperBound)
                            }
                            if let chapters = chaptersFromScripture(subString) {
                                chaptersForBook?.append(contentsOf: chapters)
                            }
                            
                            string = string.substring(from: string.range(of: ";")!.upperBound)
                        }
                        
                        //                        print(string)
                        if (string.range(of: thisBook) != nil) {
                            string = string.substring(from: string.range(of: thisBook)!.upperBound)
                        }
                        if let chapters = chaptersFromScripture(string) {
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
            
            var string = scripture!
            
            let separator = ";"
            
            while (string.range(of: separator) != nil) {
                scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                string = string.substring(from: string.range(of: separator)!.upperBound)
            }
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if (scripture.range(of: thisBook) != nil) {
                    if let chapters = chaptersFromScripture(scripture.substring(from: scripture.range(of: thisBook)!.upperBound)) {
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
        
//        if chaptersForBook.count > 1 {
//            print("\(scripture)")
//            print("\(chaptersForBook)")
//        }
        
        return chaptersForBook
    }
    
    var books:[String]? {
        get {
            return booksFromScripture(scripture)
        }
    } //Derived from scripture
    
//    var book:String? {
//        get {
//            if (dict![Field.book] == nil) {
//                if let bookTitle = mediaItemSettings?[Field.book] {
//                    dict![Field.book] = bookTitle
//                } else {
//                    if (scripture == Constants.Selected_Scriptures) {
////                        dict![Field.book] = Constants.Selected_Scriptures
//                    } else {
//                        if scripture != nil {
//                            if (dict![Field.book] == nil) {
//                                for bookTitle in Constants.OLD_TESTAMENT_BOOKS {
//                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
//                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
//                                            dict![Field.book] = bookTitle
//                                            break
//                                    }
//                                }
//                            }
//                            if (dict![Field.book] == nil) {
//                                for bookTitle in Constants.NEW_TESTAMENT_BOOKS {
//                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
//                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
//                                            dict![Field.book] = bookTitle
//                                            break
//                                    }
//                                }
//                            }
//                            if (dict![Field.book] != nil) {
////                                settings?[Field.book] = dict![Field.book]
//                            }
//                        }
//                    }
//                }
//            }
//            
//            return dict![Field.book]
//        }
//    }//Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if (self.hasDate()) {
            return Date(dateString:self.date!)
        } else {
            return nil
        }
    }()//Derived from date
    
    var contents:String? {
        get {
            return stripHTML(bodyHTML(order: ["date","title","scripture","speaker"], includeURLs: false, includeColumns: false))

            // Don't need these now that there is a web page for each sermon.
            //    if let audioURL = mediaItem?.audioURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + audioURL + "\">Audio</a>)"
            //    }
            //
            //    if let externalVideo = mediaItem?.externalVideo {
            //        bodyString = bodyString! + " (<a href=\"" + externalVideo + "\">Video</a>) "
            //    }
            //
            //    if let slidesURL = mediaItem?.slidesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + slidesURL + "\">Slides</a>)"
            //    }
            //
            //    if let notesURL = mediaItem?.notesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + notesURL + "\">Transcript</a>) "
            //    }
        }
    }

    var contentsHTML:String? {
        get {
            var bodyString = "<!DOCTYPE html><html><body>"
            
            if let string = bodyHTML(order: ["date","title","scripture","speaker"], includeURLs: true, includeColumns: true) {
                bodyString = bodyString + string
            }
            
            // Don't need these now that there is a web page for each sermon.
            //    if let audioURL = mediaItem?.audioURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + audioURL + "\">Audio</a>)"
            //    }
            //
            //    if let externalVideo = mediaItem?.externalVideo {
            //        bodyString = bodyString! + " (<a href=\"" + externalVideo + "\">Video</a>) "
            //    }
            //
            //    if let slidesURL = mediaItem?.slidesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + slidesURL + "\">Slides</a>)"
            //    }
            //
            //    if let notesURL = mediaItem?.notesURL?.absoluteString {
            //        bodyString = bodyString! + " (<a href=\"" + notesURL + "\">Transcript</a>) "
            //    }
            
            bodyString = bodyString + "</body></htm>"
            
            return bodyString
        }
    }
    
    func bodyHTML(order:[String],includeURLs:Bool,includeColumns:Bool) -> String?
    {
        var bodyString:String?
        
        if includeColumns {
            bodyString = "<tr>"
            
            for item in order {
                switch item.lowercased() {
                case "date":
                    bodyString = bodyString! + "<td valign=\"top\">"
                    if let month = formattedDateMonth {
                        bodyString = bodyString! + month
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"top\" align=\"right\">"
                    if let day = formattedDateDay {
                        bodyString  = bodyString! + day + ","
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"top\" align=\"right\">"
                    if let year = formattedDateYear {
                        bodyString  = bodyString! + year
                    }
                    bodyString = bodyString! + "</td>"
                    
                    bodyString = bodyString! + "<td valign=\"top\">"
                    if let service = self.service {
                        bodyString  = bodyString! + service
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                case "title":
                    bodyString = bodyString! + "<td valign=\"top\">"
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            bodyString = bodyString! + "<a href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = bodyString! + title
                        }
                    }
                    bodyString = bodyString! + "</td>"
                    break

                case "scripture":
                    bodyString = bodyString! + "<td valign=\"top\">"
                    if let scripture = self.scripture {
                        bodyString = bodyString! + scripture
                    }
                    bodyString = bodyString! + "</td>"
                    break

                case "speaker":
                    bodyString = bodyString! + "<td valign=\"top\">"
                    if let speaker = self.speaker {
                        bodyString = bodyString! + speaker
                    }
                    bodyString = bodyString! + "</td>"
                    break
                    
                default:
                    break
                }
            }
            
            bodyString = bodyString! + "</tr>"
        } else {
            for item in order {
                switch item.lowercased() {
                case "date":
                    if let date = formattedDate {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + date
                    }
                    
                    if let service = self.service {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + service
                    }
                    break

                case "title":
                    if let title = self.title {
                        if includeURLs, let websiteURL = websiteURL?.absoluteString {
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + "<a href=\"" + websiteURL + "\">\(title)</a>"
                        } else {
                            bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + title
                        }
                    }
                    break

                case "scripture":
                    if let scripture = self.scripture {
                        bodyString  = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + scripture
                    }
                    break
                    
                case "speaker":
                    if let speaker = self.speaker {
                        bodyString = (bodyString != nil ? bodyString! + Constants.SINGLE_SPACE : Constants.EMPTY_STRING) + Constants.SINGLE_SPACE + speaker
                    }
                    break
                    
                default:
                    break
                }
            }
        }
        
        return bodyString
    }
    
    var text : String? {
        get {
            var string:String?
            
            if hasDate() {
                string = formattedDate
            } else {
                string = "No Date"
            }
            
            if let service = service {
                string = string! + " \(service)"
            }
            
            if let speaker = speaker {
                string = string! + " \(speaker)"
            }
            
            if hasTitle() {
                if (title!.range(of: " (Part ") != nil) {
                    let first = title!.substring(to: (title!.range(of: " (Part")?.upperBound)!)
                    let second = title!.substring(from: (title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture {
                string = string! + "\n\(scripture!)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var mediaItemString = "MediaItem: "
        
        if (category != nil) {
            mediaItemString = "\(mediaItemString) \(category!)"
        }
        
        if (id != nil) {
            mediaItemString = "\(mediaItemString) \(id!)"
        }
        
        if (date != nil) {
            mediaItemString = "\(mediaItemString) \(date!)"
        }
        
        if (service != nil) {
            mediaItemString = "\(mediaItemString) \(service!)"
        }
        
        if (title != nil) {
            mediaItemString = "\(mediaItemString) \(title!)"
        }
        
        if (scripture != nil) {
            mediaItemString = "\(mediaItemString) \(scripture!)"
        }
        
        if (speaker != nil) {
            mediaItemString = "\(mediaItemString) \(speaker!)"
        }
        
        return mediaItemString
    }
    
    struct MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.mediaItemSettings?[mediaItem!.id]?[key]
            }
            set {
                if (mediaItem != nil) {
                    if globals.mediaItemSettings == nil {
                        globals.mediaItemSettings = [String:[String:String]]()
                    }
                    if (globals.mediaItemSettings != nil) {
                        if (globals.mediaItemSettings?[mediaItem!.id] == nil) {
                            globals.mediaItemSettings?[mediaItem!.id] = [String:String]()
                        }
                        if (globals.mediaItemSettings?[mediaItem!.id]?[key] != newValue) {
                            //                        print("\(mediaItem)")
                            globals.mediaItemSettings?[mediaItem!.id]?[key] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        print("globals.settings == nil in Settings!")
                    }
                } else {
                    print("mediaItem == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        return MediaItemSettings(mediaItem:self)
    }()
    
    struct MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.multiPartSettings?[mediaItem!.seriesID]?[key]
            }
            set {
                guard (mediaItem != nil) else {
                    print("mediaItem == nil in SeriesSettings!")
                    return
                }

                if globals.multiPartSettings == nil {
                    globals.multiPartSettings = [String:[String:String]]()
                }
                
                guard (globals.multiPartSettings != nil) else {
                    print("globals.viewSplits == nil in SeriesSettings!")
                    return
                }
                
                if (globals.multiPartSettings?[mediaItem!.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem!.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem!.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem!.seriesID]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    globals.saveSettingsBackground()
                }
            }
        }
    }
    
    lazy var multiPartSettings:MultiPartSettings? = {
        return MultiPartSettings(mediaItem:self)
    }()
    
    var viewSplit:String? {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var slideSplit:String? {
        get {
            return multiPartSettings?[Constants.SLIDE_SPLIT]
        }
        set {
            multiPartSettings?[Constants.SLIDE_SPLIT] = newValue
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }

        if (download?.purpose != nil) {
//            print(totalBytesWritten,totalBytesExpectedToWrite,Float(totalBytesWritten) / Float(totalBytesExpectedToWrite),Int(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100))
            
            let progress = totalBytesExpectedToWrite > 0 ? Int((Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100) % 100 : 0
            
            let current = download!.totalBytesExpectedToWrite > 0 ? Int((Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite)) * 100) % 100 : 0
            
//            print(progress,current)
            
            switch download!.purpose! {
            case Purpose.audio:
                if progress > current {
//                    print(Constants.NOTIFICATION.MEDIA_UPDATE_CELL)
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: download?.mediaItem)
                    })
                }
                break
                
            case Purpose.notes:
                fallthrough
            case Purpose.slides:
                if progress > current {
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: download)
                    })
                }
                break
                
            default:
                break
            }

            debug("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            debug("session: \(session.sessionDescription)")
            debug("downloadTask: \(downloadTask.taskDescription)")
            
            if (download?.fileSystemURL != nil) {
                debug("path: \(download!.fileSystemURL!.path)")
                debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
                
                if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                    debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
                }
            } else {
                debug("No fileSystemURL")
            }
            
            debug("bytes written: \(totalBytesWritten)")
            debug("bytes expected to write: \(totalBytesExpectedToWrite)")

            if (download?.state == .downloading) {
                download?.totalBytesWritten = totalBytesWritten
                download?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                print("ERROR NOT DOWNLOADING")
            }
        } else {
            print("ERROR NO DOWNLOAD")
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        })
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard (download!.fileSystemURL != nil) else {
            print("NO FILE SYSTEM URL!")
            return
        }

        debug("URLSession:downloadTask:didFinishDownloadingToURL:")
        
        debug("session: \(session.sessionDescription)")
        debug("downloadTask: \(downloadTask.taskDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        debug("path: \(download!.fileSystemURL!.path)")
        debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        
        if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
            debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        let fileManager = FileManager.default
        
        // Check if file exists
        //            print("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
        
        do {
            if (download?.state == .downloading) && (download!.totalBytesExpectedToWrite != -1) {
                if (fileManager.fileExists(atPath: download!.fileSystemURL!.path)){
                    do {
                        try fileManager.removeItem(at: download!.fileSystemURL!)
                    } catch _ {
                        print("failed to remove duplicate download")
                    }
                }
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: download!.fileSystemURL!)
                try fileManager.removeItem(at: location)
                download?.state = .downloaded
            } else {
                // Nothing was downloaded
                download?.state = .none
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
                })
            }
        } catch _ {
            print("failed to copy temp download file")
            download?.state = .none
        }
    
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }

        debug("URLSession:task:didCompleteWithError:")
        
        debug("session: \(session.sessionDescription)")
        debug("task: \(task.taskDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
            
            if (task.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                debug("task.taskDescription != download!.fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
//            download?.state = .none
            
            switch download!.purpose! {
            case Purpose.slides:
                fallthrough
            case Purpose.notes:
                DispatchQueue.main.async(execute: { () -> Void in
//                    print(download?.mediaItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: download)
                })
                break

            default:
                break
            }
        }
        
        //        print("Download error: \(error)")
        //
        //        if (download?.totalBytesExpectedToWrite == 0) {
        //            download?.state = .none
        //        } else {
        //            print("Download succeeded for: \(session.description)")
        ////            download?.state = .downloaded // <- This caused a very spurious error.  Let this state chagne happen in didFinishDownloadingToURL!
        //        }
        
        // This may delete temp files other than the one we just downloaded, so don't do it.
        //        removeTempFiles()
        
        session.invalidateAndCancel()
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        debug("URLSession:didBecomeInvalidWithError:")
        
        debug("session: \(session.sessionDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
        }

        download?.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var filename:String?
        
        filename = session.configuration.identifier!.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                print("\(filename) \(key)")
            return value.task?.taskDescription == filename
        }).first?.1 {
            download.completionHandler?()
        }
    }
    
    func hasDate() -> Bool
    {
        return (date != nil) && (date != Constants.EMPTY_STRING)
    }
    
    func hasTitle() -> Bool
    {
        return (title != nil) && (title != Constants.EMPTY_STRING)
    }
    
//    func hasAudio() -> Bool
//    {
//        return (audio != nil) && (audio != Constants.EMPTY_STRING)
//    }
    
    func playingAudio() -> Bool
    {
        return (playing == Playing.audio)
    }
    
//    func hasVideo() -> Bool
//    {
//        return (video != nil) && (video != Constants.EMPTY_STRING)
//    }
    
    var playingVideo:Bool
    {
        get {
            return (playing == Playing.video)
        }
    }
    
    var showingVideo:Bool
    {
        get {
            return (showing == Showing.video)
        }
    }
    
    var hasScripture:Bool
        {
        get {
            return (self.scripture != nil) && (self.scripture != Constants.EMPTY_STRING)
        }
    }
    
    var hasClassName:Bool
        {
        get {
            return (self.className != nil) && (self.className != Constants.EMPTY_STRING)
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            return (self.multiPartName != nil) && (self.multiPartName != Constants.EMPTY_STRING)
        }
    }
    
    var hasCategory:Bool
        {
        get {
            return (self.category != nil) && (self.category != Constants.EMPTY_STRING)
        }
    }
    
    var hasBook:Bool
    {
        get {
            return (self.books != nil) // && (self.book != Constants.EMPTY_STRING)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
        }
    }
    
//    func hasNotesOrSlides() -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(),hasSlides())
//    }
    
//    func hasNotes() -> Bool
//    {
//        return (self.notes != nil) && (self.notes != Constants.EMPTY_STRING)
//    }
    
    var showingNotes:Bool
    {
        get {
            return (showing == Showing.notes)
        }
    }
    
//    func hasSlides() -> Bool
//    {
//        return (self.slides != nil) && (self.slides != Constants.EMPTY_STRING)
//    }
    
    var showingSlides:Bool
    {
        get {
            return (showing == Showing.slides)
        }
    }
    
//    func hasNotesOrSlides(check:Bool) -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(check),hasSlides(check))
//    }
    
    func checkNotes() -> Bool
    {
        if !hasNotes { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: notesURL!)) != nil) {
//                notes = testNotes
                print("Transcript DOES exist for: \(title!)")
            }
        }
        
        return hasNotes
    }
    
    func hasNotes(_ check:Bool) -> Bool
    {
        return check ? checkNotes() : hasNotes
    }
    
    func checkSlides() -> Bool
    {
        if !hasSlides { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: slidesURL!)) != nil) {
//                slides = testSlides
                print("Slides DO exist for: \(title!)")
            } else {
                
            }
        }
        
        return hasSlides
    }
    
    func hasSlides(_ check:Bool) -> Bool
    {
        return check ? checkSlides() : hasSlides
    }
    
    var hasTags:Bool
    {
        get {
            return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            return hasTags ? tagsSet!.contains(Constants.Favorites) : false
        }
    }
}
