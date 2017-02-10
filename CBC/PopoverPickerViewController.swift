//
//  PopoverDatePickerViewController.swift
//  RentBuddy
//
//  Created by Steve Leeke on 5/11/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverPickerControllerDelegate
{
    // MARK: PopoverPickerControllerDelegate Protocol
    
    func stringPicked(_ string:String?)
}

extension PopoverPickerViewController : UIPickerViewDataSource
{
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if mediaListGroupSort != nil {
            var depth = 0
            
            if let depthBelow = root?.depthBelow(0) {
                depth = depthBelow
            }
            //            print("Depth: ",depth)
            return depth
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if mediaListGroupSort != nil {
            var stringNode = root
            
            switch component {
            case 0:
                break
                
            default:
                //                guard (pickerSelections[component-1] != nil) else {
                //                    return 0
                //                }
                
                for i in 0..<component {
                    if let stringNodes = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string }) {
                        pickerSelections[i] = pickerSelections[i] != nil ? pickerSelections[i] : 0
                        
                        if let selection = pickerSelections[i] {
                            if selection < stringNodes.count {
                                stringNode = stringNodes[selection]
                            }
                        }
                    }
                }
                break
            }
            
            if let count = stringNode?.stringNodes?.count {
                //                print("Component: ",component," Rows: ",count)
                return count
                //                if let wordEnding = stringNode?.wordEnding, wordEnding {
                //                    return count + 1
                //                } else {
                //                    return count
                //                }
            } else {
                return 0
            }
        } else {
            return strings != nil ? strings!.count : 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }
        
        let normal = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body) ]
        
        //        let bold = [ NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline) ]
        //
        //        let highlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
        //                            NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body) ]
        //
        //        let boldHighlighted = [ NSBackgroundColorAttributeName: UIColor.yellow,
        //                                NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline) ]
        
        if mediaListGroupSort != nil {
            if let title = title(forRow: row, forComponent: component) {
                label.attributedText = NSAttributedString(string: title,attributes: normal)
            }
        } else {
            if let string = strings?[row] {
                label.attributedText = NSAttributedString(string: string,attributes: normal)
            }
            
            label.textAlignment = .center
        }
        
        return label
        
        //        var label:UILabel!
        //
        //        if view != nil {
        //            label = view as! UILabel
        //        } else {
        //            label = UILabel()
        //        }
        //        
        ////        label.font = UIFont(name: "System", size: 16.0)
        //        label.textAlignment = .center
        //        
        //        label.text = strings?[row]
        //        
        //        return label
    }
    
    func title(forRow row:Int, forComponent component:Int) -> String?
    {
        var stringNode = root
        
        switch component {
        case 0:
            break
            
        default:
            //            guard (pickerSelections[component-1] != nil) else {
            //                return nil
            //            }
            
            for i in 0..<component {
                if let stringNodes = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string }) {
                    pickerSelections[i] = pickerSelections[i] != nil ? pickerSelections[i] : 0
                    
                    if let selection = pickerSelections[i] {
                        if selection < stringNodes.count {
                            stringNode = stringNodes[selection]
                        }
                    }
                }
            }
            break
        }
        
        if let count = stringNode?.stringNodes?.count, row < count {
            //            print("Component: ",component," Row: ",row," String: ",string)
            
            switch count {
            case 0:
                if let string = stringNode?.stringNodes?[row].string {
                    if string != Constants.WORD_ENDING {
                        return string
                    } else {
                        return nil
                    }
                }
                break
                
            default:
                if let string = stringNode?.stringNodes?[row].string {
                    return string
                }
                break
            }
            //            if let wordEnding = stringNode?.wordEnding, wordEnding {
            //            } else {
            //                if let string = stringNode?.stringNodes?[row].string {
            //                    //                        print("Component: ",component," Row: ",row," String: ",string)
            //                    return string
            //                }
            //            }
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if mediaListGroupSort != nil {
            return title(forRow: row,forComponent: component)
        } else {
            return strings?[row]
        }
    }
}

extension PopoverPickerViewController : UIPickerViewDelegate
{
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat
    {
        //        guard component < pickerView.numberOfComponents else {
        //            print(component,pickerView.numberOfComponents)
        //            return 0
        //        }
        
        if mediaListGroupSort != nil {
            var stringNode = root
            
            switch component {
            case 0:
                break
                
            default:
                //                guard (pickerSelections[component-1] != nil) else {
                //                    return 0.0
                //                }
                
                for i in 0..<component {
                    if let stringNodes = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string }) {
                        pickerSelections[i] = pickerSelections[i] != nil ? pickerSelections[i] : 0
                        
                        if let selection = pickerSelections[i] {
                            if selection < stringNodes.count {
                                stringNode = stringNodes[selection]
                            }
                        }
                    }
                }
                break
            }
            
            var width:CGFloat = 0.0
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
            
            if let stringNodes = stringNode?.stringNodes {
                switch stringNodes.count {
                case 0:
                    if let string = stringNodes[0].string {
                        if string != Constants.WORD_ENDING {
                            let stringWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)], context: nil).width
                            if stringWidth > width {
                                width = stringWidth
                            }
                        } else {
                            return 0
                        }
                    }
                    break
                    
                default:
                    for stringNode in stringNodes {
                        if let stringWidth = stringNode.string?.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)], context: nil).width {
                            if stringWidth > width {
                                width = stringWidth
                            }
                        }
                    }
                    break
                }
            }
            
            //            if pickerSelections[component] == nil {
            //                pickerSelections[component] = 0
            ////                DispatchQueue.main.async(execute: { () -> Void in
            //////                    self.picker.reloadAllComponents()
            //////                    self.picker.setNeedsLayout()
            ////                    self.setPreferredContentSize()
            ////                })
            //            }
            
            //            print("Component: ",component," Width: ",width)
            return width + 8
        } else {
            var width:CGFloat = 0.0
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
            
            if let strings = strings {
                for string in strings {
                    //                print(stringNode.string)
                    let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                    
                    let stringWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)], context: nil).width
                    
                    if stringWidth > width {
                        width = stringWidth
                    }
                }
            }
            
            return width + 8
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if mediaListGroupSort != nil {
            pickerSelections[component] = row
            
            //        print(pickerSelections)
            
            DispatchQueue.global(qos: .userInteractive).async {
                self.updatePickerSelections()
                self.updatePicker()
            }
        } else {
            string = strings?[row]
        }
    }
}

class PopoverPickerViewController : UIViewController
{
    var delegate : PopoverPickerControllerDelegate?
    
    var mediaListGroupSort:MediaListGroupSort?
    var pickerSelections = [Int:Int]()
    var root:StringNode?
    
    var lexicon:Lexicon?
    {
        get {
            return mediaListGroupSort?.lexicon
        }
    }
    
    var strings:[String]?
    var string:String?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var selectButton: UIButton!
    
    @IBAction func selectButtonAction(sender: UIButton)
    {
//        print("\(string)")
        delegate?.stringPicked(string)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if mediaListGroupSort != nil {
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
                
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.stringTreeUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.lexicon)
            })
            
            spinner.isHidden = false
            spinner.startAnimating()
            
            root = lexicon?.root

            if (root == nil) || root!.isLeaf {
                print("building")

                lexicon?.build()
                
                lexicon?.buildStringTree()
            } else {
                stringTreeUpdated()
            }
        }
        
//        print(string)
//        print(strings)
        
        if string != nil, let index = strings?.index(of:string!) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        if mediaListGroupSort != nil {
            preferredContentSize = CGSize(width: 200, height: 300)
        } else {
            preferredContentSize = CGSize(width: 300, height: 300)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: nil)
    }
    
    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "PopoverPickerViewController:setPreferredContentSize")
            return
        }
        
        var width:CGFloat = 0
        
        var count:CGFloat = 0
        
        for component in 0..<picker.numberOfComponents {
//            print(component,picker.rowSize(forComponent: component).width)
            
            let componentWidth = pickerView(picker, widthForComponent: component)
            
            if componentWidth > 0 {
                count += 1
            }

            width += componentWidth
            
//            width += picker.rowSize(forComponent: component).width
        }
    
        preferredContentSize = CGSize(width: max(200,width + (4 * count)), height: 300)
    }

    func updatePickerSelections()
    {
        guard root?.stringNodes != nil else {
            return
        }
        
        var stringNode = root
        
        var i = 0
        
        while stringNode != nil {
            if stringNode?.stringNodes == nil {
                pickerSelections[i] = nil
                stringNode = nil
            } else
                
            if pickerSelections[i] >= stringNode!.stringNodes!.count {
                pickerSelections[i] = 0
                stringNode = stringNode?.stringNodes?[0]
            } else {
                if let index = pickerSelections[i] {
                    stringNode = stringNode?.stringNodes?[index]
                } else {
                    stringNode = nil
                }
            }
            
            i += 1
        }
        
        //        print(wordPicker.numberOfComponents)
        
        var index = i
        while index < picker.numberOfComponents {
            pickerSelections[index] = nil
            index += 1
        }
        //        if i < wordPicker.numberOfComponents {
        //            for index in i..<wordPicker.numberOfComponents {
        //                pickerSelections[index] = nil
        //            }
        //        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.picker.setNeedsLayout()
        })
    }
    
    func wordFromPicker() -> String?
    {
        var word:String?
        
        var stringNode = root
        
        var i = 0
        
        while i < pickerSelections.count, pickerSelections[i] != nil {
            if i < pickerSelections.count, let selection = pickerSelections[i] {
                if let stringNodes = stringNode?.stringNodes {
                    if selection < stringNodes.count {
                        let node = stringNodes.sorted(by: { $0.string < $1.string })[selection]
                        
                        if node.string != Constants.WORD_ENDING {
                            stringNode = node
                            
                            if let string = stringNode?.string {
                                word = word != nil ? word! + string : string
                            }
                        }
                    }
                }
            }
            
            i += 1
        }
        
        //        print("wordFromPicker: ",word)
        
        if let wordEnding = stringNode?.wordEnding, wordEnding {
            return word
        } else {
            return nil
        }
    }
    
    func updatePicker()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.picker.reloadAllComponents()
            self.setPreferredContentSize()

            var i = 0
            
            while i < self.picker.numberOfComponents, i < self.pickerSelections.count, self.pickerSelections[i] != nil {
                self.picker.selectRow(self.pickerSelections[i]!,inComponent: i, animated: true)
                i += 1
            }
            
            self.string = self.wordFromPicker()
        })
    }
    
    func stringTreeUpdated()
    {
        root = lexicon?.root
            
        DispatchQueue.global(qos: .userInteractive).async {
            self.updatePickerSelections()
            self.updatePicker()
            
            DispatchQueue.main.async(execute: { () -> Void in
                if let eligible = self.lexicon?.eligible?.count, let depth = self.lexicon?.root?.depthBelow(0) {
                    if eligible == 0,depth > 0 {
                        // Should NEVER happen
                    }
                    if eligible > 0,depth == 0 {
                        // Waiting for Lexicon
                    }
                    if eligible == 0,depth == 0 {
                        // Empty Lexicon => empty tree
                        self.spinner.stopAnimating()
                        self.spinner.isHidden = true
                    }
                    if eligible > 0,depth > 0 {
                        // Lexicon and tree both have entries
                        self.spinner.stopAnimating()
                        self.spinner.isHidden = true
                    }
                }
            })
        }
        
//        updateTitle()
        
//        updateSearchResults()
    }
    
    func started()
    {
        
    }
    
    func updated()
    {
        lexicon?.buildStringTree()
    }
    
    func completed()
    {
        lexicon?.buildStringTree()
    }
}
