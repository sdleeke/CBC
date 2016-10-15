//
//  Reachability.swift
//  TPS
//
//  Created by Steve Leeke on 9/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation

open class Reachability {
    
    class func isConnectedToNetwork()->Bool
    {
        
        var Status:Bool = false
        let url = URL(string: Constants.REACHABILITY_TEST_URL)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "HEAD"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: URLResponse?
        
        let _ = (try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)) as Data?
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        
        return Status
    }
}
