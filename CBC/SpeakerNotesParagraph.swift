//
//  SpeakerNotesParagraph.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Manages all information about the speaker notes paragraphs in a list of mediaItems.
 
 */

class SpeakerNotesParagraph
{
    var name : String?
    
    var list : [MediaItem]?
    
    init(name:String? = nil,list:[MediaItem]?)
    {
        self.name = name
        self.list = list
    }
    
    lazy var words : Fetch<[String:Int]>? = { [weak self] in
        let fetch = Fetch<[String:Int]>(name:nil)
        
        fetch.fetch = {
            guard let mediaItems = self?.list?.filter({ (mediaItem) -> Bool in
                if !mediaItem.hasNotesText {
                    return false
                } else {
                    if let name = self?.name {
                        return mediaItem.speaker == name
                    } else {
                        return true
                    }
                }
            }) else {
                return nil
            }
            
            var allNotesParagraphWords = [String:Int]()
            
            for mediaItem in mediaItems {
                if let notesParagraphWords = mediaItem.notesParagraphWords?.result {
                    // notesParagraphWords.count is the number of paragraphs.
                    // So we can get the distribution of the number of paragraphs
                    // in each document - if that is useful.
                    allNotesParagraphWords.merge(notesParagraphWords) { (firstValue, secondValue) -> Int in
                        return firstValue + secondValue
                    }
                }
            }
            
            return allNotesParagraphWords.count > 0 ? allNotesParagraphWords : nil
        }
        
        return fetch
    }()

    var overallAverageLength : Int?
    {
        get {
            guard let values = averageLength?.values else {
                return nil
            }
            
            let averageLengths = Array(values)
            
            return averageLengths.reduce(0,+) / averageLengths.count
        }
    }
    
    var averageLength : [String:Int]?
    {
        get {
            return lengths?.result?.mapValues({ (paragraphLengths:[Int]) -> Int in
                return paragraphLengths.reduce(0,+) / paragraphLengths.count
            })
        }
    }
    
    lazy var lengths : Fetch<[String:[Int]]>? = { [weak self] in
        let fetch = Fetch<[String:[Int]]>(name:nil)
        
        fetch.fetch = {
            guard let mediaItems = self?.list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.speaker == self?.name) && mediaItem.hasNotesText // && (mediaItem.category == self.category)
            }) else {
                return nil
            }
            
            var allNotesParagraphLengths = [String:[Int]]()
            
            for mediaItem in mediaItems {
                if let notesParagraphLengths = mediaItem.notesParagraphLengths?.result {
                    allNotesParagraphLengths[mediaItem.mediaCode] = notesParagraphLengths
                }
            }
            
            return allNotesParagraphLengths.count > 0 ? allNotesParagraphLengths : nil
        }
        
        return fetch
    }()
}
