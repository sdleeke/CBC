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
    var popover : PopoverTableViewController? { get set }

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
        
        guard unfilteredSection.strings != nil else {
            return false
        }
        
        return search
    }
    
    @objc func barButtonAction(_ sender:UIBarButtonItem)
    {
        let toolBarItems = toolbarItems?.filter({ (barButton) -> Bool in
            return barButton.title != nil
        })
        
        if let section = toolBarItems?.index(of: sender) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    func updateSearchResults()
    {
        guard searchActive else {
            return
        }
        
        guard let text = searchText else {
            return
        }
        
        // update the search result array by filtering….
        if let keys = unfilteredSection.stringIndex?.keys {
            var filteredStringIndex = [String:[String]]()
            
            for key in keys {
                if let values = unfilteredSection.stringIndex?[key] {
                    for value in values {
                        if value.replacingOccurrences(of: Constants.UNBREAKABLE_SPACE, with: " ").range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil {
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
        }

        updateToolbar()
        
        Thread.onMainThread {
            self.tableView.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        // To make sure we start out right
        if !searchActive {
            filteredSection.showIndex = unfilteredSection.showIndex
            filteredSection.showHeaders = unfilteredSection.showHeaders

            filteredSection.indexSort = unfilteredSection.indexSort
            filteredSection.indexStringsTransform = unfilteredSection.indexStringsTransform
            filteredSection.indexHeadersTransform = unfilteredSection.indexHeadersTransform
        }
        
        searchActive = true
        
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
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchText = searchBar.text

        searchBar.resignFirstResponder()
        
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchText = nil
        searchActive = false

        if purpose == .selectingWord {
            // In case they've changed: alpha vs. freq sorting.
            unfilteredSection.showIndex = filteredSection.showIndex
            unfilteredSection.showHeaders = filteredSection.showHeaders
            
            // In case the method changed
            if let function = sort.function {
                section.strings = function(sort.method,section.strings)
            }
        }
        
        searchBar.showsCancelButton = false
       
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        updateToolbar()
        
        tableView.reloadData()
        
        if purpose == .selectingTime {
            self.follow()
        }
        
        filteredSection = Section(stringsAction: { (strings:[String]?) in
            Thread.onMainThread {
                self.segmentedControl?.isEnabled = strings != nil
            }
        })
    }
}

extension PopoverTableViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:rowClickedAtIndex",completion:nil)
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

class Sort
{
    init(_ ptvc:PopoverTableViewController)
    {
        self.ptvc = ptvc
    }
    
    weak var ptvc : PopoverTableViewController!
    
    var sorting = false
    {
        didSet {
            Thread.onMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SORTING_CHANGED), object: self.ptvc)
            }
        }
    }

    var function : ((String?,[String]?)->[String]?)?
    
    var method : String? = Constants.Sort.Alphabetical
    {
        willSet {
            
        }
        didSet {

        }
    }
}

struct SegmentAction {
    var title:String?
    var position:Int
    var action:(()->(Void))?
}

class PopoverTableViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class PopoverTableViewController : UIViewController
{
    var popover : PopoverTableViewController?
    {
        didSet {

        }
    }
    
    var alertController : UIAlertController?
    
    var changesPending = false
    
    var selectedText:String!
    
    var selection:((Int)->(Bool))?
    
    var detailAction:((UITableView,IndexPath)->(Void))?
    var detailDisclosure:((UITableView,IndexPath)->(Bool))?
    
    var editActionsAtIndexPath : ((PopoverTableViewController,UITableView,IndexPath)->([AlertAction]?))?
    
    lazy var sort = {
        return Sort(self)
    }()
 
    func stopTracking()
    {
        guard track else {
            return
        }
        
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        syncButton.title = "Sync"
    }
    
    func startTracking()
    {
        guard track else {
            return
        }
        
        if trackingTimer == nil {
            if let indexPath = tableView.indexPathForSelectedRow {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            
            trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(follow), userInfo: nil, repeats: true)
        } else {
            print("ERROR: trackingTimer not nil!")
        }

        syncButton.title = "Stop Sync"
    }
    
    var lastFollow : IndexPath?
    
    @objc func follow()
    {
        guard Globals.shared.mediaPlayer.currentTime != nil else {
            stopped()
            return
        }
        
        guard !searchActive else {
            return
        }
        
        guard let transcriptSegmentComponents = section.strings else {
            return
        }
        
        var time:Double?
        
        if isTracking {
            time = Globals.shared.mediaPlayer.currentTime?.seconds
        } else {
            time = Globals.shared.mediaPlayer.lastSeek
        }
        
        guard let seconds = time else {
            return
        }
        
        // Since the sequence of timed segments is non-overlapping and not guaranteed to be continuous, there may be gaps.
        // That is, seconds may fall in the gap between two rows.

        var timeWindowFound = false
        
        var index = 0

        for transcriptSegmentComponent in transcriptSegmentComponents {
            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
            
            if let count = transcriptSegmentArray.first, !count.isEmpty {
                transcriptSegmentArray.remove(at: 0)
            }
            
            if let timeWindow = transcriptSegmentArray.first, !timeWindow.isEmpty {
                transcriptSegmentArray.remove(at: 0)
                
                if  let start = timeWindow.components(separatedBy: " to ").first,
                    let end = timeWindow.components(separatedBy: " to ").last,
                    let startSeconds = start.hmsToSeconds,
                    let endSeconds = end.hmsToSeconds {

                    if isTracking {
                        // Since the player has a bias to start earlier that the requested seek time, don't let it jump back on row if is within X ms.
                        // This is an heuristic, empirical solution.  It may not work in all cases.
                        if (seconds >= startSeconds) && (seconds <= (endSeconds - 0.5)) { // 
                            timeWindowFound = true
                            break
                        } else {

                        }
                    } else {
                        if (seconds >= startSeconds) && (seconds <= endSeconds) {
                            timeWindowFound = true
                            break
                        } else if (seconds < startSeconds) {
                            timeWindowFound = true
                            break
                        }
                    }
                }
            }

            index += 1
        }
        
        index = max(index,0)
        
        if  let counts = self.section.counts, let indexes = self.section.indexes, counts.count == indexes.count {
            var section = 0
            
            while section < counts.count, (index >= (indexes[section] + counts[section])) {
                section += 1
            }
            
            if section < indexes.count {
                let sectionIndex = indexes[section]
                
                let row = index - sectionIndex

                // Number of sections is 1 after search!
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
    
    @objc func tracking()
    {
        isTracking = !isTracking
    }
    
    var track = false
    {
        didSet {
            
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
    }
    
    var assist = false
    
    func removeAssist()
    {
        guard assist else {
            return
        }
        
        assistButton?.isEnabled = false
    }
    
    func restoreAssist()
    {
        guard assist else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        assistButton?.isEnabled = true
    }
    
    var isTracking = false
    {
        didSet {
            if isTracking != oldValue {
                if !isTracking {
                    stopTracking()
                    restoreAssist()
                }
                
                if isTracking {
                    startTracking()
                    removeAssist()
                }
            }
        }
    }
    
    var trackingTimer : Timer?
    
    var doneButton : UIBarButtonItem!
    var syncButton : UIBarButtonItem!
    var playPauseButton : UIBarButtonItem!
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
        }
    }
        
    var searchText      : String?
    var wholeWordsOnly  = false
    
    var searchInteractive = true
    
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
            if section.strings == nil {
                segmentedControl.isEnabled = false
            }
            
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
        guard section.strings != nil else {
            return
        }
        
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
    
    var stringsFunction:(()->[String]?)?
    
    // Make thread safe?
    var stringsAny : [String:Any]?
    var stringsArray : [String]?
    var stringsAnyArray : [[String:Any]]?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var shouldSelect:((IndexPath)->Bool)?
    var didSelect:((IndexPath)->Void)?
    
    var indexStringsTransform:((String?)->String?)?
    {
        willSet {
            
        }
        didSet {
            filteredSection.indexStringsTransform = indexStringsTransform
            unfilteredSection.indexStringsTransform = indexStringsTransform
        }
    }
    
    var stringSelected : String?
    
    lazy var filteredSection:Section! = { [weak self] in
        let section = Section(stringsAction: { (strings:[String]?) in
            Thread.onMainThread {
                if let sorting = self?.sort.sorting {
                    self?.segmentedControl?.isEnabled = (strings != nil) && !sorting
                }
            }
        })
        return section
    }()
    lazy var unfilteredSection:Section! = { [weak self] in
        let section = Section(stringsAction: { (strings:[String]?) in
            Thread.onMainThread {
                if let sorting = self?.sort.sorting {
                    self?.segmentedControl?.isEnabled = (strings != nil) && !sorting
                }
            }
        })
        return section
    }()
    
    var section:Section!
    {
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
    
    var sectionBarButtons = false
    
    var parser:((String)->([String]))?
    
    func setPreferredContentSize()
    {
        guard self.navigationController?.modalPresentationStyle == .popover else {
            return
        }
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:setPreferredContentSize",completion:nil)
            return
        }

        guard let strings = section.strings else {
            return
        }
        
        guard let viewWidth = Globals.shared.splitViewController?.view.frame.width else {
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
        
        if let purpose = purpose {
            switch purpose {
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
        }
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: Constants.Fonts.body.lineHeight)
        
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
        
        for string in strings {
            if let strings = parser != nil ? parser?(string) : [string] {
                for stringInStrings in strings {
                    let maxHeight = stringInStrings.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
                    let maxWidth = stringInStrings.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
                    
                    if maxWidth.width > width {
                        width = maxWidth.width
                    }
                    
                    if tableView.rowHeight != -1 {
                        height += tableView.rowHeight
                    } else {
                        height += 2*8 + maxHeight.height // - baseHeight
                    }
                }
            }
        }
        
        if self.section.showIndex || self.section.showHeaders, let headers = self.section.headers {
            for header in headers {
                let maxWidth = header.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width // + 20
                if maxWidth > width {
                    width = maxWidth
                }
            }
        }
        
        width += margins * marginSpace
        
        if let purpose = self.purpose {
            switch purpose {
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
        }
        
        if self.section.showIndex {
            width += indexSpace
        }

        if self.section.showIndex || self.section.showHeaders, let count = self.section.headers?.count, (count > 1) {
            height += CGFloat(40 * count)
        }
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    var isRefreshing = false
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:handleRefresh",completion:nil)
            return
        }
        
        refreshControl.beginRefreshing()
        
        self.isRefreshing = true

        self.refresh?()
    }
    
    var refreshControl:UIRefreshControl?
    var refresh:(()->(Void))?

    func addRefreshControl()
    {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControlEvents.valueChanged)
        }
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
            if let refreshControl = self.refreshControl {
                Thread.onMainThread {
                    self.tableView?.addSubview(refreshControl)
                }
            }
        }
    }
    
    func removeRefreshControl()
    {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = nil
        } else {
            // Fallback on earlier versions
            Thread.onMainThread {
                self.refreshControl?.removeFromSuperview()
            }
        }
    }
    
    @objc func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func autoEdit()
    {
        var actions = [AlertAction]()
        
        actions.append(AlertAction(title: "Interactive", style: .default, handler: {
            func auto(_ transcriptSegmentComponents:[String]?)
            {
                if var transcriptSegmentComponents = transcriptSegmentComponents, transcriptSegmentComponents.count > 0 {
                    let transcriptSegmentComponent = transcriptSegmentComponents.removeFirst()
                    if let indexPath = self.section.indexPath(from: transcriptSegmentComponent) {
                        self.transcript?.editTranscriptSegment(popover:self, tableView:self.tableView, indexPath:indexPath, automatic:true, automaticInteractive:true, automaticCompletion:{
                            auto(transcriptSegmentComponents)
                        })
                    }
                } else {
                    Alerts.shared.alert(title:"Assisted Editing Complete",message:nil)
                }
            }
            
            auto(self.section.strings)
        }))
        
        actions.append(AlertAction(title: "Automatic", style: .default, handler: {
            func auto(_ transcriptSegmentComponents:[String]?)
            {
                if var transcriptSegmentComponents = transcriptSegmentComponents, transcriptSegmentComponents.count > 0 {
                    let transcriptSegmentComponent = transcriptSegmentComponents.removeFirst()
                    if let indexPath = self.section.indexPath(from: transcriptSegmentComponent) {
                        self.transcript?.editTranscriptSegment(popover:self, tableView:self.tableView, indexPath:indexPath, automatic:true, automaticInteractive:false, automaticCompletion:{
                            auto(transcriptSegmentComponents)
                        })
                    }
                } else {
                    Alerts.shared.alert(title:"Assisted Editing Complete",message:nil)
                }
            }
            
            auto(self.section.strings)
        }))
        
        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
        
        alert(viewController:self,title:"Start Assisted Editing?",message:nil,actions:actions)
    }
    
    func actions()
    {
        guard track else {
            return
        }
        
        var actions = [AlertAction]()
        
        if syncButton.isEnabled, var title = syncButton.title {
            if title == "Stop" {
                title = "Stop Sync"
            }
            
            actions.append(AlertAction(title: title, style: .default, handler: {
                self.tracking()
            }))
        }
        
        if playPauseButton.isEnabled, let title = playPauseButton.title {
            actions.append(AlertAction(title: title, style: .default, handler: {
                self.playPause()
            }))
        }
        
        if assistButton.isEnabled, let title = assistButton.title {
            actions.append(AlertAction(title: title, style: .default, handler: {
                self.autoEdit()
            }))
        }

        actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, handler: nil))
        
        alert(viewController:self,title:"Actions",message:nil,actions:actions)
    }
    
    @objc func playPause()
    {
        guard let title = playPauseButton.title else {
            return
        }
        
        switch title {
        case "Play":
            Globals.shared.mediaPlayer.play()
            playPauseButton.title = "Pause"

        case "Pause":
            Globals.shared.mediaPlayer.pause()
            playPauseButton.title = "Play"
            
        default:
            break
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        navigationController?.toolbar.isTranslucent = false

        assistButton = UIBarButtonItem(title: "Assist", style: UIBarButtonItemStyle.plain, target: self, action: #selector(autoEdit))
        syncButton = UIBarButtonItem(title: "Sync", style: UIBarButtonItemStyle.plain, target: self, action: #selector(tracking))
        playPauseButton = UIBarButtonItem(title: "Play", style: UIBarButtonItemStyle.plain, target: self, action: #selector(playPause))
        
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
        
        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .formSheet:
                fallthrough
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

        searchBar.autocapitalizationType = .none

        if refresh != nil {
            addRefreshControl()
        }

        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection

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
        
        if let selectedText = selectedText,  let index = section.strings?.index(where: { (string:String) -> Bool in
            if let range = string.range(of: " (") {
                return selectedText.uppercased() == String(string[..<range.lowerBound]).uppercased()
            } else {
                return selectedText.uppercased() == string.uppercased()
            }
        }) {
            if let method = sort.method {
                switch method {
                case Constants.Sort.Alphabetical:
                    var i = 0
                    
                    repeat {
                        i += 1
                    } while (i < self.section.indexes?.count) && (self.section.indexes?[i] <= index)
                    
                    let section = i - 1
                    
                    if let base = self.section.indexes?[section] {
                        let row = index - base
                        
                        if self.section.strings?.count > 0 {
                            Thread.onMainThread {
                                if section >= 0, section < self.tableView.numberOfSections, row >= 0, row < self.tableView.numberOfRows(inSection: section) {
                                    let indexPath = IndexPath(row: row,section: section)
                                    if scroll {
                                        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                                    }
                                    if select {
                                        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                    }
                                } else {

                                }
                            }
                        }
                    }
                    break
                    
                case Constants.Sort.Frequency:
                    let section = 0
                    let row = index

                    if self.section.strings?.count > 0 {
                        Thread.onMainThread {
                            if section >= 0, section < self.tableView.numberOfSections, row >= 0, row < self.tableView.numberOfRows(inSection: section) {
                                let indexPath = IndexPath(row: row,section: section)
                                if scroll {
                                    self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                                }
                                if select {
                                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                                }
                            } else {

                            }
                        }
                    }
                    break
                default:
                    break
                }
            }
        } else {
            if let selectedText = selectedText {
                alert(viewController:self,title:"String not found!",message:"Search is active and the string \(selectedText) is not in the results.",completion:nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        if Alerts.shared.topViewController.last == navigationController {
            Alerts.shared.topViewController.removeLast()
        }
        
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }
    
    func updateTitle()
    {

    }
    
    var orientation : UIDeviceOrientation?
    
    @objc func deviceOrientationDidChange()
    {
        // Dismiss any popover
        func action()
        {

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
    
    @objc func willResignActive()
    {
        self.alertController?.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func stopped()
    {
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        isTracking = false
        
        updateToolbar()
    }
    
    @objc func playing()
    {
        updateToolbar()
    }
    
    @objc func paused()
    {
        updateToolbar()
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopped), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.STOPPED), object: nil)
    }
    
    func updateToolbar()
    {
        var barButtonItems = [UIBarButtonItem]()
        
        if let state = Globals.shared.mediaPlayer.state {
            switch state {
            case .playing:
                self.playPauseButton?.title = "Pause"
                
            default:
                self.playPauseButton?.title = "Play"
                break
            }
        }
        
        if track || assist {
            let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            
            syncButton.isEnabled = (Globals.shared.mediaPlayer.mediaItem != nil) && !searchActive && (section.strings?.count > 0)
            playPauseButton.isEnabled = syncButton.isEnabled
            assistButton.isEnabled = (section.strings?.count > 0) && !isTracking
            
            if track {
                if assist && (transcript != nil) && (purpose == .selectingTime) {
                    barButtonItems.append(spaceButton)
                    barButtonItems.append(assistButton)
                }

                barButtonItems.append(spaceButton)
                barButtonItems.append(syncButton)

                barButtonItems.append(spaceButton)
                barButtonItems.append(playPauseButton)
            } else {
                if assist && (transcript != nil) && (purpose == .selectingTime) {
                    barButtonItems.append(spaceButton)
                    barButtonItems.append(assistButton)
                }
            }
            
            if barButtonItems.count > 0 {
                barButtonItems.append(spaceButton)
            }
        }

        if sectionBarButtons {
            // Set the toobar buttons for section access
            if let keys = section.stringIndex?.keys.sorted(), keys.count > 1 {
                let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
                
                for key in keys {
                    if barButtonItems.count > 0 {
                        barButtonItems.append(spaceButton)
                    }
                    barButtonItems.append(UIBarButtonItem(title: key, style: .plain, target: self, action: #selector(self.barButtonAction(_:))))
                }
            }
        }
        
        // This prevents the toolbarItems from being set if this is an embedded viewController.
        if self == navigationController?.visibleViewController {
            Thread.onMainThread {
                self.toolbarItems = barButtonItems.count > 0 ? barButtonItems : nil
                self.navigationController?.isToolbarHidden = !(self.toolbarItems?.count > 0)
            }
        }
    }
    
    var topConstraint : NSLayoutConstraint!
    
    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "PTVC:Operations"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

                                                            // Because it is embedded in LexiconViewController
        if let navigationController = navigationController, navigationController.topViewController == self, modalPresentationStyle != .popover {
            Alerts.shared.topViewController.append(navigationController)
        }
        
        if let state = Globals.shared.mediaPlayer.state {
            switch state {
            case .playing:
                playPauseButton?.title = "Pause"
                
            default:
                playPauseButton?.title = "Play"
                break
            }
        }
        
        if topConstraint != nil {
            view.removeConstraint(topConstraint)
        }
        
        switch (search,segments) {
        case (true,true):
            topConstraint = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: segmentedControl, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 8.0)
            break
            
        case (true,false):
            segmentedControl.removeFromSuperview()
            
            topConstraint = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: searchBar, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
            break
            
        case (false,true):
            searchBar.removeFromSuperview()
            
            view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 8.0))
            
            topConstraint = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: segmentedControl, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 8.0)
            break
            
        case (false,false):
            searchBar.removeFromSuperview()
            segmentedControl.removeFromSuperview()
            
            topConstraint = NSLayoutConstraint(item: tableView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0)
            break
        }
        
        view.addConstraint(topConstraint)
        self.view.setNeedsLayout()
        
        if segments, let method = sort.method {
            switch method {
            case Constants.Sort.Alphabetical:
                segmentedControl.selectedSegmentIndex = 0
                break
                
            case Constants.Sort.Frequency:
                segmentedControl.selectedSegmentIndex = 1
                break
                
            default:
                break
            }
        }
        
        orientation = UIDevice.current.orientation
        
        if searchActive {
            searchBar.text = searchText
        }
        
        addNotifications()

        if stringsFunction != nil, self.section.strings != nil, self.purpose == .selectingTime {
            let block = {
                Thread.onMainThread {
                    self.follow()
                }
            }
            
            // Then we need to know if we're still seeking or not and if we are we need to push the same action to be done after seeking completes.
            if !Globals.shared.mediaPlayer.isSeeking {
                block()
            } else {
                Globals.shared.mediaPlayer.seekingCompletion = {
                    block()
                }
            }
            
            updateToolbar()

            if self.navigationController?.topViewController == self {
                // Where does it start?
                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        } else
            
        if stringsFunction != nil, self.section.strings == nil, operationQueue.operationCount == 0 {
            if self.navigationController?.topViewController == self {
                Thread.onMainThread {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.isHidden = false
                }
            }

            // Should this be in an opQueue?  Seems like it should so we don't start this more than once.
//            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            operationQueue.addOperation { [weak self] in
                self?.section.strings = self?.stringsFunction?()

                Thread.onMainThread {
                    self?.tableView.reloadData()
                    
                    self?.setPreferredContentSize()
                    
                    if let indexPath = self?.section.indexPath(from: self?.stringSelected) {
                        // If we can find the string, select it!
                        // MIGHT need to make this .background to provide enough delay but throwing it back on the main thread may accomplish that.
                        // Delay so UI works as desired.
                        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                            Thread.onMainThread {
                                self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                            }
                        }
                    } else {
                        // If we're going by the media player time to find the row that matches up to time we first need to have th right purpose
                        if self?.purpose == .selectingTime {
                            let block = {
                                Thread.onMainThread {
                                    self?.follow()
                                }
                            }

                            // Then we need to know if we're still seeking or not and if we are we need to push the same action to be done after seeking completes.
                            if !Globals.shared.mediaPlayer.isSeeking {
                                block()
                            } else {
                                Globals.shared.mediaPlayer.seekingCompletion = {
                                    block()
                                }
                            }
                        }
                    }

                    self?.updateToolbar()
                    
                    if let indexPath = self?.section.indexPath(from: self?.selectedText) {
                        self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                    }

                    if self?.navigationController?.topViewController == self {
                        self?.activityIndicator.stopAnimating()
                        self?.activityIndicator.isHidden = true
                    }
                }
            }
        } else
            
        if stringsAny != nil, self.section.strings == nil {
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
                
                if let indexPath = section.indexPath(from: stringSelected) {
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            }
        } else
            
        if stringsArray != nil, self.section.strings == nil {
            self.section.strings = self.stringsArray

            self.setPreferredContentSize()
        } else
            
        if stringsAnyArray != nil, self.section.strings == nil {
            if let stringsAnyArray = self.stringsAnyArray {
                var strings = [String]()
                for stringsAny in stringsAnyArray {
                    if let string = stringsAny["w"] as? String {
                        strings.append(string)
                    } else
                    if let string = stringsAny["keyword"] as? String {
                        strings.append(string)
                    } else
                    if let string = stringsAny["topicName"] as? String {
                        strings.append(string)
                    } else
                    if let string = stringsAny["name"] as? String {
                        strings.append(string)
                    } else {
                        var string = "("
                        let keys = stringsAny.keys.sorted()
                        for key in keys {
                            string = string + key
                            if key != keys.last {
                                string = string + ","
                            }
                        }
                        string = string + ")"
                        strings.append(string)
                    }
                }
                self.section.strings = strings

                self.setPreferredContentSize()
                
                if let indexPath = section.indexPath(from: stringSelected) {
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            }
        } else
            
        if section.strings != nil {
            if section.showIndex {
                if (self.section.indexStrings?.count <= 1) {
                    // This can be a problem if this PTVC will appear because we are coming back to it and it was in search mode w/ 0 or 1 result.
                    // If then we get out of search mode and showIndex is copied from the filteredSection to the unfiltereSection and the unfilteredSection
                    // started w/ showIndex true then it will be set to false.  Right now we're trying avoid this by doing the copy back only for purpose == .selectingWord
                    // and in those case there is never a push or a back and the copy back is to reflect changes in alpha vs. freq sorting of the words.
                    section.showIndex = false
                    tableView.reloadData()
                }
            }
            
            setPreferredContentSize()
            
            if let indexPath = section.indexPath(from: stringSelected) {
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        }
        
        searchBar.isUserInteractionEnabled = searchInteractive
        
        updateToolbar()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}

extension PopoverTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // Return the number of sections.
        if section.showIndex || section.showHeaders {
            if let count = section.counts?.count {
                return count
            } else {
                return 0
            }
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // Return the number of rows in the section.
        if self.section.showIndex || self.section.showHeaders {
            if let counts = self.section.counts, (section >= 0) && (section < counts.count) {
                return counts[section]
            } else {
                return 0
            }
        } else {
            if let count = self.section.strings?.count {
                return count
            } else {
                return 0
            }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard let cell = cell as? PopoverTableViewCell else {
            return
        }
        
        let index = section.index(indexPath)
        
        if let selected = selection?(index) {
            cell.setSelected(selected, animated: false)
            if selected {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as? PopoverTableViewCell) ?? PopoverTableViewCell()
        
        cell.title.text = nil
        cell.title.attributedText = nil
        
        cell.isSelected = false
        cell.isHighlighted = false

        var index = -1
        
        index = section.index(indexPath)
        
        guard index >= 0 else {
            print("ERROR")
            return cell
        }
        
        guard index < section.strings?.count else {
            print("ERROR")
            return cell
        }
        
        guard let string = section.strings?[index].replacingOccurrences(of: Constants.UNBREAKABLE_SPACE, with: " ") else {
            print("ERROR")
            return cell
        }
        
        if search, searchActive, let searchText = searchText?.lowercased() {
            var titleString = NSMutableAttributedString()
            
            var before:String?
            var during:String?
            var after:String?
            
            var range = string.lowercased().range(of: searchText.lowercased())
            
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            if range == nil {
                // This is a special case to catch when the search text is a phrase, all the results are set from
                // VB times for the phrase (aka keyword) and it is nil because less than the full phrase appears.
                //
                // This ASSUMES that the list of results (i.e. the strings) is transcript segments generated from the
                // phrase start times, meaning the whole phrase should appear unless the start time is close to the end time
                // for the segment, in which case, since segments end on word boundaries, at least one or more but not all
                // of the words, should appear.
                //
                
                let words = searchText.split(separator: " ").map { (substring) -> String in
                    String(substring)
                }
                
                if words.count > 1 {
                    var strings = [String]()
                    var phrase : String?
                    
                    // Assemble the list of "less than the full phrase" phrases to look for.
                    for i in 0..<words.count {
                        if i == (words.count - 1) {
                            break
                        }

                        if phrase == nil {
                            phrase = words[i]
                        } else {
                            phrase = (phrase ?? "") + " " + words[i]
                        }
                        
                        if let phrase = phrase {
                            strings.append(phrase)
                        }
                    }

                    // reverse them since we want to look for the longest first.
                    strings.reverse()
                    
                    // Now look for them.
                    for subString in strings {
                        var searchRange = Range(uncheckedBounds: (lower: string.startIndex, upper: string.endIndex))

                        var rng = string.lowercased().range(of: subString.lowercased(), options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
                        
                        // But even if there is a match we have to find the LAST match
                        if rng != nil {
                            var lastRange : Range<String.Index>?
                            
                            repeat {
                                lastRange = rng
                                searchRange = Range(uncheckedBounds: (lower: rng!.upperBound, upper: string.endIndex))
                                rng = string.lowercased().range(of: subString.lowercased(), options: String.CompareOptions.caseInsensitive, range:searchRange, locale: nil)
                            } while rng != nil
                            
                            // And it only counts if the match is at the end of the string
                            if lastRange?.upperBound == string.endIndex {
                                range = lastRange
                                break
                            }
                        }
                    }
                    
                    if range == nil {
                        // THIS SHOULD NEVER HAPPEN
                    }
                } else {
                    // THIS SHOULD NEVER HAPPEN
                }
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            repeat {
                if let range = range {
                    before = String(string[..<range.lowerBound])
                    during = String(string[range])
                    after = String(string[range.upperBound...])
                    
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
                    
                    if let characterBefore:Character = before?.last, let characterAfter:Character = after?.first {
                        if  let before = UnicodeScalar(String(characterBefore)), !CharacterSet.letters.contains(before),
                            let after = UnicodeScalar(String(characterAfter)), !CharacterSet.letters.contains(after) {
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
            } while after?.contains(searchText) ?? false
            
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
        
        if stringSelected == string {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            if let detailDisclosure = detailDisclosure?(tableView,indexPath), detailDisclosure {
                cell.accessoryType = UITableViewCellAccessoryType.detailButton
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        return cell
    }
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
            Thread.onMainThread {
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
        
        view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        
        if view?.label == nil {
            let label = UILabel()
            
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(label)

//            if let superview = label.superview {
//                let centerY = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
//                label.superview?.addConstraint(centerY)
//
//                let leftMargin = NSLayoutConstraint(item: superview, attribute: NSLayoutAttribute.leftMargin, relatedBy: NSLayoutRelation.equal, toItem: label, attribute: NSLayoutAttribute.leftMargin, multiplier: 1.0, constant: 0.0)
//                label.superview?.addConstraint(leftMargin)
//            }
            
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllLeft], metrics: nil, views: ["label":label]))
            
            view?.label = label
        }
        
        view?.alpha = 0.85
        
        if section >= 0, section < self.section.headers?.count, let title = self.section.headers?[section] {
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR",   attributes: Constants.Fonts.Attributes.bold)
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if transcript !=  nil, purpose == .selectingTime, !track { // (!track || searchActive)
            // .selectingTime using Timed Words
            return false
        }
        
        if let transcript = transcript, purpose == .selectingTime {
            // .selectingTime using Timed Segments
            return transcript.rowActions(popover: self, tableView: tableView, indexPath: indexPath) != nil
        }
        
        // Otherwise
        return editActionsAtIndexPath?(self,tableView,indexPath) != nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var alertActions : [AlertAction]?
        
        if let transcript = self.transcript {
            alertActions = transcript.rowActions(popover: self, tableView: tableView, indexPath: indexPath)
        } else {
            alertActions = self.editActionsAtIndexPath?(self,tableView,indexPath)
        }
        
        let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
            let alert = UIAlertController(  title: Constants.Strings.Actions,
                                            message: self.section.string(from: indexPath),
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            if let alertActions = alertActions {
                for alertAction in alertActions {
                    let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                        alertAction.handler?()
                    })
                    alert.addAction(action)
                }
            }
            
            let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction) -> Void in
            })
            alert.addAction(okayAction)
            
            self.present(alert, animated: true, completion: {
                self.alertController = alert
            })
        }
        action.backgroundColor = UIColor.controlBlue()
        
        return alertActions != nil ? [action] : nil
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
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        if allowsMultipleSelection, let purpose = purpose {
            var index = -1
            
            index = section.index(indexPath)
            
            delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose, mediaItem: selectedMediaItem)
        }
    }
    
    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:didSelectRowAt",completion:nil)
            return
        }
        
        guard didSelect == nil else {
            didSelect?(indexPath)
            return
        }
        
        if purpose == .selectingTime, Globals.shared.mediaPlayer.currentTime != nil {
            activityIndicator.startAnimating()

            if trackingTimer != nil {
                trackingTimer?.invalidate()
                trackingTimer = nil
            }
            
            // This is a hack because it is being done because we know the delegate call makes a seek.
            Globals.shared.mediaPlayer.seekingCompletion = {
                Thread.onMainThread {
                    self.activityIndicator.stopAnimating()
                    if self.isTracking {
                        self.trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.follow), userInfo: nil, repeats: true)
                    }
                }
            }
        }
        
        if searchActive {
            self.searchBar.resignFirstResponder()
        }
        
        if isTracking {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }

        var index = -1
        
        index = section.index(indexPath)

        guard let string = section.strings?[index] else {
            return
        }
        
        if let range = string.range(of: " (") {
            selectedText = String(string[..<range.lowerBound]).uppercased()
        }

        if let purpose = purpose {
            switch purpose {
                
            default:
                delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose, mediaItem: selectedMediaItem)
                break
            }
        }

        if  (transcript !=  nil) && (purpose == .selectingTime) && (!track || searchActive) {
            if  let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                popover.navigationItem.title = string.components(separatedBy: "\n").first
                
                popover.selectedMediaItem = self.selectedMediaItem
                popover.transcript = self.transcript
                
                popover.search = false // This keeps it to one level deep.
                
                popover.editActionsAtIndexPath = self.editActionsAtIndexPath
                
                popover.delegate = self.delegate // as? PopoverTableViewControllerDelegate
                popover.purpose = self.purpose
                
                popover.parser = self.parser
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                    guard let first = first else {
                        return false
                    }
                    guard let second = second else {
                        return true
                    }
                    return Int(first) < Int(second)
                }
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                
                // Must use stringsFunction with .selectingTime.
                popover.stringsFunction = { () -> [String]? in
                    return self.transcript?.transcriptSegmentComponents?.filter({ (string:String) -> Bool in
                        return string.components(separatedBy: "\n").count > 1
                    }).map({ (transcriptSegmentComponent:String) -> String in
                        var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                        
                        if transcriptSegmentArray.count > 2  {
                            let count = transcriptSegmentArray.removeFirst()
                            let timeWindow = transcriptSegmentArray.removeFirst()
                            let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") // 
                            
                            if  let start = times.first,
                                let end = times.last,
                                let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                let string = "\(count)\n\(start) to \(end)\n" + text
                                
                                return string
                            }
                        }
                        
                        return "ERROR"
                    })
                }

                popover.track = true
                popover.assist = true
                
                popover.stringSelected = string
                
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
            if index < self.stringsAnyArray?.count {
                if searchActive, let searchText = searchText {
                    stringsAny = self.stringsAnyArray?.filter({ (dict:[String:Any]) -> Bool in
                        return (dict["w"] as? String)?.lowercased().range(of: (searchText.lowercased())) != nil
                    })[index]
                } else {
                    stringsAny = self.stringsAnyArray?[index]
                }
            }
        }
        
        if (delegate == nil) && ((stringsAny != nil) || (stringsArray != nil) || (stringsAnyArray != nil)) {
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
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
