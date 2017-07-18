//
//  TextViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/8/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit

extension TextViewController: UISearchBarDelegate
{
    //MARK: SearchBarDelegate
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarShouldBeginEditing",completion:nil)
            return false
        }
        
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        searchActive = true
        
        searchBar.showsCancelButton = true
        
        searchText = searchBar.text
        
        if let searchText = searchText {
            textView.attributedText = stringMarkedBySearchAsAttributedString(string: textView.text, searchText: searchText, wholeWordsOnly: false)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        self.searchText = searchText

        if !searchText.isEmpty {
            textView.attributedText = stringMarkedBySearchAsAttributedString(string: text, searchText: searchText, wholeWordsOnly: false)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        //        print("searchBarSearchButtonClicked:")
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchText = searchBar.text
        
        searchBar.resignFirstResponder()
        
        textView.attributedText = stringMarkedBySearchAsAttributedString(string: text, searchText: searchText, wholeWordsOnly: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false
        
        textView.attributedText = nil
        textView.text = changedText
        
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
        
        textView.attributedText = nil
        textView.text = changedText
        
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
            textView.attributedText = stringMarkedBySearchAsAttributedString(string: text, searchText: searchText, wholeWordsOnly: false)
        }
    }
    
    func textView(_ shouldChangeTextIn: NSRange, replacementText: String)
    {
        // Asks the delegate whether the specified text should be replaced in the text view.

    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // Tells the delegate that the text or attributes in the specified text view were changed by the user.
    
        changedText = textView.text
    }
    
    func textViewDidChangeSelection(_ textView: UITextView)
    {
        // Tells the delegate that the text selection changed in the specified text view.
        
    }
}

class TextViewController : UIViewController
{
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

    var search              = false
    var searchActive        = false
    var wholeWordsOnly      = false
    var searchInteractive   = true

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    @IBOutlet weak var textViewToTop: NSLayoutConstraint!
    
    var automatic = false
    var automaticInteractive = false
    var automaticCompletion : ((Void)->(Void))?
    
    var completion : ((String)->(Void))?
    
    var confirmation : ((Void)->Bool)?
    var confirmationTitle : String?
    var confirmationMessage : String?

    var onCancel : ((Void)->(Void))?
    
    @IBOutlet weak var textView: UITextView!
    
    func done()
    {
        if text != textView.text, let confirmationTitle = confirmationTitle,let needConfirmation = confirmation?(), needConfirmation {
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Yes", style: .destructive, action: { (Void) -> (Void) in
                self.dismiss(animated: true, completion: nil)
                self.completion?(self.textView.text)
            }))
            
            actions.append(AlertAction(title: "No", style: .default, action:nil))
            
            alert(viewController:self,title:confirmationTitle, message:self.confirmationMessage, actions:actions)
        } else {
            dismiss(animated: true, completion: nil)
            completion?(textView.text)
        }
    }
    
    func cancel()
    {
        dismiss(animated: true, completion: nil)
        onCancel?()
    }
    
    let operationQueue = OperationQueue()
    
    func autoEdit()
    {
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, action: {
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: true, text: self.textView.text, startingRange: nil, changes: self.changes(), completion: { (string:String) -> (Void) in
                    self.textView.text = string
                })
                
                return nil
            }) { (data:Any?) in
                
            }
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, action: {
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: false, text: self.textView.text, startingRange: nil, changes: self.changes(), completion: { (string:String) -> (Void) in
                    self.textView.text = string
                })
                
                while self.operationQueue.operationCount > 0 {
                    
                }
                
                return nil
            }) { (data:Any?) in
                
            }
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: nil))
        
        alert(viewController:self,title:"Start Assisted Editing?",message:nil,actions:actions)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if !search {
            searchBar.removeFromSuperview()
            textViewToTop.constant = 14
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.rightBarButtonItems = [  UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.done)),
                                                UIBarButtonItem(title: "Assist", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.autoEdit))]
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Constants.Strings.Cancel, style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.cancel))
        
        searchBar.text = searchText
        searchBar.isUserInteractionEnabled = searchInteractive

        textView.text = text
    }
    
    func changes() -> [String:String]?
    {
        var changes = ["scripture":"Scripture",
                      "Chapter":"chapter",
                      "Verse":"verse",
                      "Grace":"grace",
                      "Gospel":"gospel",
                      "versus":"verses",
                      "OK":"okay"]
        
        let books = [
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
        
//        var textToNumbers = [String:String]()
        
        for key in books.keys {
            changes[key] = books[key]
        }
        
        for key in singleNumbers.keys {
            changes[key] = singleNumbers[key]
        }
        
        for key in teenNumbers.keys {
            changes[key] = teenNumbers[key]
        }
        
        for key in decades.keys {
            changes[key] = decades[key]
        }
        
        for key in centuries.keys {
            changes[key] = centuries[key]
        }
        
        for decade in decades.keys {
            for singleNumber in singleNumbers.keys {
                let key = (decade + " " + singleNumber) //.replacingOccurrences(of: "  ", with: " ")
                if  let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""),
                    let singleNumber = singleNumbers[singleNumber] //?.replacingOccurrences(of: " ", with: "")
                {
                    let value = decade + singleNumber //+ " "
                    changes[key] = value
//                    print(key,value)
                }
            }
        }
        
        for century in centuries.keys {
            for singleNumber in singleNumbers.keys {
                let key = (century + " " + singleNumber) //.replacingOccurrences(of: "  ", with: " ")
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: "0"),
                    let singleNumber = singleNumbers[singleNumber] //?.replacingOccurrences(of: " ", with: "")
                    {
                    let value = century + singleNumber //+ " "
                    changes[key] = value
//                    print(key,value)
                }
            }
            for teenNumber in teenNumbers.keys {
                let key = (century + " " + teenNumber) //.replacingOccurrences(of: "  ", with: " ")
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let teenNumber = teenNumbers[teenNumber] //?.replacingOccurrences(of: " ", with: "")
                    {
                    let value = century + teenNumber //+ " "
                    changes[key] = value
//                    print(key,value)
                }
            }
        }
        
        for century in centuries.keys {
            for decade in decades.keys {
                let key = (century + " " + decade) //.replacingOccurrences(of: "  ", with: " ")
                if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                    let decade = decades[decade] //?.replacingOccurrences(of: " ", with: "")
                {
                    let value = century + decade //+ " "
                    changes[key] = value
//                    print(key,value)
                }
            }
        }
        
        for century in centuries.keys {
            for decade in decades.keys {
                for singleNumber in singleNumbers.keys {
                    let key = (century + " " + decade + " " + singleNumber) //.replacingOccurrences(of: "  ", with: " ")
                    if  let century = centuries[century]?.replacingOccurrences(of: "00", with: ""),
                        let decade = decades[decade]?.replacingOccurrences(of: "0", with: ""), //.replacingOccurrences(of: " ", with: ""),
                        let singleNumber = singleNumbers[singleNumber] //?.replacingOccurrences(of: " ", with: "")
                    {
                        let value = (century + decade + singleNumber) //+ " "
                        changes[key] = value
//                        print(key,value)
                    }
                }
            }
        }
//        
//        changeText(interactive:interactive,text: textView.text, startingRange: nil, changes: changes, completion: { (string:String) in
//            self.textView.text = string
//        })
        
        return changes
    }
    
    func changeText(interactive:Bool,text:String?,startingRange : Range<String.Index>?,changes:[String:String]?,completion:((String)->(Void))?)
    {
        var range : Range<String.Index>?
        
//        print(changes)
//        print(changes?.count)
        
        if var text = text,var changes = changes,var key = changes.keys.sorted(by: { $0.endIndex > $1.endIndex }).first {
            if (key == key.lowercased()) && (key.lowercased() != changes[key]?.lowercased()) {
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
                changes[key] = nil
                
                if let first = changes.keys.sorted(by: { $0.endIndex > $1.endIndex }).first {
                    key = first
                    
//                    print(key)
                    if (key == key.lowercased()) && (key.lowercased() != changes[key]?.lowercased()) {
                        range = text.lowercased().range(of: key)
                    } else {
                        range = text.range(of: key)
                    }
                } else {
                    break
                }
            }
            
            if let range = range, let value = changes[key] {
                let attributedString = NSMutableAttributedString()
                
                let before = "..." + String(text.substring(to: range.lowerBound).characters.dropFirst(max(text.substring(to: range.lowerBound).characters.count - 10,0)))
                let string = text.substring(with: range)
                let after = String(text.substring(from: range.upperBound).characters.dropLast(max(text.substring(from: range.upperBound).characters.count - 10,0))) + "..."
                
                attributedString.append(NSAttributedString(string: before,attributes: Constants.Fonts.Attributes.normal))
                attributedString.append(NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.highlighted))
                attributedString.append(NSAttributedString(string: after, attributes: Constants.Fonts.Attributes.normal))
                
                let prior = text.substring(to: range.lowerBound).characters.last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let following = text.substring(from: range.upperBound).characters.first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                if ((prior == nil) || prior!.isEmpty) && ((following == nil) || following!.isEmpty || (following == ".")) {
                    if interactive {
                        var actions = [AlertAction]()
                        
                        actions.append(AlertAction(title: "Yes", style: .destructive, action: {
                            text.replaceSubrange(range, with: value)

                            completion?(text)
                            
                            let before = text.substring(to: range.lowerBound)
                            
                            if let completedRange = text.range(of: before + value) {
                                let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                                self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
                            } else {
                                // ERROR
                            }
                        }))
                        
                        actions.append(AlertAction(title: "No", style: .default, action: {
                            let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
                        }))
                        
                        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: {
                            
                        }))
                        
                        globals.alert(category:nil,title:"Change \"\(string)\" to \"\(value)\"?",message:nil,attributedText:attributedString,actions:actions)
                    } else {
                        text.replaceSubrange(range, with: value)
                        
                        DispatchQueue.main.async {
                            completion?(text)
                        }

                        let operation = BlockOperation(block: {
                            let before = text.substring(to: range.lowerBound)
                            
                            if let completedRange = text.range(of: before + value) {
                                let startingRange = Range(uncheckedBounds: (lower: completedRange.upperBound, upper: text.endIndex))
                                self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
                            } else {
                                // ERROR
                            }
                        })
//                        operation.name = ""
                        operationQueue.addOperation(operation)
                        
//                        globals.queue.async(execute: { () -> Void in
//                            // Must start over (startingRange == nil) to avoid skipping
//                            self.changeText(interactive:interactive,text:text,startingRange:nil,changes:changes,completion:completion)
//                        })
                    }
                } else {
                    if interactive {
                        let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                        self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
                    } else {
                        let operation = BlockOperation(block: {
                            let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
                        })
                        //                        operation.name = ""
                        operationQueue.addOperation(operation)
                        
//                        globals.queue.async(execute: { () -> Void in
//                            let startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: text.endIndex))
//                            self.changeText(interactive:interactive,text:text,startingRange:startingRange,changes:changes,completion:completion)
//                        })
                    }
                }
            } else {
                if interactive {
                    changes[key] = nil
                    self.changeText(interactive:interactive,text:text,startingRange:nil,changes:changes,completion:completion)
                } else {
                    let operation = BlockOperation(block: {
                        changes[key] = nil
                        self.changeText(interactive:interactive,text:text,startingRange:nil,changes:changes,completion:completion)
                    })
                    //                        operation.name = ""
                    operationQueue.addOperation(operation)
                    
//                    globals.queue.async(execute: { () -> Void in
//                        changes[key] = nil
//                        self.changeText(interactive:interactive,text:text,startingRange:nil,changes:changes,completion:completion)
//                    })
                }
            }
        } else {
            print(text as Any)
            print(changes as Any)
            print(changes?.keys.sorted(by: { $0.endIndex > $1.endIndex }).first as Any)
            
            if !automatic {
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: {
                    
                }))
                
                globals.alert(category:nil,title:"Assisted Editing Process Completed",message:nil,attributedText: nil, actions: actions)
            } else {
                if Thread.isMainThread {
                    self.dismiss(animated: true, completion: nil)
                    self.completion?(self.textView.text)
                } else {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                        self.completion?(self.textView.text)
                    }
                }
                
                self.automaticCompletion?()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.scrollRangeToVisible(NSMakeRange(0, 0))
        
        if automatic {
            process(viewController: self, work: { () -> (Any?) in
                self.changeText(interactive: self.automaticInteractive, text: self.textView.text, startingRange: nil, changes: self.changes(), completion: { (string:String) -> (Void) in
                    self.textView.text = string
                })
                
                while self.operationQueue.operationCount > 0 {
                    
                }
                
                return nil
            }) { (data:Any?) in
//                self.dismiss(animated: true, completion: nil)
//                self.completion?(self.textView.text)
//                self.automaticCompletion?()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
}

