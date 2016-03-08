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
    
    var timer:NSTimer?
    
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
    
    @IBOutlet weak var numberOfSermons: UILabel!
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var numberOfRows = 1
        
        switch component {
        case 0:
            numberOfRows = 2 // N.T. or O.T.
            break
            
        case 1:
            if (selectedTestament != nil) {
                switch selectedTestament! {
                case Constants.Old_Testament:
                    numberOfRows = Constants.OLD_TESTAMENT_BOOKS.count
                    break
                    
                case Constants.New_Testament:
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
                case Constants.Old_Testament:
                    if (selectedBook != nil) {
                        if (Constants.OLD_TESTAMENT_BOOKS.indexOf(selectedBook!) != nil) {
                            numberOfRows = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                        } else {
                            numberOfRows = 0 // number of chapters in book
                        }
                    } else {
                        numberOfRows = 0 // number of chapters in book
                    }
                    break
                    
                case Constants.New_Testament:
                    if (selectedBook != nil) {
                        if (Constants.NEW_TESTAMENT_BOOKS.indexOf(selectedBook!) != nil) {
                            numberOfRows = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
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
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case 0:
            return 175
            
        case 1:
            return 200
            
        case 2:
            return 100
            
        case 3:
            return 100
            
        default:
            return 0
        }
    }
    
    //    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    //
    //    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            if row == 0 {
                return Constants.Old_Testament
            }
            if row == 1 {
                return Constants.New_Testament
            }
            break
            
        case 1:
            if (selectedTestament != nil) {
                switch selectedTestament! {
                case Constants.Old_Testament:
                    if row < Constants.OLD_TESTAMENT_BOOKS.count {
                        return Constants.OLD_TESTAMENT_BOOKS[row]
                    }
                    
                case Constants.New_Testament:
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
                case Constants.Old_Testament:
                    if selectedBook != nil {
                        let chapters = Constants.OLD_TESTAMENT_CHAPTERS[Constants.OLD_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
                        if row < chapters {
                            return "\(row+1)"
                        }
                    }
                    break
                    
                case Constants.New_Testament:
                    if selectedBook != nil {
                        let chapters = Constants.NEW_TESTAMENT_CHAPTERS[Constants.NEW_TESTAMENT_BOOKS.indexOf(selectedBook!)!]
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
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        switch component {
        case 0: // Testament
            if row == 0 {
                selectedTestament = Constants.Old_Testament
            }
            
            if row == 1 {
                selectedTestament = Constants.New_Testament
            }
            
            pickerView.reloadAllComponents()
            
            pickerView.selectRow(0, inComponent: 1, animated: true)
            selectedBook = nil
            
            pickerView.selectRow(0, inComponent: 2, animated: true)
            selectedChapter = 0
            
            //            pickerView.selectRow(0, inComponent: 3, animated: true)
            selectedVerse = 0
            
            sermons = Globals.sermonRepository.scriptureIndex!.byTestament[selectedTestament!]
            if sermons != nil {
                numberOfSermons.text = "\(sermons!.count) from the \(selectedTestament!)"
            } else {
                numberOfSermons.text = "0 from the \(selectedTestament!)"
            }
            //            print("\(sermons)")
            tableView.reloadData()
            break
            
        case 1: // Book
            if (selectedTestament != nil) {
                switch selectedTestament! {
                case Constants.Old_Testament:
                    selectedBook = Constants.OLD_TESTAMENT_BOOKS[row]
                    break
                    
                case Constants.New_Testament:
                    selectedBook = Constants.NEW_TESTAMENT_BOOKS[row]
                    break
                    
                default:
                    break
                }
                
                pickerView.reloadAllComponents()
                
                pickerView.selectRow(0, inComponent: 2, animated: true)
                selectedChapter = 0
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                selectedVerse = 0
                
                sermons = Globals.sermonRepository.scriptureIndex!.byBook[selectedTestament!]?[selectedBook!]
                if sermons != nil {
                    numberOfSermons.text = "\(sermons!.count) from the book of \(selectedBook!) in the \(selectedTestament!)"
                } else {
                    numberOfSermons.text = "0 from the book of \(selectedBook!) in the \(selectedTestament!)"
                }
                tableView.reloadData()
            }
            break
            
        case 2: // Chapter
            if (selectedTestament != nil) && (selectedBook != nil) {
                selectedChapter = row + 1
                
                pickerView.reloadAllComponents()
                
                //                pickerView.selectRow(0, inComponent: 3, animated: true)
                selectedVerse = 0
                
                sermons = Globals.sermonRepository.scriptureIndex!.byChapter[selectedTestament!]?[selectedBook!]?[selectedChapter]
                if sermons != nil {
                    numberOfSermons.text = "\(sermons!.count) from chapter \(selectedChapter) of the book of \(selectedBook!) in the \(selectedTestament!)"
                } else {
                    numberOfSermons.text = "0 from chapter \(selectedChapter) of the book of \(selectedBook!) in the \(selectedTestament!)"
                }
                
                tableView.reloadData()
            }
            break
            
        case 3: // Verse
            if (selectedTestament != nil) && (selectedBook != nil) && (selectedChapter > 0) {
                selectedVerse = row + 1
                
                pickerView.reloadAllComponents()
                
                //sermons =
                if sermons != nil {
                    numberOfSermons.text = "\(sermons!.count) from verse \(selectedVerse) in chapter \(selectedChapter) of the book of \(selectedBook!) in the \(selectedTestament!)"
                } else {
                    numberOfSermons.text = "0 from verse \(selectedVerse) in chapter \(selectedChapter) of the book of \(selectedBook!) in the \(selectedTestament!)"
                }
                
                tableView.reloadData()
            }
            break
            
        default:
            break
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destinationViewController as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case "Show Index Sermon":
                if let myCell = sender as? MyTableViewCell {
                    selectedSermon = myCell.sermon //Globals.activeSermons![index]
                    
                    if selectedSermon != nil {
                        if let destination = dvc as? MyViewController {
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return sermons != nil ? sermons!.count : 0
    }
    
    /*
    */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SermonSeries", forIndexPath: indexPath) as! MyTableViewCell
        
        cell.sermon = sermons?[indexPath.row]
        
        cell.vc = self
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, shouldSelectRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func working()
    {
        progressIndicator.progress = progress / finished
        
//        print(progress)
//        print(finished)
        
        if progressIndicator.progress == 1.0 {
            timer?.invalidate()
            timer = nil
            progressIndicator.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scripturePicker!.hidden = true
        progressIndicator.hidden = true
        
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        self.numberOfSermons.text = ""
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            if (Globals.sermonRepository.scriptureIndex == nil) {
                Globals.sermonRepository.scriptureIndex = ScriptureIndex()
                
                self.progress = 0
                self.finished = 0
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.progressIndicator.progress = 0
                    self.progressIndicator.hidden = false
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "working", userInfo: nil, repeats: true)
                })
                
                self.finished += Float(Globals.sermonRepository.list!.count)
                for sermon in Globals.sermonRepository.list! {
                    //                    if (sermon.scripture?.rangeOfString(" and ") != nil) {
                    //                        print(sermon.scripture!)
                    //                        print("STOP")
                    //                    }
                    if let books = sermon.books {
                        //                        if (books.count > 1) {
                        //                            print("\(sermon.scripture!)")
                        //                            print("\(books)")
                        //                            print("STOP")
                        //                        }
                        self.finished += Float(sermon.books!.count)
                        for book in books {
                            //                            print("\(sermon)")
                            if Globals.sermonRepository.scriptureIndex!.byTestament[testament(book)] == nil {
                                Globals.sermonRepository.scriptureIndex!.byTestament[testament(book)] = [sermon]
                            } else {
                                Globals.sermonRepository.scriptureIndex!.byTestament[testament(book)]?.append(sermon)
                            }
                            
                            if Globals.sermonRepository.scriptureIndex!.byBook[testament(book)] == nil {
                                Globals.sermonRepository.scriptureIndex!.byBook[testament(book)] = [String:[Sermon]]()
                            }
                            if Globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book] == nil {
                                Globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book] = [sermon]
                            } else {
                                Globals.sermonRepository.scriptureIndex!.byBook[testament(book)]?[book]?.append(sermon)
                            }
                            
                            let chapters = sermon.chapters(book)
                            self.finished += Float(chapters.count)
                            for chapter in chapters {
                                //                                if (books.count > 1) {
                                //                                    print("\(sermon.scripture!)")
                                //                                    print("\(book)")
                                //                                    print("\(sermon.chapters(book))")
                                //                                    print("STOP")
                                //                                }
                                if Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)] == nil {
                                    Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)] = [String:[Int:[Sermon]]]()
                                }
                                if Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book] == nil {
                                    Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book] = [Int:[Sermon]]()
                                }
                                if Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter] == nil {
                                    Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter] = [sermon]
                                } else {
                                    Globals.sermonRepository.scriptureIndex!.byChapter[testament(book)]?[book]?[chapter]?.append(sermon)
                                }
                                
                                self.progress++
                            }
                            
                            self.progress++
                        }
                    }
                    
                    self.progress++
                }
                
                // Sort
                self.finished += Float(Globals.sermonRepository.scriptureIndex!.byTestament.keys.count)
                for testament in Globals.sermonRepository.scriptureIndex!.byTestament.keys {
                    Globals.sermonRepository.scriptureIndex!.byTestament[testament] = sortSermonsChronologically(Globals.sermonRepository.scriptureIndex!.byTestament[testament])
                    
                    if Globals.sermonRepository.scriptureIndex!.byBook[testament] != nil {
                        self.finished += Float(Globals.sermonRepository.scriptureIndex!.byBook[testament]!.keys.count)
                        for book in Globals.sermonRepository.scriptureIndex!.byBook[testament]!.keys {
                            Globals.sermonRepository.scriptureIndex!.byBook[testament]![book] = sortSermonsChronologically(Globals.sermonRepository.scriptureIndex!.byBook[testament]![book])
                            
                            if Globals.sermonRepository.scriptureIndex!.byChapter[testament] != nil {
                                if Globals.sermonRepository.scriptureIndex!.byChapter[testament]![book] != nil {
                                    self.finished += Float(Globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]!.keys.count)
                                    for chapter in Globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]!.keys {
                                        Globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]![chapter] = sortSermonsChronologically(Globals.sermonRepository.scriptureIndex!.byChapter[testament]![book]![chapter])
                                        self.progress++
                                    }
                                }
                            }
                            self.progress++
                        }
                    }
                    self.progress++
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.selectedTestament = Constants.Old_Testament
                
                self.scripturePicker.reloadAllComponents()
                self.scripturePicker.selectRow(0, inComponent: 0, animated: true)
                self.scripturePicker.selectRow(0, inComponent: 1, animated: true)
                
                self.selectedBook = nil
                self.selectedChapter = 0
                self.selectedVerse = 0
                
                self.scripturePicker!.hidden = false
                self.spinner.stopAnimating()
                
                self.sermons = Globals.sermonRepository.scriptureIndex!.byTestament[self.selectedTestament!]
                self.numberOfSermons.text = "\(self.sermons!.count) from the \(self.selectedTestament!)"
                self.tableView.hidden = false
                self.tableView.reloadData()
            })
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
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
