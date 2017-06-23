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

extension PopoverTableViewController : UIAdaptivePresentationControllerDelegate
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

extension PopoverTableViewController: UISearchBarDelegate
{
    //MARK: SearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarShouldBeginEditing",completion:nil)
            return false
        }
        
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidBeginEditing",completion:nil)
            return
        }
        
        searchActive = true
        
        // To make sure we start out right
        filteredSection.showIndex = unfilteredSection.showIndex
        filteredSection.showHeaders = unfilteredSection.showHeaders
        
        searchBar.showsCancelButton = true
        
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….
            
            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                print(self.filteredStrings)
                
                filteredSection.build()
                
                tableView.reloadData()
            }
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarTextDidEndEditing",completion:nil)
            return
        }
        
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….
            
            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                self.filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                print(self.filteredStrings)
                
                filteredSection.build()
                
                tableView.reloadData()
                
                //                print(filteredSection.titles)
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBar:textDidChange",completion:nil)
            return
        }
        
        if let text = searchBar.text { // , (text.isEmpty == false)
            
            // update the search result array by filtering….

            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            }) {
                self.filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
//                print(self.filteredStrings)
                
                filteredSection.build()
                
                tableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        //        print("searchBarSearchButtonClicked:")

        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarSearchButtonClicked",completion:nil)
            return
        }
        
        searchBar.resignFirstResponder()
        
        tableView.reloadData()

//        print(searchController?.isActive)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:searchBarCancelButtonClicked",completion:nil)
            return
        }
        
        searchActive = false
        
        // In case they've changed
        unfilteredSection.showIndex = filteredSection.showIndex
        unfilteredSection.showHeaders = filteredSection.showHeaders

        // In case the method changed
        if let function = sort.function {
            section.strings = function(sort.method,section.strings)
        }

        section.build()
        
        searchBar.showsCancelButton = false
       
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        tableView.reloadData()
    }
}

extension PopoverTableViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose: PopoverPurpose, mediaItem: MediaItem?)
    {
        guard Thread.isMainThread else {
            return
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingSorting:
            sort.method = string
            
            if let function = sort.function {
                section.strings = function(sort.method,section.strings)
            }
            
            switch string {
            case Constants.Sort.Alphabetical:
                section.showIndex = true
                break
                
            case Constants.Sort.Frequency:
                section.showIndex = false
                break
                
            default:
                break
            }
            
            section.build()
            
            tableView.reloadData()
            break

        default:
            break
        }
    }
}

extension PopoverTableViewController : UIPopoverPresentationControllerDelegate
{
    
}

struct Sort
{
    var function : ((String,[String]?)->[String]?)?
    
    var method : String = Constants.Sort.Alphabetical
    {
        willSet {
            
        }
        didSet {
            if method != oldValue {
//                print(method)
            }
        }
    }
}

class PopoverTableViewController : UIViewController
{
    var vc:UIViewController?
    
    var selectedText:String!

    var sort = Sort()
    
    var search          = false
    var searchActive    = false
    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedMediaItem:MediaItem?
    
    var transcript:VoiceBase?
    
    var stringsFunction:((Void)->[String]?)?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var mediaListGroupSort:MediaListGroupSort?
    
    var indexTransform:((String?)->String?)? = stringWithoutPrefixes {
        willSet {
            
        }
        didSet {
            filteredSection.indexTransform = indexTransform
            unfilteredSection.indexTransform = indexTransform
        }
    }
    
    var filteredSection = Section()
    var unfilteredSection = Section()
    
    var section:Section! {
        get {
            if searchActive {
                return filteredSection
            } else {
                return unfilteredSection
            }
        }
        set {
            if searchActive {
                filteredSection = newValue
            } else {
                unfilteredSection = newValue
            }
        }
    }
    
    func setPreferredContentSize()
    {
        guard Thread.isMainThread else {
            return
        }

        guard (vc != nil) else {
            return
        }
        
        guard (section.strings != nil) else {
            return
        }
        
        let margins:CGFloat = 2
        let marginSpace:CGFloat = 9
        
        let checkmarkSpace:CGFloat = 38
        let indexSpace:CGFloat = 40
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0
        
        var deducts:CGFloat = 0
        
        deducts += margins * marginSpace
        
        if section.showIndex {
            deducts += indexSpace
        }
        
        switch self.purpose! {
        case .selectingCategory:
            fallthrough
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
        
        let viewWidth = vc!.view.frame.width
        
        //        print(view.frame.width - deducts)
        
        let heightSize: CGSize = CGSize(width: viewWidth - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)
        
        if let title = self.navigationItem.title {
            let string = title.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            width = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).width
        }
        
        //        print(strings)
        
        for string in self.section.strings! {
            let string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)
            
            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
            
            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.normal, context: nil)
            
            //            print(string)
            //            print(maxSize)
            
            //            print(string,width,maxWidth.width)
            
            if maxWidth.width > width {
                width = maxWidth.width
            }
            
            //            print(string,maxHeight.height) // baseHeight
            
            if tableView.rowHeight != -1 {
                height += tableView.rowHeight
            } else {
                height += 2*8 + maxHeight.height // - baseHeight
            }
            
            //            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
        }
        
        width += margins * marginSpace
        
        switch self.purpose! {
        case .selectingCategory:
            fallthrough
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
        
        if self.section.showIndex {
            width += indexSpace
            height += self.tableView.sectionHeaderHeight * CGFloat(self.section.indexStrings!.count)
        }
        
//        print(height)
//        print(width)
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    var isRefreshing = false
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "PopoverTableViewController:handleRefresh",completion:nil)
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            refreshControl.beginRefreshing()
        })

        self.lexiconUpdated()
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
    
//    var searchController:UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.autocapitalizationType = .none

        if !search {
            searchBar.removeFromSuperview()
            tableViewTopConstraint.constant = 0
        }
        
        if mediaListGroupSort != nil {
            addRefreshControl()
            
            mediaListGroupSort?.lexicon?.pauseUpdates = false
        }

        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }
    }
    
    func selectString(_ string:String?,scroll:Bool,select:Bool)
    {
        guard (string != nil) else {
            return
        }
        
        selectedText = string
        
//        if let active = self.searchController?.isActive, active {
        if let selectedText = selectedText,  let index = section.strings?.index(where: { (string:String) -> Bool in
            return selectedText.uppercased() == string.substring(to: string.range(of: " (")!.lowerBound).uppercased()
        }) {
            //                if let selectedText = self.selectedText, let index = self.filteredStrings?.index(of: selectedText) {
            var i = 0
            
            repeat {
                i += 1
            } while (i < self.section.indexes?.count) && (self.section.indexes?[i] <= index)
            
            let section = i - 1
            
            if let base = self.section.indexes?[section] {
                let row = index - base
                
                if self.section.strings?.count > 0 {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if section < self.tableView.numberOfSections, row < self.tableView.numberOfRows(inSection: section) {
                            let indexPath = IndexPath(row: row,section: section)
                            if scroll {
                                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                            }
                            if select {
                                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            }
                        } else {
                            alert(viewController:self,title:"String not found!",message:"THIS SHOULD NOT HAPPEN.",completion:nil)
                        }
                    })
                }
            }
        } else {
            alert(viewController:self,title:"String not found!",message:"Search is active and the string \(selectedText!) is not in the results.",completion:nil)
        }
    }
    
    func lexiconStarted()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator.startAnimating()
            self.activityIndicator?.isHidden = false
        })
    }
    
    func lexiconUpdated()
    {
        guard let pause = mediaListGroupSort?.lexicon?.pauseUpdates, !pause else {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            if let completed = self.mediaListGroupSort?.lexicon?.completed, !completed {
                self.activityIndicator.startAnimating()
                self.activityIndicator?.isHidden = false
            }
        })
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.updateTitle()
        })

        unfilteredSection.strings = mediaListGroupSort?.lexicon?.section.strings
        
        if let function = sort.function {
            unfilteredSection.strings = function(sort.method,unfilteredSection.strings)
        }

        if sort.method == Constants.Sort.Alphabetical {
            unfilteredSection.titles = mediaListGroupSort?.lexicon?.section.titles
        }

        unfilteredSection.build()

        if searchActive {
            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                if let text = searchBar.text {
                    return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                } else {
                    return false
                }
            }) {
                self.filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
                //                        print(self.filteredStrings)
                
                self.filteredSection.build()
                
                //                        print(self.filteredSection.titles)
            }
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            if let pause = self.mediaListGroupSort?.lexicon?.pauseUpdates, !pause {
                self.tableView.reloadData()
            }
        })
        
        DispatchQueue.main.async(execute: { () -> Void in
            if let completed = self.mediaListGroupSort?.lexicon?.completed, completed {
                self.activityIndicator.stopAnimating()
                self.activityIndicator?.isHidden = true
            }
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
        })
    }
    
    func lexiconCompleted()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.activityIndicator.startAnimating()
            self.activityIndicator?.isHidden = false
        })
        
        unfilteredSection.strings = mediaListGroupSort?.lexicon?.section.strings
        
        if let function = sort.function {
            unfilteredSection.strings = function(sort.method,unfilteredSection.strings)
        }

        if sort.method == Constants.Sort.Alphabetical {
            unfilteredSection.titles = mediaListGroupSort?.lexicon?.section.titles
        }
        
        unfilteredSection.build()

        if searchActive {
            if let filteredStrings = unfilteredSection.strings?.filter({ (string:String) -> Bool in
                if let text = searchBar.text {
                    return string.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
                } else {
                    return false
                }
            }) {
                filteredSection.strings = filteredStrings.count > 0 ? filteredStrings : nil
                
//                    print(self.filteredStrings)
                
                self.filteredSection.build()
                
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
            
            self.updateTitle()
            
            self.tableView.reloadData()

            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.isHidden = true
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
        
        if mediaListGroupSort != nil {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: mediaListGroupSort?.lexicon)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: mediaListGroupSort?.lexicon)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: mediaListGroupSort?.lexicon)
        }
    }
    
    func sortAction()
    {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingSorting
            
            popover.section.strings = [Constants.Sort.Alphabetical,Constants.Sort.Frequency]
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            popover.vc = self
            
            ptvc = popover
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateTitle()
    {
        if  let count = self.mediaListGroupSort?.lexicon?.entries?.count,
            let total = self.mediaListGroupSort?.lexicon?.eligible?.count {
            self.navigationItem.title = "Lexicon \(count) of \(total)"
        }
    }
    
    var ptvc:PopoverTableViewController?
    
    func deviceOrientationDidChange()
    {
        // Dismiss any popover
        ptvc?.dismiss(animated: false, completion: nil)
    }
    
    func willResignActive()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.willResignActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        if sort.function != nil {
            navigationItem.setRightBarButton(UIBarButtonItem(title: "Sort", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PopoverTableViewController.sortAction)),animated: true)
        }
        
        if mediaListGroupSort != nil {
            DispatchQueue(label: "CBC").async(execute: { () -> Void in
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconStarted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: self.mediaListGroupSort?.lexicon)
                NotificationCenter.default.addObserver(self, selector: #selector(PopoverTableViewController.lexiconCompleted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: self.mediaListGroupSort?.lexicon)
            })
            
            if  let completed = mediaListGroupSort?.lexicon?.completed, !completed {
                // Start lexicon creation if it isn't already being created.
                if let creating = mediaListGroupSort?.lexicon?.creating, !creating {
                    mediaListGroupSort?.lexicon?.build()
                }
                lexiconUpdated()
            } else {
                lexiconCompleted()
            }
        } else

        if stringsFunction != nil {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.startAnimating()
                    self.activityIndicator?.isHidden = false
                })
                
                self.section.strings = self.stringsFunction?()
                
                if self.section.strings != nil {
                    self.section.build()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        self.setPreferredContentSize()
                        
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator?.isHidden = true
                    })
                }
            }
        } else

        if section.strings != nil {
            if section.showIndex {
                if (self.section.indexStrings?.count > 1) {
                    section.build()
                } else {
                    section.showIndex = false
                }
            }

            tableView.reloadData()
            
            setPreferredContentSize()
            
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.isHidden = true
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
}

extension PopoverTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if section.showIndex {
            return section.titles != nil ? section.titles!.count : 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if self.section.showIndex {
            return self.section.counts != nil ? ((section < self.section.counts?.count) ? self.section.counts![section] : 0) : 0
        } else {
            return self.section.strings != nil ? self.section.strings!.count : 0
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if section.showIndex {
            return section.titles
        } else {
            return nil
        }
    }
    
    //    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //        return 48
    //    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if section.showIndex {
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.section.showIndex, self.section.showHeaders { // showIndex &&
            //        if let active = self.searchController?.isActive, active {
            if let count = self.section.titles?.count, section < count {
                return self.section.titles?[section]
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell
        
        cell.title.text = nil
        cell.title.attributedText = nil
        
        var index = -1
        
        if (section.showIndex) {
            //        if let active = self.searchController?.isActive, active {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        guard index > -1 else {
            print("ERROR")
            return cell
        }
        
        var string:String!
        
        string = section.strings?[index]

        // Configure the cell...
        switch purpose! {
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            
            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (string == Constants.Strings.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingCategory:
            if (globals.mediaCategory.names?[index] == globals.mediaCategory.selected) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
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
            
            if let sorting = (vc as? PopoverTableViewController)?.sort.method {
                //                print(sorting, string)
                if sorting == string {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
            }
            
            if let sorting = (vc as? LexiconIndexViewController)?.ptvc.sort.method {
                //                print(sorting, string)
                if sorting == string {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
            }
            break
            
        default:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        }
        
        //        print(strings)
        
        //        if let active = self.searchController?.isActive, active {
        if (index >= 0) && (index < section.strings?.count) {
            if let title = section.strings?[index] {
                if search, let searchText = searchBar.text, title.lowercased().contains(searchText.lowercased()) {
                    let titleString = NSMutableAttributedString()
                    
                    var before:String?
                    var string:String?
                    var after:String?
                    
                    if let range = title.lowercased().range(of: searchText.lowercased()) {
                        before = title.substring(to: range.lowerBound)
                        string = title.substring(with: range)
                        after = title.substring(from: range.upperBound)
                        
                        if let before = before {
                            titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                        }
                        if let string = string {
                            titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                        }
                        if let after = after {
                            titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                        }
                    }

                    cell.title.text = title
                    cell.title.attributedText = titleString
                } else {
                    cell.title.text = title
                    cell.title.attributedText = NSAttributedString(string:title,attributes:Constants.Fonts.Attributes.normal)
                }
            }
        }
        
        //        print("CELL:",cell.title.text)
        
        return cell
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
}

extension PopoverTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if search {
            DispatchQueue.main.async(execute: { () -> Void in
                self.searchBar.resignFirstResponder()
            })
        }
        
        var index = -1
        
        if (section.showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
            if let range = section.strings?[index].range(of: " (") {
                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
            }
        } else {
            index = indexPath.row
            if let range = section.strings?[index].range(of: " (") {
                selectedText = section.strings?[index].substring(to: range.lowerBound).uppercased()
            }
        }
        
        //        print(index,strings![index])
        
        switch purpose! {
            
        default:
            delegate?.rowClickedAtIndex(index, strings: section.strings, purpose: purpose!, mediaItem: selectedMediaItem)
            break
        }
    }
}
