//
//  MediaTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

enum PopoverPurpose {
    case selectingShow

    case selectingSorting
    case selectingGrouping
    case selectingSection
    
    case selectingHistory
    
    case selectingCellAction
    
    case selectingAction
    
    case selectingTags

    case showingTags
    case editingTags
}

class MediaTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate, NSURLSessionDownloadDelegate {

    override func canBecomeFirstResponder() -> Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }

    var refreshControl:UIRefreshControl?

    var session:NSURLSession? // Used for JSON

    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    var progressTimer:NSTimer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(button: UIBarButtonItem) {
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
//                popover.navigationItem.title = "Show"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingShow
                
                var showMenu = [String]()
                
                if (self.splitViewController != nil) {
                    // What if it is collapsed and the detail view is showing?
                    if (!globals.showingAbout) {
                        showMenu.append(Constants.About)
                    }
                } else {
                    showMenu.append(Constants.About)
                }
                
                //Because the list extends above and below the visible area, visibleCells is deceptive - the cell can be hidden behind a navbar or toolbar and still returned in the array of visibleCells.
                if (globals.display.sermons != nil) && (selectedSermon != nil) { // && (globals.display.sermons?.indexOf(selectedSermon!) != nil)
                    showMenu.append(Constants.Current_Selection)
                }
                
                if (globals.player.playing != nil) {
                    var show:String = Constants.EMPTY_STRING
                    
                    if (globals.player.paused) {
                        show = Constants.Sermon_Paused
                    } else {
                        show = Constants.Sermon_Playing
                    }
                    
                    if (self.splitViewController != nil) {
                        if let nvc = self.splitViewController!.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                            if let myvc = nvc.topViewController as? MediaViewController {
                                if (myvc.selectedSermon != nil) {
                                    if (myvc.selectedSermon?.title != globals.player.playing?.title) || (myvc.selectedSermon?.date != globals.player.playing?.date) {
                                        // The sermonPlaying is not the one showing
                                        showMenu.append(show)
                                    } else {
                                        // The sermonPlaying is the one showing
                                    }
                                } else {
                                    // There is no selectedSermon - which should never happen
                                    print("There is no selectedSermon - which should never happen")
                                }
                            } else {
                                // About is showing
                                showMenu.append(show)
                            }
                        }
                    } else {
                        //Always show it
                        showMenu.append(show)
                    }
                } else {
                    //Nothing to show
                }
                
                if (splitViewController != nil) {
                    showMenu.append(Constants.Scripture_Index)
                }
                
                showMenu.append(Constants.History)
                
                showMenu.append(Constants.Clear_History)
                
                showMenu.append(Constants.Live)
                
                showMenu.append(Constants.Settings)
                
                popover.strings = showMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    var selectedSermon:Sermon? {
        didSet {
            let defaults = NSUserDefaults.standardUserDefaults()
            if (selectedSermon != nil) {
                defaults.setObject(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_KEY)
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
//                defaults.removeObjectForKey(Constants.SELECTED_SERMON_KEY)
            }
            defaults.synchronize()
        }
    }
    
    var popover : PopoverTableViewController?
    
    func disableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.enabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.leftBarButtonItem?.enabled = false
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if (globals.sermonRepository.list != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.enabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (globals.sermonRepository.list != nil) {
            navigationItem.leftBarButtonItem?.enabled = true
            enableToolBarButtons()
        }
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                sermon?.audioDownload?.deleteDownload()
                break
                
            case Constants.Cancel_Audio_Download:
                sermon?.audioDownload?.cancelOrDeleteDownload()
                break
                
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
                break
                
            default:
                break
            }
            break

        case .selectingHistory:
            var sermonID:String
            if let range = globals.history!.reverse()[index].rangeOfString(Constants.TAGS_SEPARATOR) {
                sermonID = globals.history!.reverse()[index].substringFromIndex(range.endIndex)
            } else {
                sermonID = globals.history!.reverse()[index]
            }
            if let sermon = globals.sermonRepository.index![sermonID] {
                if globals.activeSermons!.contains(sermon) {
                    selectOrScrollToSermon(sermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                } else {
                    dismissViewControllerAnimated(true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not in List",
                        message: "You are currently showing sermons tagged with \"\(globals.sermonTagsSelected!)\" and the sermon \"\(sermon.title!)\" does not have that tag.  Show sermons tagged with \"All\" and try again.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                
                let alert = UIAlertController(title:"Sermon Not Found!",
                    message: "Yep, a genuine error - this should never happen!",
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                presentViewController(alert, animated: true, completion: nil)
            }
            break
            
        case .selectingTags:
            
            // Should we be showing globals.active!.sermonTags instead?  That would be the equivalent of drilling down.

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                //                    if (index >= 0) && (index <= globals.sermons.all!.sermonTags!.count) {
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch strings[index] {
                    case Constants.All:
                        if (globals.showing != Constants.ALL) {
                            new = true
                            globals.showing = Constants.ALL
                            globals.sermonTagsSelected = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        
                        let tagSelected = strings[index]
                        
                        new = (globals.showing != Constants.TAGGED) || (globals.sermonTagsSelected != tagSelected)
                        
                        if (new) {
                            //                                print("\(globals.active!.sermonTags)")
                            
                            globals.sermonTagsSelected = tagSelected
                            
                            globals.showing = Constants.TAGGED
                        }
                        break
                    }
                    
                    if (new) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            globals.clearDisplay()
                            
                            self.tableView.reloadData()
                            
                            self.listActivityIndicator.hidden = false
                            self.listActivityIndicator.startAnimating()
                            
                            self.disableBarButtons()
                        })
                        
                        if (globals.searchActive) {
                            self.updateSearchResults()
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            globals.setupDisplay()
                            
                            self.tableView.reloadData()
                            self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                            
                            self.listActivityIndicator.stopAnimating()
                            self.listActivityIndicator.hidden = true
                            
                            self.enableBarButtons()
                            
                            self.setupSearchBar()
                        })
                    }
                } else {
                    print("Index out of range")
                }
            })
            break
            
        case .selectingSection:
            dismissViewControllerAnimated(true, completion: nil)
            let indexPath = NSIndexPath(forRow: 0, inSection: index)
            
            //Too slow
            //                if (globals.grouping == Constants.SERIES) {
            //                    let string = strings[index]
            //
            //                    if (string != Constants.Individual_Sermons) && (globals.sermonSectionTitles.series?.indexOf(string) == nil) {
            //                        let index = globals.sermonSectionTitles.series?.indexOf(Constants.Individual_Sermons)
            //
            //                        var sermons = [Sermon]()
            //
            //                        for sermon in globals.activeSermons! {
            //                            if !sermon.hasSeries() {
            //                                sermons.append(sermon)
            //                            }
            //                        }
            //
            //                        let sortedSermons = sortSermons(sermons, sorting: globals.sorting, grouping: globals.grouping)
            //
            //                        let row = sortedSermons?.indexOf({ (sermon) -> Bool in
            //                            return string == sermon.title
            //                        })
            //
            //                        indexPath = NSIndexPath(forRow: row!, inSection: index!)
            //                    } else {
            //                        let sections = seriesFromSermons(globals.activeSermons,withTitles: false)
            //                        let section = sections?.indexOf(string)
            //                        indexPath = NSIndexPath(forRow: 0, inSection: section!)
            //                    }
            //                }
            
            //Can't use this reliably w/ variable row heights.
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            break
            
        case .selectingGrouping:
            dismissViewControllerAnimated(true, completion: nil)
            globals.grouping = Constants.groupings[index]
            
            if (globals.sermonsNeed.grouping) {
                globals.clearDisplay()
                
                tableView.reloadData()
                
                listActivityIndicator.hidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    globals.progress = 0
                    globals.finished = 0
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
                    })
                    
                    globals.setupDisplay()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                        self.listActivityIndicator.stopAnimating()
                        self.enableBarButtons()
                    })
                })
            }
            break
            
        case .selectingSorting:
            dismissViewControllerAnimated(true, completion: nil)
            globals.sorting = Constants.sortings[index]
            
            if (globals.sermonsNeed.sorting) {
                globals.clearDisplay()
                tableView.reloadData()
                
                listActivityIndicator.hidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    globals.setupDisplay()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                        self.listActivityIndicator.stopAnimating()
                        self.enableBarButtons()
                        //
                        //                            if (self.splitViewController != nil) {
                        //                                //iPad only
                        //                                if let nvc = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        //                                    if let myvc = nvc.visibleViewController as? MediaViewController {
                        //                                        myvc.sortSermonsInSeries()
                        //                                    }
                        //                                }
                        //
                        //                            }
                    })
                })
            }
            break
            
        case .selectingShow:
            dismissViewControllerAnimated(true, completion: nil)
            switch strings[index] {
            case Constants.About:
                about()
                break
                
            case Constants.Current_Selection:
                if let sermon = selectedSermon {
                    if globals.activeSermons!.contains(sermon) {
                        selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                    } else {
                        dismissViewControllerAnimated(true, completion: nil)
                        
                        let alert = UIAlertController(title:"Sermon Not in List",
                            message: "You are currently showing sermons tagged with \"\(globals.sermonTagsSelected!)\" and the sermon \"\(sermon.title!)\" does not have that tag.  Show sermons tagged with \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    dismissViewControllerAnimated(true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not Found!",
                        message: "Yep, a genuine error - this should never happen!",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    presentViewController(alert, animated: true, completion: nil)
                }
                break
                
            case Constants.Sermon_Playing:
                fallthrough
                
            case Constants.Sermon_Paused:
                globals.gotoPlayingPaused = true
                performSegueWithIdentifier(Constants.Show_Sermon, sender: self)
                break
                
            case Constants.Scripture_Index:
                performSegueWithIdentifier(Constants.Show_Scripture_Index, sender: nil)
                break
                
            case Constants.History:
                if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .Popover
                        //            popover?.preferredContentSize = CGSizeMake(300, 500)
                        
                        navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.barButtonItem = showButton
                        
                        popover.navigationItem.title = Constants.History
                        
                        popover.delegate = self
                        popover.purpose = .selectingHistory
                        
                        var historyMenu = [String]()
//                        var sections = [String]()
                        
//                        print(globals.history)
                        if let historyList = globals.history?.reverse() {
//                            print(historyList)
                            for history in historyList {
                                var sermonID:String
//                                var date:String
                                
                                if let range = history.rangeOfString(Constants.TAGS_SEPARATOR) {
                                    sermonID = history.substringFromIndex(range.endIndex)
//                                    date = history.substringToIndex(range.startIndex)
                                    
                                    if let sermon = globals.sermonRepository.index![sermonID] {
                                        historyMenu.append(sermon.text!)
                                    }
                                }
                            }
                        }
                        
                        popover.strings = historyMenu
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false // true if the code below and related code above is used. 
                        
//                        var indexes = [Int]()
//                        var counts = [Int]()
//                        
//                        var lastSection:String?
//                        let sectionList = sections
//                        var index = 0
//                        
//                        for sectionTitle in sectionList {
//                            if sectionTitle == lastSection {
//                                sections.removeAtIndex(index)
//                            } else {
//                                index++
//                            }
//                            lastSection = sectionTitle
//                        }
//                        
//                        popover.section.titles = sections
//
//                        let historyList = globals.history?.reverse()
//                        
//                        for historyItem in historyList! {
//                            var counter = 0
//                            
//                            if let range = historyItem.rangeOfString(Constants.TAGS_SEPARATOR) {
//                                var date:String
//
//                                date = historyItem.substringToIndex(range.startIndex)
//                                
//                                for index in 0..<sections.count {
//                                    if (sections[index] == date.substringToIndex(date.rangeOfString(" ")!.startIndex)) {
//                                        if (counter == 0) {
//                                            indexes.append(index)
//                                        }
//                                        counter++
//                                    }
//                                }
//                                
//                                counts.append(counter)
//                            }
//                        }
//                        
//                        popover.section.indexes = indexes.count > 0 ? indexes : nil
//                        popover.section.counts = counts.count > 0 ? counts : nil

                        presentViewController(navigationController, animated: true, completion: nil)
                    }
                }
                break
                
            case Constants.Clear_History:
                globals.history = nil
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.removeObjectForKey(Constants.HISTORY)
                defaults.synchronize()
                break
                
            case Constants.Live:
                performSegueWithIdentifier(Constants.Show_Live, sender: nil)
                break
                
            case Constants.Settings:
                performSegueWithIdentifier(Constants.Show_Settings, sender: nil)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func willPresentSearchController(searchController: UISearchController) {
//        print("willPresentSearchController")
        globals.searchActive = true
    }
    
    func willDismissSearchController(searchController: UISearchController)
    {
        globals.searchActive = false
    }
    
    func didDismissSearchController(searchController: UISearchController)
    {
        didDismissSearch()
    }
    
    func didDismissSearch() {
        globals.sermons.search = nil
        
        listActivityIndicator.hidden = false
        listActivityIndicator.startAnimating()
        
        globals.clearDisplay()
        
        tableView.reloadData()
        
        disableBarButtons()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            globals.setupDisplay()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.listActivityIndicator.stopAnimating()
                self.enableBarButtons()
                
                //Moving the list can be very disruptive
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
            })
        })
    }
    
    func index(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Index"
                
                popover.delegate = self
                
                popover.purpose = .selectingSection
                popover.strings = globals.active?.sectionTitles
                
                popover.showIndex = (globals.grouping == Constants.SERIES)
                popover.showSectionHeaders = (globals.grouping == Constants.SERIES)
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

        // Too slow
//        if (globals.grouping == Constants.SERIES) {
//            let strings = seriesFromSermons(globals.activeSermons,withTitles: true)
//            popover?.strings = strings
//        } else {
//            popover?.strings = globals.sermonSections
//        }
    }

    func grouping(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Group Sermons By"
                
                popover.delegate = self
                
                popover.purpose = .selectingGrouping
                popover.strings = Constants.Groupings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func sorting(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Sermon Sorting"
                
                popover.delegate = self
                
                popover.purpose = .selectingSorting
                popover.strings = Constants.Sortings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }

    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    private func setupShowMenu()
    {
        let showButton = navigationItem.leftBarButtonItem
        
        showButton?.title = Constants.FA_REORDER
        showButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_SHOW_FONT_SIZE)!], forState: UIControlState.Normal)
        
        showButton?.enabled = (globals.sermons.all != nil) //&& !globals.sermonsSortingOrGrouping
    }
    
    private func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sorting, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaTableViewController.sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Grouping, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaTableViewController.grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Index, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MediaTableViewController.index(_:)))

        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)

        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        barButtons.append(sortingButton)
        barButtons.append(spaceButton)
        barButtons.append(groupingButton)
        barButtons.append(spaceButton)
        barButtons.append(indexButton)
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.translucent = false
        
        if (globals.sermonRepository.list == nil) {
            disableToolBarButtons()
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        print("searchBar:textDidChange:")
        //Unstable results from incremental search
//        updateSearchResults()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        print("searchBarSearchButtonClicked:")
        searchBar.resignFirstResponder()
        updateSearchResults()
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool
    {
        return !globals.loading && !globals.refreshing && (globals.sermons.all != nil) // !globals.sermonsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        globals.searchActive = true
        searchBar.showsCancelButton = true
        
        globals.clearDisplay()
        tableView.reloadData()
        disableToolBarButtons()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked:")
        searchBar.showsCancelButton = false
        globals.searchActive = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        didDismissSearch()
    }
    
    /* Not ready for release

    func deepLink()
    {
        // This should be rationalized with the code in AppDelegate to have one function (somewhere) so we aren't duplicating it.
        
        globals.deepLinkWaiting = false

        let path = globals.deepLink.path
        let searchString = globals.deepLink.searchString
        let sorting = globals.deepLink.sorting
        let grouping = globals.deepLink.grouping
        let sermonTag = globals.deepLink.tag

        globals.deepLink.path = nil
        globals.deepLink.searchString = nil
        globals.deepLink.sorting = nil
        globals.deepLink.grouping = nil
        globals.deepLink.tag = nil

        var sermonSelected:Sermon?

        var seriesSelected:String?
        var firstSermonInSeries:Sermon?
        
        var bookSelected:String?
        var firstSermonInBook:Sermon?
        
//        var seriesIndexPath = NSIndexPath()
        
        if (path != nil) {
            //                print("path: \(path)")
            
            // Is it a series?
            if let sermonSeries = seriesSectionsFromSermons(globals.sermons) {
                for sermonSeries in sermonSeries {
                    //                        print("sermonSeries: \(sermonSeries)")
                    if (sermonSeries == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                        //It is a series
                        seriesSelected = sermonSeries
                        break
                    }
                }
                
                if (seriesSelected != nil) {
                    var sermonsInSelectedSeries = sermonsInSermonSeries(globals.sermons,series: seriesSelected!)
                    
                    if (sermonsInSelectedSeries?.count > 0) {
                        if let firstSermonIndex = globals.sermons!.indexOf(sermonsInSelectedSeries![0]) {
                            firstSermonInSeries = globals.sermons![firstSermonIndex]
                            //                            print("firstSermon: \(firstSermon)")
                        }
                    }
                }
            }
            
            if (seriesSelected == nil) {
                // Is it a sermon?
                for sermon in globals.sermons! {
                    if (sermon.title == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                        //Found it
                        sermonSelected = sermon
                        break
                    }
                }
                //                        print("\(sermonSelected)")
            }
            
            if (seriesSelected == nil) && (sermonSelected == nil) {
                // Is it a book?
                if let sermonBooks = bookSectionsFromSermons(globals.sermons) {
                    for sermonBook in sermonBooks {
                        //                        print("sermonBook: \(sermonBook)")
                        if (sermonBook == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //It is a series
                            bookSelected = sermonBook
                            break
                        }
                    }
                    
                    if (bookSelected != nil) {
                        var sermonsInSelectedBook = sermonsInBook(globals.sermons,book: bookSelected!)
                        
                        if (sermonsInSelectedBook?.count > 0) {
                            if let firstSermonIndex = globals.sermons!.indexOf(sermonsInSelectedBook![0]) {
                                firstSermonInBook = globals.sermons![firstSermonIndex]
                                //                            print("firstSermon: \(firstSermon)")
                            }
                        }
                    }
                }
            }
        }
        
        if (sorting != nil) {
            globals.sorting = sorting!
        }
        if (grouping != nil) {
            globals.grouping = grouping!
        }
        
        if (sermonTag != nil) {
            if (sermonTag != Constants.ALL) {
                globals.sermonTagsSelected = sermonTag!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)
                print("\(globals.sermonTagsSelected)")
                globals.showing = Constants.TAGGED
                
                if let sermons = globals.sermons {
                    var taggedSermons = [Sermon]()
                    
                    for sermon in sermons {
                        if (sermon.tags?.rangeOfString(globals.sermonTagsSelected!) != nil) {
                            taggedSermons.append(sermon)
                        }
                    }
                    
                    globals.taggedSermons = taggedSermons.count > 0 ? taggedSermons : nil
                }
            } else {
                globals.showing = Constants.ALL
                globals.sermonTagsSelected = nil
            }
        }
        
        //In case globals.searchActive is true at the start we need to cancel it.
        globals.searchActive = false
        globals.searchSermons = nil
        
        if (searchString != nil) {
            globals.searchActive = true
            globals.searchSermons = nil
            
            if let sermons = globals.sermonsToSearch {
                var searchSermons = [Sermon]()
                
                for sermon in sermons {
                    if (
                        ((sermon.title?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                        )
                    {
                        searchSermons.append(sermon)
                    }
                }
                
                globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
            }
        }
        
        globals.sermonsNeed.groupsSetup = true
        sortAndGroupSermons()
        
        var tvc:MediaTableViewController?
        
        //iPad
        if (splitViewController != nil) {
            //            print("rvc = UISplitViewController")
            if let nvc = splitViewController!.viewControllers[0] as? UINavigationController {
                //                print("nvc = UINavigationController")
                tvc = nvc.topViewController as? MediaTableViewController
            }
            if let nvc = splitViewController!.viewControllers[1] as? UINavigationController {
                //                print("nvc = UINavigationController")
                if let myvc = nvc.topViewController as? MediaViewController {
                    if (sorting != nil) {
                        //Sort the sermonsInSeries
                        myvc.sortSermonsInSeries()
                    }
                }
            }
        }
        
        //iPhone
        if let nvc = navigationController {
            //            print("rvc = UINavigationController")
            if let _ = nvc.topViewController as? MediaViewController {
                //                    print("myvc = MediaViewController")
                nvc.popToRootViewControllerAnimated(true)
                
            }
            tvc = nvc.topViewController as? MediaTableViewController
        }
        
        if (tvc != nil) {
            // All of the scrolling below becomes a problem in portrait on an iPad as the master view controller TVC may not be visible
            // AND when it is made visible it is setup to first scroll to current selection.
            
            //                print("tvc = MediaTableViewController")
            
            //            tvc.performSegueWithIdentifier("Show Sermon", sender: tvc)
            
            tvc!.tableView.reloadData()
            
            if (globals.sermonTagsSelected != nil) {
                tvc!.searchBar.placeholder = globals.sermonTagsSelected!
                
                //Show the search bar
                tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            } else {
                tvc!.searchBar.placeholder = nil
            }
            
            if (searchString != nil) {
                tvc!.searchBar.text = searchString!
//                tvc!.searchBar.becomeFirstResponder()
                tvc!.searchBar.showsCancelButton = true
                
                //Show the search bar
                tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            } else {
                tvc!.searchBar.text = nil
//                tvc!.searchBar.resignFirstResponder()
                tvc!.searchBar.showsCancelButton = false
            }
            
            //It should never occur that more than one of the following conditionals are true
            
            //The calls below are made twice because only calling them once left the scroll in the Middle.
            //Remember, these only occur when the app is being launched in response to a URL.  If the app is
            //already launched this function is replaced by one in the AppDelegate.
            
            //I have no idea why calling these twice makes the difference.
            
            if (firstSermonInSeries != nil) {
                tvc?.selectOrScrollToSermon(firstSermonInSeries, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(firstSermonInSeries, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
            
            if (firstSermonInBook != nil) {
                tvc?.selectOrScrollToSermon(firstSermonInBook, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(firstSermonInBook, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
            
            if (sermonSelected != nil) {
                tvc?.selectOrScrollToSermon(sermonSelected, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(sermonSelected, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
        }
    }
    
    */
    
    func setupViews()
    {
        setupSearchBar()
        
        tableView.reloadData()
        
        enableBarButtons()
        
        listActivityIndicator.stopAnimating()
        
        setupTitle()
        
        addRefreshControl()
        
        selectedSermon = globals.selectedSermon
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
            })
        })
        
        if (splitViewController != nil) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            })
        }
    }
    
    func updateProgress()
    {
//        print("\(Float(globals.progress))")
//        print("\(Float(globals.finished))")
//        print("\(Float(globals.progress) / Float(globals.finished))")
        
        self.progressIndicator.progress = 0
        if (globals.finished > 0) {
            self.progressIndicator.hidden = false
            self.progressIndicator.progress = Float(globals.progress) / Float(globals.finished)
        }
        
        //            print("\(self.progressIndicator.progress)")
        
        if self.progressIndicator.progress == 1.0 {
            self.progressTimer?.invalidate()
            
            self.progressIndicator.hidden = true
            self.progressIndicator.progress = 0
            
            globals.progress = 0
            globals.finished = 0
        }
    }
    
    func loadSermons(completion: (() -> Void)?)
    {
        globals.progress = 0
        globals.finished = 0
        
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            globals.loading = true

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Sermons"
            })
            
            var success = false
            var newSermons:[Sermon]?

//            if let sermons = sermonsFromArchive() {
//                newSermons = sermons
//                success = true
//            } else if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
//                newSermons = sermons
//                sermonsToArchive(sermons)
//                success = true
//            }
        
            if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
                newSermons = sermons
                success = true
            }

            if (!success) {
                // REVERT TO KNOWN GOOD JSON
                removeJSONFromFileSystemDirectory() // This will cause JSON to be loaded from the BUNDLE next time.
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setupTitle()
                    
                    self.listActivityIndicator.stopAnimating()
                    self.listActivityIndicator.hidden = true
                    self.refreshControl?.endRefreshing()
                    
                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                        let alert = UIAlertController(title:"Unable to Load Sermons",
                            message: "Please try to refresh the list.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                })
                return
            }

            var sermonsNewToUser:[Sermon]?
            
            if (globals.sermonRepository.list != nil) {
                
                let old = Set(globals.sermonRepository.list!.map({ (sermon:Sermon) -> String in
                    return sermon.id
                }))
                
                let new = Set(newSermons!.map({ (sermon:Sermon) -> String in
                    return sermon.id
                }))
                
                //                print("\(old.count)")
                //                print("\(new.count)")
                
                let inOldAndNew = old.intersect(new)
                //                print("\(inOldAndNew.count)")
                
                if inOldAndNew.count == 0 {
                    print("There were NO sermons in BOTH the old JSON and the new JSON.")
                }
                
                let onlyInOld = old.subtract(new)
                //                print("\(onlyInOld.count)")
                
                if onlyInOld.count > 0 {
                    print("There were \(onlyInOld.count) sermons in the old JSON that are NOT in the new JSON.")
                }
                
                let onlyInNew = new.subtract(old)
                //                print("\(onlyInNew.count)")
                
                if onlyInNew.count > 0 {
                    print("There are \(onlyInNew.count) sermons in the new JSON that were NOT in the old JSON.")
                }
                
                if (onlyInNew.count > 0) {
                    sermonsNewToUser = onlyInNew.map({ (id:String) -> Sermon in
                        return newSermons!.filter({ (sermon:Sermon) -> Bool in
                            return sermon.id == id
                        }).first!
                    })
                }
            }
            
            globals.sermonRepository.list = newSermons

//            testSermonsTagsAndSeries()
//            
//            testSermonsBooksAndSeries()
//            
//            testSermonsForSeries()
//            
//            //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
//            testSermonsPDFs(testExisting: false, testMissing: true, showTesting: false)
//            
//            //Test whether the audio starts to download
//            //If we can download at all, we assume we can download it all, which allows us to test all sermons to see if they can be downloaded/played.
//            testSermonsAudioFiles()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Defaults"
            })
            globals.loadDefaults()
            
            for sermon in globals.sermonRepository.list! {
                sermon.removeTag(Constants.New)
            }
            
            if (sermonsNewToUser != nil) {
                for sermon in sermonsNewToUser! {
                    sermon.addTag(Constants.New)
                }
                //                print("\(sermonsNewToUser)")
                
                globals.showing = Constants.TAGGED
                globals.sermonTagsSelected = Constants.New
            } else {
                if (globals.showing == Constants.TAGGED) {
                    if (globals.sermonTagsSelected == Constants.New) {
                        globals.sermonTagsSelected = nil
                        globals.showing = Constants.ALL
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Sorting and Grouping"
            })
            
            globals.sermons.all = SermonsListGroupSort(sermons: globals.sermonRepository.list)

            globals.setupDisplay()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Setting up Player"
                if (globals.player.playing != nil) {
                    globals.player.playOnLoad = false
                    globals.setupPlayer(globals.player.playing)
                }
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.CBC_SHORT_TITLE
                self.setupViews()
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?()
            })
            
            globals.loading = false
        })
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
    print("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
        var success = false
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesReceived > 0) {
            let fileManager = NSFileManager.defaultManager()
            
            //Get documents directory URL
            if let destinationURL = cachesURL()?.URLByAppendingPathComponent(filename) {
                // Check if file exist
                if (fileManager.fileExistsAtPath(destinationURL.path!)){
                    do {
                        try fileManager.removeItemAtURL(destinationURL)
                    } catch _ {
                        print("failed to remove old json file")
                    }
                }
                
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    try fileManager.removeItemAtURL(location)
                    success = true
                } catch _ {
                    print("failed to copy new json file to Documents")
                }
            } else {
                print("failed to get destinationURL")
            }
        } else {
            print("downloadTask.countOfBytesReceived not > 0")
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if !globals.player.paused {
                    globals.player.paused = true
                    globals.player.mpPlayer?.pause()
                    globals.updateCurrentTimeExact()
                }
                
                globals.player.mpPlayer?.view.hidden = true
                globals.player.mpPlayer?.view.removeFromSuperview()
                
                self.loadSermons() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    globals.refreshing = false
                }
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                    let alert = UIAlertController(title:"Unable to Download Sermons",
                        message: "Please try to refresh the list again.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                
                self.refreshControl!.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                globals.setupDisplay()
                self.tableView.reloadData()
                
                globals.refreshing = false

                self.setupViews()
            })
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        print("URLSession:task:didCompleteWithError")
        
        if (error != nil) {
//            print("Download failed for: \(session.description)")
        } else {
//            print("Download succeeded for: \(session.description)")
        }
        
        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
//        removeTempFiles()
        
        let filename = task.taskDescription
        print("filename: \(filename!) error: \(error)")
        
        session.invalidateAndCancel()
        
        //        if let taskIndex = globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
    {
        print("URLSession:didBecomeInvalidWithError")

    }
    
    func downloadJSON()
    {
        navigationItem.title = "Downloading Sermons"
        
        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.CBC_SHORT.lowercaseString).\(Constants.SERMONS_JSON_FILENAME)"
        let downloadRequest = NSMutableURLRequest(URL: NSURL(string: jsonURL)!)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTaskWithRequest(downloadRequest)
        downloadTask?.taskDescription = Constants.SERMONS_JSON_FILENAME
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        globals.refreshing = true
        
        globals.cancelAllDownloads()

        globals.clearDisplay()
        
        tableView.reloadData()

        if splitViewController != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
            })
        }

        disableBarButtons()
        
        downloadJSON()
    }

    func removeRefreshControl()
    {
        refreshControl?.removeFromSuperview()
    }
    
    func addRefreshControl()
    {
        if (refreshControl?.superview != tableView) {
            tableView.addSubview(refreshControl!)
        }
    }
    
    func updateList()
    {
        globals.setupDisplay()
        
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MediaTableViewController.updateList), name: Constants.UPDATE_SERMON_LIST_NOTIFICATION, object: globals.sermons.tagged)

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)

        if globals.sermonRepository.list == nil {
            //            disableBarButtons()
            loadSermons(nil)
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let selectedSermonKey = NSUserDefaults.standardUserDefaults().stringForKey(Constants.SELECTED_SERMON_KEY) {
            selectedSermon = globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                return sermon.id == selectedSermonKey
            }).first
        }
        
        //.AllVisible and .Automatic is the only option that works reliably.
        //.PrimaryOverlay and .PrimaryHidden create constraint errors after dismissing the master and then swiping right to bring it back
        //and *then* changing orientation
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
        
        // Reload the table
        tableView.reloadData()

        tableView?.allowsSelection = true

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        navigationController?.toolbarHidden = false
        setupSortingAndGroupingOptions()
        setupShowMenu()
    }

    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
//        print("searchBarResultsListButtonClicked")
        
        if !globals.loading && !globals.refreshing && (globals.sermons.all?.sermonTags != nil) && (self.storyboard != nil) { // !globals.sermonsSortingOrGrouping &&
            if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .Popover
                    //            popover?.preferredContentSize = CGSizeMake(300, 500)
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.sourceView = searchBar
                    navigationController.popoverPresentationController?.sourceRect = searchBar.bounds
                    
                    popover.navigationItem.title = "Show Sermons Tagged With"
                    
                    popover.delegate = self
                    popover.purpose = .selectingTags
                    
                    popover.strings = [Constants.All]
                    popover.strings?.appendContentsOf(globals.sermons.all!.sermonTags!)
                    
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    
                    presentViewController(navigationController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        updateSearchResults()
    }
    
    func updateSearchResults()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.listActivityIndicator.hidden = false
            self.listActivityIndicator.startAnimating()
        })
        
        globals.searchText = self.searchBar.text
        
        if let searchText = self.searchBar.text {
            globals.clearDisplay()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.disableToolBarButtons()
            })
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (searchText != Constants.EMPTY_STRING) {
                    let searchSermons = globals.sermonsToSearch?.filter({ (sermon:Sermon) -> Bool in
                        return ((sermon.title?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.speaker?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                        })
                    
                    globals.sermons.search = SermonsListGroupSort(sermons: searchSermons)
                }
                
                globals.setupDisplay()
                
                if (globals.searchText == searchText) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.listActivityIndicator.stopAnimating()
                        self.listActivityIndicator.hidden = true
                        self.enableToolBarButtons()
                    })
                } else {
                    print("Threw away search results!")
                }
            })
        }
    }

    func selectOrScrollToSermon(sermon:Sermon?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        if (sermon != nil) && (globals.activeSermons?.indexOf(sermon!) != nil) {
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let sermons = globals.activeSermons

            if let index = sermons!.indexOf(sermon!) {
                switch globals.grouping! {
                case Constants.YEAR:
//                    let calendar = NSCalendar.currentCalendar()
//                    let components = calendar.components(.Year, fromDate: sermons![index].fullDate!)
//                    
//                    switch globals.sorting! {
//                    case Constants.REVERSE_CHRONOLOGICAL:
//                        section = globals.active!.sectionTitles!.sort({ $1 < $0 }).indexOf("\(components.year)")!
//                        break
//                    case Constants.CHRONOLOGICAL:
//                        section = globals.active!.sectionTitles!.sort({ $0 < $1 }).indexOf("\(components.year)")!
//                        break
//                        
//                    default:
//                        break
//                    }
                    section = globals.active!.sectionTitles!.indexOf(sermon!.yearSection!)!
                    break
                    
                case Constants.SERIES:
                    section = globals.active!.sectionTitles!.indexOf(sermon!.seriesSection!)!
                    break
                    
                case Constants.BOOK:
                    section = globals.active!.sectionTitles!.indexOf(sermon!.bookSection!)!
                    break
                    
                case Constants.SPEAKER:
                    section = globals.active!.sectionTitles!.indexOf(sermon!.speakerSection!)!
                    break
                    
                default:
                    break
                }

                row = index - globals.active!.sectionIndexes![section]
            }

            if (section > -1) && (row > -1) {
                indexPath = NSIndexPath(forItem: row,inSection: section)
                
                //            print("\(globals.sermonSelected?.title)")
                //            print("Row: \(indexPath.item)")
                //            print("Section: \(indexPath.section)")
                
                if (select) {
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                }
                
                if (scroll) {
                    //Scrolling when the user isn't expecting it can be jarring.
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: false)
                }
            }
        }
    }

    
    private func setupSearchBar()
    {
        switch globals.showing! {
        case Constants.ALL:
            searchBar.placeholder = Constants.All
            break
            
        case Constants.TAGGED:
            searchBar.placeholder = globals.sermonTagsSelected
            break
            
        default:
            break
        }
    }
    

    func setupTitle()
    {
        if (!globals.loading && !globals.refreshing) {
            if (splitViewController == nil) {
                if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
                    navigationItem.title = Constants.CBC_LONG_TITLE
                } else {
                    navigationItem.title = Constants.CBC_SHORT_TITLE
                }
            } else {
                navigationItem.title = Constants.CBC_SHORT_TITLE
            }
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if (globals.sermons.all == nil) { // SortingOrGrouping
            listActivityIndicator.startAnimating()
            disableBarButtons()
        } else {
            listActivityIndicator.stopAnimating()
            enableBarButtons()
        }

        setupSearchBar()
        
        setupSplitViewController()
        
        setupTitle()
        
        navigationController?.toolbarHidden = false
    }
    
    func about()
    {
        performSegueWithIdentifier(Constants.Show_About2, sender: self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        globals.loadedEnoughToDeepLink = true
//        
//        if (globals.deepLinkWaiting) {
//            deepLink()
//        } else {
            //Do we want to do this?  If someone has selected something farther down the list to view, not play, when they come back
            //the list will scroll to whatever is playing or paused.
            
            //This has to be in viewDidAppear().  Putting it in viewWillAppear() does not allow the rows at the bottom of the list
            //to be scrolled to correctly with this call.  Presumably this is because of the toolbar or something else that is still
            //getting setup in viewWillAppear.
            
            if (!globals.scrolledToSermonLastSelected) {
                selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                globals.scrolledToSermonLastSelected = true
            }
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.toolbarHidden = true
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var show:Bool
        
        show = true

    //    print("shouldPerformSegueWithIdentifier")
    //    print("Selected: \(globals.sermonSelected?.title)")
    //    print("Last Selected: \(globals.sermonLastSelected?.title)")
    //    print("Playing: \(globals.player.playing?.title)")
        
        switch identifier {
            case Constants.Show_About:
                break

            case Constants.Show_Sermon:
                // We might check and see if the cell sermon is in a series and if not don't segue if we've
                // already done so, but I think we'll just let it go.
                // Mainly because if it is in series and we've selected another sermon in the series
                // we may want to reselect from the master list to go to that sermon in the series since it is no longer
                // selected in the detail list.

//                if let myCell = sender as? MediaTableViewCell {
//                    show = (splitViewController == nil) || ((splitViewController != nil) && (splitViewController!.viewControllers.count == 1)) || (myCell.sermon != selectedSermon)
//                }
                break
            
            default:
                break
        }
        
        return show
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
            case Constants.Show_Settings:
                if let svc = dvc as? SettingsViewController {
                    svc.modalPresentationStyle = .Popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.Show_Live:
                globals.setupLivePlayingInfoCenter()
                break
                
            case Constants.Show_Scripture_Index:
                break
                
            case Constants.Show_About:
                fallthrough
            case Constants.Show_About2:
                globals.showingAbout = true
                break
                
            case Constants.Show_Sermon:
                if globals.player.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL) {
                    globals.player.stateTime = nil
                    globals.player.playOnLoad = false
                }
                
                globals.showingAbout = false
                if (globals.gotoPlayingPaused) {
                    globals.gotoPlayingPaused = !globals.gotoPlayingPaused

                    if let destination = dvc as? MediaViewController {
                        destination.selectedSermon = globals.player.playing
                    }
                } else {
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
                }

                searchBar.resignFirstResponder()
                break
            default:
                break
            }
        }

    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
            })
        })

        setupSplitViewController()

        setupTitle()
        
        if (splitViewController != nil) {
            if (popover != nil) {
                dismissViewControllerAnimated(true, completion: nil)
                popover = nil
            }
        }
    }
    
    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(TableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return globals.display.sectionTitles != nil ? globals.display.sectionTitles!.count : 0
    }

    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return nil
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.HEADER_HEIGHT
    }

    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return globals.display.sectionTitles != nil ? globals.display.sectionTitles![section] : nil
    }
    
    func tableView(TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return globals.display.sectionCounts != nil ? globals.display.sectionCounts![section] : 0
    }

    func tableView(TableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MediaTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMONS_CELL_IDENTIFIER, forIndexPath: indexPath) as! MediaTableViewCell
    
        // Configure the cell
        if let section = globals.display.sectionIndexes?[indexPath.section] {
            cell.sermon = globals.display.sermons?[section + indexPath.row]
        } else {
            print("No sermon for cell!")
        }

        cell.vc = self

        return cell
    }

    // MARK: UITableViewDelegate
    
    func tableView(TableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didSelect")

        if let cell: MediaTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
            selectedSermon = cell.sermon
        } else {
            
        }
    }
    
    func tableView(TableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didDeselect")

//        if let cell: MediaTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        } else {
//            
//        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    */
    func tableView(TableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        print("shouldHighlight")
        return true
    }
    
    func tableView(TableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
//        print("Highlighted")
    }
    
    func tableView(TableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
//        print("Unhighlighted")
    }
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func TableView(TableView: UITableView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func TableView(TableView: UITableView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func TableView(TableView: UITableView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
}
