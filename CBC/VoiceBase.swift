//
//  VoiceBase.swift
//  CBC
//
//  Created by Steve Leeke on 6/27/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import Speech

extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            append(data)
        }
    }
}

extension VoiceBase // Class Methods
{
//    static var mediaIDs : [String]?
//
//    static func mediaID(search:(id:String?,title:String?,purpose:String?)?,completion:@escaping ([String]?)->(Void))
//    {
//        guard let search = search else {
//            return
//        }
//
//        mediaIDs = [String]()
//
//        func processMediaItem(_ mediaItems : [[String:Any]]?)
//        {
//            guard var mediaItems = mediaItems, mediaItems.count > 0 else {
//                completion(mediaIDs)
//                return
//            }
//
//            let mediaItem = mediaItems.removeFirst()
//
//            guard let title = search.title, let purpose = search.purpose?.lowercased(),
//                let metadata = mediaItem["metadata"] as? [String:Any], (metadata["title"] as? String)?.range(of: title + " (\(purpose))") != nil else {
//                processMediaItem(mediaItems)
//                return
//            }
//
//            guard let mediaID = mediaItem["mediaId"] as? String else {
//                return
//            }
//
//            // Need to check and see if the job status is finished or completed, but that doesn't solve a more fundamental problem of what if an align (or some other operation) is started
//            // by one mediaItem referencing it when/while another is trying to do something else...
//            VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
//                if let media = json?["media"] as? [String:Any], let mediaID = media["mediaId"] as? String {
//                    if let metadata = media["metadata"] as? [String:Any] {
//                        if let mediaItem = metadata["mediaItem"] as? [String:Any] {
//                            if let id = mediaItem["id"] as? String {
//                                if let purpose = (mediaItem["purpose"] as? String)?.uppercased() {
//                                    if search.id == id, search.purpose == purpose {
//                                        mediaIDs?.append(mediaID)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                processMediaItem(mediaItems)
//            }, onError: { (json:[String : Any]?) -> (Void) in
//                processMediaItem(mediaItems)
//            })
//        }
//
//        VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
//            processMediaItem(json?["media"] as? [[String:Any]])
//        },onError: nil)
//    }
    
    static func url(mediaID:String?,path:String?,query:String?) -> String
    {
        if mediaID == nil, path == nil, query == nil {
            return Constants.URL.VOICE_BASE_ROOT + "?limit=1000"
        } else {
            return Constants.URL.VOICE_BASE_ROOT + (mediaID != nil ? "/" + mediaID! : "") + (path != nil ? "/" + path! : "") + (query != nil ? "?" + query! : "")
        }
    }
    
//    static func loadAll()
//    {
//        all(completion: { (json:[String : Any]?) -> (Void) in
//            guard let mediaItems = json?["media"] as? [[String:Any]] else {
//                return
//            }
//
//            for mediaItem in mediaItems {
//                guard let mediaID = mediaItem["mediaId"] as? String else {
//                    continue
//                }
//
////                guard let metadata = mediaItem["metadata"] as? [String:Any] else {
////                    continue
////                }
////
////                guard let mimd = metadata["mediaItem"] as? [String:Any] else {
////                    continue
////                }
////
////                guard let id = mimd["id"] as? String else {
////                    continue
////                }
////
////                guard let purpose = mimd["purpose"] as? String else {
////                    continue
////                }
////
////                guard let mediaItem = globals.mediaRepository.index?[id] else {
////                    continue
////                }
////
////                var transcript : VoiceBase?
////
////                switch purpose.uppercased() {
////                case Purpose.audio:
////                    transcript = mediaItem.audioTranscript
////
////                case Purpose.video:
////                    transcript = mediaItem.videoTranscript
////
////                default:
////                    break
////                }
////
////                if  transcript?.transcript == nil,
////                    transcript?.mediaID == nil,
////                    transcript?.resultsTimer == nil,
////                    let transcribing = transcript?.transcribing, !transcribing {
////                    transcript?.mediaID = mediaID
////                    transcript?.transcribing = true
////
////                    // Should we alert the user to what is being loaded from VB or how many?
////
////                    Thread.onMainThread() {
////                        transcript?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: transcript as Any, selector: #selector(transcript?.monitor(_:)), userInfo: transcript?.uploadUserInfo(alert: false), repeats: true)
////                    }
////                }
//
//                Thread.sleep(forTimeInterval: 5.0) // in lieu of serializing the calls.
//
//                VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
////                    print(json)
//
//                    guard let media = json?["media"] as? [String:Any] else {
//                        return
//                    }
//
//                    guard let metadata = media["metadata"] as? [String:Any] else {
//                        return
//                    }
//
//                    guard let mimd = metadata["mediaItem"] as? [String:Any] else {
//                        return
//                    }
//
//                    guard let id = mimd["id"] as? String else {
//                        return
//                    }
//
//                    guard let purpose = mimd["purpose"] as? String else {
//                        return
//                    }
//
//                    guard let mediaItem = globals.mediaRepository.index?[id] else {
//                        return
//                    }
//
//                    var transcript : VoiceBase?
//
//                    switch purpose.uppercased() {
//                    case Purpose.audio:
//                        transcript = mediaItem.audioTranscript
//
//                    case Purpose.video:
//                        transcript = mediaItem.videoTranscript
//
//                    default:
//                        break
//                    }
//
//                    if  transcript?.transcript == nil,
//                        transcript?.mediaID == nil,
//                        transcript?.resultsTimer == nil,
//                        let transcribing = transcript?.transcribing, !transcribing {
//                        transcript?.mediaID = mediaID
//                        transcript?.transcribing = true
//
//                        // Should we alert the user to what is being loaded from VB or how many?
//
//                        Thread.onMainThread() {
//                            transcript?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: transcript as Any, selector: #selector(transcript?.monitor(_:)), userInfo: transcript?.uploadUserInfo(alert: false,detailedAlerts:false), repeats: true)
//                        }
//                    }
//                }, onError: { (json:[String : Any]?) -> (Void) in
//
//                })
//            }
//        }, onError: { (json:[String : Any]?) -> (Void) in
//
//        })
//    }
    
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
                                if let count = stats[status] {
                                    stats[status] = count + 1
                                } else {
                                    stats[status] = 1
                                }
                            }
                        }
                        
                        for key in stats.keys {
                            if let value = stats[key] {
                                htmlString = htmlString + "\(key): \(value)\n"
                            }
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
                        htmlString = htmlString + "Model Name: \(modelName)\n"
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
    
    static func get(accept:String?,mediaID:String?,path:String?,query:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard globals.isVoiceBaseAvailable == nil || globals.isVoiceBaseAvailable! else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:path, query:query)) else {
            return
        }

        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        if let accept = accept {
            request.addValue(accept, forHTTPHeaderField: "Accept")
        }
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: mediaID ?? UUID().uuidString)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
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
            
            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8)

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string as Any]
                } else {
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        
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
            } else {
                completion?(json)
            }
        })
        
        task.resume()
    }
    
    static func metadata(mediaID: String?, completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept: nil, mediaID: mediaID, path: "metadata", query: nil, completion: completion, onError: onError)
    }

    static func progress(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: "progress", query: nil, completion: completion, onError: onError)
    }
    
    static func details(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: nil, query: nil, completion: completion, onError: onError)
    }

    static func all(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: nil, path: nil, query: nil, completion: completion, onError: onError)
    }
    
    static func delete(mediaID:String?)
    {
        print("VoiceBase.delete")

        guard globals.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:nil, query:nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: mediaID)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
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
            
            if let data = data, data.count > 0 {
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
        
        get(accept: nil, mediaID: nil, path: nil, query: nil, completion: { (json:[String : Any]?) -> (Void) in
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
            var transcriptPurpose = "ERROR"
            
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
                        mediaItemString = "\(mediaItemString)\"title\":\"\(title)\"," // .replacingOccurrences(of: "\n", with: " ")
                    }
            
                    if let text = mediaItem.text {
                        mediaItemString = "\(mediaItemString)\"text\":\"\(text) (\(transcriptPurpose))\"," // .replacingOccurrences(of: "\n", with: " ")
                    }
                    
                    if let scripture = mediaItem.scripture {
                        mediaItemString = "\(mediaItemString)\"scripture\":\"\(scripture.description)\","
                    }
                    
                    if let speaker = mediaItem.speaker {
                        mediaItemString = "\(mediaItemString)\"speaker\":\"\(speaker)\","
                    }
                    
                    mediaItemString = "\(mediaItemString)\"purpose\":\"\(transcriptPurpose)\""
            
                mediaItemString = "\(mediaItemString)},"
            
                mediaItemString = "\(mediaItemString)\"device\":{"
                
                    mediaItemString = "\(mediaItemString)\"name\":\"\(UIDevice.current.deviceName)\","
                    
                    mediaItemString = "\(mediaItemString)\"model\":\"\(UIDevice.current.localizedModel)\","
                    
                    mediaItemString = "\(mediaItemString)\"modelName\":\"\(UIDevice.current.modelName)\","
        
                    if let uuid = UIDevice.current.identifierForVendor?.description {
                        mediaItemString = "\(mediaItemString)\"UUID\":\"\(uuid)\""
                    }
        
                mediaItemString = "\(mediaItemString)}"
        
            mediaItemString = "\(mediaItemString)}"
        
        mediaItemString = "\(mediaItemString)}"
        
        return mediaItemString
    }
    
    var mediaID:String?
    {
        didSet {
            guard mediaID != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["mediaID."+purpose] = mediaID
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var completed = false
    {
        didSet {
            guard completed != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["completed."+purpose] = completed ? "YES" : "NO"

            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var transcribing = false
    {
        didSet {
            guard transcribing != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["transcribing."+purpose] = transcribing ? "YES" : "NO"
        }
    }
    
    var aligning = false
    {
        didSet {
            guard aligning != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["aligning."+purpose] = aligning ? "YES" : "NO"
        }
    }
    
    var percentComplete:String?
    {
        didSet {
//            print(percentComplete)
        }
    }
    
    var uploadJSON:[String:Any]?
    
    var resultsTimer:Timer?
    
    var url:String? {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            switch purpose {
            case Purpose.video:
                return mediaItem?.mp4
                
            case Purpose.audio:
                return mediaItem?.audio
                
            default:
                return nil
            }
        }
    }
    
    var fileSystemURL:URL? {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            switch purpose {
            case Purpose.video:
                return mediaItem?.videoDownload?.fileSystemURL
                
            case Purpose.audio:
                return mediaItem?.audioDownload?.fileSystemURL
                
            default:
                return nil
            }
        }
    }
    
    func markedFullHTML(searchText:String?,wholeWordsOnly:Bool,index:Bool) -> String?
    {
        guard (stripHead(fullHTML) != nil) else {
            return nil
        }
        
//        guard let headerHTML = mediaItem?.headerHTML else {
//            return nil
//        }
        
        guard let searchText = searchText, !searchText.isEmpty else {
            return fullHTML
        }
        
//        guard let headerHTML = mediaItem?.headerHTML else {
//            return html
//        }
        
        var markCounter = 0
        
        func mark(_ input:String) -> String
        {
            var string = input
            
            var stringBefore:String = Constants.EMPTY_STRING
            var stringAfter:String = Constants.EMPTY_STRING
            var newString:String = Constants.EMPTY_STRING
            var foundString:String = Constants.EMPTY_STRING
            
            while (string.lowercased().range(of: searchText.lowercased()) != nil) {
                guard let range = string.lowercased().range(of: searchText.lowercased()) else {
                    break
                }
                
                stringBefore = string.substring(to: range.lowerBound)
                stringAfter = string.substring(from: range.upperBound)
                
                var skip = false
                
                if wholeWordsOnly {
                    if stringBefore == "" {
                        if  let characterBefore:Character = newString.last,
                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                                skip = true
                            }
                            
                            if searchText.count == 1 {
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                    skip = true
                                }
                            }
                        }
                    } else {
                        if  let characterBefore:Character = stringBefore.last,
                            let unicodeScalar = UnicodeScalar(String(characterBefore)) {
                            if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                                skip = true
                            }
                            
                            if searchText.count == 1 {
                                if CharacterSet(charactersIn: Constants.SINGLE_QUOTES + "'").contains(unicodeScalar) {
                                    skip = true
                                }
                            }
                        }
                    }
                    
                    if  let characterAfter:Character = stringAfter.first,
                        let unicodeScalar = UnicodeScalar(String(characterAfter)) {
                        if !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        } else {
//                            if characterAfter == "." {
//                                if let afterFirst = stringAfter.substring(from: String(characterAfter).endIndex).first,
//                                    let unicodeScalar = UnicodeScalar(String(afterFirst)) {
//                                    if !CharacterSet.whitespacesAndNewlines.contains(unicodeScalar) && !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters).contains(unicodeScalar) {
//                                        skip = true
//                                    }
//                                }
//                            }
                        }
                        
//                            print(characterAfter)
                        
                        // What happens with other types of apostrophes?
                        if stringAfter.endIndex >= "'s".endIndex {
                            if (stringAfter.substring(to: "'s".endIndex) == "'s") {
                                skip = true
                            }
                            if (stringAfter.substring(to: "'t".endIndex) == "'t") {
                                skip = true
                            }
                            if (stringAfter.substring(to: "'d".endIndex) == "'d") {
                                skip = true
                            }
                        }
                    }
                    if let characterBefore:Character = stringBefore.last {
                        if let unicodeScalar = UnicodeScalar(String(characterBefore)),
                            !CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars).contains(unicodeScalar) {
                            skip = true
                        }
                    }
                }
                
                foundString = string.substring(from: range.lowerBound)
                if let newRange = foundString.lowercased().range(of: searchText.lowercased()) {
                    foundString = foundString.substring(to: newRange.upperBound)
                } else {
                    // ???
                }
                
                if !skip {
                    markCounter += 1
                    foundString = "<mark>" + foundString + "</mark><a id=\"\(markCounter)\" name=\"\(markCounter)\" href=\"#locations\"><sup>\(markCounter)</sup></a>"
                }
                
                newString = newString + stringBefore + foundString
                
                stringBefore = stringBefore + foundString
                
                string = stringAfter
            }
            
            newString = newString + stringAfter
            
            return newString == Constants.EMPTY_STRING ? string : newString
        }

        var newString:String = Constants.EMPTY_STRING
        var string:String = html
        
        while let searchRange = string.range(of: "<") {
            let searchString = string.substring(to: searchRange.lowerBound)
            //            print(searchString)
            
            // mark search string
            newString = newString + mark(searchString.replacingOccurrences(of: "&nbsp;", with: " "))
            
            let remainder = string.substring(from: searchRange.lowerBound)
            
            if let htmlRange = remainder.range(of: ">") {
                let html = remainder.substring(to: htmlRange.upperBound)
                //                print(html)
                
                newString = newString + html
                
                string = remainder.substring(from: htmlRange.upperBound)
            }
        }
        
        var indexString:String!
        
        if markCounter > 0 {
            indexString = "<a id=\"locations\" name=\"locations\">Occurrences</a> of \"\(searchText)\": \(markCounter)<br/>"
        } else {
            indexString = "<a id=\"locations\" name=\"locations\">No occurrences</a> of \"\(searchText)\" were found.<br/>"
        }
        
        // If we want an index of links to the occurrences of the searchText.
        if index {
            if markCounter > 0 {
                indexString = indexString + "<div>Locations: "
                
                for counter in 1...markCounter {
                    if counter > 1 {
                        indexString = indexString + ", "
                    }
                    indexString = indexString + "<a href=\"#\(counter)\">\(counter)</a>"
                }
                
                indexString = indexString + "<br/><br/></div>"
            }
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if index {
            htmlString = htmlString + indexString
        }
        
        htmlString = htmlString + headerHTML + newString + "</body></html>"

        return insertHead(htmlString,fontSize: Constants.FONT_SIZE)
    }
    
    var headerHTML : String {
        if  var headerHTML = self.mediaItem?.headerHTML,
            let purpose = self.purpose {
            headerHTML = headerHTML +
                "<br/>" +
                "<center>MACHINE GENERATED TRANSCRIPT<br/>(\(purpose))</center>" +
                "<br/>"
            return headerHTML
        }
        
        return "NO MEDIAITEM HEADER"
    }
    
    var fullHTML : String {
        var htmlString = "<!DOCTYPE html><html><body>"

        if  let transcript = self.transcript {
            htmlString = htmlString + headerHTML +
                transcript.replacingOccurrences(of: "\n", with: "<br/>")
        }
        
        htmlString = htmlString + "</body></html>"

        return htmlString
    }
    
    var html : String {
        get {
            var htmlString = "<!DOCTYPE html><html><body>"
            
            if  let transcript = self.transcript {
                htmlString = transcript.replacingOccurrences(of: "\n", with: "<br/>")
            }
            
            htmlString = htmlString + "</body></html>"
            
            return htmlString
        }
    }
    
    var settingTimer = false // Prevents a background thread from creating multiple timers accidentally by accessing transcript before the timer creation on the main thread is complete.
    
    var transcript:String?
    {
        get {
            guard (_transcript == nil) else {
                return _transcript
            }
            
            guard mediaID != nil else {
                return nil
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            if completed {
                if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose)") {
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
            }

            if !completed && transcribing && !aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread() {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()  // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                if self.resultsTimer != nil {
                    print("TIMER NOT NIL!")
                }
            }

            if completed && !transcribing && aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread() {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()  // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                if self.resultsTimer != nil {
                    print("TIMER NOT NIL!")
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

            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            if _transcript != nil {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose)") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try self?._transcript?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8)
                        } catch let error as NSError {
                            print("failed to write transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose)") {
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
                return transcript._transcript != nil // self._
            }).count == 0 {
                // This blocks this thread until it finishes.
                globals.queue.sync {
                    mediaItem.removeTag("Machine Generated Transcript")
                }
            } else {
                // This blocks this thread until it finishes.
                globals.queue.sync {
                    mediaItem.addTag("Machine Generated Transcript")
                }
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
            
            var start : Int?
            var end : Int?
            
            if var words = words, words.count > 0 {
                while words.count > 0 {
                    let word = words.removeFirst()
                    
                    segment = word["w"] as? String
                    
                    start = word["s"] as? Int
                    end = word["e"] as? Int
                    
                    while (segment != nil), ((transcript?.components(separatedBy: segment!).count > 2) || (segment?.components(separatedBy: " ").count < 10) || (words.first?["m"] != nil)) && (words.count > 0) {
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
                        
                        end = word["e"] as? Int
                    }
                    
                    segment = segment?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    if let start = start, let end = end, let segment = segment {
                        var dict:[String:Any] = ["start":Double(start) / 1000.0,"end":Double(end) / 1000.0,"text":segment]
                        if let range = transcript?.range(of: segment) {
                            dict["lowerBound"] = range.lowerBound.encodedOffset
                            dict["upperBound"] = range.upperBound.encodedOffset
                        } else {
                            print("")
                        }
                        following.append(dict)
                    }
                    
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
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(id).\(purpose).media"), let data = try? Data(contentsOf: url) {
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
            
            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            //            guard completed else {
            //                return
            //            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                let fileManager = FileManager.default
                
                if self?._mediaJSON != nil {
                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: self?._mediaJSON as Any, format: .xml, options: 0)
                    
                    if let destinationURL = cachesURL()?.appendingPathComponent("\(id).\(purpose).media") {
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
                    if let destinationURL = cachesURL()?.appendingPathComponent("\(id).\(purpose).media") {
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
            return mediaJSON?["keywords"] as? [String:Any]
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
                return key.uppercased()
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
    
    var tokens : [String:Int]?
    {
        get {
            guard let words = words else {
                return nil
            }
            
            var tokens = [String:Int]()
            
            for word in words {
                if let text = (word["w"] as? String)?.uppercased(), !text.isEmpty, (Int(text) == nil) && !CharacterSet(charactersIn:text).intersection(CharacterSet(charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZ")).isEmpty && CharacterSet(charactersIn:text).intersection(CharacterSet(charactersIn:".")).isEmpty {
                    if let count = tokens[text] {
                        tokens[text] = count + 1
                    } else {
                        tokens[text] = 1
                    }
                }
            }
            
            return tokens.count > 0 ? tokens : nil
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
            
            return transcript?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) //?.replacingOccurrences(of: ".   ", with: ".  ")
        }
    }
    
    var topicsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["topics"] as? [String:Any]
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

        if let mediaID = mediaItem.mediaItemSettings?["mediaID."+purpose] {
            self.mediaID = mediaID
            
            if let completed = mediaItem.mediaItemSettings?["completed."+purpose] {
                self.completed = (completed == "YES") // && (mediaID != nil)
            }
            
            if let transcribing = mediaItem.mediaItemSettings?["transcribing."+purpose] {
                self.transcribing = (transcribing == "YES") // && (mediaID != nil)
            }
            
            if let aligning = mediaItem.mediaItemSettings?["aligning."+purpose] {
                self.aligning = (aligning == "YES") // && (mediaID != nil)
            }
        }
    }
    
    deinit {
        
    }
    
    func createBody(parameters: [String: String],boundary: String) -> NSData
    {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            switch key {
//            case "transcript":
//                if let id = mediaItem?.id { // , let data = value.data(using: String.Encoding.utf8)
//                    let mimeType = "text/plain"
//                    body.appendString(boundaryPrefix)
//                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(id)\"\r\n")
//                    body.appendString("Content-Type: \(mimeType)\r\n\r\n")
//                    body.appendString(value)
//                    body.appendString("\r\n")
//                }
//                break
                
                // This works, but uploading the file takes A LOT longer than the URL!
//            case "media":
//                if let purpose = purpose, let id = mediaItem?.id {
//                    var mimeType : String?
//
//                    switch purpose {
//                    case Purpose.audio:
//                        mimeType = "audio/mpeg"
//                        break
//
//                    case Purpose.video:
//                        mimeType = "video/mp4"
//                        break
//
//                    default:
//                        break
//                    }
//
//                    if let mimeType = mimeType, let url = URL(string: value), let audioData = try? Data(contentsOf: url) {
//                        body.appendString(boundaryPrefix)
//                        body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(id)\"\r\n")
//                        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
//                        body.append(audioData)
//                        body.appendString("\r\n")
//                    }
//                }
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
        guard globals.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let parameters = parameters else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:path, query:nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createBody(parameters: parameters,boundary: boundary)
        
        request.httpBody = body as Data
        request.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: self.mediaItem?.id != nil ? self.mediaItem!.id + self.transcriptPurpose : (mediaID ?? UUID().uuidString))
        sessionConfig.timeoutIntervalForRequest = 30.0 * 60.0
        let session = URLSession(configuration: sessionConfig)

        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
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

            if let data = data, data.count > 0 {
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
    
    func userInfo(alert:Bool,detailedAlerts:Bool,
                  finishedTitle:String?,finishedMessage:String?,onFinished:(()->(Void))?,
                  errorTitle:String?,errorMessage:String?,onError:(()->(Void))?) -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                if alert, let finishedTitle = finishedTitle {
                    globals.alert(title: finishedTitle,message: finishedMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onFinished?()
            } else {
                if let progress = json?["progress"] as? [String:Any] {
                    if let tasks = progress["tasks"] as? [String:Any] {
                        let count = tasks.count
                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                            if let dict = value as? [String:Any] {
                                if let status = dict["status"] as? String {
                                    return (status == "finished") || (status == "completed")
                                }
                            }
                            
                            return false
                        }).count
                        
                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                        
                        if let title = self.mediaItem?.title, let percentComplete = self.percentComplete {
                            print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
                        }
                    }
                }
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                if alert, let errorTitle = errorTitle {
                    globals.alert(title: errorTitle,message: (errorMessage ?? "") + "\n\nError: \(error)")
                }
                
                onError?()
            } else {
                if let text = self.mediaItem?.text {
                    print("An unknown error occured while monitoring the transcription of \n\n\(text).")
                } else {
                    print("An unknown error occured while monitoring a transcription.")
                }
            }
        }
        
        return userInfo.count > 0 ? userInfo : nil
    }
    
    func uploadUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcription Completed", finishedMessage: "The transcription process for\n\n\(text) (\(self.transcriptPurpose))\n\nhas completed.", onFinished: {
                            self.getTranscript(alert:detailedAlerts) {
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {
                                        self.transcribing = false
                                        self.completed = true
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcription Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again.", onError: {
                            self.remove()
                            
                            Thread.onMainThread() {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
                            }
                        })
        
//        var userInfo = [String:Any]()
//
//        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
//            if let status = json?["status"] as? String, status == "finished" {
//                if alert, let text = self.mediaItem?.text {
//                    globals.alert(title: "Transcription Completed",message: "The transcription process for\n\n\(text) (\(self.transcriptPurpose))\n\nhas completed.")
//                }
//
//                self.resultsTimer?.invalidate()
//                self.resultsTimer = nil
//
//                self.percentComplete = nil
//
//                self.getTranscript(alert:detailedAlerts) {
//                    self.getTranscriptSegments(alert:detailedAlerts) {
//                        self.details(alert:detailedAlerts) {
//                            self.transcribing = false
//                            self.completed = true
//                        }
//                    }
//                }
//            } else {
//                if let progress = json?["progress"] as? [String:Any] {
//                    if let tasks = progress["tasks"] as? [String:Any] {
//                        let count = tasks.count
//                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
//                            if let dict = value as? [String:Any] {
//                                if let status = dict["status"] as? String {
//                                    return (status == "finished") || (status == "completed")
//                                }
//                            }
//
//                            return false
//                        }).count
//
//                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
//
//                        if let title = self.mediaItem?.title, let percentComplete = self.percentComplete {
//                            print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
//                        }
//                    }
//                }
//            }
//        }
//
//        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
//            var error : String?
//
//            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
//                error = message
//            }
//
//            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
//                error = message
//            }
//
//            if let error = error {
//                self.remove()
//
//                var message : String?
//
//                if let text = self.mediaItem?.text {
//                    message = "Error: \(error)\n\n" + "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again."
//                } else {
//                    message = "Error: \(error)\n\n" + "The transcript was not completed.  Please try again."
//                }
//
//                if let message = message {
//                    globals.alert(title: "Transcript Failed",message: message)
//                }
//
//                Thread.onMainThread() {
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
//                }
//            } else {
//                if let text = self.mediaItem?.text {
//                    print("An unknown error occured while monitoring the transcription of \n\n\(text).")
//                } else {
//                    print("An unknown error occured while monitoring a transcription.")
//                }
//            }
//        }
//
//        return userInfo.count > 0 ? userInfo : nil
    }
    
    func uploadNotAccepted(_ json:[String:Any]?)
    {
        var error : String?
        
        if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
            error = message
        }
        
        if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
            error = message
        }
        
        var message : String?
        
        if let text = self.mediaItem?.text {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            } else {
                message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            }
        } else {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript failed to start.  Please try again."
            } else {
                message = "The transcript failed to start.  Please try again."
            }
        }
        
        if let message = message {
            globals.alert(title: "Transcription Failed",message: message)
        }
    }
    
    func upload()
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        let parameters:[String:String] = ["mediaUrl":url,"metadata":self.metadata,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
        
        post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            self.uploadJSON = json
            
            if let status = json?["status"] as? String, status == "accepted" {
                if let mediaID = json?["mediaId"] as? String {
                    self.mediaID = mediaID
                    
                    if let text = self.mediaItem?.text {
                        globals.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been started.  You will be notified when it is complete.")
                    }
                    
                    if self.resultsTimer == nil {
                        Thread.onMainThread() {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                }
            } else {
                // Not accepted.
                self.transcribing = false
                
                self.uploadNotAccepted(json)
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.transcribing = false
            
            self.uploadNotAccepted(json)
            
            Thread.onMainThread() {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        })
    }
    
    func progress(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept:nil, mediaID: mediaID, path: "progress", query: nil, completion: completion, onError: onError)
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
        guard globals.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
//        let service = VoiceBase.url(mediaID:mediaID, path:nil)
        //        print(service)

        guard let url = URL(string: VoiceBase.url(mediaID:mediaID, path:nil, query: nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: self.mediaItem?.id != nil ? self.mediaItem!.id + self.transcriptPurpose : mediaID)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
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
                        self.mediaID = nil
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
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
        transcriptSegments = nil
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

    func details(alert:Bool, atEnd:(()->())?)
    {
        details(completion: { (json:[String : Any]?) -> (Void) in
            if let json = json?["media"] as? [String:Any] {
                self.mediaJSON = json
                if alert, let text = self.mediaItem?.text {
                    globals.alert(title: "Keywords Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    globals.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
                }
            }

            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                globals.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
            } else {
                globals.alert(title: "Keywords Not Available",message: "The keywords are not available.")
            }

            atEnd?()
        })
    }
    
    func metadata(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept: nil, mediaID: mediaID, path: "metadata", query: nil, completion: completion, onError: onError)
    }
    
    func addMetaData()
    {
        let parameters:[String:String] = ["metadata":metadata,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
        
        post(path: "metadata", parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            
        }, onError: { (json:[String : Any]?) -> (Void) in
            
        })
    }
    
    func alignUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }

        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Realignment Complete", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been realigned.", onFinished: {
                            // Get the new versions.
                            self.getTranscript(alert:detailedAlerts) {
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {
                                        self.aligning = false
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcript Alignment Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.", onError: {
                            self.remove()
                        })
        
//        var userInfo = [String:Any]()
//
//        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
//            if let status = json?["status"] as? String, status == "finished" {
//                if alert, let text = self.mediaItem?.text {
//                    globals.alert(title: "Transcript Realignment Complete",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been realigned.")
//                }
//
//                self.percentComplete = nil
//
//                self.resultsTimer?.invalidate()
//                self.resultsTimer = nil
//
//                // Don't do this because we're just re-uploading
//                //                                self.transcribing = false
//                //                                self.completed = true
//
////                // These will NOT delete the existing versions.
////                self._transcript = nil
////                self._transcriptSegments = nil
//
//                // Get the new versions.
//                self.getTranscript(alert:detailedAlerts) {
//                    self.getTranscriptSegments(alert:detailedAlerts) {
//                        self.details(alert:detailedAlerts) {
//                            self.aligning = false
//                        }
//                    }
//                }
//
////                // This will NOT delete the existing versions.
////                self._mediaJSON = nil
//            } else {
//                if let progress = json?["progress"] as? [String:Any] {
//                    if let tasks = progress["tasks"] as? [String:Any] {
//                        let count = tasks.count
//                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
//                            if let dict = value as? [String:Any] {
//                                if let status = dict["status"] as? String {
//                                    return (status == "finished") || (status == "completed")
//                                }
//                            }
//
//                            return false
//                        }).count
//
//                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
//
//                        if let title = self.mediaItem?.title, let percentComplete = self.percentComplete {
//                            print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
//                        }
//                    }
//                }
//            }
//        }
//
//        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
//            var error : String?
//
//            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
//                error = message
//            }
//
//            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
//                error = message
//            }
//
//            if let error = error {
//                self.remove()
//
//                var message : String?
//
//                if let text = self.mediaItem?.text {
//                    message = "Error: \(error)\n\n" + "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again."
//                } else {
//                    message = "Error: \(error)\n\n" + "The transcript was not realigned.  Please try again."
//                }
//
//                if let message = message {
//                    globals.alert(title: "Transcript Alignment Failed",message: message)
//                }
//            } else {
//                if let text = self.mediaItem?.text {
//                    print("An error occured while monitoring the alignment of the transcript for\n\n\(text) (\(self.transcriptPurpose))")
//                } else {
//                    print("An error occured while monitoring the alignment of a transcript")
//                }
//            }
//        }
//
//        return userInfo.count > 0 ? userInfo : nil
    }

    func realignmentNotAccepted(_ json:[String:Any]?)
    {
        var error : String?
        
        if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
            error = message
        }
        
        if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
            error = message
        }
        
        var message : String?
        
        if let text = self.mediaItem?.text {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            } else {
                message = "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            }
        } else {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript realignment failed to start.  Please try again."
            } else {
                message = "The transcript realignment failed to start.  Please try again."
            }
        }
        
//        if let message = message {
//            globals.alert(title: "Transcript Alignment Failed",message: message)
//        }
//
//        var error : String?
//
//        if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
//            error = message
//        }
//
//        if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
//            error = message
//        }
//
//        var message : String?
//
//        if let text = self.mediaItem?.text {
//            if let error = error {
//                message = "Error: \(error)\n\n" + "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//            } else {
//                message = "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//            }
//        } else {
//            if let error = error {
//                message = "Error: \(error)\n\n" + "The transcript realignment failed to start.  Please try again."
//            } else {
//                message = "The transcript realignment failed to start.  Please try again."
//            }
//        }

        if let message = message {
            globals.alert(title: "Transcript Alignment Failed",message: message)
        }
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
            if let text = self.mediaItem?.text {
                globals.alert(title:"Transcript Alignment in Progress", message:"The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis already being aligned.  You will be notified when it is completed.")
            }
            return
        }
        
        aligning = true

        // WHY are we calling progress?  To see if the media is on VB.
        progress(completion: { (json:[String : Any]?) -> (Void) in
            let parameters:[String:String] = ["transcript":transcript,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
            
            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                // If it is on VB, upload the transcript for realignment
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        guard self.mediaID == mediaID else {
                            self.aligning = false
                            
                            self.resultsTimer?.invalidate()
                            self.resultsTimer = nil
                            
                            self.realignmentNotAccepted(json)

                            return
                        }

                        // Don't do this because we're just re-aligning.
//                        self.transcribing = true
//                        self.completed = false
                        
                        if let text = self.mediaItem?.text {
                            globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                        }
                        
                        if self.resultsTimer == nil {
                            Thread.onMainThread() {
                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                            }
                        } else {
                            print("TIMER NOT NIL!")
                        }
                    }
                } else {
                    // Not accepted
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.realignmentNotAccepted(json)
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false

                self.resultsTimer?.invalidate()
                self.resultsTimer = nil

                self.realignmentNotAccepted(json)
            })
        }, onError: { (json:[String : Any]?) -> (Void) in
            guard let url = self.url else {
                // Alert?
                return
            }
            
            // Not on VoiceBase
            
//            VoiceBase.mediaID(search: (id: self.mediaItem?.id, title: self.mediaItem?.text, purpose: self.purpose), completion: { (mediaIDs:[String]?) -> (Void) in
//                guard mediaIDs?.count > 0 else {
            
            if let text = self.mediaItem?.text {
                globals.alert(title:"Media Not on VoiceBase", message:"The media for\n\n\(text) (\(self.transcriptPurpose))\n\nis not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript realignment is started.")
            } else {
                globals.alert(title:"Media Not on VoiceBase", message:"The media is not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript realignment is started.")
            }
            
            // Upload then align
            self.mediaID = nil
            
            let parameters:[String:String] = ["media":url,"metadata":self.metadata,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
            
            self.post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        // We do get a new mediaID
                        self.mediaID = mediaID
                        
                        if let text = self.mediaItem?.text {
                            globals.alert(title:"Media Upload Started", message:"The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be started once the media upload has completed.")
                        }
                        
//                        var userInfo = [String:Any]()
//
//                        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
//                            if let status = json?["status"] as? String, status == "finished" {
//                                self.percentComplete = nil
//
//                                self.resultsTimer?.invalidate()
//                                self.resultsTimer = nil
//
//                                // Don't do any of this since we are just re-uploading.
//                                //                                self.transcribing = false
//                                //                                self.completed = true
//                                //
//                                //                                // These will delete the existing versions.
//                                //                                self.transcript = nil
//                                //                                self.transcriptSegments = nil
//                                //
//                                //                                // Really should compare the old and new version...
//                                //
//                                //                                // Get the new versions.
//                                //                                self.getTranscript()
//                                //                                self.getTranscriptSegments()
//                                //
//                                //                                // Delete the transcripts, keywords, and topics.
//                                //                                self.mediaJSON = nil
//                                //
//                                //                                // Get the new ones.
//                                //                                self.details()
//
//                                // Now do the relignment
//                                let parameters:[String:String] = ["transcript":transcript,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
//
//                                self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
//                                    self.uploadJSON = json
//
//                                    // If it is on VB, upload the transcript for realignment
//                                    if let status = json?["status"] as? String, status == "accepted" {
//                                        if let mediaID = json?["mediaId"] as? String {
//                                            guard self.mediaID == mediaID else {
//                                                self.aligning = false
//
//                                                self.resultsTimer?.invalidate()
//                                                self.resultsTimer = nil
//
//                                                self.realignmentNotAccepted(json)
//
//                                                return
//                                            }
//
//                                            // Don't do this because we're just re-aligning.
//                                            //                        self.transcribing = true
//                                            //                        self.completed = false
//
//                                            self.aligning = true
//
//                                            if let text = self.mediaItem?.text {
//                                                globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
//                                            }
//
//                                            if self.resultsTimer == nil {
//                                                Thread.onMainThread() {
//                                                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                                                }
//                                            } else {
//                                                print("TIMER NOT NIL!")
//                                            }
//                                        }
//                                    } else {
//                                        // Not accepted.
//                                        self.aligning = false
//
//                                        self.resultsTimer?.invalidate()
//                                        self.resultsTimer = nil
//
//                                        self.realignmentNotAccepted(json)
//                                    }
//                                }, onError: { (json:[String : Any]?) -> (Void) in
//                                    self.aligning = false
//
//                                    self.resultsTimer?.invalidate()
//                                    self.resultsTimer = nil
//
//                                    self.realignmentNotAccepted(json)
//                                })
//                            } else {
//                                if let progress = json?["progress"] as? [String:Any] {
//                                    if let tasks = progress["tasks"] as? [String:Any] {
//                                        let count = tasks.count
//                                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
//                                            if let dict = value as? [String:Any] {
//                                                if let status = dict["status"] as? String {
//                                                    return (status == "finished") || (status == "completed")
//                                                }
//                                            }
//
//                                            return false
//                                        }).count
//
//                                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
//
//                                        if let title = self.mediaItem?.title, let percentComplete = self.percentComplete {
//                                            print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
//                                        }
//                                    }
//                                }
//                            }
//                        }
//
//                        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
//                            self.aligning = false
//
//                            self.resultsTimer?.invalidate()
//                            self.resultsTimer = nil
//
//                            self.realignmentNotAccepted(json)
//                        }
                        
                        if self.resultsTimer == nil {
                            let newUserInfo = self.userInfo(alert: false, detailedAlerts: false,
                                                    finishedTitle: nil, finishedMessage: nil, onFinished: {
                                                        // Now do the relignment
                                                        let parameters:[String:String] = ["transcript":transcript,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
                                                        
                                                        self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                                                            self.uploadJSON = json
                                                            
                                                            // If it is on VB, upload the transcript for realignment
                                                            if let status = json?["status"] as? String, status == "accepted" {
                                                                if let mediaID = json?["mediaId"] as? String {
                                                                    guard self.mediaID == mediaID else {
                                                                        self.aligning = false
                                                                        
                                                                        self.resultsTimer?.invalidate()
                                                                        self.resultsTimer = nil
                                                                        
                                                                        self.realignmentNotAccepted(json)
                                                                        
                                                                        return
                                                                    }
                                                                    
                                                                    // Don't do this because we're just re-aligning.
                                                                    //                        self.transcribing = true
                                                                    //                        self.completed = false
                                                                    
                                                                    self.aligning = true
                                                                    
                                                                    if let text = self.mediaItem?.text {
                                                                        globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                                                                    }
                                                                    
                                                                    if self.resultsTimer == nil {
                                                                        Thread.onMainThread() {
                                                                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                                        }
                                                                    } else {
                                                                        print("TIMER NOT NIL!")
                                                                    }
                                                                }
                                                            } else {
                                                                // Not accepted.
                                                                self.aligning = false
                                                                
                                                                self.resultsTimer?.invalidate()
                                                                self.resultsTimer = nil
                                                                
                                                                self.realignmentNotAccepted(json)
                                                            }
                                                        }, onError: { (json:[String : Any]?) -> (Void) in
                                                            self.aligning = false
                                                            
                                                            self.resultsTimer?.invalidate()
                                                            self.resultsTimer = nil
                                                            
                                                            self.realignmentNotAccepted(json)
                                                        })
                                                    },
                                                    errorTitle: nil, errorMessage: nil, onError: {
                                                        self.aligning = false
                                                        self.realignmentNotAccepted(json)
                                                    })
                            
                            Thread.onMainThread() {
                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: newUserInfo, repeats: true)
                            }
                        } else {
                            print("TIMER NOT NIL!")
                        }
                    } else {
                        // No media ID???
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.realignmentNotAccepted(json)
                    }
                } else {
                    // Not accepted.
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.realignmentNotAccepted(json)
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.realignmentNotAccepted(json)
            })
            
//                    return
//                }
//
//                // Got valid mediaID
//
//                self.mediaID = mediaIDs?.first // BUT what if it isn't finished?  WORSE: What if the other mediaItem referencing it starts an align later?  OR tries?
//
//                let parameters:[String:String] = ["transcript":transcript,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
//
//                self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
//                    self.uploadJSON = json
//
//                    // If it is on VB, upload the transcript for realignment
//                    if let status = json?["status"] as? String, status == "accepted" {
//                        if let mediaID = json?["mediaId"] as? String {
//                            guard self.mediaID == mediaID else {
//                                self.aligning = false
//                                self.resultsTimer?.invalidate()
//                                self.resultsTimer = nil
//
//                                var error : String?
//
//                                if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
//                                    error = message
//                                }
//
//                                if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
//                                    error = message
//                                }
//
//                                var message : String?
//
//                                if let text = self.mediaItem?.text {
//                                    if let error = error {
//                                        message = "Error: \(error)\n\n" + "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//                                    } else {
//                                        message = "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//                                    }
//                                } else {
//                                    if let error = error {
//                                        message = "Error: \(error)\n\n" + "The transcript realignment failed to start.  Please try again."
//                                    } else {
//                                        message = "The transcript realignment failed to start.  Please try again."
//                                    }
//                                }
//
//                                if let message = message {
//                                    globals.alert(title: "Transcript Alignment Failed",message: message)
//                                }
//
//                                return
//                            }
//
//                            // Don't do this because we're just re-aligning.
//                            //                        self.transcribing = true
//                            //                        self.completed = false
//
//                            if let text = self.mediaItem?.text {
//                                globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
//                            }
//
//                            if self.resultsTimer == nil {
//                                Thread.onMainThread() {
//                                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true), repeats: true)
//                                }
//                            } else {
//                                print("TIMER NOT NIL!")
//                            }
//                        }
//                    } else {
//                        // Not accepted
//
//                    }
//                }, onError: { (json:[String : Any]?) -> (Void) in
//                    self.aligning = false
//                    self.resultsTimer?.invalidate()
//                    self.resultsTimer = nil
//
//                    var error : String?
//
//                    if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
//                        error = message
//                    }
//
//                    if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
//                        error = message
//                    }
//
//                    var message : String?
//
//                    if let text = self.mediaItem?.text {
//                        if let error = error {
//                            message = "Error: \(error)\n\n" + "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//                        } else {
//                            message = "The transcript realignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
//                        }
//                    } else {
//                        if let error = error {
//                            message = "Error: \(error)\n\n" + "The transcript realignment failed to start.  Please try again."
//                        } else {
//                            message = "The transcript realignment failed to start.  Please try again."
//                        }
//                    }
//
//                    if let message = message {
//                        globals.alert(title: "Transcript Alignment Failed",message: message)
//                    }
//                })
//            })
            
        })
    }
    
    func getTranscript(alert:Bool, atEnd:(()->())?)
    {
        guard let mediaID = mediaID else {
            upload()
            return
        }
        
        VoiceBase.get(accept:"text/plain",mediaID: mediaID, path: "transcripts/latest", query: nil, completion: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                print(error)
            }
            
            if let text = json?["text"] as? String {
                self.transcript = text

                if alert, let text = self.mediaItem?.text {
                    globals.alert(title: "Transcript Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
                
                Thread.onMainThread() {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                }
            } else {
                if let error = error {
                    if alert, let text = self.mediaItem?.text {
                        globals.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.\n\nError: \(error)")
                    }
                } else {
                    if alert, let text = self.mediaItem?.text {
                        globals.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
                    }
                }
            }
            
            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            var message : String?
            
            if let text = self.mediaItem?.text {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcription of\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
                } else {
                    message = "The transcription of\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
                }
            } else {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcription failed to start.  Please try again."
                } else {
                    message = "The transcription failed to start.  Please try again."
                }
            }
            
            if let message = message {
                globals.alert(title: "Transcription Failed",message: message)
            }
            
            atEnd?()
        })
    }
    
    var transcriptSegmentArrays:[[String]]?
    {
        get {
            guard _transcriptSegmentArrays == nil else {
                return _transcriptSegmentArrays
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentArrays
        }
        set {
            _transcriptSegmentArrays = newValue
        }
    }
    
    var _transcriptSegmentArrays:[[String]]?
    {
        didSet {
            guard let transcriptSegmentArrays = _transcriptSegmentArrays else {
                return
            }
            
            var tokenTimes = [String:[String]]()
            
            for transcriptSegmentArray in transcriptSegmentArrays {
                if let times = transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray), let startTime = times.first {
                    if let tokens = tokensFromString(transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)) {
                        for token in tokens {
                            let key = token //.lowercased()
                            
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
            
            transcriptSegmentTokensTimes = tokenTimes.count > 0 ? tokenTimes : nil
        }
    }
    
    var transcriptSegmentTokens : [String]?
    {
        return transcriptSegmentTokensTimes?.keys.sorted()
    }
    
    func transcriptSegmentTokenTimes(token:String) -> [String]?
    {
        return transcriptSegmentTokensTimes?[token]
    }
    
    var transcriptSegmentTokensTimes : [String:[String]]?
    {
        get {
            guard _transcriptSegmentTokensTimes == nil else {
                return _transcriptSegmentTokensTimes
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentTokensTimes
        }
        set {
            _transcriptSegmentTokensTimes = newValue
        }
    }
    
    var _transcriptSegmentTokensTimes : [String:[String]]?
    {
        didSet {
            
        }
    }
    
    func transcriptSegmentArrayStartTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.first)
    }
    
    func transcriptSegmentArrayEndTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.last)
    }
    
    func transcriptSegmentArrayIndex(transcriptSegmentArray:[String]?) -> String?
    {
        if let count = transcriptSegmentArray?.first {
            return count
        } else {
            return nil
        }
    }
    
    func transcriptSegmentArrayTimes(transcriptSegmentArray:[String]?) -> [String]?
    {
        guard let transcriptSegmentArray = transcriptSegmentArray else {
            return nil
        }
        
        guard transcriptSegmentArray.count > 1 else {
            return nil
        }
        
        var array = transcriptSegmentArray
        
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
    
    func transcriptSegmentArrayText(transcriptSegmentArray:[String]?) -> String?
    {
        guard let transcriptSegmentArray = transcriptSegmentArray else {
            return nil
        }
        
        guard transcriptSegmentArray.count > 1 else {
            return nil
        }
        
        var string = String()
        
        var array = transcriptSegmentArray
        
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
    
    func searchTranscriptSegmentArrays(string:String) -> [[String]]?
    {
        guard let transcriptSegmentArrays = transcriptSegmentArrays else {
            return nil
        }
        
        var results = [[String]]()
        
        for transcriptSegmentArray in transcriptSegmentArrays {
            if let contains = transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)?.contains(string.lowercased()), contains {
                results.append(transcriptSegmentArray)
            }
        }
        
        return results.count > 0 ? results : nil
    }
    
    var transcriptSegmentComponents:[String]?
    {
        get {
            guard _transcriptSegmentComponents == nil else {
                return _transcriptSegmentComponents
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentComponents
        }
        set {
            _transcriptSegmentComponents = newValue
        }
    }
    
    var _transcriptSegmentComponents:[String]?
    {
        didSet {
            guard let transcriptSegmentComponents = _transcriptSegmentComponents else {
                return
            }
            
            var transcriptSegmentArrays = [[String]]()
            
            for transcriptSegmentComponent in transcriptSegmentComponents {
                transcriptSegmentArrays.append(transcriptSegmentComponent.components(separatedBy: "\n"))
            }
            
            self.transcriptSegmentArrays = transcriptSegmentArrays.count > 0 ? transcriptSegmentArrays : nil
        }
    }
    
    var transcriptSegments:String?
    {
        get {
            guard completed else {
                return nil
            }
            
            guard _transcriptSegments == nil else {
                return _transcriptSegments
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            //Legacy
            if let url = cachesURL()?.appendingPathComponent("\(id).\(purpose).srt") {
                do {
                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
                    //                    if completed && !aligning {
                    //                        remove()
                    //                    }
                }
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(id).\(purpose).segments") {
                do {
                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
                    //                    if completed && !aligning {
                    //                        remove()
                    //                    }
                }
            }
            
            return _transcriptSegments
        }
        
        set {
            guard let mediaItem = mediaItem else {
                return
            }
            
            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            var changed = false
            
            var value = newValue
            
            if _transcriptSegments == nil {
                // Why do we do this?  To strip any header like SRT or WebVTT and remove newlines and add separator
                if var transcriptSegmentComponents = value?.components(separatedBy: "\n\n") {
                    for transcriptSegmentComponent in transcriptSegmentComponents {
                        var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                        if transcriptSegmentArray.count > 2 {
                            let count = transcriptSegmentArray.removeFirst()
                            let timeWindow = transcriptSegmentArray.removeFirst()
                            
                            if let range = transcriptSegmentComponent.range(of: timeWindow + "\n") {
                                let text = transcriptSegmentComponent.substring(from: range.upperBound).replacingOccurrences(of: "\n", with: " ")
                                
                                if let index = transcriptSegmentComponents.index(of: transcriptSegmentComponent) {
                                    transcriptSegmentComponents[index] = "\(count)\n\(timeWindow)\n" + text
                                    changed = true
                                }
                            }
                        }
                    }
                    if changed { // Essentially guaranteed to happen.
                        value = nil
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            let transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            if transcriptSegmentArray.count > 2 { // This removes anything w/o text, i.e. only count and timeWindow - or less, like a header, e.g. WebVTT (a nice side effect)
                                value = (value != nil ? value! + VoiceBase.separator : "") + transcriptSegmentComponent
                            }
                        }
                    }
                }
            }
            
            _transcriptSegments = value
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                let fileManager = FileManager.default
                
                if self?._transcriptSegments != nil {
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose).segments") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated segment transcript: \(error.localizedDescription)")
                            }
                        }
                        
                        do {
                            try self?._transcriptSegments?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8);
                        } catch let error as NSError {
                            print("failed to write segment transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                    
                    //Legacy clean-up
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose).srt") {
                        // Check if file exist
                        if (fileManager.fileExists(atPath: destinationURL.path)){
                            do {
                                try fileManager.removeItem(at: destinationURL)
                            } catch let error as NSError {
                                print("failed to remove machine generated segment transcript: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                } else {
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose).segments") {
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
                    
                    //Legacy clean-up
                    if let destinationURL = cachesURL()?.appendingPathComponent(id+".\(purpose).srt") {
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
    
    var _transcriptSegments:String?
    {
        didSet {
            transcriptSegmentComponents = _transcriptSegments?.components(separatedBy: VoiceBase.separator)
            //            print(transcriptSegmentComponents)
        }
    }
    
    var transcriptSegmentsFromWords:String?
    {
        get {
            var str : String?
            
            if let following = following {
                var count = 1
                var transcriptSegmentComponents = [String]()
                
                for element in following {
                    if  let start = element["start"] as? Double,
                        let startSeconds = secondsToHMS(seconds: "\(start)"),
                        let end = element["end"] as? Double,
                        let endSeconds = secondsToHMS(seconds: "\(end)"),
                        let text = element["text"] as? String {
                        transcriptSegmentComponents.append("\(count)\n\(startSeconds) --> \(endSeconds)\n\(text)")
                    }
                    count += 1
                }

                for transcriptSegmentComponent in transcriptSegmentComponents {
                    str = (str != nil ? str! + VoiceBase.separator : "") + transcriptSegmentComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptSegmentsFromTranscriptSegments:String?
    {
        get {
            var str : String?
            
            if let transcriptSegmentComponents = transcriptSegmentComponents {
                for transcriptSegmentComponent in transcriptSegmentComponents {
                    str = (str != nil ? str! + VoiceBase.separator : "") + transcriptSegmentComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptFromTranscriptSegments:String?
    {
        get {
            var str : String?
            
            if let transcriptSegmentComponents = transcriptSegmentComponents {
                for transcriptSegmentComponent in transcriptSegmentComponents {
                    var strings = transcriptSegmentComponent.components(separatedBy: "\n")
                    
                    if strings.count > 2 {
                        _ = strings.removeFirst() // count
                        let timing = strings.removeFirst() // time
                        
                        if let range = transcriptSegmentComponent.range(of:timing+"\n") {
                            let string = transcriptSegmentComponent.substring(from:range.upperBound)
                            str = (str != nil ? str! + " " : "") + string
                        }
                    }
                }
            }
            
            return str
        }
    }
    
    func getTranscriptSegments(alert:Bool, atEnd:(()->())?)
    {
        VoiceBase.get(accept: "text/vtt", mediaID: mediaID, path: "transcripts/latest", query: nil, completion: { (json:[String : Any]?) -> (Void) in
            if let transcriptSegments = json?["text"] as? String {
                self._transcriptSegments = nil // Without this the new transcript segments will not be processed correctly.

                self.transcriptSegments = transcriptSegments

                if alert, let text = self.mediaItem?.text {
                    globals.alert(title: "Transcript Segments Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    globals.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
                }
            }
            
            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                globals.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
            } else {
                globals.alert(title: "Transcript Segments Not Available",message: "The transcript segments is not available.")
            }
            
            atEnd?()
        })
    }
    
    func search(string:String?)
    {
        guard globals.reachability.isReachable else {
            return
        }
        
        guard globals.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let string = string else {
            return
        }
        
        var service = VoiceBase.url(mediaID: nil, path: nil, query: nil)
        service = service + "?query=" + string
        
        guard let url = URL(string:service) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        //        request.addValue("text/plain", forHTTPHeaderField: "Accept")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: self.mediaItem?.id != nil ? self.mediaItem!.id + self.transcriptPurpose : (mediaID ?? UUID().uuidString))
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
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
            
            if let data = data, data.count > 0 {
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
                self.getTranscript(alert: true) {
                    self.getTranscriptSegments(alert: true) {
                        self.details(alert: true) {
                            if let text = self.mediaItem?.text {
                                globals.alert(title: "Transcript Reload Complete",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been reloaded from VoiceBase.")
                            }
                        }
                    }
                }
            } else {
                if let progress = json?["progress"] as? [String:Any] {
                    if let tasks = progress["tasks"] as? [String:Any] {
                        let count = tasks.count
                        let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                            if let dict = value as? [String:Any] {
                                if let status = dict["status"] as? String {
                                    return (status == "finished") || (status == "completed")
                                }
                            }
                            
                            return false
                        }).count
                        
                        self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                        
                        if let title = self.mediaItem?.title, let percentComplete = self.percentComplete {
                            print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
                        }
                    }
                }
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            self.remove()
            
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            var message : String?
            
            if let text = self.mediaItem?.text {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again."
                } else {
                    message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again."
                }
            } else {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcript was not realigned.  Please try again."
                } else {
                    message = "The transcript was not realigned.  Please try again."
                }
            }
            
            if let message = message {
                globals.alert(title: "Transcript Alignment Failed",message: message)
            }
        }
        
        return userInfo.count > 0 ? userInfo : nil
    }
    
//    var recognitionTask : Any?
    
    func setModalStyle(viewController:UIViewController,navigationController:UINavigationController)
    {
        if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
            let hClass = viewController.traitCollection.horizontalSizeClass
            
            if hClass == .compact {
                navigationController.modalPresentationStyle = .overFullScreen
            } else {
                // I don't think this ever happens: collapsed and regular
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
            }
        } else {
            if viewController.splitViewController?.displayMode == .primaryHidden {
                if !UIApplication.shared.isRunningInFullScreen() {
                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                } else {
                    let vClass = viewController.traitCollection.verticalSizeClass
                    
                    if vClass == .compact {
                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                    } else {
                        navigationController.modalPresentationStyle = .formSheet // Used to be .popover
                    }
                }
            } else {
                if !UIApplication.shared.isRunningInFullScreen() {
                    if let _ = viewController as? MediaTableViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
                    } else {
                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                    }
                } else {
                    if let _ = viewController as? MediaTableViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
                    } else {
                        let vClass = viewController.traitCollection.verticalSizeClass
                        
                        if vClass == .compact {
                            navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
                        } else {
                            navigationController.modalPresentationStyle = .formSheet // Used to be .popover
                        }
                    }
                }
            }
            
            //                            let vClass = viewController.traitCollection.verticalSizeClass
            //
            //                            if vClass == .compact {
            //                                navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
            //                            } else {
            //                                if viewController.splitViewController?.displayMode == .primaryHidden {
            //                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
            //                                } else {
            //                                    if !UIApplication.shared.isRunningInFullScreen() {
            //                                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
            //                                    } else {
            //                                        navigationController.modalPresentationStyle = .formSheet //.overCurrentContext // Used to be .popover
            //                                    }
            //                                }
            //                            }
            
            //                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            //                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
        }
    }
    
    func recognizeAlertActions(viewController:UIViewController) -> AlertAction? // ,tableView:UITableView
    {
        guard let purpose = purpose else {
            return nil
        }
        
        guard let text = mediaItem?.text else {
            return nil
        }
        
        func mgtUpdate()
        {
            let completion = " (\(transcriptPurpose))" + (percentComplete != nil ? "\n(\(percentComplete!)% complete)" : "")
            
            var title = "Machine Generated Transcript "
            
            var message = "You will be notified when the machine generated transcript for\n\n\(text)\(completion) "
            
            if (mediaID != nil) {
                title = title + "in Progress"
                message = message + "\n\nis available."
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Media ID", style: .default, handler: {
                    let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                    message: text + " (\(self.transcriptPurpose))",
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    alert.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = self.mediaID
                    })
                    
                    let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction) -> Void in
                    })
                    alert.addAction(okayAction)
                    
                    viewController.present(alert, animated: true, completion: nil)
                }))
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                
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
                guard globals.reachability.isReachable else {
                    networkUnavailable(viewController,"Machine generated transcript unavailable.")
                    return
                }
                
                if !self.transcribing {
                    if globals.reachability.isReachable {
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .default, handler: {
                            self.getTranscript(alert: true) {}
//                            tableView.setEditing(false, animated: true)
                            mgtUpdate()
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, handler: nil))
                        
                        if let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Begin Creating\nMachine Generated Transcript?",
                                                message: "\(text) (\(self.transcriptPurpose))",
                                alertActions: alertActions,
                                cancelAction: nil)
                        }
                    } else {
                        networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                    }
                } else {
                    mgtUpdate()
                }
            } else {
                var alertActions = [AlertAction]()
                
                alertActions.append(AlertAction(title: "View", style: .default, handler: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Transcript", style: .default, handler: {
                        if self.transcript == self.transcriptFromWords {
                            print("THEY ARE THE SAME!")
                        }
                        
                        // APPLE only allows 60 seconds of audio to be recognized! Thank You God for VoiceBase!
//                        if #available(iOS 10.0, *) {
//                            SFSpeechRecognizer.requestAuthorization { authStatus in
//                                switch authStatus {
//                                case .authorized:
//                                    if let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), speechRecognizer.isAvailable, let url = self.fileSystemURL, FileManager.default.fileExists(atPath: url.path) {
//                                        let recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
//                                        recognitionRequest.shouldReportPartialResults = false
//                                        recognitionRequest.taskHint = .dictation
//                                        recognitionRequest.interactionIdentifier = self.mediaItem?.id
//
//                                        speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
//                                            if let error = error {
//                                                print("There was an problem: \(error)")
//                                            } else {
//                                                if let result = result {
//                                                    if result.isFinal {
//                                                        print(result.bestTranscription.formattedString)
//                                                    }
//                                                }
//                                            }
//                                        })
//                                    }
//                                    break
//
//                                case .denied:
//                                    globals.alert(title: "Speech Recognition Not Allowed", message: nil)
//
//                                case .restricted, .notDetermined:
//                                    globals.alert(title: "Could not start the speech recognizer", message: "Check your internect connection and try again")
//                                }
//                            }
//                        } else {
//                            // Fallback on earlier versions
//                        }

                        popoverHTML(viewController,mediaItem:nil,transcript:self,title:self.mediaItem?.title,barButtonItem:nil,sourceView:nil,sourceRectView:nil,htmlString:self.fullHTML)
                    }))
                    
                    alertActions.append(AlertAction(title: "Transcript with Timing", style: .default, handler: {
                        process(viewController: viewController, work: { [weak self] () -> (Any?) in
                            var htmlString = "<!DOCTYPE html><html><body>"
                            
                            var transcriptSegmentHTML = String()
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<table>"
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<tr style=\"vertical-align:bottom;\"><td><b>#</b></td><td><b>Start Time</b></td><td><b>End Time</b></td><td><b>Recognized Speech</b></td></tr>"
                            //  valign=\"bottom\"
                            if let transcriptSegmentComponents = self?.transcriptSegmentComponents {
                                for transcriptSegmentComponent in transcriptSegmentComponents {
                                    var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                                    
                                    if transcriptSegmentArray.count > 2  {
                                        let count = transcriptSegmentArray.removeFirst()
                                        let timeWindow = transcriptSegmentArray.removeFirst()
                                        let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
                                        
                                        if  let start = times.first,
                                            let end = times.last,
                                            let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                            let text = transcriptSegmentComponent.substring(from: range.upperBound)
                                            
                                            let row = "<tr style=\"vertical-align:top;\"><td>\(count)</td><td>\(start)</td><td>\(end)</td><td>\(text.replacingOccurrences(of: "\n", with: " "))</td></tr>"
                                            //  valign=\"top\"
                                            transcriptSegmentHTML = transcriptSegmentHTML + row
                                        }
                                    }
                                }
                            }
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "</table>"

                            htmlString = htmlString + (self?.headerHTML ?? "") + transcriptSegmentHTML + "</body></html>"

//                            if  let purpose = self.purpose,
//                                let headerHTML = self.mediaItem?.headerHTML {
//                                        "<br/>" +
//                                        "<center>MACHINE GENERATED TRANSCRIPT WITH TIMING<br/>(\(purpose))</center>" +
//                                        "<br/>" +
//                            }
                            
                            return htmlString as Any
                        }, completion: { [weak self] (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(viewController,mediaItem:nil,title:self?.mediaItem?.title,barButtonItem:nil,sourceView:nil,sourceRectView:nil,htmlString:htmlString)
                            }
                        })
                    }))

                    alertActionsCancel( viewController: viewController,
                                        title: "View",
                                        message: "This is a machine generated transcript for \n\n\(text) (\(self.transcriptPurpose))\n\nIt may lack proper formatting and have signifcant errors.",
                                        alertActions: alertActions,
                                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Edit", style: .default, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete, let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                        let textPopover = navigationController.viewControllers[0] as? TextViewController {
//                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        self.setModalStyle(viewController:viewController,navigationController:navigationController)
                        
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate

                        textPopover.navigationController?.isNavigationBarHidden = false
                        
                        textPopover.navigationItem.title = self.mediaItem?.title // "Edit Text"
                        
                        let text = self.transcript
                        
                        textPopover.transcript = self // Must come before track
                        textPopover.track = true
                        
                        textPopover.text = text
                        
                        textPopover.assist = true
                        textPopover.search = true
                        
//                            textPopover.confirmation = { ()->Bool in
//                                return true // self.transcript == self.transcriptFromTranscriptSegments
//                            }
//                            textPopover.confirmationTitle = "Confirm Saving Changes to Transcript"
//                            textPopover.confirmationMessage = "If you save these changes and later change a transcript element, the transcript may be overwritten and your changes lost."

                        textPopover.completion = { (text:String) -> Void in
                            guard text != textPopover.text else {
                                return
                            }
                            
                            self.transcript = text
                        }
                        
                        viewController.present(navigationController, animated: true, completion: {
                            globals.topViewController = navigationController
                        })
                    } else {
                        print("ERROR")
                    }
                }))
                
                alertActions.append(AlertAction(title: "Media ID", style: .default, handler: {
                    let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                    message: text + " (\(self.transcriptPurpose))",
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    alert.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = self.mediaID
                    })
                    
                    let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction) -> Void in
                    })
                    alert.addAction(okayAction)
                    
                    viewController.present(alert, animated: true, completion: nil)
                }))
                
                if globals.isVoiceBaseAvailable ?? false {
                    alertActions.append(AlertAction(title: "Check VoiceBase", style: .default, handler: {
                        self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: "Yes", style: .destructive, handler: { (Void) -> (Void) in
                                        VoiceBase.delete(mediaID: self.mediaID)
                                    }))
                                    
                                    actions.append(AlertAction(title: "No", style: .default, handler:nil))
                                    
                                    globals.alert(title:"Confirm Removal From VoiceBase", message:text, actions:actions)
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                globals.alert(title:"On VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis on VoiceBase.", actions:actions)
                            }
                        }, onError:  { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                globals.alert(title:"Not on VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis not on VoiceBase.", actions:actions)
                            }
                        })
                    }))
                    
                    alertActions.append(AlertAction(title: "Align", style: .destructive, handler: {
                        guard !self.aligning else {
                            if let percentComplete = self.percentComplete, let text = self.mediaItem?.text {
                                alertActionsCancel( viewController: viewController,
                                                    title: "Alignment Underway",
                                                    message: "There is an alignment already underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                    alertActions: nil,
                                    cancelAction: nil)
                            } else {
                                alertActionsCancel( viewController: viewController,
                                                    title: "Alignment Underway",
                                                    message: "There is an alignment already underway.\n\nPlease try again later.",
                                    alertActions: nil,
                                    cancelAction: nil)
                            }
                            return
                        }
                        
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                            var alertActions = [AlertAction]()
                            
                            alertActions.append(AlertAction(title: "Transcript", style: .default, handler: {
                                self.align(self.transcript)
//                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActions.append(AlertAction(title: "Segments", style: .default, handler: {
                                self.align(self.transcriptFromTranscriptSegments)
//                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActions.append(AlertAction(title: "Words", style: .default, handler: {
                                self.align(self.transcriptFromWords)
//                                tableView.setEditing(false, animated: true)
                            }))
                            
                            alertActionsCancel( viewController: viewController,
                                                title: "Select Source for Realignment",
                                                message: text,
                                                alertActions: alertActions,
                                                cancelAction: nil)
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, handler: nil))
                        
                        if let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Confirm Realignment of Machine Generated Transcript",
                                                message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))",
                                alertActions: alertActions,
                                cancelAction: nil)
                        }
                    }))
                }
                
                alertActions.append(AlertAction(title: "Restore", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete, let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Regenerate Transcript", style: .destructive, handler: {
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                            self.transcript = self.transcriptFromWords
                        }))
                        
                        alertActions.append(AlertAction(title: "No", style: .default, handler: nil))
                        
                        if let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Confirm Regeneration of Transcript",
                                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
                                alertActions: alertActions,
                                cancelAction: nil)
                        }
                    }))
                    
                    if globals.isVoiceBaseAvailable ?? false {
                        alertActions.append(AlertAction(title: "Reload from VoiceBase", style: .destructive, handler: {
                            self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                                if let text = self.mediaItem?.text {
                                    var alertActions = [AlertAction]()
                                    
                                    alertActions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                                        globals.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                        
                                        if self.resultsTimer != nil {
                                            print("TIMER NOT NIL!")
                                            
                                            var actions = [AlertAction]()
                                            
                                            actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                            
                                            globals.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                        } else {
                                            Thread.onMainThread() {
                                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(), repeats: true)
                                            }
                                        }
                                    }))
                                    
                                    alertActions.append(AlertAction(title: "No", style: .default, handler: nil))
                                    
                                    if let text = self.mediaItem?.text {
                                        alertActionsCancel( viewController: viewController,
                                                            title: "Confirm Reloading",
                                                            message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
                                            alertActions: alertActions,
                                            cancelAction: nil)
                                    }
                                }
                            }, onError:  { (dict:[String:Any]?)->(Void) in
                                if let text = self.mediaItem?.text {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                    
                                    globals.alert(title:"Not on VoiceBase", message:text + "\nis not on VoiceBase.", actions:actions)
                                }
                            })
                        }))
                    }
                    
                    if let text = self.mediaItem?.text {
                        alertActionsCancel( viewController: viewController,
                                            title: "Restore Options",
                                            message: "\(text) (\(self.transcriptPurpose))",
                            alertActions: alertActions,
                            cancelAction: nil)
                    }
                }))
                
                alertActions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete, let text = self.mediaItem?.text {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Yes", style: .destructive, handler: {
                        self.remove()
//                        tableView.setEditing(false, animated: true)
                    }))
                    
                    alertActions.append(AlertAction(title: "No", style: .default, handler: nil))
                    
                    if let text = self.mediaItem?.text {
                        alertActionsCancel( viewController: viewController,
                                            title: "Confirm Deletion of Machine Generated Transcript",
                                            message: "\(text) (\(self.transcriptPurpose))",
                            alertActions: alertActions,
                            cancelAction: nil)
                    }
                }))
                
                alertActionsCancel(  viewController: viewController,
                                     title: "Machine Generated Transcript",
                    message: text + " (\(self.transcriptPurpose))",
                    alertActions: alertActions,
                    cancelAction: nil)
            }
        }
        
        return action
    }
    
    func editTranscriptSegment(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath)
    {
        editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath,automatic:false,automaticInteractive:false,automaticCompletion:nil)
    }
    
    func editTranscriptSegment(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath,automatic:Bool,automaticInteractive:Bool,automaticCompletion:(()->(Void))?)
    {
        let stringIndex = popover.section.index(indexPath)
        
        guard let string = popover.section.strings?[stringIndex] else {
            return
        }

        let playing = globals.mediaPlayer.isPlaying
        
        globals.mediaPlayer.pause()
        
        var transcriptSegmentArray = string.components(separatedBy: "\n")
        let count = transcriptSegmentArray.removeFirst() // Count
        let timing = transcriptSegmentArray.removeFirst() // Timing
        let transcriptSegmentTiming = timing.replacingOccurrences(of: "to", with: "-->") // Timing // replacingOccurrences(of: ".", with: ",").
        
        if  let first = transcriptSegmentComponents?.filter({ (string:String) -> Bool in
//            print(transcriptSegmentTiming,string)
            return string.contains(transcriptSegmentTiming)
        }).first,
            let navigationController = popover.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
            let textPopover = navigationController.viewControllers[0] as? TextViewController,
            let transcriptSegmentIndex = self.transcriptSegmentComponents?.index(of: first),
            let range = string.range(of:timing+"\n") {
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = popover
            
            Thread.onMainThread {
                textPopover.navigationController?.isNavigationBarHidden = false
                textPopover.navigationItem.title = count // "Edit Text"
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
 
            textPopover.completion = { (text:String) -> Void in
                guard text != textPopover.text else {
                    if playing {
                        globals.mediaPlayer.play()
                    }
                    return
                }
                
                self.transcriptSegmentComponents?[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
                if popover.searchActive {
                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
                }
                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
                
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.transcriptSegments = self?.transcriptSegmentsFromTranscriptSegments
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
            self.editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath)
        }
//        edit.backgroundColor = UIColor.cyan//controlBlue()
        
        actions.append(edit)
        
        return actions.count > 0 ? actions : nil
    }

    func keywordAlertActions(viewController:UIViewController,completion:((PopoverTableViewController)->(Void))?) -> AlertAction? // ,tableView:UITableView
    {
        var action : AlertAction!
        
        action = AlertAction(title: "Timing Index", style: .default) {
            var alertActions = [AlertAction]()
            
            alertActions.append(AlertAction(title: "By Keyword", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//                    navigationController.modalPresentationStyle = .overCurrentContext

                    self.setModalStyle(viewController:viewController,navigationController:navigationController)
                    
//                    if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
//                        let hClass = viewController.traitCollection.horizontalSizeClass
//
//                        if hClass == .compact {
//                            navigationController.modalPresentationStyle = .overFullScreen
//                        } else {
//                            // I don't think this ever happens: collapsed and regular
//                            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
//
//                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                        }
//                    } else {
//                        if viewController.splitViewController?.displayMode == .primaryHidden {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                            } else {
//                                let vClass = viewController.traitCollection.verticalSizeClass
//
//                                if vClass == .compact {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                }
//                            }
//                        } else {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                }
//                            } else {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    let vClass = viewController.traitCollection.verticalSizeClass
//
//                                    if vClass == .compact {
//                                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                    } else {
//                                        navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                    }
//                                }
//                            }
//                        }
//
////                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
////                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                    }

                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.vc = viewController
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingKeyword
                    
                    popover.section.showIndex = true

                    popover.stringsFunction = { (Void) -> [String]? in
                        return self.transcriptSegmentTokens?.map({ (string:String) -> String in
                            return string //.lowercased()
                        }).sorted()
                    }

//                    popover.section.strings = self.transcriptSegmentTokens?.map({ (string:String) -> String in
//                        return string.lowercased()
//                    }).sorted()
                    
                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Segment", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
//                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    self.setModalStyle(viewController:viewController,navigationController:navigationController)
                    
//                    if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
//                        let hClass = viewController.traitCollection.horizontalSizeClass
//
//                        if hClass == .compact {
//                            navigationController.modalPresentationStyle = .overFullScreen
//                        } else {
//                            // I don't think this ever happens: collapsed and regular
//                            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
//
//                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                        }
//                    } else {
//                        if viewController.splitViewController?.displayMode == .primaryHidden {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                            } else {
//                                let vClass = viewController.traitCollection.verticalSizeClass
//
//                                if vClass == .compact {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                }
//                            }
//                        } else {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                }
//                            } else {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    let vClass = viewController.traitCollection.verticalSizeClass
//
//                                    if vClass == .compact {
//                                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                    } else {
//                                        navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                    }
//                                }
//                            }
//                        }
//
//                        //                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                        //                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                    }
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
//                    navigationController.popoverPresentationController?.permittedArrowDirections = [.right,.up]
                    
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
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { (Void) -> [String]? in
                        return self.transcriptSegmentComponents?.filter({ (string:String) -> Bool in
                            return string.components(separatedBy: "\n").count > 1
                        }).map({ (transcriptSegmentComponent:String) -> String in
                            //                            print("transcriptSegmentComponent: ",transcriptSegmentComponent)
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") // 
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                    let text = transcriptSegmentComponent.substring(from: range.upperBound).replacingOccurrences(of: "\n", with: " ")
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
            
            alertActions.append(AlertAction(title: "By Timed Word", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
//                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    self.setModalStyle(viewController:viewController,navigationController:navigationController)
                    
//                    if let isCollapsed = viewController.splitViewController?.isCollapsed, isCollapsed {
//                        let hClass = viewController.traitCollection.horizontalSizeClass
//
//                        if hClass == .compact {
//                            navigationController.modalPresentationStyle = .overFullScreen
//                        } else {
//                            // I don't think this ever happens: collapsed and regular
//                            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
//
//                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                        }
//                    } else {
//                        if viewController.splitViewController?.displayMode == .primaryHidden {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                            } else {
//                                let vClass = viewController.traitCollection.verticalSizeClass
//
//                                if vClass == .compact {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                }
//                            }
//                        } else {
//                            if !UIApplication.shared.isRunningInFullScreen() {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                }
//                            } else {
//                                if let _ = viewController as? MediaTableViewController {
//                                    navigationController.modalPresentationStyle = .overCurrentContext // Used to be .popover
//                                } else {
//                                    let vClass = viewController.traitCollection.verticalSizeClass
//
//                                    if vClass == .compact {
//                                        navigationController.modalPresentationStyle = .overFullScreen // Used to be .popover
//                                    } else {
//                                        navigationController.modalPresentationStyle = .formSheet // Used to be .popover
//                                    }
//                                }
//                            }
//                        }
//
//                        //                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                        //                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
//                    }
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
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
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { (Void) -> [String]? in
                        return self.words?.filter({ (dict:[String:Any]) -> Bool in
                            return dict["w"] != nil
                        }).map({ (dict:[String:Any]) -> String in
//                            print("transcriptSegmentComponent: ",dict)
                            
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
                    })
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
