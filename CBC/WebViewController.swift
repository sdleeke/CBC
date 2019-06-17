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

class HTML
{
    deinit {
        debug(self)
    }
    
    weak var webViewController: WebViewController?
    
    var original:String?
    {
        didSet {
            
        }
    }
    
    var previousString:String?
    
    var _string:String?
    {
        didSet {
            if original == nil {
                original = _string
            }
            
            if previousString == nil {
                if string != oldValue {
                    previousString = oldValue
                }
            } else {
                if previousString != oldValue, _string != oldValue {
                    previousString = oldValue
                }
            }
            
            if _string != previousString, let isEmpty = _string?.isEmpty, !isEmpty {
                _string?.replacingOccurrences(of: Constants.UNBREAKABLE_SPACE, with: Constants.SINGLE_SPACE).save16(filename:fileURL?.lastPathComponent)
            }
        }
    }
    var string:String?
    {
        get {
            return _string
        }
        set {
            var newString = newValue
            
            // Why are we doing this?
            newString = newString?.replacingOccurrences(of: Constants.LEFT_DOUBLE_QUOTE, with: Constants.DOUBLE_QUOTE)
            newString = newString?.replacingOccurrences(of: Constants.RIGHT_DOUBLE_QUOTE, with: Constants.DOUBLE_QUOTE)
            
            newString = newString?.replacingOccurrences(of: Constants.LEFT_SINGLE_QUOTE, with: Constants.SINGLE_QUOTE)
            newString = newString?.replacingOccurrences(of: Constants.RIGHT_SINGLE_QUOTE, with: Constants.SINGLE_QUOTE)
            
            newString = newString?.replacingOccurrences(of: Constants.EM_DASH, with: Constants.DASH)

            _string = newString
        }
    }

    var fileURL : URL?
    {
        get {
            if let isEmpty = string?.isEmpty, !isEmpty {
                return "string.html".fileSystemURL
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

extension WebViewController : UIActivityItemSource
{
    func share()
    {
        guard let html = self.html.string else {
            return
        }
        
        // Must be on main thread.
        let print = UIMarkupTextPrintFormatter(markupText: html)
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        let activityViewController = CBCActivityViewController(activityItems:[self,print] , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ]
        
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

        // present the view controller
        Alerts.shared.blockPresent(presenting: self, presented: activityViewController, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivity.ActivityType] = [.mail,.print,.openInIBooks]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        guard let activityType = activityType else {
            return nil
        }

        if #available(iOS 11.0, *) {
            WebViewController.cases.append(.markupAsPDF)
        }
        
        switch activityType {

        default:
            if WebViewController.cases.contains(activityType) {
                return self.html.string
            }
        }
        
        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return mediaItem?.text?.singleLine ?? (self.navigationItem.title ?? "") // (transcript?.mediaItem?.text?.singleLine ?? )
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
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

extension WebViewController : PopoverPickerControllerDelegate
{
    // MARK: PopoverPickerControllerDelegate
    
    func stringPicked(_ string: String?, purpose:PopoverPurpose?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "WebViewController:stringPicked", completion: nil)
            return
        }
        
        guard let string = string else {
            return
        }
        
        dismiss(animated: true, completion: nil)

        self.navigationController?.popToRootViewController(animated: true) // Why are we doing this?
        
        let searchText = string.word ?? string

        self.wkWebView?.isHidden = true
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        if bodyHTML != nil { // , headerHTML != nil // Not necessary
            html.string = bodyHTML?.markHTML(headerHTML: headerHTML, searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true).0
        }

        html.string = html.string?.stripHead.insertHead(fontSize: html.fontSize)
        
        if let url = self.html.fileURL {
            wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
}

extension WebViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return nil
    }
    
    func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    @objc func showFullScreen()
    {
        let vc = presentingViewController
        
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

            popover.bodyHTML = self.bodyHTML
            popover.headerHTML = self.headerHTML

            popover.content = self.content

            popover.navigationController?.isNavigationBarHidden = false
            
            vc?.present(navigationController, animated: true, completion: nil) // Globals.shared.splitViewController
        }
    }

    func selectingAction(action: String?, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.Full_Screen:
            showFullScreen()
            
        case Constants.Strings.Print:
            if let string = html.string, string.contains(" href=") {
                self.firstSecondCancel(title: "Remove Links?", // message: nil, //"This can take some time.",
                    firstTitle: Constants.Strings.Yes,
                    firstAction: { [weak self] in
                        // test:(()->(Bool))?
                        self?.process(work: { [weak self] () -> (Any?) in
                            return self?.html.string?.stripLinks
                        }, completion: { [weak self] (data:Any?) in
                            if let vc = self {
                                vc.printHTML(htmlString: data as? String)
                            }
                        })
                }, firstStyle: .default,
                   secondTitle: Constants.Strings.No,
                   secondAction: { [weak self] in
                    self?.printHTML(htmlString: self?.html.string)
                }, secondStyle: .default)
            } else {
                self.printHTML(htmlString: self.html.string)
            }
            
        case Constants.Strings.Share:
            // Delay before menu comes down by not dispatching or delay before share menu comes up by doing so?
            // Because share is on the main thread I'm not even sure an activity view would run.
            share()
//            DispatchQueue.global(qos: .background).async {
//                Thread.onMain {
//                    self.share()
//                }
//            }
            
        case Constants.Strings.Search:
            let alert = CBCAlertController( title: Constants.Strings.Search,
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            alert.addTextField(configurationHandler: { (textField:UITextField) in
                textField.placeholder = self.searchText ?? "search string"
            })
            
            let search = UIAlertAction(title: "Search", style: UIAlertAction.Style.default, handler: { [weak self]
                (action : UIAlertAction!) -> Void in
                self?.searchText = alert.textFields?[0].text
                
                self?.wkWebView?.isHidden = true
                
                self?.activityIndicator.isHidden = false
                self?.activityIndicator.startAnimating()
                
                if let isEmpty = self?.searchText?.isEmpty, isEmpty {
                    self?.html.string = self?.html.original?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                } else {
                    if self?.bodyHTML != nil { // , self.headerHTML != nil // Not necessary
                        self?.html.string = self?.bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:self?.searchText, wholeWordsOnly: false, lemmas: false, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    } else {
                        self?.html.string = self?.html.original?.markHTML(searchText:self?.searchText, wholeWordsOnly: false, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    }
                }
                
                if let url = self?.html.fileURL {
                    self?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }
            })
            alert.addAction(search)
            
            let searchWhole = UIAlertAction(title: "Search - Whole Words Only", style: UIAlertAction.Style.default, handler: { [weak self]
                (action : UIAlertAction!) -> Void in
                self?.searchText = alert.textFields?[0].text
                
                self?.wkWebView?.isHidden = true
                
                self?.activityIndicator.isHidden = false
                self?.activityIndicator.startAnimating()
                
                if let isEmpty = self?.searchText?.isEmpty, isEmpty {
                    self?.html.string = self?.html.original?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                } else {
                    if self?.bodyHTML != nil { // , self.headerHTML != nil // Not necessary
                        self?.html.string = self?.bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:self?.searchText, wholeWordsOnly: true, lemmas: false, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    } else {
                        self?.html.string = self?.html.original?.markHTML(searchText:self?.searchText, wholeWordsOnly: true, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    }
                }
                
                if let url = self?.html.fileURL {
                    self?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }
            })
            alert.addAction(searchWhole)
            
            let clear = UIAlertAction(title: "Clear", style: UIAlertAction.Style.destructive, handler: { [weak self]
                (action : UIAlertAction!) -> Void in
                self?.searchText = ""
                
                self?.wkWebView?.isHidden = true
                
                self?.activityIndicator.isHidden = false
                self?.activityIndicator.startAnimating()
                
                if let isEmpty = self?.searchText?.isEmpty, isEmpty {
                    self?.html.string = self?.html.original?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                } else {
                    if self?.bodyHTML != nil { // , self.headerHTML != nil // Not necessary
                        self?.html.string = self?.bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:self?.searchText, wholeWordsOnly: false, lemmas: false, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    } else {
                        self?.html.string = self?.html.original?.markHTML(searchText:self?.searchText, wholeWordsOnly: false, index: true).0?.stripHead.insertHead(fontSize: self?.html.fontSize ?? Constants.FONT_SIZE)
                    }
                }
                
                if let url = self?.html.fileURL {
                    self?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                }
            })
            alert.addAction(clear)
            
            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                (action : UIAlertAction!) -> Void in
            })
            alert.addAction(cancel)
            
            Alerts.shared.blockPresent(presenting: self, presented: alert, animated: true)
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self

                popover.navigationController?.isNavigationBarHidden = false

                popover.delegate = self

                popover.allowsSelection = search
                
                popover.navigationItem.title = navigationItem.title?.qualifier(Constants.Strings.Word_Picker)
                
                popover.stringsFunction = { [weak self] in
                    // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                    return self?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> String in
                        return word
                    }).sorted()
                }

                present(navigationController, animated: true, completion: nil)
            }
            
        case Constants.Strings.Word_Cloud:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WORD_CLOUD) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? CloudViewController {
                navigationController.modalPresentationStyle = .fullScreen
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.cloudTitle = navigationItem.title?.qualifier(Constants.Strings.Word_Cloud)
                
                if let mediaItem = mediaItem {
                    popover.cloudTitle = mediaItem.title
                }
                
                popover.cloudString = self.bodyHTML?.html2String
                
                popover.cloudWordDictsFunction = { [weak self] in
                    let words = self?.bodyHTML?.html2String?.tokensAndCounts?.map({ (word:String,count:Int) -> [String:Any] in
                        return ["word":word,"count":count,"selected":true]
                    })
                    
                    return words
                }

                popover.cloudFont = UIFont.preferredFont(forTextStyle:.body)
                
                present(navigationController, animated: true, completion:  nil)
            }
            
        case Constants.Strings.Word_Index:
            self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                return self?.bodyHTML?.html2String?.tokensAndCounts?.map({ [weak self] (word:String,count:Int) -> String in
                    // By using cache this only looks at mismatches if they are loaded
                    if let mismatches = self?.mediaItem?.notesTokensMarkMismatches?.cache {
                        var dict = [String:(String,String)]()
                        for mismatch in mismatches {
                            let parts = mismatch.components(separatedBy: " ")
                            dict[parts[0]] = (parts[1],parts[2])
                        }
                        if let tuple = dict[word] {
                            return "\(word) (\(count)) (\(tuple.0),\(tuple.1)) "
                        } else {
                            return "\(word) (\(count))"
                        }
                    } else {
                        return "\(word) (\(count))"
                    }
                }).sorted().tableHTML(title:self?.navigationItem.title?.qualifier(Constants.Strings.Word_Index), test:test)
            }, completion: { [weak self] (data:Any?,test:(()->(Bool))?) in
                self?.presentHTMLModal(mediaItem: nil, style: .overCurrentContext, title: self?.navigationItem.title?.qualifier(Constants.Strings.Word_Index), htmlString: data as? String)
            })
            
        case Constants.Strings.Words:
            self.selectWord(title:navigationItem.title?.qualifier(Constants.Strings.Words), purpose:.selectingWord, allowsSelection:false, stringsFunction:{ [weak self] in
                // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                
                return self?.bodyHTML?.html2String?.tokensAndCounts?.map({ [weak self] (word:String,count:Int) -> String in
                    // By using cache this only looks at mismatches if they are loaded
                    if let mismatches = self?.mediaItem?.notesTokensMarkMismatches?.cache {
                        var dict = [String:(String,String)]()
                        for mismatch in mismatches {
                            let parts = mismatch.components(separatedBy: " ")
                            dict[parts[0]] = (parts[1],parts[2])
                        }
                        if let tuple = dict[word] {
                            return "\(word) (\(count)) (\(tuple.0),\(tuple.1)) "
                        } else {
                            return "\(word) (\(count))"
                        }
                    } else {
                        return "\(word) (\(count))"
                    }
                }).sorted()
            })
            
        case Constants.Strings.Word_Search:
            self.selectWord(title:Constants.Strings.Search, purpose:.selectingWord, stringsFunction:{ [weak self] in
                // tokens is a generated results, i.e. get only, which takes time to derive from another data structure
                
                return self?.bodyHTML?.html2String?.tokensAndCounts?.map({ [weak self] (word:String,count:Int) -> String in
                    // By using cache this only looks at mismatches if they are loaded
                    if let mismatches = self?.mediaItem?.notesTokensMarkMismatches?.cache {
                        var dict = [String:(String,String)]()
                        for mismatch in mismatches {
                            let parts = mismatch.components(separatedBy: " ")
                            dict[parts[0]] = (parts[1],parts[2])
                        }
                        if let tuple = dict[word] {
                            return "\(word) (\(count)) (\(tuple.0),\(tuple.1)) "
                        } else {
                            return "\(word) (\(count))"
                        }
                    } else {
                        return "\(word) (\(count))"
                    }
                }).sorted()
            })

        case Constants.Strings.Email_One:
            if let title = navigationItem.title, let htmlString = html.string {
                self.mailHTML(to: [], subject: Constants.CBC.LONG + Constants.SINGLE_SPACE + title, htmlString: htmlString)
            }
            
        case Constants.Strings.Refresh_Document:
            mediaItem?.download?.delete(block:true)
            
            wkWebView?.isHidden = true
            wkWebView?.removeFromSuperview()
            
            webView.bringSubviewToFront(activityIndicator)
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            setupWKWebView()
            
            loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
            
        case Constants.Strings.Lexical_Analysis:
            self.process(disableEnable: false, work: { (test:(()->(Bool))?) -> (Any?) in
                if #available(iOS 12.0, *) {
                    return self.bodyHTML?.stripHTML.nlNameAndLexicalTypesMarkup(annotated:true, test:test)
                } else {
                    // Fallback on earlier versions
                    return self.bodyHTML?.stripHTML.nsNameAndLexicalTypesMarkup(annotated:true, test:test)
                }
            }) { (data:Any?,test:(()->(Bool))?) in
                guard test?() != true else {
                    return
                }
                
                guard let data = data else {
                    Alerts.shared.alert(title:"Lexical Analysis Not Available")
                    return
                }
                
                if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? WebViewController {
                    
                    popover.navigationItem.title = self.navigationItem.title?.qualifier(Constants.Strings.Lexical_Analysis)
                    
                    navigationController.isNavigationBarHidden = false
                    
                    navigationController.modalPresentationStyle = .overCurrentContext
                    navigationController.popoverPresentationController?.delegate = self
                    
                    popover.html.string = data as? String
                    popover.content = .html
                    
                    self.present(navigationController, animated: true, completion: nil)
                }
            }

        default:
            break
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }

        let string = strings[index]
        
        switch purpose {
        case .selectingWord:
            guard search else {
                return
            }
            
            popover?["WORD"]?.dismiss(animated: true, completion: nil)
            
            self.navigationController?.popToRootViewController(animated: true) // Why are we doing this?
            
            let searchText = string.word ?? string
            
            wkWebView?.isHidden = true
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            // This serializes the webView loading
            operationQueue.addOperation { [weak self] in
                if self?.bodyHTML != nil { // , self?.headerHTML != nil // Not necessary
                    self?.html.string = self?.bodyHTML?.markHTML(headerHTML: self?.headerHTML, searchText:searchText, wholeWordsOnly: true, lemmas: false, index: true).0
                }
                
                if let fontSize = self?.html.fontSize {
                    self?.html.string = self?.html.string?.stripHead.insertHead(fontSize: fontSize)
                    
                    if let url = self?.html.fileURL {
                        Thread.onMain {
                            self?.wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                        }
                    }
                }
            }
            
        case .selectingAction:
            popover?["ACTION"]?.dismiss(animated: true, completion: nil)
            selectingAction(action: string, mediaItem:mediaItem)
            
        default:
            break
        }
    }
}

//extension WebViewController : MFMailComposeViewControllerDelegate
//{
//    // MARK: MFMailComposeViewControllerDelegate Method
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        controller.dismiss(animated: true, completion: nil)
//    }
//}

extension WebViewController : WKNavigationDelegate
{
    // MARK: WKNavigationDelegate

    func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!)
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
        
        Thread.onMain {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            
            self.progressIndicator.isHidden = true
            
            self.barButtonItems(isEnabled: true)

            wkWebView.isHidden = false
        }
    }
    
    func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError: Error)
    {
        if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed || (self == navigationController?.visibleViewController) {
            print("wkDidFail navigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            self.networkUnavailable(withError.localizedDescription)
            NSLog(withError.localizedDescription)
        }
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error)
    {
        if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed || (self == navigationController?.visibleViewController) {
            print("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            self.networkUnavailable(withError.localizedDescription)
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
                UIApplication.shared.open(scheme: navigationAction.request.url?.absoluteString) {}
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
            
        case .other: // loading html string
            decisionHandler(WKNavigationActionPolicy.allow)
            
        default:
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }
}

extension WebViewController: UIScrollViewDelegate
{
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
    
            case .pdf:
                break

            case .html:
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
    
            case .pdf:
                break
                
            case .html:
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
    
            case .pdf:
                break
                
            case .html:
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

class WebViewController: CBCViewController
{
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "WebViewController" // Assumes there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

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
    
    lazy var html:HTML! = { [weak self] in
        let html = HTML()
        html.webViewController = self
        return html
    }()
    
    var loadTimer:Timer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var logo: UIImageView!
    
    @objc func updateDownload()
    {
        if let download = mediaItem?.download {
            switch download.state {
            case .none:
                break
                
            case .downloading:
                progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                
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

                Thread.onMain {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    self.wkWebView?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.webView.bringSubviewToFront(self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    self.networkUnavailable("Document could not be loaded.")
                }
                
            case .downloaded:
                break
            }
        }
    }
    
    var bodyHTML : String?
    var headerHTML : String?
    
    var mediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if oldValue != nil {
                Thread.onMain {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: oldValue?.download)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: oldValue?.download)
                }
            }

            if mediaItem != nil {
                Thread.onMain {
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
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
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
        
        let top = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutConstraint.Attribute.topMargin, relatedBy: NSLayoutConstraint.Relation.equal, toItem: wkWebView.superview, attribute: NSLayoutConstraint.Attribute.topMargin, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(top)
        
        let bottom = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutConstraint.Attribute.bottomMargin, relatedBy: NSLayoutConstraint.Relation.equal, toItem: wkWebView.superview, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(bottom)
        
        let leading = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutConstraint.Attribute.leadingMargin, relatedBy: NSLayoutConstraint.Relation.equal, toItem: wkWebView.superview, attribute: NSLayoutConstraint.Attribute.leadingMargin, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(leading)
        
        let trailing = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutConstraint.Attribute.trailingMargin, relatedBy: NSLayoutConstraint.Relation.equal, toItem: wkWebView.superview, attribute: NSLayoutConstraint.Attribute.trailingMargin, multiplier: 1.0, constant: 0.0)
        wkWebView.superview?.addConstraint(trailing)
        
        wkWebView.superview?.setNeedsLayout()
    }
    
    @objc func done()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "WebViewController:done", completion: nil)
            return
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        if (html.string != nil) && search {
            actionMenu.append(Constants.Strings.Search)
            
            if (bodyHTML != nil) {
                actionMenu.append(Constants.Strings.Word_Search)
            }
        }
        
        if (bodyHTML != nil) {
            if !search {
                actionMenu.append(Constants.Strings.Words)
            }
            actionMenu.append(Constants.Strings.Word_Index)
            actionMenu.append(Constants.Strings.Word_Picker)
        }

        if (bodyHTML != nil) {
            if Globals.shared.splitViewController?.isCollapsed == false {
                let vClass = Globals.shared.splitViewController?.traitCollection.verticalSizeClass
                let hClass = Globals.shared.splitViewController?.traitCollection.horizontalSizeClass
                
                if vClass != .compact, hClass != .compact {
                    actionMenu.append(Constants.Strings.Word_Cloud)
                }
            }
            actionMenu.append(Constants.Strings.Lexical_Analysis)
        }
        
        if self.navigationController?.modalPresentationStyle == .popover {
            actionMenu.append(Constants.Strings.Full_Screen)
        }
        
        if html.string != nil {
            actionMenu.append(Constants.Strings.Share)
        }
        
        if UIPrintInteractionController.isPrintingAvailable {
            actionMenu.append(Constants.Strings.Print)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
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
            
            popover.section.strings = actionMenu()
            
            self.popover?["ACTION"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["ACTION"] = nil
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func increaseFontSize()
    {
        html.fontSize += 1
        
        Thread.onMain {
            if self.html.fontSize > Constants.HTML_MIN_FONT_SIZE {
                self.minusButton?.isEnabled = true
            }
            
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }

        html.string = html.string?.stripHead.insertHead(fontSize: html.fontSize)

        if let url = html.fileURL {
            wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
    
    @objc func decreaseFontSize()
    {
        if html.fontSize > Constants.HTML_MIN_FONT_SIZE {
            html.fontSize -= 1
            
            Thread.onMain {
                if self.html.fontSize <= Constants.HTML_MIN_FONT_SIZE {
                    self.minusButton?.isEnabled = false
                }
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            
            html.string = html.string?.stripHead.insertHead(fontSize: html.fontSize)

            if let url = html.fileURL {
                wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
            }
        }
    }
    
    fileprivate func setupActionButton()
    {
        fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItem.Style.plain, target: self, action: #selector(showFullScreen))
        fullScreenButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(increaseFontSize))
        plusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(decreaseFontSize))
        minusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        activityButtonIndicator = UIActivityIndicatorView()
        activityButtonIndicator.style = .gray
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
                // This allows the back button to show. >1 implies it is below the top view controller in a push stack.
                if self.navigationController?.viewControllers.count == 1 {
                    navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done)), animated: true)

                    if Globals.shared.splitViewController?.isCollapsed == false {
                        navigationItem.setRightBarButtonItems([actionButton,fullScreenButton,minusButton,plusButton,activityButton], animated: true)
                    } else {
                        navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
                    }
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
                navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done)), animated: true)
                navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
                
            default:
                navigationItem.setRightBarButtonItems([actionButton,minusButton,plusButton,activityButton], animated: true)
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
        Thread.onMain {
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
        
        var contentOffsetXStr:String?
        var contentOffsetYStr:String?
        
        contentOffsetXStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X]
        contentOffsetYStr = mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y]
        
        var contentOffsetX:CGFloat = 0.0
        var contentOffsetY:CGFloat = 0.0

        if let x = contentOffsetXStr, let num = Float(x) {
            contentOffsetX = CGFloat(num)
        }
        
        if let y = contentOffsetYStr, let num = Float(y) {
            contentOffsetY = CGFloat(num)
        }
        
        let contentOffset = CGPoint(x: CGFloat(contentOffsetX), //
                                    y: CGFloat(contentOffsetY)) //
        
        Thread.onMain {
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
            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_X] = "\(wkWebView.scrollView.contentOffset.x)"
            
            mediaItem.mediaItemSettings?[showing + Constants.CONTENT_OFFSET_Y] = "\(wkWebView.scrollView.contentOffset.y)"
            
            mediaItem.mediaItemSettings?[showing + Constants.ZOOM_SCALE] = "\(wkWebView.scrollView.zoomScale)"
        }
    }
    
//    func setupSplitViewController()
//    {
//        if (UIDevice.current.orientation.isPortrait) {
//            if (Globals.shared.media.all == nil) {
//                splitViewController?.preferredDisplayMode = .primaryOverlay //iPad only
//            } else {
//                if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                    if let _ = nvc.visibleViewController as? WebViewController {
//                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
//                    } else {
//                        splitViewController?.preferredDisplayMode = .automatic //iPad only
//                    }
//                }
//            }
//        } else {
//            if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                if let _ = nvc.visibleViewController as? WebViewController {
//                    splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
//                } else {
//                    splitViewController?.preferredDisplayMode = .automatic //iPad only
//                }
//            }
//        }
//    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard (self.view.window == nil) else {
            return
        }

        switch self.content {
        case .document:
            captureContentOffsetAndZoomScale()

        case .pdf:
            break
            
        case .html:
            break
        }

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            switch self.content {
            case .document:
                self.setupWKContentOffset(self.wkWebView)
                
            case .pdf:
                break
                
            case .html:
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
        setupActionButton()
        setupWKWebView()
    }
    
    var download : Download?
    
    @objc func downloaded(_ notification : NSNotification)
    {
        Thread.onMain {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self.download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self.download)
        }
        
        switch content {
        case .document:
            loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
            
        case .pdf:
            loadPDF(urlString: pdfURLString)
            
        default:
            break
        }
    }
    
    @objc func downloadFailed(_ notification : NSNotification)
    {
        Thread.onMain {
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
        
        if Globals.shared.settings.cacheDownloads {
            if let destinationURL = urlString.fileSystemURL, FileManager.default.fileExists(atPath: destinationURL.path) {
                _ = wkWebView?.loadFileURL(destinationURL, allowingReadAccessTo: destinationURL)
                
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                progressIndicator.progress = 0.0
                progressIndicator.isHidden = true
                
                loadTimer?.invalidate()
                loadTimer = nil
            } else {
                download = Download(mediaItem: nil, purpose: nil, downloadURL: urlString.url) // , fileSystemURL: urlString.fileSystemURL
                
                if let download = download {
                    activityIndicator.isHidden = false
                    activityIndicator.startAnimating()
                    
                    progressIndicator.progress = download.totalBytesExpectedToWrite != 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                    progressIndicator.isHidden = false

                    NotificationCenter.default.addObserver(self, selector: #selector(downloaded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: download)
                    NotificationCenter.default.addObserver(self, selector: #selector(downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: download)

                    download.download(background: false)
                }
            }
        } else {
            if let activityIndicator = activityIndicator {
                webView.bringSubviewToFront(activityIndicator)
            }
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            progressIndicator.progress = 0.0
            progressIndicator.isHidden = false
            
            if loadTimer == nil {
                loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: target, selector: #selector(loading), userInfo: nil, repeats: true)
            }

            if let url = urlString.url {
                let request = URLRequest(url: url)
                _ = wkWebView?.load(request)
            }
        }
    }
    
    @objc func setPreferredContentSize()
    {
        guard navigationController?.modalPresentationStyle == .popover else {
            return
        }
        
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
    
    func addNotifications()
    {
//        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addNotifications()
        
        navigationController?.isToolbarHidden = true
        
        logo.isHidden = true
        
        webView.bringSubviewToFront(activityIndicator)
        
        progressIndicator.isHidden = content == .html

        if let title = mediaItem?.title {
            navigationItem.title = title
        }

        if let isHidden = wkWebView?.isHidden, isHidden {
            switch content {
            case .document:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
    
            case .pdf:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
    
            case .html:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                }

            preferredContentSize = CGSize(width: 0,height: 44)

            barButtonItems(isEnabled: false)
        } else {
            barButtonItems(isEnabled: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if let isHidden = wkWebView?.isHidden, isHidden {
            switch content {
            case .document:
                loadPDF(urlString: mediaItem?.downloadURL?.absoluteString)
                
            case .pdf:
                loadPDF(urlString: pdfURLString)
                
            case .html:
                if html.string != nil {
                    html.string = html.string?.stripHead.insertHead(fontSize: html.fontSize)
                    
                    if let url = html.fileURL {
                        wkWebView?.loadFileURL(url, allowingReadAccessTo: url)
                    }
                } else {
                    activityIndicator.stopAnimating()
                    barButtonItems(isEnabled: true)
                }
            }
        } else {

        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
                
        //Remove the next line and the app will crash
        wkWebView?.scrollView.delegate = nil
        
        loadTimer?.invalidate()
        loadTimer = nil
        
        Thread.onMain {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func didReceiveMemoryWarning()
    {
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
