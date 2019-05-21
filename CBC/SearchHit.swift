//
//  SearchHit.swift
//  CBC
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SearchHit
{
    var mediaItem:MediaItem?
    
    var searchText:String?
    
    init(_ mediaItem:MediaItem?,_ searchText:String?)
    {
        self.mediaItem = mediaItem
        self.searchText = searchText
    }
    
    deinit {
        debug(self)
    }
    
    var title:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasTitle, let searchText = searchText else {
                return false
            }
            return mediaItem.title?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var formattedDate:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.formattedDate?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var speaker:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasSpeaker, let searchText = searchText else {
                return false
            }
            return mediaItem.speaker?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var scriptureReference:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.scriptureReference?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var className:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasClassName, let searchText = searchText else {
                return false
            }
            return mediaItem.className?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var eventName:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard mediaItem.hasEventName, let searchText = searchText else {
                return false
            }
            return mediaItem.eventName?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var tags:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            return mediaItem.tags?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var transcript:Bool {
//        if #available(iOS 11.0, *) {
//            return transcriptPDF
//        } else {
            return transcriptHTML
//        }
    }
    private var transcriptHTML:Bool {
        get {
            guard let mediaItem = mediaItem else {
                return false
            }
            
            guard let searchText = searchText else {
                return false
            }
            
            return mediaItem.notesHTML?.result?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
//    @available(iOS 11.0, *)
//    private var transcriptPDF:Bool {
//        get {
//            guard let mediaItem = mediaItem else {
//                return false
//            }
//
//            guard let searchText = searchText else {
//                return false
//            }
//
//            return mediaItem.notesPDFText?.result?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
//        }
//    }
}
