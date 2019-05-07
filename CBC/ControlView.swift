//
//  ControlView.swift
//  CBC
//
//  Created by Steve Leeke on 2/19/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class LoadingContainerView : UIView
{
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        guard tag >= 100 else {
            return false
        }
        
        switch tag {
        case 101:
            guard subviews.count > 0 else {
                return true // Do not pass touches
            }
            
            let loadingView = subviews[0]
            
            for view in loadingView.subviews {
                guard let button = view as? UIButton, button.isEnabled else {
                    continue
                }
                
                if view.frame.contains(self.convert(point, to: loadingView)), view.isUserInteractionEnabled, !view.isHidden {
                    return true
                }
            }
            break
            
        case 102:
            for view in subviews {
                if view.frame.contains(point), view.isUserInteractionEnabled, !view.isHidden {
                    return true
                }
            }
            break
            
        default:
            break
        }
        
        return backgroundColor != UIColor.clear // pass touches if clear
    }
}

class ControlView : UIView
{
    deinit {
        debug(self)
    }
    
    var sliding = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool
    {
        guard !sliding else {
            return false
        }
        
        for view in subviews {
            if view.frame.contains(point) && view.isUserInteractionEnabled && !view.isHidden {
                if let control = view as? UIControl {
                    if control.isEnabled {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        
        return false
    }
}

