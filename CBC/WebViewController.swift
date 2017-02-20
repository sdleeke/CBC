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
    var string:String?
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
            userAlert(title: "Not Main Thread", message: "WebViewController:stringPicked")
            return
        }
        
        self.dismiss(animated: true, completion: nil)
        
        var searchText = string
        
        if let range = searchText?.range(of: " (") {
            searchText = searchText?.substring(to: range.lowerBound)
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.wkWebView?.isHidden = true
            
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        })
        
        html.string = selectedMediaItem?.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true, index: true)
        html.string = insertHead(stripHead(html.string),fontSize: html.fontSize)
        
        _ = self.wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
    }
}

extension WebViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func actionMenu(action: String?, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex")
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Full_Screen:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? WebViewController {
                // Had to take out the lines below or the searchBar would become unresponsive. No idea why.
                //                    DispatchQueue.main.async(execute: { () -> Void in
                //                        self.dismiss(animated: true, completion: nil)
                //                    })
                
                navigationController.modalPresentationStyle = .overFullScreen
                navigationController.popoverPresentationController?.delegate = popover
                
                popover.navigationItem.title = self.navigationItem.title
                
                popover.html.fontSize = self.html.fontSize
                popover.html.string = self.html.string
                
                popover.selectedMediaItem = self.selectedMediaItem
                
                popover.content = self.content
                
                popover.navigationController?.isNavigationBarHidden = false
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Print:
            if html.string != nil, html.string!.contains(" href=") {
                firstSecondCancel(viewController: self, title: "Remove Links?", message: "This can take some time.",
                                  firstTitle: "Yes",
                                  firstAction: {
                                    process(viewController: self, work: { () -> (Any?) in
                                        return stripLinks(self.html.string)
                                    }, completion: { (data:Any?) in
                                        printHTML(viewController: self, htmlString: data as? String)
                                    })
                },
                                  secondTitle: "No",
                                  secondAction: {
                                    printHTML(viewController: self, htmlString: self.html.string)
                },
                                  cancelAction: {}
                )
            } else {
                printHTML(viewController: self, htmlString: self.html.string)
            }
            break
            
        case Constants.Share:
            shareHTML(viewController: self, htmlString: html.string!)
            break
            
        case Constants.Search:
            let alert = UIAlertController(title: "Search",
                                          message: Constants.EMPTY_STRING,
                                          preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: { (textField:UITextField) in
                textField.placeholder = "search string"
            })
            
            let searchAction = UIAlertAction(title: "Search", style: UIAlertActionStyle.default, handler: {
                alertItem -> Void in
                let searchText = (alert.textFields![0] as UITextField).text
                
                self.wkWebView?.isHidden = true
                
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                
                self.html.string = insertHead(stripHead(self.selectedMediaItem?.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: false, index: true)),fontSize: self.html.fontSize)
                
                _ = self.wkWebView?.loadHTMLString(self.html.string!, baseURL: nil)
            })
            alert.addAction(searchAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                (action : UIAlertAction!) -> Void in
            })
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
            break
            
        case Constants.Word_Picker:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Word_Picker
                
                popover.delegate = self
                
                popover.mediaListGroupSort = MediaListGroupSort(mediaItems: [selectedMediaItem!])
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Words:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingWord
                
                if mediaItem!.hasNotesHTML {
                    if mediaItem?.notesTokens == nil {
                        popover.stringsFunction = {
                            mediaItem?.loadNotesHTML()
                            
                            if let notesTokens = tokensAndCountsFromString(mediaItem?.notesHTML) {
                                mediaItem?.notesTokens = notesTokens
                                
                                return notesTokens.map({ (string:String,count:Int) -> String in
                                    return "\(string) (\(count))"
                                }).sorted()
                            } else {
                                return nil
                            }
                        }
                    } else {
                        popover.section.strings = mediaItem?.notesTokens?.map({ (string:String,count:Int) -> String in
                            return "\(string) (\(count))"
                        }).sorted()
                        
                        // Why Array(Set())?  Duplicates?
                        let array = Array(Set(popover.section.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
                        
                        popover.section.indexStrings = array.map({ (string:String) -> String in
                            return string.uppercased()
                        })
                    }
                }
                
                popover.section.showIndex = true //(globals.grouping == .series)
                popover.section.showHeaders = true
                
                popover.search = true
                
                popover.vc = self
                
                present(navigationController, animated: true, completion: {
                    DispatchQueue.main.async(execute: { () -> Void in
                        // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                        navigationController.popoverPresentationController?.passthroughViews = nil
                    })
                })
            }
            break
            
        case Constants.Email_One:
            mailHTML(viewController: self, to: [], subject: Constants.CBC.LONG + Constants.SINGLE_SPACE + navigationItem.title!, htmlString: html.string!)
            break
            
        case Constants.Open_in_Browser:
            if selectedMediaItem?.downloadURL != nil {
                if (UIApplication.shared.canOpenURL(selectedMediaItem!.downloadURL!)) { // Reachability.isConnectedToNetwork() &&
                    UIApplication.shared.openURL(selectedMediaItem!.downloadURL!)
                } else {
                    networkUnavailable("Unable to open in browser at: \(selectedMediaItem!.downloadURL!)")
                }
            }
            break
            
        case Constants.Refresh_Document:
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
            userAlert(title: "Not Main Thread", message: "WebViewController:rowClickedAtIndex")
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingWord:
            var searchText = strings[index]
            
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
            actionMenu(action: strings[index], mediaItem:mediaItem)
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
                    
                    self.preferredContentSize = CGSize(width: wkWebView.scrollView.contentSize.width,height: wkWebView.scrollView.contentSize.height)
                    
                    wkWebView.isHidden = false
                    wkWebView.scrollView.contentOffset = CGPoint(x: 0, y: 0)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SET_PREFERRED_CONTENT_SIZE), object: nil)
                })
            }
        })
    }
    
    func webView(_ wkWebView: WKWebView, didFail navigation: WKNavigation!, withError: Error) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            print("wkDidFail navigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(withError.localizedDescription)
            NSLog(withError.localizedDescription)
        }
        // Keep trying
        //        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        //        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            print("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(withError.localizedDescription)
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
                
                //                switch tag.lowercased() {
                //                case "index":
                //                    fallthrough
                //
                //                case "locations":
                //                    decisionHandler(WKNavigationActionPolicy.allow)
                //                    break
                //
                //                default:
                //                    if Int(tag) != nil {
                //                        decisionHandler(WKNavigationActionPolicy.allow)
                //                    }
                //                    break
                //                }
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
                    networkUnavailable("Document could not be loaded.")
                })
                break
                
            case .downloaded:
                break
            }
        }
    }
    
    var selectedMediaItem:MediaItem? {
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

    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
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

//        webView.bringSubviewToFront(wkWebView!)
        
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
            userAlert(title: "Not Main Thread", message: "WebViewController:done")
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    func actions()
    {
        //In case we have one already showing
//        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
//                popover.navigationItem.title = Constants.Actions
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            var actionMenu = [String]()

            if (html.string != nil) && (selectedMediaItem != nil) {
                actionMenu.append(Constants.Search)
                actionMenu.append(Constants.Words)
                actionMenu.append(Constants.Word_Picker)
            }

            if self.navigationController?.modalPresentationStyle == .popover {
                actionMenu.append(Constants.Full_Screen)
            }
            
            if UIPrintInteractionController.isPrintingAvailable {
                actionMenu.append(Constants.Print)
            }
            
            if html.string != nil {
                actionMenu.append(Constants.Share)
            }
            
            popover.section.strings = actionMenu
            
            popover.section.showIndex = false //(globals.grouping == .series)
            popover.section.showHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: {
                DispatchQueue.main.async(execute: { () -> Void in
                    // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                    navigationController.popoverPresentationController?.passthroughViews = nil
                })
            })
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
        actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(WebViewController.actions))

        plusButton = UIBarButtonItem(title: Constants.FA.LARGER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(WebViewController.increaseFontSize))
        
        plusButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.SHOW_FONT_SIZE)!], for: UIControlState())
        
        minusButton = UIBarButtonItem(title: Constants.FA.SMALLER, style: UIBarButtonItemStyle.plain, target: self, action:  #selector(WebViewController.decreaseFontSize))
        
        minusButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.SHOW_FONT_SIZE)!], for: UIControlState())
        
        navigationItem.setRightBarButtonItems([actionButton!,minusButton!,plusButton!], animated: true)
        
        if navigationController?.modalPresentationStyle == .overFullScreen {
            navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.done)), animated: true)
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
            
//            let contentOffset = CGPoint(x: html.x,y: html.y)
            
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

//        setupSplitViewController()
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
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
                    
                    let width:CGFloat = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)], context: nil).width + 150
                    
                    self.navigationController?.preferredContentSize = CGSize(width: max(width,self.wkWebView!.scrollView.contentSize.width),
                                                                             height: self.wkWebView!.scrollView.contentSize.height)
                }
            })
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true // navigationController?.navigationBarHidden ==
    }
    
//    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
//        return UIStatusBarAnimation.Slide
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setToolbarHidden(true, animated: true)
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        // Do any additional setup after loading the view.
    }
    
//    func downloading()
//    {
//        var download:Download?
//        
//        download = selectedMediaItem?.download
//
////        if (download != nil) {
////            print("totalBytesWritten: \(download!.totalBytesWritten)")
////            print("totalBytesExpectedToWrite: \(download!.totalBytesExpectedToWrite)")
////        }
//
//        switch download!.state {
//        case .none:
//            print(".none")
//            self.loadTimer?.invalidate()
//            self.loadTimer = nil
//            
//            self.activityIndicator.stopAnimating()
//            self.activityIndicator.isHidden = true
//            
//            self.progressIndicator.progress = 0.0
//            self.progressIndicator.isHidden = true
//            break
//        
//        case .downloading:
//            print(".downloading")
//            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
//            break
//
//        case .downloaded:
//            print(".downloaded")
//            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
////            print(progressIndicator.progress)
//
//            if #available(iOS 9.0, *) {
//                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
//                    _ = self.wkWebView?.loadFileURL(download!.fileSystemURL!, allowingReadAccessTo: download!.fileSystemURL!)
//                    
//                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.loadTimer?.invalidate()
//                        self.loadTimer = nil
//                        
//                        self.activityIndicator.stopAnimating()
//                        self.activityIndicator.isHidden = true
//                        
//                        self.progressIndicator.progress = 0.0
//                        self.progressIndicator.isHidden = true
//                    })
//                })
//            } else {
//                // Fallback on earlier versions
//            }
//            break
//        }
//    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = selectedMediaItem?.title {
            navigationItem.title = title
        }
        
        if let title = navigationItem.title {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)

            let width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0)], context: nil).width + 150

            preferredContentSize = CGSize(width: width,height: 44)
        }
        
        logo.isHidden = true
        
        setupActionButton()

        setupWKWebView()
        
        webView.bringSubview(toFront: activityIndicator)
        
        progressIndicator.isHidden = content == .html
        
//        if content == .html {
//            if globals.search.valid {
//                if let htmlString = selectedMediaItem?.markedFullNotesHTML(searchText:globals.search.text,index: true) {
//                    html.string = htmlString
//                }
//            } else {
//                if let htmlString = selectedMediaItem?.fullNotesHTML {
//                    html.string = htmlString
//                }
//            }
//        }

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
        
        barButtonItems(isEnabled: false)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationItem.hidesBackButton = false
        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        navigationController?.navigationBar.backItem?.title = Constants.Back
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Remove the next line and the app will crash
        wkWebView?.scrollView.delegate = nil
        
        loadTimer?.invalidate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
