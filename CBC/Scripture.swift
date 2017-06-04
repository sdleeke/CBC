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
//    {
//        didSet {
//            print(testament)
//        }
//    }

    var book:String?
//    {
//        didSet {
//            print(book)
//        }
//    }
    
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
    var strings = [String]()
    
    var elementNames = [String]()
    var dicts = [Dict]()

//    var currentDict:[String:Any]?
    
    var book:String?
    var chapter:String?
    var verse:String?

              //Book //Chap  //Verse //Text
    var text:[String:[String:[String:String]]]?
    
//    var parentDict:Dict?
//    var currentDict:Dict?
    
    var dict = Dict()
}

class Dict : NSObject {
    var data = [String:Any]()
    
    subscript(key:String) -> Any? {
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
        print("\n\nStart Element\n")
        
        print("parentElementName",xml.elementNames.last as Any)
        
        print("elementName",elementName)
        print("namespaceURI",namespaceURI as Any)
        print("qName",qName as Any)
        print("attributeDict",attributeDict)
        
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

        xml.dicts.append(currentDict[name] as! Dict)

//        if let currentElementName = xml.elementNames.last  {
//            if currentDict[currentElementName] == nil {
//                currentDict[currentElementName] = Dict()
//            }
//            xml.dicts.append(currentDict[currentElementName] as! Dict)
//        }

        xml.elementNames.append(name)
        
        print(xml.dict)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        print("\n\nEnd Element\n")
        
        print("elementName",elementName)
        print("namespaceURI",namespaceURI as Any)
        print("qName",qName as Any)
        
//        if (xml.currentDict == nil) {
//            xml.currentDict = xml.dict
//        }
        
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
        
        print("parent elementName",xml.elementNames.last as Any)
        
        print(xml.dict)

//        if xml.text == nil {
//            xml.text = [String:[String:[String:String]]]()
//        }
//        
//        switch elementName {
//        case "bookname":
//            xml.book = xml.string
//            
//            if xml.text?[xml.book!] == nil {
//                xml.text?[xml.book!] = [String:[String:String]]()
//            }
//            break
//            
//        case "chapter":
//            xml.chapter = xml.string
//            
//            if xml.text?[xml.book!]?[xml.chapter!] == nil {
//                xml.text?[xml.book!]?[xml.chapter!] = [String:String]()
//            }
//            break
//            
//        case "verse":
//            xml.verse = xml.string
//            break
//            
//        case "text":
//            xml.text?[xml.book!]?[xml.chapter!]?[xml.verse!] = xml.string
//            //            print(scriptureText)
//            break
//            
//        default:
//            break
//        }
    }
    
    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String)
    {
        print(elementName)
        print(model)
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        //        print(string)
        
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
    var picker = Picker()

    var selected = Selected()

    var xml = XML()
    
    var booksChaptersVerses:BooksChaptersVerses?
    
    var reference:String?
    {
        willSet {
            
        }
        didSet {
            if reference != oldValue {
                // MUST update the data structure.
                setupBooksChaptersVerses()
            }
        }
    }
    
    init(reference:String?)
    {
        super.init()
        
        self.reference = reference
        setupBooksChaptersVerses() // MUST BE HERE.  DIDSET NOT CALLED IN INITIALIZER
    }
    
    lazy var html:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func setupBooksChaptersVerses()
    {
        guard let scriptureReference = reference else {
            return
        }
        
//        if let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") {
        
        let booksAndChaptersAndVerses = BooksChaptersVerses()
        
        var scriptures = [String]()
        
        var string = scriptureReference
        
        let separator = ";"

        while (string.range(of: separator) != nil) {
            if let lowerBound = string.range(of: separator)?.lowerBound {
                scriptures.append(string.substring(to: lowerBound))
            }
            
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
        
//        }

    }
    
    func jsonFromURL(url:String) -> [String:Any]?
    {
        if let data = try? Data(contentsOf: URL(string: url)!) {
//            var final:String?
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json as? [String:Any]
            } catch let error as NSError {
                print(error.localizedDescription)
            }

//            if let string = String(data: data, encoding: .utf8) {
//                print(string)
//                
//                let initial = string.substring(from: "(".endIndex)
//                
//                final = initial.substring(to:initial.index(initial.endIndex, offsetBy: -");".characters.count))
                
//                if let range = initial.range(of: ");") {
//                    final = initial.substring(to: range.lowerBound)
//                }
                
//                print(final)
                
//                if let finalData = final?.data(using: String.Encoding.utf8) {
//                    do {
//                        let json = try JSONSerialization.jsonObject(with: finalData, options: [])
//                        return json as? [String:Any]
//                    } catch let error as NSError {
//                        print(error.localizedDescription)
//                    }
//                }
//            }
        }
        
        return nil
    }
    
    func loadHTMLVerseFromURL() -> String? // _ reference:String?
    {
        guard reference != nil else {
            return nil
        }
        
        let urlString = "http://www.esvapi.org/v2/rest/passageQuery?key=5b906fb1eeed04e1&passage=\(reference!)&include-audio-link=false&include-headings=false&include-footnotes=false".replacingOccurrences(of: " ", with: "%20")

        if let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url) {
                if let string = String(data: data, encoding: .utf8) {
                    var bodyString = "<!DOCTYPE html><html><body>"

                    bodyString = bodyString + string

                    bodyString = bodyString + "</html></body>"
                    
                    return insertHead(bodyString,fontSize:Constants.FONT_SIZE)
                }
            }
        }
        
        return nil
    }

    func loadJSONVerseFromURL() -> [String:Any]? // _ reference:String?
    {
        guard reference != nil else {
            return nil
        }
        
//        let urlString = "https://getbible.net/json?passage=\(reference!)&version=nasb".replacingOccurrences(of: " ", with: "%20")
        
        let urlString = Constants.SCRIPTURE_BASE_URL + "\(reference!)&include_marginalia=true".replacingOccurrences(of: " ", with: "%20")
        
//        var mediaItemDicts = [[String:String]]()
        
        let json = jsonFromURL(url: urlString)
        
        if let json = json {
            print(json)
//            print(json["response"])
            
            return json
        } else {
            print("could not get json from URL, make sure that URL contains valid json.")
        }
        
        return nil
    }
    
    func load() // _ reference:String?
    {
        loadJSON() // reference
    }
    
    func loadHTML() // _ reference:String?
    {
        html?[reference!] = loadHTMLVerseFromURL() // reference
    }
    
//    func loadXMLVerseFromURL(_ reference:String?) -> [String:String]?
//    {
//        guard xml.parser == nil else {
//            return nil
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
//                        //                        bookNumberInBible($0) < bookNumberInBible($1)
//                    }) {
//                        for book in books {
//                            bodyString = bodyString! + book // + "<br/>"
//                            if let chapters = xml.text?[book]?.keys.sorted(by: { Int($0) < Int($1) }) {
//                                //                                bodyString = bodyString! + "<br/>"
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
    
    func loadXMLVerseFromURL(_ reference:String?) -> [String:Any]?
    {
        guard xml.parser == nil else {
            return nil
        }
        
        guard let scriptureReference = reference?.replacingOccurrences(of: " ", with: "%20") else {
            return nil
        }
    
        xml.text = nil
        
//        if let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ").replacingOccurrences(of: " ", with: "%20") {
        
        let urlString = "http://www.esvapi.org/v2/rest/passageQuery?key=5b906fb1eeed04e1&passage=\(scriptureReference)&include-audio-link=false&include-headings=false&output-format=crossway-xml-1.0"
        
        if let url = URL(string: urlString) {
            self.xml.parser = XMLParser(contentsOf: url)
            
            self.xml.parser?.delegate = self
            
            if let success = self.xml.parser?.parse(), success {
                var bodyString:String?
                
                bodyString = "<!DOCTYPE html><html><body>"
                
                bodyString = bodyString! + "Scripture: " + reference! + "<br/><br/>"
                
                if let books = xml.text?.keys.sorted(by: {
                    
                    reference?.range(of: $0)?.lowerBound < reference?.range(of: $1)?.lowerBound
                    
                    //                        bookNumberInBible($0) < bookNumberInBible($1)
                }) {
                    for book in books {
                        bodyString = bodyString! + book // + "<br/>"
                        if let chapters = xml.text?[book]?.keys.sorted(by: { Int($0) < Int($1) }) {
                            //                                bodyString = bodyString! + "<br/>"
                            for chapter in chapters {
                                bodyString = bodyString! + "<br/>"
                                if !Constants.NO_CHAPTER_BOOKS.contains(book) {
                                    bodyString = bodyString! + "Chapter " + chapter + "<br/><br/>"
                                }
                                if let verses = xml.text?[book]?[chapter]?.keys.sorted(by: { Int($0) < Int($1) }) {
                                    for verse in verses {
                                        if let text = xml.text?[book]?[chapter]?[verse] {
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
                
                html?[reference!] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
            }
            
            xml.parser = nil
        }
        
//        }
        
        return xml.dict.data
    }
    
    func loadXML(_ reference:String?)
    {
        var bodyString:String?
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString = bodyString! + "Scripture: " + reference! // + "<br/><br/>"
        
//        guard let _ = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") else {
//            return
//        }
        
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
                    
//                    scriptureReference = scriptureReference.replacingOccurrences(of: "Psalm ", with: "Psalms ")
                    
                    print(scriptureReference)
                    
                    guard let dict = loadXMLVerseFromURL(scriptureReference) else {
                        return
                    }
                    
                    print(dict["book"] as Any)
                    
                    if let bookDicts = dict["book"] as? [[String:Any]] {
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
                        
                        if let book = dict["book_name"] as? String {
                            bodyString = bodyString! + book + "<br/><br/>"
                    }
                    
                    if let chapter = dict["chapter_nr"] as? Int {
                        bodyString = bodyString! + "Chapter \(chapter)"  + "<br/><br/>"
                    }
                    
                    if let chapterDict = dict["chapter"] as? [String:Any] {
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
        
        bodyString = bodyString! + "<br/>"
        
        bodyString = bodyString! + "</html></body>"
        
        html?[reference!] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }
    
    func loadJSON() // _ reference:String?
    {
        var bodyString:String?
        
        bodyString = "<!DOCTYPE html><html><body>"
        
//        bodyString = bodyString! + "Scripture: " + reference! // + "<br/><br/>"
        
//        guard let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") else {
//            return
//        }
        
        guard let books = booksFromScriptureReference(reference) else {
            return
        }

        print(books)
        
        guard let data = booksChaptersVerses?.data else {
            return
        }
        
        print(data)
        
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
                    
//                    scriptureReference = scriptureReference.replacingOccurrences(of: "Psalm ", with: "Psalms ")
                    
                    print(scriptureReference)
                    
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
                    
                    for passage in passages {
//                        if copyright != nil {
//                            bodyString = bodyString! + "<br/><br/>"
//                        }
                        
                        if let display = passage["display"] as? String {
                            bodyString = bodyString! + "<h3><a href=\"https://www.biblegateway.com/passage/?search=\(display.replacingOccurrences(of: " ", with: "%20"))&version=NASB\">" + display + "</a></h3>"
                        }
                        
//                        if let reference = passage["reference"] as? String {
//                            bodyString = bodyString! + reference + "<br/>"
//                        }
                        
                        if var text = passage["text"] as? String {
                            text = text.replacingOccurrences(of: "span><span", with: "span> <span")
                            text = text.replacingOccurrences(of: "<sup", with: " <sup")
                            text = text.replacingOccurrences(of: "/p>\n<p", with: "/p><p")
//                            text = text.replacingOccurrences(of: "  <sup", with: " <sup")
//                            text = text.replacingOccurrences(of: ".<sup", with: ". <sup")
//                            text = text.replacingOccurrences(of: ",<sup", with: ", <sup")
//                            text = text.replacingOccurrences(of: "</p>\n<p ", with: "</p><p ")
                            
                            bodyString = bodyString! + text // + "<br/>"
                        }
                        
//                        if let display_abbreviation = passage["display_abbreviation"] as? String {
//                            bodyString = bodyString! + display_abbreviation
//                        }
                        
                        if copyright == nil {
                            copyright = passage["copyright"] as? String
                        }
                    }

                    
//                    print(dict["book"])
//                    
//                    if let bookDicts = dict["book"] as? [[String:Any]] {
//                        var header = false
//                        
//                        var lastVerse = 0
//                        
//                        for bookDict in bookDicts {
//                            if !header {
//                                bodyString = bodyString! + "<br><br>"
//                                
//                                if let book = bookDict["book_name"] as? String {
//                                    bodyString = bodyString! + book + "<br/><br/>"
//                                }
//                                
//                                if let chapter = bookDict["chapter_nr"] as? String {
//                                    bodyString = bodyString! + "Chapter " + chapter + "<br/><br/>"
//                                }
//                                
//                                header = true
//                            }
//                            
//                            if let chapterDict = bookDict["chapter"] as? [String:Any] {
//                                print(chapterDict)
//                                print(chapterDict.keys.sorted())
//                                
//                                let keys = chapterDict.keys.map({ (string:String) -> Int in
//                                    return Int(string)!
//                                }).sorted()
//                                
//                                for key in keys {
//                                    print(key)
//                                    if let verseDict = chapterDict["\(key)"] as? [String:Any] {
//                                        print(verseDict)
//                                        if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
//                                            if let number = Int(verseNumber) {
//                                                if lastVerse != 0, number != (lastVerse + 1) {
//                                                    bodyString = bodyString! + "<br><br>"
//                                                }
//                                                lastVerse = number
//                                            }
//                                            
//                                            bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
//                                        }
//                                        if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
//                                            if lastVerse != 0, verseNumber != (lastVerse + 1) {
//                                                bodyString = bodyString! + "<br><br>"
//                                            }
//                                            bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
//                                            lastVerse = verseNumber
//                                        }
//                                    }
//                                }
//                                //                        bodyString = bodyString! + "<br/>"
//                            }
//                        }
//                    } else
//                        
//                    if let book = dict["book_name"] as? String {
//                            bodyString = bodyString! + book + "<br/><br/>"
//                    }
//                    
//                    if let chapter = dict["chapter_nr"] as? Int {
//                        bodyString = bodyString! + "Chapter \(chapter)"  + "<br/><br/>"
//                    }
//                    
//                    if let chapterDict = dict["chapter"] as? [String:Any] {
//                        print(chapterDict)
//                        print(chapterDict.keys.sorted())
//                        
//                        let keys = chapterDict.keys.map({ (string:String) -> Int in
//                            return Int(string)!
//                        }).sorted()
//                        
//                        for key in keys {
//                            print(key)
//                            if let verseDict = chapterDict["\(key)"] as? [String:Any] {
//                                print(verseDict)
//                                if let verseNumber = verseDict["verse_nr"] as? String, let verse = verseDict["verse"] as? String {
//                                    bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
//                                }
//                                if let verseNumber = verseDict["verse_nr"] as? Int, let verse = verseDict["verse"] as? String {
//                                    bodyString = bodyString! + "<sup>\(verseNumber)</sup>" + verse + " "
//                                }
//                            }
//                        }
//                        //                        bodyString = bodyString! + "<br/>"
//                    }
                }
            }
        }
        
        if let fums = fums, let copyright = copyright {
            bodyString = bodyString! + "<p class=\"copyright\">" +  copyright.replacingOccurrences(of: ",1", with: ", 1") + "</p>"
            bodyString = bodyString! + fums
        }

//        bodyString = bodyString! + "<br/>"
        
        bodyString = bodyString! + "</html></body>"
        
        print(bodyString as Any)
        
        html?[reference!] = insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }
}
