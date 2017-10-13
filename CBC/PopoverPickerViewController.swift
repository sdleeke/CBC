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
        if stringTree != nil {
            var depth = 0
            
            if let depthBelow = stringTree?.root?.depthBelow(0) {
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
        guard stringTree != nil else {
            return strings?.count ?? 0
        }
        
        var stringNode = stringTree?.root
        
        switch component {
        case 0:
            break
            
        default:
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
            return count
        } else {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = view as? UILabel ?? UILabel()
        
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        if stringTree != nil {
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
            }
            
            label.textAlignment = .center
        }

        label.sizeToFit()

        return label
    }
    
    func title(forRow row:Int, forComponent component:Int) -> String?
    {
        var stringNode = stringTree?.root
        
        switch component {
        case 0:
            break
            
        default:
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
        
        if let count = stringNode?.stringNodes?.count, row >= 0, row < count {
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
        if stringTree != nil {
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
        if stringTree != nil {
            var stringNode = stringTree?.root
            
            switch component {
            case 0:
                break
                
            default:
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
            
            if  component < pickerSelections.count, let index = pickerSelections[component], index < stringNode?.stringNodes?.count,
                let string = stringNode?.stringNodes?[index].string, string == Constants.WORD_ENDING {
                return width + 20
            } else {
                return width + 10
            }
        } else {
            var width:CGFloat = 0.0
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
            
            if let strings = strings {
                for string in strings {
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
            alert(viewController:self,title: "Not Main Thread", message: "PopoverPickerViewController:pickerView", completion: nil)
            return
        }
        
        if stringTree != nil {
            pickerSelections[component] = row
            
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
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

extension PopoverPickerViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverPickerViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
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
                    
                    if let roots = self.stringTree?.root?.stringNodes {
                        bodyHTML = bodyHTML + "<table><tr>"
                        
                        for root in roots {
                            if let string = root.string {
                                bodyHTML = bodyHTML + "<td>" + "<a id=\"index\(string)\" name=\"index\(string)\" href=#\(string)>" + string + "</a>" + "</td>"
                            }
                        }
                        
                        bodyHTML = bodyHTML + "</tr></table>"
                        
                        bodyHTML = bodyHTML + "<table>"
                        
                        for root in roots {
                            if let rows = root.htmlWords(nil) {
                                if let string = root.string {
                                    bodyHTML = bodyHTML + "<tr><td>" + "<a id=\"\(string)\" name=\"\(string)\" href=#index\(string)>" + string + "</a>" + " (\(rows.count))</td></tr>"
                                }
                                
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
                    presentHTMLModal(viewController: self, mediaItem: nil, style: .fullScreen, title: Constants.Strings.Expanded_View, htmlString: data as? String)
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
    
    var stringTree : StringTree?
    var incremental = false
    
//    var mediaListGroupSort:MediaListGroupSort?
    
    var pickerSelections = [Int:Int]()
    
//    var root:StringNode?
//    {
//        get {
//            return lexicon?.stringTree.root
//        }
//    }
    
//    var lexicon:Lexicon?
//    {
//        get {
//            return mediaListGroupSort?.lexicon
//        }
//    }
    
    var strings:[String]?
    var string:String?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var expandedViewButton: UIButton!
    
    @IBAction func expandedViewAction(_ sender: UIButton)
    {
        process(viewController: self, work: { () -> (Any?) in
            var bodyHTML = "<!DOCTYPE html>"
            
            var wordsHTML = ""
            var indexHTML = ""
            
            bodyHTML = bodyHTML + "<html><body>"
            
            if let roots = self.stringTree?.root?.stringNodes?.sorted(by: { (lhs:StringNode, rhs:StringNode) -> Bool in
                return lhs.string < rhs.string
            }) {
                var total = 0
                
                wordsHTML = "<table>"
                
                for root in roots {
                    if let rows = root.htmlWords(nil) {
                        total += rows.count

                        if let string = root.string {
                            wordsHTML = wordsHTML + "<tr id=\"\(string)\" name=\"\(string)\"><td><br/></td></tr>"
                            
                            wordsHTML = wordsHTML + "<tr><td>" + "<a href=#index>" + string + "</a>" + " (\(rows.count))</td></tr>" //#index\(string)
                        }
                        
                        for row in rows {
                            wordsHTML = wordsHTML + "<tr>" + row + "</tr>"
                        }
                    }
                }
                
                wordsHTML = wordsHTML + "</table>"

                indexHTML = "<table>"
                
                indexHTML = indexHTML + "<tr id=\"index\" name=\"index\"><td><br/></td></tr>" // \(string)
                
                indexHTML = indexHTML + "<tr><td>Index to \(total) Words</td>"

                for root in roots {
                    if let string = root.string {
                        indexHTML = indexHTML + "<td>" + "<a href=#\(string)>" + string + "</a>" + "</td>"
                    }
                }
                
                indexHTML = indexHTML + "</tr></table>"
            }
            
            bodyHTML = bodyHTML + indexHTML + wordsHTML + "</body></html>"
            
            return bodyHTML
        }, completion: { (data:Any?) in
            presentHTMLModal(viewController: self, dismiss:false, mediaItem: nil, style: .fullScreen, title: Constants.Strings.Expanded_View, htmlString: data as? String)
        })
    }
    
    @IBAction func selectButtonAction(sender: UIButton)
    {
        string = wordFromPicker()

//        print("\(string)")
        delegate?.stringPicked(string)
    }
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
//        actionMenu.append(Constants.Strings.Expanded_View)
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
//            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenu()
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self
            
            ptvc = popover
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateActionButton()
    {
        navigationItem.rightBarButtonItem?.isEnabled = stringTree?.root.depthBelow(0) > 0
    }
    
    func setupActionButton()
    {
        guard stringTree != nil else {
            return
        }

        if actionMenu()?.count > 0 {
            let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverPickerViewController.actions))
            actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
            actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.disabled)
            
            navigationItem.setRightBarButton(actionButton, animated: false)
        }
    }

    func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    var doneButton : UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverPickerViewController.done))
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                if navigationItem.leftBarButtonItems != nil {
                    navigationItem.leftBarButtonItems?.append(doneButton)
                } else {
                    navigationItem.leftBarButtonItem = doneButton
                }
                
            default:
                break
            }
        }

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
        
        guard let orientation = orientation else {
            return
        }
        
        switch orientation {
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
            self.orientation = UIDevice.current.orientation
            break
            
        case .landscapeRight:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portrait:
            self.orientation = UIDevice.current.orientation
            break
            
        case .portraitUpsideDown:
            self.orientation = UIDevice.current.orientation
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
        
        if stringTree?.incremental == true {
            if stringTree?.completed == false {
                spinner.isHidden = false
                spinner.startAnimating()
            }

            globals.queue.async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverPickerViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.stringTree)
            })
        }
        
        if let string = string, let index = strings?.index(of:string) {
            picker.selectRow(index, inComponent: 0, animated: false)
        } else

        if (stringTree != nil) && (strings != nil) {
            if stringTree?.incremental == true {
                self.stringTree?.build(strings: self.strings)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    self.stringTree?.build(strings: self.strings)
                    
                    return nil
                }, completion: { (data:Any?) in
                    self.updateActionButton()
                    
                    self.updatePickerSelections()
                    self.updatePicker()
                })
            }
        }

        preferredContentSize = CGSize(width: 300, height: 300)
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
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }

    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverPickerViewController:setPreferredContentSize",completion:nil)
            return
        }

        var width:CGFloat = 0
        
        var count:CGFloat = 0
        
        for component in 0..<picker.numberOfComponents {
            let componentWidth = pickerView(picker, widthForComponent: component)
            
            if componentWidth > 0 {
                count += 1
            }

            width += componentWidth
        }
    
        preferredContentSize = CGSize(width: max(200,width + 70 + count*2), height: 300)
    }

    func updatePickerSelections()
    {
        guard stringTree?.root?.stringNodes != nil else {
            return
        }
        
        var stringNode = stringTree?.root
        
        var i = 0
        
        while stringNode != nil {
            if stringNode?.stringNodes == nil {
                pickerSelections[i] = nil
                stringNode = nil
            } else
                
            if let count = stringNode?.stringNodes?.count, pickerSelections[i] >= count {
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
        
        var index = i
        
        Thread.onMainThread {
            while index < self.picker.numberOfComponents {
                self.pickerSelections[index] = nil
                index += 1
            }
            
            self.picker.setNeedsLayout()
        }
    }
    
    func wordFromPicker() -> String?
    {
        var word:String?
        
        var stringNode = stringTree?.root
        
        var i = 0
        
        while i < pickerSelections.count, pickerSelections[i] != nil {
            if i < pickerSelections.count, let selection = pickerSelections[i] {
                if let stringNodes = stringNode?.stringNodes {
                    if selection < stringNodes.count {
                        let node = stringNodes.sorted(by: { $0.string < $1.string })[selection]
                        
                        if node.string != Constants.WORD_ENDING {
                            stringNode = node
                            
                            if let string = stringNode?.string {
                                word = (word ?? "") + string
                            }
                        }
                    }
                }
            }
            
            i += 1
        }
        
        if let wordEnding = stringNode?.wordEnding, wordEnding {
            return word
        } else {
            return nil
        }
    }
    
    func updatePicker()
    {
        Thread.onMainThread() {
            self.picker.reloadAllComponents()

            var i = 0
            
            while i < self.picker.numberOfComponents, i < self.pickerSelections.count, self.pickerSelections[i] != nil {
                if let row = self.pickerSelections[i] {
                    self.picker.selectRow(row,inComponent: i, animated: true)
                }
                
                i += 1
            }

            self.setPreferredContentSize()

            self.string = self.wordFromPicker()
        }
    }
    
    func started()
    {
        self.updatePickerSelections()
        self.updatePicker()

        Thread.onMainThread {
            self.updateActionButton()
        }
    }
    
    func updated()
    {
        self.updatePickerSelections()
        self.updatePicker()
        
        Thread.onMainThread {
            self.updateActionButton()
            
            if self.stringTree?.completed == true {
                self.spinner.stopAnimating()
            }
        }
    }
    
    func completed()
    {
        self.updatePickerSelections()
        self.updatePicker()

        Thread.onMainThread {
            self.updateActionButton()
        }
    }
}
