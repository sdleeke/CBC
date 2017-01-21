//
//  PopoverTableViewController.swift
//  CBC
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String], purpose:PopoverPurpose, mediaItem:MediaItem?)
}

class PopoverTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct Section {
        var titles:[String]?
        var counts:[Int]?
        var indexes:[Int]?
    }
    
    var vc:UIViewController?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedMediaItem:MediaItem?
    
    var stringsFunction:((Void)->[String]?)?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var showSectionHeaders:Bool = false
    
    var mediaListGroupSort:MediaListGroupSort?
    
    var indexStrings:[String]?
    
    var strings:[String]?
    
//    var transform:((String?)->String?)?
    
//    var section:Section!
    
    lazy var section:Section! = {
        var section = Section()
        return section
    }()
    
    func setPreferredContentSize()
    {
        guard (strings != nil) else {
            return
        }
        
        self.tableView.sizeToFit()
        
        let margins:CGFloat = 2
        let marginSpace:CGFloat = 9
        
        let checkmarkSpace:CGFloat = 38
        let indexSpace:CGFloat = 40
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        var deducts:CGFloat = 0
        
        deducts += margins * marginSpace
        
        if self.showIndex {
            deducts += indexSpace
        }
        
        switch self.purpose! {
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            deducts += checkmarkSpace
            break
            
        default:
            break
        }
        
        var viewWidth = self.view.frame.width
        
        if (self.vc?.splitViewController != nil) && (self.vc!.splitViewController!.viewControllers.count > 1) {
            viewWidth = self.vc!.splitViewController!.view.frame.width
        }
        
        //        print(view.frame.width - deducts)
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
        
        if let title = self.navigationItem.title {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0)], context: nil).width
        }
        
        //        print(strings)
        
        for string in self.strings! {
            let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
            //            print(string)
            //            print(maxSize)
            
            //            print(string,width,maxWidth.width)
            
            if maxWidth.width > width {
                width = maxWidth.width
            }
            
            //            print(string,maxHeight.height) // baseHeight
            
            height += 2*8 + maxHeight.height // - baseHeight
            
            //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
            //            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
        }
        
        width += margins * marginSpace
        
        switch self.purpose! {
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            width += checkmarkSpace
            break
            
        default:
            break
        }
        
        if self.showIndex {
            width += indexSpace
            height += self.tableView.sectionHeaderHeight * CGFloat(self.indexStrings!.count)
        }
        
        //        print(height)
        //        print(width)
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    var isRefreshing = false
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        refreshControl.beginRefreshing()
        
        view.isUserInteractionEnabled = false
        
        isRefreshing = true
        mediaListGroupSort?.lexicon?.pauseUpdates = false
        lexiconUpdated()
    }
    
    var refreshControl:UIRefreshControl?

    func addRefreshControl()
    {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(PopoverTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        }
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView?.addSubview(self.refreshControl!)
            })
        }
    }
    
    func removeRefreshControl()
    {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = nil
        } else {
            // Fallback on earlier versions
            DispatchQueue.main.async(execute: { () -> Void in
                self.refreshControl?.removeFromSuperview()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mediaListGroupSort != nil {
            mediaListGroupSort?.lexicon?.pauseUpdates = false
            
            DispatchQueue.main.async {
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconStarted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconCompleted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.mediaListGroupSort?.lexicon)
            }
        }

        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

//        if purpose != .selectingHistory {
//        } else {
//            tableView.rowHeight = 100
//        }

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        setPreferredContentSize()
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func setupIndex()
    {
        guard showIndex else {
            return
        }
        
        guard (strings != nil) else {
            return
        }
        
        guard (indexStrings != nil) else {
            return
        }
        
        let a = "A"
        
        var indexes = [Int]()
        var counts = [Int]()
        
        section.titles = Array(Set(indexStrings!.map({ (string:String) -> String in
            if string.endIndex >= a.endIndex {
                return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
            } else {
                return string
            }
        }))).sorted() { $0 < $1 }
        
        var stringIndex = [String:[String]]()
        
        for indexString in indexStrings! {
            if stringIndex[indexString.substring(to: a.endIndex)] == nil {
                stringIndex[indexString.substring(to: a.endIndex)] = [String]()
            }
            //                print(testString,string)
            stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
        }
        
        var counter = 0
        
        for key in stringIndex.keys.sorted() {
            //                print(stringIndex[key]!)
            indexes.append(counter)
            counts.append(stringIndex[key]!.count)
            counter += stringIndex[key]!.count
        }
        
        section.indexes = indexes.count > 0 ? indexes : nil
        section.counts = counts.count > 0 ? counts : nil
    }
    
    func lexiconStarted()
    {
        self.activityIndicator.startAnimating()
        self.activityIndicator?.isHidden = false
    }
    
    func lexiconUpdated()
    {
        guard let pause = mediaListGroupSort?.lexicon?.pauseUpdates, !pause else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.activityIndicator.startAnimating()
                self.activityIndicator?.isHidden = false
            })
            
            if  let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause,
                let creating = self.mediaListGroupSort?.lexicon?.creating, creating,
                let count = self.mediaListGroupSort?.lexicon?.entries?.count,
                let total = self.mediaListGroupSort?.lexicon?.eligible?.count {
                DispatchQueue.main.async(execute: { () -> Void in
                    if  let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause,
                        let creating = self.mediaListGroupSort?.lexicon?.creating, creating {
                        self.navigationItem.title = "Lexicon \(count) of \(total)"
                    }
                })
                
                var strings = [String]()
                
                if let words = self.mediaListGroupSort?.lexicon?.words?.keys.sorted() {
                    for word in words {
                        if let count = self.mediaListGroupSort?.lexicon?.words?[word]?.count {
                            strings.append("\(word) (\(count))")
                        }
                    }
                }
                
                let array = Array(Set(strings)).sorted() { $0.uppercased() < $1.uppercased() }
                
                let indexStrings = array.map({ (string:String) -> String in
                    return string.uppercased()
                })
                
                if  let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause,
                    let creating = self.mediaListGroupSort?.lexicon?.creating, creating {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.strings = strings
                        self.indexStrings = indexStrings
                        
                        self.setupIndex()
                        
                        self.tableView.reloadData()
                        self.tableView.sizeToFit()
                    })
                }

                let margins:CGFloat = 2
                let marginSpace:CGFloat = 9
                
                let checkmarkSpace:CGFloat = 38
                let indexSpace:CGFloat = 40
                
                var height:CGFloat = 0.0
                var width:CGFloat = 0.0
                
                var deducts:CGFloat = 0
                
                deducts += margins * marginSpace
                
                if self.showIndex {
                    deducts += indexSpace
                }
                
                switch self.purpose! {
                case .selectingTags:
                    fallthrough
                case .selectingGrouping:
                    fallthrough
                case .selectingSorting:
                    deducts += checkmarkSpace
                    break
                    
                default:
                    break
                }
                
                var viewWidth = self.view.frame.width
                
                if (self.vc?.splitViewController != nil) && (self.vc!.splitViewController!.viewControllers.count > 1) {
                    viewWidth = self.vc!.splitViewController!.view.frame.width
                }
                
                //        print(view.frame.width - deducts)
                
                let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
                let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
                
                if let title = self.navigationItem.title {
                    let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                    
                    width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0)], context: nil).width
                }
                
                //        print(strings)
                
                if let strings = self.strings {
                    for string in strings {
                        let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
                        
                        let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
                        
                        let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
                        
                        //            print(string)
                        //            print(maxSize)
                        
                        //            print(string,width,maxWidth.width)
                        
                        if maxWidth.width > width {
                            width = maxWidth.width
                        }
                        
                        //            print(string,maxHeight.height) // baseHeight
                        
                        height += 2*8 + maxHeight.height // - baseHeight
                        
                        //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
                        //            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
                    }
                }
                
                width += margins * marginSpace
                
                switch self.purpose! {
                case .selectingTags:
                    fallthrough
                case .selectingGrouping:
                    fallthrough
                case .selectingSorting:
                    width += checkmarkSpace
                    break
                    
                default:
                    break
                }
                
                if self.showIndex {
                    width += indexSpace
                    height += self.tableView.sectionHeaderHeight * CGFloat(self.indexStrings!.count)
                }
                
                //        print(height)
                //        print(width)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    if  let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause,
                        let creating = self.mediaListGroupSort?.lexicon?.creating, creating {
                        self.preferredContentSize = CGSize(width: width, height: height)
                    }
                    
                    if #available(iOS 10.0, *) {
                        if let refreshing = self.tableView.refreshControl?.isRefreshing, refreshing {
                            self.view.isUserInteractionEnabled = true
                            self.refreshControl?.endRefreshing()
                            self.removeRefreshControl()
                        }
                    } else {
                        // Fallback on earlier versions
                        if self.isRefreshing {
                            self.view.isUserInteractionEnabled = true
                            self.refreshControl?.endRefreshing()
                            self.removeRefreshControl()
                            self.isRefreshing = false
                        }
                    }
                })
            }
        }
    }
    
    func lexiconCompleted()
    {
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.activityIndicator.startAnimating()
                self.activityIndicator?.isHidden = false
            })
            
            var strings = [String]()
            
            if let words = self.mediaListGroupSort?.lexicon?.words?.keys.sorted() {
                for word in words {
                    if let count = self.mediaListGroupSort?.lexicon?.words?[word]?.count {
                        strings.append("\(word) (\(count))")
                    }
                }
            }
            
            self.strings = strings
            self.indexStrings = strings
            
            let array = Array(Set(self.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
            
            self.indexStrings = array.map({ (string:String) -> String in
                return string.uppercased()
            })
            
            self.setupIndex()
            
            DispatchQueue.main.async(execute: { () -> Void in
                if #available(iOS 10.0, *) {
                    if let refreshing = self.tableView.refreshControl?.isRefreshing, refreshing {
                        self.refreshControl?.endRefreshing()
                    }
                } else {
                    // Fallback on earlier versions
                    if self.isRefreshing {
                        self.refreshControl?.endRefreshing()
                        self.isRefreshing = false
                    }
                }
                
                self.view.isUserInteractionEnabled = true
                
                self.removeRefreshControl()

                if  let count = self.mediaListGroupSort?.lexicon?.entries?.count,
                    let total = self.mediaListGroupSort?.lexicon?.eligible?.count {
                    self.navigationItem.title = "Lexicon \(count) of \(total)"
                }
                
//                self.navigationItem.title = "Lexicon Complete"

                self.tableView.reloadData()
                self.setPreferredContentSize()

                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.isHidden = true
                
                if strings.count > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: .top, animated: true)
                }
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if mediaListGroupSort != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: mediaListGroupSort?.lexicon)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: mediaListGroupSort?.lexicon)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: mediaListGroupSort?.lexicon)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        if strings != nil {
            setupIndex()

            if showIndex && (section.titles?.count == 1) {
                showIndex = false
            }
            
            tableView.reloadData()
            
            setPreferredContentSize()
            
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true

//            activityIndicator?.isHidden = false
//            activityIndicator?.startAnimating()
        }
        
        if stringsFunction != nil {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.startAnimating()
                    self.activityIndicator?.isHidden = false
                })
                
                self.strings = self.stringsFunction?()
                if self.strings != nil {
                    let array = Array(Set(self.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
                        
                    self.indexStrings = array.map({ (string:String) -> String in
                        return string.uppercased()
                    })
                    
                    self.setupIndex()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        self.setPreferredContentSize()
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator?.isHidden = true
                    })
                }
            }
        }
        
        if mediaListGroupSort != nil {
            // Start lexicon creation if it isn't already being created.
            if (mediaListGroupSort?.lexicon?.words == nil) {
                mediaListGroupSort?.lexicon?.create()
            } else {
                if let creating = mediaListGroupSort!.lexicon?.creating, creating {
                    lexiconUpdated()
                } else {
                    lexiconCompleted()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if showIndex, section != nil {
            return self.section.titles != nil ? self.section.titles!.count : 0
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if showIndex, self.section != nil {
            return self.section.counts != nil ? ((section < self.section.counts?.count) ? self.section.counts![section] : 0) : 0
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showIndex, section != nil {
            return self.section.titles
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showIndex, section != nil {
            if let pause = mediaListGroupSort?.lexicon?.pauseUpdates, !pause, let creating = mediaListGroupSort?.lexicon?.creating, creating {
                mediaListGroupSort?.lexicon?.pauseUpdates = true
                
                addRefreshControl()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.navigationItem.title = "Lexicon Updates Paused"

//                    var strings = [String]()
//                    
//                    if let words = self.mediaListGroupSort?.lexicon?.words?.keys.sorted() {
//                        for word in words {
//                            if let count = self.mediaListGroupSort?.lexicon?.words?[word]?.count {
//                                strings.append("\(word) (\(count))")
//                            }
//                        }
//                    }
//                    
//                    self.strings = strings
//                    
//                    let array = Array(Set(self.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
//                    
//                    self.indexStrings = array.map({ (string:String) -> String in
//                        return string.uppercased()
//                    })
//                    
//                    self.setupIndex()
//
//                    tableView.reloadData()
//                    tableView.scrollToRow(at: IndexPath(row:0, section:index), at: .top, animated: true)
                })
            }
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showIndex, showSectionHeaders, self.section != nil { // showIndex &&
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            let string = strings![index]
            
            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (strings![index] == Constants.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingGrouping:
            if (Constants.groupings[index] == globals.grouping) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == globals.sorting) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        default:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        }

//        print(strings)
        cell.title.text = strings![index]

        return cell
    }

    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }

//        print(index,strings![index])
        
        switch purpose! {
//        case .selectingLexicon:
//            if let mtvc = self.storyboard!.instantiateViewController(withIdentifier: "") as? MediaTableViewController {
//                navigationItem.title = Constants.Lexicon
//                
//                DispatchQueue.main.async(execute: { () -> Void in
//                    self.navigationController?.pushViewController(mtvc, animated: true)
//                })
//            }
//            break
            
        default:
            delegate?.rowClickedAtIndex(index, strings: strings!, purpose: purpose!, mediaItem: selectedMediaItem)
            break
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
