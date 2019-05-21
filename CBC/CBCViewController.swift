//
//  CBCViewController.swift
//  CBC
//
//  Created by Steve Leeke on 5/8/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

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

class CBCViewController : UIViewController
{
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

