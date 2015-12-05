//
//  WebViewController.swift
//  GTY
//
//  Created by Steve Leeke on 11/10/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    var wkWebView:WKWebView?
    
    var loadTimer:NSTimer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedSermon:Sermon?
    
    override func canBecomeFirstResponder() -> Bool {
        return splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
        }
    }
    
    private func setupWKWebView()
    {
        wkWebView = WKWebView()
        wkWebView?.multipleTouchEnabled = true

        wkWebView?.navigationDelegate = self
        wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        webView.addSubview(wkWebView!)
        
        let centerXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerXNotes)
        
        let centerYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerYNotes)
        
        let widthXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(widthXNotes)
        
        let widthYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(widthYNotes)
        
        wkWebView?.superview?.setNeedsLayout()
    }
    
    func printSermon(sermon:Sermon?)
    {
        if (UIPrintInteractionController.isPrintingAvailable() && (sermon != nil))
        {
            var printURL:String?
            
            switch sermon!.showing! {
            case Constants.NOTES:
                printURL = Constants.BASE_PDF_URL + sermon!.notes!
                break
            case Constants.SLIDES:
                printURL = Constants.BASE_PDF_URL + sermon!.slides!
                break
                
            default:
                break
            }
            
            if (printURL != "") && UIPrintInteractionController.canPrintURL(NSURL(string: printURL!)!) {
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
                
                pic.printingItem = NSURL(string: printURL!)!
                pic.presentFromBarButtonItem(navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    private func networkUnavailable()
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            let alert = UIAlertController(title:Constants.Network_Unavailable,
                message: "",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func actions()
    {
        //        print("action!")
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        // Put up an action sheet
        
        let alert = UIAlertController(title: Constants.EMPTY_STRING,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        if (selectedSermon!.hasNotes() || selectedSermon!.hasSlides()) {
            action = UIAlertAction(title:Constants.Print, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                //            print("print!")
                self.printSermon(self.selectedSermon)
            })
            alert.addAction(action)
            
            action = UIAlertAction(title:Constants.Open_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                let urlString = Constants.BASE_PDF_URL + self.selectedSermon!.notes!
                
                if let url = NSURL(string:urlString) {
                    if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(url)) {
                        UIApplication.sharedApplication().openURL(url)
                    } else {
                        self.networkUnavailable()
                    }
                }
            })
            alert.addAction(action)

            action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            })
            alert.addAction(action)

            //on iPad this is a popover
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
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
        progressIndicator.progress = Float(wkWebView!.estimatedProgress)
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            progressIndicator.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWKWebView()
        setupActionButton()
        
        // Do any additional setup after loading the view.
    }

    func wkSetZoomAndOffset(webView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")
//
//        print("contentInset: \(webView.scrollView.contentInset)")
//        print("contentSize: \(webView.scrollView.contentSize)")

        webView.scrollView.setZoomScale(scale, animated: false)
        webView.scrollView.setContentOffset(offset,animated: false)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        //        print("wkWebViewDidFinishNavigation")
        
        //        print("Frame: \(webView.frame)")
        //        print("Bounds: \(webView.bounds)")
        
        if (selectedSermon != nil) {
            webView.hidden = false
            
            var contentOffsetXRatioIndex:String = Constants.EMPTY_STRING
            var contentOffsetYRatioIndex:String = Constants.EMPTY_STRING
            var zoomScaleIndex:String = Constants.EMPTY_STRING
            
            var contentOffset:CGPoint = CGPointMake(0,0)
            var zoomScale:CGFloat = 1.0
            
            var contentOffsetXRatio:Float = 0.0
            var contentOffsetYRatio:Float = 0.0
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                contentOffsetXRatioIndex = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO

                contentOffsetYRatioIndex = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO
                
                zoomScaleIndex = selectedSermon!.keyBase + Constants.NOTES_ZOOM_SCALE
                break
                
            case Constants.SLIDES:
                contentOffsetXRatioIndex = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO
                
                contentOffsetYRatioIndex = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO
                
                zoomScaleIndex = selectedSermon!.keyBase + Constants.SLIDES_ZOOM_SCALE
                break
                
            default:
                break
            }

            if (Globals.sermonSettings![contentOffsetXRatioIndex] != nil) {
                contentOffsetXRatio = Float(Globals.sermonSettings![contentOffsetXRatioIndex]!)!
            }
            
            if (Globals.sermonSettings![contentOffsetYRatioIndex] != nil) {
                contentOffsetYRatio = Float(Globals.sermonSettings![contentOffsetYRatioIndex]!)!
            }
            
            if (Globals.sermonSettings![zoomScaleIndex] != nil) {
                zoomScale = CGFloat(Float(Globals.sermonSettings![zoomScaleIndex]!)!)
            }

            contentOffset = CGPointMake(    CGFloat(contentOffsetXRatio) * webView.scrollView.contentSize.width * zoomScale,
                CGFloat(contentOffsetYRatio) * webView.scrollView.contentSize.height * zoomScale)
            
            wkSetZoomAndOffset(webView, scale: zoomScale, offset: contentOffset)
        }
        
        loadTimer?.invalidate()
        loadTimer = nil
        progressIndicator.hidden = true
        
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }

    func didRotate()
    {
        var contentOffset:CGPoint = CGPointMake(0,0)
        
        var contentOffsetXRatioIndex:String = Constants.EMPTY_STRING
        var contentOffsetYRatioIndex:String = Constants.EMPTY_STRING
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        //        print("\(wkWebView!.scrollView.contentSize)")
        //        print("\(wkWebView!.scrollView.contentSize)")
        
        switch selectedSermon!.showing! {
        case Constants.NOTES:
            contentOffsetXRatioIndex = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO
            
            contentOffsetYRatioIndex = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO
            break
            
        case Constants.SLIDES:
            contentOffsetXRatioIndex = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO
            
            contentOffsetYRatioIndex = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO
            break
            
        default:
            break
        }
        
        if (Globals.sermonSettings![contentOffsetXRatioIndex] != nil) {
            contentOffsetXRatio = Float(Globals.sermonSettings![contentOffsetXRatioIndex]!)!
        }
        
        if (Globals.sermonSettings![contentOffsetYRatioIndex] != nil) {
            contentOffsetYRatio = Float(Globals.sermonSettings![contentOffsetYRatioIndex]!)!
        }
        
        contentOffset = CGPointMake(    CGFloat(contentOffsetXRatio) * wkWebView!.scrollView.contentSize.width,
                                        CGFloat(contentOffsetYRatio) * wkWebView!.scrollView.contentSize.height)

        wkWebView!.scrollView.setContentOffset(contentOffset, animated: false)
    }
    
    private func captureContentOffsetAndZoomScale()
    {
        if (selectedSermon != nil) {
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                if (!wkWebView!.loading) {
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO] =
                    "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO] =
                    "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            case Constants.SLIDES:
                if (!wkWebView!.loading) {
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO] =
                    "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] =
                    "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            default:
                break
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        captureContentOffsetAndZoomScale()

        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                self.didRotate()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = selectedSermon!.title!

        var stringURL:String?
        
        switch selectedSermon!.showing! {
        case Constants.NOTES:
            stringURL = Constants.BASE_PDF_URL + selectedSermon!.notes!
            break
        case Constants.SLIDES:
            stringURL = Constants.BASE_PDF_URL + selectedSermon!.slides!
            break
            
        default:
            break
        }
       
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        wkWebView?.hidden = true
        
        progressIndicator.progress = 0.0
        progressIndicator.hidden = false
        if loadTimer == nil {
            loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
        }
        
        let request = NSURLRequest(URL: NSURL(string: stringURL!)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
    }

    
//    override func prefersStatusBarHidden() -> Bool
//    {
//        return false
//    }


    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        captureContentOffsetAndZoomScale()
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
