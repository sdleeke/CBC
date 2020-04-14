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

/**
 For displaying live events.
 */
class LiveViewController: CBCViewController
{
    deinit {
        debug(self)
    }
    
    var streamingURL : URL?
    {
        get {
            // [[String:Any]])?[0]["url"] as?
            return ((streaming?.storage?["files"] as? [String:Any])?["video"] as? String)?.url
        }
    }
    
    var streaming : Streaming?
    {
        didSet {
            
        }
    }
    
    var streamEntry:StreamEntry?
    {
        didSet {
            streaming = Streaming(streamEntry?["streaming"] as? [String:Any])
            
            let defaults = UserDefaults.standard
            if streamEntry != nil {
                if (streamEntry?.storage != nil) {
                    defaults.set(streamEntry?.storage,forKey: Constants.SETTINGS.LIVE)
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
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    func setImage(_ image:UIImage? = nil)
    {
        guard let image = image ?? UIImage(named:"CBC_logo") else {
            self.logo.image = nil
            return
        }
        
        Thread.onMain { [weak self] in
            // Need to adjust aspect ratio contraint
            let ratio = image.size.width / image.size.height
            
            self?.layoutAspectRatio = self?.layoutAspectRatio.setMultiplier(multiplier: ratio)
            
            self?.logo.image = image
        }
    }
    
    @objc func clearView()
    {
        Thread.onMain { [weak self] in 
            Globals.shared.mediaPlayer.view?.isHidden = true
            self?.setImage(UIImage(named:"CBC_logo"))
            self?.logo.isHidden = false
        }
    }
    
    @objc func liveView()
    {
        Thread.onMain { [weak self] in 
            self?.setupLivePlayerView()
            
            Globals.shared.mediaPlayer.view?.isHidden = false
            self?.logo.isHidden = true
        }
    }
    
    @objc func deviceOrientationDidChange()
    {
    
    }
    
    @objc func done()
    {
        Globals.shared.mediaPlayer.stop()
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
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
    
    @objc func willResignActive()
    {
        // URL(string:Constants.URL.LIVE_STREAM)
        guard Globals.shared.mediaPlayer.url == streamingURL else {
            return
        }
        
        guard Globals.shared.mediaPlayer.pip != .started else {
            return
        }
        
        Globals.shared.mediaPlayer.pause()
    }

    @objc func didBecomeActive()
    {
        guard Globals.shared.mediaPlayer.url == streamingURL else {
            return
        }
        
        guard Globals.shared.mediaPlayer.pip != .started else {
            return
        }
        
        Globals.shared.mediaPlayer.play()
    }

    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        logo.isHidden = true

        setDVCLeftBarButton()
        
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        
        setupLivePlayerView()

        navigationController?.isToolbarHidden = true
        
        navigationItem.title = streamEntry?.title
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
//        Globals.shared.mediaPlayer.stop()
        
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
        Globals.shared.freeMemory()
    }
    
    @IBOutlet weak var layoutAspectRatio: NSLayoutConstraint!
    
    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var webView: UIView!
    
    fileprivate func setupLivePlayerView()
    {
        guard Globals.shared.mediaPlayer.pip == .stopped else {
            return
        }
        
        if (Globals.shared.mediaPlayer.url != streamingURL) { // URL(string:Constants.URL.LIVE_STREAM)
            Globals.shared.mediaPlayer.stop() // IfPlaying

            Globals.shared.mediaPlayer.setup(url: streamingURL, playOnLoad:true) //  ?? URL(string:Constants.URL.LIVE_STREAM)
            Globals.shared.mediaPlayer.setupPlayingInfoCenter()
        } else {
            return
        }
        
        guard let view = Globals.shared.mediaPlayer.view else {
            return
        }
        
        Globals.shared.mediaPlayer.showsPlaybackControls = true
                
        view.isHidden = true
        view.removeFromSuperview()
        Globals.shared.mediaPlayer.controller?.removeFromParent()
        
        view.frame = webView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let avPlayerViewController = Globals.shared.mediaPlayer.controller {
            self.addChild(avPlayerViewController)
        }
        webView.addSubview(view)
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0.0)
        webView.addConstraint(height)

        webView.setNeedsLayout()

        webView.bringSubviewToFront(view)

        view.isHidden = false

        // So UI operates as expected
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            Thread.sleep(forTimeInterval: 2) // apparently a delay is needed to get it to play correctly?
//            Globals.shared.mediaPlayer.play()
//        }
    }
}
