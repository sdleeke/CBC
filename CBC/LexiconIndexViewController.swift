//
//  LexiconIndexViewController.swift
//  CBC
//
//  Created by Steve Leeke on 2/2/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

extension LexiconIndexViewController : UIAdaptivePresentationControllerDelegate
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

extension LexiconIndexViewController : PopoverPickerControllerDelegate
{
    //  MARK: PopoverPickerControllerDelegate

    func stringPicked(_ string: String?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:stringPicked",completion:nil)
            return
        }
        
        self.dismiss(animated: true, completion: nil)
        self.tableView.setEditing(false, animated: true)
        self.ptvc.selectString(string, scroll: true, select: true)
        
        searchText = string
    }
}

extension LexiconIndexViewController : PopoverTableViewControllerDelegate
{
    //  MARK: PopoverTableViewControllerDelegate

    func actionMenu(action: String?,mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:actionMenu", completion: nil)
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.Sorting:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = Constants.Actions
                
                popover.navigationItem.title = "Select"
                navigationController.isNavigationBarHidden = false

//                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingSorting
                popover.stringSelected = self.ptvc.sort.method
                
                popover.section.strings = [Constants.Sort.Alphabetical,Constants.Sort.Frequency]
//                
//                popover.section.showIndex = false
//                popover.section.showHeaders = false
                
                popover.vc = self
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                popover.navigationItem.title = "Select"
                navigationController.isNavigationBarHidden = false

                if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                    let hClass = traitCollection.horizontalSizeClass
                    
                    if hClass == .compact {
                        navigationController.modalPresentationStyle = .overCurrentContext
                    } else {
                        // I don't think this ever happens: collapsed and regular
                        navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                    }
                } else {
                    navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                }
                
//                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Strings.Word_Picker
                
                popover.delegate = self
                
//                popover.mediaListGroupSort = mediaListGroupSort
                
                popover.stringTree = StringTree(incremental: true)
                popover.strings = mediaListGroupSort?.lexicon?.tokens
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.View_List:
            process(viewController: self, work: { () -> (Any?) in
                if self.results?.html?.string == nil {
                    self.results?.html?.string = self.setupMediaItemsHTMLLexicon(includeURLs: true, includeColumns: true)
                }
                
                return self.results?.html?.string
            }, completion: { (data:Any?) in
                if let searchText = self.searchText {
                    presentHTMLModal(viewController: self, mediaItem: nil, style: .overFullScreen, title: "Lexicon Index For: \(searchText)", htmlString: data as? String)
                }
            })
            break
            
        default:
            break
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingSorting:
            dismiss(animated: true, completion: nil)

            ptvc.sort.method = string
            
            switch string {
            case Constants.Sort.Alphabetical:
                ptvc.section.showIndex = true
                break
                
            case Constants.Sort.Frequency:
                ptvc.section.showIndex = false
                break
                
            default:
                break
            }
            
            ptvc.section.strings = ptvc.sort.function?(ptvc.sort.method,ptvc.section.strings)
            
//            ptvc.section.buildIndex()
            
            ptvc.tableView.reloadData()
            break
            
        case .selectingSection:
            dismiss(animated: true, completion: nil)
            
            if let headerStrings = results?.section?.headerStrings {
                var i = 0
                for headerString in headerStrings {
                    if headerString == string {
                        break
                    }
                    
                    i += 1
                }
                
                let indexPath = IndexPath(row: 0, section: i)
                
                if !(indexPath.section < tableView.numberOfSections) {
                    NSLog("indexPath section ERROR in LexiconIndex .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    break
                }
                
                if !(indexPath.row < tableView.numberOfRows(inSection: indexPath.section)) {
                    NSLog("indexPath row ERROR in LexiconIndex .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    NSLog("Row: \(indexPath.row)")
                    NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                    break
                }
                
                //Can't use this reliably w/ variable row heights.
                tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            }
            break
            
        case .selectingLexicon:
            if let range = string.range(of: " (") {
                searchText = string.substring(to: range.lowerBound).uppercased()
                
                Thread.onMainThread() {
                    self.tableView.setEditing(false, animated: true)
                }
                
                updateSearchResults()
            }
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)

            actionMenu(action:string,mediaItem:mediaItem)
            break
            
        case .selectingCellAction:
            dismiss(animated: true, completion: nil)
            
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Strings.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
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

extension LexiconIndexViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension LexiconIndexViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class LexiconIndexViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class LexiconIndexViewController : UIViewController
{
    var mediaListGroupSort:MediaListGroupSort?
    
    var root:StringNode?
    
    var lexicon:Lexicon?
    {
        get {
            return mediaListGroupSort?.lexicon
        }
    }
    
    var searchText:String? {
        get {
            return lexicon?.selected
        }
        set {
            lexicon?.selected = newValue

            ptvc.selectedText = searchText
            
            Thread.onMainThread() {
                self.selectedWord.text = self.searchText

                self.updateLocateButton()
            }
            
            updateSearchResults()
        }
    }
    
    var results:MediaListGroupSort?

    var changesPending = false

    var selectedMediaItem:MediaItem?
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(LexiconIndexViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "LexiconIndexViewController")
        }
    }
    
    @IBOutlet weak var container: UIView!
    
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var selectedWord: UILabel!
    
    @IBOutlet weak var locateButton: UIButton!
    @IBAction func LocateAction(_ sender: UIButton)
    {
        ptvc.selectString(searchText,scroll: true,select: true)
    }
    
    func updateDirectionLabel()
    {

    }

    func disableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.isEnabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.isEnabled = true
            }
        }
    }
    
    func enableBarButtons()
    {
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        enableToolBarButtons()
    }
    
    func updateSearchResults()
    {
        guard let searchText = searchText else {
            results = nil
            Thread.onMainThread() {
                self.updateActionMenu()
                self.tableView.reloadData()
                self.updateUI()
            }
            return
        }

        // Show the results directly rather than by executing a search
        results = MediaListGroupSort(mediaItems: self.lexicon?.words?[searchText]?.map({ (mediaItemFrequency:(key:MediaItem,value:Int)) -> MediaItem in
            return mediaItemFrequency.key
        }))
        
        Thread.onMainThread() {
            if !self.tableView.isEditing {
                self.tableView.reloadData()
            } else {
                self.changesPending = true
            }
            
            self.updateUI()
        }
    }
    
    var ptvc:PopoverTableViewController!
    
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
                    
                    ptvc.segments = true
                    
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
                                        
                                        if let rangeLeft = left.range(of: " "), let rangeRight = right.range(of: " ") {
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
                        self.updateLocateButton()
                        DispatchQueue.global(qos: .background).async { [weak self] in
                            self?.ptvc.section.strings = self?.ptvc.sort.function?(self?.ptvc.sort.method,self?.ptvc.section.strings)
                            Thread.onMainThread(block: { (Void) -> (Void) in
                                self?.ptvc.tableView.isHidden = false
                                self?.ptvc.tableView.reloadData()
                                
                                if self?.lexicon?.creating == false {
                                    self?.ptvc.activityIndicator.stopAnimating()
                                }
                                self?.ptvc.segmentedControl.isEnabled = true
                                self?.updateLocateButton()
                            })
                        }
                    }))
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                        self.ptvc.sort.method = Constants.Sort.Frequency
                        self.ptvc.section.showIndex = false
                        self.ptvc.tableView.isHidden = true
                        self.ptvc.activityIndicator.startAnimating()
                        self.ptvc.segmentedControl.isEnabled = false
                        self.updateLocateButton()
                        DispatchQueue.global(qos: .background).async { [weak self] in
                            self?.ptvc.section.strings = self?.ptvc.sort.function?(self?.ptvc.sort.method,self?.ptvc.section.strings)
                            Thread.onMainThread(block: { (Void) -> (Void) in
                                self?.ptvc.tableView.isHidden = false
                                self?.ptvc.tableView.reloadData()
                                
                                if self?.lexicon?.creating == false {
                                    self?.ptvc.activityIndicator.stopAnimating()
                                }
                                self?.ptvc.segmentedControl.isEnabled = true
                                self?.updateLocateButton()
                            })
                        }
                    }))
                    
                    ptvc.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    ptvc.delegate = self
                    ptvc.purpose = .selectingLexicon
                    
                    ptvc.search = true
                    ptvc.segments = true

                    ptvc.section.showIndex = true

                    ptvc.section.strings = self.mediaListGroupSort?.lexicon?.section.strings
                }
                break
                
            case Constants.SEGUE.SHOW_INDEX_MEDIAITEM:
                if let myCell = sender as? MediaTableViewCell {
                    if (selectedMediaItem != myCell.mediaItem) || (globals.history == nil) {
                        globals.addToHistory(myCell.mediaItem)
                    }
                    selectedMediaItem = myCell.mediaItem
                    
                    if selectedMediaItem != nil {
                        if let destination = dvc as? MediaViewController {
                            destination.selectedMediaItem = selectedMediaItem
                        }
                    }
                }
                break
                
            default:
                break
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        var show:Bool
        
        show = true
        
        switch identifier {
        case "Show Index MediaItem":
            show = false
            break
            
        default:
            break
        }
        
        return show
    }
    
    func updateLocateButton()
    {
        // Not necessarily called on the main thread.
        
        if (self.searchText != nil) {
            Thread.onMainThread() {
                self.locateButton.isHidden = false
                
                if !self.ptvc.tableView.isHidden {
                    self.locateButton.isEnabled = true
                } else {
                    self.locateButton.isEnabled = false
                }
            }
        } else {
            Thread.onMainThread() {
                self.locateButton.isHidden = true
                self.locateButton.isEnabled = false
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        selectedWord.text = searchText

        updateLocateButton()

        if lexicon != nil {
            globals.queue.async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
            })
        }
        
        navigationItem.hidesBackButton = false
        
        if  let count = lexicon?.entries?.count,
            let total = lexicon?.eligible?.count {
            self.navigationItem.title = "Lexicon Index \(count) of \(total)"
        }
        
        updateSearchResults()
        updateUI()

        lexicon?.build()
        
        navigationController?.setToolbarHidden(false, animated: false)
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

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if lexicon?.completed == false {
            ptvc.activityIndicator.startAnimating()
        }

        ptvc.selectString(searchText,scroll: true,select: true)
        
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func setupMediaItemsHTMLLexicon(includeURLs:Bool,includeColumns:Bool) -> String?
    {
        guard let mediaItems = results?.mediaItems else {
            return nil
        }
        
        guard let grouping = globals.grouping, let sorting = globals.sorting else {
            return nil
        }
        
        var bodyString = "<!DOCTYPE html><html><body>"
        
        if let searchText = searchText {
            bodyString = bodyString + "Lexicon Index For \(searchText):"
            
            var appearances = 0

            for mediaItem in mediaItems {
                if let count = mediaItem.notesTokens?[searchText] {
                    appearances += count
                }
            }
            
            bodyString = bodyString + " \(appearances) Occurrences in \(mediaItems.count) Documents<br/><br/>"
        }
        
        bodyString = bodyString + "The following media "
        
        if results?.list?.count > 1 {
            bodyString = bodyString + "are"
        } else {
            bodyString = bodyString + "is"
        }
        
        if includeURLs {
            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = globals.mediaCategory.selected {
            bodyString = bodyString + "Category: \(category)<br/>"
        }
        
        if globals.media.tags.showing == Constants.TAGGED, let tag = globals.media.tags.selected {
            bodyString = bodyString + "Collection: \(tag)<br/>"
        }
        
        if globals.search.valid, let searchText = globals.search.text {
            bodyString = bodyString + "Search: \(searchText)<br/>"
        }
        
        if let grouping = translate(globals.grouping) {
            bodyString = bodyString + "Grouped: By \(grouping)<br/>"
        }
        
        if let sorting = translate(globals.sorting) {
            bodyString = bodyString + "Sorted: \(sorting)<br/>"
        }
        
        if let keys = results?.section?.indexStrings {
            if includeURLs, (keys.count > 1) {
                bodyString = bodyString + "<br/>"
                bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
            }
            
            if includeColumns {
                bodyString = bodyString + "<table>"
            }
            
            for key in keys {
                if  let name = results?.groupNames?[grouping]?[key],
                    let mediaItems = results?.groupSort?[grouping]?[key]?[sorting] {
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        if let speaker = mediaItem.speaker {
                            guard let count = speakerCounts[speaker] else {
                                speakerCounts[speaker] = 1
                                continue
                            }

                            speakerCounts[speaker] = count + 1
                        }
                    }
                    
                    let speakerCount = speakerCounts.keys.count
                    
                    let tag = key.replacingOccurrences(of: " ", with: "")

                    if includeColumns {
                        bodyString = bodyString + "<tr><td><br/></td></tr>"
                        bodyString = bodyString + "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" // valign=\"baseline\" 
                    }
                    
                    if includeURLs, (keys.count > 1) {
                        bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + " (\(mediaItems.count))" + "</a>"
                    } else {
                        bodyString = bodyString + name + " (\(mediaItems.count))"
                    }
                    
                    if speakerCount == 1 {
                        if let speaker = mediaItems[0].speaker, name != speaker {
                            bodyString = bodyString + " by " + speaker
                        }
                    }
                    
                    if includeColumns {
                        bodyString = bodyString + "</td>"
                        bodyString = bodyString + "</tr>"
                    } else {
                        bodyString = bodyString + "<br/>"
                    }
                    
                    for mediaItem in mediaItems {
                        var order = ["date","title","count","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        if globals.grouping != GROUPING.CLASS {
                            if let className = mediaItem.className, !className.isEmpty {
                                order.append("class")
                            }
                        }
                        
                        if globals.grouping != GROUPING.EVENT {
                            if let eventName = mediaItem.eventName, !eventName.isEmpty {
                                order.append("event")
                            }
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, token: searchText, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString = bodyString + string
                        }
                        
                        if !includeColumns {
                            bodyString = bodyString + "<br/>"
                        }
                    }
                }
            }
            
            if includeColumns {
                bodyString = bodyString + "</table>"
            }
            
            bodyString = bodyString + "<br/>"
            
            if includeURLs, keys.count > 1 {
                bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"
                
                if let grouping = globals.grouping {
                    switch grouping {
                    case GROUPING.CLASS:
                        fallthrough
                    case GROUPING.SPEAKER:
                        fallthrough
                    case GROUPING.TITLE:
                        let a = "A"
                        
                        if let indexTitles = results?.section?.indexStrings {
                            let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                                if string.endIndex >= a.endIndex, let indexString = stringWithoutPrefixes(string)?.substring(to: a.endIndex).uppercased() {
                                    return indexString
                                } else {
                                    return string
                                }
                            }))).sorted() { $0 < $1 }
                            
                            var stringIndex = [String:[String]]()
                            
                            if let indexStrings = results?.section?.indexStrings {
                                for indexString in indexStrings {
                                    let key = indexString.substring(to: a.endIndex).uppercased()
                                    
                                    if stringIndex[key] == nil {
                                        stringIndex[key] = [String]()
                                    }
                                    stringIndex[key]?.append(indexString)
                                }
                            }
                            
                            var index:String?
                            
                            for title in titles {
                                let link = "<a href=\"#\(title)\">\(title)</a>"
                                index = ((index != nil) ? index! + " " : "") + link
                            }
                            
                            bodyString = bodyString + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                            
                            if let index = index {
                                bodyString = bodyString + index + "<br/><br/>"
                            }
                            
                            for title in titles {
                                bodyString = bodyString + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                                
                                if let keys = stringIndex[title] {
                                    for key in keys {
                                        if let title = results?.groupNames?[grouping]?[key],
                                            let count = results?.groupSort?[grouping]?[key]?[sorting]?.count {
                                            let tag = key.replacingOccurrences(of: " ", with: "")
                                            bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                                        }
                                    }
                                    bodyString = bodyString + "<br/>"
                                }
                            }
                            
                            bodyString = bodyString + "</div>"
                        }
                        break
                        
                    default:
                        for key in keys {
                            if let title = results?.groupNames?[grouping]?[key],
                                let count = results?.groupSort?[grouping]?[key]?[sorting]?.count {
                                let tag = key.replacingOccurrences(of: " ", with: "")
                                bodyString = bodyString + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                            }
                        }
                        break
                    }
                }
                
                bodyString = bodyString + "</div>"
            }
        }
        
        bodyString = bodyString + "</body></html>"
        
        return insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()

        if lexicon?.tokens?.count > 0 {
            actionMenu.append(Constants.Strings.Word_Picker)
        }

        if results?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:actions", completion: nil)
            return
        }
        
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationItem.title = "Select"
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenuItems()
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func started()
    {
        
    }
    
    func updateTitle()
    {
        Thread.onMainThread() {
            if  let count = self.lexicon?.entries?.count,
                let total = self.lexicon?.eligible?.count {
                self.navigationItem.title = "Lexicon Index \(count) of \(total)"
            }
        }
    }
    
    func updated()
    {
        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
        
        Thread.onMainThread {
            self.ptvc.unfilteredSection.strings = (self.ptvc.sort.function == nil) ? self.lexicon?.section.strings : self.ptvc.sort.function?(self.ptvc.sort.method,self.lexicon?.section.strings)
            self.ptvc.updateSearchResults()

            self.ptvc.tableView.reloadData()
        }
    }
    
    func completed()
    {
        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
        
        Thread.onMainThread {
            self.ptvc.activityIndicator.stopAnimating()

            self.ptvc.unfilteredSection.strings = (self.ptvc.sort.function == nil) ? self.lexicon?.section.strings : self.ptvc.sort.function?(self.ptvc.sort.method,self.lexicon?.section.strings)
            self.ptvc.updateSearchResults()
            
            self.ptvc.tableView.reloadData()
        }
    }
    
    func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:index", completion: nil)
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection
            
            popover.section.strings = results?.section?.headerStrings
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(LexiconIndexViewController.index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([spaceButton,indexButton], animated: false)

        navigationController?.toolbar.isTranslucent = false
        
        selectedWord.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(LexiconIndexViewController.actions))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        navigationItem.setRightBarButton(actionButton, animated: true)
    }
    
    func updateText()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:updateText", completion: nil)
            return
        }
     
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenUI", completion: nil)
            return
        }
        
        directionLabel.isHidden = state
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
        isHiddenNumberAndTableUI(state)
    }
    
    func isHiddenNumberAndTableUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenNumberAndTableUI", completion: nil)
            return
        }
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
        tableView.isHidden = state
    }
    
    func updateActionMenu()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:updateActionMenu", completion: nil)
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "LexiconIndexViewController:updateUI", completion: nil)
            return
        }
        
        toolbarItems?[1].isEnabled = tableView.numberOfSections > 1
        
        spinner.isHidden = true
        spinner.stopAnimating()
        
        logo.isHidden = searchText != nil
        
        updateActionMenu()
        
        isHiddenUI(false)
        
        updateDirectionLabel()
        
        updateText()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}

extension LexiconIndexViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return
        }
        
        var mediaItem:MediaItem?
        
        mediaItem = cell.mediaItem
        
        globals.addToHistory(mediaItem)
        
        performSegue(withIdentifier: Constants.SEGUE.SHOW_INDEX_MEDIAITEM, sender: cell)
        
//        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
//            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
//                let viewController = navigationController.viewControllers[0] as? MediaViewController {
//                viewController.selectedMediaItem = mediaItem
//                splitViewController?.viewControllers[1] = navigationController
//            }
//        } else {
//            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM) as? MediaViewController {
//                viewController.selectedMediaItem = mediaItem
//                
//                self.navigationController?.navigationItem.hidesBackButton = false
//                
//                self.navigationController?.pushViewController(viewController, animated: true)
//            }
//        }
    }

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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        var mediaItem : MediaItem?
        
        if (indexPath.section >= 0) && (indexPath.section < results?.section?.indexes?.count) {
            if let section = results?.section?.indexes?[indexPath.section] {
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.mediaItems?.count {
                    mediaItem = results?.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }

        return editActions(cell: nil,mediaItem: mediaItem) != nil
    }
    
    func editActions(cell:MediaTableViewCell?,mediaItem:MediaItem?) -> [AlertAction]?
    {
        // causes recursive call to cellForRow 
//        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
//            return nil
//        }
        
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        let searchText = cell?.searchText
        
        var actions = [AlertAction]()
        
        var download:AlertAction!
        var transcript:AlertAction!
        var scripture:AlertAction!
        
        if mediaItem.hasAudio, let state = mediaItem.audioDownload?.state {
            var title = ""
            var style = UIAlertActionStyle.default
            
            switch state {
            case .none:
                title = Constants.Strings.Download_Audio
                break
                
            case .downloading:
                title = Constants.Strings.Cancel_Audio_Download
                break
            case .downloaded:
                title = Constants.Strings.Delete_Audio_Download
                style = UIAlertActionStyle.destructive
                break
            }
            
            download = AlertAction(title: title, style: style, action: {
                switch title {
                case Constants.Strings.Download_Audio:
                    mediaItem.audioDownload?.download()
                    break
                    
                case Constants.Strings.Delete_Audio_Download:
                    let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                    message: nil,
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                        (action : UIAlertAction!) -> Void in
                        mediaItem.audioDownload?.delete()
                    })
                    alert.addAction(yesAction)
                    
                    let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(noAction)
                    
                    let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(cancel)
                    
                    self.present(alert, animated: true, completion: nil)
                    break
                    
                case Constants.Strings.Cancel_Audio_Download:
                    if let state = mediaItem.audioDownload?.state {
                        switch state {
                        case .downloading:
                            mediaItem.audioDownload?.cancel()
                            break
                            
                        case .downloaded:
                            let alert = UIAlertController(  title: "Confirm Deletion of Audio Download",
                                                            message: nil,
                                                            preferredStyle: .alert)
                            alert.makeOpaque()
                            
                            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                                (action : UIAlertAction!) -> Void in
                                mediaItem.audioDownload?.delete()
                            })
                            alert.addAction(yesAction)
                            
                            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                                (action : UIAlertAction!) -> Void in
                                
                            })
                            alert.addAction(noAction)
                            
                            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                                (action : UIAlertAction!) -> Void in
                                
                            })
                            alert.addAction(cancel)
                            
                            self.present(alert, animated: true, completion: nil)
                            break
                            
                        default:
                            break
                        }
                    }
                    break
                    
                default:
                    break
                }
            })
        }
        
        transcript = AlertAction(title: Constants.Strings.Transcript, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0]
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                htmlString = mediaItem.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true,index: true)
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    return mediaItem.markedFullNotesHTML(searchText:searchText, wholeWordsOnly: true,index: true)
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable(self,"HTML transcript unavailable.")
                    }
                })
            }
        }
        
        scripture = AlertAction(title: Constants.Strings.Scripture, style: .default) {
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0]
            
            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    guard globals.reachability.isReachable else {
                        networkUnavailable(self,"Scripture text unavailable.")
                        return
                    }
                    
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load()
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable(self,"Scripture text unavailable.")
                        }
                    })
                }
            }
        }
        
        if mediaItem.books != nil {
            actions.append(scripture)
        }
        
        if mediaItem.hasNotesHTML {
            actions.append(transcript)
        }
        
        if mediaItem.hasAudio && (download != nil) {
            actions.append(download)
        }
        
        if actions.count == 0 {
            print("")
        }
        
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
            let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
                let alert = UIAlertController(  title: Constants.Strings.Actions,
                                                message: message,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                if let alertActions = self.editActions(cell: cell, mediaItem: cell.mediaItem) {
                    for alertAction in alertActions {
                        let action = UIAlertAction(title: alertAction.title, style: alertAction.style, handler: { (UIAlertAction) -> Void in
                            alertAction.action?()
                        })
                        alert.addAction(action)
                    }
                }
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction) -> Void in
                })
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            action.backgroundColor = UIColor.controlBlue()
            
            return [action]
        }
        
        return nil
    }
}

extension LexiconIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard results?.section?.headerStrings != nil else {
            return nil
        }

        if (section >= 0) && (section < results?.section?.headerStrings?.count) {
            return results?.section?.headerStrings?[section]
        } else {
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        if let count = results?.section?.counts?.count {
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let count = results?.section?.counts?[section] {
            return count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as? MediaTableViewCell) ?? MediaTableViewCell()

        cell.hideUI()
        
        cell.vc = self
        
        cell.searchText = searchText
        
        if (indexPath.section >= 0) && (indexPath.section < results?.section?.indexes?.count) {
            if let section = results?.section?.indexes?[indexPath.section] {
                if (section + indexPath.row) >= 0, (section + indexPath.row) < results?.mediaItems?.count {
                    cell.mediaItem = results?.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }
        
        if let searchText = searchText, let mediaItem = cell.mediaItem, let count = mediaItem.notesTokens?[searchText] {
            cell.countLabel.text = count.description
        } else {
            cell.countLabel.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section >= 0, section < results?.section?.headerStrings?.count, let title = results?.section?.headerStrings?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).height
        
        //        print(height,max(Constants.HEADER_HEIGHT,height + 28))
        
        return max(Constants.HEADER_HEIGHT,height + 28)
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
        var view : LexiconIndexViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "LexiconIndexViewController") as? LexiconIndexViewControllerHeaderView
        
        if view == nil {
            view = LexiconIndexViewControllerHeaderView()
        }
        
        view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        
        if view?.label == nil {
            let label = UILabel()
            
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(label)
            
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":label]))
            
            view?.label = label
        }
        
        view?.alpha = 0.85
        
        if section >= 0, section < results?.section?.headerStrings?.count, let title = results?.section?.headerStrings?[section] {
            view?.label?.attributedText = NSAttributedString(string: title, attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR", attributes: Constants.Fonts.Attributes.bold)
        }
        
        return view
    }
}
