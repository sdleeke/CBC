//
//  CancelableOperation.swift
//  CBC
//
//  Created by Steve Leeke on 10/10/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**

 An operation that passes a function to the main block that evaluates whether it has been cancelled.
 
 An operation can be cancelled but it won't actually stop until the block in main exits and if it is long-running it could go on for a long time.
 
 Properties:
     - block: the function that takes the boolean function to determine whether the block should end prematurely
     - tag: a string to label the operation
 
 */

class CancelableOperation : Operation
{
    var block : (((()->Bool)?)->())?
    
    var tag : String?
    
    override var description: String
    {
        get {
            return tag ?? ""
        }
    }
    
    init(tag:String? = nil,block:(((()->Bool)?)->())?)
    {
        super.init()
        
        self.tag = tag
        self.block = block
    }
    
    deinit {
        debug(self)
    }
    
    override func cancel()
    {
        // Why do we override this when all we do is call the super's method?
        super.cancel()
    }
    
    override func main()
    {
        block?({return self.isCancelled})
    }
}
