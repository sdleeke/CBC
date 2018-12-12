//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

class ScriptureIndexViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

extension ScriptureIndexViewController : UIAdaptivePresentationControllerDelegate
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

extension ScriptureIndexViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:rowClickedAtIndex",completion:nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        let string = strings[index]
        
        tableView.setEditing(false, animated: true)
        
        switch purpose {
        case .selectingSection:
            dismiss(animated: true, completion: nil)
            
            let indexPath = IndexPath(row: 0, section: index)
            
            if !(indexPath.section < tableView.numberOfSections) {
                NSLog("indexPath section ERROR in ScriptureIndex .selectingSection")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                break
            }
            
            if !(indexPath.row < tableView.numberOfRows(inSection: indexPath.section)) {
                NSLog("indexPath row ERROR in ScriptureIndex .selectingSection")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                NSLog("Row: \(indexPath.row)")
                NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                break
            }
            
            //Can't use this reliably w/ variable row heights.
            tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)
            
            switch strings[index] {
            case Constants.Strings.View_List:
                process(viewController: self, work: { [weak self] () -> (Any?) in
                    if self?.scriptureIndex?.html?.string == nil {
                        self?.scriptureIndex?.html?.string = self?.setupMediaItemsHTMLScripture(self?.mediaItems, includeURLs:true, includeColumns:true)
                    }
                    
                    return self?.scriptureIndex?.html?.string
                }, completion: { [weak self] (data:Any?) in
                    if let vc = self {
                        presentHTMLModal(viewController: vc, mediaItem: nil, style: .overFullScreen, title: Globals.shared.contextTitle, htmlString: data as? String)
                    }
                })
                break
                
            case Constants.Strings.View_Scripture:
                if let reference = scripture?.selected.reference {
                    scripture?.reference = reference
                    if scripture?.html?[reference] != nil {
                        popoverHTML(self,title:reference,barButtonItem:self.navigationItem.rightBarButtonItem,htmlString:scripture?.html?[reference], search:false)
                    } else {
                        process(viewController: self, work: { [weak self] () -> (Any?) in
                            self?.scripture?.load() // reference
                            return self?.scripture?.html?[reference]
                        }, completion: { [weak self] (data:Any?) in
                            if let htmlString = data as? String {
                                if let vc = self {
                                    popoverHTML(vc,title:reference,barButtonItem:self?.navigationItem.rightBarButtonItem,htmlString:htmlString, search:false)
                                }
                            } else {
                                if let vc = self {
                                    networkUnavailable(vc,"Scripture text unavailable.")
                                }
                            }
                        })
                    }
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingCellAction:
            dismiss(animated: true, completion: nil)
            
            switch strings[index] {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Strings.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete(block:true)
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            default:
                break
            }
            break
            
        case .selectingTimingIndexWord:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.navigationItem.title = string
                
                popover.selectedMediaItem = self.popover?.selectedMediaItem
                popover.transcript = self.popover?.transcript
                
                popover.delegate = self
                popover.purpose = .selectingTime
                
                popover.parser = { (string:String) -> [String] in
                    var strings = string.components(separatedBy: "\n")
                    while strings.count > 2 {
                        strings.removeLast()
                    }
                    return strings
                }
                
                popover.search = true
                popover.searchInteractive = false
                popover.searchActive = true
                popover.searchText = string
                popover.wholeWordsOnly = true
                
                popover.section.showIndex = true
                popover.section.indexStringsTransform = century
                popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                    return string
                }
                
                // using stringsFunction w/ .selectingTime ensures that follow() will be called after the strings are rendered.
                // In this case because searchActive is true, however, follow() aborts in a guard stmt at the beginning.
                popover.stringsFunction = {
                    guard let times = popover.transcript?.transcriptSegmentTokenTimes(token: string), let transcriptSegmentComponents = popover.transcript?.transcriptSegmentComponents else {
                        return nil
                    }
                    
                    var strings = [String]()
                    
                    for time in times {
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            if transcriptSegmentComponent.contains(time+" --> ") { //
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
                                        
                                        strings.append(string)
                                    }
                                }
                                break
                            }
                        }
                    }
                    
                    return strings
                }
                
                popover.editActionsAtIndexPath = popover.transcript?.rowActions
                
                self.popover?.navigationController?.pushViewController(popover, animated: true)
            }
            break
            
        case .selectingTime:
            guard Globals.shared.mediaPlayer.currentTime != nil else {
                break
            }
            
            if let time = string.components(separatedBy: "\n")[1].components(separatedBy: " to ").first, let seconds = time.hmsToSeconds {
                Globals.shared.mediaPlayer.seek(to: seconds)
            }
            break
            
        default:
            break
        }
    }
}

extension ScriptureIndexViewController : UIPickerViewDelegate
{
    // MARK: UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 50
            
        case 1:
            return 175
            
        case 2:
            return 35
            
        case 3:
            return 35
            
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        scripturePicker.isUserInteractionEnabled = false
        
        switch component {
        case 0: // Testament
            switch row {
            case 0:
                if (scriptureIndex?.byTestament[Constants.Old_Testament] == nil) {
                    scriptureIndex?.selectedTestament = Constants.NT
                    break
                }
                
                if (scriptureIndex?.byTestament[Constants.New_Testament] == nil) {
                    scriptureIndex?.selectedTestament = Constants.OT
                    break
                }
                
                scriptureIndex?.selectedTestament = Constants.OT
                break
                
            case 1:
                scriptureIndex?.selectedTestament = Constants.NT
                break
                
            default:
                break
            }

            if let selectedTestament = scriptureIndex?.selectedTestament, bookSwitch.isOn {
                scripture?.picker.books = scriptureIndex?.byBook[translateTestament(selectedTestament)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = scripture?.picker.books?[0]
            } else {
                scriptureIndex?.selectedBook = nil
            }
            
            updateSwitches()
            
            if let selectedTestament = scriptureIndex?.selectedTestament, chapterSwitch.isOn, let selectedBook = scriptureIndex?.selectedBook {
                scripture?.picker.chapters = scriptureIndex?.byChapter[translateTestament(selectedTestament)]?[selectedBook]?.keys.sorted()
                
                if let chapter = scripture?.picker.chapters?[0] {
                    scriptureIndex?.selectedChapter = chapter
                }
            } else {
                scriptureIndex?.selectedChapter = 0
            }
            
            scriptureIndex?.selectedVerse = 0
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            updateSearchResults()
            break
            
        case 1: // Book
            if let selectedTestament = scriptureIndex?.selectedTestament, bookSwitch.isOn {
                scripture?.picker.books = scriptureIndex?.byBook[translateTestament(selectedTestament)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = scripture?.picker.books?[row]
                
                updateSwitches()
                
                if chapterSwitch.isOn, let selectedBook = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[translateTestament(selectedTestament)]?[selectedBook]?.keys.sorted()

                    if let chapter = scripture?.picker.chapters?[0] {
                        scriptureIndex?.selectedChapter = chapter
                    }
                } else {
                    scriptureIndex?.selectedChapter = 0
                }
                
                scriptureIndex?.selectedVerse = 0
                
                pickerView.reloadAllComponents()
                
                pickerView.selectRow(0, inComponent: 2, animated: true)

                updateSearchResults()
            }
            break
            
        case 2: // Chapter
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                if let chapter = scripture?.picker.chapters?[row] {
                    scriptureIndex?.selectedChapter = chapter
                }
                
                scriptureIndex?.selectedVerse = 0
                
                pickerView.reloadAllComponents()
                
                updateSearchResults()
            }
            break
            
        case 3: // Verse
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && (scriptureIndex?.selectedChapter > 0) && bookSwitch.isOn && chapterSwitch.isOn {
                scriptureIndex?.selectedVerse = row + 1
                
                pickerView.reloadAllComponents()
                
                updateSearchResults()
            }
            break
            
        default:
            break
        }
    }
}

extension ScriptureIndexViewController : UIPickerViewDataSource
{
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var numberOfRows = 0
        
        switch component {
        case 0:
            if (scriptureIndex?.byTestament[Constants.Old_Testament] != nil) {
                numberOfRows += 1
            }
            
            if (scriptureIndex?.byTestament[Constants.New_Testament] != nil) {
                numberOfRows += 1
            }
            break
            
        case 1:
            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                if let count = scripture?.picker.books?.count {
                    numberOfRows = count
                }
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                if let count = scripture?.picker.chapters?.count {
                    numberOfRows = count
                }
            } else {
                numberOfRows = 0 // number of chapters in book
            }
            break
            
        case 3:
            if scriptureIndex?.selectedChapter > 0 {
                numberOfRows = 1 // number of verses in chapter
            } else {
                numberOfRows = 0 // number of verses in chapter
            }
            break
            
        default:
            break
        }
        
        return numberOfRows
    }
    
    func title(forRow row:Int, forComponent component:Int) -> String?
    {
        switch component {
        case 0:
            if (scriptureIndex?.byTestament[Constants.Old_Testament] == nil) {
                if row == 0 {
                    return Constants.NT
                }
            }
            
            if (scriptureIndex?.byTestament[Constants.New_Testament] == nil) {
                if row == 0 {
                    return Constants.OT
                }
            }
            
            switch row {
            case 0:
                return Constants.OT
                
            case 1:
                return Constants.NT
                
            default:
                break
            }
            break
            
        case 1:
            if (scriptureIndex?.selectedTestament != nil) {
                if let book = scripture?.picker.books?[row] {
                    return book
                }
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) {
                if let num = scripture?.picker.chapters?[row] {
                    return num.description
                }
            }
            break
            
        case 3:
            if scriptureIndex?.selectedChapter > 0 {
                return "1"
            }
            break
            
        default:
            break
        }
        
        return Constants.EMPTY_STRING
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label = (view as? UILabel) ?? UILabel()
        
        if let title = title(forRow: row, forComponent: component) {
            label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.normal)
        }
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return title(forRow: row,forComponent: component)
    }
}

extension ScriptureIndexViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate Method
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ScriptureIndexViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class ScriptureIndexViewController : UIViewController
{
    var popover : PopoverTableViewController?

    var finished:Float = 0.0
    var progress:Float = 0.0 {
        willSet {
            
        }
        didSet {
            Thread.onMainThread {
                if self.finished > 0 {
                    self.progressIndicator.progress = self.progress / self.finished
                }
                if self.progressIndicator.progress == 1.0 {
                    self.progressIndicator.isHidden = true
                }
            }
        }
    }

    lazy var scripture:Scripture? = { [weak self] in
        return Scripture(reference: nil)
    }()
    
    var mediaListGroupSort:MediaListGroupSort?
    {
        willSet {
            
        }
        didSet {

        }
    }
    
    var scriptureIndex:ScriptureIndex?
    {
        get {
            return mediaListGroupSort?.scriptureIndex
        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var bookSwitch: UISwitch!

    @IBAction func bookSwitchAction(_ sender: UISwitch)
    {
        if let selectedTestament = scriptureIndex?.selectedTestament, bookSwitch.isOn {
            let testament = translateTestament(selectedTestament)
            
            if let book = scriptureIndex?.selectedBook {
                scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
            }

            scripture?.picker.books = scriptureIndex?.byBook[translateTestament(selectedTestament)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }

            scriptureIndex?.selectedBook = scripture?.picker.books?[0]
        } else {
            scriptureIndex?.selectedBook = nil
        }

        updateSwitches()

        updatePicker()
        
        updateDirectionLabel()
        
        updateSearchResults()
    }
    
    @IBOutlet weak var chapterLabel: UILabel!
    @IBOutlet weak var chapterSwitch: UISwitch!
    
    @IBAction func chapterSwitchAction(_ sender: UISwitch) {
        if chapterSwitch.isOn {
            if let selectedTestament = scriptureIndex?.selectedTestament {
                let testament = translateTestament(selectedTestament)
                if let book = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }

            if let num = scripture?.picker.chapters?[0] {
                scriptureIndex?.selectedChapter = num
            }
        } else {
            scriptureIndex?.selectedChapter = 0
        }
        
        updatePicker()
        
        updateDirectionLabel()
        
        updateSearchResults()
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(ScriptureIndexViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "ScriptureIndexViewController")
        }
    }

    var sections:[String:[MediaItem]]?
    {
        get {
            return scriptureIndex?.sections
        }
        set {
            scriptureIndex?.sections = newValue
        }
    }

    var sectionTitles:[String]?
    {
        get {
            return scriptureIndex?.sectionTitles // sections?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        }
    }
    
    var mediaItems:[MediaItem]?
    {
        willSet {
            
        }
        didSet {
            guard self.sections == nil else {
                return
            }
            
            var sections = [String:[MediaItem]]()
            
            if let mediaItems = mediaItems {
                for mediaItem in mediaItems {
                    if let books = mediaItem.books {
                        for book in books {
                            if let selectedTestament = scriptureIndex?.selectedTestament {
                                if translateTestament(selectedTestament) == testament(book) {
                                    if sections[book] == nil {
                                        sections[book] = [mediaItem]
                                    } else {
                                        sections[book]?.append(mediaItem)
                                    }
                                } else {
                                    // THIS SHOULD NEVER HAPPEN
                                }
                            }
                        }
                    }
                }
            }
            
            for book in sections.keys {
                sections[book] = sortMediaItems(sections[book],book:book)
            }
            
            self.sections = sections
        }
    }
    var selectedMediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {

        }
    }
    
    @IBOutlet weak var scripturePicker: UIPickerView!
    
    @IBOutlet weak var numberOfMediaItemsLabel: UILabel!
    @IBOutlet weak var numberOfMediaItems: UILabel!
    
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
        bookSwitch.isEnabled = false
        chapterSwitch.isEnabled = false
        
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
        updateSwitches()
        
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        enableToolBarButtons()
    }
    
    func setup()
    {
        guard let scriptureIndex = scriptureIndex else {
            return
        }
        
        scripture?.selected.testament   = scriptureIndex.selectedTestament
        scripture?.selected.book        = scriptureIndex.selectedBook
        
        scripture?.selected.chapter     = scriptureIndex.selectedChapter
        scripture?.selected.verse       = scriptureIndex.selectedVerse
        
        guard let selectedTestament = scriptureIndex.selectedTestament else {
            mediaItems = nil
            return
        }

        let testament = translateTestament(selectedTestament)

        guard let selectedBook = scriptureIndex.selectedBook else {
            mediaItems = scriptureIndex.byTestament[testament]
            return
        }
        
        guard scriptureIndex.selectedChapter > 0 else {
            mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
            return
        }
        
        guard scriptureIndex.selectedVerse > 0 else {
            self.mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.selectedChapter]
            return
        }
        
        mediaItems = nil
    }
    
    var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "SIVC:Operations"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func updateSearchResults()
    {
        guard let scriptureIndex = scriptureIndex else {
            return
        }
        
        scripture?.selected.testament   = scriptureIndex.selectedTestament
        scripture?.selected.book        = scriptureIndex.selectedBook
        
        scripture?.selected.chapter     = scriptureIndex.selectedChapter
        scripture?.selected.verse       = scriptureIndex.selectedVerse
        
        guard let selectedTestament = scriptureIndex.selectedTestament else {
            mediaItems = nil
            
            Thread.onMainThread {
                self.updateUI()
                self.tableView.reloadData()
                self.scripturePicker.isUserInteractionEnabled = true
            }
            return
        }

        let testament = translateTestament(selectedTestament)

        guard let selectedBook = scriptureIndex.selectedBook else {
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            operationQueue.cancelAllOperations()
            
            operationQueue.addOperation { [weak self] in
                Thread.onMainThread {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.sorted[testament] == nil {
                    let mediaItems = scriptureIndex.byTestament[testament]
                    scriptureIndex.byTestament[testament] = self?.sortMediaItems(mediaItems,book:nil)
                    scriptureIndex.sorted[testament] = true
                }
                
                self?.mediaItems = scriptureIndex.byTestament[testament]
                
                Thread.onMainThread {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byTestament[testament]?.count > 0 {
                        self?.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        guard scriptureIndex.selectedChapter > 0 else {
            let index = testament + selectedBook

            operationQueue.cancelAllOperations()
            
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            operationQueue.addOperation { [weak self] in
                Thread.onMainThread {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.sorted[index] == nil {
                    let mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
                    scriptureIndex.byBook[testament]?[selectedBook] = self?.sortMediaItems(mediaItems,book:selectedBook)
                    scriptureIndex.sorted[index] = true
                }
                
                self?.mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
                
                Thread.onMainThread {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byBook[testament]?[selectedBook]?.count > 0 {
                        self?.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        guard scriptureIndex.selectedVerse > 0 else {
            let index = testament + selectedBook + "\(scriptureIndex.selectedChapter)"

            operationQueue.cancelAllOperations()
            
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            operationQueue.addOperation { [weak self] in
                Thread.onMainThread {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.sorted[index] == nil {
                    let mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.selectedChapter]
                    scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.selectedChapter] = self?.sortMediaItems(mediaItems,book:selectedBook)
                    scriptureIndex.sorted[index] = true
                }
                
                self?.mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.selectedChapter]
                
                Thread.onMainThread {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.selectedChapter]?.count > 0 {
                        self?.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        let index = testament + selectedBook + "\(scriptureIndex.selectedChapter)" + "\(scriptureIndex.selectedVerse)"

        operationQueue.cancelAllOperations()
        
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        operationQueue.addOperation { [weak self] in
            Thread.onMainThread {
                self?.disableBarButtons()
                self?.spinner.isHidden = false
                self?.spinner.startAnimating()
                self?.isHiddenNumberAndTableUI(true)
            }
            
            if scriptureIndex.sorted[index] == nil {
                scriptureIndex.sorted[index] = true
            }
            
            self?.mediaItems = nil
            
            Thread.onMainThread {
                self?.enableBarButtons()
                self?.updateUI()
                self?.tableView.reloadData()
                if scriptureIndex.byVerse[testament]?[selectedBook]?[scriptureIndex.selectedChapter]?[scriptureIndex.selectedVerse]?.count > 0 {
                    self?.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                }
                self?.scripturePicker.isUserInteractionEnabled = true
            }
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
            case Constants.SEGUE.SHOW_INDEX_MEDIAITEM:
                if let myCell = sender as? MediaTableViewCell {
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
    
    func addNotifications()
    {
        Globals.shared.queue.async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(self.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_UPDATED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(self.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self.scriptureIndex)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addNotifications()
        
        navigationItem.hidesBackButton = false
        
        navigationController?.isToolbarHidden = true

        scripturePicker.isUserInteractionEnabled = false

        if let completed = scriptureIndex?.completed, completed {
            setup()
            updateUI()
            scripturePicker.isUserInteractionEnabled = true
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

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

    }
    
    func setupMediaItemsHTMLScripture(_ mediaItems:[MediaItem]?,includeURLs:Bool,includeColumns:Bool) -> String?
    {
        guard let mediaItems = mediaItems else {
            return nil
        }
        
        var bodyItems = [String:[MediaItem]]()
        
        for mediaItem in mediaItems {
            if let books = mediaItem.books {
                for book in books {
                    if let okay = sectionTitles?.contains(book) {
                        if okay {
                            if bodyItems[book] == nil {
                                bodyItems[book] = [mediaItem]
                            } else {
                                bodyItems[book]?.append(mediaItem)
                            }
                        }
                    }
                }
            }
        }
        
        var bodyString:String!
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString = bodyString + "<div>"

        bodyString = bodyString + "The following media "
        
        if mediaItems.count > 1 {
            bodyString = bodyString + "are"
        } else {
            bodyString = bodyString + "is"
        }
        
        if includeURLs {
            bodyString = bodyString + " from <a target=\"_blank\" id=\"top\" name=\"top\" href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        } else {
            bodyString = bodyString + " from " + Constants.CBC.LONG + "<br/><br/>"
        }
        
        if let category = Globals.shared.mediaCategory.selected {
            bodyString = bodyString + "Category: \(category)<br/><br/>"
        }
        
        if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.tags.selected {
            bodyString = bodyString + "Collection: \(tag)<br/><br/>"
        }
        
        if Globals.shared.search.valid, let text = Globals.shared.search.text {
            bodyString = bodyString + "Search: \(text)<br/><br/>"
        }
        
        bodyString = bodyString + "</div>"

        if let selectedTestament = self.scriptureIndex?.selectedTestament {
            var indexFor = translateTestament(selectedTestament)

            if let selectedBook = self.scriptureIndex?.selectedBook {
                indexFor = selectedBook
                
                if let chapter = self.scriptureIndex?.selectedChapter, chapter > 0 {
                    indexFor = indexFor + " \(chapter)"
                    
                    if let verse = self.scriptureIndex?.selectedVerse, verse > 0 {
                        indexFor = indexFor + ":\(verse)"
                    }
                }
            }
            
            bodyString = bodyString + "\(indexFor) Scripture Index<br/>"
        }
        
        bodyString = bodyString + "Items are grouped and sorted by Scripture reference.<br/>"

        bodyString = bodyString + "Total: \(mediaItems.count)<br/>"
        
        let books = bodyItems.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString + "<br/>"
            bodyString = bodyString + "<a href=\"#index\">Index</a><br/>"
        }
        
        if includeColumns {
            bodyString  = bodyString + "<table>"
        }
        
        for book in books {
            let tag = book.asTag

            if includeColumns {
                bodyString  = bodyString + "<tr><td><br/></td></tr>"
                bodyString  = bodyString + "<tr><td style=\"vertical-align:baseline;\" colspan=\"7\">" //  valign=\"baseline\"
            }
            
            if let mediaItems = bodyItems[book] {
                if includeURLs && (books.count > 1) {
                    bodyString = bodyString + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + book + " (\(mediaItems.count))" + "</a>"
                } else {
                    bodyString = bodyString + book
                }

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
                
                let speakers = Array(speakerCounts.keys)
                
                if speakerCount == 1{
                    bodyString = bodyString + " by \(speakers[0])"
                }
                
                if includeColumns {
                    bodyString  = bodyString + "</td>"
                    bodyString  = bodyString + "</tr>"
                } else {
                    bodyString = bodyString + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["scripture","title","date"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString + "<br/>"
                    }
                }
            }
        }
        
        if includeColumns {
            bodyString  = bodyString + "</table>"
        }
        
        bodyString = bodyString + "<br/>"
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString + "<div>Index (<a id=\"index\" name=\"index\" href=\"#top\">Return to Top</a>)<br/><br/>"

            for book in books {
                if let count = bodyItems[book]?.count {
                    bodyString = bodyString + "<a href=\"#\(book.asTag)\">\(book) (\(count))</a><br/>"
                }
            }
            
            bodyString = bodyString + "</div>"
        }
        
        bodyString = bodyString + "</body></html>"
        
        return insertHead(bodyString,fontSize:Constants.FONT_SIZE)
    }

    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()
        
        if mediaItems?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        if let scriptureReference = scripture?.selected.reference, scriptureReference != scriptureIndex?.selectedBook {
            actionMenu.append(Constants.Strings.View_Scripture)
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
    
    @objc func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:index",completion:nil)
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.shared.mediaItemSections
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

            popover.section.strings = sectionTitles
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:selectOrScrollToMediaItem",completion:nil)
            return
        }
        
        // isEditing must be on main thread.
        guard !tableView.isEditing else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        if let index = mediaItems?.index(of: mediaItem) {
            let indexPath = IndexPath(row: index, section: 0)
            
            if (select) {
                // So UI operates as desired.
                DispatchQueue.global(qos: .background).async { [weak self] in
                    Thread.onMainThread {
                        self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                }
            }
            
            if (scroll) {
                // Scrolling when the user isn't expecting it can be jarring.
                // So UI operates as desired.
                DispatchQueue.global(qos: .background).async { [weak self] in
                    Thread.onMainThread {
                        self?.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                    }
                }
            }
        }
    }
    
    
    @objc func started()
    {
        
    }
    
    @objc func updated()
    {
        
    }
    
    @objc func completed()
    {
        updateSearchResults()
        
        Thread.onMainThread {
            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: .top)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
        
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        setToolbarItems([spaceButton,indexButton], animated: false)

        navigationController?.toolbar.isTranslucent = false

        if let selectedTestament = scriptureIndex?.selectedTestament {
            let testament = translateTestament(selectedTestament)
            
            if scripture?.picker.books == nil {
                scripture?.picker.books = scriptureIndex?.byBook[testament]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            }
            
            if scripture?.picker.chapters == nil {
                if let book = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }
        }
        
        progressIndicator.isHidden = true
  
        numberOfMediaItems.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()

        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        navigationItem.setRightBarButton(actionButton, animated: true) //

        isHiddenUI(false)
        disableBarButtons()
        spinner.isHidden = false
        spinner.startAnimating()
        isHiddenNumberAndTableUI(true)
        
        scriptureIndex?.build()
    }
    
    func sortMediaItems(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
    {
        var list:[MediaItem]?
        
        list = mediaItems?.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBooksChaptersVerses   = first.booksAndChaptersAndVerses()?.bookChaptersVerses(book: book)
            let secondBooksChaptersVerses  = second.booksAndChaptersAndVerses()?.bookChaptersVerses(book: book)

            if firstBooksChaptersVerses == secondBooksChaptersVerses {
                if let firstDate = first.fullDate, let secondDate = second.fullDate {
                    if firstDate.isEqualTo(secondDate) {
                        if first.service == second.service {
                            return lastNameFromName(first.speaker) < lastNameFromName(second.speaker)
                        } else {
                            return first.service < second.service
                        }
                    } else {
                        return firstDate.isOlderThan(secondDate)
                    }
                } else {
                    return false
                }
            } else {
                return firstBooksChaptersVerses < secondBooksChaptersVerses
            }
        })

        return list
    }
    
    func updateText()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:updateText", completion: nil)
            return
        }
        
        guard let scriptureIndex = scriptureIndex else {
            return
        }
        
        guard let selectedTestament = scriptureIndex.selectedTestament else {
            return
        }
        
        let testament = translateTestament(selectedTestament)
        let book = scriptureIndex.selectedBook
        let chapter = scriptureIndex.selectedChapter
        let verse = scriptureIndex.selectedVerse
        
        if let book = book, let count = self.mediaItems?.count {
            if verse > 0 {
                numberOfMediaItems.text = "\(count) from verse \(verse) in chapter \(chapter) of \(book) in the \(testament)"
                return
            }
            
            if chapter > 0 {
                numberOfMediaItems.text = "\(count) from chapter \(chapter) of \(book) in the \(testament)"
                return
            }
            
            numberOfMediaItems.text = "\(count) from \(book) in the \(testament)"
            return
        }
        
        if let count = self.mediaItems?.count {
            numberOfMediaItems.text = "\(count) from the \(testament)"
        } else {
            numberOfMediaItems.text = "0 from the \(testament)"
        }
    }

    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:isHiddenUI", completion: nil)
            return
        }
        
        directionLabel.isHidden = state
        
        bookLabel.isHidden = state
        bookSwitch.isHidden = state
        
        chapterLabel.isHidden = state
        chapterSwitch.isHidden = state
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        scripturePicker.isHidden = state
        
        isHiddenNumberAndTableUI(state)
    }

    func isHiddenNumberAndTableUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:isHiddenNumberAndTableUI", completion: nil)
            return
        }
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        tableView.isHidden = state
    }
    
    func updatePicker()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:updatePicker", completion: nil)
            return
        }
        
        scripturePicker.reloadAllComponents()
        
        if let selectedTestament = scriptureIndex?.selectedTestament {
            if let index = Constants.TESTAMENTS.index(of: selectedTestament) {
                scripturePicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            if let selectedBook = scriptureIndex?.selectedBook, let index = scripture?.picker.books?.index(of: selectedBook) {
                scripturePicker.selectRow(index, inComponent: 1, animated: false)
            }
            
            if let selectedChapter = scriptureIndex?.selectedChapter, selectedChapter > 0, let index = scripture?.picker.chapters?.index(of: selectedChapter) {
                scripturePicker.selectRow(index, inComponent: 2, animated: false)
            }
            
            if let selectedVerse = scriptureIndex?.selectedVerse, selectedVerse > 0, let index = scripture?.picker.verses?.index(of: selectedVerse) {
                scripturePicker.selectRow(index, inComponent: 3, animated: false)
            }
        }
    }

    func updateSwitches()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:updateSwitches", completion: nil)
            return
        }
        
        bookSwitch.isOn = scriptureIndex?.selectedBook != nil
        
        if let selectedTestament = scriptureIndex?.selectedTestament {
            bookSwitch.isEnabled = (scriptureIndex?.byTestament[translateTestament(selectedTestament)] != nil)
        } else {
            bookSwitch.isEnabled = false
        }

        chapterSwitch.isOn = scriptureIndex?.selectedChapter > 0
        chapterSwitch.isEnabled = bookSwitch.isOn

        if let book = scriptureIndex?.selectedBook, Constants.NO_CHAPTER_BOOKS.contains(book) {
            chapterSwitch.isOn = false
            chapterSwitch.isEnabled = false
        }
    }
    
    func updateActionMenu()
    {
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateToolbar()
    {
        navigationController?.setToolbarHidden(scriptureIndex?.selectedBook != nil, animated: true)
        
        // Why are we doing both of the following?
        
        navigationController?.toolbar.items?[1].isEnabled = mediaItems?.count > 0
        
        toolbarItems?[1].isEnabled = mediaItems?.count > 0
    }

    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:updateUI", completion: nil)
            return
        }
    
        updateToolbar()
        
        spinner.isHidden = true
        spinner.stopAnimating()
        progressIndicator.isHidden = true

        updateSwitches()
 
        updateActionMenu()
        
        isHiddenUI(false)

        updatePicker()
        
        updateDirectionLabel()
        
        updateText()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
        // We should close.
        if navigationController?.visibleViewController == self {
            navigationController?.popToRootViewController(animated: true)
        }
        
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
}

extension ScriptureIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = scriptureIndex?.selectedBook {
            return 0
        } else {
            return Constants.HEADER_HEIGHT
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let sectionTitles = sectionTitles else {
            return nil
        }

        guard section >= 0, section < sectionTitles.count else {
            return nil
        }

        guard scriptureIndex?.selectedBook == nil else {
            return nil
        }

        return sectionTitles[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        
        if let _ = scriptureIndex?.selectedBook {
            return 1
        } else {
            return sectionTitles?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        if let _ = scriptureIndex?.selectedBook {
            return mediaItems?.count ?? 0
        } else {
            if let sectionTitle = sectionTitles?[section], let rows = sections?[sectionTitle] {
                return rows.count
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as? MediaTableViewCell) ?? MediaTableViewCell()
        
        cell.hideUI()
        
        cell.vc = self
        
        if let _ = scriptureIndex?.selectedBook {
            cell.mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                cell.mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        return cell
    }
}

extension ScriptureIndexViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        var mediaItem : MediaItem?
        
        if let _ = scriptureIndex?.selectedBook {
            mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        return mediaItem?.editActions(viewController: self) != nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text else {
            return nil
        }
        
        let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
            let alert = UIAlertController(  title: Constants.Strings.Actions,
                                            message: message,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            if let alertActions = cell.mediaItem?.editActions(viewController: self) {
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
            
            self.present(alert, animated: true, completion: nil)
        }
        action.backgroundColor = UIColor.controlBlue()
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let _ = scriptureIndex?.selectedBook {
            selectedMediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                selectedMediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
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
        var view : ScriptureIndexViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ScriptureIndexViewController") as? ScriptureIndexViewControllerHeaderView
        if view == nil {
            view = ScriptureIndexViewControllerHeaderView()
        }
        
        view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        view?.alpha = 0.85
        
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
        
        if let sectionTitles = sectionTitles, section >= 0, section < sectionTitles.count {
            view?.label?.attributedText = NSAttributedString(string: sectionTitles[section], attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR", attributes: Constants.Fonts.Attributes.bold)
        }

        return view
    }
}


