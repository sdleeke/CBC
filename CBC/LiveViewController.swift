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

class LiveViewController: UIViewController
{
    var streamEntry:StreamEntry?
    {
        didSet {
            let defaults = UserDefaults.standard
            if streamEntry != nil {
                if (streamEntry?.dict != nil) {
                    defaults.set(streamEntry?.dict,forKey: Constants.SETTINGS.LIVE)
                } else {
                    //Should not happen
                    defaults.removeObject(forKey: Constants.SETTINGS.LIVE)
                }
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.LIVE)
            }
            defaults.synchronize()
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true //let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        globals.motionEnded(motion,event: event)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupLivePlayerView()
        
        // Chage spaces before am/pm to be unbreakable
        textView.text = textView.text.replacingOccurrences(of: " am", with: "\u{00a0}am")
        textView.text = textView.text.replacingOccurrences(of: " pm", with: "\u{00a0}pm")
    }

    @objc func clearView()
    {
        Thread.onMainThread {
            globals.mediaPlayer.view?.isHidden = true
            self.textView.isHidden = true
            self.logo.isHidden = false
        }
    }
    
    @objc func liveView()
    {
        Thread.onMainThread {
            self.setupLivePlayerView()
            
            globals.mediaPlayer.view?.isHidden = false
            self.textView.isHidden = false
            self.logo.isHidden = true
        }
    }
    
    func deviceOrientationDidChange()
    {
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LiveViewController.done))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func done()
    {
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
//            self.splitViewController?.preferredDisplayMode = .allVisible
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_LAST_SEGUE), object: nil)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setDVCLeftBarButton()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        logo.isHidden = true

        setDVCLeftBarButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)

        navigationController?.isToolbarHidden = true
        
        navigationItem.title = streamEntry?.name
        
        deviceOrientationDidChange()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        globals.mediaPlayer.pause()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var webView: UIView!

    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    {
        didSet {
            textViewHeight.constant = 0
        }
    }
    
    func showHideNotice(_ pan:UIPanGestureRecognizer)
    {
        switch pan.state {
        case .began:
            break
            
        case .ended:
            break
            
        case .changed:
            let translation = pan.translation(in: pan.view)
            
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
            
            pan.setTranslation(CGPoint.zero, in: pan.view)
            break
            
        default:
            break
        }
    }
    
    fileprivate func setupLivePlayerView()
    {
        if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            globals.mediaPlayer.pause() // IfPlaying

            globals.mediaPlayer.setup(url: URL(string:Constants.URL.LIVE_STREAM),playOnLoad:true)
            globals.mediaPlayer.setupPlayingInfoCenter()
        }
        
        guard let view = globals.mediaPlayer.view else {
            return
        }
        
        globals.mediaPlayer.showsPlaybackControls = true
        
        textView.sizeToFit()
        
        view.isHidden = true
        view.removeFromSuperview()
        
        view.frame = webView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        webView.addSubview(view)
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(height)

        webView.setNeedsLayout()

        webView.bringSubview(toFront: view)

        view.isHidden = false

        DispatchQueue.global(qos: .background).async { [weak self] in
            Thread.sleep(forTimeInterval: 0.1) // apparently a delay is needed to get it to play correctly?
            globals.mediaPlayer.play()
        }
    }
}
