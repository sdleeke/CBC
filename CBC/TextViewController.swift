//
//  TextViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/8/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func scrollRangeToVisible(_ range:Range<String.Index>)
    {
//        let utf16 = attributedText.string.utf16
//
//        let from = range.lowerBound.samePosition(in: utf16)
//        let to = range.upperBound.samePosition(in: utf16)
        
//        let nsRange = NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
//                              length: utf16.distance(from: from, to: to))
        
        Thread.onMainThread {
            let nsRange = NSRange(range, in: self.attributedText.string)
            self.scrollRangeToVisible(nsRange)
        }
    }
}

extension TextViewController: UISearchBarDelegate
{
    //MARK: SearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarShouldBeginEditing",completion:nil)
            return false
        }
        
        searchBar.showsCancelButton = true
        
        if !searchActive {
            searchBar.text = nil
        }
        
//        if searchText?.isEmpty == false {
//            if let _ = textView.attributedText.string.lowercased().range(of: searchText!.lowercased()) {
//                self.searchBar(searchBar, textDidChange: searchText!)
//            }
//        }
        
//        let currentRange = textView.selectedRange
//        let currentRect = textView.bounds.offsetBy(dx: textView.contentOffset.x, dy: textView.contentOffset.x)
        
        
        operationQueue.cancelAllOperations()
//        operationQueue.waitUntilAllOperationsAreFinished()
        
        let attributedText = self.textView.attributedText
        
        let searchOp = CancellableOperation { (test:(()->(Bool))?) in
            let text = stringMarkedBySearchAsAttributedString(attributedString: attributedText,string: self.changedText, searchText: self.searchText, wholeWordsOnly: false, test: test)
            
            Thread.onMainThread {
                self.textView.attributedText = text
            }
        }
        
        operationQueue.addOperation(searchOp)
        
//        DispatchQueue.global(qos: .background).async { // [weak self] in
//            Thread.sleep(forTimeInterval: 0.1)
//            Thread.onMainThread {
//                self.textView.scrollRectToVisible(currentRect, animated: true)
//            }
//        }

//        textView.scrollRangeToVisible(currentRange)

//        if let searchText = searchText,let range = textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
////            let utf16 = textView.attributedText.string.utf16
////
////            let from = range.lowerBound.samePosition(in: utf16)
////            let to = range.upperBound.samePosition(in: utf16)
////
////            let nsRange = NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
////                                  length: utf16.distance(from: from, to: to))
////
////            textView.scrollRangeToVisible(nsRange)
//
//            textView.scrollToRange(range)
//            lastRange = range
//        }
        
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
        if searchBar.text?.isEmpty == true {
            searchActive = false
            searchBar.showsCancelButton = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        self.searchText = searchText

        operationQueue.cancelAllOperations()
//        operationQueue.waitUntilAllOperationsAreFinished()

        let attributedText = self.textView.attributedText
        
        let searchOp = CancellableOperation { (test:(()->(Bool))?) in
            let text = stringMarkedBySearchAsAttributedString(attributedString: attributedText,string: self.changedText, searchText: searchText, wholeWordsOnly: false, test: test)

            Thread.onMainThread {
                self.textView.attributedText = text

                if !searchText.isEmpty {
                    if let range = self.textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
                        self.textView.scrollRangeToVisible(range)
                        self.lastRange = range
                    } else {
                        Globals.shared.alert(title: "Not Found", message: "")
                    }
                }
            }

            // Process spawns another thread and that becomes uncontrollable!
//            process(viewController: Globals.shared.splitViewController, work: {
//                return stringMarkedBySearchAsAttributedString(attributedString: attributedText,string: self.changedText, searchText: searchText, wholeWordsOnly: false, test: test)
//                }, completion: { (data:Any?) in
//                    guard let test = test?(), !test else {
//                        return
//                    }
//
//                    guard let text = data as? NSAttributedString else {
//                        return
//                    }
//
//                    Thread.onMainThread {
//                        self.textView.attributedText = text
//
//                        if !searchText.isEmpty {
//                            if let range = self.textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
//                                self.textView.scrollRangeToVisible(range)
//                                self.lastRange = range
//                            } else {
//                                Globals.shared.alert(title: "Not Found", message: "")
//                            }
//                        }
//                    }
//            })
        }
        
        operationQueue.addOperation(searchOp)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchText = searchBar.text
        
        operationQueue.cancelAllOperations()
//        operationQueue.waitUntilAllOperationsAreFinished()

        let attributedText = self.textView.attributedText
        
        let searchOp = CancellableOperation { (test:(()->(Bool))?) in
            let text = stringMarkedBySearchAsAttributedString(attributedString: attributedText,string: self.changedText, searchText: self.searchText, wholeWordsOnly: false, test: test)
            
            Thread.onMainThread {
                self.textView.attributedText = text
                
                if let lastRange = self.lastRange {
                    let startingRange = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: self.textView.attributedText.string.endIndex))
                    
                    if let searchText = self.self.searchText,let range = self.textView.attributedText.string.lowercased().range(of: searchText.lowercased(), options: [], range: startingRange, locale: nil) {
                        self.textView.scrollRangeToVisible(range)
                        self.lastRange = range
                    } else {
                        self.lastRange = nil
                    }
                }
                
                if self.lastRange == nil {
                    if let searchText = self.searchText,let range = self.textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
                        self.textView.scrollRangeToVisible(range)
                        self.lastRange = range
                    } else {
                        Globals.shared.alert(title: "Not Found", message: "")
                    }
                }
            }
        }
        
        operationQueue.addOperation(searchOp)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false
        
        if let changedText = changedText {
            operationQueue.cancelAllOperations()
//            operationQueue.waitUntilAllOperationsAreFinished()
            
            let text = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
            
            operationQueue.addOperation {
                Thread.onMainThread {
                    self.textView.attributedText = text
                }
            }
        }
        
        searchBar.showsCancelButton = false
        
        searchBar.resignFirstResponder()
        searchBar.text = nil
    }
}

extension TextViewController : UIScrollViewDelegate
{
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {

    }
}

extension TextViewController : UITextViewDelegate
{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should begin in the specified text view.
        guard !isTracking else {
            return false
        }
        
        if searchActive {
            searchActive = false
        }
        
        if let changedText = changedText, self.textView.attributedText != NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal) {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has begun.
        
        editingActive = true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should stop in the specified text view.
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has ended.
        
//        if let searchText = searchText, searchActive {
//            textView.attributedText = stringMarkedBySearchAsAttributedString(string: changedText, searchText: searchText, wholeWordsOnly: false)
//        }

        editingActive = false
    }
    
    func textView(_ shouldChangeTextIn: NSRange, replacementText: String)
    {
        // Asks the delegate whether the specified text should be replaced in the text view.

    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // Tells the delegate that the text or attributes in the specified text view were changed by the user.
    
        // Hopefully this isn't expensive
        changedText = textView.attributedText.string //textView.text
    }
    
    func textViewDidChangeSelection(_ textView: UITextView)
    {
        // Tells the delegate that the text selection changed in the specified text view.
        
    }
}

func stringMarkedBySearchAsAttributedString(attributedString:NSAttributedString!,string:String?,searchText:String?,wholeWordsOnly:Bool,test : (()->(Bool))?) -> NSAttributedString?
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
    
    var stringBefore    = String()
    var stringAfter     = String()
    
    var foundString     = String()
    
    let newAttrString       = NSMutableAttributedString()
    var foundAttrString     = NSAttributedString()
    
    while (workingString.lowercased().range(of: searchText.lowercased()) != nil) {
        if let test = test, test() {
            break
        }
        
        //                print(string)
        
        if let range = workingString.lowercased().range(of: searchText.lowercased()) {
            stringBefore = String(workingString[..<range.lowerBound])
            stringAfter = String(workingString[range.upperBound...])
            
            var skip = false
            
            if wholeWordsOnly {
                if let characterAfter:Character = stringAfter.first {
                    if let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) { // !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar)
                        skip = true
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

class CancellableOperation : Operation
{
    var block : (((()->(Bool))?)->())?

    override var description: String
        {
        get {
            return ""
        }
    }
    
    init(block:(((()->(Bool))?)->())?)
    {
        super.init()
        
        self.block = block
    }
    
    deinit {
        
    }
    
    override func main()
    {
        block?({return self.isCancelled})
    }
}

extension TextViewController : PopoverPickerControllerDelegate
{
    func stringPicked(_ string: String?)
    {
        dismiss(animated: true, completion: nil)
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stringPicked", completion: nil)
            return
        }
        
        guard let string = string else {
            return
        }
        
        let gapThreashold = Double(string)
        
        let text = self.textView.attributedText.string
        
        if let words = self.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
            if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                return first > second
            }
            
            return first["gap"] != nil
        }) {
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Yes", style: .default, handler: { () -> (Void) in
                process(viewController: self, work: { [weak self] () -> (Any?) in
                    self?.addParagraphBreaks(interactive:false, showGaps:true, gapThreshold:gapThreashold, words:words, text:text, completion: { (string:String) -> (Void) in
                        self?.updateBarButtons()
                        self?.changedText = string
                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                    })
                    
                    self?.operationQueue.waitUntilAllOperationsAreFinished()
                    
                    return nil
                }) { [weak self] (data:Any?) in
                    self?.updateBarButtons()
                }
            }))
            
            actions.append(AlertAction(title: "No", style: .default, handler:{
                process(viewController: self, work: { [weak self] () -> (Any?) in
                    self?.addParagraphBreaks(interactive:false, showGaps:false, gapThreshold:gapThreashold, words:words, text:text, completion: { (string:String) -> (Void) in
                        self?.updateBarButtons()
                        self?.changedText = string
                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                    })
                    
                    self?.operationQueue.waitUntilAllOperationsAreFinished()
                    
                    return nil
                }) { [weak self] (data:Any?) in
                    self?.updateBarButtons()
                }
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
            
            Globals.shared.alert(title:"Show Gap Times?", message:nil, actions:actions)
        }
    }
}

extension TextViewController : UIActivityItemSource
{
    @objc func share()
    {
        guard let text = textView.text else {
            return
        }
        
        //        if #available(iOS 10.0, *) {
        //            UIPasteboard.general.addItems([[kUTTypeHTML as String: html]])
        //        } else {
        //            // Fallback on earlier versions
        //        }
        
        let print = UIMarkupTextPrintFormatter(markupText: text)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        
        let activityViewController = UIActivityViewController(activityItems:[print,text,self] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        //        if let cell = cell {
        //            activityViewController.popoverPresentationController?.sourceRect = cell.bounds
        //            activityViewController.popoverPresentationController?.sourceView = cell
        //        } else {
        //            activityViewController.popoverPresentationController?.barButtonItem = viewController.navigationItem.rightBarButtonItem
        //        }
        
        // present the view controller
        Thread.onMainThread {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivityType] = [.mail,.print,.openInIBooks]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any?
    {
        guard let activityType = activityType else {
            return nil
        }
        
        guard let text = textView.text else {
            return nil
        }
        
        if #available(iOS 11.0, *) {
            WebViewController.cases.append(.markupAsPDF)
        }
        
        //        if #available(iOS 10.0, *) {
        //            UIPasteboard.general.addItems([[kUTTypeHTML as String: html]])
        //        } else {
        //            // Fallback on earlier versions
        //        }
        
        if WebViewController.cases.contains(activityType) {
            return text
        } else {
            //            html.operationQueue.waitUntilAllOperationsAreFinished()
            return text

//            if let text = self.html.text {
//                //                if #available(iOS 10.0, *) {
//                //                    UIPasteboard.general.addItems([[kUTTypeText as String: text]])
//                //                } else {
//                //                    // Fallback on earlier versions
//                //                }
//                return text
//            } else {
//                return "HTML to text conversion still in process.  Please try again later."
//            }
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        return self.navigationItem.title ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String
    {
        guard let activityType = activityType else {
            return "public.plain-text"
        }
        
        if WebViewController.cases.contains(activityType) {
            return "public.text"
        } else {
            return "public.plain-text"
        }
    }
}

class TextViewController : UIViewController
{
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    var lastRange : Range<String.Index>?
    
    var text : String?
    {
        didSet {
            changedText = text
        }
    }
    
    var changedText : String?
    {
        didSet {
            if isViewLoaded {
                updateBarButtons()
            }
        }
    }
    
    func updateBarButtons()
    {
        Thread.onMainThread {
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .playing:
                    self.playPauseButton?.title = "Pause"
                    
                default:
                    self.playPauseButton?.title = "Play"
                    break
                }
            }
            
            if let changedText = self.changedText, let text = self.text, changedText != text {
                print(prettyFirstDifferenceBetweenStrings(changedText as NSString, text as NSString))

                if !self.readOnly {
                    self.saveButton?.isEnabled = true
                    self.cancelButton?.title = "Cancel"
                } else {
                    self.saveButton?.isEnabled = false
                    self.cancelButton?.title = "Done"
                }
            } else {
                self.saveButton?.isEnabled = false
                self.cancelButton?.title = "Done"
            }
            
            if self.isTracking {
                self.syncButton?.title = "Stop Sync"
            } else {
                self.syncButton?.title = "Sync"
            }
        }
    }
    
    var readOnly = false
    
    var searchText : String?

    var search = false
    
    var fullScreenButton : UIBarButtonItem!
    var syncButton : UIBarButtonItem!
    var playPauseButton : UIBarButtonItem!
    
    func disableToolBarButtons()
    {
        Thread.onMainThread {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = false
                }
            }
        }
    }
    
    func disableBarButtons()
    {
        Thread.onMainThread {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
        }
        
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        Thread.onMainThread {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMainThread {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
            
            self.updateBarButtons()
        }
        
        enableToolBarButtons()
    }

    var searchActive = false
    {
        didSet {
            guard searchActive != oldValue else {
                return
            }

            assistButton.isEnabled = !searchActive
            syncButton.isEnabled = !searchActive

            if searchActive {
                oldRange = nil
                
//                removeTracking()
//                removeAssist()
//                disableBarButtons()
            } else {
//                enableBarButtons()
            }

            if !searchActive {
//                if !editingActive {
//                    restoreTracking()
//                    restoreAssist()
//                }
                searchBar.text = nil
                searchBar.showsCancelButton = false
                //        searchBar.resignFirstResponder()
            }

//            updateBarButtons()
        }
    }
    
    var wholeWordsOnly = false
    var searchInteractive = true

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    var editingActive = false
    {
        didSet {
            guard editingActive != oldValue else {
                return
            }
            
            assistButton.isEnabled = !editingActive
            syncButton.isEnabled = !editingActive

            if editingActive {
                oldRange = nil
                
                navigationItem.rightBarButtonItems?.append(dismissButton)
                
//                removeTracking()
//                removeAssist()
            } else {
                navigationItem.rightBarButtonItems?.removeLast()
            }
//
//            if !searchActive && !editingActive {
//                restoreTracking()
//                restoreAssist()
//            }
        }
    }

    @IBOutlet weak var textViewToTop: NSLayoutConstraint!
    
    var automatic = false
    var automaticInteractive = false
    var automaticCompletion : (()->(Void))?
    
    var completion : ((String)->(Void))?
    
    var confirmation : (()->Bool)?
    var confirmationTitle : String?
    var confirmationMessage : String?

    var onCancel : (()->(Void))?
    
    @objc func singleTapAction(_ tap:UITapGestureRecognizer)
    {
        guard isTracking else {
            return
        }
        
        let pos = tap.location(in: textView)
//        pos.y += textView.contentOffset.y
        
        let tapPos = textView.closestPosition(to: pos)
        
        if isTracking, let wordRangeTiming = wordRangeTiming, let tapPos = tapPos {
            let range = Range(uncheckedBounds: (lower: textView.offset(from: textView.beginningOfDocument, to: tapPos), upper: textView.offset(from: textView.beginningOfDocument, to: tapPos)))
            
            var closest : [String:Any]?
            var minDistance : Int?
            
            //                    let nsRange = NSRange(location: textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start), length: 0)
            //                    let textRange = Range(nsRange, in: textView.text)
            
            //                    print(textView.text?[textRange!.lowerBound...])
            
            for wordRangeTime in wordRangeTiming {
                if  let lowerBound = wordRangeTime["lowerBound"] as? Int,
                    let upperBound = wordRangeTime["upperBound"] as? Int {
                    if (range.lowerBound >= lowerBound) && (range.upperBound <= upperBound) {
                        closest = wordRangeTime
                        break
                    }
                    
                    var distance = 0
                    
                    if range.lowerBound < lowerBound {
                        distance = lowerBound - range.lowerBound
                    }
                    
                    if range.upperBound > upperBound {
                        distance = range.upperBound - upperBound
                    }
                    
                    if (minDistance == nil) || (distance < minDistance) {
                        minDistance = distance
                        closest = wordRangeTime
                    }
                }
            }
            
            if let segment = closest {
                if (oldTextRange == nil) || (oldTextRange != range) {
                    if  let start = segment["start"] as? Double,
                        let end = segment["end"] as? Double,
                        let lowerBound = segment["lowerBound"] as? Int,
                        let upperBound = segment["upperBound"] as? Int {
                        let ratio = Double(range.lowerBound - lowerBound)/Double(upperBound - lowerBound)
                        Globals.shared.mediaPlayer.seek(to: start + (ratio * (end - start)))
                    }
                }
                
                if oldTextRange != range {
                    oldTextRange = range
                }
            }
        }
    }
    
    var singleTap : UITapGestureRecognizer!
    
    @IBOutlet weak var textView: UITextView!
    {
        didSet {
            textView.autocorrectionType = .no
            
            singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(_:)))
            singleTap.numberOfTapsRequired = 1
            textView.addGestureRecognizer(singleTap)
            singleTap.isEnabled = false
        }
    }
    
    var transcript:VoiceBase?
    
    var wordRangeTiming : [[String:Any]]?
    {
        didSet {
            if wordRangeTiming != nil {
                checkSync()
            }
            Thread.onMainThread {
                self.syncButton?.isEnabled = self.wordRangeTiming != nil
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    var oldRange : Range<String.Index>?

    func removeAssist()
    {
        guard assist else {
            return
        }
        
//        guard saveButton != nil else {
//            return
//        }
        
        assistButton?.isEnabled = false
        
//        navigationItem.rightBarButtonItems = fullScreenButton != nil ? [fullScreenButton,saveButton] : [saveButton]
    }
    
    func restoreAssist()
    {
        guard assist else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        assistButton?.isEnabled = true
        
//        if navigationItem.rightBarButtonItems != nil {
////            if fullScreenButton != nil {
////                navigationItem.rightBarButtonItems?.append(fullScreenButton)
////            }
//            navigationItem.rightBarButtonItems?.append(assistButton)
//        } else {
//            navigationItem.rightBarButtonItems = fullScreenButton != nil ? [fullScreenButton,saveButton,assistButton] : [saveButton,assistButton]
////            navigationItem.rightBarButtonItem = assistButton
//        }
    }
    
    func removeTracking()
    {
        guard track else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        wasTracking = isTracking
        
        wasPlaying = Globals.shared.mediaPlayer.isPlaying
        
        isTracking = false
        stopTracking()
        
//        navigationItem.leftBarButtonItems = [cancelButton]
    }
    
    func restoreTracking()
    {
        guard track else {
            return
        }
        
        isTracking = wasTracking ?? true
        wasTracking = nil
        
        if isTracking {
            startTracking()
        }

        syncButton.isEnabled = true
        
//        if navigationItem.leftBarButtonItems != nil {
//            navigationItem.leftBarButtonItems?.append(syncButton)
//        } else {
//            navigationItem.leftBarButtonItem = syncButton
//        }
//
//        activityIndicator = UIActivityIndicatorView()
//        activityIndicator.activityIndicatorViewStyle = .gray
//        activityIndicator.hidesWhenStopped = true
//
//        activityBarButton = UIBarButtonItem(customView: activityIndicator)
//        activityBarButton.isEnabled = true
//
//        navigationItem.leftBarButtonItems?.append(activityBarButton)
        
        if wordRangeTiming == nil {
            activityIndicator.startAnimating()
        }
    }
    
    func stopTracking()
    {
        guard track else {
            return
        }
        
//        Globals.shared.mediaPlayer.pause()
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        if let changedText = changedText {
            textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
    }
    
    func startTracking()
    {
        guard track else {
            return
        }
        
//        Globals.shared.mediaPlayer.play()
        
        if trackingTimer == nil {
            trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(follow), userInfo: nil, repeats: true)
        } else {
            print("ERROR: trackingTimer not NIL!")
        }
    }
    
    var oldTextRange : Range<Int>? // UITextRange?
    
    @objc func follow()
    {
        guard !searchActive else {
            return
        }
        
        guard !editingActive else {
//            if let selectedTextRange = textView.selectedTextRange {
//                let range = Range(uncheckedBounds: (lower: textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start), upper: textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.end)))
//
//                if let segment = wordRangeTiming?.filter({ (dict:[String:Any]) -> Bool in
//                    if  let lowerBound = dict["lowerBound"] as? Int,
//                        let upperBound = dict["upperBound"] as? Int {
//                        return (range.lowerBound >= lowerBound) && (range.upperBound <= upperBound)
//                    } else {
//                        return false
//                    }
//                }).first {
//                    if (oldTextRange == nil) || (oldTextRange != selectedTextRange) {
//                        if  let start = segment["start"] as? Double,
//                            let end = segment["end"] as? Double,
//                            let lowerBound = segment["lowerBound"] as? Int,
//                            let upperBound = segment["upperBound"] as? Int {
//                            let ratio = Double(range.lowerBound - lowerBound)/Double(upperBound - lowerBound)
//                            Globals.shared.mediaPlayer.seek(to: start + (ratio * (end - start)))
//                        }
//                    }
//                }
//
//                if oldTextRange != selectedTextRange {
//                    oldTextRange = selectedTextRange
//                }
//            }
            return
        }
        
        guard let wordRangeTiming = wordRangeTiming else {
            return
        }
        
        if let seconds = Globals.shared.mediaPlayer.currentTime?.seconds {
            var index = 0
            
            for element in wordRangeTiming {
                if let startTime = element["start"] as? Double {
                    if seconds < startTime {
                        break
                    }
                }
                
                index += 1
            }
            index -= 1
            
            index = max(index,0)
            
            if  // let text = (wordRangeTiming[index]["text"] as? String),
                let range = wordRangeTiming[index]["range"] as? Range<String.Index>
//                let lowerBound = wordRangeTiming[index]["lowerBound"] as? String.Index,
//                let upperBound = wordRangeTiming[index]["upperBound"] as? String.Index
            {
//                var range = changedText?.range(of: text)
//
//                if range == nil {
//                    range = changedText?.range(of: text.replacingOccurrences(of: ".  ", with: ". "))
//                }
                
//                let range = Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
                
                if let changedText = changedText, range != oldRange { // , let range = range
                    let before = String(changedText[..<range.lowerBound])
                    let text = String(changedText[range])
                    let after = String(changedText[range.upperBound...])
                    let beforeAttr = NSMutableAttributedString(string: before, attributes: Constants.Fonts.Attributes.normal)
                    let textAttr = NSMutableAttributedString(string: text, attributes: Constants.Fonts.Attributes.marked)
                    let afterAttr = NSMutableAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal)
                    
                    beforeAttr.append(textAttr)
                    beforeAttr.append(afterAttr)
                    
                    textView.attributedText = beforeAttr
                    
                    textView.scrollRangeToVisible(range)
                    
                    oldRange = range
                } else {
                    // Too annoying when not playing.
//                    if let range = range {
//                        textView.scrollToRange(range)
//                    }
                }
            } else {
                if let text = wordRangeTiming[index]["text"] {
                    print("RANGE NOT FOUND: ",text)
                } else {
                    print("RANGE NOT FOUND")
                }
            }
        }
    }
    
    var wasTracking : Bool?
    var wasPlaying : Bool?
    
    @objc func tracking()
    {
        isTracking = !isTracking
    }
    
    var track = false
    {
        didSet {
//            if track {
//                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                    self?.wordRangeTiming = self?.transcript?.wordRangeTiming
//                }
//            }
        }
    }
    
    var isTracking = false
    {
        didSet {
            singleTap?.isEnabled = isTracking
            
            if isTracking != oldValue {
                if !isTracking {
                    oldRange = nil
                    syncButton.title = "Sync"
                    stopTracking()
                    restoreAssist()
                }
                
                if isTracking {
                    syncButton.title = "Stop Sync"
                    startTracking()
                    removeAssist()
                }
            }
        }
    }
    
    var trackingTimer : Timer?

    var assist = false

    @objc func done()
    {
        if text != textView.attributedText.string, let confirmationTitle = confirmationTitle,let needConfirmation = confirmation?(), needConfirmation {
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Yes", style: .destructive, handler: { () -> (Void) in
                if self.isTracking {
                    self.stopTracking()
                }
                self.dismiss(animated: true, completion: nil)
                self.completion?(self.textView.attributedText.string)
            }))
            
            actions.append(AlertAction(title: "No", style: .default, handler:nil))
            
            alert(viewController:self,title:confirmationTitle, message:self.confirmationMessage, actions:actions)
        } else {
            if isTracking {
                stopTracking()
            }
            dismiss(animated: true, completion: nil)
            completion?(textView.attributedText.string)
        }
    }
    
    @objc func cancel()
    {
        if isTracking {
            stopTracking()
        }
        dismiss(animated: true, completion: {
            self.onCancel?()
        })
    }
    
//    var operationQueue : OperationQueue!
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "TEXT EDIT"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    @objc func autoEdit()
    {
        guard !searchActive else {
            return
        }
        
        guard !editingActive else {
            return
        }
        
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, handler: { [weak self] in
            guard let vc = self else {
                return
            }

            if  let transcriptString = self?.textView.attributedText.string.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                let transcriptFromWordsString = self?.transcript?.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), transcriptString == transcriptFromWordsString {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Paragraph Breaks", style: .default, handler: { [weak self] in
                    //                    print(wordRangeTiming)
                    
                    let block = {
                        if let words = self?.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
                            if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                                return first > second
                            }
                            
                            return first["gap"] != nil
                        }) {
                            //                        var i = 0
                            //
                            //                        for word in words {
                            //                            print(i)
                            //                            print("gap: ",word["gap"])
                            //                            print("start: ",word["start"])
                            //                            print("end: ",word["end"])
                            //                            print("text: ",word["text"])
                            //                            print("lowerBound: ",word["lowerBound"])
                            //                            i += 1
                            //                        }
                            
                            let text = self?.textView.attributedText.string
                            
                            var actions = [AlertAction]()
                            
                            actions.append(AlertAction(title: "Yes", style: .default, handler: { () -> (Void) in
                                process(viewController: vc, work: { [weak self] () -> (Any?) in
                                    self?.addParagraphBreaks(interactive:true, showGaps:true, words:words, text:text, completion: { (string:String) -> (Void) in
                                        self?.updateBarButtons()
                                        self?.changedText = string
                                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                                    })
                                    
                                    //                            self?.operationQueue.waitUntilAllOperationsAreFinished()
                                    
                                    return nil
                                }) { [weak self] (data:Any?) in
                                    self?.updateBarButtons()
                                }
                            }))
                            
                            actions.append(AlertAction(title: "No", style: .default, handler:{
                                process(viewController: vc, work: { [weak self] () -> (Any?) in
                                    self?.addParagraphBreaks(interactive:true, showGaps:false, words:words, text:text, completion: { (string:String) -> (Void) in
                                        self?.updateBarButtons()
                                        self?.changedText = string
                                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                                    })
                                    
                                    //                            self?.operationQueue.waitUntilAllOperationsAreFinished()
                                    
                                    return nil
                                }) { [weak self] (data:Any?) in
                                    self?.updateBarButtons()
                                }
                            }))
                            
                            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))

                            Globals.shared.alert(title:"Show Gap Times?", message:nil, actions:actions)
                        }
                    }
                    
                    if self?.wordRangeTiming != nil {
                        block()
                    } else {
                        self?.creatingWordRangeTiming = true
                        process(viewController: self!, work: { [weak self] () -> (Any?) in
                            self?.wordRangeTiming = self?.transcript?.wordRangeTiming
                            self?.creatingWordRangeTiming = false
                            return nil
                        }, completion: { (data:Any?) in
                            self?.updateBarButtons()
                            block()
                        })
                    }
                }))
                
                actions.append(AlertAction(title: "Text Edits", style: .default, handler: { [weak self] in
                    let text = self?.textView.attributedText.string
                    
                    process(viewController: vc, work: { [weak self] () -> (Any?) in
                        self?.changeText(interactive: true, text: text, startingRange: nil, masterChanges: self?.masterChanges(interactive: true), completion: { (string:String) -> (Void) in
                            self?.updateBarButtons()
                            self?.changedText = string
                            self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                        })
                        
                        //                    self?.operationQueue.waitUntilAllOperationsAreFinished()
                        
                        return nil
                    }) { [weak self] (data:Any?) in
                        self?.updateBarButtons()
                    }
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                
                alert(viewController:vc,title:"Suggest",message:"Because it relies upon the original text and timing information from the transcription, Paragraph Breaks should be done first before any other editing is done.",actions:actions)
            } else {
                let text = self?.textView.attributedText.string
                
                process(viewController: vc, work: { [weak self] () -> (Any?) in
                    self?.changeText(interactive: true, text: text, startingRange: nil, masterChanges: self?.masterChanges(interactive: true), completion: { (string:String) -> (Void) in
                        self?.updateBarButtons()
                        self?.changedText = string
                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                    })
                    
                    //                    self?.operationQueue.waitUntilAllOperationsAreFinished()
                    
                    return nil
                }) { [weak self] (data:Any?) in
                    self?.updateBarButtons()
                }
            }
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, handler: { [weak self] in
            guard let vc = self else {
                return
            }
            
            if  let transcriptString = self?.textView.attributedText.string.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                let transcriptFromWordsString = self?.transcript?.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), transcriptString == transcriptFromWordsString {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Paragraph Breaks", style: .default, handler: { [weak self] in
                    let block = {
                        if let words = self?.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
                            if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                                return first > second
                            }
                            
                            return first["gap"] != nil
                        }) {
                            if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                                guard let vc = self else {
                                    return
                                }
                                
                                navigationController.modalPresentationStyle = .overCurrentContext
                                
                                navigationController.popoverPresentationController?.delegate = vc as? UIPopoverPresentationControllerDelegate
                                
                                popover.navigationController?.isNavigationBarHidden = false
                                
                                popover.navigationItem.title = "Select Gap Threshold" // Constants.Strings.Word_Picker
                                
                                popover.delegate = vc
                                
                                popover.stringTree = StringTree()
                                
                                popover.action = { (gapThresholdString:String?) in
                                    guard let gapThresholdString = gapThresholdString, let gapThreshold = Double(gapThresholdString) else {
                                        return
                                    }

                                    if var words = self?.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
                                        if let first = first["gap"] as? Double, let second = second["gap"] as? Double {
                                            return first > second
                                        }
                                        
                                        return first["gap"] != nil
                                    }), words.count > 0, var newText = self?.text {
                                        repeat {
                                            let first = words.removeFirst()

                                            guard let range = first["range"] as? Range<String.Index> else {
                                                continue
                                            }
                                            
                                            guard let gap = first["gap"] as? Double else {
                                                continue
                                            }
                                            
                                            if gap > gapThreshold {
                                                let gapString = " <\(gap)><br/><br/>"
                                                
                                                newText.insert(contentsOf:gapString, at: range.lowerBound)
                                                
                                                for i in 0..<words.count {
                                                    if let wordRange = words[i]["range"] as? Range<String.Index> {
                                                        if wordRange.lowerBound > range.lowerBound {
                                                            var lower : String.Index?
                                                            var upper : String.Index?
                                                            
                                                            if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                                                lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                                                            }
                                                            
                                                            if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                                                upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                                                            }
                                                            
                                                            if let lower = lower, let upper = upper {
                                                                let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                                                                words[i]["range"] = newRange
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        } while words.count > 0

                                        if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                                            let webView = navigationController.viewControllers[0] as? WebViewController {
                                            navigationController.modalPresentationStyle = .overCurrentContext
                                            
//                                            webView.html.fontSize = 12
                                            
                                            webView.search = false
                                            webView.content = .html
                                            
                                            newText = "<html><body>" + newText + "</body></html>"
                                            
                                            webView.html.string = insertHead(newText,fontSize: 24)
                                            
                                            Thread.onMainThread {
                                                //                                            popover.activityIndicator.stopAnimating()
                                                //                                            popover.activityIndicator.isHidden = true
                                                
                                                webView.navigationItem.title = self?.navigationItem.title
                                                
                                                popover.present(navigationController, animated: true)
                                            }
                                        }
                                    }
                                }

                                popover.stringsFunction = {
                                    let gaps = words.map({ (dict) -> String in
                                        return (dict["gap"] as? Double)?.description ?? ""
                                    })
                                    
                                    return gaps
                                }
                                
                                self?.present(navigationController, animated: true, completion: nil)
                            }
                        }
                    }
                    
                    if self?.wordRangeTiming != nil {
                        block()
                    } else {
                        self?.creatingWordRangeTiming = true
                        process(viewController: self!, work: { [weak self] () -> (Any?) in
                            self?.wordRangeTiming = self?.transcript?.wordRangeTiming
                            self?.creatingWordRangeTiming = false
                            
                            self?.operationQueue.waitUntilAllOperationsAreFinished()
                            
                            return nil
                        }, completion: { (data:Any?) in
                            self?.updateBarButtons()
                            block()
                        })
                    }
                }))
                
                actions.append(AlertAction(title: "Text Edits", style: .default, handler: { [weak self] in
                    let text = self?.textView.attributedText.string
                    
                    process(viewController: vc, work: { [weak self] () -> (Any?) in
                        self?.changeText(interactive: false, text: text, startingRange: nil, masterChanges: self?.masterChanges(interactive: false), completion: { (string:String) -> (Void) in
                            self?.updateBarButtons()
                            self?.changedText = string
                            self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                        })
                        
                        self?.operationQueue.waitUntilAllOperationsAreFinished()
                        
                        return nil
                    }) { [weak self] (data:Any?) in
                        self?.updateBarButtons()
                    }
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
                
                Globals.shared.alert(title:"Perform",message:"Because it relies upon the original text and timing information from the transcription, Paragraph Breaks should be done first before any other editing is done.",actions:actions)
            } else {
                let text = self?.textView.attributedText.string
                
                process(viewController: vc, work: { [weak self] () -> (Any?) in
                    self?.changeText(interactive: false, text: text, startingRange: nil, masterChanges: self?.masterChanges(interactive: false), completion: { (string:String) -> (Void) in
                        self?.updateBarButtons()
                        self?.changedText = string
                        self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                    })
                    
                    self?.operationQueue.waitUntilAllOperationsAreFinished()
                    
                    return nil
                }) { [weak self] (data:Any?) in
                    self?.updateBarButtons()
                }
            }
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
        
        alert(viewController:self,title:"Start Assisted Editing?",message:nil,actions:actions)
    }

    var cancelButton : UIBarButtonItem!
    var saveButton : UIBarButtonItem!
    var assistButton : UIBarButtonItem!
    var dismissButton : UIBarButtonItem!

    var keyboardShowing = false
    var shrink:CGFloat = 0.0

    @objc func keyboardWillShow(_ notification: NSNotification)
    {
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let kbdRect = CGRect(x: keyboardRect.minX, y: keyboardRect.minY - keyboardRect.height, width: keyboardRect.width, height: keyboardRect.height)
            let txtRect = textView.convert(textView.bounds, to: Globals.shared.splitViewController.view)
            let intersectRect = txtRect.intersection(kbdRect)
            
            if !keyboardShowing {
                // The toolbar and navBar are the same height.  Which should be deducted?  Why?  Why does this work?  Why is textView.bounds.minY not 0?
                
                if navigationController?.modalPresentationStyle == .formSheet {
                    shrink = intersectRect.height - (navigationController?.toolbar.frame.size.height ?? 0)// - txtRect.minY
                } else {
                    shrink = intersectRect.height + 16 // - (navigationController?.toolbar.frame.size.height ?? 0)// - txtRect.minY
                }
                
                bottomLayoutConstraint.constant += shrink // textView.frame.size.height -
            } else {
                if (intersectRect.height != shrink) {
                    let delta = shrink - intersectRect.height
                    shrink -= delta
                    if delta != 0 {
                        bottomLayoutConstraint.constant -= delta // textView.frame.size.height +
                    }
                }
            }
        }

        view.layoutSubviews()
        
        keyboardShowing = true
    }

    @objc func keyboardWillHide(_ notification: NSNotification)
    {
        if keyboardShowing {
            bottomLayoutConstraint.constant -= shrink // textView.frame.size.height +
        }

        shrink = 0
        keyboardShowing = false
    }
    
    var activityIndicator : UIActivityIndicatorView!
    var activityBarButton : UIBarButtonItem!

    @objc func showFullScreen()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? TextViewController {
            dismiss(animated: false, completion: nil)
            
            navigationController.modalPresentationStyle = .overFullScreen
//            navigationController.popoverPresentationController?.delegate = popover
            
            popover.navigationItem.title = self.navigationItem.title

            popover.text = self.text
            popover.changedText = self.changedText

            popover.assist = self.assist
            
            popover.track = self.track
            
            // The full scren view will create its own trackingTime
//            popover.trackingTimer = self.trackingTimer

            popover.search = self.search
            popover.searchText = self.searchText
            popover.searchActive = self.searchActive
            popover.searchInteractive = self.searchInteractive
            
            popover.transcript = self.transcript

            popover.completion = self.completion
            
            popover.automatic = self.automatic
            popover.automaticCompletion = self.automaticCompletion
            popover.automaticInteractive = self.automaticInteractive

            popover.confirmation = self.confirmation
            popover.confirmationTitle = self.confirmationTitle
            popover.confirmationMessage = self.confirmationMessage

            // Can't copy this or the sync button may never become active because the following data structure is never setup in the full screen view
//            popover.creatingWordRangeTiming = self.creatingWordRangeTiming
            
            popover.editingActive = self.editingActive
            
            popover.wordRangeTiming = self.wordRangeTiming
            
            popover.isTracking = self.isTracking
            
            popover.keyboardShowing = self.keyboardShowing
            popover.shrink = self.shrink

            popover.lastRange = self.lastRange
            
//            popover.mask = self.mask
            
            popover.onCancel = self.onCancel
            
            popover.operationQueue = self.operationQueue
            
            popover.oldRange = self.oldRange
            
            popover.wasPlaying = self.wasPlaying
            popover.wasTracking = self.wasTracking
            
            popover.wholeWordsOnly = self.wholeWordsOnly

            popover.navigationController?.isNavigationBarHidden = false
            
            Globals.shared.splitViewController.present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func playPause()
    {
        guard let title = playPauseButton.title else {
            return
        }
        
        switch title {
        case "Play":
            Globals.shared.mediaPlayer.play()
            playPauseButton.title = "Pause"
            
        case "Pause":
            Globals.shared.mediaPlayer.pause()
            playPauseButton.title = "Play"
            
        default:
            break
        }
    }
    
    @objc func dismissKeyboard()
    {
        textView.resignFirstResponder()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
//        operationQueue = OperationQueue()
        
        playPauseButton = UIBarButtonItem(title: "Play", style: UIBarButtonItemStyle.plain, target: self, action: #selector(playPause))

        syncButton = UIBarButtonItem(title: "Sync", style: UIBarButtonItemStyle.plain, target: self, action: #selector(tracking))
        syncButton.isEnabled = wordRangeTiming != nil
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        cancelButton = UIBarButtonItem(title: Constants.Strings.Cancel, style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancel))
        
        if (Globals.shared.mediaPlayer.mediaItem != transcript?.mediaItem) || (transcript?.mediaItem?.playing != transcript?.purpose) {
            track = false
        }
        
        if !search {
            searchBar.removeFromSuperview()
            textViewToTop.constant = 14
        } else {
            // iOS 11 changed the height of search bars by 12 points!
            if #available(iOS 11.0, *) {
                textViewToTop.constant += 12
            } else {
                // Fallback on earlier versions
            }
            
//            self.view.setNeedsLayout()
        }
        
        navigationItem.leftBarButtonItem = cancelButton

        var barButtonItems = [UIBarButtonItem]()
        
        if track {
//            if toolbarItems != nil { // navigationItem.leftBarButtonItems
//                toolbarItems?.append(spaceButton)
//                toolbarItems?.append(syncButton)
////                navigationItem.leftBarButtonItems?.append(syncButton)
//            } else {
//                toolbarItems = [spaceButton,syncButton] //
////                navigationItem.leftBarButtonItem = syncButton
//            }

            barButtonItems.append(spaceButton)
            barButtonItems.append(syncButton)

            activityIndicator = UIActivityIndicatorView()
            activityIndicator.activityIndicatorViewStyle = .gray
            activityIndicator.hidesWhenStopped = true
            
            activityBarButton = UIBarButtonItem(customView: activityIndicator)
            activityBarButton.isEnabled = true
            
            barButtonItems.append(activityBarButton)
//            toolbarItems?.append(activityBarButton)
            //            navigationItem.leftBarButtonItems?.append(activityBarButton)
            
            if wordRangeTiming == nil {
                activityIndicator.startAnimating()
            }

//            if toolbarItems != nil {
//                toolbarItems?.append(spaceButton)
//                toolbarItems?.append(playPauseButton)
//            } else {
//                toolbarItems = [spaceButton,playPauseButton]
//            }
            barButtonItems.append(spaceButton)
            barButtonItems.append(playPauseButton)
        }

        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .formSheet:
                fallthrough
            case .overCurrentContext:
                fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItemStyle.plain, target: self, action: #selector(showFullScreen))
                fullScreenButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
                
                if navigationItem.rightBarButtonItems != nil {
                    navigationItem.rightBarButtonItems?.append(fullScreenButton)
                } else {
                    navigationItem.rightBarButtonItem = fullScreenButton
                }
                
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                break
                
            default:
                break
            }
        }

        saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
        assistButton = UIBarButtonItem(title: "Assist", style: UIBarButtonItemStyle.plain, target: self, action: #selector(autoEdit))
        dismissButton = UIBarButtonItem(title: "Dismiss", style: UIBarButtonItemStyle.plain, target: self, action: #selector(dismissKeyboard))

        if assist {
//            if toolbarItems != nil {
//                toolbarItems?.append(spaceButton)
//                toolbarItems?.append(assistButton)
//            } else {
//                toolbarItems = [spaceButton,assistButton]
//            }
            barButtonItems.append(spaceButton)
            barButtonItems.append(assistButton)

//            if navigationItem.rightBarButtonItems != nil {
//                navigationItem.rightBarButtonItems?.append(assistButton)
//            } else {
//                navigationItem.rightBarButtonItem = assistButton
//            }
        }
        
        if !readOnly {
//            if toolbarItems != nil {
//                toolbarItems?.append(spaceButton)
//                toolbarItems?.append(saveButton)
//            } else {
//                toolbarItems = [spaceButton,saveButton]
//            }
//
//            toolbarItems?.append(spaceButton)

            barButtonItems.append(spaceButton)
            barButtonItems.append(saveButton)
            barButtonItems.append(spaceButton)
        } else {
            
        }

        toolbarItems = barButtonItems.count > 0 ? barButtonItems : nil
        
        if navigationItem.rightBarButtonItem == nil, navigationItem.rightBarButtonItems == nil {
            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(share)), animated: true)
        }
        
        //        if navigationItem.rightBarButtonItems != nil {
        //            navigationItem.rightBarButtonItems?.append(saveButton)
        //        } else {
        //            navigationItem.rightBarButtonItem = saveButton
        //        }
    }
    
//    var mask = false
    
    var creatingWordRangeTiming = false
    
    func checkSync()
    {
        guard let transcript = self.transcript else {
            return
        }
        
        guard let wordRangeTiming = self.wordRangeTiming else {
            return
        }
        
        if  let transcriptString = transcript.transcript?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            let transcriptFromWordsString = transcript.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            
            if transcriptString != transcriptFromWordsString {
                print(prettyFirstDifferenceBetweenStrings(transcriptString as NSString, transcriptFromWordsString as NSString))
            }
            
            if  (Globals.shared.mediaPlayer.mediaItem == transcript.mediaItem),
                (transcript.mediaItem?.playing == transcript.purpose) { // , (transcriptString.lowercased() != transcriptFromWordsString.lowercased())
                if wordRangeTiming.filter({ (dict:[String:Any]) -> Bool in
                    return dict["range"] == nil
                }).count > 0 {
                    if let text = transcript.mediaItem?.text {
                        Globals.shared.alert(title: "Transcript Sync Warning",message: "The transcript for\n\n\(text) (\(transcript.transcriptPurpose))\n\ndiffers from the individually recognized words.  As a result the sync will not be exact.  Please align the transcript for an exact sync.")
                    }
                }
            }
        }
    }
    
    @objc func stopped()
    {
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        isTracking = false

        updateBarButtons()
//        syncButton.title = "Sync"
//        syncButton.isEnabled = false
//
//        playPauseButton.title = "Play"
//        playPauseButton.isEnabled = false
//
//        assistButton.isEnabled = true
    }
    
    @objc func playing()
    {
        updateBarButtons()
    }
    
    @objc func paused()
    {
        updateBarButtons()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(stopped), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STOPPED), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        navigationController?.isToolbarHidden = toolbarItems == nil

        if let navigationController = navigationController, modalPresentationStyle != .popover {
            Globals.shared.topViewController.append(navigationController)
        }
        
        addNotifications()

//        if !Globals.shared.splitViewController.isCollapsed, navigationController?.modalPresentationStyle == .overCurrentContext {
//            var vc : UIViewController?
//            
//            if presentingViewController == Globals.shared.splitViewController.viewControllers[0] {
//                vc = Globals.shared.splitViewController.viewControllers[1]
//            }
//            
//            if presentingViewController == Globals.shared.splitViewController.viewControllers[1] {
//                vc = Globals.shared.splitViewController.viewControllers[0]
//            }
//            
//            mask = true
//            
//            if let vc = vc {
//                process(viewController:vc,disableEnable:false,hideSubviews:true,work:{ [weak self] (Void) -> Any? in
//                    // Why are we doing this?
//                    while self?.mask == true {
//                        Thread.sleep(forTimeInterval: 0.5)
//                    }
//                    return nil
//                },completion:{ [weak self] (data:Any?) -> Void in
//                    
//                })
//            }
//        }
        
        searchBar.text = searchText
        searchBar.isUserInteractionEnabled = searchInteractive

        if let changedText = changedText {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
        
        if track, wordRangeTiming == nil, !creatingWordRangeTiming {
            self.creatingWordRangeTiming = true

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.wordRangeTiming = self?.transcript?.wordRangeTiming
                self?.creatingWordRangeTiming = false
            }

//            process(viewController: self, work: { () -> (Any?) in
//                self.wordRangeTiming = self.transcript?.wordRangeTiming
//                return nil
//            }, completion: { (data:Any?) in
//                self.creatingWordRangeTiming = false
//            })
        }
        
        updateBarButtons()
    }
    
    func words() -> [String:String]?
    {
        return [
            "scripture":"Scripture",
             "Chapter":"chapter",
             "Verse":"verse",
             "Grace":"grace",
             "Gospel":"gospel",
             "vs":"verses",
             "versus":"verses",
             "pilot":"Pilate",
             "OK":"okay"
        ]
    }
    
    func books() -> [String:String]?
    {
        return [
            "first samuel"           :"1 Samuel",
            "second samuel"          :"2 Samuel",
            
            "first kings"            :"1 Kings",
            "second kings"           :"2 Kings",
            
            "first chronicles"       :"1 Chronicles",
            "second chronicles"      :"2 Chronicles",
            
            "first corinthians"      :"1 Corinthians",
            "second corinthians"     :"2 Corinthians",
            
            "first thessalonians"    :"1 Thessalonians",
            "second thessalonians"   :"2 Thessalonians",
            
            "first timothy"          :"1 Timothy",
            "second timothy"         :"2 Timothy",
            
            "first peter"             :"1 Peter",
            "second peter"            :"2 Peter",
            
            "first john"      :"1 John",
            "second john"     :"2 John",
            "third john"      :"3 John"
        ]
    }

    func textToNumbers() -> [String:String]?
    {
        var textToNumbers = [String:String]()
        
        let singleNumbers = [
           "one"        :"1",
           "two"        :"2",
           "three"      :"3",
           "four"       :"4",
           "five"       :"5",
           "six"        :"6",
           "seven"      :"7",
           "eight"      :"8",
           "nine"       :"9"
        ]
        
        let teenNumbers = [
           "ten"        :"10",
           "eleven"     :"11",
           "twelve"     :"12",
           "thirteen"   :"13",
           "fourteen"   :"14",
           "fifteen"    :"15",
           "sixteen"    :"16",
           "seventeen"  :"17",
           "eighteen"   :"18",
           "nineteen"   :"19"
        ]
            
        let decades = [
           "twenty"     :"20",
           "thirty"     :"30",
           "forty"      :"40",
           "fifty"      :"50",
           "sixty"      :"60",
           "seventy"    :"70",
           "eighty"     :"80",
           "ninety"     :"90"
        ]
        
        // If we make the translation table too big searching for replacements can take a long time,
        // possibly too long for the user.
        
        let centuries = [
            "one hundred"     :"100"//,
//            "two hundred"     :"200",
//            "three hundred"   :"300",
//            "four hundred"    :"400",
//            "five hundred"    :"500",
//            "six hundred"     :"600",
//            "seven hundred"   :"700",
//            "eight hundred"   :"800",
//            "nine hundred"    :"900",
        ]
        
//        let millenia = [
//            "one thousand"     :"1000",
//            "two thousand"     :"2000",
//            "three thousand"   :"3000",
//            "four thousand"    :"4000",
//            "five thousand"    :"5000",
//            "six thousand"     :"6000",
//            "seven thousand"   :"7000",
//            "eight thousand"   :"8000",
//            "nine thousand"    :"9000",
//        ]
        
        for key in singleNumbers.keys {
            textToNumbers[key] = singleNumbers[key]
        }
        
        for key in teenNumbers.keys {
            textToNumbers[key] = teenNumbers[key]
        }
        
        for key in decades.keys {
            textToNumbers[key] = decades[key]
        }
        
        for key in centuries.keys {
            textToNumbers[key] = centuries[key]
        }
        
//        for key in millenia.keys {
//            textToNumbers[key] = millenia[key]
//        }
        
        for hundred in ["one"] {
            for teenNumbersKey in teenNumbers.keys {
                if let num = teenNumbers[teenNumbersKey] {
                    let key = hundred + " " + teenNumbersKey
                    
                    let value = "1" + num
                    
                    textToNumbers[key] = value
                }
            }
            
            for decadesKey in decades.keys {
                if let num = decades[decadesKey] {
                    let key = hundred + " " + decadesKey
                    let value = "1" + num
                    
                    textToNumbers[key] = value
                    
                    if decadesKey != "ten" {
                        for singleNumbersKey in singleNumbers.keys {
                            let key = hundred + " " + decadesKey + " " + singleNumbersKey
                            
                            if let decade = decades[decadesKey]?.replacingOccurrences(of:"0",with:""), let singleNumber = singleNumbers[singleNumbersKey] {
                                let value = "1" + decade + singleNumber
                                textToNumbers[key] = value
                            }
                        }
                    }
                }
            }
        }
        
        for decade in decades.keys {
            for singleNumber in singleNumbers.keys {
                let key = (decade + " " + singleNumber)
                if  let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                    let singleNumber = singleNumbers[singleNumber] {
                    let value = decade + singleNumber
                    textToNumbers[key] = value
                }
            }
        }
        
        for century in centuries.keys {
            for singleNumber in singleNumbers.keys {
                let key = (century + " " + singleNumber)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
                    let singleNumber = singleNumbers[singleNumber] {
                    let value = century + singleNumber
                    textToNumbers[key] = value
                }
            }
            
            for teenNumber in teenNumbers.keys {
                let key = (century + " " + teenNumber)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let teenNumber = teenNumbers[teenNumber] {
                    let value = century + teenNumber
                    textToNumbers[key] = value
                }
            }
            
            for decade in decades.keys {
                let key = (century + " " + decade)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let decade = decades[decade] {
                    let value = century + decade
                    textToNumbers[key] = value
                }
            }
            
            for decade in decades.keys {
                for singleNumber in singleNumbers.keys {
                    let key = (century + " " + decade + " " + singleNumber)
                    if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                        let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                        let singleNumber = singleNumbers[singleNumber]
                    {
                        let value = (century + decade + singleNumber)
                        textToNumbers[key] = value
                    }
                }
            }
        }

//        for millenium in millenia.keys {
//            for century in centuries.keys {
//                for singleNumber in singleNumbers.keys {
//                    let key = (millenium + " " + century + " " + singleNumber)
//                    if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
//                        let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
//                        let singleNumber = singleNumbers[singleNumber] {
//                        let value = millenium + century + singleNumber
//                        textToNumbers[key] = value
//                    }
//                }
//
//                for teenNumber in teenNumbers.keys {
//                    let key = (millenium + " " + century + " " + teenNumber)
//                    if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
//                        let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
//                        let teenNumber = teenNumbers[teenNumber] {
//                        let value = millenium + century + teenNumber
//                        textToNumbers[key] = value
//                    }
//                }
//
//                for decade in decades.keys {
//                    let key = (millenium + " " + century + " " + decade)
//                    if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
//                        let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
//                        let decade = decades[decade] {
//                        let value = millenium + century + decade
//                        textToNumbers[key] = value
//                    }
//                }
//
//                for decade in decades.keys {
//                    for singleNumber in singleNumbers.keys {
//                        let key = (millenium + " " + century + " " + decade + " " + singleNumber)
//                        if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
//                            let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
//                            let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
//                            let singleNumber = singleNumbers[singleNumber]
//                        {
//                            let value = (millenium + century + decade + singleNumber)
//                            textToNumbers[key] = value
//                        }
//                    }
//                }
//            }
//        }

        return textToNumbers.count > 0 ? textToNumbers : nil
    }
    
    func masterChanges(interactive: Bool) -> [String:[String:String]]?
    {
        guard let textToNumbers = textToNumbers() else {
            return nil
        }
        
        guard let books = books() else {
            return nil
        }
        
        var changes = [String:[String:String]]()
        
        changes["words"] = words()
        changes["books"] = books
        
        if interactive {
            changes["textToNumbers"] = textToNumbers
        }
        
        // These should really be hierarchical.
        for key in textToNumbers.keys {
            if let value = textToNumbers[key] {
                for context in ["verse","verses","chapter","chapters"] {
                    if changes[context] == nil {
                        changes[context] = ["\(context) " + key:"\(context) " + value]
                    } else {
                        changes[context]?["\(context) " + key] = "\(context) " + value
                    }
                }
                
                for book in books.keys {
                    if let bookName = books[book], let index = Constants.OLD_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                    
                    if let bookName = books[book], let index = Constants.NEW_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                }
                
                // For books that don't start w/ a number
                for book in Constants.OLD_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {
                    
                    }
                }
                
                for book in Constants.NEW_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {

                    }
                }
            }
        }
        
        return changes.count > 0 ? changes : nil
    }
    
    func addParagraphBreaks(automatic:Bool = false,interactive:Bool,showGaps:Bool,gapThreshold:Double? = nil,words:[[String:Any]]?,text:String?,completion:((String)->(Void))?)
    {
        guard var words = words, words.count > 0 else {
            return
        }
        
        guard let text = text else {
            return
        }
        
        let first = words.removeFirst()
        
        guard let range = first["range"] as? Range<String.Index> else {
            return
        }
        
        guard let gap = first["gap"] as? Double else {
            return
        }
        
        var gapString = "\n\n"
        
        if showGaps {
            gapString = "<\(gap)>" + gapString
        }
        
//        let before = String(text[..<range.lowerBound])
//        let string = String(text[range])
//        let after = String(text[range.upperBound...])
            
        let fullAttributedString = NSMutableAttributedString()
        
        let beforeFull = String(text[..<range.lowerBound])
        let stringFull = String(text[range])
        let afterFull = String(text[range.upperBound...])
        
        fullAttributedString.append(NSAttributedString(string: beforeFull,attributes: Constants.Fonts.Attributes.normal))
        fullAttributedString.append(NSAttributedString(string: stringFull,attributes: Constants.Fonts.Attributes.highlighted))
        fullAttributedString.append(NSAttributedString(string: afterFull, attributes: Constants.Fonts.Attributes.normal))
        
        if interactive {
            Thread.onMainThread {
                self.textView.attributedText = fullAttributedString
                self.textView.scrollRangeToVisible(range)
            }
            
            let before = "..." + String(text[..<range.lowerBound]).dropFirst(max(String(text[..<range.lowerBound]).count - 10,0))
            let string = String(text[range])
            let after = String(String(text[range.upperBound...]).dropLast(max(String(text[range.upperBound...]).count - 10,0))) + "..."
            
            let beforeAttr = NSMutableAttributedString(string: before, attributes: Constants.Fonts.Attributes.normal)
            let stringAttr = NSMutableAttributedString(string: string, attributes: Constants.Fonts.Attributes.highlighted)
            let afterAttr = NSMutableAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal)
            
            let snippet = NSMutableAttributedString()
            
            snippet.append(beforeAttr)
            snippet.append(stringAttr)
            snippet.append(afterAttr)
            
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Show", style: .default, handler: {
//                var newText = String(text[..<range.lowerBound]) + "<mark>" + String(text[range]) + "</mark>" + String(text[range.upperBound...])

                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                    let textView = navigationController.viewControllers[0] as? TextViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    //                                            webView.html.fontSize = 12
                    
//                    webView.search = false
//                    webView.content = .html
//
//                    newText = "<html><body>" + newText + "</body></html>"
//
//                    webView.html.string = insertHead(newText,fontSize: 24)

                    textView.readOnly = true
                    textView.text = fullAttributedString.string

                    textView.onCancel = {
//                        Globals.shared.topViewController = self
                        words.insert(first, at:0)
                        self.addParagraphBreaks(interactive:interactive, showGaps:showGaps, words:words, text:text, completion:completion)
                    }
                    
                    Thread.onMainThread {
                        //                                            popover.activityIndicator.stopAnimating()
                        //                                            popover.activityIndicator.isHidden = true
                        
                        textView.navigationItem.title = self.navigationItem.title
                        
                        self.present(navigationController, animated: true, completion: {
                            textView.textView.attributedText = fullAttributedString
                            textView.textView.scrollRangeToVisible(range)
                        })
//                        self.present(navigationController, animated: true)
                    }
                }
            }))
            
            actions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                var newText = text
                
                newText.insert(contentsOf:gapString, at: range.lowerBound)
                
                for i in 0..<words.count {
                    if let wordRange = words[i]["range"] as? Range<String.Index> {
                        if wordRange.lowerBound > range.lowerBound {
                            var lower : String.Index?
                            var upper : String.Index?
                            
                            if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                            }
                            
                            if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                                upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                            }
                            
                            if let lower = lower, let upper = upper {
                                let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                                words[i]["range"] = newRange
                            }
                        }
                    }
                }
                
                completion?(newText)
                
                self.addParagraphBreaks(interactive:interactive, showGaps:showGaps, words:words, text:newText, completion:completion)
            }))
            
            actions.append(AlertAction(title: "No", style: .default, handler: {
                self.addParagraphBreaks(interactive:interactive, showGaps:showGaps, words:words, text:text, completion:completion)
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                completion?(text)
            }))
            
            let position = text.distance(from: text.startIndex, to: range.lowerBound)
            
            let distance = text.distance(from: text.startIndex, to: text.endIndex)
            
            Globals.shared.alert(category:nil,title:"Insert paragraph break before the highlighted text?",message:"Gap: \(gap) seconds\nat position \(position) of \(distance).",attributedText:snippet,actions:actions)
        } else {
            guard let gapThreshold = gapThreshold else {
                return
            }
            
            guard gap >= gapThreshold else {
                if !automatic {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                        self.updateBarButtons()
                    }))
                    
                    Globals.shared.alert(category:nil,title:"Assisted Editing Process Completed",message:nil,attributedText: nil, actions: actions)
                }
                return
            }
            
            var newText = text
            
            newText.insert(contentsOf:gapString, at: range.lowerBound)
            
            for i in 0..<words.count {
                if let wordRange = words[i]["range"] as? Range<String.Index> {
                    if wordRange.lowerBound > range.lowerBound {
                        var lower : String.Index?
                        var upper : String.Index?
                        
                        if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                            lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                        }
                        
                        if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                            upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                        }
                        
                        if let lower = lower, let upper = upper {
                            let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                            words[i]["range"] = newRange
                        }
                    }
                }
            }
            
            operationQueue.addOperation { [weak self] in
                Thread.onMainThread {
                    completion?(newText)
                }
                
                self?.addParagraphBreaks(interactive:interactive, showGaps:showGaps, gapThreshold:gapThreshold, words:words, text:newText, completion:completion)
            }
        }
    }

    
    func changeText(interactive:Bool,text:String?,startingRange : Range<String.Index>?,masterChanges:[String:[String:String]]?,completion:((String)->(Void))?)
    {
        guard var masterChanges = masterChanges, masterChanges.count > 0 else {
            if !automatic {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: {
                    self.updateBarButtons()
                }))
                
                Globals.shared.alert(category:nil,title:"Assisted Editing Process Completed",message:nil,attributedText: nil, actions: actions)
            } else {
                operationQueue.addOperation {
                    Thread.onMainThread {
                        self.dismiss(animated: true, completion: nil)
                        self.completion?(self.textView.attributedText.string)
                        self.automaticCompletion?()
                    }
                }
            }
            return
        }
        
        let keyOrder = ["words","textToNumbers","books","verse","verses","chapter","chapters"]
        
        let masterKeys = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
            let firstIndex = keyOrder.index(of: first)
            let secondIndex = keyOrder.index(of: second)
            
            if let firstIndex = firstIndex, let secondIndex = secondIndex {
                return firstIndex > secondIndex
            }
            
            if firstIndex != nil {
                return false
            }
            
            if secondIndex != nil {
                return true
            }
            
            return first.endIndex > second.endIndex
        })
        
        guard var text = text else {
            return
        }
        
        for masterKey in masterKeys {
            if !["words","books","textToNumbers"].contains(masterKey) {
                if !text.lowercased().contains(masterKey.lowercased()) {
                    masterChanges[masterKey] = nil
                }
            }
        }
        
        guard let masterKey = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
            let firstIndex = keyOrder.index(of: first)
            let secondIndex = keyOrder.index(of: second)
            
            if let firstIndex = firstIndex, let secondIndex = secondIndex {
                return firstIndex > secondIndex
            }
            
            if firstIndex != nil {
                return false
            }
            
            if secondIndex != nil {
                return true
            }
            
            return first.endIndex > second.endIndex
        }).first else {
            return
        }
        
//        guard var changes = masterChanges[masterKey] else {
//            return
//        }
        
        guard var key = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first else {
            return
        }
        
        var range : Range<String.Index>?
        
//        print(changes)
//        print(changes?.count)
        
//        print(masterKey,key,masterChanges[masterKey]?[key])
        
        if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
            if startingRange == nil {
                range = text.lowercased().range(of: key)
            } else {
                range = text.lowercased().range(of: key, options: [], range:  startingRange, locale: nil)
            }
        } else {
            if startingRange == nil {
                range = text.range(of: key)
            } else {
                range = text.range(of: key, options: [], range:  startingRange, locale: nil)
            }
        }
        
        while range == nil {
            masterChanges[masterKey]?[key] = nil
            
            if let first = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first {
                key = first
                
                if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
                    range = text.lowercased().range(of: key)
                } else {
                    range = text.range(of: key)
                }
            } else {
                break
            }
        }
        
        if let range = range, let value = masterChanges[masterKey]?[key] {
            let attributedString = NSMutableAttributedString()
            
            let before = "..." + String(text[..<range.lowerBound]).dropFirst(max(String(text[..<range.lowerBound]).count - 10,0))
            let string = String(text[range])
            let after = String(String(text[range.upperBound...]).dropLast(max(String(text[range.upperBound...]).count - 10,0))) + "..."
            
            attributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.normal))
            attributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
            attributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal))
            
            let prior = String(text[..<range.lowerBound]).last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let following = String(text[range.upperBound...]).first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if (prior?.isEmpty ?? true) && ((following?.isEmpty ?? true) || (following == ".")) {
                if interactive {
                    let fullAttributedString = NSMutableAttributedString()

                    let before = String(text[..<range.lowerBound])
                    let string = String(text[range])
                    let after = String(text[range.upperBound...])

                    fullAttributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.normal))
                    fullAttributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
                    fullAttributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal))

                    Thread.onMainThread {
                        self.textView.attributedText = fullAttributedString
                        self.textView.scrollRangeToVisible(range)
                    }
                    
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.normal)
                        
                        text.replaceSubrange(range, with: value)
                        
                        completion?(text)
                        
                        let before = String(text[..<range.lowerBound])
                        
                        if let completedRange = text.range(of: before + value) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                        } else {
                            // ERROR
                        }
                    }))
                    
                    actions.append(AlertAction(title: "No", style: .default, handler: {
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.normal)
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                        self.textView.attributedText = NSAttributedString(string: text,attributes: Constants.Fonts.Attributes.normal)
                    }))
                    
                    Globals.shared.alert(category:nil,title:"Change \"\(string)\" to \"\(value)\"?",message:nil,attributedText:attributedString,actions:actions)
                } else {
                    operationQueue.addOperation { [weak self] in
                        text.replaceSubrange(range, with: value)
                        
                        Thread.onMainThread {
                            completion?(text)
                        }
                        
                        let before = String(text[..<range.lowerBound])
                        
                        if let completedRange = text.range(of: before + value) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            self?.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                        } else {
                            // ERROR
                        }
                    }
                }
            } else {
                if interactive {
                    let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                    self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                } else {
                    operationQueue.addOperation { [weak self] in
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        self?.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                    }
                }
            }
        } else {
            if interactive {
                print(key)
                masterChanges[masterKey]?[key] = nil
                if masterChanges[masterKey]?.count == 0 {
                    print(masterKey)
                    masterChanges[masterKey] = nil
                }
                self.changeText(interactive:interactive,text:text,startingRange:nil,masterChanges:masterChanges,completion:completion)
            } else {
                operationQueue.addOperation { [weak self] in
                    masterChanges[masterKey]?[key] = nil
                    if masterChanges[masterKey]?.count == 0 {
                        masterChanges[masterKey] = nil
                    }
                    self?.changeText(interactive:interactive,text:text,startingRange:nil,masterChanges:masterChanges,completion:completion)
                }
            }
        }
    }
    
//    func changes(interactive: Bool)
//    {
//        if let hierarchicalChanges = heirarchicalChanges() {
//            for hierarchicalChange in hierarchicalChanges.keys {
//                print(hierarchicalChange)
//                if self.textView.attributedText.string.lowercased().contains(hierarchicalChange), let hierarchicalChanges = hierarchicalChanges[hierarchicalChange] {
//                    self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: hierarchicalChanges, completion: { (string:String) -> (Void) in
//                        self.changedText = string
//                        self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
//                    })
//                    
//                    while self.operationQueue.operationCount > 0 {
//                        
//                    }
//                }
//            }
//        }
//        
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.textToNumbers(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
////
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.books(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
////
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.words(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
//    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if isTracking {
            //            startTracking()
            //            removeAssist()
            oldRange = nil // Forces the range to be highlighted.
        } else {
            textView.scrollRangeToVisible(NSMakeRange(0, 0))
        }
        
        if automatic {
            let text = self.textView.attributedText.string
            
            process(viewController: self, work: { [weak self] () -> (Any?) in
                self?.changeText(interactive: self?.automaticInteractive == true, text: text, startingRange: nil, masterChanges: self?.masterChanges(interactive: self?.automaticInteractive == true), completion: { (string:String) -> (Void) in
                    self?.changedText = string
                    self?.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                })
                
                self?.operationQueue.waitUntilAllOperationsAreFinished()

                return nil
            }) { [weak self] (data:Any?) in
//                self.dismiss(animated: true, completion: nil)
//                self.completion?(self.textView.text)
//                self.automaticCompletion?()
            }
        } else {
//            if track {
//                follow()
//            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard (self.view.window == nil) else {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
//        mask = false
        
        NotificationCenter.default.removeObserver(self)

        if Globals.shared.topViewController.last == navigationController {
            Globals.shared.topViewController.removeLast()
        }
        
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)

    }
}

