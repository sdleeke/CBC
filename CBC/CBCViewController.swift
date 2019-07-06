//
//  CBCViewController.swift
//  CBC
//
//  Created by Steve Leeke on 5/8/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

/**
 
 Abstract class for all modal view controllers not presented as a popover
 that must push/pop themselves onto the a stack of UIViewControllers that are
 NOT in the splitViewController hierarchy and the top viewController of which
 is the one that alerts are shown in front of,
 
 Popovers are reserved for lists of strings that can be used for either
 informaiton or menus.

 If the view controller IS a popover it stops alerts from being shown,
 signallying a semaphore to allow them to proceed when it going to disappear.
 
 */

// Allow popovers
extension CBCViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
}

// Only dismiss true popovers
extension CBCViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

extension CBCViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        Thread.onMain { [weak self] in 
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

class CBCViewController : UIViewController
{
    /**
 
     Checks to see if the view controller is contained in the splitviewcontroller heirarchy and if it IS NOT
     
     it continues to check and see if it is embedded and if it IS NOT
     
     it checks to see if it is a POPOVER and if it IS NOT
     
     it appends teh navigation controller for the view controller in the top view controller
     
     stack in the Alerts singleton so it can be used to present alerts.
     
     */
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        guard Globals.shared.splitViewController?.viewControllers.containsBelow(self) == false else {
            return
        }
        
        // in case it is embedded
        guard navigationController?.topViewController == self else {
            return
        }
        
        guard navigationController?.modalPresentationStyle != .popover else {
            return
        }
        
        if let navigationController = navigationController  {
            Alerts.shared.topViewController.append(navigationController)
        }
    }
    
    /**
     
     Checks to see if the last view controller in the Alerts singleton's top view controller stack is the current navigation controller and if IT IS, it is removed.
     
     Then if the navigation controller's modal presentation style is POPOVER the Alerts singleton's semaphore is signaled to allow alerts to be presented again.
     
     */
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if let last = Alerts.shared.topViewController.last, last == navigationController {
            _ = Alerts.shared.topViewController.removeLast()
        }
        
        if navigationController?.modalPresentationStyle == .popover {
            Alerts.shared.semaphore.signal()
        }
    }
}

