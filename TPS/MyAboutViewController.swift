//
//  MyAboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MapKit
import MessageUI

class MyAboutViewController: UIViewController, UIPopoverPresentationControllerDelegate, MFMailComposeViewControllerDelegate
{
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
    
    @IBOutlet weak var tpPageControl: UIPageControl!
    
    @IBAction func tpPageControlAction(sender: UIPageControl)
    {
        flipView(tpView)
    }

    @IBOutlet weak var cbcPageControl: UIPageControl!
    
    @IBAction func cbcPageControlAction(sender: UIPageControl)
    {
        flipView(cbcView)
    }
    
    var item:MKMapItem?
    
    private func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.", delegate: self, cancelButtonTitle:Constants.Okay)
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func email()
    {
        let bodyString = String()
        
        //        bodyString = bodyString + addressStringHTML()
        
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([Constants.CBC_EMAIL])
        mailComposeViewController.setSubject(Constants.EMAIL_SUBJECT)
        //        mailComposeViewController.setMessageBody(bodyString, isHTML: false)
        mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        
        if MFMailComposeViewController.canSendMail() {
            presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    private func openWebSite(urlString:String)
    {
        if let url = NSURL(string:urlString) {
            if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(url)) {
                UIApplication.sharedApplication().openURL(url)
            } else {
                let alert = UIAlertController(title: Constants.Network_Unavailable,
                    message: Constants.EMPTY_STRING,
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)

                presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func openInGoogleMaps()
    {
        let urlAddress = Constants.CBC_FULL_ADDRESS.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
            let querystring = "comgooglemaps://?q="+urlAddress
            UIApplication.sharedApplication().openURL(NSURL(string:querystring)!)
        } else {
            let alert = UIAlertController(title: "Google Maps is not available",
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func openInAppleMaps()
    {
        item?.name = Constants.CBC_LONG
        item?.openInMapsWithLaunchOptions(nil)
    }
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    @IBAction func actions(sender: UIBarButtonItem) {
//        print("action!")
        
        // Put up an action sheet
        
        let alert = UIAlertController(title: Constants.EMPTY_STRING,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        action = UIAlertAction(title: "E-mail CBC", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.email()
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: "CBC website", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openWebSite(Constants.CBC_WEBSITE)
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: "CBC in Google Maps", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openInGoogleMaps()
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: "CBC in Apple Maps", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openInAppleMaps()
            })
        alert.addAction(action)
        
        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in

            })
        alert.addAction(action)
        
        //on iPad this is a popover
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = actionButton
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBOutlet weak var versionLabel: UILabel!
    private func setVersion()
    {
        if let dict = NSBundle.mainBundle().infoDictionary {
            if let appVersion = dict["CFBundleShortVersionString"] as? String {
                if let buildNumber = dict["CFBundleVersion"] as? String {
                    versionLabel.text = appVersion + "." + buildNumber
                    versionLabel.sizeToFit()
                }
            }
        }
    }

    //iPhone only BELOW
    @IBOutlet weak var tpView: UIView!
    @IBOutlet weak var cbcView: UIView!
    
    @IBOutlet weak var tomPenningtonImage: UIImageView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flipGRView:")
                tomPenningtonImage.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                tomPenningtonImage.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                tomPenningtonImage.addGestureRecognizer(swipeLeft)
            }
        }
    }
    
    @IBOutlet weak var tomPenningtonBio: UITextView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flipGRView:")
                tomPenningtonBio.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                tomPenningtonBio.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                tomPenningtonBio.addGestureRecognizer(swipeLeft)
            }
        }
    }

    @IBOutlet weak var cbcDescription: UITextView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flipGRView:")
                cbcDescription.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                cbcDescription.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                cbcDescription.addGestureRecognizer(swipeLeft)
            }
        }
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            if (splitViewController == nil) {
                let tap = UITapGestureRecognizer(target: self, action: "flipGRView:")
                mapView.addGestureRecognizer(tap)
                
                let swipeRight = UISwipeGestureRecognizer(target: self, action: "flipFromLeft:")
                swipeRight.direction = UISwipeGestureRecognizerDirection.Right
                mapView.addGestureRecognizer(swipeRight)
                
                let swipeLeft = UISwipeGestureRecognizer(target: self, action: "flipFromRight:")
                swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
                mapView.addGestureRecognizer(swipeLeft)
            }
        }
    }
    
    func flipFromLeft(sender: UIGestureRecognizer) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        
        var view:UIView?
        
        switch sender.view! {
        case tomPenningtonImage:
            view = tpView
            break

        case tomPenningtonBio:
            view = tpView
            break
            
        case cbcDescription:
            view = cbcView
            break
            
        case mapView:
            view = cbcView
            break
            
        default:
            break
        }
        
        let frontView = view!.subviews[0]
        let backView = view!.subviews[1]
        
        if let textView = view!.subviews[0] as? UITextView {
            textView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(view!, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            frontView.hidden = false
            view?.bringSubviewToFront(frontView)
            backView.hidden = true
            
            switch frontView {
            case self.tomPenningtonImage:
                self.tpPageControl.currentPage = 0
                break
                
            case self.tomPenningtonBio:
                self.tpPageControl.currentPage = 1
                break
                
            case self.cbcDescription:
                self.cbcPageControl.currentPage = 0
                break
                
            case self.mapView:
                self.cbcPageControl.currentPage = 1
                break
                
            default:
                print("\(sender)")
                print("no tap match!")
                break
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flipFromRight(sender: UIGestureRecognizer) {
        //        println("tap")
        
        // set a transition style
        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight

        var view:UIView?
        
        switch sender.view! {
        case tomPenningtonImage:
            view = tpView
            break
            
        case tomPenningtonBio:
            view = tpView
            break
            
        case cbcDescription:
            view = cbcView
            break
            
        case mapView:
            view = cbcView
            break
            
        default:
            break
        }

        let frontView = view!.subviews[0]
        let backView = view!.subviews[1]
        
        if let textView = view!.subviews[0] as? UITextView {
            textView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(view!, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            frontView.hidden = false
            view?.bringSubviewToFront(frontView)
            backView.hidden = true
            
            switch frontView {
            case self.tomPenningtonImage:
                self.tpPageControl.currentPage = 0
                break
                
            case self.tomPenningtonBio:
                self.tpPageControl.currentPage = 1
                break
                
            case self.cbcDescription:
                self.cbcPageControl.currentPage = 0
                break
                
            case self.mapView:
                self.cbcPageControl.currentPage = 1
                break
                
            default:
                print("\(sender)")
                print("no tap match!")
                break
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flipView(sender: UIView) {
        //        println("tap")
        
        // set a transition style
        var transitionOptions:UIViewAnimationOptions!
        
        let frontView = sender.subviews[0]
        let backView = sender.subviews[1]
        
        switch backView {
        case tomPenningtonImage:
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
            break
            
        case tomPenningtonBio:
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            break
            
        case cbcDescription:
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
            break
            
        case mapView:
            transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            break
            
        default:
            print("\(sender)")
            print("no tap match!")
            break
        }
        
        if let textView = view!.subviews[0] as? UITextView {
            textView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
            //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
        }
        
        UIView.transitionWithView(sender, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            //            println("\(self.seriesArtAndDescription.subviews.count)")
            //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
            frontView.hidden = false
            sender.bringSubviewToFront(frontView)
            backView.hidden = true
            
            switch frontView {
            case self.tomPenningtonImage:
                self.tpPageControl.currentPage = 0
                break
                
            case self.tomPenningtonBio:
                self.tpPageControl.currentPage = 1
                break
                
            case self.cbcDescription:
                self.cbcPageControl.currentPage = 0
                break
                
            case self.mapView:
                self.cbcPageControl.currentPage = 1
                break
                
            default:
                print("\(sender)")
                print("no tap match!")
                break
            }
            
            }, completion: { finished in
                
        })
        
    }
    
    func flipGRView(sender: UIGestureRecognizer) {
        //        println("tap")
        if (sender.view != nil) {
            // set a transition style
            var transitionOptions:UIViewAnimationOptions!
            var parentView:UIView?
            
            switch sender.view! {
            case tomPenningtonImage:
                parentView = tpView
                transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
                break
                
            case tomPenningtonBio:
                parentView = tpView
                transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
                break
                
            case cbcDescription:
                parentView = cbcView
                transitionOptions = UIViewAnimationOptions.TransitionFlipFromRight
                break
                
            case mapView:
                parentView = cbcView
                transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
                break
                
            default:
                print("\(sender)")
                print("no tap match!")
                break
            }
            
            let frontView = parentView!.subviews[0]
            let backView = parentView!.subviews[1]

            if let textView = parentView!.subviews[0] as? UITextView {
                textView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
                //            view.scrollRangeToVisible(NSMakeRange(0, 0))  // snaps in to place because it animates by default
            }
            
            UIView.transitionWithView(parentView!, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
                //            println("\(self.seriesArtAndDescription.subviews.count)")
                //The following assumes there are only 2 subviews, 0 and 1, and this alternates between them.
                frontView.hidden = false
                parentView!.bringSubviewToFront(frontView)
                backView.hidden = true
                
                switch frontView {
                case self.tomPenningtonImage:
                    self.tpPageControl.currentPage = 0
                    break
                    
                case self.tomPenningtonBio:
                    self.tpPageControl.currentPage = 1
                    break
                    
                case self.cbcDescription:
                    self.cbcPageControl.currentPage = 0
                    break
                    
                case self.mapView:
                    self.cbcPageControl.currentPage = 1
                    break
                    
                default:
                    print("\(sender)")
                    print("no tap match!")
                    break
                }
                
                }, completion: { finished in
                    
            })
        }
    }
    //iPhone only ABOVE

    //Only on iPad
    @IBOutlet weak var cbcContactInformation: UITextView!
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.  E.g.
    }
    
//    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.None;
//    }
    
//    func help(sender:UIBarButtonItem) {
//        print("help!")
//    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setVersion()
        
        if (splitViewController == nil) {
            tomPenningtonImage.hidden = false
            tomPenningtonBio.hidden = true
            
            cbcDescription.hidden = false
            mapView.hidden = true
        }
        
//        var rightBarButtonItems = [UIBarButtonItem]()
//        rightBarButtonItems.append(navigationItem.rightBarButtonItem!)
//        rightBarButtonItems.append(UIBarButtonItem(title: "Help", style: UIBarButtonItemStyle.Plain, target: self, action: "help:"))
//        navigationItem.rightBarButtonItems = rightBarButtonItems
        
        tomPenningtonBio.scrollRangeToVisible(NSMakeRange(0,0))
        cbcDescription.scrollRangeToVisible(NSMakeRange(0,0))
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(Constants.CBC_FULL_ADDRESS, completionHandler:{(placemarks, error) -> Void in
            if let placemark = placemarks?[0] {
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                
                let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                pointAnnotation.title = Constants.CBC_LONG
                
                self.mapView?.addAnnotation(pointAnnotation)
                self.mapView?.setCenterCoordinate(coordinates, animated: false)
                self.mapView?.selectAnnotation(pointAnnotation, animated: false)
                self.mapView?.zoomEnabled = true
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegionMakeWithDistance(coordinates, 10000, 10000)
                let adjustedRegion = self.mapView?.regionThatFits(viewRegion)
                self.mapView?.setRegion(adjustedRegion!, animated: false)
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        //This only matters on an iPhone where the text may have scrolled
//        tomPenningtonBio.scrollRectToVisible(CGRectMake(0, 0, 50, 50), animated:false)
//        cbcDescription.scrollRectToVisible(CGRectMake(0, 0, 50, 50), animated:false)
        tomPenningtonBio.scrollRangeToVisible(NSMakeRange(0,0))
        cbcDescription.scrollRangeToVisible(NSMakeRange(0,0))
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
