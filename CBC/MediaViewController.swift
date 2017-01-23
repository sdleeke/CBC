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
        didSet {
            if (wkWebView == nil) {
                oldValue?.scrollView.delegate = nil
            }
        }
    }
    
//    var sliderObserver:Timer?
    
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
    
    var scripture:Scripture? {
        get {
            return selectedMediaItem?.scripture
        }
    }
    
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
        didSet {
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil

            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: oldValue?.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: oldValue?.download)
            }
            
            if (selectedMediaItem != nil) {
                if (documents[selectedMediaItem!.id] == nil) {
                    documents[selectedMediaItem!.id] = [String:Document]()
                }
                
                if (notesDocument != nil) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateNotesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: self.notesDocument?.download)
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.cancelNotesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: self.notesDocument?.download)
                    }
                    documents[selectedMediaItem!.id]![notesDocument!.purpose!] = notesDocument
                }
            }
        }
    }
    
    func updateDocument(document:Document?)
    {
        //        print(document)
        //        print(download)
        
        guard document != nil else {
            return
        }
        
        guard document!.download != nil else {
            return
        }
        
        switch document!.download!.state {
        case .none:
            //                    print(".none")
            break
            
        case .downloading:
            //                    print(".downloading")
            if document!.showing(selectedMediaItem) {
                progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
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
        
        guard document != nil else {
            return
        }
        
        guard document!.download != nil else {
            return
        }
        
        switch document!.download!.state {
        case .none:
            //                    print(".none")
            break
            
        case .downloading:
            //                    print(".downloading")
            document?.download?.state = .none
            if document!.showing(selectedMediaItem) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    self.progressIndicator.isHidden = true
                    
                    document?.wkWebView?.isHidden = true
                    
                    globals.mediaPlayer.view?.isHidden = true
                    
                    self.logo.isHidden = false
                    self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    
                    // Can't prevent this from getting called twice in succession.
                    networkUnavailable(message)
                })
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
        didSet {
            oldValue?.wkWebView?.removeFromSuperview()
            oldValue?.wkWebView?.scrollView.delegate = nil
            
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: oldValue?.download)
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: oldValue?.download)
            }
            
            if (selectedMediaItem != nil) {
                if (documents[selectedMediaItem!.id] == nil) {
                    documents[selectedMediaItem!.id] = [String:Document]()
                }
                
                if (slidesDocument != nil) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateSlidesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_DOCUMENT), object: self.slidesDocument?.download)
                        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.cancelSlidesDocument), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CANCEL_DOCUMENT), object: self.slidesDocument?.download)
                    }
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
                playerURL(url: selectedMediaItem?.playingURL!)

//                switch selectedMediaItem!.playing! {
//                case Playing.video:
//                    if selectedMediaItem!.hasVideo {
//                        playerURL(url: selectedMediaItem?.videoURL)
//                    }
//                    break
//
//                default:
//                    if selectedMediaItem!.hasAudio {
//                        playerURL(url: selectedMediaItem?.audioURL!)
//                    }
//                    break
//                }
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

                mediaItems = selectedMediaItem?.multiPartMediaItems // mediaItemsInMediaItemSeries(selectedMediaItem)
                
//                print(selectedMediaItem)
//                let defaults = UserDefaults.standard
//                defaults.set(selectedMediaItem!.id,forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL)
//                defaults.synchronize()

                globals.selectedMediaItem.detail = selectedMediaItem
                
                DispatchQueue.main.async {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.selectedMediaItem) //
                }
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                mediaItems = nil
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
    
    var mediaItems:[MediaItem]?

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

                    setupSpinner()
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupSliderAndTimes()
                }

                selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                
                playerURL(url: selectedMediaItem?.playingURL)
                setupSliderAndTimes()

                // If video was playing we need to show slides or transcript and adjust the STV control to hide the video segment and show the other(s).
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
        
//        var showing:String?

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

        mediaItemNotesAndSlides.bringSubview(toFront: toView!)
//        selectedMediaItem?.showing = showing

        if (fromView != toView) {
            fromView?.isHidden = true
        }
    
        if let loaded = document?.loaded, let download = document?.download {
            if !loaded {
                if #available(iOS 9.0, *) {
                    if globals.cacheDownloads {
                        if (download.state != .downloading) {
                            setupDocumentsAndVideo()
                        }
                    } else {
                        if let isLoading = document?.wkWebView?.isLoading {
                            if !isLoading {
                                setupDocumentsAndVideo()
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
                        }
                    } else {
                        // No WKWebView
                        setupDocumentsAndVideo()
                    }
                }
            }
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
//                print("none")
                break
                
            case .playing:
//                print("playing")
                globals.mediaPlayer.pause() // IfPlaying

                setupPlayPauseButton()
                setupSpinner()
                break
                
            case .paused:
//                print("paused")
                if globals.mediaPlayer.loaded && (globals.mediaPlayer.url == selectedMediaItem?.playingURL) {
                    playCurrentMediaItem(selectedMediaItem)
                } else {
                    playNewMediaItem(selectedMediaItem)
                }
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                globals.mediaPlayer.pause() // IfPlaying
//                setupPlayPauseButton()
                break
                
            case .seekingBackward:
//                print("seekingBackward")
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

//        print("height: \(height) logo.bounds.height: \(logo.bounds.height) slider.bounds.height: \(slider.bounds.height) navigationBar.bounds.height: \(navigationController!.navigationBar.bounds.height)")
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

    func showSendMessageErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send a Message",
                                      message: "Your device could not send a text message.  Please check your configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    // MARK: MFMessageComposeViewControllerDelegate Method
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
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
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(messageComposeViewController, animated: true, completion: nil)
        })
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func openMediaItemScripture(_ mediaItem:MediaItem?)
    {
        var urlString = Constants.SCRIPTURE_URL.PREFIX + mediaItem!.scriptureReference! + Constants.SCRIPTURE_URL.POSTFIX

        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

//        print("\(mediaItem!.scripture!)")
//        print("\(urlString)")
//        print("\(NSURL(string:urlString))")
        
        if let url = URL(string:urlString) {
            if (UIApplication.shared.canOpenURL(url)) { // Reachability.isConnectedToNetwork() &&
                UIApplication.shared.openURL(url)
            } else {
                networkUnavailable("Unable to open scripture at: \(url)")
            }
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            default:
                break
            }
            break
            
        case .selectingAction:
            switch strings[index] {
            case Constants.Print_Slides:
                fallthrough
            case Constants.Print_Transcript:
                printDocument(viewController: self, documentURL: selectedMediaItem?.downloadURL)
                break
                
            case Constants.Add_to_Favorites:
                selectedMediaItem?.addTag(Constants.Favorites)
                break
                
            case Constants.Add_All_to_Favorites:
                for mediaItem in mediaItems! {
                    mediaItem.addTag(Constants.Favorites)
                }
                break
                
            case Constants.Remove_From_Favorites:
                selectedMediaItem?.removeTag(Constants.Favorites)
                break
                
            case Constants.Remove_All_From_Favorites:
                for mediaItem in mediaItems! {
                    mediaItem.removeTag(Constants.Favorites)
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
                
            case Constants.Scripture_Viewer:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: "Scripture View") as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? ScriptureViewController  {
                    
                    popover.scripture = self.scripture
                    
                    popover.vc = self
                    
                    navigationController.modalPresentationStyle = .popover
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
                    
                    //                    popover.navigationItem.title = title
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(navigationController, animated: true, completion: nil)
                    })
                }
                break
                
            case Constants.Scripture_in_Browser:
                openMediaItemScripture(selectedMediaItem)
                break
                
            case Constants.Download_Audio:
                selectedMediaItem?.audioDownload?.download()
                break
                
            case Constants.Download_All_Audio:
                for mediaItem in mediaItems! {
                    mediaItem.audioDownload?.download()
                }
                break
                
            case Constants.Cancel_Audio_Download:
                selectedMediaItem?.audioDownload?.cancelOrDelete()
                break
                
            case Constants.Cancel_All_Audio_Downloads:
                for mediaItem in mediaItems! {
                    mediaItem.audioDownload?.cancel()
                }
                break
                
            case Constants.Delete_Audio_Download:
                selectedMediaItem?.audioDownload?.delete()
                break
                
            case Constants.Delete_All_Audio_Downloads:
                for mediaItem in mediaItems! {
                    mediaItem.audioDownload?.delete()
                }
                break
                
            case Constants.Print:
                process(viewController: self, work: {
                    return setupMediaItemsHTML(self.mediaItems,includeURLs:false,includeColumns:true)
                }, completion: { (data:Any?) in
                    printHTML(viewController: self, htmlString: data as? String)
                })
                break
                
            case Constants.Share:
                shareHTML(viewController: self, htmlString: mediaItem?.webLink)
                break
                
            case Constants.Share_All:
                shareMediaItems(viewController: self, mediaItems: mediaItems, stringFunction: setupMediaItemsHTML)
                break
                
            case Constants.Refresh_Document:
                fallthrough
            case Constants.Refresh_Transcript:
                fallthrough
            case Constants.Refresh_Slides:
                // This only refreshes the visible document.
                download?.cancelOrDelete()
                document?.loaded = false
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

        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
            //                popover.navigationItem.title = Constants.Show
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            var actionMenu = [String]()

            if selectedMediaItem!.hasFavoritesTag {
                actionMenu.append(Constants.Remove_From_Favorites)
            } else {
                actionMenu.append(Constants.Add_to_Favorites)
            }
            
            if mediaItems?.count > 1 {
                var favoriteMediaItems = 0
                
                for mediaItem in mediaItems! {
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
                    
                case mediaItems!.count - 1:
                    if selectedMediaItem!.hasFavoritesTag {
                        actionMenu.append(Constants.Add_All_to_Favorites)
                    }
                    
                    actionMenu.append(Constants.Remove_All_From_Favorites)
                    break
                    
                case mediaItems!.count:
                    actionMenu.append(Constants.Remove_All_From_Favorites)
                    break
                    
                default:
                    actionMenu.append(Constants.Add_All_to_Favorites)
                    actionMenu.append(Constants.Remove_All_From_Favorites)
                    break
                }
            }
            
            if UIPrintInteractionController.isPrintingAvailable, let purpose = document?.purpose  {
                switch purpose {
                case Purpose.notes:
                    actionMenu.append(Constants.Print_Transcript)
                    break
                    
                case Purpose.slides:
                    actionMenu.append(Constants.Print_Slides)
                    break
                    
                default:
                    break
                }
            }

            if document != nil, globals.cacheDownloads, let purpose = document?.purpose {
//                actionMenu.append(Constants.Refresh_Document)
                switch purpose {
                case Purpose.notes:
                    actionMenu.append(Constants.Refresh_Transcript)
                    break
                    
                case Purpose.slides:
                    actionMenu.append(Constants.Refresh_Slides)
                    break
                    
                default:
                    break
                }
            }

            // Not needed any more because the CBC Website now has a page for this media w/ any documents
//            if document != nil {
//                actionMenu.append(Constants.Open_in_Browser)
//            }
            
            actionMenu.append(Constants.Open_on_CBC_Website)
            
//            if (selectedMediaItem!.hasScripture && (selectedMediaItem?.scripture != Constants.Selected_Scriptures)) {
//                actionMenu.append(Constants.Scripture_in_Browser)
//            }

            actionMenu.append(Constants.Scripture_Viewer)

            if let mediaItems = mediaItems {
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
            }
            
            if selectedMediaItem != nil {
                actionMenu.append(Constants.Print)
                actionMenu.append(Constants.Share)
            }
            
            if mediaItems?.count > 1 {
                actionMenu.append(Constants.Share_All)
            }
            
            popover.strings = actionMenu
            
            popover.showIndex = false //(globals.grouping == .series)
            popover.showSectionHeaders = false
            
            popover.vc = self
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.present(navigationController, animated: true, completion: nil)
            })
        }
    }
    
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
        guard (view != nil) else {
            return
        }

        view?.isHidden = true
        view?.removeFromSuperview()
        
        if mediaItemNotesAndSlides != nil {
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
    
    func readyToPlay()
    {
        if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) && globals.mediaPlayer.isPaused && globals.mediaPlayer.mediaItem!.hasCurrentTime() {
            globals.mediaPlayer.seek(to: Double(globals.mediaPlayer.mediaItem!.currentTime!))
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.playing == Playing.video) {
                if selectedMediaItem?.showing == Showing.video {
                    globals.mediaPlayer.view?.isHidden = false
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
        navigationItem.leftItemsSupplementBackButton = true
        
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
            
            let hasNotes = selectedMediaItem!.hasNotes // && notesDocument!.loaded
            let hasSlides = selectedMediaItem!.hasSlides // && slidesDocument!.loaded
            
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
    
//    func downloading(_ timer:Timer?)
//    {
//        let document = timer?.userInfo as? Document
//        
//        print(document?.download?.purpose)
//        print(document?.download?.state)
//        print(document?.download?.downloadURL)
//        
//        if (selectedMediaItem != nil) {
////            print(selectedMediaItem)
//            if (document?.download != nil) {
//                print("totalBytesWritten: \(document!.download!.totalBytesWritten)")
//                print("totalBytesExpectedToWrite: \(document!.download!.totalBytesExpectedToWrite)")
//                
//                switch document!.download!.state {
//                case .none:
////                    print(".none")
//                    document?.download?.task?.cancel()
//                    
//                    document?.loadTimer?.invalidate()
//                    document?.loadTimer = nil
//                    
//                    if document!.showing(selectedMediaItem) {
//                        self.activityIndicator.stopAnimating()
//                        self.activityIndicator.isHidden = true
//                        
//                        self.progressIndicator.isHidden = true
//                        
//                        document?.wkWebView?.isHidden = true
//                        
//                        globals.mediaPlayer.view?.isHidden = true
//                        
//                        self.logo.isHidden = false
//                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
//                        
//                        networkUnavailable("Download failed.")
//                    }
//                    break
//                    
//                case .downloading:
////                    print(".downloading")
//                    if document!.showing(selectedMediaItem) {
//                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
//                    }
////                    if document!.download!.totalBytesExpectedToWrite == 0 {
////                        document?.download?.cancelDownload()
////                        document?.loadTimer?.invalidate()
////                        document?.loadTimer = nil
////                        progressIndicator.isHidden = true
////                        activityIndicator.isHidden = true
////                        selectedMediaItem?.showing = Showing.none
////                        setupDocumentsAndVideo()
////                    }
//                    break
//                    
//                case .downloaded:
////                    print(".downloaded")
//                    if #available(iOS 9.0, *) {
//
//                        document?.loadTimer?.invalidate()
//                        document?.loadTimer = nil
//
////                        DispatchQueue.global(qos: .background).async {
////                            //                            print(document!.download!.fileSystemURL!)
////                            _ = document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
////                            
////                            DispatchQueue.main.async(execute: { () -> Void in
////                                if document!.visible(self.selectedMediaItem) {
////                                    self.progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
////                                }
////                                
////                                document?.loadTimer?.invalidate()
////                                document?.loadTimer = nil
////                            })
////                        }
//
////                        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
//////                            print(document!.download!.fileSystemURL!)
////                            document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
////                            
////                            DispatchQueue.main.async(execute: { () -> Void in
////                                if document!.visible(self.selectedMediaItem) {
////                                    self.progressIndicator.progress = document!.download!.totalBytesExpectedToWrite > 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
////                                }
////                                
////                                document?.loadTimer?.invalidate()
////                                document?.loadTimer = nil
////                            })
////                        })
//                    } else {
//                        // Fallback on earlier versions
//                    }
//                    break
//                }
//            }
//        }
//    }
    
    func loading(_ timer:Timer?)
    {
        // Expected to be on the main thread
        if let document = timer?.userInfo as? Document {
            if document.showing(selectedMediaItem) {
                if (document.wkWebView != nil) {
                    progressIndicator.progress = Float(document.wkWebView!.estimatedProgress)

                    if progressIndicator.progress == 1 {
                        progressIndicator.isHidden = true
                    }
                }
            }
            
            if (document.wkWebView != nil) && !document.wkWebView!.isLoading {
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                
                document.loadTimer?.invalidate()
                document.loadTimer = nil
            }
        }
    }
    
    fileprivate func setupDocument(_ document:Document?)
    {
//        print("setupDocument")
        
        if document?.wkWebView == nil {
//            document?.wkWebView?.removeFromSuperview()
            document?.wkWebView = WKWebView(frame: mediaItemNotesAndSlides.bounds)
        }

        if (document != nil) && !document!.loaded {
            loadDocument(document)
        }
        
        if !mediaItemNotesAndSlides.subviews.contains(document!.wkWebView!) {
            setupWKWebView(document?.wkWebView)
        }
    }
    
    fileprivate func loadDocument(_ document:Document?)
    {
        if let loading = document?.wkWebView?.isLoading, loading {
            return
        }
        
        document?.wkWebView?.isHidden = true
        document?.wkWebView?.stopLoading()
        
        if #available(iOS 9.0, *) {
            if globals.cacheDownloads {
//                print(document?.download?.state)
                if (document?.download != nil) && (document?.download?.state != .downloaded){
                    if document!.showing(selectedMediaItem) {
                        mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
                        mediaItemNotesAndSlides.bringSubview(toFront: progressIndicator)
                        
                        activityIndicator.isHidden = false
                        activityIndicator.startAnimating()
                        
                        mediaItemNotesAndSlides.bringSubview(toFront: activityIndicator)
                        
                        progressIndicator.progress = document!.download!.totalBytesExpectedToWrite != 0 ? Float(document!.download!.totalBytesWritten) / Float(document!.download!.totalBytesExpectedToWrite) : 0.0
                        progressIndicator.isHidden = false

                        mediaItemNotesAndSlides.bringSubview(toFront: progressIndicator)
                    }
                    
//                    if document?.loadTimer == nil {
//                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.DOWNLOADING, target: self, selector: #selector(MediaViewController.downloading(_:)), userInfo: document, repeats: true)
//                    }
                    
                    document?.download?.download()
                } else {
                    DispatchQueue.global(qos: .background).async(execute: { () -> Void in
//                        print(document!.download!.fileSystemURL!)
                        _ = document?.wkWebView?.loadFileURL(document!.download!.fileSystemURL! as URL, allowingReadAccessTo: document!.download!.fileSystemURL! as URL)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            if (document != nil) && document!.showing(self.selectedMediaItem) {
                                self.activityIndicator.startAnimating()
                                self.activityIndicator.isHidden = false
                                
                                self.progressIndicator.progress = 0.0
                                self.progressIndicator.isHidden = true
                            }
//                            document?.loadTimer?.invalidate()
//                            document?.loadTimer = nil
                        })
                    })
                }
            } else {
                DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        if document!.showing(self.selectedMediaItem) {
                            self.activityIndicator.isHidden = false
                            self.activityIndicator.startAnimating()
                            
                            self.progressIndicator.isHidden = false
                        }
                        
                        if document?.loadTimer == nil {
                            document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                        }
                    })
                    
                    if (document == nil) {
                        print("document nil")
                    }
                    if (document!.download == nil) {
                        print("document!.download nil")
                    }
                    if (document!.download!.downloadURL == nil) {
                        print("\(self.selectedMediaItem?.title)")
                        print("document!.download!.downloadURL nil")
                    }
                    
                    let request = URLRequest(url: document!.download!.downloadURL!)
//                    let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                    _ = document?.wkWebView?.load(request)
                })
            }
        } else {
            DispatchQueue.global(qos: .background).async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    if document!.showing(self.selectedMediaItem) {
                        self.activityIndicator.isHidden = false
                        self.activityIndicator.startAnimating()
                        
                        self.progressIndicator.isHidden = false
                    }
                    
                    if document?.loadTimer == nil {
                        document?.loadTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.LOADING, target: self, selector: #selector(MediaViewController.loading(_:)), userInfo: document, repeats: true)
                    }
                })
                
                let request = URLRequest(url: document!.download!.downloadURL!)
//                let request = URLRequest(url: document!.download!.downloadURL! as URL, cachePolicy: Constants.CACHE.POLICY, timeoutInterval: Constants.CACHE.TIMEOUT)
                _ = document?.wkWebView?.load(request)
            })
        }
    }
    
    fileprivate func hideOtherDocuments()
    {
        if (selectedMediaItem != nil) {
            if (documents[selectedMediaItem!.id] != nil) {
                for document in documents[selectedMediaItem!.id]!.values {
                    if !document.showing(selectedMediaItem) {
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

//        print("setupNotesAndSlides")
//        print("Selected: \(globals.mediaItemSelected?.title)")
//        print("Last Selected: \(globals.mediaItemLastSelected?.title)")
//        print("Playing: \(globals.player.playing?.title)")
        
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
            
    //        print("notes hidden \(mediaItemNotes.hidden)")
    //        print("slides hidden \(mediaItemSlides.hidden)")
            
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
//                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
                break
                
            case Showing.slides:
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = true
                
                hideOtherDocuments()
                
                if (wkWebView != nil) {
//                    wkWebView?.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: wkWebView!)
                }
                break
                
            case Showing.video:
                //This should not happen unless it is playing video.
                switch selectedMediaItem!.playing! {
                case Playing.audio:
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
        guard (mediaItem != nil) else {
            return
        }

        var indexPath = IndexPath(row: 0, section: 0)
        
        if mediaItems?.count > 0, let mediaItemIndex = mediaItems?.index(of: mediaItem!) {
            //                    print("\(mediaItemIndex)")
            indexPath = IndexPath(row: mediaItemIndex, section: 0)
        }
        
        //            print("\(tableView.bounds)")
        
        guard (indexPath.section < tableView.numberOfSections) else {
            NSLog("indexPath section ERROR in scrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            return
        }
        
        guard indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
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
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
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
                        
                        //        print("\(mediaItemNotesWebView!.scrollView.contentSize)")
                        //        print("\(mediaItemSlidesWebView!.scrollView.contentSize)")
                        
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
            
            //            print("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
            
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
                    
                    //                    print("min: \(minConstraintConstant) max: \(maxConstraintConstant)")
                    
                    if newConstraintConstant < minConstraintConstant { newConstraintConstant = minConstraintConstant }
                    if newConstraintConstant > maxConstraintConstant { newConstraintConstant = maxConstraintConstant }
                    
                    self.mediaItemNotesAndSlidesConstraint.constant = newConstraintConstant
                    
                    //                    print("\(viewSplit) \(size) \(mediaItemNotesAndSlidesConstraint.constant)")
                    
                    viewSplit.min = minConstraintConstant
                    viewSplit.max = maxConstraintConstant
                    viewSplit.height = self.mediaItemNotesAndSlidesConstraint.constant
                    
                    self.view.setNeedsLayout()
                }
            } else {
                //Capturing the viewSplit on a rotation from portrait to landscape for an iPhone
                captureViewSplit()
                
                if let ratio = ratioForSlideView(viewSplit) {
                    //            print("\(self.view.bounds.height)")
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
        
        if let viewSplit = selectedMediaItem?.viewSplit {
            ratio = CGFloat(Float(viewSplit)!)
        }
        //        print("ratio: '\(ratio)")
        return ratio
    }
    
    func ratioForSlideView(_ sender: UIView) -> CGFloat?
    {
        var ratio:CGFloat?
        
        if let slideSplit = selectedMediaItem?.slideSplit {
            ratio = CGFloat(Float(slideSplit)!)
        }
        //        print("ratio: '\(ratio)")
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
        
        //        print("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        newConstraintConstant = minConstraintConstant + tableView.rowHeight * (mediaItems!.count > 1 ? 1 : 1)
        
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
                    //            print("\(self.view.bounds.height)")
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
        
//        print("setupViewSplit ratio: \(ratio)")
        
        let (minConstraintConstant,maxConstraintConstant) = mediaItemNotesAndSlidesConstraintMinMax(self.view.bounds.height)
        
        if let ratio = ratioForSplitView(viewSplit) {
//            print("\(self.view.bounds.height)")
            newConstraintConstant = self.view.bounds.height * ratio
        } else {
            let numberOfAdditionalRows = CGFloat(mediaItems != nil ? mediaItems!.count : 0)
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
        if (selectedMediaItem != nil),
            (selectedMediaItem == globals.mediaPlayer.mediaItem),
            (globals.mediaPlayer.url != selectedMediaItem?.playingURL) {
//            ((globals.mediaPlayer.url != selectedMediaItem?.videoURL) && (globals.mediaPlayer.url != selectedMediaItem?.audioURL)) {
            globals.mediaPlayer.pause()
            globals.setupPlayer(selectedMediaItem,playOnLoad:false)
        }

        setupPlayerView(globals.mediaPlayer.view)

        //        print("viewWillAppear 1 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        setupViewSplit()
        setupSlideSplit()
        
        //        print("viewWillAppear 2 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
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

        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            
            if (self.splitViewController != nil) {
                NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            }
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
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        } else {
            if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                if let _ = nvc.visibleViewController as? WebViewController {
                    splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                } else {
                    splitViewController?.preferredDisplayMode = .automatic //iPad only
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    fileprivate func captureViewSplit()
    {
        //        print("captureViewSplit: \(mediaItemSelected?.title)")
        
        if (self.view != nil) && (viewSplit.bounds.size.width > 0) {
            if (selectedMediaItem != nil) {
                //                print("\(self.view.bounds.height)")
                let ratio = self.mediaItemNotesAndSlidesConstraint.constant / self.view.bounds.height
                
                //            print("captureViewSplit ratio: \(ratio)")
                
                selectedMediaItem?.viewSplit = "\(ratio)"
            }
        }
    }
    
    fileprivate func captureSlideSplit()
    {
        //        print("captureViewSplit: \(mediaItemSelected?.title)")

        if (self.view != nil) && (viewSplit.bounds.size.width == 0) {
            if (selectedMediaItem != nil) {
                //                print("\(self.view.bounds.height)")
                let ratio = self.tableViewWidth.constant / self.view.bounds.width
                
                //            print("captureViewSplit ratio: \(ratio)")
                
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
        //        print("captureZoomScale: \(mediaItemSelected?.title)")
        
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
                
                if document.showing(selectedMediaItem) && (document.wkWebView != nil) && document.wkWebView!.scrollView.isDecelerating {
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
        print("didReceiveMemoryWarning: \(selectedMediaItem?.title)")
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

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return selectedMediaItem != nil ? (mediaItems != nil ? mediaItems!.count : 0) : 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.isHiddenUI(true)
        
        cell.mediaItem = mediaItems?[indexPath.row]
        
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
        if (globals.mediaPlayer.duration != nil) {
            let length = globals.mediaPlayer.duration!.seconds
//            print(length)
            
            //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
            
            let playingCurrentTime = Double(globals.mediaPlayer.mediaItem!.currentTime!)!
            
            let playerCurrentTime = globals.mediaPlayer.currentTime!.seconds
            
            var progress:Double = -1.0

//            print("currentTime",selectedMediaItem?.currentTime)
//            print("timeNow",timeNow)
//            print("length",length)
//            print("progress",progress)
            
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

//                        print("paused")
//                        print("timeNow",timeNow)
//                        print("progress",progress)
//                        print("length",length)
                        
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
                        
//                        print("stopped")
//                        print("timeNow",timeNow)
//                        print("progress",progress)
//                        print("length",length)
                        
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
            
            switch globals.mediaPlayer.state! {
            case .none:
//                print("none")
                break
                
            case .playing:
//                print("playing")
                setSliderAndTimesToAudio()
                
                if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
                    setupSpinner()

                    if globals.mediaPlayer.loaded && (globals.mediaPlayer.rate == 0) {
                        globals.mediaPlayer.pause() // IfPlaying
                        setupPlayPauseButton()
                        
                        if globals.mediaPlayer.mediaItem?.playing == Playing.video,
                            let currentTime = globals.mediaPlayer.mediaItem?.currentTime,
                            let time = Double(currentTime) {
                            let newCurrentTime = (time - Constants.BACK_UP_TIME) < 0 ? 0 : time - Constants.BACK_UP_TIME
                            globals.mediaPlayer.mediaItem?.currentTime = (Double(newCurrentTime) - 1).description
                            globals.mediaPlayer.seek(to: newCurrentTime)
                        }
                    }
                }
                break
                
            case .paused:
//                print("paused")
                
                if globals.mediaPlayer.loaded {
                    setSliderAndTimesToAudio()
                }
                
                setupSpinner()
                break
                
            case .stopped:
//                print("stopped")
                break
                
            case .seekingForward:
//                print("seekingForward")
                setupSpinner()
                break
                
            case .seekingBackward:
//                print("seekingBackward")
                setupSpinner()
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

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        assert(globals.mediaPlayer.mediaItem == mediaItem)
        
        var seekToTime:CMTime?

        if mediaItem!.hasCurrentTime() {
            if mediaItem!.atEnd {
                print("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                mediaItem?.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem?.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(Double(mediaItem!.currentTime!)!,Constants.CMTime_Resolution)
            }
        } else {
            print("playPause selectedMediaItem has NO currentTime!")
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
                } else {
                    if spinner.isAnimating {
                        spinner.isHidden = true
                        spinner.stopAnimating()
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
                if document.showing(selectedMediaItem) && (document.wkWebView != nil) && document.loaded && document.wkWebView!.scrollView.isDecelerating {
                    captureContentOffset(document)
                }
            }
        }
        
        if (selectedMediaItem != mediaItems![indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(mediaItems![indexPath.row])
        }
        selectedMediaItem = mediaItems![indexPath.row]

        setupSpinner()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSliderAndTimes()
        setupDocumentsAndVideo()
        setupActionAndTagsButtons()
    }
    
    func webView(_ webView: WKWebView, didFail didFailNavigation: WKNavigation!, withError: Error) {
        print("wkDidFailNavigation")
//        if (splitViewController != nil) || (self == navigationController?.visibleViewController) {
//        }

        webView.isHidden = true
        if (selectedMediaItem != nil) && (documents[selectedMediaItem!.id] != nil) {
            for document in documents[selectedMediaItem!.id]!.values {
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
                        
                        networkUnavailable(withError.localizedDescription)
                        NSLog(withError.localizedDescription)
                    }
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
    
    func webView(_ wkWebView: WKWebView, didFailProvisionalNavigation: WKNavigation!,withError: Error) {
        print("didFailProvisionalNavigation")
        
        if !globals.cacheDownloads {
            DispatchQueue.main.async(execute: { () -> Void in
                for document in self.documents[self.selectedMediaItem!.id]!.values {
                    if (document.wkWebView == wkWebView) && document.showing(self.selectedMediaItem) {
                        self.document?.wkWebView?.isHidden = true
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                        self.logo.isHidden = false
                        
                        if let purpose = document.download?.purpose {
                            switch purpose {
                            case Purpose.notes:
                                networkUnavailable("Transcript not available.")
                                break
                                
                            case Purpose.slides:
                                networkUnavailable("Slides not available.")
                                break
                                
                            default:
                                break
                            }
                        }
                    }
                }
            })
        }
    }
    
    func wkSetZoomScaleThenContentOffset(_ wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")

        DispatchQueue.main.async(execute: { () -> Void in
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
    
    func setDocumentContentOffsetAndZoomScale(_ document:Document?)
    {
//        print("setNotesContentOffsetAndZoomScale Loading: \(mediaItemNotesWebView!.loading)")

        var zoomScale:CGFloat = 1.0
        
        var contentOffsetXRatio:Float = 0.0
        var contentOffsetYRatio:Float = 0.0
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.CONTENT_OFFSET_X_RATIO] {
//            print("X ratio string: \(ratio)")
            contentOffsetXRatio = Float(ratioStr)!
        } else {
//            print("No notes X ratio")
        }
        
        if let ratioStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.CONTENT_OFFSET_Y_RATIO] {
//            print("Y ratio string: \(ratio)")
            contentOffsetYRatio = Float(ratioStr)!
        } else {
//            print("No notes Y ratio")
        }
        
        if let zoomScaleStr = selectedMediaItem?.mediaItemSettings?[document!.purpose! + Constants.ZOOM_SCALE] {
            zoomScale = CGFloat(Float(zoomScaleStr)!)
        } else {
//            print("No notes zoomScale")
        }
        
//        print("\(notesContentOffsetXRatio)")
//        print("\(mediaItemNotesWebView!.scrollView.contentSize.width)")
//        print("\(notesZoomScale)")
        
        let contentOffset = CGPoint(x: CGFloat(contentOffsetXRatio) * document!.wkWebView!.scrollView.contentSize.width * zoomScale,
                                        y: CGFloat(contentOffsetYRatio) * document!.wkWebView!.scrollView.contentSize.height * zoomScale)
        
        wkSetZoomScaleThenContentOffset(document!.wkWebView!, scale: zoomScale, offset: contentOffset)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("wkWebViewDidFinishNavigation Loading:\(webView.isLoading)")
        
//        print("Frame: \(webView.frame)")
//        print("Bounds: \(webView.bounds)")
        
        guard self.view != nil else {
            return
        }

        guard selectedMediaItem != nil else {
            return
        }
        
        guard documents[selectedMediaItem!.id] != nil else {
            return
        }
        
        for document in documents[selectedMediaItem!.id]!.values {
            if (webView == document.wkWebView) {
                //                        print("mediaItemNotesWebView")
                if document.showing(selectedMediaItem) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        
                        self.progressIndicator.isHidden = true
                        
                        self.setupSTVControl()
                        
                        //                            print("webView:hidden=panning")
                        webView.isHidden = false // self.panning
                    })
                } else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        //                            print("webView:hidden=true")
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
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return false
        }
        
        guard let mediaItem = cell.mediaItem else {
            return false
        }
        
        return mediaItem.hasNotesHTML || (mediaItem.scriptureReference != Constants.Selected_Scriptures)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        
        guard let mediaItem = cell.mediaItem else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        var transcript:UITableViewRowAction!
        var scripture:UITableViewRowAction!
        
        transcript = UITableViewRowAction(style: .normal, title: Constants.FA.TRANSCRIPT) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: transcript)!]
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                    htmlString = mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
                } else {
                    htmlString = mediaItem.fullNotesHTML
                }
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                        return mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
                    } else {
                        return mediaItem.fullNotesHTML
                    }
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable("HTML transcript unavailable.")
                    }
                    
                    //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                })
            }
        }
        transcript.backgroundColor = UIColor.purple//controlBlue()
        
        scripture = UITableViewRowAction(style: .normal, title: Constants.FA.SCRIPTURE) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: scripture)!]
            
            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load(mediaItem.scripture?.reference)
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable("Scripture text unavailable.")
                        }
                        //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                    })
                }
            }
        }
        scripture.backgroundColor = UIColor.orange
        
        if mediaItem.scriptureReference != Constants.Selected_Scriptures {
            actions.append(scripture)
        }
        
        if mediaItem.hasNotesHTML {
            actions.append(transcript)
        }

        return actions
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
