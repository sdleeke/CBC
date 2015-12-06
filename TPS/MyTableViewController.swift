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
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
        }
    }

    var refreshControl:UIRefreshControl?

    var session:NSURLSession? // Used for JSON

    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(button: UIBarButtonItem) {
        popover = storyboard?.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
        popover?.modalPresentationStyle = .Popover
//        popover!.preferredContentSize = CGSizeMake(300, 500)
        
        popover?.popoverPresentationController?.permittedArrowDirections = .Up
        popover?.popoverPresentationController?.delegate = self
        popover?.popoverPresentationController?.barButtonItem = button
        
        popover?.delegate = self
        popover?.purpose = .selectingShow
        
        var showMenu = [String]()
    
        if (splitViewController != nil) {
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
            
            if (splitViewController != nil) {
                if let nvc = splitViewController!.viewControllers[1] as? UINavigationController {
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

        popover?.strings = showMenu

        popover?.showIndex = false //(Globals.grouping == Constants.SERIES)
        
        if (popover != nil) {
            presentViewController(popover!, animated: true, completion: nil)
        }
    }
    
    var selectedSermon:Sermon?
    
    var popover : PopoverTableViewController?
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
            case .selectingTags:
                if (index >= 0) && (index < Globals.sermonTags!.count) {
                    var new:Bool = false
                    
                    switch index {
                    case (Globals.sermonTags!.count-1):
                        //All
                        if (Globals.showing != Constants.ALL) {
                            new = true
                            Globals.showing = Constants.ALL
                            Globals.sermonTagsSelected = nil
                            Globals.taggedSermons = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        if (Globals.showing != Constants.TAGGED) {
                            Globals.showing = Constants.TAGGED
                            new = true
                            
                            Globals.searchSermons = nil
                            
                            Globals.sermonTagsSelected = Globals.sermonTags![index]
                            
                            //Searching for tagged sermons must be done across ALL sermons so Globals.activeSermons won't work here.
                            Globals.taggedSermons = taggedSermonsFromTagSelected(Globals.sermons,tagSelected: Globals.sermonTagsSelected)
                        } else {
                            if (Globals.sermonTagsSelected != Globals.sermonTags![index]) {
                                new = true
                                Globals.sermonTagsSelected = Globals.sermonTags![index]

                                //Searching for tagged sermons must be done across ALL sermons so Globals.activeSermons won't work here.
                                Globals.taggedSermons = taggedSermonsFromTagSelected(Globals.sermons,tagSelected: Globals.sermonTagsSelected)
                            }
                        }
                        break
                    }

                    //Can't get to the searchResults button when there is a search string so this is redundant.
                    //                    searchBar.text = nil
                    //And search may most definitely be active and just setting this to false doesn't deactivate the searchBar
                    //                    Globals.searchActive = false
                    
                    if (new) {
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setObject(Globals.sermonTags![index],forKey: Constants.COLLECTION)
                        defaults.synchronize()
                        
                        searchBar.placeholder = Globals.sermonTags![index]
                        
                        if (Globals.searchActive) {
                            updateSearchResults()
                        }
                        
                        Globals.sermonsNeedGroupsSetup = true
                        clearSermonsForDisplay()
                        tableView.reloadData()
                        
                        listActivityIndicator.hidden = false
                        listActivityIndicator.startAnimating()
                        
                        navigationItem.leftBarButtonItem?.enabled = false
                        
                        for barButton in toolbarItems! as [UIBarButtonItem] {
                            barButton.enabled = false
                        }
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                            sortAndGroupSermons()
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                                self.listActivityIndicator.stopAnimating()
                                
                                self.navigationItem.leftBarButtonItem?.enabled = true
                                
                                for barButton in self.toolbarItems! as [UIBarButtonItem] {
                                    barButton.enabled = true
                                }
                            })
                        })
                    }
                } else {
                    print("Index out of range")
                }
                break
                
            case .selectingSection:
                dismissViewControllerAnimated(true, completion: nil)
                let indexPath = NSIndexPath(forRow: 0, inSection: index)

                //Too slow
//                if (Globals.grouping == Constants.SERIES) {
//                    let string = strings[index]
//
//                    if (string != Constants.Individual_Sermons) && (Globals.sermonSeries?.indexOf(string) == nil) {
//                        let index = Globals.sermonSeries?.indexOf(Constants.Individual_Sermons)
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
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(Globals.grouping,forKey: Constants.GROUPING)
                defaults.synchronize()
                
                if (Globals.sermonsNeedGrouping) {
                    clearSermonsForDisplay()
                    tableView.reloadData()
                    
                    listActivityIndicator.hidden = false
                    listActivityIndicator.startAnimating()
                    
                    navigationItem.leftBarButtonItem?.enabled = false
                    
                    for barButton in toolbarItems! as [UIBarButtonItem] {
                        barButton.enabled = false
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        sortAndGroupSermons()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                            self.listActivityIndicator.stopAnimating()
                            
                            self.navigationItem.leftBarButtonItem?.enabled = true
                            
                            for barButton in self.toolbarItems! as [UIBarButtonItem] {
                                barButton.enabled = true
                            }
                        })
                    })
                }
                break
                
            case .selectingSorting:
                dismissViewControllerAnimated(true, completion: nil)
                Globals.sorting = strings[index].lowercaseString
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject(Globals.sorting,forKey: Constants.SORTING)
                defaults.synchronize()

                if (Globals.sermonsNeedSorting) {
                    clearSermonsForDisplay()
                    tableView.reloadData()
                    
                    listActivityIndicator.hidden = false
                    listActivityIndicator.startAnimating()
                    
                    navigationItem.leftBarButtonItem?.enabled = false
                    
                    for barButton in toolbarItems! as [UIBarButtonItem] {
                        barButton.enabled = false
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                        sortAndGroupSermons()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                            self.listActivityIndicator.stopAnimating()
                            
                            self.navigationItem.leftBarButtonItem?.enabled = true
                            
                            for barButton in self.toolbarItems! as [UIBarButtonItem] {
                                barButton.enabled = true
                            }
                            
                            if (self.splitViewController != nil) {
                                //iPad only
                                if let nvc = self.splitViewController!.viewControllers[1] as? UINavigationController {
                                    if let myvc = nvc.topViewController as? MyViewController {
                                        myvc.sortSermonsInSeries()
                                    }
                                }
                                
                            }
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
                    
                default:
                    break
                }
                break
                
            default:
                break
        }
    }
    
//    var resultSearchController = UISearchController()
    
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
        //        navigationController?.toolbarHidden = false
        
        Globals.searchSermons = nil
        
        listActivityIndicator.hidden = false
        listActivityIndicator.startAnimating()
        
        clearSermonsForDisplay()
        tableView.reloadData()
        
        navigationItem.leftBarButtonItem?.enabled = false
        
        for barButton in toolbarItems! as [UIBarButtonItem] {
            barButton.enabled = false
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            Globals.sermonsNeedGroupsSetup = true
            sortAndGroupSermons()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.listActivityIndicator.stopAnimating()
                
                self.navigationItem.leftBarButtonItem?.enabled = true
                
                for barButton in self.toolbarItems! as [UIBarButtonItem] {
                    barButton.enabled = true
                }
                
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
        
        let button = object as? UIBarButtonItem
        
        popover = storyboard?.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
        popover?.modalPresentationStyle = .Popover
//        popover!.preferredContentSize = CGSizeMake(300, 500)
        
        popover?.popoverPresentationController?.permittedArrowDirections = .Down
        popover?.popoverPresentationController?.delegate = self
        popover?.popoverPresentationController?.barButtonItem = button
        
        popover?.delegate = self
        popover?.purpose = .selectingSection
        popover?.strings = Globals.sermonSections        

        // Too slow
//        if (Globals.grouping == Constants.SERIES) {
//            let strings = seriesFromSermons(Globals.activeSermons,withTitles: true)
//            popover?.strings = strings
//        } else {
//            popover?.strings = Globals.sermonSections
//        }
        
        popover?.showIndex = false // (Globals.grouping == Constants.SERIES) // too cumbersome
        popover?.showSectionHeaders = false // (Globals.grouping == Constants.SERIES)  // too cumbersome

        if (popover != nil) {
            presentViewController(popover!, animated: true, completion: nil)
        }
    }

    func grouping(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        let button = object as? UIBarButtonItem
        
        popover = storyboard?.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
        popover?.modalPresentationStyle = .Popover
        //        popover!.preferredContentSize = CGSizeMake(300, 500)
        
        popover?.popoverPresentationController?.permittedArrowDirections = .Down
        popover?.popoverPresentationController?.delegate = self
        popover?.popoverPresentationController?.barButtonItem = button
        
        popover?.delegate = self
        popover?.purpose = .selectingGrouping
        popover?.strings = [Constants.Year,Constants.Series,Constants.Book,Constants.Speaker]
        
        popover?.showIndex = false
        
        if (popover != nil) {
            presentViewController(popover!, animated: true, completion: nil)
        }
    }
    
    func sorting(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        let button = object as? UIBarButtonItem
        
        popover = storyboard?.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
        popover?.modalPresentationStyle = .Popover
        //        popover!.preferredContentSize = CGSizeMake(300, 500)
        
        popover?.popoverPresentationController?.permittedArrowDirections = .Down
        popover?.popoverPresentationController?.delegate = self
        popover?.popoverPresentationController?.barButtonItem = button
        
        popover?.delegate = self
        popover?.purpose = .selectingSorting
        popover?.strings = [Constants.Chronological,Constants.Reverse_Chronological]
        
        popover?.showIndex = false
        
        if (popover != nil) {
            presentViewController(popover!, animated: true, completion: nil)
        }
    }

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    private func setupShowMenu()
    {
        navigationItem.leftBarButtonItem?.enabled = (Globals.sermons != nil) && !Globals.sermonsSortingOrGrouping
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
        
        if (Globals.sermons == nil) {
            for barButton in barButtons {
                barButton.enabled = false
            }
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchBar:textDidChange:")
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
        return !Globals.sermonsSortingOrGrouping && (Globals.sermons != nil)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        Globals.searchActive = true
        searchBar.showsCancelButton = true
        
        clearSermonsForDisplay()
        self.tableView.reloadData()
        for barButton in toolbarItems! as [UIBarButtonItem] {
            barButton.enabled = false
        }
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
        
        Globals.sermonsNeedGroupsSetup = true
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
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("URLSession: \(session.description) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func mpPlayerLoadStateDidChange(notification:NSNotification)
    {
        let player = notification.object as! MPMoviePlayerController
        
        /* Enough data has been buffered for playback to continue uninterrupted. */
        
        let loadstate:UInt8 = UInt8(player.loadState.rawValue)
        let loadvalue:UInt8 = UInt8(MPMovieLoadState.PlaythroughOK.rawValue)
        
        // If there is a sermon that was playing before and we want to start back at the same place,
        // the PlayPause button must NOT be active until loadState & PlaythroughOK == 1.
        
        //        println("\(loadstate)")
        //        println("\(loadvalue)")
        
        if ((loadstate & loadvalue) == (1<<1)) {
            print("AppDelegate mpPlayerLoadStateDidChange.MPMovieLoadState.PlaythroughOK")
            //should be called only once, only for  first time audio load.
            if(!Globals.sermonLoaded) {
                print("\(Globals.sermonPlaying!.currentTime!)")
                print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
                
                let defaults = NSUserDefaults.standardUserDefaults()
                if let currentTime = defaults.stringForKey(Constants.CURRENT_TIME) {
                    Globals.sermonPlaying!.currentTime = currentTime
                }
                
                print("\(Globals.sermonPlaying!.currentTime!)")
                print("\(NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!))")
                
                Globals.mpPlayer?.currentPlaybackTime = NSTimeInterval(Float(Globals.sermonPlaying!.currentTime!)!)
                
                Globals.sermonLoaded = true
            }
            
            var myvc:MyViewController?
            
            if let svc = splitViewController {
                //iPad
                if let nvc = svc.viewControllers[1] as? UINavigationController {
                    myvc = nvc.topViewController as? MyViewController
                }
            } else {
                myvc = self.navigationController?.topViewController as? MyViewController
            }
            myvc?.spinner.stopAnimating()

            setupTitle()
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    func setupSermonPlaying()
    {
        setupPlayer(Globals.sermonPlaying)
        
        if (!Globals.sermonLoaded) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "mpPlayerLoadStateDidChange:", name: MPMoviePlayerLoadStateDidChangeNotification, object: Globals.mpPlayer)
        }
    }
    
    func loadSermons(completion: (() -> Void)?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Sermons"
            })
            
            if let sermons = sermonsFromDocumentsDirectoryArchive() {
                Globals.sermons = sermons
            } else {
                let sermonDicts = loadSermonDicts()
                Globals.sermons = sermonsFromSermonDicts(sermonDicts)
                sermonsToDocumentsDirectoryArchive(Globals.sermons)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Synthesizing Tags"
            })
            
            Globals.sermonTags = tagsFromSermons(Globals.sermons)
            
            //            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Defaults"
            })
            loadDefaults()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Sorting and Grouping"
            })
            Globals.sermonsNeedGroupsSetup = true
            sortAndGroupSermons()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Setting up Player"
                self.setupSermonPlaying()
            })
            
            var mytvc:MyTableViewController?
            var myvc:MyViewController?
            
            if let svc = self.splitViewController {
                //iPad
                if let nvc = svc.viewControllers[0] as? UINavigationController {
                    mytvc = nvc.topViewController as? MyTableViewController
                }
                if let nvc = svc.viewControllers[1] as? UINavigationController {
                    myvc = nvc.topViewController as? MyViewController
                }
            } else {
                mytvc = self.navigationController?.topViewController as? MyTableViewController
                myvc = self.navigationController?.topViewController as? MyViewController
            }
            
            if (mytvc != nil) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    mytvc!.setupSearchBar()
                    //                    if (Globals.activeSermons != nil) {
                    //                        mytvc!.tableView.hidden = false
                    //                    } else {
                    //                        mytvc!.tableView.hidden = true
                    //                    }
                    mytvc!.tableView.reloadData()
                    mytvc!.navigationItem.leftBarButtonItem?.enabled = true
                    for barButton in mytvc!.toolbarItems! as [UIBarButtonItem] {
                        barButton.enabled = true
                    }
                    mytvc!.listActivityIndicator.stopAnimating()
                    
                    let defaults = NSUserDefaults.standardUserDefaults()
                    
                    if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
                        if let sermons = Globals.sermons {
                            for sermon in sermons {
                                if (sermon.keyBase == selectedSermonKey) {
                                    mytvc!.selectedSermon = sermon
                                    
                                    if let sermonList = Globals.activeSermons {
                                        if (sermonList.indexOf(mytvc!.selectedSermon!) != nil) {
                                            mytvc!.selectOrScrollToSermon(sermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                                        }
                                    }
                                    break
                                }
                            }
                        }
                    }
                })
            }
            
            if (myvc != nil) {
                let defaults = NSUserDefaults.standardUserDefaults()
                if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
                    if let sermons = Globals.sermons {
                        for sermon in sermons {
                            if (sermon.keyBase == selectedSermonKey) {
                                myvc?.selectedSermon = sermon
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    myvc?.updateUI()
                                    myvc?.scrollToSermon(sermon,select:true,position:UITableViewScrollPosition.Top)
                                })
                                break
                            }
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?()
            })
        })

//        let sermonDicts = loadSermonDicts()
//        
//        Globals.sermons = sermonsFromSermonDicts(sermonDicts)
//        
//        Globals.sermonTags = tagsFromSermons(Globals.sermons)
//        
//        loadDefaults()
//        
//        Globals.sermonsNeedGroupsSetup = true
//        sortAndGroupSermons()
//        
//        tableView.reloadData()
//        
//        setupSermonPlaying()
//        
//        let defaults = NSUserDefaults.standardUserDefaults()
//        
//        if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
//            if let sermons = Globals.activeSermons {
//                for sermon in sermons {
//                    if (sermon.keyBase == selectedSermonKey) {
//                        selectedSermon = sermon
//                        selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
//                        break
//                    }
//                }
//            }
//        }
//        
//        //iPad Only
//        if let navCon = self.splitViewController?.viewControllers[1] as? UINavigationController {
//            navCon.popToRootViewControllerAnimated(true)
//            if let mvc = navCon.viewControllers[0] as? MyViewController {
//                if let selectedSermonDetailKey = defaults.stringForKey(Constants.SELECTED_SERMON_DETAIL_KEY) {
//                    if let sermons = Globals.activeSermons {
//                        for sermon in sermons {
//                            if (sermon.keyBase == selectedSermonDetailKey) {
//                                mvc.selectedSermon = sermon
//                                mvc.updateUI()
//                                mvc.scrollToSermon(mvc.selectedSermon,select:true,position:UITableViewScrollPosition.Top)
//                                break
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        self.refreshControl?.endRefreshing()
//        
//        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
//        if Globals.testing {
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
//        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        var success = true
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        let fileManager = NSFileManager.defaultManager()
        
        //Get documents directory URL
        let destinationURL = documentsURL()?.URLByAppendingPathComponent(filename)
        // Check if file exist
        if (fileManager.fileExistsAtPath(destinationURL!.path!)){
            do {
                try NSFileManager.defaultManager().removeItemAtURL(destinationURL!)
            } catch _ {
                print("failed to remove old json file")
            }
        }
        
        do {
            try fileManager.copyItemAtURL(location, toURL: destinationURL!)
            try fileManager.removeItemAtURL(location)
        } catch _ {
            print("failed to copy new json file to Documents")
            success = false
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                Globals.playerPaused = true
                Globals.mpPlayer?.pause()
                
                updateUserDefaultsCurrentTimeExact()
                saveSermonSettings()
                
                Globals.mpPlayer?.view.hidden = true
                Globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSermons() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl!.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.setupTitle()
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
        
        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.CBC_SHORT.lowercaseString).\(Constants.SERMONS_JSON)"
        let downloadRequest = NSMutableURLRequest(URL: NSURL(string: jsonURL)!)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTaskWithRequest(downloadRequest)
        downloadTask?.taskDescription = Constants.SERMONS_JSON
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        cancelAllDownloads()
        
        if let svc = self.splitViewController {
            //iPad
            if let nvc = svc.viewControllers[1] as? UINavigationController {
                if let myvc = nvc.topViewController as? MyViewController {
                    myvc.selectedSermon = nil
                    myvc.updateUI()
                }
            }
        }
        
        downloadJSON()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: Selector("handleRefresh:"), forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.addSubview(refreshControl!)
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Do either of the two lines below matter? What does each do do that isn't already being done?  Nothing that I can see.
//        tableView.contentOffset = CGPointMake(0,searchBar.frame.size.height - tableView.contentOffset.y);
//        tableView.tableHeaderView = searchBar
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let selectedSermonKey = defaults.stringForKey(Constants.SELECTED_SERMON_KEY) {
            if let sermons = Globals.sermons {
                for sermon in sermons {
                    if (sermon.keyBase == selectedSermonKey) {
                        selectedSermon = sermon
                    }
                }
            }
        }
        
        //.AllVisible and .Automatic is the only option that works reliably.
        //.PrimaryOverlay and .PrimaryHidden create constraint errors after dismissing the master and then swiping right to bring it back
        //and *then* changing orientation
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
        
//        splitViewController?.maximumPrimaryColumnWidth = 325
        
//        definesPresentationContext = true

        // Programmatically created search bar used when this was a subclass of UITableViewController.
        // This did not work when rotating between portrait and landscape w/ the searchBar active because
        // the searchBar would change position and be hidden under the navbar depending on which orientation 
        // the search changed.  Also, depending upon the UITableViewController (and/or NavBarController it was
        // embedded in) settings for whether the list extended under bars at the top and bottom (and whether it did
        // so when they were opaque) the searchBar would change position when activated and the change would be 
        // different in portrait than in landscape - one would be fine (e.g. landscape) and the other would not.
        // Solved by making this class a subclass of UIViewController and adding the tableView separately and putting
        // a searchBar directly in the tableView in the storyBoard.  This makes everything work.  the UISearchBarDelegate
        // functions must be used rather than the UISearchControllerDelegate functions, but that's not a big deal,
        // I used the same searchResultsUpdate function, just w/o the searchResultsController argument.
        // The UISearchBarDelegate functions are straightforward, offer better control, and are simple to implement.
        // The searchBar appears to behave slightly differently, but this is the only way to get reliable searchBar
        // layout behavior in different orientations and when switching between orientations w/ the searchBar active.
        
//        resultSearchController = ({
//            let controller = UISearchController(searchResultsController: nil)
//            controller.searchResultsUpdater = self
//            controller.delegate = self
//            controller.searchBar.delegate = self
//            controller.dimsBackgroundDuringPresentation = false
//            controller.searchBar.sizeToFit()
//            controller.hidesNavigationBarDuringPresentation = false
//
//            controller.searchBar.showsSearchResultsButton = true
//
////            controller.searchBar.showsScopeBar = true
////            controller.searchBar.scopeButtonTitles = ["Foo","Bar"]
//            
//            self.tableView.tableHeaderView = controller.searchBar
//            
//            return controller
//        })()
        
        // Reload the table
        tableView.reloadData()

        tableView?.allowsSelection = true

        //tableView?.allowsMultipleSelection = false

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        // Register cell classes - only used if cell is creatd programmatically
        //tableView!.registerClass(MyTableViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
//        setPlayingPausedButton()
        
        navigationController?.toolbarHidden = false
        setupSortingAndGroupingOptions()
        setupShowMenu()
    }

    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
//        print("searchBarResultsListButtonClicked")
        
        if (!Globals.sermonsSortingOrGrouping) && (Globals.sermonTags != nil) && (self.storyboard != nil) {
            popover = storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? PopoverTableViewController
            
            popover?.modalPresentationStyle = .Popover
//            popover?.preferredContentSize = CGSizeMake(300, 500)
            
            popover?.popoverPresentationController?.permittedArrowDirections = .Up
            popover?.popoverPresentationController?.delegate = self

            popover?.popoverPresentationController?.sourceView = searchBar
            popover?.popoverPresentationController?.sourceRect = searchBar.bounds

            popover?.delegate = self
            popover?.purpose = .selectingTags
            popover?.strings = Globals.sermonTags
                
            if (popover != nil) {
                presentViewController(popover!, animated: true, completion: nil)
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        updateSearchResults()
    }
    
    func updateSearchResults()
    {
//        print("updateSearchResultsForSearchController")
        
//        filteredTableData.removeAll()
//        
//        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text)
//        let results = (Globals.sermons as NSArray).filteredArrayUsingPredicate(searchPredicate)
        
        searchActivityIndicator.hidden = false
        searchActivityIndicator.startAnimating()
        
        if let searchText = self.searchBar.text {
            clearSermonsForDisplay()
            self.tableView.reloadData()
            for barButton in toolbarItems! as [UIBarButtonItem] {
                barButton.enabled = false
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (searchText != Constants.EMPTY_STRING) {
                    var searchSermons = [Sermon]()
                    
                    if let sermons = Globals.sermonsToSearch {
                        for sermon in sermons {
                            if (
                                    ((sermon.title?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                    ((sermon.date?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                    ((sermon.speaker?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                    ((sermon.series?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                    ((sermon.scripture?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                                    ((sermon.tags?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                                )
                            {
                                searchSermons.append(sermon) //Globals.
                            }
                        }
                    }
                    
                    Globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
                }
                
                Globals.sermonsNeedGroupsSetup = true
                sortAndGroupSermons()
                
                if (searchText == self.searchBar.text!) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.searchActivityIndicator.stopAnimating()
                        for barButton in self.toolbarItems! as [UIBarButtonItem] {
                            barButton.enabled = true
                        }
                    })
                } else {
                    print("Threw away search results!")
                }
            })
        }
    }

    func selectOrScrollToSermon(sermon:Sermon?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        if (sermon != nil) {
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let sermons = Globals.display.sermons

            if let index = sermons!.indexOf(sermon!) {
                switch Globals.grouping! {
                case Constants.YEAR:
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components(.Year, fromDate: sermons![index].fullDate!)
                    
                    var sermonYears:[Int]?
                    
                    switch Globals.sorting! {
                    case Constants.REVERSE_CHRONOLOGICAL:
                        sermonYears = Globals.sermonYears!.sort({ $1 < $0 })
                        break
                    case Constants.CHRONOLOGICAL:
                        sermonYears = Globals.sermonYears!.sort({ $0 < $1 })
                        break
                        
                    default:
                        break
                    }
                    
                    section = sermonYears!.indexOf(components.year)!
                    break
                    
                case Constants.SERIES:
                    section = Globals.sermonSections!.indexOf(sermon!.seriesSection!)!
                    break
                    
                case Constants.BOOK:
                    section = Globals.sermonSections!.indexOf(sermon!.bookSection!)!
                    break
                    
                case Constants.SPEAKER:
                    section = Globals.sermonSections!.indexOf(sermon!.speakerSection!)!
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
            searchBar.placeholder = Globals.sermonTags?[Globals.sermonTags!.count - 1]
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
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (Globals.sermons == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
            }
        } else {
            if let nvc = self.splitViewController?.viewControllers[1] as? UINavigationController {
                if let _ = nvc.topViewController as? WebViewController {
                    splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                } else {
                    splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupSearchBar()
        
        setupSplitViewController()
        
        setupTitle()
        
        navigationController?.toolbarHidden = false
        
        //Make sure the rightBarButton is setup
//        setPlayingPausedButton()
    }
    
    func about()
    {
        performSegueWithIdentifier(Constants.Show_About, sender: self)
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        remoteControlEvent(event!)
        if let nvc = splitViewController?.viewControllers[1] as? UINavigationController {
            if let myvc = nvc.topViewController as? MyViewController {
                myvc.setupPlayPauseButton()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if Globals.sermons == nil {
            loadSermons(nil)
        }

        Globals.loadedEnoughToDeepLink = true
        
        if (Globals.deepLinkWaiting) {
            deepLink()
        } else {
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
        }
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


    func setPlayingPausedButton()
    {
        if (Globals.sermonPlaying != nil) {
            var title:String = Constants.EMPTY_STRING
            
            if (Globals.playerPaused) {
                title = Constants.Paused
            } else {
                title = Constants.Playing
            }
            
            var playingPausedButton = navigationItem.rightBarButtonItem
            
            if (playingPausedButton == nil) {
                playingPausedButton = UIBarButtonItem(title: Constants.EMPTY_STRING, style: UIBarButtonItemStyle.Plain, target: self, action: "gotoPlayingPaused")
            }
            
            playingPausedButton!.title = title
            
            if (splitViewController != nil) {
                //Only need to show it if About is being displayed.
                if (Globals.showingAbout) || (selectedSermon == nil) {
                    navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
                }
            } else {
                if (navigationItem.rightBarButtonItem == nil) {
                    navigationItem.setRightBarButtonItem(playingPausedButton, animated: true)
                }
            }
        } else {
            if (navigationItem.rightBarButtonItem != nil) {
                navigationItem.setRightBarButtonItem(nil, animated: true)
            }
        }
    }
    
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
            case Constants.Show_About:
                Globals.showingAbout = true
//                setPlayingPausedButton()
                break
                
            case Constants.Show_Sermon:
                Globals.showingAbout = false
                if (Globals.gotoPlayingPaused) {
                    Globals.gotoPlayingPaused = !Globals.gotoPlayingPaused

                    if let destination = dvc as? MyViewController {
                        destination.selectedSermon = Globals.sermonPlaying
                    }

                    navigationItem.setRightBarButtonItem(nil, animated: true)
                } else {
                    if let myCell = sender as? MyTableViewCell {
                        if let indexPath = tableView.indexPathForCell(myCell) {
                            let index = Globals.display.sectionIndexes![indexPath.section]+indexPath.row
                            
                            selectedSermon = Globals.activeSermons![index]
                            if let sermon = selectedSermon {
                                let defaults = NSUserDefaults.standardUserDefaults()
                                defaults.setObject(sermon.keyBase,forKey: Constants.SELECTED_SERMON_KEY)
                                defaults.synchronize()
                                
                                if let destination = dvc as? MyViewController {
                                    destination.selectedSermon = sermon
                                }
                            }
                        }
                    }
                    
                    if (splitViewController != nil) {
                        navigationItem.setRightBarButtonItem(nil, animated: true)
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
        setupSplitViewController()
        
        if (splitViewController == nil) {
            if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
                navigationItem.title = Constants.CBC_TITLE_LONG
            } else {
                navigationItem.title = Constants.CBC_TITLE_SHORT
            }
        } else {
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
        return Globals.display.sections != nil ? Globals.display.sections!.count : 0
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
        return Globals.display.sections != nil ? Globals.display.sections![section] : nil
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

        return cell
    }

    // MARK: UITableViewDelegate
    
    func tableView(TableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didSelect")

//        if let cell: MyTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//            //cell.backgroundColor = UIColor.whiteColor()
//        } else {
//            
//        }
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
