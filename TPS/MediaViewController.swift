//
//  MediaViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI
import WebKit
import MediaPlayer
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Document {
    var sermon:Sermon?
    
    var purpose:String?
    
    var download:Download? {
        get {
            var download:Download?
            
            switch purpose! {
            case Purpose.notes:
                download = sermon?.notesDownload
                break
                
            case Purpose.slides:
                download = sermon?.slidesDownload
                break
                
            default:
                download = nil
                break
            }
            
            if download == nil {
                NSLog("download == nil")
            }
            
            return download
        }
    }
    
    var wkWebView:WKWebView? {
        didSet {
            if (wkWebView == nil) {
                oldValue?.scrollView.delegate = nil
            }
        }
    }
    
    var loadTimer:Timer?
    
    init(purpose:String,sermon:Sermon?)
    {
        self.purpose = purpose
        self.sermon = sermon
    }
    
    func visible(_ sermon:Sermon?) -> Bool
    {
        return (sermon == self.sermon) && (sermon?.showing == purpose)
    }
}

class MediaViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    var panning = false
    
    var sliderObserver:Timer?
    
//    var showScripture = false
    
    var documents = [String:[String:Document]]()
    
    var document:Document? {
        get {
            if (selectedSermon != nil) && (selectedSermon!.showing != nil) {
                return documents[selectedSermon!.id]![selectedSermon!.showing!]
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
    
    var notesDocument:Document? {
        didSet {
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if (selectedSermon != nil) {
                if (documents[selectedSermon!.id] == nil) {
                    documents[selectedSermon!.id] = [String:Document]()
                }
                
                if (notesDocument != nil) {
                    documents[selectedSermon!.id]![notesDocument!.purpose!] = notesDocument
                }
            }
        }
    }
    
    var slidesDocument:Document? {
        didSet {
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if (selectedSermon != nil) {
                if (documents[selectedSermon!.id] == nil) {
                    documents[selectedSermon!.id] = [String:Document]()
                }
                
                if (slidesDocument != nil) {
                    documents[selectedSermon!.id]?[slidesDocument!.purpose!] = slidesDocument
                }
            }
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    var selectedSermon:Sermon? {
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: oldValue)
            }
            
            notesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            slidesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            
            if (selectedSermon != nil) {
                if (selectedSermon!.hasNotes) {
                    notesDocument = documents[selectedSermon!.id]?[Purpose.notes]
                    
                    if (notesDocument == nil) {
                        notesDocument = Document(purpose: Purpose.notes, sermon: selectedSermon)
                    }
                }
                
                if (selectedSermon!.hasSlides) {
                    slidesDocument = documents[selectedSermon!.id]?[Purpose.slides]
                    
                    if (slidesDocument == nil) {
                        slidesDocument = Document(purpose: Purpose.slides, sermon: selectedSermon)
                    }
                }

                sermonsInSeries = selectedSermon?.sermonsInSeries // sermonsInSermonSeries(selectedSermon)
                
                let defaults = UserDefaults.standard
                defaults.set(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
                defaults.synchronize()
                
                NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.SERMON_UPDATE_UI_NOTIFICATION), object: selectedSermon) // setupActionAndTagsButtons
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                sermonsInSeries = nil
                for key in documents.keys {
                    for document in documents[key]!.values {
                        document.wkWebView?.removeFromSuperview()
                        document.wkWebView?.scrollView.delegate = nil
                    }
                    documents[key] = nil
                }
            }
        }
    }
    
    var sermonsInSeries:[Sermon]?

    @IBOutlet weak var progressIndicator: UIProgressView!

    @IBOutlet weak var splitView: SplitView!

    @IBOutlet weak var audioOrVideoControl: UISegmentedControl!
    @IBOutlet weak var audioOrVideoWidthConstraint: NSLayoutConstraint!
    
    @IBAction func audioOrVideoSelection(sender: UISegmentedControl)
    {
//        print(selectedSermon!.playing!)
        
        switch sender.selectedSegmentIndex {
        case Constants.AUDIO_SEGMENT_INDEX:
            switch selectedSermon!.playing! {
            case Playing.audio:
                //Do nothing, already selected
                break
                
            case Playing.video:
                if (globals.player.playing == selectedSermon) {
                    globals.updateCurrentTimeExact()
                    
                    globals.player.mpPlayer?.view.isHidden = true
                    globals.player.mpPlayer?.stop()
                    
                    globals.player.paused = true

                    // Because there is a sermon selected but we've STOPPED so there isn't one playing.
                    globals.player.playing = nil
                    
                    spinner.stopAnimating()
                    spinner.isHidden = true
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSlider()
                }
                
                selectedSermon?.playing = Playing.audio // Must come before setupNoteAndSlides()
                setupDocumentsAndVideo() // Calls setupSTVControl()
                break
                
            default:
                break
            }
            break
            
        case Constants.VIDEO_SEGMENT_INDEX:
            switch selectedSermon!.playing! {
            case Playing.audio:
                if (globals.player.playing == selectedSermon) {
                    globals.updateCurrentTimeExact()
                    
                    globals.player.mpPlayer?.stop()
                    
                    globals.player.paused = true
                    
                    // Because there is a sermon selected but we've STOPPED so there isn't one playing.
                    globals.player.playing = nil
                    
                    spinner.stopAnimating()
                    spinner.isHidden = true
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSlider()
                }
                
                selectedSermon?.playing = Playing.video // Must come before setupNoteAndSlides()
                setupDocumentsAndVideo() // Calls setupSTVControl()
                break
                
            case Playing.video:
                //Do nothing, already selected
                break
                
            default:
                break
            }
            break
        default:
            NSLog("oops!")
            break
        }
    }

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var stvControl: UISegmentedControl!
    @IBOutlet weak var stvWidthConstraint: NSLayoutConstraint!
    @IBAction func stvAction(_ sender: UISegmentedControl)
    {
        // This assumes this action isn't called unless an unselected segment is changed.  Otherwise touching the selected segment would cause it to flip to itself.
        
        var fromView:UIView?
        
        switch selectedSermon!.showing! {
        case Showing.video:
            fromView = globals.player.mpPlayer?.view
            break
            
        default:
            fromView = wkWebView
            break
            
        }
        
//        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        
        var toView:UIView?
        
        var showing:String?

        if (sender.selectedSegmentIndex >= 0) && (sender.selectedSegmentIndex < sender.numberOfSegments){
            switch sender.titleForSegment(at: sender.selectedSegmentIndex)! {
            case Constants.FA_SLIDES_SEGMENT_TITLE:
                showing = Showing.slides
                toView = documents[selectedSermon!.id]?[Purpose.slides]?.wkWebView
                break
                
            case Constants.FA_TRANSCRIPT_SEGMENT_TITLE:
                showing = Showing.notes
                toView = documents[selectedSermon!.id]?[Purpose.notes]?.wkWebView
                break
                
            case Constants.FA_VIDEO_SEGMENT_TITLE:
                toView = globals.player.mpPlayer?.view
                showing = Showing.video
                break
                
            default:
                break
            }
        }
        
        if (toView == nil) {
            toView = logo
        }

        if let view = toView as? WKWebView {
            view.isHidden = view.isLoading
        } else {
            toView?.isHidden = false
        }

        self.sermonNotesAndSlides.bringSubview(toFront: toView!)
        self.selectedSermon!.showing = showing

        if (fromView != toView) {
            fromView?.isHidden = true
        }
    
//        UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
//            toView?.hidden = false
//            self.sermonNotesAndSlides.bringSubviewToFront(toView!)
//            self.selectedSermon!.showing = purpose
//        }, completion: { finished in
//            if (fromView != toView) {
//                fromView?.hidden = true
//            }
//        })
    }
    
    func setupSTVControl()
    {
        if (selectedSermon != nil) {
            stvControl.removeAllSegments()
            
            var index = 0
            var slidesIndex = 0
            var notesIndex = 0
            var videoIndex = 0

            let attr = [NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_ICONS_FONT_SIZE)!]
            stvControl.setTitleTextAttributes(attr, for: UIControlState())
            
            // This order: Transcript (aka Notes), Slides, Video matches the CBC web site.
            
            if (selectedSermon!.hasNotes) {
                stvControl.insertSegment(withTitle: Constants.FA_TRANSCRIPT_SEGMENT_TITLE, at: index, animated: false)
                notesIndex = index
                index += 1
            }
            if (selectedSermon!.hasSlides) {
                stvControl.insertSegment(withTitle: Constants.FA_SLIDES_SEGMENT_TITLE, at: index, animated: false)
                slidesIndex = index
                index += 1
            }
            if (selectedSermon!.hasVideo && (globals.player.playing == selectedSermon) && (selectedSermon?.playing == Playing.video)) {
                stvControl.insertSegment(withTitle: Constants.FA_VIDEO_SEGMENT_TITLE, at: index, animated: false)
                videoIndex = index
                index += 1
            }
            
            stvWidthConstraint.constant = Constants.MIN_STV_SEGMENT_WIDTH * CGFloat(index)
            view.setNeedsLayout()

            switch selectedSermon!.showing! {
            case Showing.slides:
                stvControl.selectedSegmentIndex = slidesIndex
                break
                
            case Showing.notes:
                stvControl.selectedSegmentIndex = notesIndex
                break
                
            case Showing.video:
                stvControl.selectedSegmentIndex = videoIndex
                break
                
            case Showing.none:
                fallthrough
                
            default:
                break
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
        } else {
            stvControl.isEnabled = false
            stvControl.isHidden = true
            stvWidthConstraint.constant = 0
            view.setNeedsLayout()
        }
    }

    @IBAction func playPause(_ sender: UIButton) {
        if (globals.player.mpPlayer != nil) && (globals.player.playing != nil) && (globals.player.playing == selectedSermon) {
            switch globals.player.stateTime!.state {
            case .none:
//                NSLog("none")
                break
                
            case .playing:
//                NSLog("playing")
                globals.player.paused = true
                globals.player.mpPlayer?.pause()
                globals.updateCurrentTimeExact()
                globals.setupPlayingInfoCenter()
                
                setupPlayPauseButton()
                break
                
            case .paused:
//                NSLog("paused")
                let loadstate:UInt8 = UInt8(globals.player.mpPlayer!.loadState.rawValue)
                
                let playable = (loadstate & UInt8(MPMovieLoadState.playable.rawValue)) > 0
                let playthrough = (loadstate & UInt8(MPMovieLoadState.playthroughOK.rawValue)) > 0
                
//                if playable && debug {
//                    NSLog("playTimer.MPMovieLoadState.Playable")
//                }
//
//                if playthrough && debug {
//                    NSLog("playTimer.MPMovieLoadState.Playthrough")
//                }
//
                
                if (playable || playthrough) {
//                    NSLog("playPause.MPMovieLoadState.Playable or Playthrough OK")
                    globals.player.paused = false
                    
                    if (globals.player.mpPlayer?.contentURL == selectedSermon?.playingURL) {
                        if selectedSermon!.hasCurrentTime() {
                            //Make the comparision an Int to avoid missing minor differences
                            if (globals.player.mpPlayer!.duration >= 0) && (Int(Float(globals.player.mpPlayer!.duration)) == Int(Float(selectedSermon!.currentTime!)!)) {
                                NSLog("playPause globals.player.mpPlayer?.currentPlaybackTime and globals.player.playing!.currentTime reset to 0!")
                                globals.player.playing!.currentTime = Constants.ZERO
                                globals.player.mpPlayer?.currentPlaybackTime = TimeInterval(0)
                            }
                            if (globals.player.mpPlayer!.currentPlaybackTime >= 0) && (Int(globals.player.mpPlayer!.currentPlaybackTime) != Int(Float(selectedSermon!.currentTime!)!)) {
                                // This happens on the first play after load and the correction below is requried.
                                
                                NSLog("playPause currentPlayBackTime: \(globals.player.mpPlayer!.currentPlaybackTime) != currentTime: \(selectedSermon!.currentTime!)")
                                
                                globals.player.mpPlayer?.currentPlaybackTime = TimeInterval(Float(globals.player.playing!.currentTime!)!)

                                // This should show that it has been corrected.  Otherwise the video (I've not seen it happen on audio) starts 1-3 seconds earlier than expected.
                                NSLog("playPause currentPlayBackTime: \(globals.player.mpPlayer!.currentPlaybackTime) currentTime: \(selectedSermon!.currentTime!)")
                            }
                        } else {
                            NSLog("playPause selectedSermon has NO currentTime!")
                            globals.player.playing!.currentTime = Constants.ZERO
                            globals.player.mpPlayer?.currentPlaybackTime = TimeInterval(0)
                        }
                        
                        spinner.stopAnimating()
                        spinner.isHidden = true
                        
                        globals.player.mpPlayer?.play()
                        globals.setupPlayingInfoCenter()
                
                        setupPlayPauseButton()
                    } else {
                        playNewSermon(selectedSermon)
                    }
                } else {
//                    NSLog("playPause.MPMovieLoadState.Playable or Playthrough NOT OK")
                    playNewSermon(selectedSermon)
                }
                break
                
            case .stopped:
//                NSLog("stopped")
                break
                
            case .seekingForward:
//                NSLog("seekingForward")
                globals.player.paused = true
                globals.player.mpPlayer?.pause()
                globals.updateCurrentTimeExact()
                
                setupPlayPauseButton()
                break
                
            case .seekingBackward:
//                NSLog("seekingBackward")
                globals.player.paused = true
                globals.player.mpPlayer?.pause()
                globals.updateCurrentTimeExact()
                
                setupPlayPauseButton()
                break
            }
        } else {
            playNewSermon(selectedSermon)
        }
    }
    
    fileprivate func sermonNotesAndSlidesConstraintMinMax(_ height:CGFloat) -> (min:CGFloat,max:CGFloat)
    {
        let minConstraintConstant:CGFloat = tableView.rowHeight*0 + 31 + 16 //margin on top and bottom of slider
                                                          //slider.bounds.height
        
        let maxConstraintConstant:CGFloat = height - 31 - navigationController!.navigationBar.bounds.height + 11 //  - logo.bounds.height
                                                //slider.bounds.height
        
//        NSLog("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
//        
//        print(minConstraintConstant,maxConstraintConstant)
        
        return (minConstraintConstant,maxConstraintConstant)
    }

    fileprivate func roomForLogo() -> Bool
    {
        return splitView.height > (self.view.bounds.height - slider.bounds.height - navigationController!.navigationBar.bounds.height - logo.bounds.height)
    }
    
    fileprivate func shouldShowLogo() -> Bool
    {
        var result = (selectedSermon == nil)

        if (document != nil) {
            result = ((wkWebView == nil) || (wkWebView!.isHidden == true)) && progressIndicator.isHidden
        } else {
            if (selectedSermon?.showing == Showing.video) {
                result = false
            }
            if (selectedSermon?.showing == Showing.none) {
                result = true
            }
        }

        if (selectedSermon != nil) && (documents[selectedSermon!.id] != nil) {
            var nilCount = 0
            var hiddenCount = 0
            
            for key in documents[selectedSermon!.id]!.keys {
                let wkWebView = documents[selectedSermon!.id]![key]!.wkWebView
                if (wkWebView == nil) {
                    nilCount += 1
                }
                if (wkWebView != nil) && (wkWebView!.isHidden == true) {
                    hiddenCount += 1
                }
            }
            
            if (nilCount == documents[selectedSermon!.id]!.keys.count) {
                result = true
            } else {
                if (hiddenCount > 0) {
                    result = progressIndicator.isHidden
                }
            }
        }

        return result
    }

    //        if selectedSermon != nil {
    //            switch selectedSermon!.showing! {
    //            case Showing.video:
    //                result = false
    //                break
    //
    //            case Showing.notes:
    //                result = ((sermonNotesWebView == nil) || (sermonNotesWebView!.hidden == true)) && progressIndicator.hidden
    //                break
    //
    //            case Showing.slides:
    //                result = ((sermonSlidesWebView == nil) || (sermonSlidesWebView!.hidden == true)) && progressIndicator.hidden
    //                break
    //
    //            case Showing.none:
    //                result = true
    //                break
    //
    //            default:
    //                result = false
    //                break
    //            }
    //        } else {
    //            result = true
    //        }
    //
    //        if (sermonNotesWebView == nil) && (sermonSlidesWebView == nil) {
    //            return true
    //        }
    //
    //        if (sermonNotesWebView == nil) && ((sermonSlidesWebView != nil) && (sermonSlidesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    //
    //        if (sermonSlidesWebView == nil) && ((sermonNotesWebView != nil) && (sermonNotesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    //
    //        if ((sermonNotesWebView != nil) && (sermonNotesWebView!.hidden == true)) && ((sermonSlidesWebView != nil) && (sermonSlidesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    
    fileprivate func setSermonNotesAndSlidesConstraint(_ change:CGFloat)
    {
        let newConstraintConstant = sermonNotesAndSlidesConstraint.constant + change
        
        //            NSLog("pan rowHeight: \(tableView.rowHeight)")
        
        let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.sermonNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        splitView.min = minConstraintConstant
        splitView.max = maxConstraintConstant
        splitView.height = sermonNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
        
        logo.isHidden = !shouldShowLogo() //&& roomForLogo()
    }
    
    
    @IBAction func pan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            for document in documents[selectedSermon!.id]!.values {
                document.wkWebView?.isHidden = true
                document.wkWebView?.scrollView.delegate = nil
            }

            panning = true
            break
            
        case .ended:
            captureViewSplit()

            for document in documents[selectedSermon!.id]!.values {
                document.wkWebView?.isHidden = (wkWebView?.url == nil)
                document.wkWebView?.scrollView.delegate = self
            }

            panning = false
            break
        
        case .changed:
            let translation = gesture.translation(in: splitView)
            let change = -translation.y
            if change != 0 {
                gesture.setTranslation(CGPoint.zero, in: splitView)
                setSermonNotesAndSlidesConstraint(change)
                self.view.setNeedsLayout()
                self.view.layoutSubviews()
            }
            break
            
        default:
            break
        }
    }
    
    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var sermonNotesAndSlidesConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sermonNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
//        if (globals.player.mpPlayer == nil) { //  && Reachability.isConnectedToNetwork()
//            globals.setupPlayer(selectedSermon)
//        }
//        
        if (globals.player.mpPlayer != nil) {
            if (slider.value < 1.0) {
                let length = Float(globals.player.mpPlayer!.duration)
                let seekToTime = Float(slider.value * Float(length))
                globals.player.mpPlayer?.currentPlaybackTime = TimeInterval(seekToTime)
                globals.player.playing?.currentTime = seekToTime.description
            } else {
                globals.player.mpPlayer?.pause()
                globals.player.paused = true

                globals.player.mpPlayer?.currentPlaybackTime = globals.player.mpPlayer!.duration
                globals.player.playing?.currentTime = globals.player.mpPlayer!.duration.description
            }
            
            setupPlayPauseButton()
            addSliderObserver()
        }
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        //        NSLog("sliderTouchUpOutside")
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider) {
//        NSLog("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
//        NSLog("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider) {
        setTimesToSlider()
    }
    
    var actionButton:UIBarButtonItem?
    var tagsButton:UIBarButtonItem?

    func showSendMessageErrorAlert() {
        let sendMessageErrorAlert = UIAlertView(title: "Could Not Send a Message", message: "Your device could not send a text message.  Please check your configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMessageErrorAlert.show()
    }
    
    // MARK: MFMessageComposeViewControllerDelegate Method
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func message(_ sermon:Sermon?)
    {
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = nil
        messageComposeViewController.subject = "Recommendation"
        messageComposeViewController.body = setupBody(sermon)
        
        if MFMessageComposeViewController.canSendText() {
            self.present(messageComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func setupBody(_ sermon:Sermon?) -> String? {
        var bodyString:String?
        
        if (sermon != nil) {
            bodyString = "\"" + sermon!.title! + "\"" + " by " + sermon!.speaker! + " from " + Constants.CBC_LONG

            bodyString = bodyString! + "\n\nAudio: " + sermon!.audioURL!.absoluteString
            
            if sermon!.hasVideo {
                bodyString = bodyString! + "\n\nVideo " + sermon!.videoURL!.absoluteString
            }
            
            if sermon!.hasSlides {
                bodyString = bodyString! + "\n\nSlides: " + sermon!.slidesURL!.absoluteString
            }
            
            if sermon!.hasNotes {
                bodyString = bodyString! + "\n\nTranscript " + sermon!.notesURL!.absoluteString
            }
        }
        
        return bodyString
    }
    
    func setupSermonBodyHTML(_ sermon:Sermon?) -> String? {
        var bodyString:String?
        
        if (sermon != nil) {
            bodyString = "\"" + sermon!.title! + "\"" + " by " + sermon!.speaker! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
            
            bodyString = bodyString! + " (<a href=\"" + sermon!.audioURL!.absoluteString + "\">Audio</a>)"
            
            if sermon!.hasVideo {
                bodyString = bodyString! + " (<a href=\"" + sermon!.videoURL!.absoluteString + "\">Video</a>) "
            }

            if sermon!.hasSlides {
                bodyString = bodyString! + " (<a href=\"" + sermon!.slidesURL!.absoluteString + "\">Slides</a>)"
            }
            
            if sermon!.hasNotes {
                bodyString = bodyString! + " (<a href=\"" + sermon!.notesURL!.absoluteString + "\">Transcript</a>) "
            }
            
            bodyString = bodyString! + "<br/>"
        }
        
        return bodyString
    }
    
    func setupSermonSeriesBodyHTML(_ sermonsInSeries:[Sermon]?) -> String? {
        var bodyString:String?

        if let sermons = sermonsInSeries {
            if (sermons.count > 0) {
                bodyString = "\"\(sermons[0].series!)\" by \(sermons[0].speaker!)"
                bodyString = bodyString! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
                bodyString = bodyString! + "<br/>" + "<br/>"
                
                let sermonList = sermons.sorted() {
                    if ($0.fullDate!.isEqualTo($1.fullDate!)) {
                        return $0.service < $1.service
                    } else {
                        return $0.fullDate!.isOlderThan($1.fullDate!)
                    }
                }
                
                for sermon in sermonList {
                    bodyString = bodyString! + sermon.title!
                    
                    bodyString = bodyString! + " (<a href=\"" + sermon.audioURL!.absoluteString + "\">Audio</a>)"
                    
                    if sermon.hasVideo {
                        bodyString = bodyString! + " (<a href=\"" + sermon.videoURL!.absoluteString + "\">Video</a>) "
                    }
                    
                    if sermon.hasSlides {
                        bodyString = bodyString! + " (<a href=\"" + sermon.slidesURL!.absoluteString + "\">Slides</a>)"
                    }
                    
                    if sermon.hasNotes {
                        bodyString = bodyString! + " (<a href=\"" + sermon.notesURL!.absoluteString + "\">Transcript</a>) "
                    }
                    
                    bodyString = bodyString! + "<br/>"
                }
                
                bodyString = bodyString! + "<br/>"
            }
        }
        
        return bodyString
    }
    
    func addressStringHTML() -> String
    {
        let addressString:String = "<br/>\(Constants.CBC_LONG)<br/>\(Constants.CBC_STREET_ADDRESS)<br/>\(Constants.CBC_CITY_STATE_ZIPCODE_COUNTRY)<br/>\(Constants.CBC_PHONE_NUMBER)<br/><a href=\"mailto:\(Constants.CBC_EMAIL)\">\(Constants.CBC_EMAIL)</a><br/>\(Constants.CBC_WEBSITE)"
        
        return addressString
    }
    
    func addressString() -> String
    {
        let addressString:String = "\n\n\(Constants.CBC_LONG)\n\(Constants.CBC_STREET_ADDRESS)\n\(Constants.CBC_CITY_STATE_ZIPCODE_COUNTRY)\nPhone: \(Constants.CBC_PHONE_NUMBER)\nE-mail:\(Constants.CBC_EMAIL)\nWeb: \(Constants.CBC_WEBSITE)"
        
        return addressString
    }
    
    func mailSermon(_ sermon:Sermon?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.SERMON_EMAIL_SUBJECT)

        if let bodyString = setupSermonBodyHTML(sermon) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }

        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func mailSermonSeries(_ sermons:[Sermon]?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.SERIES_EMAIL_SUBJECT)
        
        if let bodyString = setupSermonSeriesBodyHTML(sermons) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func printSermon(_ sermon:Sermon?)
    {
        if (UIPrintInteractionController.isPrintingAvailable && (sermon != nil))
        {
            let printURL = sermon?.downloadURL
            
            if (printURL != nil) && UIPrintInteractionController.canPrint(printURL!) {
//                NSLog("can print!")
                let pi = UIPrintInfo.printInfo()
                pi.outputType = UIPrintInfoOutputType.general
                pi.jobName = "Print";
                pi.orientation = UIPrintInfoOrientation.portrait
                pi.duplex = UIPrintInfoDuplex.longEdge
                
                let pic = UIPrintInteractionController.shared
                pic.printInfo = pi
                pic.showsPageRange = true
                
                //Never could get this to work:
//            pic?.printFormatter = webView?.viewPrintFormatter()
                
                pic.printingItem = printURL
                pic.present(from: navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    fileprivate func openSermonScripture(_ sermon:Sermon?)
    {
        var urlString = Constants.SCRIPTURE_URL_PREFIX + sermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX

        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

//        NSLog("\(sermon!.scripture!)")
//        NSLog("\(urlString)")
//        NSLog("\(NSURL(string:urlString))")
        
        if let url = URL(string:urlString) {
            if (UIApplication.shared.canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.shared.openURL(url)
            } else {
                networkUnavailable("Unable to open scripture at: \(url)")
            }
        }
    }
    
//    func twitter(sermon:Sermon?)
//    {
//        assert(sermon != nil, "can't tweet about a nil sermon")
//
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
//            var bodyString = String()
//            
//            bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
//            
//            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
//            twitterSheet.setInitialText(bodyString)
//            //                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
//            //                NSLog("\(str)")
//            //                twitterSheet.addURL(NSURL(string:str))
//            self.presentViewController(twitterSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//
////        if Reachability.isConnectedToNetwork() {
////            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
////                var bodyString = String()
////                
////                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
////                
////                let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
////                twitterSheet.setInitialText(bodyString)
//////                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
//////                NSLog("\(str)")
//////                twitterSheet.addURL(NSURL(string:str))
////                self.presentViewController(twitterSheet, animated: true, completion: nil)
////            } else {
////                let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
////                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
////                self.presentViewController(alert, animated: true, completion: nil)
////            }
////        } else {
////            networkUnavailable("Unable to reach the internet to tweet.")
////        }
//    }
//    
//    func facebook(sermon:Sermon?)
//    {
//        assert(sermon != nil, "can't post about a nil sermon")
//
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//            var bodyString = String()
//            
//            bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
//            
//            //So the user can paste the initialText into the post dialog/view
//            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
//            UIPasteboard.generalPasteboard().string = bodyString
//            
//            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//            facebookSheet.setInitialText(bodyString)
//            //                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
//            //                NSLog("\(str)")
//            //                facebookSheet.addURL(NSURL(string: str))
//            self.presentViewController(facebookSheet, animated: true, completion: nil)
//        } else {
//            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//
////        if Reachability.isConnectedToNetwork() {
////            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
////                var bodyString = String()
////                
////                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
////
////                //So the user can paste the initialText into the post dialog/view
////                //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
////                UIPasteboard.generalPasteboard().string = bodyString
////
////                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
////                facebookSheet.setInitialText(bodyString)
//////                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
//////                NSLog("\(str)")
//////                facebookSheet.addURL(NSURL(string: str))
////                self.presentViewController(facebookSheet, animated: true, completion: nil)
////            } else {
////                let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
////                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
////                self.presentViewController(alert, animated: true, completion: nil)
////            }
////        } else {
////            networkUnavailable("Unable to reach the internet to post to Facebook.")
////        }
//    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                sermon?.audioDownload?.deleteDownload()
                break
                
            case Constants.Cancel_Audio_Download:
                sermon?.audioDownload?.cancelOrDeleteDownload()
                break
                
            default:
                break
            }
            break
            
        case .selectingAction:
            switch strings[index] {
            case Constants.Print:
                printSermon(selectedSermon)
                break
                
            case Constants.Add_to_Favorites:
                selectedSermon?.addTag(Constants.Favorites)
                break
                
            case Constants.Add_All_to_Favorites:
                for sermon in sermonsInSeries! {
                    sermon.addTag(Constants.Favorites)
                }
                break
                
            case Constants.Remove_From_Favorites:
                selectedSermon?.removeTag(Constants.Favorites)
                break
                
            case Constants.Remove_All_From_Favorites:
                for sermon in sermonsInSeries! {
                    sermon.removeTag(Constants.Favorites)
                }
                break
                
            case Constants.Full_Screen:
                if (selectedSermon!.hasVideo && selectedSermon!.playingVideo && selectedSermon!.showingVideo) {
                    zoomScreen()
                }
                
                if document != nil {
//                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
//                    showScripture = false
                    performSegue(withIdentifier: Constants.SHOW_FULL_SCREEN_SEGUE, sender: selectedSermon)
                }
                break
                
            case Constants.Open_in_Browser:
                if selectedSermon?.downloadURL != nil {
                    if (UIApplication.shared.canOpenURL(selectedSermon!.downloadURL! as URL)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.shared.openURL(selectedSermon!.downloadURL! as URL)
                    } else {
                        networkUnavailable("Unable to open transcript in browser at: \(selectedSermon?.downloadURL)")
                    }
                }
                break
                
//            case Constants.Scripture_Full_Screen:
//                showScripture = true
//                performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: selectedSermon)
//                break
                
            case Constants.Scripture_in_Browser:
                openSermonScripture(selectedSermon)
                break
                
            case Constants.Download_Audio:
                selectedSermon?.audioDownload?.download()
                break
                
            case Constants.Download_All_Audio:
                for sermon in sermonsInSeries! {
                    sermon.audioDownload?.download()
                }
                break
                
            case Constants.Cancel_Audio_Download:
                selectedSermon?.audioDownload?.cancelOrDeleteDownload()
                break
                
            case Constants.Cancel_All_Audio_Downloads:
                for sermon in sermonsInSeries! {
                    sermon.audioDownload?.cancelDownload()
                }
                break
                
            case Constants.Delete_Audio_Download:
                selectedSermon?.audioDownload?.deleteDownload()
                break
                
            case Constants.Delete_All_Audio_Downloads:
                for sermon in sermonsInSeries! {
                    sermon.audioDownload?.deleteDownload()
                }
                break
                
            case Constants.Email_Sermon:
                mailSermon(selectedSermon)
                break
                
            case Constants.Email_Series:
                mailSermonSeries(sermonsInSeries)
                break
                
            case Constants.Check_for_Update:
                download?.deleteDownload()
                setupDocumentsAndVideo()
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }

    func actions()
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = actionButton
                
                //                popover.navigationItem.title = "Show"
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                if (document != nil) {
//                if (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) || (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) {
                    actionMenu.append(Constants.Print)
                }

                if selectedSermon!.hasFavoritesTag {
                    actionMenu.append(Constants.Remove_From_Favorites)
                } else {
                    actionMenu.append(Constants.Add_to_Favorites)
                }
                
                if sermonsInSeries?.count > 1 {
                    var favoriteSermons = 0
                    
                    for sermon in sermonsInSeries! {
                        if (sermon.hasFavoritesTag) {
                            favoriteSermons += 1
                        }
                    }
                    switch favoriteSermons {
                    case 0:
                        actionMenu.append(Constants.Add_All_to_Favorites)
                        break
                        
                    case 1:
                        actionMenu.append(Constants.Add_All_to_Favorites)

                        if !selectedSermon!.hasFavoritesTag {
                            actionMenu.append(Constants.Remove_All_From_Favorites)
                        }
                        break
                        
                    case sermonsInSeries!.count - 1:
                        if selectedSermon!.hasFavoritesTag {
                            actionMenu.append(Constants.Add_All_to_Favorites)
                        }
                        
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                        
                    case sermonsInSeries!.count:
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                        
                    default:
                        actionMenu.append(Constants.Add_All_to_Favorites)
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                    }
                }
                
                if (selectedSermon!.hasVideo && selectedSermon!.playingVideo && selectedSermon!.showingVideo) || (document != nil) {
//                   (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    actionMenu.append(Constants.Full_Screen)
                }
                
                if (document != nil) && globals.cacheDownloads {
                    actionMenu.append(Constants.Check_for_Update)
                }

//                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
//                }
                
                if document != nil {
//                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    actionMenu.append(Constants.Open_in_Browser)
                }
                
//                if (selectedSermon!.hasScripture && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
//                    actionMenu.append(Constants.Scripture_Full_Screen)
//                }
                
                if (selectedSermon!.hasScripture && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
                    actionMenu.append(Constants.Scripture_in_Browser)
                }
                
                if let sermons = sermonsInSeries {
                    var sermonsToDownload = 0
                    var sermonsDownloading = 0
                    var sermonsDownloaded = 0
                    
                    for sermon in sermons {
                        switch sermon.audioDownload!.state {
                        case .none:
                            sermonsToDownload += 1
                            break
                        case .downloading:
                            sermonsDownloading += 1
                            break
                        case .downloaded:
                            sermonsDownloaded += 1
                            break
                        }
                    }
                    
                    if (selectedSermon?.audioDownload != nil) {
                        switch selectedSermon!.audioDownload!.state {
                        case .none:
                            actionMenu.append(Constants.Download_Audio)
                            break
                            
                        case .downloading:
                            actionMenu.append(Constants.Cancel_Audio_Download)
                            break
                            
                        case .downloaded:
                            actionMenu.append(Constants.Delete_Audio_Download)
                            break
                        }
                    }
                    
                    if (selectedSermon?.audioDownload?.state == .none) {
                        if (sermonsToDownload > 1) {
                            actionMenu.append(Constants.Download_All_Audio)
                        }
                    } else {
                        if (sermonsToDownload > 0) {
                            actionMenu.append(Constants.Download_All_Audio)
                        }
                    }
                    
                    if (selectedSermon?.audioDownload?.state == .downloading) {
                        if (sermonsDownloading > 1) {
                            actionMenu.append(Constants.Cancel_All_Audio_Downloads)
                        }
                    } else {
                        if (sermonsDownloading > 0) {
                            actionMenu.append(Constants.Cancel_All_Audio_Downloads)
                        }
                    }
                    
                    if (selectedSermon?.audioDownload?.state == .downloaded) {
                        if (sermonsDownloaded > 1) {
                            actionMenu.append(Constants.Delete_All_Audio_Downloads)
                        }
                    } else {
                        if (sermonsDownloaded > 0) {
                            actionMenu.append(Constants.Delete_All_Audio_Downloads)
                        }
                    }
                }
                
                actionMenu.append(Constants.Email_Sermon)
                if (selectedSermon!.hasSeries && (sermonsInSeries?.count > 1)) {
                        actionMenu.append(Constants.Email_Series)
                }

                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func zoomScreen()
    {
        //It works!  Problem was in globals.player.mpPlayer?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
        //Thank you StackOverflow!

        globals.player.mpPlayer?.setFullscreen(!globals.player.mpPlayer!.isFullscreen, animated: true)
    }
    
    fileprivate func setupPlayerView(_ view:UIView?)
    {
        if (view != nil) {
            view?.isHidden = true
            view?.removeFromSuperview()
            
            view?.gestureRecognizers = nil
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.zoomScreen))
            tap.numberOfTapsRequired = 2
            view?.addGestureRecognizer(tap)
            
            view?.frame = sermonNotesAndSlides.bounds

            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(view!)
            
//            print(view)
//            print(view?.superview)            
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(width)
            
            let height = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(height)
            
            sermonNotesAndSlides.setNeedsLayout()
        }
    }
    
    fileprivate func setupWKWebView(_ wkWebView:WKWebView?)
    {
        if (wkWebView != nil) {
            wkWebView?.isMultipleTouchEnabled = true
            
            wkWebView?.scrollView.scrollsToTop = false
            
            //        NSLog("\(sermonNotesAndSlides.frame)")
            //        sermonNotesWebView?.UIDelegate = self
            
            wkWebView?.scrollView.delegate = self
            wkWebView?.navigationDelegate = self

            wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(wkWebView!)
            
            let centerXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerXNotes)
            
            let centerYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerYNotes)
            
            let widthXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthXNotes)
            
            let widthYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthYNotes)
            
            sermonNotesAndSlides.setNeedsLayout()
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidZoom")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        NSLog("scrollViewDidEndZooming")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
            captureZoomScale(view)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidScroll")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        NSLog("scrollViewDidEndScrollingAnimation")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
//        NSLog("scrollViewDidEndDecelerating")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
//        NSLog("scrollViewDidEndDragging")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func updateView()
    {
        selectedSermon = globals.selectedSermonDetail
        
        tableView.reloadData()

        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.none)
            })
        }

//        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: { () -> Void in
//            DispatchQueue.main.async(execute: { () -> Void in
//                self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.none)
//            })
//        })

        updateUI()
    }
    
    func clearView()
    {
//        self.navigationController?.popToRootViewController(animated: false)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.hidesBackButton = true // In case this MVC was pushed from the ScriptureIndexController.
            
            self.selectedSermon = nil
            
            self.tableView.reloadData()
            
            self.updateUI()
        })
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        navigationController?.setToolbarHidden(true, animated: false)
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.resetConstraint))
        tap.numberOfTapsRequired = 2
        splitView?.addGestureRecognizer(tap)
        
        splitView.splitViewController = splitViewController

//        NSLog("\(globals.player.mpPlayer?.contentURL)")
//        NSLog("\(Constants.LIVE_STREAM_URL)")
        if (selectedSermon == globals.player.playing) && (globals.player.mpPlayer?.contentURL == URL(string:Constants.LIVE_STREAM_URL)) {
            globals.player.mpPlayer?.stop()
            globals.player.mpPlayer = nil
            
            if (selectedSermon != nil) {
                globals.player.playOnLoad = false
                globals.setupPlayer(selectedSermon)
            }
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true

        //Unreliable
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if(globals.player.loaded) {
            spinner.stopAnimating()
        }

        if (selectedSermon == nil) {
            //Will only happen on an iPad
            selectedSermon = globals.selectedSermonDetail
        }
    }

    fileprivate func setupDefaultDocuments()
    {
        if (selectedSermon != nil) {
            splitView.isHidden = false
            
            let hasNotes = selectedSermon!.hasNotes
            let hasSlides = selectedSermon!.hasSlides
            
            globals.player.mpPlayer?.view.isHidden = true
            
            if (!hasSlides && !hasNotes) {
                hideAllDocuments()
                
                logo.isHidden = false
                selectedSermon!.showing = Showing.none
                
                sermonNotesAndSlides.bringSubview(toFront: logo)
            } else
            if (hasSlides && !hasNotes) {
                logo.isHidden = true
                
                selectedSermon!.showing = Showing.slides

                hideOtherDocuments()

                if (wkWebView != nil) {
                    sermonNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            } else
            if (!hasSlides && hasNotes) {
                logo.isHidden = true
                
                selectedSermon!.showing = Showing.notes

                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    sermonNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            } else
            if (hasSlides && hasNotes) {
                logo.isHidden = true
                
                selectedSermon!.showing = Showing.slides //This is an arbitrary choice

                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    sermonNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            }
        }
    }
    
    func downloading(_ timer:Timer?)
    {
        let document = timer?.userInfo as? Document
        
        if (selectedSermon != nil) {
            if (document?.download != nil) {
                NSLog("totalBytesWritten: \(document!.download!.totalBytesWritten)")
                NSLog("totalBytesExpectedToWrite: \(document!.download!.totalBytesExpectedToWrite)")
                
                switch document!.download!.state {
                case .none:
//                    NSLog(".none")
                    document?.download?.task?.cancel()
                    
                    document?.loadTimer?.invalidate()
                    document?.loadTimer = nil
                    
                    if document!.visible(selectedSermon) {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        
                        self.progressIndicator.isHidden = true
                        
                        document?.wkWebView?.isHidden = true
                        
                        globals.player.mpPlayer?.view.isHidden = true
                        
                        self.logo.isHidden = false
                        self.sermonNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                    break
                    
                case .downloading:
//                    NSLog(".downloading")
                    if document!.visible(selectedSermon) {
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                    }
                    break
                    
                case .downloaded:
//                    NSLog(".downloaded")
                    if #available(iOS 9.0, *) {

                        document?.loadTimer?.invalidate()
                        document?.loadTimer = nil

//                        DispatchQueue.global(qos: .background).async {
//                            //                            print(document!.download!.fileSystemURL!)
//                            _ = document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
//                            
//                            DispatchQueue.main.async(execute: { () -> Void in
//                                if document!.visible(self.selectedSermon) {
//                                    self.progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
//                                }
//                                
//                                document?.loadTimer?.invalidate()
//                                document?.loadTimer = nil
//                            })
//                        }

//                        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
////                            print(document!.download!.fileSystemURL!)
//                            document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
//                            
//                            DispatchQueue.main.async(execute: { () -> Void in
//                                if document!.visible(self.selectedSermon) {
//                                    self.progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
//                                }
//                                
//                                document?.loadTimer?.invalidate()
//                                document?.loadTimer = nil
//                            })
//                        })
                    } else {
                        // Fallback on earlier versions
                    }
                    break
                }
            }
        }
    }
    
    func loading(_ timer:Timer?)
    {
        // Expected to be on the main thread
        if let document = timer?.userInfo as? Document {
            if document.visible(selectedSermon) {
                if (document.wkWebView != nil) {
                    progressIndicator.progress = Float(document.wkWebView!.estimatedProgress)
                    
                    if progressIndicator.progress == 1 {
                        progressIndicator.isHidden = true
                    }
                }
            }
            
            if (document.wkWebView != nil) && !document.wkWebView!.isLoading {
                document.loadTimer?.invalidate()
                document.loadTimer = nil
            }
        }
    }
    
    fileprivate func setupDocument(_ document:Document?)
    {
//        NSLog("setupDocument")
        
        document?.wkWebView?.removeFromSuperview()
        document?.wkWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
        setupWKWebView(document?.wkWebView)
        
        document?.wkWebView?.isHidden = true
        document?.wkWebView?.stopLoading()
        
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads {
//                print(document?.download?.state)
                if (document?.download != nil) && (document?.download?.state != .downloaded){
                    if document!.visible(selectedSermon) {
                        sermonNotesAndSlides.bringSubview(toFront: activityIndicator)
                        sermonNotesAndSlides.bringSubview(toFront: progressIndicator)
                        
                        activityIndicator.isHidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite != 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.isHidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.DOWNLOADING_TIMER_INTERVAL, target: self, selector: #selector(MediaViewController.downloading(_:)), userInfo: document, repeats: true)
                    }
                    
                    document?.download?.download()
                } else {
                    DispatchQueue.global(qos: .background).async(execute: { () -> Void in
//                        print(document!.download!.fileSystemURL!)
                        _ = document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            if (document != nil) && document!.visible(self.selectedSermon) {
                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.isHidden = true
                                
                                self.progressIndicator.progress = 0.0
                                self.progressIndicator.isHidden = true
                            }
                            document?.loadTimer?.invalidate()
                            document?.loadTimer = nil
                        })
                    })
                }
            } else {
                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        if document!.visible(self.selectedSermon) {
                            self.activityIndicator.isHidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.isHidden = false
                        }
                        
                        if document?.loadTimer == nil {
                            document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                        }
                    })
                    
                    if (document == nil) {
                        NSLog("document nil")
                    }
                    if (document!.download == nil) {
                        NSLog("document!.download nil")
                    }
                    if (document!.download!.downloadURL == nil) {
                        NSLog("\(self.selectedSermon?.title)")
                        NSLog("document!.download!.downloadURL nil")
                    }
                    let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    _ = document?.wkWebView?.load(request)
                })
            }
        } else {
            DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if document!.visible(self.selectedSermon) {
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.isHidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                    }
                })
                
                let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                _ = document?.wkWebView?.load(request)
            })
        }
    }
    
    fileprivate func hideOtherDocuments()
    {
        if (selectedSermon != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if !document.visible(selectedSermon) {
                        document.wkWebView?.isHidden = true
                    }
                }
            }
        }
    }
    
    fileprivate func hideAllDocuments()
    {
        if (selectedSermon != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    document.wkWebView?.isHidden = true
                }
            }
        }
    }
    
    fileprivate func setupDocumentsAndVideo()
    {
        activityIndicator.isHidden = true

        progressIndicator.isHidden = true
        progressIndicator.progress = 0.0

//        NSLog("setupNotesAndSlides")
//        NSLog("Selected: \(globals.sermonSelected?.title)")
//        NSLog("Last Selected: \(globals.sermonLastSelected?.title)")
//        NSLog("Playing: \(globals.player.playing?.title)")
        
        if (selectedSermon != nil) {
            splitView.isHidden = false

            if (selectedSermon!.hasNotes) {
                notesDocument = documents[selectedSermon!.id]?[Purpose.notes]
                
                if (notesDocument == nil) {
                    notesDocument = Document(purpose: Purpose.notes, sermon: selectedSermon)
                }
//                print(notesDocument?.download?.downloadURL)
                setupDocument(notesDocument)
            } else {
                notesDocument?.wkWebView?.isHidden = true
            }
            
            if (selectedSermon!.hasSlides) {
                slidesDocument = documents[selectedSermon!.id]?[Purpose.slides]
                
                if (slidesDocument == nil) {
                    slidesDocument = Document(purpose: Purpose.slides, sermon: selectedSermon)
                }
//                print(slidesDocument?.download?.downloadURL)
                setupDocument(slidesDocument)
            } else {
                slidesDocument?.wkWebView?.isHidden = true
            }
            
    //        NSLog("notes hidden \(sermonNotes.hidden)")
    //        NSLog("slides hidden \(sermonSlides.hidden)")
            
            // Check whether they can or should show what they claim to show!
            
            switch selectedSermon!.showing! {
            case Showing.notes:
                if !selectedSermon!.hasNotes {
                    selectedSermon!.showing = Showing.none
                }
                break
                
            case Showing.slides:
                if !selectedSermon!.hasSlides {
                    selectedSermon!.showing = Showing.none
                }
                break
                
            case Showing.video:
                if !selectedSermon!.hasVideo {
                    selectedSermon!.showing = Showing.none
                }
                break
                
            default:
                break
            }
            
            switch selectedSermon!.showing! {
            case Showing.notes:
                globals.player.mpPlayer?.view.isHidden = true
                logo.isHidden = true
                
                hideOtherDocuments()
                
                sermonNotesAndSlides.bringSubview(toFront: wkWebView!)
                break
                
            case Showing.slides:
                globals.player.mpPlayer?.view.isHidden = true
                logo.isHidden = true
                
                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    sermonNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
                break
                
            case Showing.video:
                //This should not happen unless it is playing video.
                switch selectedSermon!.playing! {
                case Playing.audio:
                    //This should never happen.
                    setupDefaultDocuments()
                    break

                case Playing.video:
                    if (globals.player.playing != nil) && (globals.player.playing == selectedSermon) {
                        hideAllDocuments()

                        logo.isHidden = true
                        
                        globals.player.mpPlayer?.view.isHidden = false
                        selectedSermon?.showing = Showing.video
                        if (globals.player.mpPlayer != nil) {
                            sermonNotesAndSlides.bringSubview(toFront: globals.player.mpPlayer!.view)
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
                break
                
            case Showing.none:
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                hideAllDocuments()
                
                switch selectedSermon!.playing! {
                case Playing.audio:
                    globals.player.mpPlayer?.view.isHidden = true
                    setupDefaultDocuments()
                    break
                    
                case Playing.video:
                    if (globals.player.playing == selectedSermon) {
                        if (globals.player.playing!.hasVideo && (globals.player.playing!.playing == Playing.video)) {
                            globals.player.mpPlayer?.view.isHidden = false
                            sermonNotesAndSlides.bringSubview(toFront: globals.player.mpPlayer!.view!)
                            selectedSermon?.showing = Showing.video
                        } else {
                            globals.player.mpPlayer?.view.isHidden = true
                            self.logo.isHidden = false
                            selectedSermon?.showing = Showing.none
                            self.sermonNotesAndSlides.bringSubview(toFront: self.logo)
                        }
                    } else {
                        globals.player.mpPlayer?.view.isHidden = true
                        setupDefaultDocuments()
                    }
                    break
                    
                default:
                    break
                }
                break
                
            default:
                break
            }
        } else {
            splitView.isHidden = true
            
            hideAllDocuments()

            globals.player.mpPlayer?.view.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if (!logo.isHidden) {
                sermonNotesAndSlides.bringSubview(toFront: self.logo)
            }
        }

        setupSTVControl()
    }
    
    func scrollToSermon(_ sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = IndexPath(row: 0, section: 0)
            
            if (sermonsInSeries?.count > 1) {
                if let sermonIndex = sermonsInSeries?.index(of: sermon!) {
//                    NSLog("\(sermonIndex)")
                    indexPath = IndexPath(row: sermonIndex, section: 0)
                }
            }
            
//            NSLog("\(tableView.bounds)")
            
            if (select) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: position)
            }
            
//            NSLog("Row: \(indexPath.row) Section: \(indexPath.section)")

            if (position == UITableViewScrollPosition.top) {
//                var point = CGPointZero //tableView.bounds.origin
//                point.y += tableView.rowHeight * CGFloat(indexPath.row)
//                tableView.setContentOffset(point, animated: true)
                tableView.scrollToRow(at: indexPath, at: position, animated: false)
            } else {
                tableView.scrollToRow(at: indexPath, at: position, animated: false)
            }
        } else {
            //No sermon to scroll to.
            
        }
    }
    
    func setupPlayPauseButton()
    {
        if selectedSermon != nil {
            if (selectedSermon == globals.player.playing) {
                playPauseButton.isEnabled = globals.player.loaded
                
                if (globals.player.paused) {
                    playPauseButton.setTitle(Constants.FA_PLAY, for: UIControlState())
                } else {
                    playPauseButton.setTitle(Constants.FA_PAUSE, for: UIControlState())
                }
            } else {
                playPauseButton.isEnabled = true
                playPauseButton.setTitle(Constants.FA_PLAY, for: UIControlState())
            }

            playPauseButton.isHidden = false
        } else {
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func tags(_ object:AnyObject?)
    {
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.filters
        //And when the user chooses one, scroll to the first time in that section.
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up

                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Series"
                
                popover.delegate = self
                
                popover.purpose = .showingTags
                popover.strings = selectedSermon?.tagsArray
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                popover.allowsSelection = false
                popover.selectedSermon = selectedSermon
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func setupActionAndTagsButtons()
    {
        if (selectedSermon != nil) {
            var barButtons = [UIBarButtonItem]()
            
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(MediaViewController.actions))
            barButtons.append(actionButton!)
        
            if (selectedSermon!.hasTags) {
                if (selectedSermon?.tagsSet?.count > 1) {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
                } else {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
                }
                
                tagsButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_TAGS_FONT_SIZE)!], for: UIControlState())
                
                barButtons.append(tagsButton!)
            }

            self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
        } else {
            actionButton = nil
            tagsButton = nil
            self.navigationItem.setRightBarButtonItems(nil, animated: true)
        }
    }

//    override func prefersStatusBarHidden() -> Bool
//    {
//        return false
//    }
    
    func setupWKContentOffsets() {
        if (selectedSermon != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if document.wkWebView != nil {
                        var contentOffsetXRatio:Float = 0.0
                        var contentOffsetYRatio:Float = 0.0
                        
                        //        NSLog("\(sermonNotesWebView!.scrollView.contentSize)")
                        //        NSLog("\(sermonSlidesWebView!.scrollView.contentSize)")
                        
                        if let ratio = selectedSermon!.settings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
                            contentOffsetXRatio = Float(ratio)!
                        }
                        
                        if let ratio = selectedSermon!.settings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
                            contentOffsetYRatio = Float(ratio)!
                        }
                        
                        let contentOffset = CGPoint(
                            x: CGFloat(contentOffsetXRatio) * document.wkWebView!.scrollView.contentSize.width,
                            y: CGFloat(contentOffsetYRatio) * document.wkWebView!.scrollView.contentSize.height)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            document.wkWebView!.scrollView.setContentOffset(contentOffset, animated: false)
                        })
                    }
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        setupSplitViewController()
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

            self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.none)
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                self.setupWKContentOffsets()
        }

        if (self.splitViewController != nil) {
            let (oldMinConstraintConstant,oldMaxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)
            let (newMinConstraintConstant,newMaxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(size.height)
            
            switch self.sermonNotesAndSlidesConstraint.constant {
            case oldMinConstraintConstant:
                self.sermonNotesAndSlidesConstraint.constant = newMinConstraintConstant
                break
                
            case oldMaxConstraintConstant:
                self.sermonNotesAndSlidesConstraint.constant = newMaxConstraintConstant
                break
                
            default:
                let ratio = (sermonNotesAndSlidesConstraint.constant - oldMinConstraintConstant) / (oldMaxConstraintConstant - oldMinConstraintConstant)
                
                self.sermonNotesAndSlidesConstraint.constant = (ratio * (newMaxConstraintConstant - newMinConstraintConstant)) + newMinConstraintConstant
                
                if self.sermonNotesAndSlidesConstraint.constant < newMinConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = newMinConstraintConstant }
                if self.sermonNotesAndSlidesConstraint.constant > newMaxConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = newMaxConstraintConstant }
                break
            }
            
            //            NSLog("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
            
            splitView.min = newMinConstraintConstant
            splitView.max = newMaxConstraintConstant
            splitView.height = sermonNotesAndSlidesConstraint.constant
            
            self.view.setNeedsLayout()
        } else {
            if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
                //If we started out in landscape on an iPhone and segued to this view and then transitioned to Portrait
                //The constraint is not setup because it is not active in landscape so we have to set it up
                if let viewSplit = selectedSermon?.viewSplit {
                    var newConstraintConstant = size.height * CGFloat(Float(viewSplit)!)
                    
                    let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(size.height - 12) //Adjustment of 12 for difference in NavBar height between landscape (shorter) and portrait (taller by 12)
                    
                    //                    NSLog("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
                    
                    if newConstraintConstant < minConstraintConstant { newConstraintConstant = minConstraintConstant }
                    if newConstraintConstant > maxConstraintConstant { newConstraintConstant = maxConstraintConstant }
                    
                    self.sermonNotesAndSlidesConstraint.constant = newConstraintConstant
                    
                    //                    NSLog("\(viewSplit) \(size) \(sermonNotesAndSlidesConstraint.constant)")
                    
                    splitView.min = minConstraintConstant
                    splitView.max = maxConstraintConstant
                    splitView.height = self.sermonNotesAndSlidesConstraint.constant
                    
                    self.view.setNeedsLayout()
                }
            } else {
                //Capturing the viewSplit on a rotation from portrait to landscape for an iPhone
                captureViewSplit()
            }
        }
    }

    
    func ratioForSplitView(_ sender: SplitView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if (selectedSermon != nil) {
            if let viewSplit = selectedSermon?.viewSplit {
                ratio = CGFloat(Float(viewSplit)!)
            }
        }
//        NSLog("ratio: '\(ratio)")
        return ratio
    }
    
    
    func resetConstraint()
    {
        var newConstraintConstant:CGFloat
        
        //        NSLog("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        newConstraintConstant = minConstraintConstant + tableView.rowHeight * (sermonsInSeries!.count > 1 ? 2 : 1)
        
        if newConstraintConstant > ((maxConstraintConstant+minConstraintConstant)/2) {
            newConstraintConstant = (maxConstraintConstant+minConstraintConstant)/2
        }
        
        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.sermonNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        
        splitView.min = minConstraintConstant
        splitView.max = maxConstraintConstant
        splitView.height = self.sermonNotesAndSlidesConstraint.constant
        
        captureViewSplit()
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupViewSplit()
    {
        var newConstraintConstant:CGFloat
        
//        NSLog("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(splitView) {
//            NSLog("\(self.view.bounds.height)")
            newConstraintConstant = self.view.bounds.height * ratio
        } else {
            let numberOfAdditionalRows = CGFloat(sermonsInSeries != nil ? sermonsInSeries!.count : 0)
            newConstraintConstant = minConstraintConstant + tableView.rowHeight * numberOfAdditionalRows
            
            if newConstraintConstant > ((maxConstraintConstant+minConstraintConstant)/2) {
                newConstraintConstant = (maxConstraintConstant+minConstraintConstant)/2
            }
        }

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.sermonNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.sermonNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }

        splitView.min = minConstraintConstant
        splitView.max = maxConstraintConstant
        splitView.height = self.sermonNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupTitle()
    {
        if (selectedSermon != nil) {
            if (selectedSermon!.hasSeries) {
                //The selected sermon is in a series so set the title.
                self.navigationItem.title = selectedSermon?.series
            } else {
                self.navigationItem.title = selectedSermon?.title
            }
        } else {
            self.navigationItem.title = nil
        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        if (selectedSermon != nil) {
            if (selectedSermon!.hasVideo) {
                audioOrVideoControl.isEnabled = true
                audioOrVideoControl.isHidden = false
                audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
                view.setNeedsLayout()

                audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AUDIO_SEGMENT_INDEX)
                audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.VIDEO_SEGMENT_INDEX)
                
//                print(selectedSermon!.playing!)
                
                switch selectedSermon!.playing! {
                case Playing.audio:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AUDIO_SEGMENT_INDEX
                    break
                    
                case Playing.video:
                    audioOrVideoControl.selectedSegmentIndex = Constants.VIDEO_SEGMENT_INDEX
                    break
                    
                default:
                    break
                }

                let attr = [NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_ICONS_FONT_SIZE)!]
                
                audioOrVideoControl.setTitleTextAttributes(attr, for: UIControlState())
                
                audioOrVideoControl.setTitle(Constants.FA_AUDIO, forSegmentAt: Constants.AUDIO_SEGMENT_INDEX) // Audio

                audioOrVideoControl.setTitle(Constants.FA_VIDEO, forSegmentAt: Constants.VIDEO_SEGMENT_INDEX) // Video
            } else {
                audioOrVideoControl.isEnabled = false
                audioOrVideoControl.isHidden = true
                audioOrVideoWidthConstraint.constant = 0
                view.setNeedsLayout()
            }
        } else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
        }
    }
    
    func updateUI()
    {
        setupPlayerView(globals.player.mpPlayer?.view)
        
        if (selectedSermon == globals.player.playing) && ((globals.player.mpPlayer?.contentURL != selectedSermon?.videoURL) && (globals.player.mpPlayer?.contentURL != selectedSermon?.audioURL)) {
            globals.player.mpPlayer?.stop()
            globals.player.mpPlayer = nil
            
            if (selectedSermon != nil) {
                globals.player.playOnLoad = false
                globals.setupPlayer(selectedSermon)
            }
        }

        //        NSLog("viewWillAppear 1 sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
        //        NSLog("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        // This next line is for the case when video is playing and the video has been zoomed to full screen and that makes the embedded controls visible
        // allowing the user to control playback, pausing or stopping, and then unzooming makes the play pause button vislble and it has to be
        // updated according to the player state, which may have changed.
        if (globals.player.mpPlayer?.contentURL != URL(string:Constants.LIVE_STREAM_URL)) {
            globals.player.paused = (globals.player.mpPlayer?.playbackState == .paused) || (globals.player.mpPlayer?.playbackState == .stopped)
        }
        
//        if (selectedSermon != nil) && (globals.player.mpPlayer == nil) {
//            setupPlayerAtEnd(selectedSermon)
//        }
        
        setupViewSplit()
        
        //        NSLog("viewWillAppear 2 sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
        //        NSLog("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the sermon selected is playing already
        addSliderObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSlider()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (splitViewController != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.UPDATE_VIEW_NOTIFICATION), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.CLEAR_VIEW_NOTIFICATION), object: nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION), object: nil)

//        tableView.reloadData()

        updateUI()
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        NSLog("viewDidAppear sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
//        NSLog("viewDidAppear tableView.bounds: \(tableView.bounds)")

        setupSplitViewController()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.none)
            })
        })

//        updateUI()
    }
    
    fileprivate func captureViewSplit()
    {
//        NSLog("captureViewSplit: \(sermonSelected?.title)")
        
        if (self.view != nil) && (splitView.bounds.size.width > 0) {
            if (selectedSermon != nil) {
//                NSLog("\(self.view.bounds.height)")
                let ratio = self.sermonNotesAndSlidesConstraint.constant / self.view.bounds.height
                
                //            NSLog("captureViewSplit ratio: \(ratio)")
                
                selectedSermon?.viewSplit = "\(ratio)"
            }
        }
    }
    
    fileprivate func captureContentOffset(_ document:Document)
    {
        selectedSermon?.settings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.x / document.wkWebView!.scrollView.contentSize.width)"
        selectedSermon?.settings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.y / document.wkWebView!.scrollView.contentSize.height)"
    }
    
    fileprivate func captureContentOffset(_ webView:WKWebView?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (webView != nil) && (!webView!.isLoading) && (webView!.url != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if webView == document.wkWebView {
                        captureContentOffset(document)
                    }
                }
            }
        }
    }
    
    fileprivate func captureZoomScale(_ document:Document)
    {
        selectedSermon?.settings?[document.purpose! + Constants.ZOOM_SCALE] = "\(document.wkWebView!.scrollView.zoomScale)"
    }
    
    fileprivate func captureZoomScale(_ webView:WKWebView?)
    {
        //        NSLog("captureZoomScale: \(sermonSelected?.title)")
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (webView != nil) && (!webView!.isLoading) && (webView!.url != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if webView == document.wkWebView {
                        captureZoomScale(document)
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
        
        // Remove these lines and this view will crash the app.
        for key in documents.keys {
            for document in documents[key]!.values {
                document.wkWebView?.removeFromSuperview()
                document.wkWebView?.scrollView.delegate = nil
                
                if document.visible(selectedSermon) && (document.wkWebView != nil) && document.wkWebView!.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }

        NotificationCenter.default.removeObserver(self)
        
        sliderObserver?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSLog("didReceiveMemoryWarning: \(selectedSermon?.title)")
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
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

        if let wvc = destination as? WebViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case Constants.SHOW_FULL_SCREEN_SEGUE:
                    splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden
                    setupWKContentOffsets()
                    wvc.selectedSermon = sender as? Sermon
//                    wvc.showScripture = showScripture
                    break
                default:
                    break
                }
            }
        }
    }

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return selectedSermon != nil ? (sermonsInSeries != nil ? sermonsInSeries!.count : 0) : 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SERMONS_IN_SERIES_CELL_IDENTIFIER, for: indexPath) as! MediaTableViewCell
    
        cell.sermon = sermonsInSeries?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    

    fileprivate func setTimes(timeNow:Float, length:Float)
    {
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Float(elapsedHours) * 60*60)) / 60)
        let elapsedSec = Int(timeNow.truncatingRemainder(dividingBy: 60))
        
        var elapsed:String
        
        if (elapsedHours > 0) {
            elapsed = "\(String(format: "%d",elapsedHours)):"
        } else {
            elapsed = Constants.EMPTY_STRING
        }
        
        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = elapsed
        
        let timeRemaining = length - timeNow
        let remainingHours = Int(timeRemaining / (60*60))
        let remainingMins = Int((timeRemaining - (Float(remainingHours) * 60*60)) / 60)
        let remainingSec = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
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
        assert(globals.player.mpPlayer != nil,"globals.player.mpPlayer should not be nil if we're updating the slider to the audio")
   
        if (globals.player.mpPlayer != nil) {
            let length = Float(globals.player.mpPlayer!.duration)
            
            //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
            
            var timeNow:Float = 0.0
            var progress:Float = 0.0

//            NSLog("currentTime",selectedSermon?.currentTime)
//            NSLog("timeNow",timeNow)
//            NSLog("length",length)
//            NSLog("progress",progress)
            
            if (length > 0) {
                switch globals.player.mpPlayer!.playbackState {
                case .playing:
                    if (globals.player.mpPlayer!.currentPlaybackTime >= 0) && (globals.player.mpPlayer!.currentPlaybackTime <= globals.player.mpPlayer!.duration) {
                        timeNow = Float(globals.player.mpPlayer!.currentPlaybackTime)
                        
                        progress = timeNow / length
                        
//                        NSLog("playing")
//                        NSLog("slider.value",slider.value)
//                        NSLog("progress",progress)
//                        NSLog("length",length)
                        
                        if (Int(slider.value*100) != Int(progress*100)) {
                            timeNow = Float(selectedSermon!.currentTime!)!
                            progress = timeNow / length
                        }

                        slider.value = progress
                        setTimes(timeNow: timeNow,length: length)
                    }
                    break
                    
                case .paused:
                    if selectedSermon?.currentTime != timeNow.description {
                        timeNow = Float(selectedSermon!.currentTime!)!
                        progress = timeNow / length

//                        NSLog("paused")
//                        NSLog("timeNow",timeNow)
//                        NSLog("progress",progress)
//                        NSLog("length",length)
                        
                        slider.value = progress
                        setTimes(timeNow: timeNow,length: length)
                    }
                    break
                    
                case .stopped:
                    if selectedSermon?.currentTime != timeNow.description {
                        timeNow = Float(selectedSermon!.currentTime!)!
                        progress = timeNow / length
                        
//                        NSLog("stopped")
//                        NSLog("timeNow",timeNow)
//                        NSLog("progress",progress)
//                        NSLog("length",length)
                        
                        slider.value = progress
                        setTimes(timeNow: timeNow,length: length)
                    }
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    fileprivate func setTimesToSlider() {
        assert(globals.player.mpPlayer != nil,"globals.player.mpPlayer should not be nil if we're updating the times to the slider, i.e. the slider is showing")
        
        if (globals.player.mpPlayer != nil) {
            let length = Float(globals.player.mpPlayer!.duration)
            
            let timeNow = self.slider.value * length
            
            setTimes(timeNow: timeNow,length: length)
        }
    }
    
    fileprivate func setupSlider() {
        if spinner.isAnimating {
            spinner.stopAnimating()
            spinner.isHidden = true
        }
        
        slider.isEnabled = globals.player.loaded
        
        if (globals.player.mpPlayer != nil) && (globals.player.playing != nil) {
            if (globals.player.playing == selectedSermon) {
                setTimes(timeNow: 0,length: 0)
                slider.value = 0

                elapsed.isHidden = false
                remaining.isHidden = false
                
                slider.isHidden = false

                setSliderAndTimesToAudio()
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

    func sliderTimer()
    {
        if (selectedSermon != nil) && (selectedSermon == globals.player.playing) {
            let loadstate:UInt8 = UInt8(globals.player.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.playthroughOK.rawValue)) > 0
            
            if playable {
                NSLog("sliderTimer.MPMovieLoadState.Playable")
            }
            
            if playthrough {
                NSLog("sliderTimer.MPMovieLoadState.Playthrough")
            }
            
            playPauseButton.isEnabled = globals.player.loaded || globals.player.loadFailed
            slider.isEnabled = globals.player.loaded
            
            if (!globals.player.loaded) {
                if (!spinner.isAnimating) {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
            }
            
            switch globals.player.stateTime!.state {
            case .none:
//                NSLog("none")
                break
                
            case .playing:
//                NSLog("playing")
                switch globals.player.mpPlayer!.playbackState {
                case .seekingBackward:
//                    NSLog("sliderTimer.playing.SeekingBackward")
                    break
                    
                case .seekingForward:
//                    NSLog("sliderTimer.playing.SeekingForward")
                    break
                    
                default:
                    setSliderAndTimesToAudio()
                    
                    if !(playable || playthrough) { // globals.player.mpPlayer?.currentPlaybackRate == 0
//                        NSLog("sliderTimer.Playthrough or Playing NOT OK")
                        if !spinner.isAnimating {
                            spinner.isHidden = false
                            spinner.startAnimating()
                        }
                    }
                    if (playable || playthrough) {
//                        NSLog("sliderTimer.Playthrough or Playing OK")
                        if spinner.isAnimating {
                            spinner.stopAnimating()
                            spinner.isHidden = true
                        }
                    }
                    break
                }
                break
                
            case .paused:
//                NSLog("paused")
                
                if globals.player.loaded {
                    setSliderAndTimesToAudio()
                }
                
                if globals.player.loaded || globals.player.loadFailed{
                    if spinner.isAnimating {
                        spinner.stopAnimating()
                        spinner.isHidden = true
                    }
                }
                break
                
            case .stopped:
//                NSLog("stopped")
                break
                
            case .seekingForward:
//                NSLog("seekingForward")
                if !spinner.isAnimating {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
                break
                
            case .seekingBackward:
//                NSLog("seekingBackward")
                if !spinner.isAnimating {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
                break
            }
            
//            if (globals.player.mpPlayer != nil) {
//                switch globals.player.mpPlayer!.playbackState {
//                case .Interrupted:
//                    NSLog("sliderTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    NSLog("sliderTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    NSLog("sliderTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    NSLog("sliderTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    NSLog("sliderTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    NSLog("sliderTimer.Stopped")
//                    break
//                }
//            }
            
            //        NSLog("Duration: \(globals.player.mpPlayer!.duration) CurrentPlaybackTime: \(globals.player.mpPlayer!.currentPlaybackTime)")
            
            if (globals.player.mpPlayer!.duration > 0) && (globals.player.mpPlayer!.currentPlaybackTime > 0) &&
                (Int(Float(globals.player.mpPlayer!.currentPlaybackTime)) == Int(Float(globals.player.mpPlayer!.duration))) { //  (slider.value > 0.9999)
                if (UserDefaults.standard.bool(forKey: Constants.AUTO_ADVANCE)) {
                    advanceSermon()
                }
            }
        }
    }
    
    func advanceSermon()
    {
//        NSLog("\(globals.player.playing?.playing)")
        if (globals.player.playing?.playing == Playing.audio) {
            let sermons = sermonsInSermonSeries(globals.player.playing)
            if let index = sermons?.index(of: globals.player.playing!) {
                if index < (sermons!.count - 1) {
                    if let nextSermon = sermons?[index + 1] {
                        nextSermon.playing = Playing.audio
                        nextSermon.currentTime = Constants.ZERO
                        if (self.view.window != nil) && (sermons?.index(of: nextSermon) != nil) {
                            selectedSermon = nextSermon
                            updateUI()
                            scrollToSermon(nextSermon, select: true, position: UITableViewScrollPosition.none)
                        }
                        //            NSLog("\(selectedSermon)")
                        playNewSermon(nextSermon)
                    }
                } else {
                    globals.player.paused = true
                    setupPlayPauseButton()
                }
            }
        } else {
            globals.player.paused = true
            setupPlayPauseButton()
        }
    }
    
    func removeSliderObserver() {
        if (sliderObserver != nil) {
            sliderObserver!.invalidate()
            sliderObserver = nil
        }
    }

    func addSliderObserver()
    {
//        NSLog("addSliderObserver in")

        if (sliderObserver != nil) {
            sliderObserver?.invalidate()
            sliderObserver = nil
        }

        if (globals.player.mpPlayer != nil) {
            sliderObserver = Timer.scheduledTimer(timeInterval: Constants.SLIDER_TIMER_INTERVAL, target: self, selector: #selector(MediaViewController.sliderTimer), userInfo: nil, repeats: true)
        } else {
            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
            NSLog("globals.player == nil in sliderObserver")
            // Should we setup the player all over again?
        }

//        NSLog("addSliderObserver out")
    }
    
    fileprivate func networkUnavailable(_ message:String?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) { // && (self.view.window != nil) 
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func failedToLoad()
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            dismiss(animated: true, completion: nil)

            let alert = UIAlertController(title: Constants.Content_Failed_to_Load,
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func playNewSermon(_ sermon:Sermon?) {
        globals.updateCurrentTimeExact()
        globals.player.mpPlayer?.stop()
        
        globals.player.mpPlayer?.view.removeFromSuperview()
        
        if (sermon != nil) && (sermon!.hasVideo || sermon!.hasAudio) {
            globals.player.playing = sermon
            globals.player.paused = false
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            globals.player.playOnLoad = true
            globals.setupPlayer(sermon)
            
            if (sermon!.hasVideo && (sermon!.playing == Playing.video)) {
                setupPlayerView(globals.player.mpPlayer?.view)
                
                if (view.window != nil) {
                    globals.player.mpPlayer!.view.isHidden = false
                    sermonNotesAndSlides.bringSubview(toFront: globals.player.mpPlayer!.view!)
                }
                
                sermon!.showing = Showing.video
            }

            addSliderObserver()
            
            if (view.window != nil) {
                setupSTVControl()
                setupSlider()
                setupPlayPauseButton()
                setupActionAndTagsButtons()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAtIndexPath indexPath: IndexPath) {
//        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if (selectedSermon != nil) &&  (documents[selectedSermon!.id] != nil) {
            for document in documents[selectedSermon!.id]!.values {
                if document.visible(selectedSermon) && (document.wkWebView != nil) && document.wkWebView!.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }
        
        if (selectedSermon != sermonsInSeries![indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(sermonsInSeries![indexPath.row])
        }
        selectedSermon = sermonsInSeries![indexPath.row]

        if (selectedSermon == globals.player.playing) && (globals.player.mpPlayer?.contentURL == URL(string:Constants.LIVE_STREAM_URL)) {
            globals.player.mpPlayer?.stop()
            globals.player.mpPlayer = nil
            
            if (selectedSermon != nil) {
                globals.player.playOnLoad = false
                globals.setupPlayer(selectedSermon)
                
                if (selectedSermon!.hasVideo && (selectedSermon!.playing == Playing.video)) {
                    setupPlayerView(globals.player.mpPlayer?.view)
                }
            }
        }

        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSlider()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
    }
    
//    func webView(_ wkWebView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        
//        if (navigationAction.request.url != nil) {
////            print(navigationAction.request.URL!.absoluteString!)
//            decisionHandler(WKNavigationActionPolicy.allow)
//
////            if (navigationAction.request.URL!.absoluteString!.endIndex < Constants.BASE_PDF_URL.endIndex) {
////                decisionHandler(WKNavigationActionPolicy.Cancel)
////            } else {
////                if (navigationAction.request.URL!.absoluteString!.substringToIndex(Constants.BASE_PDF_URL.endIndex) == Constants.BASE_PDF_URL) {
////                    decisionHandler(WKNavigationActionPolicy.Allow)
////                } else {
////                    if (navigationAction.request.URL!.path!.substringToIndex(cachesURL()!.path!.endIndex) == cachesURL()!.path!) {
////                        decisionHandler(WKNavigationActionPolicy.Allow)
////                    } else {
////                        decisionHandler(WKNavigationActionPolicy.Cancel)
////                    }
////                }
////            }
//        } else {
//            decisionHandler(WKNavigationActionPolicy.cancel)
//        }
//    }
    
    func webView(_ webView: WKWebView, didFail didFailNavigation: WKNavigation!, withError: Error) {
        NSLog("wkDidFailNavigation")
//        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
//        }

        webView.isHidden = true
        if (selectedSermon != nil) && (documents[selectedSermon!.id] != nil) {
            for document in documents[selectedSermon!.id]!.values {
                if (webView == document.wkWebView) {
                    document.wkWebView?.scrollView.delegate = nil
                    document.wkWebView = nil
                    if document.visible(selectedSermon) {
                        activityIndicator.stopAnimating()
                        activityIndicator.isHidden = true
                        
                        progressIndicator.isHidden = true
                        
                        logo.isHidden = !shouldShowLogo() // && roomForLogo()
                        
                        if (!logo.isHidden) {
                            sermonNotesAndSlides.bringSubview(toFront: self.logo)
                        }
                        
                        networkUnavailable(withError.localizedDescription)
                    }
                }
            }
        }

        // Keep trying
//        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
//    func webView(_ webView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
////        print(webView.URL)
//        NSLog("wkDidFailProvisionalNavigation")
//        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
////            stvControl.hidden = true
//            
//            webView.isHidden = true
////            globals.player.mpPlayer?.view.hidden = true
//            
//            if (selectedSermon != nil) && (documents[selectedSermon!.id] != nil) {
//                for document in documents[selectedSermon!.id]!.values {
//                    if (webView == document.wkWebView) {
//                        document.wkWebView?.scrollView.delegate = nil
//                        document.wkWebView = nil
//                        if document.visible(selectedSermon) {
//                            activityIndicator.stopAnimating()
//                            activityIndicator.isHidden = true
//
//                            progressIndicator.isHidden = true
//                            
//                            logo.isHidden = !shouldShowLogo() // && roomForLogo()
//                            
//                            if (!logo.isHidden) {
//                                sermonNotesAndSlides.bringSubview(toFront: self.logo)
//                            }
//                            
////                            networkUnavailable(withError.localizedDescription)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func webView(_ wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
//        NSLog("wkDidStartProvisionalNavigation")

    }
    
    func wkSetZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        NSLog("scale: \(scale)")
//        NSLog("offset: \(offset)")

        DispatchQueue.main.async(execute: { () -> Void in
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        })

//        NSLog("contentOffset after: \(wkWebView.scrollView.contentOffset)")
    }
    
    func setDocumentContentOffsetAndZoomScale(_ document:Document?)
    {
//        NSLog("setNotesContentOffsetAndZoomScale Loading: \(sermonNotesWebView!.loading)")

        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        if let ratioStr = selectedSermon?.settings?[document!.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
//            NSLog("X ratio string: \(ratio)")
            contentOffsetXRatio = Float(ratioStr)!
        } else {
//            NSLog("No notes X ratio")
        }
        
        if let ratioStr = selectedSermon?.settings?[document!.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
//            NSLog("Y ratio string: \(ratio)")
            contentOffsetYRatio = Float(ratioStr)!
        } else {
//            NSLog("No notes Y ratio")
        }
        
        if let zoomScaleStr = selectedSermon?.settings?[document!.purpose! + Constants.ZOOM_SCALE] {
            zoomScale = CGFloat(Float(zoomScaleStr)!)
        } else {
//            NSLog("No notes zoomScale")
        }
        
//        NSLog("\(notesContentOffsetXRatio)")
//        NSLog("\(sermonNotesWebView!.scrollView.contentSize.width)")
//        NSLog("\(notesZoomScale)")
        
        let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio) * document!.wkWebView!.scrollView.contentSize.width * zoomScale,
                                        y: CGFloat(contentOffsetYRatio) * document!.wkWebView!.scrollView.contentSize.height * zoomScale)
        
        wkSetZoomScaleThenContentOffset(document!.wkWebView!, scale: zoomScale, offset: contentOffset)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        NSLog("wkWebViewDidFinishNavigation Loading:\(webView.loading)")
        
//        NSLog("Frame: \(webView.frame)")
//        NSLog("Bounds: \(webView.bounds)")

        if (self.view != nil) {
            if (selectedSermon != nil) {
                if (documents[selectedSermon!.id] != nil) {
                    for document in documents[selectedSermon!.id]!.values {
                        if (webView == document.wkWebView) {
    //                        NSLog("sermonNotesWebView")
                            if document.visible(selectedSermon) {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.isHidden = true
                                    
                                    self.progressIndicator.isHidden = true
                                    
                                    self.setupSTVControl()
                                    
//                                    NSLog("webView:hidden=panning")
                                    webView.isHidden = self.panning
                                })
                            } else {
                                DispatchQueue.main.async(execute: { () -> Void in
//                                    NSLog("webView:hidden=true")
                                    webView.isHidden = true
                                })
                            }
                            DispatchQueue.main.async(execute: { () -> Void in
                                document.loadTimer?.invalidate()
                                document.loadTimer = nil
                            })
                            setDocumentContentOffsetAndZoomScale(document)
                        }
                    }
                }
            }
        }
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
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
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
}
