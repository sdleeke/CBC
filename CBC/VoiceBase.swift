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

extension NSMutableData
{
    func appendString(_ string: String)
    {
        // ABSOLUTELY essential that this stay data8 (i.e. utf8 encoding) because it is used in setting up
        // VB http headers - utf16 will break it.
        if let data = string.data8 { // (using: String.Encoding.utf8, allowLossyConversion: false)
            append(data)
        }
    }
}

extension VoiceBase // Class Methods
{
    static func url(mediaID:String?,path:String?,query:String?) -> String
    {
        if mediaID == nil, path == nil, query == nil {
            return Constants.URL.VOICE_BASE_ROOT + "?limit=1000"
        } else {
            return Constants.URL.VOICE_BASE_ROOT + (mediaID != nil ? "/" + mediaID! : "") + (path != nil ? "/" + path! : "") + (query != nil ? "?" + query! : "")
        }
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
                    if let length = length["milliseconds"] as? Int, let hms = (Double(length) / 1000.0).secondsToHMS {
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
        if !Globals.shared.checkingVoiceBaseAvailability {
            if !(Globals.shared.isVoiceBaseAvailable ?? false){
                return
            }
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
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
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string as Any]
                } else {
                    json = data.json as? [String:Any]
                    
                    if let errors = json?["errors"] {
                        print(errors)
                        errorOccured = true
                    }

//                    do {
//                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//
//                        if let errors = json?["errors"] {
//                            print(errors)
//                            errorOccured = true
//                        }
//                    } catch let error {
//                        // JSONSerialization failed
//                        print("JSONSerialization error: ",error.localizedDescription)
//                    }
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

        guard Globals.shared.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
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
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)

                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }
                
//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                Thread.onMainThread {
                    
                }
            } else {
                Thread.onMainThread {
                    
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
                        Alerts.shared.alert(title: "Deleting \(mediaItems.count) Items from VoiceBase Media Library", message: nil)
                    } else {
                        Alerts.shared.alert(title: "Deleting \(mediaItems.count) Item from VoiceBase Media Library", message: nil)
                    }
                    
                    for mediaItem in mediaItems {
                        delete(mediaID:mediaItem["mediaId"] as? String)
                    }
                } else {
                    Alerts.shared.alert(title: "No Items to Delete in VoiceBase Media Library", message: nil)
                }
            } else {
                // No mediaItems
                Alerts.shared.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
            }
        }, onError:  { (json:[String : Any]?) -> (Void) in
            Alerts.shared.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
        })
    }
}

class VoiceBase {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// VoiceBase API for Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem?
    
    static let separator = "------------"
    
    static let configuration:String? = "{\"configuration\":{\"executor\":\"v2\"}}"
    
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

                default:
                    break
                }
            }
            
            return transcriptPurpose // .lowercased() NO
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
        
            mediaItemString += "\"metadata\":{"
        
                if let text = mediaItem.text {
                    if let mediaID = mediaID {
                        mediaItemString += "\"title\":\"\(text) (\(transcriptPurpose))\n\(mediaID)\","
                    } else {
                        mediaItemString += "\"title\":\"\(text) (\(transcriptPurpose))\","
                    }
                }
        
                mediaItemString += "\"mediaItem\":{"
                
                    if let category = mediaItem.category {
                        mediaItemString += "\"category\":\"\(category)\","
                    }
                    
                    if let id = mediaItem.id {
                        mediaItemString += "\"id\":\"\(id)\","
                    }
                    
                    if let date = mediaItem.date {
                        mediaItemString += "\"date\":\"\(date)\","
                    }
                    
                    if let service = mediaItem.service {
                        mediaItemString += "\"service\":\"\(service)\","
                    }
                    
                    if let title = mediaItem.title {
                        mediaItemString += "\"title\":\"\(title)\","
                    }
            
                    if let text = mediaItem.text {
                        mediaItemString += "\"text\":\"\(text) (\(transcriptPurpose))\","
                    }
                    
                    if let scripture = mediaItem.scripture {
                        mediaItemString += "\"scripture\":\"\(scripture.description)\","
                    }
                    
                    if let speaker = mediaItem.speaker {
                        mediaItemString += "\"speaker\":\"\(speaker)\","
                    }
                    
                    mediaItemString += "\"purpose\":\"\(transcriptPurpose)\""
            
                mediaItemString += "},"
            
                mediaItemString += "\"device\":{"
                
                    mediaItemString += "\"name\":\"\(UIDevice.current.deviceName)\","
                    
                    mediaItemString += "\"model\":\"\(UIDevice.current.localizedModel)\","
                    
                    mediaItemString += "\"modelName\":\"\(UIDevice.current.modelName)\","
        
                    if let uuid = UIDevice.current.identifierForVendor?.description {
                        mediaItemString += "\"UUID\":\"\(uuid)\""
                    }
        
                mediaItemString += "}"
        
            mediaItemString += "}"
        
        mediaItemString += "}"
        
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
            
            Thread.onMainThread {
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

            Thread.onMainThread {
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
            
            if transcribing {
                mediaItem?.addTag(Constants.Strings.Transcribing + " - " + transcriptPurpose)
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcribing + " - " + transcriptPurpose)
            }
        }
    }
    
    var alignmentSource : String?
    
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

        }
    }
    
    var uploadJSON:[String:Any]?
    
    var resultsTimer:Timer?
    {
        didSet {
            
        }
    }
    
    var url:String?
    {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            switch purpose {
            case Purpose.video:
                var mp4 = mediaItem?.mp4
                
                if let range = mp4?.range(of: "&profile_id="), let root = mp4?[..<range.upperBound] {
                    mp4 = root.description + "174"
                }
                
                return mp4
                
            case Purpose.audio:
                return mediaItem?.audio
                
            default:
                return nil
            }
        }
    }
    
    var fileSystemURL:URL?
    {
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
        return "<!DOCTYPE html><html><body>" + headerHTML + bodyHTML + "</body></html>"
    }
    
    var bodyHTML : String {
        get {
            var htmlString = String()
            
            if  let transcript = self.transcript {
                htmlString = transcript.replacingOccurrences(of: "\n", with: "<br/>")
            }

            return htmlString
        }
    }
    
    // Prevents a background thread from creating multiple timers accidentally
    // by accessing transcript before the timer creation on the main thread is complete.
    var settingTimer = false
    
    var filename : String?
    {
        get {
            if let id = mediaItem?.id, let purpose = purpose {
                return id + ".\(purpose).transcript"
            } else {
                return nil
            }
        }
    }
    
    var oldFilename : String?
    {
        get {
            if let id = mediaItem?.id, let purpose = purpose {
                return id + ".\(purpose)"
            } else {
                return nil
            }
        }
    }
    
//    lazy var transcript:Shadowed<String> = {
//        return Shadowed<String>(get: { () -> (String?) in
//            var value:String? = nil
//
//            guard self.mediaID != nil else {
//                return nil
//            }
//
//            guard let mediaItem = self.mediaItem else {
//                return nil
//            }
//
//            guard let id = mediaItem.id else {
//                return nil
//            }
//
//            guard let purpose = self.purpose else {
//                return nil
//            }
//
//            if self.completed {
//                if let destinationURL = self.filename?.fileSystemURL {
//                    do {
//                        try value = String(contentsOfFile: destinationURL.path, encoding: String.Encoding.utf8) // why not utf16?
//                        // This will cause an error.  The tag is created in the constantTags getter while loading.
//                        //                    mediaItem.addTag("Machine Generated Transcript")
//
//                        // Also, the tag would normally be added or removed in the didSet for transcript but didSet's are not
//                        // called during init()'s which is fortunate.
//                    } catch let error {
//                        print("failed to load machine generated transcript for \(self.mediaItem?.description): \(error.localizedDescription)")
//                        self.completed = false
//                        // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                        //                        if !aligning {
//                        //                            remove()
//                        //                        }
//                    }
//                } else {
//                    self.completed = false
//                }
//            }
//
//            if !self.completed && self.transcribing && !self.aligning && (self.resultsTimer == nil) && !self.settingTimer {
//                self.settingTimer = true
//                Thread.onMainThread {
//                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                    self.settingTimer = false
//                }
//            } else {
//                // Overkill to make sure the cloud storage is cleaned-up?
//                //                mediaItem.voicebase?.delete()
//                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
//                if self.resultsTimer != nil {
//                    print("TIMER NOT NIL!")
//                }
//            }
//
//            if self.completed && !self.transcribing && self.aligning && (self.resultsTimer == nil) && !self.settingTimer {
//                self.settingTimer = true
//                Thread.onMainThread {
//                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                    self.settingTimer = false
//                }
//            } else {
//                // Overkill to make sure the cloud storage is cleaned-up?
//                //                mediaItem.voicebase?.delete()
//                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
//                if self.resultsTimer != nil {
//                    print("TIMER NOT NIL!")
//                }
//            }
//
//            return value
//        },
//
////        pre: { () -> (Bool) in
////            if self.mediaID == nil {
////                return false
////            }
////
////            if self.mediaItem == nil {
////                return false
////            }
////
////            if self.mediaItem?.id == nil {
////                return false
////            }
////
////            if self.purpose == nil {
////                return false
////            }
////
////            return true
////        },
//
//        didSet: { (transcript, oldValue) in
//            guard let mediaItem = self.mediaItem else {
//                return
//            }
//
//            if mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
//                return transcript.transcript != nil // self._
//            }).count == 0 {
//                // This blocks this thread until it finishes.
//                Globals.shared.queue.sync {
//                    mediaItem.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + self.transcriptPurpose)
//                }
//            } else {
//                // This blocks this thread until it finishes.
//                Globals.shared.queue.sync {
//                    mediaItem.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + self.transcriptPurpose)
//                }
//            }
//        })
//    }()
    
    private var _transcript:String?
    {
        didSet {
            guard let mediaItem = mediaItem else {
                return
            }

            if mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                return transcript._transcript != nil // self._
            }).count == 0 {
                // This blocks this thread until it finishes.
                Globals.shared.queue.sync {
                    mediaItem.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                }
            } else {
                // This blocks this thread until it finishes.
                Globals.shared.queue.sync {
                    mediaItem.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                }
            }
        }
    }
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
                _transcript = filename?.fileSystemURL?.string16

                if transcript == nil {
                    completed = false
                }
//
//                if let destinationURL = filename?.fileSystemURL {
//                    do {
//                        try _transcript = String(contentsOfFile: destinationURL.path, encoding: String.Encoding.utf8) // why not utf16?
//                        // This will cause an error.  The tag is created in the constantTags getter while loading.
//                        //                    mediaItem.addTag("Machine Generated Transcript")
//
//                        // Also, the tag would normally be added or removed in the didSet for transcript but didSet's are not
//                        // called during init()'s which is fortunate.
//                    } catch let error {
//                        print("failed to load machine generated transcript for \(mediaItem.description): \(error.localizedDescription)")
//                        completed = false
//                        // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                        //                        if !aligning {
//                        //                            remove()
//                        //                        }
//                    }
//                } else {
//                    completed = false
//                }
            }

            if !completed && transcribing && !aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()
                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                if self.resultsTimer != nil {
                    print("TIMER NOT NIL!")
                }
            }

            if completed && !transcribing && aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()
                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
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
                    self?.filename?.fileSystemURL?.delete()
                    self?._transcript?.save16(filename: self?.filename)
                    
//                    if let destinationURL = self?.filename?.fileSystemURL {
//                        destinationURL.delete()
//
//                        do {
//                            try self?._transcript?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8) // why not utf16?
//                        } catch let error {
//                            print("failed to write transcript to cache directory: \(error.localizedDescription)")
//                        }
//                    } else {
//                        print("failed to get destinationURL")
//                    }
                }
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    if let destinationURL = self?.filename?.fileSystemURL {
                        destinationURL.delete()
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var wordRangeTiming : [[String:Any]]?
    {
        get {
            guard let transcript = transcript?.lowercased() else {
                return nil
            }
            
            guard var words = words, words.count > 0 else {
                return nil
            }
            
            var wordRangeTiming = [[String:Any]]()
            
            var offset : String.Index?
        
            var lastEnd : Int?
        
            while words.count > 0 {
                let word = words.removeFirst()
                
                guard let text = (word["w"] as? String)?.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars)), !text.isEmpty else {
                    continue
                }
                
                guard let start = word["s"] as? Int else {
                    continue
                }
                
                guard let end = word["e"] as? Int else {
                    continue
                }
                
                var dict:[String:Any] = ["start":Double(start) / 1000.0, "end":Double(end) / 1000.0, "text":text]
            
                if let lastEnd = lastEnd {
                    dict["gap"] = (Double(start) - Double(lastEnd)) / 1000.0
                }
                    
                lastEnd = end

                if offset == nil {
                    offset = transcript.range(of: text)?.lowerBound
                }
                
                if offset != nil {
                    let startingRange = Range(uncheckedBounds: (lower: offset!, upper: transcript.endIndex))
                    if let range = transcript.range(of: text, options: [], range: startingRange, locale: nil) {
                        dict["range"] = range
                        dict["lowerBound"] = range.lowerBound.encodedOffset
                        dict["upperBound"] = range.upperBound.encodedOffset
                        offset = range.upperBound
                    }
                }

                if let metadata = word["m"] as? String { // , metadata == "punc"
                    print(word["w"],metadata)
                } else {
                    wordRangeTiming.append(dict)
                }
            }
            
            return wordRangeTiming.count > 0 ? wordRangeTiming : nil
        }
    }
    
//    lazy var mediaJSON:Shadowed<[String:Any]> = {
//        return Shadowed<[String:Any]>(
//        get: { () -> ([String : Any]?) in
//            ///// THIS MAY BE A PRE /////
//            guard self.completed else {
//                return nil
//            }
//            /////////////////////////////
//
//            guard let mediaItem = self.mediaItem else {
//                return nil
//            }
//
//            guard let id = mediaItem.id else {
//                return nil
//            }
//
//            guard let purpose = self.purpose else {
//                return nil
//            }
//
//            var value : [String : Any]?
//
//            if let url = ("\(id).\(purpose).media").fileSystemURL, let data = url.data {
//                do {
//                    value = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
//                } catch let error {
//                    print("failed to load machine generated media for \(self.mediaItem?.description): \(error.localizedDescription)")
//
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    //                    if completed && !aligning {
//                    //                        remove()
//                    //                    }
//                }
//            } else {
//                print("failed to open machine generated media for \(self.mediaItem?.description)")
//                // Not sure I want to do this since it only removes keywords
//                //                remove()
//            }
//
//            return value
//        },
//
////        pre: { () -> (Bool) in
////            if !self.completed {
////                return false
////            }
////
////            if self.mediaItem == nil {
////                return false
////            }
////
////            if self.mediaItem?.id == nil {
////                return false
////            }
////
////            if self.purpose == nil {
////                return false
////            }
////
////            return true
////        },
//
//        didSet: { (mediaJSON, oldValue) in
//            guard let mediaItem = self.mediaItem else {
//                return
//            }
//
//            guard let id = mediaItem.id else {
//                return
//            }
//
//            guard let purpose = self.purpose else {
//                return
//            }
//
//            DispatchQueue.global(qos: .background).async { [weak self] in
//                let fileManager = FileManager.default
//
//                if mediaJSON != nil {
//                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: mediaJSON as Any, format: .xml, options: 0)
//
//                    if let destinationURL = "\(id).\(purpose).media".fileSystemURL {
//                        destinationURL.delete()
//
//                        do {
//                            try mediaPropertyList?.write(to: destinationURL)
//                        } catch let error {
//                            print("failed to write machine generated transcript media to cache directory: \(error.localizedDescription)")
//                        }
//                    } else {
//                        print("destinationURL nil!")
//                    }
//                } else {
//                    if let destinationURL = "\(id).\(purpose).media".fileSystemURL {
//                        destinationURL.delete()
//                    } else {
//                        print("failed to get destinationURL")
//                    }
//                }
//            }
//        })
//    }()
    
    private var _mediaJSON : [String:Any]?
    {
        didSet {

        }
    }
    var mediaJSON: [String:Any]?
    {
        get {
            guard completed else {
                return nil
            }

            guard _mediaJSON == nil else {
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
            
            guard let filename = filename else {
                return nil
            }
            
            if let url = ("\(filename).media").fileSystemURL, let data = url.data {
                do {
                    _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                } catch let error {
                    print("failed to load machine generated media for \(mediaItem.description): \(error.localizedDescription)")
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    if completed && !aligning {
//                        remove()
//                    }
                }
            } else {
                print("failed to get data for \(mediaItem.description)")
                
                // Legacy
                if let oldFilename = oldFilename, let url = ("\(oldFilename).media").fileSystemURL, let data = url.data {
                    do {
                        _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                    } catch let error {
                        print("failed to open machine generated media (again) for \(mediaItem.description)")
                    }
                }
                
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

//            guard let id = mediaItem.id else {
//                return
//            }
//
//            guard let purpose = purpose else {
//                return
//            }

            guard let filename = filename else {
                print("failed to get filename")
                return
            }

            guard let destinationURL = "\(filename).media".fileSystemURL else {
                print("failed to get destinationURL")
                return
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                if self?._mediaJSON != nil {
                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: self?._mediaJSON as Any, format: .xml, options: 0)

                    destinationURL.delete()
                    
                    do {
                        try mediaPropertyList?.write(to: destinationURL)
                    } catch let error {
                        print("failed to write machine generated transcript media to cache directory: \(error.localizedDescription)")
                    }
                } else {
                    destinationURL.delete()
                }
            }
        }
    }

    var keywordsJSON: [String:Any]?
    {
        get {
            return mediaJSON?["keywords"] as? [String:Any]
        }
    }
    
    var keywordTimes : [String:[String]]?
    {
        get {
            guard let keywordDictionaries = keywordDictionaries else {
                return nil
            }
            
            var keywordTimes = [String:[String]]()
            
            for name in keywordDictionaries.keys {
                if let dict = keywordDictionaries[name], let speakers = dict["t"] as? [String:Any], let times = speakers["unknown"] as? [String] {
                    keywordTimes[name] = times.map({ (time) -> String in
                        return time.secondsToHMS!
                    })
                }
            }
            
            return keywordTimes.count > 0 ? keywordTimes : nil
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
    
    // Make thread safe?
    var transcriptsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["transcripts"] as? [String:Any]
        }
    }
    
    // Make thread safe?
    var transcriptLatest : [String:Any]?
    {
        get {
            return transcriptsJSON?["latest"] as? [String:Any]
        }
    }
    
    // Make thread safe?
    var tokensAndCounts : [String:Int]?
    {
        get {
            guard let words = words else {
                return nil
            }
            
            var tokens = [String:Int]()
            
            for word in words {
                // This isn't going to handle Greek or Hebrew letters.
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
    
    // Make thread safe?
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
    
    // Make thread safe?
    var topicsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["topics"] as? [String:Any]
        }
    }
    
    // Make thread safe?
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
    
    // Make thread safe?
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
            
            if !completed {
                if transcribing || aligning {
                    // We need to check and see if it is really on VB and if not, clean things up.
                    
                }
            } else {
                if transcribing || aligning {
                    // This seems wrong.
                    
                }
            }
        }
    }
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func createBody(parameters: [String: String],boundary: String) -> NSData
    {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            switch key {
                // This works? But isn't necessary?
//            case "transcript":
//                if let id = mediaItem?.id { // , let data = value.data(using: String.Encoding.utf8) // why not utf16?
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
        guard Globals.shared.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
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
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0 * 60.0
        let session = URLSession(configuration: sessionConfig)

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
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }

            if errorOccured {
                Thread.onMainThread {
                    onError?(json)
                }
            } else {
                Thread.onMainThread {
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
            guard let status = json?["status"] as? String else {
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onError?()
                return
            }

            guard let title = self.mediaItem?.title else {
                return
            }
            
            switch status {
            case "finished":
                if alert, let finishedTitle = finishedTitle {
                    Alerts.shared.alert(title: finishedTitle,message: finishedMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onFinished?()
                break
                
            case "failed":
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onError?()
                break
                
            default:
                guard let progress = json?["progress"] as? [String:Any] else {
                    print("\(title) (\(self.transcriptPurpose)) no progress")
                    break
                }
                
                guard let tasks = progress["tasks"] as? [String:Any] else {
                    print("\(title) (\(self.transcriptPurpose)) no tasks")
                    break
                }
                
                let count = tasks.count
                let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                    if let dict = value as? [String:Any] {
                        if let status = dict["status"] as? String {
                            return (status == "finished") || (status == "completed")
                        }
                    }
                    
                    return false
                }).count
                
                if count > 0 {
                    self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                } else {
                    self.percentComplete = "0"
                }
                
                if let percentComplete = self.percentComplete {
                    print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
                }
                break
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
                    Alerts.shared.alert(title: errorTitle,message: (errorMessage ?? "") + "\n\nError: \(error)")
                }
            } else {
                if let text = self.mediaItem?.text {
                    print("An unknown error occured while monitoring the transcription of \n\n\(text).")
                } else {
                    print("An unknown error occured while monitoring a transcription.")
                }
            }
            
            onError?()
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
                                        
                                        // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
                                        // sure I can predict the context in which this (i.e. that) would happen.
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcription Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again.", onError: {
                            self.remove()
                            
                            Thread.onMainThread {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
                            }
                        })
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
            Alerts.shared.alert(title: "Transcription Failed",message: message)
        }
    }
    
    func upload()
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        var parameters:[String:String] = ["mediaUrl":url,"metadata":self.metadata] //
        
        if let configuration = VoiceBase.configuration {
            parameters["configuration"] = configuration
        }
        
        post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            self.uploadJSON = json
            
            guard let status = json?["status"] as? String else {
                // Not accepted.
                self.transcribing = false
                
                self.uploadNotAccepted(json)
                return
            }
            
            switch status {
            case "accepted":
                guard let mediaID = json?["mediaId"] as? String else {
                    // Not accepted.
                    self.transcribing = false
                    
                    self.uploadNotAccepted(json)
                    break
                }
                
                self.mediaID = mediaID
                
                if let text = self.mediaItem?.text {
                    Alerts.shared.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been started.  You will be notified when it is complete.")
                }
                
                if self.resultsTimer == nil {
                    Thread.onMainThread {
                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    }
                } else {
                    print("TIMER NOT NIL!")
                }
                break
                
            default:
                // Not accepted.
                self.transcribing = false
                
                self.uploadNotAccepted(json)
                break
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.transcribing = false
            
            self.uploadNotAccepted(json)
            
            Thread.onMainThread {
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
        guard Globals.shared.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }

        guard let url = URL(string: VoiceBase.url(mediaID:mediaID, path:nil, query: nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default
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
                        // It eithber completed w/o error (204) so it is now gone and we should set mediaID to nil
                        // OR it couldn't be found (404) in which case it should also be set to nil.

                        // WE DO NOT HAVE TO SET THIS TO NIL.
                        // self.mediaID = nil
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)

                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
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
    
    // Make thread safe?
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
    
    // Make thread safe?
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
                    Alerts.shared.alert(title: "Keywords Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
                }
            }

            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
            } else {
                Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords are not available.")
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
        var parameters:[String:String] = ["metadata":metadata]
        
        if let configuration = VoiceBase.configuration {
            parameters["configuration"] = configuration
        }

        post(path: "metadata", parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            
        }, onError: { (json:[String : Any]?) -> (Void) in
            
        })
    }
    
    // Not possible.  VB introduces errors in capitalization and extraneous spaces
    // Even if we took a sample before or after the string to match to try and put
    // the string in the right place I doubt it could be done as we never know where
    // VB might introduce an error which would cause the match to fail.
    //
    // All a successful relaignment does is make the timing index match the audio.
    // That's it.  The whole transcript from VB will never match the alignment source.
    //
//    func correctAlignedTranscript()
//    {
//        guard let alignmentSource = alignmentSource else {
//            return
//        }
//
//        let string = "\n\n"
//
//        var ranges = [Range<String.Index>]()
//
//        var startingRange = Range(uncheckedBounds: (lower: alignmentSource.startIndex, upper: alignmentSource.endIndex))
//
//        while let range = alignmentSource.range(of: string, options: [], range: startingRange, locale: nil) {
//            ranges.append(range)
//            startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: alignmentSource.endIndex))
//        }
//
//        if var newTranscript = transcript {
//            for range in ranges {
//                let before = String(newTranscript[..<range.lowerBound]).trimmingCharacters(in: CharacterSet(charactersIn: " "))
//                let after = String(newTranscript[range.lowerBound...]).trimmingCharacters(in: CharacterSet(charactersIn: " "))
//                newTranscript = before + string + after
//            }
//            transcript = newTranscript
//        }
//    }
    
    func alignUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }

        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Alignment Complete", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been realigned.", onFinished: {
                            // Get the new versions.
                            self.getTranscript(alert:detailedAlerts) {
//                                self.correctAlignedTranscript()
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {
                                        self.aligning = false
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcript Alignment Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.", onError: {
                            // WHY would we remove when an alignment fails?
//                            self.remove()
                            self.aligning = false
                        })
    }

    func alignmentNotAccepted(_ json:[String:Any]?)
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
                message = "Error: \(error)\n\n" + "The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            } else {
                message = "The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            }
        } else {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript alignment failed to start.  Please try again."
            } else {
                message = "The transcript alignment failed to start.  Please try again."
            }
        }

        if let message = message {
            Alerts.shared.alert(title: "Transcript Alignment Failed",message: message)
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
                Alerts.shared.alert(title:"Transcript Alignment in Progress", message:"The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis already being aligned.  You will be notified when it is completed.")
            }
            return
        }
        
        aligning = true

        // WHY are we calling progress?  To see if the media is on VB.
        progress(completion: { (json:[String : Any]?) -> (Void) in
            var parameters:[String:String] = ["transcript":transcript]
            
            if let configuration = VoiceBase.configuration {
                parameters["configuration"] = configuration
            }
            
            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json

                guard let status = json?["status"] as? String else {
                    // Not accepted
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    return
                }
                
                switch status {
                // If it is on VB, upload the transcript for alignment
                case "accepted":
                    guard let mediaID = json?["mediaId"] as? String else {
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        
                        break
                    }
                    
                    guard self.mediaID == mediaID else {
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        
                        return
                    }
                    
                    self.alignmentSource = transcript
                    
                    // Don't set transcribing to true and completed to false because we're just re-aligning.
                    
                    let title =  "Machine Generated Transcript Alignment Started"
                    
                    var message = "Realigning the machine generated transcript"
                    
                    if let text = self.mediaItem?.text {
                        message += " for\n\n\(text) (\(self.transcriptPurpose))"
                    }
                    
                    message += "\n\nhas started.  You will be notified when it is complete."
                    
                    Alerts.shared.alert(title:title, message:message)
                    
                    if self.resultsTimer == nil {
                        Thread.onMainThread {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                    break
                    
                default:
                    break
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false

                self.resultsTimer?.invalidate()
                self.resultsTimer = nil

                self.alignmentNotAccepted(json)
            })
        }, onError: { (json:[String : Any]?) -> (Void) in
            guard let url = self.url else {
                // Alert?
                return
            }
            
            // Not on VoiceBase
            
            if let text = self.mediaItem?.text {
                Alerts.shared.alert(title:"Media Not on VoiceBase", message:"The media for\n\n\(text) (\(self.transcriptPurpose))\n\nis not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript alignment is started.")
            } else {
                Alerts.shared.alert(title:"Media Not on VoiceBase", message:"The media is not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript alignment is started.")
            }
            
            // Upload then align
            self.mediaID = nil
            
            var parameters:[String:String] = ["media":url,"metadata":self.metadata]
            
            if let configuration = VoiceBase.configuration {
                parameters["configuration"] = configuration
            }

            self.post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                guard let status = json?["status"] as? String else {
                    // Not accepted.
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    return
                }
            
                switch status {
                case "accepted":
                    guard let mediaID = json?["mediaId"] as? String else {
                        // No media ID???
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        break
                    }
                    
                    // We do get a new mediaID
                    self.mediaID = mediaID
                    
                    if let text = self.mediaItem?.text {
                        Alerts.shared.alert(title:"Media Upload Started", message:"The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be started once the media upload has completed.")
                    }
                    
                    if self.resultsTimer == nil {
                        let newUserInfo = self.userInfo(alert: false, detailedAlerts: false,
                                                        finishedTitle: nil, finishedMessage: nil, onFinished: {
                                                            // Now do the relignment
                                                            var parameters:[String:String] = ["transcript":transcript]
                                                            
                                                            if let configuration = VoiceBase.configuration {
                                                                parameters["configuration"] = configuration
                                                            }
                                                            
                                                            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                                                                self.uploadJSON = json

                                                                guard let status = json?["status"] as? String else {
                                                                    // Not accepted.
                                                                    self.aligning = false
                                                                    
                                                                    self.resultsTimer?.invalidate()
                                                                    self.resultsTimer = nil
                                                                    
                                                                    self.alignmentNotAccepted(json)
                                                                    return
                                                                }
                                                                
                                                                switch status {
                                                                // If it is on VB, upload the transcript for alignment
                                                                case "accepted":
                                                                    guard let mediaID = json?["mediaId"] as? String else {
                                                                        // Not accepted.
                                                                        self.aligning = false
                                                                        
                                                                        self.resultsTimer?.invalidate()
                                                                        self.resultsTimer = nil
                                                                        
                                                                        self.alignmentNotAccepted(json)
                                                                        
                                                                        break
                                                                    }
                                                                    
                                                                    guard self.mediaID == mediaID else {
                                                                        // Not accepted.
                                                                        self.aligning = false
                                                                        
                                                                        self.resultsTimer?.invalidate()
                                                                        self.resultsTimer = nil
                                                                        
                                                                        self.alignmentNotAccepted(json)
                                                                        
                                                                        return
                                                                    }
                                                                    
                                                                    // Don't set transcribing to true and completed to false because we're just re-aligning.
                                                                    
                                                                    self.aligning = true
                                                                    
                                                                    if let text = self.mediaItem?.text {
                                                                        Alerts.shared.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                                                                    }
                                                                    
                                                                    if self.resultsTimer == nil {
                                                                        Thread.onMainThread {
                                                                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                                        }
                                                                    } else {
                                                                        print("TIMER NOT NIL!")
                                                                    }
                                                                    break
                                                                    
                                                                default:
                                                                    // Not accepted.
                                                                    self.aligning = false
                                                                    
                                                                    self.resultsTimer?.invalidate()
                                                                    self.resultsTimer = nil
                                                                    
                                                                    self.alignmentNotAccepted(json)
                                                                    break
                                                                }
                                                            }, onError: { (json:[String : Any]?) -> (Void) in
                                                                self.aligning = false
                                                                
                                                                self.resultsTimer?.invalidate()
                                                                self.resultsTimer = nil
                                                                
                                                                self.alignmentNotAccepted(json)
                                                            })
                        },
                                                        errorTitle: nil, errorMessage: nil, onError: {
                                                            self.aligning = false
                                                            self.alignmentNotAccepted(json)
                        })
                        
                        Thread.onMainThread {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: newUserInfo, repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                    break
                    
                default:
                    // Not accepted.
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    break
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.alignmentNotAccepted(json)
            })
        })
    }
    
    func getTranscript(alert:Bool, atEnd:(()->())? = nil)
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
                    Alerts.shared.alert(title: "Transcript Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                }
            } else {
                if let error = error {
                    if alert, let text = self.mediaItem?.text {
                        Alerts.shared.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.\n\nError: \(error)")
                    }
                } else {
                    if alert, let text = self.mediaItem?.text {
                        Alerts.shared.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
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
                Alerts.shared.alert(title: "Transcription Failed",message: message)
            }
            
            atEnd?()
        })
    }
    
    
//    lazy var transcriptSegmentArrays:Shadowed<[[String]]> = {
//        return Shadowed<[[String]]>(get: { () -> ([[String]]?) in
//            let _ = self.transcriptSegments
//        }, didSet: { (transcriptSegmentArrays, oldValue) in
//            guard let transcriptSegmentArrays = transcriptSegmentArrays else {
//                return
//            }
//
//            var tokenTimes = [String:[String]]()
//
//            for transcriptSegmentArray in transcriptSegmentArrays {
//                if let times = self.transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray), let startTime = times.first {
//                    if let tokens = tokensFromString(self.transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)) {
//                        for token in tokens {
//                            let key = token
//
//                            if tokenTimes[key] == nil {
//                                tokenTimes[key] = [startTime]
//                            } else {
//                                if var times = tokenTimes[key] {
//                                    times.append(startTime)
//                                    tokenTimes[key] = Array(Set(times)).sorted()
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//
//            self.transcriptSegmentTokensTimes = tokenTimes.count > 0 ? tokenTimes : nil
//        })
//    }()
    
    private var _transcriptSegmentArrays:[[String]]? // Make thread safe?
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
                            let key = token

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
    var transcriptSegmentArrays:[[String]]? // Make thread safe?
    {
        get {
            guard _transcriptSegmentArrays == nil else {
                return _transcriptSegmentArrays
            }

            // calculation by side-effect - YUK
            let _ = transcriptSegments

            return _transcriptSegmentArrays
        }
        set {
            _transcriptSegmentArrays = newValue
        }
    }
    
    // Make thread safe?
    var transcriptSegmentTokens : [String]?
    {
        return transcriptSegmentTokensTimes?.keys.sorted()
    }
    
    func transcriptSegmentTokenTimes(token:String) -> [String]?
    {
        return transcriptSegmentTokensTimes?[token]
    }
    
    private var _transcriptSegmentTokensTimes : [String:[String]]? // Make thread safe?
    {
        didSet {
            
        }
    }
    var transcriptSegmentTokensTimes : [String:[String]]? // Make thread safe?
    {
        get {
            guard _transcriptSegmentTokensTimes == nil else {
                return _transcriptSegmentTokensTimes
            }
            
            // Calculation by side-effect - YUK
            let _ = transcriptSegments
            
            return _transcriptSegmentTokensTimes
        }
        set {
            _transcriptSegmentTokensTimes = newValue
        }
    }
    
    func transcriptSegmentArrayStartTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.first?.hmsToSeconds
    }
    
    func transcriptSegmentArrayEndTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.last?.hmsToSeconds
    }
    
    func transcriptSegmentArrayIndex(transcriptSegmentArray:[String]?) -> String?
    {
        return transcriptSegmentArray?.first
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
    
    private var _transcriptSegmentComponents:[String]? // Make thread safe?
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
    var transcriptSegmentComponents:[String]? // Make thread safe?
    {
        get {
            guard _transcriptSegmentComponents == nil else {
                return _transcriptSegmentComponents
            }
            
            // Calculation by side-effect - YUK
            let _ = transcriptSegments
            
            return _transcriptSegmentComponents
        }
        set {
            _transcriptSegmentComponents = newValue
        }
    }
    
//    lazy var transcriptSegments:Shadowed<String> = {
//        return Shadowed<String>(get: { () -> (String?) in
//            ///// THIS MAY BE A PRE //////
//            guard self.completed else {
//                return nil
//            }
//            //////////////////////////////
//
//            guard let mediaItem = self.mediaItem else {
//                return nil
//            }
//
//            guard let id = mediaItem.id else {
//                return nil
//            }
//
//            guard let purpose = self.purpose else {
//                return nil
//            }
//
//            var value : String?
//
//            //Legacy
//            if let url = "\(id).\(purpose).srt".fileSystemURL {
//                do {
//                    try value = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16
//                } catch let error {
//                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
//
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    //                    if completed && !aligning {
//                    //                        remove()
//                    //                    }
//                }
//            }
//
//            if let url = "\(id).\(purpose).segments".fileSystemURL {
//                do {
//                    try value = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16?
//                } catch let error {
//                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
//
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    //                    if completed && !aligning {
//                    //                        remove()
//                    //                    }
//                }
//            }
//
//            return value
//        },
//
//        toSet: { (newValue) in
//            guard let mediaItem = self.mediaItem else {
//                return nil
//            }
//
//            guard let id = mediaItem.id else {
//                return nil
//            }
//
//            guard let purpose = self.purpose else {
//                return nil
//            }
//
//            var changed = false
//
//            var value = newValue
//
//            if _transcriptSegments == nil {
//                // Why do we do this?  To strip any header like SRT or WebVTT and remove newlines and add separator
//                if var transcriptSegmentComponents = value?.components(separatedBy: "\n\n") {
//                    for transcriptSegmentComponent in transcriptSegmentComponents {
//                        var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
//                        if transcriptSegmentArray.count > 2 {
//                            let count = transcriptSegmentArray.removeFirst()
//                            let timeWindow = transcriptSegmentArray.removeFirst()
//
//                            if let range = transcriptSegmentComponent.range(of: timeWindow + "\n") {
//                                let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
//
//                                if let index = transcriptSegmentComponents.index(of: transcriptSegmentComponent) {
//                                    transcriptSegmentComponents[index] = "\(count)\n\(timeWindow)\n" + text
//                                    changed = true
//                                }
//                            }
//                        }
//                    }
//                    if changed { // Essentially guaranteed to happen.
//                        value = nil
//                        for transcriptSegmentComponent in transcriptSegmentComponents {
//                            let transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
//                            if transcriptSegmentArray.count > 2 { // This removes anything w/o text, i.e. only count and timeWindow - or less, like a header, e.g. WebVTT (a nice side effect)
//                                value = (value != nil ? value! + VoiceBase.separator : "") + transcriptSegmentComponent
//                            }
//                        }
//                    }
//                }
//            }
//
//            _transcriptSegments = newValue
//
//            DispatchQueue.global(qos: .background).async { [weak self] in
//                let fileManager = FileManager.default
//
//                if self?._transcriptSegments != nil {
//                    if let filename = self?.filename, let destinationURL = (filename + ".segments").fileSystemURL {
//                        destinationURL.delete()
//
//                        do {
//                            try self?._transcriptSegments?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8) // why not utf16?
//                        } catch let error {
//                            print("failed to write segment transcript to cache directory: \(error.localizedDescription)")
//                        }
//                    } else {
//                        print("failed to get destinationURL")
//                    }
//
//                    //Legacy clean-up
//                    if let filename = self?.filename, let destinationURL = (filename + ".srt").fileSystemURL {
//                        destinationURL.delete()
//                    } else {
//                        print("failed to get destinationURL")
//                    }
//                } else {
//                    if let filename = self?.filename, let destinationURL = (filename + ".segments").fileSystemURL {
//                        destinationURL.delete()
//                    } else {
//                        print("failed to get destinationURL")
//                    }
//
//                    //Legacy clean-up
//                    if let filename = self?.filename, let destinationURL = (filename + ".srt").fileSystemURL {
//                        destinationURL.delete()
//                    } else {
//                        print("failed to get destinationURL")
//                    }
//                }
//            }
//
//            return newValue
//        },
//
//        didSet: { (transcriptSegments, oldValue) in
//            self.transcriptSegmentComponents = transcriptSegments?.components(separatedBy: VoiceBase.separator)
//        })
//    }()
    
    private var _transcriptSegments:String?
    {
        didSet {
            transcriptSegmentComponents = _transcriptSegments?.components(separatedBy: VoiceBase.separator)
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

            guard let filename = filename else {
                print("failed to get filename")
                return nil
            }

            //Legacy
            _transcriptSegments = "\(filename).srt".fileSystemURL?.string16 // "\(filename).srt".fileSystemURL?.string16
            
//            if let url = "\(filename).srt".fileSystemURL {
//                do {
//                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16
//                } catch let error {
//                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
//
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    //                    if completed && !aligning {
//                    //                        remove()
//                    //                    }
//                }
//            }

            _transcriptSegments = "\(filename).segments".fileSystemURL?.string16 // "\(filename).segments".fileSystemURL?.string16
            
//            if let url = "\(filename).segments".fileSystemURL {
//                do {
//                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16?
//                } catch let error {
//                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
//
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    //                    if completed && !aligning {
//                    //                        remove()
//                    //                    }
//                }
//            }

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
                                let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")

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
//                let fileManager = FileManager.default

                if self?._transcriptSegments != nil {
                    if let filename = self?.filename { // , let destinationURL = (filename + ".segments").fileSystemURL
                        let filename = filename + ".segments"
                        filename.fileSystemURL?.delete()
                        self?._transcriptSegments?.save16(filename:filename)
//                        do {
//                            try self?._transcriptSegments?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf16) // why not utf16?
//                        } catch let error {
//                            print("failed to write segment transcript to cache directory: \(error.localizedDescription)")
//                        }
                    } else {
                        print("failed to get destinationURL")
                    }

                    //Legacy clean-up
                    if let filename = self?.filename, let destinationURL = (filename + ".srt").fileSystemURL {
                        destinationURL.delete()
                    } else {
                        print("failed to get destinationURL")
                    }
                } else {
                    if let filename = self?.filename, let destinationURL = (filename + ".segments").fileSystemURL {
                        destinationURL.delete()
                    } else {
                        print("failed to get destinationURL")
                    }

                    //Legacy clean-up
                    if let filename = self?.filename, let destinationURL = (filename + ".srt").fileSystemURL {
                        destinationURL.delete()
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }

    var transcriptSegmentsFromWords:String?
    {
        get {
            var str : String?
            
            if let wordRangeTiming = wordRangeTiming {
                var count = 1
                var transcriptSegmentComponents = [String]()
                
                for element in wordRangeTiming {
                    if  let start = element["start"] as? Double,
                        let startSeconds = start.secondsToHMS,
                        let end = element["end"] as? Double,
                        let endSeconds = end.secondsToHMS,
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
                            let string = transcriptSegmentComponent[range.upperBound...] // .substring(from:range.upperBound)
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
                    Alerts.shared.alert(title: "Transcript Segments Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
                }
            }
            
            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
            } else {
                Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments is not available.")
            }
            
            atEnd?()
        })
    }
    
    func search(string:String?)
    {
        guard Globals.shared.isVoiceBaseAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
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
        
        let sessionConfig = URLSessionConfiguration.default
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
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                Thread.onMainThread {
                    
                }
            } else {
                Thread.onMainThread {
                    
                }
            }
        })
        
        task.resume()
    }

    func relaodUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Reload Completed", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been reloaded.", onFinished: {
                            self.getTranscript(alert:detailedAlerts) {
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {

                                    }
                                }
                            }
                        },
                        errorTitle: "Transcript Reload Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not reloaded.  Please try again.", onError: {

                        })
    }
    
    func alert(viewController:UIViewController)
    {
        guard !completed else {
            return
        }
        
        let completion = " (\(transcriptPurpose))" + (percentComplete != nil ? "\n(\(percentComplete!)% complete)" : "")
        
        var title = "Machine Generated Transcript "
        
        var message = "You will be notified when the machine generated transcript"
        
        if let text = self.mediaItem?.text {
            message += " for\n\n\(text)\(completion) "
        }
        
        if (mediaID != nil) {
            title += "in Progress"
            message += "\n\nis available."
            
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Media ID", style: .default, handler: {
                var message : String?
                
                if let text = self.mediaItem?.text {
                    message = text + " (\(self.transcriptPurpose))"
                }

                let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                message: message,
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
            
            Alerts.shared.alert(title:title, message:message, actions:actions)
        } else {
            title += "Requested"
            message += "\n\nhas started."
            
            Alerts.shared.alert(title:title, message:message)
        }
    }

    func confirmAlignment(action:(()->())?) // viewController:UIViewController, 
    {
        guard let text = self.mediaItem?.text else {
            return
        }
        
        var alertActions = [AlertAction]()

        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
            action?()
        }))

        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: {

        }))

        Alerts.shared.alert(title: "Confirm Alignment of Machine Generated Transcript", message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.", actions: alertActions)

//        yesOrNo(viewController: viewController, title: "Confirm Alignment of Machine Generated Transcript", message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
//            yesAction: { () -> (Void) in
//                action?()
//        },
//            yesStyle: .destructive,
//            noAction: nil, noStyle: .default)
    }
    
    func selectAlignmentSource(viewController:UIViewController)
    {
        guard let text = self.mediaItem?.text else {
            return
        }
        
        var alertActions = [AlertAction]()
        
        if (self.mediaItem?.hasNotesText == true) {
            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
                self.confirmAlignment() { // viewController:viewController
                    process(viewController: viewController, work: { [weak self] () -> (Any?) in
                        return self?.mediaItem?.notesText // self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
                    }, completion: { [weak self] (data:Any?) in
                        self?.align(data as? String) // stripHTML(self?.mediaItem?.notesHTML.result)
                    })
                }
            }))
        }
        
//        alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
//            self.confirmAlignment(viewController:viewController) {
//                self.align(self.transcript)
//            }
//        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .destructive, handler: {
            self.confirmAlignment() { // viewController:viewController
                self.align(self.transcriptFromTranscriptSegments)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Words, style: .destructive, handler: {
            self.confirmAlignment() { // viewController:viewController
                self.align(self.transcriptFromWords)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {

        }))
        
        Alerts.shared.alert(title: "Select Source for Alignment", message: text, actions: alertActions)
//        alertActionsCancel( viewController: viewController,
//                            title: "Select Source for Alignment",
//                            message: text,
//                            alertActions: alertActions,
//                            cancelAction: nil)
        
        //                            alertActionsCancel( viewController: viewController,
        //                                                title: "Confirm Alignment of Machine Generated Transcript",
        //                                                message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
        //                                alertActions: alertActions,
        //                                cancelAction: nil)
    }
    
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "VB:" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    func textToNumbers(longFormat:Bool) -> [String:String]?
    {
        // Need to have varying degrees of this since editing the entire text at once makes a more exhaustive set reasonable, but for segments it isn't.
        
        var textToNumbers = [String:String]()
        
        //        let singleNumbers = [
        //           "one"        :"1",
        //           "two"        :"2",
        //           "three"      :"3",
        //           "four"       :"4",
        //           "five"       :"5",
        //           "six"        :"6",
        //           "seven"      :"7",
        //           "eight"      :"8",
        //           "nine"       :"9"
        //        ]
        //
        //        let teenNumbers = [
        //           "ten"        :"10",
        //           "eleven"     :"11",
        //           "twelve"     :"12",
        //           "thirteen"   :"13",
        //           "fourteen"   :"14",
        //           "fifteen"    :"15",
        //           "sixteen"    :"16",
        //           "seventeen"  :"17",
        //           "eighteen"   :"18",
        //           "nineteen"   :"19"
        //        ]
        //
        //        let decades = [
        //           "twenty"     :"20",
        //           "thirty"     :"30",
        //           "forty"      :"40",
        //           "fifty"      :"50",
        //           "sixty"      :"60",
        //           "seventy"    :"70",
        //           "eighty"     :"80",
        //           "ninety"     :"90"
        //        ]
        
        // If we make the translation table too big searching for replacements can take a long time,
        // possibly too long for the user.
        
        //        let centuries = [
        //            "one hundred"     :"100",
        //            "two hundred"     :"200",
        //            "three hundred"   :"300",
        //            "four hundred"    :"400",
        //            "five hundred"    :"500",
        //            "six hundred"     :"600",
        //            "seven hundred"   :"700",
        //            "eight hundred"   :"800",
        //            "nine hundred"    :"900"
        //        ]
        
        var centuries = [String:String]()
        
        if longFormat {
            centuries = Constants.centuries
        } else {
            centuries = [
                "one hundred"     :"100"
            ]
        }
        
        //        let millenia = [
        //            "one thousand"     :"1000",
        //            "two thousand"     :"2000",
        //            "three thousand"   :"3000",
        //            "four thousand"    :"4000",
        //            "five thousand"    :"5000",
        //            "six thousand"     :"6000",
        //            "seven thousand"   :"7000",
        //            "eight thousand"   :"8000",
        //            "nine thousand"    :"9000",
        //        ]
        
        // Could add teenNumbers (>10) and "hundred" to get things like "fourteen hundred(s)..." but the plural and following numbers, if any, i.e. dates, could be complicated.
        
        for key in Constants.singleNumbers.keys {
            textToNumbers[key] = Constants.singleNumbers[key]
        }
        
        for key in Constants.teenNumbers.keys {
            textToNumbers[key] = Constants.teenNumbers[key]
        }
        
        for key in Constants.decades.keys {
            textToNumbers[key] = Constants.decades[key]
        }
        
        for key in centuries.keys {
            textToNumbers[key] = centuries[key]
        }
        
        // single digit double digit, etc.
        for hundredsKey in Constants.singleNumbers.keys { // ["one"]
            guard let prefix = Constants.singleNumbers[hundredsKey] else { // not needed if ["one"] is used
                continue
            }
            
            for teenNumbersKey in Constants.teenNumbers.keys {
                guard let num = Constants.teenNumbers[teenNumbersKey] else {
                    continue
                }
                
                var key:String
                let value = prefix + num // "1"
                
                key = hundredsKey + " " + teenNumbersKey
                textToNumbers[key] = value
                
                // not applicable
                //                        key = hundred + " and " + teenNumbersKey
                //                        textToNumbers[key] = value
            }
            
            for decadesKey in Constants.decades.keys {
                guard let decade = Constants.decades[decadesKey] else {
                    continue
                }
                
                let key = hundredsKey + " " + decadesKey
                let value = prefix + decade // "1"
                
                textToNumbers[key] = value
                
                // WHY? Because ten one is eleven, etc.
                if decadesKey != "ten" {
                    for singleNumbersKey in Constants.singleNumbers.keys {
                        var key:String
                        
                        let singleNumber = Constants.singleNumbers[singleNumbersKey]
                        let value = (Int(prefix)!*100 + Int(decade)! + Int(singleNumber!)!).description
                        
                        key = hundredsKey + " " + decadesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                        
                        // not applicable
                        //                                key = hundred + " and " + decadesKey + " " + singleNumbersKey
                        //                                textToNumbers[key] = value
                        
                        //                                if let decade = Constants.decades[decadesKey]?.replacingOccurrences(of:"0",with:""), let singleNumber = Constants.singleNumbers[singleNumbersKey] {
                        //                                    let value = prefix + decade + singleNumber // "1"
                        //                                    textToNumbers[key] = value
                        //                                }
                    }
                }
            } // not needed if ["one"] is used
        }
        
        // 20 - 99
        for decadesKey in Constants.decades.keys {
            guard let decade = Constants.decades[decadesKey] else {
                continue
            }
            
            for singleNumbersKey in Constants.singleNumbers.keys {
                guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                    continue
                }
                
                let key = (decadesKey + " " + singleNumbersKey)
                let value = (Int(decade)! + Int(singleNumber)!).description
                textToNumbers[key] = value
                
                //                if  let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                //                    let singleNumber = singleNumbers[singleNumber] {
                //                    let value = decade + singleNumber
                //                    textToNumbers[key] = value
                //                }
            }
        }
        
        for centuriesKey in centuries.keys {
            guard let century = centuries[centuriesKey] else {
                continue
            }
            
            // x01 - x09
            for singleNumbersKey in Constants.singleNumbers.keys {
                guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                    continue
                }
                
                let value = (Int(century)! + Int(singleNumber)!).description
                
                var key:String
                
                key = (centuriesKey + " " + singleNumbersKey)
                textToNumbers[key] = value
                
                key = (centuriesKey + " and " + singleNumbersKey)
                textToNumbers[key] = value
                
                //                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
                //                    let singleNumber = singleNumbers[singleNumber] {
                //                    let value = century + singleNumber
                //                    textToNumbers[key] = value
                //                }
            }
            
            // x10 - x19
            for teenNumbersKey in Constants.teenNumbers.keys {
                guard let teenNumber = Constants.teenNumbers[teenNumbersKey] else {
                    continue
                }
                
                let value = (Int(century)! + Int(teenNumber)!).description
                
                var key:String
                
                key = (centuriesKey + " " + teenNumbersKey)
                textToNumbers[key] = value
                
                key = (centuriesKey + " and " + teenNumbersKey)
                textToNumbers[key] = value
                
                //                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                //                    let teenNumber = teenNumbers[teenNumber] {
                //                    let value = century + teenNumber
                //                    textToNumbers[key] = value
                //                }
            }
            
            // x20 - x90
            for decadesKey in Constants.decades.keys {
                guard let decade = Constants.decades[decadesKey] else {
                    continue
                }
                
                let value = (Int(century)! + Int(decade)!).description
                
                var key:String
                
                key = (centuriesKey + " " + decadesKey)
                textToNumbers[key] = value
                
                key = (centuriesKey + " and " + decadesKey)
                textToNumbers[key] = value
                
                //                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                //                    let decade = decades[decade] {
                //                    let value = century + decade
                //                    textToNumbers[key] = value
                //                }
            }
            
            // x21 - x91
            for decadesKey in Constants.decades.keys {
                guard let decade = Constants.decades[decadesKey] else {
                    continue
                }
                
                for singleNumbersKey in Constants.singleNumbers.keys {
                    guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                        continue
                    }
                    
                    let value = (Int(century)! + Int(decade)! + Int(singleNumber)!).description
                    var key:String
                    
                    key = (centuriesKey + " " + decadesKey + " " + singleNumbersKey)
                    textToNumbers[key] = value
                    
                    key = (centuriesKey + " and " + decadesKey + " " + singleNumbersKey)
                    textToNumbers[key] = value
                    
                    //                    if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    //                        let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                    //                        let singleNumber = singleNumbers[singleNumber]
                    //                    {
                    //                        let value = (century + decade + singleNumber)
                    //                        textToNumbers[key] = value
                    //                    }
                }
            }
        }
        
        // JUST TAKES TOO LONG OTHERWISE
        if longFormat {
            // 1000 - 2999 as x thousand y hundred [and] decade/teen/single
            //            var age = ["one thousand":"1000","two thousand":"2000"]
            for milleniaKey in Constants.millenia.keys {
                guard let millenia = Constants.millenia[milleniaKey] else {
                    continue
                }
                
                var key:String = milleniaKey
                var value:String = millenia
                
                textToNumbers[key] = value
                
                // 1000 - 1009
                for singleNumbersKey in Constants.singleNumbers.keys {
                    guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                        continue
                    }
                    
                    value = (Int(millenia)! + Int(singleNumber)!).description
                    
                    key = milleniaKey + " " + singleNumbersKey
                    textToNumbers[key] = value
                    
                    key = milleniaKey + " and " + singleNumbersKey
                    textToNumbers[key] = value
                }
                
                // 1010 - 1019
                for teenNumbersKey in Constants.teenNumbers.keys {
                    guard let teenNumber = Constants.teenNumbers[teenNumbersKey] else {
                        continue
                    }
                    
                    value = (Int(millenia)! + Int(teenNumber)!).description
                    
                    key = milleniaKey + " " + teenNumbersKey
                    textToNumbers[key] = value
                    
                    key = milleniaKey + " and " + teenNumbersKey
                    textToNumbers[key] = value
                }
                
                // 1020 - 1099
                for decadesKey in Constants.decades.keys {
                    guard let decade = Constants.decades[decadesKey] else {
                        continue
                    }
                    
                    value = (Int(millenia)! + Int(decade)!).description
                    
                    key = milleniaKey + " " + decadesKey
                    textToNumbers[key] = value
                    
                    key = milleniaKey + " and " + decadesKey
                    textToNumbers[key] = value
                    
                    for singleNumbersKey in Constants.singleNumbers.keys {
                        guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                            continue
                        }
                        
                        value = (Int(millenia)! + Int(decade)! + Int(singleNumber)!).description
                        
                        key = milleniaKey + " " + decadesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                        
                        key = milleniaKey + " and " + decadesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                    }
                }
                
                // 1100 - 1999
                for centuriesKey in centuries.keys {
                    guard let century = centuries[centuriesKey] else {
                        continue
                    }
                    
                    value = (Int(millenia)! + Int(century)!).description
                    
                    key = milleniaKey + " " + centuriesKey
                    textToNumbers[key] = value
                    
                    // 1x01 - 1x09
                    for singleNumbersKey in Constants.singleNumbers.keys {
                        guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                            continue
                        }
                        
                        value = (Int(millenia)! + Int(century)! + Int(singleNumber)!).description
                        
                        key = milleniaKey + " " + centuriesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                        
                        key = milleniaKey + " " + centuriesKey + " and " + singleNumbersKey
                        textToNumbers[key] = value
                    }
                    
                    // 1x10 - 1x19
                    for teenNumbersKey in Constants.teenNumbers.keys {
                        guard let teenNumber = Constants.teenNumbers[teenNumbersKey] else {
                            continue
                        }
                        
                        value = (Int(millenia)! + Int(century)! + Int(teenNumber)!).description
                        
                        key = milleniaKey + " " + centuriesKey + " " + teenNumbersKey
                        textToNumbers[key] = value
                        
                        key = milleniaKey + " " + centuriesKey + " and " + teenNumbersKey
                        textToNumbers[key] = value
                    }
                    
                    // 1x20 - 1x99
                    for decadesKey in Constants.decades.keys {
                        guard let decade = Constants.decades[decadesKey] else {
                            continue
                        }
                        
                        value = (Int(millenia)! + Int(century)! + Int(decade)!).description
                        
                        key = milleniaKey + " " + centuriesKey + " " + decadesKey
                        textToNumbers[key] = value
                        
                        key = milleniaKey + " " + centuriesKey + " and " + decadesKey
                        textToNumbers[key] = value
                        
                        // 1xx0 - 1xx9
                        for singleNumbersKey in Constants.singleNumbers.keys {
                            if let singleNumber = Constants.singleNumbers[singleNumbersKey] {
                                value = (Int(millenia)! + Int(century)! + Int(decade)! + Int(singleNumber)!).description
                                
                                key = milleniaKey + " " + centuriesKey + " " + decadesKey + " " + singleNumbersKey
                                textToNumbers[key] = value
                                
                                key = milleniaKey + " " + centuriesKey + " and " + decadesKey + " " + singleNumbersKey
                                textToNumbers[key] = value
                            }
                        }
                    }
                }
            }
            
            // 1100 - 1900 as "xx hundred"
            var ages = [String:String]()
            for teenNumberKey in Constants.teenNumbers.keys {
                guard teenNumberKey != "ten" else {
                    continue
                }
                ages[teenNumberKey + " hundred"] = (Int(Constants.teenNumbers[teenNumberKey]!)! * 100).description
            }
            
            for agesKey in ages.keys {
                guard let age = ages[agesKey] else {
                    continue
                }
                
                // xx01 - xx09
                for singleNumbersKey in Constants.singleNumbers.keys {
                    guard let num = Constants.singleNumbers[singleNumbersKey] else {
                        continue
                    }
                    
                    let value = (Int(age)! + Int(num)!).description
                    
                    var key:String!
                    
                    key = agesKey + " " + singleNumbersKey
                    textToNumbers[key] = value
                    
                    key = agesKey + " and " + singleNumbersKey
                    textToNumbers[key] = value
                }
                
                // xx10 - xx19
                for teenNumbersKey in Constants.teenNumbers.keys {
                    guard let num = Constants.teenNumbers[teenNumbersKey] else {
                        continue
                    }
                    
                    let value = (Int(age)! + Int(num)!).description
                    
                    var key:String!
                    
                    key = agesKey + " " + teenNumbersKey
                    textToNumbers[key] = value
                    
                    key = agesKey + " and " + teenNumbersKey
                    textToNumbers[key] = value
                }
                
                for decadesKey in Constants.decades.keys {
                    // xx20 - xx90
                    guard let decade = Constants.decades[decadesKey] else {
                        continue
                    }
                    
                    let value = (Int(age)! + Int(decade)!).description
                    
                    var key:String!
                    
                    key = agesKey + " " + decadesKey
                    textToNumbers[key] = value
                    
                    key = agesKey + " and " + decadesKey
                    textToNumbers[key] = value
                    
                    // xx21 - xx99
                    for singleNumbersKey in Constants.singleNumbers.keys {
                        guard let singleNumber = Constants.singleNumbers[singleNumbersKey] else {
                            continue
                        }
                        
                        let value = (Int(age)! + Int(decade)! + Int(singleNumber)!).description
                        
                        var key:String!
                        
                        key = agesKey + " " + decadesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                        
                        key = agesKey + " and " + decadesKey + " " + singleNumbersKey
                        textToNumbers[key] = value
                    }
                }
            }
            
            // more generally s/b double digit double digit
            // teen teen, etc.
            for hundredsKey in Constants.teenNumbers.keys {
                guard let prefix = Constants.teenNumbers[hundredsKey] else {
                    continue
                }
                
                for teenNumbersKey in Constants.teenNumbers.keys {
                    guard let teenNumber = Constants.teenNumbers[teenNumbersKey] else {
                        continue
                    }
                    
                    var key:String
                    
                    let value = prefix + teenNumber
                    
                    key = hundredsKey + " " + teenNumbersKey
                    textToNumbers[key] = value
                    
                    // Not applicable
                    //                        key = hundred + " and " + teenNumbersKey
                    //                        textToNumbers[key] = value
                }
                
                for decadesKey in Constants.decades.keys {
                    guard let decade = Constants.decades[decadesKey] else {
                        continue
                    }
                    
                    var key:String
                    
                    let value = prefix + decade
                    
                    key = hundredsKey + " " + decadesKey
                    textToNumbers[key] = value
                    
                    // Not applicable
                    //                        key = hundred + " and " + teenNumbersKey
                    //                        textToNumbers[key] = value
                    
                    if decadesKey != "ten" { // ten ... single is teens
                        for singleNumbersKey in Constants.singleNumbers.keys {
                            var key:String
                            
                            let singleNumber = Constants.singleNumbers[singleNumbersKey]
                            let value = (Int(prefix)!*100 + Int(decade)! + Int(singleNumber!)!).description
                            
                            key = hundredsKey + " " + decadesKey + " " + singleNumbersKey
                            textToNumbers[key] = value
                        }
                    }
                }
            }
            
            for hundredsKey in Constants.decades.keys {
                // decade decade
                guard let prefix = Constants.decades[hundredsKey] else {
                    continue
                }
                
                for teenNumbersKey in Constants.teenNumbers.keys {
                    guard let teenNumber = Constants.teenNumbers[teenNumbersKey] else {
                        continue
                    }
                    
                    var key:String
                    
                    let value = prefix + teenNumber
                    
                    key = hundredsKey + " " + teenNumbersKey
                    textToNumbers[key] = value
                    
                    // Not applicable
                    //                        key = hundred + " and " + teenNumbersKey
                    //                        textToNumbers[key] = value
                }
                
                for decadesKey in Constants.decades.keys {
                    guard let decade = Constants.decades[decadesKey] else {
                        continue
                    }
                    
                    var key:String
                    
                    let value = prefix + decade
                    
                    key = hundredsKey + " " + decadesKey
                    textToNumbers[key] = value
                    
                    // Not applicable
                    //                        key = hundred + " and " + teenNumbersKey
                    //                        textToNumbers[key] = value
                    
                    if decadesKey != "ten" { // ten ... single is teens
                        for singleNumbersKey in Constants.singleNumbers.keys {
                            var key:String
                            
                            let singleNumber = Constants.singleNumbers[singleNumbersKey]
                            let value = (Int(prefix)!*100 + Int(decade)! + Int(singleNumber!)!).description
                            
                            key = hundredsKey + " " + decadesKey + " " + singleNumbersKey
                            textToNumbers[key] = value
                        }
                    }
                }
            }
        }
        
//        if longFormat {
//            for milleniumKey in Constants.millenia.keys {
//                guard let millenium = Constants.millenia[milleniumKey] else {
//                    continue
//                }
//
//                textToNumbers[milleniumKey] = millenium
//
//                for centuryKey in centuries.keys {
//                    guard let century = Constants.centuries[centuryKey] else {
//                        continue
//                    }
//
//                    let value = (Int(millenium)! + Int(century)!).description
//
//                    var key : String
//
//                    key = (milleniumKey + " " + centuryKey)
//                    textToNumbers[key] = value
//
//                    for singleNumberKey in Constants.singleNumbers.keys {
//                        guard let singleNumber = Constants.singleNumbers[singleNumberKey] else {
//                            continue
//                        }
//
//                        let value = (Int(millenium)! + Int(century)! + Int(singleNumber)!).description
//
//                        var key : String
//
//                        key = (milleniumKey + " " + centuryKey + " " + singleNumberKey)
//                        textToNumbers[key] = value
//
//                        key = (milleniumKey + " " + centuryKey + " and " + singleNumberKey)
//                        textToNumbers[key] = value
//
////                        if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
////                            let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
////                            let singleNumber = singleNumbers[singleNumber] {
////                            let value = millenium + century + singleNumber
////                            textToNumbers[key] = value
////                        }
//                    }
//
//                    for teenNumberKey in Constants.teenNumbers.keys {
//                        guard let teenNumber = Constants.teenNumbers[teenNumberKey] else {
//                            continue
//                        }
//
//                        let value = (Int(millenium)! + Int(century)! + Int(teenNumber)!).description
//
//                        var key : String
//
//                        key = (milleniumKey + " " + centuryKey + " " + teenNumberKey)
//                        textToNumbers[key] = value
//
//                        key = (milleniumKey + " " + centuryKey + " and " + teenNumberKey)
//                        textToNumbers[key] = value
//
////                        if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
////                            let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
////                            let teenNumber = teenNumbers[teenNumber] {
////                            let value = millenium + century + teenNumber
////                            textToNumbers[key] = value
////                        }
//                    }
//
//                    for decadeKey in Constants.decades.keys {
//                        guard let decade = Constants.decades[decadeKey] else {
//                            continue
//                        }
//
//                        let value = (Int(millenium)! + Int(century)! + Int(decade)!).description
//
//                        var key : String
//
//                        key = (milleniumKey + " " + centuryKey + " " + decadeKey)
//                        textToNumbers[key] = value
//
//                        key = (milleniumKey + " " + centuryKey + " and " + decadeKey)
//                        textToNumbers[key] = value
//
//                        for singleNumberKey in Constants.singleNumbers.keys {
//                            guard let singleNumber = Constants.singleNumbers[singleNumberKey] else {
//                                continue
//                            }
//
//                            let value = (Int(millenium)! + Int(century)! + Int(decade)! + Int(singleNumber)!).description
//
//                            var key : String
//
//                            key = (milleniumKey + " " + centuryKey + " " + decadeKey + " " + singleNumberKey)
//                            textToNumbers[key] = value
//
//                            key = (milleniumKey + " " + centuryKey + " and " + decadeKey + " " + singleNumberKey)
//                            textToNumbers[key] = value
//
////                            if  let millenium = millenia[millenium]?.replacingOccurrences(of: "000", with: "00"),
////                                let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
////                                let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
////                                let singleNumber = singleNumbers[singleNumber]
////                            {
////                                let value = (millenium + century + decade + singleNumber)
////                                textToNumbers[key] = value
////                            }
//                        }
//                    }
//                }
//            }
//        }
        
        //        print(textToNumbers)
        return textToNumbers.count > 0 ? textToNumbers : nil
    }
    
    func wordsToChange() -> [String:String]?
    {
        return [
            "scripture":"Scripture",
            "Chapter":"chapter",
            "Verse":"verse",
            "Grace":"grace",
            "Gospel":"gospel",
            "vs":"verses",
            "versus":"verses",
            "pilot":"Pilate",
            "OK":"okay"
        ]
    }
    
    func booksToChange() -> [String:String]?
    {
        return [
            "first samuel"           :"1 Samuel",
            "second samuel"          :"2 Samuel",
            
            "first kings"            :"1 Kings",
            "second kings"           :"2 Kings",
            
            "first chronicles"       :"1 Chronicles",
            "second chronicles"      :"2 Chronicles",
            
            "first corinthians"      :"1 Corinthians",
            "second corinthians"     :"2 Corinthians",
            
            "first thessalonians"    :"1 Thessalonians",
            "second thessalonians"   :"2 Thessalonians",
            
            "first timothy"          :"1 Timothy",
            "second timothy"         :"2 Timothy",
            
            "first peter"             :"1 Peter",
            "second peter"            :"2 Peter",
            
            "first john"      :"1 John",
            "second john"     :"2 John",
            "third john"      :"3 John"
        ]
    }
    
    func preambles() -> [String]?
    {
        let preambles = ["verse","verses","chapter","chapters"]
        
        return preambles.count > 0 ? preambles : nil
    }

    func continuations() -> [String]?
    {
        let continuations = ["through","to","and"]
        
        return continuations.count > 0 ? continuations : nil
    }
    
    func masterChanges(interactive:Bool, longFormat:Bool) -> [String:[String:String]]?
    {
        guard let textToNumbers = textToNumbers(longFormat:longFormat) else {
            return nil
        }
        
        guard let books = booksToChange() else {
            return nil
        }
        
        guard let wordsToChange = wordsToChange() else {
            return nil
        }
        
        guard let preambles = preambles() else {
            return nil
        }
        
        guard let continuations = continuations() else {
            return nil
        }
        
        var changes = [String:[String:String]]()
        
        changes["books"] = books
        changes["words"] = wordsToChange
        changes["textToNumbers"] = textToNumbers

        let maxChapters = max(Constants.OLD_TESTAMENT_CHAPTERS.max() ?? 0,Constants.NEW_TESTAMENT_CHAPTERS.max() ?? 0)
        
        var maxVerses = 0
        for book in Constants.OLD_TESTAMENT_VERSES {
            if book.max() > maxVerses {
                maxVerses = book.max() ?? 0
            }
        }
        for book in Constants.NEW_TESTAMENT_VERSES {
            if book.max() > maxVerses {
                maxVerses = book.max() ?? 0
            }
        }
        
        let maxNumber = max(maxChapters,maxVerses)
        
        var numbersToText = [String:[String]]()
        
        for (key,value) in textToNumbers {
            if numbersToText[value] == nil {
                numbersToText[value] = [key]
            } else {
                numbersToText[value]?.append(key)
            }
        }
        
        // These should really be hierarchical.
        for number in 1...maxNumber {
            let value = number.description
            guard let keys = numbersToText[value] else {
                continue
            }
            for key in keys {
                for context in preambles {
                    if changes[context] == nil {
                        changes[context] = ["\(context) " + key:"\(context) " + value]
                    } else {
                        changes[context]?["\(context) " + key] = "\(context) " + value
                    }
                }
                
                for book in books.keys {
                    if let bookName = books[book], let index = Constants.OLD_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                    
                    if let bookName = books[book], let index = Constants.NEW_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                }
                
                // For books that don't start w/ a number
                for book in Constants.OLD_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {
                        
                    }
                }
                
                for book in Constants.NEW_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {
                        
                    }
                }            }
        }
        
        if !interactive {
            for singleNumberKey in Constants.singleNumbers.keys {
                changes["textToNumbers"]?[singleNumberKey] =  nil
            }
        }

        for number in 1...maxNumber {
            guard !Constants.singleNumbers.values.contains(number.description) else {
                continue
            }
            
            let value = number.description
            guard let keys = numbersToText[value] else {
                continue
            }
            
            for key in keys {
                for context in continuations {
                    if changes[context] == nil {
                        changes[context] = ["\(context) " + key:"\(context) " + value]
                    } else {
                        changes[context]?["\(context) " + key] = "\(context) " + value
                    }
                }
            }
        }
        
        return changes.count > 0 ? changes : nil
    }
    
    func addParagraphBreaks(showGapTimes:Bool, gapThreshold:Double? = nil, tooClose:Int? = nil, words:[[String:Any]]?, text:String?, completion:((String?)->(Void))?)
    {
        guard var words = words else {
            return
        }
        
        guard words.count > 0 else {
            completion?(text)
            return
        }
        
        guard let text = text else {
            return
        }
        
        let first = words.removeFirst()
        
        guard let range = first["range"] as? Range<String.Index> else {
            return
        }
        
        let gap = first["gap"] as? Double
        
        var gapString = "\n\n"
        
        if showGapTimes, let gap = gap {
            gapString = "<\(gap)>" + gapString
        }
        
//        let beforeFull = String(text[..<range.lowerBound])
//        let stringFull = String(text[range])
//        let afterFull = String(text[range.upperBound...])
        
        //////////////////////////////////////////////////////////////////////////////
        // If words.first["range"] (either lowerBound or upperBound) is "too close"
        // (whatever that is defined to be) to a paragraph break then we should skip
        // and move on to the next word.
        //////////////////////////////////////////////////////////////////////////////
        
        if let tooClose = tooClose {
            var lowerRange : Range<String.Index>?
            var upperRange : Range<String.Index>?
            
            var rng : Range<String.Index>?
            
            var searchRange : Range<String.Index>!
            
            searchRange = Range(uncheckedBounds: (lower: text.startIndex, upper: range.lowerBound))
            
            rng = text.range(of: "\n\n", options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
            
            // But even if there is a match we have to find the LAST match
            if rng != nil {
                repeat {
                    lowerRange = rng
                    searchRange = Range(uncheckedBounds: (lower: rng!.upperBound, upper: range.lowerBound))
                    rng = text.range(of: "\n\n", options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
                } while rng != nil
            } else {
                // NONE FOUND BEFORE
            }
            
            // Too close to the previous?
            if let lowerRange = lowerRange {
                if (lowerRange.upperBound.encodedOffset + tooClose) > range.lowerBound.encodedOffset {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    operationQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    return
                }
            } else {
                // There is no previous.
                
                // Too close to the start?
                if (text.startIndex.encodedOffset + tooClose) > range.lowerBound.encodedOffset {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    operationQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    return
                }
            }
            
            searchRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
            
            upperRange = text.range(of: "\n\n", options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
            
            // Too close to the next?
            if let upperRange = upperRange {
                if (range.upperBound.encodedOffset + tooClose) > upperRange.lowerBound.encodedOffset {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    operationQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    return
                }
            } else {
                // There is no next.
                
                // Too close to end?
                if (range.lowerBound.encodedOffset + tooClose) > text.endIndex.encodedOffset {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    operationQueue.addOperation { [weak self] in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, completion:completion)
                    }
                    return
                }
            }
        }
        
        if let gapThreshold = gapThreshold, gap < gapThreshold {
            return
        }
        
        var newText = text
        newText.insert(contentsOf:gapString, at: range.lowerBound)
        
        var lower : String.Index?
        var upper : String.Index?
        var newRange : Range<String.Index>? // Was used in makeVisible
        
        if range.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
            lower = newText.index(range.lowerBound, offsetBy: gapString.count)
        }
        
        if range.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
            upper = newText.index(range.upperBound, offsetBy: gapString.count)
        }
        
        if let lower = lower, let upper = upper {
            newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
        }
        
        for i in 0..<words.count {
            if let wordRange = words[i]["range"] as? Range<String.Index> {
                if wordRange.lowerBound > range.lowerBound {
                    var lower : String.Index?
                    var upper : String.Index?
                    
                    if wordRange.lowerBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                        lower = newText.index(wordRange.lowerBound, offsetBy: gapString.count)
                    }
                    
                    if wordRange.upperBound <= newText.index(newText.endIndex, offsetBy:-gapString.count) {
                        upper = newText.index(wordRange.upperBound, offsetBy: gapString.count)
                    }
                    
                    if let lower = lower, let upper = upper {
                        let newRange = Range<String.Index>(uncheckedBounds: (lower: lower, upper: upper))
                        words[i]["range"] = newRange
                    }
                }
            }
        }
        
        operationQueue.addOperation { [weak self] in
            // Why is completion called here?
            self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:newText, completion:completion)
        }
    }
    
    func changeText(text:String?, startingRange:Range<String.Index>?, changes:[(String,String)]?, completion:((String)->(Void))?)
    {
        guard var text = text else {
            return
        }

        guard var changes = changes, let change = changes.first else {
            completion?(text)
            return
        }
        
//        guard var masterChanges = masterChanges, masterChanges.count > 0 else {
//            if !automatic {
//                Alerts.shared.alert(title:"Auto Edit Complete", message:mediaItem?.text)
//            }
//            return
//        }
        
//        guard let masterKey = masterChanges.keys.first else {
//            return
//        }
        
//        guard var key = masterChanges[masterKey]?.keys.first else {
//            return
//        }

        let oldText = change.0
        let newText = change.1
        
        var range : Range<String.Index>?

        if oldText == oldText.lowercased(), oldText.lowercased() != newText.lowercased() {
            if startingRange == nil {
                range = text.lowercased().range(of: oldText)
            } else {
                range = text.lowercased().range(of: oldText, options: [], range:  startingRange, locale: nil)
            }
        } else {
            if startingRange == nil {
                range = text.range(of: oldText)
            } else {
                range = text.range(of: oldText, options: [], range:  startingRange, locale: nil)
            }
        }
        
//        if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
//            if startingRange == nil {
//                range = text.lowercased().range(of: key)
//            } else {
//                range = text.lowercased().range(of: key, options: [], range:  startingRange, locale: nil)
//            }
//        } else {
//            if startingRange == nil {
//                range = text.range(of: key)
//            } else {
//                range = text.range(of: key, options: [], range:  startingRange, locale: nil)
//            }
//        }
//
//        while range == nil {
//            masterChanges[masterKey]?[key] = nil
//
//            if let first = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first {
//                key = first
//
//                if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
//                    range = text.lowercased().range(of: key)
//                } else {
//                    range = text.range(of: key)
//                }
//            } else {
//                break
//            }
//        }
        
        if let range = range { // masterChanges[masterKey]?[key]
//            let fullAttributedString = NSMutableAttributedString()
//
//            let beforeFull = String(text[..<range.lowerBound])
//            let stringFull = String(text[range])
//            let afterFull = String(text[range.upperBound...])
//
//            fullAttributedString.append(NSAttributedString(string: beforeFull,attributes: Constants.Fonts.Attributes.normal))
//            fullAttributedString.append(NSAttributedString(string: stringFull,attributes: Constants.Fonts.Attributes.highlighted))
//            fullAttributedString.append(NSAttributedString(string: afterFull, attributes: Constants.Fonts.Attributes.normal))
//
//            let attributedString = NSMutableAttributedString()
//
//            let before = "..." + String(text[..<range.lowerBound]).dropFirst(max(String(text[..<range.lowerBound]).count - 10,0))
//            let string = String(text[range])
//            let after = String(String(text[range.upperBound...]).dropLast(max(String(text[range.upperBound...]).count - 10,0))) + "..."
//
//            attributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.normal))
//            attributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
//            attributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal))
            
            let prior = String(text[..<range.lowerBound]).last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let following = String(text[range.upperBound...]).first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // what about other surrounding characters besides newlines and whitespaces, and periods if following?
            // what about other token delimiters?
            if (prior?.isEmpty ?? true) && ((following?.isEmpty ?? true) || (following == ".")) {
                operationQueue.addOperation { [weak self] in
                    text.replaceSubrange(range, with: newText)
                    
                    let before = String(text[..<range.lowerBound])
                    
                    if let completedRange = text.range(of: before + newText) {
                        let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                        self?.changeText(text:text, startingRange:startingRange, changes:changes, completion:completion)
                    } else {
                        // ERROR
                    }
                }
            } else {
                operationQueue.addOperation { [weak self] in
                    let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                    self?.changeText(text:text, startingRange:startingRange, changes:changes, completion:completion)
                }
            }
        } else {
            operationQueue.addOperation { [weak self] in
//                masterChanges[masterKey]?[key] = nil
//                if masterChanges[masterKey]?.count == 0 {
//                    masterChanges[masterKey] = nil
//                }
                changes.removeFirst()
                self?.changeText(text:text, startingRange:nil, changes:changes, completion:completion)
            }
        }
    }
    
    func alertActions(viewController:UIViewController) -> AlertAction?
    {
        guard let purpose = purpose else {
            return nil
        }
        
        guard let text = mediaItem?.text else {
            return nil
        }
        
        var prefix:String!
        
        switch purpose {
        case Purpose.audio:
            prefix = Constants.Strings.Audio
            
        case Purpose.video:
            prefix = Constants.Strings.Video
            
        default:
            return nil // prefix = ""
//            break
        }
        
        var action : AlertAction!

        action = AlertAction(title: prefix + " " + Constants.Strings.Transcript, style: .default) {
            if self.transcript == nil {
                guard Globals.shared.isVoiceBaseAvailable ?? false else {
                    if Globals.shared.voiceBaseAPIKey == nil {
                        let alert = UIAlertController(  title: "Please add an API Key to use VoiceBase",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        alert.addTextField(configurationHandler: { (textField:UITextField) in
                            textField.text = Globals.shared.voiceBaseAPIKey
                        })
                        
                        let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction) -> Void in
                            Globals.shared.voiceBaseAPIKey = alert.textFields?[0].text
                            
                            // If this is a valid API key then should pass a completion block to start the transcript!
                            if Globals.shared.voiceBaseAPIKey != nil {
                                Globals.shared.checkVoiceBaseAvailability {
                                    if !self.transcribing {
                                        if Globals.shared.reachability.isReachable {
//                                            var alertActions = [AlertAction]()
//
//                                            alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: {
//                                                self.getTranscript(alert: true) {}
//                                                mgtUpdate()
//                                            }))
//
//                                            alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                                            
                                            yesOrNo(viewController: viewController,
                                                    title: "Begin Creating\nMachine Generated Transcript?",
                                                    message: "\(text) (\(self.transcriptPurpose))",
                                                    yesAction: { () -> (Void) in
                                                        self.getTranscript(alert: true)
                                                        self.alert(viewController:viewController)
                                                    },
                                                    yesStyle: .default,
                                                    noAction: nil,
                                                    noStyle: .default)
                                            
//                                                alertActionsCancel( viewController: viewController,
//                                                                    title: "Begin Creating\nMachine Generated Transcript?",
//                                                                    message: "\(text) (\(self.transcriptPurpose))",
//                                                    alertActions: alertActions,
//                                                    cancelAction: nil)
                                        } else {
                                            networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                                        }
                                    } else {
                                        self.alert(viewController:viewController)
                                    }
                                }
                            }
                        })
                        alert.addAction(okayAction)
                        
                        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                            (action : UIAlertAction) -> Void in
                        })
                        alert.addAction(cancel)
                        
                        viewController.present(alert, animated: true, completion: nil)
                    } else {
                        networkUnavailable(viewController,"VoiceBase unavailable.")
                    }
                    return
                }
                
                guard Globals.shared.reachability.isReachable else {
                    networkUnavailable(viewController,"VoiceBase unavailable.")
                    return
                }
                
                if !self.transcribing {
                    if Globals.shared.reachability.isReachable {
//                        var alertActions = [AlertAction]()
//
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: {
//                            self.getTranscript(alert: true) {}
//                            mgtUpdate()
//                        }))
//
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                        
                        yesOrNo(viewController: viewController,
                                title: "Begin Creating\nMachine Generated Transcript?",
                                message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.getTranscript(alert: true)
                                self.alert(viewController:viewController)
                            },
                            yesStyle: .default,
                            noAction: nil,
                            noStyle: .default)
                        
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Begin Creating\nMachine Generated Transcript?",
//                                                message: "\(text) (\(self.transcriptPurpose))",
//                                alertActions: alertActions,
//                                cancelAction: nil)
                    } else {
                        networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                    }
                } else {
                    self.alert(viewController:viewController)
                }
            } else {
                var alertActions = [AlertAction]()
                
                alertActions.append(AlertAction(title: "View", style: .default, handler: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Transcript", style: .default, handler: {
                        if self.transcript == self.transcriptFromWords {
                            print("THEY ARE THE SAME!")
                        }

                        popoverHTML(viewController, title:self.mediaItem?.title, bodyHTML:self.bodyHTML, headerHTML:self.headerHTML, search:true)
                    }))
                    
                    alertActions.append(AlertAction(title: "Transcript with Timing", style: .default, handler: {
                        process(viewController: viewController, work: { [weak self] () -> (Any?) in
                            var htmlString = "<!DOCTYPE html><html><body>"
                            
                            var transcriptSegmentHTML = String()
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<table>"
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<tr style=\"vertical-align:bottom;\"><td><b>#</b></td><td><b>Gap</b></td><td><b>Start Time</b></td><td><b>End Time</b></td><td><b>Span</b></td><td><b>Recognized Speech</b></td></tr>"
                            
                            if let transcriptSegmentComponents = self?.transcriptSegmentComponents {
                                var priorEndTime : Double?
                                
                                for transcriptSegmentComponent in transcriptSegmentComponents {
                                    var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                                    
                                    if transcriptSegmentArray.count > 2  {
                                        let count = transcriptSegmentArray.removeFirst()
                                        let timeWindow = transcriptSegmentArray.removeFirst()
                                        let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
                                        
                                        if  let start = times.first,
                                            let end = times.last,
                                            let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                            let text = String(transcriptSegmentComponent[range.upperBound...])
                                            
                                            var gap = String()
                                            var duration = String()

                                            if let startTime = start.hmsToSeconds, let endTime = end.hmsToSeconds {
                                                let durationTime = endTime - startTime
                                                duration = String(format:"%.3f",durationTime)

                                                if let peTime = priorEndTime {
                                                    let gapTime = startTime - peTime
                                                    gap = String(format:"%.3f",gapTime)
                                                }
                                            }

                                            priorEndTime = end.hmsToSeconds

                                            let row = "<tr style=\"vertical-align:top;\"><td>\(count)</td><td>\(gap)</td><td>\(start)</td><td>\(end)</td><td>\(duration)</td><td>\(text.replacingOccurrences(of: "\n", with: " "))</td></tr>"
                                            transcriptSegmentHTML = transcriptSegmentHTML + row
                                        }
                                    }
                                }
                            }
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "</table>"

                            htmlString = htmlString + (self?.headerHTML ?? "") + transcriptSegmentHTML + "</body></html>"

                            return htmlString as Any
                        }, completion: { [weak self] (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(viewController,title:self?.mediaItem?.title,htmlString:htmlString, search:true)
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
                    guard self.operationQueue.operationCount == 0 else {
                        var message = String()
                        
                        if let text = self.mediaItem?.text {
                            message = "for\n\n\(text)\n\n"
                        }
                        
                        message += "You will be notified when it is complete."
                        
                        Alerts.shared.alert(title:"Auto Edit Underway",message:message)
                        return
                    }
                    
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                        let textPopover = navigationController.viewControllers[0] as? TextViewController {

                        navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                        
                        if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                        }

                        textPopover.navigationController?.isNavigationBarHidden = false
                        
                        textPopover.navigationItem.title = (self.mediaItem?.title ?? "") + " (\(self.transcriptPurpose))"
                        
                        let text = self.transcript
                        
                        textPopover.transcript = self // Must come before track
                        textPopover.track = true
                        
                        textPopover.text = text
                        
                        textPopover.assist = true
                        textPopover.search = true
                        
                        textPopover.onSave = { (text:String) -> Void in
                            guard text != textPopover.text else {
                                return
                            }
                            
                            self.transcript = text
                        }
                        
                        viewController.present(navigationController, animated: true, completion: nil)
                    } else {
                        print("ERROR")
                    }
                }))
                
                alertActions.append(AlertAction(title: "Auto Edit", style: .default, handler: {
                    guard let text = self.transcript else {
                        return
                    }
                    
                    guard self.operationQueue.operationCount == 0 else {
                        var message = String()
                        
                        if let text = self.mediaItem?.text {
                            message = "for\n\n\(text)\n\n"
                        }

                        message += "You will be notified when it is complete."
                        
                        Alerts.shared.alert(title:"Auto Edit Already Underway",message:message)
                        return
                    }
                    
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }

                    var message = String()
                    
                    if let text = self.mediaItem?.text {
                        message = "for\n\n\(text)\n\n"
                    }
                    
                    message += "You will be notified when it is complete."
                    
                    Alerts.shared.alert(title: "Auto Edit Underway", message: message)

                    self.operationQueue.addOperation {
                        if  let transcriptString = self.transcript?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                            let transcriptFromWordsString = self.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                            transcriptString == transcriptFromWordsString {
                            // Can insert paragraph breaks
                            let tooClose = self.mediaItem?.overallAverageSpeakerNotesParagraphLength ?? 700 // default value is arbitrary - at best based on trial and error
                            
                            let speakerNotesParagraphWords = self.mediaItem?.speakerNotesParagraphWords
                            
                            //                        print(speakerNotesParagraphWords?.sorted(by: { (first:(key: String, value: Int), second:(key: String, value: Int)) -> Bool in
                            //                            if first.value == second.value {
                            //                                return first.key < second.key
                            //                            } else {
                            //                                return first.value > second.value
                            //                            }
                            //                        }))
                            
                            // Multiply the gap time by the frequency of the word that appears after it and sort
                            // in descending order to suggest the most likely paragraph breaks.
                            
                            if let words = self.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
                                if let firstGap = first["gap"] as? Double, let secondGap = second["gap"] as? Double {
                                    if let firstWord = first["text"] as? String, let secondWord = second["text"] as? String {
                                        return (firstGap * Double(speakerNotesParagraphWords?[firstWord.lowercased()] ?? 1)) > (secondGap * Double(speakerNotesParagraphWords?[secondWord.lowercased()] ?? 1))
                                    }
                                }
                                
                                return first["gap"] != nil
                            }) {
                                self.addParagraphBreaks(showGapTimes:false, tooClose:tooClose, words:words, text:text, completion: { (string:String?) -> (Void) in
                                    guard var masterChanges = self.masterChanges(interactive:false, longFormat:true) else {
                                        self.transcript = string
                                        return
                                    }
                                    
                                    var changes = [(String,String)]()
                                    
                                    for masterKey in masterChanges.keys {
                                        if let keys = masterChanges[masterKey]?.keys {
                                            for key in keys {
                                                let oldText = key
                                                if let newText = masterChanges[masterKey]?[key] {
                                                    if let newText = masterChanges[masterKey]?[key] {
                                                        if oldText == oldText.lowercased(), oldText.lowercased() != newText.lowercased() {
                                                            if text.lowercased().range(of: oldText) != nil {
                                                                changes.append((oldText,newText))
                                                            }
                                                        } else {
                                                            if text.range(of: oldText) != nil {
                                                                changes.append((oldText,newText))
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    changes.sort(by: { (first, second) -> Bool in
                                        first.0.endIndex > second.0.endIndex
                                    })
                                    
                                    self.changeText(text: string, startingRange: nil, changes: changes, completion: { (string:String) -> (Void) in
                                        Alerts.shared.alert(title:"Auto Edit Completed", message:self.mediaItem?.text)
                                        self.transcript = string
                                    })
                                })
                            }
                        } else {
                            guard var masterChanges = self.masterChanges(interactive:false, longFormat:true) else {
                                return
                            }
                            
                            var changes = [(String,String)]()
                            
                            for masterKey in masterChanges.keys {
                                if let keys = masterChanges[masterKey]?.keys {
                                    for key in keys {
                                        let oldText = key
                                        if let newText = masterChanges[masterKey]?[key] {
                                            if let newText = masterChanges[masterKey]?[key] {
                                                if oldText == oldText.lowercased(), oldText.lowercased() != newText.lowercased() {
                                                    if text.lowercased().range(of: oldText) != nil {
                                                        changes.append((oldText,newText))
                                                    }
                                                } else {
                                                    if text.range(of: oldText) != nil {
                                                        changes.append((oldText,newText))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            changes.sort(by: { (first, second) -> Bool in
                                first.0.endIndex > second.0.endIndex
                            })
                            
                            self.changeText(text: text, startingRange: nil, changes: changes, completion: { (string:String) -> (Void) in
                                Alerts.shared.alert(title:"Auto Edit Completed", message:self.mediaItem?.text)
                                self.transcript = string
                            })
                        }
                        

//                        let keyOrder = ["words","books","verse","verses","chapter","chapters","textToNumbers"]
//
//                        let masterKeys = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
//                            let firstIndex = keyOrder.index(of: first)
//                            let secondIndex = keyOrder.index(of: second)
//
//                            if let firstIndex = firstIndex, let secondIndex = secondIndex {
//                                return firstIndex > secondIndex
//                            }
//
//                            if firstIndex != nil {
//                                return false
//                            }
//
//                            if secondIndex != nil {
//                                return true
//                            }
//
//                            return first.endIndex > second.endIndex
//                        })
                        
//                        print(changes)
                        
//                        for masterKey in masterKeys {
//                            if !["words","books","textToNumbers"].contains(masterKey) {
//                                if !text.lowercased().contains(masterKey.lowercased()) {
//                                    masterChanges[masterKey] = nil
//                                }
//                            }
//                        }

//                        guard let masterKey = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
//                            let firstIndex = keyOrder.index(of: first)
//                            let secondIndex = keyOrder.index(of: second)
//
//                            if let firstIndex = firstIndex, let secondIndex = secondIndex {
//                                return firstIndex > secondIndex
//                            }
//
//                            if firstIndex != nil {
//                                return false
//                            }
//
//                            if secondIndex != nil {
//                                return true
//                            }
//
//                            return first.endIndex > second.endIndex
//                        }).first else {
//                            return
//                        }
//
//                        guard var key = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first else {
//                            return
//                        }
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
                
                if Globals.shared.isVoiceBaseAvailable ?? false {
                    alertActions.append(AlertAction(title: "Check VoiceBase", style: .default, handler: {
                        self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                                        VoiceBase.delete(mediaID: self.mediaID)
                                    }))
                                    
                                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:nil))
                                    
                                    Alerts.shared.alert(title:"Confirm Removal From VoiceBase", message:text + "\nMedia ID: " + mediaID, actions:actions)
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"On VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis on VoiceBase.", actions:actions)
                            }
                        }, onError:  { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"Not on VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis not on VoiceBase.", actions:actions)
                            }
                        })
                    }))
                    
                    alertActions.append(AlertAction(title: "Align", style: .destructive, handler: {
                        guard !self.aligning else {
                            if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
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
                        
//                        var alertActions = [AlertAction]()
//
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                            var alertActions = [AlertAction]()
//
//                            if self.mediaItem?.hasNotesHTML == true {
//                                alertActions.append(AlertAction(title: Constants.Strings.HTML_Transcript, style: .default, handler: {
//                                    process(viewController: viewController, work: { [weak self] () -> (Any?) in
//                                        self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
//                                    }, completion: { [weak self] (data:Any?) in
//                                        self?.align(stripHTML(self?.mediaItem?.notesHTML.result))
//                                    })
//                                }))
//                            }
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .default, handler: {
//                                self.align(self.transcript)
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .default, handler: {
//                                self.align(self.transcriptFromTranscriptSegments)
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Words, style: .default, handler: {
//                                self.align(self.transcriptFromWords)
//                            }))
//
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Select Source for Alignment",
//                                                message: text,
//                                                alertActions: alertActions,
//                                                cancelAction: nil)
//                        }))
//
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                        
                        self.selectAlignmentSource(viewController:viewController)
                        
//                        if let text = self.mediaItem?.text {
//                            var alertActions = [AlertAction]()
//
//                            if (self.mediaItem?.hasNotes == true) || (self.mediaItem?.hasNotesHTML == true) {
//                                alertActions.append(AlertAction(title: Constants.Strings.HTML_Transcript, style: .destructive, handler: {
//                                    confirmAlignment {
//                                        process(viewController: viewController, work: { [weak self] () -> (Any?) in
//                                            self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
//                                            }, completion: { [weak self] (data:Any?) in
//                                                self?.align(self?.mediaItem?.notesText) // stripHTML(self?.mediaItem?.notesHTML.result)
//                                        })
//                                    }
//                                }))
//                            }
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcript)
//                                }
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcriptFromTranscriptSegments)
//                                }
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Words, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcriptFromWords)
//                                }
//                            }))
//
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Select Source for Alignment",
//                                                message: text,
//                                                alertActions: alertActions,
//                                                cancelAction: nil)
//
////                            alertActionsCancel( viewController: viewController,
////                                                title: "Confirm Alignment of Machine Generated Transcript",
////                                                message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
////                                alertActions: alertActions,
////                                cancelAction: nil)
//                        }
                    }))
                }
                
                alertActions.append(AlertAction(title: "Restore", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Regenerate Transcript", style: .destructive, handler: {
                        yesOrNo(viewController: viewController,
                                title: "Confirm Regeneration of Transcript",
                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
                                yesAction: { () -> (Void) in
                                    self.transcript = self.transcriptFromWords
                                }, yesStyle: .destructive,
                                noAction: nil, noStyle: .default)
                        
//                        var alertActions = [AlertAction]()
//                        
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                            self.transcript = self.transcriptFromWords
//                        }))
//                        
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
//                        
//                        if let text = self.mediaItem?.text {
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Confirm Regeneration of Transcript",
//                                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
//                                alertActions: alertActions,
//                                cancelAction: nil)
//                        }
                    }))
                    
                    if Globals.shared.isVoiceBaseAvailable ?? false {
                        alertActions.append(AlertAction(title: "Reload from VoiceBase", style: .destructive, handler: {
                            self.metadata(completion: { (dict:[String:Any]?)->(Void) in
//                                var alertActions = [AlertAction]()
//
//                                alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                                    Alerts.shared.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
//
//                                    if self.resultsTimer != nil {
//                                        print("TIMER NOT NIL!")
//
//                                        var actions = [AlertAction]()
//
//                                        actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
//
//                                        Alerts.shared.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
//                                    } else {
//                                        Thread.onMainThread {
//                                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                                        }
//                                    }
//                                }))
//
//                                alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                                
                                yesOrNo(viewController: viewController,
                                        title: "Confirm Reloading",
                                        message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
                                        yesAction: { () -> (Void) in
                                            Alerts.shared.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                            
                                            if self.resultsTimer != nil {
                                                print("TIMER NOT NIL!")
                                                
                                                var actions = [AlertAction]()
                                                
                                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                                
                                                Alerts.shared.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                            } else {
                                                Thread.onMainThread {
                                                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                }
                                            }
                                        }, yesStyle: .destructive,
                                        noAction: nil, noStyle: .default)
                                
//                                        alertActionsCancel( viewController: viewController,
//                                                            title: "Confirm Reloading",
//                                                            message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
//                                            alertActions: alertActions,
//                                            cancelAction: nil)
                            }, onError:  { (dict:[String:Any]?)->(Void) in
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"Not on VoiceBase", message:text + "\nis not on VoiceBase.", actions:actions)
                            })
                        }))
                    }
                    
                    alertActionsCancel( viewController: viewController,
                                        title: "Restore Options",
                                        message: "\(text) (\(self.transcriptPurpose))",
                        alertActions: alertActions,
                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
//                    var alertActions = [AlertAction]()
//
//                    alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                        self.remove()
//                    }))
//
//                    alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                    
                    yesOrNo(viewController: viewController,
                            title: "Confirm Deletion of Machine Generated Transcript",
                            message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.remove()
                            },
                            yesStyle: .destructive,
                            noAction: nil,
                            noStyle: .default)

//                        alertActionsCancel( viewController: viewController,
//                                            title: "Confirm Deletion of Machine Generated Transcript",
//                                            message: "\(text) (\(self.transcriptPurpose))",
//                            alertActions: alertActions,
//                            cancelAction: nil)
                }))
                
                alertActionsCancel(  viewController: viewController,
                                     title: Constants.Strings.Machine_Generated + " " + Constants.Strings.Transcript,
                    message: text + " (\(self.transcriptPurpose))",
                    alertActions: alertActions,
                    cancelAction: nil)
            }
        }
        
        return action
    }
    
//    func editTranscriptSegment(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath)
//    {
//        editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath,automatic:false,automaticVisible:false,automaticInteractive:false,automaticCompletion:nil)
//    }
    
    func editTranscriptSegment(popover:PopoverTableViewController, tableView:UITableView, indexPath:IndexPath, automatic:Bool = false, automaticVisible:Bool = false, automaticInteractive:Bool = false, automaticCompletion:(()->(Void))? = nil)
    {
        let stringIndex = popover.section.index(indexPath)
        
        guard let string = popover.section.strings?[stringIndex] else {
            return
        }

        let playing = Globals.shared.mediaPlayer.isPlaying
        
        Globals.shared.mediaPlayer.pause()
        
        var transcriptSegmentArray = string.components(separatedBy: "\n")
        let count = transcriptSegmentArray.removeFirst() // Count
        let timing = transcriptSegmentArray.removeFirst() // Timing
        let transcriptSegmentTiming = timing.replacingOccurrences(of: "to", with: "-->")
        
        if  let first = transcriptSegmentComponents?.filter({ (string:String) -> Bool in
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
            
            let text = String(string[range.upperBound...])
            
            textPopover.text = text
            textPopover.assist = true
            
            textPopover.automatic = automatic
            textPopover.automaticVisible = automaticVisible
            textPopover.automaticInteractive = automaticInteractive
            textPopover.automaticCompletion = automaticCompletion
 
            textPopover.onCancel = {
                if playing {
                    Globals.shared.mediaPlayer.play()
                }
            }
            
            textPopover.onSave = { (text:String) -> Void in
                // This guard condition will be false after save
                guard text != textPopover.text else {
                    if playing {
                        Globals.shared.mediaPlayer.play()
                    }
                    return
                }
                
                // I.e. THIS SHOULD NEVER HAPPEN WHEN CALLED FROM onDone UNLESS
                // It is called during automatic.
                self.transcriptSegmentComponents?[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
                if popover.searchActive {
                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
                }
                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
            }
            
            textPopover.onDone = { (text:String) -> Void in
                textPopover.onSave?(text)
//                self.transcriptSegmentComponents?[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
//                if popover.searchActive {
//                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
//                }
//                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
                
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
                    Globals.shared.mediaPlayer.play()
                }
            }
            
            popover.present(navigationController, animated: true, completion: nil)
        } else {
            print("ERROR")
        }
    }
    
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]? // popover:PopoverTableViewController,
    {
        var actions = [AlertAction]()
        
        var edit:AlertAction!
        
        edit = AlertAction(title: "Edit", style: .default) {
            self.editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath)
        }
        
        actions.append(edit)
        
        return actions.count > 0 ? actions : nil
    }

    func timingIndexAlertActions(viewController:UIViewController,completion:((PopoverTableViewController)->(Void))?) -> AlertAction?
    {
        var action : AlertAction!
        
        action = AlertAction(title: "Timing Index", style: .default) {
            var alertActions = [AlertAction]()

            alertActions.append(AlertAction(title: "By Word", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTimingIndexWord
                    
                    popover.section.showIndex = true

                    popover.stringsFunction = { () -> [String]? in
                        guard let transcriptSegmentTokens = self.transcriptSegmentTokens else {
                            return nil
                        }
                        
                        return Array(transcriptSegmentTokens).sorted()
                    }

                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Phrase", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {

                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTimingIndexPhrase
                    
                    popover.section.showIndex = true
                    
                    popover.stringsFunction = { () -> [String]? in
                        guard let keywordDictionaries = self.keywordDictionaries?.keys else {
                            return nil
                        }
                        
                        return Array(keywordDictionaries).sorted()
                    }
                    
                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Segment", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self

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
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { () -> [String]? in
                        return self.transcriptSegmentComponents?.filter({ (string:String) -> Bool in
                            return string.components(separatedBy: "\n").count > 1
                        }).map({ (transcriptSegmentComponent:String) -> String in
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") // 
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
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
                    
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
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
                    popover.stringsFunction = { () -> [String]? in
                        var strings = [String]()
                        
                        if let words = self.words?.filter({ (dict:[String:Any]) -> Bool in
                            return dict["w"] != nil
                        }) {
                            var lastEnd : Int?
                            
                            for i in 0..<words.count {
                                if  let position = words[i]["p"] as? Int,
                                    let start = words[i]["s"] as? Int,
                                    let end = words[i]["e"] as? Int,
                                    let word = words[i]["w"] as? String,
                                    let startHMS = (Double(start)/1000.0).secondsToHMS,
                                    let endHMS = (Double(end)/1000.0).secondsToHMS {
                                    strings.append("\(position+1)\n")
                                    
                                    if let lastEnd = lastEnd {
                                        strings[i] += String(format:"%.3f ",Double(start - lastEnd)/1000.0)
                                    }

                                    strings[i] += "\(startHMS) to \(endHMS)\n\(word)"

                                    lastEnd = end
                                }
                            }
                        }
                    
                        return strings.count > 0 ? strings : nil
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
