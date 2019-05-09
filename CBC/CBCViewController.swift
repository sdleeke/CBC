//
//  CBCViewController.swift
//  CBC
//
//  Created by Steve Leeke on 5/8/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class CBCViewController : UIViewController
{
//    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil)
//    {
//        while Alerts.shared.presenting != nil {
//            Thread.sleep(forTimeInterval: 0.10)
//        }
//        super.present(viewControllerToPresent, animated: flag, completion: completion)
//    }
    
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
        
        if Alerts.shared.topViewController.last == navigationController {
            Alerts.shared.topViewController.removeLast()
        }
        
        if navigationController?.modalPresentationStyle == .popover {
            Alerts.shared.semaphore.signal()
        }
        
//        if self.view.tag == 1000 {
//            Alerts.shared.semaphore.signal()
//        }
    }
}

