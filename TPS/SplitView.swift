//
//  SplitView.swift
//  TPS
//
//  Created by Steve Leeke on 9/15/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

//protocol SplitViewDataSource: class {
//    func ratioForSplitView(sender: SplitView) -> CGFloat?
//}

@IBDesignable
class SplitView: UIView {
    weak var splitViewController:UISplitViewController?
    
    var lineWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    
    var color: UIColor = UIColor.blackColor() { didSet { setNeedsDisplay() } }
    
    var scale: CGFloat = 1.0 { didSet { setNeedsDisplay() } }

    var height:CGFloat = 200 {
        didSet {
            //            print("Height: \(height)")
            setNeedsDisplay()
        }
    }
    
    var min:CGFloat = 50 {
        didSet {
            //            print("Height: \(min)")
            setNeedsDisplay()
        }
    }
    
    var max:CGFloat = 500 {
        didSet {
            //            print("Height: \(max)")
            setNeedsDisplay()
        }
    }
    
//    weak var dataSource: SplitViewDataSource?
    
    private var splitCenter: CGPoint? {
        var splitPoint:CGPoint?
        
        splitPoint = CGPointMake(self.bounds.width / 2, self.bounds.height - height)
        
        return splitPoint
    }
    
    override func drawRect(rect: CGRect)
    {
        if let startingPoint = splitCenter {
            let context = UIGraphicsGetCurrentContext()
            CGContextSaveGState(context)

            let indicatorPath = UIBezierPath()
            
            let height:CGFloat = bounds.width/4
            
            let left = CGPoint(x: startingPoint.x - bounds.width/2, y: startingPoint.y)
            indicatorPath.moveToPoint(left)

            let right = CGPoint(x: startingPoint.x + bounds.width/2, y: startingPoint.y)
            indicatorPath.addLineToPoint(right)
            
//            print("startingPoint.y: \(round(startingPoint.y)) min: \(round(min)) max: \(round(max))")
            
            if (round(startingPoint.y) > (bounds.height - round(max))) {
                let bottom = CGPoint(x: startingPoint.x, y: startingPoint.y - height)
                indicatorPath.moveToPoint(bottom)
                indicatorPath.addLineToPoint(left)
                indicatorPath.moveToPoint(bottom)
                indicatorPath.addLineToPoint(right)
            }

            if (round(startingPoint.y) < (bounds.height - round(min))) {
                let top = CGPoint(x: startingPoint.x, y: startingPoint.y + height)
                indicatorPath.moveToPoint(top)
                indicatorPath.addLineToPoint(left)
                indicatorPath.moveToPoint(top)
                indicatorPath.addLineToPoint(right)
            }
            
            indicatorPath.lineWidth = lineWidth
            color.set()
            indicatorPath.stroke()

            let boundsPath = UIBezierPath()
            
            boundsPath.moveToPoint(bounds.origin)
            boundsPath.addLineToPoint(CGPoint(x: bounds.origin.x + bounds.width, y: bounds.origin.y))
            
            if (splitViewController == nil) {
                boundsPath.addLineToPoint(CGPoint(x: bounds.origin.x + bounds.width,    y: splitCenter!.y))
                boundsPath.addLineToPoint(CGPoint(x: bounds.origin.x,                   y: splitCenter!.y))
            } else {
                boundsPath.addLineToPoint(CGPoint(x: bounds.origin.x + bounds.width,    y: bounds.origin.y + bounds.height))
                boundsPath.addLineToPoint(CGPoint(x: bounds.origin.x,                   y: bounds.origin.y + bounds.height))
            }
            
            boundsPath.addLineToPoint(bounds.origin)

            boundsPath.lineWidth = lineWidth / 2
            color.set()
            boundsPath.stroke()

            CGContextRestoreGState(context)
        } else {
            print("No starting point!")
        }
    }
}


