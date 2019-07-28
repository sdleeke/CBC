//
//  Media.swift
//  CBC
//
//  Created by Steve Leeke on 2/11/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

// Tried to use a struct and bad things happend.  Copy on write problems?  Simultaneous access problems?  Are those two related?  Could be.  Don't know.
// Problems went away when I switched to class

/**

 Handles everything related to media except the AVPlayer.

 Properties:
    - json - media json
    - category, track selected category and master/detail media items selected for that category
    - stream - live events
    - teachers - speakers
    - groups - sub-categories
    - repository - a list of all media
    - search - everything about searches
    - metaData - from new API: tells where media is stored
    - needs - whether the media list needs sorting or grouping
    - all - all mediaItems for the selected catgory
    - tagged - mediaItems that have the selected tag
             - stored by tag
    - tags - the selectd tag
    - toSearch - mediaItems to search in the given context
    - active - the current list of mediaItems to be displayed to the user
    - history
 */

class Media
{
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
        mediaQueue.cancelAllOperations()
    }
    
    @objc func freeMemory()
    {
        cache.clear()
    }
    
    init()
    {
        Thread.onMain { // [weak self] in
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Media:Operation" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    lazy var mediaQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Media:Media" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 3 // Media downloads at once.
        return operationQueue
    }()

    var json = JSON()
    
    func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
    {
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        guard mediaItem.hasMultipleParts, let multiPartSort = mediaItem.multiPartSort else {
            return [mediaItem]
        }
        
        return all?.groupSort?[GROUPING.TITLE,multiPartSort,SORTING.CHRONOLOGICAL]?.multiPartMediaItems(mediaItem) ?? repository.list?.multiPartMediaItems(mediaItem)
    }
    
    func load()
    {
        // load from storage if possible, from network if not.
        // if loading from storage is possible, then load from network in background
        // and swap when fully loaded and new json is saved.
        
        json.load(urlString: Constants.JSON.URL.GROUPS, filename: Constants.JSON.FILENAME.GROUPS) { (json:[String:Any]?) in
            guard let json = json?[Constants.JSON.ARRAY_KEY.GROUP_ENTRIES] as? [[String:Any]] else {
                return
            }
            
            json.forEach({ (dict:[String : Any]) in
                if let name = dict["name"] as? String, !name.isEmpty {
                    self.groups[name] = Group(dict)
                }
            })
        }
        
        json.load(urlString: Constants.JSON.URL.TEACHERS, filename: Constants.JSON.FILENAME.TEACHERS) { (json:[String:Any]?) in
            guard let json = json?[Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES] as? [[String:Any]] else {
                return
            }

            json.forEach({ (dict:[String : Any]) in
                if let name = dict["name"] as? String, !name.isEmpty {
                    self.teachers[name] = Teacher(dict)
                }
            })
        }
        
        json.load(urlString: Constants.JSON.URL.CATEGORIES, filename: Constants.JSON.FILENAME.CATEGORIES) { (json:[String:Any]?) in
            guard let json = json?[Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES] as? [[String:Any]] else {
                return
            }
            
            json.forEach({ (dict:[String : Any]) in
                var key = String()
                
                if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_OLD {
                    key = "category_name"
                }
                
                if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_NEW {
                    key = "name"
                }
                
                if let name = dict[key] as? String, !name.isEmpty {
                    self.categories[name] = Category(dict)
                }
            })
        }
        
        json.load(urlString: json.url, filename: json.filename) { (json:[String : Any]?) in
            guard let mediaItemDicts = json?[Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES] as? [[String:Any]] else {
                return
            }
            
            self.metadata = json?[Constants.JSON.ARRAY_KEY.META_DATA] as? [String:Any]
            
            self.repository.list = mediaItemDicts.compactMap({ (dict:[String : Any]) -> MediaItem? in
                guard (dict["published"] as? Bool) != false else {
                    return nil
                }

                guard dict["error"] == nil else {
                    return nil
                }
                
                let mediaItem = MediaItem(storage: dict)
                
                // Just in case it was...and something bad happened and the tag was left
                mediaItem?.removeTag(Constants.Strings.Downloading)

                return mediaItem
            })
            
            self.sortingAndGrouping()
            
            if let playing = self.category.playing, !playing.isEmpty {
                Globals.shared.mediaPlayer.mediaItem = self.repository.index[playing]
            } else {
                Globals.shared.mediaPlayer.mediaItem = nil
            }
        }
    }
    
    func sortingAndGrouping()
    {
        if category.selected == Constants.Strings.All {
            all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: repository.list)
        } else {
            all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: repository.list?.filter({ (mediaItem) -> Bool in
                mediaItem.category == category.selected
            }))
        }
        
        if tags.showing == Constants.TAGGED, let tag = category.tag, tags.tagged[tag] == nil {
            if all == nil {
                //This is filtering, i.e. searching all mediaItems => s/b in background
                tags.tagged[tag] = MediaListGroupSort(mediaItems: repository.list?.filter({ (mediaItem) -> Bool in
                    return mediaItem.category == category.selected
                }).withTag(tag: tags.selected))
            } else {
                if let sortTag = tags.selected?.withoutPrefixes, !sortTag.isEmpty {
                    tags.tagged[tag] = MediaListGroupSort(mediaItems: all?.tagMediaItems?[sortTag])
                }
            }
        }
    }
    
    lazy var selected : Selected! = {
        return Selected(self)
    }()

    lazy var history : History! = {
        return History(self)
    }()
    
    var stream = MediaStream()
    
    var categories = ThreadSafeDN<Category>() // [String:String]?
    
    var teachers = ThreadSafeDN<Teacher>() // [String:String]?
    
    var groups = ThreadSafeDN<Group>() // [String:String]?
    
    var repository = MediaList()

    lazy var category:MediaCategory! = {
        return MediaCategory(self)
    }()
    
    lazy var search : Search! = {
        return Search(self)
    }()
    
    // Make thread safe?
    var metadata : [String:Any]?
    
    var url : String?
    {
        get {
            return metadata?["s3MediaUrl"] as? String
        }
    }
    
    var goto:String?
    
//    var need = MediaNeed()
    
    // Globals.shared.media.category.selected is the key
    // That way work can be saved when a category is changed.
    var cache = ThreadSafeDN<MediaListGroupSort>()
    
    //All mediaItems
    var all:MediaListGroupSort?
    {
        didSet {
            _ = all?.lexicon?.eligible
            _ = all?.scriptureIndex?.eligible
        }
    }
    
    lazy var tags:Tags! = {
        return Tags(media:self)
    }()
    
    var active:MediaListGroupSort?
    {
        get {
            var active:MediaListGroupSort?
            
            if let showing = tags.showing, !showing.isEmpty {
                switch showing {
                case Constants.TAGGED:
                    if let selected = tags.selected, !selected.isEmpty {
                        active = tags.tagged[selected]
                    }
                    break
                    
                case Constants.ALL:
                    active = all
                    break
                    
                default:
                    break
                }
            }
            
            if search.isActive {
                if let context = active?.context, !context.isEmpty, let search = search.searches?[context] {
                    // active MUST NOT BE NIL!
                    active = search
                }
            }
            
            return active
        }
    }
}

