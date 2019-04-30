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
    }
    
    @IBOutlet weak var clearCache: UIButton!
    @IBAction func clearCacheAction(_ sender: UIButton)
    {
        URLCache.shared.removeAllCachedResponses()
        
        // Let it finish
        //            operationQueue.cancelAllOperations()
        
        operationQueue.addOperation { [weak self] in
            Thread.onMainThread {
                sender.isEnabled = false
                self?.cacheSizeLabel.text = "Updating..."
            }
            
            guard let cachesURL = FileManager.default.cachesURL else {
                return
            }
            
            // Really should delete anything that matches what comes before "." in lastPathComponent,
            // which in this case is id (which is mediaCode)
            // BUT all we're doing is looking for files that START with id, lots more could follow, not just "."
            

            // This really should be looking at what is in the directory as well.
            // E.g. what if a sermon is no longer in the list but its slides or notes
            // were downloaded previously?
            
            // Too slow
//            Globals.shared.mediaRepository.clearCache(block:false)

            try? autoreleasepool {
                let files = try FileManager.default.contentsOfDirectory(atPath: cachesURL.path)

                // It would be safer if our filenames had the APP_ID in them or we had our own folder in the caches directory
                // If some other app has files w/ these filename extensions (really just filenames that end with these strings)
                // in the cache, we will be deleting them.
                for file in files {
                    for fileType in Constants.cacheFileTypes {
                        if file.isFileType(fileType) {
                            var fileURL = cachesURL
                            fileURL.appendPathComponent(file)
                            fileURL.delete(block: true)
                        } else {
                            print(file)
                        }
                    }
                }
            }

            self?.updateCacheSize(sender)
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
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done)), animated: true)
                
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
        
        operationQueue.addOperation { [weak self] in
            Thread.onMainThread {
                self?.clearCache.isEnabled = false
                self?.cacheSizeLabel.text = "Updating..."
            }
            
            self?.updateCacheSize(self?.clearCache)
        }
        
        audioSizeLabel.text = "Audio Storage: updating..."
        self.updateAudioSize()
    }
    
    func updateCacheSize(_ sender:UIButton?)
    {
        var cacheSize = 0
        
        autoreleasepool {
            if let cachesURL = FileManager.default.cachesURL {
                cachesURL.files(notOfType:Constants.FILENAME_EXTENSION.MP3)?.forEach({ (string:String) in
                    var fileURL = cachesURL
                    fileURL.appendPathComponent(string)
                    cacheSize += fileURL.fileSize ?? 0
                })
            }
        }

        // THIS IS COMPUTATIONALLY EXPENSIVE TO CALL
//        let cacheSize = Globals.shared.mediaRepository.cacheSize // (Purpose.slides) + Globals.shared.cacheSize(Purpose.notes)
        
        var size:Float = Float(cacheSize) //  ?? 0
        
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
            sender?.isEnabled = size > 0
        }
    }
    
    func updateAudioSize()
    {
        // Does this REALLY need to be .user* ?
        // Should this be in an opQueue?
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

    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "SettingsViewController" // Assumes there is only ever one at a time globally 
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}
