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
    var string:String = Constants.EMPTY_STRING
    var fontSize = 0
    var xRatio = 0.0
    var yRatio = 0.0
    var zoomScale = 0.0
}

class WebViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, MFMailComposeViewControllerDelegate, PopoverTableViewControllerDelegate {

    enum Content {
        case document
        case notesHTML
    }
    
    var wkWebView:WKWebView?

    var content:Content = .document
    
    var html = HTML()
    
    var loadTimer:Timer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedMediaItem:MediaItem?
    
//    var showScripture = false
    
//    var url:NSURL? {
//        get {
//            if showScripture {
//                var urlString = Constants.SCRIPTURE_URL_PREFIX + selectedMediaItem!.scripture! + Constants.SCRIPTURE_URL_POSTFIX
//                
//                urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
//
//                return NSURL(string:urlString)
//            } else {
//                return nil
//            }
//        }
//    }

    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidZoom")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        NSLog("scrollViewDidEndZooming")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .notesHTML:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidScroll")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidEndScrollingAnimation")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .notesHTML:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
//        NSLog("scrollViewDidEndDecelerating")
        if let _ = scrollView.superview as? WKWebView {
            switch content {
            case .document:
                captureContentOffsetAndZoomScale()
                break
            case .notesHTML:
                captureHTMLContentOffsetAndZoomScale()
                break
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
//        NSLog("scrollViewDidEndDragging")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
//    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
//    {
////        if showScripture {
////            if wkWebView.loading {
////                decisionHandler(WKNavigationActionPolicy.Allow)
////            } else {
////                decisionHandler(WKNavigationActionPolicy.Cancel)
////            }
////            return
////        }
//    
//        if (navigationAction.request.url != nil) {
//            //            NSLog("\(navigationAction.request.URL!.absoluteString)")
//            
//            if (navigationAction.request.url!.absoluteString.endIndex < Constants.BASE_PDF_URL.endIndex) {
//                decisionHandler(WKNavigationActionPolicy.cancel)
//            } else {
//                if (navigationAction.request.url!.absoluteString.substring(to: Constants.BASE_PDF_URL.endIndex) == Constants.BASE_PDF_URL) {
//                    decisionHandler(WKNavigationActionPolicy.allow)
//                } else {
//                    if (navigationAction.request.url!.path.substring(to: cachesURL()!.path.endIndex) == cachesURL()!.path) {
//                        decisionHandler(WKNavigationActionPolicy.allow)
//                    } else {
//                        decisionHandler(WKNavigationActionPolicy.cancel)
//                    }
//                }
//            }
//        } else {
//            decisionHandler(WKNavigationActionPolicy.cancel)
//        }
//    }
    
    func webView(_ wkWebView: WKWebView, didFail didFailNavigation: WKNavigation!, withError: Error) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            NSLog("wkDidFailNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(withError.localizedDescription)
        }
        // Keep trying
        //        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        //        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            NSLog("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            progressIndicator.isHidden = true
            networkUnavailable(withError.localizedDescription)
        }
    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        //        NSLog("wkDidStartProvisionalNavigation")
        
    }
    
    fileprivate func setupWKWebView()
    {
        wkWebView = WKWebView(frame:webView.bounds)
        
        wkWebView?.isHidden = true

        wkWebView?.isMultipleTouchEnabled = true
        
//        wkWebView?.scrollView.scrollsToTop = false
        
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
    
    func printHTML(htmlString:String)
    {
        let pi = UIPrintInfo.printInfo()
        pi.outputType = UIPrintInfoOutputType.general
        pi.jobName = Constants.Print;
        pi.orientation = UIPrintInfoOrientation.portrait
        pi.duplex = UIPrintInfoDuplex.longEdge
        
        let pic = UIPrintInteractionController.shared
        pic.printInfo = pi
        pic.showsPageRange = true

        let formatter = UIMarkupTextPrintFormatter(markupText: htmlString)
        formatter.contentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72) // 1" margins

        pic.printFormatter = formatter
        pic.present(from: navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
    }
    
    func printMediaItem(_ mediaItem:MediaItem?)
    {
        if (UIPrintInteractionController.isPrintingAvailable && (mediaItem != nil))
        {
            var printURL:URL?
            
            printURL = mediaItem?.downloadURL as URL?
            
            if (printURL?.absoluteString != Constants.EMPTY_STRING) && UIPrintInteractionController.canPrint(printURL!) {
                //                NSLog("can print!")
                let pi = UIPrintInfo.printInfo()
                pi.outputType = UIPrintInfoOutputType.general
                pi.jobName = Constants.Print;
                pi.orientation = UIPrintInfoOrientation.portrait
                pi.duplex = UIPrintInfoDuplex.longEdge
                
                let pic = UIPrintInteractionController.shared
                pic.printInfo = pi
                pic.showsPageRange = true
                
                //Never could get this to work:
                //            pic?.printFormatter = webView?.viewPrintFormatter()
                
                pic.printingItem = printURL
                pic.present(from: navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) { //  && (self.view.window != nil)
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func mailHTML(htmlString:String)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(selectedMediaItem!.title!)
        
        mailComposeViewController.setMessageBody(htmlString, isHTML: true)
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, mediaItem:MediaItem?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
            case Constants.Print:
                //                printMediaItem(selectedMediaItem)
                printHTML(htmlString: html.string)
                break
                
            case Constants.Email_One:
                mailHTML(htmlString: html.string)
                break
                
            case Constants.Increase_Font_Size:
                var newString:String
                
                if html.fontSize <= 3 {
                    html.fontSize += 1
                }
                
                if html.fontSize < 0 {
                    newString = "<font size=\"\(html.fontSize)\">" + html.string + "</font>"
                } else {
                    newString = "<font size=\"+\(html.fontSize)\">" + html.string + "</font>"
                }
                _ = wkWebView?.loadHTMLString(newString, baseURL: nil)
                break
                
            case Constants.Decrease_Font_Size:
                var newString:String
                
                if html.fontSize >= -1 {
                    html.fontSize -= 1
                }

                if html.fontSize < 0 {
                    newString = "<font size=\"\(html.fontSize)\">" + html.string + "</font>"
                } else {
                    newString = "<font size=\"+\(html.fontSize)\">" + html.string + "</font>"
                }
                _ = wkWebView?.loadHTMLString(newString, baseURL: nil)
                break
                
            case Constants.Open_in_Browser:
                if selectedMediaItem?.downloadURL != nil {
                    if (UIApplication.shared.canOpenURL(selectedMediaItem!.downloadURL! as URL)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.shared.openURL(selectedMediaItem!.downloadURL! as URL)
                    } else {
                        networkUnavailable("Unable to open in browser at: \(selectedMediaItem!.downloadURL!)")
                    }
                }
                break

            case Constants.Refresh_Document:
                selectedMediaItem?.download?.deleteDownload()

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
            break
            
        default:
            break
        }
    }
    
    func done()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
    }
    
    func actions()
    {
        //In case we have one already showing
//        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
//                popover.navigationItem.title = Constants.Actions
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()

                actionMenu.append(Constants.Print)
                actionMenu.append(Constants.Email_One)
                
                if html.fontSize <= 3 {
                    actionMenu.append(Constants.Increase_Font_Size)
                }
                
                if html.fontSize >= -1 {
                    actionMenu.append(Constants.Decrease_Font_Size)
                }

//                if (selectedMediaItem!.hasNotes && selectedMediaItem!.showingNotes) || (selectedMediaItem!.hasSlides && selectedMediaItem!.showingSlides) {
//                    actionMenu.append(Constants.Print)
//                    actionMenu.append(Constants.Open_in_Browser)
//                    
//                    if globals.cacheDownloads { //  && !showScripture
//                        actionMenu.append(Constants.Refresh_Document)
//                    }
//                }
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func setupActionButton()
    {
        if (selectedMediaItem != nil) {
            navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(WebViewController.actions)), animated: true)

            navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.done)), animated: true)

//            if htmlString != nil {
//                navigationItem.setRightBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(WebViewController.done)), animated: true)
//            } else {
//                navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(WebViewController.actions)), animated: true)
//            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
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
//        NSLog("scale: \(scale)")
//        NSLog("offset: \(offset)")
//
//        NSLog("contentInset: \(webView.scrollView.contentInset)")
//        NSLog("contentSize: \(webView.scrollView.contentSize)")

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
    
    func webView(_ wkWebView: WKWebView, didFinish navigation: WKNavigation!) {
        setupWKZoomScaleAndContentOffset(wkWebView)

        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            self.progressIndicator.isHidden = true
            
            wkWebView.isHidden = false
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
        
        NSLog("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
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
            
            //            NSLog("About to setContentOffset with: \(contentOffset)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            //            NSLog("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func setupHTMLWKContentOffset(_ wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
        NSLog("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if (wkWebView != nil) && (selectedMediaItem != nil) { // !showScripture &&
            let contentOffset = CGPoint(x: CGFloat(html.xRatio * Double(wkWebView!.scrollView.contentSize.width)), //
                y: CGFloat(html.yRatio * Double(wkWebView!.scrollView.contentSize.height))) //
            
            //            NSLog("About to setContentOffset with: \(contentOffset)")
            
            DispatchQueue.main.async(execute: { () -> Void in
                wkWebView?.scrollView.setZoomScale(CGFloat(self.html.zoomScale), animated: false)
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            //            NSLog("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
        //        NSLog("\(wkWebView!.scrollView.contentOffset)")
        //        NSLog("\(wkWebView!.scrollView.zoomScale)")
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (selectedMediaItem != nil) && // !showScripture &&
            (wkWebView != nil) && (!wkWebView!.isLoading) && (wkWebView!.url != nil) {
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
            
            selectedMediaItem?.mediaItemSettings?[selectedMediaItem!.showing! + Constants.ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
        }
    }
    
    func captureHTMLContentOffsetAndZoomScale()
    {
        //        NSLog("\(wkWebView!.scrollView.contentOffset)")
        //        NSLog("\(wkWebView!.scrollView.zoomScale)")
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (selectedMediaItem != nil) && // !showScripture &&
            (wkWebView != nil) && (!wkWebView!.isLoading) {
            
            html.xRatio = Double(wkWebView!.scrollView.contentOffset.x) / Double(wkWebView!.scrollView.contentSize.width)
            
            html.yRatio = Double(wkWebView!.scrollView.contentOffset.y) / Double(wkWebView!.scrollView.contentSize.height)
            
            html.zoomScale = Double(wkWebView!.scrollView.zoomScale)
            
            print(html)
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = .automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
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
//            captureContentOffsetAndZoomScale()
            break
            
        case .notesHTML:
            captureHTMLContentOffsetAndZoomScale()
            break
        }
        
//        NSLog("Size: \(size)")

//        setupSplitViewController()
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                switch self.content {
                case .document:
                    self.setupWKContentOffset(self.wkWebView)
                    break
                    
                case .notesHTML:
                    self.setupHTMLWKContentOffset(self.wkWebView)
                    break
                }
            })
        }
        
//        switch UIApplication.sharedApplication().applicationState {
//        case UIApplicationState.Active:
//            setupSplitViewController()
//            
//            NSLog("Before animateAlongsideTransition: \(wkWebView?.scrollView.contentOffset)")
//            fallthrough
//            
//        case UIApplicationState.Background:
//            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
//                }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//                    self.setupWKContentOffset(self.wkWebView)
//            }
//            break
//            
//        default:
//            break
//        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true // navigationController?.navigationBarHidden ==
    }
    
//    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
//        return UIStatusBarAnimation.Slide
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        navigationController?.setToolbarHidden(true, animated: true)
        
        // Do any additional setup after loading the view.
    }
    
    func downloading()
    {
        var download:Download?
        
        download = selectedMediaItem?.download

//        if (download != nil) {
//            NSLog("totalBytesWritten: \(download!.totalBytesWritten)")
//            NSLog("totalBytesExpectedToWrite: \(download!.totalBytesExpectedToWrite)")
//        }

        switch download!.state {
        case .none:
            NSLog(".none")
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.progressIndicator.progress = 0.0
            self.progressIndicator.isHidden = true
            break
        
        case .downloading:
            NSLog(".downloading")
            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
            break

        case .downloaded:
            NSLog(".downloaded")
            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
//            print(progressIndicator.progress)

            if #available(iOS 9.0, *) {
                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                    _ = self.wkWebView?.loadFileURL(download!.fileSystemURL! as URL, allowingReadAccessTo: download!.fileSystemURL! as URL)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.loadTimer?.invalidate()
                        self.loadTimer = nil
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        
                        self.progressIndicator.progress = 0.0
                        self.progressIndicator.isHidden = true
                    })
                })
            } else {
                // Fallback on earlier versions
            }
            break
        }
        
        // This is all trying to catch download failures, but I'm afraid it is generating false positives.
        //        if ((download?.totalBytesWritten == 0) && (download?.totalBytesExpectedToWrite == 0)) {
        //            download?.state = .none
        //        }
        //
        //        if (download?.state != .downloading) && (download?.state != .downloaded) {
        //            downloadFailed()
        //            loadTimer?.invalidate()
        //            loadTimer = nil
        //            activityIndicator.stopAnimating()
        //            activityIndicator.hidden = true
        //            progressIndicator.hidden = true
        //        }
    }
    
//    func loadScripture()
//    {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.webView.bringSubviewToFront(self.activityIndicator)
//                
//                self.activityIndicator.hidden = false
//                self.activityIndicator.startAnimating()
//                
//                self.progressIndicator.progress = 0.0
//                self.progressIndicator.hidden = false
//                
//                if self.loadTimer == nil {
//                    self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
//                }
//            })
//
//            let request = NSURLRequest(URL: self.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//            self.wkWebView?.loadRequest(request)
//        })
//    }
    
    func loadDocument()
    {
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads {
                var destinationURL:URL?
                
                destinationURL = selectedMediaItem?.fileSystemURL as URL?

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
                    
                    if loadTimer == nil {
                        loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.DOWNLOADING, target: self, selector: #selector(WebViewController.downloading), userInfo: nil, repeats: true)
                    }

                    download?.download()
                }
            } else {
                var url:URL?
                
                url = selectedMediaItem?.downloadURL as URL?

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
                    
                    let request = URLRequest(url: url!, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                    _ = self.wkWebView?.load(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
                })
            }
        } else {
            var url:URL?
            
            url = selectedMediaItem?.downloadURL as URL?

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
                
                let request = URLRequest(url: url!, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                _ = self.wkWebView?.load(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
            })
        }
    }
    
    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
//        print(navigationAction.request.url!.absoluteString)
//        print(navigationAction.navigationType.rawValue)

        if (navigationAction.navigationType == .other) {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = selectedMediaItem!.title!
        
        setupActionButton()

        setupWKWebView()

        webView.bringSubview(toFront: activityIndicator)
        
        progressIndicator.isHidden = content == .notesHTML
        
        if content == .notesHTML {
            if let notesHTML = selectedMediaItem?.fullNotesHTML {
                html.string = notesHTML
            }
        }

        switch content {
        case .document:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            loadDocument()
            break
            
        case .notesHTML:
            _ = wkWebView?.loadHTMLString(html.string, baseURL: nil)
            break
        }
        
//        if showScripture {
//            loadScripture()
//        } else {
//            loadDocument()
//        }
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
        URLCache.shared.removeAllCachedResponses()
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
