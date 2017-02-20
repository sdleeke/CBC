//
//  Scripture.swift
//  CBC
//
//  Created by Steve Leeke on 1/10/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

struct Selected {
    var testament:String?
    var book:String?
    var chapter:Int = 0
    var verse:Int = 0
    
    var reference:String? {
        get {
            guard testament != nil else {
                return nil
            }
            
            var reference:String?
            
            if let selectedBook = book {
                reference = selectedBook
                
                if reference != nil, !Constants.NO_CHAPTER_BOOKS.contains(selectedBook), chapter > 0 {
                    reference = reference! + " \(chapter)"
                }
            }
            
//            if reference != nil, startingVerse > 0 {
//                reference = reference! + ":\(startingVerse)"
//            }
            
            return reference
        }
    }
}

struct Picker {
    var books:[String]?
    var chapters:[Int]?
    var verses:[Int]?
}

struct XML {
    var parser:XMLParser?
    var string:String?
    
    var book:String?
    var chapter:String?
    var verse:String?

              //Book //Chap  //Verse //Text
    var text:[String:[String:[String:String]]]?
}

extension Scripture : XMLParserDelegate
{
    // MARK: XMLParserDelegate
    
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
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        //        print(elementName)
        
        if xml.text == nil {
            xml.text = [String:[String:[String:String]]]()
        }
        
        switch elementName {
        case "bookname":
            xml.book = xml.string
            
            if xml.text?[xml.book!] == nil {
                xml.text?[xml.book!] = [String:[String:String]]()
            }
            break
            
        case "chapter":
            xml.chapter = xml.string
            
            if xml.text?[xml.book!]?[xml.chapter!] == nil {
                xml.text?[xml.book!]?[xml.chapter!] = [String:String]()
            }
            break
            
        case "verse":
            xml.verse = xml.string
            break
            
        case "text":
            xml.text?[xml.book!]?[xml.chapter!]?[xml.verse!] = xml.string
            //            print(scriptureText)
            break
            
        default:
            break
        }
        
        xml.string = nil
    }
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
        //        print(elementName)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        //        print(string)
        xml.string = (xml.string != nil ? xml.string! + string : string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

class Scripture : NSObject
{
    var picker = Picker()

    var selected = Selected()

    var xml = XML()
    
    var reference:String?
    
    init(reference:String?)
    {
        self.reference = reference
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func jsonFromURL(url:String) -> [String:Any]?
    {
        if let data = try? Data(contentsOf: URL(string: url)!) {
            var final:String?
            
            if let string = String(data: data, encoding: .utf8) {
                print(string)
                
                let initial = string.substring(from: "(".endIndex)
                
                if let range = initial.range(of: ");") {
                    final = initial.substring(to: range.lowerBound)
                }
                
                print(final)
            }
            
            if let finalData = final?.data(using: String.Encoding.utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: finalData, options: [])
                    return json as? [String:Any]
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
        
        return nil
    }

    func loadVerseFromURL(_ reference:String?) -> [String:Any]?
    {
        guard reference != nil else {
            return nil
        }
        
        let urlString = "https://getbible.net/json?passage=\(reference!)&version=nasb".replacingOccurrences(of: " ", with: "%20")

//        var mediaItemDicts = [[String:String]]()
        
        let json = jsonFromURL(url: urlString)
        
        if let json = json {
            print(json)
            print(json["book"])
            print(json["version"])
            
            return json
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func load(_ reference:String?)
    {
        var bodyString:String?
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString = bodyString! + "Scripture: " + reference! // + "<br/><br/>"
        
        if let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") {
            let booksAndChaptersAndVerses = BooksChaptersVerses()
            
            var scriptures = [String]()
            
            var string = scriptureReference
            
            let separator = ";"
            
            while (string.range(of: separator) != nil) {
                scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                string = string.substring(from: string.range(of: separator)!.upperBound)
            }
            
            scriptures.append(string)
            
            var lastBook:String?
            
            for scripture in scriptures {
                var book = booksFromScriptureReference(scripture)?.first
                
                if book == nil {
                    book = lastBook
                } else {
                    lastBook = book
                }
                
                if let book = book {
                    var reference = scripture
                    
                    if let range = scripture.range(of: book) {
                        reference = scripture.substring(from: range.upperBound)
                    }
                    
                    //                print(book,reference)
                    
                    // What if a reference includes the book more than once?
                    booksAndChaptersAndVerses[book] = chaptersAndVersesFromScripture(book:book,reference:reference)
                    
                    if let chapters = booksAndChaptersAndVerses[book]?.keys {
                        for chapter in chapters {
                            if booksAndChaptersAndVerses[book]?[chapter] == nil {
                                print(description,book,chapter)
                            }
                        }
                    }
                }
            }

            print(booksAndChaptersAndVerses.data)
            
            if let data = booksAndChaptersAndVerses.data {
                for book in data.keys {
                    if let chapters = data[book]?.keys.sorted() {
                        for chapter in chapters {
                            var scriptureReference = book
                            
                            scriptureReference = scriptureReference + " \(chapter)"
                            
                            if let verses = data[book]?[chapter] {
                                scriptureReference = scriptureReference + ":"
                                
                                var lastVerse = 0
                                var hyphen = false
                                
                                for verse in verses {
                                    if hyphen == false,lastVerse == 0 {
                                        scriptureReference = scriptureReference + "\(verse)"
                                    }
                                    
                                    if hyphen == false,lastVerse != 0,verse != (lastVerse + 1) {
                                        scriptureReference = scriptureReference + ","
                                        scriptureReference = scriptureReference + "\(verse)"
                                    }
                                    
                                    if hyphen == false,lastVerse != 0,verse == (lastVerse + 1) {
                                        scriptureReference = scriptureReference + "-"
                                        hyphen = true
                                    }
                                    
                                    if hyphen == true,lastVerse != 0,verse != (lastVerse + 1) {
                                        scriptureReference = scriptureReference + "\(lastVerse)"
                                        scriptureReference = scriptureReference + ","
                                        scriptureReference = scriptureReference + "\(verse)"
                                        hyphen = false
                                    }
                                    
                                    if hyphen == true,lastVerse != 0,verse == (lastVerse + 1),verse == verses.last {
                                        scriptureReference = scriptureReference + "\(verse)"
                                        hyphen = false
                                    }
                                    
                                    lastVerse = verse
                                }
                            }
                            
                            scriptureReference = scriptureReference.replacingOccurrences(of: "Psalm ", with: "Psalms ")

                            print(scriptureReference)
                            
                            let dict = loadVerseFromURL(scriptureReference)
                            
                            print(dict?["book"])
                            
                            if let bookDicts = dict?["book"] as? [[String:Any]] {
                                var header = false
                                
                                var lastVerse = 0
                                
                                for bookDict in bookDicts {
                                    if !header {
                                        bodyString = bodyString! + "<br><br>"

                                        if let book = bookDict["book_name"] as? String {
                                            bodyString = bodyString! + book + "<br/><br/>"
                                        }
                                        
                                        if let chapter = bookDict["chapter_nr"] as? String {
                                            bodyString = bodyString! + "Chapter " + chapter + "<br/><br/>"
                                        }
                                        
                                        header = true
                                    }
                                    
                                    if let chapterDict = bookDict["chapter"] as? [String:Any] {
                                        print(chapterDict)
                                        print(chapterDict.keys.sorted())
                                        
                                        let keys = chapterDict.keys.map({ (string:String) -> Int in
                                            return Int(string)!
                                        }).sorted()
                                        
                                        for key in keys {
                                            print(key)
                                            if let verseDict = chapterDict["\(key)"] as? [String:Any] {
                                                print(verseDict)
                                                if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
                                                    if let number = Int(verseNumber) {
                                                        if lastVerse != 0, number != (lastVerse + 1) {
                                                            bodyString = bodyString! + "<br><br>"
                                                        }
                                                        lastVerse = number
                                                    }
                                                    
                                                    bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
                                                }
                                                if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
                                                    if lastVerse != 0, verseNumber != (lastVerse + 1) {
                                                        bodyString = bodyString! + "<br><br>"
                                                    }
                                                    bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
                                                    lastVerse = verseNumber
                                                }
                                            }
                                        }
                                        //                        bodyString = bodyString! + "<br/>"
                                    }
                                }
                            } else
                                
                            if let bookDict = dict {
                                if let book = bookDict["book_name"] as? String {
                                    bodyString = bodyString! + book + "<br/><br/>"
                                }
                                
                                if let chapter = bookDict["chapter_nr"] as? Int {
                                    bodyString = bodyString! + "Chapter \(chapter)"  + "<br/><br/>"
                                }
                                
                                if let chapterDict = bookDict["chapter"] as? [String:Any] {
                                    print(chapterDict)
                                    print(chapterDict.keys.sorted())
                                    
                                    let keys = chapterDict.keys.map({ (string:String) -> Int in
                                        return Int(string)!
                                    }).sorted()
                                    
                                    for key in keys {
                                        print(key)
                                        if let verseDict = chapterDict["\(key)"] as? [String:Any] {
                                            print(verseDict)
                                            if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
                                                bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
                                            }
                                            if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
                                                bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
                                            }
                                        }
                                    }
                                    //                        bodyString = bodyString! + "<br/>"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        bodyString = bodyString! + "<br/>"
        
        bodyString = bodyString! + "</html></body>"

        html?[reference!] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }

//    func load(_ reference:String?)
//    {
//        guard xml.parser == nil else {
//            return
//        }
//
//        xml.text = nil
//
//        if let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") {
//            let urlString = "https://api.preachingcentral.com/bible.php?passage=\(scriptureReference)&version=nasb".replacingOccurrences(of: " ", with: "%20")
//
//            if let url = URL(string: urlString) {
//                self.xml.parser = XMLParser(contentsOf: url)
//                
//                self.xml.parser?.delegate = self
//                
//                if let success = self.xml.parser?.parse(), success {
//                    var bodyString:String?
//                    
//                    bodyString = "<!DOCTYPE html><html><body>"
//                    
//                    bodyString = bodyString! + "Scripture: " + reference! + "<br/><br/>"
//                    
//                    if let books = xml.text?.keys.sorted(by: {
//
//                        reference?.range(of: $0)?.lowerBound < reference?.range(of: $1)?.lowerBound
//                        
////                        bookNumberInBible($0) < bookNumberInBible($1)
//                    }) {
//                        for book in books {
//                            bodyString = bodyString! + book // + "<br/>"
//                            if let chapters = xml.text?[book]?.keys.sorted(by: { Int($0) < Int($1) }) {
////                                bodyString = bodyString! + "<br/>"
//                                for chapter in chapters {
//                                    bodyString = bodyString! + "<br/>"
//                                    if !Constants.NO_CHAPTER_BOOKS.contains(book) {
//                                        bodyString = bodyString! + "Chapter " + chapter + "<br/><br/>"
//                                    }
//                                    if let verses = xml.text?[book]?[chapter]?.keys.sorted(by: { Int($0) < Int($1) }) {
//                                        for verse in verses {
//                                            if let text = xml.text?[book]?[chapter]?[verse] {
//                                                bodyString = bodyString! + "<sup>" + verse + "</sup>" + text + " "
//                                            } // <font size=\"-1\"></font>
//                                        }
//                                        bodyString = bodyString! + "<br/>"
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    
//                    bodyString = bodyString! + "</html></body>"
//                    
//                    html?[reference!] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
//                }
//                
//                xml.parser = nil
//            }
//        }
//    }
}
