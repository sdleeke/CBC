//
//  CallBacks.swift
//  CBC
//
//  Created by Steve Leeke on 4/16/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Flexible way to handle callbacks from a long-running data structure process to a view controller that is
 displaying a representation of it.
 
 Each view controller must register to begin receiving call backs and unregister when it no longer wants them.
 Registration includes a dictionary of named closures that are called by the long-running data structure process.
 
 Right now the names are "start", "update", and "complete" and it is assumed the view controller and the data structure
 both know that.  There is no way for a view controller to get a list of the names the data structure uses or a state machine
 associated with them.  The names above imply a simple state machine that:
 
 starts in "start" then moves into "update" and then returns to "update repeatedly until it is "complete"
 
 I'm not sure how we would define a state machine in the data structure and communicate the states to the view controller in
 a way that the view controller would know what to do with them.
 
 Previously we used fixed methods: start/update/complete, meaning we could only have three and it was those three.  This is more
 flexible, should/can we define a protocol so both the data structure and view controller (delegate) can be conformed to it?
 
 */

class CallBacks
{
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    deinit {
        debug(self)
    }

                            //VCID  //State // Closure
    private var callbacks = [String:[String:(()->())]]()
    
    func register(_ id:String,_ callBacks:[String:(()->())]?)
    {
        queue.sync {
            callbacks[id] = callBacks
        }
    }
    
    func unregister(_ id:String)
    {
        queue.sync {
            callbacks[id] = nil
        }
    }
    
    func execute(_ name:String)
    {
        queue.sync {
            callbacks.values.forEach({ (dict:[String : (() -> ())]) in
                dict[name]?()
            })
        }
    }
}
