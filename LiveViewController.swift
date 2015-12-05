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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        Globals.sliderObserver?.invalidate()
        Globals.sliderObserver = nil
        
        Globals.playObserver?.invalidate()
        Globals.playObserver = nil
        
        Globals.mpPlayer?.stop()
        
        Globals.playerPaused = true
        
        Globals.mpPlayer?.view.removeFromSuperview()
        
        setupLivePlayer()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Globals.mpPlayer!.view.hidden = false
        Globals.mpPlayer?.play()
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
    
    private func setupLivePlayer()
    {
        var view:UIView!
        
        let tap = UITapGestureRecognizer(target: self, action: "zoomScreen")
        tap.numberOfTapsRequired = 2

        Globals.mpPlayer = MPMoviePlayerController(contentURL: NSURL(string: Constants.LIVE_STREAM_URL)!)
        Globals.mpPlayer?.prepareToPlay()
        
        Globals.mpPlayer!.view.addGestureRecognizer(tap)
        Globals.mpPlayer!.view!.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        view = Globals.mpPlayer!.view!
        
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
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
