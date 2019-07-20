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
    
    init?(name:String? = nil,list:[MediaItem]?)
    {
        guard list?.count > 0 else {
            return nil
        }

        if let name = name, !name.isEmpty {
            if list?.filter({ (mediaItem) -> Bool in
                if !mediaItem.hasNotesText {
                    return false
                } else {
                    return mediaItem.speaker == name
                }
            }).count == 0 {
                return nil
            }
        }
        
        self.name = name
        self.list = list
    }
    
    lazy var words : Fetch<[String:Int]>? = { [weak self] in
        let fetch = Fetch<[String:Int]>(name:nil)
        
        fetch.fetch = { [weak fetch] in
            guard let mediaItems = self?.list?.filter({ (mediaItem) -> Bool in
                if !mediaItem.hasNotesText {
                    return false
                } else {
                    if let name = self?.name, !name.isEmpty {
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
                if fetch?.interrupt?() == true {
                    break
                }
                if let notesParagraphWords = mediaItem.notesParagraphWords?.result {
                    // notesParagraphWords.count is the number of paragraphs.
                    // So we can get the distribution of the number of paragraphs
                    // in each document - if that is useful.
                    allNotesParagraphWords.merge(notesParagraphWords) { (firstValue, secondValue) -> Int in
                        return firstValue + secondValue
                    }
                }
            }
            
            if fetch?.interrupt?() == true {
                return nil
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
        
        fetch.fetch = { [weak fetch] in
            guard let mediaItems = self?.list?.filter({ (mediaItem) -> Bool in
                if let name = self?.name, !name.isEmpty {
                    return (mediaItem.speaker == name) && mediaItem.hasNotesText // && (mediaItem.category == self.category)
                } else {
                    return true
                }                    
            }) else {
                return nil
            }
            
            var allNotesParagraphLengths = [String:[Int]]()
            
            for mediaItem in mediaItems {
                if fetch?.interrupt?() == true {
                    break
                }
                if let notesParagraphLengths = mediaItem.notesParagraphLengths?.result {
                    allNotesParagraphLengths[mediaItem.mediaCode] = notesParagraphLengths
                }
            }
            
            if fetch?.interrupt?() == true {
                return nil
            }
            
            return allNotesParagraphLengths.count > 0 ? allNotesParagraphLengths : nil
        }
        
        return fetch
    }()
}
