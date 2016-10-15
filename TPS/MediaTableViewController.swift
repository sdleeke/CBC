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

class MediaTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate, PopoverPickerControllerDelegate, URLSessionDownloadDelegate { //

    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }

    var refreshControl:UIRefreshControl?

    var session:URLSession? // Used for JSON
    
    func stringPicked(_ string:String?)
    {
        dismiss(animated: true, completion: nil)
        
//        print(string)
        
        if (globals.sermonCategory != string) {
            globals.sermonCategory = string
            globals.tags.selected = nil
            
            if globals.player.mpPlayer?.contentURL != URL(string: Constants.LIVE_STREAM_URL) {
                globals.player.mpPlayer?.pause()
                globals.player.mpPlayer?.view.isHidden = true
                globals.updateCurrentTimeExact()
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.searchBar.placeholder = nil
                self.sermonCategoryButton.setTitle(globals.sermonCategory, for: UIControlState.normal)
                self.listActivityIndicator.isHidden = false
                self.listActivityIndicator.startAnimating()
            })
            
            // This does not show the activityIndicator
            handleRefresh(refreshControl!)
        }
    }

    @IBOutlet weak var sermonCategoryButton: UIButton!
    @IBAction func sermonCategoryButtonAction(_ button: UIButton) {
        NSLog("categoryButtonAction")
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: "StringPicker") as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: UIPopoverArrowDirection.up.rawValue + UIPopoverArrowDirection.down.rawValue)
                
                navigationController.popoverPresentationController?.sourceView = self.view
                navigationController.popoverPresentationController?.sourceRect = sermonCategoryButton.frame
                
                popover.navigationItem.title = "Select Category"
                
                popover.delegate = self
                
                popover.strings = ["All Media"]
                
                if (globals.sermonCategories != nil) {
                    popover.strings?.append(contentsOf: globals.sermonCategories!)
                }
                
                popover.string = globals.sermonCategory
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    var progressTimer:Timer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem) {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
//                popover.navigationItem.title = "Show"
                
                popover.navigationController?.isNavigationBarHidden = true
                
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
                                    NSLog("There is no selectedSermon - which should never happen")
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
                
                showMenu.append(Constants.Scripture_Index)

                showMenu.append(Constants.History)
                
                showMenu.append(Constants.Clear_History)
                
                showMenu.append(Constants.Live)
                
                showMenu.append(Constants.Settings)
                
                popover.strings = showMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    var selectedSermon:Sermon? {
        didSet {
            let defaults = UserDefaults.standard
            if (selectedSermon != nil) {
                defaults.set(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_KEY)
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
                barButton.isEnabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.leftBarButtonItem?.isEnabled = false
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if (globals.sermonRepository.list != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (globals.sermonRepository.list != nil) {
            navigationItem.leftBarButtonItem?.isEnabled = true
            enableToolBarButtons()
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismiss(animated: true, completion: nil)
        
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
            if let range = globals.history!.reversed()[index].range(of: Constants.TAGS_SEPARATOR) {
                sermonID = globals.history!.reversed()[index].substring(from: range.upperBound)
            } else {
                sermonID = globals.history!.reversed()[index]
            }
            if let sermon = globals.sermonRepository.index![sermonID] {
                if globals.activeSermons!.contains(sermon) {
                    selectOrScrollToSermon(sermon, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                } else {
                    dismiss(animated: true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not in List",
                        message: "You are currently showing the series \"\(globals.tags.selected!)\" and the sermon \"\(sermon.title!)\" does is not in that series.  Show the series \"All\" and try again.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    present(alert, animated: true, completion: nil)
                }
            } else {
                dismiss(animated: true, completion: nil)
                
                let alert = UIAlertController(title:"Sermon Not Found!",
                    message: "Yep, a genuine error - this should never happen!",
                    preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                present(alert, animated: true, completion: nil)
            }
            break
            
        case .selectingTags:
            
            // Should we be showing globals.active!.sermonTags instead?  That would be the equivalent of drilling down.

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                //                    if (index >= 0) && (index <= globals.sermons.all!.sermonTags!.count) {
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch strings[index] {
                    case Constants.All:
                        if (globals.tags.showing != Constants.ALL) {
                            new = true
                            globals.tags.showing = Constants.ALL
                            globals.tags.selected = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        
                        let tagSelected = strings[index]
                        
                        new = (globals.tags.showing != Constants.TAGGED) || (globals.tags.selected != tagSelected)
                        
                        if (new) {
                            //                                NSLog("\(globals.active!.sermonTags)")
                            
                            globals.tags.selected = tagSelected
                            
                            globals.tags.showing = Constants.TAGGED
                        }
                        break
                    }
                    
                    if (new) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            globals.clearDisplay()
                            
                            self.tableView.reloadData()
                            
                            self.listActivityIndicator.isHidden = false
                            self.listActivityIndicator.startAnimating()
                            
                            self.disableBarButtons()
                        })
                        
                        if (globals.searchActive) {
                            self.updateSearchResults(globals.searchText)
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            globals.setupDisplay()
                            
                            self.tableView.reloadData()
                            self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
                            self.listActivityIndicator.stopAnimating()
                            self.listActivityIndicator.isHidden = true
                            
                            self.enableBarButtons()
                            
                            self.setupSearchBar()
                        })
                    }
                } else {
                    NSLog("Index out of range")
                }
            })
            break
            
        case .selectingSection:
            dismiss(animated: true, completion: nil)
            let indexPath = IndexPath(row: 0, section: index)
            
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
            //                            if !sermon.hasSeries {
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
            tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            break
            
        case .selectingGrouping:
            dismiss(animated: true, completion: nil)
            globals.grouping = Constants.groupings[index]
            
            if (globals.sermonsNeed.grouping) {
                globals.clearDisplay()
                tableView.reloadData()
                
                listActivityIndicator.isHidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    globals.progress = 0
                    globals.finished = 0
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.progressTimer = Timer.scheduledTimer(timeInterval: Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
                    })
                    
                    globals.setupDisplay()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.progressTimer?.invalidate()
                        self.progressTimer = nil
                        self.progressIndicator.isHidden = true
                    })
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        self.listActivityIndicator.stopAnimating()
                        self.enableBarButtons()
                    })
                })
            }
            break
            
        case .selectingSorting:
            dismiss(animated: true, completion: nil)
            globals.sorting = Constants.sortings[index]
            
            if (globals.sermonsNeed.sorting) {
                globals.clearDisplay()
                tableView.reloadData()
                
                listActivityIndicator.isHidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    globals.setupDisplay()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
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
            dismiss(animated: true, completion: nil)
            switch strings[index] {
            case Constants.About:
                about()
                break
                
            case Constants.Current_Selection:
                if let sermon = selectedSermon {
                    if globals.activeSermons!.contains(sermon) {
                        selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.top)
                    } else {
                        dismiss(animated: true, completion: nil)
                        
                        let alert = UIAlertController(title:"Sermon Not in List",
                            message: "You are currently showing the series \"\(globals.tags.selected!)\" and the sermon \"\(sermon.title!)\" is not in that series.  Show the series \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        present(alert, animated: true, completion: nil)
                    }
                } else {
                    dismiss(animated: true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not Found!",
                        message: "Yep, a genuine error - this should never happen!",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    present(alert, animated: true, completion: nil)
                }
                break
                
            case Constants.Sermon_Playing:
                fallthrough
                
            case Constants.Sermon_Paused:
                globals.gotoPlayingPaused = true
                performSegue(withIdentifier: Constants.SHOW_SERMON_SEGUE, sender: self)
                break
                
            case Constants.Scripture_Index:
                let viewController = self.storyboard!.instantiateViewController(withIdentifier: "Scripture Index")
                self.navigationController?.navigationItem.hidesBackButton = false
                self.navigationController?.isToolbarHidden = true
                self.navigationController?.pushViewController(viewController, animated: true)

//                performSegue(withIdentifier: Constants.SHOW_SCRIPTURE_INDEX_SEGUE, sender: nil)
                break
                
            case Constants.History:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .popover
                        //            popover?.preferredContentSize = CGSizeMake(300, 500)
                        
                        navigationController.popoverPresentationController?.permittedArrowDirections = .up
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.barButtonItem = showButton
                        
                        popover.navigationItem.title = Constants.History
                        
                        popover.delegate = self
                        popover.purpose = .selectingHistory
                        
                        var historyMenu = [String]()
//                        var sections = [String]()
                        
//                        print(globals.history)
                        if let historyList = globals.history?.reversed() {
//                            print(historyList)
                            for history in historyList {
                                var sermonID:String
//                                var date:String
                                
                                if let range = history.range(of: Constants.TAGS_SEPARATOR) {
                                    sermonID = history.substring(from: range.upperBound)
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

                        present(navigationController, animated: true, completion: nil)
                    }
                }
                break
                
            case Constants.Clear_History:
                globals.history = nil
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: Constants.HISTORY)
                defaults.synchronize()
                break
                
            case Constants.Live:
                performSegue(withIdentifier: Constants.SHOW_LIVE_SEGUE, sender: nil)
                break
                
            case Constants.Settings:
                performSegue(withIdentifier: Constants.SHOW_SETTINGS_SEGUE, sender: nil)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
//        NSLog("willPresentSearchController")
        globals.searchActive = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController)
    {
        globals.searchActive = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController)
    {
        didDismissSearch()
    }
    
    func didDismissSearch() {
        globals.sermons.search = nil
        
        listActivityIndicator.isHidden = false
        listActivityIndicator.startAnimating()
        
        globals.clearDisplay()
        
        tableView.reloadData()
        
        disableBarButtons()
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.setupDisplay()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                self.listActivityIndicator.stopAnimating()
                self.enableBarButtons()
                
                //Moving the list can be very disruptive
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.none)
            })
        })
    }
    
    func index(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Titles.Index
                
                popover.delegate = self
                
                popover.purpose = .selectingSection

                switch globals.grouping! {
                case Grouping.TITLE:
                    popover.strings = globals.active?.sectionTitles
                    popover.indexStrings = globals.active?.sectionTitles
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    break
                    
                case Grouping.BOOK:
                    if let books = globals.active?.sectionTitles?.filter({ (string:String) -> Bool in
                        return bookNumberInBible(string) != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
//                        print(books)
                        popover.strings = books

                        if let other = globals.active?.sectionTitles?.filter({ (string:String) -> Bool in
                            return bookNumberInBible(string) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                        }) {
//                            print(other)
//                            print(other.sorted(by: { stringWithoutPrefixes($0)! < stringWithoutPrefixes($1)! } ))
                            popover.strings?.append(contentsOf: other)
//                            popover.strings?.append(contentsOf: other.sorted(by: { stringWithoutPrefixes($0)! < stringWithoutPrefixes($1)! } ))
                        }
                    }
//                    print(popover.strings)
                    popover.indexStrings = popover.strings
                    popover.showIndex = false
                    popover.showSectionHeaders = false
                    break
                    
                case Grouping.SPEAKER:
                    popover.strings = globals.active?.sectionTitles?.sorted(by: { lastNameFromName($0)! < lastNameFromName($1)! } )
                    
                    popover.transform = lastNameFromName
                    
//                        ?.sorted(by: {
//                        print($0,$1)
//                        let index0 = globals.active!.sectionTitles!.index(of: $0)!
//                        let index1 = globals.active!.sectionTitles!.index(of: $1)!
//                        
//                        print(globals.active!.sectionIndexTitles![index0],globals.active!.sectionIndexTitles![index1])
//                        return globals.active!.sectionIndexTitles![index0] < globals.active!.sectionIndexTitles![index1]
//                    })

                    popover.indexStrings = globals.active?.sectionIndexTitles
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    break
                    
                default:
                    popover.strings = globals.active?.sectionTitles
                    popover.indexStrings = globals.active?.sectionTitles
                    popover.showIndex = false
                    popover.showSectionHeaders = false
                    break
                }
                
                present(navigationController, animated: true, completion: nil)
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

    func grouping(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Grouping_Options_Title
                
                popover.delegate = self
                
                popover.purpose = .selectingGrouping
                popover.strings = Constants.Groupings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func sorting(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Sorting_Options_Title
                
                popover.delegate = self
                
                popover.purpose = .selectingSorting
                popover.strings = Constants.Sortings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
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
    
    fileprivate func setupShowMenu()
    {
        let showButton = navigationItem.leftBarButtonItem
        
        showButton?.title = Constants.FA_REORDER
        showButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_SHOW_FONT_SIZE)!], for: UIControlState())
        
        showButton?.isEnabled = (globals.sermons.all != nil) //&& !globals.sermonsSortingOrGrouping
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Titles.Sorting, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Titles.Grouping, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Titles.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.index(_:)))

        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        barButtons.append(sortingButton)
        barButtons.append(spaceButton)
        barButtons.append(groupingButton)
        barButtons.append(spaceButton)
        barButtons.append(indexButton)
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.isTranslucent = false
        
        if (globals.sermonRepository.list == nil) {
            disableToolBarButtons()
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        NSLog("searchBar:textDidChange:")
        //Unstable results from incremental search
//        updateSearchResults()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        NSLog("searchBarSearchButtonClicked:")
        searchBar.resignFirstResponder()
        globals.searchText = searchBar.text
        updateSearchResults(globals.searchText)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return !globals.loading && !globals.refreshing && (globals.sermons.all != nil) // !globals.sermonsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        NSLog("searchBarTextDidBeginEditing:")
        globals.searchActive = true
        searchBar.showsCancelButton = true
        
        globals.clearDisplay()
        tableView.reloadData()
        disableToolBarButtons()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        NSLog("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        NSLog("searchBarCancelButtonClicked:")
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        globals.searchActive = false
        globals.searchText = nil
        
        didDismissSearch()
    }
    
    func setupViews()
    {
        setupSearchBar()
        
        tableView.reloadData()
        
        enableBarButtons()
        
        listActivityIndicator.stopAnimating()
        listActivityIndicator.isHidden = true
        
        setupTitle()
        
        addRefreshControl()
        
        selectedSermon = globals.selectedSermon
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            })
        })
        
        if (splitViewController != nil) {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.UPDATE_VIEW_NOTIFICATION), object: nil)
            })
        }
    }
    
    func updateProgress()
    {
//        NSLog("\(Float(globals.progress))")
//        NSLog("\(Float(globals.finished))")
//        NSLog("\(Float(globals.progress) / Float(globals.finished))")
        
        self.progressIndicator.progress = 0
        if (globals.finished > 0) {
            self.progressIndicator.isHidden = false
            self.progressIndicator.progress = Float(globals.progress) / Float(globals.finished)
        }
        
        //            NSLog("\(self.progressIndicator.progress)")
        
        if self.progressIndicator.progress == 1.0 {
            self.progressTimer?.invalidate()
            
            self.progressIndicator.isHidden = true
            self.progressIndicator.progress = 0
            
            globals.progress = 0
            globals.finished = 0
        }
    }
    
    func jsonFromURL(url:String,filename:String) -> JSON
    {
        let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: URL(string: url)!, options: NSData.ReadingOptions.mappedIfSafe)
            
            let json = JSON(data: data)
            if json != JSON.null {
                try data.write(to: jsonFileSystemURL!, options: NSData.WritingOptions.atomicWrite)
                
                print(json)
                return json
            } else {
                NSLog("could not get json from file, make sure that file contains valid json.")
                
                let data = try Data(contentsOf: jsonFileSystemURL!, options: NSData.ReadingOptions.mappedIfSafe)
                
                let json = JSON(data: data)
                if json != JSON.null {
//                    print(json)
                    return json
                }
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            
            do {
                let data = try Data(contentsOf: jsonFileSystemURL!, options: NSData.ReadingOptions.mappedIfSafe)
                
                let json = JSON(data: data)
                if json != JSON.null {
                    //                        print(json)
                    return json
                }
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        //        } else {
        //            NSLog("Invalid filename/path.")
        //        }
        
        return nil
    }
    
    func loadJSONDictsFromCachesDirectory(key:String) -> [[String:String]]?
    {
        var sermonDicts = [[String:String]]()
        
        let json = jsonDataFromCachesDirectory()
        
        if json != JSON.null {
            //            NSLog("json:\(json)")
            
            let sermons = json[key]
            
            for i in 0..<sermons.count {
                
                var dict = [String:String]()
                
                for (key,value) in sermons[i] {
                    dict[key] = "\(value)"
                }
                
                sermonDicts.append(dict)
            }
            
            //            print(sermonDicts)
            
            return sermonDicts.count > 0 ? sermonDicts : nil
        } else {
            NSLog("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
    {
        var sermonDicts = [[String:String]]()
        
        let json = jsonFromURL(url: url,filename: filename)
        
        if json != JSON.null {
            //            NSLog("json:\(json)")
            
            let sermons = json[key]
            
            for i in 0..<sermons.count {
                
                var dict = [String:String]()
                
                for (key,value) in sermons[i] {
                    dict[key] = "\(value)"
                }
                
                sermonDicts.append(dict)
            }
            
            //            print(sermonDicts)
            
            return sermonDicts.count > 0 ? sermonDicts : nil
        } else {
            NSLog("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func sermonsFromSermonDicts(_ sermonDicts:[[String:String]]?) -> [Sermon]?
    {
        if (sermonDicts != nil) {
            return sermonDicts?.map({ (sermonDict:[String : String]) -> Sermon in
                Sermon(dict: sermonDict)
            })
        }
        
        return nil
    }

    func loadCategories()
    {
        if let categoriesDicts = self.loadJSONDictsFromURL(url: Constants.JSON_CATEGORIES_URL,key:Constants.JSON_CATEGORIES_ARRAY_KEY,filename: Constants.CATEGORIES_JSON_FILENAME) {
            //                print(categoriesDicts)
            
            var sermonCategoryDicts = [String:String]()
            
            for categoriesDict in categoriesDicts {
                sermonCategoryDicts[categoriesDict["category_name"]!] = categoriesDict["id"]
            }
            
            globals.sermonCategoryDicts = sermonCategoryDicts
            
            //                print(globals.sermonCategories)
        }
    }
    
    func loadSermons(completion: (() -> Void)?)
    {
        globals.progress = 0
        globals.finished = 0
        
        progressTimer = Timer.scheduledTimer(timeInterval: Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.loading = true

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Loading_Sermons
            })
            
//            var success = false
//            var newSermons:[Sermon]?

//            if let sermons = sermonsFromArchive() {
//                newSermons = sermons
//                success = true
//            } else if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
//                newSermons = sermons
//                sermonsToArchive(sermons)
//                success = true
//            }
        
//            if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
//                newSermons = sermons
//                success = true
//            }
//
//            if (!success) {
//                // REVERT TO KNOWN GOOD JSON
//                removeJSONFromFileSystemDirectory() // This will cause JSON to be loaded from the BUNDLE next time.
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.setupTitle()
//                    
//                    self.listActivityIndicator.stopAnimating()
//                    self.listActivityIndicator.hidden = true
//                    self.refreshControl?.endRefreshing()
//                    
//                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
//                        let alert = UIAlertController(title:"Unable to Load Sermons",
//                            message: "Please try to refresh the list.",
//                            preferredStyle: UIAlertControllerStyle.Alert)
//                        
//                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
//                            
//                        })
//                        alert.addAction(action)
//                        
//                        self.presentViewController(alert, animated: true, completion: nil)
//                    }
//                })
//                return
//            }

//            var sermonsNewToUser:[Sermon]?
//            
//            if (globals.sermonRepository.list != nil) {
//                
//                let old = Set(globals.sermonRepository.list!.map({ (sermon:Sermon) -> String in
//                    return sermon.id
//                }))
//                
//                let new = Set(newSermons!.map({ (sermon:Sermon) -> String in
//                    return sermon.id
//                }))
//                
//                //                NSLog("\(old.count)")
//                //                NSLog("\(new.count)")
//                
//                let inOldAndNew = old.intersect(new)
//                //                NSLog("\(inOldAndNew.count)")
//                
//                if inOldAndNew.count == 0 {
//                    NSLog("There were NO sermons in BOTH the old JSON and the new JSON.")
//                }
//                
//                let onlyInOld = old.subtract(new)
//                //                NSLog("\(onlyInOld.count)")
//                
//                if onlyInOld.count > 0 {
//                    NSLog("There were \(onlyInOld.count) sermons in the old JSON that are NOT in the new JSON.")
//                }
//                
//                let onlyInNew = new.subtract(old)
//                //                NSLog("\(onlyInNew.count)")
//                
//                if onlyInNew.count > 0 {
//                    NSLog("There are \(onlyInNew.count) sermons in the new JSON that were NOT in the old JSON.")
//                }
//                
//                if (onlyInNew.count > 0) {
//                    sermonsNewToUser = onlyInNew.map({ (id:String) -> Sermon in
//                        return newSermons!.filter({ (sermon:Sermon) -> Bool in
//                            return sermon.id == id
//                        }).first!
//                    })
//                }
//            }
            
            var url:String?

            if globals.sermonCategory != "All Media" {
                url = Constants.JSON_CATEGORY_URL + globals.sermonCategoryID!
            } else {
                url = Constants.JSON_MEDIA_URL
            }
            
//            print(Constants.JSON_CATEGORY_URL + globals.sermonCategoryID!)
            
            if let sermonDicts = self.loadJSONDictsFromURL(url: url!,key: Constants.JSON_SERMONS_ARRAY_KEY,filename: Constants.SERMONS_JSON_FILENAME) {
                globals.sermonRepository.list = self.sermonsFromSermonDicts(sermonDicts)
            }
            
//            globals.sermonRepository.list = newSermons

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

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Loading_Settings
            })
            globals.loadSettings()
            
//            for sermon in globals.sermonRepository.list! {
//                sermon.removeTag(Constants.New)
//            }

//            if (sermonsNewToUser != nil) {
//                for sermon in sermonsNewToUser! {
//                    sermon.addTag(Constants.New)
//                }
//                //                NSLog("\(sermonsNewToUser)")
//                
//                globals.showing = Constants.TAGGED
//                globals.sermonTagsSelected = Constants.New
//            } else {
//                if (globals.showing == Constants.TAGGED) {
//                    if (globals.sermonTagsSelected == Constants.New) {
//                        globals.sermonTagsSelected = nil
//                        globals.showing = Constants.ALL
//                    }
//                }
//            }
//            
//            if (globals.showing == Constants.TAGGED) {
//                if (globals.sermonTagsSelected == Constants.New) {
//                    globals.sermonTagsSelected = nil
//                    globals.showing = Constants.ALL
//                }
//            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Sorting_and_Grouping
            })
            
            globals.sermons.all = SermonsListGroupSort(sermons: globals.sermonRepository.list)

            DispatchQueue.main.async(execute: { () -> Void in
                self.searchBar.text = globals.searchText
            })

            self.updateSearchResults(globals.searchText)

            globals.setupDisplay()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Setting_up_Player
                
                if (globals.player.playing != nil) {
                    globals.player.playOnLoad = false
                    
                    // This MUST be called on the main loop.
                    globals.setupPlayer(globals.player.playing)
                }
            })

            self.refreshControl?.endRefreshing()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.CBC_SHORT_TITLE
                self.setupViews()
                self.sermonCategoryButton.isEnabled = true
                self.listActivityIndicator.isHidden = true
                self.listActivityIndicator.stopAnimating()
            })
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion?()
            })
            
            globals.refreshing = false
            globals.loading = false
        })
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset: Int64, expectedTotalBytes: Int64)
    {
    
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
    NSLog("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        let filename = downloadTask.taskDescription!
        
        NSLog("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        NSLog("URLSession:downloadTask:didFinishDownloadingToURL")
        
        var success = false
        
        NSLog("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        
        NSLog("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        NSLog("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesReceived > 0) {
            let fileManager = FileManager.default
            
            //Get documents directory URL
            if let destinationURL = cachesURL()?.appendingPathComponent(filename) {
                // Check if file exist
                if (fileManager.fileExists(atPath: destinationURL.path)){
                    do {
                        try fileManager.removeItem(at: destinationURL)
                    } catch _ {
                        NSLog("failed to remove old json file")
                    }
                }
                
                do {
                    try fileManager.copyItem(at: location as URL, to: destinationURL)
                    try fileManager.removeItem(at: location as URL)
                    success = true
                } catch _ {
                    NSLog("failed to copy new json file to Documents")
                }
            } else {
                NSLog("failed to get destinationURL")
            }
        } else {
            NSLog("downloadTask.countOfBytesReceived not > 0")
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            DispatchQueue.main.async(execute: { () -> Void in
                if !globals.player.paused {
                    globals.player.paused = true
                    globals.player.mpPlayer?.pause()
                    globals.updateCurrentTimeExact()
                }
                
                globals.player.mpPlayer?.view.isHidden = true
                globals.player.mpPlayer?.view.removeFromSuperview()
                
                self.loadCategories()
                
                self.loadSermons()
                {
//                    self.refreshControl?.endRefreshing()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                    globals.refreshing = false
                }
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                if (UIApplication.shared.applicationState == UIApplicationState.active) {
                    let alert = UIAlertController(title:"Unable to Download Media",
                        message: "Please try to refresh the list again.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    self.present(alert, animated: true, completion: nil)
                }
                
                self.refreshControl!.endRefreshing()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                globals.setupDisplay()
                self.tableView.reloadData()
                
                globals.refreshing = false

                self.setupViews()
            })
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        NSLog("URLSession:task:didCompleteWithError")
        
        if (error != nil) {
//            NSLog("Download failed for: \(session.description)")
        } else {
//            NSLog("Download succeeded for: \(session.description)")
        }
        
        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
//        removeTempFiles()
        
        let filename = task.taskDescription
        NSLog("filename: \(filename!) error: \(error)")
        
        session.invalidateAndCancel()
        
        //        if let taskIndex = globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        NSLog("URLSession:didBecomeInvalidWithError")

    }
    
    func downloadJSON()
    {
        var url:String?
        
        if globals.sermonCategory != "All Media" {
            url = Constants.JSON_CATEGORY_URL + globals.sermonCategoryID!
        } else {
            url = Constants.JSON_MEDIA_URL
        }
        
        navigationItem.title = Constants.Downloading_Sermons
        
//        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.CBC_SHORT.lowercaseString).\(Constants.SERMONS_JSON_FILENAME)"
        let downloadRequest = URLRequest(url: URL(string: url!)!)
        
        let configuration = URLSessionConfiguration.default
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTask(with: downloadRequest)
        downloadTask?.taskDescription = Constants.SERMONS_JSON_FILENAME
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        globals.refreshing = true
        
        globals.cancelAllDownloads()

        globals.clearDisplay()
        
        tableView.reloadData()

        if splitViewController != nil {
            DispatchQueue.main.async(execute: { () -> Void in
//                self.performSegue(withIdentifier: Constants.SHOW_SERMON_SEGUE, sender: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.CLEAR_VIEW_NOTIFICATION), object: nil)
            })
        }

        disableBarButtons()
        
        sermonCategoryButton.isEnabled = false
        
        loadCategories()
        
        // loadSermons or downloadJSON
        
        loadSermons(completion: nil)
        
//        downloadJSON()
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.UPDATE_SERMON_LIST_NOTIFICATION), object: globals.sermons.tagged)

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)

        if globals.sermonRepository.list == nil {
            //            disableBarButtons()
            
            loadCategories()
            
            // Download or Load
            
//            downloadJSON()
            
            loadSermons(completion: nil)
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let selectedSermonKey = UserDefaults.standard.string(forKey: Constants.SELECTED_SERMON_KEY) {
            selectedSermon = globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                return sermon.id == selectedSermonKey
            }).first
        }
        
        //.AllVisible and .Automatic is the only option that works reliably.
        //.PrimaryOverlay and .PrimaryHidden create constraint errors after dismissing the master and then swiping right to bring it back
        //and *then* changing orientation
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
        
        // Reload the table
        tableView.reloadData()

        tableView?.allowsSelection = true

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        navigationController?.isToolbarHidden = false
        setupSortingAndGroupingOptions()
        setupShowMenu()
    }

    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
//        NSLog("searchBarResultsListButtonClicked")
        
        if !globals.loading && !globals.refreshing && (globals.sermons.all?.sermonTags != nil) && (self.storyboard != nil) { // !globals.sermonsSortingOrGrouping &&
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .popover
                    //            popover?.preferredContentSize = CGSizeMake(300, 500)
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.sourceView = searchBar
                    navigationController.popoverPresentationController?.sourceRect = searchBar.bounds
                    
                    popover.navigationItem.title = "Show Series"
                    
                    popover.delegate = self
                    popover.purpose = .selectingTags
                    
//                    print(globals.sermons.all!.sermonTags!)
                    
                    var strings = [Constants.All]
                    
                    strings.append(contentsOf: globals.sermons.all!.sermonTags!)
                    
                    popover.strings = strings.sorted(by: { stringWithoutPrefixes($0)! < stringWithoutPrefixes($1)! })
                    
                    popover.indexStrings = popover.strings
                    
//                    print(globals.sermons.all!.sermonTags)
                    
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    
                    present(navigationController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController)
    {
        updateSearchResults(globals.searchText)
    }
    
    func updateSearchResults(_ searchText:String?)
    {
        if searchText != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.listActivityIndicator.isHidden = false
                self.listActivityIndicator.startAnimating()
            })
            
            globals.clearDisplay()

            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                self.disableToolBarButtons()
            })
            
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                if (searchText != Constants.EMPTY_STRING) {
                    let searchSermons = globals.sermonsToSearch?.filter({ (sermon:Sermon) -> Bool in
                        return
                            ((sermon.id?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.title?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.speaker?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)
                        })
                    
                    globals.sermons.search = SermonsListGroupSort(sermons: searchSermons)
                }
                
                globals.setupDisplay()
                
                if (globals.searchText == searchText) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        self.listActivityIndicator.stopAnimating()
                        self.listActivityIndicator.isHidden = true
                        self.enableToolBarButtons()
                    })
                } else {
                    NSLog("Threw away search results!")
                }
            })
        }
    }

    func selectOrScrollToSermon(_ sermon:Sermon?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        if (sermon != nil) && (globals.activeSermons?.index(of: sermon!) != nil) {
            var indexPath = IndexPath(item: 0, section: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let sermons = globals.activeSermons

            if let index = sermons!.index(of: sermon!) {
                switch globals.grouping! {
                case Grouping.YEAR:
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
                    section = globals.active!.sectionTitles!.index(of: sermon!.yearSection!)!
                    break
                    
                case Grouping.TITLE:
                    section = globals.active!.sectionTitles!.index(of: sermon!.seriesSection!)!
                    break
                    
                case Grouping.BOOK:
                    section = globals.active!.sectionTitles!.index(of: sermon!.bookSection!)!
                    break
                    
                case Grouping.SPEAKER:
                    section = globals.active!.sectionTitles!.index(of: sermon!.speakerSection!)!
                    break
                    
                default:
                    break
                }

                row = index - globals.active!.sectionIndexes![section]
            }

//            print(section)
            
            if (section > -1) && (row > -1) {
                indexPath = IndexPath(item: row,section: section)
                
                //            NSLog("\(globals.sermonSelected?.title)")
                //            NSLog("Row: \(indexPath.item)")
                //            NSLog("Section: \(indexPath.section)")
                
                if (select) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                }
                
                if (scroll) {
                    //Scrolling when the user isn't expecting it can be jarring.
                    tableView.scrollToRow(at: indexPath, at: position, animated: false)
                }
            }
        }
    }

    
    fileprivate func setupSearchBar()
    {
        switch globals.tags.showing! {
        case Constants.ALL:
            searchBar.placeholder = Constants.All
            break
            
        case Constants.TAGGED:
            searchBar.placeholder = globals.tags.selected
            break
            
        default:
            break
        }
    }
    

    func setupTitle()
    {
        if (!globals.loading && !globals.refreshing) {
            if (splitViewController == nil) {
                if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
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
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (globals.sermons.all == nil) { // SortingOrGrouping
            sermonCategoryButton.isEnabled = false
            listActivityIndicator.startAnimating()
            disableBarButtons()
        } else {
            listActivityIndicator.stopAnimating()
            enableBarButtons()
        }
        
//        print(globals.sermonCategory)
        
        sermonCategoryButton.setTitle(globals.sermonCategory, for: UIControlState.normal)

        setupSearchBar()
        
        setupSplitViewController()
        
        setupTitle()
        
        navigationController?.isToolbarHidden = false
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SHOW_ABOUT2_SEGUE, sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Do we want to do this?  If someone has selected something farther down the list to view, not play, when they come back
        //the list will scroll to whatever is playing or paused.
        
        //This has to be in viewDidAppear().  Putting it in viewWillAppear() does not allow the rows at the bottom of the list
        //to be scrolled to correctly with this call.  Presumably this is because of the toolbar or something else that is still
        //getting setup in viewWillAppear.
        
        if (!globals.scrolledToSermonLastSelected) {
            selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            globals.scrolledToSermonLastSelected = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.isToolbarHidden = true
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        URLCache.shared.removeAllCachedResponses()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var show:Bool
        
        show = true

    //    NSLog("shouldPerformSegueWithIdentifier")
    //    NSLog("Selected: \(globals.sermonSelected?.title)")
    //    NSLog("Last Selected: \(globals.sermonLastSelected?.title)")
    //    NSLog("Playing: \(globals.player.playing?.title)")
        
        switch identifier {
            case Constants.SHOW_ABOUT_SEGUE:
                break

            case Constants.SHOW_SERMON_SEGUE:
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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
            case Constants.SHOW_SETTINGS_SEGUE:
                if let svc = dvc as? SettingsViewController {
                    svc.modalPresentationStyle = .popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.SHOW_LIVE_SEGUE:
                break
                
            case Constants.SHOW_SCRIPTURE_INDEX_SEGUE:
                break
                
            case Constants.SHOW_ABOUT_SEGUE:
                fallthrough
            case Constants.SHOW_ABOUT2_SEGUE:
                globals.showingAbout = true
                break
                
            case Constants.SHOW_SERMON_SEGUE:
                if globals.player.mpPlayer?.contentURL == URL(string:Constants.LIVE_STREAM_URL) {
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            })
        })

        setupSplitViewController()

        setupTitle()
        
        if (splitViewController != nil) {
            if (popover != nil) {
                dismiss(animated: true, completion: nil)
                popover = nil
            }
        }
    }
    
    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(_ TableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return globals.display.sectionTitles != nil ? globals.display.sectionTitles!.count : 0
    }

    func sectionIndexTitlesForTableView(_ tableView: UITableView) -> [AnyObject]! {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.HEADER_HEIGHT
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return globals.display.sectionTitles != nil ? globals.display.sectionTitles![section] : nil
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return globals.display.sectionCounts != nil ? globals.display.sectionCounts![section] : 0
    }

    func tableView(_ TableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> MediaTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SERMONS_CELL_IDENTIFIER, for: indexPath) as! MediaTableViewCell
    
        // Configure the cell
        if let section = globals.display.sectionIndexes?[indexPath.section] {
            cell.sermon = globals.display.sermons?[section + indexPath.row]
        } else {
            NSLog("No sermon for cell!")
        }

        cell.vc = self

        return cell
    }

    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            header.textLabel?.textColor = UIColor.black
            header.alpha = 0.85
        }
    }
    
    func tableView(_ TableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
//        NSLog("didSelect")

        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedSermon = cell.sermon
        } else {
            
        }
    }
    
    func tableView(_ TableView: UITableView, didDeselectRowAtIndexPath indexPath: IndexPath) {
//        NSLog("didDeselect")

//        if let cell: MediaTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        } else {
//            
//        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    */
    func tableView(_ TableView: UITableView, shouldHighlightRowAtIndexPath indexPath: IndexPath) -> Bool {
//        NSLog("shouldHighlight")
        return true
    }
    
    func tableView(_ TableView: UITableView, didHighlightRowAtIndexPath indexPath: IndexPath) {
//        NSLog("Highlighted")
    }
    
    func tableView(_ TableView: UITableView, didUnhighlightRowAtIndexPath indexPath: IndexPath) {
//        NSLog("Unhighlighted")
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
