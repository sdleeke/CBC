//
//  MediaTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    static func controlBlue() -> UIColor
    {
        return UIColor(red: 14, green: 122, blue: 254)
    }
}

enum PopoverPurpose {
    case selectingShow

    case selectingSorting
    case selectingGrouping
    case selectingSection
    
    case selectingHistory
    case selectingLexicon
    
    case selectingCellAction
    case selectingCellSearch
    
    case selectingAction
    
    case selectingWord
    
    case selectingTags

    case showingTags
    case editingTags
}

enum JSONSource {
    case direct
    case download
}

class MediaTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, URLSessionDownloadDelegate, MFMailComposeViewControllerDelegate, PopoverTableViewControllerDelegate, PopoverPickerControllerDelegate { //

//    var refreshList = true
    var changesPending = false
    
    var jsonSource:JSONSource = .direct
    
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }

    var tagsToolbar: UIToolbar?
    @IBOutlet weak var tagsButton: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    
    @IBOutlet weak var lexiconLabel: UILabel!
    @IBOutlet weak var lexiconButton: UIButton!
    @IBAction func lexiconButtonAction(_ sender: UIButton)
    {
        if globals.search.lexicon {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                
                popover.navigationItem.title = Constants.Lexicon
                
                popover.delegate = self
                popover.purpose = .selectingLexicon
                
                popover.search = true
                
                popover.mediaListGroupSort = globals.media.toSearch
                
                popover.showIndex = true
                popover.showSectionHeaders = true
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.navigationController?.pushViewController(popover, animated: true)
                })
            }
        }
    }
    
    var refreshControl:UIRefreshControl?

    var session:URLSession? // Used for JSON
    
    func stringPicked(_ string:String?)
    {
        dismiss(animated: true, completion: nil)
        
//        print(string)
        
        guard (globals.mediaCategory.selected != string) else {
            return
        }
        
        globals.mediaCategory.selected = string
        
        globals.unobservePlayer()
        
        if globals.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) {
            globals.mediaPlayer.pause() // IfPlaying
        }
        
        globals.cancelAllDownloads()
        globals.clearDisplay()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
            
            if self.splitViewController != nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            }
        })
        
        tagLabel.text = nil
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        globals.media = Media()
        
        loadMediaItems()
        {
            if globals.mediaRepository.list == nil {
                let alert = UIAlertController(title: "No media available.",
                                              message: "Please check your network connection and try again.",
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    if globals.isRefreshing {
                        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                            
                        })
                    } else {
                        self.setupListActivityIndicator()
                    }
                })
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            } else {
                self.selectedMediaItem = globals.selectedMediaItem.master
                
                if globals.search.active && !globals.search.complete {
                    self.updateSearchResults(globals.search.text,completion: {
                        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                            })
                        })
                    })
                } else {
                    // Reload the table
                    self.tableView.reloadData()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        })
                    })
                }
            }
            
            self.tableView.isHidden = false
        }
    }

    @IBOutlet weak var mediaCategoryButton: UIButton!
    @IBAction func mediaCategoryButtonAction(_ button: UIButton) {
//        print("categoryButtonAction")
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: UIPopoverArrowDirection.up.rawValue + UIPopoverArrowDirection.down.rawValue)
            
            navigationController.popoverPresentationController?.sourceView = self.view
            navigationController.popoverPresentationController?.sourceRect = mediaCategoryButton.frame
            
            popover.navigationItem.title = Constants.Select_Category
            
            popover.delegate = self
            
    //                popover.strings = ["All Media"]
    //                
    //                if (globals.mediaCategory.names != nil) {
    //                    popover.strings?.append(contentsOf: globals.mediaCategory.names!)
    //                }
            
            popover.strings = globals.mediaCategory.names
            
            popover.string = globals.mediaCategory.selected
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

//    var showProgress = true
//    
//    var progressTimer:Timer?
//    
//    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem) {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
//            popover.navigationItem.title = Constants.Show
            
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
            if (globals.display.mediaItems != nil) && (selectedMediaItem != nil) { // && (globals.display.mediaItems?.indexOf(selectedMediaItem!) != nil)
                showMenu.append(Constants.Current_Selection)
            }
            
            if (globals.mediaPlayer.mediaItem != nil) {
                var show:String = Constants.EMPTY_STRING
                
                if globals.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) {
                    switch globals.mediaPlayer.state! {
                    case .paused:
                        show = Constants.Media_Paused
                        break
                        
                    case .playing:
                        show = Constants.Media_Playing
                        break
                        
                    default:
                        show = Constants.None
                        break
                    }
                } else {
                    show = Constants.Media_Paused
                }
                
                if (self.splitViewController != nil) {
                    if let nvc = self.splitViewController!.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let myvc = nvc.topViewController as? MediaViewController {
                            if (myvc.selectedMediaItem != nil) {
                                if (myvc.selectedMediaItem?.title != globals.mediaPlayer.mediaItem?.title) || (myvc.selectedMediaItem?.date != globals.mediaPlayer.mediaItem?.date) {
                                    // The mediaItemPlaying is not the one showing
                                    showMenu.append(show)
                                } else {
                                    // The mediaItemPlaying is the one showing
                                }
                            } else {
                                // The mediaItemPlaying can't be showing because there is not selectedMediaItem.
                                showMenu.append(show)
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
            
            if globals.media.active?.list?.count > 0 {
                showMenu.append(Constants.View_List)
            }
            
            if (globals.media.active?.scriptureIndex?.eligible != nil) {
                showMenu.append(Constants.Scripture_Index)
            }
            
            if (!globals.search.active || globals.search.lexicon) && (globals.media.active?.lexicon?.eligible != nil) {
                showMenu.append(Constants.Lexicon)
            }
            
            if globals.history != nil {
                showMenu.append(Constants.History)
                showMenu.append(Constants.Clear_History)
            }
            
            showMenu.append(Constants.Live)
            
            showMenu.append(Constants.Settings)
            
//            if UIPrintInteractionController.isPrintingAvailable {
//                showMenu.append(Constants.Print_All)
//            }
//            
//            if MFMailComposeViewController.canSendMail() {
//                showMenu.append(Constants.Email_All)
//            }
//            
//            showMenu.append(Constants.Share_All)
            
            popover.strings = showMenu
            
            popover.showIndex = false //(globals.grouping == .series)
            popover.showSectionHeaders = false
            
            popover.vc = self

            present(navigationController, animated: true, completion: {
                DispatchQueue.main.async(execute: { () -> Void in
                    // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                    navigationController.popoverPresentationController?.passthroughViews = nil
                })
            })
        }
    }
    
    var selectedMediaItem:MediaItem? {
        didSet {
            globals.selectedMediaItem.master = selectedMediaItem
        }
    }
    
//    var popover : PopoverTableViewController?
    
    func disableToolBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = false
                }
            }
        })
    }
    
    func disableBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        })
        
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        })
    }
    
    func enableBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        })
        
        enableToolBarButtons()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        
        guard let strings = strings else {
            return
        }
        
        switch purpose {
        case .selectingCellSearch:
            var searchText = strings[index].uppercased()
            
            if let range = searchText.range(of: " (") {
                searchText = searchText.substring(to: range.lowerBound)
            }
            
            globals.search.text = searchText

            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.setEditing(false, animated: true)
                self.searchBar.text = searchText
                self.searchBar.showsCancelButton = true
//                self.searchBar.becomeFirstResponder()
            })

            updateSearchResults(searchText,completion: nil)
            break
            
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            default:
                break
            }
            break
            
        case .selectingLexicon:
            _ = navigationController?.popViewController(animated: true)
            
            let string = strings[index]
            
            if let range = string.range(of: " (") {
                let searchText = string.substring(to: range.lowerBound).uppercased()
                    
                globals.search.lexicon = true // MUST COME FIRST to avoid saving searchText for the next startup.
                globals.search.text = searchText
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.searchBar.text = searchText
                    self.searchBar.showsCancelButton = true
//                    self.searchBar.becomeFirstResponder()
                })
                
                // Show the results directly rather than by executing a search
                if let list:[MediaItem]? = globals.media.toSearch?.lexicon?.words?[searchText]?.map({ (tuple:(MediaItem, Int)) -> MediaItem in
                    return tuple.0
                }) {
                    updateSearch(searchText:searchText,mediaItems: list)
                    updateDisplay(searchText:searchText)
                }
            }
            break
            
        case .selectingHistory:
            if let history = globals.relevantHistory {
                var mediaItemID:String
                
                if let range = history[index].range(of: Constants.TAGS_SEPARATOR) {
                    mediaItemID = history[index].substring(from: range.upperBound)
                } else {
                    mediaItemID = history[index]
                }
                
                if let mediaItem = globals.mediaRepository.index![mediaItemID] {
                    if mediaItem.text != strings[index] {
                        print(mediaItem.text!,strings[index])
                    }
                    
                    if globals.media.active!.mediaItems!.contains(mediaItem) {
                        selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                    } else {
                        dismiss(animated: true, completion: nil)
                        
                        let alert = UIAlertController(title:"Not in List",
                                                      message: "\"\(mediaItem.title!)\" is not in the list \"\(globals.contextTitle!).\"  Show \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    let alert = UIAlertController(title:"Media Item Not Found!",
                                                  message: "Oops, this should never happen!",
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(alert, animated: true, completion: nil)
                    })
                }
            }
            break
            
        case .selectingTags:
            
            // Should we be showing globals.media.active!.mediaItemTags instead?  That would be the equivalent of drilling down.

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                //                    if (index >= 0) && (index <= globals.media.all!.mediaItemTags!.count) {
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch strings[index] {
                    case Constants.All:
                        if (globals.media.tags.showing != Constants.ALL) {
                            new = true
//                            globals.media.tags.showing = Constants.ALL
                            globals.media.tags.selected = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        
                        let tagSelected = strings[index]
                        
                        new = (globals.media.tags.showing != Constants.TAGGED) || (globals.media.tags.selected != tagSelected)
                        
                        if (new) {
                            //                                print("\(globals.media.active!.mediaItemTags)")
                            
                            globals.media.tags.selected = tagSelected
                            
//                            globals.media.tags.showing = Constants.TAGGED
                        }
                        break
                    }
                    
                    if (new) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            globals.clearDisplay()
                            
                            self.tableView.reloadData()
                            
//                            self.listActivityIndicator.isHidden = false
//                            self.listActivityIndicator.startAnimating()

                            self.startAnimating()

                            self.disableBarButtons()
                        })
                        
                        if (globals.search.active) {
                            self.updateSearchResults(globals.search.text,completion: nil)
                        }
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            globals.setupDisplay(globals.media.active)
                            
                            self.tableView.reloadData()
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
//                            self.listActivityIndicator.stopAnimating()
//                            self.listActivityIndicator.isHidden = true
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                            
                            self.setupTag()
                        })
                    }
                } else {
                    print("Index out of range")
                }
            })
            break
            
        case .selectingSection:
            if let section = globals.media.active?.section?.titles?.index(of: strings[index]) {
                let indexPath = IndexPath(row: 0, section: section)
                
                if !(indexPath.section < tableView.numberOfSections) {
                    NSLog("indexPath section ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    break
                }
                
                if !(indexPath.row < tableView.numberOfRows(inSection: indexPath.section)) {
                    NSLog("indexPath row ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    NSLog("Row: \(indexPath.row)")
                    NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                    break
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.setEditing(false, animated: true)
                })
                
                //Can't use this reliably w/ variable row heights.
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
                })
            }

            //Too slow
            //                if (globals.grouping == Constants.SERIES) {
            //                    let string = strings[index]
            //
            //                    if (string != Constants.Individual_MediaItems) && (globals.mediaItemSectionTitles.series?.indexOf(string) == nil) {
            //                        let index = globals.mediaItemSectionTitles.series?.indexOf(Constants.Individual_MediaItems)
            //
            //                        var mediaItems = [MediaItem]()
            //
            //                        for mediaItem in globals.media.activeMediaItems! {
            //                            if !mediaItem.hasMultiParts {
            //                                mediaItems.append(mediaItem)
            //                            }
            //                        }
            //
            //                        let sortedMediaItems = sortMediaItems(mediaItems, sorting: globals.sorting, grouping: globals.grouping)
            //
            //                        let row = sortedMediaItems?.indexOf({ (mediaItem) -> Bool in
            //                            return string == mediaItem.title
            //                        })
            //
            //                        indexPath = NSIndexPath(forRow: row!, inSection: index!)
            //                    } else {
            //                        let sections = seriesFromMediaItems(globals.media.activeMediaItems,withTitles: false)
            //                        let section = sections?.indexOf(string)
            //                        indexPath = NSIndexPath(forRow: 0, inSection: section!)
            //                    }
            //                }
            break
            
        case .selectingGrouping:
            dismiss(animated: true, completion: nil)
            globals.grouping = globals.groupings[index]
            
            if globals.media.need.grouping {
                globals.clearDisplay()

                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
//                    self.listActivityIndicator.isHidden = false
//                    self.listActivityIndicator.startAnimating()
                    
                    self.startAnimating()

                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                        globals.progress = 0
//                        globals.finished = 0
                        
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            self.progressTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
//                        })
                        
                        globals.setupDisplay(globals.media.active)
                        
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            self.progressTimer?.invalidate()
//                            self.progressTimer = nil
//                            self.progressIndicator.isHidden = true
//                        })
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                            
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
//                            self.listActivityIndicator.stopAnimating()
//                            self.listActivityIndicator.isHidden = true
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                        })
                    })
                })
            }
            break
            
        case .selectingSorting:
            dismiss(animated: true, completion: nil)
            globals.sorting = Constants.sortings[index]
            
            if (globals.media.need.sorting) {
                globals.clearDisplay()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
//                    self.listActivityIndicator.isHidden = false
//                    self.listActivityIndicator.startAnimating()
                    
                    self.startAnimating()

                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                        globals.progress = 0
//                        globals.finished = 0
                        
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            self.progressTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
//                        })
                        
                        globals.setupDisplay(globals.media.active)
                        
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            self.progressTimer?.invalidate()
//                            self.progressTimer = nil
//                            self.progressIndicator.isHidden = true
//                        })
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                            
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
//                            self.listActivityIndicator.stopAnimating()
//                            self.listActivityIndicator.isHidden = true

                            self.stopAnimating()
                            
                            self.enableBarButtons()
                        })
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
                if let mediaItem = selectedMediaItem {
                    if globals.media.active!.mediaItems!.contains(mediaItem) {
                        if self.tableView.isEditing {
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.tableView.setEditing(false, animated: true)
                                DispatchQueue.global(qos: .background).async {
                                    Thread.sleep(forTimeInterval: 0.1)
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                }
                            })
                        } else {
                            selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    } else {
                        dismiss(animated: true, completion: nil)
                        
                        let alert = UIAlertController(title:"Not in List",
                                                      message: "\"\(mediaItem.title!)\" is not in the list \"\(globals.contextTitle!).\"  Show \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    dismiss(animated: true, completion: nil)
                    
                    let alert = UIAlertController(title:"Media Item Not Found!",
                        message: "Oops, this should never happen!",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                break
                
            case Constants.Media_Playing:
                fallthrough
                
            case Constants.Media_Paused:
                globals.gotoPlayingPaused = true
                globals.mediaPlayer.controller?.allowsPictureInPicturePlayback = false
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case Constants.Scripture_Index:
                if (globals.media.active?.scriptureIndex?.eligible == nil) {
                    let alert = UIAlertController(title:"No Scripture Index Available",
                                                  message: "The Scripture references for these media items are not specific.",
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SCRIPTURE_INDEX) as? ScriptureIndexViewController {
                        
                        viewController.mediaListGroupSort = globals.media.active

                        DispatchQueue.main.async(execute: { () -> Void in
                            self.navigationController?.pushViewController(viewController, animated: true)
                        })
                    }
                }

//                performSegue(withIdentifier: Constants.SEGUE.SHOW_SCRIPTURE_INDEX, sender: nil)
                break
                
            case Constants.Lexicon:
                var mlgs:MediaListGroupSort?
                
                if globals.search.lexicon {
                    mlgs = globals.media.toSearch
                } else {
                    mlgs = globals.media.active
                }

                if let completed = mlgs?.lexicon?.completed, !completed && !globals.reachability.isReachable {
                    networkUnavailable("Lexicon unavailable.")
                }
                
                if mlgs?.lexicon?.eligible == nil {
                    let alert = UIAlertController(title:"No Lexicon Available",
                                                  message: "HTML transcripts are not available for these media items.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        //                    navigationController.modalPresentationStyle = .popover
                        
                        //                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                        //                    navigationController.popoverPresentationController?.delegate = self
                        //
                        //                    navigationController.popoverPresentationController?.barButtonItem = self.showButton
                        
                        popover.navigationItem.title = Constants.Lexicon
                        
                        popover.delegate = self
                        popover.purpose = .selectingLexicon
                        
                        popover.search = true
                        
                        popover.mediaListGroupSort = mlgs
                        
                        popover.showIndex = true
                        popover.showSectionHeaders = true
                        
                        //                    popover.vc = self
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.navigationController?.pushViewController(popover, animated: true)
                        })
                        
                        //                    DispatchQueue.main.async(execute: { () -> Void in
                        //                        self.present(navigationController, animated: true, completion: {
                        //                            DispatchQueue.main.async(execute: { () -> Void in
                        //                                // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                        //                                navigationController.popoverPresentationController?.passthroughViews = nil
                        //                            })
                        //                        })
                        //                    })
                    }
                }
                break
                
            case Constants.View_List:
                if let string = globals.media.active?.html?.string {
                    presentHTMLModal(viewController: self, medaiItem: nil, title: globals.contextTitle, htmlString: string)
                } else {
                    process(viewController: self, work: { () -> (Any?) in
                        if globals.media.active?.html?.string == nil {
                            globals.media.active?.html?.string = setupMediaItemsHTMLGlobal(includeURLs: true, includeColumns: true)
                        }
                        return globals.media.active?.html?.string
                    }, completion: { (data:Any?) in
                        presentHTMLModal(viewController: self, medaiItem: nil, title: globals.contextTitle, htmlString: data as? String)
                    })
                }
                break
                
            case Constants.History:
                if globals.relevantHistoryList == nil {
                    let alert = UIAlertController(title: "History is empty.",
                                                  message: nil,
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in

                    })
                    alert.addAction(cancelAction)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(alert, animated: true, completion: nil)
                    })
                } else {
                    if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .popover
                        
                        navigationController.popoverPresentationController?.permittedArrowDirections = .up
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.barButtonItem = showButton
                        
                        popover.navigationItem.title = Constants.History
                        
                        popover.delegate = self
                        popover.purpose = .selectingHistory
                        
                        popover.strings = globals.relevantHistoryList
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false
                        
                        popover.vc = self
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.present(navigationController, animated: true, completion: {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                                    navigationController.popoverPresentationController?.passthroughViews = nil
                                })
                            })
                        })
                    }
                }
                break
                
            case Constants.Clear_History:
                let alert = UIAlertController(title: "Delete History?",
                                              message: nil,
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: { (UIAlertAction) -> Void in
                    globals.history = nil
                    let defaults = UserDefaults.standard
                    defaults.removeObject(forKey: Constants.HISTORY)
                    defaults.synchronize()
                })
                alert.addAction(deleteAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(cancelAction)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.present(alert, animated: true, completion: nil)
                })
                break

            case Constants.Live:
                globals.mediaPlayer.controller?.allowsPictureInPicturePlayback = false
                performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: self)
                break
                
            case Constants.Settings:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SETTINGS_NAVCON) as? UINavigationController,
                    let _ = navigationController.viewControllers[0] as? SettingsViewController {
                    navigationController.modalPresentationStyle = .popover
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.barButtonItem = showButton

                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(navigationController, animated: true, completion: {
                            DispatchQueue.main.async(execute: { () -> Void in
                                // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                                navigationController.popoverPresentationController?.passthroughViews = nil
                            })
                        })
                    })
                }

//                performSegue(withIdentifier: Constants.SEGUE.SHOW_SETTINGS, sender: nil)
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
//        print("willPresentSearchController")
        globals.search.active = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController)
    {
        globals.search.active = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController)
    {
        didDismissSearch()
    }
    
    func didDismissSearch() {
        globals.search.text = nil
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.searchBar.showsCancelButton = false
            self.searchBar.resignFirstResponder()
            self.searchBar.text = nil
        })
        
        disableBarButtons()
        
        globals.clearDisplay()

        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()

//            self.listActivityIndicator.isHidden = false
//            self.listActivityIndicator.startAnimating()

            self.startAnimating()
        })
        
        globals.setupDisplay(globals.media.active)

        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
            
//            self.listActivityIndicator.stopAnimating()
//            self.listActivityIndicator.isHidden = true
            
            self.stopAnimating()
            
            self.setupTag()
            self.setupTagsButton()
            
            self.enableBarButtons()
            
            //Moving the list can be very disruptive
            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: false, position: UITableViewScrollPosition.none)
            
//            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                Thread.sleep(forTimeInterval: 0.1)
//                DispatchQueue.main.async(execute: { () -> Void in
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_CELL_TAG), object: nil)
//                })
//            })
        })
    }
    
    func index(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection

            switch globals.grouping! {
            case Grouping.BOOK:
                if let books = globals.media.active?.section?.titles?.filter({ (string:String) -> Bool in
                    return bookNumberInBible(string) != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                }) {
//                        print(books)
                    popover.strings = books

                    if let other = globals.media.active?.section?.titles?.filter({ (string:String) -> Bool in
                        return bookNumberInBible(string) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
                        popover.strings?.append(contentsOf: other)
                    }
                }
                
//                    print(popover.strings)
                
                popover.indexStrings = popover.strings

                popover.showIndex = false
                popover.showSectionHeaders = false
                break
                
            case Grouping.CLASS:
                fallthrough
            case Grouping.SPEAKER:
                //                    popover.transform = lastNameFromName
                fallthrough
            case Grouping.TITLE:
                popover.strings = globals.media.active?.section?.titles
                popover.indexStrings = globals.media.active?.section?.indexTitles
                popover.showIndex = true
                popover.showSectionHeaders = true
                popover.search = popover.strings?.count > 10
                break
                
            default:
                popover.strings = globals.media.active?.section?.titles
                popover.indexStrings = globals.media.active?.section?.indexTitles
                popover.showIndex = false
                popover.showSectionHeaders = false
                break
            }
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }

        // Too slow
//        if (globals.grouping == Constants.SERIES) {
//            let strings = seriesFromMediaItems(globals.media.activeMediaItems,withTitles: true)
//            popover?.strings = strings
//        } else {
//            popover?.strings = globals.mediaItemSections
//        }
    }

    func grouping(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Options_Title.Grouping
            
            popover.delegate = self
            
            popover.purpose = .selectingGrouping
            popover.strings = globals.groupingTitles
            
            popover.showIndex = false
            popover.showSectionHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func sorting(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Options_Title.Sorting
            
            popover.delegate = self
            
            popover.purpose = .selectingSorting
            popover.strings = Constants.SortingTitles
            
            popover.showIndex = false
            popover.showSectionHeaders = false
            
            popover.vc = self
            
            present(navigationController, animated: true, completion: nil)
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
        
        showButton?.title = Constants.FA.REORDER
        showButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.SHOW_FONT_SIZE)!], for: UIControlState())
        
        showButton?.isEnabled = (globals.media.all != nil) //&& !globals.mediaItemsSortingOrGrouping
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Menu.Sorting, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Menu.Grouping, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.index(_:)))

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
        
        if (globals.mediaRepository.list == nil) {
            disableBarButtons()
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        print("searchBar:textDidChange:")
        //Unstable results from incremental search
//        print("\"\(searchText)\"")
        
        let searchText = searchText.uppercased()
        
        globals.search.text = searchText
        
        if (searchText != Constants.EMPTY_STRING) { //
            updateSearchResults(searchText,completion: nil)
        } else {
//            print("clearDisplay 2")
            globals.clearDisplay()
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
            disableBarButtons()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarSearchButtonClicked:")
        DispatchQueue.main.async(execute: { () -> Void in
            searchBar.resignFirstResponder()
        })
//        print(searchBar.text)

        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid {
            updateSearchResults(searchBar.text,completion: nil)
        } else {
//            print("clearDisplay 3")
            globals.clearDisplay()
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
            enableBarButtons()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return !globals.isLoading && !globals.isRefreshing && (globals.media.all != nil) // !globals.mediaItemsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        
        DispatchQueue.main.async(execute: { () -> Void in
            searchBar.showsCancelButton = true
        })

//        print(searchBar.text)
        
        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid { //
            updateSearchResults(searchText,completion: nil)
        } else {
//            print("clearDisplay 4")
            globals.clearDisplay()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
            
            disableBarButtons()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked:")
        
        didDismissSearch()
    }
    
    func setupViews()
    {
        setupTag()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
        
        setupTitle()
        
//        addRefreshControl()
        
        selectedMediaItem = globals.selectedMediaItem.master
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            })
        })
        
        if (splitViewController != nil) {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            })
        }
    }
    
//    func updateProgress()
//    {
////        print("\(Float(globals.progress))")
////        print("\(Float(globals.finished))")
////        print("\(Float(globals.progress) / Float(globals.finished))")
//        
//        self.progressIndicator.progress = 0
//        if (globals.finished > 0) {
//            self.progressIndicator.isHidden = !showProgress
//            self.progressIndicator.progress = Float(globals.progress) / Float(globals.finished)
//        }
//        
//        //            print("\(self.progressIndicator.progress)")
//        
//        if self.progressIndicator.progress == 1.0 {
//            self.progressTimer?.invalidate()
//            
//            self.progressIndicator.isHidden = true
//            self.progressIndicator.progress = 0
//            
//            globals.progress = 0
//            globals.finished = 0
//        }
//    }

    func jsonAlert(title:String,message:String)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            DispatchQueue.main.async(execute: { () -> Void in
                let alert = UIAlertController(title:title,
                                              message:message,
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            })
        }
    }

    func jsonFromURL(url:String,filename:String) -> JSON
    {
        let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename)
        
        do {
            let data = try Data(contentsOf: URL(string: url)!) // , options: NSData.ReadingOptions.mappedIfSafe
            
            let json = JSON(data: data)
            if json != JSON.null {
                do {
                    try data.write(to: jsonFileSystemURL!)//, options: NSData.WritingOptions.atomic)
//                    jsonAlert(title:"Pursue sanctification!",message:"Media list read, loaded, and written.")
                } catch let error as NSError {
                    jsonAlert(title:"Media List Error",message:"Media list read and loaded but write failed.")
                    NSLog(error.localizedDescription)
                }
                
                print(json)
                return json
            } else {
                print("could not get json from URL, make sure that it exists and contains valid json.")
                
                do {
                    let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
                    
                    let json = JSON(data: data)
                    if json != JSON.null {
//                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load.  Last available copy read and loaded.")
                        print("could get json from the file system.")
//                        print(json)
                        return json
                    } else {
                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load. Last available copy read but load failed.")
                        print("could not get json from the file system either.")
                    }
                } catch let error as NSError {
                    jsonAlert(title:"Media List Error",message:"Media list read but failed to load.  Last available copy read failed.")
                    NSLog(error.localizedDescription)
                }
            }
        } catch let error as NSError {
            print("getting json from URL failed, make sure that it exists and contains valid json.")
            print(error.localizedDescription)
            
            do {
                let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
                
                let json = JSON(data: data)
                if json != JSON.null {
//                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read and loaded.")
                    print("could get json from the file system.")
                    //                        print(json)
                    return json
                } else {
                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read but load failed.")
                    print("could not get json from the file system either.")
                }
            } catch let error as NSError {
                jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read failed.")
                NSLog(error.localizedDescription)
            }
        }
        //        } else {
        //            print("Invalid filename/path.")
        //        }
        
        return nil
    }
    
    func loadJSONDictsFromCachesDirectory(key:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        let json = jsonDataFromCachesDirectory()
        
        if json != JSON.null {
//            print("json:\(json)")
            
            let mediaItems = json[key]
            
            for i in 0..<mediaItems.count {
                
                var dict = [String:String]()
                
                for (key,value) in mediaItems[i] {
                    dict[key] = "\(value)"
                }
                
                mediaItemDicts.append(dict)
            }
            
            //            print(mediaItemDicts)
            
            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        let json = jsonFromURL(url: url,filename: filename)
        
        if json != JSON.null {
            print(json)
            
            let mediaItems = json[key]
            
            for i in 0..<mediaItems.count {
                
                var dict = [String:String]()
                
                for (key,value) in mediaItems[i] {
//                    print(key,value)
                    dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
                
                mediaItemDicts.append(dict)
            }
            
            //            print(mediaItemDicts)
            
            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func mediaItemsFromMediaItemDicts(_ mediaItemDicts:[[String:String]]?) -> [MediaItem]?
    {
        if (mediaItemDicts != nil) {
            return mediaItemDicts?.map({ (mediaItemDict:[String : String]) -> MediaItem in
                MediaItem(dict: mediaItemDict)
            })
        }
        
        return nil
    }

    func loadCategories()
    {
        if let categoriesDicts = self.loadJSONDictsFromURL(url: Constants.JSON.URL.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES,filename: Constants.JSON.FILENAME.CATEGORIES) {
            //                print(categoriesDicts)
            
            var mediaCategoryDicts = [String:String]()
            
            for categoriesDict in categoriesDicts {
                mediaCategoryDicts[categoriesDict["category_name"]!] = categoriesDict["id"]
            }
            
            globals.mediaCategory.dicts = mediaCategoryDicts
            
            //                print(globals.mediaCategories)
        }
    }
    
//    var mediaItems = [String:MediaItem]()
//    var players = [String:AVPlayer]()
//    
//    override func observeValue(forKeyPath keyPath: String?,
//                               of object: Any?,
//                               change: [NSKeyValueChangeKey : Any]?,
//                               context: UnsafeMutableRawPointer?) {
//        // Only handle observations for the playerItemContext
//        //        guard context == &GlobalPlayerContext else {
//        //            super.observeValue(forKeyPath: keyPath,
//        //                               of: object,
//        //                               change: change,
//        //                               context: context)
//        //            return
//        //        }
//        
//        if keyPath == #keyPath(AVPlayerItem.status) {
//            let status: AVPlayerItemStatus
//            
//            // Get the status change from the change dictionary
//            if let statusNumber = change?[.newKey] as? NSNumber {
//                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
//            } else {
//                status = .unknown
//            }
//            
//            // Switch over the status
//            switch status {
//            case .readyToPlay:
//                if let currentItem = object as? AVPlayerItem {
//                    currentItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
//                    
//                    let duration = currentItem.duration.seconds
//                    
//                    let hours = Int(duration / (60*60))
//                    let mins = Int((duration - Double(hours * (60 * 60))) / 60)
//                    let secs = Int(duration.truncatingRemainder(dividingBy: 60))
//                    
//                    if let url = (currentItem.asset as? AVURLAsset)?.url.absoluteString {
//                        if hours > 0 {
//                            print(mediaItems[url]!.title," \(hours):\(mins):\(secs)")
//                            print("MORE THAN AN HOUR")
//                        }
//                        players[url] = nil
//                    }
//                }
//                break
//                
//            case .failed:
//                // Player item failed. See error.
//                break
//                
//            case .unknown:
//                // Player item is not yet ready.
//                break
//            }
//        }
//    }

    func loadMediaItems(completion: (() -> Void)?)
    {
//        globals.progress = 0
//        globals.finished = 0
//        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.progressTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
//        })

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.isLoading = true

            self.setupSearchBar()
            self.setupCategoryButton()
            self.setupTagsButton()
            self.setupBarButtons()
            self.setupListActivityIndicator()

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Loading_Media
            })
            
            var url:String?

            if (globals.mediaCategory.selected != nil) && (globals.mediaCategory.selectedID != nil) {
//                if globals.mediaCategory.selected != "All Media" {
//                    url = Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!
//                } else {
//                    url = Constants.JSON.URL.MEDIA
//                }
            }

            if (globals.mediaCategory.selected != nil) && (globals.mediaCategory.selectedID != nil) {
                url = Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!
            }
            
//            print(Constants.JSON_CATEGORY_URL + globals.mediaCategoryID!)

            if url != nil {
                switch self.jsonSource {
                case .download:
                    // From Caches Directory
                    if let mediaItemDicts = self.loadJSONDictsFromCachesDirectory(key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                        globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    }
                    break
                    
                case .direct:
                    // From URL
                    if let mediaItemDicts = self.loadJSONDictsFromURL(url: url!,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES,filename: Constants.JSON.FILENAME.MEDIA) {
                        globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    }
                    break
                }
            }
            
//            globals.printLexicon()
//
//            var tokens = Set<String>()
//            
//            for mediaItem in globals.mediaRepository.list! {
//                if let stringTokens = tokensFromString(mediaItem.title!) {
//                    tokens = tokens.union(Set(stringTokens))
//                }
//            }
//            print(Array(tokens).sorted() {
//                if $0.endIndex < $1.endIndex {
//                    return $0.endIndex < $1.endIndex
//                } else
//                if $0.endIndex == $1.endIndex {
//                    return $0 < $1
//                }
//                return false
//            } )
            
//            var count = 0
//            
//            for mediaItem in globals.mediaRepository.list! {
//                if mediaItem.hasVideo {
//                    self.players[mediaItem.video!] = AVPlayer(url: mediaItem.videoURL!)
//                    
//                    self.players[mediaItem.video!]?.currentItem?.addObserver(self,
//                                                                          forKeyPath: #keyPath(AVPlayerItem.status),
//                                                                          options: [.old, .new],
//                                                                          context: nil) // &GlobalPlayerContext
//                    self.mediaItems[mediaItem.video!] = mediaItem
//                    
//                    sleep(1)
//                    count += 1
//                    
//                    print("MediaItem Count \(count): \(mediaItem.title!)")
//                }
//            }
            
//            testMediaItemsTagsAndSeries()
//            
//            testMediaItemsBooksAndSeries()
//            
//            testMediaItemsForSeries()
//            
//            //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
//            testMediaItemsPDFs(testExisting: false, testMissing: true, showTesting: false)
//
//            //Test whether the audio starts to download
//            //If we can download at all, we assume we can download it all, which allows us to test all mediaItems to see if they can be downloaded/played.
//            testMediaItemsAudioFiles()

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Loading_Settings
            })
            globals.loadSettings()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Sorting_and_Grouping
            })
            
            globals.media.all = MediaListGroupSort(mediaItems: globals.mediaRepository.list)

//            print(globals.mediaRepository.list?.count)
//            print(globals.media.all?.list?.count)
            
            if globals.search.valid {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.searchBar.text = globals.search.text
                    self.searchBar.showsCancelButton = true
                })

//                let searchMediaItems = globals.media.toSearch?.list?.filter({ (mediaItem:MediaItem) -> Bool in
//                    return mediaItem.search(searchText: globals.search.text)
//                })
//                
//                if globals.media.toSearch?.searches == nil {
//                    globals.media.toSearch?.searches = [String:MediaListGroupSort]()
//                }
//                globals.media.toSearch?.searches?[globals.search.text!] = MediaListGroupSort(mediaItems: searchMediaItems)
                globals.search.complete = false
            }

            globals.setupDisplay(globals.media.active)
            
            if globals.reachability.isReachableViaWiFi {
                globals.media.all?.lexicon?.build()
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (globals.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    globals.setupPlayer(globals.mediaPlayer.mediaItem,playOnLoad:false)
                }

                self.navigationItem.title = Constants.CBC.TITLE.SHORT
                
                self.setupViews()
                
                self.setupListActivityIndicator()
                
                if globals.mediaRepository.list != nil {
                    if globals.isRefreshing {
                        self.refreshControl?.endRefreshing()
                        self.tableView.setContentOffset(CGPoint(x:self.tableView.frame.origin.x, y:self.tableView.frame.origin.y - 44), animated: false)
                        globals.isRefreshing = false
                    }
                }

                globals.isLoading = false
                
                completion?()

                self.setupBarButtons()
                self.setupTagsButton()
                self.setupCategoryButton()
                self.setupListActivityIndicator()
            })
        })
    }
    
    func setupCategoryButton()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.mediaCategoryButton.setTitle(globals.mediaCategory.selected, for: UIControlState.normal)
            
            if globals.isLoading || globals.isRefreshing || !globals.search.complete {
                self.mediaCategoryButton.isEnabled = false
            } else {
                if (globals.mediaRepository.list != nil) && globals.search.complete {
                    self.mediaCategoryButton.isEnabled = true
                }
            }
        })
    }
    
    func setupBarButtons()
    {
        if globals.isLoading || globals.isRefreshing { //  || !globals.search.complete
            disableBarButtons()
        } else {
            if (globals.mediaRepository.list != nil) { //  && globals.search.complete
                enableBarButtons()
            }
        }
    }
    
    func setupListActivityIndicator()
    {
        if globals.isLoading || (globals.search.active && !globals.search.complete) {
            if !globals.isRefreshing {
//                if !self.listActivityIndicator.isAnimating {
                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.listActivityIndicator.isHidden = false
//                        self.listActivityIndicator.startAnimating()
                        
                        self.startAnimating()
                    })
//                }
            } else {
//                if self.listActivityIndicator.isAnimating {
                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.listActivityIndicator.stopAnimating()
//                        self.listActivityIndicator.isHidden = true
                        
                        self.stopAnimating()
                    })
//                }
            }
        } else {
//            if self.listActivityIndicator.isAnimating {
                DispatchQueue.main.async(execute: { () -> Void in
//                    self.listActivityIndicator.stopAnimating()
//                    self.listActivityIndicator.isHidden = true
                
                    self.stopAnimating()
                })
//            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset: Int64, expectedTotalBytes: Int64)
    {
    
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        print("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.progressIndicator.isHidden = false
//            
//            print(totalBytesExpectedToWrite > 0 ? Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0.0)
//            
//            self.progressIndicator.progress = totalBytesExpectedToWrite > 0 ? Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0.0
//        })

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.progressIndicator.isHidden = true
//        })

        var success = false
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesReceived > 0) {
            let fileManager = FileManager.default
            
            //Get documents directory URL
            if let destinationURL = cachesURL()?.appendingPathComponent(filename) {
                // Check if file exist
                if (fileManager.fileExists(atPath: destinationURL.path)){
                    do {
                        try fileManager.removeItem(at: destinationURL)
                    } catch _ {
                        print("failed to remove old json file")
                    }
                }
                
                do {
                    try fileManager.copyItem(at: location as URL, to: destinationURL)
                    try fileManager.removeItem(at: location as URL)
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
            DispatchQueue.main.async(execute: { () -> Void in
                globals.mediaPlayer.pause() // IfPlaying
                
                globals.mediaPlayer.view?.isHidden = true
                globals.mediaPlayer.view?.removeFromSuperview()
                
//                self.loadCategories()
                
                self.loadMediaItems()
                {
//                    self.refreshControl?.endRefreshing()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                    globals.isRefreshing = false
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
                
                globals.setupDisplay(globals.media.active)
                self.tableView.reloadData()
                
                globals.isRefreshing = false

                self.setupViews()
            })
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
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
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        print("URLSession:didBecomeInvalidWithError")

    }
    
    func downloadJSON()
    {
        var url:String?
        
        url = Constants.JSON.URL.MEDIA

        navigationItem.title = Constants.Title.Downloading_Media
        
        let downloadRequest = URLRequest(url: URL(string: url!)!)
        
        let configuration = URLSessionConfiguration.default
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTask(with: downloadRequest)
        downloadTask?.taskDescription = Constants.JSON.FILENAME.MEDIA
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func setupSearchBar()
    {
        if globals.isLoading || globals.isRefreshing {
            DispatchQueue.main.async(execute: { () -> Void in
                self.searchBar.resignFirstResponder()
                self.searchBar.placeholder = nil
                self.searchBar.text = nil
                self.searchBar.showsCancelButton = false
            })
        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        globals.isRefreshing = true
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.setupListActivityIndicator()
            refreshControl.beginRefreshing()
        })
        
        globals.unobservePlayer()
        
        let liveStream = globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM)

        globals.mediaPlayer.pause() // IfPlaying

        globals.cancelAllDownloads()

        globals.clearDisplay()
        
        globals.search.active = false

        setupSearchBar()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.lexiconButton.isEnabled = false
            self.tableView.reloadData()
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        })

        setupBarButtons()
        setupCategoryButton()
        setupTagsButton()
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        globals.media = Media()
        
        loadCategories()
        
        // loadMediaItems or downloadJSON
        
        switch jsonSource {
        case .download:
            downloadJSON()
            break
            
        case .direct:
            loadMediaItems()
            {
                if liveStream {
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
                    })
                }

                if globals.mediaRepository.list == nil {
                    let alert = UIAlertController(title: "No media available.",
                                                  message: "Please check your network connection and try again.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                        if globals.isRefreshing {
                            self.refreshControl?.endRefreshing()
                            globals.isRefreshing = false
                        } else {
                            self.setupListActivityIndicator()
                        }
                    })
                    alert.addAction(action)
                    
                    self.present(alert, animated: true, completion: nil)
                } else {
                    globals.isRefreshing = false
                    
                    self.selectedMediaItem = globals.selectedMediaItem.master
                    
                    if globals.search.active && !globals.search.complete {
                        self.updateSearchResults(globals.search.text,completion: {
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                })
                            })
                        })
                    } else {
                        // Reload the table
                        self.tableView.reloadData()
                        
                        if self.selectedMediaItem != nil {
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                })
                            })
                        } else {
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.tableView.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
                                })
                            })
                        }
                    }
                }
            }
            break
        }
    }

//    func removeRefreshControl()
//    {
//        DispatchQueue.main.async(execute: { () -> Void in
//            self.refreshControl?.removeFromSuperview()
//        })
//    }
    
//    func addRefreshControl()
//    {
//        if (refreshControl?.superview != tableView) {
//            DispatchQueue.main.async(execute: { () -> Void in
////                self.tableView.addSubview(self.refreshControl!)
//            })
//        }
//    }
    
    func updateList()
    {
        globals.setupDisplay(globals.media.active)
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    func editing()
    {
//        refreshList = false
        DispatchQueue.main.async(execute: { () -> Void in
            self.searchBar.resignFirstResponder()
        })
    }
    
    func notEditing()
    {
        if changesPending {
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        }
//        refreshList = true
        changesPending = false
    }
    
    var loadingView:UIView!
    var actInd:UIActivityIndicatorView!

    func stopAnimating()
    {
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
//        print("stopAnimating")

        DispatchQueue.main.async(execute: { () -> Void in
            self.actInd.stopAnimating()
            self.loadingView.isHidden = true
        })
    }
    
    func startAnimating()
    {
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
//        print("startAnimating")
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        })
        
        // Doesn't work to center the loadingView, instead resetting the center in viewWillTransition
        
//        let centerX = NSLayoutConstraint(item: loadingView!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: loadingView!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
//        loadingView?.superview?.addConstraint(centerX)
//        
//        let centerY = NSLayoutConstraint(item: loadingView!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: loadingView!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
//        loadingView?.superview?.addConstraint(centerY)
//        
//        loadingView?.superview?.layoutSubviews()
    }
    
    func lexiconStarted()
    {
        if globals.search.lexicon {
            
        }
    }
    
    func lexiconUpdated()
    {
        if globals.search.lexicon, let searchText = globals.search.text {
            if let list:[MediaItem]? = globals.media.toSearch?.lexicon?.words?[searchText]?.map({ (tuple:(MediaItem, Int)) -> MediaItem in
                return tuple.0
            }) {
                updateSearch(searchText:searchText,mediaItems: list)
                updateDisplay(searchText:searchText)
            }
        }
    }
    
    func lexiconCompleted()
    {
        if globals.search.lexicon, let searchText = globals.search.text {
            if let list:[MediaItem]? = globals.media.toSearch?.lexicon?.words?[searchText]?.map({ (tuple:(MediaItem, Int)) -> MediaItem in
                return tuple.0
            }) {
                updateSearch(searchText:searchText,mediaItems: list)
                updateDisplay(searchText:searchText)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.autocapitalizationType = .none
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.editing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.EDITING), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.notEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_EDITING), object: nil)
        }
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)

        tableView.addSubview(refreshControl!)
        
        setupTagsToolbar()
        
        if globals.mediaRepository.list == nil {
            //            disableBarButtons()
            
            loadCategories()
            
            // Download or Load
            
            switch jsonSource {
            case .download:
                downloadJSON()
                break
                
            case .direct:
                tableView.isHidden = true

                loadMediaItems()
                {
                    if globals.mediaRepository.list == nil {
                        let alert = UIAlertController(title: "No media available.",
                                                      message: "Please check your network connection and try again.",
                                                      preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                            if globals.isRefreshing {
                                self.refreshControl?.endRefreshing()
                                globals.isRefreshing = false
                            } else {
                                self.setupListActivityIndicator()
                            }
                        })
                        alert.addAction(action)
                        
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.selectedMediaItem = globals.selectedMediaItem.master
                        
                        if globals.search.active && !globals.search.complete { // && globals.search.transcripts
                            self.updateSearchResults(globals.search.text,completion: {
                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                    })
                                })
                            })
                        } else {
                            // Reload the table
                            self.tableView.reloadData()

                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                })
                            })
                        }
                    }

                    self.tableView.isHidden = false
                }
                break
            }
        }
        
        setupSortingAndGroupingOptions()
        setupShowMenu()

        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        // App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden when mode is changed to primaryHidden!
        splitViewController?.preferredDisplayMode = .automatic //iPad only
        
        tableView?.allowsSelection = true

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        navigationController?.isToolbarHidden = false
    }
    
//    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar)
//    {
//    
//    }
    
    func setupTagsToolbar()
    {
//        DispatchQueue.main.async(execute: { () -> Void in
            self.tagsToolbar = UIToolbar(frame: self.tagsButton.frame)
            self.tagsToolbar?.setItems([UIBarButtonItem(title: nil, style: .plain, target: self, action: nil)], animated: false)
            self.tagsToolbar?.isHidden = true
            
            self.tagsToolbar?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            self.view.addSubview(self.tagsToolbar!)
            
            let first = self.tagsToolbar
            let second = self.tagsButton
            
            let centerX = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            self.view.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            self.view.addConstraint(centerY)
            
            //        let width = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            //        self.addConstraint(width)
            //
            //        let height = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            //        self.addConstraint(height)
            
            self.view.setNeedsLayout()
//        })
    }
    
    func setupTagsButton()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            if let count = globals.media.all?.mediaItemTags?.count {
                switch count {
                case 0:
                    self.tagsButton.isEnabled = false
                    self.tagsButton.isHidden = true
                    break
                    
//                case 1: // Never happens because if there is one we add the All tag.
//                    self.tagsButton.setTitle(Constants.FA.TAG, for: UIControlState())
//                    self.tagsButton.isEnabled = true
//                    self.tagsButton.isHidden = false
//                    break
                    
                default:
                    self.tagsButton.setTitle(Constants.FA.TAGS, for: UIControlState())
                    self.tagsButton.isEnabled = true
                    self.tagsButton.isHidden = false
                    break
                }
                
            } else {
                self.tagsButton.isEnabled = false
                self.tagsButton.isHidden = true
            }
            
            if (globals.mediaRepository.list ==  nil) || globals.isLoading || globals.isRefreshing || !globals.search.complete {
                self.tagsButton.isEnabled = false
                self.tagsButton.isHidden = false
            }
            
            if globals.search.lexicon {
                self.tagsButton.isEnabled = false
                self.tagsButton.isHidden = false
            }
        })
    }
    
    @IBAction func selectingTagsAction(_ sender: UIButton)
    {
        guard !globals.isLoading else {
            return
        }
        
        guard !globals.isRefreshing else {
            return
        }
        
        guard (globals.media.all?.mediaItemTags != nil) else {
            return
        }
        
        guard (storyboard != nil) else {
            return
        }
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
//            navigationController.popoverPresentationController?.sourceView = searchBar
//            navigationController.popoverPresentationController?.sourceRect = searchBar.bounds

            navigationController.popoverPresentationController?.barButtonItem = tagsToolbar?.items?.first

            popover.navigationItem.title = Constants.Show
            
            popover.delegate = self
            popover.purpose = .selectingTags
            
            //                    print(globals.media.all!.mediaItemTags!)
            
            var strings = [Constants.All]
            
            strings.append(contentsOf: globals.media.all!.mediaItemTags!)
            
            popover.strings = strings.sorted(by: { stringWithoutPrefixes($0)! < stringWithoutPrefixes($1)! })
            
            popover.indexStrings = popover.strings?.map({ (string:String) -> String in
                return stringWithoutPrefixes(string)!.lowercased()
            })
            
            //                    print(globals.media.all!.mediaItemTags)
            
            popover.showIndex = true
            popover.showSectionHeaders = true
            
            popover.search = popover.strings?.count > 10
            
            popover.vc = self
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.present(navigationController, animated: true, completion: nil)
            })
        }
    }
    
    func updateSearchResults(for searchController: UISearchController)
    {
        updateSearchResults(globals.search.text,completion: nil)
    }
    
    func updateDisplay(searchText:String?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        if !globals.search.active || (globals.search.text?.uppercased() == searchText) {
//            print(globals.search.text,searchText)
//            print("setupDisplay")
            globals.setupDisplay(globals.media.active)
        } else {
//            print("clearDisplay 1")
//            globals.clearDisplay()
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            if !self.tableView.isEditing {
                self.tableView.reloadData()
            } else {
                self.changesPending = true
            }
        })
    }

    func updateSearch(searchText:String?,mediaItems: [MediaItem]?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
//        self.showProgress = false
        
        if globals.media.toSearch?.searches == nil {
            globals.media.toSearch?.searches = [String:MediaListGroupSort]()
        }
        
        
        globals.media.toSearch?.searches?[globals.search.lexicon ? "lexicon:"+searchText : searchText] = MediaListGroupSort(mediaItems: mediaItems)
        
//        self.showProgress = true
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
//        print(searchText)

        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard (searchText != Constants.EMPTY_STRING) else {
            return
        }
        
//        print(searchText)
        
        guard (globals.media.toSearch?.searches?[globals.search.lexicon ? "lexicon:"+searchText : searchText] == nil) else {
            updateDisplay(searchText:searchText)
            setupListActivityIndicator()
            setupBarButtons()
            setupCategoryButton()
            setupTagsButton()
            return
        }
        
        if globals.search.lexicon {
            if let list:[MediaItem]? = globals.media.toSearch?.lexicon?.words?[searchText]?.map({ (tuple:(MediaItem, Int)) -> MediaItem in
                return tuple.0
            }) {
                updateSearch(searchText:searchText,mediaItems: list)
                updateDisplay(searchText:searchText)
            } else {
                updateSearch(searchText:searchText,mediaItems: nil)
                updateDisplay(searchText:searchText)
            }

            setupListActivityIndicator()
            setupBarButtons()
            setupCategoryButton()
            setupTagsButton()
            return
        }
        
        var abort = false
        
        func shouldAbort() -> Bool
        {
            return !globals.search.valid || (globals.search.text != searchText)
        }
        
        globals.search.complete = false

//            print(searchText!)

        globals.clearDisplay()

        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })

        self.setupTagsButton()
        self.setupBarButtons()
        self.setupCategoryButton()

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            //                print("1: ",searchText,Constants.EMPTY_STRING)
            
            var searchMediaItems:[MediaItem]?
            
            if globals.media.toSearch?.list != nil {
                for mediaItem in globals.media.toSearch!.list! {
                    globals.search.complete = false
                    
                    self.setupListActivityIndicator()
                    
                    let searchHit = mediaItem.search()
                    
                    abort = abort || shouldAbort()
                    
                    if abort {
                        globals.media.toSearch?.searches?[searchText] = nil
                        break
                    } else {
                        if searchHit {
                            if searchMediaItems == nil {
                                searchMediaItems = [mediaItem]
                            } else {
                                searchMediaItems?.append(mediaItem)
                            }
                            
                            if ((searchMediaItems!.count % Constants.SEARCH_RESULTS_BETWEEN_UPDATES) == 0) {
                                self.updateSearch(searchText:searchText,mediaItems: searchMediaItems)
                                self.updateDisplay(searchText:searchText)
                            }
                        }
                    }
                }
                
                if !abort {
                    self.updateSearch(searchText:searchText,mediaItems: searchMediaItems)
                    self.updateDisplay(searchText:searchText)
                } else {
                    globals.media.toSearch?.searches?[searchText] = nil
                }
                
                if !abort && globals.search.transcripts {
                    for mediaItem in globals.media.toSearch!.list! {
                        globals.search.complete = false
                        
                        self.setupListActivityIndicator()
                        
                        var searchHit = false
                        
                        if (searchMediaItems == nil) || !searchMediaItems!.contains(mediaItem) {
                            searchHit = mediaItem.searchFullNotesHTML()
                        }

                        abort = abort || shouldAbort()
                        
                        if abort {
                            globals.media.toSearch?.searches?[searchText] = nil
                            break
                        } else {
                            if searchHit {
                                if searchMediaItems == nil {
                                    searchMediaItems = [mediaItem]
                                } else {
                                    searchMediaItems?.append(mediaItem)
                                }
                                
                                self.updateSearch(searchText:searchText,mediaItems: searchMediaItems)
                                self.updateDisplay(searchText:searchText)
                            }
                        }
                    }
                }
            }
            
            // Final search update since we're only doing them in batches of Constants.SEARCH_RESULTS_BETWEEN_UPDATES
            
            abort = abort || shouldAbort()
            
            if abort {
                globals.media.toSearch?.searches?[searchText] = nil
            } else {
                self.updateSearch(searchText:searchText,mediaItems: searchMediaItems)
                self.updateDisplay(searchText:searchText)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion?()
                
                globals.search.complete = true
                
                self.setupListActivityIndicator()
                self.setupBarButtons()
                self.setupCategoryButton()
                self.setupTagsButton()
            })
        })
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        guard !tableView.isEditing else {
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        guard globals.media.active?.mediaItems?.index(of: mediaItem!) != nil else {
            return
        }
        
        var indexPath = IndexPath(item: 0, section: 0)
        
        var section:Int = -1
        var row:Int = -1
        
        let mediaItems = globals.media.active?.mediaItems
        
        if let index = mediaItems!.index(of: mediaItem!) {
            switch globals.grouping! {
            case Grouping.YEAR:
                section = globals.media.active!.section!.titles!.index(of: mediaItem!.yearSection!)!
                break
                
            case Grouping.TITLE:
                section = globals.media.active!.section!.indexTitles!.index(of: mediaItem!.multiPartSectionSort!)!
                break
                
            case Grouping.BOOK:
                // For mediaItem.books.count > 1 this arbitrarily selects the first one, which may not be correct.
                section = globals.media.active!.section!.titles!.index(of: mediaItem!.bookSections.first!)!
                break
                
            case Grouping.SPEAKER:
                section = globals.media.active!.section!.titles!.index(of: mediaItem!.speakerSection!)!
                break
                
            case Grouping.CLASS:
                section = globals.media.active!.section!.titles!.index(of: mediaItem!.classSection!)!
                break
                
            default:
                break
            }
            
            row = index - globals.media.active!.sectionIndexes![section]
        }
        
        //            print(section)
        
        if (section > -1) && (row > -1) {
            indexPath = IndexPath(row: row,section: section)
            
//            print(tableView.numberOfSections,tableView.numberOfRows(inSection: section),indexPath)

            //            print("\(globals.mediaItemSelected?.title)")
            //            print("Row: \(indexPath.item)")
            //            print("Section: \(indexPath.section)")
            
            guard (indexPath.section < tableView.numberOfSections) else {
                NSLog("indexPath section ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                return
            }
            
            guard indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
                NSLog("indexPath row ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                NSLog("Row: \(indexPath.row)")
                NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                return
            }

            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.setEditing(false, animated: true)
            })

            if (select) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                })
            }
            
            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                })
            }
        }
    }

    
    fileprivate func setupTag()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            switch globals.media.tags.showing! {
            case Constants.ALL:
                self.tagLabel.text = Constants.All // searchBar.placeholder
                break
                
            case Constants.TAGGED:
                self.tagLabel.text = globals.media.tags.selected // searchBar.placeholder
                break
                
            default:
                break
            }
            
            self.lexiconButton.isEnabled = globals.search.lexicon

//            if globals.search.lexicon {
//                self.lexiconLabel.text = "Lexicon Mode"
//            } else {
//                self.lexiconLabel.text = nil
//            }
        })
    }
    

    func setupTitle()
    {
        if (!globals.isLoading && !globals.isRefreshing) {
            if (splitViewController == nil) {
                if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
                    navigationItem.title = Constants.CBC.TITLE.LONG
                } else {
                    navigationItem.title = Constants.CBC.TITLE.SHORT
                }
            } else {
                navigationItem.title = Constants.CBC.TITLE.SHORT
            }
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = .automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue(label: "CBC").async(execute: { () -> Void in
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.lexiconStarted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.lexiconUpdated), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.lexiconCompleted), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: nil)
        })
        
        updateUI()
        
        // Reload the table
//        tableView.reloadData() // Removes selection!
        
        // Causes a crash in split screen on first swipe to get MVC to show when only DVC is showing.
        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
        if (splitViewController?.preferredDisplayMode == .automatic) {
            splitViewController?.preferredDisplayMode = .allVisible //iPad only
        }

//        print(globals.mediaCategory)
        
//        updateList() // If removeObserer is used in viewWillDisappear then this has to be used as notifications of list changes, i.e. adding and removing from Favorites and Downloads, will not be picked up if MTVC isn't showing, ie. looking at a mediaItem on an iPhone or ScriptureIndex on either iPhone or iPad.
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
    }
    
    func updateUI()
    {
        setupCategoryButton()
        
        setupTag()
        setupTagsButton()
        
        //        setupSplitViewController()
        
        setupShowHide()
        
        setupTitle()
        
        setupBarButtons()

        setupListActivityIndicator()
        
        navigationController?.isToolbarHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if loadingView == nil {
            loadingView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            
            //        loadingView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            loadingView.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
            
            loadingView.backgroundColor = UIColor.gray.withAlphaComponent(0.75)
            
            loadingView.clipsToBounds = true
            loadingView.layer.cornerRadius = 10
            
            actInd = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            
            actInd.frame = CGRect(x: 0, y: 0, width: 40, height: 40);
            actInd.center = CGPoint(x: loadingView.bounds.width / 2, y: loadingView.bounds.height / 2)
            
            loadingView.addSubview(actInd)
            
            view.addSubview(loadingView)
        }

        //Do we want to do this?  If someone has selected something farther down the list to view, not play, when they come back
        //the list will scroll to whatever is playing or paused.
        
        //This has to be in viewDidAppear().  Putting it in viewWillAppear() does not allow the rows at the bottom of the list
        //to be scrolled to correctly with this call.  Presumably this is because of the toolbar or something else that is still
        //getting setup in viewWillAppear.

        updateUI()
        
        if (!globals.scrolledToMediaItemLastSelected) {
            selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            globals.scrolledToMediaItemLastSelected = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        if (splitViewController == nil) {
//            navigationController?.isToolbarHidden = true
//        }
        
//        NotificationCenter.default.removeObserver(self) // If you do this it won't get notified of list changes, i.e. adding and removing from Favorites and Downloads.
    
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_STARTED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_UPDATED), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LEXICON_COMPLETED), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var show:Bool
        
        show = true

    //    print("shouldPerformSegueWithIdentifier")
    //    print("Selected: \(globals.mediaItemSelected?.title)")
    //    print("Last Selected: \(globals.mediaItemLastSelected?.title)")
    //    print("Playing: \(globals.player.playing?.title)")
        
        switch identifier {
            case Constants.SEGUE.SHOW_ABOUT:
                break

            case Constants.SEGUE.SHOW_MEDIAITEM:
                // We might check and see if the cell mediaItem is in a series and if not don't segue if we've
                // already done so, but I think we'll just let it go.
                // Mainly because if it is in series and we've selected another mediaItem in the series
                // we may want to reselect from the master list to go to that mediaItem in the series since it is no longer
                // selected in the detail list.

//                if let myCell = sender as? MediaTableViewCell {
//                    show = (splitViewController == nil) || ((splitViewController != nil) && (splitViewController!.viewControllers.count == 1)) || (myCell.mediaItem != selectedMediaItem)
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
            case Constants.SEGUE.SHOW_SETTINGS:
                if let svc = dvc as? SettingsViewController {
                    svc.modalPresentationStyle = .popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.SEGUE.SHOW_LIVE:
                break
                
            case Constants.SEGUE.SHOW_SCRIPTURE_INDEX:
                break
                
            case Constants.SEGUE.SHOW_ABOUT:
                fallthrough
            case Constants.SEGUE.SHOW_ABOUT2:
                globals.showingAbout = true
                break
                
            case Constants.SEGUE.SHOW_MEDIAITEM:
                if globals.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM) {
                    globals.mediaPlayer.stop()
                    globals.mediaPlayer.playOnLoad = false
                }
                
                globals.showingAbout = false
                if (globals.gotoPlayingPaused) {
                    globals.gotoPlayingPaused = !globals.gotoPlayingPaused

                    if let destination = dvc as? MediaViewController {
                        destination.selectedMediaItem = globals.mediaPlayer.mediaItem
                    }
                } else {
                    if let myCell = sender as? MediaTableViewCell {
                        if (selectedMediaItem != myCell.mediaItem) || (globals.history == nil) {
                            globals.addToHistory(myCell.mediaItem)
                        }
                        selectedMediaItem = myCell.mediaItem //globals.media.activeMediaItems![index]

                        if selectedMediaItem != nil {
                            if let destination = dvc as? MediaViewController {
                                destination.selectedMediaItem = selectedMediaItem
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

    func showHide()
    {
        //It works!  Problem was in globals.mediaPlayer.controller?.player?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
        //Thank you StackOverflow!
        
        //        globals.mediaPlayer.controller?.player?.setFullscreen(!globals.mediaPlayer.controller?.player!.isFullscreen, animated: true)
        
        if splitViewController != nil {
//            print(splitViewController!.displayMode.rawValue)
            
            switch splitViewController!.displayMode {
            case .automatic:
                splitViewController?.preferredDisplayMode = .automatic
                break
                
            case .primaryHidden:
                splitViewController?.preferredDisplayMode = .allVisible
                break
                
            case .allVisible:
                splitViewController?.preferredDisplayMode = .primaryHidden
                break
                
            case .primaryOverlay:
                splitViewController?.preferredDisplayMode = .allVisible
                break
            }

            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            })

            setupShowHide()
        }
    }
 
    func setupShowHide()
    {
//        let isFullScreen = UIApplication.shared.delegate!.window!!.frame.equalTo(UIApplication.shared.delegate!.window!!.screen.bounds);
//            print(isFullScreen)
        guard Thread.isMainThread else {
            return
        }
        
        if (splitViewController?.viewControllers.count > 1) { //  && isFullScreen
            switch splitViewController!.displayMode {
            case .automatic:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
                break
                
            case .primaryHidden:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
                break
                
            case .allVisible:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
                break
                
            case .primaryOverlay:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
                break
            }
        } else {
            navigationItem.setRightBarButton(nil,animated: true)
        }

        navigationItem.rightBarButtonItem?.isEnabled = !globals.isRefreshing && !globals.isLoading
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

//        if let sivc = self.navigationController?.visibleViewController as? ScriptureIndexViewController {
//            print("SIVC")
//        }
//        if let ptvc = self.navigationController?.visibleViewController as? PopoverTableViewController {
//            print("PTVC")
//        }

        if !UIApplication.shared.isRunningInFullScreen() {
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        
//        if let count = self.splitViewController?.viewControllers.count {
//            print(count)
//
//            switch count {
//            case 1:
//                break
//            
//            case 2:
//                break
//                
//            default:
//                break
//            }
//        }

        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if self.loadingView != nil {
                self.loadingView.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
            }
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setupShowHide()
            if !UIApplication.shared.isRunningInFullScreen() {
                self.dismiss(animated: true, completion: nil)
            }
            self.setupTitle()
//            DispatchQueue.main.async(execute: { () -> Void in
//            })
        }

////        if (self.view.window == nil) {
////            return
////        }
//        
//        if (splitViewController != nil) {
////            dismiss(animated: false, completion: nil)
////            if (popover != nil) {
////                dismiss(animated: false, completion: nil)
////                popover = nil
////            }
//        }
//
//        if (self.splitViewController != nil) {
////            print("Before")
////            print(splitViewController!.viewControllers.count)
////            print(navigationController!.viewControllers.count)
////            print(navigationController!.visibleViewController)
//            
//            let beforeSVCC = splitViewController!.viewControllers.count
//            let beforeNVCC = navigationController!.viewControllers.count
//            
//            let sivc = self.navigationController?.visibleViewController as? ScriptureIndexViewController
//            let ptvc = self.navigationController?.visibleViewController as? PopoverTableViewController
//            
//            if (beforeSVCC == 1) && (beforeNVCC > beforeSVCC) && ((sivc != nil) || (ptvc != nil)) {
//                // Keeps any MTVC vc from showing up in the MVC rather than the MTVC hierarchy.
//                _ = self.navigationController?.popToRootViewController(animated: false)
//            }
//
//            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
//
//            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
////                print("After")
////                print(self.splitViewController?.viewControllers.count)
////                print(self.navigationController?.viewControllers.count)
////                print(self.navigationController?.visibleViewController)
//                
//                let afterSVCC = self.splitViewController!.viewControllers.count
//                let afterNVCC = self.navigationController!.viewControllers.count
//
//                if (afterNVCC == 1) && (sivc != nil) { //
//                    if (afterSVCC == 1) || (afterNVCC < afterSVCC) { //
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            if let vc = sivc {
//                                self.navigationController?.pushViewController(vc, animated: false)
//                            }
//                            if let vc = ptvc {
//                                self.navigationController?.pushViewController(vc, animated: false)
//                            }
//                        })
//                    }
//                }
//
//                //Without this background/main dispatching there isn't time to scroll after a reload.
////                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                    DispatchQueue.main.async(execute: { () -> Void in
////                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
////                    })
////                })
//
//                //        setupSplitViewController()
//                
//                DispatchQueue.main.async(execute: { () -> Void in
//                    self.setupShowHide()
//                    self.setupTitle()
//                })
//            }
//        } else {
//            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
//                
//            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//                DispatchQueue.main.async(execute: { () -> Void in
//                    self.setupTitle()
//                })
//            }
//        }
    }
    
    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(_ TableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return globals.display.section.titles != nil ? globals.display.section.titles!.count : 0
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
        if globals.display.section.titles != nil {
            if section < globals.display.section.titles!.count {
                return globals.display.section.titles![section]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if globals.display.section.counts != nil {
            if section < globals.display.section.counts!.count {
                return globals.display.section.counts![section]
            } else {
                return 0
            }
        } else {
            return 0
        }
    }

//    override func observeValue(forKeyPath keyPath: String?,
//                               of object: Any?,
//                               change: [NSKeyValueChangeKey : Any]?,
//                               context: UnsafeMutableRawPointer?) {
//        // Only handle observations for the playerItemContext
//        //        guard context == &GlobalPlayerContext else {
//        //            super.observeValue(forKeyPath: keyPath,
//        //                               of: object,
//        //                               change: change,
//        //                               context: context)
//        //            return
//        //        }
//        
//        if keyPath == #keyPath(UITableViewCell.center) {
//            // Get the status change from the change dictionary
//            if let style = change?[.newKey] as? Int {
//                print(change?[.newKey],style)
//            }
//            
//        }
//    }

    func tableView(_ TableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> MediaTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.vc = self
        
        cell.isHiddenUI(true)
        
//        cell.addObserver(self,
//                          forKeyPath: #keyPath(UITableViewCell.),
//                          options: [.old, .new],
//                          context: nil) // &GlobalPlayerContext

        // Configure the cell
        if (globals.display.section.indexes != nil) && (globals.display.mediaItems != nil) {
            if indexPath.section < globals.display.section.indexes!.count {
                if let section = globals.display.section.indexes?[indexPath.section] {
                    if section + indexPath.row < globals.display.mediaItems!.count {
                        cell.mediaItem = globals.display.mediaItems?[section + indexPath.row]
                    }
                } else {
                    print("No mediaItem for cell!")
                }
            }
        }

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
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
//        print("didSelect")

        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
//            print(selectedMediaItem)
        } else {
            
        }
    }
    
    func tableView(_ TableView: UITableView, didDeselectRowAtIndexPath indexPath: IndexPath) {
//        print("didDeselect")

//        if let cell: MediaTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        } else {
//            
//        }
    }
    
//    func setupRowActionFont()
//    {
//        if #available(iOS 9.0, *) {
//            print(NSClassFromString("UITableViewCellDeleteConfirmationView"))
//            
//            let appearanceButton = UIButton.appearance(whenContainedInInstancesOf: [NSClassFromString("UITableViewCellDeleteConfirmationView") as! UIAppearanceContainer.Type])
//
//            let attributes = [NSFontAttributeName:UIFont(name: Constants.FA.name, size: Constants.FA.ICONS_FONT_SIZE)!]
//            
//            let attributedString = NSAttributedString(string: "", attributes: attributes)
//            
//            appearanceButton.setAttributedTitle(attributedString, for: UIControlState.normal)
//            
//            appearanceButton.set
//            
////            appearanceButton.setTitleTextAttributes(attributes, for: UIControlState())
//        } else {
//            // Fallback on earlier versions
//        }
//    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
//        setupRowActionFont()
        
//        refreshList = false
        
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        
        guard let mediaItem = cell.mediaItem else {
            return nil
        }
        
        var search:UITableViewRowAction!
        var transcript:UITableViewRowAction!
        var words:UITableViewRowAction!
        var scripture:UITableViewRowAction!
        
        var actions = [UITableViewRowAction]()
        
        search = UITableViewRowAction(style: .normal, title: Constants.FA.SEARCH) { action, index in
            if let searchStrings = mediaItem.searchStrings(),
                let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: nil)
                
                navigationController.modalPresentationStyle = .popover
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.sourceView = cell.subviews[0]
                navigationController.popoverPresentationController?.sourceRect = cell.subviews[0].subviews[actions.index(of: search)!].frame
                
                popover.navigationItem.title = Constants.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.showIndex = true
                popover.showSectionHeaders = true
                
                popover.strings = searchStrings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                popover.vc = self
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.present(navigationController, animated: true, completion:nil)
                })
            }
        }
        search.backgroundColor = UIColor.controlBlue()
        
        func transcriptTokens()
        {
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: nil)
                
                navigationController.modalPresentationStyle = .popover
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.sourceView = cell.subviews[0]
                navigationController.popoverPresentationController?.sourceRect = cell.subviews[0].subviews[actions.index(of: words)!].frame
                
                popover.navigationItem.title = Constants.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.strings = mediaItem.notesTokens?.map({ (string:String,count:Int) -> String in
                    return "\(string) (\(count))"
                })
                
                popover.search = popover.strings?.count > 10
                
                if (popover.strings != nil) {
                    let array = Array(Set(popover.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
                    
                    popover.indexStrings = array.map({ (string:String) -> String in
                        return string.uppercased()
                    })
                    
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    
                    popover.vc = self
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.present(navigationController, animated: true, completion: nil)
                    })
                } else {
                    networkUnavailable("HTML transcript vocabulary unavailable.")
                }
            }
        }
        
        words = UITableViewRowAction(style: .normal, title: Constants.FA.WORDS) { action, index in
            // let searchTokens = mediaItem.searchTokens(),
            
            if mediaItem.hasNotesHTML {
                if mediaItem.notesTokens == nil {
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.loadNotesTokens()
                    }, completion: { (data:Any?) in
                        transcriptTokens()
                    })
                } else {
                    transcriptTokens()
                }
            }
        }
        words.backgroundColor = UIColor.blue
        
        transcript = UITableViewRowAction(style: .normal, title: Constants.FA.TRANSCRIPT) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: transcript)!]
            
            if mediaItem.notesHTML != nil {
                var htmlString:String?
                
                if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                    htmlString = mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
                } else {
                    htmlString = mediaItem.fullNotesHTML
                }

                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    if globals.search.valid && (globals.search.transcripts || globals.search.lexicon) {
                        return mediaItem.markedFullNotesHTML(searchText:globals.search.text,index: true)
                    } else {
                        return mediaItem.fullNotesHTML
                    }
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable("HTML transcript unavailable.")
                    }
                    
                    //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                })
            }
        }
        transcript.backgroundColor = UIColor.purple
        
        scripture = UITableViewRowAction(style: .normal, title: Constants.FA.SCRIPTURE) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: scripture)!]

            if let reference = mediaItem.scriptureReference {
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.load(mediaItem.scripture?.reference)
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable("Scripture text unavailable.")
                        }
                        //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                    })
                }
            }
        }
        
        scripture.backgroundColor = UIColor.orange

        if mediaItem.books != nil {
            actions.append(scripture)
        }

        actions.append(search)

        if mediaItem.hasNotesHTML {
            actions.append(words)
            actions.append(transcript)
        }

        return actions
    }
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool
    {
        return true // globals.search.complete
    }
    
    /*
     // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath)
    {
        switch editingStyle {
        case .delete:
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            break

        case .insert:
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            break

        case .none:
            break
        }
    }
     */
    
    /*
     // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, toIndexPath: NSIndexPath) {

    }
     */
 
    /*
     // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
     */

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func tableView(_ tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: IndexPath) -> Bool {
        print("shouldHighlight")
        return true
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAtIndexPath indexPath: IndexPath) {
        print("didHighlight")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: IndexPath) {
        print("Unhighlighted")
    }
     */
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: NSIndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) {
        print("performAction")
    }
     */
}