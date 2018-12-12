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

class Document : NSObject
{
    private weak var mediaItem:MediaItem?
    
    var purpose:String?
    
    var setZoom = false
    
    var setOffset = false
    
    lazy var fetchData : Fetch<Data>! = { [weak self] in
        let fetchData = Fetch<Data>(name:mediaItem?.id ?? "" + "DOCUMENT" + (purpose ?? "")) //
    
        fetchData.fetch = {
            var data : Data?
            
            if Globals.shared.cacheDownloads {
                data = self?.download?.fileSystemURL?.data ?? self?.download?.downloadURL?.data?.save(to: self?.download?.fileSystemURL)
                
//                if let fileSystemData = self.download?.fileSystemURL?.data {
//                    data = fileSystemData
//                } else {
//                    data = self.download?.downloadURL?.data
//                    data?.save(to: self.download?.fileSystemURL)
////                    if let url = self.download?.downloadURL {
////                        data = url.data
////                        do {
////                            if let fileSystemURL = self.download?.fileSystemURL {
////                                try data?.write(to: fileSystemURL, options: [.atomic])
////                            }
////                        } catch let error {
////                            NSLog(error.localizedDescription)
////                        }
////                    }
//                }
            } else {
                data = self?.download?.downloadURL?.data
//                if let url = self.download?.downloadURL {
//                    do {
//                        data = try Data(contentsOf: url)
//                    } catch let error {
//                        NSLog(error.localizedDescription)
//                    }
//                }
            }
            
            if #available(iOS 11.0, *) {
                if self?.purpose == Purpose.slides, let docData = data {
                    if let doc = PDFDocument(data: docData), let page = doc.page(at: 0) {
                        let rect = page.bounds(for: .mediaBox)
                        
                        if let pageImage = self?.mediaItem?.posterImage?.image {
                            let posterImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
                            
                            if let pageImage = pageImage.resize(scale:posterImageFactor) {
                                if let pdf = data?.pdf, let page = pageImage.pdf {
                                    pdf.insert(page, at: 0)
                                    
                                    if let pdfData = pdf.data {
                                        data = pdfData
                                    }
                                }
                            }
                        }
                        
//                        if let pageImage = self.mediaItem?.seriesImage?.image {
//                            let seriesImageFactor = 1/max(pageImage.size.width/rect.width,pageImage.size.height/rect.width)
//                            
//                            if let pageImage = pageImage.resize(scale:seriesImageFactor) {
//                                if let pdf = data?.pdf, let page = pageImage.pdf {
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

//    var data : Data?
//    {
//        get {
//            return fetchData.result
//        }
//    }
    
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
        
    }
    
    func showing(_ mediaItem:MediaItem?) -> Bool
    {
        return (mediaItem == self.mediaItem) && (mediaItem?.showing == purpose)
    }
}
