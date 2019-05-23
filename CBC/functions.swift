//
//  functions.swift
//  CBC
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit
import MessageUI
import UserNotifications
import NaturalLanguage

func debug(_ any:Any...)
{
//    print(any)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}

func startAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
    } catch let error {
        NSLog("failed to setCategory(AVAudioSessionCategoryPlayback): \(error.localizedDescription)")
    }
    
    UIApplication.shared.beginReceivingRemoteControlEvents()
}

func stopAudio()
{
    let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setActive(false)
    } catch let error {
        NSLog("failed to audioSession.setActive(false): \(error.localizedDescription)")
    }
}

func verifyNASB()
{
    if Constants.OLD_TESTAMENT_BOOKS.count != 39 {
        print("ERROR: ","\(Constants.OLD_TESTAMENT_BOOKS.count)")
    }
    
    for book in Constants.OLD_TESTAMENT_BOOKS {
        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
            let chapters = Constants.OLD_TESTAMENT_CHAPTERS[index]
            
            let dict = Scripture(reference: "\(book) \(chapters+1):1").loadJSONVerseFromURL()
            
            let passages = (((dict?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
            
            if passages?.count != 0 {
                print("ERROR: ","\(book) \(chapters)")
                print(passages as Any)
            }
            
            if Constants.OLD_TESTAMENT_VERSES[index].count != chapters {
                print("ERROR: WRONG COUNT IN VERSES ARRAY: ",book)
            }
            
            for chapter in 0..<chapters {
                let verses = Constants.OLD_TESTAMENT_VERSES[index][chapter]
                
                let dict1 = Scripture(reference: "\(book) \(chapter+1):\(verses)").loadJSONVerseFromURL()
                
                let passages1 = (((dict1?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                let dict2 = Scripture(reference: "\(book) \(chapter+1):\(verses + 1)").loadJSONVerseFromURL()
                
                let passages2 = (((dict2?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                if (passages1?.count != 1) || (passages2?.count != 0) {
                    print("ERROR: ","\(book) \(chapter+1):\(verses)")
                    print(passages1 as Any)
                    print(passages2 as Any)
                }
            }
        }
    }
    
    if Constants.NEW_TESTAMENT_BOOKS.count != 27 {
        print("ERROR: ","\(Constants.NEW_TESTAMENT_BOOKS.count)")
    }
    
    for book in Constants.NEW_TESTAMENT_BOOKS {
        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
            let chapters = Constants.NEW_TESTAMENT_CHAPTERS[index]
            
            let dict = Scripture(reference: "\(book) \(chapters+1):1").loadJSONVerseFromURL()
            
            let passages = (((dict?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
            
            if passages?.count != 0 {
                print("ERROR: ","\(book) \(chapters)")
                print(passages as Any)
            }
            
            if Constants.NEW_TESTAMENT_VERSES[index].count != chapters {
                print("ERROR: WRONG COUNT IN VERSES ARRAY: ",book)
            }
            
            for chapter in 0..<chapters {
                let verses = Constants.NEW_TESTAMENT_VERSES[index][chapter]
                
                let dict1 = Scripture(reference: "\(book) \(chapter+1):\(verses)").loadJSONVerseFromURL()
                
                let passages1 = (((dict1?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                let dict2 = Scripture(reference: "\(book) \(chapter+1):\(verses + 1)").loadJSONVerseFromURL()
                
                let passages2 = (((dict2?["response"] as? [String:Any])?["search"] as? [String:Any])?["result"] as? [String:Any])?["passages"] as? [[String:Any]]
                
                if (passages1?.count != 1) || (passages2?.count != 0) {
                    print("ERROR: ","\(book) \(chapter+1):\(verses)")
                    print(passages1 as Any)
                    print(passages2 as Any)
                }
            }
        }
    }
}

