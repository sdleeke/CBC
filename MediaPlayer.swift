//
//  MediaPlayer.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var mediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            startTime = mediaItem?.currentTime
        }
    }
    
    var state:PlayerState = .none {
        willSet {
            
        }
        didSet {
            guard (state != oldValue) else {
                return
            }
            
            dateEntered = Date()
        }
    }
    
    var startTime:String?
    
    var dateEntered:Date?
    var timeElapsed:TimeInterval? {
        get {
            if let dateEntered = dateEntered {
                return Date().timeIntervalSince(dateEntered)
            } else {
                return nil
            }
        }
    }
    
    init(state: PlayerState)
    {
        dateEntered = Date()
        self.state = state
    }
    
    convenience init(state: PlayerState,mediaItem:MediaItem?)
    {
        self.init(state:state)
        self.mediaItem = mediaItem
        startTime = mediaItem?.currentTime
    }
    
    deinit {
        
    }
    
    func log()
    {
        var stateName:String?
        
        switch state {
        case .none:
            stateName = "none"
            break
            
        case .paused:
            stateName = "paused"
            break
            
        case .playing:
            stateName = "playing"
            break
            
        case .seekingForward:
            stateName = "seekingForward"
            break
            
        case .seekingBackward:
            stateName = "seekingBackward"
            break
            
        case .stopped:
            stateName = "stopped"
            break
        }
        
        if let stateName = stateName {
            print(stateName)
        }
    }
}

enum PIP {
    case started
    case stopped
}

class MediaPlayer : NSObject {
    var isSeeking = false
    {
        didSet {
            if isSeeking != oldValue, !isSeeking, let state = state {
                switch state {
//                case .playing:
//                    if let startTime = currentTime {
//                        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                            repeat {
//                                Thread.sleep(forTimeInterval: 0.1)
//                            } while self?.currentTime <= startTime
//                            
//                            self?.seekingCompletion?()
//                            self?.seekingCompletion = nil
//                        }
//                    }

                default:
                    self.seekingCompletion?()
                    self.seekingCompletion = nil
                }
            }
        }
    }
    
    var seekingCompletion : (()->(Void))?
    
    var sliderTimerReturn:Any? = nil
    var playerTimerReturn:Any? = nil
    
    var observerActive = false
    var observedItem:AVPlayerItem?
    
    var playerObserverTimer:Timer?
    
    var fullScreen = false
    
    var url : URL? {
        get {
            return (currentItem?.asset as? AVURLAsset)?.url
        }
    }
    
    var controller:AVPlayerViewController?
    
    var stateTime:PlayerStateTime?
    
    var showsPlaybackControls:Bool{
        get {
            guard let controller = controller else {
                return false
            }
            
            return controller.showsPlaybackControls
        }
        set {
            controller?.showsPlaybackControls = newValue
        }
    }
    
    func checkPlayToEnd()
    {
        // didPlayToEnd observer doesn't always work.  This seemds to catch the cases where it doesn't.
        if let currentTime = currentTime?.seconds,
            let duration = duration?.seconds,
            Int(currentTime) >= Int(duration) {
            didPlayToEnd()
        }
    }
    
    var isVideoFullScreen = false

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        // Only handle observations for the playerItemContext
        //        guard context == &GlobalPlayerContext else {
        //            super.observeValue(forKeyPath: keyPath,
        //                               of: object,
        //                               change: change,
        //                               context: context)
        //            return
        //        }
        
        guard (url != URL(string: Constants.URL.LIVE_STREAM)) else {
            return
        }
        
        if keyPath == #keyPath(UIView.frame) {
            if let rect = change?[.newKey] as? CGRect {
//                print(rect.size,UIScreen.main.bounds.size)
                
                isVideoFullScreen = rect.size == UIScreen.main.bounds.size
 
//                isVideoFullScreen ? print("Player in full screen") : print("Player not in full screen")
            }
        }

        if #available(iOS 10.0, *) {
            if keyPath == #keyPath(AVPlayer.timeControlStatus) {
                if  let statusNumber = change?[.newKey] as? NSNumber,
                    let status = AVPlayerTimeControlStatus(rawValue: statusNumber.intValue) {
                    switch status {
                    case .waitingToPlayAtSpecifiedRate:
                        if let reason = player?.reasonForWaitingToPlay {
                            print("waitingToPlayAtSpecifiedRate: ",reason)
                        } else {
                            print("waitingToPlayAtSpecifiedRate: no reason")
                        }
                        break
                        
                    case .paused:
                        if let state = state {
                            switch state {
                            case .none:
                                break
                                
                            case .paused:
                                break
                                
                            case .playing:
                                pause() // coming back from true full screen to MVC fullScreen while playing triggers this pause.  Why???
                                // didPlayToEnd observer doesn't always work.  This seemds to catch the cases where it doesn't.
                                checkPlayToEnd()
                                break
                                
                            case .seekingBackward:
                                pause()
                                break
                                
                            case .seekingForward:
                                pause()
                                break
                                
                            case .stopped:
                                break
                            }
                        }
                        break
                        
                    case .playing:
                        if let state = state {
                            switch state {
                            case .none:
                                break
                                
                            case .paused:
                                play() // "fullScreen" (in MVC) then touch causes this play.  Why???
                                break
                                
                            case .playing:
                                break
                                
                            case .seekingBackward:
                                play()
                                break
                                
                            case .seekingForward:
                                play()
                                break
                                
                            case .stopped:
                                break
                            }
                        }
                        break
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber, let playerStatus = AVPlayerItemStatus(rawValue: statusNumber.intValue) {
                status = playerStatus
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                //                print(player?.currentItem?.duration.value)
                //                print(player?.currentItem?.duration.timescale)
                //                print(player?.currentItem?.duration.seconds)
                if !loaded, let mediaItem = mediaItem {
                    loaded = true
                    
                    if (mediaItem.playing == Playing.video) {
                        if mediaItem.showing == Showing.none {
                            mediaItem.showing = Showing.video
                        }
                    }
                    
                    if mediaItem.hasCurrentTime {
                        if mediaItem.atEnd {
                            if let duration = duration {
                                seek(to: duration.seconds)
                            }
                        } else {
                            if let currentTime = mediaItem.currentTime, let time = Double(currentTime) {
                                seek(to: time)
                            }
                        }
                        
                        // Why was this needed?
                        //                        if isPaused {
                        //                            seek(to: Double(mediaItem!.currentTime!))
                        //                        }
                    } else {
                        mediaItem.currentTime = Constants.ZERO
                        seek(to: 0)
                    }
                    
                    // Why only audio?
                    if (self.mediaItem?.playing == Playing.audio) {
                        if playOnLoad {
                            if mediaItem.atEnd {
                                seek(to: 0)
                                mediaItem.atEnd = false
                            }
                            
                            playOnLoad = false
                            play()
                        }
                    }
                    
                    Thread.onMainThread {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil) // why isn't the object mediaItem
                    }
                }

                setupPlayingInfoCenter()
                break
                
            case .failed:
                // Player item failed. See error.
                failedToLoad()
                break
                
            case .unknown:
                // Player item is not yet ready.
                if #available(iOS 10.0, *) {
                    print(player?.reasonForWaitingToPlay as Any)
                } else {
                    // Fallback on earlier versions
                }
                break
            }
        }
    }
    
    func setupAtEnd(_ mediaItem:MediaItem?)
    {
        setup(mediaItem,playOnLoad:false)
        
        if let seconds = duration?.seconds {
            pause()
            seek(to: seconds)
            mediaItem?.currentTime = Float(seconds).description
            mediaItem?.atEnd = true
        }
    }
    
    func setup(url:URL?,playOnLoad:Bool)
    {
        guard let url = url else {
            return
        }
        
        unload()
        
        showsPlaybackControls = false
        
        unobserve()

        controller?.contentOverlayView?.removeObserver(self, forKeyPath: #keyPath(UIView.frame))
        
        controller = AVPlayerViewController()

        controller?.contentOverlayView?.addObserver(self, forKeyPath: #keyPath(UIView.frame), options: NSKeyValueObservingOptions.new, context: nil)

        controller?.delegate = Globals.shared
        
        controller?.showsPlaybackControls = fullScreen
        
        if #available(iOS 10.0, *) {
            controller?.updatesNowPlayingInfoCenter = false
        } else {
            // Fallback on earlier versions
        }
        
        if #available(iOS 9.0, *) {
            controller?.allowsPictureInPicturePlayback = true
        } else {
            // Fallback on earlier versions
        }
        
        // Just replacing the item will not cause a timeout when the player can't load.
        player = AVPlayer(url: url)
        
        if #available(iOS 10.0, *) {
            player?.automaticallyWaitsToMinimizeStalling = (mediaItem?.playing != Playing.audio)
        } else {
            // Fallback on earlier versions
        }
        
        player?.actionAtItemEnd = .pause
        
        observe()
        
        pause() // affects playOnLoad
        self.playOnLoad = playOnLoad
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
    }
    
    func setup(_ mediaItem:MediaItem?,playOnLoad:Bool)
    {
        guard let mediaItem = mediaItem else {
            return
        }
        
        setup(url: mediaItem.playingURL,playOnLoad: playOnLoad)
    }
    
    func reload()
    {
        guard (mediaItem != nil) else {
            return
        }
        
        guard let url = url else {
            return
        }
        
        unobserve()

        unload()
        
        player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        
        pause() // To reset playOnLoad and set state to .paused
        
        observe()
    }
    
    @objc func playerObserver()
    {
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            return
        }
        
        //        logPlayerState()
        
        guard let state = state,
            let startTime = stateTime?.startTime,
            let start = Double(startTime),
            let timeElapsed = stateTime?.timeElapsed,
            let currentTime = currentTime?.seconds else {
                return
        }
        
        switch state {
        case .none:
            break
            
        case .playing:
            if (pip == .started) || fullScreen {
                // System caused - PIP or fullScreen
                if (rate == 0) {
                    pause()
                }
            } else {
                if loaded && !loadFailed {
                    if Int(currentTime) <= Int(start) {
                        // This is trying to catch failures to play after loading due to low bandwidth (or anything else).
                        // BUT it is in a timer so it may fire when start and currentTime are changing and may cause problems
                        // due to timing errors.  It certainly does in tvOS.  May just want to eliminate it.
                        if (timeElapsed > Constants.MIN_LOAD_TIME) {
                            //                            pause()
                            //                            failedToLoad()
                        } else {
                            // Kick the player in the pants to get it going (audio primarily requiring this when the network is poor)
                            print("KICK")
                            player?.play()
                        }
                    } else {
                        if #available(iOS 10.0, *) {
                        } else {
                            // Was playing normally and the system paused it.
                            // This is redundant to KVO monitoring of AVPlayer.timeControlStatus but that is only available in 10.0 and later.
                            if (rate == 0) {
                                pause()
                            }
                        }
                    }
                } else {
                    // If it isn't loaded then it shouldn't be playing.
                }
            }
            break
            
        case .paused:
            if loaded {
                if (pip == .started) || fullScreen {
                    // System caused
//                    if (rate != 0) {
//                        play() // "fullScreen" (in MVC) then touch causes this play.  Why???
//                    }
                } else {
                    // What would cause this?
//                    if (rate != 0) {
//                        pause()
//                    }
                }
            } else {
                if !loadFailed {
                    if Int(currentTime) <= Int(start) {
                        if (timeElapsed > Constants.MIN_LOAD_TIME) {
                            pause() // To reset playOnLoad
                            failedToLoad()
                        } else {
                            // Wait
                        }
                    } else {
                        // Paused normally
                    }
                } else {
                    // Load failed.
                }
            }
            break
            
        case .stopped:
            break
            
        case .seekingForward:
            break
            
        case .seekingBackward:
            break
        }
    }
    
    func updateCurrentTimeForPlaying()
    {
        assert(player != nil,"player should not be nil if we're trying to update the currentTime in userDefaults")
        
        guard loaded else {
            return
        }
        
        guard let duration = duration else {
            return
        }
        
        guard let currentTime = currentTime else {
            return
        }
        
        var timeNow = 0.0
        
        if (currentTime.seconds > 0) && (currentTime.seconds <= duration.seconds) {
            timeNow = currentTime.seconds
        }
        
        if ((timeNow > 0) && (Int(timeNow) % 10) == 0) {
            if  let string = mediaItem?.currentTime, let num = Float(string),
                Int(num) != Int(currentTime.seconds) {
                mediaItem?.currentTime = currentTime.seconds.description
            }
        }
    }
    
    func playerTimer()
    {
        guard state != nil else {
            return
        }
        
        guard url != URL(string: Constants.URL.LIVE_STREAM) else {
            return
        }
        
        if (rate > 0) {
            updateCurrentTimeForPlaying()
        }
        
            //            logPlayerState()
    }

    func failedToLoad()
    {
        loadFailed = true
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        }
        
        Globals.shared.alert(title: "Failed to Load Content",message: "Please check your network connection and try again.")

//        if (UIApplication.shared.applicationState == UIApplicationState.active) {
//            alert(viewController:nil,title: "Failed to Load Content", message: "Please check your network connection and try again.", completion: nil)
//        }
    }
    
    func failedToPlay()
    {
        loadFailed = true
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        }
        
        Globals.shared.alert(title: "Unable to Play Content",message: "Please check your network connection and try again.")
        
//        if (UIApplication.shared.applicationState == UIApplicationState.active) {
//            alert(viewController:nil,title: "Unable to Play Content", message: "Please check your network connection and try again.",completion: nil)
//        }
    }

    func play()
    {
        guard let url = url else {
            return
        }
        
        switch url.absoluteString {
        case Constants.URL.LIVE_STREAM:
            stateTime = PlayerStateTime(state:.playing)
            player?.play()
            break
            
        default:
            if loaded {
                updateCurrentTimeExact()
                stateTime = PlayerStateTime(state:.playing,mediaItem:mediaItem)
                player?.play()
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAYING), object: nil)
                }
            }
            break
        }
        
        controller?.allowsPictureInPicturePlayback = true
        
        setupPlayingInfoCenter()
    }
    
    func pause()
    {
        guard let url = url else {
            return
        }
        
        updateCurrentTimeExact()
        stateTime = PlayerStateTime(state:.paused,mediaItem:mediaItem)
        player?.pause()
        playOnLoad = false

        switch url.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
            }
            break
        }
        
        setupPlayingInfoCenter()
    }
    
    @objc func didPlayToEnd()
    {
        guard let duration = duration?.seconds, let currentTime = currentTime?.seconds, currentTime >= (duration - 1) else {
            return
        }
        
        //        print("didPlayToEnd",mediaItem)
        
        //        print(currentTime?.seconds)
        //        print(duration?.seconds)
        
        pause()

//        Thread.onMainThread {
//            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
//        }
        
        mediaItem?.atEnd = true
        
        if Globals.shared.autoAdvance, let mediaItem = mediaItem, mediaItem.playing == Playing.audio, mediaItem.atEnd, mediaItem.multiPartMediaItems?.count > 1,
            let mediaItems = mediaItem.multiPartMediaItems,
            let index = mediaItems.index(of: mediaItem), index < (mediaItems.count - 1) {
            let nextMediaItem = mediaItems[index + 1]
            
            nextMediaItem.playing = Playing.audio
            nextMediaItem.currentTime = Constants.ZERO
            
            self.mediaItem = nextMediaItem
            
            setup(nextMediaItem,playOnLoad:true)
        } else {
            stop()
        }
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        }
    }

    func unobserve()
    {
        guard Thread.isMainThread else {
            print("Not Main Thread","mediaPlayer:unobserve")
            return
        }
        
        playerObserverTimer?.invalidate()
        playerObserverTimer = nil
        
        if let playerTimerReturn = playerTimerReturn {
            player?.removeTimeObserver(playerTimerReturn)
            self.playerTimerReturn = nil
        }
        
        if observerActive {
            if observedItem != currentItem {
                print("observedItem != currentPlayer!")
            }
            
            if observedItem != nil {
                print("GLOBAL removeObserver: ",observedItem?.observationInfo as Any)
                
                observedItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
                
                if #available(iOS 10.0, *) {
                    player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: nil) // &GlobalPlayerContext
                }
                
                observedItem = nil
                
                observerActive = false
            } else {
                print("mediaPlayer.observedItem == nil!")
            }
        }
        
        NotificationCenter.default.removeObserver(self) //, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func reachableTransition()
    {
        if !loaded, mediaItem != nil {
            setup(mediaItem,playOnLoad:false)
        }
    }
    
    func observe()
    {
        guard Thread.isMainThread else {
            print("Not Main Thread","mediaPlayer:observe")
            return
        }
        
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            return
        }
        
        unobserve()
        
        self.playerObserverTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(playerObserver), userInfo: nil, repeats: true)
        
        if #available(iOS 10.0, *) {
            player?.addObserver( self,
                                 forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                                 options: [.old, .new],
                                 context: nil) // &GlobalPlayerContext
        }
        
        currentItem?.addObserver(self,
                                 forKeyPath: #keyPath(AVPlayerItem.status),
                                 options: [.old, .new],
                                 context: nil) // &GlobalPlayerContext
        observerActive = true
        observedItem = currentItem
        
        playerTimerReturn = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in //
            self?.playerTimer()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

        // This creates too many problems, not the least because the player buffers and may play on for minutes after the network goes down.  Also, if audio is downloaded stopping is exactly the wrong thing to do!
//        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_REACHABLE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reachableTransition), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.REACHABLE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)

        //
        //        // Why was this put here?  To set the state to .paused from .none
        //        pause()
    }
    
    var pip : PIP = .stopped
    
    var startingPIP = false
    var stoppingPIP = false
    
    var killPIP = false {
        willSet {
            
        }
        didSet {
            if pip == .started {
                if killPIP {
                    controller?.allowsPictureInPicturePlayback = false
                }
            } else {
                killPIP = false
            }
        }
    }

    func stop()
    {
        guard Thread.isMainThread else {
            print("Not Main Thread","mediaPlayer:stop")
            return
        }

        guard let url = url else {
            return
        }

        stateTime = PlayerStateTime(state:.stopped,mediaItem:mediaItem)
        player?.pause()
        playOnLoad = false

        switch url.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            killPIP = true
            
            updateCurrentTimeExact()
            
            if mediaItem?.showing == Showing.video {
               mediaItem?.showing = mediaItem?.wasShowing
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            break
        }
        
        // This is unique to stop()
        unload()
        player = nil
        let old = mediaItem
        mediaItem = nil
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: old)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STOPPED), object: nil)
        }

        setupPlayingInfoCenter()
    }
    
    func updateCurrentTimeExactWhilePlaying()
    {
        if isPlaying {
            updateCurrentTimeExact()
        }
    }
    
    func updateCurrentTimeExact()
    {
        guard let url = url else {
            print("Player has no URL.")
            return
        }
        
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        guard loaded else {
            print("Player NOT loaded.")
            return
        }
        
        guard let currentTime = currentTime else {
            print("Player has no currentTime.")
            return
        }
        
        guard let duration = duration else {
            print("Player has no duration.")
            return
        }
        
        var time = currentTime.seconds
        
        if time >= duration.seconds {
            time = duration.seconds
        }
        
        if time < 0 {
            time = 0
        }
        
        updateCurrentTimeExact(time)
    }
    
    func updateCurrentTimeExact(_ seekToTime:TimeInterval)
    {
        if (seekToTime == 0) {
            print("seekToTime == 0")
        }
        
        //    print(seekToTime)
        //    print(seekToTime.description)
        
        if (seekToTime >= 0) {
            mediaItem?.currentTime = seekToTime.description
        } else {
            print("seekeToTime < 0")
        }
    }
    
    @objc func doneSeeking()
    {
        print("DONE SEEKING")
        
        if isPlaying {
            checkPlayToEnd()
        }
    }
    
//    func seek(to: Double?)
//    {
//        isSeeking = true
//
//        seek(to: to,completion:{ [weak self] (finished:Bool) in
//            if finished {
//                self?.isSeeking = false
//                Thread.onMainThread {
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
//                }
//            }
//        })
//    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = DispatchQueue(label: "SEEK")
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    var lastSeek:Double?
    
    func seek(to: Double?) // ,completion:((Bool)->(Void))?
    {
        guard let to = to else {
            return
        }
        
        guard let url = url else {
            return
        }
        
        guard let length = currentItem?.duration.seconds else {
            return
        }
        
        switch url.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            if loaded {
                var seek = to
                
                if seek > length {
                    seek = length
                }
                
                if seek < 0 {
                    seek = 0
                }
                
//                self.isSeeking = false
                
                mediaItem?.atEnd = seek >= length

//                operationQueue.cancelAllOperations()
//                operationQueue.waitUntilAllOperationsAreFinished()
//
                operationQueue.addOperation { [weak self] in
                    self?.isSeeking = true
                    
                    self?.player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
                                      toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
                                      completionHandler: { (finished:Bool) in
                                        if finished { // , self?.isSeeking == true
                                            self?.mediaItem?.currentTime = seek.description
                                            self?.stateTime?.startTime = seek.description

                                            self?.lastSeek = to
                                            
                                            // This MUST come last as it triggers the seekingCompletion?() call.
                                            self?.isSeeking = false

                                            self?.setupPlayingInfoCenter()

                                            Thread.onMainThread {
                                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
                                            }
//                                            completion?(finished)

                                            // There is simply no avoiding the fact that currentTime may not be what you try to set it to, often less.
                                            
//                                            if let currentTime = self.currentTime, currentTime.seconds < to {
//                                                print(currentTime.seconds,to)
//                                                let newTime = CMTimeMakeWithSeconds(currentTime.seconds + 0.1,Int32(10))
//                                                self.player?.seek(to: newTime, toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
//                                                                  toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
//                                                                  completionHandler: { (finished:Bool) in
//                                                                    if finished {
//                                                                        completion?(finished)
//                                                                    }
//                                                })
//                                            } else {
//                                                completion?(finished)
//                                            }

//                                            var counter:Double = 1
//                                            while let currentTime = self.currentTime, currentTime.seconds < to {
//                                                let newTime = CMTimeMakeWithSeconds(currentTime.seconds + (counter * 0.001),Int32(1000))
//                                                print(newTime.seconds)
//                                                self.player?.seek(to: newTime)
//                                                Thread.sleep(forTimeInterval: 0.1)
//                                                counter += 1
//                                            }
//                                            completion?(finished)
                                        }
                    })
                }

                
//                player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
//                             completionHandler: { (finished:Bool) in
//                                if finished {
//                                    self.operationQueue.addOperation {
//                                        var counter:Double = 1
//                                        while let currentTime = self.currentTime, currentTime.seconds < to {
//                                            let newTime = CMTimeMakeWithSeconds(currentTime.seconds + (counter * 0.001),Int32(1000))
//                                            print(newTime.seconds)
//                                            self.player?.seek(to: newTime)
//                                            Thread.sleep(forTimeInterval: 0.1)
//                                            counter += 1
//                                        }
//                                        completion?(finished)
//                                    }
//
////                                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
////                                        var counter:Double = 1
////                                        while let currentTime = self?.currentTime, currentTime.seconds < to {
////                                            let newTime = CMTimeMakeWithSeconds(currentTime.seconds + (counter * 0.001),Int32(1000))
////                                            print(newTime.seconds)
////                                            self?.player?.seek(to: newTime)
////                                            Thread.sleep(forTimeInterval: 0.1)
////                                            counter += 1
////                                        }
////                                        completion?(finished)
////                                    }
//                                }
//                })

//                if let completion = completion {
//                    player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
//                                 completionHandler: { (finished:Bool) in
//                                    if finished {
//                                        while let currentTime = self.currentTime, currentTime < CMTimeMakeWithSeconds(to,Constants.CMTime_Resolution) {
//                                            self.player?.seek(to: currentTime + CMTimeMakeWithSeconds(0.001,Constants.CMTime_Resolution))
//                                        }
//                                        completion(finished)
//                                    }
//                    })
//                } else {
//                    player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution))
//                }
            }
            break
        }
    }
    
    var currentTime:CMTime? {
        get {
            return player?.currentTime()
        }
    }
    
    var currentItem:AVPlayerItem? {
        get {
            return player?.currentItem
        }
    }
    
    var player:AVPlayer? {
        get {
            return controller?.player
        }
        set {
            unobserve()
            
            if let sliderTimerReturn = sliderTimerReturn {
                self.player?.removeTimeObserver(sliderTimerReturn)
                self.sliderTimerReturn = nil
            }
            
            // This seems to be lethal if newValue is nil
            self.controller?.player = newValue
        }
    }
    
    var duration:CMTime? {
        get {
            return currentItem?.duration
        }
    }
    
    var state:PlayerState? {
        get {
            return stateTime?.state
        }
    }
    
    var startTime:String? {
        get {
            return stateTime?.startTime
        }
        set {
            stateTime?.startTime = newValue
        }
    }
    
    var rate:Float? {
        get {
            return player?.rate
        }
    }
    
    var view:UIView? {
        get {
            return controller?.view
        }
    }
    
    var isPlaying:Bool {
        get {
            return stateTime?.state == .playing
        }
    }
    
    var isPaused:Bool {
        get {
            return stateTime?.state == .paused
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    func unload()
    {
        loaded = false
        loadFailed = false
    }
    
    //    var observer: Timer?
    
    var mediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            Globals.shared.mediaCategory.playing = mediaItem?.id

            if oldValue != nil {
                // Remove playing icon if the previous mediaItem was playing.
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                }
            }
            
            if mediaItem == nil {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                
                // For some reason setting player to nil is LETHAL.
//                player = nil
//                stateTime = nil
            }
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
    
    func setupPlayingInfoCenter()
    {
        if url == URL(string: Constants.URL.LIVE_STREAM) {
            var nowPlayingInfo = [String:Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle]         = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyArtist]        = "Countryside Bible Church"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle]    = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist]   = "Countryside Bible Church"
            
            if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                if #available(iOS 10.0, *) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (CGSize) -> UIImage in
                        return image
                    })
                } else {
                    // Fallback on earlier versions
                    nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(image: image)
                }
            }
            
            Thread.onMainThread {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            if let mediaItem = self.mediaItem {
                var nowPlayingInfo = [String:Any]()
                
                nowPlayingInfo[MPMediaItemPropertyTitle]     = mediaItem.title
                nowPlayingInfo[MPMediaItemPropertyArtist]    = mediaItem.speaker
                
                if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                    if #available(iOS 10.0, *) {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (CGSize) -> UIImage in
                            return image
                        })
                    } else {
                        // Fallback on earlier versions
                        nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(image: image)
                    }
                } else {
                    print("no artwork!")
                }
                
                if mediaItem.hasMultipleParts {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mediaItem.multiPartName
                    nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = mediaItem.speaker
                    
                    if let index = mediaItem.multiPartMediaItems?.index(of: mediaItem) {
                        nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber]  = index + 1
                    } else {
                        print(mediaItem as Any," not found in ",mediaItem.multiPartMediaItems as Any)
                    }
                    
                    nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount]   = mediaItem.multiPartMediaItems?.count
                }
                
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration]          = duration?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime]  = currentTime?.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate]         = rate
                
                //    print("\(mediaItemInfo.count)")
                
                //                print(nowPlayingInfo)
                
                Thread.onMainThread {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            } else {
                Thread.onMainThread {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                }
            }
        }
    }
}

