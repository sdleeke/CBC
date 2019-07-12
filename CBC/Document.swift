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

/**
 Holds all pdf documents in mediaItems.
 */
class Document : NSObject
{
    private weak var mediaItem:MediaItem?
    
    var purpose:String?
    
    // What is the purpose of this?
    var setZoom = false
    
    // What is the purpose of this?
    var setOffset = false
    
    lazy var fetchData : Fetch<Data>! = { [weak self] in
        let fetchData = Fetch<Data>(name:mediaItem?.mediaCode ?? "" + "DOCUMENT" + (purpose ?? "")) //
    
        fetchData.retrieve = {
            return self?.download?.fileSystemURL?.data
        }
        
        fetchData.store = { (data:Data?) in
            _ = data?.save(to: self?.download?.fileSystemURL)
        }
        
        fetchData.transform = { (data:Data?) in
            guard var data = data else {
                return nil
            }
            
            if #available(iOS 11.0, *) {
                if self?.purpose == Purpose.slides {
                    if let doc = PDFDocument(data: data), let page = doc.page(at: 0) {
                        let rect = page.bounds(for: .mediaBox)
                        
                        if let pageImage = self?.mediaItem?.posterImage?.image {
                            let posterImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
                            
                            if let pageImage = pageImage.resize(scale:posterImageFactor) {
                                if let pdf = data.pdf, let page = pageImage.page {
                                    pdf.insert(page, at: 0)
                                    
                                    if let pdfData = pdf.data {
                                        data = pdfData
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
            return data
        }
        
        fetchData.fetch = {
            return self?.download?.downloadURL?.data
        }
                    
//            var data : Data?
//
//            if Globals.shared.settings.cacheDownloads {
//                data = self?.download?.fileSystemURL?.data ?? self?.download?.downloadURL?.data?.save(to: self?.download?.fileSystemURL)
//            } else {
//                data = self?.download?.downloadURL?.data
//            }
            
//            if #available(iOS 11.0, *) {
//                if self?.purpose == Purpose.slides, let docData = data {
//                    if let doc = PDFDocument(data: docData), let page = doc.page(at: 0) {
//                        let rect = page.bounds(for: .mediaBox)
//
//                        if let pageImage = self?.mediaItem?.posterImage?.image {
//                            let posterImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
//
//                            if let pageImage = pageImage.resize(scale:posterImageFactor) {
//                                if let pdf = data?.pdf, let page = pageImage.page {
//                                    pdf.insert(page, at: 0)
//
//                                    if let pdfData = pdf.data {
//                                        data = pdfData
//                                    }
//                                }
//                            }
//                        }

//                        if let pageImage = self?.mediaItem?.seriesImage?.image {
//                            let seriesImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
//
//                            if let pageImage = pageImage.resize(scale:seriesImageFactor) {
//                                if let pdf = data?.pdf, let page = pageImage.page {
//                                    pdf.insert(page, at: 0)
//
//                                    if let pdfData = pdf.data {
//                                        data = pdfData
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
            
//            } else {
//                // Fallback on earlier versions
//            }
            
//            return data
//        }
        
        return fetchData
    }()
    
//    func load(downloader:Downloader)
//    {
//        if Globals.shared.settings.cacheDownloads {
//            guard download?.exists == true else {
//                if download?.state != .downloading {
//                    download?.download(background: false)
//                }
//
//                Thread.onMain { // Can't specify @objc in a protocol definition.
//                    NotificationCenter.default.addObserver(downloader, selector: #selector(downloader.downloaded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self?.download)
//                    NotificationCenter.default.addObserver(downloader, selector: #selector(downloader.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self?.download)
//                }
//                return
//            }
//        }
//
//        // fill cache
//        fetchData.fill()
//    }
    
    var download:Download?
    {
        get {
            guard let purpose = purpose else {
                return nil
            }
  
            // Wouldn't work before because downloads dictionary was populated by lazy vars below rather than in its own lazy initialization.
            return mediaItem?.downloads?[purpose]
            
//            var download:Download?
//
//            switch purpose {
//            case Purpose.notes:
//                download = mediaItem?.notesDownload
//                break
//
//            case Purpose.slides:
//                download = mediaItem?.slidesDownload
//                break
//
//            case Purpose.outline:
//                download = mediaItem?.outlineDownload
//                break
//
//            default:
//                download = nil
//                break
//            }
//
//            if download == nil {
//                print("download == nil")
//            }
//
//            return download
        }
    }
    
    init(purpose:String,mediaItem:MediaItem?)
    {
        super.init()
        
        self.purpose = purpose
        self.mediaItem = mediaItem
    }
    
    deinit {
        debug(self)
    }
    
    func showing(_ mediaItem:MediaItem?) -> Bool
    {
        return (mediaItem == self.mediaItem) && (mediaItem?.showing == purpose)
    }
}
