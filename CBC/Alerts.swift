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

struct Alert {
    let category : String?
    let title : String?
    let message : String?
    let attributedText : NSAttributedString?
    let actions : [AlertAction]?
    let items : [AlertItem]?
}

class CBCActivityViewController : UIActivityViewController
{
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        Alerts.shared.semaphore.signal()
    }
}

class CBCAlertController : UIAlertController
{
//    override func viewWillAppear(_ animated: Bool)
//    {
//        super.viewWillAppear(animated)
//
////        Alerts.shared.semaphore.wait()
//
////        Alerts.shared.queue.async {
////            Alerts.shared.semaphore.wait()
////        }
//    }

    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)

        Alerts.shared.semaphore.signal()

//        Alerts.shared.queue.async {
//            Alerts.shared.semaphore.signal()
//        }
    }
}

class Alerts
{
    static var shared = Alerts()
        
    deinit {
        debug(self)
    }
    
    var topViewController = [UIViewController]()
    
    init()
    {
        Thread.onMainThread {
            self.alertTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.viewer), userInfo: nil, repeats: true)
//            _ = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { (Timer) in
//                Alerts.shared.alert(title: "Testing")
//            })
        }
    }

//    var presenting : CBCAlertController?
//    {
//        didSet {
//            if presenting == nil {
//
//            }
//        }
//    }
    
    @objc func viewer()
    {
        guard let viewController = self.topViewController.last ?? Globals.shared.splitViewController else { // ?.navigationController?.topViewController
            return
        }
        
//        guard vcQueue.first == nil else {
//            if let vc = vcQueue.first {
//                Thread.onMainThread {
//                    //                    if self.presenting == nil {
//                    //                        self.presenting = vc
//
//                    viewController.present(vc, animated: true, completion: {
//                        if self.vcQueue.count > 0 {
//                            self.vcQueue.remove(at: 0)
//                        }
//                    })
//                    //                    }
//                }
//            }
//            return
//        }
        
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
        
//        vcQueue.append(alertVC) // crashes
        
        self.alertQueue.remove(at: 0)

        Alerts.shared.queue.async {
            Alerts.shared.semaphore.wait()
            Thread.onMainThread {
                //            let viewController = self.topViewController.last ?? Globals.shared.splitViewController // ?.navigationController?.topViewController
                
                // This works because a new alertVC is created each time.  Presenting the same vc twice will cause a crash.
                // If the alertVC can't be shown it is simply thrown away and the struct from which it is contained is not removed from
                // the queue so attempts keep being made until it is shown.
                
                // Haven't found a way to queue the vc's themselves and show them.
                viewController.present(alertVC, animated: true, completion: {
                    //                self.queue.sync {
                    //                }
                })
            }
        }
    }
    
//    // Make it thread safe
    
    var semaphore = DispatchSemaphore(value: 1)

    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    var alertQueue = ThreadSafeArray<Alert>()
    
//    var vcQueue = [UIViewController]()
    
    var alertTimer : Timer?

    func alert(category:String? = nil, title:String?, message:String? = nil, attributedText:NSAttributedString? = nil, actions:[AlertAction]? = nil, items:[AlertItem]? = nil)
    {
//        queue.sync {
        alertQueue.append(Alert(category:category, title: title, message: message, attributedText: attributedText, actions: actions, items:items))
//        if !alertQueue.copy?.contains(where: { (alert:Alert) -> Bool in
//                return (alert.title == title) && (alert.message == message)
//            }) {
//                alertQueue.append(Alert(category:category,title: title, message: message, attributedText: attributedText, actions: actions))
//        } else {
//            // This is happening - how?
//            print("DUPLICATE ALERT")
//        }
//        }
    }
}
