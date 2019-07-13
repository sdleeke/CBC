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
                if let name = dict["name"] as? String {
                    self.groups[name] = Group(dict)
                }
            })
        }
        
//        json.load(urlString: Constants.JSON.URL.GROUPS, key:Constants.JSON.ARRAY_KEY.GROUP_ENTRIES, filename: Constants.JSON.FILENAME.GROUPS)?.forEach({ (dict:[String : Any]) in
//            if let name = dict["name"] as? String {
//                groups[name] = Group(dict)
//            }
//        })
        
        json.load(urlString: Constants.JSON.URL.TEACHERS, filename: Constants.JSON.FILENAME.TEACHERS) { (json:[String:Any]?) in
            guard let json = json?[Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES] as? [[String:Any]] else {
                return
            }

            json.forEach({ (dict:[String : Any]) in
                if let name = dict["name"] as? String {
                    self.teachers[name] = Teacher(dict)
                }
            })
        }
        
//        json.load(urlString: Constants.JSON.URL.TEACHERS, key:Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES, filename: Constants.JSON.FILENAME.TEACHERS)?.forEach({ (dict:[String : Any]) in
//            if let name = dict["name"] as? String {
//                teachers[name] = Teacher(dict)
//            }
//        })
        
        json.load(urlString: Constants.JSON.URL.CATEGORIES, filename: Constants.JSON.FILENAME.CATEGORIES) { (json:[String:Any]?) in
            guard let json = json?[Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES] as? [[String:Any]] else {
                return
            }
            
            json.forEach({ (dict:[String : Any]) in
                var key = ""
                
                if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_OLD {
                    key = "category_name"
                }
                
                if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_NEW {
                    key = "name"
                }
                
                if let name = dict[key] as? String {
                    self.categories[name] = Category(dict)
                }
            })
        }
        
//        json.load(urlString: Constants.JSON.URL.CATEGORIES, key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES, filename: Constants.JSON.FILENAME.CATEGORIES)?.forEach({ (dict:[String : Any]) in
//            var key = ""
//
//            if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_OLD {
//                key = "category_name"
//            }
//
//            if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_NEW {
//                key = "name"
//            }
//
//            if let name = dict[key] as? String {
//                categories[name] = Category(dict)
//            }
//        })
        
        json.load(urlString: json.url, filename: json.filename) { (json:[String : Any]?) in
            if let mediaItemDicts = json?[Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES] as? [[String:Any]] {
                self.metadata = json?[Constants.JSON.ARRAY_KEY.META_DATA] as? [String:Any]
                
                self.repository.list = mediaItemDicts.filter({ (dict:[String : Any]) -> Bool in
                    return (dict["published"] as? Bool) != false
                }).map({ (mediaItemDict:[String : Any]) -> MediaItem in
                    let mediaItem = MediaItem(storage: mediaItemDict)
                    
                    // Just in case it was...and something bad happened and the tag was left
                    mediaItem.removeTag(Constants.Strings.Downloading)

                    return mediaItem
                })
                
                self.sortingAndGrouping()
                
                if let playing = self.category.playing {
                    Globals.shared.mediaPlayer.mediaItem = self.repository.index[playing]
                } else {
                    Globals.shared.mediaPlayer.mediaItem = nil
                }
            }
        }
        
//        if  let url = json.url,
//            let filename = json.filename,
//            let json = json.get(urlString: url, filename: filename) as? [String:Any],
//            let mediaItemDicts = json[Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES] as? [[String:Any]] {
//            metadata = json[Constants.JSON.ARRAY_KEY.META_DATA] as? [String:Any]
//            
//            repository.list = mediaItemDicts.filter({ (dict:[String : Any]) -> Bool in
//                return (dict["published"] as? Bool) != false
//            }).map({ (mediaItemDict:[String : Any]) -> MediaItem in
//                return MediaItem(storage: mediaItemDict)
//            })
//            
//            if let playing = category.playing {
//                Globals.shared.mediaPlayer.mediaItem = repository.index[playing]
//            } else {
//                Globals.shared.mediaPlayer.mediaItem = nil
//            }
//        } else {
//            repository.list = nil
//            print("FAILED TO LOAD")
//        }
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
                if let sortTag = tags.selected?.withoutPrefixes {
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
            
            if let showing = tags.showing {
                switch showing {
                case Constants.TAGGED:
                    if let selected = tags.selected {
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
                if let context = active?.context, let search = search.searches?[context] {
                    active = search
                }
            }
            
            return active
        }
    }
}

