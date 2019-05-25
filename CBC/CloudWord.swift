//
//  CloudWord.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

/**
 To represent a word in a word cloud.
 */
class CloudWord : NSObject
{
    var wordText : String?
    
    var wordColor : Int = 0
    
    var wordCount : Int = 0
    
    @objc var pointSize : CGFloat = 0.0
    
    var boundsCenter : CGPoint = CGPoint.zero
    
    var boundsSize : CGSize = CGSize.zero
    
    @objc var boundsArea : CGFloat
    {
        get {
            return boundsSize.width * boundsSize.height
        }
    }
    
    var overallGlyphBoundingRect : CGRect?
    
    var frame : CGRect
    {
        get {
            return CGRect(x: boundsCenter.x - boundsSize.width / 2.0,
                          y: boundsCenter.y - boundsSize.height / 2.0,
                          width: boundsSize.width,
                          height: boundsSize.height)
        }
    }
    
    var wordOrientationVertical = false
    {
        didSet {
            
        }
    }
    
    var isWordOrientationVertical : Bool
    {
        get {
            return wordOrientationVertical
        }
    }
    
    init(word:String, wordCount:Int)
    {
        super.init()
        
        self.wordText = word
        self.wordCount = wordCount
    }
    
    deinit {
        debug(self)
    }
    
    override var description : String
    {
        get {
            return "\(wordText ?? "") \(wordCount) \(pointSize) \(boundsCenter) \(isWordOrientationVertical) \(boundsSize) \(boundsArea)"
        }
    }
    
    func determineColorForScale(scale:CGFloat)
    {
        switch scale {
        case 0.95...:  // 5%
            wordColor = 0

        case 0.8...: // 15%
            wordColor = 1

        case 0.55...: // 25%
            wordColor = 2
            
        case 0.30...: // 25%
            wordColor = 3
            
        default: // 30%
            wordColor = 4
        }
    }
    
    let containerMargin : CGFloat = 16.0
    
    func onlyFitsOneWay(containerSize:CGSize?) -> Bool
    {
        guard let containerSize = containerSize else {
            return false
        }
        
        let fitsHorizontal = (wordOrientationVertical ? boundsSize.height : boundsSize.width)  >= (containerSize.width - containerMargin)
        
        let fitsVertical = (wordOrientationVertical ? boundsSize.width : boundsSize.height) >= (containerSize.height - containerMargin)

        return (fitsHorizontal && !fitsVertical) || (!fitsHorizontal && fitsVertical)
    }
    
    func determineWordOrientation(orientation:Int, containerSize:CGSize, scale:CGFloat, fontName:String)
    {
        // Assign random word orientation
        
        let delta = containerSize.height - containerSize.width

        var random : UInt32 = 0

        let chance : CGFloat = 5
        
        if delta == 0 {
            random = arc4random_uniform(UInt32(chance))
        }
        
        random = arc4random_uniform(UInt32(chance * containerSize.width/containerSize.height))

        switch orientation {
        case 0,1:
            sizeWord(isVertical: (orientation == 0), scale: scale, fontName: fontName) //
        
        case 2:
            sizeWord(isVertical: (random == 0), scale: scale, fontName: fontName) //

        default:
            break
        }
        
        // Check word size against container smallest dimension
        
        let isPortrait = containerSize.height > containerSize.width
        
        if (isPortrait && !isWordOrientationVertical && (boundsSize.width >= (containerSize.width - containerMargin))) {
            // Force vertical orientation for horizontal word that's too wide
            sizeWord(isVertical: true, scale:scale, fontName:fontName)
        } else if (!isPortrait && isWordOrientationVertical && (boundsSize.height >= (containerSize.height - containerMargin))) {
            // Force horizontal orientation for vertical word that's too tall
            sizeWord(isVertical: false, scale:scale, fontName:fontName)
        }
    }
    
    func determineRandomWordPlacement(containerSize:CGSize, scale:CGFloat)
    {
        var randomGaussianPoint = randomGaussian()
        
        // Place bounds upon standard normal distribution to ensure word is placed within the container
        
        let divisions:CGFloat = 10.0
        
        while (abs(randomGaussianPoint.x) > (divisions / 2)) || (abs(randomGaussianPoint.y) > (divisions / 2))
        {
            randomGaussianPoint = randomGaussian()
        }
        
        // Midpoint +/- 50%
        let xOffset = (containerSize.width / 2.0) + (randomGaussianPoint.x * ((containerSize.width - self.boundsSize.width) * (1/divisions)));
        let yOffset = (containerSize.height / 2.0) + (randomGaussianPoint.y * ((containerSize.height - self.boundsSize.height) * (1/divisions)));
        
        // Return an integral point
        boundsCenter = CGPoint(x: round(value:xOffset, scale:scale), y: round(value:yOffset, scale:scale))
    }
    
    func determineNewWordPlacement(center:CGPoint, xOffset:CGFloat, yOffset:CGFloat, scale:CGFloat)
    {
        // Assign an integral point
        
        boundsCenter = CGPoint(x: round(value:xOffset + center.x, scale:scale), y: round(value:yOffset + center.y, scale:scale))
    }
    
    var paddedFrame : CGRect
    {
        get {
            let buffer = CGPoint(x: -2.0, y: -2.0)
            return frame.insetBy(dx: isWordOrientationVertical ? buffer.y : buffer.x, dy: isWordOrientationVertical ? buffer.x : buffer.y)
        }
    }
    
    func sizeWord(isVertical:Bool, scale:CGFloat, fontName:String)
    {
        guard let wordText = wordText else {
            return
        }
        
        guard let font = UIFont(name: fontName, size: pointSize) else {
            return
        }
        
        wordOrientationVertical = isVertical;
        
        let attributes = [NSAttributedString.Key.font: font]

        let attributedWord = NSAttributedString(string: wordText, attributes: attributes)

        let attributedWordSize = attributedWord.size()
    
        // Round up fractional values to integral points
    
        if (isWordOrientationVertical) {
            // Vertical orientation.  Width <- sized height.  Height <- sized width
            boundsSize = CGSize(width: ceil(value: attributedWordSize.height, scale:scale),height: ceil(value:attributedWordSize.width, scale:scale))
        } else {
            boundsSize = CGSize(width: ceil(value: attributedWordSize.width, scale:scale),height: ceil(value:attributedWordSize.height, scale:scale))
        }
    }

    func randomGaussian() -> CGPoint
    {
        var x1, x2, w : CGFloat

        repeat {
            // drand48() less random but faster than ((float)arc4random() / UINT_MAX)
            x1 = CGFloat(2.0 * drand48() - 1.0)
            x2 = CGFloat(2.0 * drand48() - 1.0)
            w = (x1 * x1) + (x2 * x2)
        } while (w >= 1.0) || (w == 0)
    
        w = sqrt((-2.0 * log(w)) / w)
        
        return CGPoint(x: x1 * w, y: x2 * w)
    }

    func round(value:CGFloat, scale:CGFloat) -> CGFloat
    {
        return Darwin.round(value * scale) / scale
    }

    func ceil(value:CGFloat, scale:CGFloat) -> CGFloat
    {
        return Darwin.ceil(value * scale) / scale
    }
}

