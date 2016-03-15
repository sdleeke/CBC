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

class MyViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    var panning = false
    
    var showScripture = false
    
    var loadingFromLive = false
    
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
            if (selectedSermon != nil) {
                sermonsInSeries = selectedSermon?.sermonsInSeries // sermonsInSermonSeries(selectedSermon)
                
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
                defaults.synchronize()
                
                NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: oldValue)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "setupActionAndTagsButtons", name: Constants.SERMON_UPDATE_UI_NOTIFICATION, object: selectedSermon)
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                sermonsInSeries = nil
            }
        }
    }
    
    var sermonsInSeries:[Sermon]?

    var loadTimer:NSTimer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!

//    var popover : PopoverTableViewController?
    
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
                    
//                    removePlayObserver()
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSlider()
                }
                
                // We need to do this whether the sermon was playing or not
                captureContentOffsetAndZoomScale()
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
                captureContentOffsetAndZoomScale()
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
    
//    @IBOutlet weak var flipButton: UIButton!
//    @IBOutlet weak var flipButtonWidthConstraint: NSLayoutConstraint!
    
//    @IBAction func flipNotesAndSlides(sender: UIButton)
//    {
////        print("flipNotesAndSlides")
//        tap(self)
//    }
    
    @IBOutlet weak var stvControl: UISegmentedControl!
    @IBOutlet weak var stvWidthConstraint: NSLayoutConstraint!
    @IBAction func stvAction(sender: UISegmentedControl)
    {
        // This assumes this action isn't called unless an unselected segment is changed.  Otherwise touching the selected segment would cause it to flip to itself.
        
        var view:UIView?
        
        switch selectedSermon!.showing! {
        case Constants.SLIDES:
//            if sermonSlidesWebView!.hidden {
//                return
//            }
            view = sermonSlidesWebView
            break
            
        case Constants.NOTES:
//            if sermonNotesWebView!.hidden {
//                return
//            }
            view = sermonNotesWebView
            break
            
        case Constants.VIDEO:
            view = Globals.mpPlayer?.view
            break
            
        default:
            break
            
        }
        
        captureContentOffsetAndZoomScale()

        switch sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)! {
        case Constants.FA_SLIDES_SEGMENT_TITLE:
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
            
                if (self.sermonSlidesWebView != nil) {
                    self.sermonSlidesWebView?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.sermonSlidesWebView!)
                } else {
                    view?.hidden = true
                    self.logo?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.logo!)
                }
                self.selectedSermon!.showing = Constants.SLIDES
                
                }, completion: { finished in
                    view?.hidden = true
            })
            break

        case Constants.FA_TRANSCRIPT_SEGMENT_TITLE:
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
                
                if (self.sermonNotesWebView != nil) {
                    self.sermonNotesWebView?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.sermonNotesWebView!)
                } else {
                    view?.hidden = true
                    self.logo?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.logo!)
                }
                self.selectedSermon!.showing = Constants.NOTES

                }, completion: { finished in
                    view?.hidden = true
            })
            break
        
        case Constants.FA_VIDEO_SEGMENT_TITLE:
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {

                Globals.mpPlayer?.view.hidden = false

                self.sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view)
                self.selectedSermon!.showing = Constants.VIDEO

                }, completion: { finished in
                    view?.hidden = true
            })
            break
        
        default:
            break
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
                index++
            }
            if (selectedSermon!.hasSlides()) {
                stvControl.insertSegmentWithTitle(Constants.FA_SLIDES_SEGMENT_TITLE, atIndex: index, animated: false)
                slidesIndex = index
                index++
            }
            if (selectedSermon!.hasVideo() && (Globals.sermonPlaying == selectedSermon) && (selectedSermon?.playing == Constants.VIDEO)) {
                stvControl.insertSegmentWithTitle(Constants.FA_VIDEO_SEGMENT_TITLE, atIndex: index, animated: false)
                videoIndex = index
                index++
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
            switch Globals.mpPlayer!.playbackState {
            case .SeekingBackward:
                print("playPause.SeekingBackward")
                fallthrough
                
            case .SeekingForward:
                print("playPause.SeekingForward")
                fallthrough
                
            case .Playing:
                print("playPause.Playing")
                
//                removePlayObserver()
                
                Globals.mpPlayer?.pause()
                Globals.playerPaused = true
                updateCurrentTimeExact()
                setupPlayPauseButton()
                break
                
            case .Stopped:
                print("playPause.Stopped")
                fallthrough
                
            case .Interrupted:
                print("playPause.Interrupted")
                fallthrough
                
            case .Paused:
                print("playPause.Paused")

                let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
                let loadvalue:UInt8 = UInt8(MPMovieLoadState.Playable.rawValue)
                
                let playable = ((loadstate & loadvalue) == loadvalue)

//                print("\(loadstate)")
//                print("\(loadvalue)")
                
                if (playable) {
                    print("playPause.MPMovieLoadState.Playable")
                    Globals.playerPaused = false
                    
                    if (Globals.mpPlayer?.contentURL == selectedSermon?.playingURL) {
                        //                    print("\(selectedSermon!.currentTime!)")
                        //                    print("\(NSTimeInterval(Float(selectedSermon!.currentTime!)!))")
                        
                        if selectedSermon!.hasCurrentTime() {
                            //Make the comparision an Int to avoid missing minor differences
                            if (Globals.mpPlayer!.duration >= 0) && (Int(Float(Globals.mpPlayer!.duration)) == Int(Float(selectedSermon!.currentTime!)!)) {
                                Globals.sermonPlaying?.currentTime = Constants.ZERO
                                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                            }
                            if (Globals.mpPlayer!.currentPlaybackTime >= 0) && (Int(Globals.mpPlayer!.currentPlaybackTime) != Int(Float(selectedSermon!.currentTime!)!)) {
                                print("currentPlayBackTime: \(Globals.mpPlayer!.currentPlaybackTime) != currentTime: \(selectedSermon!.currentTime!)")
                            }
                        } else {
                            Globals.sermonPlaying?.currentTime = Constants.ZERO
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
                    print("playPause.MPMovieLoadState.Playthrough NOT OK")
                    if (Globals.playerPaused) {
                        playNewSermon(selectedSermon)
                    } else {
                        Globals.playerPaused = true
                        spinner.stopAnimating()
                        spinner.hidden = true
                        setupPlayPauseButton()
                    }
                }
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
        var result = false
        
        if selectedSermon != nil {
            switch selectedSermon!.showing! {
            case Constants.VIDEO:
                result = false
                break
                
            case Constants.NOTES:
                result = ((sermonNotesWebView == nil) || (sermonNotesWebView!.hidden == true)) && progressIndicator.hidden
                break
                
            case Constants.SLIDES:
                result = ((sermonSlidesWebView == nil) || (sermonSlidesWebView!.hidden == true)) && progressIndicator.hidden
                break
                
            case Constants.NONE:
                result = true
                break
                
            default:
                result = false
                break
            }
        } else {
            result = true
        }

//        if (sermonNotesWebView == nil) && (sermonSlidesWebView == nil) {
//            return true
//        }
//        
//        if  {
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
        
        return result
    }
    
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
            panning = true
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                sermonNotesWebView?.hidden = true
                sermonNotesWebView?.scrollView.delegate = nil
                break
                
            case Constants.SLIDES:
                sermonSlidesWebView?.hidden = true
                sermonSlidesWebView?.scrollView.delegate = nil
                break
                
            case Constants.VIDEO:
                break
                
            default:
                break
            }
            break
            
        case .Ended:
            captureViewSplit()

            switch selectedSermon!.showing! {
            case Constants.NOTES:
                sermonNotesWebView?.hidden = (sermonNotesWebView?.URL == nil)
                sermonNotesWebView?.scrollView.delegate = self
                break
                
            case Constants.SLIDES:
                sermonSlidesWebView?.hidden = (sermonSlidesWebView?.URL == nil)
                sermonSlidesWebView?.scrollView.delegate = self
                break
                
            case Constants.VIDEO:
                break
                
            default:
                break
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
//            print("move by \(change)")

            
            //Not sure if we don't need this here as the view split should be visibly changing as the user makes this pan gesture.
            //Tried it with and without this and got crashes either way that I couldn't diagnose.  
            //One crash include reference to something pdf so perhaps the crashes are coming from the WKWebView trying to resize.
            
//            self.view.layoutIfNeeded() 
            
//            print("sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
//            print("tableView.bounds: \(tableView.bounds)")

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
    
//    var notesTap:UITapGestureRecognizer?
//    var slidesTap:UITapGestureRecognizer?
    
    var sermonNotesWebView: WKWebView?
    var sermonSlidesWebView: WKWebView?
    
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
    
//    var sliderObserver: NSTimer?
//    var playObserver: NSTimer?
    
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
    
//    func sortSermonsInSeries()
//    {
//        sermonsInSeries = sortSermonsByYear(sermonsInSeries, sorting: Globals.sorting)
//        tableView.reloadData()
//        scrollToSermon(selectedSermon, select: true, position:UITableViewScrollPosition.None)
//    }
    
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
                            favoriteSermons++
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
                            sermonsToDownload++
                            break
                        case .downloading:
                            sermonsDownloading++
                            break
                        case .downloaded:
                            sermonsDownloaded++
                            break
                        }
                    }
                    
                    if (sermonsToDownload > 0) {
                        switch sermonsToDownload {
                        case 1:
                            actionMenu.append(Constants.Download_Audio)
                            break
                            
                        default:
                            actionMenu.append(Constants.Download_All_Audio)
                            break
                        }
                    }
                    
                    if (sermonsDownloading > 0) {
                        actionMenu.append(Constants.Cancel_All_Downloads)
                    }
                    
                    if (sermonsDownloaded > 0) {
                        actionMenu.append(Constants.Delete_All_Downloads)
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
        //        print("action!")
        
//        //In case we have one already showing
//        dismissViewControllerAnimated(true, completion: nil)

        // Put up an action sheet

//        let alert = UIAlertController(title: Constants.EMPTY_STRING,
//            message: Constants.EMPTY_STRING,
//            preferredStyle: UIAlertControllerStyle.ActionSheet)
//        
//        var action : UIAlertAction
        
//        if (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) || (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) {
//            action = UIAlertAction(title: Constants.Print, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("print!")
//                self.printSermon(self.selectedSermon)
//                //                    if (Reachability.isConnectedToNetwork()) {
//                //                        self.printSermon(self.selectedSermon)
//                //                    } else {
//                //                        self.networkUnavailable("Unable to print.")
//                //                    }
//            })
//            alert.addAction(action)
//        }

//        var title:String?
//        
//        if selectedSermon!.hasFavoritesTag() {
//            title = Constants.Remove_From_Favorites
//        } else {
//            title = Constants.Add_to_Favorites
//        }
//        
//        action = UIAlertAction(title:title, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            switch title! {
//            case Constants.Add_to_Favorites:
//                self.selectedSermon?.addTag(Constants.Favorites)
//                break
//            case Constants.Remove_From_Favorites:
//                self.selectedSermon?.removeTag(Constants.Favorites)
//                break
//            default:
//                break
//            }
//        })
//        alert.addAction(action)
//
//        if sermonsInSeries?.count > 1 {
//            var favoriteSermons = 0
//            
//            for sermon in sermonsInSeries! {
//                if (sermon.hasFavoritesTag()) {
//                    favoriteSermons++
//                }
//            }
//            switch favoriteSermons {
//            case 0:
//                action = UIAlertAction(title:Constants.Add_All_to_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.addTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                break
//                
//            case 1:
//                if !selectedSermon!.hasFavoritesTag() {
//                    action = UIAlertAction(title:Constants.Remove_All_From_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                        for sermon in self.sermonsInSeries! {
//                            sermon.removeTag(Constants.Favorites)
//                        }
//                    })
//                    alert.addAction(action)
//                }
//                
//                action = UIAlertAction(title:Constants.Add_All_to_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.addTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                break
//                
//            case sermonsInSeries!.count - 1:
//                if selectedSermon!.hasFavoritesTag() {
//                    action = UIAlertAction(title:Constants.Add_All_to_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                        for sermon in self.sermonsInSeries! {
//                            sermon.addTag(Constants.Favorites)
//                        }
//                    })
//                    alert.addAction(action)
//                }
//                
//                action = UIAlertAction(title:Constants.Remove_All_From_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.removeTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                break
//                
//            case sermonsInSeries!.count:
//                action = UIAlertAction(title:Constants.Remove_All_From_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.removeTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                break
//                
//            default:
//                action = UIAlertAction(title:Constants.Add_All_to_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.addTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                action = UIAlertAction(title:Constants.Remove_All_From_Favorites, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in self.sermonsInSeries! {
//                        sermon.removeTag(Constants.Favorites)
//                    }
//                })
//                alert.addAction(action)
//                break
//            }
//        }
//        
//        if (selectedSermon!.hasVideo() && selectedSermon!.playingVideo() && selectedSermon!.showingVideo()) {
//                action = UIAlertAction(title: Constants.Full_Screen, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    self.zoomScreen()
//                })
//            alert.addAction(action)
//        }
//        
//        if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
//            action = UIAlertAction(title: Constants.Full_Screen, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                self.showScripture = false
//                self.performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: self.selectedSermon)
//            })
//            alert.addAction(action)
//        }
//    
//        if (selectedSermon!.hasSlides() && selectedSermon!.showingSlides()) || (selectedSermon!.hasNotes() && selectedSermon!.showingNotes()) {
//            action = UIAlertAction(title: Constants.Open_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("mail!")
//                
//                var url:NSURL?
//                
//                switch self.selectedSermon!.showing! {
//                case Constants.NOTES:
//                    url = self.selectedSermon!.notesURL
//                    break
//                case Constants.SLIDES:
//                    url = self.selectedSermon!.slidesURL
//                    break
//                    
//                default:
//                    break
//                }
//
//                if  url != nil {
//                    if (UIApplication.sharedApplication().canOpenURL(url!)) { // Reachability.isConnectedToNetwork() &&
//                        UIApplication.sharedApplication().openURL(url!)
//                    } else {
//                        self.networkUnavailable("Unable to open transcript in browser at: \(url)")
//                    }
//                }
//            })
//            alert.addAction(action)
//        }
//        
//        if (selectedSermon!.hasScripture() && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
//            action = UIAlertAction(title: Constants.Scripture_Full_Screen, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("mail!")
//                self.showScripture = true
//                self.performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: self.selectedSermon)
//                //                if (Reachability.isConnectedToNetwork()) {
//                //                    self.openSermonScripture(self.selectedSermon)
//                //                } else {
//                //                    let urlString = Constants.SCRIPTURE_URL_PREFIX + self.selectedSermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX
//                //                    self.networkUnavailable("Unable to open scripture at: \(urlString)")
//                //                }
//            })
//            alert.addAction(action)
//        }
//        
//        if (selectedSermon!.hasScripture() && (selectedSermon?.scripture != Constants.Selected_Scriptures)) {
//            action = UIAlertAction(title: Constants.Scripture_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("mail!")
//                self.openSermonScripture(self.selectedSermon)
//                //                if (Reachability.isConnectedToNetwork()) {
//                //                    self.openSermonScripture(self.selectedSermon)
//                //                } else {
//                //                    let urlString = Constants.SCRIPTURE_URL_PREFIX + self.selectedSermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX
//                //                    self.networkUnavailable("Unable to open scripture at: \(urlString)")
//                //                }
//            })
//            alert.addAction(action)
//        }
//        
//        if let sermons = sermonsInSeries {
//            var sermonsToDownload = 0
//            var sermonsDownloading = 0
//            var sermonsDownloaded = 0
//            
//            for sermon in sermons {
//                switch sermon.audioDownload!.state {
//                case .none:
//                    sermonsToDownload++
//                    break
//                case .downloading:
//                    sermonsDownloading++
//                    break
//                case .downloaded:
//                    sermonsDownloaded++
//                    break
//                }
//            }
//            
//            if (sermonsToDownload > 0) {
//                var title:String?
//                switch sermonsToDownload {
//                case 1:
//                    title = Constants.Download_Audio
//                    break
//                    
//                default:
//                    title = Constants.Download_All_Audio
//                    break
//                }
//                action = UIAlertAction(title: title, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    for sermon in sermons {
//                        if (sermon.audioDownload?.state == .none) {
//                            sermon.audioDownload?.download()
//                        }
//                    }
//                    self.tableView.reloadData()
//                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
//
////                    if (Reachability.isConnectedToNetwork()) {
////                        //            println("mail!")
////                        for sermon in sermons {
////                            if (sermon.download.state == .none) {
////                                sermon.downloadAudio()
////                            }
////                        }
////                        self.tableView.reloadData()
////                        self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
////                    } else {
////                        self.networkUnavailable("Unable to download audio.")
////                    }
//                })
//                alert.addAction(action)
//            }
//            
//            if (sermonsDownloading > 0) {
//                action = UIAlertAction(title: Constants.Cancel_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    //            println("mail!")
//                    for sermon in sermons {
//                        if (sermon.audioDownload?.state == .downloading) {
//                            sermon.audioDownload?.cancelDownload()
//                        }
//                    }
//                    self.tableView.reloadData()
//                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
//                })
//                alert.addAction(action)
//            }
//            
//            if (sermonsDownloaded > 0) {
//                action = UIAlertAction(title: Constants.Delete_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                    //            println("mail!")
//                    for sermon in sermons {
//                        if (sermon.audioDownload?.state == .downloaded) {
//                            sermon.audioDownload?.deleteDownload()
//                        }
//                    }
//                    self.tableView.reloadData()
//                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
//                })
//                alert.addAction(action)
//            }
//        }
//        
//        action = UIAlertAction(title: Constants.Email_Sermon, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            //            print("mail!")
//            self.mailSermon(self.selectedSermon)
//        })
//        alert.addAction(action)
//        
//        if (selectedSermon!.hasSeries()) {
//            action = UIAlertAction(title: Constants.Email_Series, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("mail!")
//                self.mailSermonSeries(self.sermonsInSeries)
//            })
//            alert.addAction(action)
//        }
//        
//        if (splitViewController == nil) {
//            action = UIAlertAction(title: Constants.Share_on_Facebook, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                self.facebook(self.selectedSermon)
//            })
//            alert.addAction(action)
//            
//            action = UIAlertAction(title: Constants.Share_on_Twitter, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                self.twitter(self.selectedSermon)
//            })
//            alert.addAction(action)
//        }
        
//        action = UIAlertAction(title: "Message", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
////            print("message!")
//            self.message(self.sermonSelected)
//        })
//        alert.addAction(action)

//        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
////            print("cancel!")
//        })
//        alert.addAction(action)
//        
//        //on iPad this is a popover
//        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
//        alert.popoverPresentationController?.barButtonItem = actionButton
//        
//        presentViewController(alert, animated: true, completion: nil)
    }
    
    func zoomScreen()
    {
        //It works!  Problem was in Globals.mpPlayer?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
        //Thank you StackOverflow!

        Globals.mpPlayer?.setFullscreen(!Globals.mpPlayer!.fullscreen, animated: true)
        
        if (!Globals.mpPlayer!.fullscreen) {
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
        } else {
            setupPlayPauseButton()
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
        }
    }
    
    private func setupPlayerView(view:UIView?)
    {
        if (view != nil) {
            view?.hidden = true
            view?.removeFromSuperview()
            
            view?.gestureRecognizers = nil
            
            let tap = UITapGestureRecognizer(target: self, action: "zoomScreen")
            tap.numberOfTapsRequired = 2
            view?.addGestureRecognizer(tap)
            
            view?.frame = sermonNotesAndSlides.bounds

            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(view!)
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(centerY)
            
            let widthX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthX)
            
            let widthY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides.addConstraint(widthY)
            
            sermonNotesAndSlides.setNeedsLayout()
        }
    }
    
//    private func setupMPPlayerView()
//    {
//        if (Globals.mpPlayer != nil) {
//            Globals.mpPlayer!.view.hidden = true
//            Globals.mpPlayer?.view.removeFromSuperview()
//            
//            let tap = UITapGestureRecognizer(target: self, action: "zoomScreen")
//            tap.numberOfTapsRequired = 2
//            Globals.mpPlayer!.view.addGestureRecognizer(tap)
//
//            Globals.mpPlayer?.view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
//            sermonNotesAndSlides.addSubview(Globals.mpPlayer!.view!)
//            
//            let centerX = NSLayoutConstraint(item: Globals.mpPlayer!.view!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: Globals.mpPlayer!.view!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
//            sermonNotesAndSlides?.addConstraint(centerX)
//            
//            let centerY = NSLayoutConstraint(item: Globals.mpPlayer!.view!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: Globals.mpPlayer!.view!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
//            sermonNotesAndSlides?.addConstraint(centerY)
//            
//            let widthX = NSLayoutConstraint(item: Globals.mpPlayer!.view!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: Globals.mpPlayer!.view!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
//            sermonNotesAndSlides?.addConstraint(widthX)
//            
//            let widthY = NSLayoutConstraint(item: Globals.mpPlayer!.view!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: Globals.mpPlayer!.view!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
//            sermonNotesAndSlides?.addConstraint(widthY)
//        }
//    }
    
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
    
//    private func setupWKWebViews()
//    {
//        sermonNotesWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
//        sermonNotesWebView?.multipleTouchEnabled = true
//        
////        print("\(sermonNotesAndSlides.frame)")
////        sermonNotesWebView?.UIDelegate = self
//        
//        sermonNotesWebView?.scrollView.delegate = self
//        sermonNotesWebView?.navigationDelegate = self
//        sermonNotesWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
//        sermonNotesAndSlides.addSubview(sermonNotesWebView!)
//        
//        sermonSlidesWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
//        sermonSlidesWebView?.multipleTouchEnabled = true
//        
////        print("\(sermonNotesAndSlides.frame)")
////        sermonSlidesWebView?.UIDelegate = self
//
//        sermonSlidesWebView?.scrollView.delegate = self
//        sermonSlidesWebView?.navigationDelegate = self
//        sermonSlidesWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
//        sermonNotesAndSlides.addSubview(sermonSlidesWebView!)
//        
//        let centerXNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(centerXNotes)
//        
//        let centerYNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(centerYNotes)
//        
//        let widthXNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(widthXNotes)
//        
//        let widthYNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(widthYNotes)
//        
//        let centerXSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(centerXSlides)
//        
//        let centerYSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(centerYSlides)
//        
//        let widthXSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(widthXSlides)
//        
//        let widthYSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
//        sermonNotesAndSlides.addConstraint(widthYSlides)
//        
//        sermonNotesAndSlides.setNeedsLayout()
//    }
    
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
            if let view = scrollView.superview as? WKWebView {
                captureContentOffset(view)
            }
        }
    }
    
    func applicationWillResignActive(notification:NSNotification)
    {
        setupPlayingInfoCenter()
//        removePlayObserver()
//        removeSliderObserver()
    }
    
    func applicationWillEnterForeground(notification:NSNotification)
    {
        if (Globals.mpPlayer?.currentPlaybackRate == 0) {
            //It is paused, possibly not by us, but by the system
            //But how do we know it hasn't simply finished playing?
            updateCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
//        addPlayObserver()
//        addSliderObserver()
        setupPlayPauseButton()
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
        
        if (splitViewController != nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateView", name: Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearView", name: Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
        }
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        let tap = UITapGestureRecognizer(target: self, action: "resetConstraint")
        tap.numberOfTapsRequired = 2
        splitView?.addGestureRecognizer(tap)
        
        splitView.splitViewController = splitViewController

        // NO - must be in viewWillAppear() or fullscreen video will crash app when it returns to normal
//        updateUI()
        
//        print("\(Globals.mpPlayer?.contentURL)")
//        print("\(Constants.LIVE_STREAM_URL)")
        if (selectedSermon == Globals.sermonPlaying) && (Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL)) {
            loadingFromLive = true
            
            Globals.mpPlayer?.stop()
            Globals.mpPlayer = nil
            
            setupPlayer(selectedSermon)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
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
        } else {
//            if (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
//                spinner.startAnimating()
//            }
        }

        if (selectedSermon == nil) {
            //Will only happen on an iPad
            let defaults = NSUserDefaults.standardUserDefaults()
            if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
                selectedSermon = Globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                    return sermon.id == selectedSermonKey
                }).first
            }
//            
//            if (selectedSermonKey != nil) {
//                if let sermons = Globals.sermonRepository {
//                    for sermon in sermons {
//                        if (sermon.keyBase == selectedSermonKey!) {
//                            selectedSermon = sermon
//                            break
//                        }
//                    }
//                }
//            }
//        } else {
//            let defaults = NSUserDefaults.standardUserDefaults()
//            defaults.setObject(selectedSermon!.keyBase,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
//            defaults.synchronize()
        }
        
        //We can't set the currentPlaybackTime until the player is ready
        //We need to wait on the state change observer.

        if (Globals.sermonPlaying == selectedSermon) && (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Playing:
                print("viewDidLoad.Playing")
                break
                
            case .SeekingBackward:
                print("viewDidLoad.SeekingBackward")
                break
                
            case .SeekingForward:
                print("viewDidLoad.SeekingForward")
                break
                
            case .Stopped:
                print("viewDidLoad.Stopped")
                break
                
            case .Interrupted:
                print("viewDidLoad.Interrupted")
                break
                
            case .Paused:
                print("viewDidLoad.Paused")
                break
            }
        }
        
        // Do any additional setup after loading the view.
//        setupWKWebViews()
    }

    private func setupDefaultNotesAndSlides()
    {
        if (selectedSermon != nil) {
            splitView.hidden = false
            
            let hasNotes = selectedSermon!.hasNotes()
            let hasSlides = selectedSermon!.hasSlides()
            
            Globals.mpPlayer?.view.hidden = true
            
            if (!hasSlides && !hasNotes) {
                sermonNotesWebView?.hidden = true
                sermonSlidesWebView?.hidden = true
                
                logo.hidden = false
                selectedSermon!.showing = Constants.NONE
                sermonNotesAndSlides.bringSubviewToFront(logo)
            } else
            if (hasSlides && !hasNotes) {
                sermonNotesWebView?.hidden = true
                logo.hidden = true
                
//                sermonSlidesWebView!.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.SLIDES
                sermonNotesAndSlides.bringSubviewToFront(sermonSlidesWebView!)
            } else
            if (!hasSlides && hasNotes) {
                sermonSlidesWebView?.hidden = true
                logo.hidden = true
                
//                sermonNotesWebView!.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.NOTES
                sermonNotesAndSlides.bringSubviewToFront(sermonNotesWebView!)
            } else
            if (hasSlides && hasNotes) {
                sermonNotesWebView?.hidden = true
                logo.hidden = true
                
//                sermonSlidesWebView!.hidden = false // This happens after they load. But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.SLIDES //This is an arbitrary choice
                sermonNotesAndSlides.bringSubviewToFront(sermonSlidesWebView!)
            }
        }
    }
    
    func downloading()
    {
        if (selectedSermon != nil) {
            var download:Download?
            var webView:WKWebView?
            
            switch selectedSermon!.showing! {
            case Constants.SLIDES:
                print("slides")
                download = selectedSermon?.slidesDownload
                webView = sermonSlidesWebView
                break
                
            case Constants.NOTES:
                print("notes")
                download = selectedSermon?.notesDownload
                webView = sermonNotesWebView
                break
                
            default:
                break
            }
            
            if (download != nil) {
                print("totalBytesWritten: \(download!.totalBytesWritten)")
                print("totalBytesExpectedToWrite: \(download!.totalBytesExpectedToWrite)")
                
                switch download!.state {
                case .none:
                    print(".none")
                    download?.task?.cancel()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.loadTimer?.invalidate()
                        self.loadTimer = nil
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.hidden = true
                        
                        self.progressIndicator.hidden = true
                        
                        self.sermonNotesWebView?.hidden = true
                        self.sermonSlidesWebView?.hidden = true
                        Globals.mpPlayer?.view.hidden = true
                        
                        self.logo.hidden = false
                        self.sermonNotesAndSlides.bringSubviewToFront(self.logo)
                    })
                    break
                case .downloading:
                    print(".downloading")
                    progressIndicator.progress = download!.totalBytesExpectedToWrite > 0 ? Float(download!.totalBytesWritten) / Float(download!.totalBytesExpectedToWrite) : 0.0
                    break
                case .downloaded:
                    print(".downloaded")
                    if #available(iOS 9.0, *) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                            webView?.loadFileURL(download!.fileSystemURL!, allowingReadAccessToURL: download!.fileSystemURL!)
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.loadTimer?.invalidate()
                                self.loadTimer = nil
                                
                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.hidden = true
                                
                                self.progressIndicator.hidden = true
                            })
                        })
                    } else {
                        // Fallback on earlier versions
                    }
                    break
                }
            }
            
//            print("slides")
//            if let download = selectedSermon?.slidesDownload {
////                print("totalBytesWritten: \(download.totalBytesWritten)")
////                print("totalBytesExpectedToWrite: \(download.totalBytesExpectedToWrite)")
//                
//                switch download.state {
//                case .downloading:
//                    if (selectedSermon?.showing == Constants.SLIDES) {
//                        progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
//                    }
//                    break
//                    
//                case .downloaded:
//                    if #available(iOS 9.0, *) {
//                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                            self.sermonSlidesWebView?.loadFileURL(self.selectedSermon!.slidesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.slidesFileSystemURL!)
//
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                if (self.selectedSermon?.showing == Constants.SLIDES) {
//                                    self.loadTimer?.invalidate()
//                                    self.loadTimer = nil
//                                    
//                                    self.activityIndicator.stopAnimating()
//                                    self.activityIndicator.hidden = true
//                                    
//                                    self.progressIndicator.hidden = true
//                                }
//                            })
//                        })
//                    } else {
//                        // Fallback on earlier versions
//                    }
//                    break
//                    
//                case .none:
//                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: selectedSermon)
//                    download.task?.cancel()
//                    
//                    if (selectedSermon?.showing == Constants.SLIDES) {
//                        loadTimer?.invalidate()
//                        loadTimer = nil
//                        
//                        activityIndicator.stopAnimating()
//                        activityIndicator.hidden = true
//                        progressIndicator.hidden = true
//                        
//                        sermonNotesWebView?.hidden = true
//                        sermonSlidesWebView?.hidden = true
//                        Globals.mpPlayer?.view.hidden = true
//                        
//                        logo.hidden = false
//                        sermonNotesAndSlides.bringSubviewToFront(self.logo)
//                    }
//                    break
//                }
//            }
//            
//            print("notes")
//            if let download = selectedSermon?.notesDownload {
////                print("totalBytesWritten: \(download.totalBytesWritten)")
////                print("totalBytesExpectedToWrite: \(download.totalBytesExpectedToWrite)")
//                
//                switch download.state {
//                case .downloading:
//                    if (selectedSermon?.showing == Constants.NOTES) {
//                        progressIndicator.progress = download.totalBytesExpectedToWrite > 0 ? Float(download.totalBytesWritten) / Float(download.totalBytesExpectedToWrite) : 0.0
//                    }
//                    break
//                    
//                case .downloaded:
//                    if #available(iOS 9.0, *) {
//                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                            self.sermonNotesWebView?.loadFileURL(self.selectedSermon!.notesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.notesFileSystemURL!)
//                            
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                if (self.selectedSermon?.showing == Constants.NOTES) {
//                                    self.loadTimer?.invalidate()
//                                    self.loadTimer = nil
//                                    
//                                    self.activityIndicator.stopAnimating()
//                                    self.activityIndicator.hidden = true
//                                    
//                                    self.progressIndicator.hidden = true
//                                }
//                            })
//                        })
//                    } else {
//                        // Fallback on earlier versions
//                    }
//                    break
//                    
//                case .none:
//                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.SERMON_UPDATE_UI_NOTIFICATION, object: selectedSermon)
//                    download.task?.cancel()
//                    
//                    if (selectedSermon?.showing == Constants.NOTES) {
//                        loadTimer?.invalidate()
//                        loadTimer = nil
//                        
//                        activityIndicator.stopAnimating()
//                        activityIndicator.hidden = true
//                        progressIndicator.hidden = true
//                        
//                        sermonNotesWebView?.hidden = true
//                        sermonSlidesWebView?.hidden = true
//                        Globals.mpPlayer?.view.hidden = true
//                        
//                        logo.hidden = false
//                        sermonNotesAndSlides.bringSubviewToFront(self.logo)
//                    }
//                    break
//                }
//            }
        } else {
            loadTimer?.invalidate()
            loadTimer = nil
        }
        
        // This is all trying to catch download failures, but I'm afraid it is generating false positives.
        //
        //        if (download?.state != .downloading) && (download?.state != .downloaded) {
        //            downloadFailed()
        //
        //            download?.task?.cancel()
        //
        //            loadTimer?.invalidate()
        //            loadTimer = nil
        //
        //            activityIndicator.stopAnimating()
        //            activityIndicator.hidden = true
        //            progressIndicator.hidden = true
        //
        //            sermonNotesWebView?.hidden = true
        //            sermonSlidesWebView?.hidden = true
        //            Globals.mpPlayer?.view.hidden = true
        //            
        //            logo.hidden = false
        //            sermonNotesAndSlides.bringSubviewToFront(self.logo)
        //        }
    }

    func loading()
    {
        // Expected to be on the main thread
        
        if selectedSermon != nil {
            switch selectedSermon!.showing! {
            case Constants.SLIDES:
                if (sermonSlidesWebView != nil) {
                    progressIndicator.progress = Float(sermonSlidesWebView!.estimatedProgress)
                }
                break
                
            case Constants.NOTES:
                if (sermonNotesWebView != nil) {
                    progressIndicator.progress = Float(sermonNotesWebView!.estimatedProgress)
                }
                break
                
            default:
                break
            }
        }
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            progressIndicator.hidden = true
        }
    }
    
    private func setupNotesSlidesVideo()
    {
        sermonNotesWebView?.removeFromSuperview()
        sermonSlidesWebView?.removeFromSuperview()
        
        sermonNotesWebView = nil
        sermonSlidesWebView = nil
        
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
                sermonNotesWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
                setupWKWebView(sermonNotesWebView)
                
                sermonNotesWebView?.hidden = true
                sermonNotesWebView?.stopLoading()
                
                if #available(iOS 9.0, *) {
                    if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
                        if (selectedSermon?.notesDownload?.state != .downloaded){
                            //                        if (Reachability.isConnectedToNetwork()) {
                            activityIndicator.hidden = false
                            activityIndicator.startAnimating()
                            
                            progressIndicator.progress = selectedSermon!.notesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.notesDownload!.totalBytesWritten) / Float(selectedSermon!.notesDownload!.totalBytesExpectedToWrite) : 0.0
                            progressIndicator.hidden = false
                            if loadTimer == nil {
                                loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "downloading", userInfo: nil, repeats: true)
                            }
                            
                            selectedSermon?.notesDownload?.download()
                            //                        } else {
                            //                            self.networkUnavailable("Unable to open transcript at: \(notesURL)")
                            //                        }
                        } else {
//                            print("\(selectedSermon!.notesFileSystemURL!)")
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                self.sermonNotesWebView?.loadFileURL(self.selectedSermon!.notesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.notesFileSystemURL!)
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    if (self.selectedSermon?.showing == Constants.NOTES) {
                                        self.loadTimer?.invalidate()
                                        self.loadTimer = nil
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.hidden = true
                                        self.progressIndicator.progress = 0.0
                                        self.progressIndicator.hidden = true
                                    }
                                })
                            })
                        }
                    } else {
                        //                    if (Reachability.isConnectedToNetwork()) {
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityIndicator.hidden = false
                                self.activityIndicator.startAnimating()
                                
                                self.progressIndicator.hidden = false
                                if self.loadTimer == nil {
                                    self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                                }
                            })
                            
                            let request = NSURLRequest(URL: self.selectedSermon!.notesURL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                            self.sermonNotesWebView!.loadRequest(request)
                        })
                        //                    } else {
                        //                        self.networkUnavailable("Unable to open transcript at: \(notesURL)")
                        //                    }
                    }
                } else {
                    //                    if (Reachability.isConnectedToNetwork()) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activityIndicator.hidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.hidden = false
                            if self.loadTimer == nil {
                                self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                            }
                        })
                        
                        let request = NSURLRequest(URL: self.selectedSermon!.notesURL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                        self.sermonNotesWebView!.loadRequest(request)
                    })
                    //                    } else {
                    //                        self.networkUnavailable("Unable to open transcript at: \(notesURL)")
                    //                    }
                }
                
//                if (Reachability.isConnectedToNetwork()) {
//                    sermonNotesWebView!.hidden = true // Will be made visible when the URL finishes loading
//
//                    activityIndicator.hidden = false
//                    activityIndicator.startAnimating()
//
//                    progressIndicator.hidden = false
//                    if loadTimer == nil {
//                        loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
//                    }
//                    
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                        self.sermonNotesWebView!.stopLoading()
//                        let request = NSURLRequest(URL: NSURL(string: notesURL)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//                        self.sermonNotesWebView!.loadRequest(request)
//                    })
//                } else {
//                    networkUnavailable("Unable to open sermon transcript: \(notesURL)")
//                }
            } else {
                sermonNotesWebView?.hidden = true
            }
            
            if (selectedSermon!.hasSlides()) {
                sermonSlidesWebView = WKWebView(frame: sermonNotesAndSlides.bounds)
                setupWKWebView(sermonSlidesWebView)
                
                sermonSlidesWebView?.hidden = true
                sermonSlidesWebView?.stopLoading()
                
                if #available(iOS 9.0, *) {
                    if NSUserDefaults.standardUserDefaults().boolForKey(Constants.CACHE_DOWNLOADS) {
                        if (selectedSermon?.slidesDownload?.state != .downloaded){
                            //                        if (Reachability.isConnectedToNetwork()) {
                            activityIndicator.hidden = false
                            activityIndicator.startAnimating()
                            
                            progressIndicator.progress = selectedSermon!.slidesDownload!.totalBytesExpectedToWrite != 0 ? Float(selectedSermon!.slidesDownload!.totalBytesWritten) / Float(selectedSermon!.slidesDownload!.totalBytesExpectedToWrite) : 0.0
                            progressIndicator.hidden = false
                            if loadTimer == nil {
                                loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "downloading", userInfo: nil, repeats: true)
                            }
                            
                            selectedSermon?.slidesDownload?.download()
                            //                        } else {
                            //                            self.networkUnavailable("Unable to open transcript at: \(slidesURL)")
                            //                        }
                        } else {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                self.sermonSlidesWebView?.loadFileURL(self.selectedSermon!.slidesFileSystemURL!, allowingReadAccessToURL: self.selectedSermon!.slidesFileSystemURL!)
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    if (self.selectedSermon?.showing == Constants.NOTES) {
                                        self.loadTimer?.invalidate()
                                        self.loadTimer = nil
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.hidden = true
                                        self.progressIndicator.progress = 0.0
                                        self.progressIndicator.hidden = true
                                    }
                                })
                            })
                        }
                    } else {
                        //                    if (Reachability.isConnectedToNetwork()) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityIndicator.hidden = false
                                self.activityIndicator.startAnimating()
                                
                                self.progressIndicator.hidden = false
                                if self.loadTimer == nil {
                                    self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                                }
                            })
                            
                            let request = NSURLRequest(URL: self.selectedSermon!.slidesURL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                            self.sermonSlidesWebView!.loadRequest(request)
                        })
                        //                    } else {
                        //                        self.networkUnavailable("Unable to open transcript at: \(slidesURL)")
                        //                    }
                    }
                } else {
                    //                    if (Reachability.isConnectedToNetwork()) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activityIndicator.hidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.hidden = false
                            if self.loadTimer == nil {
                                self.loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                            }
                        })
                        
                        let request = NSURLRequest(URL: self.selectedSermon!.slidesURL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                        self.sermonSlidesWebView!.loadRequest(request)
                    })
                    //                    } else {
                    //                        self.networkUnavailable("Unable to open transcript at: \(slidesURL)")
                    //                    }
                }

//                if (Reachability.isConnectedToNetwork()) {
//                    sermonSlidesWebView!.hidden = true // Will be made visible when the URL finishes loading
//                    
//                    activityIndicator.hidden = false
//                    activityIndicator.startAnimating()
//                    
//                    progressIndicator.hidden = false
//                    if loadTimer == nil {
//                        loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
//                    }
//                    
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                        self.sermonSlidesWebView!.stopLoading()
//                        let request = NSURLRequest(URL: NSURL(string: slidesURL)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
//                        self.sermonSlidesWebView!.loadRequest(request)
//                    })
//                } else {
//                    networkUnavailable("Unable to open sermon slides: \(slidesURL)")
//                }
            } else {
                sermonSlidesWebView?.hidden = true
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
                sermonSlidesWebView?.hidden = true
                logo.hidden = true
                
//                self.sermonNotesWebView?.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.NOTES
                sermonNotesAndSlides.bringSubviewToFront(sermonNotesWebView!)
                break
                
            case Constants.SLIDES:
                Globals.mpPlayer?.view.hidden = true
                sermonNotesWebView?.hidden = true
                logo.hidden = true
                
//                sermonSlidesWebView?.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon?.showing = Constants.SLIDES
                sermonNotesAndSlides.bringSubviewToFront(sermonSlidesWebView!)
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
                        sermonNotesWebView?.hidden = true
                        sermonSlidesWebView?.hidden = true
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
                
                self.sermonNotesWebView?.hidden = true
                self.sermonSlidesWebView?.hidden = true
                
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
            
            sermonNotesWebView?.hidden = true
            sermonSlidesWebView?.hidden = true
            Globals.mpPlayer?.view.hidden = true
            
            logo.hidden = !shouldShowLogo() // && roomForLogo()
            
            sermonNotesAndSlides.bringSubviewToFront(logo)
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
            
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actions")
            barButtons.append(actionButton!)
        
            if (selectedSermon!.hasTags()) {
                if (selectedSermon?.tagsSet?.count > 1) {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAGS, style: UIBarButtonItemStyle.Plain, target: self, action: "tags:")
                } else {
                    tagsButton = UIBarButtonItem(title: Constants.FA_TAG, style: UIBarButtonItemStyle.Plain, target: self, action: "tags:")
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
            if (sermonNotesWebView != nil) {
                var notesContentOffsetXRatio:Float = 0.0
                var notesContentOffsetYRatio:Float = 0.0
                
                //        print("\(sermonNotesWebView!.scrollView.contentSize)")
                //        print("\(sermonSlidesWebView!.scrollView.contentSize)")
                
                if let ratio = selectedSermon!.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] {
                    notesContentOffsetXRatio = Float(ratio)!
                }
                
                if let ratio = selectedSermon!.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] {
                    notesContentOffsetYRatio = Float(ratio)!
                }
                
                let notesContentOffset = CGPointMake(
                    CGFloat(notesContentOffsetXRatio) * sermonNotesWebView!.scrollView.contentSize.width,
                    CGFloat(notesContentOffsetYRatio) * sermonNotesWebView!.scrollView.contentSize.height)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sermonNotesWebView!.scrollView.setContentOffset(notesContentOffset, animated: false)
                })
            }
            
            if (sermonSlidesWebView != nil) {
                var slidesContentOffsetXRatio:Float = 0.0
                var slidesContentOffsetYRatio:Float = 0.0
                
                if let ratio = selectedSermon!.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] {
                    slidesContentOffsetXRatio = Float(ratio)!
                }
                
                if let ratio = selectedSermon!.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] {
                    slidesContentOffsetYRatio = Float(ratio)!
                }
                
                let slidesContentOffset = CGPointMake(
                    CGFloat(slidesContentOffsetXRatio) * sermonSlidesWebView!.scrollView.contentSize.width,
                    CGFloat(slidesContentOffsetYRatio) * sermonSlidesWebView!.scrollView.contentSize.height)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sermonSlidesWebView!.scrollView.setContentOffset(slidesContentOffset, animated: false)
                })
            }
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        if (self.view.window == nil) {
            return
        }
        
        setupSplitViewController()
        
        captureContentOffsetAndZoomScale()
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
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
        
//        sermonsInSeries = sermonsInSermonSeries(selectedSermon)
        
        //Done in sliderTimer()
//        if (!Globals.sermonLoaded && (Globals.sermonPlaying != nil) && (selectedSermon == Globals.sermonPlaying)) {
//            spinner.startAnimating()
//        }

        // This next line is for the case when video is playing and the video has been zoomed to full screen and that makes the embedded controls visible
        // allowing the user to control playback, pausing or stopping, and then unzooming makes the play pause button vislble and it has to be
        // updated according to the player state, which may have changed.
        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.playerPaused = (Globals.mpPlayer?.playbackState == .Paused) || (Globals.mpPlayer?.playbackState == .Stopped)
        }
        
        //Done in sliderTimer()
//        if (Globals.sermonLoaded || (selectedSermon != Globals.sermonPlaying)) {
//            // Redundant - also done in viewDidLoad
//            spinner.stopAnimating()
//            spinner.hidden = true
//        } else {
//            //            //This is really misplaced since we're dependent upon the AppDelegate to address loading the default sermon and setting the currentPlayTime.
//            //            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
//        }
        
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
    
    private func captureContentOffset(webView:WKWebView?)
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) && (webView != nil) && (!webView!.loading) && (webView!.URL != nil) {
            if webView == sermonNotesWebView {
                selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.x / sermonNotesWebView!.scrollView.contentSize.width)"
                selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.y / sermonNotesWebView!.scrollView.contentSize.height)"
            }
            if webView == sermonSlidesWebView {
                selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.x / sermonSlidesWebView!.scrollView.contentSize.width)"
                selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.y / sermonSlidesWebView!.scrollView.contentSize.height)"
            }
        }
    }
    
    private func captureZoomScale(webView:WKWebView?)
    {
        //        print("captureZoomScale: \(sermonSelected?.title)")
        
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) && (webView != nil) && (!webView!.loading) && (webView!.URL != nil) {
            if webView == sermonNotesWebView {
                selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE] = "\(sermonNotesWebView!.scrollView.zoomScale)"
            }
            if webView == sermonSlidesWebView {
                selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE] = "\(sermonSlidesWebView!.scrollView.zoomScale)"
            }
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
        captureContentOffset(sermonNotesWebView)
        captureZoomScale(sermonNotesWebView)
        
        captureContentOffset(sermonSlidesWebView)
        captureZoomScale(sermonSlidesWebView)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.rightBarButtonItem = nil
        
        sermonNotesWebView?.stopLoading()
        sermonSlidesWebView?.stopLoading()
        
        // Remove these two lines and this view will crash the app.
        sermonNotesWebView?.scrollView.delegate = nil
        sermonSlidesWebView?.scrollView.delegate = nil
        
//        print("viewWillDisappear: \(sermonSelected?.title)")

//        captureViewSplit()
//        captureContentOffsetAndZoomScale()
        
        //        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        //        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
        //
        //        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning: \(selectedSermon?.title)")
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    
    func tap(sender: MyViewController) {
//        print("tap")
        
        if (Globals.sermonPlaying == selectedSermon) && (selectedSermon?.playing == Constants.VIDEO) {
//            for constraint in Globals.mpPlayer!.view.constraints {
//                constraint.active = false
//            }
//            Globals.mpPlayer?.setFullscreen(true, animated: true)
        } else {
            // set a transition style
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
                
                switch self.selectedSermon!.showing! {
                case Constants.NOTES:
                    self.sermonSlidesWebView?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.sermonSlidesWebView!)
                    self.selectedSermon!.showing = Constants.SLIDES
                    break
                    
                case Constants.SLIDES:
                    self.sermonNotesWebView?.hidden = false
                    self.sermonNotesAndSlides.bringSubviewToFront(self.sermonNotesWebView!)
                    self.selectedSermon!.showing = Constants.NOTES
                    break
                    
                default:
                    self.sermonNotesAndSlides.bringSubviewToFront(self.logo)
                    break
                }
                
                }, completion: { finished in
                    
            })
        }
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
        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            if (Globals.mpPlayer!.fullscreen) {
                Globals.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded
            } else {
                Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            }
            
            if (selectedSermon == Globals.sermonPlaying) {
                playPauseButton.enabled = Globals.sermonLoaded
                slider.enabled = Globals.sermonLoaded
                
                if (!Globals.sermonLoaded) {
                    if (!spinner.isAnimating()) {
                        spinner.hidden = false
                        spinner.startAnimating()
                    }
                } else {
                    if (Globals.mpPlayer?.playbackState != .SeekingForward) && (Globals.mpPlayer?.playbackState != .SeekingBackward) {
                        setSliderAndTimesToAudio()
                        if spinner.isAnimating() {
                            spinner.stopAnimating()
                            spinner.hidden = true
                        }
                    } else {
                        if !spinner.isAnimating() {
                            spinner.hidden = false
                            spinner.startAnimating()
                        }
                    }
                }
            }
            
            if (Globals.mpPlayer?.currentPlaybackRate > 0) {
                updateUserDefaultsCurrentTimeWhilePlaying()
            }
            
            if (Globals.mpPlayer != nil) {
                switch Globals.mpPlayer!.playbackState {
                case .Interrupted:
                    print("sliderTimer.Interrupted")
                    break
                    
                case .Paused:
//                    print("sliderTimer.Paused")
//                    if (!Globals.playerPaused) {
//                        Globals.mpPlayer?.play()
//                        Globals.playerPaused = true
//                        setupPlayPauseButton()
//                    }
                    break
                    
                case .Playing:
//                    print("sliderTimer.Playing")
//                    if (Globals.playerPaused) {
//                        Globals.mpPlayer?.pause()
//                        Globals.playerPaused = false
//                        setupPlayPauseButton()
//                    }
                    break
                    
                case .SeekingBackward:
                    print("sliderTimer.SeekingBackward")
                    break
                    
                case .SeekingForward:
                    print("sliderTimer.SeekingForward")
                    break
                    
                case .Stopped:
//                    print("sliderTimer.Stopped")
                    break
                }
            }
            
            //        print("Duration: \(Globals.mpPlayer!.duration) CurrentPlaybackTime: \(Globals.mpPlayer!.currentPlaybackTime)")
            //        print("CurrentTime: \(Globals.sermonPlaying?.currentTime)")
            
            if (Globals.mpPlayer!.duration > 0) && (Globals.mpPlayer!.currentPlaybackTime > 0) &&
                (slider.value > 0.9999) {
                    // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
                    //            (Int(Globals.mpPlayer!.currentPlaybackTime) == Int(Globals.mpPlayer!.duration)) {
                    //            print("sliderTimer currentPlaybackTime == duration")
                    
                    Globals.mpPlayer?.pause()
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                    
                    Globals.sermonPlaying?.currentTime = Globals.mpPlayer!.duration.description
                    
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
    
    func addSliderObserver()
    {
//        print("addSliderObserver in")

        if (Globals.sliderObserver != nil) {
            Globals.sliderObserver?.invalidate()
            Globals.sliderObserver = nil
        }

        if (Globals.mpPlayer != nil) {
            Globals.sliderObserver = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "sliderTimer", userInfo: nil, repeats: true)
        } else {
            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
            print("Globals.player == nil in sliderObserver")
            // Should we setup the player all over again?
        }

//        print("addSliderObserver out")
    }
    
//    func addPlayObserver()
//    {
//        if (Globals.playObserver != nil) {
//            Globals.playObserver?.invalidate()
//            Globals.playObserver = nil
//        }
//
//        if (Globals.mpPlayer != nil) {
//            //Update for MPPlayer
//            Globals.playObserver = NSTimer.scheduledTimerWithTimeInterval(Constants.PLAY_OBSERVER_TIME_INTERVAL, target: self, selector: "playTimer", userInfo: nil, repeats: true)
//        } else {
//            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
//            print("Globals.player == nil in playObserver")
//            // Should we setup the player all over again?
//        }
//    }

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
    
    func seekingTimer()
    {
        setupPlayingInfoCenter()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        print("remoteControlReceivedWithEvent")
        
        switch event!.subtype {
        case UIEventSubtype.MotionShake:
            print("RemoteControlShake")
            break
            
        case UIEventSubtype.None:
            print("RemoteControlNone")
            break
            
        case UIEventSubtype.RemoteControlStop:
            print("RemoteControlStop")
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
            break
            
        case UIEventSubtype.RemoteControlPlay:
            print("RemoteControlPlay")
            Globals.mpPlayer?.play()
            Globals.playerPaused = false
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlPause:
            print("RemoteControlPause")
            Globals.mpPlayer?.pause()
            Globals.playerPaused = true
            updateCurrentTimeExact()
            break
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            print("RemoteControlTogglePlayPause")
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            break
            
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("RemoteControlPreviousTrack")
            break
            
        case UIEventSubtype.RemoteControlNextTrack:
            print("RemoteControlNextTrack")
            break
            
            //The lock screen time elapsed/remaining don't track well with seeking
            //But at least this has them moving in the right direction.
            
        case UIEventSubtype.RemoteControlBeginSeekingBackward:
            print("RemoteControlBeginSeekingBackward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingBackward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingBackward:
            print("RemoteControlEndSeekingBackward")
            Globals.mpPlayer?.endSeeking()
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlBeginSeekingForward:
            print("RemoteControlBeginSeekingForward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingForward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingForward:
            print("RemoteControlEndSeekingForward")
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            Globals.mpPlayer?.endSeeking()
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
        }

        setupPlayPauseButton()
    }

    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        let player = notification.object as! MPMoviePlayerController
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)

        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0

//        print("\(loadstate)")
//        print("\(playable)")
//        print("\(playthrough)")
        
        if (playable || playthrough) &&  !Globals.sermonLoaded && (Globals.sermonPlaying != nil) {
//            print("\(Globals.sermonPlaying!.currentTime!)")
//            print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
            
            // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
            if Globals.sermonPlaying!.hasCurrentTime() {
                if !loadingFromLive && (Int(Float(Globals.sermonPlaying!.currentTime!)!) == Int(Globals.mpPlayer!.duration)) {
                    Globals.sermonPlaying?.currentTime = Constants.ZERO
                }
            } else {
                Globals.sermonPlaying?.currentTime = Constants.ZERO
            }

            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)

            updateCurrentTimeExact()
            setupPlayingInfoCenter()
            
            spinner.stopAnimating()
            Globals.sermonLoaded = true
            
            if !loadingFromLive {
                Globals.mpPlayer?.play()
            }
            
            playPauseButton.enabled = true
            slider.enabled = true
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }
        
        //For playing
        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
                print("MVC.mpPlayerLoadStateDidChange.Interrupted")
                break
                
            case .Paused:
                print("MVC.mpPlayerLoadStateDidChange.Paused")
                break
                
            case .Playing:
                print("MVC.mpPlayerLoadStateDidChange.Playing")
                //Why do we need the following?
                spinner.stopAnimating()
                spinner.hidden = true
                setupPlayingInfoCenter()
                NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
                break
                
            case .SeekingBackward:
                print("MVC.mpPlayerLoadStateDidChange.SeekingBackward")
                break
                
            case .SeekingForward:
                print("MVC.mpPlayerLoadStateDidChange.SeekingForward")
                break
                
            case .Stopped:
                print("MVC.mpPlayerLoadStateDidChange.Stopped")
                //Why do we need the following?
                if !Globals.playerPaused {
                    Globals.mpPlayer?.play()
                }
                break
            }
        }
    }
    
    private func playNewSermon(sermon:Sermon?) {
        Globals.mpPlayer?.stop()
        
        Globals.mpPlayer?.view.removeFromSuperview()
        
        captureContentOffsetAndZoomScale()
        
        if (sermon != nil) && (sermon!.hasVideo() || sermon!.hasAudio()) {
            Globals.sermonPlaying = sermon
            Globals.playerPaused = false
            
            Globals.mpPlayer?.stop()
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            Globals.mpPlayer = MPMoviePlayerController(contentURL: sermon?.playingURL)
            
//            print("\(Globals.mpPlayer?.contentURL)")
            
            setupPlayerView(Globals.mpPlayer?.view)
            
            if (sermon!.hasVideo() && (sermon!.playing == Constants.VIDEO)) {
                if (view.window != nil) {
                    Globals.mpPlayer!.view.hidden = false
                    sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view!)
                }
                sermon!.showing = Constants.VIDEO
            }
            
            Globals.mpPlayer?.shouldAutoplay = false
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
            Globals.mpPlayer?.prepareToPlay()

            // This stops the spinner spinning once the audio starts
            Globals.sermonLoaded = false
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
            
            setupPlayingInfoCenter()

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
        captureContentOffsetAndZoomScale()
        
        if (selectedSermon != sermonsInSeries![indexPath.row]) || (Globals.sermonHistory == nil) {
            addToHistory(sermonsInSeries![indexPath.row])
        }
        selectedSermon = sermonsInSeries![indexPath.row]

        if (selectedSermon == Globals.sermonPlaying) && (Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL)) {
            loadingFromLive = true
            
            Globals.mpPlayer?.stop()
            Globals.mpPlayer = nil
            
            setupPlayer(selectedSermon)
            
            setupPlayerView(Globals.mpPlayer?.view)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
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
            //            sermonNotesWebView?.hidden = true
            //            sermonSlidesWebView?.hidden = true
            //            Globals.mpPlayer?.view.hidden = true

            if (webView == sermonNotesWebView) {
                sermonNotesWebView = nil
                if (selectedSermon?.showing == Constants.NOTES) {
                    networkUnavailable(withError.localizedDescription)
                }
            }
            
            if (webView == sermonSlidesWebView) {
                sermonSlidesWebView = nil
                if (selectedSermon?.showing == Constants.SLIDES) {
                    networkUnavailable(withError.localizedDescription)
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
            //            sermonNotesWebView?.hidden = true
            //            sermonSlidesWebView?.hidden = true
            //            Globals.mpPlayer?.view.hidden = true
            
            if (webView == sermonNotesWebView) {
                sermonNotesWebView = nil
                if (selectedSermon?.showing == Constants.NOTES) {
                    networkUnavailable(withError.localizedDescription)
                }
            }
            
            if (webView == sermonSlidesWebView) {
                sermonSlidesWebView = nil
                if (selectedSermon?.showing == Constants.SLIDES) {
                    networkUnavailable(withError.localizedDescription)
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
//        
//        print("zoomScale: \(wkWebView.scrollView.zoomScale)")
//        print("contentScaleFactor: \(wkWebView.scrollView.contentScaleFactor)")
//        
//        print("contentOffset: \(wkWebView.scrollView.contentOffset)")
//        
//        print("contentInset: \(wkWebView.scrollView.contentInset)")
//        print("contentSize: \(wkWebView.scrollView.contentSize)")
//        
//        print("minimumZoomScale: \(wkWebView.scrollView.minimumZoomScale)")
//        print("maximumZoomScale: \(wkWebView.scrollView.maximumZoomScale)")

//        var newScale = scale
//        
//        if newScale > wkWebView.scrollView.maximumZoomScale {
//            newScale = wkWebView.scrollView.maximumZoomScale
//        }
//        
//        if newScale < wkWebView.scrollView.minimumZoomScale {
//            newScale = wkWebView.scrollView.minimumZoomScale
//        }
//        
//        var newOffset = offset
//        
//        if newOffset.y > wkWebView.scrollView.contentSize.height {
//            newOffset.y = wkWebView.scrollView.contentSize.height
//        }
//        
//        if newOffset.x > wkWebView.scrollView.contentSize.width {
//            newOffset.x = wkWebView.scrollView.contentSize.width
//        }
        

//        print("zoomScale after: \(wkWebView.scrollView.zoomScale)")
//        print("contentScaleFactor after: \(wkWebView.scrollView.contentScaleFactor)")

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
    
    func notesContentOffset() -> CGPoint?
    {
        var notesContentOffsetXRatio:Float = 0.0
        var notesContentOffsetYRatio:Float = 0.0
        
        if let ratio = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] {
            notesContentOffsetXRatio = Float(ratio)!
        }
        
        if let ratio = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] {
            notesContentOffsetYRatio = Float(ratio)!
        }
        
        let notesContentOffset = CGPointMake(  CGFloat(notesContentOffsetXRatio) * sermonNotesWebView!.scrollView.contentSize.width,
            CGFloat(notesContentOffsetYRatio) * sermonNotesWebView!.scrollView.contentSize.height)
        
        return notesContentOffset
    }
    
    func setNotesContentOffsetAndZoomScale()
    {
//        print("setNotesContentOffsetAndZoomScale Loading: \(sermonNotesWebView!.loading)")

        var notesZoomScale:CGFloat = 1.0
        
        var notesContentOffsetXRatio:Float = 0.0
        var notesContentOffsetYRatio:Float = 0.0
        
        if let ratio = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] {
//            print("X ratio string: \(ratio)")
            notesContentOffsetXRatio = Float(ratio)!
        } else {
//            print("No notes X ratio")
        }
        
        if let ratio = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] {
//            print("Y ratio string: \(ratio)")
            notesContentOffsetYRatio = Float(ratio)!
        } else {
//            print("No notes Y ratio")
        }
        
        if let zoomScale = selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE] {
            notesZoomScale = CGFloat(Float(zoomScale)!)
        } else {
//            print("No notes zoomScale")
        }
        
//        print("\(notesContentOffsetXRatio)")
//        print("\(sermonNotesWebView!.scrollView.contentSize.width)")
//        print("\(notesZoomScale)")
        
        let notesContentOffset = CGPointMake(   CGFloat(notesContentOffsetXRatio) * sermonNotesWebView!.scrollView.contentSize.width * notesZoomScale,
                                                CGFloat(notesContentOffsetYRatio) * sermonNotesWebView!.scrollView.contentSize.height * notesZoomScale)
        
        wkSetZoomScaleThenContentOffset(sermonNotesWebView!, scale: notesZoomScale, offset: notesContentOffset)
    }
    
    func slidesContentOffset() -> CGPoint?
    {
        var slidesContentOffsetXRatio:Float = 0.0
        var slidesContentOffsetYRatio:Float = 0.0
        
        if let ratio = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] {
            slidesContentOffsetXRatio = Float(ratio)!
        }
        
        if let ratio = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] {
            slidesContentOffsetYRatio = Float(ratio)!
        }
        
        let slidesContentOffset = CGPointMake(  CGFloat(slidesContentOffsetXRatio) * sermonSlidesWebView!.scrollView.contentSize.width,
            CGFloat(slidesContentOffsetYRatio) * sermonSlidesWebView!.scrollView.contentSize.height)
        
        return slidesContentOffset
    }
    
    func setSlidesContentOffsetAndZoomScale()
    {
//        print("setSlidesContentOffsetAndZoomScale Loading: \(sermonSlidesWebView!.loading)")

        var slidesZoomScale:CGFloat = 1.0
        
        var slidesContentOffsetXRatio:Float = 0.0
        var slidesContentOffsetYRatio:Float = 0.0
        
        if let ratio = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] {
//            print("X ratio string: \(ratio)")
            slidesContentOffsetXRatio = Float(ratio)!
        } else {
//            print("No slides X ratio")
        }
        
        if let ratio = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] {
//            print("Y ratio string: \(ratio)")
            slidesContentOffsetYRatio = Float(ratio)!
        } else {
//            print("No slides Y ratio")
        }
        
        if let zoomScale = selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE] {
            slidesZoomScale = CGFloat(Float(zoomScale)!)
        } else {
//            print("No slides zoomScale")
        }
        
        let slidesContentOffset = CGPointMake(  CGFloat(slidesContentOffsetXRatio) * sermonSlidesWebView!.scrollView.contentSize.width * slidesZoomScale,
                                                CGFloat(slidesContentOffsetYRatio) * sermonSlidesWebView!.scrollView.contentSize.height * slidesZoomScale)
        
        wkSetZoomScaleThenContentOffset(sermonSlidesWebView!, scale: slidesZoomScale, offset: slidesContentOffset)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
//        print("wkWebViewDidFinishNavigation Loading:\(webView.loading)")
        
//        print("Frame: \(webView.frame)")
//        print("Bounds: \(webView.bounds)")

        if (self.view != nil) {
            if (selectedSermon != nil) {
                if (webView == sermonNotesWebView) {
                    print("sermonNotesWebView")
                    if (selectedSermon!.showingNotes()) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                            self.progressIndicator.hidden = true
                            
                            self.setupSTVControl()
                            
                            print("sermonNotesWebView:hidden=panning")
                            webView.hidden = self.panning
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            print("sermonNotesWebView:hidden=true")
                            webView.hidden = true
                        })
                    }
                    setNotesContentOffsetAndZoomScale()
                }
                if (webView == sermonSlidesWebView) {
                    print("sermonSlidesWebView")
                    if (selectedSermon!.showingSlides()) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.hidden = true
                            
                            self.loadTimer?.invalidate()
                            self.loadTimer = nil
                            self.progressIndicator.hidden = true
                            
                            self.setupSTVControl()
                            
                            print("sermonSlidesWebView:hidden=panning")
                            webView.hidden = self.panning
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            print("sermonSlidesWebView:hidden=true")
                            webView.hidden = true
                        })
                    }
                    setSlidesContentOffsetAndZoomScale()
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
