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

extension PopoverPickerViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
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
            } else {
                return 0
            }
        } else {
            return strings != nil ? strings!.count : 0
        }
    }
    
//    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat
//    {
//        return 48.0
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }
        
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        if mediaListGroupSort != nil {
            if let title = title(forRow: row, forComponent: component) {
                label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.normal)
            }
            
            label.textAlignment = .left
        } else {
            guard component == 0 else {
                label.text = "ERROR"
                return label
            }
            
            if let string = strings?[row] {
                label.attributedText = NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.normal)
//                print("LAST: ",string)
            }
            
            label.textAlignment = .center
        }

        label.sizeToFit()

        return label
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

            default:
                if let string = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string })[row].string {
                    return string
                }
                break
            }
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
                    
                default:
                    for stringNode in stringNodes {
                        if let stringWidth = stringNode.string?.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil).width {
                            if stringWidth > width {
                                width = stringWidth
                            }
                        }
                    }
                    break
                }
            } else {
                return 0
            }

            //            print("Component: ",component," Width: ",width)
            
            if let index = pickerSelections[component], let string = stringNode?.stringNodes?[index].string, string == Constants.WORD_ENDING {
                return width + 20
            } else {
                return width + 10
            }
        } else {
            var width:CGFloat = 0.0
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
            
            if let strings = strings {
                for string in strings {
                    //                print(stringNode.string)
//                    let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                    
                    let stringWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil).width
                    
                    if stringWidth > width {
                        width = stringWidth
                    }
                }
            } else {
                return 0
            }
            
            return width + 16
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        guard Thread.isMainThread else {
            return
        }
        
        if mediaListGroupSort != nil {
            pickerSelections[component] = row
            
            //        print(pickerSelections)
            
            DispatchQueue.global(qos: .userInteractive).async {
                self.updatePickerSelections()
                self.updatePicker()
            }
        } else {
            guard component == 0 else {
                return
            }
            
            string = strings?[row]
            print(row, string as Any)
        }
    }
}

extension PopoverPickerViewController : UIPopoverPresentationControllerDelegate
{
    
}

extension PopoverPickerViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverPickerViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        //        dismiss(animated: true, completion: nil)
        
        guard let string = strings?[index] else {
            return
        }
        
        switch purpose {
        case .selectingAction:
            switch string {
            case Constants.Strings.Expanded_View:
                process(viewController: self, work: { () -> (Any?) in
                    var bodyHTML = "<!DOCTYPE html>"
                    
                    bodyHTML = bodyHTML + "<html><body>"
                    
                    bodyHTML = bodyHTML + "<center>"
                    
                    if let roots = self.lexicon?.stringTree.root?.stringNodes {
                        bodyHTML = bodyHTML + "<table><tr>"
                        
                        for root in roots {
                            if let string = root.string {
                                bodyHTML = bodyHTML + "<td>" + "<a id=\"index\(string)\" name=\"index\(string)\" href=#\(string)>" + string + "</a>" + "</td>"
                            }
                        }
                        
                        bodyHTML = bodyHTML + "</tr></table>"
                        
                        bodyHTML = bodyHTML + "<table>"
                        
                        for root in roots {
                            if let string = root.string {
                                bodyHTML = bodyHTML + "<tr><td>" + "<a id=\"\(string)\" name=\"\(string)\" href=#index\(string)>" + string + "</a>" + "</td></tr>"
                            }
                            
                            if let rows = root.htmlWords(nil) {
                                for row in rows {
                                    bodyHTML = bodyHTML + "<tr>" + row + "</tr>"
                                }
                            }
                        }
                        
                        bodyHTML = bodyHTML + "</table>"
                    }
                    
                    bodyHTML = bodyHTML + "</center>"
                    
                    bodyHTML = bodyHTML + "</body></html>"
                    
                    return bodyHTML
                }, completion: { (data:Any?) in
                    presentHTMLModal(viewController: self, medaiItem: nil, style: .overCurrentContext, title: "Expanded Word Picker", htmlString: data as? String)
                })
                break
                
            default:
                break
            }
            break
            
        default:
            break
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
        string = wordFromPicker()

//        print("\(string)")
        delegate?.stringPicked(string)
    }
    
    func actionMenu()
    {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            var actionMenu = [String]()
            
            actionMenu.append(Constants.Strings.Expanded_View)
            
            popover.section.strings = actionMenu
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            popover.vc = self
            
            ptvc = popover
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateActionButton()
    {
        navigationItem.rightBarButtonItem?.isEnabled = lexicon?.stringTree.root.depthBelow(0) > 0
    }
    
    func setupActionButton()
    {
        guard mediaListGroupSort != nil else {
            return
        }

        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverPickerViewController.actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
        
        navigationItem.setRightBarButton(actionButton, animated: false)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        setupActionButton()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        //        print("Size: \(size)")
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }
    
    var ptvc:PopoverTableViewController?
    
    var orientation : UIDeviceOrientation?

    func deviceOrientationDidChange()
    {
        // Dismiss any popover
        func action()
        {
            ptvc?.dismiss(animated: false, completion: nil)
        }
        
        switch orientation! {
        case .faceUp:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .faceDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeLeft:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .landscapeRight:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                break
                
            case .landscapeRight:
                break
                
            case .portrait:
                action()
                break
                
            case .portraitUpsideDown:
                action()
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portrait:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .portraitUpsideDown:
            switch UIDevice.current.orientation {
            case .faceUp:
                break
                
            case .faceDown:
                break
                
            case .landscapeLeft:
                action()
                break
                
            case .landscapeRight:
                action()
                break
                
            case .portrait:
                break
                
            case .portraitUpsideDown:
                break
                
            case .unknown:
                action()
                break
            }
            break
            
        case .unknown:
            break
        }
        
        switch UIDevice.current.orientation {
        case .faceUp:
            break
            
        case .faceDown:
            break
            
        case .landscapeLeft:
            orientation = UIDevice.current.orientation
            break
            
        case .landscapeRight:
            orientation = UIDevice.current.orientation
            break
            
        case .portrait:
            orientation = UIDevice.current.orientation
            break
            
        case .portraitUpsideDown:
            orientation = UIDevice.current.orientation
            break
            
        case .unknown:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        orientation = UIDevice.current.orientation
        
        NotificationCenter.default.addObserver(self, selector: #selector(WebViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        updateActionButton()
        
        if mediaListGroupSort != nil {
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
                
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.stringTreeUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.lexicon)
            })
            
            spinner.isHidden = false
            spinner.startAnimating()
            
            root = lexicon?.stringTree.root

            if (root == nil) || root!.isLeaf {
//                print("building")

                lexicon?.build()
                
                lexicon?.stringTree.build()
            } else {
                stringTreeUpdated()
            }
        }
        
//        print(string)
//        print(strings)
        
        if string != nil, let index = strings?.index(of:string!) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        if (navigationController?.viewControllers.count == 1) {
            if (mediaListGroupSort != nil) {
                preferredContentSize = CGSize(width: 200, height: 300)
            } else {
                preferredContentSize = CGSize(width: 300, height: 300)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverPickerViewController:setPreferredContentSize",completion:nil)
            return
        }

//        print("PPVC \(navigationController!.viewControllers.count)")

        var width:CGFloat = 0
        
        var count:CGFloat = 0
        
        for component in 0..<picker.numberOfComponents {
//            print(component,picker.rowSize(forComponent: component).width)
            
            let componentWidth = pickerView(picker, widthForComponent: component)
            
            if componentWidth > 0 {
                count += 1
            }

            width += componentWidth
        }
    
//        print(max(200,width + 40 + count*2))
        preferredContentSize = CGSize(width: max(200,width + 40 + count*2), height: 300)
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
//        print(lexicon?.stringTree.root.depthBelow(0))
        
//        lexicon?.stringTree.root.printStrings(nil)
//        lexicon?.stringTree.root.printWords(nil)
        
//        let words = lexicon?.stringTree.root.htmlWords(nil)
//        print(words)
        
        root = lexicon?.stringTree.root
        
//        print(self.mediaListGroupSort?.lexicon?.root.htmlWords(nil))
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.updatePickerSelections()
            self.updatePicker()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateActionButton()

                if let eligible = self.lexicon?.eligible?.count, let depth = self.lexicon?.stringTree.root?.depthBelow(0) {
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
    }
    
    func started()
    {
        
    }
    
    func updated()
    {
        lexicon?.stringTree.build()
    }
    
    func completed()
    {
        lexicon?.stringTree.build()
    }
}
