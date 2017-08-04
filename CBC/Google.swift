//
//  Google.swift
//  CBC
//
//  Created by Steve Leeke on 7/28/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class Google {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// Google Cloud API for Storage and Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem!
    
    init(mediaItem:MediaItem?)
    {
        self.mediaItem = mediaItem
    }
    
//    let STORAGE_ID = "00b4903a97f8908436fec45a5cf378fa21209222321fe100000b1d162f1715cc"
    
    //    let PROJECT_ID = "sacred-brace-167913"
    
    let API_KEY = "AIzaSyCDbtnE6dZHB8R6FJfj8qKthqY1XnT-97s"
    
    let SAMPLE_RATE = 16000
    
    var uploading = false
    var upload:[String:Any]?
    
    func uploadAudio()
    {
        guard !uploading && (upload == nil) else {
            return
        }
        
        uploading = true
        
        var service = "https://www.googleapis.com/upload/storage/v1/b/cbcmedia/o?uploadType=media" // v1/b/
        
        service = service + "&name=\(mediaItem.id!)"
        
        service = service + "&key=\(API_KEY)"
        
        //        service = service + "&project=\(PROJECT_ID)"
        
        if let url = mediaItem.audioURL, let audioData = try? Data(contentsOf: url) {
//            let data = audioData.base64EncodedString()
            var request = URLRequest(url: URL(string:service)!)
            
            //            request.addValue("Bearer \(API_KEY)", forHTTPHeaderField: "Authorization")
            
//            let audioRequest:[String:Any] = ["content":data]
            
            //            let requestDictionary = ["audio":audioRequest]
            
            //            let requestData = try? JSONSerialization.data(withJSONObject: audioRequest, options: JSONSerialization.WritingOptions(rawValue: 0))
            
            //            request.addValue(Bundle.main.bundleIdentifier!, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
            
            request.addValue("audio/mpeg", forHTTPHeaderField: "Content-Type")
            request.addValue("\(audioData.count)", forHTTPHeaderField: "Content-Length")
            
            request.httpMethod = "POST"
            
            let task = URLSession.shared.uploadTask(with: request, from: audioData, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
                var errorOccured = false
                
                if let error = error {
                    print("post error: ",error.localizedDescription)
                    errorOccured = true
                }
                
                if let response = response {
                    print("post response: ",response.description)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("post HTTP response: ",httpResponse.description)
                        print("post HTTP response: ",httpResponse.allHeaderFields)
                        print("post HTTP response: ",httpResponse.statusCode)
                        print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                        
                        if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                            errorOccured = true
                        }
                    }
                } else {
                    errorOccured = true
                }
                
                var json : [String:Any]?
                
                if let data = data {
                    let string = String.init(data: data, encoding: String.Encoding.utf8)
                    print(string as Any)
                    
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        print(json as Any)
                        
                        if let errors = json?["errors"] {
                            print(errors)
                            errorOccured = true
                        }
                    } catch let error as NSError {
                        // JSONSerialization failed
                        print("JSONSerialization error: ",error.localizedDescription)
                        
                    }
                } else {
                    // no data
                    
                }
                
                if errorOccured {

                } else {
                    self.uploading = false
                    self.upload = json
                    self.recognizeAudio()
                }

//                if data != nil {
//                    let string = String.init(data: data!, encoding: String.Encoding.utf8)
//                    //                    print(string) // object name
//                    
//                    let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any]
//                    print(json)
//                    
//                    if json?["error"] == nil {
//                    }
//                }
            })
            
            task.resume()
        } else {
            uploading = false
        }
    }
    
    var recognizing = false
    var recognized:[String:Any]?
    
    func recognizeAudio()
    {
        //        guard upload != nil else {
        //            return
        //        }
        
        recognizing = true
        
        var service = "https://speech.googleapis.com/v1/speech:longrunningrecognize"
        
        service = service + "?key="
        service = service + API_KEY
        
        let configRequest:[String:Any] = [  "encoding":"LINEAR16",
                                            "sampleRateHertz":SAMPLE_RATE,
                                            "languageCode":"en-US",
                                            "maxAlternatives":30]
        
        let link = "gs://cbcmedia/\(mediaItem.id!)" // upload?["selfLink"] as? String
        
        let audioRequest:[String:Any] = ["uri":link]
        
        var request = URLRequest(url: URL(string:service)!)
        
        // if your API key has a bundle ID restriction, specify the bundle ID like this:
        
        let requestDictionary = ["config":configRequest,"audio":audioRequest]
        let requestData = try? JSONSerialization.data(withJSONObject: requestDictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
        
        request.addValue(Bundle.main.bundleIdentifier!, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data {
                let string = String.init(data: data, encoding: String.Encoding.utf8)
                print(string as Any)
                
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    print(json as Any)
                    
                    if let errors = json?["errors"] {
                        print(errors)
                        errorOccured = true
                    }
                } catch let error as NSError {
                    // JSONSerialization failed
                    print("JSONSerialization error: ",error.localizedDescription)
                    
                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                
            } else {
                self.recognized = json
                DispatchQueue.main.async(execute: { () -> Void in
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(Google.getTranscript), userInfo: nil, repeats: true)
                })
            }

//            if data != nil {
//                let string = String.init(data: data!, encoding: String.Encoding.utf8)
//                //                print(string)
//                
//                let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any]
//                print(json)
//                
//                if json?["error"] == nil {
//                    self.recognized = json
//                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(Google.getTranscript), userInfo: nil, repeats: true)
//                    })
//                }
//            }
        })
        
        task.resume()
    }
    
    var resultsTimer:Timer?
    var results:[String:Any]?

    @objc func getTranscript()
    {
        guard upload != nil else {
            DispatchQueue.global(qos: .background).async {
                self.uploadAudio()
            }
            return
        }
        
        var service = "https://speech.googleapis.com/v1/operations/"
        
        let operation = recognized?["name"] as? String
        
        service = service + operation!
        
        service = service + "?key="
        service = service + API_KEY
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("get error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("get response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("get HTTP response: ",httpResponse.description)
                    print("get HTTP response: ",httpResponse.allHeaderFields)
                    print("get HTTP response: ",httpResponse.statusCode)
                    print("get HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data {
                let string = String.init(data: data, encoding: String.Encoding.utf8)
                print(string as Any)
                
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                    print(json as Any)
                    
                    if let errors = json?["errors"] {
                        print(errors)
                        errorOccured = true
                    }
                } catch let error as NSError {
                    // JSONSerialization failed
                    print("JSONSerialization error: ",error.localizedDescription)
                    
                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                
            } else {
                if let done = json?["done"] as? Bool {
                    if done {
                        self.results = json
                        
                        self.resultsTimer?.invalidate()
                        self.recognizing = false
                    }
                }
            }

//            let string = String.init(data: data!, encoding: String.Encoding.utf8)
//            //            print(string)
//            
//            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any]
//            print(json)
//            
//            if json?["error"] == nil {
//                
//            }
            
//            if let done = json?["done"] as? Bool {
//                if done {
//                    self.results = json
//                    
//                    self.resultsTimer?.invalidate()
//                    self.recognizing = false
//                }
//            }
        })
        
        task.resume()
    }
}
