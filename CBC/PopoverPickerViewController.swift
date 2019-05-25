//
//  PopoverDatePickerViewController.swift
//  RentBuddy
//
//  Created by Steve Leeke on 5/11/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverPickerControllerDelegate : class
{
    // MARK: PopoverPickerControllerDelegate Protocol
    
    func stringPicked(_ string:String?, purpose:PopoverPurpose?)
}

extension PopoverPickerViewController : UIPickerViewDataSource
{
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        // This allows the window to open quickly, otherwise it computes all the components and their rows
        // which can take seconds for a large stringTree.  If this is 0 numberOfRowsInComponent isn't called.
        guard didAppear else {
            return 0
        }
        
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
        // But just in case.
        guard didAppear else {
            return 0
        }
        
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
                    pickerSelections.value?[i] = pickerSelections.value?[i] != nil ? pickerSelections.value?[i] : 0
                    
                    if let selection = pickerSelections.value?[i] {
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
                label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.body)
            }
            
            label.textAlignment = .left
        } else {
            guard component == 0 else {
                label.text = "ERROR"
                return label
            }
            
            if let string = strings?[row] {
                label.attributedText = NSAttributedString(string: string,attributes: Constants.Fonts.Attributes.body)
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
                    pickerSelections.value?[i] = pickerSelections.value?[i] != nil ? pickerSelections.value?[i] : 0
                    
                    if let selection = pickerSelections.value?[i] {
                        if selection < stringNodes.count {
                            stringNode = stringNodes[selection]
                        }
                    }
                }
            }
            break
        }
        
        if let count = stringNode?.stringNodes?.count, row >= 0, row < count {
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
        guard stringTree != nil else {
            var width:CGFloat = 0.0
            
            let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.body.lineHeight)
            
            if let strings = strings {
                for string in strings {
                    let stringWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.body, context: nil).width
                    
                    if stringWidth > width {
                        width = stringWidth
                    }
                }
            } else {
                return 0
            }
            
            return width + 16
        }
        
        var stringNode = stringTree?.root
        
        switch component {
        case 0:
            break
            
        default:
            for i in 0..<component {
                if let stringNodes = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string }) {
                    pickerSelections.value?[i] = pickerSelections.value?[i] != nil ? pickerSelections.value?[i] : 0
                    
                    if let selection = pickerSelections.value?[i] {
                        if selection < stringNodes.count {
                            stringNode = stringNodes.sorted(by: { $0.string < $1.string })[selection]
                        }
                    }
                }
            }
            break
        }
        
        var width:CGFloat = 0.0
        
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.body.lineHeight)
        
        if let stringNodes = stringNode?.stringNodes?.sorted(by: { $0.string < $1.string }) {
            switch stringNodes.count {
                
            default:
                for stringNode in stringNodes {
                    if let stringWidth = stringNode.string?.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.body, context: nil).width {
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
        
        if  component < pickerSelections.value?.count, let index = pickerSelections.value?[component], index < stringNode?.stringNodes?.count,
            let string = stringNode?.stringNodes?.sorted(by: {
                $0.string < $1.string
            })[index].string, string == Constants.WORD_ENDING {
            return width + 20
        } else {
            return width + 10
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "PopoverPickerViewController:pickerView", completion: nil)
            return
        }
        
        guard stringTree != nil else {
            guard component == 0 else {
                return
            }
            
            string = strings?[row]
//            print(row, string as Any)
            
            return
        }
        
        pickerSelections.value?[component] = row
        
        var wheel = component+1
        
        while wheel < pickerSelections.value?.count {
            pickerSelections.value?[wheel] = 0
            wheel += 1
        }

        spinner.startAnimating()
        
        if allowsSelection {
            toolbarItems?[1].isEnabled = false
        }
        
        // Needs to be in an opQueue so we don't get multiple conflicting
        operationQueue.addOperation { [weak self] in
            self?.updatePickerSelections()
            self?.updatePicker()
        }
    }
}

extension PopoverPickerViewController : PopoverTableViewControllerDelegate
{
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "PopoverPickerViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        guard let string = strings?[index] else {
            return
        }
        
        switch purpose {
        case .selectingAction:
            switch string {
            case Constants.Strings.Expanded_View:
                self.popover?["ACTION"]?.dismiss(animated: true, completion: { [weak self] in
                    self?.popover?["ACTION"] = nil
                })
                
                process(work: { [weak self] () -> (Any?) in
                    Thread.onMainThread {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = false
                    }
                    
                    return self?.stringTree?.expandedHTML
                }, completion: { [weak self] (data:Any?) in
                    var style:UIModalPresentationStyle = .overCurrentContext
                    
                    if self?.lexicon != nil {
                        style = .fullScreen
                    }
                    
                    self?.presentHTMLModal(mediaItem: nil, style: style, title: Constants.Strings.Expanded_View, htmlString: data as? String)
                    
                    Thread.onMainThread {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                })
                break

            case Constants.Strings.Word_Index:
                self.popover?["ACTION"]?.dismiss(animated: true, completion: { [weak self] in
                    self?.popover?["ACTION"] = nil
                })
                
                self.process(work: { [weak self] () -> (Any?) in
                    Thread.onMainThread {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = false
                    }

                    return self?.stringTree?.wordsHTML
                }, completion: { [weak self] (data:Any?) in
                    var style:UIModalPresentationStyle = .overCurrentContext

                    if self?.navigationController?.modalPresentationStyle == .popover {
                        style = .fullScreen
                    }

                    self?.presentHTMLModal(mediaItem: nil, style: style, title: "Word Index", htmlString: data as? String)
                    
                    Thread.onMainThread {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                })
                break

            default:
//                if string == actionTitle {
//                    popover?.dismiss(animated: true) { [weak self] in
//                        self?.action?(string)
//                    }
//                }
                break
            }
            break
            
        default:
            break
        }
    }
}

class PopoverPickerViewController : CBCViewController
{
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "PopoverPickerViewController" // Assumes there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    
        lexicon?.callBacks.unregister("PPVC")
        stringTree?.callBacks.unregister("PPVC")
    }
    
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

    weak var delegate : PopoverPickerControllerDelegate?
    
    var purpose : PopoverPurpose?
    
    weak var lexicon : Lexicon?
    {
        didSet {
            lexicon?.callBacks.register("PPVC",
                [
                "start": { [weak self] in

                },
                "update":{ [weak self] in
                    let strings = self?.stringsFunction?()
                    self?.stringTree?.build(strings: strings)
                },
                "complete":{ [weak self] in
                    let strings = self?.stringsFunction?()
                    self?.stringTree?.build(strings: strings)
                }
                ]
            )

            if stringTree == nil {
                stringTree = lexicon?.stringTreeFunction?()
                
                stringTree?.callBacks.register("PPVC",
                   [
                    "start": { [weak self] in
                        self?.started()
                    },
                    "update":{ [weak self] in
                        self?.updated()
                    },
                    "complete":{ [weak self] in
                        self?.completed()
                    }
                   ]
                )
            }
        }
    }
    
    private var stringTree : StringTree?
    
    var allowsSelection = true
    
    var barButtonAction : ((String?)->())?
    var barButtonActionTitle : String?
    
    // Either method of initialization works.
    var pickerSelections = ThreadSafe<[Int:Int]>([Int:Int]())
    
    var stringsFunction:(()->[String]?)?
    
    var strings:[String]?
    {
        didSet {
            
        }
    }
  
    var string:String?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var picker: UIPickerView!
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        actionMenu.append(Constants.Strings.Expanded_View)
        actionMenu.append(Constants.Strings.Word_Index)
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenu()
            
            self.popover?["ACTION"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["ACTION"] = nil
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateActionButton()
    {
        Thread.onMainThread { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = self?.stringTree?.root.depthBelow(0) > 0
        }
    }
    
    @objc func showFullScreen()
    {
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
            dismiss(animated: false, completion: nil)
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            navigationController.modalPresentationStyle = .overFullScreen
            navigationController.popoverPresentationController?.delegate = self
            
            popover.navigationItem.title = Constants.Strings.Word_Picker
            
            popover.delegate = self.delegate
            
            popover.lexicon = self.lexicon
            
            popover.stringsFunction = lexicon?.stringsFunction
            
            self.presentingViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func setupActionButton()
    {
        guard stringTree != nil else {
            return
        }

        // Can't have a popover on a popover!
        if actionMenu()?.count > 0, self.navigationController?.modalPresentationStyle != .popover {
            let fullScreenButton = UIBarButtonItem(title: Constants.FA.FULL_SCREEN, style: UIBarButtonItem.Style.plain, target: self, action: #selector(showFullScreen))
            fullScreenButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

            let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
            actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

            if Globals.shared.splitViewController?.isCollapsed == false {
                if self.navigationController?.modalPresentationStyle == .overFullScreen {
                    navigationItem.setRightBarButton(actionButton, animated: false)
                } else {
                    navigationItem.rightBarButtonItems = [actionButton, fullScreenButton]
                }
            } else {
                navigationItem.setRightBarButton(actionButton, animated: false)
            }
        }
    }

    @objc func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    var doneButton : UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
                
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }
    
//    var orientation : UIDeviceOrientation?

    @objc func deviceOrientationDidChange()
    {
//        // Dismiss any popover
//        func action()
//        {
//            popover?.values.forEach({ (popover:PopoverTableViewController) in
//                popover.dismiss(animated: false, completion: nil)
//            })
//        }
//
//        guard let orientation = orientation else {
//            return
//        }
//
//        switch orientation {
//        case .faceUp:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .faceDown:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .landscapeLeft:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .landscapeRight:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                break
//
//            case .landscapeRight:
//                break
//
//            case .portrait:
//                action()
//                break
//
//            case .portraitUpsideDown:
//                action()
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .portrait:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .portraitUpsideDown:
//            switch UIDevice.current.orientation {
//            case .faceUp:
//                break
//
//            case .faceDown:
//                break
//
//            case .landscapeLeft:
//                action()
//                break
//
//            case .landscapeRight:
//                action()
//                break
//
//            case .portrait:
//                break
//
//            case .portraitUpsideDown:
//                break
//
//            case .unknown:
//                action()
//                break
//
//            @unknown default:
//                break
//            }
//            break
//
//        case .unknown:
//            break
//
//        @unknown default:
//            break
//        }
//
//        switch UIDevice.current.orientation {
//        case .faceUp:
//            break
//
//        case .faceDown:
//            break
//
//        case .landscapeLeft:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .landscapeRight:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .portrait:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .portraitUpsideDown:
//            self.orientation = UIDevice.current.orientation
//            break
//
//        case .unknown:
//            break
//
//        @unknown default:
//            break
//        }
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    var didAppear = false
    
    func setupBarButtonItems()
    {
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        var barButtons = [UIBarButtonItem]()
        
        if allowsSelection {
            barButtons.append(spaceButton)
            barButtons.append(UIBarButtonItem(title: "Select", style: UIBarButtonItem.Style.plain, target: self, action: #selector(doSelect)))
            barButtons.append(spaceButton)
        }
        
        if barButtonAction != nil {
            if !allowsSelection {
                barButtons.append(spaceButton)
            }
            
            barButtons.append(UIBarButtonItem(title: barButtonActionTitle ?? "Action", style: UIBarButtonItem.Style.plain, target: self, action: #selector(doBarButtonAction)))
            barButtons.append(spaceButton)
        }
        
        toolbarItems = barButtons.count > 0 ? barButtons : nil
        
        navigationController?.isToolbarHidden = toolbarItems == nil
        
        if allowsSelection {
            toolbarItems?[1].isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        didAppear = false

        if stringTree == nil {
            stringTree = StringTree()
        }
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.leftBarButtonItem = doneButton
                
//                if navigationItem.leftBarButtonItems != nil {
//                    // When would this have been necessary?
//                    navigationItem.leftBarButtonItems?.append(doneButton)
//                } else {
//                    navigationItem.leftBarButtonItem = doneButton
//                }
                
            default:
                break
            }
        }
        
        setupActionButton()

//        picker.isHidden = true
        
//        orientation = UIDevice.current.orientation
        
        addNotifications()
        
//        updateActionButton()

        spinner.isHidden = false
        spinner.startAnimating()

//        if stringTree?.incremental == true {
//            if stringTree?.completed == false {
//                spinner.isHidden = false
//                spinner.startAnimating()
//            }
//
//            stringTree?.callBacks.register(id: "PPVC", callBack: CallBack(
//                    start: { [weak self] in
//                        self?.started()
//                    },
//                    update:{ [weak self] in
//                        self?.updated()
//                    },
//                    complete:{ [weak self] in
//                        self?.completed()
//                    }
//                )
//            )
            
//            stringTree?.update = { [weak self] in
//                self?.updated()
//            }
            
//            Globals.shared.queue.async {
//                NotificationCenter.default.addObserver(self, selector: #selector(self.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self.stringTree)
//            }
//        }
        
        if let string = string, let index = strings?.firstIndex(of:string), picker.numberOfComponents == 1 {
            // THIS IS FINE IF THERE IS ONE COMPONENT TO THE PICKER!
            picker.selectRow(index, inComponent: 0, animated: false)
        } else

//        if let string = string {
//            // This should only happen if we're coming back from action?().
//        } else
            
        if (stringTree != nil) {
            if (strings != nil) {
                // This must be changed to be in a cancellable operation in an op queue
                // otherwise the string tree keeps going forever
                self.process(work: { [weak self] () -> (Any?) in
                    if self?.stringTree?.completed == false {
                        self?.stringTree?.build(strings: self?.strings)
                    } else {
                        self?.complete = true
                    }
//                    self?.stringTree?.build(strings: self?.strings)

                    return nil
                }, completion: { [weak self] (data:Any?) in
                    if self?.didAppear == true  {
                        self?.operationQueue.addOperation {
                            self?.updateActionButton()
                            self?.updatePickerSelections()
                            self?.updatePicker()
                        }
                    }
                })
            } else
            
            if stringsFunction != nil {
                self.process(work: { [weak self] () -> (Any?) in
                    if self?.stringTree?.completed == false {
                        let strings = self?.stringsFunction?()
                        self?.stringTree?.build(strings: strings)
                    } else {
                        self?.complete = true
                    }
                    
                    return nil
                }, completion: { [weak self] (data:Any?) in
                    if self?.didAppear == true {
                        self?.operationQueue.addOperation {
                            self?.updateActionButton()
                            self?.updatePickerSelections()
                            self?.updatePicker()
                        }
                    }
                })
            }
        }
        
        setupBarButtonItems()
        
//        self.operationQueue.addOperation {
//            self.updateActionButton()
//            self.updatePickerSelections()
//            self.updatePicker()
//        }

        setPreferredContentSize() // = CGSize(width: 300, height: 300)
    }
    
    @objc func doSelect()
    {
        string = wordFromPicker()
        
        delegate?.stringPicked(string,purpose:purpose)

        dismiss(animated: false, completion: nil)
    }
    
    @objc func doBarButtonAction()
    {
        self.barButtonAction?(self.wordFromPicker())
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        didAppear = true

        self.operationQueue.addOperation {
            self.updateActionButton()
            self.updatePickerSelections()
            self.updatePicker()
        }
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
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "PopoverPickerViewController:setPreferredContentSize",completion:nil)
            return
        }

        guard self.navigationController?.modalPresentationStyle == .popover else {
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
                pickerSelections.value?[i] = nil
                stringNode = nil
            } else
                
            if let count = stringNode?.stringNodes?.count, pickerSelections.value?[i] >= count {
                pickerSelections.value?[i] = 0
                stringNode = stringNode?.stringNodes?.sorted(by: {
                    $0.string < $1.string
                })[0]
            } else {
                if let index = pickerSelections.value?[i] {
                    stringNode = stringNode?.stringNodes?.sorted(by: {
                        $0.string < $1.string
                    })[index]
                } else {
                    stringNode = nil
                }
            }
            
            i += 1
        }
        
        var index = i
        
        Thread.onMainThread { [weak self] in
            while index < self?.picker.numberOfComponents {
                self?.pickerSelections.value?[index] = nil
                index += 1
            }
            
            self?.picker.setNeedsLayout()
        }
    }
    
    func wordFromPicker() -> String?
    {
        var word:String?
        
        var stringNode = stringTree?.root
        
        var i = 0
        
        while i < pickerSelections.value?.count, pickerSelections.value?[i] != nil {
            if i < pickerSelections.value?.count, let selection = pickerSelections.value?[i] {
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
        Thread.onMainThread { [weak self] in
            self?.picker.reloadAllComponents()
        
            var i = 0
            
            while i < self?.picker.numberOfComponents, i < self?.pickerSelections.value?.count, self?.pickerSelections.value?[i] != nil {
                if let row = self?.pickerSelections.value?[i], row < self?.picker.numberOfRows(inComponent: i) {
                    self?.picker.selectRow(row,inComponent: i, animated: true)
                }
                
                i += 1
            }

            self?.setPreferredContentSize()

            self?.string = self?.wordFromPicker()
            
            if self?.allowsSelection == true {
                self?.toolbarItems?[1].isEnabled = (self?.didAppear == true) && ((self?.stringTree?.incremental == true) ? true : (self?.stringTree?.completed == true))
            }
            
            if self?.stringTree?.incremental == true { // stringTree?.
                if self?.complete == true, self?.didAppear == true {
                    self?.spinner.stopAnimating()
                }
            } else {
                self?.spinner.stopAnimating()
            }
        }
    }
    
    func started()
    {
        complete = false
        
        Thread.onMainThread {
            self.spinner.startAnimating()
        }
        
        self.updatePickerSelections()
        self.updatePicker()

        Thread.onMainThread { [weak self] in
            self?.updateActionButton()
        }
    }
    
    @objc func updated()
    {
        Thread.onMainThread {
            self.spinner.startAnimating()
        }

        self.updatePickerSelections()
        self.updatePicker()
        
        Thread.onMainThread { [weak self] in
            self?.updateActionButton()
//            
//            if self?.complete == true { // self?.stringTree?.completed == true, (self?.stringTree?.lexicon == nil) || (self?.stringTree?.lexicon?.completed == true)
//                self?.spinner.stopAnimating()
//            }
        }
    }
    
    var complete = false
    
    func completed()
    {
        complete = true
        
        Thread.onMainThread {
            self.spinner.startAnimating()
        }

        self.updatePickerSelections()
        self.updatePicker()

        Thread.onMainThread { [weak self] in
            self?.updateActionButton()
        }
    }
}
