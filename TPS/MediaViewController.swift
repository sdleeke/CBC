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

class Document {
    var loadTimer:Timer? // Why does each document have its own loadTimer?
    
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
    
    var sliderObserver:Timer?
    
    init(purpose:String,mediaItem:MediaItem?)
    {
        self.purpose = purpose
        self.mediaItem = mediaItem
    }
    
    func visible(_ mediaItem:MediaItem?) -> Bool
    {
        return (mediaItem == self.mediaItem) && (mediaItem?.showing == purpose)
    }
}

class ControlView : UIView {
    var sliding = false
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        print(event)
        if !sliding {
//            print("checking views")
            for view in subviews {
                if view.frame.contains(point) {
                    return true
                }
            }
        }
        
//        print("Passing all touches to the next view (if any), in the view stack.")
        return false
    }
}

class MediaViewController: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate {

    @IBOutlet weak var controlView: ControlView!
    
    @IBOutlet weak var controlViewTop: NSLayoutConstraint!
    
    var observerActive = false

    private var PlayerContext = 0
    
    var player:AVPlayer?
    
    var panning = false
    
//    var sliderObserver:Timer?

//    var showScripture = false
    
    var documents = [String:[String:Document]]()
    
    var document:Document? {
        get {
            if (selectedMediaItem != nil) && (selectedMediaItem!.showing != nil) {
                return documents[selectedMediaItem!.id]![selectedMediaItem!.showing!]
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
            
            if (selectedMediaItem != nil) {
                if (documents[selectedMediaItem!.id] == nil) {
                    documents[selectedMediaItem!.id] = [String:Document]()
                }
                
                if (notesDocument != nil) {
                    documents[selectedMediaItem!.id]![notesDocument!.purpose!] = notesDocument
                }
            }
        }
    }
    
    var slidesDocument:Document? {
        didSet {
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if (selectedMediaItem != nil) {
                if (documents[selectedMediaItem!.id] == nil) {
                    documents[selectedMediaItem!.id] = [String:Document]()
                }
                
                if (slidesDocument != nil) {
                    documents[selectedMediaItem!.id]?[slidesDocument!.purpose!] = slidesDocument
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
    
    func removePlayerObserver()
    {
        if observerActive {
            player?.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerContext)
            observerActive = false
        }
    }
    
    func addPlayerObserver()
    {
        player?.currentItem?.addObserver(self,
                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.old, .new],
                                         context: &PlayerContext)
        observerActive = true
    }
    
    func playerURL(url: URL?)
    {
        removePlayerObserver()
        
        if url != nil {
            player = AVPlayer(url: url!)
            
            addPlayerObserver()
        }
    }
    
    var selectedMediaItem:MediaItem? {
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: oldValue)
            }
            
            if (selectedMediaItem != nil) && (selectedMediaItem != globals.mediaPlayer.mediaItem) {
                switch selectedMediaItem!.playing! {
                case Playing.video:
                    if selectedMediaItem!.hasVideo {
                        playerURL(url: selectedMediaItem?.videoURL)
                    }
                    break

                default:
                    if selectedMediaItem!.hasAudio {
                        playerURL(url: selectedMediaItem?.audioURL!)
                    }
                    break
                }
            } else {
                removePlayerObserver()
//                addSliderObserver() // Crashes because it uses UI and this is done before viewWillAppear when the mediaItemSelected is set in prepareForSegue, but it only happens on an iPhone because the MVC isn't setup already.
            }
            
            notesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            slidesDocument = nil // CRITICAL because it removes the scrollView.delegate from the last one (if any)
            
            if (selectedMediaItem != nil) {
                if (selectedMediaItem!.hasNotes) {
                    notesDocument = documents[selectedMediaItem!.id]?[Purpose.notes]
                    
                    if (notesDocument == nil) {
                        notesDocument = Document(purpose: Purpose.notes, mediaItem: selectedMediaItem)
                    }
                }
                
                if (selectedMediaItem!.hasSlides) {
                    slidesDocument = documents[selectedMediaItem!.id]?[Purpose.slides]
                    
                    if (slidesDocument == nil) {
                        slidesDocument = Document(purpose: Purpose.slides, mediaItem: selectedMediaItem)
                    }
                }

                multiPartMediaItems = selectedMediaItem?.multiPartMediaItems // mediaItemsInMediaItemSeries(selectedMediaItem)
                
//                print(selectedMediaItem)
//                let defaults = UserDefaults.standard
//                defaults.set(selectedMediaItem!.id,forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL)
//                defaults.synchronize()

                globals.mediaCategory.selectedInDetail = selectedMediaItem?.id
                
                NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: selectedMediaItem) //
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                multiPartMediaItems = nil
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
    
    var multiPartMediaItems:[MediaItem]?

    @IBOutlet weak var tableViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var progressIndicator: UIProgressView!

    @IBOutlet weak var viewSplit: ViewSplit!

    @IBOutlet weak var audioOrVideoControl: UISegmentedControl!
    @IBOutlet weak var audioOrVideoWidthConstraint: NSLayoutConstraint!
    
    @IBAction func audioOrVideoSelection(sender: UISegmentedControl)
    {
//        print(selectedMediaItem!.playing!)
        
        switch sender.selectedSegmentIndex {
        case Constants.AV_SEGMENT_INDEX.AUDIO:
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                //Do nothing, already selected
                break
                
            case Playing.video:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    globals.mediaPlayer.stop() // IfPlaying
                    
                    globals.mediaPlayer.view?.isHidden = true

                    // Because there is a mediaItem selected but we've STOPPED so there isn't one playing.
//                    globals.mediaPlayer.mediaItem = nil // Handled by stop()
                    
                    setupSpinner()
//                    if spinner.isAnimating {
//                        spinner.isHidden = true
//                        spinner.stopAnimating()
//                    }
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSliderAndTimes()
                }

                playerURL(url: selectedMediaItem?.audioURL)
                setupSliderAndTimes()

                selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                setupDocumentsAndVideo() // Calls setupSTVControl()
                break
                
            default:
                break
            }
            break
            
        case Constants.AV_SEGMENT_INDEX.VIDEO:
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    globals.mediaPlayer.stop() // IfPlaying
                    
                    // Because there is a mediaItem selected but we've STOPPED so there isn't one playing.
//                    globals.mediaPlayer.mediaItem = nil // Handled by stop()
                    
                    setupSpinner()
//                    if spinner.isAnimating {
//                        spinner.isHidden = true
//                        spinner.stopAnimating()
//                    }
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSliderAndTimes()
                }

                playerURL(url: selectedMediaItem?.videoURL)
                setupSliderAndTimes()
                
                selectedMediaItem?.playing = Playing.video // Must come before setupNoteAndSlides()
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
        
        switch selectedMediaItem!.showing! {
        case Showing.video:
            fromView = globals.mediaPlayer.view
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
            case Constants.STV_SEGMENT_TITLE.SLIDES:
                showing = Showing.slides
                toView = documents[selectedMediaItem!.id]?[Purpose.slides]?.wkWebView
                mediaItemNotesAndSlides.gestureRecognizers = nil
                break
                
            case Constants.STV_SEGMENT_TITLE.TRANSCRIPT:
                showing = Showing.notes
                toView = documents[selectedMediaItem!.id]?[Purpose.notes]?.wkWebView
                mediaItemNotesAndSlides.gestureRecognizers = nil
                break
                
            case Constants.STV_SEGMENT_TITLE.VIDEO:
                toView = globals.mediaPlayer.view
                showing = Showing.video
                mediaItemNotesAndSlides.gestureRecognizers = nil
                let pan = UIPanGestureRecognizer(target: self, action: #selector(MediaViewController.showHideSlider(_:)))
                mediaItemNotesAndSlides?.addGestureRecognizer(pan)
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

        self.mediaItemNotesAndSlides.bringSubview(toFront: toView!)
        self.selectedMediaItem!.showing = showing

        if (fromView != toView) {
            fromView?.isHidden = true
        }
    
//        UIView.transitionWithView(self.mediaItemNotesAndSlides, duration: Constants.VIEW_TRANSITION_TIME, options: transitionOptions, animations: {
//            toView?.hidden = false
//            self.mediaItemNotesAndSlides.bringSubviewToFront(toView!)
//            self.selectedMediaItem!.showing = purpose
//        }, completion: { finished in
//            if (fromView != toView) {
//                fromView?.hidden = true
//            }
//        })
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard (context == &PlayerContext) else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            setupSliderAndTimes()
//            let status: AVPlayerItemStatus
//            
//            // Get the status change from the change dictionary
//            if let statusNumber = change?[.newKey] as? NSNumber {
//                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
//            } else {
//                status = .unknown
//            }
//            
//            // Switch over the status
//            switch status {
//            case .readyToPlay:
//                // Player item is ready to play.
//                //                print(player?.currentItem?.duration.value)
//                //                print(player?.currentItem?.duration.timescale)
//                //                print(player?.currentItem?.duration.seconds)
//                setupSliderAndTimes()
//
////                if let length = player?.currentItem?.duration.seconds {
////                    let timeNow = Double(selectedMediaItem!.currentTime!)!
////                    let progress = timeNow / length
////                    
////                    //                    print("timeNow",timeNow)
////                    //                    print("progress",progress)
////                    //                    print("length",length)
////                    
////                    slider.value = Float(progress)
////                    setTimes(timeNow: timeNow,length: length)
////                    
////                    elapsed.isHidden = false
////                    remaining.isHidden = false
////                    slider.isHidden = false
////                    slider.isEnabled = false
////                }
//                break
//                
//            case .failed:
//                // Player item failed. See error.
//                setupSliderAndTimes()
//                break
//                
//            case .unknown:
//                // Player item is not yet ready.
//                setupSliderAndTimes()
//                break
//            }
        }
    }

    func setupSTVControl()
    {
        if (selectedMediaItem != nil) {
            stvControl.removeAllSegments()
            
            var index = 0
            var slidesIndex = 0
            var notesIndex = 0
            var videoIndex = 0

            let attr = [NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.ICONS_FONT_SIZE)!]
            stvControl.setTitleTextAttributes(attr, for: UIControlState())
            
            // This order: Transcript (aka Notes), Slides, Video matches the CBC web site.
            
            if (selectedMediaItem!.hasNotes) {
                stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.TRANSCRIPT, at: index, animated: false)
                notesIndex = index
                index += 1
            }
            if (selectedMediaItem!.hasSlides) {
                stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.SLIDES, at: index, animated: false)
                slidesIndex = index
                index += 1
            }
            if (selectedMediaItem!.hasVideo && (globals.mediaPlayer.mediaItem == selectedMediaItem) && (selectedMediaItem?.playing == Playing.video)) { //  && !globals.mediaPlayer.loadFailed
                stvControl.insertSegment(withTitle: Constants.STV_SEGMENT_TITLE.VIDEO, at: index, animated: false)
                videoIndex = index
                index += 1
            }
            
            stvWidthConstraint.constant = Constants.MIN_STV_SEGMENT_WIDTH * CGFloat(index)
            view.setNeedsLayout()

            switch selectedMediaItem!.showing! {
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
                let pan = UIPanGestureRecognizer(target: self, action: #selector(MediaViewController.showHideSlider(_:)))
                mediaItemNotesAndSlides?.addGestureRecognizer(pan)
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
        if (globals.mediaPlayer.state != nil) && (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
            switch globals.mediaPlayer.state! {
            case .none:
//                NSLog("none")
                break
                
            case .playing:
//                NSLog("playing")
                globals.mediaPlayer.pause() // IfPlaying

                setupPlayPauseButton()
                setupSpinner()
//                if spinner.isAnimating {
//                    spinner.stopAnimating()
//                    spinner.isHidden = true
//                }
                break
                
            case .paused:
//                NSLog("paused")
                if globals.mediaPlayer.loaded && (globals.mediaPlayer.url == selectedMediaItem?.playingURL) {
                    playCurrentMediaItem(selectedMediaItem)
//                    switch globals.mediaPlayer.mediaItem!.playing! {
//                    case Playing.audio:
//                        playCurrentMediaItem(selectedMediaItem)
//                        break
//                        
//                    case Playing.video:
//                        reloadCurrentMediaItem(selectedMediaItem)
//                        break
//                        
//                    default:
//                        break
//                    }
                } else {
                    playNewMediaItem(selectedMediaItem)
                }
                break
                
            case .stopped:
//                NSLog("stopped")
                break
                
            case .seekingForward:
//                NSLog("seekingForward")
                globals.mediaPlayer.pause() // IfPlaying
//                setupPlayPauseButton()
                break
                
            case .seekingBackward:
//                NSLog("seekingBackward")
                globals.mediaPlayer.pause() // IfPlaying
//                setupPlayPauseButton()
                break
            }
        } else {
            playNewMediaItem(selectedMediaItem)
        }
    }
    
    fileprivate func mediaItemNotesAndSlidesConstraintMinMax(_ height:CGFloat) -> (min:CGFloat,max:CGFloat)
    {
        var minConstraintConstant:CGFloat
        var maxConstraintConstant:CGFloat
        
        minConstraintConstant = tableView.rowHeight*0 + 28 + 16 //margin on top and bottom of slider

        maxConstraintConstant = height - 31 - (navigationController != nil ? navigationController!.navigationBar.bounds.height : 0) + 11

//        NSLog("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
//        
//        print(minConstraintConstant,maxConstraintConstant)
        
        return (minConstraintConstant,maxConstraintConstant)
    }

    fileprivate func roomForLogo() -> Bool
    {
        return viewSplit.height > (self.view.bounds.height - slider.bounds.height - navigationController!.navigationBar.bounds.height - logo.bounds.height)
    }
    
    fileprivate func shouldShowLogo() -> Bool
    {
        var result = (selectedMediaItem == nil)

        if (document != nil) {
            result = ((wkWebView == nil) || (wkWebView!.isHidden == true)) && progressIndicator.isHidden
        } else {
            if (selectedMediaItem?.showing == Showing.video) {
                result = false
            }
            if (selectedMediaItem?.showing == Showing.none) {
                result = true
            }
        }

        if (selectedMediaItem != nil) && (documents[selectedMediaItem!.id] != nil) {
            var nilCount = 0
            var hiddenCount = 0
            
            for key in documents[selectedMediaItem!.id]!.keys {
                let wkWebView = documents[selectedMediaItem!.id]![key]!.wkWebView
                if (wkWebView == nil) {
                    nilCount += 1
                }
                if (wkWebView != nil) && (wkWebView!.isHidden == true) {
                    hiddenCount += 1
                }
            }
            
            if (nilCount == documents[selectedMediaItem!.id]!.keys.count) {
                result = true
            } else {
                if (hiddenCount > 0) {
                    result = progressIndicator.isHidden
                }
            }
        }

        return result
    }

    //        if selectedMediaItem != nil {
    //            switch selectedMediaItem!.showing! {
    //            case Showing.video:
    //                result = false
    //                break
    //
    //            case Showing.notes:
    //                result = ((mediaItemNotesWebView == nil) || (mediaItemNotesWebView!.hidden == true)) && progressIndicator.hidden
    //                break
    //
    //            case Showing.slides:
    //                result = ((mediaItemSlidesWebView == nil) || (mediaItemSlidesWebView!.hidden == true)) && progressIndicator.hidden
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
    //        if (mediaItemNotesWebView == nil) && (mediaItemSlidesWebView == nil) {
    //            return true
    //        }
    //
    //        if (mediaItemNotesWebView == nil) && ((mediaItemSlidesWebView != nil) && (mediaItemSlidesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    //
    //        if (mediaItemSlidesWebView == nil) && ((mediaItemNotesWebView != nil) && (mediaItemNotesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    //
    //        if ((mediaItemNotesWebView != nil) && (mediaItemNotesWebView!.hidden == true)) && ((mediaItemSlidesWebView != nil) && (mediaItemSlidesWebView!.hidden == true)) {
    //            return progressIndicator.hidden
    //        }
    
    fileprivate func setMediaItemNotesAndSlidesConstraint(_ change:CGFloat)
    {
        let newConstraintConstant = mediaItemNotesAndSlidesConstraint.constant + change
        
        //            NSLog("pan rowHeight: \(tableView.rowHeight)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        viewSplit.min = minConstraintConstant
        viewSplit.max = maxConstraintConstant
        viewSplit.height = mediaItemNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
        
        logo.isHidden = !shouldShowLogo() //&& roomForLogo()
    }
    
    
    @IBOutlet weak var vSlideView: UIView!
    @IBAction func vSlideTap(_ sender: UITapGestureRecognizer) {
        controlViewTop.constant = 0
        self.view.setNeedsLayout()
    }
    @IBAction func vSlidePan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            break
            
        case .ended:
            break
            
        case .changed:
            let translation = pan.translation(in: hSlideView)
            
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

            pan.setTranslation(CGPoint.zero, in: hSlideView)
            break
            
        default:
            break
        }
    }
    
    @IBOutlet weak var hSlideView: UIView!
    @IBAction func hSlideTap(_ sender: UITapGestureRecognizer) {
        setTableViewWidth(width: self.view.bounds.size.width / 2)
        self.view.setNeedsLayout()
    }
    @IBAction func hSlidePan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            break
            
        case .ended:
            captureSlideSplit()
            break
            
        case .changed:
            let translation = pan.translation(in: hSlideView)
            
            if translation.x != 0 {
                setTableViewWidth(width: tableViewWidth.constant + -translation.x)
                self.view.setNeedsLayout()
//                self.view.layoutSubviews()
            }
            
            pan.setTranslation(CGPoint.zero, in: hSlideView)
            break
            
        default:
            break
        }
    }

    
    @IBAction func viewSplitPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            for document in documents[selectedMediaItem!.id]!.values {
//                document.wkWebView?.isHidden = true
                document.wkWebView?.scrollView.delegate = nil
            }

            panning = true
            break
            
        case .ended:
            captureViewSplit()

            for document in documents[selectedMediaItem!.id]!.values {
                document.wkWebView?.isHidden = (wkWebView?.url == nil)
                document.wkWebView?.scrollView.delegate = self
            }

            panning = false
            break
        
        case .changed:
            let translation = gesture.translation(in: viewSplit)
            let change = -translation.y
            if change != 0 {
                gesture.setTranslation(CGPoint.zero, in: viewSplit)
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
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var mediaItemNotesAndSlidesConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mediaItemNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var slider: OBSlider!
    
    fileprivate func adjustAudioAfterUserMovedSlider()
    {
//        if (globals.mediaPlayer.player == nil) { //  && Reachability.isConnectedToNetwork()
//            globals.setupPlayer(selectedMediaItem)
//        }
//        
        if (globals.mediaPlayer.player != nil) {
            if (slider.value < 1.0) {
                let length = globals.mediaPlayer.duration!.seconds
                let seekToTime = Double(slider.value) * length
                
                globals.mediaPlayer.seek(to: seekToTime)
                
                globals.mediaPlayer.mediaItem?.currentTime = seekToTime.description
            } else {
                globals.mediaPlayer.pause()

                globals.mediaPlayer.seek(to: globals.mediaPlayer.duration?.seconds)
                
                globals.mediaPlayer.mediaItem?.currentTime = globals.mediaPlayer.duration!.seconds.description
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
    }
    
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        NSLog("sliderTouchDown")
        controlView.sliding = true
        removeSliderObserver()
    }
    
    @IBAction func sliderTouchUpOutside(_ sender: UISlider) {
        NSLog("sliderTouchUpOutside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderTouchUpInside(_ sender: UISlider) {
        NSLog("sliderTouchUpInside")
        adjustAudioAfterUserMovedSlider()
    }
    
    @IBAction func sliderValueChanging(_ sender: UISlider) {
        setTimesToSlider()
    }
    
    var actionButton:UIBarButtonItem?
    var tagsButton:UIBarButtonItem?

    func showSendMessageErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send a Message",
                                      message: "Your device could not send a text message.  Please check your configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: MFMessageComposeViewControllerDelegate Method
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func message(_ mediaItem:MediaItem?)
    {
        
        let messageComposeViewController = MFMessageComposeViewController()
        messageComposeViewController.messageComposeDelegate = self // Extremely important to set the --messageComposeDelegate-- property, NOT the --delegate-- property
        
        messageComposeViewController.recipients = nil
        messageComposeViewController.subject = "Recommendation"
        messageComposeViewController.body = setupBody(mediaItem)
        
        if MFMessageComposeViewController.canSendText() {
            self.present(messageComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func setupBody(_ mediaItem:MediaItem?) -> String? {
        var bodyString:String?
        
        if (mediaItem != nil) {
            bodyString = Constants.QUOTE + mediaItem!.title! + Constants.QUOTE + " by " + mediaItem!.speaker! + " from " + Constants.CBC.LONG

            bodyString = bodyString! + "\n\nAudio: " + mediaItem!.audioURL!.absoluteString
            
            if mediaItem!.hasVideo {
                bodyString = bodyString! + "\n\nVideo " + mediaItem!.externalVideo!
            }
            
            if mediaItem!.hasSlides {
                bodyString = bodyString! + "\n\nSlides: " + mediaItem!.slidesURL!.absoluteString
            }
            
            if mediaItem!.hasNotes {
                bodyString = bodyString! + "\n\nTranscript " + mediaItem!.notesURL!.absoluteString
            }
        }
        
        return bodyString
    }
    
    func setupMediaItemBodyHTML(_ mediaItem:MediaItem?) -> String? {
        var bodyString:String?
        
        if (mediaItem != nil) {
            bodyString = Constants.QUOTE +  "<a href=\"" + mediaItem!.websiteURL!.absoluteString + "\">\(mediaItem!.title!)</a>" + Constants.QUOTE + " by " + mediaItem!.speaker! + " from <a href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a>"
            
            bodyString = bodyString! + " (<a href=\"" + mediaItem!.audioURL!.absoluteString + "\">Audio</a>)"
            
            if mediaItem!.hasVideo {
                bodyString = bodyString! + " (<a href=\"" + mediaItem!.externalVideo! + "\">Video</a>) "
            }

            if mediaItem!.hasSlides {
                bodyString = bodyString! + " (<a href=\"" + mediaItem!.slidesURL!.absoluteString + "\">Slides</a>)"
            }
            
            if mediaItem!.hasNotes {
                bodyString = bodyString! + " (<a href=\"" + mediaItem!.notesURL!.absoluteString + "\">Transcript</a>) "
            }
            
            bodyString = bodyString! + "<br/>"
        }
        
        return bodyString
    }
    
    func setupMultiPartMediaItemBodyHTML(_ multiPartMediaItems:[MediaItem]?) -> String? {
        var bodyString:String?

        if let mediaItems = multiPartMediaItems {
            var speakerCounts = [String:Int]()
            
            for mediaItem in mediaItems {
                if mediaItem.speaker != nil {
                    if speakerCounts[mediaItem.speaker!] == nil {
                        speakerCounts[mediaItem.speaker!] = 1
                    } else {
                        speakerCounts[mediaItem.speaker!]! += 1
                    }
                }
            }
            
            let multiPartName = mediaItems[0].multiPartName
            
            let speakerCount = speakerCounts.keys.count
            
            let speakers = speakerCounts.keys.map({ (string:String) -> String in
                return string
            }) as [String]
            
            if (mediaItems.count > 0) {
                switch speakerCount {
                case 1:
                    bodyString = "\"\(multiPartName!)\" by \(speakers[0])"
                    break
                    
                default:
                    bodyString = "\"\(multiPartName!)\""
                    break
                }
                bodyString = bodyString! + " from <a href=\"\(Constants.CBC.WEBSITE)\">" + Constants.CBC.LONG + "</a>"
                bodyString = bodyString! + "<br/>" + "<br/>"
                
                let mediaItemList = mediaItems.sorted() {
                    if ($0.fullDate!.isEqualTo($1.fullDate!)) {
                        return $0.service < $1.service
                    } else {
                        return $0.fullDate!.isOlderThan($1.fullDate!)
                    }
                }
                
                for mediaItem in mediaItemList {
                    if speakerCount > 1 {
                        bodyString = bodyString! + "<a href=\"" + mediaItem.websiteURL!.absoluteString + "\">\(mediaItem.title!)</a>" + " by \(mediaItem.speaker!)"
                    } else {
                        bodyString = bodyString! + "<a href=\"" + mediaItem.websiteURL!.absoluteString + "\">\(mediaItem.title!)</a>"
                    }
                    
                    bodyString = bodyString! + " (<a href=\"" + mediaItem.audioURL!.absoluteString + "\">Audio</a>)"
                    
                    if mediaItem.hasVideo {
                        bodyString = bodyString! + " (<a href=\"" + mediaItem.externalVideo! + "\">Video</a>) "
                    }
                    
                    if mediaItem.hasSlides {
                        bodyString = bodyString! + " (<a href=\"" + mediaItem.slidesURL!.absoluteString + "\">Slides</a>)"
                    }
                    
                    if mediaItem.hasNotes {
                        bodyString = bodyString! + " (<a href=\"" + mediaItem.notesURL!.absoluteString + "\">Transcript</a>) "
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
        let addressString:String = "<br/>\(Constants.CBC.LONG)<br/>\(Constants.CBC.STREET_ADDRESS)<br/>\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)<br/>\(Constants.CBC.PHONE_NUMBER)<br/><a href=\"mailto:\(Constants.CBC.EMAIL)\">\(Constants.CBC.EMAIL)</a><br/>\(Constants.CBC.WEBSITE)"
        
        return addressString
    }
    
    func addressString() -> String
    {
        let addressString:String = "\n\n\(Constants.CBC.LONG)\n\(Constants.CBC.STREET_ADDRESS)\n\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)\nPhone: \(Constants.CBC.PHONE_NUMBER)\nE-mail:\(Constants.CBC.EMAIL)\nWeb: \(Constants.CBC.WEBSITE)"
        
        return addressString
    }
    
    func mailMediaItem(_ mediaItem:MediaItem?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ONE_SUBJECT)

        if let bodyString = setupMediaItemBodyHTML(mediaItem) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }

        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func mailMediaItemSeries(_ mediaItems:[MediaItem]?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
        
        if let bodyString = setupMultiPartMediaItemBodyHTML(mediaItems) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func printMediaItem(_ mediaItem:MediaItem?)
    {
        if (UIPrintInteractionController.isPrintingAvailable && (mediaItem != nil))
        {
            let printURL = mediaItem?.downloadURL
            
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
    
    fileprivate func openMediaItemScripture(_ mediaItem:MediaItem?)
    {
        var urlString = Constants.SCRIPTURE_URL.PREFIX + mediaItem!.scripture! + Constants.SCRIPTURE_URL.POSTFIX

        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

//        NSLog("\(mediaItem!.scripture!)")
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
    
//    func twitter(mediaItem:MediaItem?)
//    {
//        assert(mediaItem != nil, "can't tweet about a nil mediaItem")
//
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
//            var bodyString = String()
//            
//            bodyString = "Great mediaItem: \"\(mediaItem!.title!)\" by \(mediaItem!.speaker!).  " + Constants.BASE_AUDIO_URL + mediaItem!.audio!
//            
//            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
//            twitterSheet.setInitialText(bodyString)
//            //                let str = Constants.BASE_AUDIO_URL + mediaItem!.audio!
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
////                bodyString = "Great mediaItem: \"\(mediaItem!.title!)\" by \(mediaItem!.speaker!).  " + Constants.BASE_AUDIO_URL + mediaItem!.audio!
////                
////                let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
////                twitterSheet.setInitialText(bodyString)
//////                let str = Constants.BASE_AUDIO_URL + mediaItem!.audio!
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
//    func facebook(mediaItem:MediaItem?)
//    {
//        assert(mediaItem != nil, "can't post about a nil mediaItem")
//
//        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
//            var bodyString = String()
//            
//            bodyString = "Great mediaItem: \"\(mediaItem!.title!)\" by \(mediaItem!.speaker!).  " + Constants.BASE_AUDIO_URL + mediaItem!.audio!
//            
//            //So the user can paste the initialText into the post dialog/view
//            //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
//            UIPasteboard.generalPasteboard().string = bodyString
//            
//            let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//            facebookSheet.setInitialText(bodyString)
//            //                let str = Constants.BASE_AUDIO_URL + mediaItem!.audio!
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
////                bodyString = "Great mediaItem: \"\(mediaItem!.title!)\" by \(mediaItem!.speaker!).  " + Constants.BASE_AUDIO_URL + mediaItem!.audio!
////
////                //So the user can paste the initialText into the post dialog/view
////                //This is because of the known bug that when the latest FB app is installed it prevents prefilling the post.
////                UIPasteboard.generalPasteboard().string = bodyString
////
////                let facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
////                facebookSheet.setInitialText(bodyString)
//////                let str = Constants.BASE_AUDIO_URL + mediaItem!.audio!
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
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, mediaItem:MediaItem?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                mediaItem?.audioDownload?.deleteDownload()
                break
                
            case Constants.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDeleteDownload()
                break
                
            default:
                break
            }
            break
            
        case .selectingAction:
            switch strings[index] {
            case Constants.Print:
                printMediaItem(selectedMediaItem)
                break
                
            case Constants.Add_to_Favorites:
                selectedMediaItem?.addTag(Constants.Favorites)
                break
                
            case Constants.Add_All_to_Favorites:
                for mediaItem in multiPartMediaItems! {
                    mediaItem.addTag(Constants.Favorites)
                }
                break
                
            case Constants.Remove_From_Favorites:
                selectedMediaItem?.removeTag(Constants.Favorites)
                break
                
            case Constants.Remove_All_From_Favorites:
                for mediaItem in multiPartMediaItems! {
                    mediaItem.removeTag(Constants.Favorites)
                }
                break
                
            case Constants.Zoom:
                if (selectedMediaItem!.hasVideo && selectedMediaItem!.playingVideo && selectedMediaItem!.showingVideo) {
//                    zoomScreen()
                }
                
                if document != nil {
//                if (selectedMediaItem!.hasSlides() && selectedMediaItem!.showingSlides()) || (selectedMediaItem!.hasNotes() && selectedMediaItem!.showingNotes()) {
//                    showScripture = false
//                    zoomScreen()
//                    performSegue(withIdentifier: Constants.SHOW_FULL_SCREEN_SEGUE, sender: selectedMediaItem)
                }
                break
                
            case Constants.Open_on_CBC_Website:
                if selectedMediaItem?.websiteURL != nil {
                    if (UIApplication.shared.canOpenURL(selectedMediaItem!.websiteURL! as URL)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.shared.openURL(selectedMediaItem!.websiteURL! as URL)
                    } else {
                        networkUnavailable("Unable to open transcript in browser at: \(selectedMediaItem?.websiteURL)")
                    }
                }
                break
                
            case Constants.Open_in_Browser:
                if selectedMediaItem?.downloadURL != nil {
                    if (UIApplication.shared.canOpenURL(selectedMediaItem!.downloadURL! as URL)) { // Reachability.isConnectedToNetwork() &&
                        UIApplication.shared.openURL(selectedMediaItem!.downloadURL! as URL)
                    } else {
                        networkUnavailable("Unable to open transcript in browser at: \(selectedMediaItem?.downloadURL)")
                    }
                }
                break
                
//            case Constants.Scripture_Full_Screen:
//                showScripture = true
//                performSegueWithIdentifier(Constants.SHOW_FULL_SCREEN_SEGUE_IDENTIFIER, sender: selectedMediaItem)
//                break
                
            case Constants.Scripture_in_Browser:
                openMediaItemScripture(selectedMediaItem)
                break
                
            case Constants.Download_Audio:
                selectedMediaItem?.audioDownload?.download()
                break
                
            case Constants.Download_All_Audio:
                for mediaItem in multiPartMediaItems! {
                    mediaItem.audioDownload?.download()
                }
                break
                
            case Constants.Cancel_Audio_Download:
                selectedMediaItem?.audioDownload?.cancelOrDeleteDownload()
                break
                
            case Constants.Cancel_All_Audio_Downloads:
                for mediaItem in multiPartMediaItems! {
                    mediaItem.audioDownload?.cancelDownload()
                }
                break
                
            case Constants.Delete_Audio_Download:
                selectedMediaItem?.audioDownload?.deleteDownload()
                break
                
            case Constants.Delete_All_Audio_Downloads:
                for mediaItem in multiPartMediaItems! {
                    mediaItem.audioDownload?.deleteDownload()
                }
                break
                
            case Constants.Email_One:
                mailMediaItem(selectedMediaItem)
                break
                
            case Constants.Email_All:
                mailMediaItemSeries(multiPartMediaItems)
                break
                
            case Constants.Refresh_Document:
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

        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = actionButton
                
                //                popover.navigationItem.title = Constants.Show
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                if (document != nil) {
//                if (selectedMediaItem!.hasNotes() && selectedMediaItem!.showingNotes()) || (selectedMediaItem!.hasSlides() && selectedMediaItem!.showingSlides()) {
                    actionMenu.append(Constants.Print)
                }

                if selectedMediaItem!.hasFavoritesTag {
                    actionMenu.append(Constants.Remove_From_Favorites)
                } else {
                    actionMenu.append(Constants.Add_to_Favorites)
                }
                
                if multiPartMediaItems?.count > 1 {
                    var favoriteMediaItems = 0
                    
                    for mediaItem in multiPartMediaItems! {
                        if (mediaItem.hasFavoritesTag) {
                            favoriteMediaItems += 1
                        }
                    }
                    switch favoriteMediaItems {
                    case 0:
                        actionMenu.append(Constants.Add_All_to_Favorites)
                        break
                        
                    case 1:
                        actionMenu.append(Constants.Add_All_to_Favorites)

                        if !selectedMediaItem!.hasFavoritesTag {
                            actionMenu.append(Constants.Remove_All_From_Favorites)
                        }
                        break
                        
                    case multiPartMediaItems!.count - 1:
                        if selectedMediaItem!.hasFavoritesTag {
                            actionMenu.append(Constants.Add_All_to_Favorites)
                        }
                        
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                        
                    case multiPartMediaItems!.count:
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                        
                    default:
                        actionMenu.append(Constants.Add_All_to_Favorites)
                        actionMenu.append(Constants.Remove_All_From_Favorites)
                        break
                    }
                }
                
                actionMenu.append(Constants.Open_on_CBC_Website)
                
                if (selectedMediaItem!.hasVideo && selectedMediaItem!.playingVideo && selectedMediaItem!.showingVideo) || (document != nil) {
//                   (selectedMediaItem!.hasSlides() && selectedMediaItem!.showingSlides()) || (selectedMediaItem!.hasNotes() && selectedMediaItem!.showingNotes()) {
                    if splitViewController != nil {
//                        actionMenu.append(Constants.Zoom)
                    }
                }
                
                if (document != nil) && globals.cacheDownloads {
                    actionMenu.append(Constants.Refresh_Document)
                }

//                if (selectedMediaItem!.hasSlides() && selectedMediaItem!.showingSlides()) || (selectedMediaItem!.hasNotes() && selectedMediaItem!.showingNotes()) {
//                }
                
                if document != nil {
//                if (selectedMediaItem!.hasSlides() && selectedMediaItem!.showingSlides()) || (selectedMediaItem!.hasNotes() && selectedMediaItem!.showingNotes()) {
                    actionMenu.append(Constants.Open_in_Browser)
                }
                
//                if (selectedMediaItem!.hasScripture && (selectedMediaItem?.scripture != Constants.Selected_Scriptures)) {
//                    actionMenu.append(Constants.Scripture_Full_Screen)
//                }
                
                if (selectedMediaItem!.hasScripture && (selectedMediaItem?.scripture != Constants.Selected_Scriptures)) {
                    actionMenu.append(Constants.Scripture_in_Browser)
                }
                
                if let mediaItems = multiPartMediaItems {
                    var mediaItemsToDownload = 0
                    var mediaItemsDownloading = 0
                    var mediaItemsDownloaded = 0
                    
                    for mediaItem in mediaItems {
                        switch mediaItem.audioDownload!.state {
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
                    
                    if (selectedMediaItem?.audioDownload != nil) {
//                        print(selectedMediaItem?.audioDownload?.state)

                        switch selectedMediaItem!.audioDownload!.state {
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
                        
                        switch selectedMediaItem!.audioDownload!.state {
                        case .none:
                            if (mediaItemsToDownload > 1) {
                                actionMenu.append(Constants.Download_All_Audio)
                            }
                            if (mediaItemsDownloading > 0) {
                                actionMenu.append(Constants.Cancel_All_Audio_Downloads)
                            }
                            if (mediaItemsDownloaded > 0) {
                                actionMenu.append(Constants.Delete_All_Audio_Downloads)
                            }
                            break
                            
                        case .downloading:
                            if (mediaItemsToDownload > 0) {
                                actionMenu.append(Constants.Download_All_Audio)
                            }
                            if (mediaItemsDownloading > 1) {
                                actionMenu.append(Constants.Cancel_All_Audio_Downloads)
                            }
                            if (mediaItemsDownloaded > 0) {
                                actionMenu.append(Constants.Delete_All_Audio_Downloads)
                            }
                            break
                            
                        case .downloaded:
                            if (mediaItemsToDownload > 0) {
                                actionMenu.append(Constants.Download_All_Audio)
                            }
                            if (mediaItemsDownloading > 0) {
                                actionMenu.append(Constants.Cancel_All_Audio_Downloads)
                            }
                            if (mediaItemsDownloaded > 1) {
                                actionMenu.append(Constants.Delete_All_Audio_Downloads)
                            }
                            break
                        }
                    }
                    
//                    if (selectedMediaItem?.audioDownload?.state == State.none) {
//                        if (mediaItemsToDownload > 1) {
//                            actionMenu.append(Constants.Download_All_Audio)
//                        }
//                    } else {
//                        if (mediaItemsToDownload > 0) {
//                            actionMenu.append(Constants.Download_All_Audio)
//                        }
//                    }
                    
//                    if (selectedMediaItem?.audioDownload?.state == .downloading) {
//                        if (mediaItemsDownloading > 1) {
//                            actionMenu.append(Constants.Cancel_All_Audio_Downloads)
//                        }
//                    } else {
//                        if (mediaItemsDownloading > 0) {
//                            actionMenu.append(Constants.Cancel_All_Audio_Downloads)
//                        }
//                    }
                    
//                    if (selectedMediaItem?.audioDownload?.state == .downloaded) {
//                        if (mediaItemsDownloaded > 1) {
//                            actionMenu.append(Constants.Delete_All_Audio_Downloads)
//                        }
//                    } else {
//                        if (mediaItemsDownloaded > 0) {
//                            actionMenu.append(Constants.Delete_All_Audio_Downloads)
//                        }
//                    }
                }
                
                actionMenu.append(Constants.Email_One)
                if (selectedMediaItem!.hasMultipleParts && (multiPartMediaItems?.count > 1)) {
                        actionMenu.append(Constants.Email_All)
                }

                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
//    func zoomScreen()
//    {
//        //It works!  Problem was in globals.mediaPlayer.player?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
//        //Thank you StackOverflow!
//
////        globals.mediaPlayer.player?.setFullscreen(!globals.mediaPlayer.player!.isFullscreen, animated: true)
//        
//        if splitViewController != nil {
//            print(splitViewController!.displayMode.rawValue)
//            switch splitViewController!.displayMode {
//                //            case .automatic:
//                //                break
//                
//            case .primaryHidden:
//                splitViewController?.preferredDisplayMode = .automatic
//                break
//                
//            default:
//                splitViewController?.preferredDisplayMode = .primaryHidden
//                break
//            }
//        }
//    }
    
    func showHideSlider(_ pan:UIPanGestureRecognizer)
    {
        if controlViewTop != nil { // Implies landscape mode
            switch pan.state {
            case .began:
                break
                
            case .ended:
                captureSlideSplit()
                break
                
            case .changed:
                let translation = pan.translation(in: mediaItemNotesAndSlides)
                
                if translation.y != 0 {
                    if controlViewTop.constant + translation.y < -46 {
                        controlViewTop.constant = -46
                    } else
                        if controlViewTop.constant + translation.y > 0 {
                            controlViewTop.constant = 0
                        } else {
                            controlViewTop.constant += translation.y
                    }
                }
                
                if translation.x != 0 {
                    setTableViewWidth(width: tableViewWidth.constant + -translation.x)
                }
                
                self.view.setNeedsLayout()
                //                self.view.layoutSubviews()
                
                pan.setTranslation(CGPoint.zero, in: mediaItemNotesAndSlides)
                break
                
            default:
                break
            }
        }
    }
    
    fileprivate func setupPlayerView(_ view:UIView?)
    {
        if (view != nil) {
            view?.isHidden = true
            view?.removeFromSuperview()
            
//            view?.gestureRecognizers = nil
//            
//            let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.zoomScreen))
//            tap.numberOfTapsRequired = 2
//            view?.addGestureRecognizer(tap)
            
//            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MediaViewController.zoomScreen))
//            view?.addGestureRecognizer(pinch)

            view?.frame = mediaItemNotesAndSlides.bounds

            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            mediaItemNotesAndSlides.addSubview(view!)
            
//            print(view)
//            print(view?.superview)            
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(width)
            
            let height = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(height)
            
            mediaItemNotesAndSlides.setNeedsLayout()
        }
    }
    
    fileprivate func setupWKWebView(_ wkWebView:WKWebView?)
    {
        if (wkWebView != nil) {
            wkWebView?.isMultipleTouchEnabled = true
            
            wkWebView?.scrollView.scrollsToTop = false
            
            //        NSLog("\(mediaItemNotesAndSlides.frame)")
            //        mediaItemNotesWebView?.UIDelegate = self
            
            wkWebView?.scrollView.delegate = self
            wkWebView?.navigationDelegate = self

            wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            mediaItemNotesAndSlides.addSubview(wkWebView!)
            
            let centerXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(centerXNotes)
            
            let centerYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(centerYNotes)
            
            let widthXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(widthXNotes)
            
            let widthYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            mediaItemNotesAndSlides.addConstraint(widthYNotes)
            
            mediaItemNotesAndSlides.setNeedsLayout()
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
    
    func readyToPlay()
    {
        if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) && globals.mediaPlayer.isPaused && globals.mediaPlayer.mediaItem!.hasCurrentTime() {
            globals.mediaPlayer.seek(to: Double(globals.mediaPlayer.mediaItem!.currentTime!))
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.playing == Playing.video) {
                globals.mediaPlayer.view?.isHidden = false
                if selectedMediaItem?.showing == Showing.video {
                    mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                }
            }
        }
        
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    func paused()
    {
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    func failedToPlay()
    {
        setupSpinner()
        setupSliderAndTimes()
        setupPlayPauseButton()
    }
    
    func showPlaying()
    {
        if (globals.mediaPlayer.mediaItem != nil) && (selectedMediaItem?.multiPartMediaItems?.index(of: globals.mediaPlayer.mediaItem!) != nil) {
            selectedMediaItem = globals.mediaPlayer.mediaItem
            
            tableView.reloadData()
            
            //Without this background/main dispatching there isn't time to scroll correctly after a reload.
            
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
                })
            }
            
            updateUI()
        }
    }
    
    func updateView()
    {
        selectedMediaItem = globals.selectedMediaItem.detail
        
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            })
        }
        
        updateUI()
    }
    
    func clearView()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.hidesBackButton = true // In case this MVC was pushed from the ScriptureIndexController.
            
            self.selectedMediaItem = nil
            
            self.tableView.reloadData()
            
            self.updateUI()
        })
    }

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()

//        if splitViewController != nil {
//            navigationItem.setLeftBarButton(UIBarButtonItem(title: Constants.Zoom, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.zoomScreen)),animated: true)
//        }
        
        navigationController?.setToolbarHidden(true, animated: false)
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.resetConstraint))
        tap.numberOfTapsRequired = 2
        viewSplit?.addGestureRecognizer(tap)
        
//        viewSplit.splitViewController = splitViewController

        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true

        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath.
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension

        setupSpinner()
//        if globals.mediaPlayer.loaded {
//            if spinner.isAnimating {
//                spinner.stopAnimating()
//                spinner.isHidden = true
//            }
//        }

        if (selectedMediaItem == nil) {
            //Will only happen on an iPad
            selectedMediaItem = globals.selectedMediaItem.detail
        }

        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
        if (splitViewController?.preferredDisplayMode == .automatic) { // UIDeviceOrientationIsPortrait(UIDevice.current.orientation) && 
            splitViewController?.preferredDisplayMode = .allVisible //iPad only.
        }
    }

    fileprivate func setupDefaultDocuments()
    {
        if (selectedMediaItem != nil) {
            viewSplit.isHidden = false
            
            let hasNotes = selectedMediaItem!.hasNotes
            let hasSlides = selectedMediaItem!.hasSlides
            
            globals.mediaPlayer.view?.isHidden = true
            
            if (!hasSlides && !hasNotes) {
                hideAllDocuments()
                
                logo.isHidden = false
                selectedMediaItem!.showing = Showing.none
                
                mediaItemNotesAndSlides.bringSubview(toFront: logo)
            } else
            if (hasSlides && !hasNotes) {
                logo.isHidden = true
                
                selectedMediaItem!.showing = Showing.slides

                hideOtherDocuments()

                if (wkWebView != nil) {
                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            } else
            if (!hasSlides && hasNotes) {
                logo.isHidden = true
                
                selectedMediaItem!.showing = Showing.notes

                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            } else
            if (hasSlides && hasNotes) {
                logo.isHidden = true
                
                selectedMediaItem!.showing = selectedMediaItem!.wasShowing

                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
            }
        }
    }
    
    func downloading(_ timer:Timer?)
    {
        let document = timer?.userInfo as? Document
        
        if (selectedMediaItem != nil) {
            if (document?.download != nil) {
                NSLog("totalBytesWritten: \(document!.download!.totalBytesWritten)")
                NSLog("totalBytesExpectedToWrite: \(document!.download!.totalBytesExpectedToWrite)")
                
                switch document!.download!.state {
                case .none:
//                    NSLog(".none")
                    document?.download?.task?.cancel()
                    
                    document?.loadTimer?.invalidate()
                    document?.loadTimer = nil
                    
                    if document!.visible(selectedMediaItem) {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        
                        self.progressIndicator.isHidden = true
                        
                        document?.wkWebView?.isHidden = true
                        
                        globals.mediaPlayer.view?.isHidden = true
                        
                        self.logo.isHidden = false
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                    break
                    
                case .downloading:
//                    NSLog(".downloading")
                    if document!.visible(selectedMediaItem) {
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
//                                if document!.visible(self.selectedMediaItem) {
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
//                                if document!.visible(self.selectedMediaItem) {
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
            if document.visible(selectedMediaItem) {
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
        
        if document?.wkWebView == nil {
//            document?.wkWebView?.removeFromSuperview()
            document?.wkWebView = WKWebView(frame: mediaItemNotesAndSlides.bounds)
            loadDocument(document)
        }
        
        if !mediaItemNotesAndSlides.subviews.contains(document!.wkWebView!) {
            setupWKWebView(document?.wkWebView)
        }
    }
    
    fileprivate func loadDocument(_ document:Document?)
    {
        document?.wkWebView?.isHidden = true
        document?.wkWebView?.stopLoading()
        
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads {
//                print(document?.download?.state)
                if (document?.download != nil) && (document?.download?.state != .downloaded){
                    if document!.visible(selectedMediaItem) {
                        mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
                        mediaItemNotesAndSlides.bringSubview(toFront: progressIndicator)
                        
                        activityIndicator.isHidden = false
                        activityIndicator.startAnimating()
                        
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite != 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.isHidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.DOWNLOADING, target: self, selector: #selector(MediaViewController.downloading(_:)), userInfo: document, repeats: true)
                    }
                    
                    document?.download?.download()
                } else {
                    DispatchQueue.global(qos: .background).async(execute: { () -> Void in
//                        print(document!.download!.fileSystemURL!)
                        _ = document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            if (document != nil) && document!.visible(self.selectedMediaItem) {
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
                        if document!.visible(self.selectedMediaItem) {
                            self.activityIndicator.isHidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.isHidden = false
                        }
                        
                        if document?.loadTimer == nil {
                            document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                        }
                    })
                    
                    if (document == nil) {
                        NSLog("document nil")
                    }
                    if (document!.download == nil) {
                        NSLog("document!.download nil")
                    }
                    if (document!.download!.downloadURL == nil) {
                        NSLog("\(self.selectedMediaItem?.title)")
                        NSLog("document!.download!.downloadURL nil")
                    }
                    let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                    _ = document?.wkWebView?.load(request)
                })
            }
        } else {
            DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if document!.visible(self.selectedMediaItem) {
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.isHidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                    }
                })
                
                let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                _ = document?.wkWebView?.load(request)
            })
        }
    }
    
    fileprivate func hideOtherDocuments()
    {
        if (selectedMediaItem != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
                    if !document.visible(selectedMediaItem) {
                        document.wkWebView?.isHidden = true
                    }
                }
            }
        }
    }
    
    fileprivate func hideAllDocuments()
    {
        if (selectedMediaItem != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
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
//        NSLog("Selected: \(globals.mediaItemSelected?.title)")
//        NSLog("Last Selected: \(globals.mediaItemLastSelected?.title)")
//        NSLog("Playing: \(globals.player.playing?.title)")
        
        if (selectedMediaItem != nil) {
            viewSplit.isHidden = false

            if (selectedMediaItem!.hasNotes) {
                notesDocument = documents[selectedMediaItem!.id]?[Purpose.notes]
                
                if (notesDocument == nil) {
                    notesDocument = Document(purpose: Purpose.notes, mediaItem: selectedMediaItem)
                }
//                print(notesDocument?.download?.downloadURL)
                setupDocument(notesDocument)
            } else {
                notesDocument?.wkWebView?.isHidden = true
            }
            
            if (selectedMediaItem!.hasSlides) {
                slidesDocument = documents[selectedMediaItem!.id]?[Purpose.slides]
                
                if (slidesDocument == nil) {
                    slidesDocument = Document(purpose: Purpose.slides, mediaItem: selectedMediaItem)
                }
//                print(slidesDocument?.download?.downloadURL)
                setupDocument(slidesDocument)
            } else {
                slidesDocument?.wkWebView?.isHidden = true
            }
            
    //        NSLog("notes hidden \(mediaItemNotes.hidden)")
    //        NSLog("slides hidden \(mediaItemSlides.hidden)")
            
            // Check whether they can or should show what they claim to show!
            
            switch selectedMediaItem!.showing! {
            case Showing.notes:
                if !selectedMediaItem!.hasNotes {
                    selectedMediaItem!.showing = Showing.none
                }
                break
                
            case Showing.slides:
                if !selectedMediaItem!.hasSlides {
                    selectedMediaItem!.showing = Showing.none
                }
                break
                
            case Showing.video:
                if !selectedMediaItem!.hasVideo {
                    selectedMediaItem!.showing = Showing.none
                }
                break
                
            default:
                break
            }
            
            switch selectedMediaItem!.showing! {
            case Showing.notes:
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = true
                
                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
                break
                
            case Showing.slides:
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = true
                
                hideOtherDocuments()
                
                if (wkWebView != nil) {
                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
                break
                
            case Showing.video:
                //This should not happen unless it is playing video.
                switch selectedMediaItem!.playing! {
                case Playing.audio:
                    //This should never happen.
                    setupDefaultDocuments()
                    break

                case Playing.video:
                    if (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        hideAllDocuments()

                        if globals.mediaPlayer.loaded {
                            logo.isHidden = true
                            globals.mediaPlayer.view?.isHidden = false
                        }
                        
                        selectedMediaItem?.showing = Showing.video
                        
                        if (globals.mediaPlayer.player != nil) {
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
                break
                
            case Showing.none:
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                hideAllDocuments()
                
                switch selectedMediaItem!.playing! {
                case Playing.audio:
                    globals.mediaPlayer.view?.isHidden = true
                    setupDefaultDocuments()
                    break
                    
                case Playing.video:
                    if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        if (globals.mediaPlayer.mediaItem!.hasVideo && (globals.mediaPlayer.mediaItem!.playing == Playing.video)) {
                            if globals.mediaPlayer.loaded {
                                globals.mediaPlayer.view?.isHidden = false
                            }
                            mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                            selectedMediaItem?.showing = Showing.video
                        } else {
                            globals.mediaPlayer.view?.isHidden = true
                            self.logo.isHidden = false
                            selectedMediaItem?.showing = Showing.none
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
                break
                
            default:
                break
            }
        } else {
            viewSplit.isHidden = true
            
            hideAllDocuments()

            globals.mediaPlayer.view?.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if (!logo.isHidden) {
                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
        }

        setupSTVControl()
    }
    
    func scrollToMediaItem(_ mediaItem:MediaItem?,select:Bool,position:UITableViewScrollPosition)
    {
        if (mediaItem != nil) {
            var indexPath = IndexPath(row: 0, section: 0)
            
            if (multiPartMediaItems?.count > 0) {
                if let mediaItemIndex = multiPartMediaItems?.index(of: mediaItem!) {
//                    NSLog("\(mediaItemIndex)")
                    indexPath = IndexPath(row: mediaItemIndex, section: 0)
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
            //No mediaItem to scroll to.
            
        }
    }
    
    func setupPlayPauseButton()
    {
        if (selectedMediaItem != nil) {
            if (selectedMediaItem == globals.mediaPlayer.mediaItem) && (globals.mediaPlayer.state != nil) {
                playPauseButton.isEnabled = globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed
                
                switch globals.mediaPlayer.state! {
                case .playing:
//                    print("Pause")
                    playPauseButton.setTitle(Constants.FA.PAUSE, for: UIControlState())
                    break
                    
                case .paused:
//                    print("Play")
                    playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState())
                    break
                    
                default:
                    break
                }
            } else {
//                print("Play2")
                playPauseButton.isEnabled = true
                playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState())
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up

                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Tags
                
                popover.delegate = self
                
                popover.purpose = .showingTags
                popover.strings = selectedMediaItem?.tagsArray
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                popover.allowsSelection = false
                popover.selectedMediaItem = selectedMediaItem
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func setupActionAndTagsButtons()
    {
        if (selectedMediaItem != nil) {
            var barButtons = [UIBarButtonItem]()
            
            actionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(MediaViewController.actions))
            barButtons.append(actionButton!)
        
            if (selectedMediaItem!.hasTags) {
                if (selectedMediaItem?.tagsSet?.count > 1) {
                    tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
                } else {
                    tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
                }
                
                tagsButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.TAGS_FONT_SIZE)!], for: UIControlState())
                
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
        if (selectedMediaItem != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
                    if document.wkWebView != nil {
                        var contentOffsetXRatio:Float = 0.0
                        var contentOffsetYRatio:Float = 0.0
                        
                        //        NSLog("\(mediaItemNotesWebView!.scrollView.contentSize)")
                        //        NSLog("\(mediaItemSlidesWebView!.scrollView.contentSize)")
                        
                        if let ratio = selectedMediaItem!.mediaItemSettings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
                            contentOffsetXRatio = Float(ratio)!
                        }
                        
                        if let ratio = selectedMediaItem!.mediaItemSettings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
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
        
//        print(splitViewController?.viewControllers.count)
//        print(navigationController?.viewControllers.count)
        
        if (self.view.window == nil) {
            return
        }

        if (self.splitViewController != nil) {
            let (oldMinConstraintConstant,oldMaxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
            let (newMinConstraintConstant,newMaxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(size.height)
            
            switch self.mediaItemNotesAndSlidesConstraint.constant {
            case oldMinConstraintConstant:
                self.mediaItemNotesAndSlidesConstraint.constant = newMinConstraintConstant
                break
                
            case oldMaxConstraintConstant:
                self.mediaItemNotesAndSlidesConstraint.constant = newMaxConstraintConstant
                break
                
            default:
                let ratio = (mediaItemNotesAndSlidesConstraint.constant - oldMinConstraintConstant) / (oldMaxConstraintConstant - oldMinConstraintConstant)
                
                self.mediaItemNotesAndSlidesConstraint.constant = (ratio * (newMaxConstraintConstant - newMinConstraintConstant)) + newMinConstraintConstant
                
                if self.mediaItemNotesAndSlidesConstraint.constant < newMinConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = newMinConstraintConstant }
                if self.mediaItemNotesAndSlidesConstraint.constant > newMaxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = newMaxConstraintConstant }
                break
            }
            
            //            NSLog("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
            
            viewSplit.min = newMinConstraintConstant
            viewSplit.max = newMaxConstraintConstant
            viewSplit.height = mediaItemNotesAndSlidesConstraint.constant
            
            self.view.setNeedsLayout()
        } else {
            if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
                captureSlideSplit()

                setTableViewWidth(width: size.width)
                
                //If we started out in landscape on an iPhone and segued to this view and then transitioned to Portrait
                //The constraint is not setup because it is not active in landscape so we have to set it up
                if let split = selectedMediaItem?.viewSplit {
                    var newConstraintConstant = size.height * CGFloat(Float(split)!)
                    
                    let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(size.height - 12) //Adjustment of 12 for difference in NavBar height between landscape (shorter) and portrait (taller by 12)
                    
                    //                    NSLog("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
                    
                    if newConstraintConstant < minConstraintConstant { newConstraintConstant = minConstraintConstant }
                    if newConstraintConstant > maxConstraintConstant { newConstraintConstant = maxConstraintConstant }
                    
                    self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
                    
                    //                    NSLog("\(viewSplit) \(size) \(mediaItemNotesAndSlidesConstraint.constant)")
                    
                    viewSplit.min = minConstraintConstant
                    viewSplit.max = maxConstraintConstant
                    viewSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
                    
                    self.view.setNeedsLayout()
                }
            } else {
                //Capturing the viewSplit on a rotation from portrait to landscape for an iPhone
                captureViewSplit()
                
                if let ratio = ratioForSlideView(viewSplit) {
                    //            NSLog("\(self.view.bounds.height)")
                    setTableViewWidth(width: size.width * ratio)
                } else {
                    setTableViewWidth(width: size.width / 2)
                }
                
                self.view.setNeedsLayout()
            }
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.setupTitle()
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
                self.setupWKContentOffsets()
            })
        }
    }

    
    func ratioForSplitView(_ sender: ViewSplit) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if (selectedMediaItem != nil) {
            if let viewSplit = selectedMediaItem?.viewSplit {
                ratio = CGFloat(Float(viewSplit)!)
            }
        }
        //        NSLog("ratio: '\(ratio)")
        return ratio
    }
    
    func ratioForSlideView(_ sender: UIView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if (selectedMediaItem != nil) {
            if let slideSplit = selectedMediaItem?.slideSplit {
                ratio = CGFloat(Float(slideSplit)!)
            }
        }
        //        NSLog("ratio: '\(ratio)")
        return ratio
    }
    
    func defaultTableViewWidth()
    {
        tableViewWidth.constant = self.view!.bounds.size.width / 2
    }
    
    func setTableViewWidth(width:CGFloat)
    {
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
        var newConstraintConstant:CGFloat
        
        //        NSLog("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        newConstraintConstant = minConstraintConstant + tableView.rowHeight * (multiPartMediaItems!.count > 1 ? 1 : 1)
        
        if newConstraintConstant > ((maxConstraintConstant+minConstraintConstant)/2) {
            newConstraintConstant = (maxConstraintConstant+minConstraintConstant)/2
        }
        
        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }
        
        viewSplit.min = minConstraintConstant
        viewSplit.max = maxConstraintConstant
        viewSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
        
        captureViewSplit()
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupSlideSplit()
    {
        if splitViewController == nil {
            if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
                if let ratio = ratioForSlideView(viewSplit) {
                    //            NSLog("\(self.view.bounds.height)")
                    setTableViewWidth(width: self.view.bounds.width * ratio)
                } else {
                    setTableViewWidth(width: self.view.bounds.width / 2)
                }
                
                self.view.setNeedsLayout()
            }
        }
    }
    
    fileprivate func setupViewSplit()
    {
        var newConstraintConstant:CGFloat
        
//        NSLog("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(viewSplit) {
//            NSLog("\(self.view.bounds.height)")
            newConstraintConstant = self.view.bounds.height * ratio
        } else {
            let numberOfAdditionalRows = CGFloat(multiPartMediaItems != nil ? multiPartMediaItems!.count : 0)
            newConstraintConstant = minConstraintConstant + tableView.rowHeight * numberOfAdditionalRows
            
            if newConstraintConstant > ((maxConstraintConstant+minConstraintConstant)/2) {
                newConstraintConstant = (maxConstraintConstant+minConstraintConstant)/2
            }
        }

        if (newConstraintConstant >= minConstraintConstant) && (newConstraintConstant <= maxConstraintConstant) {
            self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
        } else {
            if newConstraintConstant < minConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = minConstraintConstant }
            if newConstraintConstant > maxConstraintConstant { self.mediaItemNotesAndSlidesConstraint.constant = maxConstraintConstant }
        }

        viewSplit.min = minConstraintConstant
        viewSplit.max = maxConstraintConstant
        viewSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
        
        self.view.setNeedsLayout()
    }
    
    fileprivate func setupTitle()
    {
        if (selectedMediaItem != nil) {
            if (selectedMediaItem!.hasMultipleParts) {
                //The selected mediaItem is in a series so set the title.
                self.navigationItem.title = selectedMediaItem?.multiPartName
            } else {
//                print(selectedMediaItem?.title ?? nil)
                self.navigationItem.title = selectedMediaItem?.title
            }
        } else {
            self.navigationItem.title = nil
        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        if (selectedMediaItem != nil) {
            if (selectedMediaItem!.hasVideo) {
                audioOrVideoControl.isEnabled = true
                audioOrVideoControl.isHidden = false
                audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
                view.setNeedsLayout()

                audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO)
                audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO)
                
//                print(selectedMediaItem!.playing!)
                
                switch selectedMediaItem!.playing! {
                case Playing.audio:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.AUDIO
                    break
                    
                case Playing.video:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.VIDEO
                    break
                    
                default:
                    break
                }

                let attr = [NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.ICONS_FONT_SIZE)!]
                
                audioOrVideoControl.setTitleTextAttributes(attr, for: UIControlState())
                
                audioOrVideoControl.setTitle(Constants.FA.AUDIO, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO) // Audio

                audioOrVideoControl.setTitle(Constants.FA.VIDEO, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO) // Video
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
        if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) && ((globals.mediaPlayer.url != selectedMediaItem?.videoURL) && (globals.mediaPlayer.url != selectedMediaItem?.audioURL)) {
            globals.mediaPlayer.pause()
            globals.setupPlayer(selectedMediaItem,playOnLoad:false)
        }

        setupPlayerView(globals.mediaPlayer.view)

        //        NSLog("viewWillAppear 1 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        NSLog("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        setupViewSplit()
        setupSlideSplit()
        
        //        NSLog("viewWillAppear 2 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        NSLog("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the mediaItem selected is playing already
        addSliderObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSpinner()
        setupSliderAndTimes()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)

        if (splitViewController != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }

        if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) && globals.mediaPlayer.isPaused && globals.mediaPlayer.mediaItem!.hasCurrentTime() {
            globals.mediaPlayer.seek(to: Double(globals.mediaPlayer.mediaItem!.currentTime!))
        }

        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
        if (splitViewController?.preferredDisplayMode == .automatic) { // UIDeviceOrientationIsPortrait(UIDevice.current.orientation) &&
            splitViewController?.preferredDisplayMode = .allVisible //iPad only
        }

        updateUI()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            })
        })
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = .automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        }
    }
    
//    func setupZoom()
//    {
//        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
//            if splitViewController != nil {
//                navigationItem.setLeftBarButton(nil,animated: true)
//            }
//        } else {
//            if splitViewController != nil {
//                navigationItem.setLeftBarButton(UIBarButtonItem(title: Constants.Zoom, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.zoomScreen)),animated: true)
//            }
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        NSLog("viewDidAppear mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
//        NSLog("viewDidAppear tableView.bounds: \(tableView.bounds)")

//        setupSplitViewController()
        
//        setupZoom()
        
//        updateUI()
    }
    
    fileprivate func captureViewSplit()
    {
        //        NSLog("captureViewSplit: \(mediaItemSelected?.title)")
        
        if (self.view != nil) && (viewSplit.bounds.size.width > 0) {
            if (selectedMediaItem != nil) {
                //                NSLog("\(self.view.bounds.height)")
                let ratio = self.mediaItemNotesAndSlidesConstraint.constant / self.view.bounds.height
                
                //            NSLog("captureViewSplit ratio: \(ratio)")
                
                selectedMediaItem?.viewSplit = "\(ratio)"
            }
        }
    }
    
    fileprivate func captureSlideSplit()
    {
        //        NSLog("captureViewSplit: \(mediaItemSelected?.title)")

        if (self.view != nil) && (viewSplit.bounds.size.width == 0) {
            if (selectedMediaItem != nil) {
                //                NSLog("\(self.view.bounds.height)")
                let ratio = self.tableViewWidth.constant / self.view.bounds.width
                
                //            NSLog("captureViewSplit ratio: \(ratio)")
                
                selectedMediaItem?.slideSplit = "\(ratio)"
            }
        }
    }
    
    fileprivate func captureContentOffset(_ document:Document)
    {
        selectedMediaItem?.mediaItemSettings?[document.purpose! + Constants.CONTENT_OFFSET_X_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.x / document.wkWebView!.scrollView.contentSize.width)"
        selectedMediaItem?.mediaItemSettings?[document.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] = "\(document.wkWebView!.scrollView.contentOffset.y / document.wkWebView!.scrollView.contentSize.height)"
    }
    
    fileprivate func captureContentOffset(_ webView:WKWebView?)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (webView != nil) && (!webView!.isLoading) && (webView!.url != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
                    if webView == document.wkWebView {
                        captureContentOffset(document)
                    }
                }
            }
        }
    }
    
    fileprivate func captureZoomScale(_ document:Document)
    {
        selectedMediaItem?.mediaItemSettings?[document.purpose! + Constants.ZOOM_SCALE] = "\(document.wkWebView!.scrollView.zoomScale)"
    }
    
    fileprivate func captureZoomScale(_ webView:WKWebView?)
    {
        //        NSLog("captureZoomScale: \(mediaItemSelected?.title)")
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) && (webView != nil) && (!webView!.isLoading) && (webView!.url != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
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
                
                if document.visible(selectedMediaItem) && (document.wkWebView != nil) && document.wkWebView!.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }

        removeSliderObserver()
        removePlayerObserver()

        NotificationCenter.default.removeObserver(self)
        
//        sliderObserver?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSLog("didReceiveMemoryWarning: \(selectedMediaItem?.title)")
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
                case Constants.SEGUE.SHOW_FULL_SCREEN:
                    splitViewController?.preferredDisplayMode = .primaryHidden
                    setupWKContentOffsets()
                    wvc.selectedMediaItem = sender as? MediaItem
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
        return selectedMediaItem != nil ? (multiPartMediaItems != nil ? multiPartMediaItems!.count : 0) : 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as! MediaTableViewCell
    
        cell.mediaItem = multiPartMediaItems?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    

    fileprivate func setTimes(timeNow:Double, length:Double)
    {
//        print("timeNow:",timeNow,"length:",length)
        
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Double(elapsedHours) * 60*60)) / 60)
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
        let remainingMins = Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60)
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
        assert(globals.mediaPlayer.player != nil,"globals.mediaPlayer.player should not be nil if we're updating the slider to the audio")
   
        if (globals.mediaPlayer.duration != nil) {
            let length = globals.mediaPlayer.duration!.seconds
//            print(length)
            
            //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
            
            let playingCurrentTime = Double(globals.mediaPlayer.mediaItem!.currentTime!)!
            
            let playerCurrentTime = globals.mediaPlayer.currentTime!.seconds
            
            var progress:Double = -1.0

//            NSLog("currentTime",selectedMediaItem?.currentTime)
//            NSLog("timeNow",timeNow)
//            NSLog("length",length)
//            NSLog("progress",progress)
            
            if (length > 0) && (globals.mediaPlayer.state != nil) {
                switch globals.mediaPlayer.state! {
                case .playing:
                    if (playingCurrentTime >= 0) && (playerCurrentTime <= globals.mediaPlayer.duration!.seconds) {
                        progress = playerCurrentTime / length
                        
                        if controlView.sliding && (Int(progress*100) == Int(playingCurrentTime/length*100)) {
                            print("DONE SLIDING")
                            controlView.sliding = false
                        }

                        if !controlView.sliding && globals.mediaPlayer.loaded {
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
                        }

                        elapsed.isHidden = false
                        remaining.isHidden = false
                        slider.isHidden = false
                        slider.isEnabled = true
                    }
                    break
                    
                case .paused:
//                    if selectedMediaItem?.currentTime != playerCurrentTime.description {
                        progress = playingCurrentTime / length

//                        NSLog("paused")
//                        NSLog("timeNow",timeNow)
//                        NSLog("progress",progress)
//                        NSLog("length",length)
                        
                        slider.value = Float(progress)
                        setTimes(timeNow: playingCurrentTime,length: length)
                        
                        elapsed.isHidden = false
                        remaining.isHidden = false
                        slider.isHidden = false
                        slider.isEnabled = true
//                    }
                    break
                    
                case .stopped:
//                    if selectedMediaItem?.currentTime != playerCurrentTime.description {
                        progress = playingCurrentTime / length
                        
//                        NSLog("stopped")
//                        NSLog("timeNow",timeNow)
//                        NSLog("progress",progress)
//                        NSLog("length",length)
                        
                        slider.value = Float(progress)
                        setTimes(timeNow: playingCurrentTime,length: length)
                        
                        elapsed.isHidden = false
                        remaining.isHidden = false
                        slider.isHidden = false
                        slider.isEnabled = true
//                    }
                    break
                    
                default:
                    break
                }
            }
        }
    }
    
    fileprivate func setTimesToSlider() {
        assert(globals.mediaPlayer.player != nil,"globals.mediaPlayer.player should not be nil if we're updating the times to the slider, i.e. the slider is showing")
        
        if (globals.mediaPlayer.player != nil) {
            let length = globals.mediaPlayer.duration!.seconds
            
            let timeNow = Double(slider.value) * length
            
            setTimes(timeNow: timeNow,length: length)
        }
    }
    
    fileprivate func setupSliderAndTimes() {
        if (selectedMediaItem != nil) {
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
                    if let length = player?.currentItem?.duration.seconds {
                        let timeNow = Double(selectedMediaItem!.currentTime!)!
                        let progress = timeNow / length
                        
                        //                        print("timeNow",timeNow)
                        //                        print("progress",progress)
                        //                        print("length",length)
                        
                        slider.value = Float(progress)
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
        } else {
            elapsed.isHidden = true
            remaining.isHidden = true
            slider.isHidden = true
        }
    }

    func sliderTimer()
    {
        if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            slider.isEnabled = globals.mediaPlayer.loaded
            setupPlayPauseButton()
            setupSpinner()
//            if (!globals.mediaPlayer.loaded) {
//                if !spinner.isAnimating {
//                    spinner.isHidden = false
//                    spinner.startAnimating()
//                }
//            }
            
            switch globals.mediaPlayer.state! {
            case .none:
//                NSLog("none")
                break
                
            case .playing:
//                NSLog("playing")
                setSliderAndTimesToAudio()
                
                if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
                    setupSpinner()

                    if globals.mediaPlayer.loaded && (globals.mediaPlayer.rate == 0) {
                        globals.mediaPlayer.pause() // IfPlaying
                        setupPlayPauseButton()
                        
                        if globals.mediaPlayer.mediaItem?.playing == Playing.video {
                            if let currentTime = globals.mediaPlayer.mediaItem?.currentTime {
                                if let time = Double(currentTime) {
                                    let newCurrentTime = (time - Constants.BACK_UP_TIME) < 0 ? 0 : time - Constants.BACK_UP_TIME
                                    globals.mediaPlayer.mediaItem?.currentTime = (Double(newCurrentTime) - 1).description
                                    globals.mediaPlayer.seek(to: newCurrentTime)
                                }
                            }
                        }
                    }
                    
//                    if !globals.mediaPlayer.loaded {
//                        if !spinner.isAnimating {
//                            spinner.isHidden = false
//                            spinner.startAnimating()
//                        }
//                    } else {
//                        if (globals.mediaPlayer.rate == 0) {
//                            globals.mediaPlayer.pause() // IfPlaying
//                            setupPlayPauseButton()
//                            
//                            if globals.mediaPlayer.mediaItem?.playing == Playing.video {
//                                if let currentTime = globals.mediaPlayer.mediaItem?.currentTime {
//                                    if let time = Double(currentTime) {
//                                        let newCurrentTime = (time - Constants.BACK_UP_TIME) < 0 ? 0 : time - Constants.BACK_UP_TIME
//                                        globals.mediaPlayer.mediaItem?.currentTime = (Double(newCurrentTime) - 1).description
//                                        globals.mediaPlayer.seek(to: newCurrentTime)
//                                    }
//                                }
//                            }
//                        } else {
//                            if (globals.mediaPlayer.currentTime!.seconds > Double(globals.mediaPlayer.startTime!)!) {
//                                if spinner.isAnimating {
//                                    spinner.isHidden = true
//                                    spinner.stopAnimating()
//                                }
//                            } else {
//                                if !spinner.isAnimating {
//                                    spinner.isHidden = false
//                                    spinner.startAnimating()
//                                }
//                            }
//                        }
//                    }
                }
                break
                
            case .paused:
//                NSLog("paused")
                
                if globals.mediaPlayer.loaded {
                    setSliderAndTimesToAudio()
                }
                
                setupSpinner()
//                if globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed{
//                    if spinner.isAnimating {
//                        spinner.stopAnimating()
//                        spinner.isHidden = true
//                    }
//                }
                break
                
            case .stopped:
//                NSLog("stopped")
                break
                
            case .seekingForward:
//                NSLog("seekingForward")
                setupSpinner()
//                if !spinner.isAnimating {
//                    spinner.isHidden = false
//                    spinner.startAnimating()
//                }
                break
                
            case .seekingBackward:
//                NSLog("seekingBackward")
                setupSpinner()
//                if !spinner.isAnimating {
//                    spinner.isHidden = false
//                    spinner.startAnimating()
//                }
                break
            }
            
//            if (globals.mediaPlayer.player != nil) {
//                switch globals.mediaPlayer.player!.playbackState {
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
        }
    }
    
    func removeSliderObserver()
    {
//        sliderObserver?.invalidate()
        
        if globals.mediaPlayer.sliderTimerReturn != nil {
            globals.mediaPlayer.player?.removeTimeObserver(globals.mediaPlayer.sliderTimerReturn!)
            globals.mediaPlayer.sliderTimerReturn = nil
        }
    }
    
    func addSliderObserver()
    {
        removeSliderObserver()
        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.sliderObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.SLIDER, target: self, selector: #selector(MediaViewController.sliderTimer), userInfo: nil, repeats: true)
//        })

        globals.mediaPlayer.sliderTimerReturn = globals.mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
            self?.sliderTimer()
        })
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
    
    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        assert(globals.mediaPlayer.mediaItem == mediaItem)
        
        var seekToTime:CMTime?

        if mediaItem!.hasCurrentTime() {
            if mediaItem!.atEnd {
                NSLog("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                mediaItem?.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem?.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(Double(mediaItem!.currentTime!)!,Constants.CMTime_Resolution)
            }
        } else {
            NSLog("playPause selectedMediaItem has NO currentTime!")
            mediaItem!.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }

        if seekToTime != nil {
            let loadedTimeRanges = (globals.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
            })

            let seekableTimeRanges = (globals.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
            })

            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                globals.mediaPlayer.seek(to: seekToTime?.seconds)

                globals.mediaPlayer.play()
                
                setupPlayPauseButton()
            } else {
                playNewMediaItem(mediaItem)
            }
        }
    }

    fileprivate func reloadCurrentMediaItem(_ mediaItem:MediaItem?) {
        //This guarantees a fresh start.
        globals.mediaPlayer.playOnLoad = true
        globals.reloadPlayer(mediaItem)
        addSliderObserver()
        setupPlayPauseButton()
    }
    
    fileprivate func playNewMediaItem(_ mediaItem:MediaItem?) {
        globals.mediaPlayer.pause() // IfPlaying
        
        globals.mediaPlayer.view?.removeFromSuperview()
        
        if (mediaItem != nil) && (mediaItem!.hasVideo || mediaItem!.hasAudio) {
            setupSpinner()
//            if (!spinner.isAnimating) {
//                spinner.isHidden = false
//                spinner.startAnimating()
//            }
            
            globals.mediaPlayer.mediaItem = mediaItem
            
            removeSliderObserver()
            
            //This guarantees a fresh start.
            globals.setupPlayer(mediaItem, playOnLoad: true)
            
            if (mediaItem!.hasVideo && (mediaItem!.playing == Playing.video)) {
                setupPlayerView(globals.mediaPlayer.view)
                
                if (view.window != nil) {
                    if globals.mediaPlayer.loaded {
                        globals.mediaPlayer.view?.isHidden = false
                        mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                    }
                }
                
                mediaItem!.showing = Showing.video
            }
            
            addSliderObserver()
            
            if (view.window != nil) {
                setupSTVControl()
                setupSliderAndTimes()
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
    
    func setupSpinner()
    {
        if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if !globals.mediaPlayer.loaded && !globals.mediaPlayer.loadFailed {
                if !spinner.isAnimating {
                    spinner.isHidden = false
                    spinner.startAnimating()
                }
            } else {
                if globals.mediaPlayer.isPaused {
                    if spinner.isAnimating {
                        spinner.isHidden = true
                        spinner.stopAnimating()
                    }
                }
                
                if globals.mediaPlayer.isPlaying {
                    switch globals.mediaPlayer.mediaItem!.playing! {
                    case Playing.audio:
                        if (globals.mediaPlayer.currentTime!.seconds > Double(globals.mediaPlayer.mediaItem!.currentTime!)!) {
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
                        break
                        
                    case Playing.video:
                        if spinner.isAnimating {
                            spinner.isHidden = true
                            spinner.stopAnimating()
                        }
                        break
                        
                    default:
                        break
                    }
                }
            }
        } else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if (selectedMediaItem != nil) &&  (documents[selectedMediaItem!.id] != nil) {
            for document in documents[selectedMediaItem!.id]!.values {
                if document.visible(selectedMediaItem) && (document.wkWebView != nil) && document.wkWebView!.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }
        
        if (selectedMediaItem != multiPartMediaItems![indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(multiPartMediaItems![indexPath.row])
        }
        selectedMediaItem = multiPartMediaItems![indexPath.row]

        setupSpinner()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSliderAndTimes()
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
        if (selectedMediaItem != nil) && (documents[selectedMediaItem!.id] != nil) {
            for document in documents[selectedMediaItem!.id]!.values {
                if (webView == document.wkWebView) {
                    document.wkWebView?.scrollView.delegate = nil
                    document.wkWebView = nil
                    if document.visible(selectedMediaItem) {
                        activityIndicator.stopAnimating()
                        activityIndicator.isHidden = true
                        
                        progressIndicator.isHidden = true
                        
                        logo.isHidden = !shouldShowLogo() // && roomForLogo()
                        
                        if (!logo.isHidden) {
                            mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
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
////            globals.mediaPlayer.view?.hidden = true
//            
//            if (selectedMediaItem != nil) && (documents[selectedMediaItem!.id] != nil) {
//                for document in documents[selectedMediaItem!.id]!.values {
//                    if (webView == document.wkWebView) {
//                        document.wkWebView?.scrollView.delegate = nil
//                        document.wkWebView = nil
//                        if document.visible(selectedMediaItem) {
//                            activityIndicator.stopAnimating()
//                            activityIndicator.isHidden = true
//
//                            progressIndicator.isHidden = true
//                            
//                            logo.isHidden = !shouldShowLogo() // && roomForLogo()
//                            
//                            if (!logo.isHidden) {
//                                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
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
//        NSLog("setNotesContentOffsetAndZoomScale Loading: \(mediaItemNotesWebView!.loading)")

        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
//            NSLog("X ratio string: \(ratio)")
            contentOffsetXRatio = Float(ratioStr)!
        } else {
//            NSLog("No notes X ratio")
        }
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
//            NSLog("Y ratio string: \(ratio)")
            contentOffsetYRatio = Float(ratioStr)!
        } else {
//            NSLog("No notes Y ratio")
        }
        
        if let zoomScaleStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.ZOOM_SCALE] {
            zoomScale = CGFloat(Float(zoomScaleStr)!)
        } else {
//            NSLog("No notes zoomScale")
        }
        
//        NSLog("\(notesContentOffsetXRatio)")
//        NSLog("\(mediaItemNotesWebView!.scrollView.contentSize.width)")
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
            if (selectedMediaItem != nil) {
                if (documents[selectedMediaItem!.id] != nil) {
                    for document in documents[selectedMediaItem!.id]!.values {
                        if (webView == document.wkWebView) {
    //                        NSLog("mediaItemNotesWebView")
                            if document.visible(selectedMediaItem) {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.isHidden = true
                                    
                                    self.progressIndicator.isHidden = true
                                    
                                    self.setupSTVControl()
                                    
//                                    NSLog("webView:hidden=panning")
                                    webView.isHidden = false // self.panning
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
                            
                            document.loaded = true
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
