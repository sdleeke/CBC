//
//  SettingsViewController.swift
//  TWU
//
//  Created by Steve Leeke on 2/18/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    
    @IBOutlet weak var searchTranscriptsSwitch: UISwitch!
    
    @IBAction func searchTranscriptsAction(_ sender: UISwitch) {
        globals.search.transcripts = sender.isOn
    }
    
    @IBOutlet weak var autoAdvanceSwitch: UISwitch!
    
    @IBAction func autoAdvanceAction(_ sender: UISwitch) {
        globals.autoAdvance = sender.isOn
    }
    
    @IBOutlet weak var audioSizeLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    @IBAction func cacheAction(_ sender: UISwitch) {
        globals.cacheDownloads = sender.isOn
        
        if !sender.isOn {
            URLCache.shared.removeAllCachedResponses()
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                globals.loadSingles = false
                
                for mediaItem in globals.mediaRepository.list! {
                    mediaItem.notesDownload?.delete()
                    mediaItem.slidesDownload?.delete()
                }
                
                globals.loadSingles = true

                DispatchQueue.main.async(execute: { () -> Void in
                    self.updateCacheSize()
                })
            })
        }
    }
    
//    @IBAction func doneAction(sender: UIButton) {
//        dismissViewControllerAnimated(true, completion: nil)
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchTranscriptsSwitch.isOn = globals.search.transcripts
        autoAdvanceSwitch.isOn = globals.autoAdvance
        cacheSwitch.isOn = globals.cacheDownloads
    }
    
    func updateCacheSize()
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.loadSingles = false
            
            let sizeOfCache = globals.cacheSize(Purpose.slides) + globals.cacheSize(Purpose.notes)
            
            globals.loadSingles = true

            var size:Float = Float(sizeOfCache)
            
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

            DispatchQueue.main.async(execute: { () -> Void in
                self.cacheSizeLabel.text = "\(String(format: "%0.1f",size)) \(sizeLabel) in use"
            })
        })
    }
    
    func updateAudioSize()
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            let sizeOfAudio = globals.cacheSize(Purpose.audio)
            
            var size:Float = Float(sizeOfAudio)
            
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
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.audioSizeLabel.text = "Audio Storage: \(String(format: "%0.1f",size)) \(sizeLabel) in use"
            })
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 9.0, *) {
            cacheSwitch.isEnabled = true
        } else {
            cacheSwitch.isEnabled = false
        }

        cacheSizeLabel.text = "Updating..."
        audioSizeLabel.text = "Audio Storage: updating..."

        updateCacheSize()
        updateAudioSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
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
