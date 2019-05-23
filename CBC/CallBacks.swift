//
//  CallBacks.swift
//  CBC
//
//  Created by Steve Leeke on 4/16/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

//struct CallBack
//{
//    var name : String?
//    var function : (()->())?
////    var start : (()->())?
////    var update : (()->())?
////    var complete : (()->())?
//}

class CallBacks
{
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    deinit {
        debug(self)
    }

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
    
//    func start()
//    {
//        queue.sync {
//            guard callbacks.count > 0 else {
//                return
//            }
//
//            callbacks.values.forEach { (callBack:CallBack) in
//                callBack.start?()
//            }
//        }
//    }
//
//    func update()
//    {
//        guard callbacks.count > 0 else {
//            return
//        }
//
//        queue.sync {
//            callbacks.values.forEach { (callBack:CallBack) in
//                callBack.update?()
//            }
//        }
//    }
//
//    func complete()
//    {
//        guard callbacks.count > 0 else {
//            return
//        }
//
//        queue.sync {
//            callbacks.values.forEach { (callBack:CallBack) in
//                callBack.complete?()
//            }
//        }
//    }
}
