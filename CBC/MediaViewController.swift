//
//  MediaViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MessageUI
import WebKit
import MediaPlayer

class Document : NSObject {
    var loadTimer:Timer? // Each document has its own loadTimer because each has its own WKWebView.  This is only used when a direct load is used, not when a document is cached and then loaded.
    
    var loaded = false
    
    var mediaItem:MediaItem?
    
    var purpose:String?
    
    var download:Download? {
        get {
            var download:Download?
            
            switch purpose! {
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
    
    var wkWebView:WKWebView? {
        willSet {
            
        }
        didSet {
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
    
    func showing(_ mediaItem:MediaItem?) -> Bool
    {
        return (mediaItem == self.mediaItem) && (mediaItem?.showing == purpose)
    }
}

class ControlView : UIView
{
    var sliding = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        print(event)
        if !sliding {
//            print("checking views")
            for view in subviews {
                if view.frame.contains(point) && view.isUserInteractionEnabled && !view.isHidden {
                    if let control = view as? UIControl {
                        if control.isEnabled {
                            return true
                        }
                    } else {
                        return true
                    }
                }
            }
        }
        
//        print("Passing all touches to the next view (if any), in the view stack.")
        return false
    }
}

extension MediaViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension MediaViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func actionMenu(action:String?,mediaItem:MediaItem?)
    {
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.Zoom_Video:
            zoomVideo()
            break
            
        case Constants.Strings.Swap_Video_Location:
            swapVideoLocation()
            break
            
        case Constants.Strings.Print_Slides:
            fallthrough
        case Constants.Strings.Print_Transcript:
            printDocument(viewController: self, documentURL: selectedMediaItem?.downloadURL)
            break
            
        case Constants.Strings.Add_to_Favorites:
            globals.queue.sync(execute: { () -> Void in
                self.selectedMediaItem?.addTag(Constants.Strings.Favorites)
            })
            break
            
        case Constants.Strings.Add_All_to_Favorites:
            globals.queue.sync(execute: { () -> Void in
                for mediaItem in self.mediaItems! {
                    mediaItem.addTag(Constants.Strings.Favorites)
                }
            })
            break
            
        case Constants.Strings.Remove_From_Favorites:
            globals.queue.sync(execute: { () -> Void in
                self.selectedMediaItem?.removeTag(Constants.Strings.Favorites)
            })
            break
            
        case Constants.Strings.Remove_All_From_Favorites:
            globals.queue.sync(execute: { () -> Void in
                for mediaItem in self.mediaItems! {
                    mediaItem.removeTag(Constants.Strings.Favorites)
                }
            })
            break
            
        case Constants.Strings.Open_on_CBC_Website:
            if let url = self.selectedMediaItem?.websiteURL {
                open(scheme: url.absoluteString) {
                    networkUnavailable(self,"Unable to open: \(url)")
                }
            }
            break
            
        case Constants.Strings.Open_in_Browser:
            if let url = self.selectedMediaItem?.downloadURL {
                open(scheme: url.absoluteString) {
                    networkUnavailable(self,"Unable to open: \(url)")
                }
            }
            break
            
        case Constants.Strings.Scripture_Viewer:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: "Scripture View") as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? ScriptureViewController  {
                
                popover.scripture = self.scripture
                
                popover.vc = self
                
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
//                navigationController.popoverPresentationController?.permittedArrowDirections = .up
//                navigationController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                
                //                    popover.navigationItem.title = title
                
                popover.navigationController?.isNavigationBarHidden = false
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Scripture_in_Browser:
            openMediaItemScripture(selectedMediaItem)
            break
            
        case Constants.Strings.Download_Audio:
            selectedMediaItem?.audioDownload?.download()
            break
            
        case Constants.Strings.Download_All_Audio:
            for mediaItem in mediaItems! {
                mediaItem.audioDownload?.download()
            }
            break
            
        case Constants.Strings.Cancel_Audio_Download:
            if let state = selectedMediaItem?.audioDownload?.state {
                switch state {
                case .downloading:
                    selectedMediaItem?.audioDownload?.cancel()
                    break
                    
                case .downloaded:
                    let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                    message: nil,
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                        (action : UIAlertAction!) -> Void in
                        self.selectedMediaItem?.audioDownload?.delete()
                    })
                    alert.addAction(yesAction)
                    
                    let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(noAction)
                    
                    let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(cancel)
                    
                    // For .actionSheet style
                    //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
                    
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                default:
                    break
                }
            }
            break
            
        case Constants.Strings.Cancel_All_Audio_Downloads:
            for mediaItem in mediaItems! {
                if let state = selectedMediaItem?.audioDownload?.state {
                    switch state {
                    case .downloading:
                        mediaItem.audioDownload?.cancel()
                        break
                        
                    case .downloaded:
                        let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                            (action : UIAlertAction!) -> Void in
                            mediaItem.audioDownload?.delete()
                        })
                        alert.addAction(yesAction)
                        
                        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(noAction)
                        
                        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(cancel)
                        
                        // For .actionSheet style
                        //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
                        
                        self.present(alert, animated: true, completion: nil)
                        break
                        
                    default:
                        break
                    }
                }
            }
            break
            
        case Constants.Strings.Delete_Audio_Download:
            let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                (action : UIAlertAction!) -> Void in
                self.selectedMediaItem?.audioDownload?.delete()
            })
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            alert.addAction(noAction)
            
            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            alert.addAction(cancel)
            
            // For .actionSheet style
            //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            
            self.present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.Delete_All_Audio_Downloads:
            let alert = UIAlertController(  title: "Confirm Deletion of All Audio Downloads",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                (action : UIAlertAction) -> Void in
                if let mediaItems = self.mediaItems {
                    for mediaItem in mediaItems {
                        mediaItem.audioDownload?.delete()
                    }
                }
            })
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction) -> Void in
                
            })
            alert.addAction(noAction)
            
            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            alert.addAction(cancel)
            
            // For .actionSheet style
            //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            
            self.present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.Print:
            process(viewController: self, work: {
                return setupMediaItemsHTML(self.mediaItems,includeURLs:false,includeColumns:true)
            }, completion: { (data:Any?) in
                printHTML(viewController: self, htmlString: data as? String)
            })
            break
            
        case Constants.Strings.Share:
            shareHTML(viewController: self, htmlString: mediaItem?.webLink)
            break
            
        case Constants.Strings.Share_All:
            shareMediaItems(viewController: self, mediaItems: mediaItems, stringFunction: setupMediaItemsHTML)
            break
            
        case Constants.Strings.Refresh_Document:
            fallthrough
        case Constants.Strings.Refresh_Transcript:
            fallthrough
        case Constants.Strings.Refresh_Slides:
            // This only refreshes the visible document.
            download?.cancelOrDelete()
            document?.loaded = false
            setupDocumentsAndVideo()
            break
            
        default:
            break
        }
    }
    
//    func srtAction(transcript:VoiceBase?,time:String)
//    {
//        guard let srtComponents = transcript?.srtComponents else {
//            return
//        }
//        
//        var fragment:String!
//        
//        for srtComponent in srtComponents {
//            if srtComponent.contains(time+" --> ") {
//                fragment = srtComponent.replacingOccurrences(of: "\n", with: " ")
//                break
//            }
//        }
//        
//        alert(viewController: self.popover!, title: "Machine Generated Transcript Fragment", message: fragment, completion: nil)
//    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let string = strings?[index].replacingOccurrences(of: Constants.UNBREAKABLE_SPACE, with: " ") else {
            return
        }
        
        switch purpose {
        case .selectingCellAction:
            dismiss(animated: true, completion: nil)
            
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Strings.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            default:
                break
            }
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)
            actionMenu(action:string,mediaItem:mediaItem)
            break
            
        case .selectingKeyword:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript
                
//                popover.detail = true
//                popover.detailAction = srtAction
                
                popover.vc = self.popover
                
                popover.delegate = self
                popover.purpose = .selectingTime

                popover.parser = { (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                var strings = [String]()
                
                if let times = popover.transcript?.srtTokenTimes(token: string), let srtComponents = popover.transcript?.srtComponents {
                    for time in times {
//                        print("time: ",time)
                        for srtComponent in srtComponents {
//                            print("srtComponent: ",srtComponent)
                            if srtComponent.contains(time+" --> ") { //
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
                                        
                                        //                                    for string in srtArray {
                                        //                                        text = text + string + (srtArray.index(of: string) == (srtArray.count - 1) ? "" : " ")
                                        //                                    }
                                        
                                        strings.append(string)
                                    }
                                }
                                break
                            }
                        }
                    }
                    
                    popover.editActionsAtIndexPath = popover.transcript?.rowActions

                    popover.search = true
                    popover.searchInteractive = false
                    popover.searchActive = true
                    popover.searchText = string
                    popover.wholeWordsOnly = true
                    
                    popover.section.strings = strings // popover.transcript?.srtTokenTimes(token: string)
                    //                    ?.map({ (string:String) -> String in
                    //                    return secondsToHMS(seconds: string) ?? "ERROR"
                    //                })
                    
                    self.popover?.navigationController?.pushViewController(popover, animated: true)
                }
            }
            break
            
        case .selectingTopic:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript

                popover.delegate = self
                popover.purpose = .selectingTopicKeyword
                
                popover.section.strings = popover.transcript?.topicKeywords(topic: string)
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTopicKeyword:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }

                if let topic = self.popover?.navigationController?.visibleViewController?.navigationItem.title {
                    popover.section.strings = popover.transcript?.topicKeywordTimes(topic: topic, keyword: string)?.map({ (string:String) -> String in
                        return secondsToHMS(seconds: string) ?? "ERROR"
                    })
                }
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break

        case .selectingTime:
//            dismiss(animated: true, completion: nil)
            
            if let time = string.components(separatedBy: "\n")[1].components(separatedBy: " to ").first, let seconds = hmsToSeconds(string: time) {
                globals.mediaPlayer.seek(to: seconds,completion:{ (finished:Bool)->(Void) in
                    if finished, let ptvc = self.popover?.navigationController?.visibleViewController as? PopoverTableViewController, ptvc.isTracking {
//                        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        if ptvc.trackingTimer == nil {
                            Thread.onMainThread() {
                                ptvc.trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: ptvc as Any, selector: #selector(PopoverTableViewController.follow), userInfo: nil, repeats: true)
                            }
                        } else {
                            print("ptvc.trackingTimer not nil")
                        }
                    }
                })
            }
            break
            
        default:
            break
        }
    }
}

extension MediaViewController : MFMessageComposeViewControllerDelegate
{
    // MARK: MFMessageComposeViewControllerDelegate Method
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaViewController : WKNavigationDelegate
{
    // MARK: WKNavigationDelegate
    
    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        //        print(navigationAction.request.url!.absoluteString)
        //        print(navigationAction.navigationType.rawValue)
        
        if (navigationAction.navigationType == .other) {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            //            print(navigationAction.request.url?.absoluteString)
            if let url = navigationAction.request.url?.absoluteString, let range = url.range(of: "%23") {
                let tag = url.substring(to: range.lowerBound)
                
                if tag == "about:blank" {
                    decisionHandler(WKNavigationActionPolicy.allow)
                } else {
                    decisionHandler(WKNavigationActionPolicy.cancel)
                }
            } else {
                if let url = navigationAction.request.url {
                    open(scheme: url.absoluteString) {}
                }
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
//        print(navigationResponse.response.mimeType)
//        print(navigationResponse.response.suggestedFilename)
//        print(navigationResponse.response.textEncodingName)
//        print(navigationResponse.response.expectedContentLength)
//        print(navigationResponse.response.url)
        
        guard let statusCode
            = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
                // if there's no http status code to act on, exit and allow navigation
                decisionHandler(.allow)
                return
        }
        
        if statusCode >= 400 {
            // error has occurred
            if let showing = document?.showing(self.selectedMediaItem), showing {
                if let purpose = document?.purpose {
                    switch purpose {
                    case Purpose.slides:
                        networkUnavailable(self,"Slides not available.")
                        break
                        
                    case Purpose.notes:
                        networkUnavailable(self,"Transcript not available.")
                        break
                        
                    default:
                        break
                    }
                }
                Thread.onMainThread() {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.logo.isHidden = false
                    self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                }
            }
            
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        print("wkWebViewDidFinishNavigation Loading:\(webView.isLoading)")
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:webView", completion: nil)
            return
        }
        
        //        print("Frame: \(webView.frame)")
        //        print("Bounds: \(webView.bounds)")
        
        guard self.view != nil else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard let documents = documents[selectedMediaItem.id] else {
            return
        }
        
        for document in documents.values {
            if (webView == document.wkWebView) {
                //                        print("mediaItemNotesWebView")
                if document.showing(selectedMediaItem) {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    self.setupAudioOrVideo()
                    self.setupSTVControl()
                    self.setSegmentWidths()
                    
                    //                            print("webView:hidden=panning")
                    
                    webView.isHidden = false // self.panning
                } else {
                    webView.isHidden = true
                }
                
                document.loadTimer?.invalidate()
                document.loadTimer = nil

                setDocumentContentOffsetAndZoomScale(document)

                document.loaded = true
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError: Error)
    {
        print("wkDidFail navigation")
        //        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
        //        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard let documents = documents[selectedMediaItem.id] else {
            return
        }
        
        webView.isHidden = true

        for document in documents.values {
            if (webView == document.wkWebView) {
                document.wkWebView?.scrollView.delegate = nil
                document.wkWebView = nil
                if document.showing(selectedMediaItem) {
                    activityIndicator.stopAnimating()
                    activityIndicator.isHidden = true
                    
                    progressIndicator.isHidden = true
                    
                    logo.isHidden = !shouldShowLogo() // && roomForLogo()
                    
                    if (!logo.isHidden) {
                        mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                    
                    networkUnavailable(self,withError.localizedDescription)
                    NSLog(withError.localizedDescription)
                }
            }
        }

        // Keep trying
        //        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        //        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        print("wkDidStartProvisionalNavigation")
        
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!,withError: Error)
    {
        print("didFailProvisionalNavigation")
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard let documents = documents[selectedMediaItem.id] else {
            return
        }
        
        // ,
        // let isDownloaded = document.download?.isDownloaded(), !isDownloaded

        if !globals.cacheDownloads {
            Thread.onMainThread() {
                for document in documents.values {
                    if (document.wkWebView == wkWebView) && document.showing(selectedMediaItem) {
                        self.document?.wkWebView?.isHidden = true
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                        self.logo.isHidden = false
                        
                        if let purpose = document.download?.purpose {
                            switch purpose {
                            case Purpose.notes:
                                networkUnavailable(self,"Transcript not available.")
                                break
                                
                            case Purpose.slides:
                                networkUnavailable(self,"Slides not available.")
                                break
                                
                            default:
                                break
                            }
                        }
                    }
                }
            }
        } else {
    
        }
    }
}

extension MediaViewController: UIScrollViewDelegate
{
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //        print("scrollViewDidZoom")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        //        print("scrollViewDidEndZooming")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
            captureZoomScale(view)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        print("scrollViewDidScroll")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //        print("scrollViewDidEndScrollingAnimation")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        //        print("scrollViewDidEndDecelerating")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        //        print("scrollViewDidEndDragging")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}

extension MediaViewController: UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

extension MediaViewController : PopoverPickerControllerDelegate
{
    func stringPicked(_ string: String?)
    {
        dismiss(animated: true, completion: nil)
    
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stringPicked", completion: nil)
            return
        }
        
    }
}

enum VideoLocation {
    case withDocuments
    case withTableView
}

class MediaViewController: UIViewController // MediaController
{
    @IBOutlet weak var controlView: ControlView!
    
    @IBOutlet weak var controlViewTop: NSLayoutConstraint!
    
    var searchText:String?
    
    var popover : PopoverTableViewController?
    
    var videoLocation : VideoLocation = .withDocuments
    {
        didSet {
            print("")
        }
    }
    
    var scripture:Scripture? {
        get {
            return selectedMediaItem?.scripture
        }
    }
    
    var observerActive = false
    var observedItem:AVPlayerItem?

    private var PlayerContext = 0
    
    var player:AVPlayer?
    
    var panning = false
    
    var sliderObserver:Timer?

//    var showScripture = false
    
    var documents = [String:[String:Document]]()
    
    var document:Document? {
        get {
            if let id = selectedMediaItem?.id, let showing = selectedMediaItem?.showing, let documents = documents[id] {
                return documents[showing]
            } else {
                return nil
            }
        }
    }
    
    var wkWebView:WKWebView? {
        get {
            return document?.wkWebView
        }
    }
    
    var download:Download? {
        get {
            return document?.download
        }
    }
    
    func updateNotesDocument()
    {
//        print("updateNotesDocument")
        updateDocument(document: notesDocument)
    }
    
    func cancelNotesDocument()
    {
//        print("cancelNotesDocument")
        cancelDocument(document: notesDocument,message: "Transcript not available.")
    }
    
    var notesDocument:Document? {
        willSet {
            
        }
        didSet {
            guard (notesDocument != oldValue) else {
                return
            }
            
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: oldValue?.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: oldValue?.download)
            }
            
            if let selectedMediaItem = selectedMediaItem {
                if (documents[selectedMediaItem.id] == nil) {
                    documents[selectedMediaItem.id] = [String:Document]()
                }
                
                if let notesDocument = notesDocument {
                    Thread.onMainThread() {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateNotesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: notesDocument.download)
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.cancelNotesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: notesDocument.download)
                    }
                    
                    if let purpose = notesDocument.purpose {
                        documents[selectedMediaItem.id]?[purpose] = notesDocument
                    }
                }
            }
        }
    }
    
    func updateDocument(document:Document?)
    {
        //        print(document)
        //        print(download)
        
        guard let document = document else {
            return
        }
        
        guard let download = document.download else {
            return
        }
        
        switch download.state {
        case .none:
            //                    print(".none")
            break
            
        case .downloading:
            //                    print(".downloading")
            if document.showing(selectedMediaItem) {
                progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
            }
            break
            
        case .downloaded:
            break
        }
    }
    
    func cancelDocument(document:Document?,message:String)
    {
        //        print(document)
        //        print(download)
        
        guard let document = document else {
            return
        }
        
        guard let download = document.download else {
            return
        }
        
        switch download.state {
        case .none:
            //                    print(".none")
            break
            
        case .downloading:
            //                    print(".downloading")
            download.state = .none
            if document.showing(selectedMediaItem) {
                Thread.onMainThread() {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    document.wkWebView?.isHidden = true
                    
                    globals.mediaPlayer.view?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    networkUnavailable(self,message)
                }
            }
            break
            
        case .downloaded:
            break
        }
    }
    
    func updateSlidesDocument()
    {
//        print("updateSlidesDocument")
        updateDocument(document: slidesDocument)
    }
    
    func cancelSlidesDocument()
    {
//        print("cancelSlidesDocument")
        cancelDocument(document: slidesDocument,message: "Slides not available.")
    }
    
    var slidesDocument:Document? {
        willSet {
            
        }
        didSet {
            guard slidesDocument != oldValue else {
                return
            }
            
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: oldValue?.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: oldValue?.download)
            }
            
            if let selectedMediaItem = selectedMediaItem {
                if (documents[selectedMediaItem.id] == nil) {
                    documents[selectedMediaItem.id] = [String:Document]()
                }
                
                if let slidesDocument = slidesDocument {
                    Thread.onMainThread() {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateSlidesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: slidesDocument.download)
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.cancelSlidesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: slidesDocument.download)
                    }
                    
                    if let purpose = slidesDocument.purpose {
                        documents[selectedMediaItem.id]?[purpose] = slidesDocument
                    }
                }
            }
        }
    }
    
    override var canBecomeFirstResponder : Bool
    {
        return true //let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        globals.motionEnded(motion,event: event)
    }
    
    func removePlayerObserver()
    {
        if observerActive {
            if observedItem != player?.currentItem {
                print("observedItem != player?.currentItem")
            }
            if observedItem != nil {
                print("MVC removeObserver: ",player?.currentItem?.observationInfo as Any)
                
                observedItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerContext)
                observedItem = nil
                observerActive = false
            } else {
                print("observedItem == nil!")
            }
        }
    }
    
    func addPlayerObserver()
    {
        player?.currentItem?.addObserver(self,
                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.old, .new],
                                         context: &PlayerContext)
        observerActive = true
        observedItem = player?.currentItem
    }
    
    func playerURL(url: URL?)
    {
        guard let url = url else {
            return
        }
        
        removePlayerObserver()
        
        player = AVPlayer(url: url)
        
        addPlayerObserver()
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            guard Thread.isMainThread else {
                return
            }
            
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: oldValue)
            }

            setupTitle()
            
            notesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            slidesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            
            if let selectedMediaItem = selectedMediaItem {
                if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
                    removePlayerObserver()
                    
                    if globals.mediaPlayer.url != selectedMediaItem.playingURL {
                        updateUI()
                    }
                    
                    // Crashes because it uses UI and this is done before viewWillAppear when the mediaItemSelected is set in prepareForSegue, but it only happens on an iPhone because the MVC isn't setup already.
                    //                addSliderObserver()
                } else {
                    if let url = selectedMediaItem.playingURL {
                        playerURL(url: url)
                    } else {
                        print(selectedMediaItem.dict as Any)
                        networkUnavailable(self,"Media Not Available")
                    }
                }

                if selectedMediaItem.hasNotes {
                    notesDocument = documents[selectedMediaItem.id]?[Purpose.notes]
                    
                    if (notesDocument == nil) {
                        notesDocument = Document(purpose: Purpose.notes, mediaItem: selectedMediaItem)
                    }
                }
                
                if selectedMediaItem.hasSlides {
                    slidesDocument = documents[selectedMediaItem.id]?[Purpose.slides]
                    
                    if (slidesDocument == nil) {
                        slidesDocument = Document(purpose: Purpose.slides, mediaItem: selectedMediaItem)
                    }
                }

                mediaItems = selectedMediaItem.multiPartMediaItems // mediaItemsInMediaItemSeries(selectedMediaItem)
                
                globals.selectedMediaItem.detail = selectedMediaItem
                
                Thread.onMainThread() {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.selectedMediaItem) //
                }
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                mediaItems = nil
                for key in documents.keys {
                    if let documents = documents[key]?.values {
                        for document in documents {
                            document.wkWebView?.removeFromSuperview()
                            document.wkWebView?.scrollView.delegate = nil
                        }
                    }
                    documents[key] = nil
                }
            }
        }
    }
    
    var mediaItems:[MediaItem]?

    @IBOutlet weak var tableViewWidth: NSLayoutConstraint!
    {
        didSet {
            //Eliminates blank cells at end.
            tableView.tableFooterView = UIView()
            tableView.allowsSelection = true
        }
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!

    @IBOutlet weak var verticalSplit: UIView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.resetConstraint))
            tap.numberOfTapsRequired = 2
            verticalSplit?.addGestureRecognizer(tap)
        }
    }

    @IBOutlet weak var audioOrVideoControl: UISegmentedControl!
    {
        didSet {
            audioOrVideoControl.setTitle(Constants.FA.AUDIO, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO) // Audio
            audioOrVideoControl.setTitle(Constants.FA.VIDEO, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO) // Video
        }
    }
    @IBOutlet weak var audioOrVideoWidthConstraint: NSLayoutConstraint!
    
    @IBAction func audioOrVideoSelection(sender: UISegmentedControl)
    {
//        print(selectedMediaItem!.playing!)
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:audioOrVideoSelection", completion: nil)
            return
        }
        
        switch sender.selectedSegmentIndex {
        case Constants.AV_SEGMENT_INDEX.AUDIO:
            if let playing = selectedMediaItem?.playing {
                switch playing {
                case Playing.audio:
                    //Do nothing, already selected
                    break
                    
                case Playing.video:
                    if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        globals.mediaPlayer.stop() // IfPlaying
                        
                        tableView.isEditing = false
                        globals.mediaPlayer.view?.isHidden = true
                        
                        videoLocation = .withDocuments
                        
                        setupSpinner()
                        
                        removeSliderObserver()
                        
                        setupPlayPauseButton()
                        setupSliderAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                    
                    playerURL(url: selectedMediaItem?.playingURL)
                    
                    setupSliderAndTimes()
                    
                    setupDocumentsAndVideo() // Calls setupSTVControl()
                    break
                    
                default:
                    break
                }
            }
            break
            
        case Constants.AV_SEGMENT_INDEX.VIDEO:
            if let playing = selectedMediaItem?.playing {
                switch playing {
                case Playing.audio:
                    if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        globals.mediaPlayer.stop() // IfPlaying
                        
                        tableView.isEditing = false
                        setupSpinner()
                        
                        removeSliderObserver()
                        
                        setupPlayPauseButton()
                        setupSliderAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.video // Must come before setupNoteAndSlides()
                    
                    playerURL(url: selectedMediaItem?.playingURL)
                    
                    setupSliderAndTimes()
                    
                    // Don't need to change the documents (they are already showing) or hte STV control as that will change when the video starts playing.
                    break
                    
                case Playing.video:
                    //Do nothing, already selected
                    break
                    
                default:
                    break
                }
            }
            break
            
        default:
            print("oops!")
            break
        }
    }

    @IBOutlet weak var playPauseButton: UIButton! // UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var stvControl: UISegmentedControl!
    @IBOutlet weak var stvWidthConstraint: NSLayoutConstraint!
    @IBAction func stvAction(_ sender: UISegmentedControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stvAction", completion: nil)
            return
        }
        
        // This assumes this action isn't called unless an unselected segment is changed.  Otherwise touching the selected segment would cause it to flip to itself.
        
        var fromView:UIView?
        
        if let showing = selectedMediaItem?.showing {
            switch showing {
            case Showing.video:
                fromView = globals.mediaPlayer.view
                break
                
            default:
                fromView = wkWebView
                break
                
            }
        }
        
        var toView:UIView?
        
        if (sender.selectedSegmentIndex >= 0) && (sender.selectedSegmentIndex < sender.numberOfSegments){
            switch sender.titleForSegment(at: sender.selectedSegmentIndex)! {
            case Constants.STV_SEGMENT_TITLE.SLIDES:
                selectedMediaItem?.showing = Showing.slides
                toView = document?.wkWebView // s[selectedMediaItem!.id]?[Purpose.slides]
                mediaItemNotesAndSlides.gestureRecognizers = nil
                break
                
            case Constants.STV_SEGMENT_TITLE.TRANSCRIPT:
                selectedMediaItem?.showing = Showing.notes
                toView = document?.wkWebView // s[selectedMediaItem!.id]?[Purpose.notes]
                mediaItemNotesAndSlides.gestureRecognizers = nil
                break
                
            case Constants.STV_SEGMENT_TITLE.VIDEO:
                toView = globals.mediaPlayer.view
                selectedMediaItem?.showing = Showing.video
                mediaItemNotesAndSlides.gestureRecognizers = nil
                break
                
            default:
                break
            }
        }
        
        if (toView == nil) {
            toView = logo
        }

        if let toView = toView as? WKWebView {
            toView.isHidden = toView.isLoading
        } else {
            toView?.isHidden = false
        }
    
        if let loaded = document?.loaded, let download = document?.download {
            toView?.isHidden = !loaded
            
            if !loaded {
                if #available(iOS 9.0, *) {
                    if globals.cacheDownloads {
                        if (download.state != .downloading) {
                            setupDocumentsAndVideo()
                        } else {
                            progressIndicator.isHidden = false
                            activityIndicator.isHidden = false
                            activityIndicator.startAnimating()
                        }
                    } else {
                        if let isLoading = document?.wkWebView?.isLoading {
                            if !isLoading {
                                setupDocumentsAndVideo()
                            } else {
                                activityIndicator.isHidden = false
                                activityIndicator.startAnimating()
                            }
                        } else {
                            // No WKWebView
                            setupDocumentsAndVideo()
                        }
                    }
                } else {
                    if let isLoading = document?.wkWebView?.isLoading {
                        if !isLoading {
                            setupDocumentsAndVideo()
                        } else {
                            activityIndicator.isHidden = false
                            activityIndicator.startAnimating()
                        }
                    } else {
                        // No WKWebView
                        setupDocumentsAndVideo()
                    }
                }
            }
        }

        if let toView = toView, !toView.isHidden {
            mediaItemNotesAndSlides.bringSubview(toFront: toView)
        }
        
        if (fromView != toView) {
            fromView?.isHidden = true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext

        if keyPath == #keyPath(AVPlayerItem.status) {
            guard (context == &PlayerContext) else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
            }
            
            setupSliderAndTimes()
        }
        
//        if keyPath == #keyPath(WKWebView.estimatedProgress) {
//            if let showing = document?.showing(selectedMediaItem), showing {
//                if (document?.wkWebView == (object as? WKWebView)) {
//                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.progressIndicator.progress = Float(self.document!.wkWebView!.estimatedProgress)
//                        print(self.progressIndicator.progress)
//                        if self.progressIndicator.progress == 1 {
//                            self.activityIndicator.stopAnimating()
//                            self.activityIndicator.isHidden = true
//                            
//                            self.progressIndicator.isHidden = true
//                            (object as? WKWebView)?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
//                        }
//                    })
//                }
//            }
//        }
    }

    func setupSTVControl()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupSTVControl", completion: nil)
            return
        }

        guard stvControl != nil else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            stvControl.isEnabled = false
            stvControl.isHidden = true
            stvWidthConstraint.constant = 0
            view.setNeedsLayout()
            return
        }
        
        stvControl.removeAllSegments()
        
        var index = 0
        var slidesIndex = 0
        var notesIndex = 0
        var videoIndex = 0

        // This order: Transcript (aka Notes), Slides, Video matches the CBC web site.
        
        if selectedMediaItem.hasNotes {
            stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.TRANSCRIPT, at: index, animated: false)
            notesIndex = index
            index += 1
        }
        if selectedMediaItem.hasSlides {
            stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.SLIDES, at: index, animated: false)
            slidesIndex = index
            index += 1
        }
        if selectedMediaItem.hasVideo && (videoLocation == .withDocuments) { //  && !globals.mediaPlayer.loadFailed
            if (selectedMediaItem == globals.mediaPlayer.mediaItem) && globals.mediaPlayer.loaded {
                if (selectedMediaItem.playing == Playing.video) { //  && (selectedMediaItem?.showing == Showing.video)
                    stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.VIDEO, at: index, animated: false)
                    videoIndex = index
                    index += 1
                }
            }
        }
        
        if let showing = selectedMediaItem.showing {
            switch showing {
            case Showing.slides:
                stvControl.selectedSegmentIndex = slidesIndex
                mediaItemNotesAndSlides?.gestureRecognizers = nil
                break
                
            case Showing.notes:
                stvControl.selectedSegmentIndex = notesIndex
                mediaItemNotesAndSlides?.gestureRecognizers = nil
                break
                
            case Showing.video:
                stvControl.selectedSegmentIndex = videoIndex
                mediaItemNotesAndSlides?.gestureRecognizers = nil
                break
                
            case Showing.none:
                fallthrough
                
            default:
                break
            }
        }

        if (stvControl.numberOfSegments < 2) {
            stvControl.isEnabled = false
            stvControl.isHidden = true
            stvWidthConstraint.constant = 0
            view.setNeedsLayout()
        } else {
            stvControl.isEnabled = true
            stvControl.isHidden = false
        }
    }

    func setSegmentWidths()
    {
        guard Thread.isMainThread else {
            return
        }
        
        let minSliderWidth = CGFloat(75)
        
        let minTimeWidth = CGFloat(50)
        
        let avSpace:CGFloat = 4.0 * (audioOrVideoControl.numberOfSegments > 1 ? 2 : 1)
        
        let stvSpace:CGFloat = 4.0 * (stvControl.numberOfSegments > 1 ? 2 : 1)
        
        let freeWidth = view.frame.width - minSliderWidth - avSpace - stvSpace - (2 * minTimeWidth) // Time Elapsed and Remaining
        
        var segmentWidth:CGFloat = 0
        var fontSize:CGFloat = 0
        var maxSegmentWidth:CGFloat = 0
        
        if DeviceType.IS_IPHONE_6P_7P {
            maxSegmentWidth = 50
        } else {
            maxSegmentWidth = 60
        }

        if (audioOrVideoControl.numberOfSegments > 1) || (stvControl.numberOfSegments > 1) {
            segmentWidth = min(maxSegmentWidth,freeWidth / CGFloat(stvControl.numberOfSegments + audioOrVideoControl.numberOfSegments))
        }
        
        if audioOrVideoControl.isHidden {
            audioOrVideoWidthConstraint.constant = 0
        } else {
            if audioOrVideoControl.numberOfSegments > 1 {
                audioOrVideoWidthConstraint.constant = CGFloat(audioOrVideoControl.numberOfSegments) * segmentWidth
                
                fontSize = min(audioOrVideoControl.frame.height,segmentWidth) / 1.75
                
                audioOrVideoControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: fontSize) as Any], for: UIControlState.normal)
                audioOrVideoControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: fontSize) as Any], for: UIControlState.disabled)
            }
        }

        if stvControl.isHidden {
            stvWidthConstraint.constant = 0
        } else {
            if stvControl.numberOfSegments > 1 {
                stvWidthConstraint.constant = CGFloat(stvControl.numberOfSegments) * segmentWidth
                
                fontSize = min(stvControl.frame.height,segmentWidth) / 1.75
                
                stvControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: fontSize) as Any], for: UIControlState.normal)
                stvControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: fontSize) as Any], for: UIControlState.disabled)
            }
        }
        
        view.setNeedsLayout()
    }
    
    @IBAction func playPause(_ sender: UIButton)
    {
        guard (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) else {
            playNewMediaItem(selectedMediaItem)
            return
        }

        func showState(_ state:String)
        {
            print(state)
        }
        
        switch globals.mediaPlayer.state! {
        case .none:
            break
            
        case .playing:
            showState("playing")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            setupSpinner()
            break
            
        case .paused:
            showState("paused")
            if globals.mediaPlayer.loaded && (globals.mediaPlayer.url == selectedMediaItem?.playingURL) {
                playCurrentMediaItem(selectedMediaItem)
            } else {
                playNewMediaItem(selectedMediaItem)
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            break
        }
    }
    
    fileprivate func mediaItemNotesAndSlidesConstraintMinMax(_ height:CGFloat) -> (min:CGFloat,max:CGFloat)
    {
        var minConstraintConstant:CGFloat
        var maxConstraintConstant:CGFloat
        
        var minRows:CGFloat = 0
        
        switch videoLocation {
        case .withDocuments:
            break
            
        case .withTableView:
            minRows = 0
            break
        }
        
        minConstraintConstant = tableView.rowHeight * minRows + 44 // 44 is height of ControlView

        maxConstraintConstant = height // This assumes self.view does not go under top bars of any kind.

//        print("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
//        
//        print(minConstraintConstant,maxConstraintConstant)
        
        return (minConstraintConstant,maxConstraintConstant)
    }

    fileprivate func roomForLogo() -> Bool
    {
        guard let navigationController = navigationController else {
            return false
        }
        
        return mediaItemNotesAndSlidesConstraint.constant > (self.view.bounds.height - slider.bounds.height - navigationController.navigationBar.bounds.height - logo.bounds.height)
    }
    
    fileprivate func shouldShowLogo() -> Bool
    {
        guard selectedMediaItem != nil, let showing = selectedMediaItem?.showing else {
            return true
        }
        
        var result = false
        
        switch showing {
        case Showing.slides:
            fallthrough
        case Showing.notes:
            result = ((wkWebView == nil) || (wkWebView!.isHidden == true)) && progressIndicator.isHidden
            break
        
        case Showing.video:
            result = !globals.mediaPlayer.loaded
            break
            
        default:
            result = true
            break
        }
        
//        print(result)

        return result
    }

    fileprivate func setMediaItemNotesAndSlidesConstraint(_ change:CGFloat)
    {
        let newConstraintConstant = mediaItemNotesAndSlidesConstraint.constant + change
        
        //            print("pan rowHeight: \(tableView.rowHeight)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
//        verticalSplit.min = minConstraintConstant
//        verticalSplit.max = maxConstraintConstant
//        verticalSplit.height = mediaItemNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
        
//      Should not be here
//        logo.isHidden = !shouldShowLogo() //&& roomForLogo()
    }
    
    
    @IBOutlet weak var vSlideView: UIView!
    @IBAction func vSlideTap(_ sender: UITapGestureRecognizer)
    {
        guard controlViewTop.isActive else {
            return
        }
        
        controlViewTop.constant = 0
        self.view.setNeedsLayout()
    }
    @IBAction func vSlidePan(_ pan: UIPanGestureRecognizer)
    {
        guard controlViewTop.isActive else {
            return
        }
        
        switch pan.state {
        case .began:
            break
            
        case .ended:
            break
            
        case .changed:
            let translation = pan.translation(in: pan.view)
            
            if translation.y != 0 {
                if controlViewTop.constant + translation.y < -46 {
                    controlViewTop.constant = -46
                } else
                    if controlViewTop.constant + translation.y > 0 {
                        controlViewTop.constant = 0
                    } else {
                        controlViewTop.constant += translation.y
                }
                
                self.view.setNeedsLayout()
//                self.view.layoutSubviews()
            }

            pan.setTranslation(CGPoint.zero, in: pan.view)
            break
            
        default:
            break
        }
    }
    
    @IBOutlet weak var hSlideView: UIView!
    @IBAction func hSlideTap(_ sender: UITapGestureRecognizer)
    {
        guard tableViewWidth.isActive else {
            return
        }
        
        setTableViewWidth(width: self.view.bounds.size.width / 2)
        captureHorizontalSplit()
        self.view.setNeedsLayout()
    }
    @IBAction func hSlidePan(_ pan: UIPanGestureRecognizer)
    {
        guard tableViewWidth.isActive else {
            return
        }
        
        switch pan.state {
        case .began:
            break
            
        case .ended:
            captureHorizontalSplit()
            break
            
        case .changed:
            let translation = pan.translation(in: pan.view)
            
            if translation.x != 0 {
                setTableViewWidth(width: tableViewWidth.constant + -translation.x)
                self.view.setNeedsLayout()
//                self.view.layoutSubviews()
            }
            
            pan.setTranslation(CGPoint.zero, in: pan.view)
            break
            
        default:
            break
        }
    }

    
    @IBAction func verticalSplitPan(_ pan: UIPanGestureRecognizer)
    {
        guard view.subviews.contains(verticalSplit) else {
            return
        }
        
        guard mediaItemNotesAndSlidesConstraint.isActive else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        switch pan.state {
        case .began:
            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    document.wkWebView?.scrollView.delegate = nil
                }
            }

            panning = true
            break
            
        case .ended:
            captureVerticalSplit()

            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    document.wkWebView?.isHidden = (wkWebView?.url == nil)
                    document.wkWebView?.scrollView.delegate = self
                }
            }
            
            panning = false
            break
        
        case .changed:
            let translation = pan.translation(in: pan.view)
            let change = -translation.y
            if change != 0 {
                pan.setTranslation(CGPoint.zero, in: pan.view)
                setMediaItemNotesAndSlidesConstraint(change)
                self.view.setNeedsLayout()
                self.view.layoutSubviews()
            }
            break
            
        default:
            break
        }
    }
    
    @IBOutlet weak var elapsed: UILabel! {
        didSet {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.resetConstraint))
            doubleTap.numberOfTapsRequired = 2
            elapsed.addGestureRecognizer(doubleTap)

            let singleTap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.elapsedTapAction))
            singleTap.numberOfTapsRequired = 1
            elapsed.addGestureRecognizer(singleTap)
            
            singleTap.require(toFail: doubleTap)
        }
    }

    func elapsedTapAction()
    {
        guard globals.mediaPlayer.loaded, let currentTime = globals.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        if selectedMediaItem == globals.mediaPlayer.mediaItem {
            globals.mediaPlayer.seek(to: currentTime - Constants.SKIP_TIME_INTERVAL)
        }
    }
    
    @IBOutlet weak var remaining: UILabel! {
        didSet {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.resetConstraint))
            doubleTap.numberOfTapsRequired = 2
            remaining.addGestureRecognizer(doubleTap)
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.remainingTapAction))
            singleTap.numberOfTapsRequired = 1
            remaining.addGestureRecognizer(singleTap)
            
            singleTap.require(toFail: doubleTap)
        }
    }
    
    func remainingTapAction(_ sender: UITapGestureRecognizer)
    {
        guard globals.mediaPlayer.loaded, let currentTime = globals.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        if selectedMediaItem == globals.mediaPlayer.mediaItem {
            globals.mediaPlayer.seek(to: currentTime + Constants.SKIP_TIME_INTERVAL)
        }
    }
    
    @IBOutlet weak var mediaItemNotesAndSlidesConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mediaItemNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
//    {
//        get {
//            return _tableView
//        }
//        set {
//            _tableView = newValue
//        }
//    }

    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
        guard let length = globals.mediaPlayer.duration?.seconds else {
            return
        }
        
        if (slider.value < 1.0) {
            let seekToTime = Double(slider.value) * length
            
            globals.mediaPlayer.seek(to: seekToTime)
            
            globals.mediaPlayer.mediaItem?.currentTime = seekToTime.description
        } else {
            globals.mediaPlayer.pause()
            
            globals.mediaPlayer.seek(to: length)
            
            globals.mediaPlayer.mediaItem?.currentTime = length.description
        }
        
        switch globals.mediaPlayer.state! {
        case .playing:
            controlView.sliding = globals.reachability.isReachable
            break
            
        default:
            controlView.sliding = false
            break
        }
        
        globals.mediaPlayer.mediaItem?.atEnd = slider.value == 1.0
        
        globals.mediaPlayer.startTime = globals.mediaPlayer.mediaItem?.currentTime
        
        setupSpinner()
        setupPlayPauseButton()
        addSliderObserver()
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        print("sliderTouchDown")
        controlView.sliding = true
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider) {
        print("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        print("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider) {
        setTimesToSlider()
    }
    
    var actionButton:UIBarButtonItem?
    var tagsButton:UIBarButtonItem?

    func showSendMessageErrorAlert()
    {
        alert(viewController:self,title: "Could Not Send a Message",
              message: "Your device could not send a text message.  Please check your configuration and try again.",
              completion:nil)
    }
    
    func message(_ mediaItem:MediaItem?)
    {
        guard MFMessageComposeViewController.canSendText() else {
            showSendMailErrorAlert(viewController: self)
            return
        }

        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = nil
        messageComposeViewController.subject = "Recommendation"
        messageComposeViewController.body = mediaItem?.contents
        
        Thread.onMainThread() {
            self.present(messageComposeViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func openMediaItemScripture(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem else {
            return
        }
        
        var urlString = Constants.SCRIPTURE_URL.PREFIX + mediaItem.scriptureReference! + Constants.SCRIPTURE_URL.POSTFIX

        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

//        print("\(mediaItem!.scripture!)")
//        print("\(urlString)")
//        print("\(NSURL(string:urlString))")
        
        open(scheme: urlString) {
            networkUnavailable(self,"Unable to open scripture at: \(urlString)")
        }
    }
    
    func actionMenu() -> [String]?
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return nil
        }
        
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        var actionMenu = [String]()
        
        if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
            let hasVideo = selectedMediaItem.hasVideo
            let hasSlides = selectedMediaItem.hasSlides
            let hasNotes = selectedMediaItem.hasNotes
            
            if hasVideo && (selectedMediaItem.playing == Playing.video) &&
                (
                    ((videoLocation == .withDocuments) && (selectedMediaItem.showing == Showing.video)) ||
                    ((videoLocation == .withTableView) && (selectedMediaItem.showing != Showing.video))
                ) {
                actionMenu.append(Constants.Strings.Zoom_Video)
                
                if (hasSlides || hasNotes) && !globals.mediaPlayer.fullScreen {
                    actionMenu.append(Constants.Strings.Swap_Video_Location)
                }
            }
        }
        
        actionMenu.append(Constants.Strings.Scripture_Viewer)
        
        if selectedMediaItem.hasFavoritesTag {
            actionMenu.append(Constants.Strings.Remove_From_Favorites)
        } else {
            actionMenu.append(Constants.Strings.Add_to_Favorites)
        }
        
        if mediaItems.count > 1 {
            var favoriteMediaItems = 0
            
            for mediaItem in mediaItems {
                if (mediaItem.hasFavoritesTag) {
                    favoriteMediaItems += 1
                }
            }
            switch favoriteMediaItems {
            case 0:
                actionMenu.append(Constants.Strings.Add_All_to_Favorites)
                break
                
            case 1:
                actionMenu.append(Constants.Strings.Add_All_to_Favorites)
                
                if !selectedMediaItem.hasFavoritesTag {
                    actionMenu.append(Constants.Strings.Remove_All_From_Favorites)
                }
                break
                
            case mediaItems.count - 1:
                if selectedMediaItem.hasFavoritesTag {
                    actionMenu.append(Constants.Strings.Add_All_to_Favorites)
                }
                
                actionMenu.append(Constants.Strings.Remove_All_From_Favorites)
                break
                
            case mediaItems.count:
                actionMenu.append(Constants.Strings.Remove_All_From_Favorites)
                break
                
            default:
                actionMenu.append(Constants.Strings.Add_All_to_Favorites)
                actionMenu.append(Constants.Strings.Remove_All_From_Favorites)
                break
            }
        }
        
        if UIPrintInteractionController.isPrintingAvailable, let purpose = document?.purpose  {
            switch purpose {
            case Purpose.notes:
                actionMenu.append(Constants.Strings.Print_Transcript)
                break
                
            case Purpose.slides:
                actionMenu.append(Constants.Strings.Print_Slides)
                break
                
            default:
                break
            }
        }
        
        if document != nil, globals.cacheDownloads, let purpose = document?.purpose {
            switch purpose {
            case Purpose.notes:
                actionMenu.append(Constants.Strings.Refresh_Transcript)
                break
                
            case Purpose.slides:
                actionMenu.append(Constants.Strings.Refresh_Slides)
                break
                
            default:
                break
            }
        }
        
        actionMenu.append(Constants.Strings.Open_on_CBC_Website)
        
        var mediaItemsToDownload = 0
        var mediaItemsDownloading = 0
        var mediaItemsDownloaded = 0
        
        for mediaItem in mediaItems {
            if let download = mediaItem.audioDownload {
                switch download.state {
                case .none:
                    mediaItemsToDownload += 1
                    break
                case .downloading:
                    mediaItemsDownloading += 1
                    break
                case .downloaded:
                    mediaItemsDownloaded += 1
                    break
                }
            }
        }
        
        if let state = selectedMediaItem.audioDownload?.state {
            //                        print(selectedMediaItem?.audioDownload?.state)
            
            switch state {
            case .none:
                actionMenu.append(Constants.Strings.Download_Audio)
                break
                
            case .downloading:
                actionMenu.append(Constants.Strings.Cancel_Audio_Download)
                break
                
            case .downloaded:
                actionMenu.append(Constants.Strings.Delete_Audio_Download)
                break
            }
            
            switch state {
            case .none:
                if (mediaItemsToDownload > 1) {
                    actionMenu.append(Constants.Strings.Download_All_Audio)
                }
                if (mediaItemsDownloading > 0) {
                    actionMenu.append(Constants.Strings.Cancel_All_Audio_Downloads)
                }
                if (mediaItemsDownloaded > 0) {
                    actionMenu.append(Constants.Strings.Delete_All_Audio_Downloads)
                }
                break
                
            case .downloading:
                if (mediaItemsToDownload > 0) {
                    actionMenu.append(Constants.Strings.Download_All_Audio)
                }
                if (mediaItemsDownloading > 1) {
                    actionMenu.append(Constants.Strings.Cancel_All_Audio_Downloads)
                }
                if (mediaItemsDownloaded > 0) {
                    actionMenu.append(Constants.Strings.Delete_All_Audio_Downloads)
                }
                break
                
            case .downloaded:
                if (mediaItemsToDownload > 0) {
                    actionMenu.append(Constants.Strings.Download_All_Audio)
                }
                if (mediaItemsDownloading > 0) {
                    actionMenu.append(Constants.Strings.Cancel_All_Audio_Downloads)
                }
                if (mediaItemsDownloaded > 1) {
                    actionMenu.append(Constants.Strings.Delete_All_Audio_Downloads)
                }
                break
            }
        }
        
        actionMenu.append(Constants.Strings.Print)
        actionMenu.append(Constants.Strings.Share)
        
        if mediaItems.count > 1 {
            actionMenu.append(Constants.Strings.Share_All)
        }

        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

//            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                let hClass = traitCollection.horizontalSizeClass
//                
//                if hClass == .compact {
//                    navigationController.modalPresentationStyle = .overCurrentContext
//                } else {
//                    // I don't think this ever happens: collapsed and regular
//                    navigationController.modalPresentationStyle = .popover
//                }
//            } else {
//                navigationController.modalPresentationStyle = .popover
//            }
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            popover.section.strings = actionMenu()
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self
            
            Thread.onMainThread() {
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func zoomVideo()
    {
//        if splitViewController?.viewControllers.count > 1 {
//            if globals.mediaPlayer.fullScreen {
//                splitViewController?.preferredDisplayMode = .allVisible
//            } else {
//                splitViewController?.preferredDisplayMode = .automatic
//            }
//        }
        
        globals.mediaPlayer.fullScreen = !globals.mediaPlayer.fullScreen

//        if splitViewController?.viewControllers.count > 1 {
//            if (splitViewController?.viewControllers.count > 1) {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SHOW_HIDE), object: nil)
//                //                DispatchQueue.main.async(execute: { () -> Void in
//                //                })
//            }
//        }

        updateUI()
    }
    
    func videoPinch(_ pinch:UIPinchGestureRecognizer)
    {
        switch pinch.state {
        case .began:
            break
            
        case .ended:
            if globals.mediaPlayer.fullScreen != (pinch.scale > 1) {
                globals.mediaPlayer.fullScreen = pinch.scale > 1
                
                if globals.mediaPlayer.fullScreen {
                    splitViewController?.preferredDisplayMode = .primaryOverlay
                } else {
                    splitViewController?.preferredDisplayMode = .allVisible
                }
                
                globals.mediaPlayer.fullScreen = !globals.mediaPlayer.fullScreen
                updateUI()
            }
            break
            
        case .changed:
            break
            
        default:
            break
        }
    }
    
    func videoPan(_ pan:UIPanGestureRecognizer)
    {
        guard !globals.mediaPlayer.fullScreen else {
            return
        }
        
        switch pan.state {
        case .began:
            break
            
        case .ended:
            captureHorizontalSplit()
            captureVerticalSplit()
            break
            
        case .changed:
            let translation = pan.translation(in: pan.view)
            
            if translation.y != 0 {
                if controlViewTop.isActive {
                    if controlViewTop.constant + translation.y < -46 {
                        controlViewTop.constant = -46
                    } else
                        if controlViewTop.constant + translation.y > 0 {
                            controlViewTop.constant = 0
                        } else {
                            controlViewTop.constant += translation.y
                    }
                } else {

                }
                
                if mediaItemNotesAndSlidesConstraint.isActive {
                    let change = -translation.y
                    setMediaItemNotesAndSlidesConstraint(change)
                } else {
                    
                }
            }
            
            if translation.x != 0 {
                if tableViewWidth.isActive {
                    setTableViewWidth(width: tableViewWidth.constant + -translation.x)
                } else {
                    
                }
            }
            
            self.view.setNeedsLayout()
            //                self.view.layoutSubviews()
            
            pan.setTranslation(CGPoint.zero, in: pan.view)
            break
            
        default:
            break
        }
    }
    
    func swapVideoLocation()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:swapVideoLocation", completion: nil)
            return
        }
        
        switch videoLocation {
        case .withDocuments:
            selectedMediaItem?.showing = selectedMediaItem?.wasShowing
            videoLocation = .withTableView
            break
            
        case .withTableView:
            selectedMediaItem?.showing = Showing.video
            videoLocation = .withDocuments
            break
        }
        
        tableView.isEditing = false
        
        if globals.mediaPlayer.mediaItem == selectedMediaItem {
            updateUI()
        }
    }
    
    fileprivate func setupPlayerView(_ view:UIView?)
    {
        guard let view = view else {
            return
        }
        
        guard (mediaItemNotesAndSlides != nil) else {
            return
        }
        
        guard (tableView != nil) else {
            return
        }
        
        var parentView : UIView!

        switch videoLocation {
        case .withDocuments:
            parentView = mediaItemNotesAndSlides!
            tableView.isScrollEnabled = true
            break
            
        case .withTableView:
            parentView = tableView!
            tableView.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
            tableView.isScrollEnabled = false
            break
        }
        
        if globals.mediaPlayer.fullScreen {
//            if splitViewController?.viewControllers.count > 1 {
//                splitViewController?.preferredDisplayMode = .primaryHidden
//            }
            parentView = self.view
        }
        
        globals.mediaPlayer.showsPlaybackControls = globals.mediaPlayer.fullScreen
        
        view.gestureRecognizers = nil
        let pan = UIPanGestureRecognizer(target: self, action: #selector(MediaViewController.videoPan(_:)))
        view.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MediaViewController.videoPinch(_:)))
        view.addGestureRecognizer(pinch)
        
        view.isHidden = true
        view.removeFromSuperview()
        
        view.frame = parentView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let contain = parentView?.subviews.contains(view), !contain {
            parentView.addSubview(view)
        }
        
        //            print(view)
        //            print(view?.superview)
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(height)
        
        view.superview?.setNeedsLayout()
    }
    
    fileprivate func setupWKWebView(_ wkWebView:WKWebView?)
    {
        guard let wkWebView = wkWebView else {
            return
        }
        
        wkWebView.isMultipleTouchEnabled = true
        
        wkWebView.scrollView.scrollsToTop = false
        
        wkWebView.scrollView.delegate = self
        wkWebView.navigationDelegate = self
        
        wkWebView.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        mediaItemNotesAndSlides.addSubview(wkWebView)
        
        let centerXNotes = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        mediaItemNotesAndSlides.addConstraint(centerXNotes)
        
        let centerYNotes = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        mediaItemNotesAndSlides.addConstraint(centerYNotes)
        
        let widthXNotes = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        mediaItemNotesAndSlides.addConstraint(widthXNotes)
        
        let widthYNotes = NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: wkWebView.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        mediaItemNotesAndSlides.addConstraint(widthYNotes)
        
        mediaItemNotesAndSlides.setNeedsLayout()
    }
    
    func readyToPlay()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:readyToPlay", completion: nil)
            return
        }
        
        guard globals.mediaPlayer.loaded else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
        
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            return
        }

        if globals.mediaPlayer.playOnLoad {
            if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing != Showing.video) {
                selectedMediaItem?.showing = Showing.video
            }
        }
        
        if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing == Showing.video) {
            globals.mediaPlayer.view?.isHidden = false
            
            if let view = globals.mediaPlayer.view {
                mediaItemNotesAndSlides.bringSubview(toFront: view)
            }
        }

        if globals.mediaPlayer.playOnLoad {
            if let atEnd = globals.mediaPlayer.mediaItem?.atEnd, atEnd {
                globals.mediaPlayer.seek(to: 0)
                globals.mediaPlayer.mediaItem?.atEnd = false
            }
            globals.mediaPlayer.playOnLoad = false
            
            // Purely for the delay?
            DispatchQueue.global(qos: .background).async(execute: {
                DispatchQueue.main.async(execute: { () -> Void in
                    globals.mediaPlayer.play()
                })
            })
        }
        
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()

        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }
    
    func paused()
    {
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    func failedToLoad()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                globals.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    func failedToPlay()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                globals.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    func showPlaying()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:showPlaying", completion: nil)
            return
        }
        
        guard (globals.mediaPlayer.mediaItem != nil) else {
            globals.mediaPlayer.view?.isHidden = true
            videoLocation = .withDocuments
            removeSliderObserver()
            playerURL(url: selectedMediaItem?.playingURL)
            updateUI()
            return
        }
        
        guard   let mediaItem = globals.mediaPlayer.mediaItem,
                let _ = selectedMediaItem?.multiPartMediaItems?.index(of: mediaItem) else {
            return
        }
        
        selectedMediaItem = globals.mediaPlayer.mediaItem
        
        //            tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            Thread.onMainThread() {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }
        
        updateUI()
    }
    
    func updateView()
    {
        selectedMediaItem = globals.selectedMediaItem.detail
        
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            Thread.onMainThread() {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }
        
        // This reloads all of the documents and sets the zoomscale and content offset correctly.
        if let id = selectedMediaItem?.id, let keys = documents[id]?.keys {
            for key in keys {
                documents[id]?[key]?.loaded = false
            }
        }

        updateUI()
    }
    
    func clearView()
    {
        Thread.onMainThread() {
            self.dismiss(animated: true, completion: nil) // In case a dialog is visible.
            
            self.navigationItem.hidesBackButton = true // In case this MVC was pushed from the ScriptureIndexController.
            
            self.selectedMediaItem = nil
            
            self.tableView.reloadData()
            
            self.updateUI()
        }
    }

    override func viewDidLoad()
    {
        // Do any additional setup after loading the view.
        super.viewDidLoad()

        navigationController?.setToolbarHidden(true, animated: false)
        
//        navigationItem.leftItemsSupplementBackButton = true
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension

        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
//        if (splitViewController?.preferredDisplayMode == .automatic) { // UIDeviceOrientationIsPortrait(UIDevice.current.orientation) && 
//            splitViewController?.preferredDisplayMode = .allVisible //iPad only.
//        }
    }

    fileprivate func setupDefaultDocuments()
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        verticalSplit.isHidden = false
        
        let hasNotes = selectedMediaItem.hasNotes // && notesDocument!.loaded
        let hasSlides = selectedMediaItem.hasSlides // && slidesDocument!.loaded
        
        globals.mediaPlayer.view?.isHidden = true
        
        if (!hasSlides && !hasNotes) || (globals.reachability.currentReachabilityStatus == .notReachable) {
            hideAllDocuments()
            
            logo.isHidden = false
            
            if globals.reachability.isReachable { // currentReachabilityStatus != .notReachable
                selectedMediaItem.showing = Showing.none
            }
            
            mediaItemNotesAndSlides.bringSubview(toFront: logo)
        } else
        if (hasSlides && !hasNotes) {
            selectedMediaItem.showing = Showing.slides

            hideOtherDocuments()

            if let wkWebView = wkWebView {
                logo.isHidden = true
                wkWebView.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: wkWebView)
            } else {
                logo.isHidden = false
            }
        } else
        if (!hasSlides && hasNotes) {
            selectedMediaItem.showing = Showing.notes

            hideOtherDocuments()
            
            if let wkWebView = wkWebView {
                logo.isHidden = true
                wkWebView.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: wkWebView)
            } else {
                logo.isHidden = false
            }
        } else
        if (hasSlides && hasNotes) {
            selectedMediaItem.showing = selectedMediaItem.wasShowing

            hideOtherDocuments()
            
            if let wkWebView = wkWebView {
                logo.isHidden = true
                wkWebView.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: wkWebView)
            } else {
                logo.isHidden = false
            }
        }
    }
    
    func loading(_ timer:Timer?)
    {
        // Expected to be on the main thread
        guard let document = (timer?.userInfo as? Document) else {
            return
        }

        if let isLoading = document.wkWebView?.isLoading, !isLoading {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            progressIndicator.isHidden = true
            
            document.loadTimer?.invalidate()
            document.loadTimer = nil
        } else {
            if let wkWebView = document.wkWebView {
                progressIndicator.isHidden = !wkWebView.isHidden
                activityIndicator.isHidden = !wkWebView.isHidden
            }
            
            if !activityIndicator.isHidden {
                activityIndicator.startAnimating()
            }
            
            if document.showing(selectedMediaItem) {
                if let estimatedProgress = document.wkWebView?.estimatedProgress {
                    print(estimatedProgress)
                    progressIndicator.progress = Float(estimatedProgress)
                }
            }
        }
    }
    
    fileprivate func setupDocument(_ document:Document?)
    {
//        print("setupDocument")
        
        guard let document = document else {
            return
        }
        
        if document.wkWebView == nil {
            document.wkWebView = WKWebView(frame: mediaItemNotesAndSlides.bounds)
        }
        
        if let wkWebView = document.wkWebView {
            if !mediaItemNotesAndSlides.subviews.contains(wkWebView) {
                setupWKWebView(wkWebView)
            }
        }

        if !document.loaded {
            loadDocument(document)
        }
    }
    
    func downloadFailed(_ notification:NSNotification)
    {
        if let download = notification.object as? Download, document?.download == download {
//            if let purpose = document?.purpose {
//                switch purpose {
//                case Purpose.slides:
//                    networkUnavailable(self,"Slides not available.")
//                    break
//                    
//                case Purpose.notes:
//                    networkUnavailable(self,"Transcript not available.")
//                    break
//                    
//                default:
//                    break
//                }
//            }
            Thread.onMainThread() {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                self.logo.isHidden = false
                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
        }
    }
    
    fileprivate func loadDocument(_ document:Document?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:loadDocument", completion: nil)
            return
        }

        guard let document = document else {
            return
        }
        
        guard let loading = document.wkWebView?.isLoading, !loading else {
            return
        }
        
        guard globals.cacheDownloads || globals.reachability.isReachable else { // currentReachabilityStatus != .notReachable
            return
        }
        
        document.wkWebView?.isHidden = true
        document.wkWebView?.stopLoading()
        
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads, let download = document.download {
//                print(document?.download?.state)
                if download.state != .downloaded {
                    if document.showing(selectedMediaItem) {
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.progress = download.totalBytesExpectedToWrite != 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                        self.progressIndicator.isHidden = false
                        
//                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.activityIndicator)
//                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.progressIndicator)
                        
                        // Unlike below, this doesn't seem to be necessary
//                        DispatchQueue.main.async {
//                        }
                    }

                    Thread.onMainThread(block: {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: document.download)
                    })

//                    document?.download?.observer = #selector(MediaViewController.downloadFailed)

                    download.download()
                } else {
                    if let fileSystemURL = download.fileSystemURL { //, let downloadURL = document?.download?.downloadURL
                        if document.showing(self.selectedMediaItem) {
                            // Even thought we're on the main thread without this dispatch these will never show up.
                            DispatchQueue.main.async {
                                self.activityIndicator.isHidden = false
                                self.activityIndicator.startAnimating()
                                
                                self.mediaItemNotesAndSlides.bringSubview(toFront: self.activityIndicator)
                            }
                        }
                        
//                        DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                            //                        print(document!.download!.fileSystemURL!)
                            _ = document.wkWebView?.loadFileURL(fileSystemURL, allowingReadAccessTo: fileSystemURL)
                            
                            //                        if let fileSystemURL = document?.download?.fileSystemURL { //, let downloadURL = document?.download?.downloadURL
                            //                            _ = document?.wkWebView?.loadFileURL(fileSystemURL, allowingReadAccessTo: fileSystemURL)
                            //                        }
//                        })
                    }
                }
            } else {
                if document.showing(self.selectedMediaItem) {
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                    
                    self.progressIndicator.isHidden = false
                }
                
                if document.loadTimer == nil {
                    document.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                }

                ///////
                
//                if (document == nil) {
//                    print("document nil")
//                }
                if (document.download == nil) {
                    print("document!.download nil")
                }
                if (document.download?.downloadURL == nil) {
                    print("\(String(describing: self.selectedMediaItem?.title))")
                    print("document!.download!.downloadURL nil")
                }
                
                if let url = document.download?.downloadURL {
                    let request = URLRequest(url: url)
                    _ = document.wkWebView?.load(request)
                }
            }
        } else {
            if document.showing(self.selectedMediaItem) {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                
                self.progressIndicator.isHidden = false
            }
            
            if document.loadTimer == nil {
                document.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
            }

            ///////
            
            if let url = document.download?.downloadURL {
                let request = URLRequest(url: url)
                _ = document.wkWebView?.load(request)
            }
        }
    }
    
    fileprivate func hideOtherDocuments()
    {
        if let selectedMediaItem = selectedMediaItem {
            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    if !document.showing(selectedMediaItem) {
                        document.wkWebView?.isHidden = true
                    }
                }
            }
        }
    }
    
    fileprivate func hideAllDocuments()
    {
        if let selectedMediaItem = selectedMediaItem {
            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    document.wkWebView?.isHidden = true
                }
            }
        }
    }
    
    fileprivate func setupDocumentsAndVideo()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupDocumentsAndVideo", completion: nil)
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            verticalSplit.isHidden = true
            
            hideAllDocuments()
            
            globals.mediaPlayer.view?.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if !logo.isHidden {
                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
            
            setupAudioOrVideo()
            setupSTVControl()
            setSegmentWidths()
            return
        }
        
        activityIndicator.isHidden = true

        progressIndicator.isHidden = true
        progressIndicator.progress = 0.0

//        print("setupNotesAndSlides")
//        print("Selected: \(globals.mediaItemSelected?.title)")
//        print("Last Selected: \(globals.mediaItemLastSelected?.title)")
//        print("Playing: \(globals.player.playing?.title)")
        
        verticalSplit.isHidden = false

        if selectedMediaItem.hasNotes {
            notesDocument = documents[selectedMediaItem.id]?[Purpose.notes]
            
            if (notesDocument == nil) {
                notesDocument = Document(purpose: Purpose.notes, mediaItem: selectedMediaItem)
            }
//                print(notesDocument?.download?.downloadURL)
            setupDocument(notesDocument)
        } else {
            notesDocument?.wkWebView?.isHidden = true
        }
        
        if selectedMediaItem.hasSlides {
            slidesDocument = documents[selectedMediaItem.id]?[Purpose.slides]
            
            if (slidesDocument == nil) {
                slidesDocument = Document(purpose: Purpose.slides, mediaItem: selectedMediaItem)
            }
//                print(slidesDocument?.download?.downloadURL)
            setupDocument(slidesDocument)
        } else {
            slidesDocument?.wkWebView?.isHidden = true
        }
        
//        print("notes hidden \(mediaItemNotes.hidden)")
//        print("slides hidden \(mediaItemSlides.hidden)")
        
        // Check whether they show what they should!
        
        switch (selectedMediaItem.hasNotes,selectedMediaItem.hasSlides) {
        case (true,true):
            if selectedMediaItem.showing == Showing.none {
                selectedMediaItem.showing = selectedMediaItem.wasShowing
            }
            break
            
        case (true,false):
            if selectedMediaItem.showing == Showing.none {
                selectedMediaItem.showing = Showing.notes
            }
            break
            
        case (false,true):
            if selectedMediaItem.showing == Showing.none {
                selectedMediaItem.showing = Showing.slides
            }
            break
            
        case (false,false):
            if selectedMediaItem.hasVideo {
                if (selectedMediaItem.showing != Showing.none) && (selectedMediaItem.showing != Showing.video) {
                    print("ERROR")
                }
            } else {
                if (selectedMediaItem.showing != Showing.none) {
                    print("ERROR")
                }
            }
            break
        }
        
        // Check whether they can or should show what they claim to show!
        
        if let showing = selectedMediaItem.showing {
            switch showing {
            case Showing.notes:
                if !selectedMediaItem.hasNotes {
                    selectedMediaItem.showing = Showing.none
                }
                break
                
            case Showing.slides:
                if !selectedMediaItem.hasSlides {
                    selectedMediaItem.showing = Showing.none
                }
                break
                
            case Showing.video:
                if !selectedMediaItem.hasVideo {
                    selectedMediaItem.showing = Showing.none
                }
                break
                
            default:
                break
            }
        }
        
        if var showing = selectedMediaItem.showing {
            // Account for the use of the cache.
            if !globals.cacheDownloads && (globals.reachability.currentReachabilityStatus == .notReachable) {
                switch showing {
                case Showing.slides:
                    alert(viewController: self, title: "Slides Not Available", message: nil, completion: nil)
                    break
                    
                case Showing.notes:
                    alert(viewController: self, title: "Transcript Not Available", message: nil, completion: nil)
                    break
                    
                default:
                    break
                }
                
                showing = Showing.none
            }
            
            switch showing {
            case Showing.notes:
                fallthrough
            case Showing.slides:
                globals.mediaPlayer.view?.isHidden = videoLocation == .withDocuments
                logo.isHidden = true
                
                hideOtherDocuments()
                
                if let wkWebView = wkWebView {
                    if globals.cacheDownloads {
                        if let state = document?.download?.state {
                            wkWebView.isHidden = (state != .downloaded)
                        }
                    } else {
                        wkWebView.isHidden = wkWebView.isLoading
                    }
                    
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView)
                }
                break
                
            case Showing.video:
                //This should not happen unless it is playing video.
                if let playing = selectedMediaItem.playing {
                    switch playing {
                    case Playing.audio:
                        setupDefaultDocuments()
                        break
                        
                    case Playing.video:
                        if (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                            hideAllDocuments()
                            
                            logo.isHidden = globals.mediaPlayer.loaded
                            globals.mediaPlayer.view?.isHidden = !globals.mediaPlayer.loaded
                            
                            selectedMediaItem.showing = Showing.video
                            
                            if (globals.mediaPlayer.player != nil) {
                                // Why is this commented out?
                                //                            mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                            } else {
                                setupDefaultDocuments()
                            }
                        } else {
                            //This should never happen.
                            setupDefaultDocuments()
                        }
                        break
                        
                    default:
                        break
                    }
                }
                break
                
            case Showing.none:
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                hideAllDocuments()
                
                if let playing = selectedMediaItem.playing {
                    switch playing {
                    case Playing.audio:
                        globals.mediaPlayer.view?.isHidden = true
                        setupDefaultDocuments()
                        break
                        
                    case Playing.video:
                        if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                            if (selectedMediaItem.hasVideo && (selectedMediaItem.playing == Playing.video)) {
                                if let view = globals.mediaPlayer.view {
                                    if globals.mediaPlayer.loaded {
                                        view.isHidden = false
                                    }
                                    
                                    mediaItemNotesAndSlides.bringSubview(toFront: view)
                                    
                                    selectedMediaItem.showing = Showing.video
                                }
                            } else {
                                globals.mediaPlayer.view?.isHidden = true
                                self.logo.isHidden = false
                                selectedMediaItem.showing = Showing.none
                                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                            }
                        } else {
                            globals.mediaPlayer.view?.isHidden = true
                            setupDefaultDocuments()
                        }
                        break
                        
                    default:
                        break
                    }
                }
                break
                
            default:
                break
            }
        }

        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }
    
    func scrollToMediaItem(_ mediaItem:MediaItem?,select:Bool,position:UITableViewScrollPosition)
    {
        guard let mediaItem = mediaItem else {
            return
        }

        var indexPath = IndexPath(row: 0, section: 0)
        
        if mediaItems?.count > 0, let mediaItemIndex = mediaItems?.index(of: mediaItem) {
            //                    print("\(mediaItemIndex)")
            indexPath = IndexPath(row: mediaItemIndex, section: 0)
        }
        
        //            print("\(tableView.bounds)")
        
        guard indexPath.section >= 0, indexPath.section < tableView.numberOfSections else {
            NSLog("indexPath section ERROR in scrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            return
        }
        
        guard indexPath.row >= 0, indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
            NSLog("indexPath row ERROR in scrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            NSLog("Row: \(indexPath.row)")
            NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
            return
        }
        
        if select {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: position)
        }

        tableView.scrollToRow(at: indexPath, at: position, animated: false)
    }
    
    func setupPlayPauseButton()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupPlayPauseButton", completion: nil)
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            return
        }
        
        guard selectedMediaItem.hasAudio || selectedMediaItem.hasVideo else {
            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = false
            return
        }
        
        func showState(_ state:String)
        {
//            print(state)
        }

        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            playPauseButton.isEnabled = globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed
            
            if let state = globals.mediaPlayer.state {
                switch state {
                case .playing:
                    showState("Playing -> Pause")
                    
                    playPauseButton.setTitle(Constants.FA.PAUSE, for: UIControlState.normal)
                    break
                    
                case .paused:
                    showState("Paused -> Play")
                  
                    playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
                    break
                    
                default:
                    playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
                    break
                }
            }
        } else {
            showState("Global not selected")
            playPauseButton.isEnabled = true

            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
        }

        playPauseButton.isHidden = false
    }
    
    func tags(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:tags", completion: nil)
            return
        }

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.filters
        //And when the user chooses one, scroll to the first time in that section.
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Tags
            
            popover.delegate = self
            
            popover.purpose = .showingTags
            popover.section.strings = selectedMediaItem?.tagsArray
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.allowsSelection = false
            popover.selectedMediaItem = selectedMediaItem
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func setupActionAndTagsButtons()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            actionButton = nil
            tagsButton = nil
            self.navigationItem.setRightBarButtonItems(nil, animated: true)
            return
        }

        var barButtons = [UIBarButtonItem]()
        
        if actionMenu()?.count > 0 {
            actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.actions))
            actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
            actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.disabled)
            
            if let actionButton = actionButton {
                barButtons.append(actionButton)
            }
        }
    
        if selectedMediaItem.hasTags {
            if (selectedMediaItem.tagsSet?.count > 1) {
                tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
            } else {
                tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
            }
            
            tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.normal)
            tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.disabled)
            
            if let tagsButton = tagsButton {
                barButtons.append(tagsButton)
            }
        } else {
            
        }

        if barButtons.count > 0 {
            navigationItem.setRightBarButtonItems(barButtons, animated: true)
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }

//    override var prefersStatusBarHidden : Bool
//    {
//        return true
//    }
    
    func setupWKContentOffsets()
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        
        guard let documents = documents[selectedMediaItem.id]?.values else {
            return
        }
        
        for document in documents {
            if let wkWebView = document.wkWebView {
                var contentOffsetXRatio:Float = 0.0
                var contentOffsetYRatio:Float = 0.0
                
                //        print("\(mediaItemNotesWebView!.scrollView.contentSize)")
                //        print("\(mediaItemSlidesWebView!.scrollView.contentSize)")
                
                if let purpose = document.purpose, let ratio = selectedMediaItem.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X_RATIO] {
                    contentOffsetXRatio = Float(ratio)!
                }
                
                if let purpose = document.purpose, let ratio = selectedMediaItem.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y_RATIO] {
                    contentOffsetYRatio = Float(ratio)!
                }
                
                let contentOffset = CGPoint(
                    x: CGFloat(contentOffsetXRatio) * wkWebView.scrollView.contentSize.width,
                    y: CGFloat(contentOffsetYRatio) * wkWebView.scrollView.contentSize.height)
                
                Thread.onMainThread() {
                    wkWebView.scrollView.setContentOffset(contentOffset, animated: false)
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if self.videoLocation == .withTableView {
                self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: false)
            } else {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
            
            self.setupWKContentOffsets()
            
            self.setupVerticalSplit()
            self.setupHorizontalSplit()
            
            self.setupAudioOrVideo()
            self.setupSTVControl()
            self.setSegmentWidths()
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setupTitle()
            
//            if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
//                print("splitViewController.isCollapsed == true")
//            }

            self.setDVCLeftBarButton()
//            if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//                let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
//                let count = self.splitViewController?.viewControllers.count {
//                if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                    } else {
//                        navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
//                    }
//                }
//            }
            
            if self.videoLocation == .withTableView {
                self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: false)
            } else {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
            
            self.setupWKContentOffsets()
            
            self.setupVerticalSplit()
            self.setupHorizontalSplit()
        }
    }
    
    func ratioForSplitView(_ sender: UIView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if let verticalSplit = selectedMediaItem?.verticalSplit, let num = Float(verticalSplit) {
            ratio = CGFloat(num)
        }
        //        print("ratio: '\(ratio)")
        return ratio
    }
    
    func ratioForSlideView() -> CGFloat?
    {
        var ratio:CGFloat?
        
        if let horizontalSplit = selectedMediaItem?.horizontalSplit, let num = Float(horizontalSplit) {
            ratio = CGFloat(num)
        }
        //        print("ratio: '\(ratio)")
        return ratio
    }
    
    func defaultTableViewWidth()
    {
        guard tableViewWidth.isActive else {
            return
        }
        
        if let view = self.view {
            tableViewWidth.constant = view.bounds.size.width / 2
        }
    }
    
    func setTableViewWidth(width:CGFloat)
    {
        guard tableViewWidth.isActive else {
            return
        }
        
        if (width >= 0) && (width <= self.view.bounds.size.width) {
            tableViewWidth.constant = width
        }
        if (width < 0) {
            tableViewWidth.constant = 0
        }
        if (width > self.view.bounds.size.width) {
            tableViewWidth.constant = self.view.bounds.size.width
        }
    }
    
    func resetConstraint()
    {
        guard view.subviews.contains(verticalSplit) else {
            return
        }
        
        guard mediaItemNotesAndSlidesConstraint.isActive else {
            return
        }
        
        var newConstraintConstant:CGFloat
        
        //        print("setupVerticalSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        newConstraintConstant = self.view.bounds.height / 2 + controlView.bounds.height / 2
        
        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        
//        verticalSplit.min = minConstraintConstant
//        verticalSplit.max = maxConstraintConstant
//        verticalSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
        
        captureVerticalSplit()
    }
    
    fileprivate func setupHorizontalSplit()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard tableViewWidth.isActive else {
            return
        }
        
        if let ratio = ratioForSlideView() {
            //            print("\(self.view.bounds.height)")
            setTableViewWidth(width: self.view.bounds.width * ratio)
        } else {
            setTableViewWidth(width: self.view.bounds.width / 2)
        }
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupVerticalSplit()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard view.subviews.contains(verticalSplit) else {
            return
        }
        
        guard mediaItemNotesAndSlidesConstraint.isActive else {
            return
        }

        var newConstraintConstant:CGFloat = 0
        
//        print("setupVerticalSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(verticalSplit) {
//            print("\(self.view.bounds.height)")
            newConstraintConstant = self.view.bounds.height * ratio
        } else {
            if let count = mediaItems?.count {
                let numberOfAdditionalRows = CGFloat(count)
                newConstraintConstant = minConstraintConstant + tableView.rowHeight * numberOfAdditionalRows
                
                if newConstraintConstant > ((maxConstraintConstant+minConstraintConstant)/2) {
                    newConstraintConstant = (maxConstraintConstant+minConstraintConstant)/2
                }
            }
        }

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }

//        verticalSplit.min = minConstraintConstant
//        verticalSplit.max = maxConstraintConstant
//        verticalSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupTitle()
    {
        guard Thread.isMainThread else {
            return
        }
        
        self.navigationItem.title = selectedMediaItem?.title

//        if (selectedMediaItem != nil) {
//            self.navigationItem.title = selectedMediaItem?.title
//            
//            // Prefere to see the specific title
////            if (selectedMediaItem!.hasMultipleParts) {
////                //The selected mediaItem is in a series so set the title.
////                self.navigationItem.title = selectedMediaItem?.multiPartName
////            } else {
//////                print(selectedMediaItem?.title ?? nil)
////                self.navigationItem.title = selectedMediaItem?.title
////            }
//        } else {
//            self.navigationItem.title = nil
//        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.hasAudio && selectedMediaItem.hasVideo else {
            self.audioOrVideoControl.isEnabled = false
            self.audioOrVideoControl.isHidden = true
            self.audioOrVideoWidthConstraint.constant = 0
            view.setNeedsLayout()
            return
        }
        
        audioOrVideoControl.isEnabled = true
        audioOrVideoControl.isHidden = false
        
        audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO)
        audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO)
        
        if let playing = selectedMediaItem.playing {
            switch playing {
            case Playing.audio:
                audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.AUDIO
                break
                
            case Playing.video:
                audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.VIDEO
                break
                
            default:
                break
            }
        }
        
//        audioOrVideoControl.setTitle(Constants.FA.AUDIO, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO) // Audio
//        audioOrVideoControl.setTitle(Constants.FA.VIDEO, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO) // Video
    }
    
    func updateUI()
    {
        if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (globals.mediaPlayer.url != selectedMediaItem?.playingURL) {
                //            ((globals.mediaPlayer.url != selectedMediaItem?.videoURL) && (globals.mediaPlayer.url != selectedMediaItem?.audioURL)) {
                globals.mediaPlayer.killPIP = true
                globals.mediaPlayer.pause()
                globals.mediaPlayer.setup(selectedMediaItem,playOnLoad:false)
            } else {
                if globals.mediaPlayer.loadFailed && (logo != nil) {
                    logo.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: logo)
                }
            }
        }
        
        setupPlayerView(globals.mediaPlayer.view)

        //        print("viewWillAppear 1 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        setDVCLeftBarButton()

        setupVerticalSplit()
        setupHorizontalSplit()
        
        //        print("viewWillAppear 2 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the mediaItem selected is playing already
        addSliderObserver()
        
        setupTitle()
        setupPlayPauseButton()
        setupSpinner()
        setupSliderAndTimes()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }
    
    func doneSeeking()
    {
        controlView.sliding = false
        print("DONE SEEKING")
    }
    
    var orientation : UIDeviceOrientation?
    
    func deviceOrientationDidChange()
    {
        guard popover?.popoverPresentationController?.presentationStyle == .popover else {
            return
        }
        
        switch orientation! {
        case .faceUp:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .landscapeRight:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .faceDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .landscapeRight:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portrait:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portraitUpsideDown:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .landscapeLeft:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portrait:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portraitUpsideDown:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .landscapeRight:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                break
                
            case .portrait:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portraitUpsideDown:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .portrait:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .landscapeRight:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .portraitUpsideDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .landscapeRight:
                popover?.dismiss(animated: true, completion: nil)
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                popover?.dismiss(animated: true, completion: nil)
                break
            }
            break
            
        case .unknown:
            break
        }

        switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                orientation = UIDevice.current.orientation
                break
                
            case .landscapeRight:
                orientation = UIDevice.current.orientation
                break
                
            case .portrait:
                orientation = UIDevice.current.orientation
                break
                
            case .portraitUpsideDown:
                orientation = UIDevice.current.orientation
                break
                
            case .unknown:
                break
        }
    }
    
    func stopEditing()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stopEditing", completion: nil)
            return
        }
        
        tableView.isEditing = false
    }
    
    func willEnterForeground()
    {
        
    }
    
    func didBecomeActive()
    {
//        updateUI() // TOO MUCH.  The mediaPlayer.reload in AppDelegate willEnterForeground makes a mess of this.
        setDVCLeftBarButton()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToLoad), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        
        if (self.splitViewController?.viewControllers.count > 1) {
            //            updateView()  // This caused a bug where PDF's would not appear.  The document.mediaItem == selectedMediaItem was SOMETIMES(!) false, seemingly depending on the run
            // i.e. starting over might give you a different result, but I'm not even sure that was the real cause or why!
            
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        orientation = UIDevice.current.orientation
        
        navigationController?.isToolbarHidden = true

        // Shouldn't some or all of these have object values of selectedMediaItem?
        
//        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        addNotifications()

//        if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//            let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
//            let count = self.splitViewController?.viewControllers.count {
//            if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                    navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                } else {
//                    navigationController.topViewController?.navigationItem.leftBarButtonItem = nil
//                }
//            }
//        }

        if let mediaItem = globals.mediaPlayer.mediaItem, mediaItem == selectedMediaItem, globals.mediaPlayer.isPaused, mediaItem.hasCurrentTime, let currentTime = mediaItem.currentTime {
//        if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) && globals.mediaPlayer.isPaused && globals.mediaPlayer.mediaItem!.hasCurrentTime() {
            globals.mediaPlayer.seek(to: Double(currentTime))
        }

        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
//        if (splitViewController?.preferredDisplayMode == .automatic) { // UIDeviceOrientationIsPortrait(UIDevice.current.orientation) &&
//            splitViewController?.preferredDisplayMode = .allVisible //iPad only
//        }

        self.updateUI()

        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread() {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        })
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        } else {
            if let count = splitViewController?.viewControllers.count, let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                if let _ = nvc.visibleViewController as? WebViewController {
                    splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                } else {
                    splitViewController?.preferredDisplayMode = .automatic //iPad only
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
//        // UGLY Hack to fix iOS 11 constraint problem.
//        // Will NOT work viewWillAppear
//        if #available(iOS 11.0, *) {
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                if (UIDevice.current.orientation == .landscapeRight) || (UIDevice.current.orientation == .landscapeLeft) {
//                    view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y - 12, width: view.frame.width, height: view.frame.height + 12)
//                }
//            }
//        } else {
//            // Fallback on earlier versions
//        }

        // Seems like a strange way to force MTVC to be the visible view controller.  Not sure this ever happens since it would only be during loading while the splitViewController is collapsed.
        // Which means either on an iPhone (not plus) or iPad in split screen model w/ compact width.
        if globals.isLoading, navigationController?.visibleViewController == self, let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
    }
    
    fileprivate func captureVerticalSplit()
    {
        guard view.bounds.height > 0 else {
            return
        }
        
        guard view.subviews.contains(verticalSplit) else {
            return
        }
        
        guard mediaItemNotesAndSlidesConstraint.isActive else {
            return
        }
        
        guard selectedMediaItem != nil else {
            return
        }
        
        //        print("captureVerticalSplit: \(mediaItemSelected?.title)")
        
        //                print("\(self.view.bounds.height)")
        let ratio = self.mediaItemNotesAndSlidesConstraint.constant / self.view.bounds.height
        
        //            print("captureVerticalSplit ratio: \(ratio)")
        
        selectedMediaItem?.verticalSplit = "\(ratio)"
    }
    
    fileprivate func captureHorizontalSplit()
    {
        //        print("captureVerticalSplit: \(mediaItemSelected?.title)")
        
        guard self.view != nil else {
            return
        }
        
        guard controlViewTop.isActive else { // Technially not needed, but if this isn't active the tableViewWidth constraint shouldn't be either.
            return
        }

        guard tableViewWidth.isActive else {
            return
        }
        
        if (selectedMediaItem != nil) {
            //                print("\(self.view.bounds.height)")
            let ratio = self.tableViewWidth.constant / self.view.bounds.width
            
            //            print("captureVerticalSplit ratio: \(ratio)")
            
            selectedMediaItem?.horizontalSplit = "\(ratio)"
        }
    }
    
    fileprivate func captureContentOffset(_ document:Document)
    {
        guard let wkWebView = document.wkWebView else {
            return
        }
        
        guard let purpose = document.purpose else {
            return
        }
        
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X_RATIO] = "\(wkWebView.scrollView.contentOffset.x / wkWebView.scrollView.contentSize.width)"
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y_RATIO] = "\(wkWebView.scrollView.contentOffset.y / wkWebView.scrollView.contentSize.height)"
    }
    
    fileprivate func captureContentOffset(_ webView:WKWebView?)
    {
        guard let webView = webView else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (!webView.isLoading) && (webView.url != nil) {
            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    if webView == document.wkWebView {
                        captureContentOffset(document)
                    }
                }
            }
        }
    }
    
    fileprivate func captureZoomScale(_ document:Document)
    {
        guard let purpose = document.purpose else {
            return
        }
        
        guard let wkWebView = document.wkWebView else {
            return
        }
        
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.ZOOM_SCALE] = "\(wkWebView.scrollView.zoomScale)"
    }
    
    fileprivate func captureZoomScale(_ webView:WKWebView?)
    {
        //        print("captureZoomScale: \(mediaItemSelected?.title)")
        
        guard let webView = webView else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (!webView.isLoading) && (webView.url != nil) {
            if let documents = documents[selectedMediaItem.id]?.values {
                for document in documents {
                    if webView == document.wkWebView {
                        captureZoomScale(document)
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
        
        if videoLocation == .withTableView {
            selectedMediaItem?.showing = Showing.video
        }
        
        // Remove these lines and this view will crash the app.
        for key in documents.keys {
            if let documents = documents[key]?.values {
                for document in documents {
                    document.wkWebView?.removeFromSuperview()
                    document.wkWebView?.scrollView.delegate = nil
                    
                    document.loadTimer?.invalidate()
                    
                    if let wkWebView = document.wkWebView {
                        if document.showing(selectedMediaItem) && wkWebView.scrollView.isDecelerating {
                            captureContentOffset(document)
                        }
                    }
                }
            }
        }

        removeSliderObserver()
        removePlayerObserver()
        
        NotificationCenter.default.removeObserver(self) // Catch-all.
        
        sliderObserver?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning: \(String(describing: selectedMediaItem?.title))")
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }

        if let wvc = destination as? WebViewController, let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_FULL_SCREEN:
//                splitViewController?.preferredDisplayMode = .primaryHidden
                setupWKContentOffsets()
                wvc.selectedMediaItem = sender as? MediaItem
                break
            default:
                break
            }
        }
    }

    fileprivate func setTimes(timeNow:Double, length:Double)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setTimes", completion: nil)
            return
        }
        
//        print("timeNow:",timeNow,"length:",length)
        
        let elapsedHours = max(Int(timeNow / (60*60)),0)
        let elapsedMins = max(Int((timeNow - (Double(elapsedHours) * 60*60)) / 60),0)
        let elapsedSec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
        
        var elapsed:String
        
        if (elapsedHours > 0) {
            elapsed = "\(String(format: "%d",elapsedHours)):"
        } else {
            elapsed = Constants.EMPTY_STRING
        }
        
        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = elapsed
        
        let timeRemaining = max(length - timeNow,0)
        let remainingHours = max(Int(timeRemaining / (60*60)),0)
        let remainingMins = max(Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60),0)
        let remainingSec = max(Int(timeRemaining.truncatingRemainder(dividingBy: 60)),0)
        
        var remaining:String

        if (remainingHours > 0) {
            remaining = "\(String(format: "%d",remainingHours)):"
        } else {
            remaining = Constants.EMPTY_STRING
        }
        
        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = remaining
    }
    
    
    fileprivate func setSliderAndTimesToAudio()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setSliderAndTimesToAudio", completion: nil)
            return
        }
        
        guard let state = globals.mediaPlayer.state else {
            return
        }
        
        guard let length = globals.mediaPlayer.duration?.seconds else {
            return
        }
        
        guard length > 0 else {
            return
        }
        
        guard let playerCurrentTime = globals.mediaPlayer.currentTime?.seconds, playerCurrentTime >= 0, playerCurrentTime <= length else {
            return
        }

        guard let mediaItemCurrentTime = globals.mediaPlayer.mediaItem?.currentTime, let playingCurrentTime = Double(mediaItemCurrentTime), playingCurrentTime >= 0, Int(playingCurrentTime) <= Int(length) else {
            return
        }

//            print(length)
        
        //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
        
        var progress:Double = -1.0

//            print("currentTime",selectedMediaItem?.currentTime)
//            print("timeNow",timeNow)
//            print("length",length)
//            print("progress",progress)
        
        switch state {
        case .playing:
            progress = playerCurrentTime / length
            
            if !controlView.sliding {
                if globals.mediaPlayer.loaded {
                    //                            print("playing")
                    //                            print("slider.value",slider.value)
                    //                            print("progress",progress)
                    //                            print("length",length)
                    
                    if playerCurrentTime == 0 {
                        progress = playingCurrentTime / length
                        slider.value = Float(progress)
                        setTimes(timeNow: playingCurrentTime,length: length)
                    } else {
                        slider.value = Float(progress)
                        setTimes(timeNow: playerCurrentTime,length: length)
                    }
                } else {
                    print("not loaded")
                }
            } else {
                print("still sliding 1")
            }
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .paused:
            progress = playingCurrentTime / length
            
            //                        print("paused")
            //                        print("timeNow",timeNow)
            //                        print("progress",progress)
            //                        print("length",length)
            
            if !controlView.sliding {
                slider.value = Float(progress)
            } else {
                print("still sliding 2")
            }
            
            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .stopped:
            progress = playingCurrentTime / length
            
            //                        print("stopped")
            //                        print("timeNow",timeNow)
            //                        print("progress",progress)
            //                        print("length",length)
            
            if !controlView.sliding {
                slider.value = Float(progress)
            } else {
                print("still sliding 3")
            }
            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        default:
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
            slider.isEnabled = false
            break
        }
    }
    
    fileprivate func setTimesToSlider()
    {
        assert(globals.mediaPlayer.player != nil,"globals.mediaPlayer.player should not be nil if we're updating the times to the slider, i.e. the slider is showing")
        
        guard (globals.mediaPlayer.player != nil) else {
            return
        }

        guard let length = globals.mediaPlayer.duration?.seconds else {
            return
        }
        
        let timeNow = Double(slider.value) * length
        
        setTimes(timeNow: timeNow,length: length)
    }
    
    fileprivate func setupSliderAndTimes()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupSliderAndTimes", completion: nil)
            return
        }
        
        guard controlView != nil else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
            return
        }
        
        if (globals.mediaPlayer.state != .stopped) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
            if !globals.mediaPlayer.loadFailed {
                setSliderAndTimesToAudio()
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                slider.isHidden = true
            }
        } else {
            if (player?.currentItem?.status == .readyToPlay) {
                if  let length = player?.currentItem?.duration.seconds,
                    let currentTime = selectedMediaItem?.currentTime,
                    let timeNow = Double(currentTime) {
                    let progress = timeNow / length
                    
                    //                        print("timeNow",timeNow)
                    //                        print("progress",progress)
                    //                        print("length",length)
                    
                    if !controlView.sliding {
                        slider.value = Float(progress)
                    } else {
                        print("still sliding 4")
                    }
                    setTimes(timeNow: timeNow,length: length)
                    
                    elapsed.isHidden = false
                    remaining.isHidden = false
                    slider.isHidden = false
                    slider.isEnabled = false
                } else {
                    elapsed.isHidden = true
                    remaining.isHidden = true
                    slider.isHidden = true
                }
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                slider.isHidden = true
            }
        }
    }
    
    func sliderTimer()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:sliderTimer", completion: nil)
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
    
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            return
        }
        
        guard (globals.mediaPlayer.state != nil) else {
            return
        }
        
        slider.isEnabled = globals.mediaPlayer.loaded
        setupPlayPauseButton()
        setupSpinner()
        
        func showState(_ state:String)
        {
//            print(state)
        }
        
        switch globals.mediaPlayer.state! {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            
            setupSpinner()
            
            if globals.mediaPlayer.loaded {
                setSliderAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .paused:
            showState("paused")
            
            setupSpinner()
            
            if globals.mediaPlayer.loaded {
//                print("foo")
                setSliderAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            //            setupSpinner()  // Already done above.
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            //            setupSpinner()  // Already done above.
            break
        }
        
//            if (globals.mediaPlayer.player != nil) {
//                switch globals.mediaPlayer.player!.playbackState {
//                case .Interrupted:
//                    print("sliderTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    print("sliderTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    print("sliderTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    print("sliderTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    print("sliderTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    print("sliderTimer.Stopped")
//                    break
//                }
//            }
    }
    
//    var counter = 0
    
    func removeSliderObserver()
    {
//        if sliderObserver != nil {
////            counter -= 1
////            print("remove counter: ",counter)
//            sliderObserver?.invalidate()
//            sliderObserver = nil
//        }

        sliderObserver?.invalidate()
        sliderObserver = nil

        if let sliderTimerReturn = globals.mediaPlayer.sliderTimerReturn {
            globals.mediaPlayer.player?.removeTimeObserver(sliderTimerReturn)
            globals.mediaPlayer.sliderTimerReturn = nil
        }
    }
    
    func addSliderObserver()
    {
        guard Thread.isMainThread else {
            return
        }
        
        removeSliderObserver()
        
//        self.counter += 1
//        print("add counter: ",self.counter)
        
        self.sliderObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.SLIDER, target: self, selector: #selector(MediaViewController.sliderTimer), userInfo: nil, repeats: true)

//        globals.mediaPlayer.sliderTimerReturn = globals.mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
//            self?.sliderTimer()
//        })
    }

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        assert(globals.mediaPlayer.mediaItem == mediaItem)
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        var seekToTime:CMTime?

        if mediaItem.hasCurrentTime, let currentTime = mediaItem.currentTime, let time = Double(currentTime) {
            if mediaItem.atEnd {
                print("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                mediaItem.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(time,Constants.CMTime_Resolution)
            }
        } else {
            print("playPause selectedMediaItem has NO currentTime!")
            mediaItem.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }
        
        if let seekToTime = seekToTime {
            let loadedTimeRanges = (globals.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })

            let seekableTimeRanges = (globals.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })

            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                globals.mediaPlayer.seek(to: seekToTime.seconds)

                globals.mediaPlayer.play()
                
                setupPlayPauseButton()
            } else {
                playNewMediaItem(mediaItem)
            }
        }
    }

    fileprivate func playNewMediaItem(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem else {
            return
        }
        
        globals.mediaPlayer.stop() // IfPlaying
        
        globals.mediaPlayer.view?.removeFromSuperview()
        
        guard (mediaItem.hasVideo || mediaItem.hasAudio) else {
            return
        }
        
        if globals.reachability.currentReachabilityStatus == .notReachable {
            var doNotPlay = true
            
            if (mediaItem.playing == Playing.audio) {
                if let audioDownload = mediaItem.audioDownload, audioDownload.isDownloaded {
                    doNotPlay = false
                }
            }
            
            if doNotPlay {
                alert(viewController: self, title: "Media Not Available",
                      message: "Please check your network connection and try again.",
                      completion: nil)
                return
            }
        }
        
        globals.mediaPlayer.mediaItem = mediaItem
        
        globals.mediaPlayer.unload()
        
        setupSpinner()
        
        removeSliderObserver()
        
        //This guarantees a fresh start.
        globals.mediaPlayer.setup(mediaItem, playOnLoad: true)
        
        if (mediaItem.hasVideo && (mediaItem.playing == Playing.video)) {
            setupPlayerView(globals.mediaPlayer.view)
        }
        
        addSliderObserver()
        
        setupSliderAndTimes()
        setupPlayPauseButton()
        setupActionAndTagsButtons()

        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }
    
    func setupSpinner()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupSpinner", completion: nil)
            return
        }
        
        guard (selectedMediaItem != nil) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !globals.mediaPlayer.loaded && !globals.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if globals.mediaPlayer.isPlaying {
                if !controlView.sliding,
                    let seconds = globals.mediaPlayer.currentTime?.seconds,
                    let currentTime = globals.mediaPlayer.mediaItem?.currentTime,
                    let time = Double(currentTime),
                    (seconds > time) {
                    if spinner.isAnimating {
                        spinner.isHidden = true
                        spinner.stopAnimating()
                    }
                } else {
                    if !spinner.isAnimating {
                        spinner.isHidden = false
                        spinner.startAnimating()
                    }
                }
            } else {
                if spinner.isAnimating {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                }
            }
        }
    }

    func wkSetZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")

        Thread.onMainThread() {
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        }

//        print("contentOffset after: \(wkWebView.scrollView.contentOffset)")
    }
    
    func setDocumentContentOffsetAndZoomScale(_ document:Document?)
    {
//        print("setNotesContentOffsetAndZoomScale Loading: \(mediaItemNotesWebView!.loading)")

        guard let purpose = document?.purpose else {
            return
        }
        
        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X_RATIO] {
//            print("X ratio string: \(ratio)")
            contentOffsetXRatio = Float(ratioStr)!
        } else {
//            print("No notes X ratio")
        }
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y_RATIO] {
//            print("Y ratio string: \(ratio)")
            contentOffsetYRatio = Float(ratioStr)!
        } else {
//            print("No notes Y ratio")
        }
        
        if  let zoomScaleStr = selectedMediaItem?.mediaItemSettings?[purpose + Constants.ZOOM_SCALE],
            let num = Float(zoomScaleStr) {
            zoomScale = CGFloat(num)
        } else {
//            print("No notes zoomScale")
        }
        
//        print("\(notesContentOffsetXRatio)")
//        print("\(mediaItemNotesWebView!.scrollView.contentSize.width)")
//        print("\(notesZoomScale)")
        
        if let wkWebView = document?.wkWebView {
            let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio) * wkWebView.scrollView.contentSize.width * zoomScale,
                                        y: CGFloat(contentOffsetYRatio) * wkWebView.scrollView.contentSize.height * zoomScale)
            
            wkSetZoomScaleThenContentOffset(wkWebView, scale: zoomScale, offset: contentOffset)
        }
    }
}

extension MediaViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let mediaItems = mediaItems else {
            return 0
        }

        return mediaItems.count
    }
    
    /*
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        cell.vc = self
        
        cell.mediaItem = mediaItems?[indexPath.row]
        
        return cell
    }
    
    func cancel()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return editActions(cell: nil,mediaItem:mediaItems?[indexPath.row]) != nil
    }

    func editActions(cell: MediaTableViewCell?,mediaItem:MediaItem?) -> [AlertAction]?
    {
        // Causes recursive call to cellForRowAt
//        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
//            return nil
//        }
        
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        var actions = [AlertAction]()
        
        var download:AlertAction!
        var transcript:AlertAction!
        var scripture:AlertAction!
        var voiceBase:AlertAction!
//        var recognizeAudio:AlertAction!
//        var recognizeVideo:AlertAction!
//        var audioKeywords:AlertAction!
//        var videoKeywords:AlertAction!
        var topics:AlertAction!
        
        var title = ""
        var style = UIAlertActionStyle.default

        if mediaItem.hasAudio, let audioDownload = mediaItem.audioDownload {
            switch audioDownload.state {
            case .none:
                title = Constants.Strings.Download_Audio
                break
                
            case .downloading:
                title = Constants.Strings.Cancel_Audio_Download
                break
            case .downloaded:
                title = Constants.Strings.Delete_Audio_Download
                style = UIAlertActionStyle.destructive
                break
            }
        }
        
        download = AlertAction(title: title, style: style, action: {
            switch title {
            case Constants.Strings.Download_Audio:
                mediaItem.audioDownload?.download()
                Thread.onMainThread(block: {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: mediaItem.audioDownload)
                })
                break
                
            case Constants.Strings.Delete_Audio_Download:
                let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                message: nil,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                    (action : UIAlertAction!) -> Void in
                    mediaItem.audioDownload?.delete()
                })
                alert.addAction(yesAction)
                
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(noAction)
                
                let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(cancel)
                
                // For .actionSheet style
                //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
                
                self.present(alert, animated: true, completion: nil)
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                if let state = mediaItem.audioDownload?.state {
                    switch state {
                    case .downloading:
                        mediaItem.audioDownload?.cancel()
                        break
                        
                    case .downloaded:
                        let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                            (action : UIAlertAction!) -> Void in
                            mediaItem.audioDownload?.delete()
                        })
                        alert.addAction(yesAction)
                        
                        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(noAction)
                        
                        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(cancel)
                        
                        // For .actionSheet style
                        //        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
                        
                        self.present(alert, animated: true, completion: nil)
                        break
                        
                    default:
                        break
                    }
                }
                break
                
            default:
                break
            }
        })
        
        transcript = AlertAction(title: Constants.Strings.Transcript, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0] //.subviews[actions.index(of: transcript)!] // memory leak!
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                htmlString = mediaItem.fullNotesHTML
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                guard globals.reachability.isReachable else { // currentReachabilityStatus != .notReachable
                    networkUnavailable(self,"HTML transcript unavailable.")
                    return
                }
                
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()

                    return mediaItem.fullNotesHTML
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable(self,"HTML Transcript Unavailable.")
                    }
                })
            }
        }
//        transcript.backgroundColor = UIColor.purple//controlBlue()
        
        scripture = AlertAction(title: Constants.Strings.Scripture, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0] //.subviews[actions.index(of: scripture)!] // memory leak!
            
            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    guard globals.reachability.isReachable else { // currentReachabilityStatus != .notReachable
                        networkUnavailable(self,"Scripture text unavailable.")
                        return
                    }
                    
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load() // mediaItem.scripture?.reference
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable(self,"Scripture text unavailable.")
                        }
                    })
                }
            }
        }
//        scripture.backgroundColor = UIColor.orange
        
        voiceBase = AlertAction(title: "VoiceBase", style: .default) {
            var alertActions = [AlertAction]()
            
            if let actions = mediaItem.audioTranscript?.recognizeAlertActions(viewController:self,tableView:self.tableView) {
                alertActions.append(actions)
            }
            if let actions = mediaItem.videoTranscript?.recognizeAlertActions(viewController:self,tableView:self.tableView) {
                alertActions.append(actions)
            }
            
            // At most, only ONE of the following TWO will be added.
            if let actions = mediaItem.audioTranscript?.keywordAlertActions(viewController:self,tableView:self.tableView, completion: { (popover:PopoverTableViewController)->(Void) in
                self.popover = popover
            }) {
                if (mediaItem == globals.mediaPlayer.mediaItem) && (mediaItem.playing == Playing.audio) && (mediaItem == self.selectedMediaItem)  {
                    if mediaItem.audioTranscript?.keywords != nil {
                        alertActions.append(actions)
                    }
                }
            }
            if let actions = mediaItem.videoTranscript?.keywordAlertActions(viewController:self,tableView:self.tableView, completion: { (popover:PopoverTableViewController)->(Void) in
                self.popover = popover
            }) {
                if (mediaItem == globals.mediaPlayer.mediaItem) && (mediaItem.playing == Playing.video) && (mediaItem == self.selectedMediaItem)  {
                    if mediaItem.videoTranscript?.keywords != nil {
                        alertActions.append(actions)
                    }
                }
            }
            
            alertActionsCancel( viewController: self,
                                title: "VoiceBase",
                                message: "Machine Generated Transcript",
                                alertActions: alertActions,
                                cancelAction: nil)
        }
        
//        recognizeAudio = mediaItem.audioTranscript?.recognizeRowActions(viewController: self, tableView: tableView) // recognizeTVTRA(transcript: mediaItem.audioTranscript)
//        recognizeVideo = mediaItem.videoTranscript?.recognizeRowActions(viewController: self, tableView: tableView) // recognizeTVTRA(transcript: mediaItem.videoTranscript)
        
//        audioKeywords = mediaItem.audioTranscript?.keywordRowActions(viewController: self, tableView: tableView, completion: { (popover:PopoverTableViewController)->(Void) in
//            self.popover = popover
//        }) // keywordsTVTRA(transcript: mediaItem.audioTranscript)
////        audioKeywords.backgroundColor = UIColor.brown
//        
//        videoKeywords = mediaItem.videoTranscript?.keywordRowActions(viewController: self, tableView: tableView, completion: { (popover:PopoverTableViewController)->(Void) in
//            self.popover = popover
//        }) // keywordsTVTRA(transcript: mediaItem.videoTranscript)
////        videoKeywords.backgroundColor = UIColor.brown
        
        topics = AlertAction(title: "List", style: .default) {
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
//                if let cell = cell {
//                    navigationController.popoverPresentationController?.sourceView = cell.subviews[0]
//                    navigationController.popoverPresentationController?.sourceRect = cell.subviews[0].frame // .subviews[actions.index(of: topics)!].frame // memory leak!
//                }
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = "Topics"
                
                popover.selectedMediaItem = mediaItem
                
                popover.search = true
                
                popover.delegate = self
                popover.purpose = .selectingTopic
                popover.section.strings = mediaItem.audioTranscript?.topics?.sorted()
                
//                let cancelButton = UIBarButtonItem(title: Constants.Strings.Cancel, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.cancel))
//                popover.navigationItem.leftBarButtonItem = cancelButton
                
                self.present(navigationController, animated: true, completion: {
                    self.popover = popover
                })
            }
        }
//        topics.backgroundColor = UIColor.cyan
        
        if mediaItem.books != nil {
            actions.append(scripture)
        }

        if mediaItem.hasNotesHTML {
            actions.append(transcript)
        }
        
        if mediaItem.hasAudio {
            actions.append(download)
        }
        
        if globals.allowMGTs {
            actions.append(voiceBase)
        }
        
//        if mediaItem.audioTranscript?.transcript != nil {
////            recognizeAudio.backgroundColor = UIColor.lightGray
//            actions.append(recognizeAudio)
//        } else {
//            if let transcribing = mediaItem.audioTranscript?.transcribing, transcribing {
////                recognizeAudio.backgroundColor = UIColor.gray
//                actions.append(recognizeAudio)
//            } else {
//                if mediaItem.hasAudio && globals.allowMGTs {
////                    recognizeAudio.backgroundColor = UIColor.darkGray
//                    actions.append(recognizeAudio)
//                }
//            }
//        }
//        
//        if mediaItem.hasAudio && globals.allowMGTs {
//            if (mediaItem == globals.mediaPlayer.mediaItem) && (mediaItem.playing == Playing.audio) && (mediaItem == selectedMediaItem) {
//                if mediaItem.audioTranscript?.keywords != nil {
//                    actions.append(audioKeywords)
//                }
//            }
//        }
//        
//        if mediaItem.videoTranscript?.transcript != nil {
////            recognizeVideo.backgroundColor = UIColor.lightGray
//            actions.append(recognizeVideo)
//        } else {
//            if let transcribing = mediaItem.videoTranscript?.transcribing, transcribing {
////                recognizeVideo.backgroundColor = UIColor.gray
//                actions.append(recognizeVideo)
//            } else {
//                if mediaItem.hasVideo && globals.allowMGTs {
////                    recognizeVideo.backgroundColor = UIColor.darkGray
//                    actions.append(recognizeVideo)
//                }
//            }
//        }
//        
//        if mediaItem.hasVideo && globals.allowMGTs {
//            if (mediaItem == globals.mediaPlayer.mediaItem) && (mediaItem.playing == Playing.video) && (mediaItem == selectedMediaItem)  {
//                if mediaItem.videoTranscript?.keywords != nil {
//                    actions.append(videoKeywords)
//                }
//            }
//        }
        
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
//            return editActions(cell: cell, mediaItem: cell.mediaItem)
            
            let action = UITableViewRowAction(style: .normal, title: "Actions") { rowAction, indexPath in
                let alert = UIAlertController(  title: "Actions",
                                                message: message,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                if let alertActions = self.editActions(cell: cell, mediaItem: cell.mediaItem) {
                    for alertAction in alertActions {
                        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                            alertAction.action?()
                        })
                        alert.addAction(action)
                    }
                }
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction) -> Void in
                })
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            action.backgroundColor = UIColor.controlBlue()
            
            return [action]
        }
        
        return nil
    }

    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
}

extension MediaViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let selectedMediaItem = selectedMediaItem, let documents = documents[selectedMediaItem.id]?.values {
            for document in documents {
                if document.showing(selectedMediaItem), document.loaded, let wkWebView = document.wkWebView, wkWebView.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }
        
        if (selectedMediaItem != mediaItems?[indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(mediaItems?[indexPath.row])
        }
        selectedMediaItem = mediaItems?[indexPath.row]
        
        setupSpinner()
        setupPlayPauseButton()
        setupSliderAndTimes()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        //        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
        //
        //        }
    }
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return NO if you do not want the item to be re-orderable.
     return true
     }
     */
}
