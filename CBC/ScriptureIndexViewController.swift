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
        
        dismiss(animated: true, completion: nil)
        
        guard let strings = strings else {
            return
        }
        
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
            switch strings[index] {
            case Constants.Strings.View_List:
                process(viewController: self, work: { () -> (Any?) in
                    if self.scriptureIndex?.html?.string == nil {
                        self.scriptureIndex?.html?.string = self.setupMediaItemsHTMLScripture(self.mediaItems, includeURLs: true, includeColumns: true)
                    }
                    
                    return self.scriptureIndex?.html?.string
                }, completion: { (data:Any?) in
                    presentHTMLModal(viewController: self, mediaItem: nil, style: .overFullScreen, title: globals.contextTitle, htmlString: data as? String)
                })
                break
                
            case Constants.Strings.View_Scripture:
                if let reference = scripture?.selected.reference {
                    scripture?.reference = reference
                    if scripture?.html?[reference] != nil {
                        popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:self.navigationItem.rightBarButtonItem,sourceView:nil,sourceRectView:nil,htmlString:scripture?.html?[reference])
                    } else {
                        process(viewController: self, work: { () -> (Any?) in
                            self.scripture?.load() // reference
                            return self.scripture?.html?[reference]
                        }, completion: { (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:self.navigationItem.rightBarButtonItem,sourceView:nil,sourceRectView:nil,htmlString:htmlString)
                            } else {
                                networkUnavailable(self,"Scripture text unavailable.")
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
            switch strings[index] {
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

            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                scripture?.picker.books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = scripture?.picker.books?[0]
            } else {
                scriptureIndex?.selectedBook = nil
            }
            
            updateSwitches()
            
            if chapterSwitch.isOn {
                scripture?.picker.chapters = scriptureIndex?.byChapter[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]?.keys.sorted()
                scriptureIndex?.selectedChapter = scripture!.picker.chapters![0]
            } else {
                scriptureIndex?.selectedChapter = 0
            }
            
            scriptureIndex?.selectedVerse = 0
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            //            pickerView.selectRow(0, inComponent: 3, animated: true)
            
            updateSearchResults()
            break
            
        case 1: // Book
            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                scripture?.picker.books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = scripture?.picker.books?[row]
                
                updateSwitches()
                
                if chapterSwitch.isOn {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]?.keys.sorted()
                    scriptureIndex?.selectedChapter = scripture!.picker.chapters![0]
                } else {
                    scriptureIndex?.selectedChapter = 0
                }
                
                scriptureIndex?.selectedVerse = 0
                
                pickerView.reloadAllComponents()
                
                pickerView.selectRow(0, inComponent: 2, animated: true)
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                
                updateSearchResults()
            }
            break
            
        case 2: // Chapter
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                scriptureIndex?.selectedChapter = scripture!.picker.chapters![row]
                
                scriptureIndex?.selectedVerse = 0
                
                pickerView.reloadAllComponents()
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                
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
            //            numberOfRows = 2 // N.T. or O.T.
            
            if (scriptureIndex?.byTestament[Constants.Old_Testament] != nil) {
                numberOfRows += 1
            }
            
            if (scriptureIndex?.byTestament[Constants.New_Testament] != nil) {
                numberOfRows += 1
            }
            break
            
        case 1:
            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                numberOfRows = scripture!.picker.books!.count
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                numberOfRows = scripture!.picker.chapters!.count
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
                return "\(scripture!.picker.chapters![row])"
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
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }
        
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
    var finished:Float = 0.0
    var progress:Float = 0.0 {
        willSet {
            
        }
        didSet {
            //            print(progress)
            //            print(finished)

            Thread.onMainThread() {
                if self.finished != 0 {
                    self.progressIndicator.progress = self.progress / self.finished
                }
                if self.progressIndicator.progress == 1.0 {
                    self.progressIndicator.isHidden = true
                }
            }
        }
    }

    lazy var scripture:Scripture? = {
        return Scripture(reference: nil)
        }()
    
    var mediaListGroupSort:MediaListGroupSort? {
        willSet {
            
        }
        didSet {

        }
    }
    
    var scriptureIndex:ScriptureIndex? {
        get {
            return mediaListGroupSort?.scriptureIndex
        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var switchesLabel: UILabel!
    
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var bookSwitch: UISwitch!

    @IBAction func bookSwitchAction(_ sender: UISwitch) {
        if bookSwitch.isOn && (scriptureIndex?.selectedTestament != nil) {
            if let selectedTestament = scriptureIndex!.selectedTestament {
                let testament = translateTestament(selectedTestament)
                if let book = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }

            scripture?.picker.books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            if scripture?.picker.books != nil {
                scriptureIndex?.selectedBook = scripture?.picker.books![0]
            }
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
            if let selectedTestament = scriptureIndex!.selectedTestament {
                let testament = translateTestament(selectedTestament)
                if let book = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }

            if scripture?.picker.chapters != nil {
                scriptureIndex?.selectedChapter = scripture!.picker.chapters![0]
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
            
            if mediaItems != nil {
                for mediaItem in mediaItems! {
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
                //                    print(book)
                sections[book] = sortMediaItems(sections[book],book:book)
            }
            
            self.sections = sections
        }
    }
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            print(selectedMediaItem as Any)
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
        guard scriptureIndex != nil else {
            return
        }
        
        scripture?.selected.testament   = scriptureIndex?.selectedTestament
        scripture?.selected.book        = scriptureIndex?.selectedBook
        scripture?.selected.chapter     = scriptureIndex!.selectedChapter
        scripture?.selected.verse       = scriptureIndex!.selectedVerse
        
        guard let selectedTestament = scriptureIndex?.selectedTestament else {
            mediaItems = nil
            return
        }

        let testament = translateTestament(selectedTestament)

        guard let selectedBook = scriptureIndex?.selectedBook else {
            mediaItems = scriptureIndex?.byTestament[testament]
            return
        }
        
        guard let selectedChapter = scriptureIndex?.selectedChapter, (selectedChapter > 0) else {
            mediaItems = scriptureIndex?.byBook[testament]?[selectedBook]
            return
        }
        
        guard let selectedVerse = scriptureIndex?.selectedVerse, (selectedVerse > 0) else {
            self.mediaItems = scriptureIndex?.byChapter[testament]?[selectedBook]?[selectedChapter]
            return
        }
        
        mediaItems = nil
            
        // Need to add this
//        mediaItems = scriptureIndex?.byVerse[testament]?[selectedBook!]?[selectedChapter]?[selectedVerse]
        
//        print(mediaItems)
    }
    
    func updateSearchResults()
    {
        scripture?.selected.testament   = scriptureIndex?.selectedTestament
        scripture?.selected.book        = scriptureIndex?.selectedBook
        scripture?.selected.chapter     = scriptureIndex!.selectedChapter
        scripture?.selected.verse       = scriptureIndex!.selectedVerse
        
        guard let selectedTestament = scriptureIndex?.selectedTestament else {
            mediaItems = nil
            
            Thread.onMainThread() {
                self.updateUI()
                self.tableView.reloadData()
                self.scripturePicker.isUserInteractionEnabled = true
            }
            return
        }

        let testament = translateTestament(selectedTestament)

        guard let selectedBook = scriptureIndex?.selectedBook else {
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                Thread.onMainThread() {
                    self.disableBarButtons()
                    self.spinner.isHidden = false
                    self.spinner.startAnimating()
                    self.isHiddenNumberAndTableUI(true)
                }
                
                if self.scriptureIndex!.sorted[testament] == nil {
                    self.scriptureIndex?.byTestament[testament] = self.sortMediaItems(self.scriptureIndex?.byTestament[testament],book:nil) // self.sortMediaItemsBook(self.scriptureIndex?.byTestament[testament])
                    self.scriptureIndex!.sorted[testament] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byTestament[testament]
                
                //            print(mediaItems)

                Thread.onMainThread() {
                    self.enableBarButtons()
                    self.updateUI()
                    self.tableView.reloadData()
                    if self.scriptureIndex?.byTestament[testament]?.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self.scripturePicker.isUserInteractionEnabled = true
                }
            })
            return
        }

        guard let selectedChapter = scriptureIndex?.selectedChapter, (selectedChapter > 0) else {
            let index = testament + selectedBook

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                Thread.onMainThread() {
                    self.disableBarButtons()
                    self.spinner.isHidden = false
                    self.spinner.startAnimating()
                    self.isHiddenNumberAndTableUI(true)
                }
                
                if self.scriptureIndex!.sorted[index] == nil {
                    self.scriptureIndex?.byBook[testament]?[selectedBook] = self.sortMediaItems(self.scriptureIndex?.byBook[testament]?[selectedBook],book:selectedBook) // self.sortMediaItemsChapter(self.scriptureIndex?.byBook[testament]?[book],book: book)
                    self.scriptureIndex!.sorted[index] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byBook[testament]?[selectedBook]
                
                //            print(mediaItems)
                
                Thread.onMainThread() {
                    self.enableBarButtons()
                    self.updateUI()
                    self.tableView.reloadData()
                    if self.scriptureIndex?.byBook[testament]?[selectedBook]?.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self.scripturePicker.isUserInteractionEnabled = true
                }
            })
            return
        }

        guard let selectedVerse = scriptureIndex?.selectedVerse, (selectedVerse > 0) else {
            let index = testament + selectedBook + "\(selectedChapter)"
            
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                Thread.onMainThread() {
                    self.disableBarButtons()
                    self.spinner.isHidden = false
                    self.spinner.startAnimating()
                    self.isHiddenNumberAndTableUI(true)
                }
                
                if self.scriptureIndex!.sorted[index] == nil {
                    self.scriptureIndex?.byChapter[testament]?[selectedBook]?[selectedChapter] = self.sortMediaItems(self.scriptureIndex?.byChapter[testament]?[selectedBook]?[selectedChapter],book:selectedBook) // self.sortMediaItemsVerse(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book: book,chapter: chapter)
                    self.scriptureIndex!.sorted[index] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byChapter[testament]?[selectedBook]?[selectedChapter]
                
                //            print(scriptureIndex!.selectedTestament,scriptureIndex!.selectedBook,scriptureIndex!.selectedChapter)
                //            print(mediaItems)
                
                Thread.onMainThread() {
                    self.enableBarButtons()
                    self.updateUI()
                    self.tableView.reloadData()
                    if self.scriptureIndex?.byChapter[testament]?[selectedBook]?[selectedChapter]?.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                    }
                    self.scripturePicker.isUserInteractionEnabled = true
                }
            })
            return
        }

        let index = testament + selectedBook + "\(selectedChapter)" + "\(selectedVerse)"

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread() {
                self.disableBarButtons()
                self.spinner.isHidden = false
                self.spinner.startAnimating()
                self.isHiddenNumberAndTableUI(true)
            }
            
            if self.scriptureIndex!.sorted[index] == nil {
//                self.scriptureIndex?.byVerse[testament]?[selectedBook]?[selectedChapter] = self.sortMediaItems(self.scriptureIndex?.byChapter[testament]?[book]?[selectedChapter],book:selectedBook,chapter:selectedChapter)
                self.scriptureIndex!.sorted[index] = true
            }
            
            self.mediaItems = nil
            
            // Need to add this
            //            self.mediaItems = scriptureIndex?.byVerse[testament]?[selectedBook!]?[selectedChapter]?[selectedVerse]
            
            //            print(self.mediaItems)
            
            Thread.onMainThread() {
                self.enableBarButtons()
                self.updateUI()
                self.tableView.reloadData()
                if self.scriptureIndex?.byVerse[testament]?[selectedBook]?[selectedChapter]?[selectedVerse]?.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: UITableViewScrollPosition.top, animated: true)
                }
                self.scripturePicker.isUserInteractionEnabled = true
            }
        })
    }

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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        globals.queue.async(execute: { () -> Void in
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_UPDATED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self.scriptureIndex)
        })
        
        navigationItem.hidesBackButton = false
        
        navigationController?.setToolbarHidden(true, animated: false)

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
        guard (mediaItems != nil) else {
            return nil
        }
        
        var bodyString:String?
        
        var bodyItems = [String:[MediaItem]]()
        
        for mediaItem in mediaItems! {
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
        
        bodyString = "<!DOCTYPE html><html><body>"
        
        bodyString = bodyString! + "<div>"

        bodyString = bodyString! + "The following media "
        
        if mediaItems!.count > 1 {
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
            bodyString = bodyString! + "Category: \(category)<br/><br/>"
        }
        
        if globals.media.tags.showing == Constants.TAGGED, let tag = globals.media.tags.selected {
            bodyString = bodyString! + "Collection: \(tag)<br/><br/>"
        }
        
        if globals.search.valid, let text = globals.search.text {
            bodyString = bodyString! + "Search: \(text)<br/><br/>"
        }
        
        bodyString = bodyString! + "</div>"

        if let selectedTestament = self.scriptureIndex?.selectedTestament {
            var indexFor = translateTestament(selectedTestament)

            if let selectedBook = self.scriptureIndex?.selectedBook {
                indexFor = selectedBook // indexFor + Constants.SINGLE_SPACE +
                
                if let chapter = self.scriptureIndex?.selectedChapter, chapter > 0 {
                    indexFor = indexFor + " \(chapter)"
                    
                    if let verse = self.scriptureIndex?.selectedVerse, verse > 0 {
                        indexFor = indexFor + ":\(verse)"
                    }
                }
            }
            
            bodyString = bodyString! + "\(indexFor) Scripture Index<br/>"
        }
        
        bodyString = bodyString! + "Items are grouped and sorted by Scripture reference.<br/>"

        bodyString = bodyString! + "Total: \(mediaItems!.count)<br/>"
        
        let books = bodyItems.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString! + "<br/>"
            bodyString = bodyString! + "<a href=\"#index\">Index</a><br/>"
        }
        
        if includeColumns {
            bodyString  = bodyString! + "<table>"
        }
        
        for book in books {
            let tag = book.replacingOccurrences(of: " ", with: "")

            if includeColumns {
                bodyString  = bodyString! + "<tr id=\"\(tag)\" name=\"\(tag)\"><td><br/></td></tr>"
                bodyString  = bodyString! + "<tr><td valign=\"baseline\" colspan=\"7\">"
            }
            
            if let mediaItems = bodyItems[book] {
                if includeURLs && (books.count > 1) {
                    bodyString = bodyString! + "<a href=\"#index\">" + book + " (\(mediaItems.count))" + "</a>"
                } else {
                    bodyString = bodyString! + book
                }

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
                
                let speakers = speakerCounts.keys.map({ (string:String) -> String in
                    return string
                }) as [String]
                
                if speakerCount == 1{
                    bodyString = bodyString! + " by \(speakers[0])"
                }
                
                if includeColumns {
                    bodyString  = bodyString! + "</td>"
                    bodyString  = bodyString! + "</tr>"
                } else {
                    bodyString = bodyString! + "<br/>"
                }
                
                for mediaItem in mediaItems {
                    var order = ["scripture","title","date"]
                    
                    if speakerCount > 1 {
                        order.append("speaker")
                    }
                    
                    if let string = mediaItem.bodyHTML(order: order, token: nil, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString! + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString! + "<br/>"
                    }
                }
                
//                if includeColumns {
//                    bodyString  = bodyString! + "<tr>"
//                    bodyString  = bodyString! + "<td valign=\"baseline\" colspan=\"7\">"
//                }
//                
//                bodyString = bodyString! + "<br/>"
//                
//                if includeColumns {
//                    bodyString  = bodyString! + "</td>"
//                    bodyString  = bodyString! + "</tr>"
//                }
            }
        }
        
        if includeColumns {
            bodyString  = bodyString! + "</table>"
        }
        
        bodyString = bodyString! + "<br/>"
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString! + "<div id=\"index\" name=\"index\">Index (<a href=\"#top\">Return to Top</a>)<br/><br/>"

//            bodyString = bodyString! + "<div><a id=\"index\" name=\"index\" href=\"#top\">Index</a><br/><br/>"
            
            for book in books {
                if let count = bodyItems[book]?.count {
                    bodyString = bodyString! + "<a href=\"#\(book.replacingOccurrences(of: " ", with: ""))\">\(book) (\(count))</a><br/>"
                }
            }
            
            bodyString = bodyString! + "</div>"
        }
        
        bodyString = bodyString! + "</body></html>"
        
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
    
    func actionMenu()
    {
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
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
    
    func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "ScriptureIndexViewController:index",completion:nil)
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

            popover.section.strings = sectionTitles
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self
            
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
        
        guard mediaItem != nil else {
            return
        }
        
        if let index = mediaItems?.index(of: mediaItem!) {
            let indexPath = IndexPath(row: index, section: 0)
            
            if (select) {
                DispatchQueue.global(qos: .background).async {
                    Thread.onMainThread() {
                        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                }
            }
            
            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                DispatchQueue.global(qos: .background).async {
                    Thread.onMainThread() {
                        self.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                    }
                }
            }
        }
    }
    
    
    func started()
    {
        
    }
    
    func updated()
    {
        
    }
    
    func completed()
    {
        updateSearchResults()
        
        Thread.onMainThread { (Void) -> (Void) in
            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: .top)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureIndexViewController.index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        setToolbarItems([spaceButton,indexButton], animated: false)

        navigationController?.toolbar.isTranslucent = false

        if let selectedTestament = scriptureIndex?.selectedTestament {
            let testament = translateTestament(selectedTestament)
            
            if scripture?.picker.books == nil {
                scripture?.picker.books = scriptureIndex?.byBook[testament]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            }
            
//            print(books)
            
            if scripture?.picker.chapters == nil {
                if let book = scriptureIndex?.selectedBook {
                    scripture?.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }
            
//            print(chapters)
        }
        
        progressIndicator.isHidden = true

//        navigationItem.leftItemsSupplementBackButton = true
  
        numberOfMediaItems.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()

        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureIndexViewController.actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)

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
            
//            print(book)
//            print(first,second)
//            print(firstBooksChaptersVerses?.data,secondBooksChaptersVerses?.data)

            if firstBooksChaptersVerses == secondBooksChaptersVerses {
                if first.fullDate!.isEqualTo(second.fullDate!) {
                    if first.service == second.service {
                        return lastNameFromName(first.speaker) < lastNameFromName(second.speaker)
                    } else {
                        return first.service < second.service
                    }
                } else {
                    return first.fullDate!.isOlderThan(second.fullDate!)
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
        
        let testament = translateTestament(scriptureIndex!.selectedTestament!)
        let book = scriptureIndex!.selectedBook
        let chapter = scriptureIndex!.selectedChapter
        let verse = scriptureIndex!.selectedVerse
        
        if book != nil {
            if verse > 0 {
                if mediaItems != nil {
                    numberOfMediaItems.text = "\(self.mediaItems!.count) from verse \(verse) in chapter \(chapter) of \(book!) in the \(testament)"
                } else {
                    numberOfMediaItems.text = "0 from verse \(verse) in chapter \(chapter) of \(book!) in the \(testament)"
                }
                return
            }
            
            if chapter > 0 {
                if mediaItems != nil {
                    numberOfMediaItems.text = "\(mediaItems!.count) from chapter \(chapter) of \(book!) in the \(testament)"
                } else {
                    numberOfMediaItems.text = "0 from chapter \(chapter) of \(book!) in the \(testament)"
                }
                return
            }
            
            if mediaItems != nil {
                numberOfMediaItems.text = "\(mediaItems!.count) from \(book!) in the \(testament)"
            } else {
                numberOfMediaItems.text = "0 from \(book!) in the \(testament)"
            }
            return
        }
        
        if (mediaItems != nil) {
            numberOfMediaItems.text = "\(mediaItems!.count) from the \(testament)"
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
        switchesLabel.isHidden = state
        
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
        
        //                print(selectedTestament)
        //                print(selectedBook)
        //                print(selectedChapter)
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}

extension ScriptureIndexViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
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
        guard sectionTitles != nil else {
            return nil
        }

        guard section >= 0, section < sectionTitles!.count else {
            return nil
        }

        guard scriptureIndex?.selectedBook == nil else {
            return nil
        }

        return sectionTitles![section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        
        if let _ = scriptureIndex?.selectedBook {
            return 1
        } else {
            return sectionTitles != nil ? sectionTitles!.count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        if let _ = scriptureIndex?.selectedBook {
            return mediaItems != nil ? mediaItems!.count : 0
        } else {
            if let sectionTitle = sectionTitles?[section], let rows = sections?[sectionTitle] {
                return rows.count
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        if let _ = scriptureIndex?.selectedBook {
            //            print(scriptureIndex?.selectedBook)
            cell.mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                cell.mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        cell.vc = self
        
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
            //            print(scriptureIndex?.selectedBook)
            mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        return editActions(cell: nil, mediaItem: mediaItem) != nil
    }
    
    func editActions(cell: MediaTableViewCell?, mediaItem:MediaItem?) -> [UITableViewRowAction]?
    {
        // causes recursive call to cellForRowAt
//        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
//            return nil
//        }
        
        guard let mediaItem = mediaItem else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        var transcript:UITableViewRowAction!
        var scripture:UITableViewRowAction!
        
        transcript = UITableViewRowAction(style: .normal, title: Constants.FA.TRANSCRIPT) { action, index in
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0].subviews[actions.index(of: transcript)!]
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                htmlString = mediaItem.fullNotesHTML
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    
                    return mediaItem.fullNotesHTML
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable(self,"HTML transcript unavailable.")
                    }
                })
            }
        }
        transcript.backgroundColor = UIColor.purple
        
        scripture = UITableViewRowAction(style: .normal, title: Constants.FA.SCRIPTURE) { action, index in
            let sourceView = cell?.subviews[0]
            let sourceRectView = cell?.subviews[0].subviews[actions.index(of: scripture)!]
            
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
        
        if actions.count == 0 {
            print("")
        }
        
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            return editActions(cell: cell, mediaItem: cell.mediaItem)
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("didSelectRowAtIndexPath")
        
        if let _ = scriptureIndex?.selectedBook {
            selectedMediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                selectedMediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        globals.addToHistory(selectedMediaItem)
        
        print(selectedMediaItem?.booksAndChaptersAndVerses()?.data as Any)
        
//        print(selectedMediaItem?.booksChaptersVerses?.data as Any)
        
        if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? MediaViewController {
                viewController.selectedMediaItem = selectedMediaItem
                splitViewController?.viewControllers[1] = navigationController
            }
        } else {
            if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM) as? MediaViewController {
                viewController.selectedMediaItem = selectedMediaItem
                
                self.navigationController?.navigationItem.hidesBackButton = false
                
//                self.navigationController?.setToolbarHidden(true, animated: true)
                
                self.navigationController?.pushViewController(viewController, animated: true)
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
            view?.label = UILabel()
            
            view?.label?.numberOfLines = 0
            view?.label?.lineBreakMode = .byWordWrapping
            
            view?.label?.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(view!.label!)
            
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":view!.label!]))
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":view!.label!]))
        }
        
        if sectionTitles != nil, section >= 0, section < sectionTitles!.count {
            view?.label?.attributedText = NSAttributedString(string: sectionTitles![section], attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR", attributes: Constants.Fonts.Attributes.bold)
        }

        return view
    }
}


