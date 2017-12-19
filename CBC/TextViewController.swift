//
//  TextViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/8/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    func scrollToRange(_ range:Range<String.Index>)
    {
        let utf16 = attributedText.string.utf16
        
        let from = range.lowerBound.samePosition(in: utf16)
        let to = range.upperBound.samePosition(in: utf16)
        
        let nsRange = NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                              length: utf16.distance(from: from, to: to))
        
        scrollRangeToVisible(nsRange)
    }
}

extension TextViewController: UISearchBarDelegate
{
    //MARK: SearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarShouldBeginEditing",completion:nil)
            return false
        }

        searchActive = true
        
        searchBar.showsCancelButton = true
        
        searchText = searchBar.text
        
        textView.attributedText = stringMarkedBySearchAsAttributedString(string: textView.attributedText.string, searchText: searchText, wholeWordsOnly: false)

        if let searchText = searchText,let range = textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
            let utf16 = textView.attributedText.string.utf16
            
            let from = range.lowerBound.samePosition(in: utf16)
            let to = range.upperBound.samePosition(in: utf16)
            
            let nsRange = NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                                  length: utf16.distance(from: from, to: to))
            
            textView.scrollRangeToVisible(nsRange)
        }
        
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        self.searchText = searchText

        textView.attributedText = stringMarkedBySearchAsAttributedString(string: changedText, searchText: searchText, wholeWordsOnly: false)
        
        
        if let range = textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
            textView.scrollToRange(range)
            lastRange = range
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchText = searchBar.text
        
        textView.attributedText = stringMarkedBySearchAsAttributedString(string: changedText, searchText: searchText, wholeWordsOnly: false)
        
        if let lastRange = lastRange {
            let startingRange = Range(uncheckedBounds: (lower: lastRange.upperBound, upper: textView.attributedText.string.endIndex))

            if let searchText = searchText,let range = textView.attributedText.string.lowercased().range(of: searchText.lowercased(), options: [], range: startingRange, locale: nil) {
                textView.scrollToRange(range)
                self.lastRange = range
            } else {
                self.lastRange = nil
            }
        }
        
        if lastRange == nil {
            if let searchText = searchText,let range = textView.attributedText.string.lowercased().range(of: searchText.lowercased()) {
                textView.scrollToRange(range)
                lastRange = range
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "TextViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false
        
        if let changedText = changedText {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
        
        searchBar.showsCancelButton = false
        
        searchBar.resignFirstResponder()
        searchBar.text = nil
    }
}

extension TextViewController : UITextViewDelegate
{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should begin in the specified text view.

        editingActive = true
        
        if let changedText = changedText {
            self.textView.attributedText = NSAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has begun.
        
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should stop in the specified text view.
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        // Tells the delegate that editing of the specified text view has ended.
        
        if let searchText = searchText, searchActive {
            textView.attributedText = stringMarkedBySearchAsAttributedString(string: changedText, searchText: searchText, wholeWordsOnly: false)
        }

        editingActive = false
    }
    
    func textView(_ shouldChangeTextIn: NSRange, replacementText: String)
    {
        // Asks the delegate whether the specified text should be replaced in the text view.

    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // Tells the delegate that the text or attributes in the specified text view were changed by the user.
    
        // Hopefully this isn't expensive
        changedText = textView.attributedText.string //textView.text
    }
    
    func textViewDidChangeSelection(_ textView: UITextView)
    {
        // Tells the delegate that the text selection changed in the specified text view.
        
    }
}

class TextViewController : UIViewController
{
    var lastRange : Range<String.Index>?
    
    var text : String?
    {
        didSet {
            changedText = text
        }
    }
    
    var changedText : String?
    {
        didSet {
            
        }
    }
    
    var searchText : String?

    var search = false
    
    var syncButton : UIBarButtonItem!
    
    func disableBarButtons()
    {
        Thread.onMainThread() {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMainThread() {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
        }
    }

    var searchActive = false
    {
        didSet {
            guard searchActive != oldValue else {
                return
            }

            if searchActive {
                removeTracking()
                removeAssist()
                disableBarButtons()
            } else {
                enableBarButtons()
            }
            
            if !searchActive && !editingActive {
                restoreTracking()
                restoreAssist()
            }
        }
    }
    
    var wholeWordsOnly = false
    var searchInteractive = true

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    var editingActive = false
    {
        didSet {
            guard editingActive != oldValue else {
                return
            }
            
            if editingActive {
                removeTracking()
                removeAssist()
            }
            
            if !searchActive && !editingActive {
                restoreTracking()
                restoreAssist()
            }
        }
    }

    @IBOutlet weak var textViewToTop: NSLayoutConstraint!
    
    var automatic = false
    var automaticInteractive = false
    var automaticCompletion : (()->(Void))?
    
    var completion : ((String)->(Void))?
    
    var confirmation : (()->Bool)?
    var confirmationTitle : String?
    var confirmationMessage : String?

    var onCancel : (()->(Void))?
    
    @IBOutlet weak var textView: UITextView!
    
    var transcript:VoiceBase?
    
    var following : [[String:Any]]?
    {
        didSet {
            Thread.onMainThread {
                self.syncButton.isEnabled = true
            }
        }
    }
    
    var oldRange : Range<String.Index>?

    func removeAssist()
    {
        guard assist else {
            return
        }
        
        navigationItem.rightBarButtonItems = [saveButton]
    }
    
    func restoreAssist()
    {
        guard assist else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        if navigationItem.rightBarButtonItems != nil {
            navigationItem.rightBarButtonItems?.append(assistButton)
        } else {
            navigationItem.rightBarButtonItem = assistButton
        }
    }
    
    func removeTracking()
    {
        guard track else {
            return
        }
        
        guard wasTracking == nil else {
            return
        }
        
        wasTracking = isTracking
        
        wasPlaying = globals.mediaPlayer.isPlaying
        
        isTracking = false
        stopTracking()
        
        navigationItem.leftBarButtonItems = [cancelButton]
    }
    
    func restoreTracking()
    {
        guard track else {
            return
        }
        
        isTracking = wasTracking ?? true
        wasTracking = nil
        
        if isTracking {
            startTracking()
        }

        if navigationItem.leftBarButtonItems != nil {
            navigationItem.leftBarButtonItems?.append(syncButton)
        } else {
            navigationItem.leftBarButtonItem = syncButton
        }
    }
    
    func stopTracking()
    {
        guard track else {
            return
        }
        
        globals.mediaPlayer.pause()
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        if let changedText = changedText {
            textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
    }
    
    func startTracking()
    {
        guard track else {
            return
        }
        
        globals.mediaPlayer.play()
        
        if trackingTimer == nil {
            trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TextViewController.follow), userInfo: nil, repeats: true)
        } else {
            print("ERROR: trackingTimer not NIL!")
        }
    }
    
    func follow()
    {
        guard let following = following else {
            return
        }
        
        if let seconds = globals.mediaPlayer.currentTime?.seconds {
            var index = 0
            
            for element in following {
                if let startTime = element["start"] as? Double {
                    if seconds < startTime {
                        break
                    }
                }
                
                index += 1
            }
            index -= 1
            
            index = max(index,0)
            
            if let text = (following[index]["text"] as? String), let range = changedText?.range(of: text) {
                if range != oldRange {
                    if  let before = changedText?.substring(to: range.lowerBound),
                        let text = changedText?.substring(with: range),
                        let after = changedText?.substring(from: range.upperBound) {
                        let beforeAttr = NSMutableAttributedString(string: before, attributes: Constants.Fonts.Attributes.normal)
                        let textAttr = NSMutableAttributedString(string: text, attributes: Constants.Fonts.Attributes.marked)
                        let afterAttr = NSMutableAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal)
                        
                        beforeAttr.append(textAttr)
                        beforeAttr.append(afterAttr)
                        
                        textView.attributedText = beforeAttr
                        
                        textView.scrollToRange(range)
                    }
                    
                    oldRange = range
                }
            } else {
                if let text = following[index]["text"] {
                    print("RANGE NOT FOUND: ",text)
                } else {
                    print("RANGE NOT FOUND")
                }
            }
        }
    }
    
    var wasTracking : Bool?
    var wasPlaying : Bool?
    
    func tracking()
    {
        isTracking = !isTracking
    }
    
    var track = false
    {
        didSet {
            if track {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.following = self?.transcript?.following
                }
            }
        }
    }
    
    var isTracking = false
    {
        didSet {
            if isTracking != oldValue {
                if !isTracking {
                    oldRange = nil
                    syncButton.title = "Sync"
                    stopTracking()
                    restoreAssist()
                }
                
                if isTracking {
                    syncButton.title = "Stop"
                    startTracking()
                    removeAssist()
                }
            }
        }
    }
    
    var trackingTimer : Timer?

    var assist = false

    func done()
    {
        if text != textView.attributedText.string, let confirmationTitle = confirmationTitle,let needConfirmation = confirmation?(), needConfirmation {
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Yes", style: .destructive, action: { (Void) -> (Void) in
                if self.isTracking {
                    self.stopTracking()
                }
                self.dismiss(animated: true, completion: nil)
                self.completion?(self.textView.attributedText.string)
            }))
            
            actions.append(AlertAction(title: "No", style: .default, action:nil))
            
            alert(viewController:self,title:confirmationTitle, message:self.confirmationMessage, actions:actions)
        } else {
            if isTracking {
                stopTracking()
            }
            dismiss(animated: true, completion: nil)
            completion?(textView.attributedText.string)
        }
    }
    
    func cancel()
    {
        if isTracking {
            stopTracking()
        }
        dismiss(animated: true, completion: nil)
        onCancel?()
    }
    
    let operationQueue = OperationQueue()
    
    func autoEdit()
    {
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, action: {
            let text = self.textView.attributedText.string
            
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: true, text: text, startingRange: nil, masterChanges: self.masterChanges(interactive: true), completion: { (string:String) -> (Void) in
                    self.changedText = string
                    self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                })

                self.operationQueue.waitUntilAllOperationsAreFinished()
//                while self.operationQueue.operationCount > 0 {
//
//                }

                return nil
            }) { (data:Any?) in
                
            }
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, action: {
            let text = self.textView.attributedText.string
            
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: false, text: text, startingRange: nil, masterChanges: self.masterChanges(interactive: false), completion: { (string:String) -> (Void) in
                    self.changedText = string
                    self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                })
                
                self.operationQueue.waitUntilAllOperationsAreFinished()
//                while self.operationQueue.operationCount > 0 {
//                    
//                }

                return nil
            }) { (data:Any?) in
                
            }
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: nil))
        
        alert(viewController:self,title:"Start Assisted Editing?",message:nil,actions:actions)
    }

    var cancelButton : UIBarButtonItem!
    var saveButton : UIBarButtonItem!
    var assistButton : UIBarButtonItem!
    
    var keyboardShowing = false
    var shrink:CGFloat = 0.0

    func keyboardWillShow(_ notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if !keyboardShowing {
                shrink = keyboardSize.height
                textView.frame.size.height -= keyboardSize.height
            } else {
                if (keyboardSize.height != shrink) {
                    let delta = shrink - keyboardSize.height
                    shrink -= delta
                    if delta != 0 {
                        textView.frame.size.height += delta
                    }
                }
            }
        }
        
        keyboardShowing = true
    }
    
    func keyboardWillHide(_ notification: NSNotification)
    {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if keyboardShowing {
                textView.frame.size.height += keyboardSize.height
            }
        }
        
        keyboardShowing = false
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TextViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TextViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        syncButton = UIBarButtonItem(title: "Sync", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.tracking))
        syncButton.isEnabled = false
        
        cancelButton = UIBarButtonItem(title: Constants.Strings.Cancel, style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.cancel))
        
        if (globals.mediaPlayer.mediaItem != transcript?.mediaItem) || (transcript?.mediaItem?.playing != transcript?.purpose) {
            track = false
        }
        
        if !search {
            searchBar.removeFromSuperview()
            textViewToTop.constant = 14
        }
        
        navigationItem.leftBarButtonItem = cancelButton

        if track {
            if navigationItem.leftBarButtonItems != nil {
                navigationItem.leftBarButtonItems?.append(syncButton)
            } else {
                navigationItem.leftBarButtonItem = syncButton
            }
        }

        saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.done))
        assistButton = UIBarButtonItem(title: "Assist", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.autoEdit))
        
        navigationItem.rightBarButtonItem = saveButton
        
        if assist {
            if navigationItem.rightBarButtonItems != nil {
                navigationItem.rightBarButtonItems?.append(assistButton)
            } else {
                navigationItem.rightBarButtonItem = assistButton
            }
        }
    }
    
    var mask = false
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if !globals.splitViewController.isCollapsed, navigationController?.modalPresentationStyle == .overCurrentContext {
            var vc : UIViewController?
            
            if presentingViewController == globals.splitViewController.viewControllers[0] {
                vc = globals.splitViewController.viewControllers[1]
            }
            
            if presentingViewController == globals.splitViewController.viewControllers[1] {
                vc = globals.splitViewController.viewControllers[0]
            }
            
            mask = true
            
            if let vc = vc {
                process(viewController:vc,disableEnable:false,hideSubviews:true,work:{ (Void) -> Any? in
                    // Why are we doing this?
                    while self.mask {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    return nil
                },completion:{ (data:Any?) -> Void in
                    
                })
            }
        }
        
        searchBar.text = searchText
        searchBar.isUserInteractionEnabled = searchInteractive

        if let changedText = changedText {
            self.textView.attributedText = NSMutableAttributedString(string: changedText,attributes: Constants.Fonts.Attributes.normal)
        }
    }
    
    func words() -> [String:String]?
    {
        return [
            "scripture":"Scripture",
             "Chapter":"chapter",
             "Verse":"verse",
             "Grace":"grace",
             "Gospel":"gospel",
             "vs":"verses",
             "versus":"verses",
             "pilot":"Pilate",
             "OK":"okay"
        ]
    }
    
    func books() -> [String:String]?
    {
        return [
            "first samuel"           :"1 Samuel",
            "second samuel"          :"2 Samuel",
            
            "first kings"            :"1 Kings",
            "second kings"           :"2 Kings",
            
            "first chronicles"       :"1 Chronicles",
            "second chronicles"      :"2 Chronicles",
            
            "first corinthians"      :"1 Corinthians",
            "second corinthians"     :"2 Corinthians",
            
            "first thessalonians"    :"1 Thessalonians",
            "second thessalonians"   :"2 Thessalonians",
            
            "first timothy"          :"1 Timothy",
            "second timothy"         :"2 Timothy",
            
            "first peter"             :"1 Peter",
            "second peter"            :"2 Peter",
            
            "first john"      :"1 John",
            "second john"     :"2 John",
            "third john"      :"3 John"
        ]
    }

    func textToNumbers() -> [String:String]?
    {
        var textToNumbers = [String:String]()
        
        let singleNumbers = [
           "one"        :"1",
           "two"        :"2",
           "three"      :"3",
           "four"       :"4",
           "five"       :"5",
           "six"        :"6",
           "seven"      :"7",
           "eight"      :"8",
           "nine"       :"9"
        ]
        
        let teenNumbers = [
           "ten"        :"10",
           "eleven"     :"11",
           "twelve"     :"12",
           "thirteen"   :"13",
           "fourteen"   :"14",
           "fifteen"    :"15",
           "sixteen"    :"16",
           "seventeen"  :"17",
           "eighteen"   :"18",
           "nineteen"   :"19"
        ]
            
        let decades = [
           "twenty"     :"20",
           "thirty"     :"30",
           "forty"      :"40",
           "fifty"      :"50",
           "sixty"      :"60",
           "seventy"    :"70",
           "eighty"     :"80",
           "ninety"     :"90"
        ]
        
        let centuries = [
           "one hundred"     :"100"
        ]
        
        for key in singleNumbers.keys {
            textToNumbers[key] = singleNumbers[key]
        }
        
        for key in teenNumbers.keys {
            textToNumbers[key] = teenNumbers[key]
        }
        
        for key in decades.keys {
            textToNumbers[key] = decades[key]
        }
        
        for key in centuries.keys {
            textToNumbers[key] = centuries[key]
        }
        
        for hundred in ["one"] {
            for teenNumbersKey in teenNumbers.keys {
                if let num = teenNumbers[teenNumbersKey] {
                    let key = hundred + " " + teenNumbersKey
                    
                    let value = "1" + num
                    
                    textToNumbers[key] = value
                }
            }
            
            for decadesKey in decades.keys {
                if let num = decades[decadesKey] {
                    let key = hundred + " " + decadesKey
                    let value = "1" + num
                    
                    textToNumbers[key] = value
                    
                    if decadesKey != "ten" {
                        for singleNumbersKey in singleNumbers.keys {
                            let key = hundred + " " + decadesKey + " " + singleNumbersKey
                            
                            if let decade = decades[decadesKey]?.replacingOccurrences(of:"0",with:""), let singleNumber = singleNumbers[singleNumbersKey] {
                                let value = "1" + decade + singleNumber
                                textToNumbers[key] = value
                            }
                        }
                    }
                }
            }
        }
        
        for decade in decades.keys {
            for singleNumber in singleNumbers.keys {
                let key = (decade + " " + singleNumber)
                if  let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                    let singleNumber = singleNumbers[singleNumber] {
                    let value = decade + singleNumber
                    textToNumbers[key] = value
                }
            }
        }
        
        for century in centuries.keys {
            for singleNumber in singleNumbers.keys {
                let key = (century + " " + singleNumber)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
                    let singleNumber = singleNumbers[singleNumber] {
                    let value = century + singleNumber
                    textToNumbers[key] = value
                }
            }
            for teenNumber in teenNumbers.keys {
                let key = (century + " " + teenNumber)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let teenNumber = teenNumbers[teenNumber] {
                    let value = century + teenNumber
                    textToNumbers[key] = value
                }
            }
        }
        
        for century in centuries.keys {
            for decade in decades.keys {
                let key = (century + " " + decade)
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let decade = decades[decade] {
                    let value = century + decade
                    textToNumbers[key] = value
                }
            }
        }
        
        for century in centuries.keys {
            for decade in decades.keys {
                for singleNumber in singleNumbers.keys {
                    let key = (century + " " + decade + " " + singleNumber)
                    if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                        let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                        let singleNumber = singleNumbers[singleNumber]
                    {
                        let value = (century + decade + singleNumber)
                        textToNumbers[key] = value
                    }
                }
            }
        }

        return textToNumbers.count > 0 ? textToNumbers : nil
    }
    
    func masterChanges(interactive: Bool) -> [String:[String:String]]?
    {
        guard let textToNumbers = textToNumbers() else {
            return nil
        }
        
        guard let books = books() else {
            return nil
        }
        
        var changes = [String:[String:String]]()
        
        changes["words"] = words()
        changes["books"] = books
        
        if interactive {
            changes["textToNumbers"] = textToNumbers
        }
        
        // These should really be hierarchical.
        for key in textToNumbers.keys {
            if let value = textToNumbers[key] {
                for context in ["verse","verses","chapter","chapters"] {
                    if changes[context] == nil {
                        changes[context] = ["\(context) " + key:"\(context) " + value]
                    } else {
                        changes[context]?["\(context) " + key] = "\(context) " + value
                    }
                }
                
                for book in books.keys {
                    if let bookName = books[book], let index = Constants.OLD_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                    
                    if let bookName = books[book], let index = Constants.NEW_TESTAMENT_BOOKS.index(of: bookName) {
                        if Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book] == nil {
                                changes[book] = ["\(book) " + key:"\(bookName) " + value]
                            } else {
                                changes[book]?["\(book) " + key] = "\(bookName) " + value
                            }
                        }
                    }
                }
                
                for book in Constants.OLD_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.OLD_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {
                    
                    }
                }
                
                for book in Constants.NEW_TESTAMENT_BOOKS {
                    if !books.values.contains(book) {
                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book), Int(value) <= Constants.NEW_TESTAMENT_CHAPTERS[index] {
                            if changes[book.lowercased()] == nil {
                                changes[book.lowercased()] = ["\(book.lowercased()) " + key:"\(book) " + value]
                            } else {
                                changes[book.lowercased()]?["\(book.lowercased()) " + key] = "\(book) " + value
                            }
                        }
                    } else {

                    }
                }
            }
        }
        
        return changes.count > 0 ? changes : nil
    }
    
    func changeText(interactive:Bool,text:String?,startingRange : Range<String.Index>?,masterChanges:[String:[String:String]]?,completion:((String)->(Void))?)
    {
        guard var masterChanges = masterChanges, masterChanges.count > 0 else {
            if !automatic {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: {
                    
                }))
                
                globals.alert(category:nil,title:"Assisted Editing Process Completed",message:nil,attributedText: nil, actions: actions)
            } else {
                Thread.onMainThread {
                    self.dismiss(animated: true, completion: nil)
                    self.completion?(self.textView.attributedText.string)
                }
                
                self.automaticCompletion?()
            }
            return
        }
        
        let keyOrder = ["words","textToNumbers","books","verse","verses","chapter","chapters"]
        
        let masterKeys = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
            let firstIndex = keyOrder.index(of: first)
            let secondIndex = keyOrder.index(of: second)
            
            if let firstIndex = firstIndex, let secondIndex = secondIndex {
                return firstIndex > secondIndex
            }
            
            if firstIndex != nil {
                return false
            }
            
            if secondIndex != nil {
                return true
            }
            
            return first.endIndex > second.endIndex
        })
        
        guard var text = text else {
            return
        }
        
        for masterKey in masterKeys {
            if !["words","books","textToNumbers"].contains(masterKey) {
                if !text.lowercased().contains(masterKey.lowercased()) {
                    masterChanges[masterKey] = nil
                }
            }
        }
        
        guard let masterKey = masterChanges.keys.sorted(by: { (first:String, second:String) -> Bool in
            let firstIndex = keyOrder.index(of: first)
            let secondIndex = keyOrder.index(of: second)
            
            if let firstIndex = firstIndex, let secondIndex = secondIndex {
                return firstIndex > secondIndex
            }
            
            if firstIndex != nil {
                return false
            }
            
            if secondIndex != nil {
                return true
            }
            
            return first.endIndex > second.endIndex
        }).first else {
            return
        }
        
//        guard var changes = masterChanges[masterKey] else {
//            return
//        }
        
        guard var key = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first else {
            return
        }
        
        var range : Range<String.Index>?
        
//        print(changes)
//        print(changes?.count)
        
//        print(masterKey,key,masterChanges[masterKey]?[key])
        
        if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
            if startingRange == nil {
                range = text.lowercased().range(of: key)
            } else {
                range = text.lowercased().range(of: key, options: [], range:  startingRange, locale: nil)
            }
        } else {
            if startingRange == nil {
                range = text.range(of: key)
            } else {
                range = text.range(of: key, options: [], range:  startingRange, locale: nil)
            }
        }
        
        while range == nil {
            masterChanges[masterKey]?[key] = nil
            
            if let first = masterChanges[masterKey]?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first {
                key = first
                
                if (key == key.lowercased()) && (key.lowercased() != masterChanges[masterKey]?[key]?.lowercased()) {
                    range = text.lowercased().range(of: key)
                } else {
                    range = text.range(of: key)
                }
            } else {
                break
            }
        }
        
        if let range = range, let value = masterChanges[masterKey]?[key] {
            let attributedString = NSMutableAttributedString()
            
            let before = "..." + String(text.substring(to: range.lowerBound).dropFirst(max(text.substring(to: range.lowerBound).count - 10,0)))
            let string = text.substring(with: range)
            let after = String(text.substring(from: range.upperBound).dropLast(max(text.substring(from: range.upperBound).count - 10,0))) + "..."
            
            attributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.normal))
            attributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
            attributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal))
            
            let prior = text.substring(to: range.lowerBound).last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            let following = text.substring(from: range.upperBound).first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if (prior?.isEmpty ?? true) && ((following?.isEmpty ?? true) || (following == ".")) {
                if interactive {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: "Yes", style: .destructive, action: {
                        text.replaceSubrange(range, with: value)
                        
                        completion?(text)
                        
                        let before = text.substring(to: range.lowerBound)
                        
                        if let completedRange = text.range(of: before + value) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                        } else {
                            // ERROR
                        }
                    }))
                    
                    actions.append(AlertAction(title: "No", style: .default, action: {
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                    }))
                    
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: {
                        
                    }))
                    
                    globals.alert(category:nil,title:"Change \"\(string)\" to \"\(value)\"?",message:nil,attributedText:attributedString,actions:actions)
                } else {
                    text.replaceSubrange(range, with: value)
                    
                    Thread.onMainThread {
                        completion?(text)
                    }
                    
                    operationQueue.addOperation {
                        let before = text.substring(to: range.lowerBound)
                        
                        if let completedRange = text.range(of: before + value) {
                            let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                        } else {
                            // ERROR
                        }
                    }
                }
            } else {
                if interactive {
                    let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                    self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                } else {
                    operationQueue.addOperation {
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        self.changeText(interactive:interactive,text:text,startingRange:startingRange,masterChanges:masterChanges,completion:completion)
                    }
                }
            }
        } else {
            if interactive {
                print(key)
                masterChanges[masterKey]?[key] = nil
                if masterChanges[masterKey]?.count == 0 {
                    print(masterKey)
                    masterChanges[masterKey] = nil
                }
                self.changeText(interactive:interactive,text:text,startingRange:nil,masterChanges:masterChanges,completion:completion)
            } else {
                operationQueue.addOperation {
                    masterChanges[masterKey]?[key] = nil
                    if masterChanges[masterKey]?.count == 0 {
                        masterChanges[masterKey] = nil
                    }
                    self.changeText(interactive:interactive,text:text,startingRange:nil,masterChanges:masterChanges,completion:completion)
                }
            }
        }
    }
    
//    func changes(interactive: Bool)
//    {
//        if let hierarchicalChanges = heirarchicalChanges() {
//            for hierarchicalChange in hierarchicalChanges.keys {
//                print(hierarchicalChange)
//                if self.textView.attributedText.string.lowercased().contains(hierarchicalChange), let hierarchicalChanges = hierarchicalChanges[hierarchicalChange] {
//                    self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: hierarchicalChanges, completion: { (string:String) -> (Void) in
//                        self.changedText = string
//                        self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
//                    })
//                    
//                    while self.operationQueue.operationCount > 0 {
//                        
//                    }
//                }
//            }
//        }
//        
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.textToNumbers(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
////
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.books(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
////
////        self.changeText(interactive: interactive, text: self.textView.attributedText.string, startingRange: nil, changes: self.words(), completion: { (string:String) -> (Void) in
////            self.changedText = string
////            self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
////        })
////        
////        while self.operationQueue.operationCount > 0 {
////            
////        }
//    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        textView.scrollRangeToVisible(NSMakeRange(0, 0))
        
        if automatic {
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: self.automaticInteractive, text: self.textView.attributedText.string, startingRange: nil, masterChanges: self.masterChanges(interactive: self.automaticInteractive), completion: { (string:String) -> (Void) in
                    self.changedText = string
                    self.textView.attributedText = NSMutableAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
                })
                
                self.operationQueue.waitUntilAllOperationsAreFinished()
//                while self.operationQueue.operationCount > 0 {
//                    
//                }

                return nil
            }) { (data:Any?) in
//                self.dismiss(animated: true, completion: nil)
//                self.completion?(self.textView.text)
//                self.automaticCompletion?()
            }
        } else {
//            if track {
//                follow()
//            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        mask = false
        
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)

    }
}

