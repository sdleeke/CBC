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
    func rowClickedAtIndex(_ index:Int, strings:[String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
}

extension PopoverTableViewController: UISearchControllerDelegate {
    // MARK: UISearchControllerDelegate
    
    func didDismissSearchController(_ searchController: UISearchController)
    {
        print("didDismissSearchController")
    }
    
    func didPresentSearchController(_ searchController: UISearchController)
    {
        print("didPresentSearchController")
    }
    
    func presentSearchController(_ searchController: UISearchController)
    {
        print("presentSearchController")
    }
    
    func willDismissSearchController(_ searchController: UISearchController)
    {
        print("willDismissSearchController")
    }
    
    func willPresentSearchController(_ searchController: UISearchController)
    {
        print("willPresentSearchController")
    }
}

extension PopoverTableViewController: UISearchResultsUpdating {
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for: UISearchController) {
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
}

extension PopoverTableViewController: UISearchBarDelegate {
    //MARK: SearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….
            
            if let filteredStrings = strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                self.filteredStrings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                print(self.filteredStrings)
                
                let indexStrings = self.filteredStrings?.map({ (string:String) -> String in
                    return string.uppercased()
                })
                
                filteredSection.build(indexStrings)
                
                //                print(filteredSection.titles)
                //
                //                DispatchQueue.main.async(execute: {
                //                    self.tableView.reloadData()
                //                })
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….
            
            if let filteredStrings = strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                self.filteredStrings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                print(self.filteredStrings)
                
                let indexStrings = self.filteredStrings?.map({ (string:String) -> String in
                    return string.uppercased()
                })
                
                filteredSection.build(indexStrings)
                
                //                print(filteredSection.titles)
                //
                //                DispatchQueue.main.async(execute: {
                //                    self.tableView.reloadData()
                //                })
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….

            if let filteredStrings = strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                self.filteredStrings = filteredStrings.count > 0 ? filteredStrings : nil
                
//                print(self.filteredStrings)
                
                let indexStrings = self.filteredStrings?.map({ (string:String) -> String in
                    return string.uppercased()
                })

                filteredSection.build(indexStrings)
                
//                print(filteredSection.titles)
//                
//                DispatchQueue.main.async(execute: {
//                    self.tableView.reloadData()
//                })
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //        print("searchBarSearchButtonClicked:")

        DispatchQueue.main.async(execute: {
            searchBar.resignFirstResponder()
        })

        print(searchController?.isActive)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async(execute: {
            searchBar.text = nil
            searchBar.resignFirstResponder()
        })
    }
}

//struct Section {
//    var titles:[String]?
//    var counts:[Int]?
//    var indexes:[Int]?
//}

class PopoverTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
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
    var section = Section()
    
    var filteredStrings:[String]?
    var filteredSection = Section()
    
//    var transform:((String?)->String?)?
    
//    var section:Section!
    
    func setPreferredContentSize()
    {
        guard (strings != nil) else {
            return
        }
        
//        self.tableView.sizeToFit()
        
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
        DispatchQueue.main.async(execute: { () -> Void in
            refreshControl.beginRefreshing()
        })
        
//        view.isUserInteractionEnabled = false
        
        if let pause = mediaListGroupSort?.lexicon?.pauseUpdates, pause {
            isRefreshing = true
            mediaListGroupSort?.lexicon?.pauseUpdates = false
            DispatchQueue.global(qos: .userInitiated).async {
                self.lexiconUpdated()
            }
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.refreshControl?.endRefreshing()
            })
        }
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
    
    var search = false
    
    var searchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if search {
            definesPresentationContext = true // ABSOLUTE ESSENTIAL TO SEARCH BAR BEING CORRECTLY PLACED WHEN ACTIVATED

            searchController = UISearchController(searchResultsController: nil)
            
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.sizeToFit()

            searchController?.delegate = self
            searchController?.searchBar.delegate = self

//            if #available(iOS 9.1, *) {
//                searchController?.obscuresBackgroundDuringPresentation = false
//            } else {
//                // Fallback on earlier versions
//            }
            
            searchController?.dimsBackgroundDuringPresentation = false
            
            tableView.tableHeaderView = searchController?.searchBar
        }
        
        if mediaListGroupSort != nil {
            searchController?.hidesNavigationBarDuringPresentation = true

            addRefreshControl()
            
            mediaListGroupSort?.lexicon?.pauseUpdates = false

            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconStarted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconCompleted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.mediaListGroupSort?.lexicon)
            })
           
//            DispatchQueue.main.async {
//            }
        } else {
            searchController?.hidesNavigationBarDuringPresentation = false
//            tableView.bounces = false
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
            
            self.strings = strings.count > 0 ? strings.sorted() { $0.uppercased() < $1.uppercased() } : nil
            
            self.indexStrings = self.strings?.map({ (string:String) -> String in
                return string.uppercased()
            })
            
            self.section.build(self.indexStrings)
            
            //                if let strings = self.strings {
            //                    let array = Array(Set(strings))
            //
            //                }
            
            //                let array = Array(Set(strings)).sorted() { $0.uppercased() < $1.uppercased() }
            //
            //                let indexStrings = array.map({ (string:String) -> String in
            //                    return string.uppercased()
            //                })
            
            if let active = self.searchController?.isActive, active {
                if let filteredStrings = self.strings?.filter({ (string:String) -> Bool in
                    if let text = self.searchController?.searchBar.text {
                        return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                    } else {
                        return false
                    }
                }) {
                    self.filteredStrings = filteredStrings.count > 0 ? filteredStrings : nil
                    
                    //                        print(self.filteredStrings)
                    
                    let indexStrings = self.filteredStrings?.map({ (string:String) -> String in
                        return string.uppercased()
                    })
                    
                    self.filteredSection.build(indexStrings)
                    
                    //                        print(self.filteredSection.titles)
                }
            }
            
            if  let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause,
                let creating = self.mediaListGroupSort?.lexicon?.creating, creating {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    //                        self.tableView.sizeToFit()
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
                if self.indexStrings != nil {
                    height += self.tableView.sectionHeaderHeight * CGFloat(self.indexStrings!.count)
                }
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
                        //                            self.view.isUserInteractionEnabled = true
                        self.refreshControl?.endRefreshing()
                        //                            self.removeRefreshControl()
                    }
                } else {
                    // Fallback on earlier versions
                    if self.isRefreshing {
                        //                            self.view.isUserInteractionEnabled = true
                        self.refreshControl?.endRefreshing()
                        //                            self.removeRefreshControl()
                        self.isRefreshing = false
                    }
                }
            })
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
            
            self.strings = strings.count > 0 ? strings.sorted() { $0.uppercased() < $1.uppercased() } : nil

            self.indexStrings = self.strings?.map({ (string:String) -> String in
                return string.uppercased()
            })
            
//            if let strings = self.strings {
//                let array = Array(Set(strings))
//                
//            }
            
            self.section.build(self.indexStrings)
            
            if let active = self.searchController?.isActive, active {
                if let filteredStrings = self.strings?.filter({ (string:String) -> Bool in
                    if let text = self.searchController?.searchBar.text {
                        return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                    } else {
                        return false
                    }
                }) {
                    self.filteredStrings = filteredStrings.count > 0 ? filteredStrings : nil
                    
//                    print(self.filteredStrings)
                    
                    let indexStrings = self.filteredStrings?.map({ (string:String) -> String in
                        return string.uppercased()
                    })
                    
                    self.filteredSection.build(indexStrings)
                    
//                    print(self.filteredSection.titles)
                }
            }
            
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
                
//                self.view.isUserInteractionEnabled = true
                
                self.removeRefreshControl()
//                self.tableView.bounces = false

                if  let count = self.mediaListGroupSort?.lexicon?.entries?.count,
                    let total = self.mediaListGroupSort?.lexicon?.eligible?.count {
                    self.navigationItem.title = "Lexicon \(count) of \(total)"
                }
                
//                self.navigationItem.title = "Lexicon Complete"

                self.tableView.reloadData()
                self.setPreferredContentSize()

                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.isHidden = true

                if let active = self.searchController?.isActive, active {
                    if self.filteredStrings?.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: .top, animated: true)
                    }
                } else {
                    if self.strings?.count > 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0,section: 0), at: .top, animated: true)
                    }
                }
                
                self.tableView.setContentOffset(CGPoint(x:0, y:0), animated: false)
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
            if showIndex {
                if (self.indexStrings?.count > 1) {
                    section.build(self.indexStrings)
                } else {
                    showIndex = false
                }
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
                    
                    self.section.build(self.indexStrings)
                    
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
                mediaListGroupSort?.lexicon?.build()
            } else {
                if let creating = mediaListGroupSort!.lexicon?.creating, creating {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.lexiconUpdated()
                    }
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
        if showIndex {
            if let active = searchController?.isActive, active {
                return filteredSection.titles != nil ? filteredSection.titles!.count : 0
            } else {
                return section.titles != nil ? section.titles!.count : 0
            }
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if showIndex {
            if let active = searchController?.isActive, active {
                return self.filteredSection.counts != nil ? ((section < self.filteredSection.counts?.count) ? self.filteredSection.counts![section] : 0) : 0
            } else {
                return self.section.counts != nil ? ((section < self.section.counts?.count) ? self.section.counts![section] : 0) : 0
            }
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showIndex {
            if let active = searchController?.isActive, active {
                return filteredSection.titles
            } else {
                return section.titles
            }
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showIndex {
            if let pause = mediaListGroupSort?.lexicon?.pauseUpdates, !pause, let creating = mediaListGroupSort?.lexicon?.creating, creating {
                mediaListGroupSort?.lexicon?.pauseUpdates = true
                
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
        if showIndex, showSectionHeaders { // showIndex &&
            if let active = searchController?.isActive, active {
                return self.filteredSection.titles?[section]
            } else {
                return self.section.titles?[section]
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell

        var index = -1
        
        if (showIndex) {
            if let active = searchController?.isActive, active {
                index = filteredSection.indexes != nil ? (indexPath.section < filteredSection.indexes?.count ? filteredSection.indexes![indexPath.section] + indexPath.row : -1) : -1
            } else {
                index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
            }
        } else {
            index = indexPath.row
        }
        
        if index == -1 {
            print("ERROR")
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            var string:String!

            if let active = searchController?.isActive, active {
                string = filteredStrings?[index]
            } else {
                string = strings?[index]
            }

            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (string == Constants.All)) {
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
            if (globals.groupings[index] == globals.grouping) {
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

        if let active = searchController?.isActive, active {
            if (index >= 0) && (index < filteredStrings?.count) {
                cell.title.text = filteredStrings?[index]
            }
        } else {
            if (index >= 0) && (index < strings?.count) {
                cell.title.text = strings?[index]
            }
        }
        
//        print("CELL:",cell.title.text)

        return cell
    }

    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)

        var index = -1
        
        if (showIndex) {
            if let active = searchController?.isActive, active {
                index = filteredSection.indexes != nil ? filteredSection.indexes![indexPath.section] + indexPath.row : -1
            } else {
                index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
            }
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
            if let active = searchController?.isActive, active {
                delegate?.rowClickedAtIndex(index, strings: filteredStrings, purpose: purpose!, mediaItem: selectedMediaItem)
            } else {
                delegate?.rowClickedAtIndex(index, strings: strings, purpose: purpose!, mediaItem: selectedMediaItem)
            }
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
