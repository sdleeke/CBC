//
//  WebViewController.swift
//  GTY
//
//  Created by Steve Leeke on 11/10/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    var wkWebView:WKWebView?
    
    var loadTimer:NSTimer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedSermon:Sermon?
    
    var showScripture = false
    
    var url:NSURL? {
        get {
            if showScripture {
                var urlString = Constants.SCRIPTURE_URL_PREFIX + selectedSermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX
                
                urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!

                return NSURL(string:urlString)
            } else {
                return nil
            }
        }
    }

    override func canBecomeFirstResponder() -> Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
        }
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        //        print("scrollViewDidZoom")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //        print("scrollViewDidScroll")
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
//        print("scrollViewDidEndZooming")
        if let _ = scrollView.superview as? WKWebView {
            captureContentOffsetAndZoomScale()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
//        print("scrollViewDidEndDecelerating")
        if let _ = scrollView.superview as? WKWebView {
            captureContentOffsetAndZoomScale()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        //        print("scrollViewDidEndDragging")
        if !decelerate {
            if let _ = scrollView.superview as? WKWebView {
                captureContentOffsetAndZoomScale()
            }
        }
    }
    
    func webView(wkWebView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    {
        if showScripture {
            if wkWebView.loading {
                decisionHandler(WKNavigationActionPolicy.Allow)
            } else {
                decisionHandler(WKNavigationActionPolicy.Cancel)
            }
            return
        }
    
        if (navigationAction.request.URL != nil) {
            //            print("\(navigationAction.request.URL!.absoluteString)")
            
            if (navigationAction.request.URL!.absoluteString.endIndex < Constants.BASE_PDF_URL.endIndex) {
                decisionHandler(WKNavigationActionPolicy.Cancel)
            } else {
                if (navigationAction.request.URL!.absoluteString.substringToIndex(Constants.BASE_PDF_URL.endIndex) == Constants.BASE_PDF_URL) {
                    decisionHandler(WKNavigationActionPolicy.Allow)
                } else {
                    if (navigationAction.request.URL!.path!.substringToIndex(cachesURL()!.path!.endIndex) == cachesURL()!.path!) {
                        decisionHandler(WKNavigationActionPolicy.Allow)
                    } else {
                        decisionHandler(WKNavigationActionPolicy.Cancel)
                    }
                }
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }
    
    func webView(wkWebView: WKWebView, didFailNavigation: WKNavigation!, withError: NSError) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            print("wkDidFailNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            progressIndicator.hidden = true
            networkUnavailable(withError.localizedDescription)
        }
        // Keep trying
        //        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        //        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: NSError) {
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            print("wkDidFailProvisionalNavigation")
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            progressIndicator.hidden = true
            networkUnavailable(withError.localizedDescription)
        }
    }
    
    func webView(wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        //        print("wkDidStartProvisionalNavigation")
        
    }
    
    private func setupWKWebView()
    {
        wkWebView = WKWebView(frame:webView.bounds)
        wkWebView?.multipleTouchEnabled = true
        
        wkWebView?.scrollView.scrollsToTop = false
        
        wkWebView?.scrollView.delegate = self

        wkWebView?.navigationDelegate = self
        wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        webView.addSubview(wkWebView!)

        webView.bringSubviewToFront(wkWebView!)
        
        let centerX = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(height)
        
        wkWebView?.superview?.setNeedsLayout()
    }
    
    func printSermon(sermon:Sermon?)
    {
        if (UIPrintInteractionController.isPrintingAvailable() && (sermon != nil))
        {
            var printURL:NSURL?
            
            switch sermon!.showing! {
            case Constants.NOTES:
                printURL = sermon!.notesURL
                break
            case Constants.SLIDES:
                printURL = sermon!.slidesURL
                break
                
            default:
                break
            }
            
            if (printURL != "") && UIPrintInteractionController.canPrintURL(printURL!) {
                //                print("can print!")
                let pi = UIPrintInfo.printInfo()
                pi.outputType = UIPrintInfoOutputType.General
                pi.jobName = Constants.Print;
                pi.orientation = UIPrintInfoOrientation.Portrait
                pi.duplex = UIPrintInfoDuplex.LongEdge
                
                let pic = UIPrintInteractionController.sharedPrintController()
                pic.printInfo = pi
                pic.showsPageRange = true
                
                //Never could get this to work:
                //            pic?.printFormatter = webView?.viewPrintFormatter()
                
                pic.printingItem = printURL
                pic.presentFromBarButtonItem(navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { //  && (self.view.window != nil)
            dismissViewControllerAnimated(true, completion: nil)
            
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func seekingTimer()
    {
        setupPlayingInfoCenter()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        print("remoteControlReceivedWithEvent")
        
        switch event!.subtype {
        case UIEventSubtype.MotionShake:
            print("RemoteControlShake")
            break
            
        case UIEventSubtype.None:
            print("RemoteControlNone")
            break
            
        case UIEventSubtype.RemoteControlStop:
            print("RemoteControlStop")
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
            break
            
        case UIEventSubtype.RemoteControlPlay:
            print("RemoteControlPlay")
            Globals.mpPlayer?.play()
            Globals.playerPaused = false
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlPause:
            print("RemoteControlPause")
            Globals.mpPlayer?.pause()
            Globals.playerPaused = true
            updateCurrentTimeExact()
            break
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            print("RemoteControlTogglePlayPause")
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            break
            
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("RemoteControlPreviousTrack")
            break
            
        case UIEventSubtype.RemoteControlNextTrack:
            print("RemoteControlNextTrack")
            break
            
            //The lock screen time elapsed/remaining don't track well with seeking
            //But at least this has them moving in the right direction.
            
        case UIEventSubtype.RemoteControlBeginSeekingBackward:
            print("RemoteControlBeginSeekingBackward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingBackward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingBackward:
            print("RemoteControlEndSeekingBackward")
            Globals.mpPlayer?.endSeeking()
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlBeginSeekingForward:
            print("RemoteControlBeginSeekingForward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingForward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingForward:
            print("RemoteControlEndSeekingForward")
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            Globals.mpPlayer?.endSeeking()
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
            case Constants.Print:
                printSermon(selectedSermon)
                break
                
            case Constants.Open_in_Browser:
                var url:NSURL?
                
                switch selectedSermon!.showing! {
                case Constants.NOTES:
                    url = selectedSermon!.notesURL
                    break
                case Constants.SLIDES:
                    url = selectedSermon!.slidesURL
                    break
                    
                default:
                    break
                }
                
                if  url != nil {
                    if (UIApplication.sharedApplication().canOpenURL(url!)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.sharedApplication().openURL(url!)
                    } else {
                        networkUnavailable("Unable to open in browser at: \(url)")
                    }
                }
                break

            case Constants.Check_for_Update:
                if selectedSermon!.showingSlides() {
                    selectedSermon?.slidesDownload?.deleteDownload()
                }
                if selectedSermon!.showingNotes() {
                    selectedSermon?.notesDownload?.deleteDownload()
                }
                
                wkWebView?.hidden = true
                wkWebView?.removeFromSuperview()
                
                webView.bringSubviewToFront(activityIndicator)
                
                activityIndicator.hidden = false
                activityIndicator.startAnimating()
                
                setupWKWebView()
                
                wkWebView?.hidden = true
                
                loadNotesOrSlides()
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func actions()
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = "Actions"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                if (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) || (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) {
                    actionMenu.append(Constants.Print)
                    actionMenu.append(Constants.Open_in_Browser)
                    
                    if Globals.cacheDownloads && !showScripture {
                        actionMenu.append(Constants.Check_for_Update)
                    }
                }
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
//    func actions()
//    {
//        //        print("action!")
//        
//        //In case we have one already showing
//        dismissViewControllerAnimated(true, completion: nil)
//        
//        // Put up an action sheet
//        
//        let alert = UIAlertController(title: Constants.EMPTY_STRING,
//            message: Constants.EMPTY_STRING,
//            preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        var action : UIAlertAction
//        
//        if (selectedSermon!.hasNotes() || selectedSermon!.hasSlides()) {
//            action = UIAlertAction(title:Constants.Print, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("print!")
//                self.printSermon(self.selectedSermon)
////                if Reachability.isConnectedToNetwork() {
////                    self.printSermon(self.selectedSermon)
////                } else {
////                    self.networkUnavailable("Unable to print.)")
////                }
//            })
//            alert.addAction(action)
//            
//            action = UIAlertAction(title:Constants.Open_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//
//                var url:NSURL?
//                
//                switch self.selectedSermon!.showing! {
//                case Constants.NOTES:
//                    url = self.selectedSermon!.notesURL
//                    break
//                    
//                case Constants.SLIDES:
//                    url = self.selectedSermon!.slidesURL
//                    break
//                    
//                default:
//                    break
//                }
//                
//                if url != nil {
//                    if UIApplication.sharedApplication().canOpenURL(url!) {
//                        UIApplication.sharedApplication().openURL(url!)
//                    } else {
//                        self.networkUnavailable("Unable to open in browser: \(url)")
//                    }
////                    if Reachability.isConnectedToNetwork() {
////                        if UIApplication.sharedApplication().canOpenURL(url) {
////                            UIApplication.sharedApplication().openURL(url)
////                        } else {
////                            self.networkUnavailable("Unable to open in browser: \(urlString)")
////                        }
////                    } else {
////                        self.networkUnavailable("Unable to open in browser: \(urlString)")
////                    }
//                }
//            })
//            alert.addAction(action)
//
//            action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
//            })
//            alert.addAction(action)
//
//            //on iPad this is a popover
//            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//            alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
//            
//            presentViewController(alert, animated: true, completion: nil)
//        }
//    }
    
    private func setupActionButton()
    {
        if (selectedSermon != nil) {
            self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actions"), animated: true)
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
            progressIndicator.hidden = true
        }
    }
    
    func setWKZoomScaleThenContentOffset(wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")
//
//        print("contentInset: \(webView.scrollView.contentInset)")
//        print("contentSize: \(webView.scrollView.contentSize)")

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        })
    }
    
    func webView(wkWebView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        setupWKZoomScaleAndContentOffset(wkWebView)

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.hidden = true
            
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            self.progressIndicator.hidden = true
            
            wkWebView.hidden = false
        })
    }
    
    func setupWKZoomScaleAndContentOffset()
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
    }
    
    func setupWKZoomScaleAndContentOffset(wkWebView: WKWebView?)
    {
        if !showScripture && (wkWebView != nil) && (selectedSermon != nil) {
            var zoomScaleStr:String?
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO]
                zoomScaleStr = selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE]
                break
                
            case Constants.SLIDES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO]
                zoomScaleStr = selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE]
                break
                
            default:
                break
            }
            
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
            
            let contentOffset = CGPointMake(CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width * zoomScale),
                                            CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height * zoomScale))
            
            setWKZoomScaleThenContentOffset(wkWebView!, scale: zoomScale, offset: contentOffset)
        }
    }
    
    func setupWKContentOffset(wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
        print("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if !showScripture && (wkWebView != nil) && (selectedSermon != nil) {
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO]
                break
                
            case Constants.SLIDES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO]
                break
                
            default:
                break
            }
            
            var contentOffsetXRatio:CGFloat = 0.0
            var contentOffsetYRatio:CGFloat = 0.0
            
            if let ratio = contentOffsetXRatioStr {
                contentOffsetXRatio = CGFloat(Float(ratio)!)
            }
            
            if let ratio = contentOffsetYRatioStr {
                contentOffsetYRatio = CGFloat(Float(ratio)!)
            }
            
            let contentOffset = CGPointMake(CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width), //
                                            CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height)) //
            
            print("About to setContentOffset with: \(contentOffset)")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            })
            
            print("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
//        print("\(wkWebView!.scrollView.contentOffset)")
//        print("\(wkWebView!.scrollView.zoomScale)")
        
        if !showScripture && (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) && (selectedSermon != nil) &&
            (wkWebView != nil) && (!wkWebView!.loading) && (wkWebView!.URL != nil) {
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                if (!wkWebView!.loading) {
                    selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            case Constants.SLIDES:
                if (!wkWebView!.loading) {
                    selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            default:
                break
            }
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (Globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        if (self.view.window == nil) {
            return
        }
        
        print("Size: \(size)")
        
        switch UIApplication.sharedApplication().applicationState {
        case UIApplicationState.Active:
            setupSplitViewController()
            
            print("Before animateAlongsideTransition: \(wkWebView?.scrollView.contentOffset)")
            
            captureContentOffsetAndZoomScale()
            fallthrough
            
        case UIApplicationState.Background:
            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
                }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    self.setupWKContentOffset(self.wkWebView)
            }
            break
            
        default:
            break
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true // navigationController?.navigationBarHidden ==
    }
    
//    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
//        return UIStatusBarAnimation.Slide
//    }

//    func tap()
//    {
//        navigationController?.setNavigationBarHidden(!navigationController!.navigationBar.hidden, animated: splitViewController != nil)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
//        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tap"))

        navigationController?.setToolbarHidden(true, animated: true)

//        setupWKWebView()
//        setupActionButton()
        
        // Do any additional setup after loading the view.
    }
    
//    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
////        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
//        
////        let filename = downloadTask.taskDescription!
//        
////        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
//        
//        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
//    }
//    
//    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
//    {
////        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
//        
//        let filename = downloadTask.taskDescription!
//        
////        print("filename: \(filename) location: \(location)")
//        
//        let fileManager = NSFileManager.defaultManager()
//        
//        //Get documents directory URL
//        let destinationURL = cachesURL()?.URLByAppendingPathComponent(filename)
//        // Check if file exist
//        if (fileManager.fileExistsAtPath(destinationURL!.path!)){
//            do {
//                try fileManager.removeItemAtURL(destinationURL!)
//            } catch _ {
//                print("failed to remove old file")
//            }
//        }
//        
//        do {
//            try fileManager.copyItemAtURL(location, toURL: destinationURL!)
//            try fileManager.removeItemAtURL(location)
//        } catch _ {
//            print("failed to copy new file to Documents")
//        }
//        
//        // URL call back does NOT run on the main queue
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            if (filename == self.selectedSermon?.notes) {
//                if #available(iOS 9.0, *) {
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                        self.wkWebView?.loadFileURL(destinationURL!, allowingReadAccessToURL: destinationURL!)
//                        
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            
//                        })
//                    })
//                } else {
//                    // Fallback on earlier versions
//                }
//                //                let url = self.fileURLForWKWebView(filename)
//                //                print("\(url)")
//                //                self.sermonNotesWebView!.loadRequest(NSURLRequest(URL: url))
//            }
//            
//            if (filename == self.selectedSermon?.slides) {
//                if #available(iOS 9.0, *) {
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                        self.wkWebView?.loadFileURL(destinationURL!, allowingReadAccessToURL: destinationURL!)
//                        
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            
//                        })
//                    })
//                } else {
//                    // Fallback on earlier versions
//                }
//                //                let url = self.fileURLForWKWebView(filename)
//                //                print("\(url)")
//                //                self.sermonSlidesWebView!.loadRequest(NSURLRequest(URL: url))
//            }
//        })
//        
//    }
//    
//    func removeTempFiles()
//    {
//        // Clean up temp directory for cancelled downloads
//        let fileManager = NSFileManager.defaultManager()
//        let path = NSTemporaryDirectory()
//        do {
//            let array = try fileManager.contentsOfDirectoryAtPath(path)
//            
//            for string in array {
//                print("Deleting: \(string)")
//                try fileManager.removeItemAtPath(path + string)
//            }
//        } catch _ {
//        }
//    }
//    
//    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
//        if (error != nil) {
//            print("Download failed for: \(session.description)")
//        } else {
//            print("Download succeeded for: \(session.description)")
//        }
//        
//        //        removeTempFiles()
//        
//        let filename = task.taskDescription
//        print("filename: \(filename!) error: \(error)")
//        
//        session.invalidateAndCancel()
//        
//        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
//        //            Globals.downloadTasks.removeAtIndex(taskIndex)
//        //        }
//        
//        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//    }
//    
//    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
//    {
//        
//    }
    
    func downloading()
    {
        var download:Download?
        
        //There is a big flaw in the use of .showing - it assumes only one of slides or notes is downloading when, for TPS/CBC,
        //they both would be.  In that case we would need the timer to persist until the last one finishes, or have one timers for each.
        
        switch selectedSermon!.showing! {
        case Constants.SLIDES:
            print("slides")
            download = selectedSermon?.slidesDownload
            if (download?.state == .downloading) {
                progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
            }
            if (download?.state == .downloaded) {
                if #available(iOS 9.0, *) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        self.wkWebView?.loadFileURL(self.selectedSermon!.slidesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.slidesFileSystemURL!)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            self.progressIndicator.progress = 0.0
                            self.progressIndicator.hidden = true
                        })
                    })
                } else {
                    // Fallback on earlier versions
                }
            }
            break
            
        case Constants.NOTES:
            print("notes")
            download = selectedSermon?.notesDownload
            if (download?.state == .downloading) {
                progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
            }
            if (download?.state == .downloaded) {
                if #available(iOS 9.0, *) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        self.wkWebView?.loadFileURL(self.selectedSermon!.notesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.notesFileSystemURL!)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            self.progressIndicator.progress = 0.0
                            self.progressIndicator.hidden = true
                        })
                    })
                } else {
                    // Fallback on earlier versions
                }
            }
            break
            
        default:
            break
        }
        
        if (download != nil) {
            print("totalBytesWritten: \(download!.totalBytesWritten)")
            print("totalBytesExpectedToWrite: \(download!.totalBytesExpectedToWrite)")
            
            switch download!.state {
            case .none:
                print(".none")
                break
            case .downloading:
                print(".downloading")
                break
            case .downloaded:
                print(".downloaded")
                break
            }
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
    
    func loadScripture()
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            print(self.url?.absoluteString)
            let request = NSURLRequest(URL: self.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
            self.wkWebView?.loadRequest(request)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.activityIndicator.stopAnimating()
                self.activityIndicator.hidden = true
                
                self.progressIndicator.progress = 0.0
                self.progressIndicator.hidden = true
                
                self.loadTimer?.invalidate()
                self.loadTimer = nil
            })
        })
    }
    
    func loadNotesOrSlides()
    {
        if #available(iOS 9.0, *) {
            if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
                var destinationURL:NSURL?
                
                switch selectedSermon!.showing! {
                case Constants.VIDEO:
                    fallthrough
                    
                case Constants.NOTES:
                    destinationURL = selectedSermon!.notesFileSystemURL!
                    break
                    
                case Constants.SLIDES:
                    destinationURL = selectedSermon!.slidesFileSystemURL!
                    break
                    
                default:
                    break
                }
                
                if (NSFileManager.defaultManager().fileExistsAtPath(destinationURL!.path!)){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        self.wkWebView?.loadFileURL(destinationURL!, allowingReadAccessToURL: destinationURL!)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            
                            self.progressIndicator.progress = 0.0
                            self.progressIndicator.hidden = true
                            
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                        })
                    })
                } else {
                    switch selectedSermon!.showing! {
                    case Constants.VIDEO:
                        fallthrough
                        
                    case Constants.NOTES:
                        activityIndicator.hidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = selectedSermon!.notesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.notesDownload!.totalBytesWritten) / Float(selectedSermon!.notesDownload!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.hidden = false
                        
                        if loadTimer == nil {
                            loadTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "downloading", userInfo: nil, repeats: true)
                        }
                        
                        selectedSermon?.notesDownload?.download()
                        break
                        
                    case Constants.SLIDES:
                        activityIndicator.hidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = selectedSermon!.slidesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.slidesDownload!.totalBytesWritten) / Float(selectedSermon!.slidesDownload!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.hidden = false
                        
                        if loadTimer == nil {
                            loadTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "downloading", userInfo: nil, repeats: true)
                        }
                        
                        selectedSermon?.slidesDownload?.download()
                        break
                        
                    default:
                        break
                    }
                }
            } else {
                var url:NSURL?
                
                switch selectedSermon!.showing! {
                case Constants.VIDEO:
                    fallthrough
                    
                case Constants.NOTES:
                    url = selectedSermon!.notesURL
                    break
                    
                case Constants.SLIDES:
                    url = selectedSermon!.slidesURL
                    break
                    
                default:
                    break
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.bringSubviewToFront(self.activityIndicator)
                        
                        self.activityIndicator.hidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.progress = 0.0
                        self.progressIndicator.hidden = false
                        
                        if self.loadTimer == nil {
                            self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                        }
                    })
                    
                    let request = NSURLRequest(URL: url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    self.wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
                })
            }
        } else {
            var url:NSURL?
            
            switch selectedSermon!.showing! {
            case Constants.VIDEO:
                fallthrough
                
            case Constants.NOTES:
                url = selectedSermon!.notesURL
                break
                
            case Constants.SLIDES:
                url = selectedSermon!.slidesURL
                break
                
            default:
                break
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.webView.bringSubviewToFront(self.activityIndicator)
                    
                    self.activityIndicator.hidden = false
                    self.activityIndicator.startAnimating()
                    
                    self.progressIndicator.progress = 0.0
                    self.progressIndicator.hidden = false
                    
                    if self.loadTimer == nil {
                        self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                    }
                })
                
                let request = NSURLRequest(URL: url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                self.wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = selectedSermon!.title!
        
        setupActionButton()

//        webView.bringSubviewToFront(activityIndicator)

        activityIndicator.hidden = false
        activityIndicator.startAnimating()

        setupWKWebView()
        
        wkWebView?.hidden = true

        if showScripture {
            loadScripture()
        } else {
            loadNotesOrSlides()
        }
//        super.viewWillAppear(animated)
//        
//        navigationItem.title = selectedSermon!.title!
//
//        view.bringSubviewToFront(activityIndicator)
//        activityIndicator.hidden = false
//        activityIndicator.startAnimating()
//        
//        wkWebView?.hidden = true
//        
//        progressIndicator.hidden = true
//
//        if showScripture {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                let request = NSURLRequest(URL: self.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//                self.wkWebView?.loadRequest(request)
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    //                    self.activityIndicator.stopAnimating()
//                    //                    self.activityIndicator.hidden = true
//                    
//                    //                            self.progressIndicator.progress = 0.0
//                    //                            self.progressIndicator.hidden = true
//                    //
//                    //                            self.loadTimer?.invalidate()
//                    //                            self.loadTimer = nil
//                })
//            })
//            return
//        }
//        
//        if #available(iOS 9.0, *) {
//            if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
//                var destinationURL:NSURL?
//                
//                switch selectedSermon!.showing! {
//                case Constants.NOTES:
//                    destinationURL = selectedSermon!.notesFileSystemURL!
//                    break
//                case Constants.SLIDES:
//                    destinationURL = selectedSermon!.slidesFileSystemURL!
//                    break
//                    
//                default:
//                    break
//                }
//                
//                if (NSFileManager.defaultManager().fileExistsAtPath(destinationURL!.path!)){
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                        self.wkWebView?.loadFileURL(destinationURL!, allowingReadAccessToURL: destinationURL!)
//
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            self.activityIndicator.stopAnimating()
//                            self.activityIndicator.hidden = true
//                            
//                            self.progressIndicator.progress = 0.0
//                            self.progressIndicator.hidden = true
//                            
//                            self.loadTimer?.invalidate()
//                            self.loadTimer = nil
//                        })
//                    })
//                } else {
//                    switch selectedSermon!.showing! {
//                    case Constants.NOTES:
//                        activityIndicator.hidden = false
//                        activityIndicator.startAnimating()
//                        
//                        progressIndicator.progress = selectedSermon!.notesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.notesDownload!.totalBytesWritten) / Float(selectedSermon!.notesDownload!.totalBytesExpectedToWrite) : 0.0
//                        progressIndicator.hidden = false
//                        if loadTimer == nil {
//                            loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "downloading", userInfo: nil, repeats: true)
//                        }
//                        selectedSermon!.notesDownload?.download()
//                        break
//                        
//                    case Constants.SLIDES:
//                        activityIndicator.hidden = false
//                        activityIndicator.startAnimating()
//                        
//                        progressIndicator.progress = selectedSermon!.slidesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.slidesDownload!.totalBytesWritten) / Float(selectedSermon!.slidesDownload!.totalBytesExpectedToWrite) : 0.0
//                        progressIndicator.hidden = false
//                        if loadTimer == nil {
//                            loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "downloading", userInfo: nil, repeats: true)
//                        }
//                        selectedSermon!.slidesDownload?.download()
//                        break
//                        
//                    default:
//                        break
//                    }
//                }
//            } else {
//                var url:NSURL?
//                
//                switch selectedSermon!.showing! {
//                case Constants.NOTES:
//                    url = selectedSermon!.notesURL
//                    break
//                case Constants.SLIDES:
//                    url = selectedSermon!.slidesURL
//                    break
//                    
//                default:
//                    break
//                }
//                
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        self.view.bringSubviewToFront(self.activityIndicator)
//
//                        self.activityIndicator.hidden = false
//                        self.activityIndicator.startAnimating()
//                        
//                        self.progressIndicator.progress = 0.0
//                        self.progressIndicator.hidden = false
//                        if self.loadTimer == nil {
//                            self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
//                        }
//                    })
//                    
//                    let request = NSURLRequest(URL: url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//                    self.wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
//                })
//            }
//        } else {
//            var url:NSURL?
//            
//            switch selectedSermon!.showing! {
//            case Constants.NOTES:
//                url = selectedSermon!.notesURL
//                break
//            case Constants.SLIDES:
//                url = selectedSermon!.slidesURL
//                break
//                
//            default:
//                break
//            }
//            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.view.bringSubviewToFront(self.activityIndicator)
//                    
//                    self.activityIndicator.hidden = false
//                    self.activityIndicator.startAnimating()
//                    
//                    self.progressIndicator.progress = 0.0
//                    self.progressIndicator.hidden = false
//                    if self.loadTimer == nil {
//                        self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
//                    }
//                })
//                
//                let request = NSURLRequest(URL: url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//                self.wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
//            })
//        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.hidesBackButton = false
        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        navigationController?.navigationBar.backItem?.title = Constants.Back
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Remove the next line and the app will crash
        wkWebView?.scrollView.delegate = nil
        
//        captureContentOffsetAndZoomScale()
        
        loadTimer?.invalidate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
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
