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
            if (state != oldValue) {
                dateEntered = Date()
            }
        }
    }
    
    var startTime:String?
    
    var dateEntered:Date?
    var timeElapsed:TimeInterval {
        get {
            return Date().timeIntervalSince(dateEntered!)
        }
    }
    
//    init()
//    {
//        dateEntered = Date()
//    }
//    
//    convenience init(_ mediaItem:MediaItem?)
//    {
//        self.init()
//        self.mediaItem = mediaItem
//        startTime = mediaItem?.currentTime
//    }
    
    init(state: PlayerState)
    {
        dateEntered = Date()
        self.state = state
    }
    
    convenience init(_ mediaItem:MediaItem?,state: PlayerState)
    {
        self.init(state:state)
        self.mediaItem = mediaItem
        startTime = mediaItem?.currentTime
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
        
        if stateName != nil {
            print(stateName!)
        }
    }
}

class MediaPlayer {
    var sliderTimerReturn:Any? = nil
    var playerTimerReturn:Any? = nil
    
    var observerActive = false
    var observedItem:AVPlayerItem?
    
    var playerObserver:Timer?
    
    var fullScreen = false
    {
        didSet {
            print(fullScreen)
        }
    }
    
    var url : URL? {
        get {
            return (currentItem?.asset as? AVURLAsset)?.url
        }
    }
    
    var controller:AVPlayerViewController? // = AVPlayerViewController()
    
    var stateTime:PlayerStateTime?
    {
        didSet {
//            print(stateTime?.mediaItem)
//            print(stateTime?.state.hashValue)
//            print(stateTime?.dateEntered)
//            print(stateTime?.timeElapsed)
//            print(stateTime?.startTime)
        }
    }
    
    var showsPlaybackControls:Bool{
        get {
            return controller != nil ? controller!.showsPlaybackControls : false
        }
        set {
            controller?.showsPlaybackControls = newValue
        }
    }
    
//    init()
//    {
//        controller?.showsPlaybackControls = false
//        
//        if #available(iOS 10.0, *) {
//            controller?.updatesNowPlayingInfoCenter = false
//        } else {
//            // Fallback on earlier versions
//        }
//        
//        if #available(iOS 9.0, *) {
//            controller?.allowsPictureInPicturePlayback = true
//        } else {
//            // Fallback on earlier versions
//        }
//    }
    
    //    func stopIfPlaying()
    //    {
    //        if isPlaying {
    //            stop()
    //        } else {
    //            print("Player NOT playing.")
    //        }
    //    }
    
    //    func pauseIfPlaying()
    //    {
    //        if isPlaying {
    //            pause()
    //        } else {
    //            print("Player NOT playing.")
    //        }
    //    }
    
    func reload()
    {
        guard (mediaItem != nil) else {
            return
        }

        unload()
        
        player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
        
        pause() // To reset playOnLoad and set state to .paused
    }
    
    func play()
    {
        guard (url != nil) else {
            return
        }
        
        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            stateTime = PlayerStateTime(state:.playing)
            player?.play()
            break
            
        default:
            if loaded {
                stateTime = PlayerStateTime(mediaItem,state:.playing)
                player?.play()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                })
            }
            break
        }
        
        controller?.allowsPictureInPicturePlayback = true
        
        setupPlayingInfoCenter()
    }
    
    func pause()
    {
        guard (url != nil) else {
            return
        }
        
        stateTime = PlayerStateTime(mediaItem,state:.paused)
        player?.pause()
        playOnLoad = false

        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            updateCurrentTimeExact()
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
            break
        }
        
        setupPlayingInfoCenter()
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
            userAlert(title: "Not Main Thread", message: "MediaPlayer:stop")
            return
        }

        guard (url != nil) else {
            return
        }

        stateTime = PlayerStateTime(mediaItem,state:.stopped)
        player?.pause()
        playOnLoad = false

        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            killPIP = true
            
            updateCurrentTimeExact()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            break
        }
        
        // This is unique to stop()
        mediaItem = nil
        unload()
        player = nil
        
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
        if (url != nil) && (url != URL(string:Constants.URL.LIVE_STREAM)) {
            if loaded && (currentTime != nil) {
                var time = currentTime!.seconds
                if time >= duration!.seconds {
                    time = duration!.seconds
                }
                if time < 0 {
                    time = 0
                }
                updateCurrentTimeExact(time)
            } else {
                print("Player NOT loaded or has no currentTime.")
            }
        } else {
            print("Player has no URL or is LIVE STREAM.")
        }
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
    
    func seek(to: Double?)
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
                
                player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
                             completionHandler: { (finished:Bool) in
                                if finished {
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
                                    })
                                }
                })
                
                mediaItem?.currentTime = seek.description
                stateTime?.startTime = seek.description
                
                setupPlayingInfoCenter()
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
            globals.unobservePlayer()
            
            if self.sliderTimerReturn != nil {
                self.player?.removeTimeObserver(self.sliderTimerReturn!)
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
            globals.mediaCategory.playing = mediaItem?.id

            if oldValue != nil {
                // Remove playing icon if the previous mediaItem was playing.
                //            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                })
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
                nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(image: image)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            })
        } else {
            if let mediaItem = self.mediaItem {
                var nowPlayingInfo = [String:Any]()
                
                nowPlayingInfo[MPMediaItemPropertyTitle]     = mediaItem.title
                nowPlayingInfo[MPMediaItemPropertyArtist]    = mediaItem.speaker
                
                if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
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
                
                DispatchQueue.main.async(execute: { () -> Void in
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                })
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                })
            }
        }
    }
}

