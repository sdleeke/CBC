//
//  Document.swift
//  CBC
//
//  Created by Steve Leeke on 2/19/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import WebKit
import PDFKit

class Document : NSObject {
    var loadTimer:Timer? // Each document has its own loadTimer because each has its own WKWebView.  This is only used when a direct load is used, not when a document is cached and then loaded.
    
    var loaded : Bool = false
    //    {
    //        get {
    //            if globals.cacheDownloads {
    //                // This assumes it will load.
    //                return (wkWebView?.url == download?.fileSystemURL) && (download?.isDownloaded == true) // (wkWebView?.isLoading == false) &&
    //            } else {
    //                return (wkWebView?.isLoading == false) && (wkWebView?.url == download?.downloadURL)
    //            }
    //        }
    //    }
    
    var data : Data?
    {
        get {
            var data : Data?
            
            if download?.isDownloaded == true {
                if let url = download?.fileSystemURL {
                    data = try? Data(contentsOf: url)
                }
            } else {
                if let url = download?.downloadURL {
                    data = try? Data(contentsOf: url)
                }
            }
            
            if #available(iOS 11.0, *) {
                if purpose == Purpose.slides {
                    if let pageImage = mediaItem?.posterImage {
                        if let docData = data, let doc = PDFDocument(data: docData), let page = PDFPage(image: pageImage) {
                            doc.insert(page, at: 0)
                            
                            if let docData = doc.dataRepresentation() {
                                data = docData
                            }
                        }
                    }
                    
                    if let pageImage = mediaItem?.seriesImage {
                        if  let docData = data, let doc = PDFDocument(data: docData), let page = PDFPage(image: pageImage) {
                            doc.insert(page, at: 0)
                            
                            if let docData = doc.dataRepresentation() {
                                data = docData
                            }
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
            return data
        }
    }
    
    var mediaItem:MediaItem?
    
    var purpose:String?
    
    var download:Download? {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            var download:Download?
            
            switch purpose {
            case Purpose.notes:
                download = mediaItem?.notesDownload
                break
                
            case Purpose.slides:
                download = mediaItem?.slidesDownload
                break
                
            default:
                download = nil
                break
            }
            
            if download == nil {
                print("download == nil")
            }
            
            return download
        }
    }
    
    var wkWebView:WKWebView?
    {
        willSet {
            
        }
        didSet {
            loaded = false

            if (wkWebView == nil) {
                oldValue?.scrollView.delegate = nil
            }
        }
    }
    
    init(purpose:String,mediaItem:MediaItem?)
    {
        self.purpose = purpose
        self.mediaItem = mediaItem
    }
    
    deinit {
        
    }
    
    func showing(_ mediaItem:MediaItem?) -> Bool
    {
        return (mediaItem == self.mediaItem) && (mediaItem?.showing == purpose)
    }
}
