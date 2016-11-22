//
//  ViewSplit.swift
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
class ViewSplit: UIView {
//    weak var splitViewController:UISplitViewController?
    
    var lineWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    
    var color: UIColor = UIColor.black { didSet { setNeedsDisplay() } }
    
    var scale: CGFloat = 1.0 { didSet { setNeedsDisplay() } }

    var height:CGFloat = 200 {
        didSet {
            //            NSLog("Height: \(height)")
            setNeedsDisplay()
        }
    }
    
    var min:CGFloat = 50 {
        didSet {
            //            NSLog("Height: \(min)")
            setNeedsDisplay()
        }
    }
    
    var max:CGFloat = 500 {
        didSet {
            //            NSLog("Height: \(max)")
            setNeedsDisplay()
        }
    }
    
//    weak var dataSource: SplitViewDataSource?
    
    fileprivate var splitCenter: CGPoint? {
        var splitPoint:CGPoint?
        
        splitPoint = CGPoint(x: self.bounds.width / 2, y: self.bounds.height - height)
        
        return splitPoint
    }
    
    override func draw(_ rect: CGRect)
    {
        if let startingPoint = splitCenter {
            let context = UIGraphicsGetCurrentContext()
            context!.saveGState()

            let indicatorPath = UIBezierPath()
            
            let height:CGFloat = bounds.width/4
            
            let left = CGPoint(x: startingPoint.x - bounds.width/2, y: startingPoint.y)
            indicatorPath.move(to: left)

            let right = CGPoint(x: startingPoint.x + bounds.width/2, y: startingPoint.y)
            indicatorPath.addLine(to: right)
            
//            NSLog("startingPoint.y: \(round(startingPoint.y)) min: \(round(min)) max: \(round(max))")
            
            if (round(startingPoint.y) > (bounds.height - round(max))) {
                let bottom = CGPoint(x: startingPoint.x, y: startingPoint.y - height)
                indicatorPath.move(to: bottom)
                indicatorPath.addLine(to: left)
                indicatorPath.move(to: bottom)
                indicatorPath.addLine(to: right)
            }

            if (round(startingPoint.y) < (bounds.height - round(min))) {
                let top = CGPoint(x: startingPoint.x, y: startingPoint.y + height)
                indicatorPath.move(to: top)
                indicatorPath.addLine(to: left)
                indicatorPath.move(to: top)
                indicatorPath.addLine(to: right)
            }
            
            indicatorPath.lineWidth = lineWidth
            color.set()
            indicatorPath.stroke()

            let boundsPath = UIBezierPath()
            
            boundsPath.move(to: bounds.origin)
            boundsPath.addLine(to: CGPoint(x: bounds.origin.x + bounds.width, y: bounds.origin.y))
            
//            if (splitViewController == nil) {
                boundsPath.addLine(to: CGPoint(x: bounds.origin.x + bounds.width,    y: splitCenter!.y))
                boundsPath.addLine(to: CGPoint(x: bounds.origin.x,                   y: splitCenter!.y))
//            } else {
//                boundsPath.addLine(to: CGPoint(x: bounds.origin.x + bounds.width,    y: bounds.origin.y + bounds.height))
//                boundsPath.addLine(to: CGPoint(x: bounds.origin.x,                   y: bounds.origin.y + bounds.height))
//            }
            
            boundsPath.addLine(to: bounds.origin)

            boundsPath.lineWidth = lineWidth / 2
            color.set()
            boundsPath.stroke()

            context!.restoreGState()
        } else {
            NSLog("No starting point!")
        }
    }
}


