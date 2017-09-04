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
struct StringTree {
    weak var lexicon:Lexicon!
    
    init(lexicon:Lexicon?)
    {
        self.lexicon = lexicon
    }
    
    lazy var root:StringNode! = {
        return StringNode(nil)
    }()
    
    var building = false
    var completed = false
    
    mutating func build()
    {
        guard !building else {
            return
        }
        
        building = true

        self.root = StringNode(nil)
        self.root.addStrings(self.lexicon.tokens)
        
        self.building = false
        self.completed = true
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.lexicon)

//        DispatchQueue.global(qos: .background).async {
//            self.root = StringNode(nil)
//            self.root.addStrings(self.lexicon.tokens)
//            
//            self.building = false
//            self.completed = true
//
//            globals.queue.async(execute: { () -> Void in
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.lexicon)
//            })
//        }
    }
}

