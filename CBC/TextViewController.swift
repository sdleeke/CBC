//
//  TextViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/8/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit

class TextViewController : UIViewController
{
    var text : String?
    {
        didSet {
            
        }
    }
    
    var completion : ((String)->(Void))?
    
    var onCancel : ((Void)->(Void))?
    
    @IBOutlet weak var textView: UITextView!
    
    func done()
    {
        dismiss(animated: true, completion: nil)
        completion?(textView.text)
    }
    
    func cancel()
    {
        dismiss(animated: true, completion: nil)
        onCancel?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.cancel))

        textView.text = text
    }
    
    func autoEdit()
    {
        var changes = ["Scripture":"scripture",
                      "Chapter":"chapter",
                      "Verse":"verse",
                      "Grace":"grace",
                      "Gospel":"gospel"]
        
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
        
//        print(changes)
        
        var changed = [Range<String.Index>]()
        
        for key in changes.keys.sorted(by: { $0.endIndex > $1.endIndex }) {
            if key == "Chapter" {
                print("")
            }
            var oldRange : Range<String.Index>?
            var range : Range<String.Index>?
            
            if key == key.lowercased() {
                range = self.textView.text.lowercased().range(of: key)
            } else {
                range = self.textView.text.range(of: key)
            }
            
            while (range != nil) && (range != oldRange) {
                if  let range = range,
                    changed.filter({ (changedRange:Range<String.Index>) -> Bool in
                        return changedRange.overlaps(range)
                    }).count == 0,
                    let value = changes[key] {
                    let text = NSMutableAttributedString()
                    
                    let before = "..." + String(textView.text.substring(to: range.lowerBound).characters.dropFirst(max(textView.text.substring(to: range.lowerBound).characters.count - 7,0)))
                    let after = String(textView.text.substring(from: range.upperBound).characters.dropLast(max(textView.text.substring(from: range.upperBound).characters.count - 7,0))) + "..."
                    
                    text.append(NSAttributedString(string: before,                              attributes: Constants.Fonts.Attributes.normal))
                    text.append(NSAttributedString(string: textView.text.substring(with: range),attributes: Constants.Fonts.Attributes.highlighted))
                    text.append(NSAttributedString(string: after,                               attributes: Constants.Fonts.Attributes.normal))
                    
                    let prior = self.textView.text.substring(to: range.lowerBound).characters.last?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let following = self.textView.text.substring(from: range.upperBound).characters.first?.description.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if ((prior == nil) || prior!.isEmpty) && ((following == nil) || following!.isEmpty) {
                        var actions = [AlertAction]()
                        
                        actions.append(AlertAction(title: "Yes", style: .destructive, action: {
                            self.textView.text.replaceSubrange(range, with: value)
//                            if let range = self.textView.text.lowercased().range(of: key) {
//                            }
                        }))
                        
                        actions.append(AlertAction(title: "No", style: .default, action: nil))
                        
//                        actions.append(AlertAction(title: "Cancel", style: .default, action: nil))
                        
                        changed.append(range)
                        
                        globals.alert(title:"Change \"\(key)\" to \"\(value)\"?",message:nil,attributedText:text,actions:actions)
                    }
                }
                
                if range != nil {
                    oldRange = range
                    
                    let searchRange = Range(uncheckedBounds: (lower: range!.upperBound, upper: textView.text.endIndex))
                    
                    if key == key.lowercased() {
                        range = self.textView.text.lowercased().range(of: key, options: [], range:  searchRange, locale: nil)
                    } else {
                        range = self.textView.text.range(of: key, options: [], range:  searchRange, locale: nil)
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        autoEdit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
}

extension TextViewController : UITextViewDelegate
{
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    {
        // Asks the delegate if editing should begin in the specified text view.
        
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

    }
    
    func textView(_ shouldChangeTextIn: NSRange, replacementText: String)
    {
        // Asks the delegate whether the specified text should be replaced in the text view.
        
    }

    func textViewDidChange(_ textView: UITextView)
    {
        // Tells the delegate that the text or attributes in the specified text view were changed by the user.
        
    }
    
    func textViewDidChangeSelection(_ textView: UITextView)
    {
        // Tells the delegate that the text selection changed in the specified text view.
        
    }
}
