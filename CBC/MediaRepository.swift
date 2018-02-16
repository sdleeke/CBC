//
//  MediaRepository.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaRepository {
    weak var globals:Globals!
    
    var list:[MediaItem]? { //Not in any specific order
        willSet {
            
        }
        didSet {
            guard let list = list else {
                return
            }
            
            index = nil
            classes = nil
            events = nil
            
            for mediaItem in list {
                if let id = mediaItem.id {
                    if index == nil {
                        index = [String:MediaItem]()
                    }
                    if index?[id] == nil {
                        index?[id] = mediaItem
                    } else {
                        print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
                
                if mediaItem.hasClassName, let className = mediaItem.className {
                    if classes == nil {
                        classes = [className]
                    } else {
                        classes?.append(className)
                    }
                }
                
                if mediaItem.hasEventName, let eventName = mediaItem.eventName {
                    if events == nil {
                        events = [eventName]
                    } else {
                        events?.append(eventName)
                    }
                }
            }
            
            globals.groupings = Constants.groupings
            globals.groupingTitles = Constants.GroupingTitles
            
            if classes?.count > 0 {
                globals.groupings.append(GROUPING.CLASS)
                globals.groupingTitles.append(Grouping.Class)
            }
            
            if events?.count > 0 {
                globals.groupings.append(GROUPING.EVENT)
                globals.groupingTitles.append(Grouping.Event)
            }
            
            if let grouping = globals.grouping, !globals.groupings.contains(grouping) {
                globals.grouping = GROUPING.YEAR
            }
        }
    }
    
    var index:[String:MediaItem]?
    var classes:[String]?
    var events:[String]?
}

