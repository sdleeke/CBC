//
//  MediaTeacher.swift
//  CBC
//
//  Created by Steve Leeke on 3/28/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

class MediaTeacher
{
    deinit {
        
    }
    
    var name : String?
    var title : String?
    
    lazy var speakerNotesParagraphWords : Fetch<[String:Int]>? = {
        let fetch = Fetch<[String:Int]>(name:nil)

        fetch.fetch = {
            guard let mediaItems = Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.speaker == self.name) && mediaItem.hasNotesText // && (mediaItem.category == self.category)
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
    
    // Replace with Fetch?
    // How will we know when new transcripts are added?  On refresh when this is reset to nil.  Until then we WON'T.
    
//    private var _speakerNotesParagraphWords:[String:Int]?
//    {
//        didSet {
//
//        }
//    }
//    var speakerNotesParagraphWords:[String:Int]?
//    {
//        get {
//            guard _speakerNotesParagraphWords == nil else {
//                return _speakerNotesParagraphWords
//            }
//
//            guard let mediaItems = Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
//                return (mediaItem.category == self.category) && (mediaItem.speaker == self.speaker) && mediaItem.hasNotesText
//            }) else {
//                return nil
//            }
//
//            var allNotesParagraphWords = [String:Int]()
//
//            for mediaItem in mediaItems {
//                if let notesParagraphWords = mediaItem.notesParagraphWords?.result {
//                    // notesParagraphWords.count is the number of paragraphs.
//                    // So we can get the distribution of the number of paragraphs
//                    // in each document - if that is useful.
//                    allNotesParagraphWords.merge(notesParagraphWords) { (firstValue, secondValue) -> Int in
//                        return firstValue + secondValue
//                    }
//                }
//            }
//
//            _speakerNotesParagraphWords = allNotesParagraphWords.count > 0 ? allNotesParagraphWords : nil
//
//            return _speakerNotesParagraphWords
//        }
//        set {
//            _speakerNotesParagraphWords = newValue
//        }
//    }
    
    var overallAverageSpeakerNotesParagraphLength : Int?
    {
        get {
            guard let values = averageSpeakerNotesParagraphLength?.values else {
                return nil
            }
            
            let averageLengths = Array(values)
            
            return averageLengths.reduce(0,+) / averageLengths.count
        }
    }
    
    var averageSpeakerNotesParagraphLength : [String:Int]?
    {
        get {
            return speakerNotesParagraphLengths?.result?.mapValues({ (paragraphLengths:[Int]) -> Int in
                return paragraphLengths.reduce(0,+) / paragraphLengths.count
            })
        }
    }
    
    lazy var speakerNotesParagraphLengths : Fetch<[String:[Int]]>? = {
        let fetch = Fetch<[String:[Int]]>(name:nil)
        
        fetch.fetch = {
            guard let mediaItems = Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.speaker == self.name) && mediaItem.hasNotesText // && (mediaItem.category == self.category)
            }) else {
                return nil
            }
            
            var allNotesParagraphLengths = [String:[Int]]()
            
            for mediaItem in mediaItems {
                if let notesParagraphLengths = mediaItem.notesParagraphLengths?.result {
                    allNotesParagraphLengths[mediaItem.id] = notesParagraphLengths
                }
            }
            
            return allNotesParagraphLengths.count > 0 ? allNotesParagraphLengths : nil
        }
        
        return fetch
    }()

    
    // Replace with Fetch?
    // How will we know when new transcripts are added?  On refresh when this is reset to nil.
    
//    private var _speakerNotesParagraphLengths : [String:[Int]]?
//    {
//        didSet {
//
//        }
//    }
//    var speakerNotesParagraphLengths : [String:[Int]]?
//    {
//        get {
//            guard _speakerNotesParagraphLengths == nil else {
//                return _speakerNotesParagraphLengths
//            }
//
//            guard let mediaItems = Globals.shared.mediaRepository.list?.filter({ (mediaItem) -> Bool in
//                return (mediaItem.category == self.category) && (mediaItem.speaker == self.speaker) && mediaItem.hasNotesText
//            }) else {
//                return nil
//            }
//
//            var allNotesParagraphLengths = [String:[Int]]()
//
//            for mediaItem in mediaItems {
//                if let notesParagraphLengths = mediaItem.notesParagraphLengths?.result {
//                    allNotesParagraphLengths[mediaItem.id] = notesParagraphLengths
//                }
//            }
//
//            _speakerNotesParagraphLengths = allNotesParagraphLengths.count > 0 ? allNotesParagraphLengths : nil
//
//            return _speakerNotesParagraphLengths
//        }
//        set {
//            _speakerNotesParagraphLengths = newValue
//        }
//    }

    init(name:String?,title:String?)
    {
        self.name = name
        self.title = title
    }
}
