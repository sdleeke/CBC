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
