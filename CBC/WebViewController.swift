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

struct HTML {
    var original:String?
    
    var string:String?
    {
        didSet {
            if original == nil {
                original = string
            }
        }
    }
    var fontSize = Constants.FONT_SIZE
    var xRatio = 0.0
    var yRatio = 0.0
    var zoomScale = 0.0
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
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:stringPicked", completion: nil)
            return
        }
        
        self.dismiss(animated: true, completion: nil)

        self.navigationController?.popToRootViewController(animated: true)
        
        var searchText = string
        
        if let range = searchText?.range(of: " (") {
            searchText = searchText?.substring(to: range.lowerBound)
        }
        
        self.wkWebView?.isHidden = true
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        html.string = selectedMediaItem?.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true, index: true)
        html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
        
        _ = self.wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
    }
}

extension WebViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func cancel()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func shareHTML(_ htmlString:String?)
    {
        guard htmlString != nil else {
            return
        }
        
        let activityItems = [htmlString as Any]
        
        activityViewController = UIActivityViewController(activityItems:activityItems , applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        
        activityViewController?.excludedActivityTypes = [ .addToReadingList ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
        activityViewController?.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        // present the view controller
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(self.activityViewController!, animated: false, completion: nil)
        })
    }
    
    func showFullScreen()
    {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? WebViewController {
            
            navigationController.modalPresentationStyle = .overFullScreen
            navigationController.popoverPresentationController?.delegate = popover
            
            popover.navigationItem.title = self.navigationItem.title
            
            popover.html.fontSize = self.html.fontSize
            popover.html.string = self.html.string
            
            popover.search = self.search
            popover.selectedMediaItem = self.selectedMediaItem
            
            popover.content = self.content
            
            popover.navigationController?.isNavigationBarHidden = false
            
            present(navigationController, animated: true, completion: nil)
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
            if html.string != nil, html.string!.contains(" href=") {
                firstSecondCancel(viewController: self, title: "Remove Links?", message: "This can take some time.",
                                  firstTitle: "Yes",
                                  firstAction: {
                                        process(viewController: self, work: { () -> (Any?) in
                                            return stripLinks(self.html.string)
                                        }, completion: { (data:Any?) in
                                            printHTML(viewController: self, htmlString: data as? String)
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
            shareHTML(html.string)
            break
            
        case Constants.Strings.Search:
            searchAlert(viewController: self, title: "Search", message: nil, searchText:searchText, searchAction:  { (alert:UIAlertController) -> (Void) in
                self.searchText = (alert.textFields![0] as UITextField).text
                
                if let isEmpty = self.searchText?.isEmpty, isEmpty, self.html.string == self.html.original {
                    return
                }
                
                self.wkWebView?.isHidden = true
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                
                if self.selectedMediaItem != nil {
                    self.html.string = insertHead(stripHead(self.selectedMediaItem?.markedFullNotesHTML(searchText:self.searchText, wholeWordsOnly: false, index: true)),fontSize: self.html.fontSize)
                } else {
                    self.html.string = insertHead(stripHead(self.markedHTML(searchText:self.searchText, wholeWordsOnly: false, index: true)),fontSize: self.html.fontSize)
                }
                
                _ = self.wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
            })
//            let alert = UIAlertController(title: "Search",
//                                          message: Constants.EMPTY_STRING,
//                                          preferredStyle: .alert)
//            
//            alert.addTextField(configurationHandler: { (textField:UITextField) in
//                textField.placeholder = "search string"
//            })
//            
//            let searchAction = UIAlertAction(title: "Search", style: UIAlertActionStyle.default, handler: {
//                alertItem -> Void in
//                let searchText = (alert.textFields![0] as UITextField).text
//                
//                self.wkWebView?.isHidden = true
//                
//                self.activityIndicator.isHidden = false
//                self.activityIndicator.startAnimating()
//                
//                self.html.string = insertHead(stripHead(self.selectedMediaItem?.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: false, index: true)),fontSize: self.html.fontSize)
//                
//                _ = self.wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
//            })
//            alert.addAction(searchAction)
//            
//            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
//                (action : UIAlertAction!) -> Void in
//            })
//            alert.addAction(cancelAction)
//            
//            present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                navigationController.modalPresentationStyle = .overCurrentContext

                navigationController.popoverPresentationController?.delegate = self

                popover.navigationController?.isNavigationBarHidden = false

                popover.navigationItem.title = Constants.Strings.Word_Picker

                popover.delegate = self

                popover.mediaListGroupSort = MediaListGroupSort(mediaItems: [selectedMediaItem!])

                let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.cancel))
                popover.navigationItem.leftBarButtonItem = cancelButton

                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Words:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = Constants.Strings.Words
                
                popover.delegate = self
                popover.purpose = .selectingWord
                
                popover.sort.function = sort
                
                popover.section.showIndex = true
                popover.section.showHeaders = true
                
                popover.search = true
                
                if mediaItem!.hasNotesHTML {
                    if mediaItem?.notesTokens == nil {
                        popover.stringsFunction = {
                            mediaItem?.loadNotesTokens()

                            return mediaItem?.notesTokens?.map({ (string:String,count:Int) -> String in
                                return "\(string) (\(count))"
                            }).sorted()
                        }
                    } else {
                        popover.section.strings = mediaItem?.notesTokens?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                    }
                }
                
                popover.vc = self
                
                let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.cancel))
                popover.navigationItem.leftBarButtonItem = cancelButton

                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Email_One:
            mailHTML(viewController: self, to: [], subject: Constants.CBC.LONG + Constants.SINGLE_SPACE + navigationItem.title!, htmlString: html.string!)
            break
            
        case Constants.Strings.Open_in_Browser:
            if selectedMediaItem?.downloadURL != nil {
                if (UIApplication.shared.canOpenURL(selectedMediaItem!.downloadURL!)) { // Reachability.isConnectedToNetwork() &&
                    UIApplication.shared.openURL(selectedMediaItem!.downloadURL!)
                } else {
                    networkUnavailable(self,"Unable to open in browser at: \(selectedMediaItem!.downloadURL!)")
                }
            }
            break
            
        case Constants.Strings.Refresh_Document:
            selectedMediaItem?.download?.delete()
            
            wkWebView?.isHidden = true
            wkWebView?.removeFromSuperview()
            
            webView.bringSubview(toFront: activityIndicator)
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            setupWKWebView()
            
            loadDocument()
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
            self.navigationController?.popToRootViewController(animated: true)
            
            var searchText = string
            
            if let range = searchText.range(of: " (") {
                searchText = searchText.substring(to: range.lowerBound)
            }
            
            wkWebView?.isHidden = true
            
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            html.string = selectedMediaItem?.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true, index: true)
            html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
            
            _ = wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
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

    func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!) {
        setupWKZoomScaleAndContentOffset(wkWebView)
        setupHTMLWKZoomScaleAndContentOffset(wkWebView)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            
            self.progressIndicator.isHidden = true
            
            self.barButtonItems(isEnabled: true)
            
            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: 0.1) // This is ESSENTIAL to allow the preferred content size to be set correctly.
                
                DispatchQueue.main.async(execute: { () -> Void in
                    //                    print(wkWebView.scrollView.contentSize.width,wkWebView.scrollView.contentSize.height)
                    
                    wkWebView.isHidden = false
                    wkWebView.scrollView.contentOffset = CGPoint(x: 0, y: 0)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
                })
            }
        })
    }
    
    func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError: Error) {
        if (splitViewController?.viewControllers.count > 1) || (self == navigationController?.visibleViewController) {
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
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        if (splitViewController?.viewControllers.count > 1) || (self == navigationController?.visibleViewController) {
            print("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(self,withError.localizedDescription)
            NSLog(withError.localizedDescription)
        }
    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        //        print("wkDidStartProvisionalNavigation")
        
    }
    
    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        //        print(navigationAction.request.url!.absoluteString)
        //        print(navigationAction.navigationType.rawValue)
        
        if (navigationAction.navigationType == .other) {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            //            print(navigationAction.request.url?.absoluteString)
            if let url = navigationAction.request.url?.absoluteString, let range = url.range(of: "%23") {
                let tag = url.substring(to: range.lowerBound)
                
                if tag == "about:blank" {
                    decisionHandler(WKNavigationActionPolicy.allow)
                } else {
                    decisionHandler(WKNavigationActionPolicy.cancel)
                }
            } else {
                if let url = navigationAction.request.url {
                    if UIApplication.shared.canOpenURL(url) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.shared.openURL(url)
                    }
                }
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
        }
    }
}

extension WebViewController: UIScrollViewDelegate
{
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //        print("scrollViewDidZoom")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        //        print("scrollViewDidEndZooming")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        print("scrollViewDidScroll")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //        print("scrollViewDidEndScrollingAnimation")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        //        print("scrollViewDidEndDecelerating")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .html:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        //        print("scrollViewDidEndDragging")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}

extension WebViewController: UIPopoverPresentationControllerDelegate
{

}

class WebViewController: UIViewController
{
    var search = false
    var searchText:String?
    
    enum Content {
        case document
        case html
    }
    
    var actionButton:UIBarButtonItem?
    var minusButton:UIBarButtonItem?
    var plusButton:UIBarButtonItem?
    
    var wkWebView:WKWebView?

    var content:Content = .document
    
    var html = HTML()
    
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
        
        guard let isEmpty = searchText?.isEmpty, !isEmpty else {
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
            
            while (string.lowercased().range(of: searchText!.lowercased()) != nil) {
                //                print(string)
                
                if let range = string.lowercased().range(of: searchText!.lowercased()) {
                    stringBefore = string.substring(to: range.lowerBound)
                    stringAfter = string.substring(from: range.upperBound)
                    
                    var skip = false
                    
                    let tokenDelimiters = "$\"' :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.QUOTES
                    
                    if wholeWordsOnly {
                        if let characterAfter:Character = stringAfter.characters.first {
                            if !CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterAfter))!) {
                                skip = true
                            }
                            
                            //                            print(characterAfter)
                            if stringAfter.endIndex >= "'s".endIndex {
                                if (stringAfter.substring(to: "'s".endIndex) == "'s") {
                                    skip = false
                                }
                                if (stringAfter.substring(to: "'t".endIndex) == "'t") {
                                    skip = true
                                }
                            }
                        }
                        if let characterBefore:Character = stringBefore.characters.last {
                            if !CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterBefore))!) {
                                skip = true
                            }
                        }
                    }
                    
                    foundString = string.substring(from: range.lowerBound)
                    let newRange = foundString.lowercased().range(of: searchText!.lowercased())
                    foundString = foundString.substring(to: newRange!.upperBound)
                    
                    if !skip {
                        markCounter += 1
                        foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                    }
                    
                    newString = newString + stringBefore + foundString
                    
                    stringBefore = stringBefore + foundString
                    
                    string = stringAfter
                } else {
                    break
                }
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }
        
        var newString:String = Constants.EMPTY_STRING
        var string:String = html.original! // stripHead(fullNotesHTML)!
        
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
        
        var indexString:String!
        
        if markCounter > 0 {
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText!)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText!)\" were found.<br/>"
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
        
        return insertHead(htmlString,fontSize: Constants.FONT_SIZE) // insertHead(newString,fontSize: Constants.FONT_SIZE)
    }

    func updateDownload()
    {
        //        print(document)
        //        print(download)
        
        if let download = selectedMediaItem?.download {
            switch download.state {
            case .none:
                //                    print(".none")
                break
                
            case .downloading:
                //                    print(".downloading")
                progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                break
                
            case .downloaded:
                break
            }
        }
    }
    
    func cancelDownload()
    {
        //        print(document)
        //        print(download)
        
        if let download = selectedMediaItem?.download {
            switch download.state {
            case .none:
                //                    print(".none")
                break
                
            case .downloading:
                //                    print(".downloading")
                download.state = .none

                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    self.wkWebView?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.webView.bringSubview(toFront: self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    networkUnavailable(self,"Document could not be loaded.")
                })
                break
                
            case .downloaded:
                break
            }
        }
    }
    
    var selectedMediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: oldValue?.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: oldValue?.download)
            }

            if selectedMediaItem != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.updateDownload), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: self.selectedMediaItem?.download)
                    NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.cancelDownload), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: self.selectedMediaItem?.download)
                }
            }
        }
    }

    override var canBecomeFirstResponder : Bool
    {
        return true //let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        globals.motionEnded(motion,event: event)
    }
    
    fileprivate func setupWKWebView()
    {
        wkWebView = WKWebView(frame:webView.bounds)
        
        wkWebView?.isHidden = true

        wkWebView?.isMultipleTouchEnabled = true
        wkWebView?.isUserInteractionEnabled = true
        
        wkWebView?.scrollView.scrollsToTop = true
        
        wkWebView?.scrollView.delegate = self

        wkWebView?.navigationDelegate = self
        wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        webView.addSubview(wkWebView!)

        let centerX = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(height)
        
        wkWebView?.superview?.setNeedsLayout()
    }
    
    func done()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "WebViewController:done", completion: nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    var ptvc:PopoverTableViewController?
    
    var activityViewController:UIActivityViewController?
    
    func actionMenu()
    {
        //In case we have one already showing
//        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            var actionMenu = [String]()
            
            if (html.string != nil) && search {
                actionMenu.append(Constants.Strings.Search)
                
                if (selectedMediaItem != nil) {
                    actionMenu.append(Constants.Strings.Words)
                    actionMenu.append(Constants.Strings.Word_Picker)
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
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            popover.vc = self
            
            ptvc = popover
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func increaseFontSize()
    {
        html.fontSize += 1
        
        captureHTMLContentOffsetAndZoomScale()
        
        DispatchQueue.main.async(execute: { () -> Void in
            if self.html.fontSize > Constants.HTML_MIN_FONT_SIZE {
                self.minusButton?.isEnabled = true
            }
            
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        })

        html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
        _ = wkWebView?.loadHTMLString(html.string!, baseURL: nil)
    }
    
    func decreaseFontSize()
    {
        if html.fontSize > Constants.HTML_MIN_FONT_SIZE {
            html.fontSize -= 1
            
            captureHTMLContentOffsetAndZoomScale()
            
            DispatchQueue.main.async(execute: { () -> Void in
                if self.html.fontSize <= Constants.HTML_MIN_FONT_SIZE {
                    self.minusButton?.isEnabled = false
                }
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            })
            
            html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
            _ = wkWebView?.loadHTMLString(html.string!, baseURL: nil)
        }
    }
    
    fileprivate func setupActionButton()
    {
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.actionMenu))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)

        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(WebViewController.increaseFontSize))
        plusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
        
        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(WebViewController.decreaseFontSize))
        minusButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
        
        navigationItem.setRightBarButtonItems([actionButton!,minusButton!,plusButton!], animated: true)
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.done)), animated: true)
                
            default:
                break
            }
        }
    }

    func loading()
    {
        if (wkWebView != nil) {
            progressIndicator.progress = Float(wkWebView!.estimatedProgress)
        }
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            
            progressIndicator.isHidden = true
        }
    }
    
    func setWKZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")
//
//        print("contentInset: \(webView.scrollView.contentInset)")
//        print("contentSize: \(webView.scrollView.contentSize)")

        DispatchQueue.main.async(execute: { () -> Void in
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        })
    }
    
    func setupWKZoomScaleAndContentOffset()
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
    }
    
    func setupWKZoomScaleAndContentOffset(_ wkWebView: WKWebView?)
    {
        if (wkWebView != nil) && (selectedMediaItem != nil) { // !showScripture &&
            var zoomScaleStr:String?
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?

            contentOffsetXRatioStr = selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_X_RATIO]
            contentOffsetYRatioStr = selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_Y_RATIO]
            zoomScaleStr = selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.ZOOM_SCALE]

            var zoomScale:CGFloat = 1.0
            
            var contentOffsetXRatio:CGFloat = 0.0
            var contentOffsetYRatio:CGFloat = 0.0
            
            if let ratio = contentOffsetXRatioStr {
                contentOffsetXRatio = CGFloat(Float(ratio)!)
            }
            
            if let ratio = contentOffsetYRatioStr {
                contentOffsetYRatio = CGFloat(Float(ratio)!)
            }
            
            if let zoom = zoomScaleStr {
                zoomScale = CGFloat(Float(zoom)!)
            }
            
            let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width * zoomScale),
                                            y: CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height * zoomScale))
            
            setWKZoomScaleThenContentOffset(wkWebView!, scale: zoomScale, offset: contentOffset)
        }
    }
    
    func setupWKContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
//        print("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if (wkWebView != nil) && (selectedMediaItem != nil) { // !showScripture &&
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?
            
            contentOffsetXRatioStr = selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_X_RATIO]
            contentOffsetYRatioStr = selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_Y_RATIO]
            
            var contentOffsetXRatio:CGFloat = 0.0
            var contentOffsetYRatio:CGFloat = 0.0
            
            if let ratio = contentOffsetXRatioStr {
                contentOffsetXRatio = CGFloat(Float(ratio)!)
            }
            
            if let ratio = contentOffsetYRatioStr {
                contentOffsetYRatio = CGFloat(Float(ratio)!)
            }
            
            let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width), //
                y: CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height)) //
            
            //            print("About to setContentOffset with: \(contentOffset)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            //            print("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func setupHTMLWKZoomScaleAndContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
        //        print("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if (wkWebView != nil) { //  && (selectedMediaItem != nil)   !showScripture &&
            let contentOffset = CGPoint(x: CGFloat(html.xRatio * Double(wkWebView!.scrollView.contentSize.width)),
                y: CGFloat(html.yRatio * Double(wkWebView!.scrollView.contentSize.height)))
            
            //            print("About to setContentOffset with: \(contentOffset)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                wkWebView?.scrollView.setZoomScale(CGFloat(self.html.zoomScale), animated: false)
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            //            print("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func setupHTMLWKContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
        //        print("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if (wkWebView != nil) { //  && (selectedMediaItem != nil)   !showScripture &&
            let contentOffset = CGPoint(x: CGFloat(html.xRatio * Double(wkWebView!.scrollView.contentSize.width)), //
                y: CGFloat(html.yRatio * Double(wkWebView!.scrollView.contentSize.height))) //
            
            //            print("About to setContentOffset with: \(contentOffset)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            //            print("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
        //        print("\(wkWebView!.scrollView.contentOffset)")
        //        print("\(wkWebView!.scrollView.zoomScale)")
        
        if (selectedMediaItem != nil) && // (UIApplication.shared.applicationState == UIApplicationState.active) && // !showScripture &&
            (wkWebView != nil) && (!wkWebView!.isLoading) && (wkWebView!.url != nil) {
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
        }
    }
    
    func captureHTMLContentOffsetAndZoomScale()
    {
        //        print("\(wkWebView!.scrollView.contentOffset)")
        //        print("\(wkWebView!.scrollView.zoomScale)")
        
        if // (UIApplication.shared.applicationState == UIApplicationState.active) && //  && (selectedMediaItem != nil) !showScripture &&
            (wkWebView != nil) && (!wkWebView!.isLoading) {
            
            html.xRatio = Double(wkWebView!.scrollView.contentOffset.x) / Double(wkWebView!.scrollView.contentSize.width)

            html.yRatio = Double(wkWebView!.scrollView.contentOffset.y) / Double(wkWebView!.scrollView.contentSize.height)
            
            html.zoomScale = Double(wkWebView!.scrollView.zoomScale)
            
//            print(html)
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        } else {
            if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
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
        
        if (self.view.window == nil) {
            return
        }

        switch self.content {
        case .document:
            captureContentOffsetAndZoomScale()
            break
            
        case .html:
            captureHTMLContentOffsetAndZoomScale()
            break
        }
        
//        print("Size: \(size)")

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            switch self.content {
            case .document:
                self.setupWKContentOffset(self.wkWebView)
                break
                
            case .html:
                self.setupHTMLWKZoomScaleAndContentOffset(self.wkWebView)
                break
            }
            
            if let title = self.navigationItem.title {
                let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                
                let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 48.0)
                
                let width:CGFloat = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width + 150
                
//                print("WebViewController:viewWillTransition",max(width,self.wkWebView!.scrollView.contentSize.width),self.wkWebView!.scrollView.contentSize.height)
                
                self.navigationController?.preferredContentSize = CGSize(width: max(width,self.wkWebView!.scrollView.contentSize.width),
                                                                         height: self.wkWebView!.scrollView.contentSize.height)
            }
        }
    }
    
    override var prefersStatusBarHidden : Bool
    {
        return true
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.setToolbarHidden(true, animated: true)

//        navigationItem.leftItemsSupplementBackButton = true
        
        logo.isHidden = true
        
        setupActionButton()
        
        setupWKWebView()
        
        webView.bringSubview(toFront: activityIndicator)
        
        progressIndicator.isHidden = content == .html
    }
    
    func loadDocument()
    {
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads {
                var destinationURL:URL?
                
                destinationURL = selectedMediaItem?.fileSystemURL

                if (FileManager.default.fileExists(atPath: destinationURL!.path)){
                    DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                        _ = self.wkWebView?.loadFileURL(destinationURL!, allowingReadAccessTo: destinationURL!)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true
                            
                            self.progressIndicator.progress = 0.0
                            self.progressIndicator.isHidden = true
                            
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                        })
                    })
                } else {
                    activityIndicator.isHidden = false
                    activityIndicator.startAnimating()
                    
                    let download = selectedMediaItem!.download
                    
                    progressIndicator.progress = download!.totalBytesExpectedToWrite != 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
                    progressIndicator.isHidden = false
                    
//                    if loadTimer == nil {
//                        loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.DOWNLOADING, target: self, selector: #selector(WebViewController.downloading), userInfo: nil, repeats: true)
//                    }

                    download?.download()
                }
            } else {
                var url:URL?
                
                url = selectedMediaItem?.downloadURL

                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.webView.bringSubview(toFront: self.activityIndicator)
                        
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.progress = 0.0
                        self.progressIndicator.isHidden = false
                        
                        if self.loadTimer == nil {
                            self.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
                        }
                    })
                    
                    let request = URLRequest(url: url!)
//                    let request = URLRequest(url: url!, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                    _ = self.wkWebView?.load(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
                })
            }
        } else {
            var url:URL?
            
            url = selectedMediaItem?.downloadURL

            DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.webView.bringSubview(toFront: self.activityIndicator)
                    
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                    
                    self.progressIndicator.progress = 0.0
                    self.progressIndicator.isHidden = false
                    
                    if self.loadTimer == nil {
                        self.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
                    }
                })
                
                let request = URLRequest(url: url!)
//                let request = URLRequest(url: url!, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                _ = self.wkWebView?.load(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
            })
        }
    }
    
    func setPreferredContentSize()
    {
        guard let title = navigationItem.title?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE),
            let size = wkWebView?.scrollView.contentSize else {
                //                preferredContentSize = CGSize(width: size.width,height: size.height)
            return
        }
        
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
        
        let width = title.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width + 150
        
        if let widthView = (presentingViewController != nil) ? presentingViewController!.view : view {
            preferredContentSize = CGSize(width: max(width,widthView.frame.width),height: size.height)
        }
    }
    
    var orientation : UIDeviceOrientation?
    
    func deviceOrientationDidChange()
    {
        func action()
        {
            ptvc?.dismiss(animated: false, completion: nil)
            activityViewController?.dismiss(animated: false, completion: nil)
        }
        
        // Dismiss any popover
        switch orientation! {
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
            orientation = UIDevice.current.orientation
            break
            
        case .landscapeRight:
            orientation = UIDevice.current.orientation
            break
            
        case .portrait:
            orientation = UIDevice.current.orientation
            break
            
        case .portraitUpsideDown:
            orientation = UIDevice.current.orientation
            break
            
        case .unknown:
            break
        }
    }
    
    func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        orientation = UIDevice.current.orientation
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.setPreferredContentSize), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)

        if let title = selectedMediaItem?.title {
            navigationItem.title = title
        }

        if let isHidden = wkWebView?.isHidden, isHidden {
            switch content {
            case .document:
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
                
                loadDocument()
                break
                
            case .html:
                if html.string != nil {
                    html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
                    _ = wkWebView?.loadHTMLString(html.string!, baseURL: nil)
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
        
        navigationItem.hidesBackButton = false

        navigationController?.navigationBar.backItem?.title = Constants.Strings.Back
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        //Remove the next line and the app will crash
        wkWebView?.scrollView.delegate = nil
        
        loadTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    /*
    // MARK: - Navigation
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            default:
                break
            }
        }
    }
}
