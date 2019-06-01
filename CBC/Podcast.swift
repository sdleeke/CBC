//
//  Podcast.swift
//  CBC
//
//  Created by Steve Leeke on 5/31/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import FeedKit

/**
 
 Class for podcasts w/ dictionary storage.
 
 */

class Podcast : NSObject, StorageProtocol
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
    
    required init?(_ storage:[String:Any]?)
    {
        guard let storage = storage else {
            return nil
        }
        
        self.storage = storage
    }
    
    deinit {
        debug(self)
    }
    
    var url:URL?
    
    init(url:URL?)
    {
        self.url = url
    }
    
    func load(completion:((RSSFeed?)->())? = nil)
    {
        guard let url = url else {
            return
        }
        let parser = FeedParser(URL: url)
        
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            completion?(result.rssFeed)
        }
    }
}

