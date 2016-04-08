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
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
    func fullScreen()
    {
        globals.player.mpPlayer?.setFullscreen(!globals.player.mpPlayer!.fullscreen, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        print("\(globals.player.mpPlayer?.contentURL)")
//        print("\(NSURL(string:Constants.LIVE_STREAM_URL))")
        
        setupLivePlayerView()
        
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(title: "Full Screen", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(LiveViewController.fullScreen)),animated: true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        globals.player.mpPlayer?.controlStyle = MPMovieControlStyle.Embedded
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
        globals.player.mpPlayer?.setFullscreen(true, animated: true)
    }
    
    private func setupLivePlayerView()
    {
        if (globals.player.mpPlayer?.contentURL != NSURL(string:Constants.LIVE_STREAM_URL)) {
            globals.player.mpPlayer?.stop()
            globals.player.paused = true

            globals.player.mpPlayer = MPMoviePlayerController(contentURL: NSURL(string: Constants.LIVE_STREAM_URL)!)
            globals.player.mpPlayer?.prepareToPlay()
        }
        
        if (globals.player.mpPlayer != nil) {
//            globals.player.mpPlayer!.setFullscreen(false, animated: false)

            let view = globals.player.mpPlayer!.view

            view.hidden = true
            view.removeFromSuperview()
            
            view.gestureRecognizers = nil
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(LiveViewController.zoomScreen))
            tap.numberOfTapsRequired = 2
            view.addGestureRecognizer(tap)
            
            view.frame = webView.bounds
            
            webView.addSubview(view)
            
            view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
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
            
            let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(width)
            
            let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
            webView.addConstraint(height)

            webView!.setNeedsLayout()

            webView.bringSubviewToFront(view)

            view.hidden = false

            globals.player.mpPlayer!.play()
        }
    }
}
