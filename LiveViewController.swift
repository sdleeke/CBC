//
//  LiveViewController.swift
//  TPS
//
//  Created by Steve Leeke on 11/9/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit
import MediaPlayer
import AVKit

class LiveViewController: UIViewController {
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
        }
    }
    
    func fullScreen()
    {
        Globals.mpPlayer?.setFullscreen(!Globals.mpPlayer!.fullscreen, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        removeSliderObserver()
        
//        print("\(Globals.mpPlayer?.contentURL)")
//        print("\(NSURL(string:Constants.LIVE_STREAM_URL))")
        
        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
        }
        
        Globals.mpPlayer?.view.removeFromSuperview()
        setupLivePlayer()
        
        Globals.mpPlayer?.view.hidden = false
        Globals.mpPlayer?.play()
        
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(title: "Full Screen", style: UIBarButtonItemStyle.Plain, target: self, action: "fullScreen"),animated: true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Globals.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }

    @IBOutlet weak var webView: UIView!

    func zoomScreen()
    {
        Globals.mpPlayer?.setFullscreen(true, animated: true)
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
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
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
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
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
    }
    
    private func setupLivePlayer()
    {
        var view:UIView!

        if (Globals.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            Globals.mpPlayer = MPMoviePlayerController(contentURL: NSURL(string: Constants.LIVE_STREAM_URL)!)
            Globals.mpPlayer?.prepareToPlay()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: "zoomScreen")
        tap.numberOfTapsRequired = 2
        
        view = Globals.mpPlayer?.view
        
        view.frame = webView.bounds
        
        view.addGestureRecognizer(tap)
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        webView.addSubview(view)
        
        let left = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0.0)
        webView!.addConstraint(left)
        
        let right = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0.0)
        webView!.addConstraint(right)
        
        let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0)
        webView!.addConstraint(top)
        
        let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0)
        webView!.addConstraint(bottom)
        
        webView!.setNeedsLayout()
        webView!.layoutIfNeeded()
        
        webView.bringSubviewToFront(view)
    }
}
