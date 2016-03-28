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
            scrollViewDidEndDecelerating(scrollView)
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
        
        wkWebView?.hidden = true

        wkWebView?.multipleTouchEnabled = true
        
        wkWebView?.scrollView.scrollsToTop = false
        
        wkWebView?.scrollView.delegate = self

        wkWebView?.navigationDelegate = self
        wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        webView.addSubview(wkWebView!)

//        webView.bringSubviewToFront(wkWebView!)
        
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
            
            printURL = sermon?.downloads[sermon!.showing!]?.url
            
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

                url = selectedSermon?.downloads[selectedSermon!.showing!]?.url
                
                if  url != nil {
                    if (UIApplication.sharedApplication().canOpenURL(url!)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.sharedApplication().openURL(url!)
                    } else {
                        networkUnavailable("Unable to open in browser at: \(url)")
                    }
                }
                break

            case Constants.Check_for_Update:
                selectedSermon?.downloads[selectedSermon!.showing!]?.deleteDownload()

                wkWebView?.hidden = true
                wkWebView?.removeFromSuperview()
                
                webView.bringSubviewToFront(activityIndicator)
                
                activityIndicator.hidden = false
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
    
    private func setupActionButton()
    {
        if (selectedSermon != nil) {
            self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: #selector(WebViewController.actions)), animated: true)
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

            contentOffsetXRatioStr = selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_X_RATIO]
            contentOffsetYRatioStr = selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_Y_RATIO]
            zoomScaleStr = selectedSermon?.settings?[selectedSermon!.showing! + Constants.ZOOM_SCALE]

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

            contentOffsetXRatioStr = selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_X_RATIO]
            contentOffsetYRatioStr = selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_Y_RATIO]

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

            selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
            
            selectedSermon?.settings?[selectedSermon!.showing! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
            
            selectedSermon?.settings?[selectedSermon!.showing! + Constants.ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
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
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        print("Size: \(size)")
        
        switch UIApplication.sharedApplication().applicationState {
        case UIApplicationState.Active:
            setupSplitViewController()
            
            print("Before animateAlongsideTransition: \(wkWebView?.scrollView.contentOffset)")
            
//            captureContentOffsetAndZoomScale()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        // Do any additional setup after loading the view.
    }
    
    func downloading()
    {
        var download:Download?
        
        //There is a big flaw in the use of .showing - it assumes only one of slides or notes is downloading when, for TPS/CBC,
        //they both would be.  In that case we would need the timer to persist until the last one finishes, or have one timers for each.
        
        download = selectedSermon?.downloads[selectedSermon!.showing!]

//        if (download != nil) {
//            print("totalBytesWritten: \(download!.totalBytesWritten)")
//            print("totalBytesExpectedToWrite: \(download!.totalBytesExpectedToWrite)")
//        }

        switch download!.state {
        case .none:
            print(".none")
            self.loadTimer?.invalidate()
            self.loadTimer = nil
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.hidden = true
            
            self.progressIndicator.progress = 0.0
            self.progressIndicator.hidden = true
            break
        
        case .downloading:
            print(".downloading")
            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
            break

        case .downloaded:
            print(".downloaded")
            progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
//            print(progressIndicator.progress)

            if #available(iOS 9.0, *) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    self.wkWebView?.loadFileURL(download!.fileSystemURL!, allowingReadAccessToURL: download!.fileSystemURL!)
                    
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
    
    func loadScripture()
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.webView.bringSubviewToFront(self.activityIndicator)
                
                self.activityIndicator.hidden = false
                self.activityIndicator.startAnimating()
                
                self.progressIndicator.progress = 0.0
                self.progressIndicator.hidden = false
                
                if self.loadTimer == nil {
                    self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
                }
            })

            let request = NSURLRequest(URL: self.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
            self.wkWebView?.loadRequest(request)
        })
    }
    
    func loadDocument()
    {
        if #available(iOS 9.0, *) {
            if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
                var destinationURL:NSURL?
                
                destinationURL = selectedSermon?.downloads[selectedSermon!.showing!]?.fileSystemURL

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
                    activityIndicator.hidden = false
                    activityIndicator.startAnimating()
                    
                    let download = selectedSermon!.downloads[selectedSermon!.showing!]
                    
                    progressIndicator.progress = download!.totalBytesExpectedToWrite != 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
                    progressIndicator.hidden = false
                    
                    if loadTimer == nil {
                        loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.DOWNLOADING_TIMER_INTERVAL, target: self, selector: #selector(WebViewController.downloading), userInfo: nil, repeats: true)
                    }

                    download?.download()
                }
            } else {
                var url:NSURL?
                
                url = selectedSermon?.downloads[selectedSermon!.showing!]?.url

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.webView.bringSubviewToFront(self.activityIndicator)
                        
                        self.activityIndicator.hidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.progress = 0.0
                        self.progressIndicator.hidden = false
                        
                        if self.loadTimer == nil {
                            self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
                        }
                    })
                    
                    let request = NSURLRequest(URL: url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    self.wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
                })
            }
        } else {
            var url:NSURL?
            
            url = selectedSermon?.downloads[selectedSermon!.showing!]?.url

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.webView.bringSubviewToFront(self.activityIndicator)
                    
                    self.activityIndicator.hidden = false
                    self.activityIndicator.startAnimating()
                    
                    self.progressIndicator.progress = 0.0
                    self.progressIndicator.hidden = false
                    
                    if self.loadTimer == nil {
                        self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(WebViewController.loading), userInfo: nil, repeats: true)
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

        setupWKWebView()

        webView.bringSubviewToFront(activityIndicator)
        
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        if showScripture {
            loadScripture()
        } else {
            loadDocument()
        }
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
