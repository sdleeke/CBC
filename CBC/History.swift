//
//  History.swift
//  CBC
//
//  Created by Steve Leeke on 5/20/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

class History
{
    weak var media : Media?
    
    init(_ media:Media?)
    {
        self.media = media
    }
    
    var list = ThreadSafeArray<String>() // :[String]?
    
    // thread safe
    var relevant:[String]?
    {
        get {
            // This is a problem for grouping these.
            guard let index = media?.all?.mediaList?.index else {
                return nil
            }
            
            return list.reversed?.filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.SEPARATOR) {
                    let mediaItemID = String(string[range.upperBound...])
                    return index[mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    var relevantFirst : MediaItem?
    {
        get {
            if let first = relevant?.first {
                let components = first.components(separatedBy: Constants.SEPARATOR)
                
                if components.count == 2 {
                    let id = components[1]
                    
                    // This is a problem for grouping these.
                    return media?.repository.index[id]
                }
            }
            
            return nil
        }
    }
    
    // thread safe
    var relevantText:[String]?
    {
        get {
            guard let index = media?.all?.mediaList?.index else {
                return nil
            }
            
            return relevant?.map({ (string:String) -> String in
                if  let mediaCode = string.components(separatedBy: Constants.SEPARATOR).last, // let range = string.range(of: Constants.SEPARATOR),
                    let mediaItem = index[mediaCode], // String(string[range.upperBound...])
                    let text = mediaItem.text {
                    return text
                }
                
                return ("ERROR")
            })
        }
    }
    
    func add(_ mediaItem:MediaItem? = nil)
    {
        guard let mediaItem = mediaItem else {
            print("mediaItem NIL!")
            return
        }
        
        guard mediaItem.mediaCode != nil else {
            print("mediaItem ID NIL!")
            return
        }
        
        let entry = "\(Date())" + Constants.SEPARATOR + mediaItem.mediaCode
        
        list.append(entry)
        
        let defaults = UserDefaults.standard
        defaults.set(list.copy, forKey: Constants.SETTINGS.HISTORY)
        defaults.synchronize()
    }
}
