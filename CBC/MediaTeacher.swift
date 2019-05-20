//
//  MediaTeacher.swift
//  CBC
//
//  Created by Steve Leeke on 3/28/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Abstract class for a dictionary backed class, i.e. properties are values in the dictionary
 
 */

class Storage
{
    var storage:[String:Any]?
    
    subscript(key:String?) -> Any?
    {
        get {
            guard let key = key else {
                return nil
            }
            return storage?[key]
        }
        set {
            guard let key = key else {
                return
            }
            storage?[key] = newValue
        }
    }
    
    init?(_ storage:[String:Any]?)
    {
        guard let storage = storage else {
            return nil
        }
        
        self.storage = storage
    }
    
    deinit {
        debug(self)
    }
}

/**
 
 Dictionary backed class for streaming entries
 
 */

class Streaming : Storage
{
    var liveNow : Bool?
    {
        get {
            return self["liveNow"] as? Bool
        }
    }
    
    var start : String?
    {
        get {
            return self["start"] as? String
        }
    }
    
    var startDate : Date?
    {
        get {
            if let start = start {
                return Date(dateString: start)
            } else {
                return nil
            }
        }
    }
    
    var end : String?
    {
        get {
            return self["end"] as? String
        }
    }
    
    var endDate : Date?
    {
        get {
            if let end = end {
                return Date(dateString: end)
            } else {
                return nil
            }
        }
    }
    
    var startTs : Int?
    {
        get {
            return self["startTs"] as? Int
        }
    }
    
    var endTs : Int?
    {
        get {
            return self["endTs"] as? Int
        }
    }
}

/**
 
Dictionary backed class that has properties for file urls.
 
 Properties:
 - slides
 - transcript
 - outline
 - html
 */

class Files : Storage
{
    var slides : String?
    {
        get {
            return self[Field.slides] as? String
        }
    }
    
    var notes : String?
    {
        get {
            return self[Field.notes] as? String
        }
    }
    
    var notesHTML : String?
    {
        get {
            return self[Field.notes_html] as? String
        }
    }
    
    var transcript : String?
    {
        get {
            return self[Field.transcript] as? String
        }
    }
    
    var transcriptHTML : String?
    {
        get {
            return self[Field.transcript_html] as? String
        }
    }
    
    var outline : String?
    {
        get {
            return self[Field.outline] as? String
        }
    }
}

/**
 
 Abstract dictionary backed class
 
 Properties:
    - id
    - name
 */

class Base : Storage
{
    var id : Int?
    {
        get {
            return self[Field.mediaCode] as? Int
        }
    }
    
    var name : String?
    {
        get {
            return self[Field.name] as? String
        }
    }
}

/**
 
 Abstract dictionary backed class with id/name

 */

class Series : Base
{
    
}

/**
 
 Abstract dictionary backed class with id/name
 
 */

class Event : Base
{
    
}

/**
 
 Abstract dictionary backed class with id/name
 
 */

class Suffix : Base
{
    var suffix : String?
    {
        get {
            return self[Field.suffix] as? String
        }
    }
}


/**
 
 Abstract dictionary backed class for audio
 
 Parameters:
    - mp3 url
    - duration
    - file size
 */

class Audio : Storage
{
    var mp3 : String?
    {
        return self[Field.mp3] as? String
    }
    
    var duration : String?
    {
        return self[Field.duration] as? String
    }
    
    var filesize : Int?
    {
        get {
            guard let filesize = self[Field.filesize] as? String else {
                return nil
            }
            
            return Int(filesize)
        }
    }
}

/**
 
 Abstract dictionary backed class for video
 
 Parameters:
 - mp4 url
 - m3u8 url
 - poster url
 */

class Video : Storage
{
    var mp4 : String?
    {
        return self[Field.vimeo_mp4] as? String
    }
    
    var m3u8 : String?
    {
        return self[Field.vimeo_m3u8] as? String
    }
    
    var poster : String?
    {
        return self[Field.poster] as? String
    }
}

/**
 
 Abstract dictionary backed class with id, name, suffix

 */

class Category : Suffix
{

}

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Group : Suffix
{

}

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Teacher : Suffix
{
    var status : String?
    {
        get {
            return self[Field.status] as? String
        }
    }
        
    lazy var speakerNotesParagraphWords : Fetch<[String:Int]>? = {
        let fetch = Fetch<[String:Int]>(name:nil)

        fetch.fetch = {
            guard let mediaItems = Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
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
//            guard let mediaItems = Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
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
            guard let mediaItems = Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                return (mediaItem.speaker == self.name) && mediaItem.hasNotesText // && (mediaItem.category == self.category)
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
//            guard let mediaItems = Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
//                return (mediaItem.category == self.category) && (mediaItem.speaker == self.speaker) && mediaItem.hasNotesText
//            }) else {
//                return nil
//            }
//
//            var allNotesParagraphLengths = [String:[Int]]()
//
//            for mediaItem in mediaItems {
//                if let notesParagraphLengths = mediaItem.notesParagraphLengths?.result {
//                    allNotesParagraphLengths[mediaItem.mediaCode] = notesParagraphLengths
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

//    init(id:Int,name:String?,status:String?,suffix:String? = nil)
//    {
//        self.id = id
//        self.name = name
//        self.status = status
//        self.suffix = suffix
//    }
}
