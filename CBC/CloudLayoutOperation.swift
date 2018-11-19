//
//  CloudLayoutOperation.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

protocol CloudLayoutOperationDelegate
{
    func insertWord(word:String, pointSize:CGFloat, color:Int, center:CGPoint, isVertical:Bool)
    func insertBoundingRect(boundingRect:CGRect) -> CALayer
    func finished(cloudWords:[CloudWord]?)
    func update(cloudWords:[CloudWord]?)
}

class CloudLayoutOperation : Operation
{
    var cloudFont : UIFont?
    var cloudTitle : String?
    var cloudWords : [CloudWord]?
    var containerSize : CGSize?
    var containerScale : CGFloat = 0.0
    var orientation:Int = 2
    var delegate:CloudLayoutOperationDelegate?
    var boundingRects : QuadTree?
    
    var placedCloudWords : [CloudWord]?
    
    override var description: String
    {
        get {
            return "container size = (\(containerSize?.height ?? 0) \(containerSize?.width ?? 0)), delegate = \(delegate); words = \(cloudWords.debugDescription)"
        }
    }
    
    init(cloudWordDicts:[[String:Any]]?, title:String?, containerSize:CGSize, containerScale:CGFloat, cloudFont: UIFont?, orientation:Int, delegate:CloudLayoutOperationDelegate)
    {
        super.init()
        
        // Custom initialization
    
        var words = [CloudWord]()

        if let cloudWordDicts = cloudWordDicts {
            for cloudWordDict in cloudWordDicts {
                if let word = cloudWordDict["word"] as? String, let count = cloudWordDict["count"] as? Int {
                    words.append(CloudWord(word: word, wordCount: count))
                } else {
                    
                }
            }
        }

        self.cloudWords = words.count > 0 ? words.sorted(by: { (first, second) -> Bool in
            return first.wordCount > second.wordCount
        }) : nil

        self.cloudTitle = title
        
        self.containerSize = containerSize
        self.containerScale = containerScale

        self.delegate = delegate
        
        self.cloudFont = cloudFont
        
        self.orientation = orientation
        
        self.boundingRects = QuadTree(frame: CGRect(x: 0.0, y: 0.0, width: containerSize.width, height: containerSize.height))
    }
    
    deinit {
        
    }
    
    override func main()
    {
        if isCancelled {
            return
        }
        
        normalizeWordWeights()
        
        if isCancelled {
            return
        }
        
        assignColorsForWords()
        
        if isCancelled {
            return
        }
        
        assignPreferredPlacementsForWords()

        if isCancelled {
            return
        }
        
        reorderWordsByDescendingWordArea()
        
        if isCancelled {
            return
        }
        
        layoutCloudWords()
    }
    
    func normalizeWordWeights()
    {
        guard let cloudWords = cloudWords else {
            return
        }
        
        guard let containerSize = containerSize else {
            return
        }
        
        guard let cloudFont = cloudFont else {
            return
        }
        
        // Determine minimum and maximum weight of words
        let cloudWordCounts = cloudWords.map({ (word:CloudWord) -> Int in
            return word.wordCount
        }).sorted()
        
        guard let minWordCount = cloudWordCounts.first else {
            return
        }
        
        guard let maxWordCount = cloudWordCounts.last else {
            return
        }
        
        let deltaWordCount:CGFloat = CGFloat(maxWordCount) - CGFloat(minWordCount)
        
        let ratioCap:CGFloat = 20.0 // Parameter to vary.  Used to be 20.  That was too drastic.
        
        let maxMinRatio:CGFloat = CGFloat(min(CGFloat(maxWordCount) / CGFloat(minWordCount),ratioCap))
        
        // Start with these values, which will be decreased as needed that all the words may fit the container
        let minFontMin:CGFloat = 4.0
        var oldFontMin:CGFloat = 0.0
        var fontMin:CGFloat = 12.0
        var fontMax:CGFloat = fontMin * maxMinRatio;

        // A way to account for whitespace between words
        let whitespaceFactor:CGFloat = 0.95 // parameter to vary
        let containerArea:CGFloat = CGFloat(containerSize.width * containerSize.height) * whitespaceFactor

        var wordAreaExceedsContainerSize = false

        // Looking at word volumes
        // If word volumes were in proportion to their relative frequency
        // it seems intuitive that the image would be more meaningful
        // but how do we do that?
        //
//        if let first = cloudWords.first, let last = cloudWords.last {
//            first.pointSize = fontMax
//            first.sizeWord(isVertical: false, scale:containerScale, fontName:cloudFont.fontName)
//            let firstArea = first.boundsArea
//
//            last.pointSize = fontMin
//            last.sizeWord(isVertical: false, scale:containerScale, fontName:cloudFont.fontName)
//            let lastArea = last.boundsArea
//
//            print(firstArea,lastArea,firstArea/lastArea)
//        }
        
        // It would be very cool to be able to map the word locations to the surface of a sphere and use a pan gesture
        // to rotate the sphere around a fixed center.
        
        repeat {
            var wordArea:CGFloat
            
            wordAreaExceedsContainerSize = false
            
            var fontRange:CGFloat = fontMax - fontMin
            let fontStep:CGFloat = 0.1 // 1.0 // 3.0 // parameter to vary
            
            // Normalize word weights
            
            let scaleFactor:CGFloat = 0.85
            
            repeat {
                wordArea = 0.0
                
                for cloudWord in cloudWords {
                    let scale:CGFloat = CGFloat(cloudWord.wordCount - minWordCount) / (deltaWordCount != 0 ? deltaWordCount : 1)
                    cloudWord.pointSize = fontMin + (fontStep * floor(scale * (fontRange / fontStep))) // + dynamicTypeDelta
                    cloudWord.determineWordOrientation(orientation: orientation, containerSize: containerSize, scale:containerScale, fontName:cloudFont.fontName)
                    wordArea += cloudWord.boundsArea // * 1.1 // Another way to account for whitespace between words - parameter to vary
                }
                
                if wordArea < (containerArea * scaleFactor) {
//                    oldFontMin = fontMin
                    
                    fontMin += fontStep
                    
                    fontMax = fontMin * maxMinRatio
                    fontRange = fontMax - fontMin
                }
            } while wordArea < (containerArea * scaleFactor)
            
            wordArea = 0.0
            
            for cloudWord in cloudWords {
                if (isCancelled) {
                    return
                }
                
                let scale:CGFloat = CGFloat(cloudWord.wordCount - minWordCount) / (deltaWordCount != 0 ? deltaWordCount : 1)
                cloudWord.pointSize = fontMin + (fontStep * floor(scale * (fontRange / fontStep))) // + dynamicTypeDelta
                
                cloudWord.determineWordOrientation(orientation: orientation, containerSize: containerSize, scale:containerScale, fontName:cloudFont.fontName)
                
                // Check to see if the current word fits in the container
                
                wordArea += cloudWord.boundsArea // * 1.1 // Another way to account for whitespace between words - parameter to vary
                
                if (wordArea >= containerArea) || (cloudWord.boundsSize.width >= containerSize.width) || (cloudWord.boundsSize.height >= containerSize.height) {
                    wordAreaExceedsContainerSize = true

                    oldFontMin = fontMin

                    fontMin = fontMin == minFontMin ? minFontMin : fontMin - fontStep
                    
                    fontMax = fontMin * maxMinRatio
                    fontRange = fontMax - fontMin
                    break
                }
            }
        } while wordAreaExceedsContainerSize && (oldFontMin != minFontMin)
    }
    
    func assignColorsForWords()
    {
        guard let cloudWords = cloudWords else {
            return
        }
        
        var index = 0
        
        for cloudWord in cloudWords {
            if isCancelled {
                break
            }

            cloudWord.wordColor = index % 5 // Simple way to allocate color - round-robin
            
            index += 1
        }
    }
    
    func assignPreferredPlacementsForWords()
    {
        guard let cloudWords = cloudWords else {
            return
        }
        
        guard let containerSize = containerSize else {
            return
        }
        
        for cloudWord in cloudWords {
            if (isCancelled) {
                return;
            }
            
            // Assign a new preferred location for each word, as the size may have changed
            cloudWord.determineRandomWordPlacement(containerSize:containerSize, scale:containerScale)
        }
    }
    
    func reorderWordsByDescendingWordArea()
    {
        // Words that only fit one way go to the top of the list.
        cloudWords?.sort(by: { (first:CloudWord, second:CloudWord) -> Bool in
            switch (first.onlyFitsOneWay(containerSize:self.containerSize), second.onlyFitsOneWay(containerSize:self.containerSize)) {
            case (false, true):
                return false
                
            default:
                return true
            }
        })
        
        var sortDescriptors = [NSSortDescriptor]()
        
        sortDescriptors.append(NSSortDescriptor(key: #keyPath(CloudWord.pointSize), ascending: false))
        
        sortDescriptors.append(NSSortDescriptor(key: #keyPath(CloudWord.boundsArea), ascending: false))
        
        cloudWords = (cloudWords as NSArray?)?.sortedArray(using: sortDescriptors) as? [CloudWord]
    }

    func layoutCloudWords()
    {
        guard var cloudWords = cloudWords else {
            return
        }
        
        guard let containerSize = containerSize else {
            return
        }
        
        guard let fontName = cloudFont?.fontName else {
            return
        }
        
        let wordCount = cloudWords.count
        
        repeat {
            print("\(String(format: "%0.1f",Float(cloudWords.count)/Float(wordCount)*100))%")
            
            let cloudWord = cloudWords.removeFirst()
            
            if (isCancelled) {
                return
            }

            // Can the word can be placed at its preferred location?
            if (hasPlacedWord(word: cloudWord)) {
                if placedCloudWords == nil {
                    placedCloudWords = [CloudWord]()
                }
                placedCloudWords?.append(cloudWord)
                // Yes. Move on to the next word
                delegate?.update(cloudWords: placedCloudWords)
                continue
            }
            
            var index = 0

            var placed = hasFoundConcentricPlacementForWord(word: cloudWord)
            
            while !placed {
                print("\(String(format: "%0.1f",Float(cloudWords.count)/Float(wordCount)*100))%")

                // No placement found centered on preferred location. Pick a new location at random
                cloudWord.determineWordOrientation(orientation: orientation, containerSize:containerSize, scale:containerScale, fontName:fontName)
                cloudWord.determineRandomWordPlacement(containerSize:containerSize, scale:containerScale)
                
                if (isCancelled) {
                    return
                }
                
                index += 1
                
                if index == cloudWord.wordCount {
                    cloudWords.append(cloudWord)
                    break
                }
                
                placed = hasFoundConcentricPlacementForWord(word: cloudWord)
            }
            
            if placed {
                placedCloudWords?.append(cloudWord)
                delegate?.update(cloudWords: placedCloudWords)
            }
        } while cloudWords.count > 0
        
        delegate?.finished(cloudWords: placedCloudWords)
    }
    
    func hasFoundConcentricPlacementForWord(word:CloudWord) -> Bool
    {
        guard let containerSize = containerSize else {
            return false
        }
        
        let containerRect = CGRect(x: 0.0, y:0.0, width:containerSize.width, height:containerSize.height)
        
        let savedCenter = word.boundsCenter
        
        var radiusMultiplier:CGFloat = 1 // 1, 2, 3, until radius too large for container
        
        let radiusMultiplierIncrement:CGFloat = 1
        
        var radiusWithinContainerSize = true
        
        // Placement terminated once no points along circle are within container
        
        while (radiusWithinContainerSize) {
            // Start with random angle and proceed 360 degrees from that point
            
            let initialDegree = arc4random_uniform(360)
            let finalDegree = initialDegree + 360
            
            // Try more points along circle as radius increases
            
            let degreeStep = radiusMultiplier == 1 ? 15 : radiusMultiplier == 2 ? 10 : 5
            
            let radius:CGFloat = radiusMultiplier * word.pointSize
            
            radiusWithinContainerSize = false // NO until proven otherwise
            
            for degrees in stride(from:initialDegree, to:finalDegree, by:degreeStep) {
                if (isCancelled) {
                    return false
                }
                
                let radians:CGFloat = CGFloat(degrees) * CGFloat.pi / 180.0
                
                let x:CGFloat = cos(radians) * radius
                let y:CGFloat = sin(radians) * radius
                
                word.determineNewWordPlacement(center: savedCenter, xOffset:x, yOffset:y, scale:containerScale)
                
                let wordRect = word.paddedFrame
                
                if containerRect.contains(wordRect) {
                    radiusWithinContainerSize = true
                    if (hasPlacedWord(word: word, wordRect:wordRect)) {
                        return true
                    }
                }
            }
            
            // No placement found for word on points along current radius.  Try larger radius.
            
            radiusMultiplier += radiusMultiplierIncrement
        }
        
        // The word did not fit along any concentric circles within the bounds of the container
        
        return false
    }
    
    func hasPlacedWord(word:CloudWord) -> Bool
    {
        let wordRect = word.paddedFrame
        
        return hasPlacedWord(word: word, wordRect:wordRect)
    }
    
    func hasPlacedWord(word:CloudWord,wordRect:CGRect) -> Bool
    {
        guard !isCancelled else {
            return false
        }
        
        if let intersects = boundingRects?.hasGlyphThatIntersectsWithWordRect(wordRect:wordRect), intersects {
            // Word intersects with another word
            return false
        }
        
        // Word doesn't intersect any (glyphs of) previously placed words.  Place it
        
        if let wordText = word.wordText {
            self.delegate?.insertWord(word: wordText, pointSize:word.pointSize, color:word.wordColor, center:word.boundsCenter, isVertical:word.isWordOrientationVertical)
        } else {
            
        }

        addGlyphBoundingRectToQuadTreeForWord(word:word)
        
        return true
    }
    
    func addGlyphBoundingRectToQuadTreeForWord(word:CloudWord)
    {
        guard let containerSize = containerSize else {
            return
        }
        
        guard let cloudFont = cloudFont else {
            return
        }
        
        guard let font = UIFont(name: cloudFont.fontName, size: word.pointSize) else {
            return
        }
        
        guard let wordText = word.wordText else {
            return
        }
        
        var overallGlyphRect = CGRect.zero
        
        let wordRect = word.frame
        
        // Typesetting is always done in the horizontal direction
        
        // There's a small possibility that a particular typeset word using a particular font, may still not fit within a slightly larger frame.  Give the typesetter a very large frame, to ensure that any word, at any point size, can be typeset on a line
        
        let horizontalFrame = CGRect(x: 0.0,y: 0.0,
                                     width: word.wordOrientationVertical ? containerSize.height : containerSize.width,
                                     height: word.wordOrientationVertical ? containerSize.width : containerSize.height)
        
        let attributes = [NSAttributedStringKey.font : font]
        
        let attributedString = NSAttributedString(string: wordText, attributes: attributes)
        
        let cfas = attributedString as CFAttributedString

        let framesetter = CTFramesetterCreateWithAttributedString(cfas)

        let drawingPath = CGPath(rect: horizontalFrame, transform: nil)

        let textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), drawingPath, nil)

        let lines = CTFrameGetLines(textFrame)

        if (CFArrayGetCount(lines) > 0) {
            var lineOrigin = CGPoint.zero

            CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 1), &lineOrigin)

            let line = (lines as NSArray).object(at: 0) as! CTLine

            let runs = CTLineGetGlyphRuns(line)

            for runIndex in 0..<CFArrayGetCount(runs) {
                let run = (runs as NSArray).object(at: runIndex) as! CTRun

                let runAttributes:CFDictionary = CTRunGetAttributes(run)

                let font = (runAttributes as NSDictionary)[NSAttributedStringKey.font] as! CTFont

                for glyphIndex in 0..<CTRunGetGlyphCount(run) {
                    var glyphPosition = CGPoint.zero

                    CTRunGetPositions(run, CFRangeMake(glyphIndex, 1), &glyphPosition)

                    var glyph = CGGlyph()

                    CTRunGetGlyphs(run, CFRangeMake(glyphIndex, 1), &glyph)

                    var glyphBounds = CGRect.zero

                    CTFontGetBoundingRectsForGlyphs(font, CTFontOrientation.default, &glyph, &glyphBounds, 1);

                    var glyphRect = CGRect.zero

                    let glyphX:CGFloat = lineOrigin.x + glyphPosition.x + glyphBounds.minX
                    let glyphY:CGFloat = horizontalFrame.height - (lineOrigin.y + glyphPosition.y + glyphBounds.maxY)

                    if (word.isWordOrientationVertical) {
                        glyphRect = CGRect(x: wordRect.width - glyphY,y: glyphX, width: -glyphBounds.height, height: glyphBounds.width)
                    } else {
                        glyphRect = CGRect(x: glyphX,y: glyphY, width: glyphBounds.width, height: glyphBounds.height)
                    }

                    glyphRect = glyphRect.offsetBy(dx: wordRect.minX, dy: wordRect.minY)

                    // Added some buffer space
                    glyphRect = glyphRect.insetBy(dx: -2, dy: -2)

                    if overallGlyphRect == CGRect.zero {
                        overallGlyphRect = glyphRect
                    } else {
                        overallGlyphRect = overallGlyphRect.union(glyphRect)
                    }
                }
            }
        }
        
        if isCancelled {
            return
        }
        
        if overallGlyphRect != CGRect.zero {
            word.overallGlyphBoundingRect = overallGlyphRect
                
            _ = boundingRects?.insertBoundingRect(boundingRect: overallGlyphRect)
            
            if let debug = (delegate as? CloudViewController)?.debug, debug {
                Thread.onMainThread {
                    _ = self.delegate?.insertBoundingRect(boundingRect: overallGlyphRect)
                }
            }
        }
    }
    
    func addWordRectToQuadTreeForWord(word:CloudWord)
    {
        let wordRect = word.frame

        _ = boundingRects?.insertBoundingRect(boundingRect: wordRect)
        
        if let debug = (delegate as? CloudViewController)?.debug, debug {
            Thread.onMainThread {
                _ = self.delegate?.insertBoundingRect(boundingRect: wordRect)
            }
        }
    }
}
