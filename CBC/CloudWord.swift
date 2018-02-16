//
//  CloudWord.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit


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
    
    var isWordOrientationVertical : Bool {
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
        
    }
    
    override var description : String
        {
        get {
            return "\(wordText) \(wordCount) \(pointSize) \(boundsCenter) \(isWordOrientationVertical) \(boundsSize) \(boundsArea)"
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

//        if (scale >= 0.95) // 5%
//        {
//            self.wordColor = 0;
//        }
//        else if (scale >= 0.8) // 15%
//        {
//            self.wordColor = 1;
//        }
//        else if (scale >= 0.55) // 25%
//        {
//            self.wordColor = 2;
//        }
//        else if (scale >= 0.30) // 25%
//        {
//            self.wordColor = 3;
//        }
//        else // 30%
//        {
//            self.wordColor = 4;
//        }
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
        
//        if delta > 0 {
//            print(containerSize.height/containerSize.width)
//            random = arc4random_uniform(UInt32(chance * containerSize.width/containerSize.height))
//        }
//
//        if delta < 0 {
//            print(containerSize.width/containerSize.height)
//            random = arc4random_uniform(UInt32(chance * containerSize.width/containerSize.height))
//        }

//        print(containerSize.width/containerSize.height)
        random = arc4random_uniform(UInt32(chance * containerSize.width/containerSize.height))
//        print(random)

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
        
        while (fabs(randomGaussianPoint.x) > (divisions / 2)) || (fabs(randomGaussianPoint.y) > (divisions / 2))
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
        
//        print(wordText,pointSize)
        
        wordOrientationVertical = isVertical;
        
        let attributes = [NSAttributedStringKey.font: font]

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
    
//    func setSizeToGlyphBoundingRect(containerSize:CGSize,cloudFont:UIFont?)
//    {
////        guard let containerSize = containerSize else {
////            return
////        }
//        
//        guard let cloudFont = cloudFont else {
//            return
//        }
//        
//        guard let font = UIFont(name: cloudFont.fontName, size: pointSize) else {
//            return
//        }
//        
//        guard let wordText = wordText else {
//            return
//        }
//        
//        var overallGlyphRect = CGRect.zero
//        
//        let wordRect = frame
//        
//        // Typesetting is always done in the horizontal direction
//        
//        // There's a small possibility that a particular typeset word using a particular font, may still not fit within a slightly larger frame.  Give the typesetter a very large frame, to ensure that any word, at any point size, can be typeset on a line
//        
//        let horizontalFrame = CGRect(x: 0.0,y: 0.0,
//                                     width: wordOrientationVertical ? containerSize.height : containerSize.width,
//                                     height: wordOrientationVertical ? containerSize.width : containerSize.height)
//        
//        let attributes = [NSFontAttributeName : font]
//        
//        let attributedString = NSAttributedString(string: wordText, attributes: attributes)
//        
//        let cfas = attributedString as CFAttributedString
//        
//        let framesetter = CTFramesetterCreateWithAttributedString(cfas)
//        
//        let drawingPath = CGPath(rect: horizontalFrame, transform: nil)
//        
//        let textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), drawingPath, nil)
//        
//        let lines = CTFrameGetLines(textFrame)
//        
//        if (CFArrayGetCount(lines) > 0) {
//            var lineOrigin = CGPoint.zero
//            
//            CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 1), &lineOrigin)
//            
//            let line = (lines as NSArray).object(at: 0) as! CTLine
//            
//            //            let line = CFArrayGetValueAtIndex(lines, 0) as! CTLine
//            
//            let runs = CTLineGetGlyphRuns(line)
//            
//            for runIndex in 0..<CFArrayGetCount(runs) {
//                let run = (runs as NSArray).object(at: runIndex) as! CTRun
//                
//                //                let run = CFArrayGetValueAtIndex(runs, runIndex) as! CTRun
//                
//                let runAttributes:CFDictionary = CTRunGetAttributes(run)
//                
//                let font = (runAttributes as NSDictionary)[NSFontAttributeName] as! CTFont
//                //                let font = CFDictionaryGetValue(runAttributes, NSFontAttributeName) as! CTFont
//                
//                for glyphIndex in 0..<CTRunGetGlyphCount(run) {
//                    var glyphPosition = CGPoint.zero
//                    
//                    CTRunGetPositions(run, CFRangeMake(glyphIndex, 1), &glyphPosition)
//                    
//                    var glyph = CGGlyph()
//                    
//                    CTRunGetGlyphs(run, CFRangeMake(glyphIndex, 1), &glyph)
//                    
//                    var glyphBounds = CGRect.zero
//                    
//                    CTFontGetBoundingRectsForGlyphs(font, CTFontOrientation.default, &glyph, &glyphBounds, 1);
//                    
//                    var glyphRect = CGRect.zero
//                    
//                    let glyphX:CGFloat = lineOrigin.x + glyphPosition.x + glyphBounds.minX
//                    let glyphY:CGFloat = horizontalFrame.height - (lineOrigin.y + glyphPosition.y + glyphBounds.maxY)
//                    
//                    if isWordOrientationVertical {
//                        glyphRect = CGRect(x: wordRect.width - glyphY,y: glyphX, width: -glyphBounds.height, height: glyphBounds.width)
//                    } else {
//                        glyphRect = CGRect(x: glyphX,y: glyphY, width: glyphBounds.width, height: glyphBounds.height)
//                    }
//                    
//                    glyphRect = glyphRect.offsetBy(dx: wordRect.minX, dy: wordRect.minY)
//                    
//                    // Added some buffer space
//                    glyphRect = glyphRect.insetBy(dx: -2, dy: -2)
//                    
//                    if overallGlyphRect == CGRect.zero {
//                        overallGlyphRect = glyphRect
//                    } else {
//                        overallGlyphRect = overallGlyphRect.union(glyphRect)
//                    }
//                    
//                    //#ifdef DEBUG
//                    //                __weak id<CloudLayoutOperationDelegate> delegate = self.delegate;
//                    //                dispatch_async(dispatch_get_main_queue(), ^{
//                    //                    [delegate insertBoundingRect:glyphRect];
//                    //                });
//                    //#endif
//                }
//            }
//        }
//
//        if overallGlyphRect == CGRect.zero {
//            boundsSize = frame.size
//        } else {
//            boundsSize = overallGlyphRect.size
//            boundsCenter = CGPoint(x: overallGlyphRect.midX, y: overallGlyphRect.midY)
//        }
//    }
}

