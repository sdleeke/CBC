//
//  Alerts.swift
//  PrEq
//
//  Created by Steve Leeke on 4/10/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

//var alerts = Alerts()

/**

 struct containing all the information for an alert, including actions/times.
 
 Properties:
    - category for tracking different types of alerts
    - title of alert
    - message of alert
    - attributedText that will be displayed in a text field
    - actions, or
    - items, where items can be actions or text fields
 */

struct Alert {
    let category : String?
    let title : String?
    let message : String?
    let attributedText : NSAttributedString?
    let actions : [AlertAction]?
    let items : [AlertItem]?
}

/**

 CBC specific subclass for releasing the Alerts.shared.semaphore
 after the activity view controller (i.e. share sheet) disappears.
 
 */

class CBCActivityViewController : UIActivityViewController
{
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        Alerts.shared.semaphore.signal()
    }
}

/**
 
 CBC specific subclass for releasing the Alerts.shared.semaphore
 after the alert controller disappears.
 
 */

class CBCAlertController : UIAlertController
{
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)

        Alerts.shared.semaphore.signal()
    }
}

/**
 
 Singleton class for app-wide managing of alerts so they are queued and never lost.
 
 Properties:
    - queue: used asynchronously to allow blocking if an alert should NOT be presented
    - array: used as a stack of alerts
    - timer: use to keep checking for alerts to present
    - semaphore: used to track whether an alert should be presented
 
 Methods:
    - init() start timer
    - viewer() present the next alert in the queue, actually forks the alert into the async queue
    but the semaphore keeps them in order since each fork decrements and they run as signals increment it.
    - blockPresent does the view controller presentation with blocking.  Whether semphore is released after view controller presents is controlled by a function parameter.
    - alert queues the content of alerts.
 */

class Alerts
{
    static var shared = Alerts()
        
    deinit {
        debug(self)
    }
    
    var topViewController = ThreadSafeArray<UIViewController>()
    
    init()
    {
        Thread.onMain {
            self.alertTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.viewer), userInfo: nil, repeats: true)
//            _ = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (Timer) in
//                Alerts.shared.alert(title: "Testing")
//            })
        }
    }

    @objc func viewer()
    {
        guard let viewController = self.topViewController.last ?? Globals.shared.splitViewController else { // ?.navigationController?.topViewController
            return
        }
        
        alertQueue.forEach { (alert:Alert) in
            debug(alert)
        }
            
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
            return
        }
        
        guard let alert = alertQueue.first else {
            return
        }
        
        let alertVC = CBCAlertController(title:alert.title,
                                         message:alert.message,
                                         preferredStyle: .alert)
        alertVC.makeOpaque()
        
        if let attributedText = alert.attributedText {
            alertVC.addTextField(configurationHandler: { (textField:UITextField) in
                textField.isUserInteractionEnabled = false
                textField.textAlignment = .center
                textField.attributedText = attributedText
                textField.adjustsFontSizeToFitWidth = true
            })
        }
        
        if let alertActions = alert.actions {
            for alertAction in alertActions {
                let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                    alertAction.handler?()
                })
                alertVC.addAction(action)
            }
        } else
        if let alertItems = alert.items {
            for alertItem in alertItems {
                switch alertItem {
                case .action(let action):
                    let action = UIAlertAction(title: action.title, style: action.style, handler: { (UIAlertAction) -> Void in
                        action.handler?()
                    })
                    alertVC.addAction(action)
                    break
                    
                case .text(let text):
                    alertVC.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = text
                    })
                    break
                }
            }
        } else {
            alertVC.addAction(UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.cancel, handler: nil))
        }
        
        self.alertQueue.remove(at: 0)

        // This means we could actually queue viewControllers now since they aren't really queued
        // The timer means we only dequeue one alert every period and fork that on to an aync queue
        // that blocks on the semaphore.  We don't limit the number of threads the queue can have.
        
        blockPresent(presenting:viewController,presented:alertVC, animated:true)
    }
    
    func blockPresent(presenting:UIViewController, presented:UIViewController, animated:Bool, release:(()->(Bool))? = nil, completion:(()->())? = nil)
    {
        queue.async { [weak self] in
            self?.semaphore.wait()
            
            Thread.onMain {
                presenting.present(presented, animated: true, completion: {
                    if release?() == true {
                        self?.semaphore.signal()
                    }
                    completion?()
                })
            }
        }
    }
    
    // value 1 => block immediately upon first wait() call.
    var semaphore = DispatchSemaphore(value: 1)

    // Do not limit the number of threads that the queue may use.
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    // Thread safe queue of alert contents.
    var alertQueue = ThreadSafeArray<Alert>()

    // Timer to keep looking for alerts to show.
    var alertTimer : Timer?

    func alert(category:String? = nil, title:String?, message:String? = nil, attributedText:NSAttributedString? = nil, actions:[AlertAction]? = nil, items:[AlertItem]? = nil)
    {
        if title == "No Network Connection" {
            alertQueue.update(storage: alertQueue.filter({ (alert:Alert) -> Bool in
                alert.title?.contains("Network Connection") !=  true
            }))
        }
        
        if title == "Network Connection Restored" {
            if let alerts = alertQueue.filter({ (alert:Alert) -> Bool in
                alert.title?.contains("Network Connection") ==  true
            }) {
                if alerts.last?.title?.contains("No Network Connection") == true {
                    alertQueue.update(storage: alertQueue.filter({ (alert:Alert) -> Bool in
                        alert.title?.contains("Network Connection") !=  true
                    }))
                    return // Do not show Network Connection Restored if No Network Connection was pending
                }
            }
        }
        
        alertQueue.append(Alert(category:category, title: title, message: message, attributedText: attributedText, actions: actions, items:items))
    }
}
