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
    var byTestament = [String:[Sermon]]()
    
    //Test  //Book
    var byBook = [String:[String:[Sermon]]]()
    
    //Test  //Book  //Ch#
    var byChapter = [String:[String:[Int:[Sermon]]]]()
    
    //Test  //Book  //Ch#/Verse#
    var byVerse = [String:[String:[Int:[Int:[Sermon]]]]]()
}

class ScriptureIndexViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var finished:Float = 0.0
    var progress:Float = 0.0
    
    var timer:Timer?
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var directionLabel: UILabel!
    
    @IBOutlet weak var switchesLabel: UILabel!
    
    @IBOutlet weak var bookLabel: UILabel!
    @IBOutlet weak var bookSwitch: UISwitch!

    @IBAction func bookSwitchAction(_ sender: UISwitch) {
        if bookSwitch.isOn {
            chapterSwitch.isEnabled = true
            
            switch selectedTestament! {
            case Constants.OT:
                selectedBook = Constants.OLD_TESTAMENT_BOOKS[0]
                break
                
            case Constants.NT:
                selectedBook = Constants.NEW_TESTAMENT_BOOKS[0]
                break
                
            default:
                break
            }
        } else {
            chapterSwitch.isOn = false
            chapterSwitch.isEnabled = false
            selectedBook = nil
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
            
            switch selectedTestament! {
            case Constants.OT:
                selectedChapter = 1 // Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                break
                
            case Constants.NT:
                selectedChapter = 1 // Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                break
                
            default:
                break
            }
        } else {
            selectedChapter = 0
        }
        
        updateDirectionLabel()
        
        updateSearchResults()
        
        scripturePicker.reloadAllComponents()
        tableView.reloadData()
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var selectedTestament:String?
    var selectedBook:String?
    var selectedChapter = 0
    var selectedVerse = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    var sermons:[Sermon]?
    var selectedSermon:Sermon?
    
    @IBOutlet weak var scripturePicker: UIPickerView!
    
    @IBOutlet weak var numberOfSermonsLabel: UILabel!
    @IBOutlet weak var numberOfSermons: UILabel!
    
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
            if (selectedTestament != nil) && bookSwitch.isOn {
                switch selectedTestament! {
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
            if (selectedTestament != nil) {
                switch selectedTestament! {
                case Constants.OT:
                    if (selectedBook != nil) {
                        if chapterSwitch.isOn {
                            if (Constants.OLD_TESTAMENT_BOOKS.index(of: selectedBook!) != nil) {
                                numberOfRows = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.index(of: selectedBook!)!]
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
                    if (selectedBook != nil) {
                        if chapterSwitch.isOn {
                            if (Constants.NEW_TESTAMENT_BOOKS.index(of: selectedBook!) != nil) {
                                numberOfRows = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.index(of: selectedBook!)!]
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
            if selectedChapter > 0 {
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
        var translation = ""
        
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
            if (selectedTestament != nil) {
                switch selectedTestament! {
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
            if (selectedTestament != nil) {
                switch selectedTestament! {
                case Constants.OT:
                    if selectedBook != nil {
                        let chapters = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.index(of: selectedBook!)!]
                        if row < chapters {
                            return "\(row+1)"
                        }
                    }
                    break
                    
                case Constants.NT:
                    if selectedBook != nil {
                        let chapters = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.index(of: selectedBook!)!]
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
            if selectedChapter > 0 {
                return "1"
            }
            break
            
        default:
            break
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return title(forRow: row,forComponent: component)
    }
    
    func updateSearchResults()
    {
        if (selectedTestament != nil) {
            if (selectedBook != nil) {
                if (selectedChapter > 0) {
                    if (selectedVerse > 0) {
                        sermons = nil // Need to add this
//                        sermons = globals.sermonRepository.scriptureIndex!.byChapter[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]?[selectedVerse]
                        if sermons != nil {
                            numberOfSermons.text = "\(sermons!.count) from verse \(selectedVerse) in chapter \(selectedChapter) of \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                        } else {
                            numberOfSermons.text = "0 from verse \(selectedVerse) in chapter \(selectedChapter) of \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                        }
                    } else {
                        sermons = globals.sermonRepository.scriptureIndex!.byChapter[translateTestament(selectedTestament!)]?[selectedBook!]?[selectedChapter]
                        if sermons != nil {
                            numberOfSermons.text = "\(sermons!.count) from chapter \(selectedChapter) of \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                        } else {
                            numberOfSermons.text = "0 from chapter \(selectedChapter) of \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                        }
                    }
                } else {
                    sermons = globals.sermonRepository.scriptureIndex!.byBook[translateTestament(selectedTestament!)]?[selectedBook!]
                    if sermons != nil {
                        numberOfSermons.text = "\(sermons!.count) from \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                    } else {
                        numberOfSermons.text = "0 from \(selectedBook!) in the \(translateTestament(selectedTestament!))"
                    }
                }
            } else {
                sermons = globals.sermonRepository.scriptureIndex!.byTestament[translateTestament(selectedTestament!)]
                if sermons != nil {
                    numberOfSermons.text = "\(sermons!.count) from the \(translateTestament(selectedTestament!))"
                } else {
                    numberOfSermons.text = "0 from the \(translateTestament(selectedTestament!))"
                }
            }
        }
        
//        NSLog("\(sermons)")

        tableView.reloadData()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch component {
        case 0: // Testament
            if row == 0 {
                selectedTestament = Constants.OT
            }
            
            if row == 1 {
                selectedTestament = Constants.NT
            }
            
            if bookSwitch.isOn {
                switch selectedTestament! {
                case Constants.OT:
                    selectedBook = Constants.OLD_TESTAMENT_BOOKS[0]
                    break
                    
                case Constants.NT:
                    selectedBook = Constants.NEW_TESTAMENT_BOOKS[0]
                    break
                    
                default:
                    break
                }
            } else {
                selectedBook = nil
            }
            
            if chapterSwitch.isOn {
                selectedChapter = 1
            } else {
                selectedChapter = 0
            }
            
            selectedVerse = 0
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)

            pickerView.selectRow(0, inComponent: 2, animated: true)
            
            //            pickerView.selectRow(0, inComponent: 3, animated: true)
            
            updateSearchResults()
            break
            
        case 1: // Book
            if (selectedTestament != nil) && bookSwitch.isOn {
                switch selectedTestament! {
                case Constants.OT:
                    selectedBook = Constants.OLD_TESTAMENT_BOOKS[row]
                    break
                    
                case Constants.NT:
                    selectedBook = Constants.NEW_TESTAMENT_BOOKS[row]
                    break
                    
                default:
                    break
                }
                
                if chapterSwitch.isOn {
                    selectedChapter = 1
                } else {
                    selectedChapter = 0
                }
                
                selectedVerse = 0
                
                pickerView.reloadAllComponents()

                pickerView.selectRow(0, inComponent: 2, animated: true)
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                
                updateSearchResults()
            }
            break
            
        case 2: // Chapter
            if (selectedTestament != nil) && (selectedBook != nil) && bookSwitch.isOn && chapterSwitch.isOn {
                selectedChapter = row + 1
                
                selectedVerse = 0

                pickerView.reloadAllComponents()
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)

                updateSearchResults()
            }
            break
            
        case 3: // Verse
            if (selectedTestament != nil) && (selectedBook != nil) && (selectedChapter > 0) && bookSwitch.isOn && chapterSwitch.isOn {
                selectedVerse = row + 1
                
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
            case Constants.SHOW_INDEX_SERMON_SEGUE:
                if let myCell = sender as? MediaTableViewCell {
                    if (selectedSermon != myCell.sermon) || (globals.history == nil) {
                        globals.addToHistory(myCell.sermon)
                    }
                    selectedSermon = myCell.sermon //globals.activeSermons![index]
                    
                    if selectedSermon != nil {
                        if let destination = dvc as? MediaViewController {
                            destination.selectedSermon = selectedSermon
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
        
        return sermons != nil ? sermons!.count : 0
    }
    
    /*
    */
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SermonSeries", for: indexPath) as! MediaTableViewCell
        
        cell.sermon = sermons?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldSelectRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        NSLog("didSelectRowAtIndexPath")
        if (splitViewController != nil) {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: "Show Sermon NavCon") as? UINavigationController {
                if let viewController = navigationController.viewControllers[0] as? MediaViewController {
                    viewController.selectedSermon = sermons?[indexPath.row]
                    
                    splitViewController?.viewControllers[1] = navigationController
                    
                    //            let navigationController = splitViewController?.viewControllers[1] as? UINavigationController
                    //
                    //            navigationController?.navigationItem.hidesBackButton = false
                    //            navigationController?.isToolbarHidden = true
                    //            navigationController?.pushViewController(viewController, animated: true)
                }
            }
        } else {
            if let viewController = self.storyboard!.instantiateViewController(withIdentifier: "Show Sermon") as? MediaViewController {
                viewController.selectedSermon = sermons?[indexPath.row]
                
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
        case "Show Index Sermon":
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
//            if (globals.sermons.all == nil) {
//                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryOverlay//iPad only
//            } else {
//                if (splitViewController != nil) {
//                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
//                        if let _ = nvc.visibleViewController as? ScriptureIndexViewController {
//                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
//                        } else {
//                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
//                        }
//                    }
//                }
//            }
//        } else {
//            if (splitViewController != nil) {
//                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
//                    if let _ = nvc.visibleViewController as? ScriptureIndexViewController {
//                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
//                    } else {
//                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
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
        NotificationCenter.default.addObserver(self, selector: #selector(ScriptureIndexViewController.clearView), name: NSNotification.Name(rawValue: Constants.CLEAR_VIEW_NOTIFICATION), object: nil)
        
        navigationItem.hidesBackButton = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

        navigationItem.hidesBackButton = false
        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        navigationController?.navigationBar.backItem?.title = Constants.Back
    }
    
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
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
//        navigationController?.setToolbarHidden(true, animated: true)
  
        numberOfSermonsLabel.isHidden = true
        numberOfSermons.text = ""
        numberOfSermons.isHidden = true
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            if (globals.sermonRepository.scriptureIndex == nil) {
                globals.sermonRepository.scriptureIndex = ScriptureIndex()
                
                self.progress = 0
                self.finished = 0
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.progressIndicator.progress = 0
                    self.progressIndicator.isHidden = false
                    self.timer = Timer.scheduledTimer(timeInterval: Constants.WORKING_TIMER_INTERVAL, target: self, selector: #selector(ScriptureIndexViewController.working), userInfo: nil, repeats: true)
                })
                
                self.finished += Float(globals.active!.list!.count)
                for sermon in globals.active!.list! {
                    //                    if (sermon.scripture?.rangeOfString(" and ") != nil) {
//                                            NSLog(sermon.scripture!)
                    //                        NSLog("STOP")
                    //                    }
                    if let books = sermon.books {
                        //                        if (books.count > 1) {
                        //                            NSLog("\(sermon.scripture!)")
                        //                            NSLog("\(books)")
                        //                            NSLog("STOP")
                        //                        }
                        self.finished += Float(sermon.books!.count)
                        for book in books {
                            //                            NSLog("\(sermon)")
                            if globals.sermonRepository.scriptureIndex!.byTestament[testament(book)] == nil {
                                globals.sermonRepository.scriptureIndex!.byTestament[testament(book)] = [sermon]
                            } else {
                                globals.sermonRepository.scriptureIndex!.byTestament[testament(book)]?.append(sermon)
                            }
                            
                            if globals.sermonRepository.scriptureIndex!.byBook[testament(book)] == nil {
                                globals.sermonRepository.scriptureIndex!.byBook[testament(book)] = [String:[Sermon]]()
                            }
                            if globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book] == nil {
                                globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book] = [sermon]
                            } else {
                                globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book]?.append(sermon)
                            }
                            
                            let chapters = sermon.chapters(book)
                            self.finished += Float(chapters.count)
                            for chapter in chapters {
                                //                                if (books.count > 1) {
                                //                                    NSLog("\(sermon.scripture!)")
                                //                                    NSLog("\(book)")
                                //                                    NSLog("\(sermon.chapters(book))")
                                //                                    NSLog("STOP")
                                //                                }
                                if globals.sermonRepository.scriptureIndex!.byChapter[testament(book)] == nil {
                                    globals.sermonRepository.scriptureIndex!.byChapter[testament(book)] = [String:[Int:[Sermon]]]()
                                }
                                if globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book] == nil {
                                    globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book] = [Int:[Sermon]]()
                                }
                                if globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter] == nil {
                                    globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter] = [sermon]
                                } else {
                                    globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter]?.append(sermon)
                                }
                                
                                self.progress += 1
                            }
                            
                            self.progress += 1
                        }
                    }
                    
                    self.progress += 1
                }
                
                // Sort
                self.finished += Float(globals.sermonRepository.scriptureIndex!.byTestament.keys.count)
                for testament in globals.sermonRepository.scriptureIndex!.byTestament.keys {
                    globals.sermonRepository.scriptureIndex!.byTestament[testament] = sortSermonsChronologically(globals.sermonRepository.scriptureIndex!.byTestament[testament])
                    
                    if globals.sermonRepository.scriptureIndex!.byBook[testament] != nil {
                        self.finished += Float(globals.sermonRepository.scriptureIndex!.byBook[testament]!.keys.count)
                        for book in globals.sermonRepository.scriptureIndex!.byBook[testament]!.keys {
                            globals.sermonRepository.scriptureIndex!.byBook[testament]![book] = sortSermonsChronologically(globals.sermonRepository.scriptureIndex!.byBook[testament]![book])
                            
                            if globals.sermonRepository.scriptureIndex!.byChapter[testament] != nil {
                                if globals.sermonRepository.scriptureIndex!.byChapter[testament]![book] != nil {
                                    self.finished += Float(globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]!.keys.count)
                                    for chapter in globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]!.keys {
                                        globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]![chapter] = sortSermonsChronologically(globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]![chapter])
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
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectedTestament = Constants.OT
                
                self.scripturePicker.reloadAllComponents()
                self.scripturePicker.selectRow(0, inComponent: 0, animated: true)
                self.scripturePicker.selectRow(0, inComponent: 1, animated: true)
                
                self.selectedBook = nil
                self.selectedChapter = 0
                self.selectedVerse = 0
                
                self.directionLabel.isHidden = false
                self.switchesLabel.isHidden = false
                
                self.bookLabel.isHidden = false
                self.bookSwitch.isHidden = false

                self.chapterLabel.isHidden = false
                self.chapterSwitch.isHidden = false

                self.chapterSwitch.isEnabled = self.bookSwitch.isOn

                self.numberOfSermonsLabel.isHidden = false
                self.numberOfSermons.isHidden = false

                self.scripturePicker!.isHidden = false
                self.spinner.stopAnimating()
                
                self.updateDirectionLabel()
                
                self.sermons = globals.sermonRepository.scriptureIndex!.byTestament[self.selectedTestament!]
                
                if (self.sermons != nil) {
                    self.numberOfSermons.text = "\(self.sermons!.count) from the \(self.selectedTestament!)"
                } else {
                    self.numberOfSermons.text = "0 from the \(self.selectedTestament!)"
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
