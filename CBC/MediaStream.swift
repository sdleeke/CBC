//
//  MediaStream.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Handles live events 
 
 */

class MediaStream
{
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MediaStream" // Assumes there is only one globally
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    var liveEvents:[String:Any]?
    {
        get {
            return Constants.URL.LIVE_EVENTS.url?.data?.json as? [String:Any]
        }
    }
    
    func loadLive(completion:(()->(Void))? = nil)
    {
        operationQueue.addOperation { [weak self] in
            // To get a visible amount of delay
            Thread.sleep(forTimeInterval: 1.0)
            
            var key = ""
            
            if Constants.URL.LIVE_EVENTS == Constants.URL.LIVE_EVENTS_OLD {
                key = "streamEntries"
            }
            
            if Constants.URL.LIVE_EVENTS == Constants.URL.LIVE_EVENTS_NEW {
                key = "mediaEntries"
            }

            self?.streamEntries = self?.liveEvents?[key] as? [[String:Any]]
            
            Thread.onMain {
                completion?()
            }
        }
    }
    
    // Make thread safe?
    var streamEntries:[[String:Any]]?
    
    // Make thread safe?
    var streamStrings:[String]?
    {
        get {
            return streamEntries?.filter({ (dict:[String : Any]) -> Bool in
                return StreamEntry(dict)?.startDate > Date()
            }).compactMap({ (dict:[String : Any]) -> String? in
                return StreamEntry(dict)?.text
            })
        }
    }
    
    // Make thread safe?
    var streamStringIndex:[String:[String]]?
    {
        get {
            var streamStringIndex = [String:[String]]()
            
            let now = Date().addHours(0) // for ease of testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start, let text = streamEntry?.text {
                        // All streaming to start 5 minutes before the scheduled start time
                        if ((now.timeIntervalSince1970 + 5*60) >= Double(start)) && (now <= streamEntry?.endDate) {
                            if streamStringIndex[Constants.Strings.Playing] == nil {
                                streamStringIndex[Constants.Strings.Playing] = [String]()
                            }
                            streamStringIndex[Constants.Strings.Playing]?.append(text)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamStringIndex[Constants.Strings.Upcoming] == nil {
                                    streamStringIndex[Constants.Strings.Upcoming] = [String]()
                                }
                                streamStringIndex[Constants.Strings.Upcoming]?.append(text)
                            } else {
                                
                            }
                        }
                    } else {
                        
                    }
                }
                
                if streamStringIndex[Constants.Strings.Playing]?.count == 0 {
                    streamStringIndex[Constants.Strings.Playing] = nil
                }
                
                return streamStringIndex.count > 0 ? streamStringIndex : nil
            } else {
                return nil
            }
        }
    }
    
    // Make thread safe?
    var streamEntryIndex:[String:[[String:Any]]]?
    {
        get {
            var streamEntryIndex = [String:[[String:Any]]]()
            
            let now = Date().addHours(0) // for ease of testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start {
                        // All streaming to start 5 minutes before the scheduled start time
                        if ((now.timeIntervalSince1970 + 5*60) >= Double(start)) && (now <= streamEntry?.endDate) {
                            if streamEntryIndex[Constants.Strings.Playing] == nil {
                                streamEntryIndex[Constants.Strings.Playing] = [[String:Any]]()
                            }
                            streamEntryIndex[Constants.Strings.Playing]?.append(event)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamEntryIndex[Constants.Strings.Upcoming] == nil {
                                    streamEntryIndex[Constants.Strings.Upcoming] = [[String:Any]]()
                                }
                                streamEntryIndex[Constants.Strings.Upcoming]?.append(event)
                            }
                        }
                    }
                }
                
                if streamEntryIndex[Constants.Strings.Playing]?.count == 0 {
                    streamEntryIndex[Constants.Strings.Playing] = nil
                }
                
                return streamEntryIndex.count > 0 ? streamEntryIndex : nil
            } else {
                return nil
            }
        }
    }
    
    // Make thread safe?
    var streamSorted:[[String:Any]]?
    {
        get {
            return streamEntries?.sorted(by: { (firstDict: [String : Any], secondDict: [String : Any]) -> Bool in
                return StreamEntry(firstDict)?.startDate <= StreamEntry(secondDict)?.startDate
            })
        }
    }
    
    // Make thread safe?
    var streamCategories:[String:[[String:Any]]]?
    {
        get {
            var streamCategories = [String:[[String:Any]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let name = StreamEntry(streamEntry)?.name {
                        if streamCategories[name] == nil {
                            streamCategories[name] = [[String:Any]]()
                        }
                        streamCategories[name]?.append(streamEntry)
                    }
                }
                
                return streamCategories.count > 0 ? streamCategories : nil
            } else {
                return nil
            }
        }
    }
    
    // Make thread safe?
    // Year // Month // Day // Event
    var streamSchedule:[String:[String:[String:[[String:Any]]]]]?
    {
        get {
            var streamSchedule = [String:[String:[String:[[String:Any]]]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let startDate = StreamEntry(streamEntry)?.startDate {
                        if streamSchedule[startDate.year] == nil {
                            streamSchedule[startDate.year] = [String:[String:[[String:Any]]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month] == nil {
                            streamSchedule[startDate.year]?[startDate.month] = [String:[[String:Any]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month]?[startDate.day] == nil {
                            streamSchedule[startDate.year]?[startDate.month]?[startDate.day] = [[String:Any]]()
                        }
                        streamSchedule[startDate.year]?[startDate.month]?[startDate.day]?.append(streamEntry)
                    }
                }
                
                return streamSchedule.count > 0 ? streamSchedule : nil
            } else {
                return nil
            }
        }
    }
}
