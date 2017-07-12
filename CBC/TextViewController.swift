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
    
    @IBOutlet weak var textView: UITextView!
    
    func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func cancel()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(TextViewController.cancel))

        textView.text = text
    }
    
    func autoEdit()
    {
        if textView.text.contains("scripture") {
            let alert = UIAlertController(  title: "Change scripture to Scripture?",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.destructive, handler: {
                alertItem -> Void in
                self.textView.text = self.textView.text.replacingOccurrences(of: "scripture", with: "Scripture")
            })
            alert.addAction(okayAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
                alertItem -> Void in
                
            })
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        if textView.text.contains("Chapter") {
            let alert = UIAlertController(  title: "Change Chapter to chapter?",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.destructive, handler: {
                alertItem -> Void in
                self.textView.text = self.textView.text.replacingOccurrences(of: "Chapter", with: "chapter")
            })
            alert.addAction(okayAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
                alertItem -> Void in
                
            })
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        if textView.text.contains("Verse") {
            let alert = UIAlertController(  title: "Change Verse to verse?",
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.destructive, handler: {
                alertItem -> Void in
                self.textView.text = self.textView.text.replacingOccurrences(of: "Verse", with: "verse")
            })
            alert.addAction(okayAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
                alertItem -> Void in
                
            })
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        let singleNumbers = [
            " one "         :" 1 ",
            " two "         :" 2 ",
            " three "       :" 3 ",
            " four "        :" 4 ",
            " five "        :" 5 ",
            " six "         :" 6 ",
            " seven "       :" 7 ",
            " eight "       :" 8 ",
            " nine "        :" 9 "
        ]
        
        let teenNumbers = [
            " ten "         :" 10 ",
            " eleven "      :" 11 ",
            " twelve "      :" 12 ",
            " thirteen "    :" 13 ",
            " fourteen "    :" 14 ",
            " fifteen "     :" 15 ",
            " sixteen "     :" 16 ",
            " seventeen "   :" 17 ",
            " eighteen "    :" 18 ",
            " nineteen "    :" 19 "
        ]
            
        let decades = [
            " twenty "      :" 20 ",
            " thirty "      :" 30 ",
            " fourty "      :" 40 ",
            " fifty "       :" 50 ",
            " sixty "       :" 60 ",
            " seventy "     :" 70 ",
            " eighty "      :" 80 ",
            " ninety "      :" 90 ",
            " one hundred "     :" 100 "
        ]

        var textToNumbers = [String:String]()
        
        for key in singleNumbers.keys {
            textToNumbers[key] = singleNumbers[key]
        }
        
        for key in teenNumbers.keys {
            textToNumbers[key] = teenNumbers[key]
        }
        
        for key in decades.keys {
            textToNumbers[key] = decades[key]
        }
        
        for decade in decades.keys {
            for singleNumber in singleNumbers.keys {
                let key = (decade + singleNumber).replacingOccurrences(of: "  ", with: " ")
                if let decade = decades[decade]?.replacingOccurrences(of: "0 ", with: ""),let singleNumber = singleNumbers[singleNumber]?.replacingOccurrences(of: " ", with: "") {
                    let value = decade + singleNumber + " "
                    textToNumbers[key] = value
                    print(key,value)
                }
            }
        }
        
        var changes = [String:String]()
        
        for key in textToNumbers.keys.sorted(by: { $0.endIndex > $1.endIndex }) {
            if  changes.keys.filter({ (string:String) -> Bool in
                return string.contains(key.trimmingCharacters(in: CharacterSet.whitespaces))
                }).count == 0,
                textView.text.contains(key), let value = textToNumbers[key] {
                changes[key] = value
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Yes", style: .destructive, action: {
                    self.textView.text = self.textView.text.replacingOccurrences(of: key, with: value)
                }))
                
                actions.append(AlertAction(title: "No", style: .default, action: nil))
                
                globals.alert(title:"Change \"\(key)\" to \"\(value)\"?",message:nil,actions:actions)
            }
        }
        
        for key in textToNumbers.keys.sorted(by: { $0.endIndex > $1.endIndex }) {
            if  changes.keys.filter({ (string:String) -> Bool in
                    return string.contains(key.trimmingCharacters(in: CharacterSet.whitespaces))
                }).count == 0,
                key != " one ",key != " ten ",changes[key] == nil,
                textView.text.contains(key.trimmingCharacters(in: CharacterSet.whitespaces)), let value = textToNumbers[key]?.trimmingCharacters(in: CharacterSet.whitespaces) {
                changes[key.trimmingCharacters(in: CharacterSet.whitespaces)] = value
                
                var actions = [AlertAction]()
                
                actions.append(AlertAction(title: "Yes", style: .destructive, action: {
                    self.textView.text = self.textView.text.replacingOccurrences(of: key.trimmingCharacters(in: CharacterSet.whitespaces), with: value)
                }))
                
                actions.append(AlertAction(title: "No", style: .default, action: nil))
                
                globals.alert(title:"Change \"\(key.trimmingCharacters(in: CharacterSet.whitespaces))\" to \"\(value)\"?",message:nil,actions:actions)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        autoEdit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completion?(textView.text)
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
