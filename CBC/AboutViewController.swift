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

extension AboutViewController : UIAdaptivePresentationControllerDelegate
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

extension AboutViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        Thread.onMainThread() {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

extension AboutViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate Method
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "AboutViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingAction:
            switch strings[index] {
                
            case Constants.Strings.Email_CBC:
                mailHTML(viewController: self, to: [Constants.CBC.EMAIL], subject: Constants.EMAIL_SUBJECT, htmlString: "")
                break
                
            case Constants.Strings.CBC_WebSite:
                openWebSite(Constants.CBC.WEBSITE)
                break
                
            case Constants.Strings.CBC_in_Apple_Maps:
                openInAppleMaps()
                break
                
            case Constants.Strings.CBC_in_Google_Maps:
                openInGoogleMaps()
                break
                
            case Constants.Strings.Share_This_App:
                shareHTML(viewController: self, htmlString: "Countryside Bible Church app\n\nhttps://itunes.apple.com/us/app/countryside-bible-church/id1166303807?mt=8")
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
}

extension AboutViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class AboutViewController: UIViewController
{
    override var canBecomeFirstResponder : Bool
    {
        return true //let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        globals.motionEnded(motion,event: event)
    }
    
    @IBOutlet weak var liveStreamButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var item:MKMapItem?
    
    fileprivate func openWebSite(_ urlString:String)
    {
        open(scheme: urlString) {
            networkUnavailable(self,"Unable to open web site: \(urlString)")
        }
    }
    
    fileprivate func openInGoogleMaps()
    {
        let urlAddress = Constants.CBC.FULL_ADDRESS.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.PLUS, options: NSString.CompareOptions.literal, range: nil)
        
        let querystring = "comgooglemaps://?q="+urlAddress
        open(scheme: querystring) {
            alert(viewController:self,title: "Google Maps is not available", message: "", completion: nil)
        }
    }
    
    fileprivate func openInAppleMaps()
    {
        item?.name = Constants.CBC.LONG
        item?.openInMaps(launchOptions: nil)
    }
    
//    @IBOutlet weak var actionButton: UIBarButtonItem!
 
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        actionMenu.append(Constants.Strings.Email_CBC)
        actionMenu.append(Constants.Strings.CBC_WebSite)
        actionMenu.append(Constants.Strings.CBC_in_Apple_Maps)
        actionMenu.append(Constants.Strings.CBC_in_Google_Maps)
        
        actionMenu.append(Constants.Strings.Share_This_App)
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions(_ sender: UIBarButtonItem)
    {
//        print("action!")
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

//            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                let hClass = traitCollection.horizontalSizeClass
//                
//                if hClass == .compact {
//                    navigationController.modalPresentationStyle = .overCurrentContext
//                } else {
//                    // I don't think this ever happens: collapsed and regular
//                    navigationController.modalPresentationStyle = .popover
//                }
//            } else {
//                navigationController.modalPresentationStyle = .popover
//            }

            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.vc = self
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenu()
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var versionLabel: UILabel!
    fileprivate func setVersion()
    {
        if  let dict = Bundle.main.infoDictionary,
            let appVersion = dict["CFBundleShortVersionString"] as? String,
            let buildNumber = dict["CFBundleVersion"] as? String {
            versionLabel.text = appVersion + "." + buildNumber
            versionLabel.sizeToFit()
        }
    }

    @IBOutlet weak var mapView: MKMapView!
    
    func setupActionButton()
    {
        if actionMenu()?.count > 0 {
            let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(AboutViewController.actions))
            actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
            
            navigationItem.rightBarButtonItem = actionButton
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        navigationController?.setToolbarHidden(true, animated: false)

//        navigationItem.leftItemsSupplementBackButton = true
        
        setupActionButton()
    }
    
    func reachableTransition()
    {
        if mapView.isHidden, globals.reachability.currentReachabilityStatus != .notReachable {
            addMap()
        }
    }
    
    func addMap()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(Constants.CBC.FULL_ADDRESS, completionHandler:{(placemarks, error) -> Void in
            if let placemark = placemarks?[0] {
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                
                let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                pointAnnotation.title = Constants.CBC.LONG
                
                self.mapView?.addAnnotation(pointAnnotation)
                self.mapView?.setCenter(coordinates, animated: false)
                self.mapView?.selectAnnotation(pointAnnotation, animated: false)
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegionMakeWithDistance(coordinates, 50000, 50000)
                let adjustedRegion = self.mapView?.regionThatFits(viewRegion)
                self.mapView?.setRegion(adjustedRegion!, animated: false)
                
                self.mapView?.isZoomEnabled = false
                self.mapView?.isUserInteractionEnabled = false
                
                self.mapView?.isHidden = false
            }
        })
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    
        setVersion()
        
        if self.navigationController?.visibleViewController == self {
            self.navigationController?.isToolbarHidden = true
        }
        
        setDVCLeftBarButton()
//        if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//            let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
//            let count = self.splitViewController?.viewControllers.count {
//            if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                    navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                } else {
//                    navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
//                }
//            }
//        }
        
        mapView.isHidden = true

        addMap()
        
        Thread.onMainThread() {
            NotificationCenter.default.addObserver(self, selector: #selector(AboutViewController.reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(AboutViewController.reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if self.navigationController?.visibleViewController == self {
                self.navigationController?.isToolbarHidden = true
            }
            
            self.setDVCLeftBarButton()

//            if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//                let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
//                let count = self.splitViewController?.viewControllers.count {
//                if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                    } else {
//                        navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
//                    }
//                }
//            }
        }
    }
}
