//
//  VoiceBase.swift
//  CBC
//
//  Created by Steve Leeke on 6/27/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

extension VoiceBase // Class Methods
{
    static func url(mediaID:String?,path:String?) -> String
    {
        return "https://apis.voicebase.com/v2-beta/media" + (mediaID != nil ? "/"+mediaID! : "") + (path != nil ? "/"+path! : "")
    }
    
    static func html(_ json:[String:Any]?) -> String?
    {
        guard json != nil else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if let media = json?["media"] as? [String:Any] {
            if let mediaID = media["mediaId"] as? String {
                htmlString = htmlString + "MediaID: \(mediaID)\n"
            }
            
            if let status = media["status"] as? String {
                htmlString = htmlString + "Status: \(status)\n"
            }
            
            //                                            if let tasks = media["tasks"] as? [String:Any] {
            //                                                htmlString = htmlString + "Tasks: \(tasks.count)\n"
            //                                            }
            
            if let dateCreated = media["dateCreated"] as? String {
                htmlString = htmlString + "Date Created: \(dateCreated)\n"
            }
            
            if let job = media["job"] as? [String:Any] {
                htmlString = htmlString + "\nJob\n"
                
                if let jobProgress = job["progress"] as? [String:Any] {
                    if let jobStatus = jobProgress["status"] as? String {
                        htmlString = htmlString + "Job Status: \(jobStatus)\n"
                    }
                    if let jobTasks = jobProgress["tasks"] as? [String:Any] {
                        htmlString = htmlString + "Job Tasks: \(jobTasks.count)\n"
                        
                        var stats = [String:Int]()
                        
                        for task in jobTasks.keys {
                            if let status = (jobTasks[task] as? [String:Any])?["status"] as? String {
                                if stats[status] == nil {
                                    stats[status] = 1
                                } else {
                                    stats[status] = stats[status]! + 1
                                }
                            }
                        }
                        
                        for key in stats.keys {
                            htmlString = htmlString + "\(key): \(stats[key]!)\n"
                        }
                    }
                }
            }
            
            if let metadata = media["metadata"] as? [String:Any] {
                htmlString = htmlString + "\nMetadata\n"
                
                if let length = metadata["length"] as? [String:Any] {
                    if let length = length["milliseconds"] as? Int, let hms = secondsToHMS(seconds: "\(Double(length) / 1000.0)") {
                        htmlString = htmlString + "Length: \(hms)\n"
                    }
                }
                
                if let metadataTitle = metadata["title"] as? String {
                    htmlString = htmlString + "Title: \(metadataTitle)\n"
                }
                
                if let device = metadata["device"] as? [String:String] {
                    htmlString = htmlString + "\nDevice Information:\n"
                    
                    if let model = device["model"] {
                        htmlString = htmlString + "Model: \(model)\n"
                    }
                    
                    if let modelName = device["modelName"] {
                        htmlString = htmlString + "Name: \(modelName)\n"
                    }
                    
                    if let name = device["name"] {
                        htmlString = htmlString + "Name: \(name)\n"
                    }
                    
                    if let deviceUUID = device["UUID"] {
                        htmlString = htmlString + "UUID: \(deviceUUID)\n"
                    }
                }
                
                if let mediaItem = metadata["mediaItem"] as? [String:String] {
                    htmlString = htmlString + "\nMediaItem\n"
                    
                    if let category = mediaItem["category"] {
                        htmlString = htmlString + "Category: \(category)\n"
                    }
                    
                    if let id = mediaItem["id"] {
                        htmlString = htmlString + "id: \(id)\n"
                    }
                    
                    if let title = mediaItem["title"] {
                        htmlString = htmlString + "Title: \(title)\n"
                    }
                    
                    if let date = mediaItem["date"] {
                        htmlString = htmlString + "Date: \(date)\n"
                    }
                    
                    if let service = mediaItem["service"] {
                        htmlString = htmlString + "Service: \(service)\n"
                    }
                    
                    if let speaker = mediaItem["speaker"] {
                        htmlString = htmlString + "Speaker: \(speaker)\n"
                    }
                    
                    if let scripture = mediaItem["scripture"] {
                        htmlString = htmlString + "Scripture: \(scripture)\n"
                    }
                    
                    if let purpose = mediaItem["purpose"] {
                        htmlString = htmlString + "Purpose: \(purpose)\n"
                    }
                }
            }
            
            if let transcripts = media["transcripts"] as? [String:Any] {
                htmlString = htmlString + "\nTranscripts\n"
                
                if let latest = transcripts["latest"] as? [String:Any] {
                    htmlString = htmlString + "Latest\n"
                    
                    if let engine = latest["engine"] as? String {
                        htmlString = htmlString + "Engine: \(engine)\n"
                    }
                    
                    if let confidence = latest["confidence"] as? String {
                        htmlString = htmlString + "Confidence: \(confidence)\n"
                    }
                    
                    if let words = latest["words"] as? [[String:Any]] {
                        htmlString = htmlString + "Words: \(words.count)\n"
                    }
                }
            }
            
            if let keywords = media["keywords"] as? [String:Any] {
                htmlString = htmlString + "\nKeywords\n"
                
                if let keywordsLatest = keywords["latest"] as? [String:Any] {
                    if let words = keywordsLatest["words"] as? [[String:Any]] {
                        htmlString = htmlString + "Keywords: \(words.count)\n"
                    }
                }
            }
            
            if let topics = media["topics"] as? [String:Any] {
                htmlString = htmlString + "\nTopics\n"
                
                if let topicsLatest = topics["latest"] as? [String:Any] {
                    if let topics = topicsLatest["topics"] as? [[String:Any]] {
                        htmlString = htmlString + "Topics: \(topics.count)\n"
                    }
                }
            }
        }
        
        htmlString = htmlString.replacingOccurrences(of: "\n", with: "<br/>") + "</body></html>"

        return htmlString
    }
    
    func post(mediaID:String?,path:String?,parameters:[String:String]?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        guard let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let parameters = parameters else {
            return
        }
        
        //        guard let mediaItem = mediaItem else {
        //            return
        //        }
        
        //        guard let mediaID = mediaID else {
        //            return
        //        }
        
        let service = VoiceBase.url(mediaID:mediaID, path:path)
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "POST"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createBody(parameters: parameters,boundary: boundary)
        
        request.httpBody = body as Data
        request.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
        
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
                Thread.onMainThread() {
                    onError?(json)
                }
            } else {
                Thread.onMainThread() {
                    completion?(json)
                }
            }
        })
        
        task.resume()
    }

    static func get(accept:String?,mediaID:String?,path:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        guard globals.isVoiceBaseAvailable == nil || globals.isVoiceBaseAvailable! else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
//        guard let mediaID = mediaID else {
//            return
//        }

        let service = VoiceBase.url(mediaID:mediaID,path:path)
        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        if let accept = accept {
            request.addValue(accept, forHTTPHeaderField: "Accept")
        }
        
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
//                print(string as Any)

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string as Any]
                } else {
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                        print(json as Any)
                        
                        if let errors = json?["errors"] {
                            print(errors)
                            errorOccured = true
                        }
                    } catch let error as NSError {
                        // JSONSerialization failed
                        print("JSONSerialization error: ",error.localizedDescription)
                    }
                }
            } else {
                // no data
                errorOccured = true
            }
            
            if errorOccured {
                onError?(json)
                
                // Avoid blocking the main thread.
//                Thread.onMainThread() {
//                }
            } else {
                completion?(json)
                // Avoid blocking the main thread.
//                Thread.onMainThread() {
//                }
            }
        })
        
        task.resume()
    }
    
    static func metadata(mediaID: String?, completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept: nil, mediaID: mediaID, path: "metadata", completion: completion, onError: onError)
    }

    static func progress(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: "progress", completion: completion, onError: onError)
    }
    
    static func details(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: nil, completion: completion, onError: onError)
    }

    static func all(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: nil, path: nil, completion: completion, onError: onError)
    }
    
    static func delete(mediaID:String?)
    {
        print("VoiceBase.delete")

//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        guard let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        let service = VoiceBase.url(mediaID:mediaID,path:nil)
        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
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
                Thread.onMainThread() {
                    
                }
            } else {
                Thread.onMainThread() {
                    
                }
            }
        })
        
        task.resume()
    }
    
    @objc static func deleteAll()
    {
        print("VoiceBase.deleteAllMedia")
        
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
//        
//        guard globals.voiceBaseAvailable else {
//            return
//        }
        
        get(accept: nil, mediaID: nil, path: nil, completion: { (json:[String : Any]?) -> (Void) in
            if let mediaItems = json?["media"] as? [[String:Any]] {
                if mediaItems.count > 0 {
                    if mediaItems.count > 1 {
                        globals.alert(title: "Deleting \(mediaItems.count) Items from VoiceBase Media Library", message: nil)
                    } else {
                        globals.alert(title: "Deleting \(mediaItems.count) Item from VoiceBase Media Library", message: nil)
                    }
                    
                    for mediaItem in mediaItems {
                        delete(mediaID:mediaItem["mediaId"] as? String)
                    }
                } else {
                    globals.alert(title: "No Items to Delete in VoiceBase Media Library", message: nil)
                }
            } else {
                // No mediaItems
                globals.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
            }
        }, onError:  { (json:[String : Any]?) -> (Void) in
            globals.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
        })
    }
}

class VoiceBase {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// VoiceBase API for Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem?
    
    static let separator = "------------"
    
    var purpose:String?
    
    var transcriptPurpose:String
    {
        get {
            var transcriptPurpose : String!
            
            if let purpose = self.purpose {
                switch purpose {
                case Purpose.audio:
                    transcriptPurpose = Constants.Strings.Audio
                    break
                    
                case Purpose.video:
                    transcriptPurpose = Constants.Strings.Video
                    break
                    
                case Purpose.slides:
                    transcriptPurpose = Constants.Strings.Slides
                    break
                    
                case Purpose.notes:
                    transcriptPurpose = Constants.Strings.Transcript
                    break
                    
                default:
                    transcriptPurpose = "ERROR"
                    break
                }
            }
            
            return transcriptPurpose.lowercased()
        }
    }

    var metadata : String
    {
        guard let mediaItem = mediaItem else {
            return "ERROR no mediaItem"
        }
        
//        guard let purpose = purpose else {
//            return "ERROR no purpose"
//        }
        
        guard mediaItem.id != nil else {
            return "ERROR no mediaItem.id"
        }

        var mediaItemString = "{"
        
            mediaItemString = "\(mediaItemString)\"metadata\":{"
        
                if let text = mediaItem.text {
                    if let mediaID = mediaID {
                        mediaItemString = "\(mediaItemString)\"title\":\"\(text) (\(transcriptPurpose))\n\(mediaID)\","
                    } else {
                        mediaItemString = "\(mediaItemString)\"title\":\"\(text) (\(transcriptPurpose))\","
                    }
                }
        
                mediaItemString = "\(mediaItemString)\"mediaItem\":{"
                
                    if let category = mediaItem.category {
                        mediaItemString = "\(mediaItemString)\"category\":\"\(category)\","
                    }
                    
                    if let id = mediaItem.id {
                        mediaItemString = "\(mediaItemString)\"id\":\"\(id)\","
                    }
                    
                    if let date = mediaItem.date {
                        mediaItemString = "\(mediaItemString)\"date\":\"\(date)\","
                    }
                    
                    if let service = mediaItem.service {
                        mediaItemString = "\(mediaItemString)\"service\":\"\(service)\","
                    }
                    
                    if let title = mediaItem.title {
                        mediaItemString = "\(mediaItemString)\"title\":\"\(title)\","
                    }
            
                    if let text = mediaItem.text {
                        mediaItemString = "\(mediaItemString)\"text\":\"\(text) (\(transcriptPurpose))\","
                    }
                    
                    if let scripture = mediaItem.scripture {
                        mediaItemString = "\(mediaItemString)\"scripture\":\"\(scripture.description)\","
                    }
                    
                    if let speaker = mediaItem.speaker {
                        mediaItemString = "\(mediaItemString)\"speaker\":\"\(speaker)\","
                    }
                    
                    mediaItemString = "\(mediaItemString)\"purpose\":\"\(transcriptPurpose)\""
            
                mediaItemString = "\(mediaItemString)}"
            
                mediaItemString = "\(mediaItemString)\"device\":{"
                
                    mediaItemString = "\(mediaItemString)\"name\":\"\(UIDevice.current.deviceName)\","
                    
                    mediaItemString = "\(mediaItemString)\"model\":\"\(UIDevice.current.localizedModel)\","
                    
                    mediaItemString = "\(mediaItemString)\"modelName\":\"\(UIDevice.current.modelName)\","
                    
                    mediaItemString = "\(mediaItemString)\"UUID\":\"\(UIDevice.current.identifierForVendor!.description)\""
                    
                mediaItemString = "\(mediaItemString)}"
        
            mediaItemString = "\(mediaItemString)}"
        
        mediaItemString = "\(mediaItemString)}"
        
        return mediaItemString
    }
    
    var mediaID:String?
    {
        didSet {
            mediaItem?.mediaItemSettings?["mediaID."+purpose!] = mediaID
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var completed = false
    {
        didSet {
            mediaItem?.mediaItemSettings?["completed."+purpose!] = completed ? "YES" : "NO"

            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var transcribing = false
    
    var aligning = false
    {
        didSet {
            print("")
        }
    }
    
    var percentComplete:String?
    
    var uploadJSON:[String:Any]?
    
    var resultsTimer:Timer?
    
    var url:String? {
        switch purpose! {
        case Purpose.video:
            return mediaItem?.mp4
            
        case Purpose.audio:
            return mediaItem?.audio
            
        default:
            return nil
        }
    }
    
    var transcript:String?
    {
        get {
            guard (_transcript == nil) else {
                return _transcript
            }
            
            guard mediaID != nil else { // (mediaID == "Completed") ||
                return nil
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            if completed {
                if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(self.purpose!)") {
                    do {
                        try _transcript = String(contentsOfFile: destinationURL.path, encoding: String.Encoding.utf8)
                        // This will cause an error.  The tag is created in the constantTags getter while loading.
                        //                    mediaItem.addTag("Machine Generated Transcript")
                        
                        // Also, the tag would normally be added or removed in teh didSet for transcript but didSet's are not
                        // called during init()'s which is fortunate.
                    } catch let error as NSError {
                        print("failed to load machine generated transcript for \(mediaItem.description): \(error.localizedDescription)")
                        completed = false
                        // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                        if !aligning {
//                            remove()
//                        }
                    }
                } else {
                    completed = false
                }
            } else {
                if !transcribing && (_transcript == nil) && (self.resultsTimer == nil) { //  && (mediaID != "Completed")
                    transcribing = true
                    
                    Thread.onMainThread() {
                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true), repeats: true)
                    }
                } else {
                    // Overkill to make sure the cloud storage is cleaned-up?
                    //                mediaItem.voicebase?.delete()  // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                    if self.resultsTimer != nil {
                        print("TIMER NOT NIL!")
                    }
                }
            }
            
            return _transcript
        }
        
        set {
            _transcript = newValue
            
            let fileManager = FileManager.default
            
            guard let mediaItem = mediaItem else {
                return
            }

            guard mediaItem.id != nil else {
                return
            }

            if _transcript != nil {
                DispatchQueue.global(qos: .background).async {
                    if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(self.purpose!)") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try self._transcript?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8);
                        } catch let error as NSError {
                            print("failed to write transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            } else {
                DispatchQueue.global(qos: .background).async {
                    if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(self.purpose!)") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
                            }
                        } else {
                            print("machine generated transcript file doesn't exist")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _transcript:String?
    {
        didSet {
            guard let mediaItem = mediaItem else {
                return
            }
            
            if mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                return self._transcript != nil
            }).count == 0 {
                globals.queue.sync(execute: { () -> Void in
                    mediaItem.removeTag("Machine Generated Transcript")
                })
            } else {
                globals.queue.sync(execute: { () -> Void in
                    mediaItem.addTag("Machine Generated Transcript")
                })
            }
        }
    }
    
    var following : [[String:Any]]?
    {
        get {
            guard globals.mediaPlayer.mediaItem == mediaItem else {
                return nil
            }
            
            let transcript = transcriptFromWords
            
            var segment : String?
            
            var following = [[String:Any]]()
            
            var start : Double?
            var end : Double?
            
//            print(words)
            
            if var words = words, words.count > 0 {
                while words.count > 0 {
                    let word = words.removeFirst()
                    
                    segment = word["w"] as? String
                    
                    start = Double(word["s"] as! Int) / 1000.0
                    end = Double(word["e"] as! Int) / 1000.0
                    
                    while ((transcript?.components(separatedBy: segment!).count > 2) || (segment?.components(separatedBy: " ").count < 10) || (words.first?["m"] != nil)) && (words.count > 0) {
                        let word = words.removeFirst()
                        
                        if let string = word["w"] as? String {
                            if let metadata = word["m"] as? String, metadata == "punc" {
                                var spacing = String()
                                
                                switch string {
                                case ".":
                                    spacing = " "
                                    
                                default:
                                    spacing = ""
                                    break
                                }
                                
                                segment = (segment != nil ? segment! : "") + string + (words.count > 0 ? spacing : " ") // + "  "
                            } else {
                                segment = (segment != nil ? segment! + (!segment!.isEmpty ? " " : "") : "") + string
                            }
                        }
                        
                        end = Double(word["e"] as! Int) / 1000.0
                    }
                    
//                    segment = segment?.replacingOccurrences(of: ".   ", with: ".  ")
                    
                    following.append(["start":start!,"end":end!,"text":segment!])
                    
                    segment = nil
                }
            }
            
            return following.count > 0 ? following : nil
        }
    }
    
    var mediaJSON: [String:Any]?
    {
        get {
            guard completed else {
                return nil
            }
            
            guard _mediaJSON == nil else {
//                print(_mediaJSON)
                return _mediaJSON
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard mediaItem.id != nil else {
                return nil
            }
            
            guard purpose != nil else {
                return nil
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(self.purpose!).media"), let data = try? Data(contentsOf: url) {
                do {
                    _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                } catch let error as NSError {
                    print("failed to load machine generated media for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    if completed && !aligning {
//                        remove()
//                    }
                }
            } else {
                print("failed to open machine generated media for \(mediaItem.description)")
                // Not sure I want to do this since it only removes keywords
//                remove()
            }
            
            return _mediaJSON
        }
        set {
            _mediaJSON = newValue
            
            guard let mediaItem = mediaItem else {
                return
            }
            
            guard mediaItem.id != nil else {
                return
            }
            
            guard purpose != nil else {
                return
            }
            
            //            guard completed else {
            //                return
            //            }
            
            DispatchQueue.global(qos: .background).async {
                let fileManager = FileManager.default
                
                if self._mediaJSON != nil {
                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: self._mediaJSON as Any, format: .xml, options: 0)
                    
                    if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(self.purpose!).media") {
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript media: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try mediaPropertyList?.write(to: destinationURL)
                        } catch let error as NSError {
                            print("failed to write machine generated transcript media to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("destinationURL nil!")
                    }
                } else {
                    if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(self.purpose!).media") {
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript media: \(error.localizedDescription)")
                            }
                        } else {
                            print("machine generated transcript media file doesn't exist")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _mediaJSON : [String:Any]?
    {
        didSet {

        }
    }

    var keywordsJSON: [String:Any]?
    {
        get {
            return mediaJSON?["keywords"] as! [String:Any]?
        }
    }
    
    var keywordDictionaries : [String:[String:Any]]?
    {
        get {
            if let latest = keywordsJSON?["latest"] as? [String:Any] {
                if let wordDictionaries = latest["words"] as? [[String:Any]] {
                    var kwdd = [String:[String:Any]]()
                    
                    for dict in wordDictionaries {
                        if let name = dict["name"] as? String {
                            kwdd[name.lowercased()] = dict
                        }
                    }
                    
                    return kwdd.count > 0 ? kwdd : nil
                }
            }
            
            return nil
        }
    }
    
    var keywords : [String]?
    {
        get {
            if let keywords = keywordDictionaries?.filter({ (key: String, value: [String : Any]) -> Bool in
                if let speakerTimes = value["t"] as? [String:[String]] {
                    if let times = speakerTimes["unknown"] {
                        return times.count > 0
                    }
                }
                return false
            }).map({ (key: String, value: [String : Any]) -> String in
                return key
            }) {
                return keywords
            } else {
                return nil
            }
        }
    }
    
    var transcriptsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["transcripts"] as? [String:Any]
        }
    }
    
    var transcriptLatest : [String:Any]?
    {
        get {
            return transcriptsJSON?["latest"] as? [String:Any]
        }
    }
    
    var words : [[String:Any]]?
    {
        get {
            return transcriptLatest?["words"] as? [[String:Any]]
        }
    }
    
    var transcriptFromWords : String?
    {
        get {
            var transcript:String?
            
            if let words = words {
                var index = 0
                
                for word in words {
                    if let string = word["w"] as? String {
                        if let metadata = word["m"] as? String, metadata == "punc" {
                            var spacing = String()
                            
                            switch string {
                            case ".":
                                spacing = " "
                                
                            default:
                                spacing = ""
                                break
                            }
                            
                            transcript = (transcript != nil ? transcript! : "") + string + (index < (words.count - 1) ? spacing : " ")
                        } else {
                            transcript = (transcript != nil ? transcript! + (!transcript!.isEmpty ? " " : "") : "") + string
                        }
                    }
                    index += 1
                }
            }
            
            return transcript //?.replacingOccurrences(of: ".   ", with: ".  ")
        }
    }
    
    var topicsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["topics"] as! [String:Any]?
        }
    }
    
    var topicsDictionaries : [String:[String:Any]]?
    {
        get {
            if let latest = topicsJSON?["latest"] as? [String:Any] {
                if let words = latest["topics"] as? [[String:Any]] {
                    var tdd = [String:[String:Any]]()
                    
                    for dict in words {
                        if let name = dict["name"] as? String {
                            tdd[name] = dict
                        }
                    }
                    
                    return tdd.count > 0 ? tdd : nil
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    var topics : [String]?
    {
        get {
            if let topics = topicsDictionaries?.map({ (key: String, value: [String : Any]) -> String in
                return key
            }) {
                return topics
            } else {
                return nil
            }
        }
    }
    
    init(mediaItem:MediaItem,purpose:String)
    {
        self.mediaItem = mediaItem
        
        self.purpose = purpose

        if let mediaID = mediaItem.mediaItemSettings?["mediaID."+self.purpose!] {
            self.mediaID = mediaID
        }
        
        if let completed = mediaItem.mediaItemSettings?["completed."+self.purpose!] {
            self.completed = completed == "YES"
        }
    }
    
    func createBody(parameters: [String: String],boundary: String) -> NSData
    {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            switch key {
                // This works, but uploading the file takes A LOT longer than the URL!
//            case "media":
//                var mimeType : String!
//
//                switch purpose! {
//                case Purpose.audio:
//                    mimeType = "audio/mpeg"
//                    break
//
//                case Purpose.video:
//                    mimeType = "video/mp4"
//                    break
//
//                default:
//                    break
//                }
//
//                body.appendString(boundaryPrefix)
//                let audioData = try? Data(contentsOf: URL(string: value)!)
//                body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(mediaItem!.id!)\"\r\n")
//                body.appendString("Content-Type: \(mimeType!)\r\n\r\n")
//                body.append(audioData!)
//                body.appendString("\r\n")
//                break
                
            default:
                body.appendString(boundaryPrefix)
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
                break
            }
        }
        
        body.appendString("--".appending(boundary.appending("--\r\n")))

        return body //as Data
    }
    
    func post(path:String?,parameters:[String:String]?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        guard let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let parameters = parameters else {
            return
        }
        
//        guard let mediaItem = mediaItem else {
//            return
//        }
        
//        guard let mediaID = mediaID else {
//            return
//        }
        
        let service = VoiceBase.url(mediaID:mediaID, path:path)
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "POST"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createBody(parameters: parameters,boundary: boundary)
        
        request.httpBody = body as Data
        request.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
        
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
                Thread.onMainThread() {
                    onError?(json)
                }
            } else {
                Thread.onMainThread() {
                    completion?(json)
                }
            }
        })
        
        task.resume()
    }
    
    func uploadUserInfo(alert:Bool) -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                if alert {
                    globals.alert(title: "Transcription Completed",message: "The transcription process for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas completed.")
                }
                
                self.transcribing = false
                self.completed = true

                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                self.getTranscript(alert:alert)
                self.getTranscriptSRT(alert:alert)
                
                self.details(alert:alert)
            } else {
                if let progress = json?["progress"] as? [String:Any] {
                    if let tasks = progress["tasks"] as? [String:Any] {
                        let count = tasks.count
                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                            if let dict = value as? [String:Any] {
                                if let status = dict["status"] as? String {
                                    return status == "finished"
                                }
                            }
                            
                            return false
                        }).count
                        
                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                        
                        print("\(self.mediaItem!.title!) (\(self.transcriptPurpose)) is \(self.percentComplete!)% finished")
                    }
                }
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            self.remove()
            
            let error = (json?["errors"] as? [String:Any])?["error"] as? String

            globals.alert(title: "Transcript Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again.")
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }

        return userInfo.count > 0 ? userInfo : nil
    }
    
    func upload()
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        let parameters:[String:String] = ["media":url,"metadata":self.metadata]//,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
        
        post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            self.uploadJSON = json
            
            if let status = json?["status"] as? String, status == "accepted" {
                if let mediaID = json?["mediaId"] as? String {
                    self.mediaID = mediaID
                    
                    globals.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas been started.  You will be notified when it is complete.")
                    
                    if self.resultsTimer == nil {
                        Thread.onMainThread() {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true), repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                }
            } else {
                // Not accepted.
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.transcribing = false
            
            let error = (json?["errors"] as? [String:Any])?["error"] as? String
            
            globals.alert(title: "Transcript Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")

            Thread.onMainThread() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        })
    }
    
    func progress(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept:nil, mediaID: mediaID, path: "progress", completion: completion, onError: onError)
    }
    
    @objc func monitor(_ timer:Timer?)
    {
        // Expected to be on the main thread
        guard   let dict = timer?.userInfo as? [String:Any],
            let completion = dict["completion"] as? (([String:Any]?)->(Void)),
            let onError = dict["onError"] as? (([String:Any]?)->(Void)) else {
            return
        }
        
        progress(completion: completion, onError: onError)
    }
    
    func delete()
    {
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        guard let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        let service = VoiceBase.url(mediaID:mediaID, path:nil)
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
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
                    
                    if (httpResponse.statusCode == 204) || (httpResponse.statusCode == 404) {
                        // It eithber completed w/o error (204) so it is now gone and we should set mediaID to nil OR it couldn't be found (404) in which case it should also be set to nil.
                        self.mediaID = nil // self._transcript != nil ? "Completed" :
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
            
            }
        })
        
        task.resume()
    }
    
    func remove()
    {
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            return
//        }
        
        delete()

        // Must retain purpose and mediaItem.
        //        purpose = nil
        //        mediaItem = nil
        
        mediaID = nil
        
        transcribing = false
        completed = false
        aligning = false

        percentComplete = nil
        
        uploadJSON = nil
        mediaJSON = nil
        
        resultsTimer?.invalidate()
        resultsTimer = nil
        
        transcript = nil
        transcriptSRT = nil
        
//        topicsJSON = nil
//        
//        keywordsJSON = nil
        
//        globals.queue.sync(execute: { () -> Void in
//            self.mediaItem.removeTag("Machine Generated Transcript")
//        })
        
//        let fileManager = FileManager.default
        
//        if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).keywords") {
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript keywords")
//                }
//            } else {
//                print("machine generated transcript keywords file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
        
//        if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).topics") {
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript topics")
//                }
//            } else {
//                print("machine generated transcript topics file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
        
//        if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(purpose!)") {
//            // Check if file exist
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript")
//                }
//            } else {
//                print("machine generated transcript file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
    }
    
    func topicKeywordDictionaries(topic:String?) -> [String:[String:Any]]?
    {
        guard let topic = topic else {
            return nil
        }
        
        if let topicDictionary = topicsDictionaries?[topic] {
            if let keywordsDictionaries = topicDictionary["keywords"] as? [[String:Any]] {
                var kwdd = [String:[String:Any]]()
                
                for dict in keywordsDictionaries {
                    if let name = dict["name"] as? String {
                        kwdd[name.lowercased()] = dict
                    }
                }
                
                return kwdd.count > 0 ? kwdd : nil
            }
        }
        
        return nil
    }
    
    func topicKeywords(topic:String?) -> [String]?
    {
        guard let topic = topic else {
            return nil
        }
        
        if let topicKeywordDictionaries = topicKeywordDictionaries(topic: topic) {
            let topicKeywords = topicKeywordDictionaries.map({ (key: String, value: [String : Any]) -> String in
                return key
            })
            
            return topicKeywords.count > 0 ? topicKeywords : nil
        }
        
        return nil
    }
    
    func topicKeywordTimes(topic:String?,keyword:String?) -> [String]?
    {
        guard let topic = topic else {
            return nil
        }
        
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionaries = topicKeywordDictionaries(topic:topic) {
            if let keywordDictionary = keywordDictionaries[keyword] {
                if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                    if let times = speakerTimes["unknown"] {
                        return times
                    }
                }
            }
        }
        
        return nil
    }
    
    var allTopicKeywords : [String]?
    {
        guard let topics = topics else {
            return nil
        }
        
        var keywords = Set<String>()
        
        for topic in topics {
            if let topicsKeywords = topicKeywords(topic: topic) {
                keywords = keywords.union(Set(topicsKeywords))
            }
        }
        
        return keywords.count > 0 ? Array(keywords) : nil
    }
    
    var allTopicKeywordDictionaries : [String:[String:Any]]?
    {
        guard let topics = topics else {
            return nil
        }
        
        var allTopicKeywordDictionaries = [String:[String:Any]]()
        
        for topic in topics {
            if let topicKeywordDictionaries = topicKeywordDictionaries(topic: topic) {
                for topicKeywordDictionary in topicKeywordDictionaries {
                    if allTopicKeywordDictionaries[topicKeywordDictionary.key] == nil {
                        allTopicKeywordDictionaries[topicKeywordDictionary.key.lowercased()] = topicKeywordDictionary.value
                    } else {
                        print("allTopicKeywordDictionaries key occupied")
                    }
                }
            }
        }
        
        return allTopicKeywordDictionaries.count > 0 ? allTopicKeywordDictionaries : nil
    }
    
    func allTopicKeywordTimes(keyword:String?) -> [String]?
    {
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionary = allTopicKeywordDictionaries?[keyword] {
            if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                if let times = speakerTimes["unknown"] {
                    return times
                }
            }
        }
        
        return nil
    }
    
    func keywordTimes(keyword:String?) -> [String]?
    {
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionary = keywordDictionaries?[keyword] {
            if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                if let times = speakerTimes["unknown"] {
                    return times
                }
            }
        }
        
        return nil
    }
    
    func details(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.details(mediaID: mediaID, completion: completion, onError: onError)
    }

    func details(alert:Bool)
    {
        details(completion: { (json:[String : Any]?) -> (Void) in
            if let json = json?["media"] as? [String:Any] {
                self.mediaJSON = json
                if alert {
                    globals.alert(title: "Keywords Available",message: "The keywords for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nare available.")
                }
            } else {
                if alert {
                    globals.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nare not available.")
                }
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert {
                globals.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nare not available.")
            }
        })
    }
    
    func metadata(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept: nil, mediaID: mediaID, path: "metadata", completion: completion, onError: onError)
    }
    
    func addMetaData()
    {
        let parameters = ["metadata":metadata]
        
        post(path: "metadata", parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            
        }, onError: { (json:[String : Any]?) -> (Void) in
            
        })
    }
    
    func alignUserInfo(alert:Bool) -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                if alert {
                    globals.alert(title: "Transcript Realignment Complete",message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas been realigned.")
                }
                
                self.aligning = false

                self.percentComplete = nil
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                // Don't do this because we're just re-uploading
                //                                self.transcribing = false
                //                                self.completed = true
                
//                // These will NOT delete the existing versions.
//                self._transcript = nil
//                self._transcriptSRT = nil
                
                // Get the new versions.
                self.getTranscript(alert:alert)
                self.getTranscriptSRT(alert:alert)
                
//                // This will NOT delete the existing versions.
//                self._mediaJSON = nil
                
                // Get the new ones.
                self.details(alert:alert)
            } else {
                if let progress = json?["progress"] as? [String:Any] {
                    if let tasks = progress["tasks"] as? [String:Any] {
                        let count = tasks.count
                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                            if let dict = value as? [String:Any] {
                                if let status = dict["status"] as? String {
                                    return status == "finished"
                                }
                            }
                            
                            return false
                        }).count
                        
                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                        
                        print("\(self.mediaItem!.title!) (\(self.transcriptPurpose)) is \(self.percentComplete!)% finished")
                    }
                }
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            self.remove()
            
            let error = (json?["errors"] as? [String:Any])?["error"] as? String
            
            globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.")
            
//            DispatchQueue.main.async(execute: { () -> Void in
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
//            })
        }

        return userInfo.count > 0 ? userInfo : nil
    }
    
    func align(_ transcript:String?)
    {
        guard let transcript = transcript else {
            return
        }
        
        guard completed else {
            // Should never happen.
            return
        }
        
        guard !aligning else {
            globals.alert(title:"Transcript Alignment in Progress", message:"The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis already being aligned.  You will be notified when it is completed.")
            return
        }
        
        aligning = true
        
        // Check whether the media is on VB
        progress(completion: { (json:[String : Any]?) -> (Void) in
            let parameters = ["transcript":transcript]//,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
            
            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                // If it is on VB, upload the transcript for realignment
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        guard self.mediaID == mediaID else {
                            self.aligning = false
                            self.resultsTimer?.invalidate()
                            self.resultsTimer = nil
                            
                            let error = (json?["errors"] as? [String:Any])?["error"] as? String
                            
                            globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")
                            return
                        }

                        // Don't do this because we're just re-aligning.
//                        self.transcribing = true
//                        self.completed = false
                        
                        globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                        
                        if self.resultsTimer == nil {
                            Thread.onMainThread() {
                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true), repeats: true)
                            }
                        } else {
                            print("TIMER NOT NIL!")
                        }
                    }
                } else {
                    // Not accepted
                    
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                let error = (json?["errors"] as? [String:Any])?["error"] as? String
                
                globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")
            })
        }, onError: { (json:[String : Any]?) -> (Void) in
            // Not on VoiceBase
            globals.alert(title:"Media Not on VoiceBase", message:"The media for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript realignment is started.")
            
            // Upload then align
            self.mediaID = nil
            
            let parameters:[String:String] = ["media":self.url!,"metadata":self.metadata] // "configuration":"{\"configuration\":{\"executor\":\"v2\"}}"
            
            self.post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        // We do get a new mediaID
                        self.mediaID = mediaID
                        
                        globals.alert(title:"Media Upload Started", message:"The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwill be started once the media upload has completed.")
                        
                        var userInfo = [String:Any]()
                        
                        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
                            if let status = json?["status"] as? String, status == "finished" {
                                self.percentComplete = nil
                                
                                self.resultsTimer?.invalidate()
                                self.resultsTimer = nil

                                // Don't do any of this since we are just re-uploading.
//                                self.transcribing = false
//                                self.completed = true
//                                
//                                // These will delete the existing versions.
//                                self.transcript = nil
//                                self.transcriptSRT = nil
//                                
//                                // Really should compare the old and new version...
//                                
//                                // Get the new versions.
//                                self.getTranscript()
//                                self.getTranscriptSRT()
//                                
//                                // Delete the transcripts, keywords, and topics.
//                                self.mediaJSON = nil
//                                
//                                // Get the new ones.
//                                self.details()
                                
                                // Now do the relignment
                                let parameters:[String:String] = ["transcript":self.transcript!]//,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
                                
                                self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                                    self.uploadJSON = json
                                    
                                    // If it is on VB, upload the transcript for realignment
                                    if let status = json?["status"] as? String, status == "accepted" {
                                        if let mediaID = json?["mediaId"] as? String {
                                            guard self.mediaID == mediaID else {
                                                self.aligning = false
                                                self.resultsTimer?.invalidate()
                                                self.resultsTimer = nil

                                                let error = (json?["errors"] as? [String:Any])?["error"] as? String
                                                
                                                globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")
                                                return
                                            }
                                            
                                            // Don't do this because we're just re-aligning.
                                            //                        self.transcribing = true
                                            //                        self.completed = false
                                            
                                            self.aligning = true
                                            
                                            globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                                            
                                            if self.resultsTimer == nil {
                                                Thread.onMainThread() {
                                                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true), repeats: true)
                                                }
                                            } else {
                                                print("TIMER NOT NIL!")
                                            }
                                        }
                                    } else {
                                        // Not accepted.
                                    }
                                }, onError: { (json:[String : Any]?) -> (Void) in
                                    self.aligning = false
                                    self.resultsTimer?.invalidate()
                                    self.resultsTimer = nil
                                    
                                    let error = (json?["errors"] as? [String:Any])?["error"] as? String
                                    
                                    globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")
                                })
                            } else {
                                if let progress = json?["progress"] as? [String:Any] {
                                    if let tasks = progress["tasks"] as? [String:Any] {
                                        let count = tasks.count
                                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                                            if let dict = value as? [String:Any] {
                                                if let status = dict["status"] as? String {
                                                    return status == "finished"
                                                }
                                            }
                                            
                                            return false
                                        }).count
                                        
                                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)

                                        print("\(self.mediaItem!.title!) (\(self.transcriptPurpose)) is \(self.percentComplete!)% finished")
                                    }
                                }
                            }
                        }
                        
                        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
                            self.aligning = false
                            self.resultsTimer?.invalidate()
                            self.resultsTimer = nil

                            let error = (json?["errors"] as? [String:Any])?["error"] as? String
                            
                            globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.")

//                            DispatchQueue.main.async(execute: { () -> Void in
//                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
//                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
//                            })
                        }
                        
                        if self.resultsTimer == nil {
                            Thread.onMainThread() {
                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: userInfo, repeats: true)
                            }
                        } else {
                            print("TIMER NOT NIL!")
                        }
                    }
                } else {
                    // No accepted.
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                let error = (json?["errors"] as? [String:Any])?["error"] as? String
                
                globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript realignment for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again.")
            })
        })
    }
    
    func getTranscript(alert:Bool)
    {
        guard let mediaID = mediaID else {
            upload()
            return
        }
        
        VoiceBase.get(accept:"text/plain",mediaID: mediaID, path: "transcripts/latest", completion: { (json:[String : Any]?) -> (Void) in
            if let text = json?["text"] as? String {
                self.transcript = text

                if alert {
                    globals.alert(title: "Transcript Available",message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis available.")
                }
                
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                }
            } else {
                if alert {
                    globals.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis not available.")
                }
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert {
                globals.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis not available.")
            }
        })
    }
    
    var srtArrays:[[String]]?
    {
        get {
            guard _srtArrays == nil else {
                return _srtArrays
            }
            
            let _ = transcriptSRT
            
            return _srtArrays
        }
        set {
            _srtArrays = newValue
        }
    }
    
    var _srtArrays:[[String]]?
    {
        didSet {
            guard let srtArrays = _srtArrays else {
                return
            }
            
            var tokenTimes = [String:[String]]()
            
            for srtArray in srtArrays {
                if let times = srtArrayTimes(srtArray: srtArray), let startTime = times.first {
                    if let tokens = tokensFromString(srtArrayText(srtArray: srtArray)) {
                        for token in tokens {
                            let key = token.lowercased()
                            
                            if tokenTimes[key] == nil {
                                tokenTimes[key] = [startTime]
                            } else {
                                if var times = tokenTimes[key] {
                                    times.append(startTime)
                                    tokenTimes[key] = Array(Set(times)).sorted()
                                }
                            }
                        }
                    }
                }
            }
            
            srtTokensTimes = tokenTimes.count > 0 ? tokenTimes : nil
        }
    }
    
    var srtTokens : [String]?
    {
        return srtTokensTimes?.keys.sorted()
    }
    
    func srtTokenTimes(token:String) -> [String]?
    {
        return srtTokensTimes?[token]
    }
    
    var srtTokensTimes : [String:[String]]?
    {
        get {
            guard _srtTokensTimes == nil else {
                return _srtTokensTimes
            }
            
            let _ = transcriptSRT
            
            return _srtTokensTimes
        }
        set {
            _srtTokensTimes = newValue
        }
    }
    
    var _srtTokensTimes : [String:[String]]?
    {
        didSet {
            
        }
    }
    
    func srtArrayStartTime(srtArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: srtArrayTimes(srtArray: srtArray)?.first)
    }
    
    func srtArrayEndTime(srtArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: srtArrayTimes(srtArray: srtArray)?.last)
    }
    
    func srtArrayIndex(srtArray:[String]?) -> String?
    {
        if let count = srtArray?.first {
            return count
        } else {
            return nil
        }
    }
    
    func srtArrayTimes(srtArray:[String]?) -> [String]?
    {
        guard srtArray?.count > 1 else {
            return nil
        }
        
        var array = srtArray!
        
        if let count = array.first, !count.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        if let timeWindow = array.first, !timeWindow.isEmpty {
            array.remove(at: 0)
            let times = timeWindow.components(separatedBy: " --> ")
            //            print(times)
            
            return times
        } else {
            return nil
        }
    }
    
    func srtArrayText(srtArray:[String]?) -> String?
    {
        guard srtArray?.count > 1 else {
            return nil
        }
        
        var string = String()
        
        var array = srtArray!
        
        if let count = array.first, !count.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        if let timeWindow = array.first, !timeWindow.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        for element in array {
            string = string + " " + element.lowercased()
        }
        
        return !string.isEmpty ? string : nil
    }
    
    func searchSRTArrays(string:String) -> [[String]]?
    {
        var results = [[String]]()
        
        for srtArray in srtArrays! {
            if let contains = srtArrayText(srtArray: srtArray)?.contains(string.lowercased()), contains {
                results.append(srtArray)
            }
        }
        
        return results.count > 0 ? results : nil
    }
    
    var srtComponents:[String]?
    {
        get {
            guard _srtComponents == nil else {
                return _srtComponents
            }
            
            let _ = transcriptSRT
            
            return _srtComponents
        }
        set {
            _srtComponents = newValue
        }
    }
    
    var _srtComponents:[String]?
    {
        didSet {
            guard let srtComponents = _srtComponents else {
                return
            }
            
            var srtArrays = [[String]]()
            
            for srtComponent in srtComponents {
                srtArrays.append(srtComponent.components(separatedBy: "\n"))
            }
            
            self.srtArrays = srtArrays.count > 0 ? srtArrays : nil
        }
    }
    
    var transcriptSRT:String?
    {
        get {
            guard completed else {
                return nil
            }
            
            guard _transcriptSRT == nil else {
                return _transcriptSRT
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard mediaItem.id != nil else {
                return nil
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(self.purpose!).srt") {
                do {
                    try _transcriptSRT = String(contentsOfFile: url.path, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    print("failed to load machine generated transcriptSRT for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    if completed && !aligning {
//                        remove()
//                    }
                }
            }
            
            return _transcriptSRT
        }
        
        set {
            guard let mediaItem = mediaItem else {
                return
            }
            
            guard mediaItem.id != nil else {
                return
            }
            
//            guard completed else {
//                return
//            }
            
            var changed = false
            
            var value = newValue
            
            if _transcriptSRT == nil {
                if var srtComponents = value?.components(separatedBy: "\n\n") {
                    for srtComponent in srtComponents {
                        var srtArray = srtComponent.components(separatedBy: "\n")
                        if srtArray.count > 2 {
                            let count = srtArray.removeFirst()
                            let timeWindow = srtArray.removeFirst()
                            
                            if let range = srtComponent.range(of: timeWindow + "\n") {
                                let text = srtComponent.substring(from: range.upperBound).replacingOccurrences(of: "\n", with: " ")
                                
                                if let index = srtComponents.index(of: srtComponent) {
                                    srtComponents[index] = "\(count)\n\(timeWindow)\n" + text
                                    changed = true
                                }
                            }
                        }
                    }
                    if changed {
                        value = nil
                        for srtComponent in srtComponents {
                            value = value != nil ? value! + VoiceBase.separator + srtComponent : srtComponent
                        }
                    }
                }
            }
            
            _transcriptSRT = value
            
            DispatchQueue.global(qos: .background).async {
                let fileManager = FileManager.default
                
                if self._transcriptSRT != nil {
                    if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(self.purpose!).srt") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated SRT transcript: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try self._transcriptSRT?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8);
                        } catch let error as NSError {
                            print("failed to write SRT transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                } else {
                    if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(self.purpose!).srt") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
                            }
                        } else {
                            print("machine generated transcript file doesn't exist")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _transcriptSRT:String?
    {
        didSet {
            srtComponents = _transcriptSRT?.components(separatedBy: VoiceBase.separator)
            //            print(srtComponents)
        }
    }
    
    var transcriptSRTFromWords:String?
    {
        get {
            var str : String?
            
            if let following = following {
                var count = 1
                var srtComponents = [String]()
                
                for element in following {
                    if  let start = element["start"] as? Double,
                        let startSeconds = secondsToHMS(seconds: "\(start)"),
                        let end = element["end"] as? Double,
                        let endSeconds = secondsToHMS(seconds: "\(end)"),
                        let text = element["text"] as? String {
                        srtComponents.append("\(count)\n\(startSeconds) --> \(endSeconds)\n\(text)")
                    }
                    count += 1
                }

                for srtComponent in srtComponents {
                    str = str != nil ? str! + VoiceBase.separator + srtComponent : srtComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptSRTFromSRTs:String?
    {
        get {
            var str : String?
            
            if let srtComponents = srtComponents {
                for srtComponent in srtComponents {
                    str = str != nil ? str! + VoiceBase.separator + srtComponent : srtComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptFromSRTs:String?
    {
        get {
            var str : String?
            
            if let srtComponents = srtComponents {
                for srtComponent in srtComponents {
                    var strings = srtComponent.components(separatedBy: "\n")
                    
                    if strings.count > 2 {
                        _ = strings.removeFirst() // count
                        let timing = strings.removeFirst() // time
                        
                        if let range = srtComponent.range(of:timing+"\n") {
                            let string = srtComponent.substring(from:range.upperBound)
                            str = str != nil ? str! + " " + string : string
                        }
                    }
                }
            }
            
//            str = str?.replacingOccurrences(of: " . ", with: ".  ").replacingOccurrences(of: ". ", with: ".  ").replacingOccurrences(of: ".   ", with: ".  ")
//            
//            str = str != nil ? str! + " " : nil

            return str
        }
    }
    
    func getTranscriptSRT(alert:Bool)
    {
        VoiceBase.get(accept: "text/srt", mediaID: mediaID, path: "transcripts/latest", completion: { (json:[String : Any]?) -> (Void) in
            if let srt = json?["text"] as? String {
                self._transcriptSRT = nil // Without this the new SRT will not be processed correctly.

                self.transcriptSRT = srt

                if alert {
                    globals.alert(title: "Transcript SRT Available",message: "The transcript SRT for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis available.")
                }
            } else {
                if alert {
                    globals.alert(title: "Transcript SRT Not Available",message: "The transcript SRT for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis not available.")
                }
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert {
                globals.alert(title: "Transcript SRT Not Available",message: "The transcript SRT for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nis not available.")
            }
        })
    }
    
    func search(string:String?)
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let string = string else {
            return
        }
        
        //        guard let mediaID = mediaID else {
        //            return
        //        }
        
        var service = VoiceBase.url(mediaID: nil, path: nil)
        
        service = service + "q=" + string
        
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        //        request.addValue("text/plain", forHTTPHeaderField: "Accept")
        
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
                Thread.onMainThread() {
                    
                }
            } else {
                Thread.onMainThread() {
                    
                }
            }
        })
        
        task.resume()
    }

    func relaodUserInfo() -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                self.percentComplete = nil
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                // Don't do this because we're just re-uploading
                //                                self.transcribing = false
                //                                self.completed = true
                
                // Get the new versions.
                self.getTranscript(alert: true)
                self.getTranscriptSRT(alert: true)
                
                // Get the new ones.
                self.details(alert: true)

                globals.alert(title: "Transcript Reload Complete",message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nhas been reloaded from VoiceBase.")
            } else {
                if let progress = json?["progress"] as? [String:Any] {
                    if let tasks = progress["tasks"] as? [String:Any] {
                        let count = tasks.count
                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                            if let dict = value as? [String:Any] {
                                if let status = dict["status"] as? String {
                                    return status == "finished"
                                }
                            }
                            
                            return false
                        }).count
                        
                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                        
                        print("\(self.mediaItem!.title!) (\(self.transcriptPurpose)) is \(self.percentComplete!)% finished")
                    }
                }
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            self.remove()
            
            let error = (json?["errors"] as? [String:Any])?["error"] as? String
            
            globals.alert(title: "Transcript Alignment Failed",message: (error != nil ? "Error: \(error!)\n": "") + "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.")
            
            //            DispatchQueue.main.async(execute: { () -> Void in
            //                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
            //                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            //            })
        }
        
        return userInfo.count > 0 ? userInfo : nil
    }
    
    func recognizeAlertActions(viewController:UIViewController,tableView:UITableView) -> AlertAction?
    {
        guard let purpose = purpose else {
            return nil
        }
        
        func mgtUpdate()
        {
            let completion = percentComplete == nil ? " (\(transcriptPurpose))" : " (\(transcriptPurpose))" + "\n(\(percentComplete!)% complete)"
            
            var title = "Machine Generated Transcript "
            
            var message = "You will be notified when the machine generated transcript for\n\n\(mediaItem!.text!)\(completion) "
            
            if (mediaID != nil) {
                title = title + "in Progress"
                message = message + "\n\nis available."
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Media ID", style: .default, action: {
                    let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                    message: nil,
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    alert.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = self.mediaID
                    })
                    
                    let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        alertItem -> Void in
                    })
                    alert.addAction(okayAction)
                    
                    viewController.present(alert, animated: true, completion: nil)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                
                globals.alert(title:title, message:message, actions:actions)
            } else {
                title = title + "Requested"
                message = message + "\n\nhas started."
                
                globals.alert(title:title, message:message)
            }
        }
        
        var prefix:String!
        
        switch purpose {
        case Purpose.audio:
            prefix = Constants.Strings.Audio
            
        case Purpose.video:
            prefix = Constants.Strings.Video
            
        default:
            prefix = ""
            break
        }
        
        var action : AlertAction!
        
        action = AlertAction(title: prefix + " " + Constants.Strings.Transcript, style: .default) {
            if self.transcript == nil {
                guard globals.reachability.currentReachabilityStatus != .notReachable else {
                    networkUnavailable(viewController,"Machine generated transcript unavailable.")
                    return
                }
                
                if !self.transcribing {
                    if globals.reachability.currentReachabilityStatus != .notReachable {
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .default, action: {
                            self.getTranscript(alert: true)
                            //                                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                            //                                })
                            tableView.setEditing(false, animated: true)
                            mgtUpdate()
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, action: nil))
                        
                        alertActionsCancel( viewController: viewController,
                                            title: "Begin Creating\nMachine Generated Transcript?",
                                            message: "\(self.mediaItem!.text!) (\(self.transcriptPurpose))",
                            alertActions: alertActions,
                            cancelAction: nil)
                    } else {
                        networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                    }
                } else {
                    mgtUpdate()
                }
            } else {
                var alertActions = [AlertAction]()
                
                alertActions.append(AlertAction(title: "Show", style: .default, action: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Transcript", style: .default, action: {
                        if self.transcript == self.transcriptFromWords {
                            print("THEY ARE THE SAME!")
                        }
                        
                        var htmlString = "<!DOCTYPE html><html><body>"
                        
                        htmlString = htmlString + self.mediaItem!.headerHTML! +
                            "<br/>" +
                            "<center>MACHINE GENERATED TRANSCRIPT<br/>(\(self.purpose!))</center>" +
                            "<br/>" +
                            self.transcript!.replacingOccurrences(of: "\n", with: "<br/>") +
                            //                                            "<br/>" +
                            //                                            "<plaintext>" + transcript!.transcriptSRT! + "</plaintext>" +
                        "</body></html>"
                        
                        popoverHTML(viewController,mediaItem:nil,title:self.mediaItem?.title,barButtonItem:nil,sourceView:nil,sourceRectView:nil,htmlString:htmlString)
                    }))
                    
                    alertActions.append(AlertAction(title: "Transcript with Timing", style: .default, action: {
                        process(viewController: viewController, work: { () -> (Any?) in
                            var htmlString = "<!DOCTYPE html><html><body>"
                            
                            var srtHTML = String()
                            
                            srtHTML = srtHTML + "<table>"
                            
                            srtHTML = srtHTML + "<tr valign=\"bottom\"><td><b>#</b></td><td><b>Start Time</b></td><td><b>End Time</b></td><td><b>Recognized Speech</b></td></tr>"
                            
                            if let srtComponents = self.srtComponents {
                                for srtComponent in srtComponents {
                                    var srtArray = srtComponent.components(separatedBy: "\n")
                                    
                                    if srtArray.count > 2  {
                                        let count = srtArray.removeFirst()
                                        let timeWindow = srtArray.removeFirst()
                                        let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                                        
                                        if  let start = times.first,
                                            let end = times.last,
                                            let range = srtComponent.range(of: timeWindow+"\n") {
                                            let text = srtComponent.substring(from: range.upperBound)
                                            
                                            let row = "<tr valign=\"top\"><td>\(count)</td><td>\(start)</td><td>\(end)</td><td>\(text.replacingOccurrences(of: "\n", with: " "))</td></tr>"
                                            srtHTML = srtHTML + row
                                        }
                                    }
                                }
                            }
                            
                            srtHTML = srtHTML + "</table>"
                            
                            htmlString = htmlString + self.mediaItem!.headerHTML! +
                                "<br/>" +
                                "<center>MACHINE GENERATED TRANSCRIPT WITH TIMING<br/>(\(self.purpose!))</center>" +
                                "<br/>" +
                                
                                srtHTML +
                                
                            "</body></html>"
                            return htmlString as Any
                        }, completion: { (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(viewController,mediaItem:nil,title:self.mediaItem?.title,barButtonItem:nil,sourceView:nil,sourceRectView:nil,htmlString:htmlString)
                            }
                        })
                    }))

                    alertActionsCancel( viewController: viewController,
                                        title: "Show",
                                        message: "This is a machine generated transcript.  It may lack proper formatting and have signifcant errors.",
                                        alertActions: alertActions,
                                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Edit", style: .default, action: {
                    if  let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: "TextViewController") as? UINavigationController,
                        let textPopover = navigationController.viewControllers[0] as? TextViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                        
                        textPopover.navigationController?.isNavigationBarHidden = false
                        
                        textPopover.navigationItem.title = "Edit Text"
                        
                        let text = self.transcript
                        
                        textPopover.transcript = self // Must come before track
                        textPopover.track = true
                        
                        textPopover.text = text
                        
                        textPopover.assist = true
                        textPopover.search = true
                        
//                            textPopover.confirmation = { (Void)->Bool in
//                                return true // self.transcript == self.transcriptFromSRTs
//                            }
//                            textPopover.confirmationTitle = "Confirm Saving Changes to Transcript"
//                            textPopover.confirmationMessage = "If you save these changes and later change a transcript element, the transcript may be overwritten and your changes lost."

                        textPopover.completion = { (text:String) -> Void in
                            guard text != textPopover.text else {
                                return
                            }
                            
//                            print(text)
                            
                            // Not clear that NSLinguisticTagger does anything for us since it doesn't know how to punctuate, correct grammar, or segment into paragraphs.
                            // Just knowing the part of speech for a token doesn't do much.
                            
//                            let options = NSLinguisticTagger.Options.omitWhitespace.rawValue | NSLinguisticTagger.Options.joinNames.rawValue
//
//                            let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "en"), options: Int(options))
//                            tagger.string = text
//                            
//                            let range = NSRange(location: 0, length: text.utf16.count)
//                            tagger.enumerateTags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: NSLinguisticTagger.Options(rawValue: options)) { tag, tokenRange, sentenceRange, stop in
//                                let token = (text as NSString).substring(with: tokenRange)
////                                let sentence = (text as NSString).substring(with: sentenceRange)
//                                print("\(tokenRange.location):\(tokenRange.length) \(tag): \(token)") // \n\(sentence)\n
//                            }

//                            var ranges : NSArray?
//                            
//                            let tags = tagger.tags(in: range, scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: NSLinguisticTagger.Options(rawValue: options), tokenRanges: &ranges)
//                            
//                            var index = 0
//                            for tag in tags {
//                                let token = (text as NSString).substring(with: ranges![index] as! NSRange)
//                                print("\(tag): \(token)") // \n\(sentence)\n
//                                index += 1
//                            }
                            
                            self.transcript = text
                        }
                        
                        viewController.present(navigationController, animated: true, completion: {
                            if (globals.mediaPlayer.mediaItem == self.mediaItem) && (self.transcript != self.transcriptFromWords) {
//                                let transcriptCharacters = Array(self.transcript!.characters)
//                                let transcriptFromWordsCharacters = Array(self.transcriptFromWords!.characters)
//            
//                                var index = 0
//                                for character in transcriptCharacters {
//                                    if index < transcriptFromWordsCharacters.count {
//                                        let characterWord = transcriptFromWordsCharacters[index]
//            
//                                        if character != characterWord {
//                                            let window = 15
//                                            print("\n\ncharacter error: \(character) vs. \(characterWord)\n\n")
//                                            print("\(transcriptCharacters[max(index-window,0)...min(index+window,transcriptCharacters.count - 1)])\n\(transcriptFromWordsCharacters[max(index-window,0)...min(index+window,transcriptFromWordsCharacters.count - 1)])")
//                                        } else {
//                                            print(character)
//                                        }
//                                    } else {
//                                        print(character,"BEYOND THE END OF WORD CHARACTERS")
//                                    }
//                                    index += 1
//                                }
                                
                                alertActionsOkay( viewController: viewController,
                                                    title: "Transcript Sync Warning",
                                                    message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\ndiffers from the individually recognized words.  As a result the sync will not be exact.  Please align the transcript for an exact sync.",
                                    alertActions: nil,
                                    okayAction: nil)
                            }
                        })
                    } else {
                        print("ERROR")
                    }
                }))
                
                alertActions.append(AlertAction(title: "Media ID", style: .default, action: {
                    let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                    message: nil,
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    alert.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = self.mediaID
                    })
                    
                    let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        alertItem -> Void in
                    })
                    alert.addAction(okayAction)
                    
                    viewController.present(alert, animated: true, completion: nil)
                }))
                
                if let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable {
                    alertActions.append(AlertAction(title: "Check VoiceBase", style: .default, action: {
                        self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                            if let text = self.mediaItem?.text, let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: "Remove", style: .destructive, action: {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: "Yes", style: .destructive, action: { (Void) -> (Void) in
                                        VoiceBase.delete(mediaID: self.mediaID)
                                    }))
                                    
                                    actions.append(AlertAction(title: "No", style: .default, action:nil))
                                    
                                    globals.alert(title:"Confirm Removal From VoiceBase", message:text, actions:actions)
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                                
                                globals.alert(title:"On VoiceBase", message:"A transcript for\n" + text + "\nwith mediaID \(mediaID) is on VoiceBase.", actions:actions)
                            }
                        }, onError:  { (dict:[String:Any]?)->(Void) in
                            if let text = self.mediaItem?.text, let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                                
                                globals.alert(title:"Not on VoiceBase", message:"A transcript for\n" + text + "\nwith mediaID \(mediaID) is not on VoiceBase.", actions:actions)
                            }
                        })
                    }))
                    
                    alertActions.append(AlertAction(title: "Align", style: .destructive, action: {
                        guard !self.aligning else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment already underway (\(self.percentComplete!)% complete) for:\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                            return
                        }
                        
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .destructive, action: {
                            var alertActions = [AlertAction]()
                            
                            alertActions.append(AlertAction(title: "Transcript", style: .default, action: {
                                self.align(self.transcript)
                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActions.append(AlertAction(title: "Segments", style: .default, action: {
                                self.align(self.transcriptFromSRTs)
                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActions.append(AlertAction(title: "Words", style: .default, action: {
                                self.align(self.transcriptFromWords)
                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActionsCancel( viewController: viewController,
                                                title: "Select Source for Realignment",
                                                message: nil,
                                                alertActions: alertActions,
                                                cancelAction: nil)
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, action: nil))
                        
                        alertActionsCancel( viewController: viewController,
                                            title: "Confirm Realignment of Machine Generated Transcript",
                                            message: "Depending on the source selected, this may change both the transcript and timing for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))",
                            alertActions: alertActions,
                            cancelAction: nil)
                    }))
                }
                
                alertActions.append(AlertAction(title: "Restore", style: .destructive, action: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Regenerate Transcript", style: .destructive, action: {
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .destructive, action: {
                            self.transcript = self.transcriptFromWords
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, action: nil))
                        
                        alertActionsCancel( viewController: viewController,
                                            title: "Confirm Regeneration of Transcript",
                                            message: "The transcript for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
                            alertActions: alertActions,
                            cancelAction: nil)
                    }))
                    
                    if let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable {
                        alertActions.append(AlertAction(title: "Reload from VoiceBase", style: .destructive, action: {
                            self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                                if let text = self.mediaItem?.text {
                                    var alertActions = [AlertAction]()
                                    
                                    alertActions.append(AlertAction(title: "Yes", style: .destructive, action: {
                                        globals.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                        
                                        if self.resultsTimer != nil {
                                            print("TIMER NOT NIL!")
                                            
                                            var actions = [AlertAction]()
                                            
                                            actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                                            
                                            globals.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                        } else {
                                            Thread.onMainThread() {
                                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(), repeats: true)
                                            }
                                        }
                                    }))
                                    
                                    alertActions.append(AlertAction(title: "No", style: .default, action: nil))
                                    
                                    alertActionsCancel( viewController: viewController,
                                                        title: "Confirm Reloading",
                                                        message: "The results of speech recognition for\n\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
                                        alertActions: alertActions,
                                        cancelAction: nil)
                                }
                            }, onError:  { (dict:[String:Any]?)->(Void) in
                                if let text = self.mediaItem?.text {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                                    
                                    globals.alert(title:"Not on VoiceBase", message:text + "\nis not on VoiceBase.", actions:actions)
                                }
                            })
                        }))
                    }
                    
                    alertActionsCancel( viewController: viewController,
                                        title: "Restore Options",
                                        message: "For\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))",
                        alertActions: alertActions,
                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Delete", style: .destructive, action: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Yes", style: .destructive, action: {
                        self.remove()
                        tableView.setEditing(false, animated: true)
                    }))
                    
                    alertActions.append(AlertAction(title: "No", style: .default, action: nil))
                    
                    alertActionsCancel( viewController: viewController,
                                        title: "Confirm Deletion of Machine Generated Transcript",
                                        message: "\(self.mediaItem!.text!) (\(self.transcriptPurpose))",
                        alertActions: alertActions,
                        cancelAction: nil)
                }))
                
                alertActionsCancel(  viewController: viewController,
                                     title: "Machine Generated Transcript (\(self.transcriptPurpose))",
                    message: nil,
                    alertActions: alertActions,
                    cancelAction: nil)
            }
        }
        
        return action
    }
    
    func editSRT(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath)
    {
        editSRT(popover:popover,tableView:tableView,indexPath:indexPath,automatic:false,automaticInteractive:false,automaticCompletion:nil)
    }
    
    func editSRT(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath,automatic:Bool,automaticInteractive:Bool,automaticCompletion:((Void)->(Void))?)
    {
        let stringIndex = popover.section.index(indexPath)
        
        guard let string = popover.section.strings?[stringIndex] else {
            return
        }

        let playing = globals.mediaPlayer.isPlaying
        
        globals.mediaPlayer.pause()
        
        var srtArray = string.components(separatedBy: "\n")
        let count = srtArray.removeFirst() // Count
        let timing = srtArray.removeFirst() // Timing
        let srtTiming = timing.replacingOccurrences(of: ".", with: ",").replacingOccurrences(of: "to", with: "-->") // Timing
        
        if  let first = srtComponents?.filter({ (string:String) -> Bool in
//            print(srtTiming,string)
            return string.contains(srtTiming)
        }).first,
            let navigationController = popover.storyboard!.instantiateViewController(withIdentifier: "TextViewController") as? UINavigationController,
            let textPopover = navigationController.viewControllers[0] as? TextViewController,
            let srtIndex = self.srtComponents?.index(of: first),
            let range = string.range(of:timing+"\n") {
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = popover
            
            Thread.onMainThread {
                textPopover.navigationController?.isNavigationBarHidden = false
                textPopover.navigationItem.title = "Edit Text"
            }
            
            let text = string.substring(from: range.upperBound)
            
            textPopover.text = text
            textPopover.assist = true
            
            textPopover.onCancel = {
                if playing {
                    globals.mediaPlayer.play()
                }
            }
            
            textPopover.automatic = automatic
            textPopover.automaticInteractive = automaticInteractive
            textPopover.automaticCompletion = automaticCompletion
 
//            if !automatic {
//                textPopover.confirmation = { (Void)->Bool in
//                    return true // self.transcript != self.transcriptFromSRTs
//                }
//                textPopover.confirmationTitle = "Confirm Saving Changes to Transcript Element"
//                textPopover.confirmationMessage = "If you save this transcript element the transcript may be overwritten and any changes you have made to the transcript as a whole will be lost."
//            }
            
            textPopover.completion = { (text:String) -> Void in
//                print(text)
                
                guard text != textPopover.text else {
                    if playing {
                        globals.mediaPlayer.play()
                    }
                    return
                }
                
                self.srtComponents?[srtIndex] = "\(count)\n\(srtTiming)\n\(text)"
                if popover.searchActive {
                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
                }
                popover.unfilteredSection.strings?[srtIndex] = "\(count)\n\(timing)\n\(text)"
                
                DispatchQueue.global(qos: .background).async {
                    self.transcriptSRT = self.transcriptSRTFromSRTs
                    
//                    print(self.transcriptSRTFromSRTs)
//                    print("\n\n")
//                    print(self.transcriptSRTFromWords)
                }
                
                Thread.onMainThread {
                    popover.tableView.isEditing = false
                    popover.tableView.reloadData()
                    popover.tableView.reloadData()
                }
                
                if indexPath.section >= popover.tableView.numberOfSections {
                    print("ERROR: bad indexPath.section")
                }
                
                if indexPath.row >= popover.tableView.numberOfRows(inSection: indexPath.section) {
                    print("ERROR: bad indexPath.row")
                }
                
                Thread.onMainThread {
                    popover.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
                }
                
                if playing {
                    globals.mediaPlayer.play()
                }
            }
            
            popover.present(navigationController, animated: true, completion: nil)
        } else {
            print("ERROR")
        }
    }
    
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]? // popover:PopoverTableViewController,
    {
//        let stringIndex = popover.section.index(indexPath)
        
//        guard let string = popover.section.strings?[stringIndex] else {
//            return nil
//        }
        
//        let transcript = popover.transcript
        
        var actions = [AlertAction]()
        
        var edit:AlertAction!
        
        edit = AlertAction(title: "Edit", style: .default) {
            self.editSRT(popover:popover,tableView:tableView,indexPath:indexPath)
        }
//        edit.backgroundColor = UIColor.cyan//controlBlue()
        
        actions.append(edit)
        
        return actions.count > 0 ? actions : nil
    }

    func keywordAlertActions(viewController:UIViewController,tableView:UITableView,completion:((PopoverTableViewController)->(Void))?) -> AlertAction?
    {
        guard let purpose = purpose else {
            return nil
        }
        
        var prefix:String!
        
        switch purpose {
        case Purpose.audio:
            prefix = Constants.FA.AUDIO
            
        case Purpose.video:
            prefix = Constants.FA.VIDEO
            
        default:
            prefix = ""
            break
        }
        
        var action : AlertAction!
        
        action = AlertAction(title: prefix + "\n" + Constants.Strings.List, style: .default) {
            
//            let sourceView = self.view // cell.subviews[0]
//            let sourceRectView = self.controlView! // cell.subviews[0].subviews[actions.index(of: action)!] // memory leak!
            
            var alertActions = [AlertAction]()
            
            alertActions.append(AlertAction(title: "By Keyword", style: .default, action: {
//                print(self.transcriptWords)
                
                if  let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    navigationController.popoverPresentationController?.permittedArrowDirections = [.right,.up]
                    
//                    navigationController.popoverPresentationController?.sourceView = sourceView
//                    navigationController.popoverPresentationController?.sourceRect = sourceRectView.frame
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.vc = viewController
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingKeyword
                    
                    popover.section.showIndex = true
                    //                        popover.section.showHeaders = true
                    
                    popover.section.strings = self.srtTokens?.map({ (string:String) -> String in
                        return string.lowercased()
                    }).sorted()
                    
                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Segment", style: .default, action: {
                if let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    navigationController.popoverPresentationController?.permittedArrowDirections = [.right,.up]
                    
                    //                    navigationController.popoverPresentationController?.sourceView = sourceView
                    //                    navigationController.popoverPresentationController?.sourceRect = sourceRectView.frame
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.vc = viewController
                    popover.search = true
                    
                    popover.editActionsAtIndexPath = self.rowActions
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.parser = { (string:String) -> [String] in
                        var strings = string.components(separatedBy: "\n")
                        while strings.count > 2 {
                            strings.removeLast()
                        }
                        return strings
                    }
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = century
                    popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                        return string
                    }
                    //                        popover.section.showHeaders = true
                    
                    popover.stringsFunction = { (Void) -> [String]? in
                        return self.srtComponents?.filter({ (string:String) -> Bool in
                            return string.components(separatedBy: "\n").count > 1
                        }).map({ (srtComponent:String) -> String in
                            //                            print("srtComponent: ",srtComponent)
                            var srtArray = srtComponent.components(separatedBy: "\n")
                            
                            if srtArray.count > 2  {
                                let count = srtArray.removeFirst()
                                let timeWindow = srtArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = srtComponent.range(of: timeWindow+"\n") {
                                    let text = srtComponent.substring(from: range.upperBound).replacingOccurrences(of: "\n", with: " ")
                                    let string = "\(count)\n\(start) to \(end)\n" + text
                                    
                                    return string
                                }
                            }
                            
                            return "ERROR"
                        })
                    }
                        
                    popover.track = true
                    popover.assist = true
                    
                    viewController.present(navigationController, animated: true, completion: {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Word", style: .default, action: {
                if let navigationController = viewController.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    navigationController.popoverPresentationController?.permittedArrowDirections = [.right,.up]
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.vc = viewController
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = century
                    popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) < Int(second)
                    }
                    popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                        return string
                    }
                    
                    popover.stringsFunction = { (Void) -> [String]? in
                        return self.words?.filter({ (dict:[String:Any]) -> Bool in
                            return dict["w"] != nil
                        }).map({ (dict:[String:Any]) -> String in
                            //                            print("srtComponent: ",srtComponent)
                            
                            if  let position = dict["p"] as? Int,
                                let start = dict["s"] as? Int,
                                let end = dict["e"] as? Int,
                                let word = dict["w"] as? String,
                                let startHMS = secondsToHMS(seconds: "\(Double(start)/1000.0)"),
                                let endHMS = secondsToHMS(seconds: "\(Double(end)/1000.0)") {
                                return "\(position+1)\n\(startHMS) to \(endHMS)\n\(word)"
                            }
                            
                            return "ERROR"
                        })
                    }
                    
                    viewController.present(navigationController, animated: true, completion: {
                        completion?(popover)
                    }) // {self.popover = popover}
                }
            }))
            
            alertActionsCancel( viewController: viewController,
                                title: "Show Timing Index",
                                message: nil,
                                alertActions: alertActions,
                                cancelAction: nil)
        }
        
        return action
    }
}
