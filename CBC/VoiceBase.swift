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
        if let data = string.data8, !data.isEmpty { // (using: String.Encoding.utf8, allowLossyConversion: false)
            append(data)
        }
    }
}

//extension VoiceBase : URLSessionTaskDelegate
//{
//    // URLSessionTaskDelegate methods
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
//    {
//        // task finished
//
//    }
//}

//extension VoiceBase : URLSessionDataDelegate
//{
//    // URLSessionDataDelegate methods
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
//    {
//        // got some data
//
//    }
//
//    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
//    {
//
//    }
//}

extension VoiceBase // Class Methods
{
    private class func url(path:String?, query:String? = nil) -> String // mediaID:String?,
    {
        if path == nil, query == nil { // mediaID == nil,
            return Constants.URL.VOICE_BASE_ROOT + "?limit=1000"
        } else {
            var url = Constants.URL.VOICE_BASE_ROOT
            
            if let path = path {
                url += path
            }
            
//            if let mediaID = mediaID {
//                url += "/" + mediaID
//            }
            
            if let query = query {
                url += "?" + query
            }
            
            return url // Constants.URL.VOICE_BASE_ROOT + (mediaID != nil ? "/" + mediaID! : "") + (path != nil ? "/" + path! : "") + (query != nil ? "?" + query! : "")
        }
    }
    
    class func bulkDeleteMedia()
    {
        VoiceBase.all(completion:{ (json:[String:Any]?) -> Void in
            guard let json = json?["media"] as? [[String:Any]], !json.isEmpty else {
                Alerts.shared.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase.")
                return
            }
            
            var alertActions = [AlertAction]()
            alertActions.append(AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { () -> (Void) in
                VoiceBase.bulkDelete(alert: true)
            }))
            alertActions.append(AlertAction(title: Constants.Strings.No))
            Alerts.shared.alert(title: "Confirm Bulk Deletion of VoiceBase Media",
                                message: "This will delete all VoiceBase media files in the cloud for all transcripts generated on all devices using the same API key that is on this device.", actions:alertActions)
        },onError: nil)
    }
    
    class func deleteAllVoiceBaseMedia(mediaItems:[MediaItem]?, alert:Bool, detailedAlert:Bool)
    {
        guard let list = mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
            return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                return transcript.mediaID != nil
            }).count > 0
        }), let multiPartName = list.multiPartName else {
            Alerts.shared.alert(title: "No VoiceBase Media Were Deleted", message:mediaItems?.multiPartName)
            return
        }
        
        let checkIn = CheckIn()
        
        checkIn.reset()
        checkIn.total = list.reduce(0, { (result, mediaItem) -> Int in
            return result + mediaItem.transcripts.values.filter({ (voiceBase:VoiceBase) -> Bool in
                return voiceBase.mediaID != nil
            }).count
        })
        
        // [weak self]
        let monitorOperation = CancelableOperation() { (test:(()->Bool)?) in
            // How do I know all of the deletions were successful?
            
            //            guard let checkIn = self?.checkIn else {
            //                return
            //            }
            
            var cycles = 0
            while cycles < 10, ((checkIn.success + checkIn.failure) < checkIn.total) {
                Thread.sleep(forTimeInterval: 1.0)
                cycles += 1
            }
            
            var preamble = String()
            
            if checkIn.success == checkIn.total, checkIn.failure == 0 {
                preamble = "All "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:multiPartName)
            }
            
            if checkIn.failure == checkIn.total, checkIn.success == 0 {
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:multiPartName)
                
                preamble = "No "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Found\n(\(checkIn.failure) of \(checkIn.total))", message:multiPartName)
            }
            
            if checkIn.failure > 0, checkIn.failure < checkIn.total, checkIn.success > 0, checkIn.success < checkIn.total {
                preamble = "Some "
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Deleted\n(\(checkIn.success) of \(checkIn.total))", message:multiPartName)
                Alerts.shared.alert(title: "\(preamble)VoiceBase Media Were Not Found\n(\(checkIn.failure) of \(checkIn.total))", message:multiPartName)
            }
        }
        
        list.forEach({ (mediaItem:MediaItem) in
            mediaItem.transcripts.values.forEach({ (voiceBase:VoiceBase) in
                if voiceBase.mediaID != nil {
                    // [weak self]
                    let operation = CancelableOperation() { (test:(()->Bool)?) in
                        voiceBase.delete(alert:detailedAlert,
                                         // [weak self]
                            completion: { (json:[String:Any]?) in
                                checkIn.success += 1
                        },
                            // [weak self]
                            onError: { (json:[String:Any]?) in
                                checkIn.failure += 1
                        }
                        )
                    }
                    
                    monitorOperation.addDependency(operation)
                    
                    /////////////////////////////////////////////////////////////////////////////////////////////////////////
                    // Will NOT work if opQueue's maxConcurrentOperationCount == 1 WHY??? (>1, i.e. 2 or more it works fine.)
                    // could it be that because delete() creates a dataTask that it needs a way to run that task on this
                    // same opQueue, which it can't if the maxConcurrent is 1 and the op that calls delete() is running,
                    // meaning both are blocked because the second, the dataTask, is.
                    /////////////////////////////////////////////////////////////////////////////////////////////////////////
                    Globals.shared.media.mediaQueue.addOperation(operation)
                }
            })
        })
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Will NOT work if opQueue's maxConcurrentOperationCount == 1 WHY??? (>1, i.e. 2 or more it works fine.)
        // could it be that because delete() creates a dataTask that it needs a way to run that task on this
        // same opQueue, which it can't if the maxConcurrent is 1 and the op that calls delete() is running,
        // meaning both are blocked because the second, the dataTask, is.
        /////////////////////////////////////////////////////////////////////////////////////////////////////////
        Globals.shared.media.mediaQueue.addOperation(monitorOperation)
    }

    class func html(_ json:[String:Any]?) -> String?
    {
        guard let media = json else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if let accountName = media["accountName"] as? String {
            htmlString += "Account Name: \(accountName)\n"
        }
    
        if let accountId = media["accountId"] as? String {
            htmlString += "Account ID: \(accountId)\n"
        }
    
        if let mediaID = media["mediaId"] as? String {
            htmlString += "MediaID: \(mediaID)\n"
        }
        
        if let status = media["status"] as? String {
            htmlString += "Status: \(status)\n"
        }
        
        if let length = media["length"] as? String {
            htmlString += "Length: \(length)\n"
        }
    
        if let dateCreated = media["dateCreated"] as? String {
            htmlString += "Date Created: \(dateCreated)\n"
        }
    
        if let dateFinished = media["dateFinished"] as? String {
            htmlString += "Date Finished: \(dateFinished)\n"
        }
    
        if let mediaContentType = media["mediaContentType"] as? String {
            htmlString += "Media Content Type: \(mediaContentType)\n"
        }
    
        if let formatVersion = media["formatVersion"] as? String {
            htmlString += "Format Version: \(formatVersion)\n"
        }
    
//            if let job = media["job"] as? [String:Any] {
//                htmlString += "\nJob\n"
//
//                if let jobProgress = job["progress"] as? [String:Any] {
//                    if let jobStatus = jobProgress["status"] as? String {
//                        htmlString += "Job Status: \(jobStatus)\n"
//                    }
//                    if let jobTasks = jobProgress["tasks"] as? [String:Any] {
//                        htmlString += "Job Tasks: \(jobTasks.count)\n"
//
//                        var stats = [String:Int]()
//
//                        for task in jobTasks.keys {
//                            if let status = (jobTasks[task] as? [String:Any])?["status"] as? String {
//                                if let count = stats[status] {
//                                    stats[status] = count + 1
//                                } else {
//                                    stats[status] = 1
//                                }
//                            }
//                        }
//
//                        for key in stats.keys {
//                            if let value = stats[key] {
//                                htmlString += "\(key): \(value)\n"
//                            }
//                        }
//                    }
//                }
//            }
        
        if let metadata = media["metadata"] as? [String:Any] {
            htmlString += "\nMetadata\n"

            if let title = metadata["title"] as? String {
                htmlString += "Title: \(title)\n"
            }
            
            if let mediaItem = metadata["extended"] as? [String:Any] {
                if let category = mediaItem["category"] {
                    htmlString += "Category: \(category)\n"
                }
                
                if let id = mediaItem["id"] {
                    htmlString += "id: \(id)\n"
                }
                
                if let title = mediaItem["title"] {
                    htmlString += "Title: \(title)\n"
                }
                
                if let date = mediaItem["date"] {
                    htmlString += "Date: \(date)\n"
                }
                
                if let service = mediaItem["service"] {
                    htmlString += "Service: \(service)\n"
                }
                
                if let speaker = mediaItem["speaker"] {
                    htmlString += "Speaker: \(speaker)\n"
                }
                
                if let scripture = mediaItem["scripture"] {
                    htmlString += "Scripture: \(scripture)\n"
                }
                
                if let purpose = mediaItem["purpose"] {
                    htmlString += "Purpose: \(purpose)\n"
                }
                
                if let device = mediaItem["device"] as? [String:Any] {
                    htmlString += "\nDevice Information:\n"
                    
                    if let model = device["model"] {
                        htmlString += "Model: \(model)\n"
                    }
                    
                    if let modelName = device["modelName"] {
                        htmlString += "Model Name: \(modelName)\n"
                    }
                    
                    if let name = device["name"] {
                        htmlString += "Name: \(name)\n"
                    }
                    
                    if let deviceUUID = device["UUID"] {
                        htmlString += "UUID: \(deviceUUID)\n"
                    }
                }
            }
        }
            
        if let transcript = media["transcript"] as? [String:Any] {
            htmlString += "\nTranscript\n"
            
            if let engine = transcript["engine"] as? String {
                htmlString += "Engine: \(engine)\n"
            }
            
            if let confidence = transcript["confidence"] {
                htmlString += "Confidence: \(confidence)\n"
            }
            
            if let words = transcript["words"] as? [[String:Any]] {
                htmlString += "Words: \(words.count)\n"
            }
        }
            
//            if let keywords = media["keywords"] as? [String:Any] {
//                htmlString += "\nKeywords\n"
//
//                if let keywordsLatest = keywords["latest"] as? [String:Any] {
//                    if let words = keywordsLatest["words"] as? [[String:Any]] {
//                        htmlString += "Keywords: \(words.count)\n"
//                    }
//                }
//            }
//
//            if let topics = media["topics"] as? [String:Any] {
//                htmlString += "\nTopics\n"
//
//                if let topicsLatest = topics["latest"] as? [String:Any] {
//                    if let topics = topicsLatest["topics"] as? [[String:Any]] {
//                        htmlString += "Topics: \(topics.count)\n"
//                    }
//                }
//            }
//        }
        
        htmlString = htmlString.replacingOccurrences(of: "\n", with: "<br/><br/>") + "</body></html>"

        return htmlString
    }
    
    private class func get(accept:String?,path:String?,query:String?, completion:(([String:Any]?)->(Void))? = nil, onError:(([String:Any]?)->(Void))? = nil) // mediaID:String?,
    {
        // Critical to know if we are checking VB availability or not since we make a get to check if it is available!
        // If not, then we need to know if VB is available
        if !VoiceBase.checkingAvailability {
            if !(VoiceBase.isAvailable ?? false){
                return
            }
        }
        
        guard let voiceBaseAPIKey = VoiceBase.APIKey else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(path:path, query:query)) else { // mediaID:mediaID,
            return
        }

        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        if let accept = accept {
            request.addValue(accept, forHTTPHeaderField: "Accept")
        }
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: UUID().uuidString)
        let session = URLSession(configuration: sessionConfig)
        
        // Alternate using extension that uses Swift 5's new Result type.
        // Downside - .failure does NOT get to look at the http response
//        let task = session.dataTask(with: request) { (result) in
//            var errorOccured = false
//
//            var json : [String:Any]?
//
//            switch result {
//            case .success(let response, let data):
//                // Handle Data and Response
//                debug("post response: ",response.description)
//
//                if let httpResponse = response as? HTTPURLResponse {
//                    debug("post HTTP response: ",httpResponse.description)
//                    debug("post HTTP response: ",httpResponse.allHeaderFields)
//                    debug("post HTTP response: ",httpResponse.statusCode)
//                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
//
//                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
//                        errorOccured = true
//                    }
//                }
//
//                if data.count > 0 {
//                    let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
//
//                    if let acceptText = accept?.contains("text"), acceptText {
//                        json = ["text":string as Any]
//                    } else {
//                        json = data.json as? [String:Any]
//
//                        if let errors = json?["errors"] {
//                            print(string as Any)
//                            print(json as Any)
//                            print(errors)
//                            errorOccured = true
//                        }
//                    }
//                } else {
//                    // no data
//                    errorOccured = true
//                }
//                break
//
//            case .failure(let error):
//                // Handle Error - Don't get to see the response!
//                print("post error: ",error.localizedDescription)
//                errorOccured = true
//                break
//            }
//
//            if errorOccured {
//                Thread.onMain { [weak self] in 
//                    onError?(json)
//                }
//            } else {
//                Thread.onMain { [weak self] in 
//                    completion?(json)
//                }
//            }
//        }
        
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                debug("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    debug("post HTTP response: ",httpResponse.description)
                    debug("post HTTP response: ",httpResponse.allHeaderFields)
                    debug("post HTTP response: ",httpResponse.statusCode)
                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, !data.isEmpty {
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string as Any]
                } else {
                    json = data.json as? [String:Any]
//                    print(json)
                    if let errors = json?["errors"] {
                        print(string as Any)
                        print(json as Any)
                        print(errors)
                        errorOccured = true
                    }
                }
            } else {
                // no data
                errorOccured = true
            }
            
            if errorOccured {
                onError?(json)
//                Thread.onMain { [weak self] in 
//                }
            } else {
                completion?(json)
//                Thread.onMain { [weak self] in 
//                }
            }
        })
        
        task.resume()
    }
    
    private class func metadata(mediaID: String?, completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard let mediaID = mediaID else {
            return
        }
        // mediaID:mediaID,
        get(accept:nil, path:"media/\(mediaID)/metadata", query:nil, completion:completion, onError:onError)
    }

    private class func progress(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard let mediaID = mediaID else {
            return
        }
        
        // mediaID:mediaID,
        get(accept:nil, path:"media/\(mediaID)/progress", query:nil, completion:completion, onError:onError)
    }
    
    class func details(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard let mediaID = mediaID else {
            return
        }
        
        // mediaID:mediaID,
        get(accept:nil, path:"media/\(mediaID)", query:nil, completion:completion, onError:onError)
    }

    class func all(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        // mediaID:nil,
        get(accept:nil, path:"media", query:nil, completion:completion, onError:onError)
    }
    
    class func delete(alert:Bool,mediaID:String?, completion:(([String:Any]?)->(Void))? = nil, onError:(([String:Any]?)->(Void))? = nil)
    {
        print("VoiceBase.delete")

        guard VoiceBase.isAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = VoiceBase.APIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        // mediaID:mediaID, 
        guard let url = URL(string:VoiceBase.url(path:"media/\(mediaID)")) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: UUID().uuidString)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                debug("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    debug("post HTTP response: ",httpResponse.description)
                    debug("post HTTP response: ",httpResponse.allHeaderFields)
                    debug("post HTTP response: ",httpResponse.statusCode)
                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, !data.isEmpty {
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                debug(string as Any)
                
                json = data.json as? [String:Any]
                debug(json as Any)

                if let errors = json?["errors"] {
                    print(string as Any)
                    print(json as Any)
                    print(errors)
                    errorOccured = true
                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                if alert {
                    if let error = error?.localizedDescription {
                        Alerts.shared.alert(title:"Media NOT Removed From VoiceBase", message:"Error: " + error + "\n\nMedia ID: " + mediaID)
                    } else {
                        Alerts.shared.alert(title:"Media NOT Removed From VoiceBase", message:"Media ID: " + mediaID)
                    }
                }
                onError?(json)
//                Thread.onMain { [weak self] in 
//                }
            } else {
                if alert {
                    Alerts.shared.alert(notifyOnly:true, title:"Media Removed From VoiceBase", message:"Media ID: " + mediaID)
                }
                completion?(json)
//                Thread.onMain { [weak self] in 
//                }
            }
        })
        
        task.resume()
    }
    
    class func bulkDelete(alert:Bool, alertNone:Bool = true)
    {
        print("VoiceBase.bulkDelete")
        // This will only return up to 100
        
        // mediaID:nil,
        get(accept:nil,  path:"media", query:nil, completion: { (json:[String : Any]?) -> (Void) in
            if let mediaItems = json?["media"] as? [[String:Any]] {
                if mediaItems.count > 0 {
                    if alert {
                        if mediaItems.count > 1 {
                            Alerts.shared.alert(title: "Deleting \(mediaItems.count) Items from VoiceBase Media Library")
                        } else {
                            Alerts.shared.alert(title: "Deleting \(mediaItems.count) Item from VoiceBase Media Library")
                        }
                    }
                    
                    for mediaItem in mediaItems {
                        delete(alert:false,mediaID:mediaItem["mediaId"] as? String)
                    }
                    
                    // Keep going until they are all gone since it only does up to 100 at a time.
                    bulkDelete(alert:alert,alertNone:false) // alertNone == false => Don't tell when we've stopped.
                } else {
                    if alertNone {
                        Alerts.shared.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase.")
                    }
                }
            } else {
                // No mediaItems
                if alertNone {
                    Alerts.shared.alert(title: "No Items Deleted from the VoiceBase Media Library")
                }
            }
        }, onError:  { (json:[String : Any]?) -> (Void) in
            if alertNone {
                Alerts.shared.alert(title: "No Items Deleted from the VoiceBase Media Library")
            }
        })
    }
}

// Transcript
extension VoiceBase
{
    // thread safe?
    // s
    var transcriptJSON : [String:Any]?
    {
        get {
            // s
            return mediaJSON?["transcript"] as? [String:Any]
        }
    }
}

// Words
extension VoiceBase
{
    // thread safe?
    var words : [[String:Any]]?
    {
        get {
            // Latest
            return transcriptJSON?["words"] as? [[String:Any]]
        }
    }
    
    // thread safe?
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
    
    var transcriptFromWords : String?
    {
        get {
            var transcript:String?
            
            if let words = words {
                var index = 0
                
                for word in words {
                    if let string = (word["w"] as? String)?.folding(options: .diacriticInsensitive, locale: nil) {
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
}

// Knowledge - cleaned up for v3 but not used.
extension VoiceBase
{
    var knowledgeJSON: [String:Any]?
    {
        get {
            return mediaJSON?["knowledge"] as? [String:Any]
        }
    }
}

// Keywords - cleaned up for v3 but not used.
extension VoiceBase
{
    // thread safe?
    var keywordsJSON: [[String:Any]]?
    {
        get {
            return knowledgeJSON?["keywords"] as? [[String:Any]]
        }
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
    
    // thread safe?
    var keywordTimes : [String:[String]]?
    {
        get {
            guard let keywordDictionaries = keywordDictionaries else {
                return nil
            }
            
            var keywordTimes = [String:[String]]()
            
            for name in keywordDictionaries.keys {
                if let dict = keywordDictionaries[name], let mentions = dict["mentions"] as? [[String:Any]] {
                    for mention in mentions {
                        if let occurences = mention["occurrences"] as? [[String:Any]] {
                            keywordTimes[name] = occurences.compactMap({ (dict) -> String? in
                                return (Double((dict["s"] as? Int) ?? 0) / 1000.0).description.secondsToHMS
                            })
                        }
                    }
                }
            }
            
            return keywordTimes.count > 0 ? keywordTimes : nil
        }
    }
    
    // thread safe?
    var keywordDictionaries : [String:[String:Any]]?
    {
        get {
            //            if let latest = keywordsJSON?["latest"] as? [String:Any] {
            //                if let wordDictionaries = latest["words"] as? [[String:Any]] {
            if let wordDictionaries = keywordsJSON {
                var kwdd = [String:[String:Any]]()
                
                for dict in wordDictionaries {
                    if let name = dict["keyword"] as? String {
                        kwdd[name.uppercased()] = dict
                    }
                }
                
                return kwdd.count > 0 ? kwdd : nil
            }
            //            }
            
            return nil
        }
    }
    
    // thread safe?
    var keywords : [String]?
    {
        get {
            guard let keys = keywordDictionaries?.keys else {
                return nil
            }
            
            return Array(keys).sorted()
//            if let keywords = keywordDictionaries?.filter({ (key: String, value: [String : Any]) -> Bool in
//                if let speakerTimes = value["mentions"] as? [String:[String]] {
//                    if let times = speakerTimes["occurences"] {
//                        return times.count > 0
//                    }
//                }
//                return false
//            }).map({ (key: String, value: [String : Any]) -> String in
//                return key.uppercased()
//            }) {
//                return keywords.count > 0 ? keywords : nil
//            } else {
//                return nil
//            }
        }
    }
}

// Topics - cleaned up for v3 but not used.
extension VoiceBase
{
    // thread safe?
    var topicsJSON : [[String:Any]]?
    {
        get {
            return knowledgeJSON?["topics"] as? [[String:Any]]
        }
    }
    
    // thread safe?
    var topicsDictionaries : [String:[String:Any]]?
    {
        get {
            //            if let latest = topicsJSON?["latest"] as? [String:Any] {
            //                if let words = latest["topics"] as? [[String:Any]] {
            if let words = topicsJSON {
                var tdd = [String:[String:Any]]()
                
                for dict in words {
                    if let name = dict["topicName"] as? String {
                        tdd[name] = dict
                    }
                }
                
                return tdd.count > 0 ? tdd : nil
            } else {
                return nil
            }
            //            } else {
            //                return nil
            //            }
        }
    }
    
    // thread safe?
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
    
    func topicKeywordDictionaries(topic:String?) -> [String:[String:Any]]?
    {
        guard let topic = topic else {
            return nil
        }
        
        if let topicDictionary = topicsDictionaries?[topic] {
            if let keywordsDictionaries = topicDictionary["keywords"] as? [[String:Any]] {
                var kwdd = [String:[String:Any]]()
                
                for dict in keywordsDictionaries {
                    if let name = dict["keyword"] as? String {
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
    
    // Why not a dict of topics, each w/ all of their keywords
    // var allTopicKeywords : [String:[String]]?

    // OR ADD TIMES AS WELL
    // var allTopicKeywordsAndTimes : [String:[String:[String]]]? // where time is always a string.
    
    // Because we don't use them...
    
    // thread safe?
    var allTopicKeywords : [String]?
    {
        get {
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
    }
    
    // thread safe?
    var allTopicKeywordDictionaries : [String:[String:Any]]?
    {
        get {
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
    }
    
    // Needs work
//    func allTopicKeywordTimes(keyword:String?) -> [String]?
//    {
//        guard let keyword = keyword else {
//            return nil
//        }
//
//        if let keywordDictionary = allTopicKeywordDictionaries?[keyword] {
//            if let mentions = keywordDictionary["mentions"] as? [[String:Any]] {
//                for mention in mentions { // Assumes there is only one mention!
//                    if let occurences = mention["occurences"] as? [[String:Any]] {
//                        return occurences.compactMap({ (dict:[String : Any]) -> String? in
//                            return (dict["s"] as? Int)?.description
//                        }).sorted()
//                    }
//                }
//            }
//        }
//
//        return nil
//    }
}

// All downloading depends on app being active / foregroun until transcription is started
// because URLSessions are not setup for background because that requires the use of a delegate
// and not completion handlers.

/**
 
 Class to ecapsulate VoiceBase use for transcripts
 
 */

class VoiceBase
{
    // flag whether machine generated transcripts are allowed
    static var allowMGTs = true
    
    // Timer to keep checking on whether VoiceBase is available
    static var checkTimer : Timer?
    
    // Shadow property for voicebase availability.
    static var _isAvailable : Bool? // = false
    {
        didSet {
            guard _isAvailable != oldValue else {
                return
            }
            
            guard let _isAvailable = _isAvailable else {
                return
            }
            
            if !_isAvailable {
                if checkTimer == nil {
                    checkTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.ckVBA), userInfo:nil, repeats:true)
                }
            } else {
                checkTimer?.invalidate()
                checkTimer = nil
            }
            
            // Why?
            Thread.onMain {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
            }
        }
    }
    static var isAvailable : Bool? // = false
    {
        get {
            guard allowMGTs else {
                return false
            }
            
            guard Globals.shared.reachability.isReachable else {
                return false
            }
            
            return _isAvailable ?? false // checkingAvailability
        }
        set {
            _isAvailable = newValue
        }
    }
    
    // This is critical since we make a VB call to see if VB is available so we need to ignore the isVBAvailable nil or false
    static var checkingAvailability = false
    
    class func checkAvailability(completion:(()->(Void))? = nil)
    {
        isAvailable = nil
        
        guard Globals.shared.reachability.isReachable else {
            isAvailable = false
            completion?()
            return
        }
        
        // Tell the world we are checking
        checkingAvailability = true
        
        VoiceBase.all(completion: { (json:[String : Any]?) -> (Void) in
            self.isAvailable = true
            completion?()
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.isAvailable = false
                completion?()
        })
        
        // Tell the world we are done checking
        checkingAvailability = false
    }
    
    @objc class func ckVBA()
    {
        checkAvailability()
    }
    
    static var _APIKey : String?
    {
        didSet {
            if let key = _APIKey, !key.isEmpty {
                UserDefaults.standard.set(key, forKey: Constants.Strings.VoiceBase_API_Key)
                
                // Do we need to notify VoiceBase objects?
                // No, because if it was nil before there shouldn't be anything on VB.com
                // No, because if it was not nil before then they either the new KEY is good or bad.
                // If bad, then it will fail.  If good, then they will finish.
                // So, nothing needs to be done.
            } else {
                isAvailable = false
                UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
            }
            
            UserDefaults.standard.synchronize()
            
            if isAvailable == true {
                checkAvailability()
            }
        }
    }
    static var APIKey : String?
    {
        get {
            if _APIKey == nil {
                if let key = UserDefaults.standard.string(forKey: Constants.Strings.VoiceBase_API_Key), !key.isEmpty {
                    if key == Obfuscator().decode(key: [36, 9, 58, 116, 0, 52, 36, 14, 46, 29, 47, 5, 5, 126, 51, 3, 41, 32, 62, 41, 18, 55, 39, 12, 35, 12, 45, 40, 33, 31, 7, 98, 1, 11, 32, 92, 77, 17, 56, 58, 1, 32, 34, 7, 12, 40, 8, 61, 87, 0, 7, 25, 9, 48, 34, 50, 64, 12, 35, 65, 46, 40, 22, 35, 13, 45, 32, 52, 54, 9, 37, 51, 30, 42, 39, 33, 112, 41, 35, 116, 29, 54, 33, 49, 12, 45, 31, 4, 56, 22, 24, 2, 9, 58, 70, 8, 25, 60, 7, 47, 93, 6, 85, 55, 13, 54, 25, 2, 38, 45, 3, 47, 11, 16, 25, 34, 31, 9, 45, 27, 84, 40, 53, 50, 14, 23, 4, 26, 86, 48, 50, 54, 69, 24, 10, 61, 51, 63, 6, 35, 14, 56, 35, 48, 54, 30, 8, 36, 3, 42, 39, 31, 40, 60, 51, 14, 19, 15, 8, 3, 9, 22, 8, 34, 101, 22, 58, 56, 21, 1, 70, 116, 58, 42, 7, 44, 90, 44, 10, 59, 31, 60, 25, 30, 53, 44, 0, 52, 80, 56, 21, 49, 9, 10, 34, 33, 17, 61, 37, 57, 80, 0, 42, 127, 24, 36, 49, 4, 14, 13, 36, 50, 44, 42, 40, 36, 82, 44, 35, 44, 123, 30, 53, 59, 88, 40, 48, 61, 50, 57, 29, 18, 18, 13, 34, 49, 21, 46, 61, 4, 59, 45, 33, 35, 83, 57, 25, 7, 3, 19, 118, 48, 31, 44, 10, 13, 28, 1, 13, 26, 121, 47, 62, 48, 20, 57, 5, 61, 68, 9, 33, 15, 86, 41, 37, 45, 85, 3, 42, 56, 11, 11, 61, 45, 14, 8, 26, 31, 45, 4, 36, 55, 87, 2, 48, 10, 56, 31, 124, 6, 89, 1, 26, 65, 115, 18, 66, 40, 15, 54, 50, 45, 9, 23, 87, 27, 38, 22, 80, 83, 17, 42, 26, 113, 94, 61, 13, 12, 92, 33, 6, 47, 55, 40, 60, 60, 120, 52, 11, 23, 80, 23, 12, 5, 35, 112, 63, 38, 47, 87, 5, 76, 80, 23, 54, 34, 10, 38, 2, 19, 19, 114, 5, 68, 16, 52, 53, 32]) {

//"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE" {
                        
                        UserDefaults.standard.removeObject(forKey: Constants.Strings.VoiceBase_API_Key)
                    } else {
                        _APIKey = key
                    }
                }
            }
            
            #if targetEnvironment(simulator)
            // Simulator
                return Obfuscator().decode(key: [36, 9, 58, 116, 0, 52, 36, 14, 46, 29, 47, 5, 5, 126, 51, 3, 41, 32, 62, 41, 18, 55, 39, 12, 35, 12, 45, 40, 33, 31, 7, 98, 1, 11, 32, 92, 77, 17, 56, 58, 1, 32, 34, 7, 12, 40, 8, 61, 87, 0, 7, 25, 9, 48, 34, 50, 64, 12, 35, 65, 46, 40, 22, 35, 13, 45, 32, 52, 54, 9, 37, 51, 30, 42, 39, 33, 112, 41, 35, 116, 29, 54, 33, 49, 12, 45, 31, 4, 56, 22, 24, 2, 9, 58, 70, 8, 25, 60, 7, 47, 93, 6, 85, 55, 13, 54, 25, 2, 38, 45, 3, 47, 11, 16, 25, 34, 31, 9, 45, 27, 84, 40, 53, 50, 14, 23, 4, 26, 86, 48, 50, 54, 69, 24, 10, 61, 51, 63, 6, 35, 14, 56, 35, 48, 54, 30, 8, 36, 3, 42, 39, 31, 40, 60, 51, 14, 19, 15, 8, 3, 9, 22, 8, 34, 101, 22, 58, 56, 21, 1, 70, 116, 58, 42, 7, 44, 90, 44, 10, 59, 31, 60, 25, 30, 53, 44, 0, 52, 80, 56, 21, 49, 9, 10, 34, 33, 17, 61, 37, 57, 80, 0, 42, 127, 24, 36, 49, 4, 14, 13, 36, 50, 44, 42, 40, 36, 82, 44, 35, 44, 123, 30, 53, 59, 88, 40, 48, 61, 50, 57, 29, 18, 18, 13, 34, 49, 21, 46, 61, 4, 59, 45, 33, 35, 83, 57, 25, 7, 3, 19, 118, 48, 31, 44, 10, 13, 28, 1, 13, 26, 121, 47, 62, 48, 20, 57, 5, 61, 68, 9, 33, 15, 86, 41, 37, 45, 85, 3, 42, 56, 11, 11, 61, 45, 14, 8, 26, 31, 45, 4, 36, 55, 87, 2, 48, 10, 56, 31, 124, 6, 89, 1, 26, 65, 115, 18, 66, 40, 15, 54, 50, 45, 9, 23, 87, 27, 38, 22, 80, 83, 17, 42, 26, 113, 94, 61, 13, 12, 92, 33, 6, 47, 55, 40, 60, 60, 120, 52, 11, 23, 80, 23, 12, 5, 35, 112, 63, 38, 47, 87, 5, 76, 80, 23, 54, 34, 10, 38, 2, 19, 19, 114, 5, 68, 16, 52, 53, 32])

//            return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE"
            #else
            // Device
            if UIDevice.current.name.contains("Leeke-") {
                return Obfuscator().decode(key: [36, 9, 58, 116, 0, 52, 36, 14, 46, 29, 47, 5, 5, 126, 51, 3, 41, 32, 62, 41, 18, 55, 39, 12, 35, 12, 45, 40, 33, 31, 7, 98, 1, 11, 32, 92, 77, 17, 56, 58, 1, 32, 34, 7, 12, 40, 8, 61, 87, 0, 7, 25, 9, 48, 34, 50, 64, 12, 35, 65, 46, 40, 22, 35, 13, 45, 32, 52, 54, 9, 37, 51, 30, 42, 39, 33, 112, 41, 35, 116, 29, 54, 33, 49, 12, 45, 31, 4, 56, 22, 24, 2, 9, 58, 70, 8, 25, 60, 7, 47, 93, 6, 85, 55, 13, 54, 25, 2, 38, 45, 3, 47, 11, 16, 25, 34, 31, 9, 45, 27, 84, 40, 53, 50, 14, 23, 4, 26, 86, 48, 50, 54, 69, 24, 10, 61, 51, 63, 6, 35, 14, 56, 35, 48, 54, 30, 8, 36, 3, 42, 39, 31, 40, 60, 51, 14, 19, 15, 8, 3, 9, 22, 8, 34, 101, 22, 58, 56, 21, 1, 70, 116, 58, 42, 7, 44, 90, 44, 10, 59, 31, 60, 25, 30, 53, 44, 0, 52, 80, 56, 21, 49, 9, 10, 34, 33, 17, 61, 37, 57, 80, 0, 42, 127, 24, 36, 49, 4, 14, 13, 36, 50, 44, 42, 40, 36, 82, 44, 35, 44, 123, 30, 53, 59, 88, 40, 48, 61, 50, 57, 29, 18, 18, 13, 34, 49, 21, 46, 61, 4, 59, 45, 33, 35, 83, 57, 25, 7, 3, 19, 118, 48, 31, 44, 10, 13, 28, 1, 13, 26, 121, 47, 62, 48, 20, 57, 5, 61, 68, 9, 33, 15, 86, 41, 37, 45, 85, 3, 42, 56, 11, 11, 61, 45, 14, 8, 26, 31, 45, 4, 36, 55, 87, 2, 48, 10, 56, 31, 124, 6, 89, 1, 26, 65, 115, 18, 66, 40, 15, 54, 50, 45, 9, 23, 87, 27, 38, 22, 80, 83, 17, 42, 26, 113, 94, 61, 13, 12, 92, 33, 6, 47, 55, 40, 60, 60, 120, 52, 11, 23, 80, 23, 12, 5, 35, 112, 63, 38, 47, 87, 5, 76, 80, 23, 54, 34, 10, 38, 2, 19, 19, 114, 5, 68, 16, 52, 53, 32])

//                return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI2NTVkZGQ4MS1jMzFjLTQxZjQtODU1YS0xZDVmYzJkYzhlY2IiLCJ1c2VySWQiOiJhdXRoMHw1OTFkYWU4ZWU1YzMwZjFiYWUxMGFiODkiLCJvcmdhbml6YXRpb25JZCI6ImZkYWMzNjQ3LTAyNGMtZDM5Ny0zNTgzLTBhODA5MWI5MzY2MSIsImVwaGVtZXJhbCI6ZmFsc2UsImlhdCI6MTUwMDM4MDc3NDY0MywiaXNzIjoiaHR0cDovL3d3dy52b2ljZWJhc2UuY29tIn0.MIi0DaNCMro7Var3cMuS4ZJJ0d85YemhLgpg3u4TQYE"
            }
            #endif
            
            return _APIKey
        }
        set {
            _APIKey = newValue
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// VoiceBase API for Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem?
    
    static let separator = "\n\n" // "------------"
    
    // ,\"transcripts\":
    static let customVocab = "{\"vocabularies\": [{\"terms\":[\"Genesis\",\"Exodus\",\"Leviticus\",\"Numbers\",\"Deuteronomy\",\"Joshua\",\"Judges\",\"Ruth\",\"1 Samuel\",\"2 Samuel\",\"1 Kings\",\"2 Kings\",\"1 Chronicles\",\"2 Chronicles\",\"Ezra\",\"Nehemiah\",\"Esther\",\"Job\",\"Psalms\",\"Proverbs\",\"Ecclesiastes\",\"Song of Solomon\",\"Isaiah\",\"Jeremiah\",\"Lamentations\",\"Ezekiel\",\"Daniel\",\"Hosea\",\"Joel\",\"Amos\",\"Obadiah\",\"Jonah\",\"Micah\",\"Nahum\",\"Habakkuk\",\"Zephaniah\",\"Haggai\",\"Zechariah\",\"Malachi\",\"Matthew\",\"Mark\",\"Luke\",\"John\",\"Acts\",\"Romans\",\"1 Corinthians\",\"2 Corinthians\",\"Galatians\",\"Ephesians\",\"Philippians\",\"Colossians\",\"1 Thessalonians\",\"2 Thessalonians\",\"1 Timothy\",\"2 Timothy\",\"Titus\",\"Philemon\",\"Hebrews\",\"James\",\"1 Peter\",\"2 Peter\",\"1 John\",\"2 John\",\"3 John\",\"Jude\",\"Revelation\"]}]}"
    
    static let includeVocab = false
    
//    static let configuration:String? = "{\"transcript\": { \"formatting\":{ \"enableNumberFormatting\": true } } }"
    
    //includeVocab ? customVocab : "" // "{\"configuration\":{\"executor\":\"v2\"\(includeVocab ? customVocab : "")}}"
    
    var title:String?
    {
        get {
            guard let title = mediaItem?.title else {
                return nil
            }
            
            return title + " (\(transcriptPurpose))"
        }
    }
    
    var unchanged : Bool
    {
        get {
            guard let transcriptString = transcript?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return false
            }
            
            guard let transcriptFromWordsString = transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return false
            }
            
            return transcriptString == transcriptFromWordsString
        }
    }
    
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

    var metadata : String?
    {
        get {
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard mediaItem.mediaCode != nil else {
                return nil
            }
            
            guard let title = mediaItem.title?.replacingOccurrences(of: "'s", with: Constants.RIGHT_SINGLE_QUOTE + "s").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "\"")) else {
                return nil
            }
            
            var mediaItemString = "{"
            
            if let mediaID = mediaID {
                mediaItemString += "\"title\":\"\(title) (\(transcriptPurpose))\n\(mediaID)\","
            } else {
                mediaItemString += "\"title\":\"\(title) (\(transcriptPurpose))\","
            }
            
            mediaItemString += "\"extended\":{" // mediaItem
            
            if let category = mediaItem.category {
                mediaItemString += "\"category\":\"\(category)\","
            }
            
            if let id = mediaItem.mediaCode {
                mediaItemString += "\"id\":\"\(id)\","
            }
            
            if let date = mediaItem.date {
                mediaItemString += "\"date\":\"\(date)\","
            }
            
            if let service = mediaItem.service {
                mediaItemString += "\"service\":\"\(service)\","
            }
            
            //
            mediaItemString += "\"title\":\"\(title)\","
            
            //                if let text = mediaItem.text {
            //                    mediaItemString += "\"text\":\"\(text) (\(transcriptPurpose))\","
            //                }
            
            if let scripture = mediaItem.scripture {
                mediaItemString += "\"scripture\":\"\(scripture.description)\","
            }
            
            if let speaker = mediaItem.speaker {
                mediaItemString += "\"speaker\":\"\(speaker)\","
            }
            
            mediaItemString += "\"purpose\":\"\(transcriptPurpose)\","
            
            mediaItemString += "\"device\":{"
            
            mediaItemString += "\"name\":\"\(UIDevice.current.name)\","
            
            mediaItemString += "\"model\":\"\(UIDevice.current.localizedModel)\","
            
            if let uuid = UIDevice.current.identifierForVendor?.description {
                mediaItemString += "\"UUID\":\"\(uuid)\""
            }
            
            mediaItemString += "}"
            
            mediaItemString += "}"
            
            mediaItemString += "}"
            
            return mediaItemString        }
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
            
            Thread.onMain { [weak self] in 
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self?.mediaItem)
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
            
            if completed {
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
            }

            mediaItem?.mediaItemSettings?["completed."+purpose] = completed ? "YES" : "NO"

            Thread.onMain { [weak self] in 
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self?.mediaItem)
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
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
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
            
            if aligning {
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
            }
        }
    }
    
    var totalChanges = 0
    
    var percentCompleteFormatted:String?
    {
        get {
            guard let percentComplete = percentComplete else {
                return nil
            }
            
            return String(format: "%0.0f",percentComplete * 100)
        }
    }
    
    var percentComplete:Double?
    {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            return mediaItem?.percentComplete["TRANSCRIPT"+purpose]
        }
        set {
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.percentComplete["TRANSCRIPT"+purpose] = newValue
        }
    }

    // Make thread safe?
    var uploadJSON:[String:Any]?
    
    // Prevents a background thread from creating multiple timers accidentally
    // by accessing transcript before the timer creation on the main thread is complete.
//    var settingTimer = false

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
                
                if let range = mp4?.range(of: "&profile_id=175"), let root = mp4?[..<range.lowerBound] { // .upperBound
                    mp4 = root.description + "&profile_id=174"
                }
                
                return mp4
                
            case Purpose.audio:
                return mediaItem?.audioURL
                
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
    
    var filename : String?
    {
        get {
            if let mediaCode = mediaItem?.mediaCode, let purpose = purpose {
                return mediaCode + "." + purpose + Constants.FILENAME_EXTENSION.transcript
            } else {
                return nil
            }
        }
    }
    
    var oldFilename : String?
    {
        get {
            if let mediaCode = mediaItem?.mediaCode, let purpose = purpose {
                return mediaCode + "." + purpose
            } else {
                return nil
            }
        }
    }
    
    func initialize()
    {
        // Assumed to be called from lazy initializer.
        
        // In case app was killed during auto editing.
        mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Auto_Edit + " - " + transcriptPurpose)
//        if Globals.shared.isLoading {
//        }
        
        // TRANSCRIBING
        if !completed && transcribing && !aligning && (self.resultsTimer == nil) { //  && !settingTimer
//            settingTimer = true
            if Globals.shared.isLoading {
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
            }
            Thread.onMain { [weak self] in 
                self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                self.settingTimer = false
            }
        } else {
            // Overkill to make sure the cloud storage is cleaned-up?
            //                mediaItem.voicebase?.delete()
            // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
            if self.resultsTimer != nil {
                debug("TIMER NOT NIL!")
            }
        }
        
        // ALIGNING
        if completed && !transcribing && aligning && (self.resultsTimer == nil) { //  && !settingTimer
//            settingTimer = true
            if Globals.shared.isLoading {
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
            }
            Thread.onMain { [weak self] in 
                self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                self.settingTimer = false
            }
        } else {
            // Overkill to make sure the cloud storage is cleaned-up?
            //                mediaItem.voicebase?.delete()
            // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
            if self.resultsTimer != nil {
                debug("TIMER NOT NIL!")
            }
        }
        
        // !settingTimer is CRUCIAL since the timer is set in a DISPATCH to the MAIN thread above.
//        if _transcript == nil, resultsTimer == nil, mediaID != nil { // , !settingTimer
//            mediaID = nil
//        }
        
        if !transcribing {
            mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
        }
        
        if !aligning {
            mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
        }
        
        if !completed {
            mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
        }
    }
    
    // Replaced with Fetch?
    private var _transcript:String?
    {
        didSet {
            
        }
    }
    var transcript:String?
    {
        get {
            guard (_transcript == nil) else {
                return _transcript
            }

//            guard mediaID != nil else {
//                return nil
//            }

            if completed {
                _transcript = filename?.fileSystemURL?.string16?.folding(options: .diacriticInsensitive, locale: nil)
                
                if _transcript == nil {
                    completed = false
                }
            }

//            if completed {
//                if _transcript == nil {
//                    // In case app was killed during auto editing.
//                    if Globals.shared.isLoading {
//                        mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Auto_Edit + " - " + transcriptPurpose)
//                    }
//                }
//
//                _transcript = filename?.fileSystemURL?.string16?.folding(options: .diacriticInsensitive, locale: nil)
//
//                if _transcript == nil {
//                    completed = false
//                }
//            }

//            if Globals.shared.isLoading {
//                // TRANSCRIBING
//                if !completed && transcribing && !aligning && (self.resultsTimer == nil) && !settingTimer {
//                    settingTimer = true
//                    if Globals.shared.isLoading {
//                        mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
//                    }
//                    Thread.onMain { [weak self] in 
//                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                        self.settingTimer = false
//                    }
//                } else {
//                    // Overkill to make sure the cloud storage is cleaned-up?
//                    //                mediaItem.voicebase?.delete()
//                    // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
//                    if self.resultsTimer != nil {
//                        debug("TIMER NOT NIL!")
//                    }
//                }
//
//                // ALIGNING
//                if completed && !transcribing && aligning && (self.resultsTimer == nil) && !settingTimer {
//                    settingTimer = true
//                    if Globals.shared.isLoading {
//                        mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
//                    }
//                    Thread.onMain { [weak self] in 
//                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
//                        self.settingTimer = false
//                    }
//                } else {
//                    // Overkill to make sure the cloud storage is cleaned-up?
//                    //                mediaItem.voicebase?.delete()
//                    // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
//                    if self.resultsTimer != nil {
//                        debug("TIMER NOT NIL!")
//                    }
//                }
//
//                // !settingTimer is CRUCIAL since the timer is set in a DISPATCH to the MAIN thread above.
//                if _transcript == nil, resultsTimer == nil, !settingTimer, mediaID != nil {
//                    mediaID = nil
//                }
//
//                if !transcribing {
//                    mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Transcribing + " - " + transcriptPurpose)
//                }
//
//                if !aligning {
//                    mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Aligning + " - " + transcriptPurpose)
//                }
//
//                if !completed {
//                    mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
//                }
//            }

            return _transcript
        }
        set {
            _transcript = newValue

            if _transcript != nil {
                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                
                fileQueue.addOperation { [weak self] in
                    self?._transcript?.save16(filename: self?.filename) // Keep in mind that this is being saved in the cache folder where it could disappear.
                }
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                
                fileQueue.addOperation { [weak self] in
                    self?.filename?.fileSystemURL?.delete(block:true)
                }
            }

//            guard let mediaItem = mediaItem else {
//                return
//            }
            
            //            if mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
            //                return transcript._transcript != nil // self._
            //            }).count == 0
            
//            if newValue == nil {
//                // This blocks this thread until it finishes. NO IT DOESN'T.
//                mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
//            } else {
//                // This blocks this thread until it finishes. NO IT DOESN'T.
//                mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
//            }
        }
    }
    
    var wordRangeTiming : [[String:Any]]?
    {
        get {
            guard let transcript = transcript else { // ?.lowercased()
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
                    offset = transcript.range(of: text, options: .caseInsensitive, range: nil, locale: nil)?.lowerBound
                }

                if offset != nil {
                    let startingRange = Range(uncheckedBounds: (lower: offset!, upper: transcript.endIndex))
                    
                    if let range = transcript.range(of: text, options: .caseInsensitive, range: startingRange, locale: nil) {
                        dict["range"] = range
                        dict["lowerBound"] = range.lowerBound.utf16Offset(in: transcript)// encodedOffset
                        dict["upperBound"] = range.upperBound.utf16Offset(in: transcript)// encodedOffset
                        offset = range.upperBound
                    }
                }

                if let metadata = word["m"] as? String { // , metadata == "punc"
//                    print(word["w"],metadata)
                } else {
                    wordRangeTiming.append(dict)
                }
            }
            
            return wordRangeTiming.count > 0 ? wordRangeTiming : nil
        }
    }
    
    // Replaced with Fetch?
    // Make thread safe?
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

            guard let filename = filename else {
                return nil
            }
            
            if let url = ("\(filename).media").fileSystemURL, let data = url.data {
                _mediaJSON = data.json as? [String:Any]

//                do {
//                    _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
//                } catch let error {
//                    print("failed to load machine generated media for \(mediaItem.description): \(error.localizedDescription)")
//                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
////                    if completed && !aligning {
////                        remove()
////                    }
//                }
            } else {
                print("failed to get data for \(mediaItem.description)")
                
                // Legacy
                if let oldFilename = oldFilename, let url = ("\(oldFilename).media").fileSystemURL, let data = url.data {
                    _mediaJSON = data.json as? [String:Any]
                    
//                    do {
//                        _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
//                    } catch let error {
//                        print("failed to open machine generated media (again) for \(mediaItem.description)",error.localizedDescription)
//                    }
                }
                
                // Not sure I want to do this since it only removes keywords
//                remove()
            }

            return _mediaJSON
        }
        set {
            _mediaJSON = newValue

            guard let filename = filename else {
                print("failed to get filename")
                return
            }
            
            guard let destinationURL = (filename + Constants.FILENAME_EXTENSION.media).fileSystemURL else {
                print("failed to get destinationURL")
                return
            }
            
            fileQueue.addOperation { [weak self] in
                if newValue != nil {
                    do {
                        try JSONSerialization.data(withJSONObject: newValue, options: .sortedKeys).string8?.save8(filename: filename + Constants.FILENAME_EXTENSION.media)
                    } catch let error {
                        print("failed to save mediaJSON: \(error.localizedDescription)")
                    }
                    
                    //                if self?._mediaJSON != nil {
                    //                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: self?._mediaJSON as Any, format: .xml, options: 0)
                    //
                    //                    do {
                    //                        try mediaPropertyList?.write(to: destinationURL)
                    //                    } catch let error {
                    //                        print("failed to write machine generated transcript media to cache directory: \(error.localizedDescription)")
                    //                    }
                    //                } else {
                    //                    destinationURL.delete(block:true)
                    //                }
                    
                } else {
                    destinationURL.delete(block:true)
                }
            }
        }
    }

    @objc func freeMemory()
    {
        _mediaJSON = nil
        _transcript = nil
    }
    
    init?(mediaItem:MediaItem?,purpose:String?)
    {
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        guard let purpose = purpose else {
            return nil
        }
        
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
            
//            if !completed {
//                if transcribing || aligning {
//                    // We need to check and see if it is really on VB and if not, clean things up.
//
//                }
//            } else {
//                if transcribing || aligning {
//                    // This seems wrong.
//
//                }
//            }
        }
        
        Thread.onMain { // [weak self] in
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    lazy var fileQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "VoiceBase:Files" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
        fileQueue.cancelAllOperations()
    }
    
    func createBody(parameters: [String: String],boundary: String) -> NSData
    {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            switch key {
//            case "vocabulary":
//                let mimeType = "application/json"
//                body.appendString(boundaryPrefix)
//                body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"CBC\"\r\n")
//                body.appendString("Content-Type: \(mimeType)\r\n\r\n")
//                body.appendString(value)
//                body.appendString("\r\n")
//                break

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
    
    // mediaID:String?,
    func post(path:String?, parameters:[String:String]?, completion:(([String:Any]?)->(Void))? = nil, onError:(([String:Any]?)->(Void))? = nil)
    {
        guard VoiceBase.isAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = VoiceBase.APIKey else {
            return
        }
        
        guard let parameters = parameters else {
            return
        }
        
        // mediaID:mediaID,
        guard let url = URL(string:VoiceBase.url(path:path)) else {
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
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: UUID().uuidString)
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
                    debug("post HTTP response: ",httpResponse.description)
                    debug("post HTTP response: ",httpResponse.allHeaderFields)
                    debug("post HTTP response: ",httpResponse.statusCode)
                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))

                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }

            var json : [String:Any]?

            if let data = data, !data.isEmpty {
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                debug(string as Any)
                
                json = data.json as? [String:Any]
                debug(json as Any)
                
                if let errors = json?["errors"] {
                    print(string as Any)
                    print(json as Any)
                    print(errors)
                    errorOccured = true
                }
            } else {
                // no data
                
            }

            if errorOccured {
                onError?(json)
//                Thread.onMain { [weak self] in 
//                }
            } else {
                completion?(json)
//                Thread.onMain { [weak self] in 
//                }
            }
        })
        
        task.resume()
    }
    
    private func userInfo(alert:Bool,//detailedAlerts:Bool,
                  finishedTitle:String?,finishedMessage:String?,onFinished:(()->(Void))?,
                  errorTitle:String?,errorMessage:String?,onError:(()->(Void))?) -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { [weak self] (json:[String : Any]?) -> (Void) in
            guard let transcriptPurpose = self?.transcriptPurpose else {
                return
            }
            
            guard let status = json?["status"] as? String else {
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self?.resultsTimer?.invalidate()
                self?.resultsTimer = nil
                
                self?.percentComplete = nil
                
                onError?()
                return
            }

            guard let title = self?.mediaItem?.title else {
                return
            }
            
            switch status {
            case "finished":
                if alert, let finishedTitle = finishedTitle {
                    Alerts.shared.alert(title: finishedTitle,message: finishedMessage)
                }
                
                self?.resultsTimer?.invalidate()
                self?.resultsTimer = nil
                
                self?.percentComplete = nil
                
                onFinished?()
                break
                
            case "failed":
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self?.resultsTimer?.invalidate()
                self?.resultsTimer = nil
                
                self?.percentComplete = nil
                
                onError?()
                break
                
            default:
                guard let progress = json?["progress"] as? [String:Any] else {
                    print("\(title) (\(transcriptPurpose)) no progress")
                    break
                }
                
                guard let tasks = progress["tasks"] as? [[String:Any]] else {
                    print("\(title) (\(transcriptPurpose)) no tasks")
                    break
                }
                
                let count = tasks.count
                let finished = tasks.filter({ (dict:[String:Any]) -> Bool in
                    if let status = dict["status"] as? String {
                        return (status == "finished") || (status == "completed")
                    }
                    
                    return false
                }).count
                
                if count > 0 {
                    self?.percentComplete = Double(finished)/Double(count) // String(format: "%0.0f",) //  * 100.0
                } else {
                    self?.percentComplete = 0
                }
                
                if let percentComplete = self?.percentComplete {
                    print("\(title) (\(transcriptPurpose)) is \(String(format: "%0.1f",percentComplete * 100))% finished")
                }
                break
            }
        }
        
        userInfo["onError"] = { [weak self] (json:[String : Any]?) -> (Void) in
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
                if let text = self?.mediaItem?.text {
                    print("An unknown error occured while monitoring the transcription of \n\n\(text).")
                } else {
                    print("An unknown error occured while monitoring a transcription.")
                }
            }
            
            onError?()
        }
        
        return userInfo.count > 0 ? userInfo : nil
    }
    
    private func uploadUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, //detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcription Completed", finishedMessage: "The transcription process for\n\n\(text) (\(self.transcriptPurpose))\n\nhas completed.", onFinished: {
                            self.getTranscript(alert:detailedAlerts,detailedAlerts:detailedAlerts)
                        },
                        errorTitle: "Transcription Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again.", onError: {
                            self.delete(alert:false)
                            self.reset()
                            
                            Thread.onMain { [weak self] in 
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self?.mediaItem)
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
    
    func upload(url:String?)
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        var parameters:[String:String] = ["mediaUrl":url] //,"metadata":metadata
        
//        parameters["configuration"] = VoiceBase.configuration
        
        parameters["metadata"] = self.metadata
        
        parameters["configuration"] = """
            {
                "transcript":
                {
                    "formatting":{
                        "enableNumberFormatting" : false
                    }
                },
                "knowledge":
                {
                    "enableDiscovery" : false,
                    "enableExternalDataSources" : false
                }
            }
        """

        let path = "media" + (mediaID != nil ? "/\(mediaID!)" : "")
        
        // mediaID:mediaID,
        
        post(path:path, parameters:parameters, completion: { (json:[String : Any]?) -> (Void) in
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
                    Thread.onMain { [weak self] in 
                        self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    }
                } else {
                    debug("TIMER NOT NIL!")
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
            
            Thread.onMain { [weak self] in 
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self?.mediaItem)
            }
        })
    }
    
    func progress(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard let mediaID = mediaID else {
            return
        }
        
        // mediaID: nil,
        VoiceBase.get(accept:nil, path: "media/\(mediaID)/progress", query: nil, completion: completion, onError: onError)
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
    
    func delete(alert:Bool = false,completion:(([String:Any]?)->(Void))? = nil, onError:(([String:Any]?)->(Void))? = nil)
    {
        VoiceBase.delete(alert: alert, mediaID: self.mediaID, completion: completion, onError: onError)
        
//        guard VoiceBase.isAvailable ?? false else {
//            return
//        }
//        
//        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
//            return
//        }
//        
//        guard let mediaID = mediaID else {
//            return
//        }
//
//        // mediaID:mediaID,
//        guard let url = URL(string: VoiceBase.url(path:"media/\(mediaID)", query: nil)) else {
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        
//        request.httpMethod = "DELETE"
//        
//        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
//        
//        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: UUID().uuidString)
//        let session = URLSession(configuration: sessionConfig)
//        
//        // URLSession.shared
//        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
//            var errorOccured = false
//            
//            if let error = error {
//                print("post error: ",error.localizedDescription)
//                errorOccured = true
//            }
//            
//            if let response = response {
//                debug("post response: ",response.description)
//                
//                if let httpResponse = response as? HTTPURLResponse {
//                    debug("post HTTP response: ",httpResponse.description)
//                    debug("post HTTP response: ",httpResponse.allHeaderFields)
//                    debug("post HTTP response: ",httpResponse.statusCode)
//                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
//                    
//                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
//                        errorOccured = true
//                    }
//                    
//                    if (httpResponse.statusCode == 204) || (httpResponse.statusCode == 404) {
//                        // It eithber completed w/o error (204) so it is now gone and we should set mediaID to nil
//                        // OR it couldn't be found (404) in which case it should also be set to nil.
//
//                        // WE DO NOT HAVE TO SET THIS TO NIL.
//                        // self.mediaID = nil
//                    }
//                }
//            } else {
//                errorOccured = true
//            }
//            
//            var json : [String:Any]?
//            
//            if let data = data, data.count > 0 {
//                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
//                debug(string as Any)
//
//                json = data.json as? [String:Any]
//                debug(json as Any)
//                
//                if let errors = json?["errors"] {
//                    print(string as Any)
//                    print(json as Any)
//                    print(errors)
//                    errorOccured = true
//                }
//            } else {
//                // no data
//                
//            }
//            
//            if errorOccured {
//                // ???
//                onError?(json)
////                Thread.onMain { [weak self] in 
////                }
//            } else {
//                completion?(json)
////                Thread.onMain { [weak self] in 
////                }
//            }
//        })
//        
//        task.resume()
    }
    
    func details(completion:(([String:Any]?)->())?,onError:(([String:Any]?)->())?)
    {
        VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
            completion?(json)
        }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
            onError?(json)
        })
    }
    
    func reset(alert:Bool = false)
    {
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
        
        // Fetch shoudl NOT be set to nil.
        // Unless cache is being used it doesn't
        // even need to be cleared.
//        transcriptSegments = nil
        
        if alert, let text = self.mediaItem?.text {
            Alerts.shared.alert(title:"Transcript Deleted", message:"The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been deleted.")
        }
    }
    
    private func details(alert:Bool, atEnd:(()->())?)
    {
        details(completion: { (json:[String : Any]?) -> (Void) in
            self.mediaJSON = json

            if alert {
                if let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Details Available",message: "The transcript details for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
                } else {
                    Alerts.shared.alert(title: "Transcript Details Available",message: "The transcript details are available.")
                }
            }
            
//            if alert, let text = self.mediaItem?.text {
//                Alerts.shared.alert(title: "Keywords Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
//            }
//            if let json = json?["media"] as? [String:Any] {
//                self.mediaJSON = json
//                if alert, let text = self.mediaItem?.text {
//                    Alerts.shared.alert(title: "Keywords Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
//                }
//            } else {
//                if alert, let text = self.mediaItem?.text {
//                    Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
//                }
//            }

            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert {
                if let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Details Not Available",message: "The transcript details for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
                } else {
                    Alerts.shared.alert(title: "Transcript Details Not Available",message: "The transcript details are not available.")
                }
            }
            
//            if alert {
//                if let text = self.mediaItem?.text {
//                    Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
//                } else {
//                    Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords are not available.")
//                }
//            }

            atEnd?()
        })
    }
    
    func metadata(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard let mediaID = mediaID else {
            return
        }
        
        VoiceBase.get(accept:nil, path:"media/\(mediaID)/metadata", query:nil, completion:completion, onError:onError)
    }
    
//    func addMetaData()
//    {
//        guard let mediaID = mediaID else {
//            return
//        }
//
//        var parameters:[String:String] = ["metadata":metadata]
//
//        parameters["configuration"] = VoiceBase.configuration
//
//        // mediaID:mediaID,
//        post(path:"media/\(mediaID)/metadata", parameters:parameters, completion: { (json:[String : Any]?) -> (Void) in
//
//        }, onError: { (json:[String : Any]?) -> (Void) in
//
//        })
//    }
    
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
    
    private func alignUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }

        return userInfo(alert: alert, //detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Alignment Complete", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been realigned.", onFinished: {
                            // Get the new versions.
                            self.getTranscript(alert:detailedAlerts,detailedAlerts:detailedAlerts) {
                                self.aligning = false
                                
                                // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
                                // sure I can predict the context in which this (i.e. that) would happen.
                            }
                            
//                            self.getTranscript(alert:detailedAlerts) {
////                                self.correctAlignedTranscript()
//                                self.getTranscriptSegments(alert:detailedAlerts) {
//                                    self.details(alert:detailedAlerts) {
//                                        self.aligning = false
//
//                                        // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
//                                        // sure I can predict the context in which this (i.e. that) would happen.
//                                    }
//                                }
//                            }
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
        guard let mediaID = mediaID else {
            return
        }
        
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
            
//            parameters["configuration"] = VoiceBase.configuration

            // mediaID:self.mediaID,
            self.post(path:"media/\(mediaID)", parameters:parameters, completion: { (json:[String : Any]?) -> (Void) in
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
                        Thread.onMain { [weak self] in 
                            self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                        }
                    } else {
                        debug("TIMER NOT NIL!")
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
            
            var parameters:[String:String] = ["media":url] // ,"metadata":self.metadata
            
            parameters["metadata"] = self.metadata

//            parameters["configuration"] = VoiceBase.configuration

            // mediaID:self.mediaID,
            self.post(path:"media", parameters:parameters, completion: { (json:[String : Any]?) -> (Void) in
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
                        let newUserInfo = self.userInfo(alert: false, //detailedAlerts: false,
                                                        finishedTitle: nil, finishedMessage: nil, onFinished: {
                                                            // Now do the relignment
                                                            var parameters:[String:String] = ["transcript":transcript]
                                                            
//                                                            parameters["configuration"] = VoiceBase.configuration

                                                            // mediaID:mediaID,
                                                            self.post(path:"media/\(mediaID)", parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
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
                                                                        Thread.onMain { [weak self] in 
                                                                            self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                                        }
                                                                    } else {
                                                                        debug("TIMER NOT NIL!")
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
                        
                        Thread.onMain { [weak self] in 
                            self?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: newUserInfo, repeats: true)
                        }
                    } else {
                        debug("TIMER NOT NIL!")
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
    
    func performAutoEdit()
    {
        guard !self.isAutoEditUnderway else {
            // AutoEdit underway
            return
        }
        
        var alertActions = [AlertAction]()
        
        var message:String?
        
        if let text = self.mediaItem?.text {
            message = text + " (\(self.transcriptPurpose))"
        }
        
        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
            self.confirmAutoEdit()
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: {
            
        }))
        
        Alerts.shared.alert(title:"Perform " + Constants.Strings.Auto_Edit, message: message, actions: alertActions)
    }
    
    func getTranscript(alert:Bool = true,detailedAlerts:Bool = false,completion:(()->())? = nil)
    {
        getTranscript(alert: alert) {
            self.getTranscriptSegments(alert:detailedAlerts) {
                self.details(alert:detailedAlerts) {
                    if let completion = completion {
                        completion()
                    } else {
                        self.transcribing = false
                        self.completed = true
                        self.percentComplete = nil
                    }
                    
                    // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
                    // sure I can predict the context in which this (i.e. that) would happen.
                    self.performAutoEdit()
                }
            }
        }
    }
    
    private func getTranscript(alert:Bool, onSuccess:(()->())? = nil) // , onFailure:(()->())? = nil
    {
        guard let mediaID = mediaID else {
            upload(url: url)
            return
        }
        
        // mediaID:mediaID, // latest // s
        VoiceBase.get(accept:"text/plain", path:"media/\(mediaID)/transcript/text", query:nil, completion: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                debug(error)
            }
            
            guard let text = json?["text"] as? String else {
                if alert {
                    var message : String?
                    
                    if let text = self.mediaItem?.text {
                        message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available."
                    }
                    
                    if let error = error {
                        if message != nil {
                            message = message! + "\n\n"
                        }
                        message = (message ?? "") + "Error: \(error)"
                    }
                    
                    Alerts.shared.alert(title: "Transcript Not Available",message: message)
                }
                
                self.delete(alert:false)
                self.reset()

                return
            }
            
            self.transcript = text.folding(options: .diacriticInsensitive, locale: nil)
            
            if alert {
                var message : String?
                
                if let text = self.mediaItem?.text {
                    message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis available."
                }
                
                Alerts.shared.alert(title: "Transcript Available",message: message)
            }
            
            onSuccess?()
            
            Thread.onMain { [weak self] in 
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                debug(error)
            }
            
            if alert {
                var message : String?
                
                if let text = self.mediaItem?.text {
                    message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
                }
                
                if let error = error {
                    if message != nil {
                        message = message! + "\n\n"
                    }
                    message = (message ?? "") + "Error: \(error)"
                }
                
                Alerts.shared.alert(title: "Transcription Failed",message: message)
            }
            
//            onFailure?()

            self.delete()
            self.reset()
        })
    }
    
    
    lazy var transcriptSegmentArrays:Fetch<[[String]]>? = { [weak self] in
        let fetch = Fetch<[[String]]>()
        
        fetch.fetch = { [weak self] in
            guard let transcriptSegmentComponents = self?.transcriptSegmentComponents?.result else {
                return nil
            }
            
            var transcriptSegmentArrays = [[String]]()
            
            for transcriptSegmentComponent in transcriptSegmentComponents {
                transcriptSegmentArrays.append(transcriptSegmentComponent.components(separatedBy: "\n"))
            }
            
            return transcriptSegmentArrays.count > 0 ? transcriptSegmentArrays : nil
        }
        
        return fetch
    }()
    
    lazy var transcriptSegmentTokensTimes:Fetch<[String:[String]]>? = { [weak self] in
        let fetch = Fetch<[String:[String]]>()
    
        fetch.fetch = { [weak self] in
            guard let transcriptSegmentArrays = self?.transcriptSegmentArrays?.result else {
                return nil
            }
            
            var tokenTimes = [String:[String]]()
            
            for transcriptSegmentArray in transcriptSegmentArrays {
                if let times = self?.transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray), let startTime = times.first {
                    if let tokens = self?.transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)?.tokens {
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
            
            return tokenTimes.count > 0 ? tokenTimes : nil
        }
        
        return fetch
    }()
    
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
            string += " " + element.lowercased()
        }
        
        return !string.isEmpty ? string : nil
    }
    
    func searchTranscriptSegmentArrays(string:String) -> [[String]]?
    {
        guard let transcriptSegmentArrays = transcriptSegmentArrays?.result else {
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
    
    lazy var transcriptSegmentComponents:Fetch<[String]>? = { [weak self] in
        let fetch = Fetch<[String]>()
        
        fetch.fetch = { [weak self] in
            return self?.transcriptSegments?.result?.components(separatedBy: VoiceBase.separator)
        }
        
        return fetch
    }()
    
    lazy var transcriptSegments:Fetch<String>? = { [weak self] in
        let fetch = Fetch<String>()
        
        fetch.retrieve = { [weak self] in
            guard let filename = self?.filename else {
                print("failed to get filename")
                return nil
            }
            
            return (filename + Constants.FILENAME_EXTENSION.segments).fileSystemURL?.string16 // "\(filename).segments".fileSystemURL?.string16
        }
        
        fetch.store = { [weak self] (string:String?) in
            guard let filename = self?.filename else {
                print("failed to get filename")
                return
            }
            
            string?.save16(filename:filename + Constants.FILENAME_EXTENSION.segments) // Keep in mind that this is being saved in the cache folder where it could disappear.
        }
        
        return fetch
    }()
    
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
    
    private func getTranscriptSegments(alert:Bool, atEnd:(()->())?)
    {
        guard let mediaID = mediaID else {
            return
        }
        
        // s/latest
        VoiceBase.get(accept:"text/vtt", path:"media/\(mediaID)/transcript/webvtt", query:nil, completion: { (json:[String : Any]?) -> (Void) in
            if let transcriptSegments = json?["text"] as? String {
                self.transcriptSegments?.store?(transcriptSegments)
                
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
                Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments are not available.")
            }
            
            atEnd?()
        })
    }
    
    func search(string:String?, completion:(([String:Any]?)->(Void))? = nil, onError:(([String:Any]?)->(Void))? = nil)
    {
        guard VoiceBase.isAvailable ?? false else {
            return
        }
        
        guard let voiceBaseAPIKey = VoiceBase.APIKey else {
            return
        }
        
        guard let string = string else {
            return
        }
        
        var service = VoiceBase.url(path: "media", query: nil)
        service = service + "?query=" + string
        
        guard let url = URL(string:service) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: UUID().uuidString)
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
                    debug("post HTTP response: ",httpResponse.description)
                    debug("post HTTP response: ",httpResponse.allHeaderFields)
                    debug("post HTTP response: ",httpResponse.statusCode)
                    debug("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, !data.isEmpty {
                let string = data.string8 // String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                debug(string as Any)
                
                json = data.json as? [String:Any]
                debug(json as Any)
                
                if let errors = json?["errors"] {
                    print(string as Any)
                    print(json as Any)
                    print(errors)
                    errorOccured = true
                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                onError?(json)
//                Thread.onMain { [weak self] in 
//                }
            } else {
                completion?(json)
//                Thread.onMain { [weak self] in 
//                }
            }
        })
        
        task.resume()
    }

    private func relaodUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, //detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Reload Completed", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been reloaded.", onFinished: {
                            self.getTranscript(alert:detailedAlerts,detailedAlerts:detailedAlerts) {

                                // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
                                // sure I can predict the context in which this (i.e. that) would happen.
                                
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
        
        let completion = " (\(transcriptPurpose))" + (percentCompleteFormatted != nil ? "\n(\(percentCompleteFormatted!)% complete)" : "")
        
        var title = "Machine Generated Transcript "
        
        var message = "You will be notified when the machine generated transcript"
        
        if let text = self.mediaItem?.text {
            message += " for\n\n\(text)\(completion) "
        }
        
        guard (mediaID == nil) else {
            title += "in Progress"
            message += "\n\nis available."
            
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Media ID", style: .default, handler: {
                var message : String?
                
                if let text = self.mediaItem?.text {
                    message = text + " (\(self.transcriptPurpose))"
                }
                
                var alertItems = [AlertItem]()
                alertItems.append(AlertItem.text(self.mediaID))
                alertItems.append(AlertItem.action(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil)))
                Alerts.shared.alert(title: "VoiceBase Media ID", message: message, items: alertItems)
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
            
            Alerts.shared.alert(title:title, message:message, actions:actions)
            
            return
        }
        
        title += "Requested"
        message += "\n\nhas started."
        
        Alerts.shared.alert(title:title, message:message)
    }

    func confirmAlignment(source:String, action:(()->())?) // viewController:UIViewController,
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

        Alerts.shared.alert(title: "Confirm Alignment of Machine Generated Transcript From \(source)", message: "This may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.", actions: alertActions)
    }
    
    func selectAlignmentSource(viewController:UIViewController)
    {
        guard let text = self.mediaItem?.text else {
            return
        }
        
        var alertActions = [AlertAction]()

        // This is aligning the VB to the official transcript, not the edited VB transcript!
        if (self.mediaItem?.hasNotesText == true) {
            alertActions.append(AlertAction(title: Constants.Strings.HTML_Transcript, style: .destructive, handler: {
                self.confirmAlignment(source:Constants.Strings.HTML_Transcript) { // viewController:viewController
                    // test:(()->(Bool))?
                    viewController.process(work: { [weak self] () -> (Any?) in
                        return self?.mediaItem?.notesText // self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
                    }, completion: { [weak self] (data:Any?) in
                            self?.align(data as? String) // stripHTML(self?.mediaItem?.notesHTML.result)
                    })
                }
            }))
        }

        // This is aligning the VB transcript to the (presumably) edited VB transcript!
        alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
            self.confirmAlignment(source:Constants.Strings.Transcript) { // viewController:viewController
                self.align(self.transcript)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .destructive, handler: {
            self.confirmAlignment(source:Constants.Strings.Segments) { // viewController:viewController
                self.align(self.transcriptSegmentComponents?.result?.transcriptFromTranscriptSegments)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Words, style: .destructive, handler: {
            self.confirmAlignment(source:Constants.Strings.Words) { // viewController:viewController
                self.align(self.transcriptFromWords)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: {

        }))
        
        Alerts.shared.alert(title: "Select Source for Alignment", message: text, actions: alertActions)
    }
    
    // This is used to keep track of auto edit and must be accessible, i.e. not private
    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "VoiceBase:Operations" + UUID().uuidString
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
        let preambles = ["chapters","chapter","verses","verse"]
        
        return preambles.count > 0 ? preambles : nil
    }

    func continuations() -> [String]?
    {
        let continuations = ["through","and","to"]
        
        return continuations.count > 0 ? continuations : nil
    }
    
    func keyOrder() -> [String]?
    {
        var keyOrder = ["words","books"]
        
        if let preambles = preambles() {
            keyOrder.append(contentsOf:preambles)
        }
        
        if let continuations = continuations() {
            keyOrder.append(contentsOf: continuations)
        }
        
        keyOrder.append("textToNumbers")
        
        return keyOrder.count > 0 ? keyOrder : nil
    }
    
    func changes(interactive:Bool, longFormat:Bool) -> [(String,String)]?
    {
        guard var masterChanges = masterChanges(interactive:interactive, longFormat:longFormat) else {
            return nil
        }
        
        guard let keyOrder = keyOrder() else {
            return nil
        }
        
        let masterKeys = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
            let firstIndex = keyOrder.firstIndex(of: first)
            let secondIndex = keyOrder.firstIndex(of: second)
            
            if let firstIndex = firstIndex, let secondIndex = secondIndex {
                return firstIndex < secondIndex
            }
            
            if firstIndex != nil {
                return true
            }
            
            if secondIndex != nil {
                return false
            }
            
            return first.endIndex > second.endIndex
        })
        
//        for masterKey in masterKeys {
//            if !["words","books","textToNumbers"].contains(masterKey) {
//                if !text.lowercased().contains(masterKey.lowercased()) {
//                    masterChanges[masterKey] = nil
//                }
//            }
//        }

        var changes = [(String,String)]()
        
        for masterKey in masterKeys {
            if let keys = masterChanges[masterKey]?.keys {
                var masterKeyChanges = [(String,String)]()
                
                for key in keys {
                    let oldText = key
                    if let newText = masterChanges[masterKey]?[key] {
                        masterKeyChanges.append((oldText,newText))
                    }
                }
                
                if masterKeyChanges.count > 0 {
                    changes.append(contentsOf: masterKeyChanges)
                }
            }
        }
        
        return changes.count > 0 ? changes.sorted(by: { (first, second) -> Bool in
            guard first.0.endIndex != second.0.endIndex else {
                if  Constants.singleNumbers.keys.contains(first.0), let first = Constants.singleNumbers[first.0],
                    Constants.singleNumbers.keys.contains(second.0), let second = Constants.singleNumbers[second.0] {
                    return Int(first) > Int(second)
                }
                
                return first.0 < second.0
            }
            
            return first.0.endIndex > second.0.endIndex
        }) : nil
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
        if maxNumber > 0 {
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
                        if let bookName = books[book], let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: bookName) {
                            if Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                                if changes[book] == nil {
                                    changes[book] = ["\(book) " + key:"\(bookName) " + value]
                                } else {
                                    changes[book]?["\(book) " + key] = "\(bookName) " + value
                                }
                            }
                        }
                        
                        if let bookName = books[book], let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: bookName) {
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
                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book), Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
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
                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book), Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                                if changes[book.lowercased()] == nil {
                                    changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                                } else {
                                    changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                                }
                            }
                        } else {
                            
                        }
                    }
                }
            }
        }
        
        if !interactive {
            for singleNumberKey in Constants.singleNumbers.keys {
                changes["textToNumbers"]?[singleNumberKey] =  nil
            }
        }

        if maxNumber > 0 {
            for number in 1...maxNumber {
                if !interactive, Constants.singleNumbers.values.contains(number.description) {
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
        }
//        print(changes)
        return changes.count > 0 ? changes : nil
    }
    
    func addParagraphBreaks(showGapTimes:Bool, gapThreshold:Double? = nil, tooClose:Int? = nil, words:[[String:Any]]?, text:String?, test:(()->Bool)? = nil, completion:((String?)->(Void))?)
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
        
        if let test = test, test() {
            return
        }
        
        let first = words.removeFirst()
        
        if totalChanges > 0 {
            percentComplete = 1.0 - Double(words.count)/Double(totalChanges) // String(format: "%0.0f",()) //  * 100.0
        } else {
            percentComplete = 0
        }
        
        guard let range = first["range"] as? Range<String.Index> else {
            operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, test:test, completion:completion)
            }
            return
        }

        let gap = first["gap"] as? Double
        
        var gapString = "\n\n"
        
        if showGapTimes, let gap = gap {
            gapString = "<\(gap)>" + gapString
        }

        //////////////////////////////////////////////////////////////////////////////
        // If words.first["range"] (either lowerBound or upperBound) is "too close"
        // (whatever that is defined to be) to a paragraph break then we should skip
        // and move on to the next word.
        //////////////////////////////////////////////////////////////////////////////
        
        if let tooClose = tooClose {
            var lowerRange : Range<String.Index>?
            var upperRange : Range<String.Index>?
            
            var rng : Range<String.Index>?
            
            var searchRange : Range<String.Index>?
            
            searchRange = Range(uncheckedBounds: (lower: text.startIndex, upper: range.lowerBound))

            rng = text.range(of: "\n\n", options: .caseInsensitive, range:searchRange, locale: nil)
            
            // But even if there is a match we have to find the LAST match
            if rng != nil {
                repeat {
                    lowerRange = rng
                    searchRange = Range(uncheckedBounds: (lower: rng!.upperBound, upper: range.lowerBound))
                    rng = text.range(of: "\n\n", options: .caseInsensitive, range:searchRange, locale: nil)
                } while rng != nil
            } else {
                // NONE FOUND BEFORE
            }
            
            // Too close to the previous?
            if let lowerRange = lowerRange {
                if (lowerRange.upperBound.utf16Offset(in: text) + tooClose) > range.lowerBound.utf16Offset(in: text) {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    if let test = test, test() {
                        return
                    }

                    // This turns recursion into serial and avoids stack overflow.
                    operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, test:test, completion:completion)
                    }
                    return
                }
            } else {
                // There is no previous.
                
                // Too close to the start?
                if (text.startIndex.utf16Offset(in: text) + tooClose) > range.lowerBound.utf16Offset(in: text) {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    if let test = test, test() {
                        return
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, test:test, completion:completion)
                    }
                    return
                }
            }
            
            searchRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
            
            upperRange = text.range(of: "\n\n", options: .caseInsensitive, range:searchRange, locale: nil)
            
            // Too close to the next?
            if let upperRange = upperRange {
                if (range.upperBound.utf16Offset(in: text) + tooClose) > upperRange.lowerBound.utf16Offset(in: text) {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    if let test = test, test() {
                        return
                    }
                    
                    // This turns recursion into serial and avoids stack overflow.
                    operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, test:test, completion:completion)
                    }
                    return
                }
            } else {
                // There is no next.
                
                // Too close to end?
                if (range.lowerBound.utf16Offset(in: text) + tooClose) > text.endIndex.utf16Offset(in: text) {
                    guard gap >= gapThreshold else {
                        return
                    }
                    
                    if let test = test, test() {
                        return
                    }

                    // This turns recursion into serial and avoids stack overflow.
                    operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                        self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:text, test:test, completion:completion)
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
        
        if let test = test, test() {
            return
        }

        operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
            self?.addParagraphBreaks(showGapTimes:showGapTimes, gapThreshold:gapThreshold, tooClose:tooClose, words:words, text:newText, test:test, completion:completion)
        }
    }
    
    struct Change
    {
        var oldText:String?
        var newText:String?
        var range:Range<String.Index>?
    }
    
    func changeText(text:String?, startingRange:Range<String.Index>?, changes:[(String,String)]?, test:(()->Bool)? = nil, completion:((String)->(Void))?)
    {
        guard var text = text else {
            return
        }

        guard var changes = changes, let change = changes.first else {
            completion?(text)
            return
        }
        
        if let test = test, test() {
            return
        }
        
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
        
        if let range = range {
            let prior = String(text[..<range.lowerBound]).last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let following = String(text[range.upperBound...]).first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // what about other surrounding characters besides newlines and whitespaces, and periods if following?
            // what about other token delimiters?
            if (prior?.isEmpty ?? true) && ((following?.isEmpty ?? true) || (following == ".")) {
                if let test = test, test() {
                    return
                }
                
                percentComplete = 1.0 - Double(changes.count)/Double(totalChanges) // String(format: "%0.0f",()) //  * 100.0

//                print("Changes left:",changes.count, percentComplete ?? "", "%")

                operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                    text.replaceSubrange(range, with: newText)
                    
                    let before = String(text[..<range.lowerBound])
                    
                    if let completedRange = text.range(of: before + newText) {
                        let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                        
                        self?.changeText(text:text, startingRange:startingRange, changes:changes, test:test, completion:completion)
                    } else {
                        // ERROR
                    }
                }
            } else {
                if let test = test, test() {
                    return
                }
                
                percentComplete = 1.0 - Double(changes.count)/Double(totalChanges) // String(format: "%0.0f",()) //  * 100.0

//                print("Changes left:",changes.count, percentComplete ?? "", "%")

                operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                    let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                    
                    self?.changeText(text:text, startingRange:startingRange, changes:changes, test:test, completion:completion)
                }
            }
        } else {
            if let test = test, test() {
                return
            }
            
            percentComplete = 1.0 - Double(changes.count)/Double(totalChanges) // String(format: "%0.0f",())  //  * 100.0

//            print("Changes left:",changes.count, percentComplete ?? "", "%")
            
            operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                changes.removeFirst()
                self?.changeText(text:text, startingRange:nil, changes:changes, test:test, completion:completion)
            }
        }
    }
    
    // We need a way to report how long autoEdit takes.
    // We also need a way to report progress on a percentage basis

    func cancelAutoEdit(alert:Bool)
    {
        // Not sure why we tag cancellable operations with tag:Constants.Strings.Auto_Edit when we just cancel everything.
        self.operationQueue.cancelAllOperations()
        self.mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Auto_Edit + " - " + self.transcriptPurpose)
        
        self.percentComplete = nil
        
        //                            self.operationQueue.waitUntilAllOperationsAreFinished()
        
        guard alert else {
            return
        }
        
        if let text = self.mediaItem?.text {
            Alerts.shared.alert(title: Constants.Strings.Auto_Edit_Canceled, message: "\(text) (\(self.transcriptPurpose))")
        } else {
            Alerts.shared.alert(title: Constants.Strings.Auto_Edit_Canceled)
        }
    }
    
    func cancelAutoEdit(confirm:Bool,alert:Bool)
    {
        guard confirm else {
            cancelAutoEdit(alert:alert)
            return
        }
        
        var alertActions = [AlertAction]()
        
        let yesAction = AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: {
            () -> Void in
            if let text = self.mediaItem?.text {
                Alerts.shared.alert(title: Constants.Strings.Canceling_Auto_Edit, message: "\(text) (\(self.transcriptPurpose))")
            } else {
                Alerts.shared.alert(title: Constants.Strings.Canceling_Auto_Edit)
            }

            self.cancelAutoEdit(alert:alert)
        })
        alertActions.append(yesAction)
        
        let noAction = AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: {
            () -> Void in
            
        })
        alertActions.append(noAction)
        
        if let text = self.mediaItem?.text {
            Alerts.shared.alert(title: Constants.Strings.Confirm_Cancel_Auto_Edit, message: "\(text) (\(self.transcriptPurpose))", actions: alertActions)
        } else {
            Alerts.shared.alert(title: Constants.Strings.Confirm_Cancel_Auto_Edit, actions: alertActions)
        }
    }
    
    func autoEditUnderway()
    {
        guard let purpose = purpose else {
            return
        }
        
        var message = String()
        
        if let text = self.mediaItem?.text {
            message = "for\n\n\(text)"
            message += "\n(\(self.transcriptPurpose))"
            if let percentCompleteFormatted = self.percentCompleteFormatted {
                message += "\n(\(percentCompleteFormatted)% complete)"
            }
            message += "\n\n"
        }
        
        message += "You will be notified when it is complete."
        
        var alertActions = [AlertAction]()
        
        let cancelAction = AlertAction(title: Constants.Strings.Cancel_Auto_Edit, style: .destructive, handler: {
            () -> Void in
            self.cancelAutoEdit(confirm: true, alert: true)
        })
        alertActions.append(cancelAction)
        
        let okayAction = AlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: {
            () -> Void in
            
        })
        alertActions.append(okayAction)
        
        Alerts.shared.alert(title: Constants.Strings.Auto_Edit_Underway, message: message, actions: alertActions)
    }
    
    func confirmAutoEdit()
    {
        var message = String()
        
        if let text = self.mediaItem?.text {
            message = "for\n\n\(text)"
            message += "\n(\(self.transcriptPurpose))"
            message += "\n\n"
        }

        var alertActions = [AlertAction]()
        
        let yesAction = AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
            self.autoEdit()
        })
        alertActions.append(yesAction)
        
        let noAction = AlertAction(title: Constants.Strings.No, style: .default, handler: {
            
        })
        alertActions.append(noAction)
        
        Alerts.shared.alert(title: Constants.Strings.Confirm_Auto_Edit, message: message, actions: alertActions)
    }
    
    var isAutoEditUnderway : Bool
    {
        get {
            return operationQueue.operationCount != 0
        }
    }
    
    func autoEdit(notify:Bool = true)
    {
        guard !isAutoEditUnderway else {
            var message = String()
        
            if let text = self.mediaItem?.text {
                message = "for\n\n\(text)"
                message += "\n(\(self.transcriptPurpose))"
                if let percentCompleteFormatted = self.percentCompleteFormatted {
                    message += "\n(\(percentCompleteFormatted)% complete)"
                }
                message += "\n\n"
            }
            
            message += "You will be notified when it is complete."
            
            if notify {
                Alerts.shared.alert(title:"Auto Edit Already Underway",message:message)
            }
            return
        }
        
        guard !self.aligning else {
            if notify {
                if let percentCompleteFormatted = self.percentCompleteFormatted { // , let text = self.mediaItem?.text
                    Alerts.shared.alert(title: "Alignment Underway",
                                        message: "There is an alignment underway (\(percentCompleteFormatted)% complete) for:\n\n\(self.mediaItem?.text ?? "") (\(self.transcriptPurpose))\n\nPlease try again later.")
                } else {
                    Alerts.shared.alert(title: "Alignment Underway",
                                        message: "There is an alignment underway for:\n\n\(self.mediaItem?.text ?? "") (\(self.transcriptPurpose))\n\nPlease try again later.")
                }
            }
            return
        }
        
        if notify {
            autoEditUnderway()
        }
        
        operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
            self?.mediaItem?.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Auto_Edit + " - " + (self?.transcriptPurpose ?? ""))

            func textChanges()
            {
                guard let text = self?.transcript else {
                    return
                }
                
                guard var masterChanges = self?.masterChanges(interactive:false, longFormat:true) else {
                    return
                }
                
                if let test = test, test() {
                    return
                }
                
                var changes = [(String,String)]()
                
                // THIS IS A VERY, VERY LONG RUNNING LOOP
                for masterKey in masterChanges.keys {
                    if let test = test, test() {
                        return
                    }
                    
                    if let keys = masterChanges[masterKey]?.keys {
                        for key in keys {
                            if let test = test, test() {
                                return
                            }
                            
                            let oldText = key
                            if let newText = masterChanges[masterKey]?[key] {
                                // In case we don't want to prefilter the edits (delay now or later)
                                changes.append((oldText,newText))
                            }
                        }
                    }
                }
                
                if let test = test, test() {
                    return
                }
                
                // THIS IS NOT THE RIGHT WAY TO SORT CHANGES - WHY?
                changes.sort(by: { (first, second) -> Bool in
                    guard first.0.endIndex != second.0.endIndex else {
                        if Constants.singleNumbers.values.contains(first.0), Constants.singleNumbers.values.contains(second.0) {
                            return Constants.singleNumbers[first.0] > Constants.singleNumbers[second.0]
                        }
                        
                        return first.0 < second.0
                    }
                    
                    return first.0.endIndex > second.0.endIndex
                })
                
                if let test = test, test() {
                    return
                }
                
                self?.totalChanges = changes.count
                print("Total changes:",changes.count)
                
                if let test = test, test() {
                    return
                }
                
                self?.operationQueue.addCancelableOperation(tag:Constants.Strings.Auto_Edit) { [weak self] (test:(() -> Bool)?) in
                    self?.changeText(text: text, startingRange: nil, changes: changes, test:test, completion: { (string:String) -> (Void) in
                        var message = String()
                        
                        if let text = self?.mediaItem?.text {
                            message = "for\n\n\(text)"
                            message += "\n(\(self?.transcriptPurpose ?? ""))"
                        }
                        
                        Alerts.shared.alert(title:"Auto Edit Completed", message:message)
                        self?.transcript = string
                        self?.percentComplete = nil
                        self?.mediaItem?.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Auto_Edit + " - " + (self?.transcriptPurpose ?? ""))
                    })
                }
            }
            
//            let transcriptString = self?.transcript?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
//            let transcriptFromWordsString = self?.transcriptFromWords?.replacingOccurrences(of: ".  ", with: ". ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
//            transcriptString == transcriptFromWordsString
            
            if self?.unchanged == true {
                // Can insert paragraph breaks
                
                let mediaItems = Globals.shared.media.repository.list
//                ?.filter({ (mediaItem:MediaItem) -> Bool in
//                    mediaItem.speaker == self?.mediaItem?.speaker // self?.mediaItem?.teacher?.name
//                })
                
                // speakerNotesParagraph has a lot of work inside.  How do we update percentComplete while this is going on?
                
                // First try using only transcripts from this speaker, if there aren't any, then use all that can be found.
                let speakerNotesParagraph = mediaItems?.speakerNotesParagraph(name:self?.mediaItem?.speaker) ?? mediaItems?.speakerNotesParagraph

                // self?.mediaItem?.teacher?.
                let tooClose = speakerNotesParagraph?.overallAverageLength ?? 700 // default value is arbitrary - at best based on trial and error
                
                // self?.mediaItem?.teacher?.
                let speakerNotesParagraphWords = speakerNotesParagraph?.words?.result
                
                // Multiply the gap time by the frequency of the word that appears after it and sort
                // in descending order to suggest the most likely paragraph breaks.
                
                if  let speakerNotesParagraphWords = speakerNotesParagraphWords,
                    let words = self?.wordRangeTiming?.sorted(by: { (first, second) -> Bool in
                    if let firstGap = first["gap"] as? Double, let secondGap = second["gap"] as? Double {
                        if let firstWord = first["text"] as? String, let secondWord = second["text"] as? String {
                            return (firstGap * Double(speakerNotesParagraphWords[firstWord.lowercased()] ?? 1)) > (secondGap * Double(speakerNotesParagraphWords[secondWord.lowercased()] ?? 1))
                        }
                    }
                    
                    return first["gap"] != nil
                }) {
                    guard let text = self?.transcript else {
                        return
                    }
                    
                    self?.totalChanges = words.count
                    print("Total changes:",words.count)

                    self?.addParagraphBreaks(showGapTimes:false, tooClose:tooClose, words:words, text:text, test:test, completion: { (string:String?) -> (Void) in
                        self?.transcript = string
                        textChanges()
                    })
                } else {
                    // Can't insert paragraph breaks.
                }
            } else {
                textChanges()
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
            return nil
        }
        
        var action : AlertAction!
        
        print(topicsJSON)
        print(topicsDictionaries)
        print(topics)
        print(allTopicKeywords)
        print(allTopicKeywordDictionaries)

        action = AlertAction(title: prefix + " " + Constants.Strings.Transcript, style: .default) {
            if self.transcript == nil {
                guard VoiceBase.isAvailable ?? false else {
                    if VoiceBase.APIKey == nil {
                        let alert = CBCAlertController( title: "Please add an API Key to use VoiceBase",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        alert.addTextField(configurationHandler: { (textField:UITextField) in
                            textField.text = VoiceBase.APIKey
                        })
                        
                        let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: {
                            (action : UIAlertAction) -> Void in
                            VoiceBase.APIKey = alert.textFields?[0].text
                            
                            // If this is a valid API key then should pass a completion block to start the transcript!
                            if VoiceBase.APIKey != nil {
                                VoiceBase.checkAvailability {
                                    if !self.transcribing {
                                        if Globals.shared.reachability.isReachable {
                                            Alerts.shared.yesOrNo(title: "Begin Creating\nMachine Generated Transcript?",
                                                    message: "\(text) (\(self.transcriptPurpose))",
                                                    yesAction: { () -> (Void) in
                                                        self.getTranscript() // alert:true,detailedAlerts:true
                                                        self.alert(viewController:viewController)
                                                    },
                                                    yesStyle: .default,
                                                    noAction: nil,
                                                    noStyle: .default)
                                        } else {
                                            viewController.networkUnavailable( "Machine Generated Transcript Unavailable.")
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
                        
                        Alerts.shared.blockPresent(presenting: viewController, presented: alert, animated: true)
                    } else {
                        viewController.networkUnavailable("VoiceBase unavailable.")
                    }
                    return
                }
                
                guard Globals.shared.reachability.isReachable else {
                    viewController.networkUnavailable("VoiceBase unavailable.")
                    return
                }
                
                if !self.transcribing {
                    if Globals.shared.reachability.isReachable {
                        Alerts.shared.yesOrNo(title: "Begin Creating\nMachine Generated Transcript?",
                                message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.getTranscript()
                                self.alert(viewController:viewController)
                            },
                            yesStyle: .default,
                            noAction: nil,
                            noStyle: .default)
                    } else {
                        viewController.networkUnavailable( "Machine Generated Transcript Unavailable.")
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

                        viewController.popoverHTML(title:self.mediaItem?.title, bodyHTML:self.bodyHTML, headerHTML:self.headerHTML, search:true)
                    }))
                    
                    alertActions.append(AlertAction(title: "Transcript with Timing", style: .default, handler: {
                        var alertActions = [AlertAction]()
                        
                        alertActions.append(AlertAction(title: "By Word", style: .default, handler: {
                            viewController.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                                var strings = [String]()

                                guard let dicts = self?.words else {
                                    return nil
                                }
                                
//                                self?.words?.forEach({ (dict:[String : Any]) in
                                for dict in dicts {
                                    guard test?() != true else {
                                        return nil
                                    }
                                    
                                    if  let position = dict["p"] as? Int,
                                        let start = dict["s"] as? Int,
                                        let end = dict["e"] as? Int,
                                        let word = dict["w"] as? String,
                                        let startHMS = (Double(start)/1000.0).secondsToHMSms,
                                        let endHMS = (Double(end)/1000.0).secondsToHMSms {
                                        strings.append("\(position+1)\n\(startHMS) --> \(endHMS)\n\(word)")
                                    }
                                } //)
                                
                                return strings.timingHTML(self?.headerHTML)
                            }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                                if let htmlString = data as? String {
                                    viewController.popoverHTML(title:self?.mediaItem?.title,htmlString:htmlString, search:true)
                                }
                            })
                        }))
                        
                        alertActions.append(AlertAction(title: "By Segment", style: .default, handler: {
                            viewController.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                                return self?.transcriptSegmentComponents?.result?.timingHTML(self?.headerHTML, test:test) as Any
                            }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                                if let htmlString = data as? String {
                                    viewController.popoverHTML(title:self?.mediaItem?.title,htmlString:htmlString, search:true)
                                }
                            })
                        }))
                        
                        Alerts.shared.alertActionsCancel(  title: "Transcript with Timing",
                                                            message: "\(text) (\(self.transcriptPurpose))",
                                                            alertActions: alertActions,
                                                            cancelAction:nil)
                    }))

                    Alerts.shared.alertActionsCancel(  title: "View",
                                                        message: "This is a machine generated transcript for \n\n\(text) (\(self.transcriptPurpose))\n\nIt may lack proper formatting and have signifcant errors.",
                                                        alertActions: alertActions,
                                                        cancelAction:nil)
                }))
                
                alertActions.append(AlertAction(title: "Edit", style: .default, handler: {
                    guard !self.isAutoEditUnderway else {
                        self.autoEditUnderway()
                        return
                    }
                    
                    guard !self.aligning else {
                        if let percentCompleteFormatted = self.percentCompleteFormatted { // , let text = self.mediaItem?.text
                            Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                               message: "There is an alignment underway (\(percentCompleteFormatted)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                               message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                        let textPopover = navigationController.viewControllers[0] as? TextViewController {

                        navigationController.modalPresentationStyle = viewController.preferredModalPresentationStyle
                        
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
                        
                        textPopover.onSave = { [weak self] (text:String?) -> Void in
                            guard text != textPopover.text else {
                                return
                            }
                            
                            self?.transcript = text
                        }
                        
                        viewController.present(navigationController, animated: true, completion: nil)
                    } else {
                        print("ERROR")
                    }
                }))

                if !self.isAutoEditUnderway {
                    alertActions.append(AlertAction(title: Constants.Strings.Auto_Edit, style: .destructive, handler: {
                        self.confirmAutoEdit()
                    }))
                } else {
                    alertActions.append(AlertAction(title: Constants.Strings.Auto_Edit, style: .default, handler: {
                        self.autoEditUnderway()
                    }))
                }
                
                alertActions.append(AlertAction(title: "Media ID", style: .default, handler: {
                    var alertItems = [AlertItem]()
                    alertItems.append(AlertItem.text(self.mediaID))
                    alertItems.append(AlertItem.action(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil)))
                    Alerts.shared.alert(title: "VoiceBase Media ID", message: text + " (\(self.transcriptPurpose))", items: alertItems)
                }))
                
                if VoiceBase.isAvailable ?? false {
                    alertActions.append(AlertAction(title: "Check VoiceBase", style: .default, handler: {
                        self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                                        VoiceBase.delete(alert:true,mediaID: self.mediaID)
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
                    
                    alertActions.append(AlertAction(title: Constants.Strings.Align, style: .destructive, handler: {
                        guard !self.aligning else {
                            if let percentCompleteFormatted = self.percentCompleteFormatted { // , let text = self.mediaItem?.text
                                Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                                   message: "There is an alignment already underway (\(percentCompleteFormatted)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.")
                            } else {
                                Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                                   message: "There is an alignment already underway.\n\nPlease try again later.")
                            }
                            return
                        }
                        
                        self.selectAlignmentSource(viewController:viewController)
                    }))
                }
                
                alertActions.append(AlertAction(title: "Restore", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentCompleteFormatted = self.percentCompleteFormatted { // , let text = self.mediaItem?.text
                            Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                               message: "There is an alignment underway (\(percentCompleteFormatted)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                               message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Regenerate Transcript", style: .destructive, handler: {
                        Alerts.shared.yesOrNo(title: "Confirm Regeneration of Transcript",
                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
                                yesAction: { () -> (Void) in
                                    self.transcript = self.transcriptFromWords
                                }, yesStyle: .destructive,
                                noAction: nil, noStyle: .default)
                    }))
                    
                    if VoiceBase.isAvailable ?? false {
                        alertActions.append(AlertAction(title: "Reload from VoiceBase", style: .destructive, handler: {
                            // This metadata call is how we verify that it is on VB.
                            self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                                // If so, confirm reloading.
                                Alerts.shared.yesOrNo(title: "Confirm Reloading",
                                        message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
                                        yesAction: { () -> (Void) in
                                            Alerts.shared.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                            
                                            if self.resultsTimer != nil {
                                                debug("TIMER NOT NIL!")
                                                
                                                var actions = [AlertAction]()
                                                
                                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                                
                                                Alerts.shared.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                            } else {
                                                Thread.onMain { [weak self] in 
                                                    self?.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self?.monitor(_:)), userInfo: self?.relaodUserInfo(alert:true,detailedAlerts:false), repeats: false)
                                                }
                                            }
                                        }, yesStyle: .destructive,
                                        noAction: nil, noStyle: .default)
                            }, onError:  { (dict:[String:Any]?)->(Void) in
                                // If not, tell the user.
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"Not on VoiceBase", message:text + "\nis not on VoiceBase.", actions:actions)
                            })
                        }))
                    }
                    
                    Alerts.shared.alertActionsCancel( title: "Restore Options",
                                                       message: "\(text) (\(self.transcriptPurpose))",
                        alertActions: alertActions,
                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentCompleteFormatted = self.percentCompleteFormatted { // , let text = self.mediaItem?.text
                            Alerts.shared.alertActionsCancel( title: "Alignment Underway",
                                                               message: "There is an alignment underway (\(percentCompleteFormatted)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            Alerts.shared.alertActionsCancel(  title: "Alignment Underway",
                                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                                                alertActions: nil,
                                                                cancelAction: nil)
                        }
                        return
                    }
                    
                    guard !self.isAutoEditUnderway else {
                        self.autoEditUnderway()
                        return
                    }
                    
                    Alerts.shared.yesOrNo(title: "Confirm Deletion of Machine Generated Transcript",
                            message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.delete(alert:false)
                                self.reset(alert:true)
                            },
                            yesStyle: .destructive,
                            noAction: nil,
                            noStyle: .default)
                }))
                
                Alerts.shared.alertActionsCancel(title: Constants.Strings.Machine_Generated + " " + Constants.Strings.Transcript,
                    message: text + " (\(self.transcriptPurpose))",
                    alertActions: alertActions,
                    cancelAction: nil)
            }
        }
        
        return action
    }
    
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
        
        if  let first = transcriptSegmentComponents?.result?.filter({ (string:String) -> Bool in
            return string.contains(transcriptSegmentTiming)
        }).first,
            let navigationController = popover.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
            let textPopover = navigationController.viewControllers[0] as? TextViewController,
            let transcriptSegmentIndex = self.transcriptSegmentComponents?.result?.firstIndex(of: first),
            let range = string.range(of:timing+"\n") {
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = popover
            
            Thread.onMain { [weak self] in 
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
            
            textPopover.onSave = { [weak self] (text:String?) -> Void in
                // This guard condition will be false after save
                guard text != textPopover.text else {
                    if playing {
                        Globals.shared.mediaPlayer.play()
                    }
                    return
                }
                
                // I.e. THIS SHOULD NEVER HAPPEN WHEN CALLED FROM onDone UNLESS
                // It is called during automatic.
                if var transcriptSegmentComponents = self?.transcriptSegmentComponents?.result {
                    transcriptSegmentComponents[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
                    self?.transcriptSegments?.store?(transcriptSegmentComponents.transcriptSegmentsFromTranscriptSegmentComponents)
                }

                if popover.searchActive {
                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
                }
                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
            }
            
            textPopover.onDone = { [weak self] (text:String?) -> Void in
                textPopover.onSave?(text)
            self?.transcriptSegments?.store?(self?.transcriptSegmentComponents?.result?.transcriptSegmentsFromTranscriptSegmentComponents)

                Thread.onMain { [weak self] in 
                    popover.tableView.isEditing = false
                    popover.tableView.reloadData()
                    popover.tableView.reloadData()
                }
                
                Thread.onMain { [weak self] in 
                    if popover.tableView.isValid(indexPath) {
                        popover.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
                    }
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
    
    func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        var actions = [AlertAction]()
        
        var edit:AlertAction!
        
        edit = AlertAction(title: "Edit", style: .default) { // [weak popover] in
            self.editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath)
        }
        
        actions.append(edit)
        
        return actions.count > 0 ? actions : nil
    }

    func timingIndexAlertActions(viewController:UIViewController,completion:((PopoverTableViewController,String)->(Void))?) -> AlertAction?
    {
        var action : AlertAction!
        
        action = AlertAction(title: "Timing Index", style: .default) {
            var alertActions = [AlertAction]()

            alertActions.append(AlertAction(title: "By Word", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTimingIndexWord
                    
                    popover.section.showIndex = true

                    popover.stringsFunction = { [weak self] () -> [String]? in
                        guard let words = self?.words else {
                            return nil
                        }
                        
                        var wordCounts = [String:Int]()
                        
                        words.compactMap({ (dict:[String : Any]) -> String? in
                            guard (dict["m"] as? String) != "punc" else {
                                return nil
                            }
                            
                            return (dict["w"] as? String)?.uppercased()
                        }).forEach({ (word:String) in
                            if let count = wordCounts[word] {
                                wordCounts[word] = count + 1
                            } else {
                                wordCounts[word] = 1
                            }
                        })
                        
                        return wordCounts.keys.sorted().map({ (word:String) -> String in
                            if let count = wordCounts[word] {
                                return word + " (\(count))"
                            } else {
                                return word
                            }
                        })
                    }

                    popover.segments = true
                    
                    popover.section.function = { [weak self] (method:String?,strings:[String]?) in
                        return strings?.sort(method: method)
                    }
                    popover.section.method = Constants.Sort.Alphabetical
                    
                    popover.bottomBarButton = true
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self, weak popover] in
                        guard let popover = popover else {
                            return
                        }
                        
                        let strings = popover.section.function?(Constants.Sort.Alphabetical,popover.section.strings)
                        
                        if popover.segmentedControl.selectedSegmentIndex == 0 {
                            popover.section.method = Constants.Sort.Alphabetical
                            
                            popover.section.showHeaders = false
                            popover.section.showIndex = true
                            
                            popover.section.indexStringsTransform = nil
                            popover.section.indexHeadersTransform = nil
                            popover.section.indexSort = nil
                            
                            popover.section.strings = strings
                            
                            popover.section.stringsAction?(strings, popover.section.sorting)
                            
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self, weak popover] in
                        guard let popover = popover else {
                            return
                        }
                        
                        let strings = popover.section.function?(Constants.Sort.Frequency,popover.section.strings)
                        
                        if popover.segmentedControl.selectedSegmentIndex == 1 {
                            popover.section.method = Constants.Sort.Frequency
                            
                            popover.section.showHeaders = false
                            popover.section.showIndex = true
                            
                            popover.section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                                return string?.log
                            }
                            
                            popover.section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                                return string
                            }
                            
                            popover.section.indexSort = { [weak self] (first:String?,second:String?) -> Bool in
                                guard let first = first else {
                                    return false
                                }
                                guard let second = second else {
                                    return true
                                }
                                return Int(first) > Int(second)
                            }
                            
                            popover.section.strings = strings
                            
                            popover.section.stringsAction?(strings, popover.section.sorting)
                            
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Length, position: 2, action: { [weak self, weak popover] in
                        guard let popover = popover else {
                            return
                        }
                        
                        let strings = popover.section.function?(Constants.Sort.Length,popover.section.strings)
                        
                        if popover.segmentedControl.selectedSegmentIndex == 2 {
                            popover.section.method = Constants.Sort.Length
                            
                            popover.section.showHeaders = false
                            popover.section.showIndex = true
                            
                            popover.section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                                return (string?.word?.count ?? string?.count)?.description
                            }
                            
                            popover.section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                                return string
                            }
                            
                            popover.section.indexSort = { [weak self] (first:String?,second:String?) -> Bool in
                                guard let first = first else {
                                    return false
                                }
                                guard let second = second else {
                                    return true
                                }
                                return Int(first) > Int(second)
                            }
                            
                            popover.section.strings = strings
                            
                            popover.section.stringsAction?(strings, popover.section.sorting)
                            
                            popover.tableView?.reloadData()
                        }
                    }))
                    
                    popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    viewController.navigationController?.pushViewController(popover, animated: true)
                    completion?(popover,"TIMINGINDEXWORD")
                }
            }))
            
//            let byPhrase = AlertAction(title: "By Phrase", style: .default, handler: {
//                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
//                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//                    popover.navigationController?.isNavigationBarHidden = false
//
//                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
//
//                    popover.selectedMediaItem = self.mediaItem
//                    popover.transcript = self
//
//                    popover.search = true
//
//                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
//                    popover.purpose = .selectingTimingIndexPhrase
//
//                    popover.section.showIndex = true
//
//                    popover.stringsFunction = { [weak self] () -> [String]? in
//                        guard let keywordDictionaries = self?.keywordDictionaries else {
//                            return nil
//                        }
//
//                        var keywordCounts = [String:Int]()
//
//                        for keyword in keywordDictionaries.keys {
//                            // This gets the number of SEGMENTS not the number of total occurences if it occurs more than once in a segment.
//                            if let speakers = keywordDictionaries[keyword]?["t"] as? [String:Any],  let times = speakers["unknown"] as? [String] {
//                                for time in 0..<times.count {
//                                    if let time = Double(times[time]) {
//                                        if let component = self?.transcriptSegmentComponents?.result?.component(atTime: Double(time).secondsToHMSms, returnClosest: true) {
//                                            let range = NSRange(location: 0, length: component.utf16.count)
//
//                                            // "\\b" +  + "\\b"
//                                            if let regex = try? NSRegularExpression(pattern: keyword, options: .caseInsensitive) {
//                                                let matches = regex.matches(in: component, options: .withTransparentBounds, range: range)
//
//                                                if matches.count > 0 {
//                                                    if let oldCount = keywordCounts[keyword] {
//                                                        keywordCounts[keyword] = oldCount + matches.count
//                                                    } else {
//                                                        keywordCounts[keyword] = matches.count
//                                                    }
//                                                } else {
//                                                    let words = keyword.components(separatedBy: Constants.SINGLE_SPACE).map { (substring) -> String in
//                                                        String(substring)
//                                                    }
//
//                                                    if words.count > 1 {
//                                                        var strings = [String]()
//                                                        var phrase : String?
//
//                                                        // Assemble the list of "less than the full phrase" phrases to look for.
//                                                        for i in 0..<words.count {
//                                                            if i == (words.count - 1) {
//                                                                break
//                                                            }
//
//                                                            if phrase == nil {
//                                                                phrase = words[i]
//                                                            } else {
//                                                                phrase = (phrase ?? "") + " " + words[i]
//                                                            }
//
//                                                            if let phrase = phrase {
//                                                                strings.append(phrase)
//                                                            }
//                                                        }
//
//                                                        // reverse them since we want to look for the longest first.
//                                                        strings.reverse()
//
//                                                        // Now look for them.
//                                                        var found = false
//
//                                                        for string in strings {
//                                                            if let regex = try? NSRegularExpression(pattern: "\\b" + string + "\\b", options: .caseInsensitive) {
//                                                                let matches = regex.matches(in: component, options: .withTransparentBounds, range: range)
//                                                                if matches.count > 0 {
//                                                                    for match in matches {
//                                                                        if match.range.upperBound == component.endIndex.utf16Offset(in: component) {
//                                                                            if let oldCount = keywordCounts[keyword] {
//                                                                                keywordCounts[keyword] = oldCount + 1
//                                                                            } else {
//                                                                                keywordCounts[keyword] = 1
//                                                                            }
//                                                                            found = true
//                                                                            break
//                                                                        } else {
//
//                                                                        }
//                                                                    }
//                                                                } else {
//
//                                                                }
//                                                            }
//
//                                                            if found {
//                                                                break
//                                                            }
//                                                        }
//
//                                                        if !found {
//                                                            if let string = strings.first {
//                                                                if let range = component.components(separatedBy: " ").last?.range(of: string) {
//                                                                    if let oldCount = keywordCounts[keyword] {
//                                                                        keywordCounts[keyword] = oldCount + 1
//                                                                    } else {
//                                                                        keywordCounts[keyword] = 1
//                                                                    }
//                                                                    found = true
//                                                                }
//                                                            }
//                                                        }
//
//                                                        if !found {
//                                                            var phrase = keyword
//
//                                                            if #available(iOS 12.0, *) {
//                                                                if let lemmas = keyword.lowercased().nlLemmas {
//                                                                    for lemma in lemmas {
//                                                                        if lemma.0 != lemma.1 {
//                                                                            if let word = lemma.1 {
//                                                                                phrase = phrase.replacingOccurrences(of: lemma.0, with: word.uppercased(), options: .caseInsensitive, range: lemma.2)
//                                                                            }
//                                                                        }
//                                                                    }
//                                                                }
//                                                            } else {
//                                                                // Fallback on earlier versions
//                                                                if let lemmas = keyword.nsLemmas {
//
//                                                                }
//                                                            }
//
//                                                            print(keyword,phrase)
//
//                                                            if phrase != keyword {
//                                                                if let regex = try? NSRegularExpression(pattern: phrase, options: .caseInsensitive) {
//                                                                    let matches = regex.matches(in: component, options: .withTransparentBounds, range: range)
//
//                                                                    if matches.count > 0 {
//                                                                        if let oldCount = keywordCounts[keyword] {
//                                                                            keywordCounts[keyword] = oldCount + matches.count
//                                                                        } else {
//                                                                            keywordCounts[keyword] = matches.count
//                                                                        }
//                                                                        found = true
//                                                                    } else {
//
//                                                                    }
//                                                                }
//                                                            } else {
//
//                                                            }
//
//                                                            if !found {
//                                                                // Lemmas didn't help
//                                                                // try to match part of the last word?
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//
//                        return keywordCounts.keys.sorted().map({ (keyword:String) -> String in
//                            if let count = keywordCounts[keyword] {
//                                return keyword + " (\(count))"
//                            } else {
//                                return keyword
//                            }
//                        })
//                    }
//
//                    popover.segments = true
//
//                    popover.section.function = { (method:String?,strings:[String]?) in
//                        return strings?.sort(method: method)
//                    }
//                    popover.section.method = Constants.Sort.Alphabetical
//
//                    popover.bottomBarButton = true
//
//                    var segmentActions = [SegmentAction]()
//
//                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self, weak popover] in
//                        guard let popover = popover else {
//                            return
//                        }
//
//                        let strings = popover.section.function?(Constants.Sort.Alphabetical,popover.section.strings)
//
//                        if popover.segmentedControl.selectedSegmentIndex == 0 {
//                            popover.section.method = Constants.Sort.Alphabetical
//
//                            popover.section.showHeaders = false
//                            popover.section.showIndex = true
//
//                            popover.section.indexStringsTransform = nil
//                            popover.section.indexHeadersTransform = nil
//                            popover.section.indexSort = nil
//
//                            popover.section.strings = strings
//
//                            popover.section.stringsAction?(strings, popover.section.sorting)
//
//                            popover.tableView?.reloadData()
//                        }
//                    }))
//
//                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self, weak popover] in
//                        guard let popover = popover else {
//                            return
//                        }
//
//                        let strings = popover.section.function?(Constants.Sort.Frequency,popover.section.strings)
//
//                        if popover.segmentedControl.selectedSegmentIndex == 1 {
//                            popover.section.method = Constants.Sort.Frequency
//
//                            popover.section.showHeaders = false
//                            popover.section.showIndex = true
//
//                            popover.section.indexStringsTransform = { (string:String?) -> String? in
//                                return string?.log
//                            }
//
//                            popover.section.indexHeadersTransform = { (string:String?) -> String? in
//                                return string
//                            }
//
//                            popover.section.indexSort = { (first:String?,second:String?) -> Bool in
//                                guard let first = first else {
//                                    return false
//                                }
//                                guard let second = second else {
//                                    return true
//                                }
//                                return Int(first) > Int(second)
//                            }
//
//                            popover.section.strings = strings
//
//                            popover.section.stringsAction?(strings, popover.section.sorting)
//
//                            popover.tableView?.reloadData()
//                        }
//                    }))
//
//                    segmentActions.append(SegmentAction(title: Constants.Sort.Length, position: 2, action: { [weak self, weak popover] in
//                        guard let popover = popover else {
//                            return
//                        }
//
//                        let strings = popover.section.function?(Constants.Sort.Length,popover.section.strings)
//
//                        if popover.segmentedControl.selectedSegmentIndex == 2 {
//                            popover.section.method = Constants.Sort.Length
//
//                            popover.section.showHeaders = false
//                            popover.section.showIndex = true
//
//                            popover.section.indexStringsTransform = { (string:String?) -> String? in
//                                guard let word = string?.word else {
//                                    return nil
//                                }
//
//                                return word.count.description
//                            }
//
//                            popover.section.indexHeadersTransform = { (string:String?) -> String? in
//                                return string
//                            }
//
//                            popover.section.indexSort = { (first:String?,second:String?) -> Bool in
//                                guard let first = first else {
//                                    return false
//                                }
//                                guard let second = second else {
//                                    return true
//                                }
//                                return Int(first) > Int(second)
//                            }
//
//                            popover.section.strings = strings
//
//                            popover.section.stringsAction?(strings, popover.section.sorting)
//
//                            popover.tableView?.reloadData()
//                        }
//                    }))
//
//                    popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil
//
//                    viewController.navigationController?.pushViewController(popover, animated: true)
//                    completion?(popover,"TIMINGINDEXPHRASE")
//                }
//            })
            
            alertActions.append(AlertAction(title: "By Timed Segment", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self

                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.parser = { [weak self] (string:String) -> [String] in
                        var strings = string.components(separatedBy: "\n")
                        while strings.count > 2 {
                            strings.removeLast()
                        }
                        return strings
                    }
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = { [weak self] (string:String?)->(String?) in // century
                        return string?.century
                    }
                    
                    popover.section.indexHeadersTransform = { [weak self] (string:String?)->(String?) in
                        return string
                    }
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { [weak self] () -> [String]? in
                        return self?.transcriptSegmentComponents?.result?.filter({ (string:String) -> Bool in
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

                    viewController.navigationController?.pushViewController(popover, animated: true)
                    completion?(popover,"TIMINGINDEXTIMEDSEGMENT")
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Word", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = { [weak self] (string:String?) -> String? in // century
                        return string?.century
                    }
                    
                    popover.section.indexSort = { [weak self] (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) < Int(second)
                    }
                    popover.section.indexHeadersTransform = { [weak self] (string:String?)->(String?) in
                        return string
                    }
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { [weak self] () -> [String]? in
                        var strings = [String]()
                        
                        if let words = self?.words?.filter({ (dict:[String:Any]) -> Bool in
                            return dict["w"] != nil
                        }) {
                            for i in 0..<words.count {
                                if  let position = words[i]["p"] as? Int,
                                    let start = words[i]["s"] as? Int,
                                    let end = words[i]["e"] as? Int,
                                    let word = words[i]["w"] as? String,
                                    let startHMS = (Double(start)/1000.0).secondsToHMSms,
                                    let endHMS = (Double(end)/1000.0).secondsToHMSms {
                                    strings.append("\(position+1)\n")
                                    
                                    strings[i] += "\(startHMS) to \(endHMS)\n\(word)"
                                }
                            }
                        }
                    
                        return strings.count > 0 ? strings : nil
                    }

                    viewController.navigationController?.pushViewController(popover, animated: true)
                    completion?(popover,"TIMINGINDEXTIMEDWORD")
                }
            }))
            
            Alerts.shared.alertActionsCancel( title: "Show Timing Index",
                                               alertActions: alertActions)
        }
        
        return action
    }
}
