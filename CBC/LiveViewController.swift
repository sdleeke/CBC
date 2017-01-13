//
//  LiveViewController.swift
//  CBC
//
//  Created by Steve Leeke on 11/9/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Chage spaces before am/pm to be unbreakable
        textView.text = textView.text.replacingOccurrences(of: " am", with: "\u{00a0}am")
        textView.text = textView.text.replacingOccurrences(of: " pm", with: "\u{00a0}pm")
        
        setupLivePlayerView()
    }

    func clearView()
    {
        DispatchQueue.main.async {
            globals.mediaPlayer.view?.isHidden = true
            self.textView.isHidden = true
            self.logo.isHidden = false
        }
    }
    
    func liveView()
    {
        DispatchQueue.main.async {
            self.setupLivePlayerView()
            
            globals.mediaPlayer.view?.isHidden = false
            self.textView.isHidden = false
            self.logo.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        logo.isHidden = true
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        }

        navigationController?.isToolbarHidden = true
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
        globals.freeMemory()
    }

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var webView: UIView!

    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    func showHideNotice(_ pan:UIPanGestureRecognizer)
    {
        switch pan.state {
        case .began:
            break
            
        case .ended:
            break
            
        case .changed:
            let translation = pan.translation(in: view)
            
            if translation.y != 0 {
                if textViewHeight.constant - translation.y < 0 {
                    textViewHeight.constant = 0
                } else
                    if textViewHeight.constant - translation.y > self.view.bounds.height {
                        textViewHeight.constant = self.view.bounds.height
                    } else {
                    textViewHeight.constant -= translation.y
                }
            }
            
            self.view.setNeedsLayout()
            //                self.view.layoutSubviews()
            
            pan.setTranslation(CGPoint.zero, in: view)
            break
            
        default:
            break
        }
    }
    
    fileprivate func setupLivePlayerView()
    {
        if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            globals.mediaPlayer.pause() // IfPlaying

            globals.setupPlayer(url: URL(string:Constants.URL.LIVE_STREAM),playOnLoad:true)
            globals.mediaPlayer.setupPlayingInfoCenter()
        }
        
        globals.mediaPlayer.showsPlaybackControls = true
        
        view.gestureRecognizers = nil
        let pan = UIPanGestureRecognizer(target: self, action: #selector(LiveViewController.showHideNotice(_:)))
        view.addGestureRecognizer(pan)

        textView.sizeToFit()
        
        if (globals.mediaPlayer.view != nil) {
            let view = globals.mediaPlayer.view

            view?.isHidden = true
            view?.removeFromSuperview()
            
            view?.frame = webView.bounds
            
            view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            webView.addSubview(view!)
            
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

            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: 0.1)
                globals.mediaPlayer.play()
            }
        }
    }
}
