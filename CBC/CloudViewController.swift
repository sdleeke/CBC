//
//  CloudViewController.swift
//  CBC
//
//  Created by Steve Leeke on 12/9/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

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

class CloudViewController: UIViewController, CloudLayoutOperationDelegate, PopoverTableViewControllerDelegate, UIScrollViewDelegate
{
    var cloudLayoutOperationQueue : OperationQueue?
    
    @IBOutlet weak var selectAllButton: UIButton!
    @IBAction func selectAllAction(_ sender: UIButton)
    {
        guard var cloudWords = cloudWords else {
            return
        }
        
        for index in 0..<cloudWords.count {
            cloudWords[index]["selected"] = true
            if let word = cloudWords[index]["word"] as? String, let indexPath = ptvc.section.indexPath(from: word) {
                ptvc.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        
        self.cloudWords = cloudWords
        
        cancelAndRelayoutCloudWords()
    }
    
    @IBOutlet weak var selectNoneButton: UIButton!
    @IBAction func selectNoneAction(_ sender: UIButton)
    {
        guard var cloudWords = cloudWords else {
            return
        }
        
        for index in 0..<cloudWords.count {
            cloudWords[index]["selected"] = nil
            if let word = cloudWords[index]["word"] as? String, let indexPath = ptvc.section.indexPath(from: word) {
                ptvc.tableView?.deselectRow(at: indexPath, animated: true)
            }
        }
        
        self.cloudWords = cloudWords

        cancelAndRelayoutCloudWords()
    }
    
    @IBOutlet weak var cloudView: UIView!
    
    var allowVertical = true
    var maxWords = 0
    var minFrequency = 0
    
    var cloudTitle : String?
    var cloudColors : [UIColor]? = CloudColors.GreenBlue
    var cloudFont : UIFont?
    var cloudWords : [[String:Any]]?
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return cloudView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let selectTap = UITapGestureRecognizer(target: self, action: #selector(CloudViewController.selectCloudWord(_:)))
        selectTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(selectTap)
        
        let layoutTap = UITapGestureRecognizer(target: self, action: #selector(CloudViewController.cancelAndRelayoutCloudWords))
        layoutTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(layoutTap)
        
        selectTap.require(toFail: layoutTap)
        
        cloudLayoutOperationQueue = OperationQueue()
        cloudLayoutOperationQueue?.name = "Cloud layout operation queue"
        cloudLayoutOperationQueue?.maxConcurrentOperationCount = 1;
    }
    
    func selectCloudWord(_ tap:UITapGestureRecognizer)
    {
        switch tap.state {
        case .began:
            break
            
        case .ended:
            let location = tap.location(in: cloudView)
            for view in cloudView.subviews {
                if let label = view as? UILabel {
                    if label.frame.contains(location) {
                        print(label.text)
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
    
    func contentSizeCategoryDidChange()
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
    
    func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    func share()
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0.0)

        let success = view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)

        if (success) {
            let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
            
//            NSURL *appURL = [NSURL URLWithString:@"https://itunes.apple.com/app/lion-lamb-admiring-jesus-christ/id1018992236?mt=8&at=1010l3f4"];

            let activityViewController = UIActivityViewController(activityItems: [snapshotImage], applicationActivities: nil)
            
            // Exclude AirDrop, as it appears to delay the initial appearance of the activity sheet
            activityViewController.excludedActivityTypes = [UIActivityType.airDrop]
            
            let popoverPresentationController = activityViewController.popoverPresentationController
            
            popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            present(activityViewController, animated: true, completion: nil)
        }
        UIGraphicsEndImageContext();
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        navigationItem.title = cloudTitle
        
        navigationItem.setLeftBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(CloudViewController.done)), animated: true)
        
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(CloudViewController.share)), animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(self.contentSizeCategoryDidChange), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        cancelAndRelayoutCloudWords()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        cloudLayoutOperationQueue?.cancelAllOperations()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
//    func insertTitle(cloudTitle:String)
//    {
//        updateCloudTitle(cloudTitle)
//    }
    
//    func updateCloudTitle(_ newTitle:String)
//    {
//        navigationItem.title = newTitle
//    }

    func insertWord(word:String, pointSize:CGFloat, color:Int, center:CGPoint, isVertical:Bool)
    {
        guard let color = cloudColors?[color] else {
            return
        }
        
        let wordLabel = UILabel(frame: CGRect.zero)
        
        wordLabel.text = word
        wordLabel.textAlignment = .center
        wordLabel.font = cloudFont?.withSize(pointSize)
        
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
        
        //#ifdef DEBUG
        //    wordLabel.layer.borderColor = [UIColor redColor].CGColor;
        //    wordLabel.layer.borderWidth = 1;
        //#endif
        
        cloudView.addSubview(wordLabel)
    }
    
    func insertBoundingRect(boundingRect:CGRect)
    {
        let layer = CALayer()

        layer.frame = boundingRect

        layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5).cgColor

        layer.borderWidth = 1;

        cloudView.layer.addSublayer(layer)
    }
    
    let debug = false
    
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
        
        if debug {
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
    
    func cancelAndRelayoutCloudWords()
    {
        // Cancel any in-progress layout
        cloudLayoutOperationQueue?.cancelAllOperations()
        cloudLayoutOperationQueue?.waitUntilAllOperationsAreFinished()
        
        Thread.onMainThread{
            self.removeCloudWords()
        }
        
        layoutCloudWords()
    }
    
    func relayoutCloudWords()
    {
        Thread.onMainThread{
            self.removeCloudWords()
        }
        
        layoutCloudWords()
    }
    
    func layoutCloudWords()
    {
        cloudColors = CloudColors.GreenBlue
        
        cloudView.backgroundColor = UIColor.white
        
        if let cloudWords = cloudWords?.filter({ (dict:[String:Any]) -> Bool in
            if let selected = dict["selected"] as? Bool, selected {
                return true
            } else {
                return false
            }
        }), cloudWords.count > 0 {
            let newCloudLayoutOperation = CloudLayoutOperation(cloudWords:cloudWords,
                                                               title:cloudTitle,
                                                               containerSize:cloudView.bounds.size,
                                                               containerScale:UIScreen.main.scale,
                                                               cloudFont: cloudFont,
                                                               delegate:self)
            
            cloudLayoutOperationQueue?.addOperation(newCloudLayoutOperation)
        }
    }
    
    var ptvc:PopoverTableViewController!
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard let cloudWords = cloudWords else {
            return
        }
        
        guard let string = strings?[index] else {
            return
        }
        
        guard let startRange = string.range(of: " (") else {
            return
        }
        
        let word = string.substring(to: startRange.lowerBound)
        let remainder = string.substring(from: startRange.upperBound)
        
        guard let endRange = remainder.range(of: ")") else {
            return
        }

        let count = remainder.substring(to: endRange.lowerBound)
        
        var index = 0
        
        for cloudWord in cloudWords {
            if ((cloudWord["word"] as? String) == word) && ((cloudWord["count"] as? Int) == Int(count)) {
                if let selected = self.cloudWords?[index]["selected"] as? Bool, selected {
                    self.cloudWords?[index]["selected"] =  nil
                } else {
                    self.cloudWords?[index]["selected"] =  true
                }
                break
            }
            
            index += 1
        }

        Thread.onMainThread {
            self.cancelAndRelayoutCloudWords()
        }
    }
    
//    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
//    {
//        var actions = [AlertAction]()
//
//        var action:AlertAction!
//
//        action = AlertAction(title: "Select All Above", style: .default) {
//
//        }
//        actions.append(action)
//
//        action = AlertAction(title: "Deselect All Above", style: .default) {
//
//        }
//        actions.append(action)
//
//        action = AlertAction(title: "Select All Below", style: .default) {
//
//        }
//        actions.append(action)
//
//        action = AlertAction(title: "Deselect All Below", style: .default) {
//
//        }
//        actions.append(action)
//
//        return actions.count > 0 ? actions : nil
//    }

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
                    ptvc = destination
                    
                    ptvc.allowsMultipleSelection = true
                    
                    ptvc.segments = true
                    
//                    ptvc.editActionsAtIndexPath = rowActions
                    
                    ptvc.sort.function = { (method:String?,strings:[String]?) -> [String]? in
                        guard let strings = strings else {
                            return nil
                        }
                        
                        guard let method = method else {
                            return nil
                        }
                        
                        switch method {
                        case Constants.Sort.Alphabetical:
                            return strings.sorted()
                            
                        case Constants.Sort.Frequency:
                            return strings.sorted(by: { (first:String, second:String) -> Bool in
                                if let rangeFirst = first.range(of: " ("), let rangeSecond = second.range(of: " (") {
                                    let left = first.substring(from: rangeFirst.upperBound)
                                    let right = second.substring(from: rangeSecond.upperBound)
                                    
                                    let first = first.substring(to: rangeFirst.lowerBound)
                                    let second = second.substring(to: rangeSecond.lowerBound)
                                    
                                    if let rangeLeft = left.range(of: ")"), let rangeRight = right.range(of: ")") {
                                        let left = left.substring(to: rangeLeft.lowerBound)
                                        let right = right.substring(to: rangeRight.lowerBound)
                                        
                                        if let left = Int(left), let right = Int(right) {
                                            if left == right {
                                                return first < second
                                            } else {
                                                return left > right
                                            }
                                        }
                                    }
                                    
                                    return false
                                } else {
                                    return false
                                }
                            })
                            
                        default:
                            return nil
                        }
                    }
                    
                    ptvc.sort.method = Constants.Sort.Alphabetical
                    
                    var segmentActions = [SegmentAction]()
                    
                    segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: {
                        self.ptvc.sort.method = Constants.Sort.Alphabetical
                        self.ptvc.section.showIndex = true
                        self.ptvc.tableView.isHidden = true
                        self.ptvc.activityIndicator.startAnimating()
                        self.ptvc.segmentedControl.isEnabled = false

                        DispatchQueue.global(qos: .background).async { [weak self] in
                            self?.ptvc.section.strings = self?.ptvc.sort.function?(self?.ptvc.sort.method,self?.ptvc.section.strings)
                            Thread.onMainThread(block: { (Void) -> (Void) in
                                self?.ptvc.tableView.isHidden = false
                                self?.ptvc.tableView.reloadData()
                                self?.ptvc.activityIndicator.stopAnimating()
                                self?.ptvc.segmentedControl.isEnabled = true
                                
                                guard var cloudWords = self?.cloudWords else {
                                    return
                                }
                                
                                for index in 0..<cloudWords.count {
                                    if let word = cloudWords[index]["word"] as? String, let indexPath = self?.ptvc.section.indexPath(from: word) {
                                        if let selected = cloudWords[index]["selected"] as? Bool, selected {
                                            self?.ptvc.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                        } else {
                                            self?.ptvc.tableView?.deselectRow(at: indexPath, animated: true)
                                        }
                                    }
                                }
                            })
                        }
                    }))
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                        self.ptvc.sort.method = Constants.Sort.Frequency
                        self.ptvc.section.showIndex = false
                        self.ptvc.tableView.isHidden = true
                        self.ptvc.activityIndicator.startAnimating()
                        self.ptvc.segmentedControl.isEnabled = false

                        DispatchQueue.global(qos: .background).async { [weak self] in
                            self?.ptvc.section.strings = self?.ptvc.sort.function?(self?.ptvc.sort.method,self?.ptvc.section.strings)
                            Thread.onMainThread(block: { (Void) -> (Void) in
                                self?.ptvc.tableView.isHidden = false
                                self?.ptvc.tableView.reloadData()
                                self?.ptvc.activityIndicator.stopAnimating()
                                self?.ptvc.segmentedControl.isEnabled = true
                                
                                guard var cloudWords = self?.cloudWords else {
                                    return
                                }
                                
                                for index in 0..<cloudWords.count {
                                    if let word = cloudWords[index]["word"] as? String, let indexPath = self?.ptvc.section.indexPath(from: word) {
                                        if let selected = cloudWords[index]["selected"] as? Bool, selected {
                                            self?.ptvc.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                        } else {
                                            self?.ptvc.tableView?.deselectRow(at: indexPath, animated: true)
                                        }
                                    }
                                }
                            })
                        }
                    }))
                    
                    ptvc.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    ptvc.delegate = self
                    ptvc.purpose = .selectingWordCloud
                    
                    ptvc.search = false
                    ptvc.segments = true
                    
                    ptvc.section.showIndex = true
                    
                    ptvc.section.strings = self.cloudWords?.map({ (dict:[String:Any]) -> String in
                        let word = dict["word"] as? String ?? "ERROR"
                        let count = dict["count"] as? Int ?? -1
                        return "\(word) (\(count))"
                    })
                    
                    ptvc.section.strings = ptvc.sort.function?(ptvc.sort.method,ptvc.section.strings)
                }
                break
                
            default:
                break
            }
        }
    }
}











