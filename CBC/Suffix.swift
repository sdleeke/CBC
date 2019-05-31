//
//  Suffix.swift
//  CBC
//
//  Created by Steve Leeke on 5/23/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation
import FeedKit

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
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Category : Suffix
{
    lazy var podcast : Podcast? = {
        guard let id = id else {
            return nil
        }

        return Podcast(url: "https://countrysidebible.org/mediafeed.php?return=podcast&categoryID=\(id)".url)
    }()
}

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

/**
 
 Abstract dictionary backed class with id, name, suffix
 
 */

class Group : Suffix
{
    
}

