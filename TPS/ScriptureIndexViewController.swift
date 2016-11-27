//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI

class ScriptureIndex {
    var sorted = [String:Bool]()
    
                    //Test
    var byTestament = [String:[MediaItem]]()
    
                    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
                    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
                    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()

    var selectedTestament:String? = Constants.OT
    
    var selectedBook:String? {
        didSet {
            if selectedBook == nil {
                selectedChapter = 0
                selectedVerse = 0
            }
        }
    }
    
    var selectedChapter:Int = 0 {
        didSet {
            if selectedChapter == 0 {
                selectedVerse = 0
            }
        }
    }
    
    var selectedVerse:Int = 0
}

class ScriptureIndexViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate, MFMailComposeViewControllerDelegate, PopoverTableViewControllerDelegate {
    var finished:Float = 0.0
    var progress:Float = 0.0
    
    var books:[String]?
    var chapters:[Int]?
    var verses:[Int]?
    
    var mediaListGroupSort:MediaListGroupSort?
    
    var scriptureIndex:ScriptureIndex? {
        get {
            return mediaListGroupSort?.scriptureIndex
        }
        set {
            mediaListGroupSort?.scriptureIndex = newValue
        }
    }
    
    var list:[MediaItem]? {
        get {
            return mediaListGroupSort?.list
        }
    }
    
    var timer:Timer?
    
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
                    chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }

            books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            if books != nil {
                scriptureIndex?.selectedBook = books![0]
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
                    chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }

            if chapters != nil {
                scriptureIndex?.selectedChapter = chapters![0]
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
    
    var sections:[String:[MediaItem]]?

    var sectionTitles:[String]? {
        get {
            return sections?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        }
    }
    
    var mediaItems:[MediaItem]? {
        didSet {
            sections = [String:[MediaItem]]()
            
            if mediaItems != nil {
                for mediaItem in mediaItems! {
                    if let books = mediaItem.books {
                        for book in books {
                            if let selectedTestament = scriptureIndex?.selectedTestament {
                                if translateTestament(selectedTestament) == testament(book) {
                                    if sections?[book] == nil {
                                        sections?[book] = [mediaItem]
                                    } else {
                                        sections?[book]?.append(mediaItem)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    var selectedMediaItem:MediaItem?
    
    @IBOutlet weak var scripturePicker: UIPickerView!
    
    @IBOutlet weak var numberOfMediaItemsLabel: UILabel!
    @IBOutlet weak var numberOfMediaItems: UILabel!
    
    func updateDirectionLabel()
    {
//        if !bookSwitch.isOn && !chapterSwitch.isOn {
//            directionLabel.text = "Select a testament to find related media."
//        }
//        
//        if bookSwitch.isOn && !chapterSwitch.isOn {
//            directionLabel.text = "Select a testament and book to find related media."
//        }
//        
//        if bookSwitch.isOn && chapterSwitch.isOn {
//            directionLabel.text = "Select a testament, book, and chapter to find related media."
//        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var numberOfRows = 1
        
        switch component {
        case 0:
            numberOfRows = 2 // N.T. or O.T.
            break
            
        case 1:
            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                numberOfRows = books!.count
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) && (scriptureIndex?.selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                numberOfRows = chapters!.count
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
    
    //    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    //
    //    }
    
    func translateTestament(_ testament:String) -> String
    {
        var translation = Constants.EMPTY_STRING
        
        switch testament {
        case Constants.OT:
            translation = Constants.Old_Testament
            break
            
        case Constants.NT:
            translation = Constants.New_Testament
            break
            
        default:
            break
        }
        
        return translation
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label:UILabel!
        
        if view != nil {
            label = view as! UILabel
        } else {
            label = UILabel()
        }

        label.font = UIFont(name: "System", size: 12.0)
        
        label.text = title(forRow: row, forComponent: component)
        
        return label
    }
    
    func title(forRow row:Int, forComponent component:Int) -> String?
    {
        switch component {
        case 0:
            if row == 0 {
                return Constants.OT
            }
            if row == 1 {
                return Constants.NT
            }
            break
            
        case 1:
            if (scriptureIndex?.selectedTestament != nil) {
                return books![row]
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) {
                return "\(chapters![row])"
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return title(forRow: row,forComponent: component)
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
    
    func updateSearchResults()
    {
        guard (scriptureIndex?.selectedTestament != nil) else {
            mediaItems = nil
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateUI()
            })
            return
        }

        guard (scriptureIndex?.selectedBook != nil) else {
            let testament = translateTestament(scriptureIndex!.selectedTestament!)
            
            let index = testament

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if self.scriptureIndex!.sorted[index] == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.hideNumberAndTableUI()
                    })

                    self.scriptureIndex?.byTestament[testament] = self.sortMediaItemsBook(self.scriptureIndex?.byTestament[testament])
                    self.scriptureIndex!.sorted[index] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byTestament[testament]
                
                //            print(mediaItems)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.updateUI()
                    self.enableBarButtons()
                })
            })
            return
        }

        guard (scriptureIndex?.selectedChapter > 0) else {
            let testament = translateTestament(scriptureIndex!.selectedTestament!)
            let book = scriptureIndex!.selectedBook!
            
            let index = testament + book

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if self.scriptureIndex!.sorted[index] == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.hideNumberAndTableUI()
                    })
                    
                    self.scriptureIndex?.byBook[testament]?[book] = self.sortMediaItemsChapter(self.scriptureIndex?.byBook[testament]?[book],book: book)
                    self.scriptureIndex!.sorted[index] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byBook[testament]?[book]
                
                //            print(mediaItems)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.updateUI()
                    self.enableBarButtons()
                })
            })
            return
        }

        guard (scriptureIndex?.selectedVerse > 0) else {
            let testament = translateTestament(scriptureIndex!.selectedTestament!)
            let book = scriptureIndex!.selectedBook!
            let chapter = scriptureIndex!.selectedChapter
            
            let index = testament + book + "\(chapter)"
            
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if self.scriptureIndex!.sorted[index] == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.hideNumberAndTableUI()
                    })

                    self.scriptureIndex?.byChapter[testament]?[book]?[chapter] = self.sortMediaItemsVerse(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book: book,chapter: chapter)
                    self.scriptureIndex!.sorted[index] = true
                }
                
                self.mediaItems = self.scriptureIndex?.byChapter[testament]?[book]?[chapter]
                
                //            print(scriptureIndex!.selectedTestament,scriptureIndex!.selectedBook,scriptureIndex!.selectedChapter)
                //            print(mediaItems)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.updateUI()
                    self.enableBarButtons()
                })
            })
            return
        }

        let testament = translateTestament(scriptureIndex!.selectedTestament!)
        let book = scriptureIndex!.selectedBook!
        let chapter = scriptureIndex!.selectedChapter
        let verse = scriptureIndex!.selectedVerse

        let index = testament + book + "\(chapter)" + "\(verse)"

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            if self.scriptureIndex!.sorted[index] == nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.disableBarButtons()
                    self.spinner.isHidden = false
                    self.spinner.startAnimating()
                    self.hideNumberAndTableUI()
                })
                
//                self.scriptureIndex?.byChapter[testament]?[book]?[chapter] = self.sortMediaItems(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book: book,chapter: chapter)
                self.scriptureIndex!.sorted[index] = true
            }

            self.mediaItems = nil
            
            // Need to add this
//            self.mediaItems = scriptureIndex?.byVerse[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]?[selectedVerse]
            
//            print(self.mediaItems)
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateUI()
                self.enableBarButtons()
            })
        })
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch component {
        case 0: // Testament
            if row == 0 {
                scriptureIndex?.selectedTestament = Constants.OT
            }
            
            if row == 1 {
                scriptureIndex?.selectedTestament = Constants.NT
            }
            
            if (scriptureIndex?.selectedTestament != nil) && bookSwitch.isOn {
                books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = books?[0]
            } else {
                scriptureIndex?.selectedBook = nil
            }

            updateSwitches()
            
            if chapterSwitch.isOn {
                chapters = scriptureIndex?.byChapter[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]?.keys.sorted()
                scriptureIndex?.selectedChapter = chapters![0]
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
                books = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
                scriptureIndex?.selectedBook = books?[row]
                
                updateSwitches()
                
                if chapterSwitch.isOn {
                    chapters = scriptureIndex?.byChapter[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]?.keys.sorted()
                    scriptureIndex?.selectedChapter = chapters![0]
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
                scriptureIndex?.selectedChapter = chapters![row]
                
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
                    selectedMediaItem = myCell.mediaItem //globals.activeMediaItems![index]
                    
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
    
    func sectionIndexTitlesForTableView(_ tableView: UITableView) -> [AnyObject]! {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = scriptureIndex?.selectedBook {
            return 0
        } else {
            return Constants.HEADER_HEIGHT
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let _ = scriptureIndex?.selectedBook {
            return nil
        } else {
            if sectionTitles != nil {
                if section < sectionTitles!.count {
                    return sectionTitles![section]
                }
            }
        }

        return nil
    }

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
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
            if let sectionTitle = sectionTitles?[section] {
                if let rows = sections?[sectionTitle] {
                    return rows.count
                }
            }
        }

        return 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell
        
        if let _ = scriptureIndex?.selectedBook {
            cell.mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                cell.mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }
        
        cell.vc = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        print("didSelectRowAtIndexPath")
        
        var mediaItem:MediaItem?
        
        if let _ = scriptureIndex?.selectedBook {
            mediaItem = mediaItems?[indexPath.row]
        } else {
            if let sectionTitle = sectionTitles?[indexPath.section] {
                mediaItem = sections?[sectionTitle]?[indexPath.row]
            }
        }

        print(mediaItem?.bcv)
        
        if (splitViewController != nil) && (splitViewController!.viewControllers.count > 1) {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController {
                if let viewController = navigationController.viewControllers[0] as? MediaViewController {
                    viewController.selectedMediaItem = mediaItem
                    splitViewController?.viewControllers[1] = navigationController
                }
            }
        } else {
            if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM) as? MediaViewController {
                viewController.selectedMediaItem = mediaItem
                
                self.navigationController?.navigationItem.hidesBackButton = false
                self.navigationController?.isToolbarHidden = true
                self.navigationController?.pushViewController(viewController, animated: true)
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

    func clearView()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.title = nil
            self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            for view in self.view.subviews {
                view.isHidden = true
            }
            self.logo.isHidden = false
        })
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
//    {
//        super.viewWillTransition(to: size, with: coordinator)
//        
//        if (self.view.window == nil) {
//            return
//        }
//        
//        //        print("Size: \(size)")
//        
//        setupSplitViewController()
//        
//        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
//        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        
        navigationItem.hidesBackButton = false
//        navigationController?.isToolbarHidden = true
    
        updateSwitches()

        if scriptureIndex == nil {
            buildScriptureIndex()
        } else {
            updateSearchResults()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        saveSettings()
        NotificationCenter.default.removeObserver(self)
    }
    
    func working()
    {
        progressIndicator.progress = progress / finished
        
//        print(progress)
//        print(finished)
        
        if progressIndicator.progress == 1.0 {
            timer?.invalidate()
            timer = nil
            progressIndicator.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back

//        navigationController?.navigationBar.backItem?.title = Constants.Back
//        navigationItem.hidesBackButton = false
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func setupMediaItemsScriptureBodyHTML(_ mediaItems:[MediaItem]?) -> String? {
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
        
        bodyString = "The following media "
        
        if mediaItems!.count > 1 {
            bodyString = bodyString! + "are"
        } else {
            bodyString = bodyString! + "is"
        }
        bodyString = bodyString! + " from <a href=\"\(Constants.CBC.MEDIA_WEBSITE)\">" + Constants.CBC.LONG + "</a><br/><br/>"
        
        if let category = globals.mediaCategory.selected {
            bodyString = bodyString! + "Category: \(category)<br/><br/>"
        }
        
        if (globals.tags.showing == Constants.TAGGED) {
            if let tag = globals.tags.selected {
                bodyString = bodyString! + "Collection: \(tag)<br/><br/>"
            }
        }
        
        if globals.searchActive {
            if (globals.searchText != nil) && (globals.searchText != Constants.EMPTY_STRING) {
                if let searchText = globals.searchText {
                    bodyString = bodyString! + "Search: \(searchText)<br/><br/>"
                }
            }
        }
        
        let books = bodyItems.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if books.count > 0 {
            for book in books {
                bodyString = bodyString! + book
                
                if let mediaItems = bodyItems[book] {
                    
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
                    
                    switch speakerCount {
                    case 1:
                        bodyString = bodyString! + " by \(speakers[0])<br/>"
                        break
                        
                    default:
                        bodyString = bodyString! + "<br/>"
                        break
                    }

                    for mediaItem in mediaItems {
                        bodyString = bodyString! + mediaItem.scripture!
                        
                        if let title = mediaItem.title {
                            if let websiteURL = mediaItem.websiteURL?.absoluteString {
                                bodyString = bodyString! + Constants.SINGLE_SPACE + "<a href=\"" + websiteURL + "\">\(title)</a>"
                            } else {
                                bodyString = bodyString! + Constants.SINGLE_SPACE + title
                            }
                        }
                        
                        if speakerCount > 1 {
                            if let speaker = mediaItem.speaker {
                                bodyString = bodyString! + " by \(speaker)"
                            }
                        }
                        
                        bodyString = bodyString! + "<br/>"
                    }
                }
                
                bodyString = bodyString! + "<br/>"
            }
        }
        
        bodyString = bodyString! + "<br/>"
        
        return bodyString
    }
    
    func mailMediaItems(_ mediaItems:[MediaItem]?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
        
        if let bodyString = setupMediaItemsScriptureBodyHTML(mediaItems) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }

    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, mediaItem:MediaItem?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingSection:
            dismiss(animated: true, completion: nil)
            let indexPath = IndexPath(row: 0, section: index)
            //Can't use this reliably w/ variable row heights.
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            })
            break
            
        case .selectingAction:
            switch strings[index] {
            case Constants.Email_All:
                mailMediaItems(mediaItems)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func actions()
    {
        //In case we have one already showing
        //        dismiss(animated: true, completion: nil)
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                //                popover.navigationItem.title = Constants.Actions
                
                popover.navigationController?.isNavigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingAction
                
                var actionMenu = [String]()
                
                actionMenu.append(Constants.Email_All)
                
                popover.strings = actionMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func index(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Menu.Index
                
                popover.delegate = self
                
                popover.purpose = .selectingSection

                popover.strings = sectionTitles
                popover.showIndex = false
                popover.showSectionHeaders = true

                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let indexButton = UIBarButtonItem(title: Constants.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureIndexViewController.index(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        navigationController?.toolbar.isTranslucent = false
        setToolbarItems([spaceButton,indexButton], animated: false)

        if let selectedTestament = scriptureIndex?.selectedTestament {
            let testament = translateTestament(selectedTestament)
            
            if books == nil {
                books = scriptureIndex?.byBook[testament]?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            }
            
//            print(books)
            
            if chapters == nil {
                if let book = scriptureIndex?.selectedBook {
                    chapters = scriptureIndex?.byChapter[testament]?[book]?.keys.sorted()
                }
            }
            
//            print(chapters)
        }
        
        hideAllUI()
        
        // Do any additional setup after loading the view.
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        navigationController?.setToolbarHidden(true, animated: true)
  
        numberOfMediaItemsLabel.isHidden = true
        numberOfMediaItems.text = Constants.EMPTY_STRING
        numberOfMediaItems.isHidden = true
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()

        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(ScriptureIndexViewController.actions)), animated: true)
    }
    
    func sortMediaItemsBook(_ mediaItems:[MediaItem]?) -> [MediaItem]?
    {
        var list:[MediaItem]?
        
        list = mediaItems?.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBCV   = first.booksAndChaptersAndVerses()
            let secondBCV  = second.booksAndChaptersAndVerses()
            
            let firstBooks = firstBCV?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            let secondBooks = secondBCV?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            
//            if (firstBooks?.count > 1) || (secondBooks?.count > 1) {
//                print("stop")
//            }
            
//            print("First Books: ",firstBooks)
//            print("Second Books: ",secondBooks)
            
            switch (firstBooks!.count,secondBooks!.count) {
            case (0,0):
                // Should never happen - neither has a book in the Scripture reference.
                return false
                
            default:
                for secondBook in secondBooks! {
//                    print("Second Book: ",secondBook)
                    for firstBook in firstBooks! {
//                        print("First Book: ",firstBook)
                        if bookNumberInBible(firstBook) == bookNumberInBible(secondBook) {
                            let firstChaps = first.chapters(firstBook)
                            let secondChaps = second.chapters(secondBook)
                            
                            if (firstChaps == nil) && (secondChaps == nil) {
                                if firstBooks?.count == secondBooks?.count {
                                    if first.fullDate!.isEqualTo(second.fullDate!) {
                                        return first.service < second.service
                                    } else {
                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                    }
                                } else {
                                    return firstBooks?.count < secondBooks?.count
                                }
                            }
                            if (firstChaps == nil) {
                                return true
                            }
                            if (secondChaps == nil) {
                                return false
                            }
                            
                            let firstChapters = firstBCV?[firstBook]?.keys.sorted()
                            let secondChapters = secondBCV?[secondBook]?.keys.sorted()

//                            print("First Chapters: ",firstChapters)
//                            print("Second Chapters: ",secondChapters)

                            if (firstChapters!.count > 0) && (secondChapters!.count > 0) {
                                for secondChapter in secondChapters! {
//                                    print("Second Chapter: ",secondChapter)
                                    for firstChapter in firstChapters! {
//                                        print("First Chapter: ",firstChapter)
                                        if firstChapter == secondChapter {
                                            let firstVerses = firstBCV?[firstBook]?[firstChapter]?.sorted()
                                            let secondVerses = secondBCV?[secondBook]?[secondChapter]?.sorted()
                                            
//                                            print("First Verses: ",firstVerses)
//                                            print("Second Verses: ",secondVerses)
                                            
                                            if (firstVerses!.count > 0) && (secondVerses!.count > 0) {
                                                for secondVerse in secondVerses! {
//                                                    print("Second Verse: ",secondVerse)
                                                    for firstVerse in firstVerses! {
//                                                        print("First Verse: ",firstVerse)
                                                        if firstVerse == secondVerse {
                                                            if firstVerses!.count == secondVerses!.count {
                                                                if first.fullDate!.isEqualTo(second.fullDate!) {
                                                                    return first.service < second.service
                                                                } else {
                                                                    return first.fullDate!.isOlderThan(second.fullDate!)
                                                                }
                                                            } else {
                                                                return firstVerses!.count < secondVerses!.count
                                                            }
                                                        } else {
                                                            return firstVerse < secondVerse
                                                        }
                                                    }
                                                }
                                                if firstVerses!.count == secondVerses!.count {
                                                    if first.fullDate!.isEqualTo(second.fullDate!) {
                                                        return first.service < second.service
                                                    } else {
                                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                                    }
                                                } else {
                                                    return firstVerses!.count < secondVerses!.count
                                                }
                                            } else {
                                                switch (firstVerses!.count,secondVerses!.count) {
                                                case (0,0):
                                                    if firstChapters!.count == secondChapters!.count {
                                                        if first.fullDate!.isEqualTo(second.fullDate!) {
                                                            return first.service < second.service
                                                        } else {
                                                            return first.fullDate!.isOlderThan(second.fullDate!)
                                                        }
                                                    } else {
                                                        return firstChapters!.count < secondChapters!.count
                                                    }
                                                    
                                                default:
                                                    if (firstVerses!.count == 0) {
                                                        return true
                                                    }
                                                    if (secondVerses!.count == 0) {
                                                        return false
                                                    }
                                                }
                                            }
                                        } else {
                                            return firstChapter < secondChapter
                                        }
                                    }
                                }
                                if firstChapters!.count == secondChapters!.count {
                                    if first.fullDate!.isEqualTo(second.fullDate!) {
                                        return first.service < second.service
                                    } else {
                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                    }
                                } else {
                                    return firstChapters!.count < secondChapters!.count
                                }
                            } else {
                                switch (firstChapters!.count,secondChapters!.count) {
                                case (0,0):
                                    if firstBooks!.count == secondBooks!.count {
                                        if first.fullDate!.isEqualTo(second.fullDate!) {
                                            return first.service < second.service
                                        } else {
                                            return first.fullDate!.isOlderThan(second.fullDate!)
                                        }
                                    } else {
                                        return firstBooks!.count < secondBooks!.count
                                    }
                                    
                                default:
                                    if firstChapters!.count == secondChapters!.count {
                                        if first.fullDate!.isEqualTo(second.fullDate!) {
                                            return first.service < second.service
                                        } else {
                                            return first.fullDate!.isOlderThan(second.fullDate!)
                                        }
                                    } else {
                                        return firstChapters!.count < secondChapters!.count
                                    }
                                }
                            }
                        } else {
                            return bookNumberInBible(firstBook) < bookNumberInBible(secondBook)
                        }
                    }
                }
                if firstBooks!.count == secondBooks!.count {
                    if first.fullDate!.isEqualTo(second.fullDate!) {
                        return first.service < second.service
                    } else {
                        return first.fullDate!.isOlderThan(second.fullDate!)
                    }
                } else {
                    return firstBooks!.count < secondBooks!.count
                }
            }
        })
        
//        for item in list! {
//            print(item.scripture!,item.bcv)
//        }
        return list
    }
    
    func sortMediaItemsChapter(_ mediaItems:[MediaItem]?,book:String) -> [MediaItem]?
    {
        var list:[MediaItem]?
        
        list = mediaItems?.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBCV   = first.booksAndChaptersAndVerses()
            let secondBCV  = second.booksAndChaptersAndVerses()
            
            let firstBooks = firstBCV?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            let secondBooks = secondBCV?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
            
//            if (firstBooks?.count > 1) || (secondBooks?.count > 1) {
//                print("stop")
//            }
            
            let firstChapters = firstBCV?[book]?.keys.sorted()
            let secondChapters = secondBCV?[book]?.keys.sorted()
            
            let firstChaps = first.chapters(book)
            let secondChaps = second.chapters(book)
            
            if (firstChaps == nil) && (secondChaps == nil) {
                if firstBooks?.count == secondBooks?.count {
                    if first.fullDate!.isEqualTo(second.fullDate!) {
                        return first.service < second.service
                    } else {
                        return first.fullDate!.isOlderThan(second.fullDate!)
                    }
                } else {
                    return firstBooks?.count < secondBooks?.count
                }
            }
            if (firstChaps == nil) {
                return true
            }
            if (secondChaps == nil) {
                return false
            }
            
//            print("First Chapters: ",firstChapters)
//            print("Second Chapters: ",secondChapters)
            
            switch (firstChapters!.count,secondChapters!.count) {
            case (0,0):
                if firstBooks!.count == secondBooks!.count {
                    return first.fullDate!.isOlderThan(second.fullDate!)
                } else {
                    return firstBooks!.count < secondBooks!.count
                }
                
            default:
                if (firstChapters!.count > 0) && (secondChapters!.count > 0) {
                    for secondChapter in secondChapters! {
                        for firstChapter in firstChapters! {
                            if firstChapter == secondChapter {
                                let firstVerses = firstBCV?[book]?[firstChapter]?.sorted()
                                let secondVerses = secondBCV?[book]?[secondChapter]?.sorted()
                                
                                //                            print("First Verses: ",firstVerses)
                                //                            print("Second Verses: ",secondVerses)
                                
                                if (firstVerses!.count > 0) && (secondVerses!.count > 0) {
                                    for secondVerse in secondVerses! {
                                        for firstVerse in firstVerses! {
                                            if firstVerse == secondVerse {
                                                if firstVerses!.count == secondVerses!.count {
                                                    if first.fullDate!.isEqualTo(second.fullDate!) {
                                                        return first.service < second.service
                                                    } else {
                                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                                    }
                                                } else {
                                                    return firstVerses!.count < secondVerses!.count
                                                }
                                            } else {
                                                return firstVerse < secondVerse
                                            }
                                        }
                                    }
                                    if firstVerses!.count == secondVerses!.count {
                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                    } else {
                                        return firstVerses!.count < secondVerses!.count
                                    }
                                } else {
                                    switch (firstVerses!.count,secondVerses!.count) {
                                    case (0,0):
                                        if firstChapters!.count == secondChapters!.count {
                                            if first.fullDate!.isEqualTo(second.fullDate!) {
                                                return first.service < second.service
                                            } else {
                                                return first.fullDate!.isOlderThan(second.fullDate!)
                                            }
                                        } else {
                                            return firstChapters!.count < secondChapters!.count
                                        }
                                        
                                    default:
                                        if (firstVerses!.count == 0) {
                                            return true
                                        }
                                        if (secondVerses!.count == 0) {
                                            return false
                                        }
                                    }
                                }
                            } else {
                                return firstChapter < secondChapter
                            }
                        }
                    }
                } else {
                    if firstChapters!.count == secondChapters!.count {
                        if first.fullDate!.isEqualTo(second.fullDate!) {
                            return first.service < second.service
                        } else {
                            return first.fullDate!.isOlderThan(second.fullDate!)
                        }
                    } else {
                        return firstChapters!.count < secondChapters!.count
                    }
                }
                if firstChapters!.count == secondChapters!.count {
                    if first.fullDate!.isEqualTo(second.fullDate!) {
                        return first.service < second.service
                    } else {
                        return first.fullDate!.isOlderThan(second.fullDate!)
                    }
                } else {
                    return firstChapters!.count < secondChapters!.count
                }
            }
        })
        
        return list
    }
    
    func sortMediaItemsVerse(_ mediaItems:[MediaItem]?,book:String,chapter:Int) -> [MediaItem]?
    {
        var list:[MediaItem]?
        
        list = mediaItems?.sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            let firstBCV   = first.booksAndChaptersAndVerses()
            let secondBCV  = second.booksAndChaptersAndVerses()
            
            let firstBooks = firstBCV?.keys.sorted()
            let secondBooks = secondBCV?.keys.sorted()
            
            let firstChapters = firstBCV?[book]?.keys.sorted()
            let secondChapters = secondBCV?[book]?.keys.sorted()
            
            let firstVerses = firstBCV?[book]?[chapter]?.sorted()
            let secondVerses = secondBCV?[book]?[chapter]?.sorted()
            
            let firstChaps = first.chapters(book)
            let secondChaps = second.chapters(book)
            
            if (firstChaps == nil) && (secondChaps == nil) {
                if firstBooks?.count == secondBooks?.count {
                    if first.fullDate!.isEqualTo(second.fullDate!) {
                        return first.service < second.service
                    } else {
                        return first.fullDate!.isOlderThan(second.fullDate!)
                    }
                } else {
                    return firstBooks?.count < secondBooks?.count
                }
            }
            if (firstChaps == nil) {
                return true
            }
            if (secondChaps == nil) {
                return false
            }

            if firstChapters?.first != secondChapters?.first {
                return firstChapters?.first < secondChapters?.first
            }
            
            switch (firstVerses!.count,secondVerses!.count) {
            case (0,0):
                if firstChapters!.count == secondChapters!.count {
                    return first.fullDate!.isOlderThan(second.fullDate!)
                } else {
                    return firstChapters!.count < secondChapters!.count
                }
                
            default:
                if (firstVerses!.count > 0) && (secondVerses!.count > 0) {
                    for secondVerse in secondVerses! {
                        for firstVerse in firstVerses! {
                            if firstVerse == secondVerse {
                                if firstVerses!.count == secondVerses!.count {
                                    if first.fullDate!.isEqualTo(second.fullDate!) {
                                        return first.service < second.service
                                    } else {
                                        return first.fullDate!.isOlderThan(second.fullDate!)
                                    }
                                } else {
                                    return firstVerses!.count < secondVerses!.count
                                }
                            } else {
                                return firstVerse < secondVerse
                            }
                        }
                    }
                    if firstVerses!.count == secondVerses!.count {
                        if first.fullDate!.isEqualTo(second.fullDate!) {
                            return first.service < second.service
                        } else {
                            return first.fullDate!.isOlderThan(second.fullDate!)
                        }
                    } else {
                        return firstVerses!.count < secondVerses!.count
                    }
                } else {
                    if (firstVerses!.count == 0) {
                        return true
                    }
                    if (secondVerses!.count == 0) {
                        return false
                    }
                    
                    return firstVerses!.count < secondVerses!.count
                }
            }
        })
        
        return list
    }
    
    func updateText()
    {
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
                    numberOfMediaItems.text = "\(mediaItems!.count) from chapter \(chapter) of \(book!) in the \(testament))"
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

    func showUI()
    {
        let state = false
        
        directionLabel.isHidden = state
        switchesLabel.isHidden = state
        
        bookLabel.isHidden = state
        bookSwitch.isHidden = state
        
        chapterLabel.isHidden = state
        chapterSwitch.isHidden = state
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        scripturePicker.isHidden = state
        tableView.isHidden = state
    }
    
    func hideAllUI()
    {
        let state = true
        
        directionLabel.isHidden = state
        switchesLabel.isHidden = state
        
        bookLabel.isHidden = state
        bookSwitch.isHidden = state
        
        chapterLabel.isHidden = state
        chapterSwitch.isHidden = state
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        scripturePicker.isHidden = state
        progressIndicator.isHidden = state
        
        hideNumberAndTableUI()
    }

    func hideNumberAndTableUI()
    {
        let state = true
        
        numberOfMediaItemsLabel.isHidden = state
        numberOfMediaItems.isHidden = state
        
        tableView.isHidden = state
    }
    
    func updatePicker()
    {
        scripturePicker.reloadAllComponents()
        
        //                print(selectedTestament)
        //                print(selectedBook)
        //                print(selectedChapter)
        
        if let selectedTestament = scriptureIndex?.selectedTestament {
            if let index = Constants.TESTAMENTS.index(of: selectedTestament) {
                scripturePicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            if let selectedBook = scriptureIndex?.selectedBook {
                if let index = books?.index(of: selectedBook) {
                    scripturePicker.selectRow(index, inComponent: 1, animated: false)
                }
            }
            
            if let selectedChapter = scriptureIndex?.selectedChapter {
                if selectedChapter > 0 {
                    if let index = chapters?.index(of: selectedChapter) {
                        scripturePicker.selectRow(index, inComponent: 2, animated: false)
                    }
                }
            }
            
            if let selectedVerse = scriptureIndex?.selectedVerse {
                if selectedVerse > 0 {
                    if let index = verses?.index(of: selectedVerse) {
                        scripturePicker.selectRow(index, inComponent: 3, animated: false)
                    }
                }
            }
        }
    }

    func updateSwitches()
    {
        bookSwitch.isOn = scriptureIndex?.selectedBook != nil
        bookSwitch.isEnabled = scriptureIndex != nil

        chapterSwitch.isOn = scriptureIndex?.selectedChapter > 0
        chapterSwitch.isEnabled = bookSwitch.isOn

        if let book = scriptureIndex?.selectedBook {
            if Constants.NO_CHAPTER_BOOKS.contains(book) {
                chapterSwitch.isOn = false
                chapterSwitch.isEnabled = false
            }
        }
    }
    
    func updateUI()
    {
        navigationController?.isToolbarHidden = scriptureIndex?.selectedBook != nil

        spinner.isHidden = true
        spinner.stopAnimating()
        progressIndicator.isHidden = true

        updateSwitches()
 
        showUI()
        
        updatePicker()
        
        updateDirectionLabel()
        
        updateText()
        
        tableView.reloadData()
    }

    func buildScriptureIndex()
    {
        guard (scriptureIndex == nil) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            self.scriptureIndex = ScriptureIndex()
            
            //                self.clearSettings()
            
            self.progress = 0
            self.finished = 0
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.progressIndicator.progress = 0
                self.progressIndicator.isHidden = false
                self.timer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.WORKING, target: self, selector: #selector(ScriptureIndexViewController.working), userInfo: nil, repeats: true)
            })
            
            if self.list != nil {
                self.finished += Float(self.list!.count)
                for mediaItem in self.list! {
                    //                    if (mediaItem.scripture?.rangeOfString(" and ") != nil) {
                    //                                            print(mediaItem.scripture!)
                    //                        print("STOP")
                    //                    }
                    let BCV = mediaItem.booksAndChaptersAndVerses()
                    if let books = BCV?.keys {
                        self.finished += Float(mediaItem.books!.count)
                        for book in books {
                            //                            print("\(mediaItem)")
                            if self.scriptureIndex?.byTestament[testament(book)] != nil {
                                if !self.scriptureIndex!.byTestament[testament(book)]!.contains(mediaItem) {
                                    self.scriptureIndex?.byTestament[testament(book)]?.append(mediaItem)
                                }
                            } else {
                                self.scriptureIndex?.byTestament[testament(book)] = [mediaItem]
                            }
                            
                            if self.scriptureIndex?.byBook[testament(book)] == nil {
                                self.scriptureIndex?.byBook[testament(book)] = [String:[MediaItem]]()
                            }
                            if self.scriptureIndex?.byBook[testament(book)]?[book] != nil {
                                if !self.scriptureIndex!.byBook[testament(book)]![book]!.contains(mediaItem) {
                                    self.scriptureIndex?.byBook[testament(book)]?[book]?.append(mediaItem)
                                }
                            } else {
                                self.scriptureIndex?.byBook[testament(book)]?[book] = [mediaItem]
                            }
                            
                            if let chapters = BCV?[book]?.keys {
                                self.finished += Float(chapters.count)
                                for chapter in chapters {
                                    //                                if (books.count > 1) {
                                    //                                    print("\(mediaItem.scripture!)")
                                    //                                    print("\(book)")
                                    //                                    print("\(mediaItem.chapters(book))")
                                    //                                    print("STOP")
                                    //                                }
                                    if self.scriptureIndex?.byChapter[testament(book)] == nil {
                                        self.scriptureIndex?.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self.scriptureIndex?.byChapter[testament(book)]?[book] == nil {
                                        self.scriptureIndex?.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
                                    }
                                    if self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] != nil {
                                        if !self.scriptureIndex!.byChapter[testament(book)]![book]![chapter]!.contains(mediaItem) {
                                            self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
                                        }
                                    } else {
                                        self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
                                    }
                                    
                                    if let verses = BCV?[book]?[chapter] {
                                        self.finished += Float(verses.count)
                                        for verse in verses {
                                            //                                if (books.count > 1) {
                                            //                                    print("\(mediaItem.scripture!)")
                                            //                                    print("\(book)")
                                            //                                    print("\(mediaItem.chapters(book))")
                                            //                                    print("STOP")
                                            //                                }
                                            if self.scriptureIndex?.byVerse[testament(book)] == nil {
                                                self.scriptureIndex?.byVerse[testament(book)] = [String:[Int:[Int:[MediaItem]]]]()
                                            }
                                            if self.scriptureIndex?.byVerse[testament(book)]?[book] == nil {
                                                self.scriptureIndex?.byVerse[testament(book)]?[book] = [Int:[Int:[MediaItem]]]()
                                            }
                                            if self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter] == nil {
                                                self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter] = [Int:[MediaItem]]()
                                            }
                                            if self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse] != nil {
                                                if !self.scriptureIndex!.byVerse[testament(book)]![book]![chapter]![verse]!.contains(mediaItem) {
                                                    self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse]?.append(mediaItem)
                                                }
                                            } else {
                                                self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse] = [mediaItem]
                                            }
                                            
                                            self.progress += 1
                                        }
                                    }
                                    
                                    self.progress += 1
                                }
                            }
                            
                            self.progress += 1
                        }
                    }
                    
                    self.progress += 1
                }
            }
            
//                print(self.scriptureIndex?.byTestament,"\n\n")
//                print(self.scriptureIndex?.byBook,"\n\n")
//                print(self.scriptureIndex?.byChapter,"\n\n")
//                print(self.scriptureIndex?.byVerse,"\n\n")
            
                // Sort
//                if self.scriptureIndex != nil {
//                    self.finished += Float(self.scriptureIndex!.byTestament.keys.count)
//                    
//                    for testament in self.scriptureIndex!.byTestament.keys {
//                        self.scriptureIndex?.byTestament[testament] = self.sortMediaItemsBook(self.scriptureIndex?.byTestament[testament])
//                        
//                        if self.scriptureIndex?.byBook[testament] != nil {
//                            self.finished += Float(self.scriptureIndex!.byBook[testament]!.keys.count)
//                            
//                            for book in self.scriptureIndex!.byBook[testament]!.keys {
//                                self.scriptureIndex?.byBook[testament]![book] = self.sortMediaItemsChapter(self.scriptureIndex?.byBook[testament]![book],book: book)
//                                
//                                if self.scriptureIndex?.byChapter[testament]?[book] != nil {
//                                    self.finished += Float(self.scriptureIndex!.byChapter[testament]![book]!.keys.count)
//                                    
//                                    for chapter in self.scriptureIndex!.byChapter[testament]![book]!.keys {
//                                        self.scriptureIndex?.byChapter[testament]![book]![chapter] = self.sortMediaItemsVerse(self.scriptureIndex?.byChapter[testament]![book]![chapter],book: book,chapter: chapter)
//                                        
//                                            if self.scriptureIndex?.byVerse[testament]?[book]?[chapter] != nil {
//                                                self.finished += Float(self.scriptureIndex!.byVerse[testament]![book]![chapter]!.keys.count)
//
//                                                for verse in self.scriptureIndex!.byVerse[testament]![book]![chapter]!.keys {
//                                                    self.scriptureIndex?.byVerse[testament]?[book]?[chapter]?[verse] = self.sortMediaItemsVerse(self.scriptureIndex?.byVerse[testament]?[book]?[chapter]?[verse],book: book,chapter: chapter)
//                                                    
//                                                    self.progress += 1
//                                                }
//                                            }
//                                        self.progress += 1
//                                    }
//                                }
//                                self.progress += 1
//                            }
//                        }
//                        self.progress += 1
//                    }
//                }

//                print(self.scriptureIndex?.byTestament,"\n\n")
//                print(self.scriptureIndex?.byBook,"\n\n")
//                print(self.scriptureIndex?.byChapter,"\n\n")
//                print(self.scriptureIndex?.byVerse,"\n\n")

            self.updateSearchResults()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
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
