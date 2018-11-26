//
//  SettingsViewController.swift
//  CBC
//
//  Created by Steve Leeke on 2/18/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController
{
    @IBOutlet weak var searchTranscriptsSwitch: UISwitch!
    
    @IBAction func searchTranscriptsAction(_ sender: UISwitch)
    {
        Globals.shared.search.transcripts = sender.isOn
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        }
    }
    
    @IBOutlet weak var autoAdvanceSwitch: UISwitch!
    
    @IBAction func autoAdvanceAction(_ sender: UISwitch)
    {
        Globals.shared.autoAdvance = sender.isOn
    }
    
    @IBOutlet weak var audioSizeLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    @IBAction func cacheAction(_ sender: UISwitch)
    {
        Globals.shared.cacheDownloads = sender.isOn
        
        if !sender.isOn {
            URLCache.shared.removeAllCachedResponses()
            
            // Let it finish
//            operationQueue.cancelAllOperations()
            
            operationQueue.addOperation { [weak self] in
                Thread.onMainThread {
                    self?.cacheSizeLabel.text = "Updating..."
                }
                
                // This really should be looking at what is in the directory as well.
                // E.g. what if a sermon is no longer in the list but its slides or notes
                // were downloaded previously?
                Globals.shared.mediaRepository.clearCache(block:false)
                
//                if let mediaItems = Globals.shared.mediaRepository.list {
//                    for mediaItem in mediaItems {
//                        mediaItem.clearCache()
//                    }
//                }
                
                self?.updateCacheSize()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done)), animated: true)
                
            default:
                break
            }
        }
        
        if #available(iOS 9.0, *) {
            cacheSwitch.isEnabled = true
        } else {
            cacheSwitch.isEnabled = false
        }
        
        searchTranscriptsSwitch.isOn = Globals.shared.search.transcripts
        autoAdvanceSwitch.isOn = Globals.shared.autoAdvance
        cacheSwitch.isOn = Globals.shared.cacheDownloads
        
        operationQueue.addOperation {
            Thread.onMainThread {
                self.cacheSizeLabel.text = "Updating..."
            }
            
            self.updateCacheSize()
        }
        
        audioSizeLabel.text = "Audio Storage: updating..."
        self.updateAudioSize()
    }
    
    func updateCacheSize()
    {
        let cacheSize = Globals.shared.mediaRepository.cacheSize // (Purpose.slides) + Globals.shared.cacheSize(Purpose.notes)
        
        var size:Float = Float(cacheSize ?? 0)
        
        var count = 0
        
        while size > 1024 {
            size /= 1024
            count += 1
        }
        
        var sizeLabel:String
        
        switch count {
        case 0:
            sizeLabel = "bytes"
            break
            
        case 1:
            sizeLabel = "KB"
            break
            
        case 2:
            sizeLabel = "MB"
            break
            
        case 3:
            sizeLabel = "GB"
            break
            
        default:
            sizeLabel = "ERROR"
            break
        }
        
        Thread.onMainThread {
            self.cacheSizeLabel.text = "\(String(format: "%0.1f",size)) \(sizeLabel) in use"
        }
    }
    
    func updateAudioSize()
    {
        // Does this REALLY need to be .user* ?
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let sizeOfAudio = Globals.shared.mediaRepository.cacheSize(Purpose.audio)
            
            var size:Float = Float(sizeOfAudio ?? 0)
            
            var count = 0
            
            while size > 1024 {
                size /= 1024
                count += 1
            } 
            
            var sizeLabel:String
            
            switch count {
            case 0:
                sizeLabel = "bytes"
                break
                
            case 1:
                sizeLabel = "KB"
                break
                
            case 2:
                sizeLabel = "MB"
                break
                
            case 3:
                sizeLabel = "GB"
                break
                
            default:
                sizeLabel = "ERROR"
                break
            }
            
            Thread.onMainThread {
                self?.audioSizeLabel.text = "Audio Storage: \(String(format: "%0.1f",size)) \(sizeLabel) in use"
            }
        }
    }
    
    @objc func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

    }

    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "SETTINGS"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}
