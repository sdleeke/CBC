//
//  AboutViewController.swift
//  TWU
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MapKit
import MessageUI

class AboutViewController: UIViewController, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate, MFMailComposeViewControllerDelegate
{
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
    
    @IBOutlet weak var liveStreamButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
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
            if (UIApplication.sharedApplication().canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.sharedApplication().openURL(url)
            } else {
                let alert = UIAlertController(title: Constants.Network_Error,
                    message: "Unable to open web site: \(urlString)",
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
        
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) { // Reachability.isConnectedToNetwork() &&
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
                
                actionMenu.append(Constants.Email_CBC)
                actionMenu.append(Constants.CBC_in_Apple_Maps)
                actionMenu.append(Constants.CBC_in_Google_Maps)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
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

            case Constants.Email_CBC:
                email()
                break
                
            case Constants.CBC_in_Apple_Maps:
                openInAppleMaps()
                break
                
            case Constants.CBC_in_Google_Maps:
                openInGoogleMaps()
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
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

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        // Do any additional setup after loading the view.  E.g.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setVersion()
        
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
        
        scrollView.flashScrollIndicators()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
    }

    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { //  && (self.view.window != nil)
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
}
