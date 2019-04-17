//
//  CallBacks.swift
//  CBC
//
//  Created by Steve Leeke on 4/16/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

struct CallBack
{
    var start : (()->())?
    var update : (()->())?
    var complete : (()->())?
}

class CallBacks
{
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    deinit {
        debug(self)
    }

    private var callbacks = [String:CallBack]()
//    private var callbacks : [String:CallBack]!
//    {
//        get {
//            return queue.sync {
//                return _callbacks
//            }
//        }
//        set {
//            queue.sync {
//                _callbacks = newValue
//            }
//        }
//    }
    
    func register(id:String,callBack:CallBack)
    {
        queue.sync {
            callbacks[id] = callBack
        }
    }
    
    func unregister(id:String)
    {
        queue.sync {
            callbacks[id] = nil
        }
    }
    
    func start()
    {
        // Crashes without this and build() comes before register()
        // Why didn't queue.sync protect against that?
        guard callbacks.count > 0 else {
            return
        }
        
        queue.sync {
            callbacks.values.forEach { (callBack:CallBack) in
                callBack.start?()
            }
        }
    }
    
    func update()
    {
        guard callbacks.count > 0 else {
            return
        }
        
        queue.sync {
            callbacks.values.forEach { (callBack:CallBack) in
                callBack.update?()
            }
        }
    }
    
    func complete()
    {
        guard callbacks.count > 0 else {
            return
        }
        
        queue.sync {
            callbacks.values.forEach { (callBack:CallBack) in
                callBack.complete?()
            }
        }
    }
}
