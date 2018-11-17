//
//  StringIndex.swift
//  CBC
//
//  Created by Steve Leeke on 10/15/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class StringIndex : NSObject
{
    // Make thread safe?
    var dict : [String:[[String:Any]]]?
    
    subscript(key:String) -> [[String:Any]]?
    {
        get {
            return dict?[key]
        }
        set {
            if dict == nil {
                dict = [String:[[String:Any]]]()
            }
            
            dict?[key] = newValue
        }
    }
    
    // Make thread safe?
    var keys : [String]?
    {
        guard let dict = dict else {
            return nil
        }
        
        return Array(dict.keys)
    }
    
    func stringIndex(key:String,sort:((String,String)->(Bool))?) -> [String:[String]]?
    {
        guard let keys = dict?.keys.sorted() else {
            return nil
        }
        
        var stringIndex = [String:[String]]()
        
        for dk in keys {
            if let values = dict?[dk] {
                for value in values {
                    if let string = value[key] as? String {
                        if stringIndex[dk] == nil {
                            stringIndex[dk] = [string]
                        } else {
                            stringIndex[dk]?.append(string)
                        }
                    }
                }
            }
        }
        
        if let sort = sort {
            for key in stringIndex.keys {
                stringIndex[key] = stringIndex[key]?.sorted(by: { (lhs:String, rhs:String) -> Bool in
                    return sort(lhs,rhs)
                })
            }
        }
        
        return stringIndex.count > 0 ? stringIndex : nil
    }
    
    convenience init?(mediaItems:[[String:Any]]?,sort:(([String:Any],[String:Any])->(Bool))?)
    {
        self.init()
        
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        var dict = [String:[[String:Any]]]()
        
        for mediaItem in mediaItems {
            if  let mediaID = mediaItem["mediaId"] as? String,
                let dateCreated = mediaItem["dateCreated"] as? String,
                let status = mediaItem["status"] as? String {
                
                var newDict:[String:Any] = ["mediaId":mediaID,"status":status]
                
                var category = "Other"
                
                if  let metadata = mediaItem["metadata"] as? [String:Any] { //,
                    newDict["metadata"] = metadata as Any
                    
                    if let string = metadata["title"] as? String {
                        newDict["title"] = string
                        
                        if let range = string.lowercased().range(of: " (\(Constants.Strings.Audio)".lowercased()) {
                            newDict["title"] = String(string[..<range.lowerBound])
                            category = Constants.Strings.Audio
                        }
                        
                        if let range = string.lowercased().range(of: " (\(Constants.Strings.Video)".lowercased()) {
                            newDict["title"] = String(string[..<range.lowerBound])
                            category = Constants.Strings.Video
                        }
                    } else {
                        newDict["title"] = "Unknown"
                    }
                    
                    if let lengthDict = metadata["length"] as? [String:Any], let length = lengthDict["milliseconds"] as? Int, let hms = (Double(length) / 1000.0).secondsToHMS {
                        newDict["length"] = hms
                    }
                } else {
                    
                }
                
                let dateStringFormatter = DateFormatter()
                
                dateStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                
                dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateStringFormatter.timeZone = TimeZone(abbreviation: "UTC")
                
                if let date = dateStringFormatter.date(from: dateCreated) {
                    newDict["dateCreated"] = date.mdyhm
                }
                
                if var title = newDict["title"] as? String {
                    title += "\nSource: \(category)"
                    
                    if let length = newDict["length"] {
                        title += "\nLength: \(length)"
                    }
                    if let dateCreated = newDict["dateCreated"] {
                        title += "\nCreated: \(dateCreated)"
                    }
                    if let status = newDict["status"] {
                        title += "\nStatus: \(status)"
                    }
                    title += "\nMedia ID: \(mediaID)"
                    
                    if let mediaList = Globals.shared.media.all?.mediaList?.list {
                        if mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                            let mediaItems = mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                                return transcript.mediaID == mediaID
                            })
                            
                            return mediaItems.count == 1
                        }).count == 1 {
                            title += "\nLocal"
                        } else {
                            
                        }
                    }
                    
                    newDict["title"] = title
                } else {
                    
                }
                
                if dict[category] == nil {
                    dict[category] = [newDict]
                } else {
                    dict[category]?.append(newDict)
                }
            } else {
                print("Unable to add: \(mediaItem)")
            }
        }
        
        if let sort = sort {
            let keys = Array(dict.keys)
            
            for key in keys {
                dict[key] = dict[key]?.sorted(by: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                    return sort(lhs,rhs)
                })
            }
        }
        
        if dict.count > 0 {
            self.dict = dict
        } else {
            return nil
        }
    }
}
