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

    override func canBecomeFirstResponder() -> Bool {
        return splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            setupPlayPauseButton()
        }
    }
    
    var selectedSermon:Sermon?
    var sermonsInSeries:[Sermon]?

    var loadTimer:NSTimer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!

    var popover : PopoverTableViewController?
    
    func rowClickedAtIndex(index:Int, strings:[String], purpose:PopoverPurpose) {}
    
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
                    updateUserDefaultsCurrentTimeExact()
                    
                    Globals.mpPlayer?.view.hidden = true
                    Globals.mpPlayer?.stop()
                    
                    Globals.playerPaused = true
                    Globals.sermonPlaying = nil
                    
                    spinner.stopAnimating()
                    spinner.hidden = true
                    
                    removePlayObserver()
                    removeSliderObserver()
                    
                    captureContentOffsetAndZoomScale()
                    setupPlayPauseButton()
                    setupSlider()
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.removeObjectForKey(Constants.SERMON_PLAYING)
                    defaults.synchronize()
                }
                
                selectedSermon?.playing = Constants.AUDIO // Must come before setupNoteAndSlides()
                setupNotesAndSlides() // Calls setupSTVControl()
                
                saveSermonSettings()
                break
                
            default:
                break
            }
            break
            
        case Constants.VIDEO_SEGMENT_INDEX:
            switch selectedSermon!.playing! {
            case Constants.AUDIO:
                if (Globals.sermonPlaying == selectedSermon) {
                    updateUserDefaultsCurrentTimeExact()
                    
                    Globals.mpPlayer?.stop()
                    
                    Globals.playerPaused = true
                    Globals.sermonPlaying = nil
                    
                    spinner.stopAnimating()
                    spinner.hidden = true
                    
                    removePlayObserver()
                    removeSliderObserver()
                    
                    captureContentOffsetAndZoomScale()
                    setupPlayPauseButton()
                    setupSlider()
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.removeObjectForKey(Constants.SERMON_PLAYING)
                    defaults.synchronize()
                }
                
                selectedSermon?.playing = Constants.VIDEO // Must come before setupNoteAndSlides()
                setupNotesAndSlides() // Calls setupSTVControl()
                
                saveSermonSettings()
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
            view = sermonSlidesWebView
            break
            
        case Constants.NOTES:
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
            
                self.sermonSlidesWebView?.hidden = false
                self.sermonNotesAndSlides.bringSubviewToFront(self.sermonSlidesWebView!)
                self.selectedSermon!.showing = Constants.SLIDES
            
                }, completion: { finished in
                    view!.hidden = true
            })
            break

        case Constants.FA_TRANSCRIPT_SEGMENT_TITLE:
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
                
                self.sermonNotesWebView?.hidden = false
                self.sermonNotesAndSlides.bringSubviewToFront(self.sermonNotesWebView!)
                self.selectedSermon!.showing = Constants.NOTES
                
                }, completion: { finished in
                    view!.hidden = true
            })
            break
        
        case Constants.FA_VIDEO_SEGMENT_TITLE:
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.sermonNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {

                var playerView:UIView!
                
                playerView = Globals.mpPlayer?.view
                
                playerView.hidden = false

                self.sermonNotesAndSlides.bringSubviewToFront(playerView)
                self.selectedSermon!.showing = Constants.VIDEO

                }, completion: { finished in
                    view!.hidden = true
            })
            break
        
        default:
            break
        }

        saveSermonSettings()
    }
    
    func setupSTVControl()
    {
        if (selectedSermon != nil) {
            stvControl.enabled = true
            stvControl.hidden = false

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
            
//                if (Globals.sermonPlaying == selectedSermon) && (selectedSermon?.playing == .video) {
//                    stvControl.selectedSegmentIndex = videoIndex
//                }

            if (stvControl.numberOfSegments < 2) {
                stvControl.enabled = false
                stvControl.hidden = true
                stvWidthConstraint.constant = 0
                view.setNeedsLayout()
            }
        } else {
            stvControl.enabled = false
            stvControl.hidden = true
            stvWidthConstraint.constant = 0
            view.setNeedsLayout()
        }
    }

    //returnToSermon has been deprecated
//    @IBOutlet weak var returnToSermonButton: UIButton!
//    @IBAction func returnToSermonPlaying(sender: UIButton)
//    {
////        print("Selected: \(Globals.sermonSelected?.title) \(Globals.sermonSelected?.series)")
////        print("Playing: \(Globals.sermonPlaying?.title) \(Globals.sermonPlaying?.series)")
//        
//        if (!Globals.sermonLoaded) {
//            spinner.startAnimating()
//        } else {
//            spinner.stopAnimating()
//        }
//        
//        captureViewSplit()
//        captureContentOffsetAndZoomScale()
//        
//        setupSermonsInSeries(Globals.sermonPlaying)
//        selectedSermon = Globals.sermonPlaying
//
//        let defaults = NSUserDefaults.standardUserDefaults()
//        defaults.setObject(selectedSermon!.keyBase,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
//        defaults.synchronize()
//        
//        tableView.reloadData()
//
//        setupTitle()
//        setupViewSplit()
//        setupAudioOrVideo()
//        setupPlayPauseButton()
//        setupReturnToSermonButton()
//        setupActionAndTagsButtons()
//        setupSlider()
//        setupNotesAndSlides()
//        
//        scrollToSermon(selectedSermon,select:true,position:UITableViewScrollPosition.Top)
//    }
    
    @IBAction func playPause(sender: UIButton) {
        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
            let loadstate:UInt8 = UInt8(Globals.mpPlayer!.loadState.rawValue)
            let loadvalue:UInt8 = UInt8(MPMovieLoadState.PlaythroughOK.rawValue)
            
            print("\(loadstate)")
            print("\(loadvalue)")

            if ((loadstate & loadvalue) == (1<<1)) {
                print("mpPlayerLoadStateDidChange.MPMovieLoadState.PlaythroughOK")
            } else {
                print("mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough NOT OK")
            }
            
            switch Globals.mpPlayer!.playbackState {
            case .Playing:
                print("playPause.Playing")
                Globals.playerPaused = true
                
                removePlayObserver()
                
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
                setupPlayPauseButton()
                saveSermonSettings()
                break
                
            case .SeekingBackward:
                print("playPause.SeekingBackward")
                fallthrough
                
            case .SeekingForward:
                print("playPause.SeekingForward")
                fallthrough
                
            case .Stopped:
                print("playPause.Stopped")
                fallthrough
                
            case .Interrupted:
                print("playPause.Interrupted")
                fallthrough
                
            case .Paused:
                print("playPause.Paused")
                Globals.playerPaused = false
                
                var playOn = true
                
                //Since we save the currentPlayTime with each sermon this should work.
                // BUT it blanks the screen and starts from time zero.
//                playNewSermon(Globals.sermonPlaying)
                
                removePlayObserver()
                
                if (selectedSermon?.playing == Constants.AUDIO) {
                    //See if there is a download
                    var sermonURL:String?
                    var fileURL:NSURL?
                    
                    fileURL = documentsURL()?.URLByAppendingPathComponent(selectedSermon!.audio!)
                    if (!NSFileManager.defaultManager().fileExistsAtPath(fileURL!.path!)){
                        sermonURL = "\(Constants.BASE_AUDIO_URL)\(selectedSermon!.audio!)"
                        //        println("playNewSermon: \(sermonURL)")
                        fileURL = NSURL(string:sermonURL!)
                        if !Reachability.isConnectedToNetwork() {
                            networkUnavailable()
                            fileURL = nil
                        }
                    }
                    
                    if (Globals.mpPlayer!.contentURL != fileURL) {
                        print("different url's!")
//                        Globals.mpPlayer?.contentURL = url
                        playOn = false
                        playNewSermon(selectedSermon)
                    } else {
                        playOn = true
                    }
                } else {
                    playOn = true
                }
                
                if (playOn) {
                    print("\(selectedSermon!.currentTime!)")
                    print("\(NSTimeInterval(Float(selectedSermon!.currentTime!)!))")
                    
                    //Make the comparision an Int to avoid missing minor differences
                    if (Int(Float(selectedSermon!.currentTime!)!) < Int(Float(Globals.mpPlayer!.duration))) {
                        Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(selectedSermon!.currentTime!)!)
                    } else {
                        Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                    }
                    
                    if (Globals.mpPlayer?.currentPlaybackTime == 0) {
                        print("Globals.mpPlayer?.currentPlaybackTime == 0!")
                    }
                    
                    //                assert(Float(selectedSermon!.currentTime!)! == Float(Globals.mpPlayer!.currentPlaybackTime),"player and sermon times should be the same")
                    
                    //Make the comparision an Int to avoid missing minor differences
                    if (Globals.mpPlayer!.currentPlaybackTime > 0) {
                        if (Int(Globals.mpPlayer!.currentPlaybackTime) != Int(Float(selectedSermon!.currentTime!)!)) {
                            print("currentPlayBackTime: \(Globals.mpPlayer!.currentPlaybackTime) != currentTime: \(selectedSermon!.currentTime!)")
                        }
                    }
                    
                    spinner.stopAnimating()
                    //Too late now
                    Globals.sermonLoaded = true
                    
                    Globals.mpPlayer?.play()
                    
                    addPlayObserver()
                    setupPlayingInfoCenter()
                    setupPlayPauseButton()
                }
                break
            }
        } else {
            playNewSermon(selectedSermon)
        }
    }
    
    func setupSermonsInSeries(sermon:Sermon?)
    {
        let seriesSermons = Globals.sermons?.filter({ (testSermon:Sermon) -> Bool in
            return testSermon.hasSeries() && (testSermon.series == sermon?.series)
        })
        sermonsInSeries = sortSermonsByYear(seriesSermons, sorting: Globals.sorting)

//        if let sermons = Globals.sermons {
//            var seriesSermons = [Sermon]()
//            
//            if ((sermon != nil) && sermon!.hasSeries()) {
//                for index in 0..<sermons.count {
//                    if (sermons[index].series == sermon?.series) {
//                        seriesSermons.append(sermons[index])
//                    }
//                }
//            } else {
//                if (sermon != nil) {
//                    seriesSermons.append(sermon!)
//                }
//            }
//            
//            sermonsInSeries = sortSermonsByYear(seriesSermons, sorting: Globals.sorting)
//        }
    }
    
    private func sermonNotesAndSlidesConstraintMinMax(height:CGFloat) -> (min:CGFloat,max:CGFloat)
    {
        let minConstraintConstant:CGFloat = tableView.rowHeight*1 + slider.bounds.height + 16 //margin on top and bottom of slider
        
        let maxConstraintConstant:CGFloat = height - logo.bounds.height - slider.bounds.height - navigationController!.navigationBar.bounds.height
        
//        print("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
        
        return (minConstraintConstant,maxConstraintConstant)
    }

    private func setSermonNotesAndSlidesConstraint(change:CGFloat)
    {
        let newConstraintConstant = self.sermonNotesAndSlidesConstraint.constant + change
        
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
        splitView.height = self.sermonNotesAndSlidesConstraint.constant
        self.view.setNeedsLayout()
    }
    
    
    @IBAction func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            captureViewSplit()
            saveSermonSettings()
            break
        
        case .Changed:
            let translation = gesture.translationInView(splitView)
            let change = -translation.y
            if change != 0 {
                gesture.setTranslation(CGPointZero, inView: splitView)
                setSermonNotesAndSlidesConstraint(change)
                self.view.setNeedsLayout()
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
    
    @IBOutlet weak var slider: UISlider!
    
    private func adjustAudioAfterUserMovedSlider()
    {
        if (Globals.mpPlayer == nil) {
            setupPlayer(selectedSermon)
        }
        
        if (Globals.mpPlayer != nil) {
            if (slider.value < 1.0) {
                let length = Float(Globals.mpPlayer!.duration)
                let seekToTime = Float(slider.value * Float(length))
                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(seekToTime)
                updateUserDefaultsCurrentTimeExact(seekToTime)
                
                if (Globals.playerPaused) {
                    Globals.mpPlayer?.pause()
                } else {
                    Globals.mpPlayer?.play()
                }
            } else {
                Globals.playerPaused = true

                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.mpPlayer!.duration))
                updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.duration))
                Globals.mpPlayer?.pause()
            }
            
            setupPlayPauseButton()
            addSliderObserver()

            saveSermonSettings()
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

            bodyString = bodyString! + "\n\nAudio: " + Constants.BASE_AUDIO_URL + sermon!.audio!
            
            if sermon!.hasVideo() {
                bodyString = bodyString! + "\n\nVideo " + Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX
            }
            
            if sermon!.hasSlides() {
                bodyString = bodyString! + "\n\nSlides: " + Constants.BASE_PDF_URL + sermon!.slides!
            }
            
            if sermon!.hasNotes() {
                bodyString = bodyString! + "\n\nTranscript " + Constants.BASE_PDF_URL + sermon!.notes!
            }
        }
        
        return bodyString
    }
    
    func setupSermonBodyHTML(sermon:Sermon?) -> String? {
        var bodyString:String?
        
        if (sermon != nil) {
            bodyString = "\"" + sermon!.title! + "\"" + " by " + sermon!.speaker! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
            
            bodyString = bodyString! + " (<a href=\"" + Constants.BASE_AUDIO_URL + sermon!.audio! + "\">Audio</a>)"
            
            if sermon!.hasVideo() {
                bodyString = bodyString! + " (<a href=\"" + Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX + "\">Video</a>) "
            }

            if sermon!.hasSlides() {
                bodyString = bodyString! + " (<a href=\"" + Constants.BASE_PDF_URL + sermon!.slides! + "\">Slides</a>)"
            }
            
            if sermon!.hasNotes() {
                bodyString = bodyString! + " (<a href=\"" + Constants.BASE_PDF_URL + sermon!.notes! + "\">Transcript</a>) "
            }
            
            bodyString = bodyString! + "<br/>"
        }
        
        return bodyString
    }
    
    func sortSermonsInSeries()
    {
        sermonsInSeries = sortSermonsByYear(sermonsInSeries, sorting: Globals.sorting)
        tableView.reloadData()
        scrollToSermon(selectedSermon, select: true, position:UITableViewScrollPosition.None)
    }
    
    func setupSermonSeriesBodyHTML(sermonsInSeries:[Sermon]?) -> String? {
        var bodyString:String?

        if let sermons = sermonsInSeries {
            if (sermons.count > 0) {
                bodyString = "\"\(sermons[0].series!)\" by \(sermons[0].speaker!)"
                bodyString = bodyString! + " from <a href=\"\(Constants.CBC_WEBSITE)\">" + Constants.CBC_LONG + "</a>"
                bodyString = bodyString! + "<br/>" + "<br/>"
                
                let sermonList = sermons.sort() {
                    if ($0.fullDate!.isEqualToDate($1.fullDate!)) {
                        return $0.service == Constants.MORNING_SERVICE
                    } else {
                        return $0.fullDate!.isLessThanDate($1.fullDate!)
                    }
                }
                
                for sermon in sermonList {
                    bodyString = bodyString! + sermon.title!
                    
                    bodyString = bodyString! + " (<a href=\"" + Constants.BASE_AUDIO_URL + sermon.audio! + "\">Audio</a>)"
                    
                    if sermon.hasVideo() {
                        bodyString = bodyString! + " (<a href=\"" + Constants.BASE_VIDEO_URL_PREFIX + sermon.video! + Constants.BASE_VIDEO_URL_POSTFIX + "\">Video</a>) "
                    }
                    
                    if sermon.hasSlides() {
                        bodyString = bodyString! + " (<a href=\"" + Constants.BASE_PDF_URL + sermon.slides! + "\">Slides</a>)"
                    }
                    
                    if sermon.hasNotes() {
                        bodyString = bodyString! + " (<a href=\"" + Constants.BASE_PDF_URL + sermon.notes! + "\">Transcript</a>) "
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
            var printURL:String?
            
            switch sermon!.showing! {
            case Constants.NOTES:
                printURL = Constants.BASE_PDF_URL + sermon!.notes!
                break
            case Constants.SLIDES:
                printURL = Constants.BASE_PDF_URL + sermon!.slides!
                break
                
            default:
                break
            }
            
            if (printURL != nil) && UIPrintInteractionController.canPrintURL(NSURL(string: printURL!)!) {
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
                
                pic.printingItem = NSURL(string: printURL!)!
                pic.presentFromBarButtonItem(navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    private func openSermonScripture(sermon:Sermon?)
    {
        var urlString = Constants.SCRIPTURE_URL_PREFIX + sermon!.scripture! + Constants.SCRIPTURE_URL_POSTFIX

        urlString = urlString.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)

//        print("\(sermon!.scripture!)")
//        print("\(urlString)")
//        print("\(NSURL(string:urlString))")
        
        if let url = NSURL(string:urlString) {
            if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(url)) {
                UIApplication.sharedApplication().openURL(url)
            } else {
                networkUnavailable()
            }
        }
    }
    
    func twitter(sermon:Sermon?)
    {
        assert(sermon != nil, "can't tweet about a nil sermon")

        if Reachability.isConnectedToNetwork() {
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
                var bodyString = String()
                
                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_AUDIO_URL + sermon!.audio!
                
                let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                twitterSheet.setInitialText(bodyString)
                self.presentViewController(twitterSheet, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            networkUnavailable()
        }
    }
    
    func facebook(sermon:Sermon?)
    {
        assert(sermon != nil, "can't post about a nil sermon")

        if Reachability.isConnectedToNetwork() {
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
                var bodyString = String()
                
                bodyString = "Great sermon: \"\(sermon!.title!)\" by \(sermon!.speaker!).  " + Constants.BASE_PDF_URL + sermon!.audio!

                //So the user can paste the initialText into the post dialog/view
                //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
                UIPasteboard.generalPasteboard().string = bodyString

                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                facebookSheet.setInitialText(bodyString)
                self.presentViewController(facebookSheet, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Accounts", message: "Please login to a Facebook account to share.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            networkUnavailable()
        }
    }
    
    func actions()
    {
        //        print("action!")
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)

        // Put up an action sheet

        let alert = UIAlertController(title: Constants.EMPTY_STRING,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        if (selectedSermon!.hasNotes() || selectedSermon!.hasSlides()) {
            if (selectedSermon?.showing == Constants.NOTES) || (selectedSermon?.showing == Constants.SLIDES) {
                action = UIAlertAction(title: Constants.Print, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //            print("print!")
                    self.printSermon(self.selectedSermon)
                })
                alert.addAction(action)
            }
        }
        
        action = UIAlertAction(title: Constants.Full_Screen, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            //            print("full screen!")
            if (self.selectedSermon!.hasVideo() &&
                (self.selectedSermon!.playing == Constants.VIDEO) &&
                (self.selectedSermon!.showing == Constants.VIDEO)) {
                    self.zoomScreen() // Crashes when return from zoom on 9.x but not on 8.4
            }
            
            if (self.selectedSermon!.showing == Constants.SLIDES) || (self.selectedSermon!.showing == Constants.NOTES) {
                self.performSegueWithIdentifier(Constants.SHOW_TRANSCRIPT_FULL_SCREEN_SEGUE_IDENTIFIER, sender: self.selectedSermon)
            }
        })
        alert.addAction(action)
    
        if (self.selectedSermon!.showing == Constants.SLIDES) || (self.selectedSermon!.showing == Constants.NOTES) {
            action = UIAlertAction(title: Constants.Open_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                //            print("mail!")
                
                var urlString:String?
                
                switch self.selectedSermon!.showing! {
                case Constants.NOTES:
                    urlString = Constants.BASE_PDF_URL + self.selectedSermon!.notes!
                    break
                case Constants.SLIDES:
                    urlString = Constants.BASE_PDF_URL + self.selectedSermon!.slides!
                    break
                    
                default:
                    break
                }

                if let url = NSURL(string:urlString!) {
                    if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(url)) {
                        UIApplication.sharedApplication().openURL(url)
                    } else {
                        self.networkUnavailable()
                    }
                }
            })
            alert.addAction(action)
        }
        
        if ((selectedSermon!.hasScripture()) && (selectedSermon!.scripture != Constants.Selected_Scriptures)) {
            action = UIAlertAction(title: Constants.Scripture, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                //            print("mail!")
                self.openSermonScripture(self.selectedSermon)
            })
            alert.addAction(action)
        }
        
        if let sermons = sermonsInSeries {
            var sermonsToDownload = 0
            var sermonsDownloading = 0
            var sermonsDownloaded = 0
            
            for sermon in sermons {
                switch sermon.download.state {
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
                action = UIAlertAction(title: Constants.Download_All, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //            println("mail!")
                    for sermon in sermons {
                        if (sermon.download.state == .none) {
                            sermon.downloadAudio()
                        }
                    }
                    self.tableView.reloadData()
                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                })
                alert.addAction(action)
            }
            
            if (sermonsDownloading > 0) {
                action = UIAlertAction(title: Constants.Cancel_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //            println("mail!")
                    for sermon in sermons {
                        if (sermon.download.state == .downloading) {
                            sermon.cancelDownload()
                        }
                    }
                    self.tableView.reloadData()
                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                })
                alert.addAction(action)
            }
            
            if (sermonsDownloaded > 0) {
                action = UIAlertAction(title: Constants.Delete_All_Downloads, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //            println("mail!")
                    for sermon in sermons {
                        if (sermon.download.state == .downloaded) {
                            sermon.deleteDownload()
                        }
                    }
                    self.tableView.reloadData()
                    self.scrollToSermon(self.selectedSermon, select: true, position: UITableViewScrollPosition.Middle)
                })
                alert.addAction(action)
            }
        }
        
        action = UIAlertAction(title: Constants.Email_Sermon, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            //            print("mail!")
            self.mailSermon(self.selectedSermon)
        })
        alert.addAction(action)
        
        if (selectedSermon!.hasSeries()) {
            action = UIAlertAction(title: Constants.Email_Series, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                //            print("mail!")
                self.mailSermonSeries(self.sermonsInSeries)
            })
            alert.addAction(action)
        }
        
        action = UIAlertAction(title: Constants.Share_on_Facebook, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            //            print("mail!")
            self.facebook(self.selectedSermon)
        })
        alert.addAction(action)
        
        action = UIAlertAction(title: Constants.Share_on_Twitter, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            //            print("mail!")
            self.twitter(self.selectedSermon)
        })
        alert.addAction(action)
        
        //We can't download transcripts and slides so we can't supporting downloading, iOS 9 apparently solves this.
//        action = UIAlertAction(title: "Download Sermon", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            //            print("mail!")
//            self.downloadSermon(self.selectedSermon)
//        })
//        alert.addAction(action)
//        
//        if (selectedSermon?.series != nil) && (selectedSermon?.series != Constants.EMPTY_STRING) {
//            action = UIAlertAction(title: "Download Series", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//                //            print("mail!")
//                self.downloadSermonSeries(Globals.sermonsInSeries)
//            })
//            alert.addAction(action)
//        }
        
//        action = UIAlertAction(title: "Message", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
////            print("message!")
//            self.message(self.sermonSelected)
//        })
//        alert.addAction(action)
//
//        action = UIAlertAction(title: "Print", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
//            print("print!")
//        })
//        alert.addAction(action)
//        
        action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
//            print("cancel!")
        })
        alert.addAction(action)
        
        //on iPad this is a popover
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        alert.popoverPresentationController?.barButtonItem = actionButton
        
        presentViewController(alert, animated: true, completion: nil)
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
                        
            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            sermonNotesAndSlides.addSubview(view!)
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides?.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides?.addConstraint(centerY)
            
            let widthX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides?.addConstraint(widthX)
            
            let widthY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: view!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
            sermonNotesAndSlides?.addConstraint(widthY)
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

    private func setupWKWebViews()
    {
        sermonNotesWebView = WKWebView(frame: sermonNotesAndSlides.frame)
        sermonNotesWebView?.multipleTouchEnabled = true
        
//        print("\(sermonNotesAndSlides.frame)")
//        sermonNotesWebView?.UIDelegate = self
        
//        sermonNotesWebView?.scrollView.delegate = self //seems to cause crash
        sermonNotesWebView?.navigationDelegate = self
        sermonNotesWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        sermonNotesAndSlides.addSubview(sermonNotesWebView!)
        
        sermonSlidesWebView = WKWebView(frame: sermonNotesAndSlides.frame)
        sermonSlidesWebView?.multipleTouchEnabled = true
        
//        print("\(sermonNotesAndSlides.frame)")
//        sermonSlidesWebView?.UIDelegate = self

//        sermonSlidesWebView?.scrollView.delegate = self //seems to cause crash
        sermonSlidesWebView?.navigationDelegate = self
        sermonSlidesWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        sermonNotesAndSlides.addSubview(sermonSlidesWebView!)
        
        let centerXNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(centerXNotes)
        
        let centerYNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(centerYNotes)
        
        let widthXNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(widthXNotes)
        
        let widthYNotes = NSLayoutConstraint(item: sermonNotesWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: sermonNotesWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(widthYNotes)
        
        let centerXSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(centerXSlides)
        
        let centerYSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(centerYSlides)
        
        let widthXSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(widthXSlides)
        
        let widthYSlides = NSLayoutConstraint(item: sermonSlidesWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: sermonSlidesWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
        sermonNotesAndSlides?.addConstraint(widthYSlides)
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
//            saveSermonSettings() //seems to cause crash
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        print("scrollViewDidEndDragging")
        if let view = scrollView.superview as? WKWebView {
            captureContentOffset(view)
//            saveSermonSettings() //seems to cause crash
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
            updateUserDefaultsCurrentTimeExact()
            Globals.playerPaused = true
        } else {
            Globals.playerPaused = false
        }
        
//        addPlayObserver()
//        addSliderObserver()
        setupPlayPauseButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.splitViewController = self.splitViewController

        // NO - must be in viewWillAppear() or fullscreen video will crash app when it returns to normal
//        updateUI()
        
//        print("\(Globals.mpPlayer?.contentURL)")
//        print("\(Constants.LIVE_STREAM_URL)")
        if (Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.mpPlayer?.stop()
            setupPlayer(selectedSermon)
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //Unreliable
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if(Globals.sermonLoaded) {
            spinner.stopAnimating()
        } else {
            if (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
                spinner.startAnimating()
            }
        }

        if (selectedSermon == nil) {
            //Will only happen on an iPad
            let defaults = NSUserDefaults.standardUserDefaults()
            let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
            if (selectedSermonKey != nil) {
                if let sermons = Globals.sermons {
                    for sermon in sermons {
                        if (sermon.keyBase == selectedSermonKey!) {
                            selectedSermon = sermon
                            break
                        }
                    }
                }
            }
        } else {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(selectedSermon!.keyBase,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
            defaults.synchronize()
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
                fallthrough
                
            case .Interrupted:
                print("viewDidLoad.Interrupted")
                fallthrough
                
            case .Paused:
                print("viewDidLoad.Paused")
                break
            }
        }
        
        // Do any additional setup after loading the view.
        setupWKWebViews()
    }

//    private func setupFlipButton()
//    {
//        if (Globals.sermonPlaying == selectedSermon) && (selectedSermon?.playing == Constants.VIDEO) {
//            flipButton.hidden = true
//            flipButtonWidthConstraint.constant = 0
//            view.setNeedsLayout()
//        } else {
//            if (selectedSermon != nil) {
//                var hasNotes:Bool = false
//                var hasSlides:Bool = false
//                
//                (hasNotes,hasSlides) = selectedSermon!.hasNotesOrSlides(false)
//                
//                if (hasNotes && hasSlides) {
//                    flipButton.hidden = false
//                    flipButtonWidthConstraint.constant = 30
//                    view.setNeedsLayout()
//                } else {
//                    flipButton.hidden = true
//                    flipButtonWidthConstraint.constant = 0
//                    view.setNeedsLayout()
//                }
//            }
//        }
//    }
    
    private func setupDefaultNotesAndSlides()
    {
        var hasNotes:Bool = false
        var hasSlides:Bool = false
        
        if (selectedSermon != nil) {
            splitView.hidden = false
            
            (hasNotes,hasSlides) = selectedSermon!.hasNotesOrSlides(true)

            Globals.mpPlayer?.view.hidden = true
            
            if (!hasSlides && !hasNotes) {
                sermonNotesWebView?.hidden = true
                sermonSlidesWebView?.hidden = true
                
                logo.hidden = false
                selectedSermon!.showing = Constants.NONE
                sermonNotesAndSlides.bringSubviewToFront(logo)
            }
            if (hasSlides && !hasNotes) {
                sermonNotesWebView?.hidden = true
                logo.hidden = true
                
//                sermonSlidesWebView!.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.SLIDES
                sermonNotesAndSlides.bringSubviewToFront(sermonSlidesWebView!)
            }
            if (!hasSlides && hasNotes) {
                sermonSlidesWebView?.hidden = true
                logo.hidden = true
                
//                sermonNotesWebView!.hidden = false // This happens after they load.  But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.NOTES
                sermonNotesAndSlides.bringSubviewToFront(sermonNotesWebView!)
            }
            if (hasSlides && hasNotes) {
                sermonNotesWebView?.hidden = true
                logo.hidden = true
                
//                sermonSlidesWebView!.hidden = false // This happens after they load. But not if they come out of the cache I think.
                selectedSermon!.showing = Constants.SLIDES //This is an arbitrary choice
                sermonNotesAndSlides.bringSubviewToFront(sermonSlidesWebView!)
            }
        }
    }
    
    func loading()
    {
        switch selectedSermon!.showing! {
        case Constants.SLIDES:
            progressIndicator.progress = Float(sermonSlidesWebView!.estimatedProgress)
            break
            
        case Constants.NOTES:
            progressIndicator.progress = Float(sermonNotesWebView!.estimatedProgress)
            break
            
        default:
            break
        }
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            progressIndicator.hidden = true
        }
    }
    
    private func setupNotesAndSlides()
    {
        var hasNotes:Bool = false
        var hasSlides:Bool = false
        
        sermonNotesWebView?.removeFromSuperview()
        sermonSlidesWebView?.removeFromSuperview()
        
        setupWKWebViews()

        progressIndicator.hidden = true
        progressIndicator.progress = 0.0

//        print("setupNotesAndSlides")
//        print("Selected: \(Globals.sermonSelected?.title)")
//        print("Last Selected: \(Globals.sermonLastSelected?.title)")
//        print("Playing: \(Globals.sermonPlaying?.title)")
        
        if (selectedSermon != nil) {
            splitView.hidden = false
            
            (hasNotes,hasSlides) = selectedSermon!.hasNotesOrSlides(true)

            if (hasNotes) {
                let notesURL = Constants.BASE_PDF_URL + selectedSermon!.notes!
                //                            print("\(notesURL)")
                
                if (Reachability.isConnectedToNetwork()) {
                    sermonNotesWebView!.hidden = true // Will be made visible when the URL finishes loading

                    activityIndicator.hidden = false
                    activityIndicator.startAnimating()

                    progressIndicator.hidden = false
                    if loadTimer == nil {
                        loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                    }
                    
                    sermonNotesWebView!.stopLoading()
                    let request = NSURLRequest(URL: NSURL(string: notesURL)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    sermonNotesWebView!.loadRequest(request)
                } else {
                    networkUnavailable()
                }
            } else {
                sermonNotesWebView!.hidden = true
            }
            
            if (hasSlides) {
                let slidesURL = Constants.BASE_PDF_URL + selectedSermon!.slides!
                //                            print("\(slidesURL)")
                
                if (Reachability.isConnectedToNetwork()) {
                    sermonSlidesWebView!.hidden = true // Will be made visible when the URL finishes loading
                    
                    activityIndicator.hidden = false
                    activityIndicator.startAnimating()
                    
                    progressIndicator.hidden = false
                    if loadTimer == nil {
                        loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
                    }
                    
                    sermonSlidesWebView!.stopLoading()
                    let request = NSURLRequest(URL: NSURL(string: slidesURL)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
                    sermonSlidesWebView!.loadRequest(request)
                } else {
                    networkUnavailable()
                }
            } else {
                sermonSlidesWebView!.hidden = true
            }
            
    //        print("notes hidden \(sermonNotes.hidden)")
    //        print("slides hidden \(sermonSlides.hidden)")
            
            // Note: we aren't doing anything to check whether they can or should show what they claim to show!
            
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

            logo.hidden = false
            sermonNotesAndSlides.bringSubviewToFront(logo)
        }

        setupSTVControl()
    }
    
    
    func scrollToSermon(sermon:Sermon?,select:Bool,position:UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = NSIndexPath(forRow: 0, inSection: 0)
            
            if (sermonsInSeries!.count > 1) {
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
//        let attributes = [NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_PLAY_PLAUSE_FONT_SIZE)!,
//            NSForegroundColorAttributeName:Constants.iosBlueColor]
        
        playPauseButton.setTitle(Constants.FA_PLAY, forState: UIControlState.Normal)
        
//        playPauseButton.setAttributedTitle(NSMutableAttributedString(string: Constants.FA_PLAY,attributes: attributes), forState: UIControlState.Normal)
        
//            playPauseButton.setTitle(Constants.Play, forState: UIControlState.Normal)

        if (selectedSermon != nil) {
            playPauseButton.hidden = false
            
            if (Globals.sermonPlaying != nil) {
                if (selectedSermon?.title == Globals.sermonPlaying?.title) &&
                    (selectedSermon?.date == Globals.sermonPlaying?.date) {
                    if (!Globals.playerPaused) {
                        playPauseButton.setTitle(Constants.FA_PAUSE, forState: UIControlState.Normal)
                        
//                        playPauseButton.setAttributedTitle(NSMutableAttributedString(string: Constants.FA_PAUSE,attributes: attributes), forState: UIControlState.Normal)
                        
//                        playPauseButton.setTitle(Constants.Pause, forState: UIControlState.Normal)
                    }
                }
            }
        } else {
            playPauseButton.hidden = true
        }
    }
    
    
//    private func setupReturnToSermonButton()
//    {
//        returnToSermonButton.hidden = true
//        returnToSermonButton.enabled = false
//        
//        if (Globals.mpPlayer != nil) && (Globals.sermonPlaying != nil) {
//            if (selectedSermon == nil) {
//                returnToSermonButton.hidden = true
//            } else
//            if (selectedSermon == Globals.sermonPlaying) {
//                returnToSermonButton.hidden = true
//            } else {
//                if (Globals.playerPaused) {
//                    returnToSermonButton.setTitle("Return to Paused", forState: UIControlState.Normal)
//                } else {
//                    returnToSermonButton.setTitle("Return to Playing", forState: UIControlState.Normal)
//                }
//                
//                returnToSermonButton.hidden = false
//            }
//        } else {
//            returnToSermonButton.hidden = true
//        }
//    }
    
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func tags(object:AnyObject?)
    {
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.filters
        //And when the user chooses one, scroll to the first time in that section.
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        let button = object as? UIBarButtonItem
        
        if let popover = self.storyboard?.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController {
            popover.modalPresentationStyle = .Popover
//            popover.preferredContentSize = CGSizeMake(300, 500)
            
            popover.popoverPresentationController?.permittedArrowDirections = .Up
            popover.popoverPresentationController?.delegate = self
            popover.popoverPresentationController?.barButtonItem = button
            
            popover.delegate = self
            popover.purpose = .showingTags
            popover.strings = Globals.sermonTags
            popover.allowsSelection = false
            popover.selectedSermon = selectedSermon
            
            presentViewController(popover, animated: true, completion: nil)
        }
    }
    
    private func setupActionAndTagsButtons()
    {
        if (selectedSermon != nil) {
            var barButtons = [UIBarButtonItem]()
            
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actions")
            barButtons.append(actionButton!)
        
            if (selectedSermon!.hasTags()) {
                tagsButton = UIBarButtonItem(title: Constants.Tags, style: UIBarButtonItemStyle.Plain, target: self, action: "tags:")
                barButtons.append(tagsButton!)
            }

            self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
        } else {
            self.navigationItem.rightBarButtonItem = nil
            actionButton = nil
            tagsButton = nil
        }
    }

//    override func prefersStatusBarHidden() -> Bool
//    {
//        return false
//    }
    
    func didRotate() {
        if (selectedSermon != nil) {
            var index:String
            var notesContentOffset:CGPoint = CGPointMake(0,0)
            
            var notesContentOffsetXRatio:Float = 0.0
            var notesContentOffsetYRatio:Float = 0.0
            
            //        print("\(sermonNotesWebView!.scrollView.contentSize)")
            //        print("\(sermonSlidesWebView!.scrollView.contentSize)")
            
            index = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO
            if (Globals.sermonSettings![index] != nil) {
                notesContentOffsetXRatio = Float(Globals.sermonSettings![index]!)!
            }
            
            index = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO
            if (Globals.sermonSettings![index] != nil) {
                notesContentOffsetYRatio = Float(Globals.sermonSettings![index]!)!
            }
            
            notesContentOffset = CGPointMake(
                CGFloat(notesContentOffsetXRatio) * sermonNotesWebView!.scrollView.contentSize.width,
                CGFloat(notesContentOffsetYRatio) * sermonNotesWebView!.scrollView.contentSize.height)
            
            sermonNotesWebView!.scrollView.setContentOffset(notesContentOffset, animated: false)
            
            var slidesContentOffset:CGPoint = CGPointMake(0,0)
            
            var slidesContentOffsetXRatio:Float = 0.0
            var slidesContentOffsetYRatio:Float = 0.0
            
            index = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO
            if (Globals.sermonSettings![index] != nil) {
                slidesContentOffsetXRatio = Float(Globals.sermonSettings![index]!)!
            }
            
            index = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO
            if (Globals.sermonSettings![index] != nil) {
                slidesContentOffsetYRatio = Float(Globals.sermonSettings![index]!)!
            }
            
            slidesContentOffset = CGPointMake(
                CGFloat(slidesContentOffsetXRatio) * sermonSlidesWebView!.scrollView.contentSize.width,
                CGFloat(slidesContentOffsetYRatio) * sermonSlidesWebView!.scrollView.contentSize.height)
            
            sermonSlidesWebView!.scrollView.setContentOffset(slidesContentOffset, animated: false)
            
//            setupViewSplit()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        captureContentOffsetAndZoomScale()
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                self.didRotate()
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
                if let viewSplit = Globals.seriesViewSplits![selectedSermon!.seriesKeyBase] {
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
            if let viewSplit = Globals.seriesViewSplits![selectedSermon!.seriesKeyBase] {
                ratio = CGFloat(Float(viewSplit)!)
            }
        }
//        print("ratio: '\(ratio)")
        return ratio
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
        if ((selectedSermon != nil) && selectedSermon!.hasSeries()) {
            //The selected sermon is in a series so set the title.
            self.navigationItem.title = selectedSermon?.series
        } else {
            self.navigationItem.title = selectedSermon?.title
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
        
        setupSermonsInSeries(selectedSermon)
        
        if (!Globals.sermonLoaded && (Globals.sermonPlaying != nil) && (selectedSermon == Globals.sermonPlaying)) {
            spinner.startAnimating()
        }
        
        if (Globals.sermonLoaded || (selectedSermon != Globals.sermonPlaying)) {
            // Redundant - also done in viewDidLoad
            spinner.stopAnimating()
        } else {
            //            //This is really misplaced since we're dependent upon the AppDelegate to address loading the default sermon and setting the currentPlayTime.
            //            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }
        
        if (selectedSermon != nil) && (Globals.mpPlayer == nil) {
            setupPlayerAtEnd(selectedSermon)
        }
        
        setupViewSplit()
        
        //        print("viewWillAppear 2 sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
        //        print("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the sermon selected is playing already
        addPlayObserver()
        addSliderObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
//        setupReturnToSermonButton()
        setupSTVControl()
        setupSlider()
        setupNotesAndSlides()
        setupActionAndTagsButtons()
        
        tableView.allowsSelection = true
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

//        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic
        updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

//        print("viewDidAppear sermonNotesAndSlides.bounds: \(sermonNotesAndSlides.bounds)")
//        print("viewDidAppear tableView.bounds: \(tableView.bounds)")

        if (splitViewController != nil) && (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (Globals.sermons == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
            }
        } else {
            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
        }
        
        scrollToSermon(selectedSermon,select:true,position:UITableViewScrollPosition.Top)
    }
    
    func removeSliderObserver() {
        if (Globals.sliderObserver != nil) {
            Globals.sliderObserver!.invalidate()
            Globals.sliderObserver = nil
        }
    }
    
    func removePlayObserver() {
        if (Globals.playObserver != nil) {
            Globals.playObserver!.invalidate()
            Globals.playObserver = nil
        }
    }
    
    private func captureViewSplit()
    {
//        print("captureViewSplit: \(sermonSelected?.title)")
        
        if (self.view != nil) && (splitView.bounds.size.width > 0) {
            if (selectedSermon != nil) {
                print("\(self.view.bounds.height)")
                let ratio = self.sermonNotesAndSlidesConstraint.constant / self.view.bounds.height
                
                //            print("captureViewSplit ratio: \(ratio)")
                
                Globals.seriesViewSplits![selectedSermon!.seriesKeyBase] = "\(ratio)"
            }
        }
    }
    
    private func captureContentOffset(webView:WKWebView)
    {
//        print("captureContentOffset: \(sermonSelected?.title)")

        if (selectedSermon != nil) {
            if (webView == sermonNotesWebView) {
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.x / sermonNotesWebView!.scrollView.contentSize.width)"
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.y / sermonNotesWebView!.scrollView.contentSize.height)"
            }
            
            if (webView == sermonSlidesWebView) {
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.x / sermonSlidesWebView!.scrollView.contentSize.width)"
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.y / sermonSlidesWebView!.scrollView.contentSize.height)"
            }
        }
    }
    
    private func captureZoomScale(webView:WKWebView)
    {
//        print("captureZoomScale: \(sermonSelected?.title)")

        if (selectedSermon != nil) && (!webView.loading) {
            if (webView == sermonNotesWebView) {
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_ZOOM_SCALE] = "\(sermonNotesWebView!.scrollView.zoomScale)"
            }
            
            if (webView == sermonSlidesWebView) {
                Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_ZOOM_SCALE] = "\(sermonSlidesWebView!.scrollView.zoomScale)"
            }
        }
    }
    
    private func captureContentOffsetAndZoomScale()
    {
        if (selectedSermon != nil) {
//            print("captureContentOffsetAndZoomScale: \(sermonSelected?.title)")
            
            if (sermonNotesWebView != nil) {
                if (!sermonNotesWebView!.loading) {
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.x / sermonNotesWebView!.scrollView.contentSize.width)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO] = "\(sermonNotesWebView!.scrollView.contentOffset.y / sermonNotesWebView!.scrollView.contentSize.height)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.NOTES_ZOOM_SCALE] = "\(sermonNotesWebView!.scrollView.zoomScale)"
                }
            }
            
            if (sermonSlidesWebView != nil) {
                if (!sermonSlidesWebView!.loading) {
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.x / sermonSlidesWebView!.scrollView.contentSize.width)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] = "\(sermonSlidesWebView!.scrollView.contentOffset.y / sermonSlidesWebView!.scrollView.contentSize.height)"
                    
                    Globals.sermonSettings![selectedSermon!.keyBase + Constants.SLIDES_ZOOM_SCALE] = "\(sermonSlidesWebView!.scrollView.zoomScale)"
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.rightBarButtonItem = nil
        
//        print("viewWillDisappear: \(sermonSelected?.title)")

        sermonNotesWebView?.stopLoading()
        sermonSlidesWebView?.stopLoading()
        
        captureViewSplit()
        captureContentOffsetAndZoomScale()
        
//        removeSliderObserver()
//        removePlayObserver()
        
        saveSermonSettings()
        
        //        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        //        NSNotificationCenter.defaultCenter().removeObserver(self,name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
        
//        Globals.mpPlayer?.view.removeFromSuperview()
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
                case Constants.SHOW_TRANSCRIPT_FULL_SCREEN_SEGUE_IDENTIFIER:
                    splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
                    wvc.selectedSermon = sender as? Sermon
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
        return sermonsInSeries != nil ? sermonsInSeries!.count : 0
    }
    
    /*
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMONS_IN_SERIES_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyTableViewCell
    
        cell.sermon = sermonsInSeries?[indexPath.row]
        
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
        
//        if (splitViewController == nil) {
//            if UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation) {
//                print("\(slider.bounds.width)")
//                slider.hidden = (stvControl.enabled && (slider.bounds.width < Constants.MIN_SLIDER_WIDTH)) || slider.hidden
//            } else {
//                slider.hidden = false || slider.hidden
//            }
//        }
    }

    func playTimer()
    {
        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
//                print("playTimer.Interrupted")
                Globals.playerPaused = true
                updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
                removePlayObserver()
                break
                
            case .Paused:
//                print("playTimer.Paused")
                if (!Globals.playerPaused) {
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                }

                //I'm not sure this is reliable - esp. with video - it seems to happen after dragging the slider
                //We might need to have a delay before we call an unauthorized pause as a network outage.
                
                //
//                if (!Globals.playerPaused) {
//                    if (Int(Globals.mpPlayer!.currentPlaybackTime) < Int(Globals.mpPlayer!.duration)) {
//                        print("player paused when it should be playing")
//                        
//                        //Something happened.  We called this because we wanted the audio to play.
//                        //Can't say this since this is called on viewWillAppear to handle spinner
//                        
//                        //Alert - network unavailable.
//                        networkUnavailable()
//                    }
//                    
//                    updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
//                    
//                    //Don't stop and don't lose the time.
//                    //                Globals.mpPlayer?.stop()
//                    
//                    spinner.stopAnimating()
//                    Globals.playerPaused = true
//                    setupPlayPauseButton()
//                    
//                    removePlayObserver()
//                }
                break
                
            case .Playing:
//                print("playTimer.Playing")
                if (Globals.mpPlayer?.currentPlaybackRate == 0) {
                    //Force a restart of the sermon currently playing?
                    //But don't use playNewSermon() as that assumes the MVC visible is the one the sermonPlaying is a part of.
                    print("currentPlaybackRate is 0 for Globals.sermonPlaying: \(Globals.sermonPlaying)")
                    if (Globals.sermonPlaying != nil) && (Globals.sermonPlaying == selectedSermon) {
                        playNewSermon(Globals.sermonPlaying)
                    }
                }
                if (Globals.playerPaused) {
                    Globals.playerPaused = false
                    setupPlayPauseButton()
                }
                //Don't do the following so we can determine if, after it starts playing, the player stops when it shouldn't
                //removePlayObserver()
                break
                
            case .SeekingBackward:
//                print("playTimer.SeekingBackward")
                if (Globals.playerPaused) {
                    Globals.playerPaused = false
                    setupPlayPauseButton()
                }
                break
                
            case .SeekingForward:
//                print("playTimer.SeekingForward")
                if (Globals.playerPaused) {
                    Globals.playerPaused = false
                    setupPlayPauseButton()
                }
                break
                
            case .Stopped:
//                print("playTimer.Stopped")
                
                //I'm not sure this is reliable - esp. with video - it seems to happen after dragging the slider
                //We might need to have a delay before we call an unauthorized pause as a network outage.
                
                //
//                if (!Globals.playerPaused) && ((Globals.mpPlayer!.currentPlaybackTime >= 0) && (Globals.mpPlayer!.duration >= 0)) {
//                    if (Int(Globals.mpPlayer!.currentPlaybackTime) < Int(Globals.mpPlayer!.duration)) {
//                        print("player stopped when it should be playing")
//                        
//                        //Something happened.  We called this because we wanted the audio to play.
//                        //Can't say this since this is called on viewWillAppear to handle spinner
//                        
//                        //Alert - network unavailable.
//                        networkUnavailable()
//                    }
//                    
//                    updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.currentPlaybackTime))
//                    
//                    Globals.mpPlayer?.stop()  //s/b unnecessary
//                    
//                    spinner.stopAnimating()
//                    Globals.playerPaused = true
//                    setupPlayPauseButton()
//                    
//                    removePlayObserver()
//                }
                break
            }
        }
    }
    
    
    func sliderTimer()
    {
        if (Globals.mpPlayer!.fullscreen) {
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded // Fullscreen
        } else {
            Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
        }

//        if (splitViewController == nil) {
//            setupSlider()
//            slider.hidden = !((Globals.sermonPlaying == selectedSermon) && (slider.bounds.width >= Constants.MIN_SLIDER_WIDTH))
//        }
        
        //The conditional below depends upon sliderTimer running even when, in fact especially when, nothing is playing.
        if (!Globals.sermonLoaded) {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let currentTime = defaults.stringForKey(Constants.CURRENT_TIME) {
                print("\(currentTime)")
                print("\(NSTimeInterval(Float(currentTime)!))")
                
                if (Float(currentTime)! <= Float(Globals.mpPlayer!.duration)) {
                    Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(currentTime)!)
                    
                    if (Globals.mpPlayer!.currentPlaybackTime == NSTimeInterval(Float(currentTime)!)) {
                        spinner.stopAnimating()
                        spinner.hidden = true
                        Globals.sermonLoaded = true
                    }
                }
            }
        }

        setSliderAndTimesToAudio()
        
        if (Globals.mpPlayer?.currentPlaybackRate > 0) {
            updateUserDefaultsCurrentTimeWhilePlaying()
        }

        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
//                print("sliderTimer.Interrupted")
                break
                
            case .Paused:
//                print("sliderTimer.Paused")
                if (!Globals.playerPaused) {
                    Globals.playerPaused = true
                    setupPlayPauseButton()
                }
                break
                
            case .Playing:
//                print("sliderTimer.Playing")
                if (Globals.playerPaused) {
                    Globals.playerPaused = false
                    setupPlayPauseButton()
                }
                break
                
            case .SeekingBackward:
//                print("sliderTimer.SeekingBackward")
                break
                
            case .SeekingForward:
//                print("sliderTimer.SeekingForward")
                break
                
            case .Stopped:
//                print("sliderTimer.Stopped")
                break
            }
        }
        
        //        print("Duration: \(Globals.mpPlayer!.duration) CurrentPlaybackTime: \(Globals.mpPlayer!.currentPlaybackTime)")
        //        print("CurrentTime: \(Globals.sermonPlaying?.currentTime)")
        
        if (Globals.mpPlayer!.duration > 0) && (Globals.mpPlayer!.currentPlaybackTime > 0) &&
            // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
            (Int(Globals.mpPlayer!.currentPlaybackTime) == Int(Globals.mpPlayer!.duration)) {
            print("sliderTimer currentPlaybackTime == duration")
            
            //Prefer that it pause
            //pause() doesn't change state at end!
            Globals.mpPlayer?.stop()
//            Globals.mpPlayer?.currentPlaybackTime = Globals.mpPlayer!.duration
            
            setupPlayPauseButton()
            updateUserDefaultsCurrentTimeExact(Float(Globals.mpPlayer!.duration))
            setupPlayingInfoCenter()
            
            spinner.stopAnimating()
            spinner.hidden = true
            
//            Globals.playerPaused = true
            
            if (!Globals.playerPaused) {
                advanceSermon()
            }
        }
    }
    
    func advanceSermon()
    {
//        print("\(Globals.sermonPlaying?.playing)")
        if (Globals.sermonPlaying?.playing == Constants.AUDIO) {
            let sermons = sortSermons(sermonsInSermonSeries(Globals.sermons,series: Globals.sermonPlaying?.series),sorting: Constants.CHRONOLOGICAL,grouping: Constants.YEAR)
            if sermons?.indexOf(Globals.sermonPlaying!) < (sermons!.count - 1) {
                if let nextSermon = sermons?[(sermons?.indexOf(Globals.sermonPlaying!))! + 1] {
                    nextSermon.playing = Constants.AUDIO
                    nextSermon.currentTime = Constants.ZERO
                    if (self.view.window != nil) && (sermonsInSeries!.indexOf(nextSermon) != nil) {
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
            Globals.sliderObserver = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "sliderTimer", userInfo: nil, repeats: true)
        } else {
            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
            print("Globals.player == nil in sliderObserver")
            // Should we setup the player all over again?
        }

//        print("addSliderObserver out")
    }
    
    
    func addPlayObserver()
    {
        if (Globals.playObserver != nil) {
            Globals.playObserver?.invalidate()
            Globals.playObserver = nil
        }

        if (Globals.mpPlayer != nil) {
            //Update for MPPlayer
            Globals.playObserver = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "playTimer", userInfo: nil, repeats: true)
        } else {
            // This will happen when there is no sermonPlaying, e.g. when a clean install is done and the app is put into the background and then brought back to the forground
            print("Globals.player == nil in playObserver")
            // Should we setup the player all over again?
        }
    }
    

    private func networkUnavailable()
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            let alert = UIAlertController(title: Constants.Network_Unavailable,
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    private func failedToLoad()
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            let alert = UIAlertController(title: Constants.Content_Failed_to_Load,
                message: Constants.EMPTY_STRING,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        remoteControlEvent(event!)
        setupPlayPauseButton()
    }

    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
//        let player = notification.object as! MPMoviePlayerController
        
        /* Enough data has been buffered for playback to continue uninterrupted. */
        
//        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
//        let loadvalue:UInt8 = UInt8(MPMovieLoadState.PlaythroughOK.rawValue)
        
        // If there is a sermon that was playing before and we want to start back at the same place,
        // the PlayPause button must NOT be active until loadState & PlaythroughOK == 1.
        
//        print("\(loadstate)")
//        print("\(loadvalue)")
        
        //For loading
//        if ((loadstate & loadvalue) == (1<<1)) {
//            print("mpPlayerLoadStateDidChange.MPMovieLoadState.PlaythroughOK")
        if !Globals.sermonLoaded {
            print("\(Globals.sermonPlaying!.currentTime!)")
            print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
            
            // The comparison below is Int because I'm concerned Float leaves room for small differences.  We'll see.
            if (Int(Float(Globals.sermonPlaying!.currentTime!)!) == Int(Globals.mpPlayer!.duration)) {
                Globals.sermonPlaying!.currentTime = Constants.ZERO
            }

            Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)

            updateUserDefaultsCurrentTimeExact()
            setupPlayingInfoCenter()
            
            spinner.stopAnimating()
            Globals.sermonLoaded = true
            
            Globals.mpPlayer?.play()
            
            // This removes ALL notifications for this observer so the "for playing" below will likely never happen.
            // Which is fine since all it did was stop the spinner, which is done above.
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
//        }
        
        //For playing
        if (Globals.mpPlayer != nil) {
            switch Globals.mpPlayer!.playbackState {
            case .Interrupted:
                print("mpPlayerLoadStateDidChange.Interrupted")
                break
                
            case .Paused:
                print("mpPlayerLoadStateDidChange.Paused")
                break
                
            case .Playing:
                print("mpPlayerLoadStateDidChange.Playing")
                spinner.stopAnimating()
                setupPlayingInfoCenter()
                NSNotificationCenter.defaultCenter().removeObserver(self)
                break
                
            case .SeekingBackward:
                print("mpPlayerLoadStateDidChange.SeekingBackward")
                break
                
            case .SeekingForward:
                print("mpPlayerLoadStateDidChange.SeekingForward")
                break
                
            case .Stopped:
                print("mpPlayerLoadStateDidChange.Stopped")
                break
            }
        }
    }
    
    private func playNewSermon(sermon:Sermon?) {
        //We don't set Globals.sermonSelected because that is only for selections made from the main sermon list, not from the series list.
        
        updateUserDefaultsCurrentTimeExact()
        Globals.mpPlayer?.stop()
        
        Globals.mpPlayer?.view.removeFromSuperview()
        
        // Why, when we're showing Video, are we doing this?
        // Why aren't we doing it in every case?
        // Because we don't know if the WKWebViews are setup otherwise?
        // That would be odd because just because you have video doesn't mean there are notes or slides
//        if (sermon?.playing == Constants.VIDEO) {
//            captureContentOffsetAndZoomScale()
//        }
        captureContentOffsetAndZoomScale()
        
        if (sermon != nil) && (sermon!.hasVideo() || sermon!.hasAudio()) {
            //Too late now
            Globals.sermonLoaded = true

            Globals.sermonPlaying = sermon
            Globals.playerPaused = false
            
            Globals.mpPlayer?.stop()
            
            setupSermonPlayingUserDefaults()

            var sermonURL:String?
            
            switch sermon!.playing! {
            case Constants.AUDIO:
                sermonURL = Constants.BASE_AUDIO_URL + sermon!.audio!
                break
            case Constants.VIDEO:
                sermonURL = Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX
                break
            default:
                break
            }
//            if (sermon!.hasVideo()) {
//                switch audioOrVideoControl.selectedSegmentIndex {
//                case Constants.AUDIO_SEGMENT_INDEX:
//                    sermonURL = Constants.BASE_AUDIO_URL + sermon!.audio!
//                    sermon?.playing = Constants.AUDIO
//                    break
//                case Constants.VIDEO_SEGMENT_INDEX:
//                    sermonURL = Constants.BASE_VIDEO_URL_PREFIX + sermon!.video! + Constants.BASE_VIDEO_URL_POSTFIX
//                    sermon?.playing = Constants.VIDEO
//                    break
//                default:
//                    break
//                }
//            } else {
//                sermonURL = Constants.BASE_AUDIO_URL + sermon!.audio!
//                sermon?.playing = Constants.AUDIO
//            }
            
            var url = NSURL(string:sermonURL!)
            var networkRequired = true
            
            if (sermon?.playing == Constants.AUDIO) {
                let fileURL = documentsURL()?.URLByAppendingPathComponent(sermon!.audio!)
                if (NSFileManager.defaultManager().fileExistsAtPath(fileURL!.path!)){
                    url = fileURL!
                    networkRequired = false
                }
            }
            
            //        print("playNewSermon: \(sermonURL)")
            
            if !networkRequired || (networkRequired && Reachability.isConnectedToNetwork()) {
                removeSliderObserver()
                removePlayObserver()
                
                //This guarantees a fresh start.
                Globals.mpPlayer = MPMoviePlayerController(contentURL: url)

                if (sermon!.hasVideo() && (sermon!.playing == Constants.VIDEO)) {
                    if (view.window != nil) {
                        setupPlayerView(Globals.mpPlayer?.view)
                        Globals.mpPlayer!.view.hidden = false
                        sermonNotesAndSlides.bringSubviewToFront(Globals.mpPlayer!.view!)
                    }
                    sermon!.showing = Constants.VIDEO
                } else {

                }

                Globals.mpPlayer?.shouldAutoplay = false
                Globals.mpPlayer?.controlStyle = MPMovieControlStyle.None
                Globals.mpPlayer?.prepareToPlay()
                
                spinner.startAnimating()
                // This stops the spinner spinning once the audio starts
                Globals.sermonLoaded = false
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
                
                setupPlayingInfoCenter()

                //Does this crash if prepareToPlay is not complete?
                //Can we even call this here if the sermon is not available?
                //If the sermon isn't available, how do we timeout?
                //Do we need to set a flag and call this from mpPlayerLoadStateDidChange?  What if it never gets called?
                //Is this causing crashes when prepareToPlay() is not completed and Globals.mpPlayer.loadState does not include MPMovieLoadState.PlaythroughOK?
//                Globals.mpPlayer?.play() // occurs in mpPlayerLoadStateDidChange after sermon has loaded
                
                addPlayObserver()
                addSliderObserver()
                
                if (view.window != nil) {
                    setupSTVControl()
                    setupSlider()
                    setupPlayPauseButton()
//                    setupReturnToSermonButton()
    //                setupFlipButton()
                    setupActionAndTagsButtons()
                }
            } else {
                networkUnavailable()
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//
//        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sermonSelected = sermonsInSeries![indexPath.row]
        
        captureContentOffsetAndZoomScale()
        saveSermonSettings()
        
//        sermonSelected.description()
//        selectedSermon.description()

        self.selectedSermon = sermonSelected

        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(sermonSelected.keyBase,forKey: Constants.SELECTED_SERMON_DETAIL_KEY)
        defaults.synchronize()

        if (selectedSermon != nil) && (selectedSermon == Globals.sermonPlaying) {
            if (!Globals.sermonLoaded) {
                spinner.startAnimating()
            } else {
                spinner.stopAnimating()
            }
        } else {
            spinner.stopAnimating()
        }

        setupAudioOrVideo()
        setupPlayPauseButton()
//        setupReturnToSermonButton()
        setupSlider()
        setupNotesAndSlides()
        setupActionAndTagsButtons()
        
//            print("Playing: \(Globals.sermonPlaying?.title)")
//            print("Selected: \(Globals.sermonSelected?.title)")
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if (navigationAction.request.URL != nil) {
//            print("\(navigationAction.request.URL!.absoluteString)")
            
            if (navigationAction.request.URL!.absoluteString.endIndex < Constants.BASE_PDF_URL.endIndex) {
                decisionHandler(WKNavigationActionPolicy.Cancel)
            } else {
                if (navigationAction.request.URL!.absoluteString.substringToIndex(Constants.BASE_PDF_URL.endIndex) == Constants.BASE_PDF_URL) {
                    decisionHandler(WKNavigationActionPolicy.Allow)
                } else {
                    decisionHandler(WKNavigationActionPolicy.Cancel)
                }
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }
    
    func webView(webView: WKWebView, didFailNavigation: WKNavigation!, withError: NSError) {
//        print("wkDidFailNavigation")
        
        // Keep trying
        let request = NSURLRequest(URL: webView.URL!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        webView.loadRequest(request) // NSURLRequest(URL: webView.URL!)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: NSError) {
//        print("wkDidFailProvisionalNavigation")

    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
//        print("wkDidStartProvisionalNavigation")

    }
    
    func wkSetZoomAndOffset(webView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")
//
//        print("contentInset: \(webView.scrollView.contentInset)")
//        print("contentSize: \(webView.scrollView.contentSize)")

        webView.scrollView.setZoomScale(scale, animated: false)
        webView.scrollView.setContentOffset(offset,animated: false)
    }
    
    func setNotesContentOffsetViewScale()
    {
        var notesContentOffset:CGPoint = CGPointMake(0,0)
        var notesZoomScale:CGFloat = 1.0
        
        var index:String
        
        var notesContentOffsetXRatio:Float = 0.0
        var notesContentOffsetYRatio:Float = 0.0
        
        index = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_X_RATIO
        if (Globals.sermonSettings![index] != nil) {
            notesContentOffsetXRatio = Float(Globals.sermonSettings![index]!)!
        }
        
        index = selectedSermon!.keyBase + Constants.NOTES_CONTENT_OFFSET_Y_RATIO
        if (Globals.sermonSettings![index] != nil) {
            notesContentOffsetYRatio = Float(Globals.sermonSettings![index]!)!
        }
        
        index = selectedSermon!.keyBase + Constants.NOTES_ZOOM_SCALE
        if (Globals.sermonSettings![index] != nil) {
            notesZoomScale = CGFloat(Float((Globals.sermonSettings![index]!))!)
        }
        
//        print("\(notesContentOffsetXRatio)")
//        print("\(sermonNotesWebView!.scrollView.contentSize.width)")
//        print("\(notesZoomScale)")
        
        notesContentOffset = CGPointMake(   CGFloat(notesContentOffsetXRatio) * sermonNotesWebView!.scrollView.contentSize.width * notesZoomScale,
                                            CGFloat(notesContentOffsetYRatio) * sermonNotesWebView!.scrollView.contentSize.height * notesZoomScale)
        
        wkSetZoomAndOffset(sermonNotesWebView!, scale: notesZoomScale, offset: notesContentOffset)
    }
    
    func setSlidesContentOffsetViewScale()
    {
        var slidesContentOffset:CGPoint = CGPointMake(0,0)
        var slidesZoomScale:CGFloat = 1.0
        
        var index:String
        
        var slidesContentOffsetXRatio:Float = 0.0
        var slidesContentOffsetYRatio:Float = 0.0
        
        index = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_X_RATIO
        if (Globals.sermonSettings![index] != nil) {
            slidesContentOffsetXRatio = Float(Globals.sermonSettings![index]!)!
        }
        
        index = selectedSermon!.keyBase + Constants.SLIDES_CONTENT_OFFSET_Y_RATIO
        if (Globals.sermonSettings![index] != nil) {
            slidesContentOffsetYRatio = Float(Globals.sermonSettings![index]!)!
        }
        
        index = selectedSermon!.keyBase + Constants.SLIDES_ZOOM_SCALE
        if (Globals.sermonSettings![index] != nil) {
            slidesZoomScale = CGFloat(Float((Globals.sermonSettings![index]!))!)
        }
        
//        print("\(slidesContentOffsetXRatio)")
//        print("\(sermonSlidesWebView!.scrollView.contentSize.width)")
//        print("\(slidesZoomScale)")
        
        slidesContentOffset = CGPointMake(  CGFloat(slidesContentOffsetXRatio) * sermonSlidesWebView!.scrollView.contentSize.width * slidesZoomScale,
                                            CGFloat(slidesContentOffsetYRatio) * sermonSlidesWebView!.scrollView.contentSize.height * slidesZoomScale)
        
        wkSetZoomAndOffset(sermonSlidesWebView!, scale: slidesZoomScale, offset: slidesContentOffset)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
//        print("wkWebViewDidFinishNavigation")
        
//        print("Frame: \(webView.frame)")
//        print("Bounds: \(webView.bounds)")

        if (self.view != nil) {
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            
            loadTimer?.invalidate()
            loadTimer = nil
            progressIndicator.hidden = true

            if (selectedSermon != nil) {
                if (webView == sermonNotesWebView) {
                    if (selectedSermon!.showing == Constants.NOTES) {
                        webView.hidden = false
                    }

                    setNotesContentOffsetViewScale()
                }
                
                if (webView == sermonSlidesWebView) {
                    if (selectedSermon!.showing == Constants.SLIDES) {
                        webView.hidden = false
                    }
                    
                    setSlidesContentOffsetViewScale()
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
