//
//  StringTree.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class StringTree {
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
    
    func build()
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

