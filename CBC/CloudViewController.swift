//
//  CloudViewController.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
//import PDFKit

enum CloudColors {
    static let BlueGreen = [
        UIColor(hue:216.0/360.0, saturation:1.0, brightness:0.3, alpha:1.0),
        UIColor(hue:216.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:216.0/360.0, saturation:0.8, brightness:1.0, alpha:1.0),
        UIColor(hue:184.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:152.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0)
        ]
    
    static let MagentaBlue = [
        UIColor(hue:306.0/360.0, saturation:1.0, brightness:0.3, alpha:1.0),
        UIColor(hue:306.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:306.0/360.0, saturation:0.8, brightness:0.6, alpha:1.0),
        UIColor(hue:274.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:242.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0)
    ]
    
    static let MustardRed = [
        UIColor(hue: 36.0/360.0, saturation:1.0, brightness:0.3, alpha:1.0),
        UIColor(hue: 36.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue: 36.0/360.0, saturation:0.8, brightness:1.0, alpha:1.0),
        UIColor(hue:  4.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:332.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0)
    ]
    
    static let GreenBlue = [
        UIColor(hue:126.0/360.0, saturation:1.0, brightness:0.3, alpha:1.0),
        UIColor(hue:126.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0),
        UIColor(hue:126.0/360.0, saturation:0.8, brightness:0.6, alpha:1.0), // Brightness 0.6 instead of 1.0
        UIColor(hue:190.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0), // Hue + 64 instead of - 32
        UIColor(hue:222.0/360.0, saturation:0.9, brightness:0.8, alpha:1.0)  // Hue + 96 instead of - 64
    ]
    
    static let CoralReef = [
        UIColor(red: 51.0/255.0, green: 77.0/255.0, blue: 92.0/255.0, alpha:1.0),
        UIColor(red:226.0/255.0, green:122.0/255.0, blue: 63.0/255.0, alpha:1.0),
        UIColor(red:239.0/255.0, green:201.0/255.0, blue: 76.0/255.0, alpha:1.0),
        UIColor(red: 69.0/255.0, green:178.0/255.0, blue:157.0/255.0, alpha:1.0),
        UIColor(red:223.0/255.0, green: 90.0/255.0, blue: 73.0/255.0, alpha:1.0),
    ]
    
    static let SpicyOlive = [
        UIColor(red:242.0/255.0, green: 92.0/255.0, blue:  5.0/255.0, alpha:1.0),
        UIColor(red:136.0/255.0, green:166.0/255.0, blue: 27.0/255.0, alpha:1.0),
        UIColor(red:242.0/255.0, green:159.0/255.0, blue:  5.0/255.0, alpha:1.0),
        UIColor(red:217.0/255.0, green: 37.0/255.0, blue: 37.0/255.0, alpha:1.0),
        UIColor(red: 47.0/255.0, green:102.0/255.0, blue:179.0/255.0, alpha:1.0)
    ]
    
    static let MaroonGrey = [
        UIColor(hue:17.0/360.0, saturation:1.0, brightness:0.4, alpha:1.0),
        UIColor(hue:17.0/360.0, saturation:0.0, brightness:0.0, alpha:1.0),
        UIColor(hue:17.0/360.0, saturation:0.0, brightness:0.3, alpha:1.0),
        UIColor(hue:17.0/360.0, saturation:0.3, brightness:0.6, alpha:1.0),
        UIColor(hue:17.0/360.0, saturation:1.0, brightness:0.6, alpha:1.0)
    ]
    
    static let Black = [UIColor.black]
    
    static let White = [UIColor.white]
}

extension CloudViewController : UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return cloudView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat)
    {

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {

    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {

    }
}

extension CloudViewController : PopoverTableViewControllerDelegate
{
    func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return nil
    }
    
    func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        return nil
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        switch purpose {
        case .selectingAction:
            dismiss(animated: true, completion: {
                guard let string = strings?[index] else {
                    return
                }
                
                switch string {
                case Constants.Strings.Share:
                    self.share()
                    break
                    
                case Constants.Strings.Print:
                    if #available(iOS 11.0, *) {
                        self.printJob(data: self.cloudView.image?.pdf?.data)
                    } else {
                        // Fallback on earlier versions
                        self.printJob(data: self.cloudView.image?.jpegData(compressionQuality: 1.0))
                    }
                    break
                    
                default:
                    break
                }
            })
            
        case .selectingWordCloud:
            guard let cloudWordDicts = cloudWordDicts else {
                return
            }
            
            guard let string = strings?[index] else {
                return
            }

            guard let word = string.word else {
                return
            }
            
            guard let frequency = string.frequency else {
                return
            }
            
            var index = 0
            
            for cloudWordDict in cloudWordDicts {
                if ((cloudWordDict["word"] as? String) == word) && ((cloudWordDict["count"] as? Int) == frequency) { // Int(count)
                    if let selected = self.cloudWordDicts?[index]["selected"] as? Bool, selected {
                        self.cloudWordDicts?[index]["selected"] = false
                    } else {
                        self.cloudWordDicts?[index]["selected"] = true
                    }
                    break
                }
                
                index += 1
            }
            
            Thread.onMain { [weak self] in 
                self?.cancelAndRelayoutCloudWords()
            }

        default:
            break
        }
    }
}

extension CloudViewController : CloudLayoutOperationDelegate
{
    func update(cloudWords:[CloudWord]?)
    {
        self.cloudWords = cloudWords
    }
    
    func finished(cloudWords:[CloudWord]?)
    {
        self.cloudWords = cloudWords
        
        Thread.onMain { () -> (Void) in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
    }
    
    func insertWord(word:String, pointSize:CGFloat, color:Int, center:CGPoint, isVertical:Bool)
    {
        guard pointSize > 0 else {
            return
        }
        
        guard let color = cloudColors?[color] else {
            return
        }

        labelQueue.addOperation {
//            Thread.onMain { [weak self] in 
                let wordLabel = UILabel()
                
                wordLabel.frame = CGRect.zero
                wordLabel.text = word
                wordLabel.textAlignment = .center
                wordLabel.font = self.cloudFont?.withSize(pointSize)
                
                wordLabel.sizeToFit()
                
                wordLabel.textColor = color
                
                // Round up size to even multiples to "align" frame without ofsetting center
                var wordLabelRect = wordLabel.frame
                wordLabelRect.size.width = CGFloat(Int((wordLabelRect.width + 3) / 2) * 2)
                wordLabelRect.size.height = CGFloat(Int((wordLabelRect.height + 3) / 2) * 2)
                wordLabel.frame = wordLabelRect;
                
                wordLabel.center = center;
                
                if (isVertical)
                {
                    wordLabel.transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi / 2))
                }
                
                self.cloudView.addSubview(wordLabel)
  //          }
        }
    }
    
    func insertBoundingRect(boundingRect:CGRect) -> CALayer
    {
        let layer = CALayer()
        
        layer.frame = boundingRect
        
        layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5).cgColor
        
        layer.borderWidth = 1;
        
        cloudView.layer.addSublayer(layer)
        
        return layer
    }
}

extension CloudViewController : UIActivityItemSource
{
    @objc func share()
    {
        // Must be on main thread.
        let print = cloudView.viewPrintFormatter()
        let margin:CGFloat = 0.5 * 72
        print.perPageContentInsets = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)

        var activityItems:[Any] = [self]

        if #available(iOS 11.0, *) {
            activityItems.append(cloudView.image?.pdf?.data)
        } else {
            activityItems.append(cloudView.image)
        }

        let activityViewController = CBCActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Exclude AirDrop, as it appears to delay the initial appearance of the activity sheet
        activityViewController.excludedActivityTypes = [.addToReadingList,.airDrop]
        
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        // present the view controller
        Alerts.shared.blockPresent(presenting: self, presented: activityViewController, animated: true)
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    static var cases : [UIActivity.ActivityType] = [.message,.mail,.print,.openInIBooks]
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        guard let activityType = activityType else {
            return nil
        }
        
        if #available(iOS 11.0, *) {
            CloudViewController.cases.append(.markupAsPDF)
        }
        
        switch activityType {
        case .message:
            return cloudView.image
            
        case .mail:
            return cloudView.image
            
        case .print:
            return nil

        default:
            if CloudViewController.cases.contains(activityType) {
                return self.cloudView.image
            }
        }

        return nil
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return self.navigationItem.title ?? "" // mediaItem?.text ?? (transcript?.mediaItem?.text ?? ( ?? ""))
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        guard let activityType = activityType else {
            return "public.plain-text"
        }
        
        if CloudViewController.cases.contains(activityType) {
            return "public.text"
        } else {
            return "public.plain-text"
        }
    }
}

/**
 To create word clouds for a list of strings and frequencies
 */
class CloudViewController : CBCViewController
{
    var cloudWords : [CloudWord]?
    {
        didSet {
            if #available(iOS 12.0, *) {
//                animate()
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    lazy var popover : [String:PopoverTableViewController]? = {
        return [String:PopoverTableViewController]()
    }()

    var wordsTableViewController:PopoverTableViewController!
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "CloudViewController:Operations" // Assumes there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    private lazy var layoutQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "CloudViewController:Operations" // Assumes there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    private lazy var labelQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "CloudViewController:Labels" // Assumes there is only ever one at a time globally
        operationQueue.qualityOfService = .userInteractive
        operationQueue.underlyingQueue = DispatchQueue.main
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    func cancelAllOperations()
    {
        labelQueue.cancelAllOperations()
        layoutQueue.cancelAllOperations()
        animateQueue.cancelAllOperations()
        operationQueue.cancelAllOperations()
    }
    
    deinit {
        debug(self)
        cancelAllOperations()
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var selectAllButton: UIButton!
    @IBAction func selectAllAction(_ sender: UIButton)
    {
        guard var cloudWordDicts = cloudWordDicts else {
            return
        }

        for index in 0..<cloudWordDicts.count {
            cloudWordDicts[index]["selected"] = true
        }
        
        self.cloudWordDicts = cloudWordDicts

        self.wordsTableViewController.tableView.reloadData()
        
        cancelAndRelayoutCloudWords()
    }
    
    @IBOutlet weak var selectNoneButton: UIButton!
    @IBAction func selectNoneAction(_ sender: UIButton)
    {
        guard var cloudWordDicts = cloudWordDicts else {
            return
        }
        
        for index in 0..<cloudWordDicts.count {
            cloudWordDicts[index]["selected"] = false
        }
        
        self.cloudWordDicts = cloudWordDicts

        self.wordsTableViewController.tableView.reloadData()

        cancelAndRelayoutCloudWords()
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cloudView: UIView!
    
    @IBOutlet weak var wordOrientation: UISegmentedControl!
    {
        didSet {
            wordOrientation.selectedSegmentIndex = 2
        }
    }
    
    @IBAction func wordOrientationAction(_ sender: UISegmentedControl)
    {
        cancelAndRelayoutCloudWords()
    }
    
    let cloudDebug = false
    
    var cloudString : String?
    
    var cloudTitle : String?
    var cloudColors : [UIColor]? = CloudColors.GreenBlue
    var cloudFont : UIFont?
    
    // Make thread safe?
    var cloudWordDicts : [[String:Any]]?
    var cloudWordDictsFunction:(()->[[String:Any]]?)?
    
    lazy var animateQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "CloudViewController:Animation" // Assumes there is only one globally // + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    @available(iOS 12.0, *)
    func animate()
    {
        guard let cloudWords = cloudWords else {
            return
        }

        animateQueue.cancelAllOperations()
        
        animateQueue.addOperation {
            var cloudDict = [String:CloudWord]()
            
            for cloudWord in cloudWords {
                if let wordText = cloudWord.wordText {
                    cloudDict[wordText.uppercased()] = cloudWord
                }
            }
            
            if let words = self.cloudString?.nlTokenTypes {
                for word in words {
                    if let cloudWord = cloudDict[word.0.uppercased()] {
//                        print(cloudWord.wordText)
                        Thread.onMain { [weak self] in 
                            if let overallGlyphBoundingRect = cloudWord.overallGlyphBoundingRect, let layer = self?.insertBoundingRect(boundingRect: overallGlyphBoundingRect) {
                                // So UI operates as expected
                                DispatchQueue.global(qos: .background).async { [weak self] in
                                    Thread.sleep(forTimeInterval: 0.1)
                                    Thread.onMain { [weak self] in 
                                        layer.removeFromSuperlayer()
                                    }
                                }
                            }
                        }
                    } else {
                        
                    }
                }
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let selectTap = UITapGestureRecognizer(target: self, action: #selector(selectCloudWord(_:)))
        selectTap.numberOfTapsRequired = 1
        cloudView.addGestureRecognizer(selectTap)
        
        let layoutTap = UITapGestureRecognizer(target: self, action: #selector(cancelAndRelayoutCloudWords))
        layoutTap.numberOfTapsRequired = 2
        cloudView.addGestureRecognizer(layoutTap)
        
        selectTap.require(toFail: layoutTap)
    }
    
    @objc func selectCloudWord(_ tap:UITapGestureRecognizer)
    {
        switch tap.state {
        case .began:
            break
            
        case .ended:
            let location = tap.location(in: cloudView)
            for view in cloudView.subviews {
                if let label = view as? UILabel {
                    if label.frame.contains(location) {
                        // Dismiss WordCloud and select that word in the document?
                        break
                    }
                }
            }
            break
            
        case .changed:
            break
            
        default:
            break
        }
    }
    
    @objc func contentSizeCategoryDidChange()
    {
        cancelAndRelayoutCloudWords()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.cancelAndRelayoutCloudWords()
        }
    }
    
    @objc func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()
        
        actionMenu.append(Constants.Strings.Share)
        
        if UIPrintInteractionController.isPrintingAvailable {
            actionMenu.append(Constants.Strings.Print)
        }

        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actionMenu()
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
            
            popover.section.strings = actionMenuItems()
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()

        self.navigationItem.title = cloudTitle
        self.navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(done)), animated: true)
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        self.navigationItem.setRightBarButton(actionButton, animated: true)

        if cloudWordDictsFunction != nil {
            // test:(()->(Bool))?
            self.process(work: { [weak self] () -> (Any?) in
                self?.cloudWordDicts = self?.cloudWordDictsFunction?()

                self?.wordsTableViewController.section.strings = self?.cloudWordDicts?.map({ (dict:[String:Any]) -> String in
                    let word = dict["word"] as? String ?? "ERROR"
                    let count = dict["count"] as? Int ?? -1
                    return "\(word) (\(count))"
                })
                
                self?.wordsTableViewController.section.strings = self?.wordsTableViewController.section.function?(self?.wordsTableViewController.section.method,self?.wordsTableViewController.section.strings)
                
                return nil
            }, completion: { [weak self] (data:Any?) in
                self?.cancelAndRelayoutCloudWords()
                self?.wordsTableViewController.tableView.isHidden = false
                self?.wordsTableViewController.tableView.reloadData()
            })
        } else {
            self.cancelAndRelayoutCloudWords()
            self.wordsTableViewController.tableView.isHidden = false
            self.wordsTableViewController.tableView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        cancelAllOperations()
        
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func removeCloudWords()
    {
        // Remove cloud words (UILabels)
        var removableLabels = [UILabel]()

        for subview in cloudView.subviews {
            if let label = subview as? UILabel {
                removableLabels.append(label)
            }
        }

        removableLabels.forEach { (label:UILabel) in
            label.removeFromSuperview()
        }
        
        if cloudDebug {
            // Remove bounding boxes
            var removableLayers = [CALayer]()
            
            if let sublayers = cloudView.layer.sublayers {
                for sublayer in sublayers {
                    if sublayer.borderWidth > 0, sublayer.delegate == nil {
                        removableLayers.append(sublayer)
                    }
                }
            }
            
            removableLayers.forEach { (layer:CALayer) in
                layer.removeFromSuperlayer()
            }
        }
    }
    
    @objc func cancelAndRelayoutCloudWords()
    {
        // Cancel any in-progress layout
        layoutQueue.cancelAllOperations()
        
        labelQueue.cancelAllOperations()
        
        relayoutCloudWords()
    }
    
    func relayoutCloudWords()
    {
        labelQueue.addOperation {
            self.removeCloudWords()
        }
        
        self.layoutCloudWords()
    }
    
    func layoutCloudWords()
    {
        cloudColors = CloudColors.GreenBlue
        
//        cloudView.backgroundColor = UIColor.white
        
        if let cloudWordDicts = cloudWordDicts?.filter({ (dict:[String:Any]) -> Bool in
            return (dict["selected"] as? Bool) ?? false
        }), cloudWordDicts.count > 0 {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
            let newCloudLayoutOperation = CloudLayoutOperation(cloudWordDicts:cloudWordDicts,
                                                               title:cloudTitle,
                                                               containerSize:cloudView.bounds.size,
                                                               containerScale:UIScreen.main.scale,
                                                               cloudFont: cloudFont,
                                                               orientation: wordOrientation.selectedSegmentIndex,
                                                               delegate:self)
            
            layoutQueue.addOperation(newCloudLayoutOperation)
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            dvc = visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_WORD_LIST:
                if let destination = dvc as? PopoverTableViewController {
                    wordsTableViewController = destination
                    
                    wordsTableViewController.allowsMultipleSelection = true
                    wordsTableViewController.selection = { [weak self] (index:Int) -> Bool in
                        guard let cloudWordDicts = self?.cloudWordDicts else {
                            return false
                        }
                        
                        guard let string = self?.wordsTableViewController.section.strings?[index] else {
                            return false
                        }
                        
                        guard let word = string.word else {
                            return false
                        }
                        
                        guard let frequency = string.frequency else {
                            return false
                        }
                        
                        var index = 0
                        
                        for cloudWordDict in cloudWordDicts {
                            if ((cloudWordDict["word"] as? String) == word) && ((cloudWordDict["count"] as? Int) == frequency) { // Int(count)
                                return (cloudWordDicts[index]["selected"] as? Bool) ?? false
                            }
                            
                            index += 1
                        }
                        
                        return false
                    }
                    wordsTableViewController.segments = true
                    
                    wordsTableViewController.section.function = { [weak self] (method:String?,strings:[String]?) in
                        return strings?.sort(method: method)
                    }
                    
                    wordsTableViewController.bottomBarButton = true
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMain { [weak self] in 
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                            }
                            
                            self?.cloudWordDicts = self?.cloudWordDicts?.sorted(by: { (first:[String:Any], second:[String:Any]) -> Bool in
                                let firstWord = first["word"] as? String
                                let secondWord = second["word"] as? String
                                
                                let firstCount = first["count"] as? Int
                                let secondCount = second["count"] as? Int
                                
                                if firstWord == secondWord {
                                    return firstCount > secondCount
                                } else {
                                    return firstWord < secondWord
                                }
                            })
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Alphabetical,self?.wordsTableViewController.section.strings)

                            Thread.onMain { [weak self] in 
                                guard let wordsTableViewController = self?.wordsTableViewController else {
                                    return
                                }
                                
                                if wordsTableViewController.segmentedControl.selectedSegmentIndex == 0 {
                                    if let section = wordsTableViewController.section {
                                        section.method = Constants.Sort.Alphabetical
                                        section.showHeaders = false
                                        section.showIndex = true
                                        section.indexStringsTransform = nil
                                        section.indexHeadersTransform = nil
                                        section.indexSort = nil
                                        
                                        section.strings = strings
                                        section.stringsAction?(strings,section.sorting)
                                    }
                                    
                                    wordsTableViewController.tableView.reloadData()
                                }
                                
                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.activityIndicator.stopAnimating()
                                wordsTableViewController.segmentedControl.isEnabled = true
                            }
                        }
                    }))
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: { [weak self] in
                        // Cancel or wait?
                        self?.operationQueue.cancelAllOperations()
                        
                        self?.operationQueue.addOperation { [weak self] in
                            Thread.onMain { [weak self] in 
                                self?.wordsTableViewController.tableView.isHidden = true
                                self?.wordsTableViewController.activityIndicator.startAnimating()
                                self?.wordsTableViewController.segmentedControl.isEnabled = false
                            }
                            
                            self?.cloudWordDicts = self?.cloudWordDicts?.sorted(by: { (first:[String:Any], second:[String:Any]) -> Bool in
                                let firstWord = first["word"] as? String
                                let secondWord = second["word"] as? String
                                
                                let firstCount = first["count"] as? Int
                                let secondCount = second["count"] as? Int
                                
                                if firstCount == secondCount {
                                    return firstWord < secondWord
                                } else {
                                    return firstCount > secondCount
                                }
                            })
                            
                            let strings = self?.wordsTableViewController.section.function?(Constants.Sort.Frequency,self?.wordsTableViewController.unfilteredSection.strings)

                            Thread.onMain { [weak self] in 
                                guard let wordsTableViewController = self?.wordsTableViewController else {
                                    return
                                }
                                
                                if wordsTableViewController.segmentedControl.selectedSegmentIndex == 1 {
                                    if let section = wordsTableViewController.section {
                                        section.method = Constants.Sort.Frequency
                                        section.showHeaders = false
                                        section.showIndex = true
                                        section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                                            return string?.log
                                        }
                                        section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                                            return string
                                        }
                                        section.indexSort = { [weak self] (first:String?,second:String?) -> Bool in
                                            guard let first = first else {
                                                return false
                                            }
                                            guard let second = second else {
                                                return true
                                            }
                                            return Int(first) > Int(second)
                                        }
                                        
                                        section.strings = strings
                                        section.stringsAction?(strings,section.sorting)
                                    }
                                    
                                    wordsTableViewController.tableView.reloadData()
                                }

                                wordsTableViewController.tableView.isHidden = false
                                wordsTableViewController.activityIndicator.stopAnimating()
                                wordsTableViewController.segmentedControl.isEnabled = true
                            }
                        }
                    }))
                    
                    wordsTableViewController.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    wordsTableViewController.delegate = self
                    wordsTableViewController.purpose = .selectingWordCloud
                    
                    wordsTableViewController.search = false
                    
                    wordsTableViewController.section.stringsAction = { [weak self] (strings:[String]?,sorting:Bool) in
                        Thread.onMain { [weak self] in 
                            self?.wordsTableViewController.segmentedControl?.isEnabled = (strings != nil) && (sorting == false)
                        }
                    }

                    wordsTableViewController.section.method = Constants.Sort.Frequency
                    wordsTableViewController.section.showIndex = true
                    wordsTableViewController.section.indexStringsTransform = { [weak self] (string:String?) -> String? in
                        return string?.log
                    }
                    wordsTableViewController.section.indexHeadersTransform = { [weak self] (string:String?) -> String? in
                        return string
                    }
                    wordsTableViewController.section.indexSort = { [weak self] (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) > Int(second)
                    }

                    wordsTableViewController.section.strings = self.cloudWordDicts?.map({ (dict:[String:Any]) -> String in
                        let word = dict["word"] as? String ?? "ERROR"
                        let count = dict["count"] as? Int ?? -1
                        return "\(word) (\(count))"
                    })
                    
                    wordsTableViewController.section.strings = wordsTableViewController.section.function?(wordsTableViewController.section.method,wordsTableViewController.section.strings)
                    
                    if let method = wordsTableViewController.section.method {
                        switch method {
                        case Constants.Sort.Alphabetical:
                            self.cloudWordDicts = self.cloudWordDicts?.sorted(by: { (first:[String:Any], second:[String:Any]) -> Bool in
                                let firstWord = first["word"] as? String
                                let secondWord = second["word"] as? String
                                
                                let firstCount = first["count"] as? Int
                                let secondCount = second["count"] as? Int
                                
                                if firstWord == secondWord {
                                    return firstCount > secondCount
                                } else {
                                    return firstWord < secondWord
                                }
                            })
                            
                        case Constants.Sort.Frequency:
                            self.cloudWordDicts = self.cloudWordDicts?.sorted(by: { (first:[String:Any], second:[String:Any]) -> Bool in
                                let firstWord = first["word"] as? String
                                let secondWord = second["word"] as? String
                                
                                let firstCount = first["count"] as? Int
                                let secondCount = second["count"] as? Int
                                
                                if firstCount == secondCount {
                                    return firstWord < secondWord
                                } else {
                                    return firstCount > secondCount
                                }
                            })
                            
                        default:
                            break
                        }
                    }
                }
                break
                
            default:
                break
            }
        }
    }
}










