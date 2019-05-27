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
                    scriptureIndex?.scripture.picked.testament = Constants.NT
                    break
                }
                
                if (scriptureIndex?.byTestament[Constants.New_Testament] == nil) {
                    scriptureIndex?.scripture.picked.testament = Constants.OT
                    break
                }
                
                scriptureIndex?.scripture.picked.testament = Constants.OT
                break
                
            case 1:
                scriptureIndex?.scripture.picked.testament = Constants.NT
                break
                
            default:
                break
            }

            if let selectedTestament = scriptureIndex?.scripture.picked.testament, bookSwitch.isOn {
                scriptureIndex?.scripture.picked.picker.books = scriptureIndex?.byBook[selectedTestament.translateTestament]?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
                scriptureIndex?.scripture.picked.book = scriptureIndex?.scripture.picked.picker.books?[0]
            } else {
                scriptureIndex?.scripture.picked.book = nil
            }
            
            updateSwitches()
            
            if let selectedTestament = scriptureIndex?.scripture.picked.testament, chapterSwitch.isOn, let selectedBook = scriptureIndex?.scripture.picked.book {
                scriptureIndex?.scripture.picked.picker.chapters = scriptureIndex?.byChapter[selectedTestament.translateTestament]?[selectedBook]?.keys.sorted()
                
                if let chapter = scriptureIndex?.scripture.picked.picker.chapters?[0] {
                    scriptureIndex?.scripture.picked.chapter = chapter
                }
            } else {
                scriptureIndex?.scripture.picked.chapter = 0
            }
            
            scriptureIndex?.scripture.picked.verse = 0
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            updateSearchResults()
            break
            
        case 1: // Book
            if let selectedTestament = scriptureIndex?.scripture.picked.testament, bookSwitch.isOn {
                scriptureIndex?.scripture.picked.picker.books = scriptureIndex?.byBook[selectedTestament.translateTestament]?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
                scriptureIndex?.scripture.picked.book = scriptureIndex?.scripture.picked.picker.books?[row]
                
                updateSwitches()
                
                if chapterSwitch.isOn, let selectedBook = scriptureIndex?.scripture.picked.book {
                    scriptureIndex?.scripture.picked.picker.chapters = scriptureIndex?.byChapter[selectedTestament.translateTestament]?[selectedBook]?.keys.sorted()

                    if let chapter = scriptureIndex?.scripture.picked.picker.chapters?[0] {
                        scriptureIndex?.scripture.picked.chapter = chapter
                    }
                } else {
                    scriptureIndex?.scripture.picked.chapter = 0
                }
                
                scriptureIndex?.scripture.picked.verse = 0
                
                pickerView.reloadAllComponents()
                
                pickerView.selectRow(0, inComponent: 2, animated: true)

                updateSearchResults()
            }
            break
            
        case 2: // Chapter
            if let selectedTestament = scriptureIndex?.scripture.picked.testament, bookSwitch.isOn, let selectedBook = scriptureIndex?.scripture.picked.book, chapterSwitch.isOn {
                if let chapter = scriptureIndex?.scripture.picked.picker.chapters?[row] {
                    scriptureIndex?.scripture.picked.chapter = chapter
                }
                
                scriptureIndex?.scripture.picked.verse = 0
                
                if let selectedChapter = scriptureIndex?.scripture.picked.chapter {
                    scriptureIndex?.scripture.picked.picker.verses = scriptureIndex?.byVerse[selectedTestament.translateTestament]?[selectedBook]?[selectedChapter]?.keys.sorted()
                }
                
                pickerView.reloadAllComponents()
                
                if includeVerses {
                    pickerView.selectRow(0, inComponent: 3, animated: true)
                }
                
                updateSearchResults()
            }
            break
            
        case 3: // Verse
            if (scriptureIndex?.scripture.picked.testament != nil) && (scriptureIndex?.scripture.picked.book != nil) && (scriptureIndex?.scripture.picked.chapter > 0) && bookSwitch.isOn && chapterSwitch.isOn {
                scriptureIndex?.scripture.picked.verse = row + 1
                
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return includeVerses ? 4 : 3  // Compact width => 3, otherwise 5?  (beginning and ending verses)
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
            guard scriptureIndex?.scripture.picked.testament != nil else {
                numberOfRows = 0 // number of books
                break
            }
            
            guard bookSwitch.isOn else {
                numberOfRows = 0 // number of books
                break
            }
            
            if let count = scriptureIndex?.scripture.picked.picker.books?.count {
                numberOfRows = count // number of books
            }
            break
            
        case 2:
            guard scriptureIndex?.scripture.picked.testament != nil else {
                numberOfRows = 0 // number of chapters in book
                break
            }

            guard bookSwitch.isOn else {
                numberOfRows = 0 // number of chapters in book
                break
            }
            
            guard scriptureIndex?.scripture.picked.book != nil else {
                numberOfRows = 0 // number of chapters in book
                break
            }
            
            guard chapterSwitch.isOn else {
                numberOfRows = 0 // number of chapters in book
                break
            }

            if let count = scriptureIndex?.scripture.picked.picker.chapters?.count {
                numberOfRows = count
            }
            break
            
        case 3:
            guard includeVerses else {
                numberOfRows = 0 // number of verses in chapter
                break
            }
            
            guard scriptureIndex?.scripture.picked.chapter > 0 else {
                numberOfRows = 0 // number of verses in chapter
                break
            }
            
            if let count = scriptureIndex?.scripture.picked.picker.verses?.count {
                numberOfRows = count // number of verses in chapter
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
            if (scriptureIndex?.scripture.picked.testament != nil) {
                if let book = scriptureIndex?.scripture.picked.picker.books?[row] {
                    return book
                }
            }
            break
            
        case 2:
            if (scriptureIndex?.scripture.picked.testament != nil) {
                if let num = scriptureIndex?.scripture.picked.picker.chapters?[row] {
                    return num.description
                }
            }
            break
            
        case 3:
            guard includeVerses else {
                break
            }

            if scriptureIndex?.scripture.picked.chapter > 0 {
                if let num = scriptureIndex?.scripture.picked.picker.verses?[row] {
                    return num.description
                }
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
            label.attributedText = NSAttributedString(string: title,attributes: Constants.Fonts.Attributes.body)
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

/**
 For displaying ScriptureIndex from an MLGS
 */
class ScriptureIndexViewController : MediaItemsViewController
{
    let name = "SIVC:" + UUID().uuidString
    
    var includeVerses = false
    
    var finished:Float = 0.0
    var progress:Float = 0.0
    {
        willSet {
            
        }
        didSet {
            Thread.onMain {
                if self.finished > 0 {
                    self.progressIndicator.progress = self.progress / self.finished
                }
                if self.progressIndicator.progress == 1.0 {
                    self.progressIndicator.isHidden = true
                }
            }
        }
    }
    
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
    
    var scripture:Scripture?
    {
        get {
            return scriptureIndex?.scripture
        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var bookSwitch: UISwitch!

    @IBAction func bookSwitchAction(_ sender: UISwitch)
    {
        if let selectedTestament = scriptureIndex?.scripture.picked.testament, bookSwitch.isOn {
            scriptureIndex?.scripture.picked.picker.books = scriptureIndex?.byBook[selectedTestament.translateTestament]?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
            
            scriptureIndex?.scripture.picked.book = scriptureIndex?.scripture.picked.picker.books?[0]

            if let book = scriptureIndex?.scripture.picked.book {
                scriptureIndex?.scripture.picked.picker.chapters = scriptureIndex?.byChapter[selectedTestament.translateTestament]?[book]?.keys.sorted()
            }
        } else {
            scriptureIndex?.scripture.picked.book = nil
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
            if let selectedTestament = scriptureIndex?.scripture.picked.testament, let selectedBook = scriptureIndex?.scripture.picked.book {
                scriptureIndex?.scripture.picked.picker.chapters = scriptureIndex?.byChapter[selectedTestament.translateTestament]?[selectedBook]?.keys.sorted()
            }

            if let num = scriptureIndex?.scripture.picked.picker.chapters?[0] {
                scriptureIndex?.scripture.picked.chapter = num
            }
            
            if let selectedTestament = scriptureIndex?.scripture.picked.testament, let selectedBook = scriptureIndex?.scripture.picked.book, let selectedChapter = scriptureIndex?.scripture.picked.chapter {
                scriptureIndex?.scripture.picked.picker.verses = scriptureIndex?.byVerse[selectedTestament.translateTestament]?[selectedBook]?[selectedChapter]?.keys.sorted()
            }
        } else {
            scriptureIndex?.scripture.picked.chapter = 0
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
            return scriptureIndex?.sectionTitles // sections?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
        }
    }
    
    var mediaItems:[MediaItem]?
    {
        get {
            return scriptureIndex?.mediaItems
        }
        
        set {
            scriptureIndex?.mediaItems = newValue
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
        
        guard let selectedTestament = scriptureIndex.scripture.picked.testament else {
            mediaItems = nil
            return
        }

        let testament = selectedTestament.translateTestament

        guard let selectedBook = scriptureIndex.scripture.picked.book else {
            mediaItems = scriptureIndex.byTestament[testament]
            return
        }
        
        guard scriptureIndex.scripture.picked.chapter > 0 else {
            mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
            return
        }
        
        guard scriptureIndex.scripture.picked.verse > 0 else {
            self.mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]
            return
        }
        
        mediaItems = nil
    }
    
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "SIVC:Operations"
        operationQueue.qualityOfService = .userInteractive
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    
        scriptureIndex?.callBacks.unregister(name)
    }
    
    func updateSearchResults()
    {
        guard let scriptureIndex = scriptureIndex else {
            return
        }
        
        guard let selectedTestament = scriptureIndex.scripture.picked.testament else {
            mediaItems = nil
            
            Thread.onMain {
                self.updateUI()
                self.tableView.reloadData()
                self.scripturePicker.isUserInteractionEnabled = true
            }
            return
        }

        let testament = selectedTestament.translateTestament

        guard let selectedBook = scriptureIndex.scripture.picked.book else {
            operationQueue.cancelAllOperations()
            
            operationQueue.addOperation { [weak self] in
                Thread.onMain {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.isSorted[testament] == nil {
                    let mediaItems = scriptureIndex.byTestament[testament]
                    scriptureIndex.byTestament[testament] = mediaItems?.sort(book:nil)
                    scriptureIndex.isSorted[testament] = true
                }
                
                self?.mediaItems = scriptureIndex.byTestament[testament]
                
                Thread.onMain {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byTestament[testament]?.count > 0 {
                        let indexPath = IndexPath(row: 0,section: 0)
                        
                        if self?.tableView.isValid(indexPath) == true {
                            self?.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                        }
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        guard scriptureIndex.scripture.picked.chapter > 0 else {
            let index = testament + selectedBook

            operationQueue.cancelAllOperations()

            operationQueue.addOperation { [weak self] in
                Thread.onMain {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.isSorted[index] == nil {
                    let mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
                    scriptureIndex.byBook[testament]?[selectedBook] = mediaItems?.sort(book:selectedBook)
                    scriptureIndex.isSorted[index] = true
                }
                
                self?.mediaItems = scriptureIndex.byBook[testament]?[selectedBook]
                
                Thread.onMain {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byBook[testament]?[selectedBook]?.count > 0 {
                        let indexPath = IndexPath(row: 0,section: 0)
                        
                        if self?.tableView.isValid(indexPath) == true {
                            self?.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                        }
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        guard scriptureIndex.scripture.picked.verse > 0 else {
            let index = testament + selectedBook + "\(scriptureIndex.scripture.picked.chapter)"

            operationQueue.cancelAllOperations()
            
            operationQueue.addOperation { [weak self] in
                Thread.onMain {
                    self?.disableBarButtons()
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                    self?.isHiddenNumberAndTableUI(true)
                }
                
                if scriptureIndex.isSorted[index] == nil {
                    let mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]
                    scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter] = mediaItems?.sort(book:selectedBook)
                    scriptureIndex.isSorted[index] = true
                }
                
                self?.mediaItems = scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]
                
                Thread.onMain {
                    self?.enableBarButtons()
                    self?.updateUI()
                    self?.tableView.reloadData()
                    if scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]?.count > 0 {
                        let indexPath = IndexPath(row: 0,section: 0)
                        
                        if self?.tableView.isValid(indexPath) == true {
                            self?.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                        }
                    }
                    self?.scripturePicker.isUserInteractionEnabled = true
                }
            }
            return
        }

        let index = testament + selectedBook + "\(scriptureIndex.scripture.picked.chapter)" + "\(scriptureIndex.scripture.picked.verse)"

        operationQueue.cancelAllOperations()
        
        operationQueue.addOperation { [weak self] in
            Thread.onMain {
                self?.disableBarButtons()
                self?.spinner.isHidden = false
                self?.spinner.startAnimating()
                self?.isHiddenNumberAndTableUI(true)
            }
            
            if scriptureIndex.isSorted[index] == nil {
                scriptureIndex.isSorted[index] = true
            }
            
            self?.mediaItems = nil // scriptureIndex.byChapter[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]?[scriptureIndex.scripture.picked.verse]
            
            Thread.onMain {
                self?.enableBarButtons()
                self?.updateUI()
                self?.tableView.reloadData()
                if scriptureIndex.byVerse[testament]?[selectedBook]?[scriptureIndex.scripture.picked.chapter]?[scriptureIndex.scripture.picked.verse]?.count > 0 {
                    let indexPath = IndexPath(row: 0,section: 0)
                    
                    if self?.tableView.isValid(indexPath) == true {
                        self?.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                    }
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

    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        addNotifications()
        
        scriptureIndex?.callBacks.register(name,
            [
            "start": { [weak self] in
                self?.started()
            },
            "update": { [weak self] in
                self?.updated()
            },
            "complete": { [weak self] in
                self?.completed()
            }
            ]
        )

        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItem.Style.plain, target: self, action: #selector(index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        setToolbarItems([spaceButton,indexButton], animated: false)
        
        navigationController?.toolbar.isTranslucent = false
        
        if let selectedTestament = scriptureIndex?.scripture.picked.testament {
            let testament = selectedTestament.translateTestament
            
            if scriptureIndex?.scripture.picked.picker.books == nil {
                scriptureIndex?.scripture.picked.picker.books = scriptureIndex?.byBook[testament]?.keys.sorted() { $0.bookNumberInBible < $1.bookNumberInBible }
            }
            
            if let book = scriptureIndex?.scripture.picked.book {
                if scriptureIndex?.scripture.picked.picker.chapters == nil {
                    scriptureIndex?.scripture.picked.picker.chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
                
                if scriptureIndex?.scripture.picked.picker.verses == nil {
                    if let chapter = scriptureIndex?.scripture.picked.chapter {
                        scriptureIndex?.scripture.picked.picker.verses = scriptureIndex?.byVerse[testament]?[book]?[chapter]?.keys.sorted()
                    }
                }
            }
        }
        
        progressIndicator.isHidden = true
        
        numberOfMediaItems.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        let actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actionMenu))
        actionButton.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
        
        navigationItem.setRightBarButton(actionButton, animated: true) //
        
        isHiddenUI(false)
        disableBarButtons()
        spinner.isHidden = false
        spinner.startAnimating()
        isHiddenNumberAndTableUI(true)
        
        navigationItem.hidesBackButton = false
        
        navigationController?.isToolbarHidden = true

        scripturePicker.isUserInteractionEnabled = false

        if let completed = scriptureIndex?.completed, completed {
            setup()
            updateUI()
            scripturePicker.isUserInteractionEnabled = true
        }

        scriptureIndex?.build()
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
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()
        
        if mediaItems?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        if let scriptureReference = scriptureIndex?.scripture.picked.reference, scriptureReference != scriptureIndex?.scripture.picked.book {
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
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:index",completion:nil)
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
    
    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableView.ScrollPosition)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:selectOrScrollToMediaItem",completion:nil)
            return
        }
        
        // isEditing must be on main thread.
        guard !tableView.isEditing else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let index = mediaItems?.firstIndex(of: mediaItem) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        guard tableView.isValid(indexPath) else {
            return
        }
        
        if (select) {
            // So UI operates as desired.
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.onMain {
                    self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        
        if (scroll) {
            // Scrolling when the user isn't expecting it can be jarring.
            // So UI operates as desired.
            DispatchQueue.global(qos: .background).async { [weak self] in
                Thread.onMain {
                    self?.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                }
            }
        }
    }
    
    
    @objc func started()
    {
        
    }
    
    @objc func updated()
    {
        // Can't do this until ScriptureIndex is thread safe
        
//        updateSearchResults()
//
//        // In case the search results were already computed.
//        Thread.onMainSync {
//            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: .top)
//        }
    }
    
    @objc func completed()
    {
        updateSearchResults()
        
        // In case the search results were already computed.
        Thread.onMainSync {
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
        
    }
    
    func updateText()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:updateText", completion: nil)
            return
        }
        
        guard let scriptureIndex = scriptureIndex else {
            return
        }
        
        guard let selectedTestament = scriptureIndex.scripture.picked.testament else {
            return
        }
        
        let testament = selectedTestament.translateTestament
        let book = scriptureIndex.scripture.picked.book
        let chapter = scriptureIndex.scripture.picked.chapter
        let verse = scriptureIndex.scripture.picked.verse
        
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
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:isHiddenUI", completion: nil)
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
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:isHiddenNumberAndTableUI", completion: nil)
            return
        }
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        tableView.isHidden = state
    }
    
    func updatePicker()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:updatePicker", completion: nil)
            return
        }
        
        scripturePicker.reloadAllComponents()
        
        guard let selectedTestament = scriptureIndex?.scripture.picked.testament else {
            return
        }
        
        if let index = Constants.TESTAMENTS.firstIndex(of: selectedTestament) {
            scripturePicker.selectRow(index, inComponent: 0, animated: false)
        }
        
        if let selectedBook = scriptureIndex?.scripture.picked.book, let index = scriptureIndex?.scripture.picked.picker.books?.firstIndex(of: selectedBook) {
            scripturePicker.selectRow(index, inComponent: 1, animated: false)
        }
        
        if let selectedChapter = scriptureIndex?.scripture.picked.chapter, selectedChapter > 0, let index = scriptureIndex?.scripture.picked.picker.chapters?.firstIndex(of: selectedChapter) {
            scripturePicker.selectRow(index, inComponent: 2, animated: false)
        }

        guard includeVerses else {
            return
        }
        
        if let selectedVerse = scriptureIndex?.scripture.picked.verse, selectedVerse > 0, let index = scriptureIndex?.scripture.picked.picker.verses?.firstIndex(of: selectedVerse) {
            scripturePicker.selectRow(index, inComponent: 3, animated: false)
        }
    }

    func updateSwitches()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:updateSwitches", completion: nil)
            return
        }
        
        bookSwitch.isOn = scriptureIndex?.scripture.picked.book != nil
        
        if let selectedTestament = scriptureIndex?.scripture.picked.testament {
            bookSwitch.isEnabled = (scriptureIndex?.byTestament[selectedTestament.translateTestament] != nil)
        } else {
            bookSwitch.isEnabled = false
        }

        if !bookSwitch.isOn {
            scriptureIndex?.scripture.picked.chapter = 0
        }
        
        chapterSwitch.isOn = bookSwitch.isOn && (scriptureIndex?.scripture.picked.chapter > 0)
        chapterSwitch.isEnabled = bookSwitch.isOn
    }
    
    func updateActionMenu()
    {
        navigationItem.rightBarButtonItem?.isEnabled = actionMenuItems()?.count > 0
    }
    
    func updateToolbar()
    {
        navigationController?.setToolbarHidden(scriptureIndex?.scripture.picked.book != nil, animated: true)
        
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
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:updateUI", completion: nil)
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
    
    override func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        super.rowClickedAtIndex(index, strings: strings, purpose: purpose, mediaItem: mediaItem)
        
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "ScriptureIndexViewController:rowClickedAtIndex",completion:nil)
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
            
            //Can't use this reliably w/ variable row heights.
            if tableView.isValid(indexPath) {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
            }
            break
            
        case .selectingAction:
            dismiss(animated: true, completion: nil)
            
            switch strings[index] {
            case Constants.Strings.View_List:
                self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                    if self?.scriptureIndex?.html?.string == nil {
                        self?.scriptureIndex?.html?.string = self?.scriptureIndex?.html(includeURLs:true, includeColumns:true, test:test)
                    }
                    
                    return self?.scriptureIndex?.html?.string
                    }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                        if let vc = self {
                            vc.presentHTMLModal(mediaItem: nil, style: .overFullScreen, title: Globals.shared.contextTitle, htmlString: data as? String)
                        }
                })
                break
                
            case Constants.Strings.View_Scripture:
                if let reference = scriptureIndex?.scripture.picked.reference {
                    scripture?.reference = reference
                    if scripture?.html?[reference] != nil {
                        self.popoverHTML(title:reference, bodyHTML:self.scripture?.text(reference), barButtonItem:self.navigationItem.rightBarButtonItem, htmlString:scripture?.html?[reference], search:false)
                    } else {
                        // test:(()->(Bool))?
                        self.process(work: { [weak self] () -> (Any?) in
                            self?.scripture?.load() // reference
                            return self?.scripture?.html?[reference]
                        }, completion: { [weak self] (data:Any?) in
                            if let htmlString = data as? String {
                                if let vc = self {
                                    vc.popoverHTML(title:reference, bodyHTML:self?.scripture?.text(reference), barButtonItem:self?.navigationItem.rightBarButtonItem, htmlString:htmlString, search:false)
                                }
                            } else {
                                if let vc = self {
                                    vc.networkUnavailable("Scripture text unavailable.")
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
                mediaItem?.audioDownload?.download(background: true)
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
            
        default:
            break
        }
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
        if let _ = scriptureIndex?.scripture.picked.book {
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

        guard scriptureIndex?.scripture.picked.book == nil else {
            return nil
        }

        return sectionTitles[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        
        if let _ = scriptureIndex?.scripture.picked.book {
            return 1
        } else {
            return sectionTitles?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        if let _ = scriptureIndex?.scripture.picked.book {
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
        
        if let _ = scriptureIndex?.scripture.picked.book {
            if indexPath.row < mediaItems?.count {
                cell.mediaItem = mediaItems?[indexPath.row]
            }
        } else {
            if indexPath.section < sectionTitles?.count, let sectionTitle = sectionTitles?[indexPath.section] {
                if indexPath.row < sections?[sectionTitle]?.count {
                    cell.mediaItem = sections?[sectionTitle]?[indexPath.row]
                }
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
        
        if let _ = scriptureIndex?.scripture.picked.book {
            if indexPath.row < mediaItems?.count {
                mediaItem = mediaItems?[indexPath.row]
            }
        } else {
            if indexPath.section < sectionTitles?.count, let sectionTitle = sectionTitles?[indexPath.section] {
                if indexPath.row < sections?[sectionTitle]?.count {
                    mediaItem = sections?[sectionTitle]?[indexPath.row]
                }
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
            guard var alertActions = cell.mediaItem?.editActions(viewController: self) else {
                return
            }
            
            alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil))

            Alerts.shared.alert(title: Constants.Strings.Actions, message: message, actions: alertActions)
        }
        action.backgroundColor = UIColor.controlBlue()
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let _ = scriptureIndex?.scripture.picked.book {
            if indexPath.row < mediaItems?.count {
                selectedMediaItem = mediaItems?[indexPath.row]
            }
        } else {
            if indexPath.section < sectionTitles?.count, let sectionTitle = sectionTitles?[indexPath.section] {
                if indexPath.row < sections?[sectionTitle]?.count {
                    selectedMediaItem = sections?[sectionTitle]?[indexPath.row]
                }
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


