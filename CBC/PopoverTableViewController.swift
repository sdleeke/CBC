//
//  PopoverTableViewController.swift
//  CBC
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
}

extension PopoverTableViewController : UIAdaptivePresentationControllerDelegate
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

extension PopoverTableViewController: UISearchBarDelegate
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
    
    func updateSearchResults()
    {
        guard searchActive else {
            return
        }
        
        guard let text = searchText else { // , !text.isEmpty
            return
        }
        
        // update the search result array by filtering….
        if let keys = unfilteredSection.stringIndex?.keys {
            var filteredStringIndex = [String:[String]]()
            
            for key in keys {
                if let values = unfilteredSection.stringIndex?[key] {
                    for value in values {
                        if value.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil {
                            if filteredStringIndex[key] == nil {
                                filteredStringIndex[key] = [String]()
                            }
                            filteredStringIndex[key]?.append(value)
                        }
                    }
                }
            }
            
            filteredSection.stringIndex = filteredStringIndex.keys.count > 0 ? filteredStringIndex : nil
        } else
            
        if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
            return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }) {
            filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
            
            //                print(self.filteredStrings)
            
            //                filteredSection.buildIndex()
        }
        
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        searchActive = true
        
        // To make sure we start out right
        filteredSection.showIndex = unfilteredSection.showIndex
        filteredSection.showHeaders = unfilteredSection.showHeaders
        filteredSection.indexStringsTransform = unfilteredSection.indexStringsTransform
        filteredSection.indexHeadersTransform = unfilteredSection.indexHeadersTransform
        
        searchBar.showsCancelButton = true
        
        searchText = searchBar.text

        updateSearchResults()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
        searchText = searchBar.text

        updateSearchResults()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        self.searchText = searchBar.text

        updateSearchResults()
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
        
        tableView.reloadData()

//        print(searchController?.isActive)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false
        
        // In case they've changed
        unfilteredSection.showIndex = filteredSection.showIndex
        unfilteredSection.showHeaders = filteredSection.showHeaders

        // In case the method changed
        if let function = sort.function {
            section.strings = function(sort.method,section.strings)
        }

//        section.buildIndex()
        
        searchBar.showsCancelButton = false
       
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        tableView.reloadData()
        
        if purpose == .selectingTime {
            follow()
        }
        
        filteredSection = Section()
    }
}

extension PopoverTableViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard Thread.isMainThread else {
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingSorting:
            sort.method = string
            
            switch string {
            case Constants.Sort.Alphabetical:
                section.showIndex = true
                break
                
            case Constants.Sort.Frequency:
                section.showIndex = false
                break
                
            default:
                break
            }
            
            if let function = sort.function {
                section.strings = function(sort.method,section.strings)
            }
            
//            section.buildIndex()
            
            tableView.reloadData()
            break

        default:
            break
        }
    }
}

extension PopoverTableViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

struct Sort
{
    var function : ((String,[String]?)->[String]?)?
    
    var method : String = Constants.Sort.Alphabetical
    {
        willSet {
            
        }
        didSet {
            if method != oldValue {
//                print(method)
            }
        }
    }
}

struct SegmentAction {
    var title:String?
    var position:Int
    var action:((Void)->(Void))?
}

class PopoverTableViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class PopoverTableViewController : UIViewController
{
    var vc:UIViewController?
    
    var changesPending = false
    
    var selectedText:String!
    
//    var detail = false
    
    var detailAction:((UITableView,IndexPath)->(Void))?
    var detailDisclosure:((UITableView,IndexPath)->(Bool))?
    
    var editActionsAtIndexPath : ((PopoverTableViewController,UITableView,IndexPath)->([UITableViewRowAction]?))?
    
    var sort = Sort()
 
//    var startTimes:[Double]?
    
    func stopTracking()
    {
        guard track else {
            return
        }
        
        globals.mediaPlayer.pause()
        
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    func startTracking()
    {
        guard track else {
            return
        }
        
        globals.mediaPlayer.play()
        
        if trackingTimer == nil {
            if let indexPath = tableView.indexPathForSelectedRow {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            
            trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PopoverTableViewController.follow), userInfo: nil, repeats: true)
        } else {
            print("ERROR: trackingTimer not nil!")
        }
    }
    
    var lastFollow : IndexPath?
    
    func follow()
    {
//        guard let startTimes = startTimes else {
//            return
//        }
        
        guard let srtComponents = section.strings else {
            return
        }
        
        guard let seconds = globals.mediaPlayer.currentTime?.seconds else {
            return
        }
        
        // Since the sequence of timed segments is non-overlapping and not guaranteed to be continuous, there may be gaps.
        // That is, seconds may fall in the gap between two rows.

        var timeWindowFound = false
        
        var index = 0
        
//            print("seconds: ",seconds)

        for srtComponent in srtComponents {
//                print("startTime: ",startTime)
//                print(seconds,startTime)
            var srtArray = srtComponent.components(separatedBy: "\n")
            
            if let count = srtArray.first, !count.isEmpty {
                srtArray.remove(at: 0)
            }
            
            if let timeWindow = srtArray.first, !timeWindow.isEmpty {
                srtArray.remove(at: 0)
                
                if  let start = timeWindow.components(separatedBy: " to ").first,
                    let end = timeWindow.components(separatedBy: " to ").last {
                    
//                    print(hmsToSeconds(string: start),seconds,hmsToSeconds(string: end))
                    
                    if (seconds >= hmsToSeconds(string: start)) && (seconds <= hmsToSeconds(string: end))  {
                        timeWindowFound = true
                        break
                    } else {
                        if (seconds < hmsToSeconds(string: start))  {
                            timeWindowFound = true
                            break
                        }
                    }
                }
            }

            index += 1
        }
//        index -= 1
        
        index = max(index,0)
        
//            print("Row: ",row-1)

        if self.section.counts?.count == self.section.indexes?.count {
            var section = 0
            
            while section < self.section.counts?.count, (index >= (self.section.indexes![section] + self.section.counts![section])) {
                section += 1
            }
            
            if section < self.section.indexes?.count, let sectionIndex = self.section.indexes?[section] {

                let row = index - sectionIndex

                if (section >= 0) && (section < tableView.numberOfSections) && (row >= 0) && (row < tableView.numberOfRows(inSection: section)) {
                    let indexPath = IndexPath(row: row, section: section)
                    
                    if timeWindowFound {
                        if tableView.indexPathForSelectedRow != indexPath {
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                        }
                    } else {
                        if let lastFollow = lastFollow, indexPath != lastFollow {
                            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        }
                    }

                    lastFollow = indexPath
                } else {
                    print("CELL NOT FOUND")
                }
            } else {
                print("CELL NOT FOUND")
            }
        }
    }
    
    func tracking()
    {
        isTracking = !isTracking
        
//        if isTracking {
//            globals.mediaPlayer.pause()
//            
//            if let count = navigationItem.leftBarButtonItems?.count {
//                navigationItem.leftBarButtonItems?[count - 1].title = "Sync"
//            }
//            
//            isTracking = false
//            trackingTimer?.invalidate()
//            trackingTimer = nil
//        } else {
//            globals.mediaPlayer.play()
//            
//            if let count = navigationItem.leftBarButtonItems?.count {
//                navigationItem.leftBarButtonItems?[count - 1].title = "Stop"
//            }
//
//            if trackingTimer != nil {
//                isTracking = true
//                
//                if let indexPath = tableView.indexPathForSelectedRow {
//                    self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
//                }
//                
//                trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PopoverTableViewController.follow), userInfo: nil, repeats: true)
//            } else {
//                print("ERROR: trackingTimer not nil!")
//            }
//        }
    }
    
    var assist = false
    
    var track = false
    {
        didSet {
//            if track { //  && globals.mediaPlayer.isPlaying
//                var strings : [String]?
//                
//                if let stringsFunction = stringsFunction {
//                    strings = stringsFunction()
//                } else {
//                    strings = section.strings
//                }
//                
//                startTimes = strings?.filter({ (string:String) -> Bool in
//                    return string.components(separatedBy: "\n").count > 1
//                }).map({ (string:String) -> Double in
//                    var srtArray = string.components(separatedBy: "\n")
//                    
//                    if let count = srtArray.first, !count.isEmpty {
//                        srtArray.remove(at: 0)
//                    }
//                    
//                    if let timeWindow = srtArray.first, !timeWindow.isEmpty {
//                        srtArray.remove(at: 0)
//                        
//                        let start = timeWindow.components(separatedBy: " to ").first
//                        //                    let end = timeWindow.components(separatedBy: " to ").last
//                        
//                        return hmsToSeconds(string: start)!
//                    }
//                    
//                    return 0.0
//                })
//            }
        }
    }

    func removeTracking()
    {
        guard track else {
            return
        }
        
        isTracking = false
        stopTracking()
        
        syncButton.isEnabled = false
        
//        navigationItem.rightBarButtonItems = [doneButton,assistButton]
    }
    
    func restoreTracking()
    {
        guard track else {
            return
        }
        
        if isTracking {
            startTracking()
        }

        syncButton.isEnabled = true
        
//        if navigationItem.rightBarButtonItems != nil {
//            navigationItem.rightBarButtonItems?.append(syncButton)
//        } else {
//            navigationItem.rightBarButtonItem = syncButton
//        }
    }
    
    func removeAssist()
    {
        guard assist else {
            return
        }
        
        assistButton.isEnabled = false
        
//        navigationItem.rightBarButtonItems = [doneButton,syncButton]
    }
    
    func restoreAssist()
    {
        guard assist else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        assistButton.isEnabled = true
        
//        if navigationItem.rightBarButtonItems != nil {
//            navigationItem.rightBarButtonItems?.append(assistButton)
//        } else {
//            navigationItem.rightBarButtonItem = assistButton
//        }
    }
    
    var isTracking = false
    {
        didSet {
            if isTracking != oldValue {
                if !isTracking {
                    syncButton.title = "Sync"
                    stopTracking()
                    restoreAssist()
                }
                
                if isTracking {
                    syncButton.title = "Stop"
                    startTracking()
                    removeAssist()
                }
            }

//            if isTracking {
//                globals.mediaPlayer.pause()
//                
//                if let count = navigationItem.leftBarButtonItems?.count {
//                    navigationItem.leftBarButtonItems?[count - 1].title = "Sync"
//                }
//                
//                isTracking = false
//                trackingTimer?.invalidate()
//                trackingTimer = nil
//            } else {
//                globals.mediaPlayer.play()
//                
//                if let count = navigationItem.leftBarButtonItems?.count {
//                    navigationItem.leftBarButtonItems?[count - 1].title = "Stop"
//                }
//                
//                if trackingTimer != nil {
//                    isTracking = true
//                    
//                    if let indexPath = tableView.indexPathForSelectedRow {
//                        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
//                    }
//                    
//                    trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(PopoverTableViewController.follow), userInfo: nil, repeats: true)
//                } else {
//                    print("ERROR: trackingTimer not nil!")
//                }
//            }
        }
    }
    
    var trackingTimer : Timer?
    
    var doneButton : UIBarButtonItem!
    var syncButton : UIBarButtonItem!
    var assistButton : UIBarButtonItem!
        
    var search          = false
        
    var searchActive    = false
    {
        didSet {
            if searchActive != oldValue {
                if searchActive {
                    removeTracking()
                } else {
                    restoreTracking()
                }
            }

//            if searchActive {
//                if track {
//                    navigationItem.leftBarButtonItems = nil
//                    trackingTimer?.invalidate()
//                    trackingTimer = nil
//                    isTracking = false
//                }
//            } else {
//                if track { //  && globals.mediaPlayer.isPlaying
//                    if isTracking {
//                        syncButton.title = "Stop"
//                    } else {
//                        syncButton.title = "Sync"
//                    }
//                }
//            }
        }
    }
        
    var searchText      : String?
    var wholeWordsOnly  = false
    
    var searchInteractive = true
    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(PopoverTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "PopoverTableViewController")
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    {
        didSet {
            if segments {
                segmentedControl.removeAllSegments()
                
                if let segmentActions = segmentActions {
                    for segmentAction in segmentActions {
                        segmentedControl.insertSegment(withTitle: segmentAction.title, at: segmentAction.position, animated: false)
                    }
                    
                    if segmentActions.count > 0 {
                        segmentedControl.selectedSegmentIndex = 0
                    }
                }
            }
        }
    }

    @IBAction func segmentedControlAction(_ sender: UISegmentedControl)
    {
        if let segmentActions = segmentActions {
            for segmentAction in segmentActions {
                if segmentAction.position == segmentedControl.selectedSegmentIndex {
                    segmentAction.action?()
                    break
                }
            }
        }
    }
    
    var segments = false
    var segmentActions:[SegmentAction]?
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedMediaItem:MediaItem?
    
    var transcript:VoiceBase?
    
    var stringsFunction:((Void)->[String]?)?
    
    var stringsAny : [String:Any]?
    var stringsArray : [String]?
    var stringsAnyArray : [[String:Any]]?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var shouldSelect:((IndexPath)->Bool)?
    var didSelect:((IndexPath)->Void)?
    
    var mediaListGroupSort:MediaListGroupSort?
    
    var indexStringsTransform:((String?)->String?)? = stringWithoutPrefixes {
        willSet {
            
        }
        didSet {
            filteredSection.indexStringsTransform = indexStringsTransform
            unfilteredSection.indexStringsTransform = indexStringsTransform
        }
    }
    
    var filteredSection = Section()
    var unfilteredSection = Section()
    
    var section:Section! {
        get {
            if searchActive {
                return filteredSection
            } else {
                return unfilteredSection
            }
        }
        set {
            if searchActive {
                filteredSection = newValue
            } else {
                unfilteredSection = newValue
            }
        }
    }
    
    var parser:((String)->([String]))?
    
    func setPreferredContentSize()
    {
        guard self.navigationController?.modalPresentationStyle == .popover else {
            return
        }
        
        guard Thread.isMainThread else {
            return
        }

        guard (vc != nil) else {
            return
        }
        
        guard (section.strings != nil) else {
            return
        }
        
        preferredContentSize = CGSize(width: 0, height: 0)

        let margins:CGFloat = 2
        let marginSpace:CGFloat = 20
        
        let checkmarkSpace:CGFloat = 38
        let indexSpace:CGFloat = 40
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        var deducts:CGFloat = 0
        
        deducts += margins * marginSpace
        
        if section.showIndex {
            deducts += indexSpace
        }
        
        switch self.purpose! {
        case .selectingCategory:
            fallthrough
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            deducts += checkmarkSpace
            break
            
        default:
            break
        }
        
        let viewWidth = vc!.view.frame.width
        
        //        print(view.frame.width - deducts)
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
        
        if let title = self.navigationItem.title, !title.isEmpty {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width
            
            if let left = navigationItem.leftBarButtonItem?.title {
                let string = left.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                width += string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil).width + 20
            }
            
            if let right = navigationItem.rightBarButtonItem?.title {
                let string = right.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                width += string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil).width + 20
            }
        }
        
        //        print(strings)
        
        for string in self.section.strings! {
            if let strings = parser != nil ? parser?(string) : [string] {
                for stringInStrings in strings {
                    let maxHeight = stringInStrings.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
                    
                    //                let string = stringInStrings.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                    
                    let maxWidth = stringInStrings.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
                    
                    //            print(string)
                    //            print(maxSize)
                    
                    //            print(string,width,maxWidth.width)
                    
                    if maxWidth.width > width {
                        width = maxWidth.width
                    }
                    
                    //            print(string,maxHeight.height) // baseHeight
                    
                    if tableView.rowHeight != -1 {
                        height += tableView.rowHeight
                    } else {
                        height += 2*8 + maxHeight.height // - baseHeight
                    }
                    
                    //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
                }
            }
        }

        // Did not set width correctly.  Header views probably depends upon overall size, so these will not be setup correctly at this point.
//        for section in 0..<tableView.numberOfSections {
//            if let frame = tableView.headerView(forSection: section)?.frame {
//                if frame.width > width {
//                    width = frame.width
//                }
//            }
//        }
        
        if self.section.showIndex || self.section.showHeaders, let headers = self.section.headers {
            for header in headers {
                let maxWidth = header.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width // + 20
                if maxWidth > width {
                    width = maxWidth
                }
            }
        }
        
        width += margins * marginSpace
        
        switch self.purpose! {
        case .selectingCategory:
            fallthrough
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            width += checkmarkSpace
            break
            
        default:
            break
        }
        
        if self.section.showIndex {
            width += indexSpace
        }
        
        if self.section.showIndex || self.section.showHeaders {
            height += self.tableView.sectionHeaderHeight * CGFloat(self.section.headers!.count)
        }
        
//        print(height)
//        print(width)
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    var isRefreshing = false
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:handleRefresh",completion:nil)
            return
        }
        
        refreshControl.beginRefreshing()
        
        self.isRefreshing = true

        if self.refresh != nil {
            self.refresh?()
        } else {
            DispatchQueue.global(qos: .background).async {
                self.lexiconUpdated()
            }
        }
    }
    
    var refreshControl:UIRefreshControl?
    var refresh:((Void)->(Void))?

    func addRefreshControl()
    {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(PopoverTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        }
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
            Thread.onMainThread() {
                self.tableView?.addSubview(self.refreshControl!)
            }
        }
    }
    
    func removeRefreshControl()
    {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = nil
        } else {
            // Fallback on earlier versions
            Thread.onMainThread() {
                self.refreshControl?.removeFromSuperview()
            }
        }
    }
    
//    var searchController:UISearchController?
    
    func done()
    {
        if self.isTracking {
            self.stopTracking()
        }
        dismiss(animated: true, completion: nil)
    }
    
    let operationQueue = OperationQueue()
    
    func autoEdit()
    {
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, action: {
            func auto(_ srtComponents:[String]?)
            {
                if var srtComponents = srtComponents, srtComponents.count > 0 {
                    let srtComponent = srtComponents.removeFirst()
                    if let indexPath = self.section.indexPath(from: srtComponent) {
                        self.transcript?.editSRT(popover:self,tableView:self.tableView,indexPath:indexPath,automatic:true,automaticInteractive:true,automaticCompletion:{
                            auto(srtComponents)
                        })
                    }
                } else {
                    globals.alert(title:"Assisted Editing Process Completed",message:nil)
                }
            }
            
            auto(self.section.strings)
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, action: {
            func auto(_ srtComponents:[String]?)
            {
                if var srtComponents = srtComponents, srtComponents.count > 0 {
                    let srtComponent = srtComponents.removeFirst()
                    if let indexPath = self.section.indexPath(from: srtComponent) {
                        self.transcript?.editSRT(popover:self,tableView:self.tableView,indexPath:indexPath,automatic:true,automaticInteractive:false,automaticCompletion:{
                            auto(srtComponents)
                        })
                    }
                } else {
                    globals.alert(title:"Assisted Editing Process Completed",message:nil)
                }
            }
            
            auto(self.section.strings)
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: nil))
        
        alert(viewController:self,title:"Start Assisted Editing?",message:nil,actions:actions)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverTableViewController.done))
        assistButton = UIBarButtonItem(title: "Assist", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.autoEdit))
        syncButton = UIBarButtonItem(title: "Sync", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverTableViewController.tracking))

        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.rightBarButtonItems = [doneButton]
                
            default:
                break
            }
        }

        if track {
            if navigationItem.rightBarButtonItems != nil {
                navigationItem.rightBarButtonItems?.append(syncButton)
            } else {
                navigationItem.rightBarButtonItem = syncButton
            }
        }
        
        if assist && (transcript != nil) && (purpose == .selectingTime) {
            if navigationItem.rightBarButtonItems != nil {
                navigationItem.rightBarButtonItems?.append(assistButton)
            } else {
                navigationItem.rightBarButtonItem = assistButton
            }
        }
        
        searchBar.autocapitalizationType = .none

        switch (search,segments) {
        case (true,true):
            tableViewTopConstraint.constant = 88
            break
        case (true,false):
            segmentedControl.removeFromSuperview()
            break
        case (false,true):
            searchBar.removeFromSuperview()
            break
        case (false,false):
            searchBar.removeFromSuperview()
            tableViewTopConstraint.constant = 0
            break
        }
        
//        if segments {
//            segmentedControl.removeAllSegments()
//            if let segmentActions = segmentActions {
//                for segmentAction in segmentActions {
//                    segmentedControl.insertSegment(withTitle: segmentAction.title, at: segmentAction.position, animated: false)
//                }
//            }
//        }
        
        if refresh != nil {
            addRefreshControl()
        }
        
        if mediaListGroupSort != nil {
            addRefreshControl()
            
            mediaListGroupSort?.lexicon?.pauseUpdates = false
        }

        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setPreferredContentSize()
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }
    }
    
    func selectString(_ string:String?,scroll:Bool,select:Bool)
    {
        guard (string != nil) else {
            return
        }
        
        selectedText = string
        
//        if let active = self.searchController?.isActive, active {
        if let selectedText = selectedText,  let index = section.strings?.index(where: { (string:String) -> Bool in
            return selectedText.uppercased() == string.substring(to: string.range(of: " (")!.lowerBound).uppercased()
        }) {
            //                if let selectedText = self.selectedText, let index = self.filteredStrings?.index(of: selectedText) {
            switch sort.method {
            case Constants.Sort.Alphabetical:
                var i = 0
                
                repeat {
                    i += 1
                } while (i < self.section.indexes?.count) && (self.section.indexes?[i] <= index)
                
                let section = i - 1
                
                if let base = self.section.indexes?[section] {
                    let row = index - base
                    
                    if self.section.strings?.count > 0 {
                        Thread.onMainThread() {
                            if section >= 0, section < self.tableView.numberOfSections, row >= 0, row < self.tableView.numberOfRows(inSection: section) {
                                let indexPath = IndexPath(row: row,section: section)
                                if scroll {
                                    self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                                }
                                if select {
                                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                }
                            } else {
//                                alert(viewController:self,title:"String not found!",message:"THIS SHOULD NOT HAPPEN.",completion:nil)
                            }
                        }
                    }
                }
                break
                
            case Constants.Sort.Frequency:
                let section = 0
                let row = index

                if self.section.strings?.count > 0 {
                    Thread.onMainThread() {
                        if section >= 0, section < self.tableView.numberOfSections, row >= 0, row < self.tableView.numberOfRows(inSection: section) {
                            let indexPath = IndexPath(row: row,section: section)
                            if scroll {
                                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                            }
                            if select {
                                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            }
                        } else {
//                            alert(viewController:self,title:"String not found!",message:"THIS SHOULD NOT HAPPEN.",completion:nil)
                        }
                    }
                }
                break
            default:
                break
            }
        } else {
            alert(viewController:self,title:"String not found!",message:"Search is active and the string \(selectedText!) is not in the results.",completion:nil)
        }
    }
    
    func lexiconStarted()
    {
        Thread.onMainThread() {
            self.activityIndicator.startAnimating()
            self.activityIndicator?.isHidden = false
        }
    }
    
    func lexiconUpdated()
    {
        guard let pause = mediaListGroupSort?.lexicon?.pauseUpdates, !pause else {
            return
        }
        
        Thread.onMainThread() {
            if let completed = self.mediaListGroupSort?.lexicon?.completed, !completed {
                self.activityIndicator.startAnimating()
                self.activityIndicator?.isHidden = false
            }
        }
        
        Thread.onMainThread() {
            self.updateTitle()
        }
        
        self.unfilteredSection.strings = (self.sort.function == nil) ? self.mediaListGroupSort?.lexicon?.section.strings : self.sort.function?(self.sort.method,self.mediaListGroupSort?.lexicon?.section.strings)
        
        //        if sort.method == Constants.Sort.Alphabetical {
        //            unfilteredSection.indexHeaders = mediaListGroupSort?.lexicon?.section.indexHeaders
        //        }
        
        //        unfilteredSection.buildIndex()
        
        if self.searchActive {
            if let filteredStrings = self.unfilteredSection.strings?.filter({ (string:String) -> Bool in
                if let text = self.searchText {
                    return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                } else {
                    return false
                }
            }) {
                self.filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                        print(self.filteredStrings)
                
                //                self.filteredSection.buildIndex()
                
                //                        print(self.filteredSection.indexHeaders)
            }
        }
        
        Thread.onMainThread() {
            if let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause {
                self.tableView.reloadData()
            }
        }
        
        Thread.onMainThread() {
            if let completed = self.mediaListGroupSort?.lexicon?.completed, completed {
                self.activityIndicator.stopAnimating()
                self.activityIndicator?.isHidden = true
            }
            if #available(iOS 10.0, *) {
                if let isRefreshing = self.tableView.refreshControl?.isRefreshing, isRefreshing {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                // Fallback on earlier versions
                if self.isRefreshing {
                    self.refreshControl?.endRefreshing()
                    self.isRefreshing = false
                }
            }
        }
    }
    
    func lexiconCompleted()
    {
        Thread.onMainThread() {
            self.activityIndicator.startAnimating()
            self.activityIndicator?.isHidden = false
        }

        unfilteredSection.strings = (sort.function == nil) ? mediaListGroupSort?.lexicon?.section.strings : sort.function?(sort.method,mediaListGroupSort?.lexicon?.section.strings)

//        unfilteredSection.strings = mediaListGroupSort?.lexicon?.section.strings
//        
//        if let function = sort.function {
//            unfilteredSection.strings = function(sort.method,unfilteredSection.strings)
//        }

//        if sort.method == Constants.Sort.Alphabetical {
//            unfilteredSection.indexHeaders = mediaListGroupSort?.lexicon?.section.indexHeaders
//        }
        
//        unfilteredSection.buildIndex()

        if searchActive {
            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                if let text = searchText {
                    return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                } else {
                    return false
                }
            }) {
                filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                    print(self.filteredStrings)
                
                //                self.filteredSection.buildIndex()
                
                //                    print(self.filteredSection.indexHeaders)
            }
        }
        
        Thread.onMainThread() {
            if #available(iOS 10.0, *) {
                if let isRefreshing = self.tableView.refreshControl?.isRefreshing, isRefreshing {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                // Fallback on earlier versions
                if self.isRefreshing {
                    self.refreshControl?.endRefreshing()
                    self.isRefreshing = false
                }
            }
            
            self.updateTitle()
            
            self.tableView.reloadData()
            
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.isHidden = true
            
            self.removeRefreshControl()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        mask = false
        
        NotificationCenter.default.removeObserver(self)
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
//        if mediaListGroupSort != nil {
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: mediaListGroupSort?.lexicon)
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: mediaListGroupSort?.lexicon)
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: mediaListGroupSort?.lexicon)
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }
    
//    func sortAction()
//    {
//        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
//            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//            navigationController.modalPresentationStyle = .popover
//            
//            popover.navigationItem.title = "Select"
//            navigationController.isNavigationBarHidden = false
//
//            navigationController.popoverPresentationController?.permittedArrowDirections = .up
//            navigationController.popoverPresentationController?.delegate = self
//            
//            navigationController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
//            
////            popover.navigationController?.isNavigationBarHidden = true
//            
//            popover.delegate = self
//            popover.purpose = .selectingSorting
//            
//            popover.section.strings = [Constants.Sort.Alphabetical,Constants.Sort.Frequency]
////            
////            popover.section.showIndex = false
////            popover.section.showHeaders = false
//            
//            popover.vc = self
//            
//            ptvc = popover
//            
//            present(navigationController, animated: true, completion: nil)
//        }
//    }

    func updateTitle()
    {
        if  let count = self.mediaListGroupSort?.lexicon?.entries?.count,
            let total = self.mediaListGroupSort?.lexicon?.eligible?.count {
            self.navigationItem.title = "Lexicon \(count) of \(total)"
        }
    }
    
//    var ptvc:PopoverTableViewController?
    
    var orientation : UIDeviceOrientation?
    
    func deviceOrientationDidChange()
    {
        // Dismiss any popover
        func action()
        {
//            ptvc?.dismiss(animated: false, completion: nil)
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
    
    func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    var mask = false
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        if !globals.splitViewController.isCollapsed, navigationController?.modalPresentationStyle == .overCurrentContext {
            var vc : UIViewController?
            
            if presentingViewController == globals.splitViewController?.viewControllers[0] {
                vc = globals.splitViewController!.viewControllers[1]
            }
            
            if presentingViewController == globals.splitViewController?.viewControllers[1] {
                vc = globals.splitViewController!.viewControllers[0]
            }
            
            mask = true
            
            if let vc = vc {
                process(viewController:vc,disableEnable:false,hideSubviews:true,work:{ (Void) -> Any? in
                    while self.mask {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    return nil
                },completion:{ (data:Any?) -> Void in
                    
                })
            }
        }
        
        orientation = UIDevice.current.orientation
        
        if searchActive {
            searchBar.text = searchText
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        navigationController?.setToolbarHidden(true, animated: false)
        
//        if sort.function != nil {
//            if navigationItem.leftBarButtonItems != nil {
//                navigationItem.leftBarButtonItems?.append(UIBarButtonItem(title: "Sort", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverTableViewController.sortAction)))
//            } else {
//                navigationItem.setLeftBarButton(UIBarButtonItem(title: "Sort", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverTableViewController.sortAction)),animated:false)
//            }
//        }
        
        if mediaListGroupSort != nil {
            globals.queue.async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconStarted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconCompleted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.mediaListGroupSort?.lexicon)
            })
            
            if  let completed = mediaListGroupSort?.lexicon?.completed, !completed {
                // Start lexicon creation if it isn't already being created.
                if let creating = mediaListGroupSort?.lexicon?.creating, !creating {
                    mediaListGroupSort?.lexicon?.build()
                }
                lexiconUpdated()
            } else {
                lexiconCompleted()
            }
        } else

        if (stringsFunction != nil) && (self.section.strings == nil) {
            DispatchQueue.global(qos: .background).async {
                Thread.onMainThread() {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator?.isHidden = false
                }
                
                self.section.strings = self.stringsFunction?()
                
                if self.section.strings != nil {
//                    self.section.buildIndex()
                    
                    Thread.onMainThread() {
                        self.tableView.reloadData()
                        
                        self.setPreferredContentSize()
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator?.isHidden = true
                        
                        if self.purpose == .selectingTime {
                            self.follow()
                        }
                    }
                }
            }
        } else
            
        if (stringsAny != nil) && (self.section.strings == nil) {
            if let keys = self.stringsAny?.keys.sorted() {
                var strings = [String]()
                for key in keys {
                    var string = key
                    if let value = self.stringsAny?[key] as? String {
                        string = string + ": " + value
                    }
                    if let value = self.stringsAny?[key] as? Double {
                        string = string + ": \(value)"
                    } else
                        if let value = self.stringsAny?[key] as? Int {
                            string = string + ": \(value)"
                    }
                    strings.append(string)
                }
                self.section.strings = strings
                
                self.setPreferredContentSize()
            }
        } else
            
        if (stringsArray != nil) && (self.section.strings == nil) {
            self.section.strings = self.stringsArray
            
            self.setPreferredContentSize()
        } else
            
        if (stringsAnyArray != nil) && (self.section.strings == nil) {
            if let stringsAnyArray = self.stringsAnyArray {
                var strings = [String]()
                for stringsAny in stringsAnyArray {
                    if let string = stringsAny["name"] as? String {
                        strings.append(string)
                    }
                    if let string = stringsAny["w"] as? String {
                        strings.append(string)
                    }
                }
                self.section.strings = strings
                
                self.setPreferredContentSize()
            }
        } else
            
        if section.strings != nil {
            if section.showIndex {
                if (self.section.indexStrings?.count > 1) {
//                    section.buildIndex()
                } else {
                    section.showIndex = false
                }
            }

            // Causes problems when other view controllers are pushed on top of this and then the user comes "Back" to this one - section titles dont' show correctly.
//            tableView.reloadData()
            
            setPreferredContentSize()
            
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        }
        
        searchBar.isUserInteractionEnabled = searchInteractive
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
        
        if purpose == .selectingTime {
            follow()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}

extension PopoverTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // Return the number of sections.
        if section.showIndex || section.showHeaders {
            return section.counts != nil ? section.counts!.count : 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Return the number of rows in the section.
        if self.section.showIndex || self.section.showHeaders {
            return self.section.counts != nil ? (((section >= 0) && (section < self.section.counts?.count)) ? self.section.counts![section] : 0) : 0
        } else {
            return self.section.strings != nil ? self.section.strings!.count : 0
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        if section.showIndex {
            return section.indexHeaders
        } else {
            return nil
        }
    }
    
    //    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //        return 48
    //    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        if section.showIndex {
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if self.section.showIndex || self.section.showHeaders {
            if let count = self.section.headers?.count, section >= 0, section < count {
                return self.section.headers?[section]
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell
        
        cell.title.text = nil
        cell.title.attributedText = nil
        
        var index = -1
        
        index = section.index(indexPath)
        
//        if (section.showIndex || section.showHeaders) {
//            //        if let active = self.searchController?.isActive, active {
//            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
//        } else {
//            index = indexPath.row
//        }
        
        guard index >= 0 else {
            print("ERROR")
            return cell
        }
        
        guard index < section.strings?.count else {
            print("ERROR")
            return cell
        }
        
        guard let string = section.strings?[index] else {
            print("ERROR")
            return cell
        }
        
        if search, searchActive, let searchText = searchText?.lowercased(), string.lowercased().contains(searchText) {
            var titleString = NSMutableAttributedString()
            
            let tokenDelimiters = "$\"' :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.QUOTES
            var before:String?
            var during:String?
            var after:String?
            
            var range = string.lowercased().range(of: searchText.lowercased())
            
            repeat {
                if let range = range {
                    before = string.substring(to: range.lowerBound)
                    during = string.substring(with: range)
                    after = string.substring(from: range.upperBound)
                    
                    titleString = NSMutableAttributedString()
                    
                    if let before = before {
                        titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                    }
                    if let during = during {
                        titleString.append(NSAttributedString(string: during,   attributes: Constants.Fonts.Attributes.highlighted))
                    }
                    if let after = after {
                        titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                    }
                } else {
                    break
                }
                
                if wholeWordsOnly {
                    if let beforeEmpty = before?.isEmpty, beforeEmpty, let afterEmpty = after?.isEmpty, afterEmpty {
                        break
                    }
                    
                    if let characterBefore:Character = before?.characters.last, let characterAfter:Character = after?.characters.first {
                        if CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterBefore))!) &&
                            CharacterSet(charactersIn: tokenDelimiters).contains(UnicodeScalar(String(characterAfter))!) {
                            break
                        }
                    }
                    
                    if let after = after, !after.isEmpty {
                        range = string.range(of: searchText, options: String.CompareOptions.caseInsensitive, range: string.range(of: after), locale: NSLocale.current)
                    } else {
                        break
                    }
                } else {
                    break
                }
            } while after != nil ? after!.contains(searchText) : false
            
            cell.title.text = string
            cell.title.attributedText = titleString
        } else {
            cell.title.text = string
            cell.title.attributedText = NSAttributedString(string:string,attributes:Constants.Fonts.Attributes.normal)
        }
        
        guard purpose != nil else {
            cell.accessoryType = UITableViewCellAccessoryType.none
            return cell
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            
            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (string == Constants.Strings.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingCategory:
            if (globals.mediaCategory.names?[index] == globals.mediaCategory.selected) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingGrouping:
            if (globals.groupings[index] == globals.grouping) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == globals.sorting) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            
            if let sorting = (vc as? PopoverTableViewController)?.sort.method {
                //                print(sorting, string)
                if sorting == string {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
            }
            
            if let sorting = (vc as? LexiconIndexViewController)?.ptvc.sort.method {
                //                print(sorting, string)
                if sorting == string {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
            }
            break
            
        default:
            if let detailDisclosure = detailDisclosure?(tableView,indexPath), detailDisclosure {
                cell.accessoryType = UITableViewCellAccessoryType.detailButton
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break // UITableViewCellAccessoryType.none
        }
        
        //        print(strings)
        
        //        if let active = self.searchController?.isActive, active {
        //        print("CELL:",cell.title.text)
        
        return cell
    }

    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return NO if you do not want the item to be re-orderable.
     return true
     }
     */
}

extension PopoverTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath: IndexPath)
    {
        // Tells the delegate that the table view is about to go into editing mode.
        
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMainThread() {
                self.tableView.reloadData()
            }
        }
        
        changesPending = false
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard self.section.showIndex || self.section.showHeaders else {
            return 0
        }
        
        guard section >= 0, section < self.section.headers?.count, let title = self.section.headers?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).height + 20
        
        //        print(height,max(Constants.HEADER_HEIGHT,height + 28))
        
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
            header.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            header.textLabel?.text = nil
            header.textLabel?.textColor = UIColor.black
            
            header.alpha = 0.85
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        guard self.section.showIndex || self.section.showHeaders else {
            return nil
        }
        
        var view : PopoverTableViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "PopoverTableViewController") as? PopoverTableViewControllerHeaderView
        if view == nil {
            view = PopoverTableViewControllerHeaderView()
        }
        
        if section >= 0, section < self.section.headers?.count, let title = self.section.headers?[section] {
            view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            if view?.label == nil {
                view?.label = UILabel()
                
                view?.label?.numberOfLines = 0
                view?.label?.lineBreakMode = .byWordWrapping
                
                view?.label?.translatesAutoresizingMaskIntoConstraints = false
                
                view?.addSubview(view!.label!)
                
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":view!.label!]))
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":view!.label!]))
            }
            
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold)
            
            view?.alpha = 0.85
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if let transcript = transcript {
            return transcript.rowActions(popover: self, tableView: tableView, indexPath: indexPath) != nil
        }
        
        return editActionsAtIndexPath?(self,tableView,indexPath) != nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let transcript = transcript {
            return transcript.rowActions(popover: self, tableView: tableView, indexPath: indexPath)
        }
        
        return editActionsAtIndexPath?(self,tableView,indexPath)
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
    {
        detailAction?(tableView,indexPath)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        let index = section.index(indexPath)
        
        guard let strings = section.strings else {
            return false
        }
        
        guard shouldSelect == nil else {
            if let shouldSelect = shouldSelect?(indexPath) {
                return shouldSelect
            }
            
            return false
        }
        
//        if let keys = self.stringsAny?.keys.sorted().map({ (string:String) -> String in
//            return string
//        }) {
//            if let _ = self.stringsAny?[keys[index]] as? String {
//                return false
//            }
//            if let _ = self.stringsAny?[keys[index]] as? Double {
//                return false
//            }
//            if let _ = self.stringsAny?[keys[index]] as? Int {
//                return false
//            }
//        }
        
        if (stringsAny != nil) && (stringsAny?[strings[index]] == nil) {
            return false
        }
        
        if let _ = self.stringsAny?[strings[index]] as? String {
            return false
        }
        if let _ = self.stringsAny?[strings[index]] as? Double {
            return false
        }
        if let _ = self.stringsAny?[strings[index]] as? Int {
            return false
        }
        
        if let _ = self.stringsArray?[index] {
            return false
        }
        
        return allowsSelection
    }
    
    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard didSelect == nil else {
            didSelect?(indexPath)
            return
        }
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        if searchActive {
            self.searchBar.resignFirstResponder()
        }
        
        if isTracking {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }

        var index = -1
        
        index = section.index(indexPath)
        
//        if (section.showIndex || section.showHeaders) {
//            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
//            if let range = section.strings?[index].range(of: " (") {
//                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
//            }
//        } else {
//            index = indexPath.row
//            if let range = section.strings?[index].range(of: " (") {
//                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
//            }
//        }

        guard let string = section.strings?[index] else {
            return
        }
        
        if let range = section.strings?[index].range(of: " (") {
            selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
        }

        //        print(index,strings![index])
        
        switch purpose! {
            
        default:
            delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose!, mediaItem: selectedMediaItem)
            break
        }

        if  (transcript !=  nil) && (purpose == .selectingTime) &&
            (!track || searchActive) {
            if  let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                
//                navigationController.modalPresentationStyle = .overCurrentContext
//                
//                navigationController.popoverPresentationController?.delegate = self // as? UIPopoverPresentationControllerDelegate
//                navigationController.popoverPresentationController?.permittedArrowDirections = [.right,.up]
                
                //                    navigationController.popoverPresentationController?.sourceView = sourceView
                //                    navigationController.popoverPresentationController?.sourceRect = sourceRectView.frame
                
//                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string.components(separatedBy: "\n").first //"Timing Index (\(self.transcriptPurpose))" //
                
                popover.selectedMediaItem = self.selectedMediaItem
                popover.transcript = self.transcript
                
                popover.vc = self.vc
                popover.search = false // This keeps it to one level deep.
                
                popover.editActionsAtIndexPath = self.editActionsAtIndexPath
                
                popover.delegate = self.delegate // as? PopoverTableViewControllerDelegate
                popover.purpose = self.purpose
                
                popover.parser = self.parser
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                //                        popover.section.showHeaders = true
                
//                popover.stringsFunction = self.stringsFunction
                popover.stringsFunction = { (Void) -> [String]? in
                    return self.transcript?.srtComponents?.filter({ (string:String) -> Bool in
                        return string.components(separatedBy: "\n").count > 1
                    }).map({ (srtComponent:String) -> String in
                        //                            print("srtComponent: ",srtComponent)
                        var srtArray = srtComponent.components(separatedBy: "\n")
                        
                        if srtArray.count > 2  {
                            let count = srtArray.removeFirst()
                            let timeWindow = srtArray.removeFirst()
                            let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ")
                            
                            if  let start = times.first,
                                let end = times.last,
                                let range = srtComponent.range(of: timeWindow+"\n") {
                                let text = srtComponent.substring(from: range.upperBound).replacingOccurrences(of: "\n", with: " ")
                                let string = "\(count)\n\(start) to \(end)\n" + text
                                
                                return string
                            }
                        }
                        
                        return "ERROR"
                    })
                }

                popover.track = true
                popover.assist = true
                
                self.navigationController?.pushViewController(popover, animated: true)
            }
        }
        
        var stringsAny : [String : Any]?
        var stringsArray : [String]?
        var stringsAnyArray : [[String : Any]]?

        if self.stringsAny != nil {
            stringsAny = self.stringsAny?[string] as? [String : Any]
            stringsArray = self.stringsAny?[string] as? [String]
            stringsAnyArray = self.stringsAny?[string] as? [[String : Any]]
        }
        
        if self.stringsArray != nil {
            
        }
        
        if self.stringsAnyArray != nil {
            stringsAny = self.stringsAnyArray?[index]
        }
        
        if (delegate == nil) && ((stringsAny != nil) || (stringsArray != nil) || (stringsAnyArray != nil)) {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                popover.search = true
                
                popover.navigationItem.title = string
                
                popover.stringsAny = stringsAny
                popover.stringsArray = stringsArray
                popover.stringsAnyArray = stringsAnyArray
                
                popover.purpose = .showingVoiceBaseMediaItem
                
                self.navigationController?.pushViewController(popover, animated: true)
            }
        }
    }
}
