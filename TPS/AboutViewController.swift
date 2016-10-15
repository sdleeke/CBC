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
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    @IBOutlet weak var liveStreamButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var item:MKMapItem?
    
    fileprivate func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check your e-mail configuration and try again.", delegate: self, cancelButtonTitle:Constants.Okay)
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func email()
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
            present(mailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    fileprivate func openWebSite(_ urlString:String)
    {
        if let url = URL(string:urlString) {
            if (UIApplication.shared.canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.shared.openURL(url)
            } else {
                let alert = UIAlertController(title: Constants.Network_Error,
                    message: "Unable to open web site: \(urlString)",
                    preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)

                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func openInGoogleMaps()
    {
        let urlAddress = Constants.CBC_FULL_ADDRESS.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)
        
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) { // Reachability.isConnectedToNetwork() &&
            let querystring = "comgooglemaps://?q="+urlAddress
            UIApplication.shared.openURL(URL(string:querystring)!)
        } else {
            let alert = UIAlertController(title: "Google Maps is not available",
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func openInAppleMaps()
    {
        item?.name = Constants.CBC_LONG
        item?.openInMaps(launchOptions: nil)
    }
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    @IBAction func actions(_ sender: UIBarButtonItem) {
//        NSLog("action!")
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = "Actions"
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                actionMenu.append(Constants.Email_CBC)
                actionMenu.append(Constants.CBC_in_Apple_Maps)
                actionMenu.append(Constants.CBC_in_Google_Maps)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
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
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismiss(animated: true, completion: nil)
        
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
    fileprivate func setVersion()
    {
        if let dict = Bundle.main.infoDictionary {
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

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        // Do any additional setup after loading the view.  E.g.
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
                self.mapView?.setCenter(coordinates, animated: false)
                self.mapView?.selectAnnotation(pointAnnotation, animated: false)
                self.mapView?.isZoomEnabled = true
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegionMakeWithDistance(coordinates, 10000, 10000)
                let adjustedRegion = self.mapView?.regionThatFits(viewRegion)
                self.mapView?.setRegion(adjustedRegion!, animated: false)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
    }

    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) { //  && (self.view.window != nil)
            let alert = UIAlertController(title:Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
}
