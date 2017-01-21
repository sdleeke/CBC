//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit
import MessageUI


//struct ScripturePicker {
//    var books:[String]?
//    var chapters:[Int]?
//    var verses:[Int]?
//}

class ScriptureIndexViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate, MFMailComposeViewControllerDelegate, XMLParserDelegate, PopoverTableViewControllerDelegate {
    var finished:Float = 0.0
    var progress:Float = 0.0 {
        didSet {
            //            print(progress)
            //            print(finished)

            DispatchQueue.main.async(execute: { () -> Void in
                if self.finished != 0 {
                    self.progressIndicator.progress = self.progress / self.finished
                }
                if self.progressIndicator.progress == 1.0 {
                    self.progressIndicator.isHidden = true
                }
            })
        }
    }

    lazy var scripture:Scripture? = {
        return Scripture(reference: nil)
        }()
    
    var mediaListGroupSort:MediaListGroupSort? {
        didSet {
//            scriptureIndex?.active = true
        }
    }
    
    var scriptureIndex:ScriptureIndex? {
        get {
            return mediaListGroupSort?.scriptureIndex
        }
//        set {
//            mediaListGroupSort?.scriptureIndex = newValue
////            scriptureIndex?.active = true
//        }
    }
    
//    var list:[MediaItem]? {
//        get {
//            return mediaListGroupSort?.list
//        }
//    }
    
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
    
    var sections:[String:[MediaItem]]?
    {
        get {
            return scriptureIndex?.sections
        }
        set {
            scriptureIndex?.sections = newValue
        }
    }

    var sectionTitles:[String]? {
        get {
            return sections?.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        }
    }
    
    var mediaItems:[MediaItem]?
    {
        didSet {
            if sections == nil {
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
                if let book = scripture?.picker.books?[row] {
                    if book == "Psalm" {
                        return "Psalms"
                    } else {
                        return book
                    }
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
//        scriptureText = nil
        
        scripture?.selected.testament   = scriptureIndex?.selectedTestament
        scripture?.selected.book        = scriptureIndex?.selectedBook
        scripture?.selected.chapter     = scriptureIndex!.selectedChapter
        scripture?.selected.verse       = scriptureIndex!.selectedVerse
        
        guard (scriptureIndex?.selectedTestament != nil) else {
            mediaItems = nil
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.updateUI()
            })
            return
        }

        guard (scriptureIndex?.selectedBook != nil) else {
            var testament:String!
            
            if let selectedTestament = scriptureIndex?.selectedTestament {
                testament = translateTestament(selectedTestament)
            }

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if self.scriptureIndex!.sorted[testament] == nil {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.isHiddenNumberAndTableUI(true)
                    })

                    self.scriptureIndex?.byTestament[testament] = self.sortMediaItems(self.scriptureIndex?.byTestament[testament],book:nil) // self.sortMediaItemsBook(self.scriptureIndex?.byTestament[testament])
                    self.scriptureIndex!.sorted[testament] = true
                    
                    self.mediaItems = self.scriptureIndex?.byTestament[testament]
                    
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                } else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.isHiddenNumberAndTableUI(true)
                    })
                    
                    self.mediaItems = self.scriptureIndex?.byTestament[testament]
                    
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                }
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
                        self.isHiddenNumberAndTableUI(true)
                    })
                    
                    self.scriptureIndex?.byBook[testament]?[book] = self.sortMediaItems(self.scriptureIndex?.byBook[testament]?[book],book:book) // self.sortMediaItemsChapter(self.scriptureIndex?.byBook[testament]?[book],book: book)
                    self.scriptureIndex!.sorted[index] = true
                    
                    self.mediaItems = self.scriptureIndex?.byBook[testament]?[book]
                    
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                } else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.isHiddenNumberAndTableUI(true)
                    })
                    
                    self.mediaItems = self.scriptureIndex?.byBook[testament]?[book]
                    
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                }
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
                        self.isHiddenNumberAndTableUI(true)
                    })

                    self.scriptureIndex?.byChapter[testament]?[book]?[chapter] = self.sortMediaItems(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book:book) // self.sortMediaItemsVerse(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book: book,chapter: chapter)
                    self.scriptureIndex!.sorted[index] = true

                    self.mediaItems = self.scriptureIndex?.byChapter[testament]?[book]?[chapter]
                    
                    //            print(scriptureIndex!.selectedTestament,scriptureIndex!.selectedBook,scriptureIndex!.selectedChapter)
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                } else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.disableBarButtons()
                        self.spinner.isHidden = false
                        self.spinner.startAnimating()
                        self.isHiddenNumberAndTableUI(true)
                    })
                    
                    self.mediaItems = self.scriptureIndex?.byChapter[testament]?[book]?[chapter]
                    
                    //            print(scriptureIndex!.selectedTestament,scriptureIndex!.selectedBook,scriptureIndex!.selectedChapter)
                    //            print(mediaItems)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.enableBarButtons()
                        self.updateUI()
                    })
                }
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
                    self.isHiddenNumberAndTableUI(true)
                })
                
//                self.scriptureIndex?.byChapter[testament]?[book]?[chapter] = self.sortMediaItems(self.scriptureIndex?.byChapter[testament]?[book]?[chapter],book: book,chapter: chapter)
                self.scriptureIndex!.sorted[index] = true
                
                self.mediaItems = nil
                
                // Need to add this
                //            self.mediaItems = scriptureIndex?.byVerse[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]?[selectedVerse]
                
                //            print(self.mediaItems)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.enableBarButtons()
                    self.updateUI()
                })
            } else {
                self.mediaItems = nil
                
                // Need to add this
                //            self.mediaItems = scriptureIndex?.byVerse[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]?[selectedVerse]
                
                //            print(self.mediaItems)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.enableBarButtons()
                    self.updateUI()
                })
            }
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
            if let sectionTitle = sectionTitles?[section], let rows = sections?[sectionTitle] {
                return rows.count
            }
        }

        return 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell
        
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

        print(mediaItem?.booksChaptersVerses?.data as Any)
        
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

//    func clearView()
//    {
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.navigationItem.title = nil
//            self.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//            for view in self.view.subviews {
//                view.isHidden = true
//            }
//            self.logo.isHidden = false
//        })
//    }
    
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
        
//        DispatchQueue.main.async {
//            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
//        }
        
        navigationItem.hidesBackButton = false
        
        navigationController?.setToolbarHidden(true, animated: false)

//        navigationController?.isToolbarHidden = true
    
        updateSwitches()

        scriptureIndex?.build()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        saveSettings()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: scriptureIndex)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_UPDATED), object: scriptureIndex)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: scriptureIndex)

//        NotificationCenter.default.removeObserver(self)
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
        
        if globals.search.lexicon {
            bodyString = bodyString! + "Lexicon Mode<br/>"
        }
        
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

        bodyString = bodyString! + "Total: \(mediaItems!.count)<br/><br/>"

        let books = bodyItems.keys.sorted() { bookNumberInBible($0) < bookNumberInBible($1) }
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString! + "<a href=\"#index\">Index</a><br/><br/>"
        }
        
        if includeColumns {
            bodyString  = bodyString! + "<table>"
        }
        
        for book in books {
            if includeColumns {
                bodyString  = bodyString! + "<tr>"
                bodyString  = bodyString! + "<td valign=\"top\" colspan=\"6\">"
            }

            if let mediaItems = bodyItems[book] {
                if includeURLs && (books.count > 1) {
                    let tag = book.replacingOccurrences(of: " ", with: "")
                    bodyString = bodyString! + "<a id=\"\(tag)\" name=\"\(tag)\" href=\"#index\">" + book + " (\(mediaItems.count))" + "</a>"
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
                    
                    if let string = mediaItem.bodyHTML(order: order, includeURLs: includeURLs, includeColumns: includeColumns) {
                        bodyString = bodyString! + string
                    }
                    
                    if !includeColumns {
                        bodyString = bodyString! + "<br/>"
                    }
                }
                
                if includeColumns {
                    bodyString  = bodyString! + "<tr>"
                    bodyString  = bodyString! + "<td valign=\"top\" colspan=\"6\">"
                }
                
                bodyString = bodyString! + "<br/>"
                
                if includeColumns {
                    bodyString  = bodyString! + "</td>"
                    bodyString  = bodyString! + "</tr>"
                }
            }
        }
        
        if includeColumns {
            bodyString  = bodyString! + "</table>"
        }
        
        bodyString = bodyString! + "<br/>"
        
        if includeURLs, (books.count > 1) {
            bodyString = bodyString! + "<div><a id=\"index\" name=\"index\" href=\"#top\">Index</a><br/><br/>"
            
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

//    var xmlParser:XMLParser?
//    var xmlString:String?
//
//    lazy var scripture:CachedString? = {
//        return CachedString(index: nil)
//    }()
//    
//    var scriptureReference:String? {
//        get {
//            guard scriptureIndex?.selectedTestament != nil else {
//                return nil
//            }
//            
//            var reference:String?
//            
//            if let selectedBook = scriptureIndex?.selectedBook {
//                reference = selectedBook
//            }
//            
//            if reference != nil, let selectedChapter = scriptureIndex?.selectedChapter, selectedChapter > 0 {
//                reference = reference! + " \(selectedChapter)"
//            }
//            
//            if reference != nil, let selectedVerse = scriptureIndex?.selectedVerse, selectedVerse > 0 {
//                reference = reference! + ":\(selectedVerse)"
//            }
//            
//            return reference
//        }
//    }
//    
//    var scriptureText:ScriptureText?
//    
//    var book:String?
//    var chapter:String?
//    var verse:String?
//    
//    func parserDidStartDocument(_ parser: XMLParser) {
//        
//    }
//    
//    func parserDidEndDocument(_ parser: XMLParser) {
//        
//    }
//    
//    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
//        print(parseError.localizedDescription)
//    }
//    
//    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
//        
//        //        print(elementName)
//    }
//    
//    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        //        print(elementName)
//        
//        if scriptureText == nil {
//            scriptureText = [String:[String:[String:String]]]()
//        }
//        
//        switch elementName {
//        case "bookname":
//            book = xmlString
//            
//            if scriptureText?[book!] == nil {
//                scriptureText?[book!] = [String:[String:String]]()
//            }
//            break
//            
//        case "chapter":
//            chapter = xmlString
//            
//            if scriptureText?[book!]?[chapter!] == nil {
//                scriptureText?[book!]?[chapter!] = [String:String]()
//            }
//            break
//            
//        case "verse":
//            verse = xmlString
//            break
//            
//        case "text":
//            scriptureText?[book!]?[chapter!]?[verse!] = xmlString
//            //            print(scriptureText)
//            break
//            
//        default:
//            break
//        }
//        
//        xmlString = nil
//    }
//    
//    func parser(_ parser: XMLParser, foundElementDeclarationWithName elementName: String, model: String) {
//        //        print(elementName)
//    }
//    
//    func parser(_ parser: XMLParser, foundCharacters string: String) {
//        //        print(string)
//        xmlString = (xmlString != nil ? xmlString! + string : string).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//    }
//    
//    var scriptureTextHTML:String? {
//        get {
//            return scriptureTextToHTML(scriptureReference:scriptureReference,scriptureText:scriptureText)
//        }
//    }
//    
//    func loadScriptureText()
//    {
//        guard xmlParser == nil else {
//            return
//        }
//        
//        guard scriptureText == nil else {
//            return
//        }
//        
//        if let scripture = scriptureReference?.replacingOccurrences(of: "Psalm", with: "Psalms") {
//            let urlString = "https://api.preachingcentral.com/bible.php?passage=\(scripture)&version=nasb".replacingOccurrences(of: " ", with: "%20")
//            
//            if let url = URL(string: urlString) {
//                self.xmlParser = XMLParser(contentsOf: url)
//                
//                self.xmlParser?.delegate = self
//                
//                if let success = self.xmlParser?.parse(), success {
//                    xmlParser = nil
//                }
//            }
//        }
//    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, mediaItem:MediaItem?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
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
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            })
            break
            
        case .selectingAction:
            switch strings[index] {
            case Constants.View_List:
                process(viewController: self, work: { () -> (Any?) in
                    if self.scriptureIndex?.html?.string == nil {
                        self.scriptureIndex?.html?.string = self.setupMediaItemsHTMLScripture(self.mediaItems, includeURLs: true, includeColumns: true)
                    }

                    return self.scriptureIndex?.html?.string
                }, completion: { (data:Any?) in
                    presentHTMLModal(viewController: self, medaiItem: nil, title: globals.contextTitle, htmlString: data as? String)
                })
                break
                
            case Constants.View_Scripture:
                if let reference = scripture?.selected.reference {
                    if scripture?.html?[reference] != nil {
                        popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:self.navigationItem.rightBarButtonItem,sourceView:nil,sourceRectView:nil,htmlString:scripture?.html?[reference])
                    } else {
                        process(viewController: self, work: { () -> (Any?) in
                            self.scripture?.load(reference)
                            return self.scripture?.html?[reference]
                        }, completion: { (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:self.navigationItem.rightBarButtonItem,sourceView:nil,sourceRectView:nil,htmlString:htmlString)
                            } else {
                                networkUnavailable("Scripture text unavailable.")
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
    
    func actionMenuItems() -> [String]?
    {
        var actionMenu = [String]()
        
        if mediaItems?.count > 0 {
            actionMenu.append(Constants.View_List)
        }
        
        if let scriptureReference = scripture?.selected.reference, scriptureReference != scriptureIndex?.selectedBook {
            actionMenu.append(Constants.View_Scripture)
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
            
            popover.strings = actionMenuItems()
            
            popover.showIndex = false //(globals.grouping == .series)
            popover.showSectionHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection

            popover.strings = sectionTitles
            popover.showIndex = false
            popover.showSectionHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.started), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_STARTED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.updated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_UPDATED), object: self.scriptureIndex)
            NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.completed), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SCRIPTURE_INDEX_COMPLETED), object: self.scriptureIndex)
        }

        let indexButton = UIBarButtonItem(title: Constants.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(ScriptureIndexViewController.index(_:)))
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
        
        isHiddenUI(true)
        progressIndicator.isHidden = true

//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
  
        numberOfMediaItems.text = Constants.EMPTY_STRING
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()

        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(ScriptureIndexViewController.actions)), animated: true) //
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
    
    func updateUI()
    {
        navigationController?.toolbar.items?[1].isEnabled = mediaItems?.count > 0
        
        navigationController?.setToolbarHidden(scriptureIndex?.selectedBook != nil, animated: true)
        
//        navigationController?.isToolbarHidden =
        
        spinner.isHidden = true
        spinner.stopAnimating()
        progressIndicator.isHidden = true

        updateSwitches()
 
        updateActionMenu()
        
        isHiddenUI(false)
        progressIndicator.isHidden = true

        updatePicker()
        
        updateDirectionLabel()
        
        updateText()
        
        tableView.reloadData()
    }

//    func buildScriptureIndex()
//    {
//        guard (scriptureIndex == nil) else {
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//            self.scriptureIndex = ScriptureIndex()
//            
//            //                self.clearSettings()
//            
//            self.progress = 0
//            self.finished = 0
//            
//            DispatchQueue.main.async(execute: { () -> Void in
//                self.disableBarButtons()
//                
//                self.spinner.isHidden = false
//                self.spinner.startAnimating()
//
//                self.progressIndicator.progress = 0
//                self.progressIndicator.isHidden = false
//            })
//            
//            if self.list != nil {
//                self.finished += Float(self.list!.count)
//                for mediaItem in self.list! {
//                    let booksChaptersVerses = mediaItem.booksAndChaptersAndVerses()
//                    if let books = booksChaptersVerses?.data?.keys {
//                        self.finished += Float(mediaItem.books!.count)
//                        for book in books {
////                            print("\(mediaItem)")
//                            if self.scriptureIndex?.byTestament[testament(book)] != nil {
//                                if !self.scriptureIndex!.byTestament[testament(book)]!.contains(mediaItem) {
//                                    self.scriptureIndex?.byTestament[testament(book)]?.append(mediaItem)
//                                }
//                            } else {
//                                self.scriptureIndex?.byTestament[testament(book)] = [mediaItem]
//                            }
//                            
//                            if self.scriptureIndex?.byBook[testament(book)] == nil {
//                                self.scriptureIndex?.byBook[testament(book)] = [String:[MediaItem]]()
//                            }
//                            if self.scriptureIndex?.byBook[testament(book)]?[book] != nil {
//                                if !self.scriptureIndex!.byBook[testament(book)]![book]!.contains(mediaItem) {
//                                    self.scriptureIndex?.byBook[testament(book)]?[book]?.append(mediaItem)
//                                }
//                            } else {
//                                self.scriptureIndex?.byBook[testament(book)]?[book] = [mediaItem]
//                            }
//                            
//                            if let chapters = booksChaptersVerses?[book]?.keys {
//                                self.finished += Float(chapters.count)
//                                for chapter in chapters {
//                                    if self.scriptureIndex?.byChapter[testament(book)] == nil {
//                                        self.scriptureIndex?.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
//                                    }
//                                    if self.scriptureIndex?.byChapter[testament(book)]?[book] == nil {
//                                        self.scriptureIndex?.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
//                                    }
//                                    if self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] != nil {
//                                        if !self.scriptureIndex!.byChapter[testament(book)]![book]![chapter]!.contains(mediaItem) {
//                                            self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
//                                        }
//                                    } else {
//                                        self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
//                                    }
//                                    
//                                    if let verses = booksChaptersVerses?[book]?[chapter] {
//                                        self.finished += Float(verses.count)
//                                        for verse in verses {
//                                            if self.scriptureIndex?.byVerse[testament(book)] == nil {
//                                                self.scriptureIndex?.byVerse[testament(book)] = [String:[Int:[Int:[MediaItem]]]]()
//                                            }
//                                            if self.scriptureIndex?.byVerse[testament(book)]?[book] == nil {
//                                                self.scriptureIndex?.byVerse[testament(book)]?[book] = [Int:[Int:[MediaItem]]]()
//                                            }
//                                            if self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter] == nil {
//                                                self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter] = [Int:[MediaItem]]()
//                                            }
//                                            if self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse] != nil {
//                                                if !self.scriptureIndex!.byVerse[testament(book)]![book]![chapter]![verse]!.contains(mediaItem) {
//                                                    self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse]?.append(mediaItem)
//                                                }
//                                            } else {
//                                                self.scriptureIndex?.byVerse[testament(book)]?[book]?[chapter]?[verse] = [mediaItem]
//                                            }
//                                            
//                                            self.progress += 1
//                                        }
//                                    }
//                                    
//                                    self.progress += 1
//                                }
//                            }
//                            
//                            self.progress += 1
//                        }
//                    }
//                    
//                    self.progress += 1
//                }
//            }
//            
//            self.updateSearchResults()
//        })
//    }
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return false
        }
        
        guard let mediaItem = cell.mediaItem else {
            return false
        }
        
        return mediaItem.hasNotesHTML || (mediaItem.scriptureReference != Constants.Selected_Scriptures)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        
        guard let mediaItem = cell.mediaItem else {
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
                
                if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                    htmlString = mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
                } else {
                    htmlString = mediaItem.fullNotesHTML
                }
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                        return mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
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
        
        if mediaItem.scriptureReference != Constants.Selected_Scriptures {
            actions.append(scripture)
        }
        
        if mediaItem.hasNotesHTML {
            actions.append(transcript)
        }
        
        return actions
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
