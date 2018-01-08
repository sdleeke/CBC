//
//  QuadTree.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

let BoundingRectThreashold = 8

enum Quadrants : String {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

class QuadTree {
    var frame : CGRect?
    
    var boundingRects : [CGRect]?
    
    var quadTrees : [String:QuadTree]?
    
    var topRight : QuadTree?
    {
        get {
            return quadTrees?[Quadrants.topRight.rawValue]
        }
        set {
            if quadTrees == nil {
                quadTrees = [String:QuadTree]()
            }
            quadTrees?[Quadrants.topRight.rawValue] = newValue
        }
    }
    
    var topLeft : QuadTree?
    {
        get {
            return quadTrees?[Quadrants.topLeft.rawValue]
        }
        set {
            if quadTrees == nil {
                quadTrees = [String:QuadTree]()
            }
            quadTrees?[Quadrants.topLeft.rawValue] = newValue
        }
    }
    
    var bottomRight : QuadTree?
    {
        get {
            return quadTrees?[Quadrants.bottomRight.rawValue]
        }
        set {
            if quadTrees == nil {
                quadTrees = [String:QuadTree]()
            }
            quadTrees?[Quadrants.bottomRight.rawValue] = newValue
        }
    }

    var bottomLeft : QuadTree?
    {
        get {
            return quadTrees?[Quadrants.bottomLeft.rawValue]
        }
        set {
            if quadTrees == nil {
                quadTrees = [String:QuadTree]()
            }
            quadTrees?[Quadrants.bottomLeft.rawValue] = newValue
        }
    }

    init(frame:CGRect)
    {
        self.frame = frame
    }
    
    init()
    {
        self.frame = CGRect.zero
    }
    
    deinit {
        
    }
    
    func debugDescription()
    {
        print("Frame: \(frame?.minX) \(frame?.maxX) \(frame?.minY) \(frame?.maxY)\n\nBoudning Rects: \(boundingRects)\n\n\(topLeft?.debugDescription)\n\n\(topRight?.debugDescription)\n\n\(bottomRight?.debugDescription)\n\n\(bottomRight?.debugDescription)")
    }
    
    func insertBoundingRect(boundingRect:CGRect) -> Bool
    {
        if let contains = self.frame?.contains(boundingRect), !contains {
            return false
        }
        
        if quadTrees == nil, boundingRects?.count > BoundingRectThreashold {
            setupChildQuads()
            migrateBoundingRects()
        }
        
        if quadTrees != nil, migrate(boundingRect:boundingRect) {
            return true
        }
        
        if boundingRects == nil {
            boundingRects = [CGRect]()
        }
        boundingRects?.append(boundingRect)
        
        return true
    }
    
    func hasGlyphThatIntersectsWithWordRect(wordRect:CGRect) -> Bool
    {
        if let boundingRects = boundingRects {
            for boundingRect in boundingRects {
                if boundingRect.intersects(wordRect) {
                    return true
                }
            }
        }
        
        if quadTrees == nil {
            return false
        }

        if let frame = topLeft?.frame, frame.intersects(wordRect) {
            if let topLeft = topLeft?.hasGlyphThatIntersectsWithWordRect(wordRect: wordRect), topLeft {
                return true
            }
            
            if let frame = topLeft?.frame, frame.contains(wordRect) {
                return false
            }
        }
        
        if let frame = topRight?.frame, frame.intersects(wordRect) {
            if let topRight = topRight?.hasGlyphThatIntersectsWithWordRect(wordRect: wordRect), topRight {
                return true
            }
            
            if let frame = topRight?.frame, frame.contains(wordRect) {
                return false
            }
        }

        if let frame = bottomLeft?.frame, frame.intersects(wordRect) {
            if let bottomLeft = bottomLeft?.hasGlyphThatIntersectsWithWordRect(wordRect: wordRect), bottomLeft {
                return true
            }
            
            if let frame = bottomLeft?.frame, frame.contains(wordRect) {
                return false
            }
        }
        
        if let frame = bottomRight?.frame, frame.intersects(wordRect) {
            if let bottomRight = bottomRight?.hasGlyphThatIntersectsWithWordRect(wordRect: wordRect), bottomRight {
                return true
            }
            
            if let frame = bottomRight?.frame, frame.contains(wordRect) {
                return false
            }
        }
        
        return false
    }
    
    func setupChildQuads()
    {
        guard quadTrees == nil else {
            return
        }
        
        guard let frame = frame else {
            return
        }
        
        let minX = frame.minX
        let minY = frame.minY
        let childWidth = frame.width / 2
        let childHeight = frame.height / 2
        
        topLeft = QuadTree(frame: CGRect(x: minX, y: minY, width: childWidth, height: childHeight))
        topRight = QuadTree(frame: CGRect(x: minX + childWidth, y: minY, width: childWidth, height: childHeight))
        
        bottomLeft = QuadTree(frame: CGRect(x: minX, y: minY + childHeight, width: childWidth, height: childHeight))
        bottomRight = QuadTree(frame: CGRect(x: minX + childWidth, y: minY + childHeight, width: childWidth, height: childHeight))
    }
    
    func migrateBoundingRects()
    {
        guard var boundingRects = boundingRects else {
            return
        }
        
        var migratedBoundingRects = [CGRect]()
        
        for boundingRect in boundingRects {
            if migrate(boundingRect: boundingRect) {
                migratedBoundingRects.append(boundingRect)
            }
        }
        
        if migratedBoundingRects.count > 0 {
            for boundingRect in migratedBoundingRects {
                if let index = boundingRects.index(of: boundingRect) {
                    boundingRects.remove(at: index)
                }
            }
        }
        
        self.boundingRects = boundingRects.count > 0 ? boundingRects : nil
    }
    
    func migrate(boundingRect:CGRect) -> Bool
    {
        if let topLeft = self.topLeft?.insertBoundingRect(boundingRect: boundingRect), topLeft {
            return true
        }

        if let topRight = self.topRight?.insertBoundingRect(boundingRect: boundingRect), topRight {
            return true
        }
        
        if let bottomLeft = self.bottomLeft?.insertBoundingRect(boundingRect: boundingRect), bottomLeft {
            return true
        }
        
        if let bottomRight = self.bottomRight?.insertBoundingRect(boundingRect: boundingRect), bottomRight {
            return true
        }

        return false
    }
}
