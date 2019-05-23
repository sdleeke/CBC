//
//  CheckIn.swift
//  CBC
//
//  Created by Steve Leeke on 5/21/19.
//  Copyright © 2019 Steve Leeke. All rights reserved.
//

import Foundation

/**
 
 Allows tracking success/failure of network calls.
 
 */

class CheckIn
{
    deinit {
        debug(self)
    }
    
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    func reset()
    {
        total = 0
        success = 0
        failure = 0
    }
    
    var total = 0
    
    var _success = 0
    var success : Int
    {
        get {
            return queue.sync {
                return _success
            }
        }
        set {
            queue.sync {
                _success = newValue
            }
        }
    }
    
    var _failure = 0
    var failure : Int
    {
        get {
            return queue.sync {
                return _failure
            }
        }
        set {
            queue.sync {
                _failure = newValue
            }
        }
    }
}

