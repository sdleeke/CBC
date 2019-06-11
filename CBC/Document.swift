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
    
    var setZoom = false
    
    var setOffset = false
    
    lazy var fetchData : Fetch<Data>! = { [weak self] in
        let fetchData = Fetch<Data>(name:mediaItem?.mediaCode ?? "" + "DOCUMENT" + (purpose ?? "")) //
    
        fetchData.fetch = {
            var data : Data?
            
            if Globals.shared.settings.cacheDownloads {
                data = self?.download?.fileSystemURL?.data ?? self?.download?.downloadURL?.data?.save(to: self?.download?.fileSystemURL)
            } else {
                data = self?.download?.downloadURL?.data
            }
            
            if #available(iOS 11.0, *) {
                if self?.purpose == Purpose.slides, let docData = data {
                    if let doc = PDFDocument(data: docData), let page = doc.page(at: 0) {
                        let rect = page.bounds(for: .mediaBox)
                        
                        if let pageImage = self?.mediaItem?.posterImage?.image {
                            let posterImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
                            
                            if let pageImage = pageImage.resize(scale:posterImageFactor) {
                                if let pdf = data?.pdf, let page = pageImage.page {
                                    pdf.insert(page, at: 0)
                                    
                                    if let pdfData = pdf.data {
                                        data = pdfData
                                    }
                                }
                            }
                        }
//                        
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
                    }
                }
            } else {
                // Fallback on earlier versions
            }
            
            return data
        }
        
        return fetchData
    }()
    
    var download:Download?
    {
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
                
            case Purpose.outline:
                download = mediaItem?.outlineDownload
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
