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
    let title : String
    let message : String?
    let attributedText : NSAttributedString?
    let actions : [AlertAction]?
}

class Alerts
{
    static var shared = Alerts()
        
    deinit {
        
    }
    
    var topViewController = [UIViewController]()
    
    init()
    {
        Thread.onMainThread {
            self.alertTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.viewer), userInfo: nil, repeats: true)
        }
    }

    @objc func viewer()
    {
        for alert in queue {
            debug(alert)
        }
        
        guard UIApplication.shared.applicationState == UIApplication.State.active else {
            return
        }
        
        guard let alert = queue.first else {
            return
        }
        
        let alertVC = UIAlertController(title:alert.title,
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
        } else {
            let action = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alertVC.addAction(action)
        }
        
        Thread.onMainThread {
            let viewController = self.topViewController.last ?? Globals.shared.splitViewController
            
            viewController?.present(alertVC, animated: true, completion: {
                if self.queue.count > 0 {
                    self.queue.remove(at: 0)
                }
            })
        }
    }
    
    var queue = [Alert]()
    
    var alertTimer : Timer?

    func alert(category:String? = nil,title:String,message:String? = nil,attributedText:NSAttributedString? = nil,actions:[AlertAction]? = nil)
    {
        if !queue.contains(where: { (alert:Alert) -> Bool in
            return (alert.title == title) && (alert.message == message)
        }) {
            queue.append(Alert(category:category,title: title, message: message, attributedText: attributedText, actions: actions))
        } else {
            // This is happening - how?
            print("DUPLICATE ALERT")
        }
    }
}
