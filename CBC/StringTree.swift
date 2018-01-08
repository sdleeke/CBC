//
//  StringTree.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

// Crucial for Word Picker that this be a struct so that it is passed by value, not reference; i.e. a copy is made.
// That means all of the stringNodes are frozen when it is passed by value so that Expanded Views are always complete as of that moment and
// are not affected by changes to the tree while the expanded view is being prepared.

class StringTree
{
    lazy var root:StringNode! = {
        return StringNode(nil)
    }()
    
    var incremental = false
    var building = false
    var completed = false
    
    convenience init(incremental: Bool)
    {
        self.init()
        self.incremental = incremental
    }
    
    deinit {
        
    }
    
    func build(strings:[String]?)
    {
        guard !building else {
            return
        }
        
        guard let strings = strings?.sorted(), strings.count > 0 else {
            return
        }
        
        building = true

        if incremental {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.root = StringNode(nil)

                var date : Date?
                
                for string in strings {
                    self?.root.addString(string)
                    
                    if (date == nil) || (date?.timeIntervalSinceNow <= -1) { // Any more frequent and the UI becomes unresponsive.
//                        print(date)
                        
                        globals.queue.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                        })
                        
                        date = Date()
                    }
                }
                
                self?.building = false
                self?.completed = true
                
                globals.queue.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                })
            }
        } else {
            self.root = StringNode(nil)
            self.root.addStrings(strings)
            
            self.building = false
            self.completed = true
        }
    }
}

