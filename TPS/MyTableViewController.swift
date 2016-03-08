//
//  MyTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

//extension UINavigationBar {
//    public override func sizeThatFits(size: CGSize) -> CGSize {
//        var newSize = CGSizeMake(UIScreen.mainScreen().bounds.width, 44)
//        return newSize
//    }
//}

enum PopoverPurpose {
    case selectingShow

    case selectingSorting
    case selectingGrouping
    case selectingSection

    case selectingTags

    case showingTags
    case editingTags
}

class MyTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate, NSURLSessionDownloadDelegate {

    override func canBecomeFirstResponder() -> Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
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
                
                popover.navigationItem.title = "Show"
                
                popover.delegate = self
                popover.purpose = .selectingShow
                
                var showMenu = [String]()
                
                if (self.splitViewController != nil) {
                    // What if it is collapsed and the detail view is showing?
                    if (!Globals.showingAbout) {
                        showMenu.append(Constants.About)
                    }
                } else {
                    showMenu.append(Constants.About)
                }
                
                //Because the list extends above and below the visible area, visibleCells is deceptive - the cell can be hidden behind a navbar or toolbar and still returned in the array of visibleCells.
                if (Globals.display.sermons != nil) && (selectedSermon != nil) && (Globals.display.sermons?.indexOf(selectedSermon!) != nil) {
                    showMenu.append(Constants.Current_Selection)
                }
                
                if (Globals.sermonPlaying != nil) {
                    var show:String = Constants.EMPTY_STRING
                    
                    if (Globals.playerPaused) {
                        show = Constants.Sermon_Paused
                    } else {
                        show = Constants.Sermon_Playing
                    }
                    
                    if (self.splitViewController != nil) {
                        if let nvc = self.splitViewController!.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                            if let myvc = nvc.topViewController as? MyViewController {
                                if (myvc.selectedSermon != nil) {
                                    if (myvc.selectedSermon?.title != Globals.sermonPlaying?.title) || (myvc.selectedSermon?.date != Globals.sermonPlaying?.date) {
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

                showMenu.append(Constants.Settings)
                
                popover.strings = showMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
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
        if (Globals.sermonRepository.list != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.enabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (Globals.sermonRepository.list != nil) {
            navigationItem.leftBarButtonItem?.enabled = true
            enableToolBarButtons()
        }
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
            case .selectingTags:
                
                // Should we be showing Globals.active!.sermonTags instead?  That would be the equivalent of drilling down.
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
//                    if (index >= 0) && (index <= Globals.sermons.all!.sermonTags!.count) {
                    if (index < strings.count) {
                        var new:Bool = false
                        
                        switch strings[index] {
                        case Constants.All:
                            if (Globals.showing != Constants.ALL) {
                                new = true
                                Globals.showing = Constants.ALL
                                Globals.sermonTagsSelected = nil
                            }
                            break
                            
                        default:
                            //Tagged
                            
                            let tagSelected = strings[index]
                            
                            new = (Globals.showing != Constants.TAGGED) || (Globals.sermonTagsSelected != tagSelected)
                            
                            if (new) {
//                                print("\(Globals.active!.sermonTags)")
                                
                                Globals.sermonTagsSelected = tagSelected
                                
                                Globals.showing = Constants.TAGGED
                            }
                            break
                        }
                        
                        if (new) {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                clearSermonsForDisplay()
                                self.tableView.reloadData()
                                
                                self.listActivityIndicator.hidden = false
                                self.listActivityIndicator.startAnimating()
                                
                                self.disableBarButtons()
                            })
                            
                            if (Globals.searchActive) {
                                self.updateSearchResults()
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                setupSermonsForDisplay()
                                self.tableView.reloadData()
                                
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
//                if (Globals.grouping == Constants.SERIES) {
//                    let string = strings[index]
//
//                    if (string != Constants.Individual_Sermons) && (Globals.sermonSectionTitles.series?.indexOf(string) == nil) {
//                        let index = Globals.sermonSectionTitles.series?.indexOf(Constants.Individual_Sermons)
//                        
//                        var sermons = [Sermon]()
//                        
//                        for sermon in Globals.activeSermons! {
//                            if !sermon.hasSeries() {
//                                sermons.append(sermon)
//                            }
//                        }
//                        
//                        let sortedSermons = sortSermons(sermons, sorting: Globals.sorting, grouping: Globals.grouping)
//
//                        let row = sortedSermons?.indexOf({ (sermon) -> Bool in
//                            return string == sermon.title
//                        })
//                        
//                        indexPath = NSIndexPath(forRow: row!, inSection: index!)
//                    } else {
//                        let sections = seriesFromSermons(Globals.activeSermons,withTitles: false)
//                        let section = sections?.indexOf(string)
//                        indexPath = NSIndexPath(forRow: 0, inSection: section!)
//                    }
//                }
                
                //Can't use this reliably w/ variable row heights.
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                break
            
            case .selectingGrouping:
                dismissViewControllerAnimated(true, completion: nil)
                Globals.grouping = strings[index].lowercaseString
                
                if (Globals.sermonsNeed.grouping) {
                    clearSermonsForDisplay()
                    tableView.reloadData()
                    
                    listActivityIndicator.hidden = false
                    listActivityIndicator.startAnimating()
                    
                    disableBarButtons()
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        Globals.progress = 0
                        Globals.finished = 0
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
                        })
                        
                        setupSermonsForDisplay()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                            self.listActivityIndicator.stopAnimating()
                            self.enableBarButtons()
                        })
                    })
                }
                break
                
            case .selectingSorting:
                dismissViewControllerAnimated(true, completion: nil)
                Globals.sorting = strings[index].lowercaseString

                if (Globals.sermonsNeed.sorting) {
                    clearSermonsForDisplay()
                    tableView.reloadData()
                    
                    listActivityIndicator.hidden = false
                    listActivityIndicator.startAnimating()
                    
                    disableBarButtons()
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        setupSermonsForDisplay()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                            self.listActivityIndicator.stopAnimating()
                            self.enableBarButtons()
//                            
//                            if (self.splitViewController != nil) {
//                                //iPad only
//                                if let nvc = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count - 1] as? UINavigationController {
//                                    if let myvc = nvc.visibleViewController as? MyViewController {
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
                    selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                    break
                    
                case Constants.Sermon_Playing:
                    fallthrough
                    
                case Constants.Sermon_Paused:
                    Globals.gotoPlayingPaused = true
                    performSegueWithIdentifier(Constants.Show_Sermon, sender: self)
                    break
                    
                case Constants.Scripture_Index:
                    performSegueWithIdentifier(Constants.Show_Scripture_Index, sender: nil)
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
        Globals.searchActive = true
    }
    
    func willDismissSearchController(searchController: UISearchController)
    {
        Globals.searchActive = false
    }
    
    func didDismissSearchController(searchController: UISearchController)
    {
        didDismissSearch()
    }
    
    func didDismissSearch() {
        Globals.sermons.search = nil
        
        listActivityIndicator.hidden = false
        listActivityIndicator.startAnimating()
        
        clearSermonsForDisplay()
        tableView.reloadData()
        
        disableBarButtons()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            setupSermonsForDisplay()
            
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

        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
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
                popover.strings = Globals.active?.sectionTitles
                
                popover.showIndex = (Globals.grouping == Constants.SERIES)
                popover.showSectionHeaders = (Globals.grouping == Constants.SERIES)
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

        // Too slow
//        if (Globals.grouping == Constants.SERIES) {
//            let strings = seriesFromSermons(Globals.activeSermons,withTitles: true)
//            popover?.strings = strings
//        } else {
//            popover?.strings = Globals.sermonSections
//        }
    }

    func grouping(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
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
                popover.strings = [Constants.Year,Constants.Series,Constants.Book,Constants.Speaker]
                
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
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
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
                popover.strings = [Constants.Chronological,Constants.Reverse_Chronological]
                
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
        
        showButton?.enabled = (Globals.sermons.all != nil) //&& !Globals.sermonsSortingOrGrouping
    }
    
    private func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sorting, style: UIBarButtonItemStyle.Plain, target: self, action: "sorting:")
        let groupingButton = UIBarButtonItem(title: Constants.Grouping, style: UIBarButtonItemStyle.Plain, target: self, action: "grouping:")
        let indexButton = UIBarButtonItem(title: Constants.Index, style: UIBarButtonItemStyle.Plain, target: self, action: "index:")

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
        
        if (Globals.sermonRepository.list == nil) {
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
        return !Globals.loading && !Globals.refreshing && (Globals.sermons.all != nil) // !Globals.sermonsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        Globals.searchActive = true
        searchBar.showsCancelButton = true
        
        clearSermonsForDisplay()
        tableView.reloadData()
        disableToolBarButtons()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked:")
        searchBar.showsCancelButton = false
        Globals.searchActive = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        didDismissSearch()
    }
    
    /* Not ready for release

    func deepLink()
    {
        // This should be rationalized with the code in AppDelegate to have one function (somewhere) so we aren't duplicating it.
        
        Globals.deepLinkWaiting = false

        let path = Globals.deepLink.path
        let searchString = Globals.deepLink.searchString
        let sorting = Globals.deepLink.sorting
        let grouping = Globals.deepLink.grouping
        let sermonTag = Globals.deepLink.tag

        Globals.deepLink.path = nil
        Globals.deepLink.searchString = nil
        Globals.deepLink.sorting = nil
        Globals.deepLink.grouping = nil
        Globals.deepLink.tag = nil

        var sermonSelected:Sermon?

        var seriesSelected:String?
        var firstSermonInSeries:Sermon?
        
        var bookSelected:String?
        var firstSermonInBook:Sermon?
        
//        var seriesIndexPath = NSIndexPath()
        
        if (path != nil) {
            //                print("path: \(path)")
            
            // Is it a series?
            if let sermonSeries = seriesSectionsFromSermons(Globals.sermons) {
                for sermonSeries in sermonSeries {
                    //                        print("sermonSeries: \(sermonSeries)")
                    if (sermonSeries == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                        //It is a series
                        seriesSelected = sermonSeries
                        break
                    }
                }
                
                if (seriesSelected != nil) {
                    var sermonsInSelectedSeries = sermonsInSermonSeries(Globals.sermons,series: seriesSelected!)
                    
                    if (sermonsInSelectedSeries?.count > 0) {
                        if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedSeries![0]) {
                            firstSermonInSeries = Globals.sermons![firstSermonIndex]
                            //                            print("firstSermon: \(firstSermon)")
                        }
                    }
                }
            }
            
            if (seriesSelected == nil) {
                // Is it a sermon?
                for sermon in Globals.sermons! {
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
                if let sermonBooks = bookSectionsFromSermons(Globals.sermons) {
                    for sermonBook in sermonBooks {
                        //                        print("sermonBook: \(sermonBook)")
                        if (sermonBook == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //It is a series
                            bookSelected = sermonBook
                            break
                        }
                    }
                    
                    if (bookSelected != nil) {
                        var sermonsInSelectedBook = sermonsInBook(Globals.sermons,book: bookSelected!)
                        
                        if (sermonsInSelectedBook?.count > 0) {
                            if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedBook![0]) {
                                firstSermonInBook = Globals.sermons![firstSermonIndex]
                                //                            print("firstSermon: \(firstSermon)")
                            }
                        }
                    }
                }
            }
        }
        
        if (sorting != nil) {
            Globals.sorting = sorting!
        }
        if (grouping != nil) {
            Globals.grouping = grouping!
        }
        
        if (sermonTag != nil) {
            if (sermonTag != Constants.ALL) {
                Globals.sermonTagsSelected = sermonTag!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)
                print("\(Globals.sermonTagsSelected)")
                Globals.showing = Constants.TAGGED
                
                if let sermons = Globals.sermons {
                    var taggedSermons = [Sermon]()
                    
                    for sermon in sermons {
                        if (sermon.tags?.rangeOfString(Globals.sermonTagsSelected!) != nil) {
                            taggedSermons.append(sermon)
                        }
                    }
                    
                    Globals.taggedSermons = taggedSermons.count > 0 ? taggedSermons : nil
                }
            } else {
                Globals.showing = Constants.ALL
                Globals.sermonTagsSelected = nil
            }
        }
        
        //In case Globals.searchActive is true at the start we need to cancel it.
        Globals.searchActive = false
        Globals.searchSermons = nil
        
        if (searchString != nil) {
            Globals.searchActive = true
            Globals.searchSermons = nil
            
            if let sermons = Globals.sermonsToSearch {
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
                
                Globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
            }
        }
        
        Globals.sermonsNeed.groupsSetup = true
        sortAndGroupSermons()
        
        var tvc:MyTableViewController?
        
        //iPad
        if (splitViewController != nil) {
            //            print("rvc = UISplitViewController")
            if let nvc = splitViewController!.viewControllers[0] as? UINavigationController {
                //                print("nvc = UINavigationController")
                tvc = nvc.topViewController as? MyTableViewController
            }
            if let nvc = splitViewController!.viewControllers[1] as? UINavigationController {
                //                print("nvc = UINavigationController")
                if let myvc = nvc.topViewController as? MyViewController {
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
            if let _ = nvc.topViewController as? MyViewController {
                //                    print("myvc = MyViewController")
                nvc.popToRootViewControllerAnimated(true)
                
            }
            tvc = nvc.topViewController as? MyTableViewController
        }
        
        if (tvc != nil) {
            // All of the scrolling below becomes a problem in portrait on an iPad as the master view controller TVC may not be visible
            // AND when it is made visible it is setup to first scroll to current selection.
            
            //                print("tvc = MyTableViewController")
            
            //            tvc.performSegueWithIdentifier("Show Sermon", sender: tvc)
            
            tvc!.tableView.reloadData()
            
            if (Globals.sermonTagsSelected != nil) {
                tvc!.searchBar.placeholder = Globals.sermonTagsSelected!
                
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
    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        print("MyTVC.mpPlayerLoadStateDidChange")

        let player = notification.object as! MPMoviePlayerController
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        
        let playable = (loadstate & UInt8(MPMovieLoadState.Playable.rawValue)) > 0
        let playthrough = (loadstate & UInt8(MPMovieLoadState.PlaythroughOK.rawValue)) > 0
        
//        print("\(loadstate)")
//        print("\(playable)")
//        print("\(playthrough)")
        
        if (playable || playthrough) {
            print("MyTVC.mpPlayerLoadStateDidChange.MPMovieLoadState.Playable")
            //should be called only once, only for  first time audio load.
            if(!Globals.sermonLoaded) {
//                print("\(Globals.sermonPlaying!.currentTime!)")
//                print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
                
                if (Globals.sermonPlaying != nil) && Globals.sermonPlaying!.hasCurrentTime() {
                    Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
                } else {
                    Globals.sermonPlaying?.currentTime = Constants.ZERO
                    Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(0)
                }

                Globals.sermonLoaded = true
            }
            
            setupTitle()
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        } else {
            print("MyTVC.mpPlayerLoadStateDidChange.MPMovieLoadState.Playthrough NOT OK")
        }

        switch Globals.mpPlayer!.playbackState {
        case .Playing:
            print("MyTVC.mpPlayerLoadStateDidChange.Playing")
            break
            
        case .SeekingBackward:
            print("MyTVC.mpPlayerLoadStateDidChange.SeekingBackward")
            break
            
        case .SeekingForward:
            print("MyTVC.mpPlayerLoadStateDidChange.SeekingForward")
            break
            
        case .Stopped:
            print("MyTVC.mpPlayerLoadStateDidChange.Stopped")
            break
            
        case .Interrupted:
            print("MyTVC.mpPlayerLoadStateDidChange.Interrupted")
            break
            
        case .Paused:
            print("MyTVC.mpPlayerLoadStateDidChange.Paused")
            break
        }
    }
    
    func setupSermonPlaying()
    {
        setupPlayer(Globals.sermonPlaying)
        
        if (!Globals.sermonLoaded) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        } else {
            setupTitle()
        }
    }
    
    func setupViews()
    {
        var mytvc:MyTableViewController?
        var myvc:MyViewController?
        
        if let svc = self.splitViewController {
            //iPad
            if let nvc = svc.viewControllers[0] as? UINavigationController {
                mytvc = nvc.visibleViewController as? MyTableViewController
            }
            if let nvc = svc.viewControllers[svc.viewControllers.count - 1] as? UINavigationController {
                myvc = nvc.visibleViewController as? MyViewController
            }
        } else {
            mytvc = self.navigationController?.visibleViewController as? MyTableViewController
            myvc = self.navigationController?.visibleViewController as? MyViewController
        }
        
        if (mytvc != nil) {
            mytvc!.setupSearchBar()
            mytvc!.tableView.reloadData()
            mytvc!.enableBarButtons()
            mytvc!.listActivityIndicator.stopAnimating()
            mytvc!.setupTitle()
            mytvc!.addRefreshControl()
            
            let defaults = NSUserDefaults.standardUserDefaults()
            
            if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
                mytvc?.selectedSermon = Globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                    return sermon.id == selectedSermonKey
                }).first
                
                if (mytvc?.selectedSermon != nil) {
                    if (Globals.activeSermons?.indexOf(mytvc!.selectedSermon!) != nil) {
                        mytvc!.selectOrScrollToSermon(mytvc?.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                    }
                }
//
//                if let sermons = Globals.sermonRepository.list {
//                    for sermon in sermons {
//                        if (sermon.keyBase == selectedSermonKey) {
//                            mytvc!.selectedSermon = sermon
//                            
//                            if let sermonList = Globals.activeSermons {
//                                if (sermonList.indexOf(mytvc!.selectedSermon!) != nil) {
//                                    mytvc!.selectOrScrollToSermon(sermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
//                                }
//                            }
//                            break
//                        }
//                    }
//                }
            }
        }
        
        if (myvc != nil) {
            if let selectedSermonKey = NSUserDefaults.standardUserDefaults().stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
                let sermon = Globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                    return sermon.id == selectedSermonKey
                }).first

                myvc?.selectedSermon = sermon
                myvc?.updateUI()

                myvc?.scrollToSermon(sermon,select:true,position:UITableViewScrollPosition.None)
            }
        }
    }
    
    func updateProgress()
    {
//        print("\(Float(Globals.progress))")
//        print("\(Float(Globals.finished))")
//        print("\(Float(Globals.progress) / Float(Globals.finished))")
        
        self.progressIndicator.progress = 0
        if (Globals.finished > 0) {
            self.progressIndicator.hidden = false
            self.progressIndicator.progress = Float(Globals.progress) / Float(Globals.finished)
        }
        
        //            print("\(self.progressIndicator.progress)")
        
        if self.progressIndicator.progress == 1.0 {
            self.progressTimer?.invalidate()
            self.progressIndicator.hidden = true
            self.progressIndicator.progress = 0
            Globals.progress = 0
            Globals.finished = 0
        }
    }
    
    func loadSermons(completion: (() -> Void)?)
    {
        //        Globals.sermonsSortingOrGrouping = true
        
//        progressIndicator.hidden = false
        Globals.progress = 0
        Globals.finished = 0
        
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            Globals.loading = true

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Sermons"
            })
            
            var success = false
            var newSermons:[Sermon]?

            if let sermons = sermonsFromArchive() {
                newSermons = sermons
                success = true
            } else if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
                newSermons = sermons
                sermonsToArchive(sermons)
                success = true
            }
            
            if (!success) {
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
            
            if (Globals.sermonRepository.list != nil) {
                
                let old = Set(Globals.sermonRepository.list!.map({ (sermon:Sermon) -> String in
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
            
            Globals.sermonRepository.list = newSermons

//            var scriptures = 0
//            var ot = 0
//            var nt = 0
//            var total = 0
//            
//            for sermon in Globals.sermonRepository.list! {
//                if (sermon.scripture != nil) && (sermon.scripture != Constants.Selected_Scriptures) {
//                    scriptures++
//                    for book in booksFromScripture(sermon.scripture) {
//                        switch testament(book) {
//                        case Constants.New_Testament:
//                            nt++
//                            break
//                        case Constants.Old_Testament:
//                            ot++
//                            break
//                        default:
//                            break
//                        }
//                    }
//                }
//                total++
//            }
//            print(total)
//            print(scriptures)
//            print(ot)
//            print(nt)

//            for sermon in newSermons! {
//                print("\(sermon.title!):\(sermon.id!)")
//            }
            
            if Globals.testing {
                testSermonsTagsAndSeries()
                
                testSermonsBooksAndSeries()
                
                testSermonsForSeries()
                
                //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
                testSermonsPDFs(testExisting: false, testMissing: true, showTesting: false)
                
                //Test whether the audio starts to download
                //If we can download at all, we assume we can download it all, which allows us to test all sermons to see if they can be downloaded/played.
                //                testSermonsAudioFiles()
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Defaults"
            })
            loadDefaults()
            
            if (sermonsNewToUser != nil) {
                for sermon in Globals.sermonRepository.list! {
                    sermon.removeTag(Constants.New)
                }

                for sermon in sermonsNewToUser! {
                    sermon.addTag(Constants.New)
                }
                //                print("\(sermonsNewToUser)")
                
                Globals.showing = Constants.TAGGED
                Globals.sermonTagsSelected = Constants.New
            } else {
                if (Globals.showing == Constants.TAGGED) {
                    if (Globals.sermonTagsSelected == Constants.New) {
                        Globals.sermonTagsSelected = nil
                        Globals.showing = Constants.ALL
                    }
                }
            }
            
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Sorting and Grouping"
            })
            
            Globals.sermons.all = SermonsListGroupSort(sermons: Globals.sermonRepository.list)

            setupSermonsForDisplay()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Setting up Player"
                self.setupSermonPlaying()
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.setupViews()
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?()
            })
            
            Globals.loading = false
        })
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
//        let filename = downloadTask.taskDescription!
        
//        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        var success = false
        
//        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
//        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesExpectedToReceive > 0) {
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
            }
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                
                updateCurrentTimeExact()
                
                Globals.mpPlayer?.view.hidden = true
                Globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSermons() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    Globals.refreshing = false
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
                self.setupTitle()
                setupSermonsForDisplay()
                self.tableView.reloadData()
                self.setupViews()
                Globals.refreshing = false
            })
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error != nil) {
            print("Download failed for: \(session.description)")
        } else {
            print("Download succeeded for: \(session.description)")
        }
        
        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
//        removeTempFiles()
        
        let filename = task.taskDescription
        print("filename: \(filename!) error: \(error)")
        
        session.invalidateAndCancel()
        
        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            Globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {

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
        Globals.refreshing = true
        
        cancelAllDownloads()

        clearSermonsForDisplay()
        tableView.reloadData()
        
        if let svc = self.splitViewController {
            //iPad
            if let nvc = svc.viewControllers[svc.viewControllers.count - 1] as? UINavigationController {
                if let myvc = nvc.visibleViewController as? MyViewController {
                    myvc.captureContentOffsetAndZoomScale()
                    myvc.selectedSermon = nil
                    myvc.sermonsInSeries = nil
                    myvc.updateUI()
                }
            }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: Selector("handleRefresh:"), forControlEvents: UIControlEvents.ValueChanged)

        if Globals.sermonRepository.list == nil {
            //            disableBarButtons()
            loadSermons(nil)
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Do either of the two lines below matter? What does each do do that isn't already being done?  Nothing that I can see.
//        tableView.contentOffset = CGPointMake(0,searchBar.frame.size.height - tableView.contentOffset.y);
//        tableView.tableHeaderView = searchBar
        
        if let selectedSermonKey = NSUserDefaults.standardUserDefaults().stringForKey(Constants.SELECTED_SERMON_KEY) {
            selectedSermon = Globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                return sermon.id == selectedSermonKey
            }).first
//            if let sermons = Globals.sermonRepository.list {
//                for sermon in sermons {
//                    if (sermon.keyBase == selectedSermonKey) {
//                        selectedSermon = sermon
//                    }
//                }
//            }
        }
        
        //.AllVisible and .Automatic is the only option that works reliably.
        //.PrimaryOverlay and .PrimaryHidden create constraint errors after dismissing the master and then swiping right to bring it back
        //and *then* changing orientation
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
        
//        splitViewController?.maximumPrimaryColumnWidth = 325
        
//        definesPresentationContext = true

        // Reload the table
        tableView.reloadData()

        tableView?.allowsSelection = true

        //tableView?.allowsMultipleSelection = false

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        // Register cell classes - only used if cell is creatd programmatically
        //tableView!.registerClass(MyTableViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        navigationController?.toolbarHidden = false
        setupSortingAndGroupingOptions()
        setupShowMenu()
    }

    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
//        print("searchBarResultsListButtonClicked")
        
        if !Globals.loading && !Globals.refreshing && (Globals.sermons.all?.sermonTags != nil) && (self.storyboard != nil) { // !Globals.sermonsSortingOrGrouping &&
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
                    popover.strings?.appendContentsOf(Globals.sermons.all!.sermonTags!)
                    
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
        
        Globals.searchText = self.searchBar.text
        
        if let searchText = self.searchBar.text {
            clearSermonsForDisplay()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.disableToolBarButtons()
            })
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (searchText != Constants.EMPTY_STRING) {
                    let searchSermons = Globals.sermonsToSearch?.filter({ (sermon:Sermon) -> Bool in
                        return ((sermon.title?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.speaker?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                        })
                    
                    Globals.sermons.search = SermonsListGroupSort(sermons: searchSermons)
                }
                
                setupSermonsForDisplay()
                
                if (Globals.searchText == searchText) {
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
        if (sermon != nil) && (Globals.display.sermons != nil) {
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let sermons = Globals.display.sermons

            if let index = sermons!.indexOf(sermon!) {
                switch Globals.grouping! {
                case Constants.YEAR:
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components(.Year, fromDate: sermons![index].fullDate!)
                    
                    switch Globals.sorting! {
                    case Constants.REVERSE_CHRONOLOGICAL:
                        section = Globals.active!.sectionTitles!.sort({ $1 < $0 }).indexOf("\(components.year)")!
                        break
                    case Constants.CHRONOLOGICAL:
                        section = Globals.active!.sectionTitles!.sort({ $0 < $1 }).indexOf("\(components.year)")!
                        break
                        
                    default:
                        break
                    }
                    break
                    
                case Constants.SERIES:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.seriesSection!)!
                    break
                    
                case Constants.BOOK:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.bookSection!)!
                    break
                    
                case Constants.SPEAKER:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.speakerSection!)!
                    break
                    
                default:
                    break
                }

                row = index - Globals.display.sectionIndexes![section]
            }

            if (section > -1) && (row > -1) {
                indexPath = NSIndexPath(forItem: row,inSection: section)
                
                //            print("\(Globals.sermonSelected?.title)")
                //            print("Row: \(indexPath.item)")
                //            print("Section: \(indexPath.section)")
                
                if (select) {
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                }
                
                if (scroll) {
                    //Scrolling when the user isn't expecting it can be jarring.
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: true)
                }
            }
        }
    }

    
    private func setupSearchBar()
    {
        switch Globals.showing! {
        case Constants.ALL:
            searchBar.placeholder = Constants.All
            break
            
        case Constants.TAGGED:
            searchBar.placeholder = Globals.sermonTagsSelected
            break
            
        default:
            break
        }
    }
    

    func setupTitle()
    {
        if (!Globals.loading && !Globals.refreshing) {
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
            if (Globals.sermons.all == nil) {
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

        if (Globals.sermons.all == nil) { // SortingOrGrouping
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
    
    func seekingTimer()
    {
        setupPlayingInfoCenter()
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        print("remoteControlReceivedWithEvent")
        
        switch event!.subtype {
        case UIEventSubtype.MotionShake:
            print("RemoteControlShake")
            break
            
        case UIEventSubtype.None:
            print("RemoteControlNone")
            break
            
        case UIEventSubtype.RemoteControlStop:
            print("RemoteControlStop")
            Globals.mpPlayer?.stop()
            Globals.playerPaused = true
            break
            
        case UIEventSubtype.RemoteControlPlay:
            print("RemoteControlPlay")
            Globals.mpPlayer?.play()
            Globals.playerPaused = false
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlPause:
            print("RemoteControlPause")
            Globals.mpPlayer?.pause()
            Globals.playerPaused = true
            updateCurrentTimeExact()
            break
            
        case UIEventSubtype.RemoteControlTogglePlayPause:
            print("RemoteControlTogglePlayPause")
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
            break
            
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("RemoteControlPreviousTrack")
            break
            
        case UIEventSubtype.RemoteControlNextTrack:
            print("RemoteControlNextTrack")
            break
            
            //The lock screen time elapsed/remaining don't track well with seeking
            //But at least this has them moving in the right direction.
            
        case UIEventSubtype.RemoteControlBeginSeekingBackward:
            print("RemoteControlBeginSeekingBackward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingBackward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingBackward:
            print("RemoteControlEndSeekingBackward")
            Globals.mpPlayer?.endSeeking()
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlBeginSeekingForward:
            print("RemoteControlBeginSeekingForward")
            
            Globals.seekingObserver = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "seekingTimer", userInfo: nil, repeats: true)
            
            Globals.mpPlayer?.beginSeekingForward()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
            
        case UIEventSubtype.RemoteControlEndSeekingForward:
            print("RemoteControlEndSeekingForward")
            Globals.seekingObserver?.invalidate()
            Globals.seekingObserver = nil
            Globals.mpPlayer?.endSeeking()
            updateCurrentTimeExact()
            //        updatePlayingInfoCenter()
            setupPlayingInfoCenter()
            break
        }

        if (splitViewController != nil) {
            if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                if let myvc = nvc.visibleViewController as? MyViewController {
                    myvc.setupPlayPauseButton()
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        if Globals.sermonRepository.list == nil {
//            disableBarButtons()
//            loadSermons(nil)
//        }

//        Globals.loadedEnoughToDeepLink = true
//        
//        if (Globals.deepLinkWaiting) {
//            deepLink()
//        } else {
            //Do we want to do this?  If someone has selected something farther down the list to view, not play, when they come back
            //the list will scroll to whatever is playing or paused.
            
            //This has to be in viewDidAppear().  Putting it in viewWillAppear() does not allow the rows at the bottom of the list
            //to be scrolled to correctly with this call.  Presumably this is because of the toolbar or something else that is still
            //getting setup in viewWillAppear.
            
            if (!Globals.scrolledToSermonLastSelected) {
                if (selectedSermon != nil) && (Globals.activeSermons?.indexOf(selectedSermon!) != nil) {
                    selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                }
                Globals.scrolledToSermonLastSelected = true
            }
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.toolbarHidden = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }


//    func setPlayingPausedButton()
//    {
//        if (Globals.sermonPlaying != nil) {
//            var title:String = Constants.EMPTY_STRING
//            
//            if (Globals.playerPaused) {
//                title = Constants.Paused
//            } else {
//                title = Constants.Playing
//            }
//            
//            var playingPausedButton = navigationItem.rightBarButtonItem
//            
//            if (playingPausedButton == nil) {
//                playingPausedButton = UIBarButtonItem(title: Constants.EMPTY_STRING, style: UIBarButtonItemStyle.Plain, target: self, action: "gotoPlayingPaused")
//            }
//            
//            playingPausedButton!.title = title
//            
//            if (splitViewController != nil) {
//                //Only need to show it if About is being displayed.
//                if (Globals.showingAbout) || (selectedSermon == nil) {
//                    navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
//                }
//            } else {
//                if (navigationItem.rightBarButtonItem == nil) {
//                    navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
//                }
//            }
//        } else {
//            if (navigationItem.rightBarButtonItem != nil) {
//                navigationItem.setRightBarButtonItem(nil, animated: true)
//            }
//        }
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var show:Bool
        
        show = true

    //    print("shouldPerformSegueWithIdentifier")
    //    print("Selected: \(Globals.sermonSelected?.title)")
    //    print("Last Selected: \(Globals.sermonLastSelected?.title)")
    //    print("Playing: \(Globals.sermonPlaying?.title)")
        
        switch identifier {
            case Constants.Show_About:
                break

            case Constants.Show_Sermon:
                // We might check and see if the cell sermon is in a series and if not don't segue if we've
                // already done so, but I think we'll just let it go.
                // Mainly because if it is in series and we've selected another sermon in the series
                // we may want to reselect from the master list to go to that sermon in the series since it is no longer
                // selected in the detail list.

//                if let myCell = sender as? MyTableViewCell {
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
                if let svc = dvc as? MySettingsViewController {
                    svc.modalPresentationStyle = .Popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.Show_Scripture_Index:
                break
                
            case Constants.Show_About:
                fallthrough
            case Constants.Show_About2:
                Globals.showingAbout = true
                break
                
            case Constants.Show_Sermon:
                Globals.showingAbout = false
                if (Globals.gotoPlayingPaused) {
                    Globals.gotoPlayingPaused = !Globals.gotoPlayingPaused

                    if let destination = dvc as? MyViewController {
                        destination.selectedSermon = Globals.sermonPlaying
                    }
                } else {
                    if let myCell = sender as? MyTableViewCell {
                        selectedSermon = myCell.sermon //Globals.activeSermons![index]

                        if selectedSermon != nil {
                            if let destination = dvc as? MyViewController {
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
        if (self.view.window == nil) {
            return
        }
        
        setupSplitViewController()

        setupTitle()
        
        if (splitViewController != nil) {
            if (popover != nil) {
                dismissViewControllerAnimated(true, completion: nil)
                popover = nil
            }
        }
    }
    
    func gotoPlayingPaused()
    {
//        print("gotoPlayingPaused")
        
        Globals.gotoPlayingPaused = true
        
        performSegueWithIdentifier(Constants.Show_Sermon, sender: self)
    }
    
    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(TableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return Globals.display.sectionTitles != nil ? Globals.display.sectionTitles!.count : 0
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
        return Globals.display.sectionTitles != nil ? Globals.display.sectionTitles![section] : nil
    }
    
    func tableView(TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return Globals.display.sectionCounts != nil ? Globals.display.sectionCounts![section] : 0
    }

    func tableView(TableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MyTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMONS_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyTableViewCell
    
        // Configure the cell
        if let section = Globals.display.sectionIndexes?[indexPath.section] {
            cell.sermon = Globals.display.sermons?[section + indexPath.row]
        } else {
            print("No sermon for cell!")
        }
        
//        print("Section: \(indexPath.section) Row: \(indexPath.row) sermonSectionIndex: \(Globals.sermonSectionIndexes[indexPath.section]) SSI count \(Globals.sermonSectionIndexes.count)")

//        print("\(indexPath.row)")
//        print("\(Globals.sermons[indexPath.row].title)")
//        print("\(Globals.sermons[indexPath.row].date)")

        cell.vc = self

        return cell
    }

    // MARK: UITableViewDelegate
    
    func tableView(TableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didSelect")

        if let cell: MyTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
            selectedSermon = cell.sermon
        } else {
            
        }
    }
    
    func tableView(TableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didDeselect")

//        if let cell: MyTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//            //cell.backgroundColor = UIColor.whiteColor()
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
