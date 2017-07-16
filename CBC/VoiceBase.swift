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
    
    func post(mediaID:String?,path:String?,parameters:[String:String]?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                    print(json)
                    
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
                DispatchQueue.main.async(execute: { () -> Void in
                    onError?(json)
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion?(json)
                })
            }
        })
        
        task.resume()
    }

    static func get(accept:String?,mediaID:String?,path:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                print(string as Any)

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string]
                } else {
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        print(json)
                        
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
                DispatchQueue.main.async(execute: { () -> Void in
                    onError?(json)
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion?(json)
                })
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

        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                    print(json)
                    
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
                DispatchQueue.main.async(execute: { () -> Void in

                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                
                })
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
//        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
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
        
        guard let purpose = purpose else {
            return "ERROR no purpose"
        }
        
        guard mediaItem.id != nil else {
            return "ERROR no mediaItem.id"
        }

        var mediaItemString = "{"
        
            mediaItemString = "\(mediaItemString)\"metadata\":{"
        
                if let text = mediaItem.text {
                    if let mediaID = mediaID {
                        mediaItemString = "\(mediaItemString)\"title\":\"\(text) (\(purpose.lowercased()))\n\(mediaID)\","
                    } else {
                        mediaItemString = "\(mediaItemString)\"title\":\"\(text) (\(purpose.lowercased()))\","
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
                        mediaItemString = "\(mediaItemString)\"text\":\"\(text) (\(purpose.lowercased()))\","
                    }
                    
                    if let scripture = mediaItem.scripture {
                        mediaItemString = "\(mediaItemString)\"scripture\":\"\(scripture.description)\","
                    }
                    
                    if let speaker = mediaItem.speaker {
                        mediaItemString = "\(mediaItemString)\"speaker\":\"\(speaker)\","
                    }
                    
                    mediaItemString = "\(mediaItemString)\"purpose\":\"\(purpose.lowercased())\""
            
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
        }
    }
    
    var completed = false
    {
        didSet {
            mediaItem?.mediaItemSettings?["completed."+purpose!] = completed ? "YES" : "NO"
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
            
            guard let mediaID = mediaID else { // (mediaID == "Completed") ||
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
                        
                        // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                        if !aligning {
//                            remove()
//                        }
                    }
                }
            } else {
                if !transcribing && (_transcript == nil) && (self.resultsTimer == nil) { //  && (mediaID != "Completed")
                    globals.queue.sync(execute: { () -> Void in
                        mediaItem.removeTag("Machine Generated Transcript")
                    })
                    
                    transcribing = true
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(), repeats: true)
                    })
                } else {
                    // Overkill to make sure the cloud storage is cleaned-up?
                    //                mediaItem.voicebase?.delete()  // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
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
                globals.queue.sync(execute: { () -> Void in
                    mediaItem.addTag("Machine Generated Transcript")
                })
                
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
                globals.queue.sync(execute: { () -> Void in
                    mediaItem.removeTag("Machine Generated Transcript")
                })
                
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
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
        }
    }
    
    var _transcript:String?
    {
        didSet {

        }
    }
    
    var mediaJSON: [String:Any]?
    {
        get {
            guard _mediaJSON == nil else {
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
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                    print(json)

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
                DispatchQueue.main.async(execute: { () -> Void in
                    onError?(json)
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion?(json)
                })
            }
        })
        
        task.resume()
    }
    
    func uploadUserInfo() -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                self.percentComplete = nil
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.getTranscript()
                self.getTranscriptSRT()
                
                self.details()
                
                self.transcribing = false
                self.completed = true
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
            globals.alert(title: "Transcript Failed",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nwas not completed.  Please try again.")
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
        }

        return userInfo.count > 0 ? userInfo : nil
    }
    
    func upload()
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        let parameters:[String:String] = ["media":url,"metadata":self.metadata,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
        
        post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            self.uploadJSON = json
            
            if let status = json?["status"] as? String, status == "accepted" {
                if let mediaID = json?["mediaId"] as? String {
                    self.mediaID = mediaID
                    
                    globals.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nhas been started.  You will be notified when it is complete.")
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(), repeats: true)
                    })
                }
            } else {
                // Not accepted.
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.transcribing = false
            globals.alert(title: "Transcript Failed",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
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
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                    print(json)
                    
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
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
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

    func details()
    {
        details(completion: { (json:[String : Any]?) -> (Void) in
            if let json = json?["media"] as? [String:Any] {
                self.mediaJSON = json
                globals.alert(title: "Keywords Available",message: "The keywords for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nare available.")
            } else {
                globals.alert(title: "Keywords Not Available",message: "The keywords for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nare not available.")
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            globals.alert(title: "Keywords Not Available",message: "The keywords for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nare not available.")
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
    
    func alignUserInfo() -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            if let status = json?["status"] as? String, status == "finished" {
                globals.alert(title: "Transcript Realignment Complete",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nhas been realigned.")

                self.percentComplete = nil
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                // Don't do this because we're just re-uploading
                //                                self.transcribing = false
                //                                self.completed = true
                
                // These will NOT delete the existing versions.
                self._transcript = nil
                self._transcriptSRT = nil
                
                // Get the new versions.
                self.getTranscript()
                self.getTranscriptSRT()
                
                // This will NOT delete the existing versions.
                self._mediaJSON = nil
                
                // Get the new ones.
                self.details()
                
                self.aligning = false
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
            globals.alert(title: "Transcript Realignment Failed",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nwas not realigned.  Please try again.")
            
            //                        DispatchQueue.main.async(execute: { () -> Void in
            //                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
            //                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            //                        })
        }

        return userInfo.count > 0 ? userInfo : nil
    }
    
    func align()
    {
        guard completed else {
            // Should never happen.
            return
        }
        
        guard !aligning else {
            globals.alert(title:"Transcript Alignment in Progress", message:"The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis already being aligned.  You will be notified when it is completed.")
            return
        }
        
        aligning = true
        
        // Check whether the media is on VB
        progress(completion: { (json:[String : Any]?) -> (Void) in
            let parameters = ["transcript":self.transcript!,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
            
            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                // If it is on VB, upload the transcript for realignment
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        guard self.mediaID == mediaID else {
                            self.aligning = false
                            self.resultsTimer?.invalidate()
                            self.resultsTimer = nil
                            globals.alert(title: "Transcript Alignment Failed",message: "The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
                            return
                        }

                        // Don't do this because we're just re-aligning.
//                        self.transcribing = true
//                        self.completed = false
                        
                        globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nhas started.  You will be notified when it is complete.")
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(), repeats: true)
                        })
                    }
                } else {
                    // Not accepted
                    
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                globals.alert(title: "Transcript Alignment Failed",message: "The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
            })
        }, onError: { (json:[String : Any]?) -> (Void) in
            // Not on VoiceBase
            globals.alert(title:"Media Not on VoiceBase", message:"The media for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript realignment is started.")
            
            // Upload then then align
            self.mediaID = nil
            
            let parameters:[String:String] = ["media":self.url!,"metadata":self.metadata,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
            
            self.post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                if let status = json?["status"] as? String, status == "accepted" {
                    if let mediaID = json?["mediaId"] as? String {
                        // We do get a new mediaID
                        self.mediaID = mediaID
                        
                        globals.alert(title:"Media Upload Started", message:"The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nwill be started once the media upload has completed.")
                        
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
                                let parameters:[String:String] = ["transcript":self.transcript!,"configuration":"{\"configuration\":{\"executor\":\"v2\"}}"]
                                
                                self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                                    self.uploadJSON = json
                                    
                                    // If it is on VB, upload the transcript for realignment
                                    if let status = json?["status"] as? String, status == "accepted" {
                                        if let mediaID = json?["mediaId"] as? String {
                                            guard self.mediaID == mediaID else {
                                                self.aligning = false
                                                self.resultsTimer?.invalidate()
                                                self.resultsTimer = nil
                                                globals.alert(title: "Transcript Alignment Failed",message: "The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
                                                return
                                            }
                                            
                                            // Don't do this because we're just re-aligning.
                                            //                        self.transcribing = true
                                            //                        self.completed = false
                                            
                                            self.aligning = true
                                            
                                            globals.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nhas started.  You will be notified when it is complete.")
                                            
                                            DispatchQueue.main.async(execute: { () -> Void in
                                                self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(), repeats: true)
                                            })
                                        }
                                    } else {
                                        // Not accepted.
                                    }
                                }, onError: { (json:[String : Any]?) -> (Void) in
                                    self.aligning = false
                                    self.resultsTimer?.invalidate()
                                    self.resultsTimer = nil
                                    globals.alert(title: "Transcript Alignment Failed",message: "The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
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
                            globals.alert(title: "Transcript Alignment Failed",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nwas not realigned.  Please try again.")
                            
                            //                        DispatchQueue.main.async(execute: { () -> Void in
                            //                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                            //                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                            //                        })
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: userInfo, repeats: true)
                        })
                    }
                } else {
                    // No accepted.
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                globals.alert(title: "Transcript Alignment Failed",message: "The transcript realignment for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nfailed to start.  Please try again.")
            })
        })
    }
    
    func getTranscript()
    {
        guard let mediaID = mediaID else {
            upload()
            return
        }
        
        VoiceBase.get(accept:"text/plain",mediaID: mediaID, path: "transcripts/latest", completion: { (json:[String : Any]?) -> (Void) in
            if let text = json?["text"] as? String {
                self.transcript = text

                globals.alert(title: "Transcript Available",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis available.")
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                })
            } else {
                globals.alert(title: "Transcript Not Available",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis not available.")
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            globals.alert(title: "Transcript Not Available",message: "The transcript for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis not available.")
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
                            
                            var string : String?
                            
                            for str in srtArray {
                                string = string != nil ? string! + " " + str : str
                            }
                            
                            if let index = srtComponents.index(of: srtComponent) {
                                srtComponents[index] = "\(count)\n\(timeWindow)\n\(string!)"
                                changed = true
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
    
    func getTranscriptSRT()
    {
        VoiceBase.get(accept: "text/srt", mediaID: mediaID, path: "transcripts/latest", completion: { (json:[String : Any]?) -> (Void) in
            if let srt = json?["text"] as? String {
                self.transcriptSRT = srt
                globals.alert(title: "Transcript SRT Available",message: "The transcript SRT for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis available.")
            } else {
                globals.alert(title: "Transcript SRT Not Available",message: "The transcript SRT for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis not available.")
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            globals.alert(title: "Transcript SRT Not Available",message: "The transcript SRT for\n\(self.mediaItem!.text!) (\(self.transcriptPurpose))\nis not available.")
        })
    }
    
    func search(string:String?)
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
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
                    print(json)
                    
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
                DispatchQueue.main.async(execute: { () -> Void in

                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in

                })
            }
        })
        
        task.resume()
    }
}
