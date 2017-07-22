//
//  LexiconIndexViewController.swift
//  CBC
//
//  Created by Steve Leeke on 2/2/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

//extension NSLayoutConstraint {
//  MARK: NSLayoutConstraint extension
//    /**
//     Change multiplier constraint
//     
//     - parameter multiplier: CGFloat
//     - returns: NSLayoutConstraint
//     */
//    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
//        
//        NSLayoutConstraint.deactivate([self])
//        
//        let newConstraint = NSLayoutConstraint(
//            item: firstItem,
//            attribute: firstAttribute,
//            relatedBy: relation,
//            toItem: secondItem,
//            attribute: secondAttribute,
//            multiplier: multiplier,
//            constant: constant)
//        
//        newConstraint.priority = priority
//        newConstraint.shouldBeArchived = self.shouldBeArchived
//        newConstraint.identifier = self.identifier
//        
//        NSLayoutConstraint.activate([newConstraint])
//        return newConstraint
//    }
//}

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
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.Sorting:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = Constants.Actions
                
                popover.navigationItem.title = "Select"
                navigationController.isNavigationBarHidden = false

//                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingSorting
                
                popover.section.strings = [Constants.Sort.Alphabetical,Constants.Sort.Frequency]
//                
//                popover.section.showIndex = false
//                popover.section.showHeaders = false
                
                popover.vc = self
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Word_Picker:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                popover.navigationItem.title = "Select"
                navigationController.isNavigationBarHidden = false

                if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                    let hClass = traitCollection.horizontalSizeClass
                    
                    if hClass == .compact {
                        navigationController.modalPresentationStyle = .overCurrentContext
                    } else {
                        // I don't think this ever happens: collapsed and regular
                        navigationController.modalPresentationStyle = .popover
                    }
                } else {
                    navigationController.modalPresentationStyle = .popover
                }
                
//                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                popover.navigationItem.title = Constants.Strings.Word_Picker
                
                popover.delegate = self
                
                popover.mediaListGroupSort = mediaListGroupSort
                
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
                presentHTMLModal(viewController: self, medaiItem: nil, style: .overFullScreen, title: "Lexicon Index For: \(self.searchText!)", htmlString: data as? String)
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
        guard (searchText != nil) else {
            results = nil
            Thread.onMainThread() {
                self.updateActionMenu()
                self.tableView.reloadData()
                self.updateUI()
            }
            return
        }

        // Show the results directly rather than by executing a search
        results = MediaListGroupSort(mediaItems: self.lexicon?.words?[self.searchText!]?.map({ (mediaItemFrequency:(key:MediaItem,value:Int)) -> MediaItem in
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
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_WORD_LIST:
//                print("SHOW WORD LIST")
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
                        self.ptvc.section.strings = self.ptvc.sort.function?(self.ptvc.sort.method,self.ptvc.section.strings)
                        self.ptvc.tableView.reloadData()
                    }))
                    segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                        self.ptvc.sort.method = Constants.Sort.Frequency
                        self.ptvc.section.showIndex = false
                        self.ptvc.section.strings = self.ptvc.sort.function?(self.ptvc.sort.method,self.ptvc.section.strings)
                        self.ptvc.tableView.reloadData()
                    }))
                    
                    ptvc.segmentActions = segmentActions.count > 0 ? segmentActions : nil
                    
                    ptvc.delegate = self
                    ptvc.purpose = .selectingLexicon
                    
                    ptvc.search = true
                    ptvc.segments = true
                    
                    ptvc.mediaListGroupSort = mediaListGroupSort
                    
                    ptvc.section.showIndex = true
//                    destination.section.showHeaders = true
                }
                break
                
            case Constants.SEGUE.SHOW_INDEX_MEDIAITEM:
                if let myCell = sender as? MediaTableViewCell {
                    if (selectedMediaItem != myCell.mediaItem) || (globals.history == nil) {
                        globals.addToHistory(myCell.mediaItem)
                    }
                    selectedMediaItem = myCell.mediaItem //globals.media.activeMediaItems![index]
                    
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
//        guard Thread.isMainThread else {
//            return
//        }
        
        if (self.searchText != nil) {
            Thread.onMainThread() {
                self.locateButton.isHidden = false
                self.locateButton.isEnabled = true
            }
        } else {
            Thread.onMainThread() {
                self.locateButton.isHidden = true
                self.locateButton.isEnabled = false
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedWord.text = searchText

        updateLocateButton()

        globals.queue.async(execute: { () -> Void in
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
        })
        
        navigationItem.hidesBackButton = false
        
        navigationController?.setToolbarHidden(false, animated: true)
        
        if  let count = lexicon?.entries?.count,
            let total = lexicon?.eligible?.count {
            self.navigationItem.title = "Lexicon Index \(count) of \(total)"
        }
        
        updateSearchResults()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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

        ptvc.selectString(searchText,scroll: true,select: true)
    }
    
    func setupMediaItemsHTMLLexicon(includeURLs:Bool,includeColumns:Bool) -> String?
    {
        guard (results?.mediaItems != nil) else {
            return nil
        }
        
        var bodyString:String?
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        if searchText != nil {
            bodyString = bodyString! + "Lexicon Index For \(searchText!):"
            
            var appearances = 0

            if let mediaItems = results!.mediaItems {
                for mediaItem in mediaItems {
                    if let count = mediaItem.notesTokens?[searchText!] {
                        appearances += count
                    }
                }
                
                bodyString = bodyString! + " \(appearances) Occurrences in \(mediaItems.count) Documents<br/><br/>"
            }
        }
        
        bodyString = bodyString! + "The following media "
        
        if results?.list?.count > 1 {
            bodyString = bodyString! + "are"
        } else {
            bodyString = bodyString! + "is"
        }
        
        if includeURLs {
            bodyString = bodyString! + " from <a id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString = bodyString! + " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = globals.mediaCategory.selected {
            bodyString = bodyString! + "Category: \(category)<br/>"
        }
        
        if globals.media.tags.showing == Constants.TAGGED, let tag = globals.media.tags.selected {
            bodyString = bodyString! + "Collection: \(tag)<br/>"
        }
        
        if globals.search.valid, let searchText = globals.search.text {
            bodyString = bodyString! + "Search: \(searchText)<br/>"
        }
        
        bodyString = bodyString! + "Grouped: By \(translate(globals.grouping)!)<br/>"
        bodyString = bodyString! + "Sorted: \(translate(globals.sorting)!)<br/>"
        
        if let keys = results?.section?.indexStrings {
            bodyString = bodyString! + "<br/>"
            
            if includeURLs, (keys.count > 1) {
                bodyString = bodyString! + "<a href=\"#index\">Index</a><br/><br/>"
            }
            
            if includeColumns {
                bodyString = bodyString! + "<table>"
            }
            
            for key in keys {
                if  let name = results?.groupNames?[globals.grouping!]?[key],
                    let mediaItems = results?.groupSort?[globals.grouping!]?[key]?[globals.sorting!] {
                    var speakerCounts = [String:Int]()
                    
                    for mediaItem in mediaItems {
                        if mediaItem.speaker != nil {
                            if speakerCounts[mediaItem.speaker!] == nil {
                                speakerCounts[mediaItem.speaker!] = 1
                            } else {
                                speakerCounts[mediaItem.speaker!]! += 1
                            }
                        }
                    }
                    
                    let speakerCount = speakerCounts.keys.count
                    
                    if includeColumns {
                        bodyString = bodyString! + "<tr>"
                        bodyString = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                    }
                    
                    if includeURLs, (keys.count > 1) {
                        let tag = key.replacingOccurrences(of: " ", with: "")
                        bodyString = bodyString! + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\(tag)\">" + name + " (\(mediaItems.count))" + "</a>"
                    } else {
                        bodyString = bodyString! + name + " (\(mediaItems.count))"
                    }
                    
                    if speakerCount == 1 {
                        if let speaker = mediaItems[0].speaker, name != speaker {
                            bodyString = bodyString! + " by " + speaker
                        }
                    }
                    
                    if includeColumns {
                        bodyString = bodyString! + "</td>"
                        bodyString = bodyString! + "</tr>"
                    } else {
                        bodyString = bodyString! + "<br/>"
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
                            bodyString = bodyString! + string
                        }
                        
                        if !includeColumns {
                            bodyString = bodyString! + "<br/>"
                        }
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString! + "<tr>"
                    bodyString = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
                }
                
                bodyString = bodyString! + "<br/>"
                
                if includeColumns {
                    bodyString = bodyString! + "</td>"
                    bodyString = bodyString! + "</tr>"
                }
            }
            
            if includeColumns {
                bodyString = bodyString! + "</table>"
            }
            
            bodyString = bodyString! + "<br/>"
            
            if includeURLs, keys.count > 1 {
                bodyString = bodyString! + "<div><a id=\"index\" name=\"index\" href=\"#top\">Index</a><br/><br/>"
                
                switch globals.grouping! {
                case GROUPING.CLASS:
                    fallthrough
                case GROUPING.SPEAKER:
                    fallthrough
                case GROUPING.TITLE:
                    let a = "A"
                    
                    if let indexTitles = results?.section?.indexStrings {
                        let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                            if string.endIndex >= a.endIndex {
                                return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
                            } else {
                                return string
                            }
                        }))).sorted() { $0 < $1 }
                        
                        var stringIndex = [String:[String]]()
                        
                        for indexString in results!.section!.indexStrings! {
                            let key = indexString.substring(to: a.endIndex).uppercased()
                            
                            if stringIndex[key] == nil {
                                stringIndex[key] = [String]()
                            }
                            //                print(testString,string)
                            stringIndex[key]?.append(indexString)
                        }
                        
                        //                    print(stringIndex)
                        
                        var index:String?
                        
                        for title in titles {
                            let link = "<a href=\"#\(title)\">\(title)</a>"
                            index = (index != nil) ? index! + " " + link : link
                        }
                        
                        bodyString = bodyString! + "<div><a id=\"sections\" name=\"sections\">Sections</a> "
                        
                        if index != nil {
                            bodyString = bodyString! + index! + "<br/><br/>"
                        }
                        
                        for title in titles {
                            bodyString = bodyString! + "<a id=\"\(title)\" name=\"\(title)\" href=\"#index\">\(title)</a><br/>"
                            
                            if let keys = stringIndex[title] {
                                for key in keys {
                                    if let title = results?.groupNames?[globals.grouping!]?[key],
                                        let count = results?.groupSort?[globals.grouping!]?[key]?[globals.sorting!]?.count {
                                        let tag = key.replacingOccurrences(of: " ", with: "")
                                        bodyString = bodyString! + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                                    }
                                }
                                bodyString = bodyString! + "<br/>"
                            }
                        }
                        
                        bodyString = bodyString! + "</div>"
                    }
                    break
                    
                default:
                    for key in keys {
                        if let title = results?.groupNames?[globals.grouping!]?[key],
                            let count = results?.groupSort?[globals.grouping!]?[key]?[globals.sorting!]?.count {
                            let tag = key.replacingOccurrences(of: " ", with: "")
                            bodyString = bodyString! + "<a id=\"index\(tag)\" name=\"index\(tag)\" href=\"#\(tag)\">\(title) (\(count))</a><br/>"
                        }
                    }
                    break
                }
                
                bodyString = bodyString! + "</div>"
            }
        }
        
        bodyString = bodyString! + "</body></html>"
        
        return insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()

//        actionMenu.append("Sorting")
        actionMenu.append(Constants.Strings.Word_Picker)

        if results?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        guard Thread.isMainThread else {
            return
        }
        
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

//            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                let hClass = traitCollection.horizontalSizeClass
//                
//                if hClass == .compact {
//                    navigationController.modalPresentationStyle = .overCurrentContext
//                } else {
//                    // I don't think this ever happens: collapsed and regular
//                    navigationController.modalPresentationStyle = .popover
//                }
//            } else {
//                navigationController.modalPresentationStyle = .popover
//            }
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationItem.title = "Select"
            
//            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenuItems()
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
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
//        print(lexicon?.tokens)
//        print(lexicon?.gcw)
//        print(lexicon?.gcr)

        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
    }
    
    func completed()
    {
//        print(lexicon?.tokens)
//        print(lexicon?.gcw)
//        print(lexicon?.gcr)

        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
    }
    
    func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection
            
            popover.section.strings = results?.section?.headerStrings
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
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
        
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        
        selectedWord.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(LexiconIndexViewController.actions))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)

        navigationItem.setRightBarButton(actionButton, animated: true) //
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
        
        navigationController?.setToolbarHidden(false, animated: true)

        toolbarItems?[1].isEnabled = results?.mediaItems?.count > 0
        
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
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

extension LexiconIndexViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //        print("didSelectRowAtIndexPath")
        
        var mediaItem:MediaItem?
        
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            mediaItem = cell.mediaItem // mediaItems?[indexPath.row]

            globals.addToHistory(mediaItem)

            if (splitViewController?.viewControllers.count > 1) {
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
                    let viewController = navigationController.viewControllers[0] as? MediaViewController {
                    viewController.selectedMediaItem = mediaItem
                    splitViewController?.viewControllers[1] = navigationController
                }
            } else {
                if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM) as? MediaViewController {
                    viewController.selectedMediaItem = mediaItem
                    
                    self.navigationController?.navigationItem.hidesBackButton = false
                    
                    self.navigationController?.setToolbarHidden(true, animated: true)
                    
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        }
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
        return editActionsForIndexPath(tableView,indexPath: indexPath) != nil
    }
    
    func editActionsForIndexPath(_ tableView:UITableView,indexPath:IndexPath) -> [UITableViewRowAction]?
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        
        guard let mediaItem = cell.mediaItem else {
            return nil
        }
        
        guard let searchText = cell.searchText else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        var transcript:UITableViewRowAction!
        var scripture:UITableViewRowAction!
        
        transcript = UITableViewRowAction(style: .normal, title: Constants.FA.TRANSCRIPT) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: transcript)!]
            
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
                    
                    //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                })
            }
        }
        transcript.backgroundColor = UIColor.purple
        
        scripture = UITableViewRowAction(style: .normal, title: Constants.FA.SCRIPTURE) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: scripture)!]
            
            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    guard globals.reachability.currentReachabilityStatus != .notReachable else {
                        networkUnavailable(self,"Scripture text unavailable.")
                        return
                    }
                    
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load() // reference
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable(self,"Scripture text unavailable.")
                        }
                        //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                    })
                }
            }
        }
        scripture.backgroundColor = UIColor.orange
        
        if mediaItem.books != nil {
            actions.append(scripture)
        }
        
        if mediaItem.hasNotesHTML {
            actions.append(transcript)
        }
        
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return editActionsForIndexPath(tableView, indexPath: indexPath)
    }
}

extension LexiconIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if results?.section?.headerStrings != nil {
            if (section >= 0) && (section < results?.section?.headerStrings?.count) {
                return results?.section?.headerStrings?[section]
            } else {
                return nil
            }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell

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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let view = UIView()
        
        view.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        
        if section >= 0, section < results?.section?.headerStrings?.count, let title = results?.section?.headerStrings?[section] {
            let label = UILabel()
            
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            label.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold)
            
            label.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(label)

            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":label]))
        }
        
        view.alpha = 0.85
        
        return view
    }
}
