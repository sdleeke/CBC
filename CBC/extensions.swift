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

extension UIViewController
{
    // This also works as a stand alone function w/ the view controller passed in as a parameter.
    func process(disableEnable:Bool = true,hideSubviews:Bool = false,work:(()->(Any?))?,completion:((Any?)->())?)
    {
        guard (work != nil) && (completion != nil) else {
            return
        }
        
//        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
//            return
//        }
        
        guard let container = Globals.shared.loadingViewController?.view else {
            return
        }
        
        guard let view = self.view else {
            return
        }

        Thread.onMainThread {
            // Brute force disable
            if disableEnable {
                if let buttons = self.navigationItem.rightBarButtonItems {
                    for button in buttons {
                        button.isEnabled = false
                    }
                }
                
                if let buttons = self.navigationItem.leftBarButtonItems {
                    for button in buttons {
                        button.isEnabled = false
                    }
                }
                
                if let buttons = self.toolbarItems {
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
                    // Brute force enable => need to be set according to state in completion.
                    if disableEnable {
                        if let buttons = self.navigationItem.rightBarButtonItems {
                            for button in buttons {
                                button.isEnabled = true
                            }
                        }
                        
                        if let buttons = self.navigationItem.leftBarButtonItems {
                            for button in buttons {
                                button.isEnabled = true
                            }
                        }
                        
                        if let buttons = self.toolbarItems {
                            for button in buttons {
                                button.isEnabled = true
                            }
                        }
                    }
                    
                    completion?(data)
                    
                    if container.superview != nil { //  != viewController.view
                        container.removeFromSuperview()
                    }
                }
            }
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

extension Double {
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
            var string = String()
            
            for char in self {
                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet.alphanumerics.contains(unicodeScalar) { // !CharacterSet(charactersIn:
                    string.append(char)
                }
            }

            return string
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
    func setTitleTextAttributes(_ attributes:[NSAttributedStringKey:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.highlighted)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UISegmentedControl
{
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.highlighted)
//        setTitleTextAttributes(attributes, for: UIControlState.selected)
    }
}

extension UIButton
{
    func setTitle(_ string:String? = nil)
    {
        setTitle(string, for: UIControlState.normal)
        setTitle(string, for: UIControlState.disabled)
        setTitle(string, for: UIControlState.highlighted)
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
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.normal)
        }
        
        guard let range = self.lowercased().range(of: searchText.lowercased()) else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.normal)
        }
        
        let highlightedString = NSMutableAttributedString()
        
        let before = String(self[..<range.lowerBound])
        let string = String(self[range])
        let after = String(self[range.upperBound...])
        
        highlightedString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
        highlightedString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
        highlightedString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
        
        return highlightedString
    }
    
    func boldHighlighted(_ searchText:String?) -> NSAttributedString
    {
        guard let searchText = searchText else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.bold)
        }
        
        guard let range = self.lowercased().range(of: searchText.lowercased()) else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.bold)
        }
        
        let highlightedString = NSMutableAttributedString()
        
        let before = String(self[..<range.lowerBound])
        let string = String(self[range])
        let after = String(self[range.upperBound...])
        
        highlightedString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.bold))
        highlightedString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.boldHighlighted))
        highlightedString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.bold))
        
        return highlightedString
    }
}

extension String
{
    var books : [String]?
    {
        get {
            return booksFromScriptureReference(self)
        }
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
    
    var tokensAndCounts : [String:Int]?
    {
        get {
            return tokensAndCountsFromString(self) // tokensAndCountsFromString // tokensAndCountsInString uses NSLinguisticTagger but that doesn't do contractions
        }
    }
}

extension String
{
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
                    return cachesURL?.appendingPathComponent(lastPathComponent)
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
    var nsLemmas : [(String,String,NSRange)]?
    {
        get {
            return nsLemmasInString(string: self)
        }
    }
    
    var nsNameTypes : [(String,String,NSRange)]?
    {
        get {
            return nsNameTypesInString(string: self)
        }
    }
    
    var nsLexicalTypes : [(String,String,NSRange)]?
    {
        get {
            return nsLexicalTypesInString(string: self)
        }
    }
    
    var nsTokenTypes : [(String,String,NSRange)]?
    {
        get {
            return nsTokenTypesInString(string: self)
        }
    }
    
    var nsNameTypesAndLexicalClasses : [(String,String,NSRange)]?
    {
        get {
            return nsNameTypesAndLexicalClassesInString(string: self)
        }
    }
    
    @available(iOS 12.0, *)
    var nlLemmas : [(String,String,Range<String.Index>)]?
    {
        get {
            return nlLemmasInString(string: self)
        }
    }
    
    @available(iOS 12.0, *)
    var nlTokenTypes : [(String,String,Range<String.Index>)]?
    {
        get {
            return nlTokenTypesInString(string: self)
        }
    }
    
    @available(iOS 12.0, *)
    var nlNameTypesAndLexicalClasses : [(String,String,Range<String.Index>)]?
    {
        get {
            return nlNameTypesAndLexicalClassesInString(string: self)
        }
    }

    func nsNameAndLexicalTypesMarkup(annotated:Bool) -> String?
    {
        guard let nameAndLexicalTypes = self.nsNameTypesAndLexicalClasses else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        var types = Set<String>()
        
        for nameAndLexicalType in nameAndLexicalTypes {
            types.insert(nameAndLexicalType.1)
        }
        
        let lexicalTypes = Array(types).sorted()
        
        var lexicalTypeColors = [String:String]()
        
        var count = 0
        for lexicalType in lexicalTypes {
            lexicalTypeColors[lexicalType] = colors[count % colors.count]
            count += 1
        }
        
        for lexicalType in lexicalTypes {
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
        
        return insertHead(htmlString, fontSize:Constants.FONT_SIZE)
    }
    
    var nsNameAndLexicalTypesMarkup : String?
    {
        get {
            return nsNameAndLexicalTypesMarkup(annotated:false)
        }
    }
    
    @available(iOS 12.0, *)
    func nlNameAndLexicalTypesMarkup(annotated:Bool) -> String?
    {
        guard let nameAndLexicalTypes = self.nlNameTypesAndLexicalClasses else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        var types = Set<String>()
        
        for nameAndLexicalType in nameAndLexicalTypes {
            types.insert(nameAndLexicalType.1)
        }
        
        let lexicalTypes = Array(types).sorted()
        
        var lexicalTypeColors = [String:String]()
        
        var count = 0
        for lexicalType in lexicalTypes {
            lexicalTypeColors[lexicalType] = colors[count % colors.count]
            count += 1
        }
        
        for lexicalType in lexicalTypes {
            if let color = lexicalTypeColors[lexicalType] {
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(lexicalType)</td></tr>"
                htmlString += "</table>"
                //                    htmlString += "<mark style=\"background-color:\(color);\">\(lexicalType)</mark>"
                if lexicalType != lexicalTypes.last {
                    htmlString += " "
                }
            }
        }
        htmlString += "<br/><br/>"
        
        var text = self
        
        for nameAndLexicalType in nameAndLexicalTypes.reversed() {
            let token = nameAndLexicalType.0
            let nameOrLexicalType = nameAndLexicalType.1
            let range = nameAndLexicalType.2
            
            let before = text[..<range.lowerBound]
            let after = text[range.upperBound...]
            
            if let color = lexicalTypeColors[nameOrLexicalType] {
                var htmlString = String()
                
                htmlString += "<table style=\"display:inline;\">"
                htmlString += "<tr><td style=\"background-color:\(color)\">\(token)</td></tr>"
                if annotated {
                    htmlString += "<tr><td style=\"font-size:75%;background-color:\(color)\">\(nameOrLexicalType)</td></tr>"
                }
                htmlString += "</table>"
                
                text = before + htmlString + after
                
                //  <sup>\(nameOrLexicalType)</sup> style=\"background-color:\(color);\"
                //                    text = before + "<mark style=\"background-color:\(color);\">\(token)</mark>" + after
            } else {
                text = before + "<mark>\(token)</mark>" + after
            }
        }
        
        htmlString += text.replacingOccurrences(of: "\n\n", with: "<br/><br/>")
        htmlString += "</body></html>"
        
        return insertHead(htmlString, fontSize:Constants.FONT_SIZE)

    }
    
    @available(iOS 12.0, *)
    var nlNameAndLexicalTypesMarkup : String?
    {
        get {
            return nlNameAndLexicalTypesMarkup(annotated:false)
        }
    }
}

extension URL
{
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
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL.path)
            
            if let num = fileAttributes[FileAttributeKey.size] as? Int {
                return num
            }
        } catch let error {
            debug("failed to get file attributes for \(fileSystemURL): \(error.localizedDescription)")
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
            try UIImageJPEGRepresentation(self, 1.0)?.write(to: url, options: [.atomic])
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
    var pdf : PDFPage?
    {
        get {
            return PDFPage(image: self)
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


