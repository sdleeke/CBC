//
//  ControlView.swift
//  CBC
//
//  Created by Steve Leeke on 2/19/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

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

