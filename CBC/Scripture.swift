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
    
    var reference:String?
    {
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
    var strings = [String]()
    
    var elementNames = [String]()
    var dicts = [Dict]()

    var book:String?
    var chapter:String?
    var verse:String?

    // Make thread safe?

              //Book //Chap  //Verse //Text
    var text:[String:[String:[String:String]]]?
    
    var dict = Dict()
}

class Dict : NSObject {
    // Make thread safe?
    var data = [String:Any]()
    
    subscript(key:String) -> Any?
    {
        get {
            return data[key]
        }
        set {
            data[key] = newValue
        }
    }
    
    override var description: String {
        get {
            return data.description
        }
    }
}

extension Scripture : XMLParserDelegate
{
    // MARK: XMLParserDelegate
    
    func parserDidStartDocument(_ parser: XMLParser)
    {
        xml.dicts.append(xml.dict)
        print(xml.dict)
    }
    
    func parserDidEndDocument(_ parser: XMLParser)
    {
        print("\n\nEnd Document\n")
        
        print(xml.dict)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
    {
        print(parseError.localizedDescription)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
    {
        guard let currentDict = xml.dicts.last else {
            return
        }
        
        var name = elementName

        xml.strings.append(String())

        for key in attributeDict.keys {
            if key.contains("id") {
                if let id = attributeDict[key] {
                    name = name + "-" + id
                }
            }
        }

        currentDict[name] = Dict()

        if attributeDict.count > 0 {
            (currentDict[name] as? Dict)?["attributes"] = attributeDict
        }

        if let dict = currentDict[name] as? Dict {
            xml.dicts.append(dict)
        }

        xml.elementNames.append(name)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        if let currentDict = xml.dicts.last {
            if let string = xml.strings.last {
                if !string.isEmpty {
                    currentDict["text"] = string
                }
                xml.strings.removeLast()
            }
            xml.dicts.removeLast()
        }
        
        xml.elementNames.removeLast()
    }
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String)
    {
        print(elementName)
        print(model)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        var count = xml.strings.count
        
        if count > 0 {
            count -= 1
            xml.strings[count] = (xml.strings[count] + string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            let string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if !string.isEmpty {
                xml.strings.append(string)
            }
        }
    }
}

class Scripture : NSObject
{
//    var passages : [[String:Any]]?
    
    var picker = Picker()

    var selected = Selected()

    lazy var xml = {
        return XML()
    }()
    
    var booksChaptersVerses:BooksChaptersVerses?
    
    override var description: String
    {
        return reference ?? ""
    }
    
    var reference:String?
    {
        willSet {
            
        }
        didSet {
            if reference != oldValue {
                // MUST update the data structure.
//                _books = nil
                books = nil
                setupBooksChaptersVerses()
            }
        }
    }
    
//    lazy var books:Shadowed<[String]> = {
//        return Shadowed<[String]>(get: { () -> ([String]?) in
//            return booksFromScriptureReference(self.reference)
//        })
//    }()
    
    private var _books:[String]?
    {
        didSet {
            
        }
    }
    var books:[String]?
    {
        get {
            guard _books == nil else {
                return _books
            }
            
            _books = booksFromScriptureReference(reference)
            
            return _books
        }
        set {
            _books = newValue
        }
    }
    
//    var htmlString : String?
//    {
//        guard let reference = reference else {
//            return nil
//        }
//
//        return html?[reference]
//    }
    
    func text(_ reference:String?) -> String?
    {
        guard let reference = reference else {
            return nil
        }
        
        guard var string = stripHTML(html?[reference]) else {
            return nil
        }

        if let startRange = string.range(of: "</sup>") {
            string = String(string[startRange.upperBound...])
        }

        while string.range(of: "<sup ") != nil {
            if let startRange = string.range(of: "<sup ") {
                if let endRange = String(string[startRange.lowerBound...]).range(of: "</sup>") {
                    let to = String(string[..<startRange.lowerBound])
                    let from = String(String(string[startRange.lowerBound...])[..<endRange.upperBound])
                    
                    string = to + String(string[(to + from).endIndex...])
                }
            }
        }
        
        while string.range(of: "<h3") != nil {
            if let startRange = string.range(of: "<h3") {
                if let endRange = String(string[startRange.lowerBound...]).range(of: "</h3>") {
                    let to = String(string[..<startRange.lowerBound])
                    let from = String(String(string[startRange.lowerBound...])[..<endRange.upperBound])
                    
                    string = to + String(string[(to + from).endIndex...])
                }
            }
        }
        
        if let startRange = string.range(of: "\n\n\n ") {
            if let endRange = String(string[startRange.lowerBound...]).range(of: "</noscript>") {
                let to = String(string[..<startRange.lowerBound])
                let from = String(String(string[startRange.lowerBound...])[..<endRange.upperBound])
                
                string = to + String(string[(to + from).endIndex...])
            }
        }

        return string
    }
    
    init(reference:String?)
    {
        super.init()
        
        self.reference = reference
        
        setupBooksChaptersVerses() // MUST BE HERE.  DIDSET NOT CALLED IN INITIALIZER
    }
    
    deinit {
        
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func setupBooksChaptersVerses()
    {
        guard let scriptureReference = reference else {
            return
        }
        
        guard let books = books else {
            return
        }
        
        let booksAndChaptersAndVerses = BooksChaptersVerses()
        
//        var scriptures = [String]()
        
//        var string = scriptureReference
        
//        let separator = ";"
//
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
        
//        while (string.range(of: separator) != nil) {
//            if let lowerBound = string.range(of: separator)?.lowerBound {
//                scriptures.append(String(string[..<lowerBound]))
//            }
//
//            if let range = string.range(of: separator) {
//                string = String(string[range.upperBound...])
//            }
//        }
//
//        scriptures.append(string)
        
//        var lastBook:String?
        
        for scripture in scriptures {
            if let book = scripture.books?.first {
                var reference : String?
                
                if let range = scripture.range(book) {
                    reference = String(scripture[range.upperBound...])
                }
                
//                var bk = book
//
//                repeat {
//                    if let range = scripture.range(of: bk) {
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

                if let chaptersAndVerses = chaptersAndVersesFromScripture(book:book,reference:reference) {
                    if let _ = booksAndChaptersAndVerses[book] {
                        for key in chaptersAndVerses.keys {
                            if let verses = chaptersAndVerses[key] {
                                if let _ = booksAndChaptersAndVerses[book]?[key] {
                                    booksAndChaptersAndVerses[book]?[key]?.append(contentsOf: verses)
                                } else {
                                    booksAndChaptersAndVerses[book]?[key] = verses
                                }
                            }
                        }
                    } else {
                        booksAndChaptersAndVerses[book] = chaptersAndVerses
                    }
                }
                
                if let chapters = booksAndChaptersAndVerses[book]?.keys {
                    for chapter in chapters {
                        if booksAndChaptersAndVerses[book]?[chapter] == nil {
                            print(description,book,chapter)
                        }
                    }
                }
            }
        }
        
        booksChaptersVerses = booksAndChaptersAndVerses.data?.count > 0 ? booksAndChaptersAndVerses : nil
    }
    
    func loadHTMLVerseFromURL() -> String?
    {
        guard let reference = reference else {
            return nil
        }
        
        let urlString = "http://www.esvapi.org/v2/rest/passageQuery?key=5b906fb1eeed04e1&passage=\(reference)&include-audio-link=false&include-headings=false&include-footnotes=false".replacingOccurrences(of: " ", with: "%20")

        if let url = URL(string: urlString) {
            if let data = url.data {
                if let string = String(data: data, encoding: .utf8) {
                    var bodyString = "<!DOCTYPE html><html><body>"

                    bodyString = bodyString + string

                    bodyString = bodyString + "</body></html>"
                    
                    return insertHead(bodyString,fontSize:Constants.FONT_SIZE)
                }
            }
        }
        
        return nil
    }

    func loadJSONVerseFromURL() -> [String:Any]?
    {
        guard Globals.shared.reachability.isReachable else {
            return nil
        }
        
        guard let reference = reference else {
            return nil
        }
        
        //
        let urlString = Constants.SCRIPTURE_BASE_URL + "\(reference)&include_marginalia=true".replacingOccurrences(of: " ", with: "%20")

        return urlString.url?.data?.json as? [String:Any]
    }
    
    func load()
    {
        loadHTMLFromJSON()
    }
    
    func loadHTML()
    {
        if let reference = reference {
            html?[reference] = loadHTMLVerseFromURL()
        }
    }
    
    func loadXMLVerseFromURL(_ reference:String?) -> [String:Any]?
    {
        guard let reference = reference else {
            return nil
        }
        
        guard xml.parser == nil else {
            return nil
        }
        
        let scriptureReference = reference.replacingOccurrences(of: " ", with: "%20")
        
        xml.text = nil
        
        let urlString = "http://www.esvapi.org/v2/rest/passageQuery?key=5b906fb1eeed04e1&passage=\(scriptureReference)&include-audio-link=false&include-headings=false&output-format=crossway-xml-1.0"
        
        if let url = URL(string: urlString) {
            self.xml.parser = XMLParser(contentsOf: url)
            
            self.xml.parser?.delegate = self
            
            if let success = self.xml.parser?.parse(), success {
                var bodyString:String!
                
                bodyString = "<!DOCTYPE html><html><body>"
                
                bodyString = bodyString + "Scripture: " + reference + "<br/><br/>"
                
                if let books = xml.text?.keys.sorted(by: { (first:String, second:String) -> Bool in
                    if  let first = reference.range(of: first)?.lowerBound,
                        let second = reference.range(of: second)?.lowerBound {
                        return first < second
                    } else {
                        return false
                    }
                }) {
                    for book in books {
                        bodyString = bodyString + book
                        if let chapters = xml.text?[book]?.keys.sorted(by: { Int($0) < Int($1) }) {
                            for chapter in chapters {
                                bodyString = bodyString + "<br/>"
                                if !Constants.NO_CHAPTER_BOOKS.contains(book) {
                                    bodyString = bodyString + "Chapter " + chapter + "<br/><br/>"
                                }
                                if let verses = xml.text?[book]?[chapter]?.keys.sorted(by: { Int($0) < Int($1) }) {
                                    for verse in verses {
                                        if let text = xml.text?[book]?[chapter]?[verse] {
                                            bodyString = bodyString + "<sup>" + verse + "</sup>" + text + " "
                                        }
                                    }
                                    bodyString = bodyString + "<br/>"
                                }
                            }
                        }
                    }
                }
                
                bodyString = bodyString + "</body></html>"
                
                html?[reference] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
            }
            
            xml.parser = nil
        }
        
        return xml.dict.data
    }
    
    func loadXML(_ reference:String?)
    {
        guard let reference = reference else {
            return
        }
        
        var bodyString:String!
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString = bodyString + "Scripture: " + reference
        
        guard let data = booksChaptersVerses?.data else {
            return
        }
        
        print(data)
        
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
                                        
                    guard let dict = loadXMLVerseFromURL(scriptureReference) else {
                        return
                    }
                    
                    print(dict["book"] as Any)
                    
                    if let bookDicts = dict["book"] as? [[String:Any]] {
                        var header = false
                        
                        var lastVerse = 0
                        
                        for bookDict in bookDicts {
                            if !header {
                                bodyString = bodyString + "<br><br>"
                                
                                if let book = bookDict["book_name"] as? String {
                                    bodyString = bodyString + book + "<br/><br/>"
                                }
                                
                                if let chapter = bookDict["chapter_nr"] as? String {
                                    bodyString = bodyString + "Chapter " + chapter + "<br/><br/>"
                                }
                                
                                header = true
                            }
                            
                            if let chapterDict = bookDict["chapter"] as? [String:Any] {
                                print(chapterDict)
                                print(chapterDict.keys.sorted())
                                
                                let keys = chapterDict.keys.map({ (string:String) -> Int in
                                    if let num = Int(string) {
                                        return num
                                    } else {
                                        return -1
                                    }
                                }).sorted()
                                
                                for key in keys {
                                    print(key)
                                    if let verseDict = chapterDict["\(key)"] as? [String:Any] {
                                        print(verseDict)
                                        if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
                                            if let number = Int(verseNumber) {
                                                if lastVerse != 0, number != (lastVerse + 1) {
                                                    bodyString = bodyString + "<br><br>"
                                                }
                                                lastVerse = number
                                            }
                                            
                                            bodyString = bodyString + "<sup>\(verseNumber)</sup>" + verse + " "
                                        }
                                        if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
                                            if lastVerse != 0, verseNumber != (lastVerse + 1) {
                                                bodyString = bodyString + "<br><br>"
                                            }
                                            bodyString = bodyString + "<sup>\(verseNumber)</sup>" + verse + " "
                                            lastVerse = verseNumber
                                        }
                                    }
                                }
                            }
                        }
                    } else
                        
                        if let book = dict["book_name"] as? String {
                            bodyString = bodyString + book + "<br/><br/>"
                    }
                    
                    if let chapter = dict["chapter_nr"] as? Int {
                        bodyString = bodyString + "Chapter \(chapter)"  + "<br/><br/>"
                    }
                    
                    if let chapterDict = dict["chapter"] as? [String:Any] {
                        print(chapterDict)
                        print(chapterDict.keys.sorted())
                        
                        let keys = chapterDict.keys.map({ (string:String) -> Int in
                            if let num = Int(string) {
                                return num
                            } else {
                                return -1
                            }
                        }).sorted()
                        
                        for key in keys {
                            print(key)
                            if let verseDict = chapterDict["\(key)"] as? [String:Any] {
                                print(verseDict)
                                if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
                                    bodyString = bodyString + "<sup>\(verseNumber)</sup>" + verse + " "
                                }
                                if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
                                    bodyString = bodyString + "<sup>\(verseNumber)</sup>" + verse + " "
                                }
                            }
                        }
                    }
                }
            }
        }
        
        bodyString = bodyString + "<br/>"
        
        bodyString = bodyString + "</body></html>"
        
        html?[reference] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }
    
    func loadHTMLFromJSON()
    {
        var bodyString:String!
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        guard let books = books else { // FromScriptureReference(reference)
            return
        }
        
        //        print(books)
        
        guard let data = booksChaptersVerses?.data else {
            return
        }
        
        //        print(data)
        
        var copyright:String?
        
        var fums:String?
        
        for book in books {
            if let chapters = data[book]?.keys.sorted(by: { (first:Int, second:Int) -> Bool in
                if let left = reference?.range(of: "\(first):")?.lowerBound, let right = reference?.range(of: "\(second):")?.lowerBound {
                    return left < right
                } else {
                    return first < second
                }
            }) {
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
                    
                    guard let dict = Scripture(reference: scriptureReference).loadJSONVerseFromURL() else {
                        return
                    }
                    
                    guard let response = dict["response"] as? [String:Any] else {
                        return
                    }
                    
                    guard let meta = response["meta"] as? [String:Any] else {
                        return
                    }
                    
                    fums = meta["fums"] as? String
                    
                    guard let search = response["search"] as? [String:Any] else {
                        return
                    }
                    
                    guard let result = search["result"] as? [String:Any] else {
                        return
                    }
                    
                    guard let passages = result["passages"] as? [[String:Any]] else {
                        return
                    }
                    
//                    self.passages = passages
                    
                    for passage in passages {
                        if let display = passage["display"] as? String {
                            bodyString = bodyString! + "<h3><a href=\"https://www.biblegateway.com/passage/?search=\(display.replacingOccurrences(of: " ", with: "%20"))&version=NASB\">" + display + "</a></h3>"
                        }
                        
                        if var text = passage["text"] as? String {
                            text = text.replacingOccurrences(of: "span><span", with: "span> <span")
                            text = text.replacingOccurrences(of: "<sup", with: " <sup")
                            text = text.replacingOccurrences(of: ">\n<", with: "><")
                            text = text.replacingOccurrences(of: "<p class=\"b\"></p>", with: "")
                            
                            
                            if var lastRange = text.range(of: "</h3>") {
                                var range = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: text.endIndex))
                                //                                print(text.substring(with: range))
                                
                                while text.range(of: "</h3>", options: String.CompareOptions.caseInsensitive, range: range, locale: nil) != nil {
                                    if let newRange = text.range(of: "</h3>", options: String.CompareOptions.caseInsensitive, range: range, locale: nil) {
                                        lastRange = newRange
                                        range = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: text.endIndex))
                                        //                                        print(text.substring(with: range))
                                    } else {
                                        break
                                    }
                                }
                                
                                if lastRange.upperBound == text.endIndex {
                                    if let newRange = text.range(of: "<h3 class=\"s\">") {
                                        lastRange = newRange
                                        range = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: text.endIndex))
                                        //                                        print(text.substring(with: range))
                                        
                                        while text.range(of: "<h3 class=\"s\">", options: String.CompareOptions.caseInsensitive, range: range, locale: nil) != nil {
                                            if let newRange = text.range(of: "<h3 class=\"s\">", options: String.CompareOptions.caseInsensitive, range: range, locale: nil) {
                                                lastRange = newRange
                                                range = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: text.endIndex))
                                                //                                                print(text.substring(with: range))
                                            } else {
                                                break
                                            }
                                        }
                                        
                                        text = String(text[..<lastRange.lowerBound])
                                    }
                                }
                            }
                            
                            
                            bodyString = bodyString + text
                        }
                        
                        if copyright == nil {
                            copyright = passage["copyright"] as? String
                        }
                    }
                }
            }
        }
        
        if let fums = fums, let copyright = copyright {
            bodyString = bodyString + "<p class=\"copyright\">" +  copyright.replacingOccurrences(of: ",1", with: ", 1") + "</p>"
            bodyString = bodyString + fums
        }
        
        bodyString = bodyString + "</body></html>"
        
        if let reference = reference {
            html?[reference] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
        }
    }
}
