//
//  AboutViewController.swift
//  CBC
//
//  Created by Steve Leeke on 8/6/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import MapKit
import MessageUI

//extension AboutViewController : MFMailComposeViewControllerDelegate
//{
//    // MARK: MFMailComposeViewControllerDelegate Method
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
//    {
//        Thread.onMain { [weak self] in 
//            controller.dismiss(animated: true, completion: nil)
//        }
//    }
//}

extension AboutViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate Method
    
    func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return nil
    }
    
    func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "AboutViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        dismiss(animated: true, completion: {
            guard let strings = strings else {
                return
            }
            
            switch purpose {
            case .selectingAction:
                switch strings[index] {
                    
                case Constants.Strings.Email_CBC:
                    self.mailHTML(to: [Constants.CBC.EMAIL], subject: Constants.EMAIL_SUBJECT, htmlString: "")
                    break
                    
                case Constants.Strings.CBC_WebSite:
                    self.openWebSite(Constants.CBC.WEBSITE)
                    break
                    
                case Constants.Strings.CBC_in_Apple_Maps:
                    self.openInAppleMaps()
                    break
                    
                case Constants.Strings.CBC_in_Google_Maps:
                    self.openInGoogleMaps()
                    break
                    
                case Constants.Strings.Share_This_App:
                    self.share()
                    break
                    
                default:
                    break
                }
                break
                
            default:
                break
            }
        })
    }
}

extension AboutViewController : UIActivityItemSource
{
    func share()
    {
        let url = URL(string: Constants.CBC.APP_URL)
        let activityViewController = CBCActivityViewController(activityItems: ["Countryside Bible Church App",url,self], applicationActivities: nil)

        // exclude some activity types from the list (optional)
        
        activityViewController.excludedActivityTypes = [ .addToReadingList,.airDrop,.saveToCameraRoll ] // UIActivityType.addToReadingList doesn't work for third party apps - iOS bug.
        
        activityViewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        // present the view controller
        Alerts.shared.blockPresent(presenting: self, presented: activityViewController, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivity.ActivityType] = [.mail,.message]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let url = URL(string: "https://itunes.apple.com/us/app/countryside-bible-church/id1166303807?mt=8")

        if WebViewController.cases.contains(activityType!) {
            return url
        } else {
            return "https://itunes.apple.com/us/app/countryside-bible-church/id1166303807?mt=8"
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return "Countryside Bible Church Media App"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        guard let activityType = activityType else {
            return "public.plain-text"
        }
        
        if WebViewController.cases.contains(activityType) {
            return "public.text"
        } else {
            return "public.plain-text"
        }
    }
}

/**
 About view has information on the app, CBC, TP, etc.
 */
class AboutViewController: CBCViewController
{
    lazy var geocoder:CLGeocoder? = {
        return CLGeocoder()
    }()
    
    deinit {
        debug(self)
    }
    
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
    }
    
    @IBOutlet weak var liveStreamButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var item:MKMapItem?
    
    fileprivate func openWebSite(_ urlString:String)
    {
        UIApplication.shared.open(scheme: urlString) {
            self.networkUnavailable("Unable to open website: \(urlString)")
        }
    }
    
    fileprivate func openInGoogleMaps()
    {
        let urlAddress = Constants.CBC.FULL_ADDRESS.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.PLUS, options: NSString.CompareOptions.literal, range: nil)
        
        let querystring = "comgooglemaps://?q="+urlAddress
        UIApplication.shared.open(scheme: querystring) {
            self.alert(title: "Google Maps is not available", message: "", completion: nil)
        }
    }
    
    fileprivate func openInAppleMaps()
    {
        item?.name = Constants.CBC.LONG
        item?.openInMaps(launchOptions: nil)
    }
 
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
    
    @objc func actions(_ sender: UIBarButtonItem)
    {
        //In case we have one already showing
//        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
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
            let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
            actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
            
            navigationItem.rightBarButtonItem = actionButton
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupActionButton()
    }
    
    @objc func reachableTransition()
    {
        if mapView.isHidden, Globals.shared.reachability.isReachable {
            addMap()
        }
    }
    
    func addMap()
    {
        guard Globals.shared.reachability.isReachable else {
            return
        }
        
        geocoder?.geocodeAddressString(Constants.CBC.FULL_ADDRESS, completionHandler:{[weak self] (placemarks, error) -> Void in
            if let placemark = placemarks?[0], let location = placemark.location {
                let coordinates:CLLocationCoordinate2D = location.coordinate
                
                let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                pointAnnotation.title = Constants.CBC.LONG
                
                self?.mapView?.addAnnotation(pointAnnotation)
                self?.mapView?.setCenter(coordinates, animated: false)
                self?.mapView?.selectAnnotation(pointAnnotation, animated: false)
                
                let mkPlacemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                self?.item = MKMapItem(placemark: mkPlacemark)
                
                let viewRegion = MKCoordinateRegion.init(center: coordinates, latitudinalMeters: 50000, longitudinalMeters: 50000)
                if let adjustedRegion = self?.mapView?.regionThatFits(viewRegion) {
                    self?.mapView?.setRegion(adjustedRegion, animated: false)
                }
                
                self?.mapView?.isZoomEnabled = false
                self?.mapView?.isUserInteractionEnabled = false
                
                self?.mapView?.isHidden = false
            }
        })
    }

    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        setVersion()
        
        self.navigationController?.isToolbarHidden = true
        
        setDVCLeftBarButton()
        
        mapView.isHidden = true

        addMap()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
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

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { [weak self] (UIViewControllerTransitionCoordinatorContext) -> Void in
            if self?.navigationController?.visibleViewController == self {
                self?.navigationController?.isToolbarHidden = true
            }
            
            self?.setDVCLeftBarButton()
        }
    }
}
