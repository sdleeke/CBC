//
//  MyViewController.swift
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
import Social

class Document {
    var sermon:Sermon?
    
    var purpose:String?
    
    var download:Download? {
        get {
            var download:Download?
            
            switch purpose! {
            case Constants.NOTES:
                download = sermon?.notesDownload
                
            case Constants.SLIDES:
                download = sermon?.slidesDownload
                
            default:
                break
            }
            
            return download
        }
    }
    
    var wkWebView:WKWebView?
    
    var loadTimer:NSTimer?
    
    init(purpose:String,sermon:Sermon?)
    {
        self.purpose = purpose
        self.sermon = sermon
    }
}

class MyViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    var panning = false
    
    var sliderObserver:NSTimer?
    
    var showScripture = false
    
    var documents = [String:[String:Document]]()
    
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
    
    override func canBecomeFirstResponder() -> Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            setupPlayPauseButton()
        }
    }
    
    var selectedSermon:Sermon? {
        didSet {
            if oldValue != nil {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: oldValue)
            }
            
            notesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            slidesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            
            if (selectedSermon != nil) {
                if (selectedSermon!.hasNotes()) {
                    notesDocument = documents[selectedSermon!.id]?[Constants.NOTES]
                    
                    if (notesDocument == nil) {
                        notesDocument = Document(purpose: Constants.NOTES, sermon: selectedSermon)
                    }
                }
                
                if (selectedSermon!.hasSlides()) {
                    slidesDocument = documents[selectedSermon!.id]?[Constants.SLIDES]
                    
                    if (slidesDocument == nil) {
                        slidesDocument = Document(purpose: Constants.SLIDES, sermon: selectedSermon)
                    }
                }

                sermonsInSeries = selectedSermon?.sermonsInSeries // sermonsInSermonSeries(selectedSermon)
                
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
                defaults.synchronize()
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.setupActionAndTagsButtons), name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: selectedSermon)
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                sermonsInSeries = nil
                for key in documents.keys {
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
        switch sender.selectedSegmentIndex {
        case Constants.AUDIO_SEGMENT_INDEX:
            switch selectedSermon!.playing! {
            case Constants.AUDIO:
                //Do nothing, already selected
                break
                
            case Constants.VIDEO:
                if (Globals.sermonPlaying == selectedSermon) {
                    updateCurrentTimeExact()
                    
                    Globals.mpPlayer?.view.hidden = true
                    Globals.mpPlayer?.stop()
                    
                    Globals.playerPaused = true

                    // Because there is a sermon selected but we've STOPPED so there isn't one playing.
                    Globals.sermonPlaying = nil
                    
                    spinner.stopAnimating()
                    spinner.hidden = true
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSlider()
                }
                
                // We need to do this whether the sermon was playing or not
//                captureContentOffsetAndZoomScale()
                
                selectedSermon?.playing = Constants.AUDIO // Must come before setupNoteAndSlides()
                setupNotesSlidesVideo() // Calls setupSTVControl()
                break
                
            default:
                break
            }
            break
            
        case Constants.VIDEO_SEGMENT_INDEX:
            switch selectedSermon!.playing! {
            case Constants.AUDIO:
                if (Globals.sermonPlaying == selectedSermon) {
                    updateCurrentTimeExact()
                    
                    Globals.mpPlayer?.stop()
                    
                    Globals.playerPaused = true
                    
                    // Because there is a sermon selected but we've STOPPED so there isn't one playing.
                    Globals.sermonPlaying = nil
                    
                    spinner.stopAnimating()
                    spinner.hidden = true
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSlider()
                }
                
                // We need to do this whether the sermon was playing or not
//                captureContentOffsetAndZoomScale()
                
                selectedSermon?.playing = Constants.VIDEO // Must come before setupNoteAndSlides()
                setupNotesSlidesVideo() // Calls setupSTVControl()
                break
                
            case Constants.VIDEO:
                //Do nothing, already selected
                break
                
            default:
                break
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
    @IBAction func stvAction(sender: UISegmentedControl)
    {
        // This assumes this action isn't called unless an unselected segment is changed.  Otherwise touching the selected segment would cause it to flip to itself.
        
        var view:UIView?
        
        switch selectedSermon!.showing! {
        case Constants.SLIDES:
            view = documents[selectedSermon!.id]?[selectedSermon!.showing!]?.wkWebView
            break
            
        case Constants.NOTES:
            view = documents[selectedSermon!.id]?[selectedSermon!.showing!]?.wkWebView
            break
            
        case Constants.VIDEO:
            view = Globals.mpPlayer?.view
            break
            
        default:
            break
            
        }
        
//        captureContentOffsetAndZoomScale()

        let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
        
        var toView:UIView?
        
        var purpose:String?

        switch sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)! {
        case Constants.FA_SLIDES_SEGMENT_TITLE:
            purpose = Constants.SLIDES
            toView = documents[selectedSermon!.id]?[purpose!]?.wkWebView
            break

        case Constants.FA_TRANSCRIPT_SEGMENT_TITLE:
            purpose = Constants.NOTES
            toView = documents[selectedSermon!.id]?[purpose!]?.wkWebView
            break
        
        case Constants.FA_VIDEO_SEGMENT_TITLE:
            toView = Globals.mpPlayer?.view
            purpose = Constants.VIDEO
            break
        
        default:
            break
        }

        if (toView != nil) {
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
                if (toView != nil) {
                    toView?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(toView!)
                    self.selectedSermon!.showing = purpose
                } else {
                    self.logo?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.logo!)
                    self.selectedSermon!.showing = Constants.NONE
                }
                
                }, completion: { finished in
                    view?.hidden = true
            })
        }
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
            stvControl.setTitleTextAttributes(attr, forState: .Normal)
            
            // This order: Transcript (aka Notes), Slides, Video matches the CBC web site.
            
            if (selectedSermon!.hasNotes()) {
                stvControl.insertSegmentWithTitle(Constants.FA_TRANSCRIPT_SEGMENT_TITLE, atIndex: index, animated: false)
                notesIndex = index
                index += 1
            }
            if (selectedSermon!.hasSlides()) {
                stvControl.insertSegmentWithTitle(Constants.FA_SLIDES_SEGMENT_TITLE, atIndex: index, animated: false)
                slidesIndex = index
                index += 1
            }
            if (selectedSermon!.hasVideo() && (Globals.sermonPlaying == selectedSermon) && (selectedSermon?.playing == Constants.VIDEO)) {
                stvControl.insertSegmentWithTitle(Constants.FA_VIDEO_SEGMENT_TITLE, atIndex: index, animated: false)
                videoIndex = index
                index += 1
            }
            
            stvWidthConstraint.constant = Constants.MIN_STV_SEGMENT_WIDTH * CGFloat(index)
            view.setNeedsLayout()

            switch selectedSermon!.showing! {
            case Constants.SLIDES:
                stvControl.selectedSegmentIndex = slidesIndex
                break
                
            case Constants.NOTES:
                stvControl.selectedSegmentIndex = notesIndex
                break
                
            case Constants.VIDEO:
                stvControl.selectedSegmentIndex = videoIndex
                break
                
            case Constants.NONE:
                fallthrough
                
            default:
                break
            }

            if (stvControl.numberOfSegments < 2) {
                stvControl.enabled = false
                stvControl.hidden = true
                stvWidthConstraint.constant = 0
                view.setNeedsLayout()
            } else {
                stvControl.enabled = true
                stvControl.hidden = false
            }
        } else {
            stvControl.enabled = false
            stvControl.hidden = true
            stvWidthConstraint.constant = 0
            view.setNeedsLayout()
        }
    }

    @IBAction func playPause(sender: UIButton) {
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
            switch Globals.mpPlayerStateTime!.state {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
                setupPlayPauseButton()
                break
                
            case .paused:
//                print("paused")
                let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
                
                let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
                let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
                
//                if playable && debug {
//                    print("playTimer.MPMovieLoadState.Playable")
//                }
//
//                if playthrough && debug {
//                    print("playTimer.MPMovieLoadState.Playthrough")
//                }
//
                
                if (playable || playthrough) {
//                    print("playPause.MPMovieLoadState.Playable or Playthrough OK")
                    Globals.playerPaused = false
                    
                    if (Globals.mpPlayer?.contentURL == selectedSermon?.playingURL) {
                        if selectedSermon!.hasCurrentTime() {
                            //Make the comparision an Int to avoid missing minor differences
                            if (Globals.mpPlayer!.duration >= 0) && (Int(Float(Globals.mpPlayer!.duration)) == Int(Float(selectedSermon!.currentTime!)!)) {
                                Globals.sermonPlaying!.currentTime = Constants.ZERO
                                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                            }
                            if (Globals.mpPlayer!.currentPlaybackTime >= 0) && (Int(Globals.mpPlayer!.currentPlaybackTime) != Int(Float(selectedSermon!.currentTime!)!)) {
                                // This happens on the first play after load and the correction below is requried.
                                
                                print("currentPlayBackTime: \(Globals.mpPlayer!.currentPlaybackTime) != currentTime: \(selectedSermon!.currentTime!)")
                                
                                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)

                                // This should show that it has been corrected.  Otherwise the video (I've not seen it happen on audio) starts 1-3 seconds earlier than expected.
                                print("currentPlayBackTime: \(Globals.mpPlayer!.currentPlaybackTime) currentTime: \(selectedSermon!.currentTime!)")
                            }
                        } else {
                            Globals.sermonPlaying!.currentTime = Constants.ZERO
                            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                        }
                        
                        if (Globals.mpPlayer?.currentPlaybackTime == 0) {
                            print("Globals.mpPlayer?.currentPlaybackTime == 0!")
                        }
                        
                        spinner.stopAnimating()
                        spinner.hidden = true
                        
                        Globals.mpPlayer?.play()
                        
                        setupPlayingInfoCenter()
                        setupPlayPauseButton()
                    } else {
                        playNewSermon(selectedSermon)
                    }
                } else {
//                    print("playPause.MPMovieLoadState.Playable or Playthrough NOT OK")
                    playNewSermon(selectedSermon)
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
                setupPlayPauseButton()
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
                setupPlayPauseButton()
                break
            }
        } else {
            playNewSermon(selectedSermon)
        }
    }
    
    private func sermonNotesAndSlidesConstraintMinMax(height:CGFloat) -> (min:CGFloat,max:CGFloat)
    {
        let minConstraintConstant:CGFloat = tableView.rowHeight*1 + slider.bounds.height + 16 //margin on top and bottom of slider
        
        let maxConstraintConstant:CGFloat = height - slider.bounds.height - navigationController!.navigationBar.bounds.height + 11 //  - logo.bounds.height
        
//        print("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
        
        return (minConstraintConstant,maxConstraintConstant)
    }

    private func roomForLogo() -> Bool
    {
        return splitView.height > (self.view.bounds.height - slider.bounds.height - navigationController!.navigationBar.bounds.height - logo.bounds.height)
    }
    
    private func shouldShowLogo() -> Bool
    {
        var result = (selectedSermon == nil)

        if (selectedSermon != nil) && (selectedSermon!.showing != nil) && (documents[selectedSermon!.id] != nil) && (documents[selectedSermon!.id]![selectedSermon!.showing!] != nil) {
            let wkWebView = documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView
            result = ((wkWebView == nil) || (wkWebView!.hidden == true)) && progressIndicator.hidden
        } else {
            if (selectedSermon?.showing == Constants.VIDEO) {
                result = false
            }
            if (selectedSermon?.showing == Constants.NONE) {
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
                if (wkWebView != nil) && (wkWebView!.hidden == true) {
                    hiddenCount += 1
                }
            }
            
            if (nilCount == documents[selectedSermon!.id]!.keys.count) {
                result = true
            } else {
                if (hiddenCount > 0) {
                    result = progressIndicator.hidden
                }
            }
        }

        return result
    }

    //        if selectedSermon != nil {
    //            switch selectedSermon!.showing! {
    //            case Constants.VIDEO:
    //                result = false
    //                break
    //
    //            case Constants.NOTES:
    //                result = ((sermonNotesWebView == nil) || (sermonNotesWebView!.hidden == true)) && progressIndicator.hidden
    //                break
    //
    //            case Constants.SLIDES:
    //                result = ((sermonSlidesWebView == nil) || (sermonSlidesWebView!.hidden == true)) && progressIndicator.hidden
    //                break
    //
    //            case Constants.NONE:
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
    
    private func setSermonNotesAndSlidesConstraint(change:CGFloat)
    {
        let newConstraintConstant = sermonNotesAndSlidesConstraint.constant + change
        
        //            print("pan rowHeight: \(tableView.rowHeight)")
        
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
        
        logo.hidden = !shouldShowLogo() //&& roomForLogo()
    }
    
    
    @IBAction func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            for key in documents[selectedSermon!.id]!.keys {
                let wkWebView = documents[selectedSermon!.id]![key]?.wkWebView
                
                wkWebView?.hidden = true
                wkWebView?.scrollView.delegate = nil
            }

            panning = true
            break
            
        case .Ended:
            captureViewSplit()

            for key in documents[selectedSermon!.id]!.keys {
                let wkWebView = documents[selectedSermon!.id]![key]?.wkWebView
                
                wkWebView?.hidden = (wkWebView?.URL == nil)
                wkWebView?.scrollView.delegate = self
            }

            panning = false
            break
        
        case .Changed:
            let translation = gesture.translationInView(splitView)
            let change = -translation.y
            if change != 0 {
                gesture.setTranslation(CGPointZero, inView: splitView)
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
    
    private func adjustAudioAfterUserMovedSlider()
    {
        if (Globals.mpPlayer == nil) { //  && Reachability.isConnectedToNetwork()
            setupPlayer(selectedSermon)
        }
        
        if (Globals.mpPlayer != nil) {
            if (slider.value < 1.0) {
                let length = Float(Globals.mpPlayer!.duration)
                let seekToTime = Float(slider.value * Float(length))
                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(seekToTime)
                Globals.sermonPlaying?.currentTime = seekToTime.description
            } else {
                Globals.mpPlayer?.pause()
                Globals.playerPaused = true

                Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
                Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
            }
            
            setupPlayPauseButton()
            addSliderObserver()
        }
    }
    
    @IBAction func sliderTouchDown(sender: UISlider) {
        //        print("sliderTouchUpOutside")
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(sender: UISlider) {
//        print("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(sender: UISlider) {
//        print("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(sender: UISlider) {
        setTimesToSlider()
    }
    
    var actionButton:UIBarButtonItem?
    var tagsButton:UIBarButtonItem?

    func showSendMessageErrorAlert() {
        let sendMessageErrorAlert = UIAlertView(title: "Could Not Send a Message", message: "Your device could not send a text message.  Please check your configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMessageErrorAlert.show()
    }
    
    // MARK: MFMessageComposeViewControllerDelegate Method
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func message(sermon:Sermon?)
    {
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = nil
        messageComposeViewController.subject = "Recommendation"
        messageComposeViewController.body = setupBody(sermon)
        
        if MFMessageComposeViewController.canSendText() {
            self.presentViewController(messageComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: Constants.Okay)
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setupBody(sermon:Sermon?) -> String? {
        var bodyString:String?
        
        if (sermon != nil) {
            bodyString = "\"" + sermon!.title! + "\"" + " by " + sermon!.speaker! + " from " + Constants.CBC_LONG

            bodyString = bodyString! + "\n\nAudio: " + sermon!.audioURL!.absoluteString
            
            if sermon!.hasVideo() {
                bodyString = bodyString! + "\n\nVideo " + sermon!.videoURL!.absoluteString
            }
            
            if sermon!.hasSlides() {
                bodyString = bodyString! + "\n\nSlides: " + sermon!.slidesURL!.absoluteString
            }
            
            if sermon!.hasNotes() {
                bodyString = bodyString! + "\n\nTranscript " + sermon!.notesURL!.absoluteString
            }
        }
        
        return bodyString
    }
    
    func setupSermonBodyHTML(sermon:Sermon?) -> String? {
        var bodyString:String?
        
        if (sermon != nil) {
            bodyString = "\"" + sermon!.title! + "\"" + " by " + sermon!.speaker! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
            
            bodyString = bodyString! + " (<a href=\"" + sermon!.audioURL!.absoluteString + "\">Audio</a>)"
            
            if sermon!.hasVideo() {
                bodyString = bodyString! + " (<a href=\"" + sermon!.videoURL!.absoluteString + "\">Video</a>) "
            }

            if sermon!.hasSlides() {
                bodyString = bodyString! + " (<a href=\"" + sermon!.slidesURL!.absoluteString + "\">Slides</a>)"
            }
            
            if sermon!.hasNotes() {
                bodyString = bodyString! + " (<a href=\"" + sermon!.notesURL!.absoluteString + "\">Transcript</a>) "
            }
            
            bodyString = bodyString! + "<br/>"
        }
        
        return bodyString
    }
    
    func setupSermonSeriesBodyHTML(sermonsInSeries:[Sermon]?) -> String? {
        var bodyString:String?

        if let sermons = sermonsInSeries {
            if (sermons.count > 0) {
                bodyString = "\"\(sermons[0].series!)\" by \(sermons[0].speaker!)"
                bodyString = bodyString! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
                bodyString = bodyString! + "<br/>" + "<br/>"
                
                let sermonList = sermons.sort() {
                    if ($0.fullDate!.isEqualTo($1.fullDate!)) {
                        return $0.service < $1.service
                    } else {
                        return $0.fullDate!.isOlderThan($1.fullDate!)
                    }
                }
                
                for sermon in sermonList {
                    bodyString = bodyString! + sermon.title!
                    
                    bodyString = bodyString! + " (<a href=\"" + sermon.audioURL!.absoluteString + "\">Audio</a>)"
                    
                    if sermon.hasVideo() {
                        bodyString = bodyString! + " (<a href=\"" + sermon.videoURL!.absoluteString + "\">Video</a>) "
                    }
                    
                    if sermon.hasSlides() {
                        bodyString = bodyString! + " (<a href=\"" + sermon.slidesURL!.absoluteString + "\">Slides</a>)"
                    }
                    
                    if sermon.hasNotes() {
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
    
    func mailSermon(sermon:Sermon?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.SERMON_EMAIL_SUBJECT)

        if let bodyString = setupSermonBodyHTML(sermon) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }

        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func mailSermonSeries(sermons:[Sermon]?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.SERIES_EMAIL_SUBJECT)
        
        if let bodyString = setupSermonSeriesBodyHTML(sermons) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func printSermon(sermon:Sermon?)
    {
        if (UIPrintInteractionController.isPrintingAvailable() && (sermon != nil))
        {
            var printURL:NSURL?
            
            switch sermon!.showing! {
            case Constants.NOTES:
                printURL = sermon!.notesURL
                break
            case Constants.SLIDES:
                printURL = sermon!.slidesURL
                break
                
            default:
                break
            }
            
            if (printURL != nil) && UIPrintInteractionController.canPrintURL(printURL!) {
//                print("can print!")
                let pi = UIPrintInfo.printInfo()
                pi.outputType = UIPrintInfoOutputType.General
                pi.jobName = "Print";
                pi.orientation = UIPrintInfoOrientation.Portrait
                pi.duplex = UIPrintInfoDuplex.LongEdge
                
                let pic = UIPrintInteractionController.sharedPrintController()
                pic.printInfo = pi
                pic.showsPageRange = true
                
                //Never could get this to work:
//            pic?.printFormatter = webView?.viewPrintFormatter()
                
                pic.printingItem = printURL
                pic.presentFromBarButtonItem(navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    private func openSermonScripture(sermon:Sermon?)
    {
        var urlString = Constants.SCRIPTURE_URL_PREFIX + sermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX

        urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!

//        print("\(sermon!.scripture!)")
//        print("\(urlString)")
//        print("\(NSURL(string:urlString))")
        
        if let url = NSURL(string:urlString) {
            if (UIApplication.sharedApplication().canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.sharedApplication().openURL(url)
            } else {
                networkUnavailable("Unable to open scripture at: \(url)")
            }
        }
    }
    
    func twitter(sermon:Sermon?)
    {
        assert(sermon != nil, "can't tweet about a nil sermon")

        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            var bodyString = String()
            
            bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
            
            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText(bodyString)
            //                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
            //                print("\(str)")
            //                twitterSheet.addURL(NSURL(string:str))
            self.presentViewController(twitterSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }

//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
//                var bodyString = String()
//                
//                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
//                
//                let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
//                twitterSheet.setInitialText(bodyString)
////                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
////                print("\(str)")
////                twitterSheet.addURL(NSURL(string:str))
//                self.presentViewController(twitterSheet, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
//        } else {
//            networkUnavailable("Unable to reach the internet to tweet.")
//        }
    }
    
    func facebook(sermon:Sermon?)
    {
        assert(sermon != nil, "can't post about a nil sermon")

        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
            var bodyString = String()
            
            bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
            
            //So the user can paste the initialText into the post dialog/view
            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
            UIPasteboard.generalPasteboard().string = bodyString
            
            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            facebookSheet.setInitialText(bodyString)
            //                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
            //                print("\(str)")
            //                facebookSheet.addURL(NSURL(string: str))
            self.presentViewController(facebookSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }

//        if Reachability.isConnectedToNetwork() {
//            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//                var bodyString = String()
//                
//                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
//
//                //So the user can paste the initialText into the post dialog/view
//                //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
//                UIPasteboard.generalPasteboard().string = bodyString
//
//                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//                facebookSheet.setInitialText(bodyString)
////                let str = Constants.BASE_AUDIO_URL + sermon!.audio!
////                print("\(str)")
////                facebookSheet.addURL(NSURL(string: str))
//                self.presentViewController(facebookSheet, animated: true, completion: nil)
//            } else {
//                let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
//                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
//        } else {
//            networkUnavailable("Unable to reach the internet to post to Facebook.")
//        }
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
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
                
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
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
                if (selectedSermon!.hasVideo() && selectedSermon!.playingVideo() && selectedSermon!.showingVideo()) {
                    zoomScreen()
                }
                
                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    showScripture = false
                    performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: selectedSermon)
                }
                break
                
            case Constants.Open_in_Browser:
                var url:NSURL?
                
                switch selectedSermon!.showing! {
                case Constants.NOTES:
                    url = selectedSermon!.notesURL
                    break
                case Constants.SLIDES:
                    url = selectedSermon!.slidesURL
                    break
                    
                default:
                    break
                }
                
                if  url != nil {
                    if (UIApplication.sharedApplication().canOpenURL(url!)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.sharedApplication().openURL(url!)
                    } else {
                        networkUnavailable("Unable to open transcript in browser at: \(url)")
                    }
                }
                break
                
            case Constants.Scripture_Full_Screen:
                showScripture = true
                performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: selectedSermon)
                break
                
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
//                tableView.reloadData()
//                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Cancel_All_Downloads:
                for sermon in sermonsInSeries! {
                    sermon.audioDownload?.cancelDownload()
                }
//                tableView.reloadData()
//                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Delete_All_Downloads:
                for sermon in sermonsInSeries! {
                    sermon.audioDownload?.deleteDownload()
                }
//                tableView.reloadData()
//                scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                break
                
            case Constants.Email_Sermon:
                mailSermon(selectedSermon)
                break
                
            case Constants.Email_Series:
                mailSermonSeries(sermonsInSeries)
                break
                
            case Constants.Check_for_Update:
                if selectedSermon!.showingSlides() {
                    selectedSermon!.slidesDownload?.deleteDownload()
                }
                if selectedSermon!.showingNotes() {
                    selectedSermon!.notesDownload?.deleteDownload()
                }
                setupNotesSlidesVideo()
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
        dismissViewControllerAnimated(true, completion: nil)

        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = actionButton
                
                //                popover.navigationItem.title = "Show"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                if (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) || (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) {
                    actionMenu.append(Constants.Print)
                }

                if selectedSermon!.hasFavoritesTag() {
                    actionMenu.append(Constants.Remove_From_Favorites)
                } else {
                    actionMenu.append(Constants.Add_to_Favorites)
                }
                
                if sermonsInSeries?.count > 1 {
                    var favoriteSermons = 0
                    
                    for sermon in sermonsInSeries! {
                        if (sermon.hasFavoritesTag()) {
                            favoriteSermons += 1
                        }
                    }
                    switch favoriteSermons {
                    case 0:
                        actionMenu.append(Constants.Add_All_to_Favorites)
                        break
                        
                    case 1:
                        actionMenu.append(Constants.Add_All_to_Favorites)

                        if !selectedSermon!.hasFavoritesTag() {
                            actionMenu.append(Constants.Remove_All_From_Favorites)
                        }
                        break
                        
                    case sermonsInSeries!.count - 1:
                        if selectedSermon!.hasFavoritesTag() {
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
                
                if (selectedSermon!.hasVideo() && selectedSermon!.playingVideo() && selectedSermon!.showingVideo()) ||
                   (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    actionMenu.append(Constants.Full_Screen)
                }
                
                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    if Globals.cacheDownloads {
                        actionMenu.append(Constants.Check_for_Update)
                    }
                }
                
                if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
                    actionMenu.append(Constants.Open_in_Browser)
                }
                
                if (selectedSermon!.hasScripture() && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
                    actionMenu.append(Constants.Scripture_Full_Screen)
                }
                
                if (selectedSermon!.hasScripture() && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
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
                if (selectedSermon!.hasSeries()) {
                        actionMenu.append(Constants.Email_Series)
                }

                popover.strings = actionMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func zoomScreen()
    {
        //It works!  Problem was in Globals.mpPlayer?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
        //Thank you StackOverflow!

        Globals.mpPlayer?.setFullscreen(!Globals.mpPlayer!.fullscreen, animated: true)
    }
    
    private func setupPlayerView(view:UIView?)
    {
        if (view != nil) {
            view?.hidden = true
            view?.removeFromSuperview()
            
            view?.gestureRecognizers = nil
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(MyViewController.zoomScreen))
            tap.numberOfTapsRequired = 2
            view?.addGestureRecognizer(tap)
            
            view?.frame = sermonNotesAndSlides.bounds

            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(view!)
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(width)
            
            let height = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(height)
            
            sermonNotesAndSlides.setNeedsLayout()
        }
    }
    
    private func setupWKWebView(wkWebView:WKWebView?)
    {
        if (wkWebView != nil) {
            wkWebView?.multipleTouchEnabled = true
            
            wkWebView?.scrollView.scrollsToTop = false
            
            //        print("\(sermonNotesAndSlides.frame)")
            //        sermonNotesWebView?.UIDelegate = self
            
            wkWebView?.scrollView.delegate = self
            wkWebView?.navigationDelegate = self

            wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(wkWebView!)
            
            let centerXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerXNotes)
            
            let centerYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerYNotes)
            
            let widthXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthXNotes)
            
            let widthYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthYNotes)
            
            sermonNotesAndSlides.setNeedsLayout()
        }
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
//        print("scrollViewDidZoom")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        print("scrollViewDidScroll")
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
//        print("scrollViewDidEndZooming")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
            captureZoomScale(view)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
//        print("scrollViewDidEndDecelerating")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        //        print("scrollViewDidEndDragging")
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func updateView()
    {
        selectedSermon = Globals.selectedSermonDetail
        
        tableView.reloadData()
        scrollToSermon(selectedSermon, select: true, position: UITableViewScrollPosition.Top)
        
        updateUI()
    }
    
    func clearView()
    {
        selectedSermon = nil
        
        tableView.reloadData()
        
        updateUI()
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        addAccessoryEvents()
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        if (splitViewController != nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.updateView), name: Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.clearView), name: Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyViewController.setupPlayPauseButton), name: Constants.UPDATE_PLAY_PAUSE_NOTIFICATION, object: nil)
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MyViewController.resetConstraint))
        tap.numberOfTapsRequired = 2
        splitView?.addGestureRecognizer(tap)
        
        splitView.splitViewController = splitViewController

//        print("\(Globals.mpPlayer?.contentURL)")
//        print("\(Constants.LIVE_STREAM_URL)")
        if (selectedSermon == Globals.sermonPlaying) && (Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.mpPlayer?.stop()
            Globals.mpPlayer = nil
            
            Globals.playOnLoad = false
            
            setupPlayer(selectedSermon)
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
        
        if(Globals.sermonLoaded) {
            spinner.stopAnimating()
        }

        if (selectedSermon == nil) {
            //Will only happen on an iPad
            selectedSermon = Globals.selectedSermonDetail
        }
    }

    private func setupDefaultNotesAndSlides()
    {
        if (selectedSermon != nil) {
            splitView.hidden = false
            
            let hasNotes = selectedSermon!.hasNotes()
            let hasSlides = selectedSermon!.hasSlides()
            
            Globals.mpPlayer?.view.hidden = true
            
            if (!hasSlides && !hasNotes) {
                hideAllDocuments()
                
                logo.hidden = false
                selectedSermon!.showing = Constants.NONE
                sermonNotesAndSlides.bringSubviewToFront(logo)
            } else
            if (hasSlides && !hasNotes) {
                logo.hidden = true
                
                selectedSermon!.showing = Constants.SLIDES

                hideOtherDocuments()

                sermonNotesAndSlides.bringSubviewToFront(documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView!)
            } else
            if (!hasSlides && hasNotes) {
                logo.hidden = true
                
                selectedSermon!.showing = Constants.NOTES

                hideOtherDocuments()
                
                sermonNotesAndSlides.bringSubviewToFront(documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView!)
            } else
            if (hasSlides && hasNotes) {
                logo.hidden = true
                
                selectedSermon!.showing = Constants.SLIDES //This is an arbitrary choice

                hideOtherDocuments()
                
                sermonNotesAndSlides.bringSubviewToFront(documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView!)
            }
        }
    }
    
    func downloading(timer:NSTimer?)
    {
        let document = timer?.userInfo as? Document
        
        if (selectedSermon != nil) {
            if (document?.download != nil) {
                print("totalBytesWritten: \(document!.download!.totalBytesWritten)")
                print("totalBytesExpectedToWrite: \(document!.download!.totalBytesExpectedToWrite)")
                
                switch document!.download!.state {
                case .none:
                    print(".none")
                    document?.download?.task?.cancel()
                    
                    document?.loadTimer?.invalidate()
                    document?.loadTimer = nil
                    
                    if (selectedSermon == document?.sermon) && (selectedSermon?.showing == document?.purpose) {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.hidden = true
                        
                        self.progressIndicator.hidden = true
                        
                        document?.wkWebView?.hidden = true
                        
                        Globals.mpPlayer?.view.hidden = true
                        
                        self.logo.hidden = false
                        self.sermonNotesAndSlides.bringSubviewToFront(self.logo)
                    }
                    break
                    
                case .downloading:
                    print(".downloading")
                    if (selectedSermon == document?.sermon) && (selectedSermon?.showing == document?.purpose) {
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                    }
                    break
                    
                case .downloaded:
                    print(".downloaded")
                    if #available(iOS 9.0, *) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                            document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL!, allowingReadAccessToURL: document!.download!.fileSystemURL!)
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if (self.selectedSermon == document?.sermon) && (self.selectedSermon?.showing == document?.purpose) {
                                    self.progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                                }
                                
                                document?.loadTimer?.invalidate()
                                document?.loadTimer = nil
                            })
                        })
                    } else {
                        // Fallback on earlier versions
                    }
                    break
                }
            }
        }
    }
    
    func loading(timer:NSTimer?)
    {
        // Expected to be on the main thread
        let document = timer?.userInfo as? Document
        
        if (selectedSermon == document?.sermon) && (selectedSermon?.showing == document?.purpose) {
            if (document?.wkWebView != nil) {
                progressIndicator.progress = Float(document!.wkWebView!.estimatedProgress)
                
                if progressIndicator.progress == 1 {
                    progressIndicator.hidden = true
                }
            }
        }
        
        if (document?.wkWebView != nil) && !document!.wkWebView!.loading {
            document?.loadTimer?.invalidate()
            document?.loadTimer = nil
        }
    }
    
    private func setupDocument(document:Document?)
    {
//        print("setupDocument")
        
        document?.wkWebView?.removeFromSuperview()
        document?.wkWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
        setupWKWebView(document?.wkWebView)
        
        document?.wkWebView?.hidden = true
        document?.wkWebView?.stopLoading()
        
        if #available(iOS 9.0, *) {
            if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
                if (document?.download?.state != .downloaded){
                    if (selectedSermon == document?.sermon) && (selectedSermon?.showing == document?.purpose) {
                        sermonNotesAndSlides.bringSubviewToFront(activityIndicator)
                        sermonNotesAndSlides.bringSubviewToFront(progressIndicator)
                        
                        activityIndicator.hidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite != 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.hidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.DOWNLOADING_TIMER_INTERVAL, target: self, selector: #selector(MyViewController.downloading(_:)), userInfo: document, repeats: true)
                    }
                    
                    document?.download?.download()
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL!, allowingReadAccessToURL: document!.download!.fileSystemURL!)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if (self.selectedSermon == document?.sermon) && (self.selectedSermon?.showing == document?.purpose) {
                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.hidden = true
                                
                                self.progressIndicator.progress = 0.0
                                self.progressIndicator.hidden = true
                            }
                            document?.loadTimer?.invalidate()
                            document?.loadTimer = nil
                        })
                    })
                }
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if (self.selectedSermon == document?.sermon) && (self.selectedSermon?.showing == document?.purpose) {
                            self.activityIndicator.hidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.hidden = false
                        }
                        
                        if document?.loadTimer == nil {
                            document?.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(MyViewController.loading(_:)), userInfo: document, repeats: true)
                        }
                    })
                    
                    let request = NSURLRequest(URL: document!.download!.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    document?.wkWebView?.loadRequest(request)
                })
            }
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if (self.selectedSermon == document?.sermon) && (self.selectedSermon?.showing == document?.purpose) {
                        self.activityIndicator.hidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.hidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.LOADING_TIMER_INTERVAL, target: self, selector: #selector(MyViewController.loading(_:)), userInfo: document, repeats: true)
                    }
                })
                
                let request = NSURLRequest(URL: document!.download!.url!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                document?.wkWebView?.loadRequest(request)
            })
        }
    }
    
    private func hideOtherDocuments()
    {
        if (selectedSermon != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if document.purpose != selectedSermon!.showing {
                        document.wkWebView?.hidden = true
                    }
                }
            }
        }
    }
    
    private func hideAllDocuments()
    {
        if (selectedSermon != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    document.wkWebView?.hidden = true
                }
            }
        }
    }
    
    private func setupNotesSlidesVideo()
    {
        activityIndicator.hidden = true

        progressIndicator.hidden = true
        progressIndicator.progress = 0.0

//        print("setupNotesAndSlides")
//        print("Selected: \(Globals.sermonSelected?.title)")
//        print("Last Selected: \(Globals.sermonLastSelected?.title)")
//        print("Playing: \(Globals.sermonPlaying?.title)")
        
        if (selectedSermon != nil) {
            splitView.hidden = false

            if (selectedSermon!.hasNotes()) {
                setupDocument(notesDocument)
            } else {
                notesDocument?.wkWebView?.hidden = true
            }
            
            if (selectedSermon!.hasSlides()) {
                setupDocument(slidesDocument)
            } else {
                slidesDocument?.wkWebView?.hidden = true
            }
            
    //        print("notes hidden \(sermonNotes.hidden)")
    //        print("slides hidden \(sermonSlides.hidden)")
            
            // Check whether they can or should show what they claim to show!
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                if !selectedSermon!.hasNotes() {
                    selectedSermon!.showing = Constants.NONE
                }
                break
                
            case Constants.SLIDES:
                if !selectedSermon!.hasSlides() {
                    selectedSermon!.showing = Constants.NONE
                }
                break
                
            case Constants.VIDEO:
                if !selectedSermon!.hasVideo() {
                    selectedSermon!.showing = Constants.NONE
                }
                break
                
            default:
                break
            }
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                Globals.mpPlayer?.view.hidden = true
                logo.hidden = true
                
                hideOtherDocuments()
                
                sermonNotesAndSlides.bringSubviewToFront(documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView!)
                break
                
            case Constants.SLIDES:
                Globals.mpPlayer?.view.hidden = true
                logo.hidden = true
                
                hideOtherDocuments()
                
                sermonNotesAndSlides.bringSubviewToFront(documents[selectedSermon!.id]![selectedSermon!.showing!]!.wkWebView!)
                break
                
            case Constants.VIDEO:
                //This should not happen unless it is playing video.
                switch selectedSermon!.playing! {
                case Constants.AUDIO:
                    //This should never happen.
                    setupDefaultNotesAndSlides()
                    break

                case Constants.VIDEO:
                    if (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
                        hideAllDocuments()

                        logo.hidden = true
                        
                        Globals.mpPlayer?.view.hidden = false
                        selectedSermon?.showing = Constants.VIDEO
                        if (Globals.mpPlayer != nil) {
                            sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view)
                        } else {
                            setupDefaultNotesAndSlides()
                        }
                    } else {
                        //This should never happen.
                        setupDefaultNotesAndSlides()
                    }
                    break
                    
                default:
                    break
                }
                break
                
            case Constants.NONE:
                activityIndicator.stopAnimating()
                activityIndicator.hidden = true
                
                hideAllDocuments()
                
                switch selectedSermon!.playing! {
                case Constants.AUDIO:
                    Globals.mpPlayer?.view.hidden = true
                    setupDefaultNotesAndSlides()
                    break
                    
                case Constants.VIDEO:
                    if (Globals.sermonPlaying == selectedSermon) {
                        if (Globals.sermonPlaying!.hasVideo() && (Globals.sermonPlaying!.playing == Constants.VIDEO)) {
                            Globals.mpPlayer?.view.hidden = false
                            sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view!)
                            selectedSermon?.showing = Constants.VIDEO
                        } else {
                            Globals.mpPlayer?.view.hidden = true
                            self.logo.hidden = false
                            selectedSermon?.showing = Constants.NONE
                            self.sermonNotesAndSlides.bringSubviewToFront(self.logo)
                        }
                    } else {
                        Globals.mpPlayer?.view.hidden = true
                        setupDefaultNotesAndSlides()
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
            splitView.hidden = true
            
            hideAllDocuments()

            Globals.mpPlayer?.view.hidden = true
            
            logo.hidden = !shouldShowLogo() // && roomForLogo()
            
            if (!logo.hidden) {
                sermonNotesAndSlides.bringSubviewToFront(self.logo)
            }
        }

        setupSTVControl()
    }
    
    func scrollToSermon(sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = NSIndexPath(forRow: 0, inSection: 0)
            
            if (sermonsInSeries?.count > 1) {
                if let sermonIndex = sermonsInSeries?.indexOf(sermon!) {
//                    print("\(sermonIndex)")
                    indexPath = NSIndexPath(forRow: sermonIndex, inSection: 0)
                }
            }
            
//            print("\(tableView.bounds)")
            
            if (select) {
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: position)
            }
            
//            print("Row: \(indexPath.row) Section: \(indexPath.section)")

            if (position == UITableViewScrollPosition.Top) {
//                var point = CGPointZero //tableView.bounds.origin
//                point.y += tableView.rowHeight * CGFloat(indexPath.row)
//                tableView.setContentOffset(point, animated: true)
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: true)
            } else {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: true)
            }
        } else {
            //No sermon to scroll to.
            
        }
    }
    
    func setupPlayPauseButton()
    {
        if selectedSermon != nil {
            if (selectedSermon == Globals.sermonPlaying) {
                playPauseButton.enabled = Globals.sermonLoaded
                
                if (Globals.playerPaused) {
                    playPauseButton.setTitle(Constants.FA_PLAY, forState: UIControlState.Normal)
                } else {
                    playPauseButton.setTitle(Constants.FA_PAUSE, forState: UIControlState.Normal)
                }
            } else {
                playPauseButton.enabled = true
                playPauseButton.setTitle(Constants.FA_PLAY, forState: UIControlState.Normal)
            }

            playPauseButton.hidden = false
        } else {
            playPauseButton.enabled = false
            playPauseButton.hidden = true
        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func tags(object:AnyObject?)
    {
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.filters
        //And when the user chooses one, scroll to the first time in that section.
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up

                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Sermon Tags"
                
                popover.delegate = self
                
                popover.purpose = .showingTags
                popover.strings = selectedSermon?.tagsArray
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                popover.allowsSelection = false
                popover.selectedSermon = selectedSermon
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func setupActionAndTagsButtons()
    {
        if (selectedSermon != nil) {
            var barButtons = [UIBarButtonItem]()
            
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: #selector(MyViewController.actions))
            barButtons.append(actionButton!)
        
            if (selectedSermon!.hasTags()) {
                if (selectedSermon?.tagsSet?.count > 1) {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAGS, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MyViewController.tags(_:)))
                } else {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAG, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MyViewController.tags(_:)))
                }
                
                tagsButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_TAGS_FONT_SIZE)!], forState: UIControlState.Normal)
                
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
                        
                        //        print("\(sermonNotesWebView!.scrollView.contentSize)")
                        //        print("\(sermonSlidesWebView!.scrollView.contentSize)")
                        
                        if let ratio = selectedSermon!.settings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
                            contentOffsetXRatio = Float(ratio)!
                        }
                        
                        if let ratio = selectedSermon!.settings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
                            contentOffsetYRatio = Float(ratio)!
                        }
                        
                        let contentOffset = CGPointMake(
                            CGFloat(contentOffsetXRatio) * document.wkWebView!.scrollView.contentSize.width,
                            CGFloat(contentOffsetYRatio) * document.wkWebView!.scrollView.contentSize.height)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            document.wkWebView!.scrollView.setContentOffset(contentOffset, animated: false)
                        })
                    }
                }
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        setupSplitViewController()
        
//        captureContentOffsetAndZoomScale()
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in

            self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Top)
            
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
            
            //            print("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
            
            splitView.min = newMinConstraintConstant
            splitView.max = newMaxConstraintConstant
            splitView.height = sermonNotesAndSlidesConstraint.constant
            self.view.setNeedsLayout()
        } else {
            if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
                //If we started out in landscape on an iPhone and segued to this view and then transitioned to Portrait
                //The constraint is not setup because it is not active in landscape so we have to set it up
                if let viewSplit = selectedSermon?.viewSplit {
                    var newConstraintConstant = size.height * CGFloat(Float(viewSplit)!)
                    
                    let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(size.height - 12) //Adjustment of 12 for difference in NavBar height between landscape (shorter) and portrait (taller by 12)
                    
                    //                    print("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
                    
                    if newConstraintConstant < minConstraintConstant { newConstraintConstant = minConstraintConstant }
                    if newConstraintConstant > maxConstraintConstant { newConstraintConstant = maxConstraintConstant }
                    
                    self.sermonNotesAndSlidesConstraint.constant = newConstraintConstant
                    
                    //                    print("\(viewSplit) \(size) \(sermonNotesAndSlidesConstraint.constant)")
                    
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

    
    func ratioForSplitView(sender: SplitView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if (selectedSermon != nil) {
            if let viewSplit = selectedSermon?.viewSplit {
                ratio = CGFloat(Float(viewSplit)!)
            }
        }
//        print("ratio: '\(ratio)")
        return ratio
    }
    
    
    func resetConstraint()
    {
        var newConstraintConstant:CGFloat
        
        //        print("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        newConstraintConstant = minConstraintConstant + tableView.rowHeight * (sermonsInSeries!.count > 1 ? 1 : 0)
        
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
    
    private func setupViewSplit()
    {
        var newConstraintConstant:CGFloat
        
//        print("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = sermonNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(splitView) {
//            print("\(self.view.bounds.height)")
            newConstraintConstant = self.view.bounds.height * ratio
        } else {
            let numberOfAdditionalRows = CGFloat(sermonsInSeries != nil ? sermonsInSeries!.count - 1 : 0)
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
    
    private func setupTitle()
    {
        if (selectedSermon != nil) {
            if (selectedSermon!.hasSeries()) {
                //The selected sermon is in a series so set the title.
                self.navigationItem.title = selectedSermon?.series
            } else {
                self.navigationItem.title = selectedSermon?.title
            }
        } else {
            self.navigationItem.title = nil
        }
    }
    
    private func setupAudioOrVideo()
    {
        if (selectedSermon != nil) {
            if (selectedSermon!.hasVideo()) {
                audioOrVideoControl.enabled = true
                audioOrVideoControl.hidden = false
                audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
                view.setNeedsLayout()

                audioOrVideoControl.setEnabled(true, forSegmentAtIndex: Constants.AUDIO_SEGMENT_INDEX)
                audioOrVideoControl.setEnabled(true, forSegmentAtIndex: Constants.VIDEO_SEGMENT_INDEX)
                
                switch selectedSermon!.playing! {
                case Constants.AUDIO:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AUDIO_SEGMENT_INDEX
                    break
                    
                case Constants.VIDEO:
                    audioOrVideoControl.selectedSegmentIndex = Constants.VIDEO_SEGMENT_INDEX
                    break
                    
                default:
                    break
                }

                let attr = [NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_ICONS_FONT_SIZE)!]
                
                audioOrVideoControl.setTitleTextAttributes(attr, forState: .Normal)
                
                audioOrVideoControl.setTitle(Constants.FA_AUDIO, forSegmentAtIndex: Constants.AUDIO_SEGMENT_INDEX) // Audio

                audioOrVideoControl.setTitle(Constants.FA_VIDEO, forSegmentAtIndex: Constants.VIDEO_SEGMENT_INDEX) // Video
            } else {
                audioOrVideoControl.enabled = false
                audioOrVideoControl.hidden = true
                audioOrVideoWidthConstraint.constant = 0
                view.setNeedsLayout()
            }
        } else {
            audioOrVideoControl.enabled = false
            audioOrVideoControl.hidden = true
        }
    }
    
    func updateUI()
    {
        setupPlayerView(Globals.mpPlayer?.view)

        //        print("viewWillAppear 1 sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
        //        print("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        // This next line is for the case when video is playing and the video has been zoomed to full screen and that makes the embedded controls visible
        // allowing the user to control playback, pausing or stopping, and then unzooming makes the play pause button vislble and it has to be
        // updated according to the player state, which may have changed.
        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.playerPaused = (Globals.mpPlayer?.playbackState == .Paused) || (Globals.mpPlayer?.playbackState == .Stopped)
        }
        
        if (selectedSermon != nil) && (Globals.mpPlayer == nil) {
            setupPlayerAtEnd(selectedSermon)
        }
        
        setupViewSplit()
        
        //        print("viewWillAppear 2 sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
        //        print("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the sermon selected is playing already
        addSliderObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSlider()
        setupNotesSlidesVideo()
        setupActionAndTagsButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

//        tableView.reloadData()

        updateUI()
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (Globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

//        print("viewDidAppear sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
//        print("viewDidAppear tableView.bounds: \(tableView.bounds)")

        setupSplitViewController()
        
        scrollToSermon(selectedSermon,select:true,position:UITableViewScrollPosition.Top)
    }
    
    private func captureViewSplit()
    {
//        print("captureViewSplit: \(sermonSelected?.title)")
        
        if (self.view != nil) && (splitView.bounds.size.width > 0) {
            if (selectedSermon != nil) {
//                print("\(self.view.bounds.height)")
                let ratio = self.sermonNotesAndSlidesConstraint.constant / self.view.bounds.height
                
                //            print("captureViewSplit ratio: \(ratio)")
                
                selectedSermon?.viewSplit = "\(ratio)"
            }
        }
    }
    
    private func captureContentOffset(document:Document)
    {
        selectedSermon?.settings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.x / document.wkWebView!.scrollView.contentSize.width)"
        selectedSermon?.settings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.y / document.wkWebView!.scrollView.contentSize.height)"
    }
    
    private func captureContentOffset(webView:WKWebView?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) && (webView != nil) && (!webView!.loading) && (webView!.URL != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if webView == document.wkWebView {
                        captureContentOffset(document)
                    }
                }
            }
        }
    }
    
    private func captureZoomScale(document:Document)
    {
        selectedSermon?.settings?[document.purpose! + Constants.ZOOM_SCALE] = "\(document.wkWebView!.scrollView.zoomScale)"
    }
    
    private func captureZoomScale(webView:WKWebView?)
    {
        //        print("captureZoomScale: \(sermonSelected?.title)")
        
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) && (webView != nil) && (!webView!.loading) && (webView!.URL != nil) {
            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if webView == document.wkWebView {
                        captureZoomScale(document)
                    }
                }
            }
        }
    }
    
//    func captureContentOffsetAndZoomScale()
//    {
////        if (documents[selectedSermon!.id] != nil) {
////            for document in documents[selectedSermon!.id]!.values {
////                captureContentOffset(document)
////                captureZoomScale(document)
////            }
////        }
//
////        captureContentOffset(notesDocument?.wkWebView)
////        captureZoomScale(notesDocument?.wkWebView)
////        
////        captureContentOffset(slidesDocument?.wkWebView)
////        captureZoomScale(slidesDocument?.wkWebView)
//    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
        
        // The scrollView delegate MUST be set to nil or the app will crash.
        if (selectedSermon != nil) && (documents[selectedSermon!.id] != nil) {
            for document in documents[selectedSermon!.id]!.values {
                document.wkWebView?.stopLoading()
                document.wkWebView?.scrollView.delegate = nil
                
                if (document.sermon == selectedSermon) && (document.purpose == selectedSermon?.showing) && (document.wkWebView != nil) && document.wkWebView!.scrollView.decelerating {
                    captureContentOffset(document)
                }
            }
        }

        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        sliderObserver?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning: \(selectedSermon?.title)")
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destinationViewController as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }

        if let wvc = destination as? WebViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER:
                    splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
                    setupWKContentOffsets()
                    wvc.selectedSermon = sender as? Sermon
                    wvc.showScripture = showScripture
                    break
                default:
                    break
                }
            }
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return selectedSermon != nil ? (sermonsInSeries != nil ? sermonsInSeries!.count : 0) : 0
    }
    
    /*
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMONS_IN_SERIES_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyTableViewCell
    
        cell.sermon = sermonsInSeries?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, shouldSelectRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    private func setTimes(timeNow:Float, length:Float)
    {
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Float(elapsedHours) * 60*60)) / 60)
        let elapsedSec = Int(timeNow % 60)
        
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
        let remainingSec = Int(timeRemaining % 60)
        
        var remaining:String
        
        if (remainingHours > 0) {
            remaining = "\(String(format: "%d",remainingHours)):"
        } else {
            remaining = Constants.EMPTY_STRING
        }
        
        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = remaining
    }
    
    
    private func setSliderAndTimesToAudio() {
        assert(Globals.mpPlayer != nil,"Globals.mpPlayer should not be nil if we're updating the slider to the audio")
        
        if (Globals.mpPlayer != nil) {
            let length = Float(Globals.mpPlayer!.duration)
            
            if (Globals.mpPlayer!.currentPlaybackTime >= 0) {
                var timeNow:Float = 0.0
                
                if (Globals.mpPlayer!.currentPlaybackTime <= Globals.mpPlayer!.duration) {
                    timeNow = Float(Globals.mpPlayer!.currentPlaybackTime)
                }
                
                let progress = Float(timeNow) / Float(length)
                
                slider.value = progress
                
                setTimes(timeNow,length: length)
            } else {
                slider.value = 0
                setTimes(0,length: length)
            }
        } else {
            slider.value = 0
            setTimes(0,length: 0)
        }
    }
    
    private func setTimesToSlider() {
        assert(Globals.mpPlayer != nil,"Globals.mpPlayer should not be nil if we're updating the times to the slider, i.e. the slider is showing")
        
        if (Globals.mpPlayer != nil) {
            let length = Float(Globals.mpPlayer!.duration)
            
            let timeNow = Float(self.slider.value * length)
            
            setTimes(timeNow,length: length)
        }
    }
    
    private func setupSlider() {
        if spinner.isAnimating() {
            spinner.stopAnimating()
            spinner.hidden = true
        }
        
        slider.enabled = Globals.sermonLoaded
        
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {
            if (Globals.sermonPlaying == selectedSermon) {
                elapsed.hidden = false
                remaining.hidden = false
                slider.hidden = false
                
                setSliderAndTimesToAudio()
            } else {
                elapsed.hidden = true
                remaining.hidden = true
                slider.hidden = true
            }
        } else {
            elapsed.hidden = true
            remaining.hidden = true
            slider.hidden = true
        }
    }

    func sliderTimer()
    {
        if (selectedSermon != nil) && (selectedSermon == Globals.sermonPlaying) {
            let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
            
            let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
            let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
            
//            if playable {
//                print("sliderTimer.MPMovieLoadState.Playable")
//            }
//            
//            if playthrough {
//                print("sliderTimer.MPMovieLoadState.Playthrough")
//            }
            
            playPauseButton.enabled = Globals.sermonLoaded
            slider.enabled = Globals.sermonLoaded
            
            if (!Globals.sermonLoaded) {
                if (!spinner.isAnimating()) {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
            }
            
            switch Globals.mpPlayerStateTime!.state {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                switch Globals.mpPlayer!.playbackState {
                case .SeekingBackward:
//                    print("sliderTimer.playing.SeekingBackward")
                    break
                    
                case .SeekingForward:
//                    print("sliderTimer.playing.SeekingForward")
                    break
                    
                default:
                    setSliderAndTimesToAudio()
                    
                    if !(playable || playthrough) { // Globals.mpPlayer?.currentPlaybackRate == 0
//                        print("sliderTimer.Playthrough or Playing NOT OK")
                        if !spinner.isAnimating() {
                            spinner.hidden = false
                            spinner.startAnimating()
                        }
                    }
                    if (playable || playthrough) {
//                        print("sliderTimer.Playthrough or Playing OK")
                        if spinner.isAnimating() {
                            spinner.stopAnimating()
                            spinner.hidden = true
                        }
                    }
                    break
                }
                break
                
            case .paused:
//                print("paused")
                
                if Globals.sermonLoaded {
                    setSliderAndTimesToAudio()
                    if spinner.isAnimating() {
                        spinner.stopAnimating()
                        spinner.hidden = true
                    }
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                if !spinner.isAnimating() {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
                setSliderAndTimesToAudio()
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                if !spinner.isAnimating() {
                    spinner.hidden = false
                    spinner.startAnimating()
                }
                setSliderAndTimesToAudio()
                break
            }
            
//            if (Globals.mpPlayer != nil) {
//                switch Globals.mpPlayer!.playbackState {
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
            
            //        print("Duration: \(Globals.mpPlayer!.duration) CurrentPlaybackTime: \(Globals.mpPlayer!.currentPlaybackTime)")
            
            if (Globals.mpPlayer!.duration > 0) && (Globals.mpPlayer!.currentPlaybackTime > 0) &&
                (Int(Float(Globals.mpPlayer!.currentPlaybackTime)) == Int(Float(Globals.mpPlayer!.duration))) { //  (slider.value > 0.9999)
                    Globals.mpPlayer?.pause()
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                    
                    if (Globals.sermonPlaying?.currentTime != Globals.mpPlayer!.duration.description) {
                        Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
                    }
                    
                    if (NSUserDefaults.standardUserDefaults().boolForKey(Constants.AUTO_ADVANCE)) {
                        advanceSermon()
                    }
            }
        }
    }
    
    func advanceSermon()
    {
//        print("\(Globals.sermonPlaying?.playing)")
        if (Globals.sermonPlaying?.playing == Constants.AUDIO) {
            let sermons = sermonsInSermonSeries(Globals.sermonPlaying)
            if let index = sermons?.indexOf(Globals.sermonPlaying!) {
                if index < (sermons!.count - 1) {
                    if let nextSermon = sermons?[index + 1] {
                        nextSermon.playing = Constants.AUDIO
                        nextSermon.currentTime = Constants.ZERO
                        if (self.view.window != nil) && (sermons?.indexOf(nextSermon) != nil) {
                            selectedSermon = nextSermon
                            updateUI()
                            scrollToSermon(nextSermon, select: true, position: UITableViewScrollPosition.Top)
                        }
                        //            print("\(selectedSermon)")
                        playNewSermon(nextSermon)
                    }
                } else {
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                }
            }
        } else {
            Globals.playerPaused = true
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
//        print("addSliderObserver in")

        if (sliderObserver != nil) {
            sliderObserver?.invalidate()
            sliderObserver = nil
        }

        if (Globals.mpPlayer != nil) {
            sliderObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.SLIDER_TIMER_INTERVAL, target: self, selector: #selector(MyViewController.sliderTimer), userInfo: nil, repeats: true)
        } else {
            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
            print("Globals.player == nil in sliderObserver")
            // Should we setup the player all over again?
        }

//        print("addSliderObserver out")
    }
    
    private func networkUnavailable(message:String?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) { // && (self.view.window != nil) 
            dismissViewControllerAnimated(true, completion: nil)
            
            let alert = UIAlertController(title: Constants.Network_Error,
                message: message,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func failedToLoad()
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            dismissViewControllerAnimated(true, completion: nil)

            let alert = UIAlertController(title: Constants.Content_Failed_to_Load,
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func playNewSermon(sermon:Sermon?) {
        Globals.mpPlayer?.stop()
        
        Globals.mpPlayer?.view.removeFromSuperview()
        
//        captureContentOffsetAndZoomScale()
        
        if (sermon != nil) && (sermon!.hasVideo() || sermon!.hasAudio()) {
            Globals.sermonPlaying = sermon
            Globals.playerPaused = false
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            setupPlayer(sermon)
            
            if (sermon!.hasVideo() && (sermon!.playing == Constants.VIDEO)) {
                setupPlayerView(Globals.mpPlayer?.view)
                
                if (view.window != nil) {
                    Globals.mpPlayer!.view.hidden = false
                    sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view!)
                }
                
                sermon!.showing = Constants.VIDEO
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
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//
//        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        captureContentOffsetAndZoomScale()
        
        if (selectedSermon != nil) &&  (documents[selectedSermon!.id] != nil) {
            for document in documents[selectedSermon!.id]!.values {
                if (document.sermon == selectedSermon) && (document.purpose == selectedSermon?.showing) && (document.wkWebView != nil) && document.wkWebView!.scrollView.decelerating {
                    captureContentOffset(document)
                }
            }
        }
        
        if (selectedSermon != sermonsInSeries![indexPath.row]) || (Globals.sermonHistory == nil) {
            addToHistory(sermonsInSeries![indexPath.row])
        }
        selectedSermon = sermonsInSeries![indexPath.row]

        if (selectedSermon == Globals.sermonPlaying) && (Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.mpPlayer?.stop()
            Globals.mpPlayer = nil
            
            Globals.playOnLoad = false
            
            setupPlayer(selectedSermon)
            
            if (selectedSermon!.hasVideo() && (selectedSermon!.playing == Constants.VIDEO)) {
                setupPlayerView(Globals.mpPlayer?.view)
            }
        }

        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSlider()
        setupNotesSlidesVideo()
        setupActionAndTagsButtons()
    }
    
    func webView(wkWebView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if (navigationAction.request.URL != nil) {
//            print("\(navigationAction.request.URL!.absoluteString)")
            
            if (navigationAction.request.URL!.absoluteString.endIndex < Constants.BASE_PDF_URL.endIndex) {
                decisionHandler(WKNavigationActionPolicy.Cancel)
            } else {
                if (navigationAction.request.URL!.absoluteString.substringToIndex(Constants.BASE_PDF_URL.endIndex) == Constants.BASE_PDF_URL) {
                    decisionHandler(WKNavigationActionPolicy.Allow)
                } else {
                    if (navigationAction.request.URL!.path!.substringToIndex(cachesURL()!.path!.endIndex) == cachesURL()!.path!) {
                        decisionHandler(WKNavigationActionPolicy.Allow)
                    } else {
                        decisionHandler(WKNavigationActionPolicy.Cancel)
                    }
                }
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation: WKNavigation!, withError: NSError) {
        print("wkDidFailNavigation")
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            
            progressIndicator.hidden = true
            
//            stvControl.hidden = true
            
            webView.hidden = true
//            Globals.mpPlayer?.view.hidden = true

            if (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if (webView == document.wkWebView) {
                        document.wkWebView = nil
                        if (selectedSermon == document.sermon) && (selectedSermon?.showing == document.purpose) {
                            networkUnavailable(withError.localizedDescription)
                        }
                    }
                }
            }

            logo.hidden = !shouldShowLogo() // && roomForLogo()
            
            if (!logo.hidden) {
                sermonNotesAndSlides.bringSubviewToFront(self.logo)
            }
        }
        
        // Keep trying
//        let request = NSURLRequest(URL: wkWebView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//        wkWebView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: NSError) {
        print("wkDidFailProvisionalNavigation")
        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            progressIndicator.hidden = true
            
//            stvControl.hidden = true
            
            webView.hidden = true
//            Globals.mpPlayer?.view.hidden = true
            
            if (selectedSermon != nil) && (documents[selectedSermon!.id] != nil) {
                for document in documents[selectedSermon!.id]!.values {
                    if (webView == document.wkWebView) {
                        document.wkWebView = nil
                        if (selectedSermon == document.sermon) && (selectedSermon?.showing == document.purpose) {
                            networkUnavailable(withError.localizedDescription)
                        }
                    }
                }
            }

            logo.hidden = !shouldShowLogo() // && roomForLogo()
            
            if (!logo.hidden) {
                sermonNotesAndSlides.bringSubviewToFront(self.logo)
            }
        }
    }
    
    func webView(wkWebView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
//        print("wkDidStartProvisionalNavigation")

    }
    
    func wkSetZoomScaleThenContentOffset(wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // The effects of the next two calls are strongly order dependent.
            if !scale.isNaN {
                wkWebView.scrollView.setZoomScale(scale, animated: false)
            }
            if (!offset.x.isNaN && !offset.y.isNaN) {
                wkWebView.scrollView.setContentOffset(offset,animated: false)
            }
        })

//        print("contentOffset after: \(wkWebView.scrollView.contentOffset)")
    }
    
    func setDocumentContentOffsetAndZoomScale(document:Document?)
    {
//        print("setNotesContentOffsetAndZoomScale Loading: \(sermonNotesWebView!.loading)")

        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        if let ratioStr = selectedSermon?.settings?[document!.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
//            print("X ratio string: \(ratio)")
            contentOffsetXRatio = Float(ratioStr)!
        } else {
//            print("No notes X ratio")
        }
        
        if let ratioStr = selectedSermon?.settings?[document!.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
//            print("Y ratio string: \(ratio)")
            contentOffsetYRatio = Float(ratioStr)!
        } else {
//            print("No notes Y ratio")
        }
        
        if let zoomScaleStr = selectedSermon?.settings?[document!.purpose! + Constants.ZOOM_SCALE] {
            zoomScale = CGFloat(Float(zoomScaleStr)!)
        } else {
//            print("No notes zoomScale")
        }
        
//        print("\(notesContentOffsetXRatio)")
//        print("\(sermonNotesWebView!.scrollView.contentSize.width)")
//        print("\(notesZoomScale)")
        
        let contentOffset = CGPointMake(CGFloat(contentOffsetXRatio) * document!.wkWebView!.scrollView.contentSize.width * zoomScale,
                                        CGFloat(contentOffsetYRatio) * document!.wkWebView!.scrollView.contentSize.height * zoomScale)
        
        wkSetZoomScaleThenContentOffset(document!.wkWebView!, scale: zoomScale, offset: contentOffset)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
//        print("wkWebViewDidFinishNavigation Loading:\(webView.loading)")
        
//        print("Frame: \(webView.frame)")
//        print("Bounds: \(webView.bounds)")

        if (self.view != nil) {
            if (selectedSermon != nil) {
                if (documents[selectedSermon!.id] != nil) {
                    for document in documents[selectedSermon!.id]!.values {
                        if (webView == document.wkWebView) {
    //                        print("sermonNotesWebView")
                            if (selectedSermon == document.sermon) && (selectedSermon?.showing == document.purpose) {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.hidden = true
                                    
                                    self.progressIndicator.hidden = true
                                    
                                    self.setupSTVControl()
                                    
//                                    print("webView:hidden=panning")
                                    webView.hidden = self.panning
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                    print("webView:hidden=true")
                                    webView.hidden = true
                                })
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
