//
//  MediaViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import PDFKit
import AVFoundation
import AVKit
import MessageUI
import WebKit
import MediaPlayer
import MobileCoreServices

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

extension MediaViewController : UIActivityItemSource
{
    func share()
    {
        DispatchQueue.global(qos: .userInteractive).async {
            var activityViewController : UIActivityViewController!

            if self.document != nil {

            } else {

            }

            activityViewController = UIActivityViewController(activityItems: [self.document?.data,self.selectedMediaItem?.text,self], applicationActivities: nil)

            // Exclude AirDrop, as it appears to delay the initial appearance of the activity sheet
            activityViewController.excludedActivityTypes = [] // .addToReadingList,.airDrop
            
            Thread.onMainThread {
                let popoverPresentationController = activityViewController.popoverPresentationController
                
                popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivityType] = [.message,.mail,.print,.openInIBooks]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any?
    {
//        guard let activityType = activityType else {
//            return nil
//        }
        
        if #available(iOS 11.0, *) {
            MediaViewController.cases.append(.markupAsPDF)
        }
        
        return selectedMediaItem?.text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        return selectedMediaItem?.text ?? (self.navigationItem.title ?? "")
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String
    {
//        guard let activityType = activityType else {
//            return "public.plain-text"
//        }
        
        return "public.plain-text"
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
//        case Constants.Strings.Print_Slides:
//            fallthrough
//        case Constants.Strings.Print_Transcript:
//            printDocument(viewController: self, documentURL: selectedMediaItem?.downloadURL)
//            break
            
        case Constants.Strings.Share_Slides:
            fallthrough
        case Constants.Strings.Share + " " + (selectedMediaItem?.notesName ?? "") :
            share()
            break

        case Constants.Strings.Add_All_to_Favorites:
            guard let mediaItems = mediaItems else {
                break
            }
            
            // This blocks this thread until it finishes.
            Globals.shared.queue.sync {
                for mediaItem in mediaItems {
                    mediaItem.addTag(Constants.Strings.Favorites)
                }
            }
            break
            
        case Constants.Strings.Remove_All_From_Favorites:
            guard let mediaItems = mediaItems else {
                break
            }
            
            // This blocks this thread until it finishes.
            Globals.shared.queue.sync {
                for mediaItem in mediaItems {
                    mediaItem.removeTag(Constants.Strings.Favorites)
                }
            }
            break
            
        case Constants.Strings.Scripture_Viewer:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: "Scripture View") as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? ScriptureViewController  {
                
                popover.scripture = self.scripture
                
                // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: self)

                if navigationController.modalPresentationStyle == .popover {
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .any
                    navigationController.popoverPresentationController?.delegate = self
                }
                
                popover.navigationController?.isNavigationBarHidden = false
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Download_All_Audio:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
                mediaItem.audioDownload?.download()
            }
            break
            
        case Constants.Strings.Cancel_All_Audio_Downloads:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
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
                        
                        let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
                            (action : UIAlertAction!) -> Void in
                            mediaItem.audioDownload?.delete()
                        })
                        alert.addAction(yesAction)
                        
                        let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(noAction)
                        
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
            
            let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
                (action : UIAlertAction!) -> Void in
                self.selectedMediaItem?.audioDownload?.delete()
            })
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction!) -> Void in
                
            })
            alert.addAction(noAction)
            
//            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
//                (action : UIAlertAction!) -> Void in
//                
//            })
//            alert.addAction(cancel)
            
            self.present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.Delete_All_Audio_Downloads:
            let alert = UIAlertController(  title: "Confirm Deletion of All Audio Downloads",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let yesAction = UIAlertAction(title: Constants.Strings.Yes, style: UIAlertActionStyle.destructive, handler: {
                (action : UIAlertAction) -> Void in
                if let mediaItems = self.mediaItems {
                    for mediaItem in mediaItems {
                        mediaItem.audioDownload?.delete()
                    }
                }
            })
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: Constants.Strings.No, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction) -> Void in
                
            })
            alert.addAction(noAction)
            
            self.present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.Print:
            process(viewController: self, work: { [weak self] in
                return setupMediaItemsHTML(self?.mediaItems, includeURLs:false, includeColumns:true)
            }, completion: { [weak self] (data:Any?) in
                if let vc = self {
                    printHTML(viewController: vc, htmlString: data as? String)
                }
            })
            break
            
        case Constants.Strings.Refresh_Document:
            fallthrough
        case Constants.Strings.Refresh + " " + (selectedMediaItem?.notesName ?? ""):
            fallthrough
        case Constants.Strings.Refresh_Slides:
            // This only refreshes the visible document.
            document?.download?.cancelOrDelete()
            setupDocumentsAndVideo()
            break
            
            
        case Constants.Strings.Transcribe_All_Audio:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
                guard mediaItem.audioTranscript?.transcribing == false else {
                    break
                }
                
                guard mediaItem.audioTranscript?.completed == false else {
                    break
                }
                
                mediaItem.audioTranscript?.getTranscript(alert: true, atEnd: nil)
                mediaItem.audioTranscript?.alert(viewController: self)
            }
            break
            
        case Constants.Strings.Transcribe_All_Video:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
                guard mediaItem.videoTranscript?.transcribing == false else {
                    break
                }
                
                guard mediaItem.videoTranscript?.completed == false else {
                    break
                }
                
                mediaItem.videoTranscript?.getTranscript(alert: true, atEnd: nil)
                mediaItem.videoTranscript?.alert(viewController: self)
            }
            break
            
            
        case Constants.Strings.Align_All_Audio:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
                guard mediaItem.audioTranscript?.transcribing == false else {
                    break
                }
                
                guard mediaItem.audioTranscript?.completed == true else {
                    break
                }
                
                mediaItem.audioTranscript?.selectAlignmentSource(viewController: self)
            }
            break
            
        case Constants.Strings.Align_All_Video:
            guard let mediaItems = mediaItems else {
                break
            }
            
            for mediaItem in mediaItems {
                guard mediaItem.videoTranscript?.transcribing == false else {
                    break
                }
                
                guard mediaItem.videoTranscript?.completed == true else {
                    break
                }
                
                mediaItem.videoTranscript?.selectAlignmentSource(viewController: self)
            }
            break
            

        default:
            break
        }
    }
    
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
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
                }
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
            
        case .selectingTimingIndexWord:
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
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = string
                popover.wholeWordsOnly = true
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = {
                    guard let times = popover.transcript?.transcriptSegmentTokenTimes(token: string), let transcriptSegmentComponents = popover.transcript?.transcriptSegmentComponents else {
                        return nil
                    }
                    
                    var strings = [String]()
                    
                    for time in times {
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            if transcriptSegmentComponent.contains(time+" --> ") { //
                                var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                                
                                if transcriptSegmentArray.count > 2  {
                                    let count = transcriptSegmentArray.removeFirst()
                                    let timeWindow = transcriptSegmentArray.removeFirst()
                                    let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                                    
                                    if  let start = times.first,
                                        let end = times.last,
                                        let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                        let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                        let string = "\(count)\n\(start) to \(end)\n" + text
                                        
                                        strings.append(string)
                                    }
                                }
                                break
                            }
                        }
                    }
                    
                    return strings
                }
                
                popover.editActionsAtIndexPath = popover.transcript?.rowActions

                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTimingIndexPhrase:
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
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = string
                popover.wholeWordsOnly = true
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = {
                    guard let times = popover.transcript?.keywordTimes?[string], let transcriptSegmentComponents = popover.transcript?.transcriptSegmentComponents else { // (token: string)
                        return nil
                    }
                    
                    var strings = [String]()
                    
                    for time in times {
                        var found = false
                        var gap : Double?
                        var closest : String?
                        
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                    let string = "\(count)\n\(start) to \(end)\n" + text
                                    
                                    if (start.hmsToSeconds <= time.hmsToSeconds) && (time.hmsToSeconds <= end.hmsToSeconds) {
                                        strings.append(string)
                                        found = true
                                        gap = nil
                                        break
                                    } else {
                                        guard let time = time.hmsToSeconds else {
                                            continue
                                        }
                                        
                                        guard let start = start.hmsToSeconds else {
                                            continue
                                        }

                                        guard let end = end.hmsToSeconds else { //
                                            continue
                                        }

                                        var currentGap = 0.0
                                        
                                        if time < start {
                                            currentGap = start - time
                                        }
                                        if time > end {
                                            currentGap = time - end
                                        }

                                        if gap != nil {
                                            if currentGap < gap {
                                                gap = currentGap
                                                closest = string
                                            }
                                        } else {
                                            gap = currentGap
                                            closest = string
                                        }
                                    }
                                }
                            }
                        }
                        
                        // We have to deal w/ the case where the keyword time isn't found in a segment which is probably due to a rounding error in the milliseconds, e.g. 1.
                        if !found {
                            if let closest = closest {
                                strings.append(closest)
                            } else {
                                // ??
                            }
                        }
                    }
                    
                    return strings
                }
                
                popover.editActionsAtIndexPath = popover.transcript?.rowActions
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTimingIndexTopic:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript

                popover.delegate = self
                popover.purpose = .selectingTimingIndexTopicKeyword
                
                popover.section.strings = popover.transcript?.topicKeywords(topic: string)
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTimingIndexTopicKeyword:
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
                        return string.secondsToHMS ?? "ERROR"
                    })
                }
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break

        case .selectingTime:
            guard Globals.shared.mediaPlayer.currentTime != nil else {
                break
            }
            
            if let time = string.components(separatedBy: "\n")[1].components(separatedBy: " to ").first, let seconds = time.hmsToSeconds {
                Globals.shared.mediaPlayer.seek(to: seconds)
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
        if (navigationAction.navigationType == .other) {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
        guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
                // if there's no http status code to act on, exit and allow navigation
                decisionHandler(.allow)
                return
        }
        
        if statusCode >= 400 {
            // error has occurred
            Thread.onMainThread {
                webView.isHidden = true
                
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                self.logo.isHidden = false
                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
            
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

            decisionHandler(WKNavigationResponsePolicy.cancel)
        } else {
            decisionHandler(WKNavigationResponsePolicy.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:webView", completion: nil)
            return
        }
        
        guard self.view != nil else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard selectedMediaItem.id != nil else {
            return
        }
        
        loadTimer?.invalidate()
        loadTimer = nil

        // This dispatch and delay is essential to getting the scroll view to accept the offset and zoom.
        DispatchQueue.global(qos: .background).async {
            // Delay has to be longest to deal with cold start delays
            Thread.sleep(forTimeInterval: 0.4)

            self.setDocumentContentOffsetAndZoomScale(self.document)
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!)
    {
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError: Error)
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard selectedMediaItem.id != nil else {
            return
        }
        
        stvControl.isEnabled = true
        
        webView.isHidden = true

        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        progressIndicator.isHidden = true
        
        logo.isHidden = !shouldShowLogo() // && roomForLogo()
        
        if !logo.isHidden {
            mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
        }
        
        networkUnavailable(self,withError.localizedDescription)
        NSLog(withError.localizedDescription)
    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!)
    {
        
    }
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!,withError: Error)
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        guard selectedMediaItem.id != nil else {
            return
        }

        stvControl.isEnabled = true
        
        Thread.onMainThread {
            wkWebView.isHidden = true
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            self.logo.isHidden = false
        }
        
        if let purpose = self.document?.download?.purpose {
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

extension MediaViewController: UIScrollViewDelegate
{
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {
        if document?.setZoom == true {
            document?.setZoom = false
        }
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?)
    {

    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
            captureZoomScale(view)
        } else {
            document?.setZoom = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if document?.setOffset == true {
            document?.setOffset = false
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        if let view = scrollView.superview as? WKWebView, document?.setOffset == false {
            captureContentOffset(view)
        } else {
            document?.setOffset = false
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        } else {
            
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
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
    func stringPicked(_ string: String?, purpose:PopoverPurpose?)
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

class MediaViewController: UIViewController
{
    var popover : PopoverTableViewController?
    
    @IBOutlet weak var controlView: ControlView!
    
    @IBOutlet weak var controlViewTop: NSLayoutConstraint!
    
    var searchText:String?
    
    var videoLocation : VideoLocation = .withDocuments
    
    var scripture:Scripture?
    {
        get {
            return selectedMediaItem?.scripture
        }
    }
//    = {
//        return Scripture(reference: selectedMediaItem?.scripture?.reference)
//    }()

    var observerActive = false
    var observedItem:AVPlayerItem?

    private var PlayerContext = 0
    
    var player:AVPlayer?
    
    var panning = false
    
    var sliderObserver:Timer?

    var documents : ThreadSafeDictionaryOfDictionaries<Document>!
    {
        get {
            return selectedMediaItem?.documents
        }
        set {
            selectedMediaItem?.documents = newValue
        }
    }
    
    var document : Document?
    {
        get {
            if let selectedMediaItem = selectedMediaItem, let showing = selectedMediaItem.showing, let document = documents[selectedMediaItem.id,showing] {
                return document
            }

            return nil
        }
        set {
            if document != nil {
                Thread.onMainThread {
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self.document?.download)
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.document?.download)
                }
            }

            guard let newValue = newValue else {
                return
            }
            
            guard let selectedMediaItem = selectedMediaItem, let showing = selectedMediaItem.showing else {
                return
            }
            
            documents[selectedMediaItem.id,showing] = newValue
        }
    }
    
    lazy var wkWebView:WKWebView? = {
        guard isViewLoaded else {
            return nil
        }
        
        let wkWebView = WKWebView(frame: mediaItemNotesAndSlides.bounds)
        setupWKWebView(wkWebView)
        return wkWebView
    }()
    
    // Each document has its own loadTimer because each has its own WKWebView.
    // This is only used when a direct load is used, not when a document is cached and then loaded.
    var loadTimer:Timer?

    var download:Download?
    {
        get {
            return document?.download
        }
    }
    
    @objc func updateDocument(_ notification:NSNotification)
    {
        guard let download = notification.object as? Download else {
            return
        }
        
        guard document?.download == download else {
            return
        }
        
        switch download.state {
        case .none:
            break
            
        case .downloading:
            if document?.showing(selectedMediaItem) == true {
                progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
            }
            break
            
        case .downloaded:
            Thread.onMainThread {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.download)
            }
            break
        }
    }
    
    @objc func cancelDocument(_ notification:NSNotification)
    {
        Thread.onMainThread {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self.download)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.download)
        }
        
        guard let download = notification.object as? Download else {
            return
        }
        
        guard document?.download == download else {
            return
        }
        
        switch download.state {
        case .none:
            break
            
        case .downloading:
            download.state = .none
            if document?.showing(selectedMediaItem) == true {
                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    self.wkWebView?.isHidden = true

                    Globals.shared.mediaPlayer.view?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    if let purpose = self.document?.purpose {
                        switch purpose {
                        case Purpose.slides:
                            networkUnavailable(self,"Slides unavailable.")
                            break
                            
                        case Purpose.notes:
                            networkUnavailable(self,"Transcript unavailable.")
                            break
                            
                        default:
                            break
                        }
                    }
                }
            }
            break
            
        case .downloaded:
            break
        }
    }
    
    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
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
    
    @objc func downloaded(_ notification:NSNotification)
    {
        guard let download = notification.object as? Download else {
            return
        }

        guard download.mediaItem == selectedMediaItem else {
            return
        }
        
        guard download.purpose == selectedMediaItem?.showing else { // stvControl.selectedSegmentIndex.description
            return
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: download)
        
        guard let fileSystemURL = download.fileSystemURL else {
            return
        }
        
        Thread.onMainThread {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            
            self.mediaItemNotesAndSlides.bringSubview(toFront: self.activityIndicator)
        }
        
        operationQueue.addOperation { [weak self] in
            Thread.onMainThread {
                self?.wkWebView?.isHidden = true
            }
            
            if let data = self?.document?.data {
                if download.mediaItem == self?.selectedMediaItem, download.purpose == self?.selectedMediaItem?.showing { //  self?.stvControl.selectedSegmentIndex.description
                    Thread.onMainThread {
                        self?.wkWebView?.isHidden = true
                        self?.wkWebView?.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: fileSystemURL)
                    }
                }
            }
        }
    }
    
    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "WKWEBVIEW"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    var selectedMediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            guard Thread.isMainThread else {
                return
            }
            
            if isViewLoaded {
                Thread.onMainThread {
                    self.wkWebView?.isHidden = true
                    self.wkWebView?.stopLoading()
                    
                    if let logo = UIImage(named:"CBC_logo") {
                        // Need to adjust aspect ratio contraint
                        let ratio = logo.size.width / logo.size.height
                        
                        self.layoutAspectRatio = self.layoutAspectRatio.setMultiplier(multiplier: ratio)
                        self.logo.image = logo
                    }
                }
            }
            
            operationQueue.cancelAllOperations()

            mediaItems = selectedMediaItem?.multiPartMediaItems
            
            if let selectedMediaItem = selectedMediaItem, selectedMediaItem.id != nil {
                if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
                    removePlayerObserver()
                    
                    if Globals.shared.mediaPlayer.url != selectedMediaItem.playingURL {
                        updateUI()
                    }
                } else {
                    if let url = selectedMediaItem.playingURL {
                        playerURL(url: url)
                    } else {
                        networkUnavailable(self,"Media Not Available")
                    }
                }

                Globals.shared.selectedMediaItem.detail = selectedMediaItem
            } else {
                // We always select, never deselect
                
            }
        }
    }
    
    var mediaItems:[MediaItem]?
    {
        didSet {
            mediaItems?.forEach({ (mediaItem:MediaItem) in
                mediaItem.loadDocuments()
            })
            if mediaItems != oldValue {
                tableView?.reloadData()
            }
        }
    }
    
    @IBOutlet weak var tableViewWidth: NSLayoutConstraint!
    {
        didSet {
            //Eliminates blank cells at end.
            tableView.tableFooterView = UIView()
            tableView.allowsSelection = true
        }
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!

    @IBOutlet weak var verticalSplit: UIView!
    {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(resetConstraint))
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

    @IBAction func audioOrVideoSelection(_ sender: UISegmentedControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:audioOrVideoSelection", completion: nil)
            return
        }
        
        switch audioOrVideoControl.selectedSegmentIndex {
        case Constants.AV_SEGMENT_INDEX.AUDIO:
            if let playing = selectedMediaItem?.playing {
                switch playing {
                case Playing.audio:
                    //Do nothing, already selected
                    break
                    
                case Playing.video:
                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                        Globals.shared.mediaPlayer.stop() // IfPlaying
                        
                        tableView.isEditing = false
                        Globals.shared.mediaPlayer.view?.isHidden = true
                        
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
                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                        Globals.shared.mediaPlayer.stop()
                        
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
    
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var stvControl: UISegmentedControl!
    @IBOutlet weak var stvWidthConstraint: NSLayoutConstraint!
    @IBAction func stvAction(_ sender: UISegmentedControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stvAction", completion: nil)
            return
        }
        
        if let showing = selectedMediaItem?.showing {
            switch showing {
            case Showing.video:
                Globals.shared.mediaPlayer.view?.isHidden = true
                break

            default:
                wkWebView?.isHidden = true
                break

            }
        }

        if (stvControl.selectedSegmentIndex >= 0) && (stvControl.selectedSegmentIndex < stvControl.numberOfSegments) {
            if let title = stvControl.titleForSegment(at: stvControl.selectedSegmentIndex) {
                switch title {
                case Constants.STV_SEGMENT_TITLE.SLIDES:
                    selectedMediaItem?.showing = Showing.slides
                    break
                    
                case Constants.STV_SEGMENT_TITLE.TRANSCRIPT:
                    selectedMediaItem?.showing = Showing.notes
                    break
                    
                case Constants.STV_SEGMENT_TITLE.VIDEO:
                    selectedMediaItem?.showing = Showing.video
                    break
                    
                default:
                    break
                }
            }
        }

        setupDocumentsAndVideo()
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        // Only handle observations for the playerItemContext

//        if keyPath == #keyPath(UINavigationController.isToolbarHidden) {
//            if self.view.window != nil {
//                print("TOOLBAR CHANGED")
//            }
//        }
        
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
        
        if selectedMediaItem.hasVideo && (videoLocation == .withDocuments) {
            if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) && Globals.shared.mediaPlayer.loaded {
                if (selectedMediaItem.playing == Playing.video) {
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
        
        let avSpace:CGFloat = 4.0 * (audioOrVideoControl.numberOfSegments > 1 ? 2 : 0)
        
        let stvSpace:CGFloat = 4.0 * (stvControl.numberOfSegments > 1 ? 2 : 0)
        
        let freeWidth = view.frame.width - minSliderWidth - avSpace - stvSpace - (2 * minTimeWidth) // Time Elapsed and Remaining
        
        var segmentWidth:CGFloat = 0
        var fontSize:CGFloat = 0
        var maxSegmentWidth:CGFloat = 0
        
        maxSegmentWidth = 60

        let numberOfSegments = ((audioOrVideoControl.numberOfSegments > 1) && !audioOrVideoControl.isHidden ? audioOrVideoControl.numberOfSegments : 0) + ((stvControl.numberOfSegments > 1) && !stvControl.isHidden ? stvControl.numberOfSegments : 0)

        if (numberOfSegments > 0) {
            segmentWidth = min(maxSegmentWidth,freeWidth / CGFloat(numberOfSegments))
        }
        
        if audioOrVideoControl.isHidden {
            audioOrVideoWidthConstraint.constant = 0
        } else {
            if audioOrVideoControl.numberOfSegments > 1 {
                audioOrVideoWidthConstraint.constant = CGFloat(audioOrVideoControl.numberOfSegments) * segmentWidth
                
                fontSize = min(audioOrVideoControl.frame.height,segmentWidth) / 1.75
                
                if let font = UIFont(name: Constants.FA.name, size: fontSize) {
                    audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font.rawValue: font])
                }
            }
        }

        if stvControl.isHidden {
            stvWidthConstraint.constant = 0
        } else {
            if stvControl.numberOfSegments > 1 {
                stvWidthConstraint.constant = CGFloat(stvControl.numberOfSegments) * segmentWidth
                
                fontSize = min(stvControl.frame.height,segmentWidth) / 1.75
                
                if let font = UIFont(name: Constants.FA.name, size: fontSize) {
                    stvControl.setTitleTextAttributes([ NSAttributedStringKey.font.rawValue: font])
                }
            }
        }
        
        view.setNeedsLayout()
    }
    
    @IBAction func playPause(_ sender: UIButton)
    {
        guard (selectedMediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) else {
            playNewMediaItem(selectedMediaItem)
            return
        }

        // Without this there can be a play/pause loop that creates a slow mo miasma
        // that is only broken by switching between audio and video
        // or playing a different media item if there is only one media type.
        if let timeElapsed = Globals.shared.mediaPlayer.stateTime?.timeElapsed {
            if timeElapsed < 0.5 { // 1.0
                print("STOP HITTING THE PLAY PAUSE BUTTON SO QUICKLY!")
                return
            }
        }
        
        func showState(_ state:String)
        {
            print(state)
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        switch state {
        case .none:
            break
            
        case .playing:
            showState("playing")
            Globals.shared.mediaPlayer.pause()
            setupPlayPauseButton()
            setupSpinner()
            break
            
        case .paused:
            showState("paused")
            if Globals.shared.mediaPlayer.loaded && (Globals.shared.mediaPlayer.url == selectedMediaItem?.playingURL) {
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
            Globals.shared.mediaPlayer.pause()
            setupPlayPauseButton()
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            Globals.shared.mediaPlayer.pause()
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
        
        minConstraintConstant = tableView.rowHeight * minRows + controlView.frame.height

        let navHeight = navigationController?.navigationBar.frame.height ?? 0
        
        // This assumes the view goes under top bars, incl. opaque.
        maxConstraintConstant = height - navHeight - UIApplication.shared.statusBarFrame.height

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
            result = (wkWebView?.isHidden ?? true) && progressIndicator.isHidden
            break
        
        case Showing.video:
            result = !Globals.shared.mediaPlayer.loaded
            break
            
        default:
            result = true
            break
        }

        return result
    }

    fileprivate func setMediaItemNotesAndSlidesConstraint(_ change:CGFloat)
    {
        let newConstraintConstant = mediaItemNotesAndSlidesConstraint.constant + change
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }

        self.view.setNeedsLayout()
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
        
        guard selectedMediaItem.id != nil else {
            return
        }
        
        switch pan.state {
        case .began:
            panning = true
            break
            
        case .ended:
            captureVerticalSplit()
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
    
    @IBOutlet weak var elapsed: UILabel!
    {
        didSet {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(resetConstraint))
            doubleTap.numberOfTapsRequired = 2
            elapsed.addGestureRecognizer(doubleTap)

            let singleTap = UITapGestureRecognizer(target: self, action: #selector(elapsedTapAction))
            singleTap.numberOfTapsRequired = 1
            elapsed.addGestureRecognizer(singleTap)
            
            singleTap.require(toFail: doubleTap)
        }
    }

    @objc func elapsedTapAction()
    {
        guard Globals.shared.mediaPlayer.loaded, let currentTime = Globals.shared.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        if selectedMediaItem == Globals.shared.mediaPlayer.mediaItem {
            Globals.shared.mediaPlayer.seek(to: currentTime - Constants.SKIP_TIME_INTERVAL)
        }
    }
    
    @IBOutlet weak var remaining: UILabel!
    {
        didSet {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(resetConstraint))
            doubleTap.numberOfTapsRequired = 2
            remaining.addGestureRecognizer(doubleTap)
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(remainingTapAction))
            singleTap.numberOfTapsRequired = 1
            remaining.addGestureRecognizer(singleTap)
            
            singleTap.require(toFail: doubleTap)
        }
    }
    
    @objc func remainingTapAction(_ sender: UITapGestureRecognizer)
    {
        guard Globals.shared.mediaPlayer.loaded, let currentTime = Globals.shared.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        if selectedMediaItem == Globals.shared.mediaPlayer.mediaItem {
            Globals.shared.mediaPlayer.seek(to: currentTime + Constants.SKIP_TIME_INTERVAL)
        }
    }
    
    @IBOutlet weak var mediaItemNotesAndSlidesConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mediaItemNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
            return
        }
        
        if (slider.value < 1.0) {
            let seekToTime = Double(slider.value) * length
            
            Globals.shared.mediaPlayer.seek(to: seekToTime)
            
            Globals.shared.mediaPlayer.mediaItem?.currentTime = seekToTime.description
        } else {
            Globals.shared.mediaPlayer.pause()
            
            Globals.shared.mediaPlayer.seek(to: length)
            
            Globals.shared.mediaPlayer.mediaItem?.currentTime = length.description
        }
        
        if let state = Globals.shared.mediaPlayer.state {
            switch state {
            case .playing:
                controlView.sliding = Globals.shared.reachability.isReachable
                break
                
            default:
                controlView.sliding = false
                break
            }
        }
        
        Globals.shared.mediaPlayer.mediaItem?.atEnd = slider.value == 1.0
        
        Globals.shared.mediaPlayer.startTime = Globals.shared.mediaPlayer.mediaItem?.currentTime
        
        setupSpinner()
        setupPlayPauseButton()
        addSliderObserver()
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider)
    {
        controlView.sliding = true
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider)
    {
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider)
    {
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider)
    {
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
        
        Thread.onMainThread {
            self.present(messageComposeViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func openMediaItemScripture(_ mediaItem:MediaItem?)
    {
        guard let scriptureReference = mediaItem?.scriptureReference else {
            return
        }
        
        let urlString = Constants.SCRIPTURE_URL.PREFIX + scriptureReference + Constants.SCRIPTURE_URL.POSTFIX

        if let urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            open(scheme: urlString) {
                networkUnavailable(self,"Unable to open scripture at: \(urlString)")
            }
        } else {
            
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
        
        actionMenu.append(Constants.Strings.Scripture_Viewer)
        
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
        
        if let purpose = document?.purpose { // UIPrintInteractionController.isPrintingAvailable
            switch purpose {
            case Purpose.notes:
                if let notesName = selectedMediaItem.notesName {
                    actionMenu.append(Constants.Strings.Share + " " + notesName)
                }
                break
                
            case Purpose.slides:
                actionMenu.append(Constants.Strings.Share_Slides)
                break
                
            default:
                break
            }
        }
        
        if document != nil, let purpose = document?.purpose { // Globals.shared.cacheDownloads,
            switch purpose {
            case Purpose.notes:
                if let notesName = selectedMediaItem.notesName {
                    actionMenu.append(Constants.Strings.Refresh + " " + notesName)
                }
                break
                
            case Purpose.slides:
                actionMenu.append(Constants.Strings.Refresh_Slides)
                break
                
            default:
                break
            }
        }
        
        var mediaItemsToDownload = 0
        var mediaItemsDownloading = 0
        var mediaItemsDownloaded = 0
        
        var mediaItemsToTranscribeAudio = 0
        var mediaItemsToTranscribeVideo = 0
        
        var mediaItemsToAlignAudio = 0
        var mediaItemsToAlignVideo = 0
        
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
            
            if mediaItem.hasAudio, mediaItem.audioTranscript?.transcribing == false, mediaItem.audioTranscript?.completed == false {
                mediaItemsToTranscribeAudio += 1
            }
            
            if mediaItem.hasVideo, mediaItem.videoTranscript?.transcribing == false, mediaItem.videoTranscript?.completed == false {
                mediaItemsToTranscribeVideo += 1
            }
            
            if mediaItem.hasAudio, mediaItem.hasNotesText, mediaItem.audioTranscript?.transcribing == false, mediaItem.audioTranscript?.completed == true {
                mediaItemsToAlignAudio += 1
            }
            
            if mediaItem.hasVideo, mediaItem.hasNotesText, mediaItem.videoTranscript?.transcribing == false, mediaItem.videoTranscript?.completed == true {
                mediaItemsToAlignVideo += 1
            }
        }
        
        if let state = selectedMediaItem.audioDownload?.state {
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
        
        if Globals.shared.isVoiceBaseAvailable, mediaItemsToTranscribeAudio > 0 { // , !((mediaItemsToTranscribeAudio == 1) && (mediaItems.count == 1)) {
            actionMenu.append(Constants.Strings.Transcribe_All_Audio)
        }
        
        if Globals.shared.isVoiceBaseAvailable, mediaItemsToTranscribeVideo > 0 { // , !((mediaItemsToTranscribeVideo == 1) && (mediaItems.count == 1)) {
            actionMenu.append(Constants.Strings.Transcribe_All_Video)
        }
        
        if Globals.shared.isVoiceBaseAvailable, mediaItemsToAlignAudio > 0 { // , !((mediaItemsToAlignAudio == 1) && (mediaItems.count == 1)) {
            actionMenu.append(Constants.Strings.Align_All_Audio)
        }
        
        if Globals.shared.isVoiceBaseAvailable, mediaItemsToAlignVideo > 0 { // , !((mediaItemsToAlignVideo == 1) && (mediaItems.count == 1)) {
            actionMenu.append(Constants.Strings.Align_All_Video)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            popover.section.strings = actionMenu()
            
            Thread.onMainThread {
                self.present(navigationController, animated: true, completion: {
                    self.popover = popover
                })
            }
        }
    }
    
    func zoomVideo()
    {
        Globals.shared.mediaPlayer.fullScreen = !Globals.shared.mediaPlayer.fullScreen

        updateUI()
    }
    
    @objc func videoLongPress(_ longPress:UILongPressGestureRecognizer)
    {
        switch longPress.state {
        case .began:
            guard let selectedMediaItem = selectedMediaItem else {
                break
            }
            
            let hasSlides = selectedMediaItem.hasSlides
            let hasNotes = selectedMediaItem.hasNotes
            
            if (hasSlides || hasNotes) && !Globals.shared.mediaPlayer.fullScreen {
                swapVideoLocation()
            }
            break
            
        case .ended:
            break
            
        case .changed:
            break
            
        default:
            break
        }
    }
    
    @objc func videoPinch(_ pinch:UIPinchGestureRecognizer)
    {
        switch pinch.state {
        case .began:
            break
            
        case .ended:
            if Globals.shared.mediaPlayer.fullScreen != (pinch.scale > 1) {
                Globals.shared.mediaPlayer.fullScreen = pinch.scale > 1
                updateUI()
            }
            break
            
        case .changed:
            break
            
        default:
            break
        }
    }
    
    @objc func videoPan(_ pan:UIPanGestureRecognizer)
    {
        guard !Globals.shared.mediaPlayer.fullScreen else {
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
                    setMediaItemNotesAndSlidesConstraint(-translation.y)
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
        
        if Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
            updateUI()
        }
    }
    
    fileprivate func setupPlayerView(_ view:UIView?)
    {
        guard let view = view else {
            return
        }
        
        guard let mediaItemNotesAndSlides = mediaItemNotesAndSlides else {
            return
        }
        
        guard let tableView = tableView else {
            return
        }
        
        var parentView : UIView!

        switch videoLocation {
        case .withDocuments:
            parentView = mediaItemNotesAndSlides
            tableView.isScrollEnabled = true
            break
            
        case .withTableView:
            parentView = tableView
            tableView.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
            tableView.isScrollEnabled = false
            break
        }
        
        var offset:CGFloat = 0
        var topView:UIView!

        if Globals.shared.mediaPlayer.fullScreen {
            parentView = self.view

            offset = min(mediaItemNotesAndSlides.frame.minY,controlView.frame.minY)
            
            if offset == mediaItemNotesAndSlides.frame.minY {
                topView = mediaItemNotesAndSlides
            }
            
            if offset == controlView.frame.minY {
                topView = controlView
            }
            
            if let prefersStatusBarHidden = navigationController?.prefersStatusBarHidden, prefersStatusBarHidden {
                offset -= UIApplication.shared.statusBarFrame.height
            }
        }
        
        view.gestureRecognizers = nil
        let pan = UIPanGestureRecognizer(target: self, action: #selector(videoPan(_:)))
        view.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(videoPinch(_:)))
        view.addGestureRecognizer(pinch)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(videoLongPress(_:)))
        view.addGestureRecognizer(longPress)
        
        view.isHidden = true
        view.removeFromSuperview()
        
        Globals.shared.mediaPlayer.showsPlaybackControls = Globals.shared.mediaPlayer.fullScreen

        view.frame = parentView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let contain = parentView?.subviews.contains(view), !contain {
            parentView.addSubview(view)
        }
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerX)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(width)
        
        if offset == 0 {
            let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            view.superview?.addConstraint(centerY)
            
            let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: offset)
            view.superview?.addConstraint(height)
        } else {
            let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
            view.superview?.addConstraint(bottom)
            
            let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: topView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0)
            view.superview?.addConstraint(top)
        }
        
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
        
        mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
        
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
    
    @objc func readyToPlay()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:readyToPlay", completion: nil)
            return
        }
        
        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
        
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            return
        }

        if Globals.shared.mediaPlayer.playOnLoad {
            if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing != Showing.video) {
                selectedMediaItem?.showing = Showing.video
            }
        }
        
        if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing == Showing.video) {
            Globals.shared.mediaPlayer.view?.isHidden = false
            
            if let view = Globals.shared.mediaPlayer.view {
                mediaItemNotesAndSlides.bringSubview(toFront: view)
            }
        }

        if Globals.shared.mediaPlayer.playOnLoad {
            if let atEnd = Globals.shared.mediaPlayer.mediaItem?.atEnd, atEnd {
                Globals.shared.mediaPlayer.seek(to: 0)
                Globals.shared.mediaPlayer.mediaItem?.atEnd = false
            }
            Globals.shared.mediaPlayer.playOnLoad = false
            
            // Purely for the delay?
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.onMainThread {
                    Globals.shared.mediaPlayer.play()
                }
            }
        }
        
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()

        setupAudioOrVideo()
        setupSTVControl()
        setSegmentWidths()
    }
    
    @objc func paused()
    {
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    @objc func failedToLoad()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                Globals.shared.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    @objc func failedToPlay()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                Globals.shared.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    @objc func showPlaying()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:showPlaying", completion: nil)
            return
        }
        
        guard (Globals.shared.mediaPlayer.mediaItem != nil) else {
            Globals.shared.mediaPlayer.view?.isHidden = true
            videoLocation = .withDocuments
            removeSliderObserver()
            playerURL(url: selectedMediaItem?.playingURL)
            updateUI()
            return
        }
        
        guard   let mediaItem = Globals.shared.mediaPlayer.mediaItem,
                let _ = selectedMediaItem?.multiPartMediaItems?.index(of: mediaItem) else {
            return
        }
        
        selectedMediaItem = Globals.shared.mediaPlayer.mediaItem
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            Thread.onMainThread {
                self?.scrollToMediaItem(self?.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }
        
        updateUI()
    }
    
    @objc func updateView()
    {
        selectedMediaItem = Globals.shared.selectedMediaItem.detail
        
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            Thread.onMainThread {
                self?.scrollToMediaItem(self?.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }
        
        updateUI()
    }
    
    @objc func clearView()
    {
        Thread.onMainThread {
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

    }
    
    @IBOutlet weak var layoutAspectRatio: NSLayoutConstraint!
    
    fileprivate func setupDefaultDocuments()
    {
        guard let selectedMediaItem = selectedMediaItem else {
            return
        }
        
        verticalSplit.isHidden = false
        
        let hasNotes = selectedMediaItem.hasNotes
        let hasSlides = selectedMediaItem.hasSlides
        
        Globals.shared.mediaPlayer.view?.isHidden = true
        
        if (!hasSlides && !hasNotes) {
            wkWebView?.isHidden = true

            mediaItemNotesAndSlides.bringSubview(toFront: logo)
            logo.isHidden = false

            if selectedMediaItem.hasPosterImage {
                DispatchQueue.global(qos: .userInitiated).async {
                    Thread.onMainThread {
                        guard self.selectedMediaItem == selectedMediaItem else {
                            return
                        }
                        
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.activityIndicator)
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                    }
                
                    if let posterImage = selectedMediaItem.poster.image {
                        guard self.selectedMediaItem == selectedMediaItem else {
                            return
                        }
                        
                        Thread.onMainThread {
                            guard self.selectedMediaItem == selectedMediaItem else {
                                return
                            }
                            
                            // Need to adjust aspect ratio contraint
                            let ratio = posterImage.size.width / posterImage.size.height
                            
                            self.layoutAspectRatio = self.layoutAspectRatio.setMultiplier(multiplier: ratio)
                            self.logo.image = posterImage
                        }
                    }

                    Thread.onMainThread {
                        guard self.selectedMediaItem == selectedMediaItem else {
                            return
                        }
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                    }
                }
            }
            
            if Globals.shared.reachability.isReachable {
                selectedMediaItem.showing = Showing.none
            }
        } else
        if (hasSlides && !hasNotes) {
            selectedMediaItem.showing = Showing.slides

            logo.isHidden = wkWebView != nil
        } else
        if (!hasSlides && hasNotes) {
            selectedMediaItem.showing = Showing.notes
            
            logo.isHidden = wkWebView != nil
        } else
        if (hasSlides && hasNotes) {
            selectedMediaItem.showing = selectedMediaItem.wasShowing
            
            logo.isHidden = wkWebView != nil
        }
    }
    
    @objc func loading(_ timer:Timer?)
    {
        // Expected to be on the main thread
        guard let document = (timer?.userInfo as? Document) else {
            return
        }
        
        guard let isLoading = wkWebView?.isLoading else {
            return
        }
        
        if !isLoading {
            loadTimer?.invalidate()
            loadTimer = nil
        }
        
        if document.showing(selectedMediaItem) {
            if isLoading {
                progressIndicator.isHidden = !wkWebView!.isHidden
                activityIndicator.isHidden = !wkWebView!.isHidden

                mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
                mediaItemNotesAndSlides.bringSubview(toFront: progressIndicator)

                if !progressIndicator.isHidden {
                    if let estimatedProgress = wkWebView?.estimatedProgress {
                        print(estimatedProgress)
                        progressIndicator.progress = Float(estimatedProgress)
                    }
                }

                if !activityIndicator.isHidden {
                    activityIndicator.startAnimating()
                }
            } else {
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true

                progressIndicator.isHidden = true
            }
        }
    }
    
    @objc func downloadFailed(_ notification:NSNotification)
    {
        if let download = notification.object as? Download, document?.download == download {
            Thread.onMainThread {
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

        guard Globals.shared.cacheDownloads || Globals.shared.reachability.isReachable else {
            return
        }
        
        wkWebView?.isHidden = true
        
        if #available(iOS 9.0, *) {
            if Globals.shared.cacheDownloads, let download = document.download {
                if download.state != .downloaded {
                    if Globals.shared.reachability.isReachable {
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.progress = download.totalBytesExpectedToWrite != 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
                        self.progressIndicator.isHidden = false

                        Thread.onMainThread {
                            NotificationCenter.default.addObserver(self, selector: #selector(self.updateDocument(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOWNLOAD), object: self.download)
                            NotificationCenter.default.addObserver(self, selector: #selector(self.cancelDocument(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOWNLOAD), object: self.download)
                            
                            NotificationCenter.default.addObserver(self, selector: #selector(self.downloaded(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOADED), object: self.download)
                            NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: self.download)
                        }
                        
                        if download.state != .downloading {
                            download.download()
                        }
                    }
                } else {
                    if let fileSystemURL = download.fileSystemURL {
                        Thread.onMainThread {
                            self.activityIndicator.isHidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.mediaItemNotesAndSlides.bringSubview(toFront: self.activityIndicator)
                        }
                        
                        operationQueue.addOperation { [weak self] in
                            Thread.onMainThread {
                                self?.wkWebView?.isHidden = true
                            }
                            
                            if let data = document.data {
                                if document.mediaItem == self?.selectedMediaItem, document.download?.purpose == self?.selectedMediaItem?.showing { // self?.stvControl.selectedSegmentIndex.description
                                    Thread.onMainThread {
                                        self?.wkWebView?.isHidden = true
                                        self?.wkWebView?.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: fileSystemURL)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if document.showing(self.selectedMediaItem) {
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                }
                
                operationQueue.addOperation { [weak self] in
                    Thread.onMainThread {
                        self?.wkWebView?.isHidden = true
                    }
                    
                    if let data = document.data, let url = document.download?.downloadURL  {
                        if document.mediaItem == self?.selectedMediaItem, document.download?.purpose == self?.selectedMediaItem?.showing { // self?.stvControl.selectedSegmentIndex.description
                            Thread.onMainThread {
                                self?.wkWebView?.isHidden = true
                                self?.wkWebView?.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: url)
                            }
                        }
                    }
                }
            }
        } else {
            if document.showing(self.selectedMediaItem) {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
                
                self.progressIndicator.isHidden = false
            }
            
            if let url = document.download?.downloadURL {
                operationQueue.addOperation { [weak self] in
                    Thread.onMainThread {
                        self?.wkWebView?.isHidden = true
                    }
                    
                    if let data = try? Data(contentsOf: url) {
                        if document.mediaItem == self?.selectedMediaItem, document.download?.purpose == self?.selectedMediaItem?.showing { // self?.stvControl.selectedSegmentIndex.description
                            Thread.onMainThread {
                                self?.wkWebView?.isHidden = true
                                self?.wkWebView?.load(data, mimeType: "application/pdf", characterEncodingName: "", baseURL: url)
                            }
                        }
                    }
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
        
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.id != nil else {
            verticalSplit.isHidden = true
            
            wkWebView?.isHidden = true

            Globals.shared.mediaPlayer.view?.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if !logo.isHidden {
                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
            
            return
        }
        
        activityIndicator.isHidden = true

        progressIndicator.isHidden = true
        progressIndicator.progress = 0.0

        verticalSplit.isHidden = false

        if selectedMediaItem.hasNotes, selectedMediaItem.showing == Showing.notes {
            if document == nil {
                document = Document(purpose: Purpose.notes, mediaItem: selectedMediaItem)
            }
            
            loadDocument(document)
        } else {

        }

        if selectedMediaItem.hasSlides, selectedMediaItem.showing == Showing.slides {
            if document == nil {
                document = Document(purpose: Purpose.slides, mediaItem: selectedMediaItem)
            }
            
            loadDocument(document)
        } else {

        }

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
            if !Globals.shared.reachability.isReachable {
                if !Globals.shared.cacheDownloads || (download?.isDownloaded == false) {
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
            }
            
            switch showing {
            case Showing.notes:
                fallthrough
            case Showing.slides:
                Globals.shared.mediaPlayer.view?.isHidden = videoLocation == .withDocuments
                logo.isHidden = true
    
                if wkWebView != nil {
                    // Don't want to show it just because it is already (down)loaded!
                    // The scale and offset have not yet been set!
                    mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
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
                        if (Globals.shared.mediaPlayer.mediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                            wkWebView?.isHidden = true

                            logo.isHidden = Globals.shared.mediaPlayer.loaded
                            Globals.shared.mediaPlayer.view?.isHidden = !Globals.shared.mediaPlayer.loaded
                            
                            selectedMediaItem.showing = Showing.video
                            
                            if (Globals.shared.mediaPlayer.player != nil) {

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
                
                wkWebView?.isHidden = true

                if let playing = selectedMediaItem.playing {
                    switch playing {
                    case Playing.audio:
                        Globals.shared.mediaPlayer.view?.isHidden = true
                        setupDefaultDocuments()
                        break
                        
                    case Playing.video:
                        if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                            if (selectedMediaItem.hasVideo && (selectedMediaItem.playing == Playing.video)) {
                                if let view = Globals.shared.mediaPlayer.view {
                                    if Globals.shared.mediaPlayer.loaded {
                                        view.isHidden = false
                                    }
                                    
                                    mediaItemNotesAndSlides.bringSubview(toFront: view)
                                    
                                    selectedMediaItem.showing = Showing.video
                                }
                            } else {
                                Globals.shared.mediaPlayer.view?.isHidden = true
                                self.logo.isHidden = false
                                selectedMediaItem.showing = Showing.none
                                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                            }
                        } else {
                            Globals.shared.mediaPlayer.view?.isHidden = true
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
    }
    
    func scrollToMediaItem(_ mediaItem:MediaItem?,select:Bool,position:UITableViewScrollPosition)
    {
        guard let mediaItem = mediaItem else {
            return
        }

        var indexPath = IndexPath(row: 0, section: 0)
        
        if mediaItems?.count > 0, let mediaItemIndex = mediaItems?.index(of: mediaItem) {
            indexPath = IndexPath(row: mediaItemIndex, section: 0)
        }
        
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
    
    @objc func setupPlayPauseButton()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setupPlayPauseButton", completion: nil)
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else {
            playPauseButton.setTitle(Constants.FA.PLAY)
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            return
        }
        
        guard selectedMediaItem.hasAudio || selectedMediaItem.hasVideo else {
            playPauseButton.setTitle(Constants.FA.PLAY)
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = false
            return
        }
        
        func showState(_ state:String)
        {
//            print(state)
        }

        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            playPauseButton.isEnabled = Globals.shared.mediaPlayer.loaded || Globals.shared.mediaPlayer.loadFailed
            
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .playing:
                    showState("Playing -> Pause")
                    
                    playPauseButton.setTitle(Constants.FA.PAUSE)
                    break
                    
                case .paused:
                    showState("Paused -> Play")
                  
                    playPauseButton.setTitle(Constants.FA.PLAY)
                    break
                    
                default:
                    playPauseButton.setTitle(Constants.FA.PLAY)
                    break
                }
            }
        } else {
            showState("Global not selected")
            playPauseButton.isEnabled = true

            playPauseButton.setTitle(Constants.FA.PLAY)
        }

        playPauseButton.isHidden = false
    }
    
    @objc func tags(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:tags", completion: nil)
            return
        }

        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.shared.filters
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
            
            popover.allowsSelection = false
            popover.selectedMediaItem = selectedMediaItem
            
            present(navigationController, animated: true, completion: {
                self.popover = popover
            })
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
            actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(actions))
            actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

            if let actionButton = actionButton {
                barButtons.append(actionButton)
            }
        }
    
        if selectedMediaItem.hasTags {
            if (selectedMediaItem.tagsSet?.count > 1) {
                tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(tags(_:)))
            } else {
                tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(tags(_:)))
            }
            
            tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags)

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

    func setupWKContentOffsets()
    {
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.id != nil else {
            return
        }
        
        guard let document = document else {
            return
        }
    
        if let wkWebView = wkWebView {
            var contentOffsetX:Float = 0.0
            var contentOffsetY:Float = 0.0
            
            if let purpose = document.purpose, let x = selectedMediaItem.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X] {
                if let num = Float(x) {
                    contentOffsetX = num
                }
            }
            
            if let purpose = document.purpose, let y = selectedMediaItem.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y] {
                if let num = Float(y) {
                    contentOffsetY = num
                }
            }
            
            let contentOffset = CGPoint(
                x: CGFloat(contentOffsetX),
                y: CGFloat(contentOffsetY))
            
            Thread.onMainThread {
                wkWebView.scrollView.setContentOffset(contentOffset, animated: false)
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

            self.updateUI()
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }
    
    func ratioForSplitView(_ sender: UIView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if let verticalSplit = selectedMediaItem?.verticalSplit, let num = Float(verticalSplit) {
            ratio = CGFloat(num)
        }

        return ratio
    }
    
    func ratioForSlideView() -> CGFloat?
    {
        var ratio:CGFloat?
        
        if let horizontalSplit = selectedMediaItem?.horizontalSplit, let num = Float(horizontalSplit) {
            ratio = CGFloat(num)
        }

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
        guard let isCollapsed = splitViewController?.isCollapsed, (traitCollection.verticalSizeClass == .compact) && isCollapsed else {
            return
        }
        
        let min:CGFloat = 0.0
        
        // if max is allowed to be self.view.bounds.size.width the app will crash because the tableViewWidth constraint will force the slides to be zero width and somewhere between a value like 60 and zero the crash occurs.  If the video is swapped with the slides by a long press when the video is full width there is no crash, so something about the value goint to zero causes a crash so 60 is an arbitrary deduction to keep the min width of the left to be more than zero while the pan is occuring either in the video on the RHS or the view along the bottom.
        let max:CGFloat = self.view.bounds.size.width - 60.0
        
        if (width >= min) && (width < max) {
            tableViewWidth.constant = width
        }
        if (width < min) {
            tableViewWidth.constant = min
        }
        if (width >= max) {
            tableViewWidth.constant = max
        }
    }
    
    @objc func resetConstraint()
    {
        guard view.subviews.contains(verticalSplit) else {
            return
        }
        
        guard mediaItemNotesAndSlidesConstraint.isActive else {
            return
        }
        
        var newConstraintConstant:CGFloat
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        // This assumes the view goes under top bars, incl. opaque.
        let height = self.view.bounds.height - navigationController!.navigationBar.frame.height - UIApplication.shared.statusBarFrame.height
        
        newConstraintConstant = height / 2 + controlView.bounds.height / 2
        
        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        
        self.view.setNeedsLayout()
        
        captureVerticalSplit()
    }
    
    fileprivate func setupHorizontalSplit()
    {
        guard let isCollapsed = splitViewController?.isCollapsed, (traitCollection.verticalSizeClass == .compact) && isCollapsed else {
            return
        }
        
        guard Thread.isMainThread else {
            return
        }
        
        if let ratio = ratioForSlideView() {
            setTableViewWidth(width: self.view.bounds.width * ratio)
        } else {
            setTableViewWidth(width: self.view.bounds.width / 2)
        }
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupVerticalSplit()
    {
        guard let isCollapsed = splitViewController?.isCollapsed, (traitCollection.verticalSizeClass != .compact) || !isCollapsed else {
            return
        }
        
        guard Thread.isMainThread else {
            return
        }
        
        var newConstraintConstant:CGFloat = 0
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(verticalSplit) {
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
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupTitle()
    {
        guard Thread.isMainThread else {
            return
        }

        self.navigationItem.title = selectedMediaItem?.title

//        if let title = selectedMediaItem?.title, let category = selectedMediaItem?.category {
//            self.navigationItem.title = title + "\n" + category
//        } else {
//            self.navigationItem.title = selectedMediaItem?.title
//        }

//        if Globals.shared.mediaCategory.selected != selectedMediaItem?.category {
//            if let title = selectedMediaItem?.title, let category = selectedMediaItem?.category {
//                self.navigationItem.title = category + ": " + title
//            } else {
//                self.navigationItem.title = selectedMediaItem?.title
//            }
//        } else {
//            self.navigationItem.title = selectedMediaItem?.title
//        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.hasAudio, selectedMediaItem.hasVideo else {
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
    }
    
    @objc func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        if (selectedMediaItem != nil) && (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (Globals.shared.mediaPlayer.url != selectedMediaItem?.playingURL) {
                Globals.shared.mediaPlayer.killPIP = true
                Globals.shared.mediaPlayer.pause()
                Globals.shared.mediaPlayer.setup(selectedMediaItem,playOnLoad:false)
            } else {
                if Globals.shared.mediaPlayer.loadFailed && (logo != nil) {
                    logo.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: logo)
                }
            }
        }
        
        setupPlayerView(Globals.shared.mediaPlayer.view)

        setDVCLeftBarButton()

        setupVerticalSplit()
        setupHorizontalSplit()
        
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
        
        scrollToMediaItem(selectedMediaItem, select: true, position: .none)
    }
    
    @objc func doneSeeking()
    {
        controlView.sliding = false
        print("DONE SEEKING")
    }
    
    var orientation : UIDeviceOrientation?
    
    @objc func deviceOrientationDidChange()
    {
        defer {
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                self.orientation = UIDevice.current.orientation
                break
                
            case .landscapeRight:
                self.orientation = UIDevice.current.orientation
                break
                
            case .portrait:
                self.orientation = UIDevice.current.orientation
                break
                
            case .portraitUpsideDown:
                self.orientation = UIDevice.current.orientation
                break
                
            case .unknown:
                break
            }
        }
        
        guard popover?.popoverPresentationController?.presentationStyle == .popover else {
            return
        }
        
        guard let orientation = orientation else {
            return
        }
        
        switch orientation {
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
    }
    
    @objc func stopEditing()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:stopEditing", completion: nil)
            return
        }
        
        tableView.isEditing = false
    }
    
    @objc func willEnterForeground()
    {
        // Player is refreshed in AppDelegate
        
    }
    
    @objc func didBecomeActive()
    {
        setDVCLeftBarButton()
    }
    
    @objc func reachableTransition()
    {
        // This just triggers the didSet as if we had just selected it all over again.
        // Which sets up the AVPlayer to show length and position for mediaItems that aren't loaded in the media Player.
        if let selectedMediaItem = selectedMediaItem {
            self.selectedMediaItem = selectedMediaItem
        }
        
        updateUI()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(failedToLoad), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        if let isCollapsed = self.splitViewController?.isCollapsed, !isCollapsed {
            NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = true
        
        orientation = UIDevice.current.orientation
        
        addNotifications()

        if let mediaItem = Globals.shared.mediaPlayer.mediaItem, mediaItem == selectedMediaItem, Globals.shared.mediaPlayer.isPaused, mediaItem.hasCurrentTime, let currentTime = mediaItem.currentTime {
            Globals.shared.mediaPlayer.seek(to: Double(currentTime))
        }

        updateUI()

        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            Thread.onMainThread {
                self?.scrollToMediaItem(self?.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (Globals.shared.media.all == nil) {
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
        
        if selectedMediaItem == nil, Globals.shared.selectedMediaItem.detail != nil {
            selectedMediaItem = Globals.shared.selectedMediaItem.detail
            updateUI()
            
            tableView.reloadData()
            
            //Without this background/main dispatching there isn't time to scroll correctly after a reload.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                Thread.onMainThread {
                    self?.scrollToMediaItem(self?.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
                }
            }
        }

        // Seems like a strange way to force MTVC to be the visible view controller.  Not sure this ever happens since it would only be during loading while the splitViewController is collapsed.
        // Which means either on an iPhone (not plus) or iPad in split screen model w/ compact width.
        if Globals.shared.isLoading, navigationController?.visibleViewController == self, let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
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
        
        let ratio = self.mediaItemNotesAndSlidesConstraint.constant / self.view.bounds.height
        
        selectedMediaItem?.verticalSplit = "\(ratio)"
    }
    
    fileprivate func captureHorizontalSplit()
    {
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
            let ratio = self.tableViewWidth.constant / self.view.bounds.width
            
            selectedMediaItem?.horizontalSplit = "\(ratio)"
        }
    }
    
    fileprivate func captureContentOffset(_ document:Document)
    {
        guard let wkWebView = wkWebView else {
            return
        }
        
        guard let purpose = document.purpose else {
            return
        }
        
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X] = "\(wkWebView.scrollView.contentOffset.x)"
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y] = "\(wkWebView.scrollView.contentOffset.y)"
    }
    
    fileprivate func captureContentOffset(_ webView:WKWebView?)
    {
        guard let webView = webView else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.id != nil else {
            return
        }
        
        guard let document = document else {
            return
        }
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (!webView.isLoading) && (webView.url != nil) {
            captureContentOffset(document)
        }
    }
    
    fileprivate func captureZoomScale(_ document:Document)
    {
        guard let purpose = document.purpose else {
            return
        }
        
        guard let wkWebView = wkWebView else {
            return
        }
        
        selectedMediaItem?.mediaItemSettings?[purpose + Constants.ZOOM_SCALE] = "\(wkWebView.scrollView.zoomScale)"
    }
    
    fileprivate func captureZoomScale(_ webView:WKWebView?)
    {
        guard let webView = webView else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.id != nil else {
            return
        }
        
        guard let document = document else {
            return
        }
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (!webView.isLoading) && (webView.url != nil) {
            captureZoomScale(document)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if selectedMediaItem == Globals.shared.mediaPlayer.mediaItem {
            Globals.shared.mediaPlayer.view?.removeFromSuperview()
        }
        
        navigationItem.rightBarButtonItem = nil
        
        if videoLocation == .withTableView {
            selectedMediaItem?.showing = Showing.video
        }

        loadTimer?.invalidate()
        
        if let document = document, let wkWebView = wkWebView {
            if document.showing(selectedMediaItem) && wkWebView.scrollView.isDecelerating {
                captureContentOffset(document)
            }
            self.wkWebView = nil
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

        // Dispose of any resources that can be recreated.
        print("didReceiveMemoryWarning: \(String(describing: selectedMediaItem?.title))")
        Globals.shared.freeMemory()
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
        if let navCon = destination as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            destination = visibleViewController
        }

        if let wvc = destination as? WebViewController, let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_FULL_SCREEN:
                setupWKContentOffsets()
                wvc.mediaItem = sender as? MediaItem
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
        
        guard !timeNow.isNaN else {
            return
        }
        
        guard !length.isNaN else {
            return
        }
        
        self.elapsed.text = timeNow.secondsToHMS
        
        let timeRemaining = max(length - timeNow,0)
        
        self.remaining.text = timeRemaining.secondsToHMS
    }
    
    
    fileprivate func setSliderAndTimesToAudio()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:setSliderAndTimesToAudio", completion: nil)
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
            return
        }
        
        guard length > 0 else {
            return
        }
        
        guard let playerCurrentTime = Globals.shared.mediaPlayer.currentTime?.seconds, playerCurrentTime >= 0, playerCurrentTime <= length else {
            return
        }

        guard let mediaItemCurrentTime = Globals.shared.mediaPlayer.mediaItem?.currentTime, let playingCurrentTime = Double(mediaItemCurrentTime), playingCurrentTime >= 0, Int(playingCurrentTime) <= Int(length) else {
            return
        }
        
        //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
        
        var progress:Double = -1.0

        switch state {
        case .playing:
            progress = playerCurrentTime / length
            
            if !controlView.sliding {
                if Globals.shared.mediaPlayer.loaded {
                    if playerCurrentTime == 0 {
                        progress = playingCurrentTime / length
                        slider.value = Float(progress)
                        setTimes(timeNow: playingCurrentTime,length: length)
                    } else {
                        slider.value = Float(progress)
                        setTimes(timeNow: playerCurrentTime,length: length)
                    }
                }
            }
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .paused:
            progress = playingCurrentTime / length
            
            if !controlView.sliding {
                slider.value = Float(progress)
            }
            
            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            slider.isHidden = false
            slider.isEnabled = true
            break
            
        case .stopped:
            progress = playingCurrentTime / length
            
            if !controlView.sliding {
                slider.value = Float(progress)
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
        assert(Globals.shared.mediaPlayer.player != nil,"Globals.shared.mediaPlayer.player should not be nil if we're updating the times to the slider, i.e. the slider is showing")
        
        guard (Globals.shared.mediaPlayer.player != nil) else {
            return
        }

        guard let length = Globals.shared.mediaPlayer.duration?.seconds else {
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
        
        if (Globals.shared.mediaPlayer.state != .stopped) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
            if !Globals.shared.mediaPlayer.loadFailed {
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
                    
                    if !controlView.sliding {
                        slider.value = Float(progress)
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
    
    @objc func sliderTimer()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaViewController:sliderTimer", completion: nil)
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
    
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }

        slider.isEnabled = Globals.shared.mediaPlayer.loaded
        setupPlayPauseButton()
        setupSpinner()
        
        func showState(_ state:String)
        {
//            print(state)
        }
        
        switch state {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            
            setupSpinner()
            
            if Globals.shared.mediaPlayer.loaded {
                setSliderAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .paused:
            showState("paused")
            
            setupSpinner()
            
            if Globals.shared.mediaPlayer.loaded {
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
            break
        }
    }
    
    func removeSliderObserver()
    {
        sliderObserver?.invalidate()
        sliderObserver = nil

        if let sliderTimerReturn = Globals.shared.mediaPlayer.sliderTimerReturn {
            Globals.shared.mediaPlayer.player?.removeTimeObserver(sliderTimerReturn)
            Globals.shared.mediaPlayer.sliderTimerReturn = nil
        }
    }
    
    func addSliderObserver()
    {
        guard Thread.isMainThread else {
            return
        }
        
        removeSliderObserver()
        
        self.sliderObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.SLIDER, target: self, selector: #selector(sliderTimer), userInfo: nil, repeats: true)
    }

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        assert(Globals.shared.mediaPlayer.mediaItem == mediaItem)
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        var seekToTime:CMTime?

        if mediaItem.hasCurrentTime, let currentTime = mediaItem.currentTime, let time = Double(currentTime) {
            if mediaItem.atEnd {
                mediaItem.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(time,Constants.CMTime_Resolution)
            }
        } else {
            mediaItem.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }
        
        if let seekToTime = seekToTime {
            let loadedTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })

            let seekableTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime)
            })

            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                Globals.shared.mediaPlayer.seek(to: seekToTime.seconds)

                Globals.shared.mediaPlayer.play()
                
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
        
        Globals.shared.mediaPlayer.stop() // IfPlaying
        
        Globals.shared.mediaPlayer.view?.removeFromSuperview()
        
        guard (mediaItem.hasVideo || mediaItem.hasAudio) else {
            return
        }
        
        if !Globals.shared.reachability.isReachable { // currentReachabilityStatus == .notReachable
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
        
        Globals.shared.mediaPlayer.mediaItem = mediaItem
        
        Globals.shared.mediaPlayer.unload()
        
        setupSpinner()
        
        removeSliderObserver()
        
        //This guarantees a fresh start.
        Globals.shared.mediaPlayer.setup(mediaItem, playOnLoad: true)
        
        if (mediaItem.hasVideo && (mediaItem.playing == Playing.video)) {
            setupPlayerView(Globals.shared.mediaPlayer.view)
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
        
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !Globals.shared.mediaPlayer.loaded && !Globals.shared.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if Globals.shared.mediaPlayer.isPlaying {
                if !controlView.sliding,
                    let seconds = Globals.shared.mediaPlayer.currentTime?.seconds,
                    let currentTime = Globals.shared.mediaPlayer.mediaItem?.currentTime,
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

    func wkSetZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint)
    {
        Thread.onMainThread {
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                self.document?.setZoom = true
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                self.document?.setOffset = true
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        }
    }
    
    func setDocumentContentOffsetAndZoomScale(_ document:Document?)
    {
        guard let purpose = document?.purpose else {
            return
        }
        
        var zoomScale:CGFloat? // = 1.0
        
        var contentOffsetX:Float = 0.0
        var contentOffsetY:Float = 0.0
        
        if let str = selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_X] {
            if let num = Float(str) {
                contentOffsetX = num
            }
        } else {
            
        }
        
        if let str = selectedMediaItem?.mediaItemSettings?[purpose + Constants.CONTENT_OFFSET_Y] {
            if let num = Float(str) {
                contentOffsetY = num
            }
        } else {
            
        }
        
        if  let zoomScaleStr = selectedMediaItem?.mediaItemSettings?[purpose + Constants.ZOOM_SCALE] {
            if let num = Float(zoomScaleStr) {
                zoomScale = CGFloat(num)
            }
        } else {
        
        }
        
        if let wkWebView = wkWebView {
            Thread.onMainThread { () -> (Void) in
                guard wkWebView.scrollView.contentSize != CGSize.zero else {
                    return
                }
                
                let contentOffset = CGPoint(x: CGFloat(contentOffsetX), //
                    y: CGFloat(contentOffsetY)) //
                
                
                if #available(iOS 11.0, *) {
                    if zoomScale == nil {
                        if let data = document?.data, let pdf = PDFDocument(data: data), let page = pdf.page(at: 0) {
                            // 0.95 worked on an iPad but 0.75 was required to make the entire width of the PDF fit on an iPhone.
                            // I have no idea why these magic numbers are required.
                            // It should be noted that the inequality depends on the devices as self.mediaItemNotesAndSlides.frame.width
                            // varies by device.
                            if page.bounds(for: .mediaBox).width > self.mediaItemNotesAndSlides.frame.width {
                                zoomScale = (self.mediaItemNotesAndSlides.frame.width * 0.75) / page.bounds(for: .mediaBox).width
                            } else {
                                zoomScale = (page.bounds(for: .mediaBox).width * 0.75) / self.mediaItemNotesAndSlides.frame.width
                            }
                        }
                    }
                }
                
                self.wkSetZoomScaleThenContentOffset(wkWebView, scale: zoomScale ?? 1.0, offset: contentOffset)
                
                self.progressIndicator.isHidden = true

                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                wkWebView.isHidden = false
            }
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as? MediaTableViewCell) ?? MediaTableViewCell()
        
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
        guard let mediaItem = mediaItems?[indexPath.row] else {
            return false
        }
        
        return mediaItem.editActions(viewController: self) != nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
            let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
                let alert = UIAlertController(  title: Constants.Strings.Actions,
                                                message: message,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                if let alertActions = cell.mediaItem?.editActions(viewController: self) {
                    for alertAction in alertActions {
                        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                            alertAction.handler?()
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
}

extension MediaViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let document = document, wkWebView?.scrollView.isDecelerating == true {
            captureContentOffset(document)
        }

        selectedMediaItem = mediaItems?[indexPath.row]
        
        updateUI()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {

    }
}
