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

class Scripture : NSObject, XMLParserDelegate {
   
    var picker = Picker()

    var selected = Selected()

    var xml = XML()
    
    var reference:String?
    
    init(reference:String?)
    {
        self.reference = reference
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
    
    lazy var html:CachedString? = {
        return CachedString(index: nil)
    }()
    
    func load(_ reference:String?)
    {
        guard xml.parser == nil else {
            return
        }
        
        xml.text = nil
        
        if let scriptureReference = reference?.replacingOccurrences(of: "Psalm ", with: "Psalms ") {
            let urlString = "https://api.preachingcentral.com/bible.php?passage=\(scriptureReference)&version=nasb".replacingOccurrences(of: " ", with: "%20")
            
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
        }
    }
}
