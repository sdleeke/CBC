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
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    func fullScreen()
    {
        globals.player.mpPlayer?.setFullscreen(!globals.player.mpPlayer!.isFullscreen, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        NSLog("\(globals.player.mpPlayer?.contentURL)")
//        NSLog("\(NSURL(string:Constants.LIVE_STREAM_URL))")
        
        setupLivePlayerView()
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "Full Screen", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LiveViewController.fullScreen)),animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        globals.player.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }

    @IBOutlet weak var webView: UIView!

    func zoomScreen()
    {
        globals.player.mpPlayer?.setFullscreen(true, animated: true)
    }
    
    fileprivate func setupLivePlayerView()
    {
        if (globals.player.mpPlayer?.contentURL != URL(string:Constants.LIVE_STREAM_URL)) {
            globals.updateCurrentTimeExact()
            
            globals.player.mpPlayer?.stop()
            globals.player.paused = true

            globals.setupLivePlayingInfoCenter()

            globals.player.mpPlayer = MPMoviePlayerController(contentURL: URL(string: Constants.LIVE_STREAM_URL)!)
            globals.player.mpPlayer?.prepareToPlay()
        }
        
        if (globals.player.mpPlayer != nil) {
//            globals.player.mpPlayer!.setFullscreen(false, animated: false)

            let view = globals.player.mpPlayer!.view

            view?.isHidden = true
            view?.removeFromSuperview()
            
            view?.gestureRecognizers = nil
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(LiveViewController.zoomScreen))
            tap.numberOfTapsRequired = 2
            view?.addGestureRecognizer(tap)
            
            view?.frame = webView.bounds
            
            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            webView.addSubview(view!)
            
//            let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0)
//            webView.addConstraint(top)
//            
//            let leading = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0)
//            webView.addConstraint(leading)
//            
//            let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0)
//            webView.addConstraint(bottom)
//            
//            let trailing = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0.0)
//            webView.addConstraint(trailing)
//            print(view)
//            print(view?.superview)
            
            let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(width)
            
            let height = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(height)

            webView!.setNeedsLayout()

            webView.bringSubview(toFront: view!)

            view?.isHidden = false

            globals.player.mpPlayer!.play()
        }
    }
}
