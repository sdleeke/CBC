//
//  ScriptureIndexViewController.swift
//  GTY
//
//  Created by Steve Leeke on 3/5/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class ScriptureIndex {
    //Test
    var byTestament = [String:[MediaItem]]()
    
    //Test  //Book
    var byBook = [String:[String:[MediaItem]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[MediaItem]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[MediaItem]]]]]()

    var selectedTestament:String? = Constants.OT
//    {
//        get {
//            if let testament = UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.TESTAMENT) {
//                return testament
//            } else {
//                return Constants.OT
//            }
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.TESTAMENT)
//            UserDefaults.standard.synchronize()
//        }
//    }
    
    var selectedBook:String?
//    {
//        get {
//            return UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.BOOK)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.BOOK)
//            UserDefaults.standard.synchronize()
//        }
//    }
    
    var selectedChapter:Int = 0
//    {
//        get {
//            return UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//            UserDefaults.standard.synchronize()
//        }
//    }
    
    var selectedVerse:Int = 0
//    {
//        get {
//            return UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.VERSE)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.VERSE)
//            UserDefaults.standard.synchronize()
//        }
//    }
}

class ScriptureIndexViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var finished:Float = 0.0
    var progress:Float = 0.0
    
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
            chapterSwitch.isEnabled = true
            
            switch scriptureIndex!.selectedTestament! {
            case Constants.OT:
                scriptureIndex?.selectedBook = Constants.OLD_TESTAMENT_BOOKS[0]
                break
                
            case Constants.NT:
                scriptureIndex?.selectedBook = Constants.NEW_TESTAMENT_BOOKS[0]
                break
                
            default:
                break
            }
        } else {
            chapterSwitch.isOn = false
            chapterSwitch.isEnabled = false
            scriptureIndex?.selectedBook = nil
        }

        updateDirectionLabel()
        
        updateSearchResults()
        
        scripturePicker.reloadAllComponents()
        tableView.reloadData()
    }
    
    @IBOutlet weak var chapterLabel: UILabel!
    @IBOutlet weak var chapterSwitch: UISwitch!
    
    @IBAction func chapterSwitchAction(_ sender: UISwitch) {
        if chapterSwitch.isOn {
            updateDirectionLabel()
            
            switch scriptureIndex!.selectedTestament! {
            case Constants.OT:
                scriptureIndex?.selectedChapter = 1 // Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                break
                
            case Constants.NT:
                scriptureIndex?.selectedChapter = 1 // Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                break
                
            default:
                break
            }
        } else {
            scriptureIndex?.selectedChapter = 0
        }
        
        updateDirectionLabel()
        
        updateSearchResults()
        
        scripturePicker.reloadAllComponents()
        tableView.reloadData()
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
//    var selectedTestament:String? {
//        get {
//            if let testament = UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.TESTAMENT) {
//                return testament
//            } else {
//                return Constants.OT
//            }
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.TESTAMENT)
//            UserDefaults.standard.synchronize()
//        }
//    }
//    
//    var selectedBook:String? {
//        get {
//            return UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.BOOK)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.BOOK)
//            UserDefaults.standard.synchronize()
//        }
//    }
//
//    var selectedChapter:Int {
//        get {
//            return UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//            UserDefaults.standard.synchronize()
//        }
//    }
//
//    var selectedVerse:Int {
//        get {
//            return UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.VERSE)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: Constants.SCRIPTURE_INDEX.VERSE)
//            UserDefaults.standard.synchronize()
//        }
//    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var mediaItems:[MediaItem]?
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
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    numberOfRows = Constants.OLD_TESTAMENT_BOOKS.count
                    break
                    
                case Constants.NT:
                    numberOfRows = Constants.NEW_TESTAMENT_BOOKS.count
                    break
                    
                default:
                    break
                }
            } else {
                numberOfRows = 0 // number of books in testament
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) {
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    if (scriptureIndex?.selectedBook != nil) {
                        if chapterSwitch.isOn {
                            if (Constants.OLD_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!) != nil) {
                                numberOfRows = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!)!]
                            } else {
                                numberOfRows = 0 // number of chapters in book
                            }
                        } else {
                            numberOfRows = 0 // number of chapters in book
                        }
                    } else {
                        numberOfRows = 0 // number of chapters in book
                    }
                    break
                    
                case Constants.NT:
                    if (scriptureIndex?.selectedBook != nil) {
                        if chapterSwitch.isOn {
                            if (Constants.NEW_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!) != nil) {
                                numberOfRows = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!)!]
                            } else {
                                numberOfRows = 0 // number of chapters in book
                            }
                        } else {
                            numberOfRows = 0 // number of chapters in book
                        }
                    } else {
                        numberOfRows = 0 // number of chapters in book
                    }
                    break
                    
                default:
                    numberOfRows = 0 // number of chapters in book
                    break
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
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 50
            
        case 1:
            return 200
            
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
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    if row < Constants.OLD_TESTAMENT_BOOKS.count {
                        return Constants.OLD_TESTAMENT_BOOKS[row]
                    }
                    
                case Constants.NT:
                    if row < Constants.NEW_TESTAMENT_BOOKS.count {
                        return Constants.NEW_TESTAMENT_BOOKS[row]
                    }
                    
                default:
                    break
                }
            }
            break
            
        case 2:
            if (scriptureIndex?.selectedTestament != nil) {
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    if scriptureIndex?.selectedBook != nil {
                        let chapters = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!)!]
                        if row < chapters {
                            return "\(row+1)"
                        }
                    }
                    break
                    
                case Constants.NT:
                    if scriptureIndex?.selectedBook != nil {
                        let chapters = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.index(of: scriptureIndex!.selectedBook!)!]
                        if row < chapters {
                            return "\(row+1)"
                        }
                    }
                    break
                    
                default:
                    break
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return title(forRow: row,forComponent: component)
    }
    
    func updateSearchResults()
    {
        if (scriptureIndex?.selectedTestament != nil) {
            if (scriptureIndex?.selectedBook != nil) {
                if (scriptureIndex?.selectedChapter > 0) {
                    if (scriptureIndex?.selectedVerse > 0) {
                        mediaItems = nil // Need to add this
//                        mediaItems = scriptureIndex?.byChapter[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]?[selectedVerse]
                        if mediaItems != nil {
                            numberOfMediaItems.text = "\(mediaItems!.count) from verse \(scriptureIndex!.selectedVerse) in chapter \(scriptureIndex!.selectedChapter) of \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                        } else {
                            numberOfMediaItems.text = "0 from verse \(scriptureIndex!.selectedVerse) in chapter \(scriptureIndex!.selectedChapter) of \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                        }
                    } else {
                        mediaItems = scriptureIndex?.byChapter[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]?[scriptureIndex!.selectedChapter]
                        if mediaItems != nil {
                            numberOfMediaItems.text = "\(mediaItems!.count) from chapter \(scriptureIndex!.selectedChapter) of \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                        } else {
                            numberOfMediaItems.text = "0 from chapter \(scriptureIndex!.selectedChapter) of \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                        }
                    }
                } else {
                    mediaItems = scriptureIndex?.byBook[translateTestament(scriptureIndex!.selectedTestament!)]?[scriptureIndex!.selectedBook!]
                    if mediaItems != nil {
                        numberOfMediaItems.text = "\(mediaItems!.count) from \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                    } else {
                        numberOfMediaItems.text = "0 from \(scriptureIndex!.selectedBook!) in the \(translateTestament(scriptureIndex!.selectedTestament!))"
                    }
                }
            } else {
                mediaItems = scriptureIndex?.byTestament[translateTestament(scriptureIndex!.selectedTestament!)]
                if mediaItems != nil {
                    numberOfMediaItems.text = "\(mediaItems!.count) from the \(translateTestament(scriptureIndex!.selectedTestament!))"
                } else {
                    numberOfMediaItems.text = "0 from the \(translateTestament(scriptureIndex!.selectedTestament!))"
                }
            }
        } else {
            numberOfMediaItems.text = "0"
        }
        
//        NSLog("\(mediaItems)")

        tableView.reloadData()
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
            
            if bookSwitch.isOn && (scriptureIndex?.selectedTestament != nil) {
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    scriptureIndex?.selectedBook = Constants.OLD_TESTAMENT_BOOKS[0]
                    break
                    
                case Constants.NT:
                    scriptureIndex?.selectedBook = Constants.NEW_TESTAMENT_BOOKS[0]
                    break
                    
                default:
                    break
                }
            } else {
                scriptureIndex?.selectedBook = nil
            }
            
            if chapterSwitch.isOn {
                scriptureIndex?.selectedChapter = 1
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
                switch scriptureIndex!.selectedTestament! {
                case Constants.OT:
                    scriptureIndex?.selectedBook = Constants.OLD_TESTAMENT_BOOKS[row]
                    break
                    
                case Constants.NT:
                    scriptureIndex?.selectedBook = Constants.NEW_TESTAMENT_BOOKS[row]
                    break
                    
                default:
                    break
                }
                
                if chapterSwitch.isOn {
                    scriptureIndex?.selectedChapter = 1
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
                scriptureIndex?.selectedChapter = row + 1
                
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
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return mediaItems != nil ? mediaItems!.count : 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.INDEX_MEDIA_ITEM, for: indexPath) as! MediaTableViewCell
        
        cell.mediaItem = mediaItems?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        NSLog("didSelectRowAtIndexPath")
        if (splitViewController != nil) && (splitViewController!.viewControllers.count > 1) {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM_NAVCON) as? UINavigationController {
                if let viewController = navigationController.viewControllers[0] as? MediaViewController {
                    viewController.selectedMediaItem = mediaItems?[indexPath.row]
                    splitViewController?.viewControllers[1] = navigationController
                }
            }
        } else {
            if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SHOW_MEDIAITEM) as? MediaViewController {
                viewController.selectedMediaItem = mediaItems?[indexPath.row]
                
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
    
//    func setupSplitViewController()
//    {
//        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
//            if (globals.media.all == nil) {
//                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
//            } else {
//                if (splitViewController != nil) {
//                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
//                        if let _ = nvc.visibleViewController as? ScriptureIndexViewController {
//                            splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
//                        } else {
//                            splitViewController?.preferredDisplayMode = .automatic //iPad only
//                        }
//                    }
//                }
//            }
//        } else {
//            if (splitViewController != nil) {
//                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
//                    if let _ = nvc.visibleViewController as? ScriptureIndexViewController {
//                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
//                    } else {
//                        splitViewController?.preferredDisplayMode = .automatic //iPad only
//                    }
//                }
//            }
//        }
//    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
//    {
//        super.viewWillTransition(to: size, with: coordinator)
//        
//        if (self.view.window == nil) {
//            return
//        }
//        
//        //        NSLog("Size: \(size)")
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
        self.navigationController?.isToolbarHidden = true
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

//    func loadSettings()
//    {
//        selectedTestament = UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.TESTAMENT)
//        
//        if selectedTestament == nil {
//            selectedTestament = Constants.OT
//        }
//
//        selectedBook        = UserDefaults.standard.string(forKey: Constants.SCRIPTURE_INDEX.BOOK)
//        selectedChapter     = UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//        selectedVerse       = UserDefaults.standard.integer(forKey: Constants.SCRIPTURE_INDEX.VERSE)
//    }
    
//    func saveSettings()
//    {
//        UserDefaults.standard.set(selectedTestament,    forKey: Constants.SCRIPTURE_INDEX.TESTAMENT)
//        UserDefaults.standard.set(selectedBook,         forKey: Constants.SCRIPTURE_INDEX.BOOK)
//        UserDefaults.standard.set(selectedChapter,      forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//        UserDefaults.standard.set(selectedVerse,        forKey: Constants.SCRIPTURE_INDEX.VERSE)
//        
//        UserDefaults.standard.synchronize()
//    }
    
//    func clearSettings()
//    {
//        UserDefaults.standard.removeObject(forKey: Constants.SCRIPTURE_INDEX.TESTAMENT)
//        UserDefaults.standard.removeObject(forKey: Constants.SCRIPTURE_INDEX.BOOK)
//        UserDefaults.standard.removeObject(forKey: Constants.SCRIPTURE_INDEX.CHAPTER)
//        UserDefaults.standard.removeObject(forKey: Constants.SCRIPTURE_INDEX.VERSE)
//        
//        UserDefaults.standard.synchronize()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        directionLabel.isHidden = true
        switchesLabel.isHidden = true

        bookLabel.isHidden = true
        bookSwitch.isHidden = true

        chapterLabel.isHidden = true
        chapterSwitch.isHidden = true
        
        scripturePicker!.isHidden = true
        progressIndicator.isHidden = true
        
        // Do any additional setup after loading the view.
//        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
//        navigationItem.leftItemsSupplementBackButton = true
        navigationController?.setToolbarHidden(true, animated: true)
  
        numberOfMediaItemsLabel.isHidden = true
        numberOfMediaItems.text = Constants.EMPTY_STRING
        numberOfMediaItems.isHidden = true
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            if (self.scriptureIndex == nil) {
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
                        //                                            NSLog(mediaItem.scripture!)
                        //                        NSLog("STOP")
                        //                    }
                        if let books = mediaItem.books {
                            //                        if (books.count > 1) {
                            //                            NSLog("\(mediaItem.scripture!)")
                            //                            NSLog("\(books)")
                            //                            NSLog("STOP")
                            //                        }
                            self.finished += Float(mediaItem.books!.count)
                            for book in books {
                                //                            NSLog("\(mediaItem)")
                                if globals.active?.scriptureIndex?.byTestament[testament(book)] == nil {
                                    self.scriptureIndex?.byTestament[testament(book)] = [mediaItem]
                                } else {
                                    self.scriptureIndex?.byTestament[testament(book)]?.append(mediaItem)
                                }
                                
                                if self.scriptureIndex?.byBook[testament(book)] == nil {
                                    self.scriptureIndex?.byBook[testament(book)] = [String:[MediaItem]]()
                                }
                                if self.scriptureIndex?.byBook[testament(book)]?[book] == nil {
                                    self.scriptureIndex?.byBook[testament(book)]?[book] = [mediaItem]
                                } else {
                                    self.scriptureIndex?.byBook[testament(book)]?[book]?.append(mediaItem)
                                }
                                
                                let chapters = mediaItem.chapters(book)
                                self.finished += Float(chapters.count)
                                for chapter in chapters {
                                    //                                if (books.count > 1) {
                                    //                                    NSLog("\(mediaItem.scripture!)")
                                    //                                    NSLog("\(book)")
                                    //                                    NSLog("\(mediaItem.chapters(book))")
                                    //                                    NSLog("STOP")
                                    //                                }
                                    if self.scriptureIndex?.byChapter[testament(book)] == nil {
                                        self.scriptureIndex?.byChapter[testament(book)] = [String:[Int:[MediaItem]]]()
                                    }
                                    if self.scriptureIndex?.byChapter[testament(book)]?[book] == nil {
                                        self.scriptureIndex?.byChapter[testament(book)]?[book] = [Int:[MediaItem]]()
                                    }
                                    if self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] == nil {
                                        self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter] = [mediaItem]
                                    } else {
                                        self.scriptureIndex?.byChapter[testament(book)]?[book]?[chapter]?.append(mediaItem)
                                    }
                                    
                                    self.progress += 1
                                }
                                
                                self.progress += 1
                            }
                        }
                        
                        self.progress += 1
                    }
                }
                
                // Sort
                if self.scriptureIndex != nil {
                    self.finished += Float(self.scriptureIndex!.byTestament.keys.count)
                    for testament in self.scriptureIndex!.byTestament.keys {
                        self.scriptureIndex?.byTestament[testament] = sortMediaItemsChronologically(self.scriptureIndex?.byTestament[testament])
                        
                        if self.scriptureIndex?.byBook[testament] != nil {
                            self.finished += Float(self.scriptureIndex!.byBook[testament]!.keys.count)
                            for book in self.scriptureIndex!.byBook[testament]!.keys {
                                self.scriptureIndex?.byBook[testament]![book] = sortMediaItemsChronologically(self.scriptureIndex?.byBook[testament]![book])
                                
                                if self.scriptureIndex?.byChapter[testament] != nil {
                                    if self.scriptureIndex?.byChapter[testament]![book] != nil {
                                        self.finished += Float(self.scriptureIndex!.byChapter[testament]![book]!.keys.count)
                                        for chapter in self.scriptureIndex!.byChapter[testament]![book]!.keys {
                                            self.scriptureIndex?.byChapter[testament]![book]![chapter] = sortMediaItemsChronologically(self.scriptureIndex?.byChapter[testament]![book]![chapter])
                                            self.progress += 1
                                        }
                                    }
                                }
                                self.progress += 1
                            }
                        }
                        self.progress += 1
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
//                self.loadSettings()
                
//                self.selectedTestament = Constants.OT
//                self.selectedBook = nil
//                self.selectedChapter = 0
//                self.selectedVerse = 0

                self.bookSwitch.isOn = self.scriptureIndex?.selectedBook != nil
                self.chapterSwitch.isOn = self.scriptureIndex?.selectedChapter > 0

                self.scripturePicker.reloadAllComponents()
                
//                print(self.selectedTestament)
//                print(self.selectedBook)
//                print(self.selectedChapter)

                if let selectedTestament = self.scriptureIndex?.selectedTestament {
                    if let index = Constants.TESTAMENTS.index(of: selectedTestament) {
                        self.scripturePicker.selectRow(index, inComponent: 0, animated: true)
                    }
                    
                    if let selectedBook = self.scriptureIndex?.selectedBook {
                        if let index = Constants.BOOKS[selectedTestament]?.index(of: selectedBook) {
                            self.scripturePicker.selectRow(index, inComponent: 1, animated: true)
                        }
                    }
                    
                    if let selectedChapter = self.scriptureIndex?.selectedChapter {
                        if selectedChapter > 0 {
                            self.scripturePicker.selectRow(selectedChapter - 1, inComponent: 2, animated: true)
                        }
                    }
                }
                
                self.directionLabel.isHidden = false
                self.switchesLabel.isHidden = false
                
                self.bookLabel.isHidden = false
                self.bookSwitch.isHidden = false
                
                self.chapterLabel.isHidden = false
                self.chapterSwitch.isHidden = false

                self.bookSwitch.isEnabled = self.scriptureIndex != nil
                self.chapterSwitch.isEnabled = self.bookSwitch.isOn

                self.numberOfMediaItemsLabel.isHidden = false
                self.numberOfMediaItems.isHidden = false

                self.scripturePicker.isHidden = false
                self.spinner.stopAnimating()
                
                self.updateDirectionLabel()
                
                if let selectedTestament = self.scriptureIndex?.selectedTestament {
                    self.mediaItems = self.scriptureIndex?.byTestament[selectedTestament]
                    
                    if (self.mediaItems != nil) {
                        self.numberOfMediaItems.text = "\(self.mediaItems!.count) from the \(selectedTestament)"
                    } else {
                        self.numberOfMediaItems.text = "0 from the \(selectedTestament)"
                    }
                }
                
                self.updateSearchResults()
                self.tableView.isHidden = false
                self.tableView.reloadData()
            })
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
