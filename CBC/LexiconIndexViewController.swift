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
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:stringPicked")
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

    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:rowClickedAtIndex")
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingLexicon:
            if index < strings.count {
                let string = strings[index]
                
                if let range = string.range(of: " (") {
                    searchText = string.substring(to: range.lowerBound).uppercased()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.setEditing(false, animated: true)
                    })
                    
                    updateSearchResults()
                }
            }
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)
            
            switch strings[index] {
            case Constants.Word_Picker:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                    navigationController.modalPresentationStyle = .popover
                    
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    
                    navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                    
                    popover.navigationItem.title = Constants.Word_Picker
                    
                    popover.delegate = self
                    
                    popover.mediaListGroupSort = mediaListGroupSort
                    
                    present(navigationController, animated: true, completion: nil)
                }
                break
                
            case Constants.View_List:
                process(viewController: self, work: { () -> (Any?) in
                    if self.results?.html?.string == nil {
                        self.results?.html?.string = self.setupMediaItemsHTMLLexicon(includeURLs: true, includeColumns: true)
                    }
                    
                    return self.results?.html?.string
                }, completion: { (data:Any?) in
                    presentHTMLModal(viewController: self, medaiItem: nil, title: "Lexicon Index For: \(self.searchText!)", htmlString: data as? String)
                })
                break
                
            default:
                break
            }
            break
            
        case .selectingCellAction:
            dismiss(animated: true, completion: nil)
            
            switch strings[index] {
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            case Constants.Download_Audio:
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

extension LexiconIndexViewController: MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

class LexiconIndexViewController: UIViewController, UIPopoverPresentationControllerDelegate
{
    var mediaListGroupSort:MediaListGroupSort?
    
    var root:StringNode?
    
//    var format:Format = .list
    
    var lexicon:Lexicon?
    {
        get {
            return mediaListGroupSort?.lexicon
        }
    }
    
    var searchText:String? {
        didSet {
            ptvc.selectedText = searchText
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectedWord.text = self.searchText

                self.updateLocateButton()
            })
            
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
    
//    @IBOutlet weak var wordPicker: UIPickerView!
    
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
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateActionMenu()
                self.tableView.reloadData()
            })
            return
        }

        // Show the results directly rather than by executing a search
        results = MediaListGroupSort(mediaItems: self.lexicon?.words?[self.searchText!]?.map({ (tuple:(MediaItem, Int)) -> MediaItem in
            return tuple.0
        }))
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.updateActionMenu()
            
            if !self.tableView.isEditing {
                self.tableView.reloadData()
            } else {
                self.changesPending = true
            }
        })
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
                    
                    destination.delegate = self
                    destination.purpose = .selectingLexicon
                    
                    destination.search = true
                    
                    destination.mediaListGroupSort = mediaListGroupSort
                    
                    destination.section.showIndex = true
                    destination.section.showHeaders = true
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
        
        if (self.searchText != nil) { //  && wordPicker.isHidden
//            if let visibleCells = ptvc?.tableView.visibleCells as? [PopoverTableViewCell] {
//                for cell in visibleCells {
//                    if let text = cell.title.text {
//                        if text.substring(to: text.range(of: " (")!.lowerBound).uppercased() == searchText {
//                            DispatchQueue.main.async(execute: { () -> Void in
//                                self.locateButton.isHidden = true
//                                self.locateButton.isEnabled = false
//                            })
//                            return
//                        }
//                    }
//                }
//            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.locateButton.isHidden = false
                self.locateButton.isEnabled = true
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.locateButton.isHidden = true
                self.locateButton.isEnabled = false
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        disableBarButtons()
        
        updateLocateButton()

        DispatchQueue(label: "CBC").async(execute: { () -> Void in
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.lexicon)
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.lexicon)
            NotificationCenter.default.addObserver(self, selector: #selector(LexiconIndexViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.lexicon)
        })
        
        navigationItem.hidesBackButton = false
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        if  let count = lexicon?.entries?.count,
            let total = lexicon?.eligible?.count {
            self.navigationItem.title = "Lexicon Index \(count) of \(total)"
        }
        
        updateActionMenu()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        
        //        navigationController?.navigationBar.backItem?.title = Constants.Back
        //        navigationItem.hidesBackButton = false
    }
    
    func setupMediaItemsHTMLLexicon(includeURLs:Bool,includeColumns:Bool) -> String?
    {
        guard (results?.mediaItems != nil) else {
            return nil
        }
        
        var bodyString:String?
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        if searchText != nil {
            bodyString = bodyString! + "Lexicon Index For: \(searchText!)<br/><br/>"
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
        
        if let keys = results?.section?.indexTitles {
            var count = 0
            for key in keys {
                if let mediaItems = results?.groupSort?[globals.grouping!]?[key]?[globals.sorting!] {
                    count += mediaItems.count
                }
            }
            
            bodyString = bodyString! + "Total: \(count)<br/>"
            
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
                        bodyString = bodyString! + "<td valign=\"top\" colspan=\"6\">"
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
                        var order = ["date","title","scripture"]
                        
                        if speakerCount > 1 {
                            order.append("speaker")
                        }
                        
                        if globals.grouping != Grouping.CLASS {
                            if let className = mediaItem.className, !className.isEmpty {
                                order.append("class")
                            }
                        }
                        
                        if let string = mediaItem.bodyHTML(order: order, includeURLs: includeURLs, includeColumns: includeColumns) {
                            bodyString = bodyString! + string
                        }
                        
                        if !includeColumns {
                            bodyString = bodyString! + "<br/>"
                        }
                    }
                }
                
                if includeColumns {
                    bodyString = bodyString! + "<tr>"
                    bodyString = bodyString! + "<td valign=\"top\" colspan=\"6\">"
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
                case Grouping.CLASS:
                    fallthrough
                case Grouping.SPEAKER:
                    fallthrough
                case Grouping.TITLE:
                    let a = "A"
                    
                    if let indexTitles = results?.section?.indexTitles {
                        let titles = Array(Set(indexTitles.map({ (string:String) -> String in
                            if string.endIndex >= a.endIndex {
                                return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
                            } else {
                                return string
                            }
                        }))).sorted() { $0 < $1 }
                        
                        var stringIndex = [String:[String]]()
                        
                        for indexString in results!.section!.indexTitles! {
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

        actionMenu.append(Constants.Word_Picker)

        if results?.list?.count > 0 {
            actionMenu.append(Constants.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            //                popover.navigationItem.title = Constants.Actions
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.section.strings = actionMenuItems()
            
            popover.section.showIndex = false //(globals.grouping == .series)
            popover.section.showHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func started()
    {
        
    }
    
    func updateTitle()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            if  let count = self.lexicon?.entries?.count,
                let total = self.lexicon?.eligible?.count {
                self.navigationItem.title = "Lexicon Index \(count) of \(total)"
            }
        })
    }
    
//    func updatePickerSelections()
//    {
//        guard root?.stringNodes != nil else {
//            return
//        }
//        
//        var stringNode = root
//        
//        var i = 0
//        
//        while stringNode != nil {
//            if stringNode?.stringNodes == nil {
//                pickerSelections[i] = nil
//                stringNode = nil
//            } else
//                
//            if pickerSelections[i] >= stringNode!.stringNodes!.count {
//                pickerSelections[i] = 0
//                stringNode = stringNode?.stringNodes?[0]
//            } else {
//                if let index = pickerSelections[i] {
//                    stringNode = stringNode?.stringNodes?[index]
//                } else {
//                    stringNode = nil
//                }
//            }
//            
//            i += 1
//        }
//        
////        print(wordPicker.numberOfComponents)
//
//        var index = i
//        while index < wordPicker.numberOfComponents {
//            pickerSelections[index] = nil
//            index += 1
//        }
////        if i < wordPicker.numberOfComponents {
////            for index in i..<wordPicker.numberOfComponents {
////                pickerSelections[index] = nil
////            }
////        }
//        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.wordPicker.setNeedsLayout()
//        })
//    }
    
//    func stringTreeUpdated()
//    {
//        if !wordPicker.isHidden {
//            root = lexicon?.root
//            
//            DispatchQueue.main.async(execute: { () -> Void in
//                self.spinner.stopAnimating()
//                self.spinner.isHidden = true
//            })
//
//            updatePickerSelections()
//            updatePicker()
//            
//            updateTitle()
//            
//            updateLocateButton()
//            
//            updateSearchResults()
//        }
//    }
    
    func updated()
    {
        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
        
//        if !wordPicker.isHidden {
//            lexicon?.buildStringTree()
//        }
    }
    
    func completed()
    {
        updateTitle()
        
        updateLocateButton()
        
        updateSearchResults()
        
//        if !wordPicker.isHidden {
//            lexicon?.buildStringTree()
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationController?.toolbar.isTranslucent = false
        
        //        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        selectedWord.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(LexiconIndexViewController.actions)), animated: true) //
    }
    
    func updateText()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:updateText")
            return
        }
     
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenUI")
            return
        }
        
        directionLabel.isHidden = state
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
//        wordPicker.isHidden = state
        
        isHiddenNumberAndTableUI(state)
    }
    
    func isHiddenNumberAndTableUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:isHiddenNumberAndTableUI")
            return
        }
        
        selectedLabel.isHidden = state
        selectedWord.isHidden = state
        
        tableView.isHidden = state
    }
    
//    func updatePicker()
//    {
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.wordPicker.reloadAllComponents()
//            
//            var i = 0
//            
//            while i < self.wordPicker.numberOfComponents, i < self.pickerSelections.count, self.pickerSelections[i] != nil {
//                self.wordPicker.selectRow(self.pickerSelections[i]!,inComponent: i, animated: true)
//                i += 1
//            }
//            
//            self.searchText = self.wordFromPicker()
//        })
//    }
    
    func updateActionMenu()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:updateActionMenu")
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateUI()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "LexiconIndexViewController:updateUI")
            return
        }
        
//        navigationController?.toolbar.items?[1].isEnabled = results?.list?.count > 0
        
        navigationController?.setToolbarHidden(true, animated: true)
        
        //        navigationController?.isToolbarHidden =
        
        spinner.isHidden = true
        spinner.stopAnimating()
        
        logo.isHidden = searchText != nil
        
        updateActionMenu()
        
        isHiddenUI(false)
        
//        if !wordPicker.isHidden {
//            updatePickerSelections()
//            updatePicker()
//        }
        
        updateDirectionLabel()
        
        updateText()
        
        tableView.reloadData()
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
            
            if (splitViewController != nil) && (splitViewController!.viewControllers.count > 1) {
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
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        }
        
        changesPending = false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
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
                
                htmlString = mediaItem.markedFullNotesHTML(searchText:searchText,index: true)
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    if globals.search.valid && globals.search.transcripts { // ( || globals.search.lexicon)
                        return mediaItem.markedFullNotesHTML(searchText:searchText,index: true)
                    } else {
                        return mediaItem.fullNotesHTML
                    }
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable("HTML transcript unavailable.")
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
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load(reference)
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable("Scripture text unavailable.")
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
        
        return actions
    }
}

extension LexiconIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return Constants.HEADER_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if results?.section?.titles != nil {
            if section < results?.section?.titles?.count {
                return results?.section?.titles?[section]
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

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return false
        }
        
        guard let mediaItem = cell.mediaItem else {
            return false
        }
        
        return mediaItem.hasNotesHTML || (mediaItem.scriptureReference != Constants.Selected_Scriptures)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        cell.vc = self
        
        cell.searchText = searchText
        
        if indexPath.section < results?.section?.indexes?.count {
            if let section = results?.section?.indexes?[indexPath.section] {
                if section + indexPath.row < results?.mediaItems?.count {
                    cell.mediaItem = results?.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }
        
        return cell
    }
}
