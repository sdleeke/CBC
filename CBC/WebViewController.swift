//
//  WebViewController.swift
//  GTY
//
//  Created by Steve Leeke on 11/10/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit
import MessageUI
import MobileCoreServices

class HTML {
    weak var webViewController: WebViewController?
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "LEXICON UPDATE"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    var text : String?
    {
        didSet {
//            print(text)
        }
    }
    
    var original:String?
    
    var string:String?
    {
        didSet {
            // Why are we doing this?
            
            string = string?.replacingOccurrences(of: Constants.LEFT_DOUBLE_QUOTE, with: Constants.DOUBLE_QUOTE)
            string = string?.replacingOccurrences(of: Constants.RIGHT_DOUBLE_QUOTE, with: Constants.DOUBLE_QUOTE)
            
            string = string?.replacingOccurrences(of: Constants.LEFT_SINGLE_QUOTE, with: Constants.SINGLE_QUOTE)
            string = string?.replacingOccurrences(of: Constants.RIGHT_SINGLE_QUOTE, with: Constants.SINGLE_QUOTE)
            
            string = string?.replacingOccurrences(of: Constants.EM_DASH, with: Constants.DASH)
            
            if original == nil {
                original = string
            }
            
            if string != oldValue {
                if let url = fileURL {
                    let fileManager = FileManager.default

                    if (fileManager.fileExists(atPath: url.path)){
                        do {
                            try fileManager.removeItem(at: url)
                        } catch let error as NSError {
                            print("failed to remove htmlString: \(error.localizedDescription)")
                        }
                    }

                    if let isEmpty = string?.isEmpty, !isEmpty {
                        do {
                            try string?.replacingOccurrences(of: Constants.UNBREAKABLE_SPACE, with: Constants.SINGLE_SPACE).write(toFile: url.path, atomically: false, encoding: String.Encoding.utf16);
                        } catch let error as NSError {
                            print("failed to write htmlString to cache directory: \(error.localizedDescription)")
                        }
                    }
                }

                Thread.onMainThread {
                    self.webViewController?.activityButtonIndicator?.startAnimating()
                }
                
                // Get a new queue - does this ever happen more than once?  Yes, when font size is changed or searching occurs.
                operationQueue = OperationQueue()
                operationQueue.name = "HTML"
                operationQueue.qualityOfService = .userInteractive
                operationQueue.maxConcurrentOperationCount = 1

//                operationQueue.cancelAllOperations()
//                operationQueue.waitUntilAllOperationsAreFinished()

                operationQueue.addOperation { [weak self] in
                    self?.text = stripHTML(self?.string) // This leaves an HTML frame around the text!
                    Thread.onMainThread {
                        self?.webViewController?.activityButtonIndicator?.stopAnimating()
                    }
                }
            }
        }
    }
    
    var fileURL : URL?
    {
        get {
            // Same result, just harder to read and understand.
//            return !(string?.isEmpty ?? true) ? cachesURL()?.appendingPathComponent("string.html") : nil
            
            if let isEmpty = string?.isEmpty, !isEmpty {
                return cachesURL()?.appendingPathComponent("string.html")
            } else {
                return nil
            }
        }
    }
    
    var fontSize = Constants.FONT_SIZE
    var xRatio = 0.0
    var yRatio = 0.0
    var zoomScale = 0.0
}

//class StripHTMLActivity : UIActivityItemProvider
//{
//    override var item : Any {
//        get {
//            return stripHTML(placeholderItem as? String)
//        }
//    }
//}

extension WebViewController : UIActivityItemSource
{
    func share()
    {
        guard let html = self.html.string else {
            return
        }
        
//        if #available(iOS 10.0, *) {
//            UIPasteboard.general.addItems([[kUTTypeHTML as String: html]])
//        } else {
//            // Fallback on earlier versions
//        }

        let print = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        let activityViewController = UIActivityViewController(activityItems:[self,html,print] , applicationActivities: nil)
        
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

        guard let html = self.html.string else {
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
            return self.html.string
        } else {
//            html.operationQueue.waitUntilAllOperationsAreFinished()
            
            if let text = self.html.text {
//                if #available(iOS 10.0, *) {
//                    UIPasteboard.general.addItems([[kUTTypeText as String: text]])
//                } else {
//                    // Fallback on earlier versions
//                }
                return text
            } else {
                return "HTML to text conversion still in process.  Please try again later."
            }
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        return mediaItem?.text ?? (transcript?.mediaItem?.text ?? (self.navigationItem.title ?? ""))
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

extension WebViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension WebViewController : PopoverPickerControllerDelegate
{
    // MARK: PopoverPickerControllerDelegate
    
    func stringPicked(_ string: String?)
    {
        guard let string = string else {
            return
        }
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:stringPicked", completion: nil)
            return
        }
        
        self.dismiss(animated: true, completion: nil)

        self.navigationController?.popToRootViewController(animated: true) // Why are we doing this?
        
        var searchText = string
        
        if let range = searchText.range(of: " (") {
            searchText = String(searchText[..<range.lowerBound])
        }
        
        self.wkWebView?.isHidden = true
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        if let mediaItem = mediaItem {
            html.string = mediaItem.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true)
        }

        if let transcript = transcript {
            html.string = transcript.markedFullHTML(searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true)
        }

        html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
        
        if let url = self.html.fileURL {
            wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
        }
        
        // Problem is hyperlinks do not work w/o file based HTML
//        if let htmlString = self.html.string {
//            _ = self.wkWebView?.loadHTMLString(htmlString, baseURL: nil)
//        }
    }
}

extension WebViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
//    func done()
//    {
//        dismiss(animated: true, completion: nil)
//    }
    
//    func shareHTML(_ htmlString:String?)
//    {
//        guard let htmlString = htmlString else {
//            return
//        }
//        
//        let print = UIMarkupTextPrintFormatter(markupText: htmlString)
//        let margin:CGFloat = 0.5 * 72
//        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
//        
//        let activityViewController = UIActivityViewController(activityItems:[stripHTML(htmlString),htmlString,print] , applicationActivities: nil)
//
//        // exclude some activity types from the list (optional)
//        
//        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
//        
//        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//        
//        // present the view controller
//        Thread.onMainThread {
//            self.present(activityViewController, animated: true, completion: nil)
//        }
//    }
    
    @objc func showFullScreen()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? WebViewController {
            dismiss(animated: false, completion: nil)
            
            navigationController.modalPresentationStyle = .overFullScreen
            navigationController.popoverPresentationController?.delegate = popover
            
            popover.navigationItem.title = self.navigationItem.title
            
            popover.html.fontSize = self.html.fontSize
            popover.html.string = self.html.string
            
            popover.search = self.search
            popover.mediaItem = self.mediaItem
            popover.transcript = self.transcript

            popover.content = self.content

            popover.navigationController?.isNavigationBarHidden = false
            
            Globals.shared.splitViewController.present(navigationController, animated: true, completion: nil)
        }
    }

    func actions(action: String?, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.Full_Screen:
            showFullScreen()
            break
            
        case Constants.Strings.Print:
            if let string = html.string, string.contains(" href=") {
                firstSecondCancel(viewController: self, title: "Remove Links?", message: nil, //"This can take some time.",
                                  firstTitle: "Yes",
                                  firstAction: {
                                        process(viewController: self, work: { [weak self] () -> (Any?) in
                                            return stripLinks(self?.html.string)
                                        }, completion: { [weak self] (data:Any?) in
                                            if let vc = self {
                                                printHTML(viewController: vc, htmlString: data as? String)
                                            }
                                        })
                                    }, firstStyle: .default,
                                  secondTitle: "No",
                                  secondAction: {
                                        printHTML(viewController: self, htmlString: self.html.string)
                                    }, secondStyle: .default,
                                  cancelAction: nil
                )
            } else {
                printHTML(viewController: self, htmlString: self.html.string)
            }
            break
            
        case Constants.Strings.Share:
            share()
            break
            
        case Constants.Strings.Search:
            searchAlert(viewController: self, title: "Search", message: nil, searchText:searchText, searchAction:  { (alert:UIAlertController) -> (Void) in
                self.searchText = alert.textFields?[0].text
                
                if let isEmpty = self.searchText?.isEmpty, isEmpty, self.html.string == self.html.original {
                    return
                }
                
                self.wkWebView?.isHidden = true
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                
                if self.mediaItem != nil {
                    self.html.string = insertHead(stripHead(self.mediaItem?.markedFullNotesHTML(searchText:self.searchText, wholeWordsOnly: false, lemmas: false, index: true)),fontSize: self.html.fontSize)
                } else
                if self.transcript != nil {
                    self.html.string = insertHead(stripHead(self.transcript?.markedFullHTML(searchText:self.searchText, wholeWordsOnly: false, lemmas: false, index: true)),fontSize: self.html.fontSize)
                } else {
                    self.html.string = insertHead(stripHead(self.markedHTML(searchText:self.searchText, wholeWordsOnly: false, index: true)),fontSize: self.html.fontSize)
                }
                
                if let url = self.html.fileURL {
                    self.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }
                
//                if let htmlString = self.html.string {
//                    _ = self.wkWebView?.loadHTMLString(htmlString, baseURL: nil)
//                }
            })
            break
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self

                popover.navigationController?.isNavigationBarHidden = false

                popover.delegate = self

                popover.stringTree = StringTree()
                
                if let mediaItem = mediaItem {
                    popover.navigationItem.title = mediaItem.title // Constants.Strings.Word_Picker
                    
//                    mediaItem.loadNotesTokens()
//                    if let keys = mediaItem.notesTokens?.keys {
//                        let strings = [String](keys).sorted()
//                        popover.strings = strings
//                    }

                    popover.stringsFunction = {
                        mediaItem.loadNotesTokens()
                        if let keys = mediaItem.notesTokens?.keys {
                            let strings = [String](keys).sorted()
                            return strings
                        }
                        
                        return nil
                    }

//                    let strings:[String]? = mediaItem.notesTokens?.keys.map({ (string:String) -> String in
//                        return string
//                    }).sorted()
                }
                
                if let transcript = transcript {
                    popover.navigationItem.title = transcript.mediaItem?.title // Constants.Strings.Word_Picker
                    
//                    popover.strings = transcript.tokens?.map({ (word:String,count:Int) -> String in
//                        return word
//                    }).sorted()
                    
                    popover.stringsFunction = {
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return transcript.tokens?.map({ (word:String,count:Int) -> String in
                            return word
                        }).sorted()
                    }
                }

                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Word_Cloud:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WORD_CLOUD) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? CloudViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                if let mediaItem = mediaItem {
                    popover.cloudTitle = mediaItem.title
                    popover.mediaItem = mediaItem
                    
                    popover.cloudWordsFunction = {
                        mediaItem.loadNotesTokens()
                        
                        let words:[[String:Any]]? = mediaItem.notesTokens?.map({ (key:String, value:Int) -> [String:Any] in
                            return ["word":key,"count":value,"selected":true]
                        })
                        
                        return words
                    }
                    
                    //                .filter({ (dict:[String:Any]) -> Bool in
                    //                    guard let word = dict["word"] as? String else {
                    //                        return false
                    //                    }
                    //
                    //                    guard let count = dict["count"] as? Int else {
                    //                        return false
                    //                    }
                    //
                    //                    return !Constants.COMMON_WORDS.contains(word) && (count > 8)
                    //                })
                    
//                    popover.cloudWords = words
                }
                
                if let transcript = transcript {
                    popover.cloudTitle = transcript.mediaItem?.title
                    popover.mediaItem = transcript.mediaItem

                    popover.cloudWordsFunction = {
                        let words = transcript.tokens?.map({ (word:String,count:Int) -> [String:Any] in
                            return ["word":word,"count":count,"selected":true]
                        })
                        
                        return words
                    }
                    
//                    popover.cloudWords = words
                }
                
                popover.cloudFont = UIFont.preferredFont(forTextStyle:.body)
                
                present(navigationController, animated: true, completion:  nil)
            }
            break
            
        case Constants.Strings.Words:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingWord
                
                popover.segments = true
                
                popover.sort.function = sort
                popover.sort.method = Constants.Sort.Alphabetical
                
                var segmentActions = [SegmentAction]()
                
                segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: {
                    let strings = popover.sort.function?(Constants.Sort.Alphabetical,popover.section.strings)
                    if popover.segmentedControl.selectedSegmentIndex == 0 {
                        popover.sort.method = Constants.Sort.Alphabetical
                        popover.section.strings = strings
                        popover.section.showIndex = true
                        popover.tableView?.reloadData()
                    }
                }))
                
                segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                    let strings = popover.sort.function?(Constants.Sort.Frequency,popover.section.strings)
                    if popover.segmentedControl.selectedSegmentIndex == 1 {
                        popover.sort.method = Constants.Sort.Frequency
                        popover.section.strings = strings
                        popover.section.showIndex = false
                        popover.tableView?.reloadData()
                    }
                }))

//                segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: {
//                    popover.sort.method = Constants.Sort.Alphabetical
//                    popover.section.showIndex = true
//                    popover.section.strings = popover.sort.function?(popover.sort.method,popover.section.strings)
//                    popover.tableView.reloadData()
//                }))
//                segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
//                    popover.sort.method = Constants.Sort.Frequency
//                    popover.section.showIndex = false
//                    popover.section.strings = popover.sort.function?(popover.sort.method,popover.section.strings)
//                    popover.tableView.reloadData()
//                }))
                
                popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                
                popover.section.showIndex = true
                
                popover.search = true
                
                if let mediaItem = mediaItem, mediaItem.hasNotesHTML {
                    popover.navigationItem.title = mediaItem.title // Constants.Strings.Words
                    
                    popover.selectedMediaItem = mediaItem
                    
                    if mediaItem.notesTokens == nil {
                        popover.stringsFunction = {
                            mediaItem.loadNotesTokens()

                            return mediaItem.notesTokens?.map({ (string:String,count:Int) -> String in
                                return "\(string) (\(count))"
                            }).sorted()
                        }
                    } else {
                        popover.section.strings = mediaItem.notesTokens?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    }
                }
                
                if let transcript = transcript {
                    popover.navigationItem.title = transcript.mediaItem?.title // Constants.Strings.Words
                    
                    // If the transcript has been edited some of these words may not be found.
//                    popover.section.strings = transcript.tokens?.map({ (word:String,count:Int) -> String in
//                        return "\(word) (\(count))"
//                    }).sorted()

                    popover.stringsFunction = {
                        // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                        return transcript.tokens?.map({ (word:String,count:Int) -> String in
                            return "\(word) (\(count))"
                        }).sorted()
                    }

//                    popover.section.strings = tokensAndCountsFromString(transcript.transcript)?.map({ (word:String,count:Int) -> String in
//                        return "\(word) (\(count))"
//                    }).sorted()
                }
                
                popover.vc = self

                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Email_One:
            if let title = navigationItem.title, let htmlString = html.string {
                mailHTML(viewController: self, to: [], subject: Constants.CBC.LONG + Constants.SINGLE_SPACE + title, htmlString: htmlString)
            }
            break
            
//        case Constants.Strings.Open_in_Browser:
//            if let url = selectedMediaItem?.downloadURL {
//                open(scheme: url.absoluteString) {
//                    networkUnavailable(self,"Unable to open: \(url)")
//                }
//            }
//            break
            
        case Constants.Strings.Refresh_Document:
            mediaItem?.download?.delete()
            
            wkWebView?.isHidden = true
            wkWebView?.removeFromSuperview()
            
            webView.bringSubview(toFront: activityIndicator)
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            setupWKWebView()
            
//            loadDocument()
            
            loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
            break
            
        default:
            break
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }

        dismiss(animated: true, completion: nil)
        
        let string = strings[index]
        
        switch purpose {
        case .selectingWord:
            self.navigationController?.popToRootViewController(animated: true) // Why are we doing this?
            
            var searchText = string
            
            if let range = searchText.range(of: " (") {
                searchText = String(searchText[..<range.lowerBound])
            }
            
            wkWebView?.isHidden = true
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let mediaItem = mediaItem {
                    self?.html.string = mediaItem.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true)
                }
                
                if let transcript = self?.transcript {
                    self?.html.string = transcript.markedFullHTML(searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true)
                }
                
                if let fontSize = self?.html.fontSize {
                    self?.html.string = insertHead(stripHead(self?.html.string),fontSize: fontSize)
                    
                    if let url = self?.html.fileURL {
                        Thread.onMainThread {
                            self?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                        }
                    }
                }
                
                //            if let htmlString = self.html.string {
                //                _ = wkWebView?.loadHTMLString(htmlString, baseURL: nil)
                //            }
            }
            break
            
        case .selectingAction:
            actions(action: string, mediaItem:mediaItem)
            break
            
        default:
            break
        }
    }
}

extension WebViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension WebViewController : WKNavigationDelegate
{
    // MARK: WKNavigationDelegate

    func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!)
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
        setupHTMLWKZoomScaleAndContentOffset(wkWebView)
        
        Thread.onMainThread {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            
            self.progressIndicator.isHidden = true
            
            self.barButtonItems(isEnabled: true)
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.sleep(forTimeInterval: 0.1) // This is ESSENTIAL to allow the preferred content size to be set correctly.
                
                Thread.onMainThread {
                    wkWebView.isHidden = false
                    wkWebView.scrollView.contentOffset = CGPoint(x: 0, y: 0)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
                }
            }
        }
    }
    
    func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError: Error)
    {
//        if (splitViewController?.viewControllers.count > 1) || (self == navigationController?.visibleViewController) {
        if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed || (self == navigationController?.visibleViewController) {
            print("wkDidFail navigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(self,withError.localizedDescription)
            NSLog(withError.localizedDescription)
        }
        // Keep trying
        //        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        //        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error)
    {
//        if (splitViewController?.viewControllers.count > 1) || (self == navigationController?.visibleViewController) {
        if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed || (self == navigationController?.visibleViewController) {
            print("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(self,withError.localizedDescription)
            NSLog(withError.localizedDescription)
        }
    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!)
    {

    }
    
    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        switch navigationAction.navigationType {
        case .linkActivated:
            if let url = navigationAction.request.url?.absoluteString, url.contains("file:///") {
                decisionHandler(WKNavigationActionPolicy.allow)
            } else {
                open(scheme: navigationAction.request.url?.absoluteString) {}
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
            break
            
        case .other: // loading html string
            decisionHandler(WKNavigationActionPolicy.allow)
            break
            
        default:
            decisionHandler(WKNavigationActionPolicy.cancel)
            break
        }
    }
}

extension WebViewController: UIScrollViewDelegate
{
//    func viewForZooming(in scrollView: UIScrollView) -> UIView?
//    {
//        return 
//    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .pdf:
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .pdf:
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .pdf:
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}

extension WebViewController: UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class WebViewController: UIViewController
{
    var popover : PopoverTableViewController?

    var search = false
    var searchText:String?
    
    var pdfURLString : String?

    enum Content {
        case document
        case pdf
        case html
    }
    
    var fullScreenButton:UIBarButtonItem?
    var actionButton:UIBarButtonItem?
    var minusButton:UIBarButtonItem?
    var plusButton:UIBarButtonItem?
    var activityButton:UIBarButtonItem?
    var activityButtonIndicator:UIActivityIndicatorView!
    
    var wkWebView:WKWebView?

    var content:Content = .document
    
    lazy var html:HTML! = {
//        [weak self] in
        let html = HTML()
        html.webViewController = self
        return html
    }()
    
    var loadTimer:Timer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var logo: UIImageView!
    
    func markedHTML(searchText:String?,wholeWordsOnly:Bool,index:Bool) -> String?
    {
        guard (stripHead(html.original) != nil) else {
            return nil
        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return html.original
        }
        
        var markCounter = 0
        
        func mark(_ input:String) -> String
        {
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
                            if CharacterSet.letters.contains(unicodeScalar) { // }!CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                                skip = true
                            }
                            
                            if searchText.count == 1 {
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
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
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                    skip = true
                                }
                            }
                        }
                    }
                    
                    if let characterAfter:Character = stringAfter.first {
                        if  let unicodeScalar = UnicodeScalar(String(characterAfter)), CharacterSet.letters.contains(unicodeScalar) {
//                            !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        } else {
//                            if characterAfter == "." {
//                                if let afterFirst = stringAfter[String(String(characterAfter).endIndex...]).first,
//                                    let unicodeScalar = UnicodeScalar(String(afterFirst)) {
//                                    if !CharacterSet.whitespacesAndNewlines.contains(unicodeScalar) && !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
//                                        skip = true
//                                    }
//                                }
//                            }
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
                        if  let unicodeScalar = UnicodeScalar(String(characterBefore)), CharacterSet.letters.contains(unicodeScalar) {
//                            !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
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
        
        var newString:String = Constants.EMPTY_STRING
        var string:String = html.original ?? Constants.EMPTY_STRING
        
        while let searchRange = string.range(of: "<") {
            let searchString = String(string[..<searchRange.lowerBound])
            //            print(searchString)
            
            // mark search string
            newString = newString + mark(searchString.replacingOccurrences(of: "&nbsp;", with: " "))
            
            let remainder = String(string[searchRange.lowerBound...])
            
            if let htmlRange = remainder.range(of: ">") {
                let html = String(remainder[..<htmlRange.upperBound])
                //                print(html)
                
                newString = newString + html
                
                string = String(remainder[htmlRange.upperBound...])
            }
        }
        
        var indexString:String!
        
        if markCounter > 0 {
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.<br/>"
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
                
                indexString = indexString + "<br/><br/></div>"
            }
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if index {
            htmlString = htmlString + indexString
        }
        
        htmlString = htmlString + newString + "</body></html>"
        
        return insertHead(htmlString,fontSize: Constants.FONT_SIZE)
    }

    @objc func updateDownload()
    {
        if let download = mediaItem?.download {
            switch download.state {
            case .none:
                break
                
            case .downloading:
                progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                break
                
            case .downloaded:
                break
            }
        }
    }
    
    @objc func cancelDownload()
    {
        if let download = mediaItem?.download {
            switch download.state {
            case .none:
                break
                
            case .downloading:
                download.state = .none

                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    self.wkWebView?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.webView.bringSubview(toFront: self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    networkUnavailable(self,"Document could not be loaded.")
                }
                break
                
            case .downloaded:
                break
            }
        }
    }
    
    var transcript:VoiceBase?
    {
        willSet {
            
        }
        didSet {
            
        }
    }
    
    var mediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if oldValue != nil {
                Thread.onMainThread {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: oldValue?.download)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: oldValue?.download)
                }
            }

            if mediaItem != nil {
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.updateDownload), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self.mediaItem?.download)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.cancelDownload), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.mediaItem?.download)
                }
            }
        }
    }

    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
    }
    
    fileprivate func setupWKWebView()
    {
        wkWebView = WKWebView(frame:webView.bounds)
        
        guard let wkWebView = wkWebView else {
            return
        }

        wkWebView.isHidden = true
        
        wkWebView.isMultipleTouchEnabled = true
        wkWebView.isUserInteractionEnabled = true
        
        wkWebView.scrollView.scrollsToTop = true
        
        wkWebView.scrollView.delegate = self
        
        wkWebView.navigationDelegate = self
        wkWebView.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        webView.addSubview(wkWebView)
        
        let centerX = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(height)
        
        wkWebView.superview?.setNeedsLayout()
    }
    
    @objc func done()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:done", completion: nil)
            return
        }

        dismiss(animated: true, completion: nil)
    }
    
    var ptvc:PopoverTableViewController?
    
    var activityViewController:UIActivityViewController?
    
    @objc func actionMenu()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = mediaItem
            
            var actionMenu = [String]()
            
            if (html.string != nil) && search {
                actionMenu.append(Constants.Strings.Search)
                
                if (mediaItem != nil) || (transcript != nil) {
                    actionMenu.append(Constants.Strings.Words)
                    actionMenu.append(Constants.Strings.Word_Picker)
                    
                    if !Globals.shared.splitViewController.isCollapsed {
                        actionMenu.append(Constants.Strings.Word_Cloud)
                    }
                }
            }
            
            if self.navigationController?.modalPresentationStyle == .popover {
                actionMenu.append(Constants.Strings.Full_Screen)
            }
            
            if UIPrintInteractionController.isPrintingAvailable {
                actionMenu.append(Constants.Strings.Print)
            }
            
            if html.string != nil {
                actionMenu.append(Constants.Strings.Share)
            }
            
            popover.section.strings = actionMenu
            
            popover.vc = self
            
            ptvc = popover
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func increaseFontSize()
    {
        html.fontSize += 1
        
        captureHTMLContentOffsetAndZoomScale()
        
        Thread.onMainThread {
            if self.html.fontSize > Constants.HTML_MIN_FONT_SIZE {
                self.minusButton?.isEnabled = true
            }
            
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }

        html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)

        if let url = html.fileURL {
            wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
        }

//        if let htmlString = html.string {
//            _ = wkWebView?.loadHTMLString(htmlString, baseURL: nil)
//        }
    }
    
    @objc func decreaseFontSize()
    {
        if html.fontSize > Constants.HTML_MIN_FONT_SIZE {
            html.fontSize -= 1
            
            captureHTMLContentOffsetAndZoomScale()
            
            Thread.onMainThread {
                if self.html.fontSize <= Constants.HTML_MIN_FONT_SIZE {
                    self.minusButton?.isEnabled = false
                }
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            
            html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)

            if let url = html.fileURL {
                wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
            }

//            if let htmlString = html.string {
//                _ = wkWebView?.loadHTMLString(htmlString, baseURL: nil)
//            }
        }
    }
    
    fileprivate func setupActionButton()
    {
        fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItemStyle.plain, target: self, action: #selector(showFullScreen))
        fullScreenButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(actionMenu))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(increaseFontSize))
        plusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(decreaseFontSize))
        minusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        activityButtonIndicator = UIActivityIndicatorView()
        activityButtonIndicator.activityIndicatorViewStyle = .gray
        activityButtonIndicator.hidesWhenStopped = true
        
        activityButton = UIBarButtonItem(customView: activityButtonIndicator)
        activityButton?.isEnabled = true

        if let presentationStyle = navigationController?.modalPresentationStyle {
            guard   let actionButton = actionButton,
                    let fullScreenButton = fullScreenButton,
                    let minusButton = minusButton,
                    let plusButton = plusButton,
                    let activityButton = activityButton else {
                return
            }
            
            switch presentationStyle {
            case .formSheet:
                fallthrough
            case .overCurrentContext:
                if self.navigationController?.viewControllers.count == 1 { // This allows the back button to show. >1 implies it is below the top view controller in a push stack.
                    navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done)), animated: true)
                    navigationItem.setRightBarButtonItems([actionButton,fullScreenButton,minusButton,plusButton,activityButton], animated: true)
                } else {
                    if let count = navigationItem.rightBarButtonItems?.count, count > 0 {
                        navigationItem.rightBarButtonItems?.append(actionButton)
                        navigationItem.rightBarButtonItems?.append(minusButton)
                        navigationItem.rightBarButtonItems?.append(plusButton)
                        navigationItem.rightBarButtonItems?.append(activityButton)
                    } else {
                        navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
                    }
                }
                
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done)), animated: true)
                navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
                
            default:
                navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
                break
            }
        }
    }

    @objc func loading()
    {
        if let wkWebView = wkWebView {
            progressIndicator.progress = Float(wkWebView.estimatedProgress)
        }
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            
            progressIndicator.isHidden = true
        }
    }
    
    func setWKZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint)
    {
        Thread.onMainThread {
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        }
    }
    
    func setupWKZoomScaleAndContentOffset()
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
    }
    
    func setupWKZoomScaleAndContentOffset(_ wkWebView: WKWebView?)
    {
        guard let wkWebView = wkWebView else {
            return
        }
        
        guard let showing = mediaItem?.showing else {
            return
        }
        
        guard (mediaItem != nil) else {
            return
        }

        var zoomScaleStr:String?
        var contentOffsetXRatioStr:String?
        var contentOffsetYRatioStr:String?
        
//        contentOffsetXRatioStr = mediaItem?.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X_RATIO]
//        contentOffsetYRatioStr = mediaItem?.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y_RATIO]
        
        contentOffsetXRatioStr = mediaItem?.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X]
        contentOffsetYRatioStr = mediaItem?.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y]
        zoomScaleStr = mediaItem?.mediaItemSettings?[showing + Constants.ZOOM_SCALE]
        
        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:CGFloat = 0.0
        var contentOffsetYRatio:CGFloat = 0.0
        
        if let ratio = contentOffsetXRatioStr, let num = Float(ratio) {
            contentOffsetXRatio = CGFloat(num)
        }
        
        if let ratio = contentOffsetYRatioStr, let num = Float(ratio) {
            contentOffsetYRatio = CGFloat(num)
        }
        
        if let zoom = zoomScaleStr, let num = Float(zoom) {
            zoomScale = CGFloat(num)
        }
        
        let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio * wkWebView.scrollView.contentSize.width * zoomScale),
                                    y: CGFloat(contentOffsetYRatio * wkWebView.scrollView.contentSize.height * zoomScale))
        
        setWKZoomScaleThenContentOffset(wkWebView, scale: zoomScale, offset: contentOffset)
    }
    
    func setupWKContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.

        guard let wkWebView = wkWebView else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let showing = mediaItem.showing else {
            return
        }
        
//        var contentOffsetXRatioStr:String?
//        var contentOffsetYRatioStr:String?
//
//        contentOffsetXRatioStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X_RATIO]
//        contentOffsetYRatioStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y_RATIO]
        
        var contentOffsetXStr:String?
        var contentOffsetYStr:String?
        
        contentOffsetXStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X]
        contentOffsetYStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y]
        
//        var contentOffsetXRatio:CGFloat = 0.0
//        var contentOffsetYRatio:CGFloat = 0.0
        
        var contentOffsetX:CGFloat = 0.0
        var contentOffsetY:CGFloat = 0.0
        
//        if let ratio = contentOffsetXRatioStr, let num = Float(ratio) {
//            contentOffsetXRatio = CGFloat(num)
//        }
//
//        if let ratio = contentOffsetYRatioStr, let num = Float(ratio) {
//            contentOffsetYRatio = CGFloat(num)
//        }
        
        if let x = contentOffsetXStr, let num = Float(x) {
            contentOffsetX = CGFloat(num)
        }
        
        if let y = contentOffsetYStr, let num = Float(y) {
            contentOffsetY = CGFloat(num)
        }
        
//        let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio * wkWebView.scrollView.contentSize.width), //
//            y: CGFloat(contentOffsetYRatio * wkWebView.scrollView.contentSize.height)) //
        
        let contentOffset = CGPoint(x: CGFloat(contentOffsetX), //
                                    y: CGFloat(contentOffsetY)) //
        
        Thread.onMainThread {
            wkWebView.scrollView.setContentOffset(contentOffset,animated: false)
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
        guard let wkWebView = wkWebView else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let showing = mediaItem.showing else {
            return
        }
        
        if !wkWebView.isLoading, wkWebView.url != nil {
//            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X_RATIO] = "\(wkWebView.scrollView.contentOffset.x / wkWebView.scrollView.contentSize.width)"
//
//            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y_RATIO] = "\(wkWebView.scrollView.contentOffset.y / wkWebView.scrollView.contentSize.height)"
            
            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X] = "\(wkWebView.scrollView.contentOffset.x)"
            
            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y] = "\(wkWebView.scrollView.contentOffset.y)"
            
            mediaItem.mediaItemSettings?[showing + Constants.ZOOM_SCALE] = "\(wkWebView.scrollView.zoomScale)"
        }
    }
    
    //
    // The following don't work well
    //
    
    func setupHTMLWKZoomScaleAndContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
//        guard let wkWebView = wkWebView else {
//            return
//        }
//
//        let contentOffset = CGPoint(x: CGFloat(html.xRatio * Double(wkWebView.scrollView.contentSize.width)),
//                                    y: CGFloat(html.yRatio * Double(wkWebView.scrollView.contentSize.height)))
//
//        Thread.onMainThread {
//            wkWebView.scrollView.setZoomScale(CGFloat(self.html.zoomScale), animated: false)
//            wkWebView.scrollView.setContentOffset(contentOffset,animated: false)
//        }
    }
    
    func setupHTMLWKContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
//        guard let wkWebView = wkWebView else {
//            return
//        }
//
//        let contentOffset = CGPoint(x: CGFloat(html.xRatio * Double(wkWebView.scrollView.contentSize.width)), //
//            y: CGFloat(html.yRatio * Double(wkWebView.scrollView.contentSize.height))) //
//
//        Thread.onMainThread {
//            wkWebView.scrollView.setContentOffset(contentOffset,animated: false)
//        }
    }
    
    func captureHTMLContentOffsetAndZoomScale()
    {
//        guard let wkWebView = wkWebView else {
//            return
//        }
//
//        if !wkWebView.isLoading {
//            html.xRatio = Double(wkWebView.scrollView.contentOffset.x) / Double(wkWebView.scrollView.contentSize.width)
//
//            html.yRatio = Double(wkWebView.scrollView.contentOffset.y) / Double(wkWebView.scrollView.contentSize.height)
//
//            html.zoomScale = Double(wkWebView.scrollView.zoomScale)
//        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (Globals.shared.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay //iPad only
            } else {
                if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        } else {
            if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                if let _ = nvc.visibleViewController as? WebViewController {
                    splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                } else {
                    splitViewController?.preferredDisplayMode = .automatic //iPad only
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard (self.view.window == nil) else {
            return
        }

        switch self.content {
        case .document:
            captureContentOffsetAndZoomScale()
            break

        case .pdf:
            break
            
        case .html:
            captureHTMLContentOffsetAndZoomScale()
            break
        }

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            switch self.content {
            case .document:
                self.setupWKContentOffset(self.wkWebView)
                break
                
            case .pdf:
                break
                
            case .html:
                self.setupHTMLWKZoomScaleAndContentOffset(self.wkWebView)
                break
            }
            
            // only works for popover
            if let title = self.navigationItem.title, let wkWebView = self.wkWebView {
                let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                
                let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 48.0)
                
                let width:CGFloat = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width + 150
                
                self.navigationController?.preferredContentSize = CGSize(width: max(width,wkWebView.scrollView.contentSize.width),
                                                                         height: wkWebView.scrollView.contentSize.height)
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.isToolbarHidden = true

        logo.isHidden = true
        
        setupActionButton()
        
        setupWKWebView()
        
        webView.bringSubview(toFront: activityIndicator)
        
        progressIndicator.isHidden = content == .html
    }
    
    var download : Download?
    
    @objc func downloaded(_ notification : NSNotification)
    {
        Thread.onMainThread {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self.download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self.download)
        }
        
        switch content {
        case .document:
            loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
            break
            
        case .pdf:
            loadPDF(urlString: pdfURLString)
            break
            
        default:
            break
        }
    }
    
    @objc func downloadFailed(_ notification : NSNotification)
    {
        Thread.onMainThread {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self.download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self.download)
        }
        
        switch content {
        case .document:
            break
            
        case .pdf:
            break
            
        default:
            break
        }
    }
    
    func loadPDF(urlString:String?)
    {
        guard let urlString = urlString else {
            return
        }
        
        if #available(iOS 9.0, *) {
            if Globals.shared.cacheDownloads {
                if let destinationURL = urlString.fileSystemURL, FileManager.default.fileExists(atPath: destinationURL.path) {
                    _ = wkWebView?.loadFileURL(destinationURL, allowingReadAccessTo: destinationURL)
                    
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                    
                    progressIndicator.progress = 0.0
                    progressIndicator.isHidden = true
                    
                    loadTimer?.invalidate()
                    loadTimer = nil
                    
//                    DispatchQueue.global(qos: .background).async { [weak self] in
//                        Thread.onMainThread {
//                        }
//                    }
                } else {
                    download = Download(mediaItem: nil, purpose: nil, downloadURL: urlString.url, fileSystemURL: urlString.fileSystemURL)
                    
                    if let download = download {
                        activityIndicator.isHidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = download.totalBytesExpectedToWrite != 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.isHidden = false

                        NotificationCenter.default.addObserver(self, selector: #selector(downloaded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: download)
                        NotificationCenter.default.addObserver(self, selector: #selector(downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: download)

                        download.download()
                    }
                }
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    Thread.onMainThread {
                        if let activityIndicator = self?.activityIndicator {
                            self?.webView.bringSubview(toFront: activityIndicator)
                        }

                        self?.activityIndicator.isHidden = false
                        self?.activityIndicator.startAnimating()

                        self?.progressIndicator.progress = 0.0
                        self?.progressIndicator.isHidden = false

                        if self?.loadTimer == nil, let target = self {
                            self?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: target, selector: #selector(self?.loading), userInfo: nil, repeats: true)
                        }
                    }

                    if let url = urlString.url {
                        let request = URLRequest(url: url)
                        _ = self?.wkWebView?.load(request)
                    }
                }
            }
        } else {
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.onMainThread {
                    if let activityIndicator = self?.activityIndicator {
                        self?.webView.bringSubview(toFront: activityIndicator)
                    }

                    self?.activityIndicator.isHidden = false
                    self?.activityIndicator.startAnimating()

                    self?.progressIndicator.progress = 0.0
                    self?.progressIndicator.isHidden = false

                    if self?.loadTimer == nil {
                        self?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self!, selector: #selector(self?.loading), userInfo: nil, repeats: true)
                    }
                }

                if let url = urlString.url {
                    let request = URLRequest(url: url)
                    _ = self?.wkWebView?.load(request)
                }
            }
        }
    }
    
//    func loadDocument()
//    {
//        if #available(iOS 9.0, *) {
//            if Globals.shared.cacheDownloads {
//                if let destinationURL = mediaItem?.fileSystemURL, FileManager.default.fileExists(atPath: destinationURL.path) {
//                    DispatchQueue.global(qos: .background).async { [weak self] in
//                        _ = self?.wkWebView?.loadFileURL(destinationURL, allowingReadAccessTo: destinationURL)
//
//                        Thread.onMainThread {
//                            self?.activityIndicator.stopAnimating()
//                            self?.activityIndicator.isHidden = true
//
//                            self?.progressIndicator.progress = 0.0
//                            self?.progressIndicator.isHidden = true
//
//                            self?.loadTimer?.invalidate()
//                            self?.loadTimer = nil
//                        }
//                    }
//                } else {
//                    activityIndicator.isHidden = false
//                    activityIndicator.startAnimating()
//
//                    if let download = mediaItem?.download {
//                        progressIndicator.progress = download.totalBytesExpectedToWrite != 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
//                        progressIndicator.isHidden = false
//
//                        download.download()
//                    }
//                }
//            } else {
//                DispatchQueue.global(qos: .background).async { [weak self] in
//                    Thread.onMainThread {
//                        if let activityIndicator = self?.activityIndicator {
//                            self?.webView.bringSubview(toFront: activityIndicator)
//                        }
//
//                        self?.activityIndicator.isHidden = false
//                        self?.activityIndicator.startAnimating()
//
//                        self?.progressIndicator.progress = 0.0
//                        self?.progressIndicator.isHidden = false
//
//                        if self?.loadTimer == nil, let target = self {
//                            self?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: target, selector: #selector(self?.loading), userInfo: nil, repeats: true)
//                        }
//                    }
//
//                    if let url = self?.mediaItem?.downloadURL {
//                        let request = URLRequest(url: url)
//                        _ = self?.wkWebView?.load(request)
//                    }
//                }
//            }
//        } else {
//            DispatchQueue.global(qos: .background).async { [weak self] in
//                Thread.onMainThread {
//                    if let activityIndicator = self?.activityIndicator {
//                        self?.webView.bringSubview(toFront: activityIndicator)
//                    }
//
//                    self?.activityIndicator.isHidden = false
//                    self?.activityIndicator.startAnimating()
//
//                    self?.progressIndicator.progress = 0.0
//                    self?.progressIndicator.isHidden = false
//
//                    if self?.loadTimer == nil {
//                        self?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self!, selector: #selector(self?.loading), userInfo: nil, repeats: true)
//                    }
//                }
//
//                if let url = self?.mediaItem?.downloadURL {
//                    let request = URLRequest(url: url)
//                    _ = self?.wkWebView?.load(request)
//                }
//            }
//        }
//    }
    
    @objc func setPreferredContentSize()
    {
        guard let title = navigationItem.title?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE),
                let size = wkWebView?.scrollView.contentSize else {
            return
        }
        
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.body.lineHeight)
        
        let width = title.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width + 150
        
        if let widthView = (presentingViewController?.view ?? view) {
            preferredContentSize = CGSize(width: max(width,widthView.frame.width),height: size.height)
        }
    }
    
    var orientation : UIDeviceOrientation?
    
    @objc func deviceOrientationDidChange()
    {
        guard let orientation = orientation else {
            return
        }
        
        func action()
        {
            ptvc?.dismiss(animated: false, completion: nil)
            activityViewController?.dismiss(animated: false, completion: nil)
        }
        
        // Dismiss any popover
        switch orientation {
        case .faceUp:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .faceDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeLeft:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeRight:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portrait:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portraitUpsideDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .unknown:
            break
        }
        
        switch UIDevice.current.orientation {
        case .faceUp:
            break
            
        case .faceDown:
            break
            
        case .landscapeLeft:
            self.orientation = UIDevice.current.orientation
            break
            
        case .landscapeRight:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portrait:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portraitUpsideDown:
            self.orientation = UIDevice.current.orientation
            break
            
        case .unknown:
            break
        }
    }
    
    @objc func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
//    var mask = false
    
    func addNotifications()
    {
//        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if let navigationController = navigationController, modalPresentationStyle != .popover {
            Alerts.shared.topViewController.append(navigationController)
        }
        
        addNotifications()
        
        if html.operationQueue.operationCount > 0 {
            activityButtonIndicator.startAnimating()
        }
        
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
        
        orientation = UIDevice.current.orientation

        if let title = mediaItem?.title {
            navigationItem.title = title
        }

        if let isHidden = wkWebView?.isHidden, isHidden {
            switch content {
            case .document:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                
//                loadDocument()
                
                loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
                break
                
            case .pdf:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()

                loadPDF(urlString: pdfURLString)
                break
                
            case .html:
                if html.string != nil {
                    html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
  
                    if let url = html.fileURL {
                        wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }

//                    if let htmlString = html.string {
//                        _ = wkWebView?.loadHTMLString(htmlString, baseURL: nil)
//                    }
                }
                break
            }
            
            preferredContentSize = CGSize(width: 0,height: 44)
            
            barButtonItems(isEnabled: false)
        } else {
            barButtonItems(isEnabled: true)
        }
    }

    func barButtonItems(isEnabled:Bool)
    {
        if let toolbarItems = self.navigationItem.rightBarButtonItems {
            for toolbarItem in toolbarItems {
                toolbarItem.isEnabled = isEnabled
            }
        }
        
        if let toolbarItems = self.navigationItem.leftBarButtonItems {
            for toolbarItem in toolbarItems {
                toolbarItem.isEnabled = isEnabled
            }
        }
        
        if let toolbarItems = self.toolbarItems {
            for toolbarItem in toolbarItems {
                toolbarItem.isEnabled = isEnabled
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        // WHY WERE THESE ADDED?
//        navigationItem.hidesBackButton = false
//        navigationController?.navigationBar.backItem?.title = Constants.Strings.Back
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
//        mask = false
        
        //Remove the next line and the app will crash
        wkWebView?.scrollView.delegate = nil
        
        loadTimer?.invalidate()
        
        if Alerts.shared.topViewController.last == navigationController {
            Alerts.shared.topViewController.removeLast()
        }

        Thread.onMainThread {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            dvc = visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            default:
                break
            }
        }
    }
}
