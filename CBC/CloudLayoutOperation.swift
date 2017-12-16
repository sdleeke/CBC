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
//    func insertTitle(cloudTitle:String)
    func insertWord(word:String, pointSize:CGFloat, color:Int, center:CGPoint, isVertical:Bool)
    func insertBoundingRect(boundingRect:CGRect)
}

class CloudLayoutOperation : Operation
{
    var cloudFont : UIFont?
    var cloudTitle : String?
    var cloudWords : [CloudWord]?
    var containerSize : CGSize?
    var containerScale : CGFloat = 0.0
    var delegate:CloudLayoutOperationDelegate?
    var boundingRects : QuadTree?
    
    override var description: String
    {
        get {
            return "container size = (\(containerSize?.height) \(containerSize?.width)), delegate = \(delegate); words = \(cloudWords.debugDescription)"
        }
    }
    
    init(cloudWords:[[String:Any]]?, title:String?, containerSize:CGSize, containerScale:CGFloat, cloudFont: UIFont?, delegate:CloudLayoutOperationDelegate)
    {
        super.init()
        
        // Custom initialization
    
        var words = [CloudWord]()

        if let cloudWords = cloudWords {
            for cloudWord in cloudWords {
                if let word = cloudWord["word"] as? String, let count = cloudWord["count"] as? Int {
                    words.append(CloudWord(word: word, wordCount: count))
                }
            }
        }

        self.cloudWords = words.count > 0 ? words : nil

        self.cloudTitle = title
        
        self.containerSize = containerSize
        self.containerScale = containerScale

        self.delegate = delegate
        
        self.cloudFont = cloudFont

        self.boundingRects = QuadTree(frame: CGRect(x: 0.0, y: 0.0, width: containerSize.width, height: containerSize.height))
    }
    
    override func main()
    {
//        if isCancelled {
//            return
//        }
//
//        layoutCloudTitle()
        
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

//        if isCancelled {
//            return
//        }
//
//        setSizesForWords()
        
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
        
//        CGFloat minWordCount = [[self.cloudWords valueForKeyPath:@"@min.wordCount"] doubleValue];
//        CGFloat maxWordCount = [[self.cloudWords valueForKeyPath:@"@max.wordCount"] doubleValue];
        
        let deltaWordCount:CGFloat = CGFloat(maxWordCount) - CGFloat(minWordCount)
        let ratioCap:CGFloat = 20.0
        
        let maxMinRatio:CGFloat = CGFloat(min((CGFloat(maxWordCount) / CGFloat(minWordCount)), ratioCap))
        if maxMinRatio == ratioCap {
            print(CGFloat(maxWordCount) / CGFloat(minWordCount))
        }
        
        // Start with these values, which will be decreased as needed that all the words may fit the container
        
        let minFontMin:CGFloat = 4.0
        var oldFontMin:CGFloat = 0.0
        var fontMin:CGFloat = 12.0
        var fontMax:CGFloat = fontMin * maxMinRatio;

//        let dynamicTypeDelta:CGFloat = 1.0
        
//        NSInteger dynamicTypeDelta = [UIFont lal_preferredContentSizeDelta]
        
        let containerArea:CGFloat = CGFloat(containerSize.width * containerSize.height) // * 0.9
        var wordAreaExceedsContainerSize = false
        
        repeat {
            var wordArea:CGFloat = 0.0;
            wordAreaExceedsContainerSize = false
            
            var fontRange:CGFloat = fontMax - fontMin
            let fontStep:CGFloat = 1.0 // 3.0
            
            // Normalize word weights
            
            for cloudWord in cloudWords {
                if (isCancelled) {
                    return
                }
                
                let scale:CGFloat = CGFloat(cloudWord.wordCount - minWordCount) / (deltaWordCount != 0 ? deltaWordCount : 1)
                cloudWord.pointSize = fontMin + (fontStep * floor(scale * (fontRange / fontStep))) // + dynamicTypeDelta
                
//                print(cloudWord.wordCount,minWordCount,deltaWordCount,cloudWord.pointSize,fontMin,fontRange,fontStep,scale)
                
                cloudWord.determineRandomWordOrientationInContainerWithSize(containerSize: containerSize, scale:containerScale, fontName:cloudFont.fontName)
                
                // Check to see if the current word fits in the container
                
                wordArea += cloudWord.boundsArea
                
                if (wordArea >= containerArea) || (cloudWord.boundsSize.width >= containerSize.width) || (cloudWord.boundsSize.height >= containerSize.height) {
                    wordAreaExceedsContainerSize = true

                    oldFontMin = fontMin

                    fontMin = fontMin == minFontMin ? minFontMin : fontMin - 1
                    
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

//        let cloudWordsCount:CGFloat = CGFloat(cloudWords.count)

        var index = 0
        
        for cloudWord in cloudWords {
            if isCancelled {
                break
            }

            cloudWord.wordColor = index % 5
            
//            let scale:CGFloat = (cloudWordsCount - index) / cloudWordsCount
//
//            cloudWord.determineColorForScale(scale:scale)
            
            index += 1
        }

//        [self.cloudWords enumerateObjectsUsingBlock:^(CloudWord *word, NSUInteger index, BOOL *stop) {
//            *stop = [self isCancelled];
//            CGFloat scale = (cloudWordsCount - index) / cloudWordsCount;
//            [word determineColorForScale:scale];
//            }];
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
            cloudWord.determineRandomWordPlacementInContainerWithSize(containerSize:containerSize, scale:containerScale)
        }
    }
    
//    func setSizesForWords()
//    {
//        guard let cloudWords = cloudWords else {
//            return
//        }
//
//        guard let containerSize = containerSize else {
//            return
//        }
//
//        for cloudWord in cloudWords {
//            if (isCancelled) {
//                return;
//            }
//
//            // Assign a new size for each word
//            cloudWord.setSizeToGlyphBoundingRect(containerSize:containerSize, cloudFont:cloudFont)
//        }
//    }

    func reorderWordsByDescendingWordArea()
    {
        var sortDescriptors = [NSSortDescriptor]()
        
        sortDescriptors.append(NSSortDescriptor(key: #keyPath(CloudWord.boundsArea), ascending: false))
        
        sortDescriptors.append(NSSortDescriptor(key: #keyPath(CloudWord.pointSize), ascending: false))

        cloudWords = (cloudWords as NSArray?)?.sortedArray(using: sortDescriptors) as? [CloudWord]

        cloudWords = cloudWords?.sorted(by: { (first:CloudWord, second:CloudWord) -> Bool in
//            print(first.wordText!,first.onlyFitsOneWay(containerSize:self.containerSize),second.wordText!,second.onlyFitsOneWay(containerSize:self.containerSize))
            
            if first.onlyFitsOneWay(containerSize:self.containerSize) && second.onlyFitsOneWay(containerSize:self.containerSize) {
                return false
            }
            if first.onlyFitsOneWay(containerSize:self.containerSize) && !second.onlyFitsOneWay(containerSize:self.containerSize) {
                return true
            }
            if !first.onlyFitsOneWay(containerSize:self.containerSize) && second.onlyFitsOneWay(containerSize:self.containerSize) {
                return true
            }
            if !first.onlyFitsOneWay(containerSize:self.containerSize) && !second.onlyFitsOneWay(containerSize:self.containerSize) {
                return false
            }
            return true
        })
        
//        sortedArrayUsingDescriptors:@[primarySortDescriptor, secondarySortDescriptor]];

//        NSSortDescriptor *primarySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"boundsArea" ascending:NO];
//        NSSortDescriptor *secondarySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pointSize" ascending:NO];
        
//        cloudWords?.sorted(by: { (first:CloudWord, second:CloudWord) -> Bool in
//            if first.boundsArea < second.boundsArea {
//                return false
//            }
//            if first.boundsArea > second.boundsArea {
//                return true
//            }
//            if first.boundsArea == second.boundsArea {
//                if first.pointSize < second.pointSize {
//                    return false
//                }
//                if first.pointSize > second.pointSize {
//                    return true
//                }
//                if first.pointSize == second.pointSize {
//                    return true
//                }
//            }
//
//            return false
//        })
    }
    
//    func layoutCloudTitle()
//    {
//        UIButton *sizingButton = [UIButton buttonWithType:UIButtonTypeSystem];
//        sizingButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 5.0, 2.0);
//
//        [sizingButton setTitle:self.cloudTitle forState:UIControlStateNormal];
//        CGFloat pointSize = kLALsystemPointSize + [UIFont lal_preferredContentSizeDelta];
//        sizingButton.titleLabel.font = [UIFont systemFontOfSize:pointSize];
//
//        // UIKit sizeToFit is not thread-safe
//        [sizingButton performSelectorOnMainThread:@selector(sizeToFit) withObject:nil waitUntilDone:YES];
//
//        CGRect bounds = CGRectMake(0.0, self.containerSize.height - CGRectGetHeight(sizingButton.bounds), CGRectGetWidth(sizingButton.bounds), CGRectGetHeight(sizingButton.bounds));
//        [self.glyphBoundingRects insertBoundingRect:bounds];
//
//        __weak id<CloudLayoutOperationDelegate> delegate = self.delegate;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [delegate insertTitle:self.cloudTitle];
//            //#ifdef DEBUG
//            //        [delegate insertBoundingRect:bounds];
//            //#endif
//            });
//    }
    
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
        
        repeat {
            let cloudWord = cloudWords.removeFirst()
            
            if (isCancelled) {
                return
            }

            // Can the word can be placed at its preferred location?
            if (hasPlacedWord(word: cloudWord)) {
                // Yes. Move on to the next word
                continue
            }
            
            var index = 0
            
            while !hasFoundConcentricPlacementForWord(word: cloudWord) {
                // No placement found centered on preferred location. Pick a new location at random
                cloudWord.determineRandomWordOrientationInContainerWithSize(containerSize:containerSize, scale:containerScale, fontName:fontName)
                cloudWord.determineRandomWordPlacementInContainerWithSize(containerSize:containerSize, scale:containerScale)
                
                if (isCancelled) {
                    return
                }
                
                print(cloudWords.count,index,cloudWord.wordText ?? "nil",cloudWord.wordCount)
                
                index += 1
                
                if index == 1 {
                    cloudWords.append(cloudWord)
                    break
                }
            }
        } while cloudWords.count > 0
        
//        var failed = false
//
//        for cloudWord in cloudWords {
//            if (isCancelled) {
//                return
//            }
//
//            // Can the word can be placed at its preferred location?
//            if (hasPlacedWord(word: cloudWord)) {
//                // Yes. Move on to the next word
//                continue
//            }
//
////            var placed = false
//
//            var index = 0
//
//            while !hasFoundConcentricPlacementForWord(word: cloudWord) {
//                // No placement found centered on preferred location. Pick a new location at random
//                cloudWord.determineRandomWordOrientationInContainerWithSize(containerSize:containerSize, scale:containerScale, fontName:fontName)
//                cloudWord.determineRandomWordPlacementInContainerWithSize(containerSize:containerSize, scale:containerScale)
//
//                if (isCancelled) {
//                    return
//                }
//
//                index += 1
//
//                if index == 100 {
//                    failed = true
//                    break
//                }
//            }
//
//            if failed {
//                break
//            }

//            placed = true

            // If there's a spot for a word, it will almost always be found within 50 attempts.
            // Make 100 attempts to handle extremely rare cases where more than 50 attempts are needed to place a word
            
//            for attempt in 0..<100 {
//                // Try alternate placements along concentric circles
//                if (hasFoundConcentricPlacementForWord(word: cloudWord)) {
//                    placed = true
//                    break
//                }
//
//                if (isCancelled) {
//                    return
//                }
//
//                // No placement found centered on preferred location. Pick a new location at random
//                cloudWord.determineRandomWordOrientationInContainerWithSize(containerSize:containerSize, scale:containerScale, fontName:cloudFont!.fontName)
//                cloudWord.determineRandomWordPlacementInContainerWithSize(containerSize:containerSize, scale:containerScale)
//            }
            
            // Reduce font size if word doesn't fit
//            if (!placed) {
//                NSLog("Couldn't find a spot for \(cloudWord.debugDescription)");
//            }
//        }
        
//        if failed {
//            Thread.onMainThread {
//                (self.delegate as? CloudViewController)?.relayoutCloudWords()
//            }
//            self.cancel()
//        }
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
                
                word.determineNewWordPlacementFromSavedCenter(center: savedCenter, xOffset:x, yOffset:y, scale:containerScale)
                
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
        if let intersects = boundingRects?.hasGlyphThatIntersectsWithWordRect(wordRect:wordRect), intersects {
            // Word intersects with another word
            return false
        }
        
        // Word doesn't intersect any (glyphs of) previously placed words.  Place it
        
        Thread.onMainThread {
            if let wordText = word.wordText {
                self.delegate?.insertWord(word: wordText, pointSize:word.pointSize, color:word.wordColor, center:word.boundsCenter, isVertical:word.isWordOrientationVertical)
            }
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
        
        let attributes = [NSFontAttributeName : font]
        
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

    //            let line = CFArrayGetValueAtIndex(lines, 0) as! CTLine

            let runs = CTLineGetGlyphRuns(line)

            for runIndex in 0..<CFArrayGetCount(runs) {
                let run = (runs as NSArray).object(at: runIndex) as! CTRun

    //                let run = CFArrayGetValueAtIndex(runs, runIndex) as! CTRun

                let runAttributes:CFDictionary = CTRunGetAttributes(run)

                let font = (runAttributes as NSDictionary)[NSFontAttributeName] as! CTFont
    //                let font = CFDictionaryGetValue(runAttributes, NSFontAttributeName) as! CTFont

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
                    
                    //#ifdef DEBUG
                    //                __weak id<CloudLayoutOperationDelegate> delegate = self.delegate;
                    //                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    [delegate insertBoundingRect:glyphRect];
                    //                });
                    //#endif
                }
            }
        }
        
        if isCancelled {
            return
        }
        
        if overallGlyphRect != CGRect.zero {
            _ = boundingRects?.insertBoundingRect(boundingRect: overallGlyphRect)
            
            if let debug = (delegate as? CloudViewController)?.debug, debug {
                Thread.onMainThread {
                    self.delegate?.insertBoundingRect(boundingRect: overallGlyphRect)
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
                self.delegate?.insertBoundingRect(boundingRect: wordRect)
            }
        }
    }
}
