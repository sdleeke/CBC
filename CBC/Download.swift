//
//  Download.swift
//  CBC
//
//  Created by Steve Leeke on 12/15/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

enum State {
    case downloading
    case downloaded
    case none
}

class Download {
    weak var mediaItem:MediaItem?
    
    var purpose:String?
    
    var downloadURL:URL?
    
    var fileSystemURL:URL? {
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:URLSession? // We're using a session for each download.  Not sure is the best but it works for TWU.
    
    var task:URLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    
    var state:State = .none {
        didSet {
            if state != oldValue {
                switch purpose! {
                case Purpose.audio:
                    switch state {
                    case .downloading:
                        break
                        
                    case .downloaded:
                        mediaItem?.addTag(Constants.Downloaded)
                        break
                        
                    case .none:
                        mediaItem?.removeTag(Constants.Downloaded)
                        break
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        // The following must appear AFTER we change the state
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    })
                    break
                    
                case Purpose.notes:
                    fallthrough
                case Purpose.slides:
                    switch state {
                    case .downloading:
                        break
                        
                    case .downloaded:
                        DispatchQueue.main.async(execute: { () -> Void in
                            // The following must appear AFTER we change the state
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.mediaItem)
                        })
                        break
                        
                    case .none:
                        break
                    }
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    var completionHandler: ((Void) -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
            //            print(fileSystemURL!.path!)
            //            print(FileManager.default.fileExists(atPath: fileSystemURL!.path!))
            return FileManager.default.fileExists(atPath: fileSystemURL!.path)
        } else {
            return false
        }
    }
    
    var fileSize:Int
    {
        var size = 0
        
        if fileSystemURL != nil {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL!.path)
                size = fileAttributes[FileAttributeKey.size] as! Int
            } catch _ {
                print("failed to get file attributes for \(fileSystemURL!)")
            }
        }
        
        return size
    }
    
    func download()
    {
        guard (downloadURL != nil) else {
            print(mediaItem?.title)
            print(purpose)
            print(fileSystemURL)
            return
        }
        
        print(state)
        if (state == .none) {
            state = .downloading
            
            let downloadRequest = URLRequest(url: downloadURL!)
            
            let configuration = URLSessionConfiguration.ephemeral
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            //            let configuration = URLSessionConfiguration.background(withIdentifier: Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent)
            //            configuration.sessionSendsLaunchEvents = true
            
            session = URLSession(configuration: configuration, delegate: mediaItem, delegateQueue: nil)
            session?.reset() {}
            
            session?.sessionDescription = fileSystemURL!.lastPathComponent
            
            task = session?.downloadTask(with: downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
        }
    }
    
    func delete()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (FileManager.default.fileExists(atPath: fileSystemURL!.path)){
                do {
                    try FileManager.default.removeItem(at: fileSystemURL!)
                } catch _ {
                    print("failed to delete download")
                }
            }
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
    
    func cancelOrDelete()
    {
        switch state {
        case .downloading:
            cancel()
            break
            
        case .downloaded:
            delete()
            break
            
        default:
            break
        }
    }
    
    func cancel()
    {
        if (active) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            
            task?.cancel()
            task = nil
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
}

