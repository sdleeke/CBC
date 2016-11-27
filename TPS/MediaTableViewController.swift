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
    
    case selectingCellAction
    case selectingCellSearch
    
    case selectingAction
    
    case selectingTags

    case showingTags
    case editingTags
}

enum JSONSource {
    case direct
    case download
}

//struct Search {
//    var tableView:UITableView?
//    var searchResults:MediaListGroupSort?
//}

class MediaTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, URLSessionDownloadDelegate, MFMailComposeViewControllerDelegate, PopoverTableViewControllerDelegate, PopoverPickerControllerDelegate { //

    var showProgress = true
    
    var refreshList = true
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

    var refreshControl:UIRefreshControl?

    var session:URLSession? // Used for JSON
    
    func stringPicked(_ string:String?)
    {
        dismiss(animated: true, completion: nil)
        
//        print(string)
        
        if (globals.mediaCategory.selected != string) {
            globals.mediaCategory.selected = string
            globals.tags.selected = nil
            globals.searchActive = false
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.searchBar.resignFirstResponder()
                self.searchBar.placeholder = nil
                self.mediaCategoryButton.setTitle(globals.mediaCategory.selected, for: UIControlState.normal)
                self.listActivityIndicator.isHidden = false
                self.listActivityIndicator.startAnimating()
            })
            
            // This does not show the activityIndicator
            handleRefresh(refreshControl!)
        }
    }

    @IBOutlet weak var mediaCategoryButton: UIButton!
    @IBAction func mediaCategoryButtonAction(_ button: UIButton) {
        print("categoryButtonAction")
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.STRING_PICKER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverPickerViewController {
                
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
    }
    
    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    var progressTimer:Timer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem) {
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
//                popover.navigationItem.title = Constants.Show
                
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
                
                showMenu.append(Constants.Scripture_Index)

                showMenu.append(Constants.History)
                
                showMenu.append(Constants.Clear_History)
                
                showMenu.append(Constants.Live)
                
                showMenu.append(Constants.Settings)
                
                showMenu.append(Constants.Email_All)
                
                popover.strings = showMenu
                
                popover.showIndex = false //(globals.grouping == .series)
                popover.showSectionHeaders = false
                
                present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    var selectedMediaItem:MediaItem? {
        didSet {
//            let defaults = UserDefaults.standard
//            if (selectedMediaItem != nil) {
//                defaults.set(selectedMediaItem!.id,forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER)
//            } else {
//                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
////                defaults.removeObjectForKey(Constants.SELECTED_SERMON_KEY)
//            }
//            defaults.synchronize()
            
            globals.mediaCategory.selectedInMaster = selectedMediaItem?.id
        }
    }
    
//    var popover : PopoverTableViewController?
    
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
        mediaCategoryButton.isEnabled = false

        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.isEnabled = true
            }
        }
    }
    
    func enableBarButtons()
    {
        mediaCategoryButton.isEnabled = true
        
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        enableToolBarButtons()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email",
                                      message: "Your device could not send e-mail.  Please check e-mail configuration and try again.",
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func mailMediaItem(_ mediaItem:MediaItem?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ONE_SUBJECT)
        
        if let bodyString = setupMediaItemBodyHTML(mediaItem) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func mailMediaItems(_ mediaItems:[MediaItem]?)
    {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposeViewController.setToRecipients([])
        mailComposeViewController.setSubject(Constants.EMAIL_ALL_SUBJECT)
        
        if let bodyString = setupMediaItemsGlobalBodyHTML(mediaItems) {
            mailComposeViewController.setMessageBody(bodyString, isHTML: true)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func rowClickedAtIndex(_ index: Int, strings: [String], purpose:PopoverPurpose, mediaItem:MediaItem?) {
        dismiss(animated: true, completion: nil)
        
        switch purpose {
        case .selectingCellSearch:
            let searchText = strings[index]
            
            switch searchText {
            case Constants.Transcript:
                if globals.searchActive && (globals.searchText != nil) && (mediaItem?.notesHTML != nil) {
//                    if mediaItem?.notesHTML?.lowercased().range(of: globals.searchText!.lowercased()) != nil {
                        // put a <b></b> around the matched text everywhere it occurs
                        // load the transcript into a popover webViewController that loads the HTML string.
                    
                        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController {
                            if let popover = navigationController.viewControllers[0] as? WebViewController {
                                self.dismiss(animated: true, completion: nil)
                                
                                navigationController.modalPresentationStyle = .overFullScreen
                                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                                navigationController.popoverPresentationController?.delegate = self

//                                navigationController.modalPresentationStyle = .popover
//                                navigationController.popoverPresentationController?.sourceView = tableView
//                                
//                                navigationController.popoverPresentationController?.sourceRect = tableView.frame
                                
                                popover.navigationItem.title = Constants.Search
                                
                                popover.navigationController?.isNavigationBarHidden = false
                                
                                popover.selectedMediaItem = mediaItem
                                popover.content = .notesHTML
                                
                                self.present(navigationController, animated: true, completion: nil
//                                    {
//                                        DispatchQueue.main.async(execute: { () -> Void in
//                                            self.tableView.reloadData()
//                                        })
//                                    }
                                )
                            }
                        }

//                    }
                }
                break
                
            default:
                globals.searchActive = true
                globals.searchText = searchText
                searchBar.text = searchText
                searchBar.showsCancelButton = true
                updateSearchResults(searchText)
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
                break
            }
            break
        
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                mediaItem?.audioDownload?.deleteDownload()
                break
                
            case Constants.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDeleteDownload()
                break
                
            case Constants.Download_Audio:
                mediaItem?.audioDownload?.download()
                break
                
            default:
                break
            }
            break

        case .selectingHistory:
            var mediaItemID:String
            if let range = globals.history!.reversed()[index].range(of: Constants.TAGS_SEPARATOR) {
                mediaItemID = globals.history!.reversed()[index].substring(from: range.upperBound)
            } else {
                mediaItemID = globals.history!.reversed()[index]
            }
            if let mediaItem = globals.mediaRepository.index![mediaItemID] {
                if globals.active!.mediaItems!.contains(mediaItem) {
                    selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                } else {
                    dismiss(animated: true, completion: nil)
                    
                    let alert = UIAlertController(title:"Not in List",
                        message: "You are currently showing \"\(globals.tags.selected!)\" and \"\(mediaItem.title!)\" is not in that list.  Show \"All\" and try again.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    present(alert, animated: true, completion: nil)
                }
            } else {
                dismiss(animated: true, completion: nil)
                
                let alert = UIAlertController(title:"Media Item Not Found!",
                    message: "Yep, a genuine error - this should never happen!",
                    preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                present(alert, animated: true, completion: nil)
            }
            break
            
        case .selectingTags:
            
            // Should we be showing globals.active!.mediaItemTags instead?  That would be the equivalent of drilling down.

            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                //                    if (index >= 0) && (index <= globals.media.all!.mediaItemTags!.count) {
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
                            //                                print("\(globals.active!.mediaItemTags)")
                            
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
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
                            self.listActivityIndicator.stopAnimating()
                            self.listActivityIndicator.isHidden = true
                            
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
            dismiss(animated: true, completion: nil)
            let indexPath = IndexPath(row: 0, section: index)
            
            //Too slow
            //                if (globals.grouping == Constants.SERIES) {
            //                    let string = strings[index]
            //
            //                    if (string != Constants.Individual_MediaItems) && (globals.mediaItemSectionTitles.series?.indexOf(string) == nil) {
            //                        let index = globals.mediaItemSectionTitles.series?.indexOf(Constants.Individual_MediaItems)
            //
            //                        var mediaItems = [MediaItem]()
            //
            //                        for mediaItem in globals.activeMediaItems! {
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
            //                        let sections = seriesFromMediaItems(globals.activeMediaItems,withTitles: false)
            //                        let section = sections?.indexOf(string)
            //                        indexPath = NSIndexPath(forRow: 0, inSection: section!)
            //                    }
            //                }
            
            //Can't use this reliably w/ variable row heights.
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            })
            break
            
        case .selectingGrouping:
            dismiss(animated: true, completion: nil)
            globals.grouping = Constants.groupings[index]
            
            if (globals.mediaNeed.grouping) {
                globals.clearDisplay()

                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    self.listActivityIndicator.isHidden = false
                    self.listActivityIndicator.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        globals.progress = 0
                        globals.finished = 0
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.progressTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
                        })
                        
                        globals.setupDisplay()
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.progressTimer?.invalidate()
                            self.progressTimer = nil
                            self.progressIndicator.isHidden = true
                        })
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            self.listActivityIndicator.stopAnimating()
                            self.enableBarButtons()
                        })
                    })
                })
            }
            break
            
        case .selectingSorting:
            dismiss(animated: true, completion: nil)
            globals.sorting = Constants.sortings[index]
            
            if (globals.mediaNeed.sorting) {
                globals.clearDisplay()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    self.listActivityIndicator.isHidden = false
                    self.listActivityIndicator.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        globals.setupDisplay()
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            self.listActivityIndicator.stopAnimating()
                            self.enableBarButtons()
                            //
                            //                            if (self.splitViewController != nil) {
                            //                                //iPad only
                            //                                if let nvc = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count - 1] as? UINavigationController {
                            //                                    if let myvc = nvc.visibleViewController as? MediaViewController {
                            //                                        myvc.sortMediaItemsInSeries()
                            //                                    }
                            //                                }
                            //
                            //                            }
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
                
            case Constants.Email_All:
                mailMediaItems(globals.active?.list)
                break
                
            case Constants.Current_Selection:
                if let mediaItem = selectedMediaItem {
                    if globals.active!.mediaItems!.contains(mediaItem) {
                        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                    } else {
                        dismiss(animated: true, completion: nil)
                        
                        let alert = UIAlertController(title:"Not in List",
//                            message: "\"\(mediaItem.title!)\" is not in the list.",
                            message: "You are currently showing \"\(globals.tags.selected!)\" and \"\(mediaItem.title!)\" is not in that list.  Show \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        present(alert, animated: true, completion: nil)
                    }
                } else {
                    dismiss(animated: true, completion: nil)
                    
                    let alert = UIAlertController(title:"Media Item Not Found!",
                        message: "Yep, a genuine error - this should never happen!",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    present(alert, animated: true, completion: nil)
                }
                break
                
            case Constants.Media_Playing:
                fallthrough
                
            case Constants.Media_Paused:
                globals.gotoPlayingPaused = true
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case Constants.Scripture_Index:
                if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SCRIPTURE_INDEX) as? ScriptureIndexViewController {

                    viewController.mediaListGroupSort = globals.active

                    self.navigationController?.pushViewController(viewController, animated: true)
                }

//                performSegue(withIdentifier: Constants.SEGUE.SHOW_SCRIPTURE_INDEX, sender: nil)
                break
                
            case Constants.History:
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
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
                                var mediaItemID:String
//                                var date:String
                                
                                if let range = history.range(of: Constants.TAGS_SEPARATOR) {
                                    mediaItemID = history.substring(from: range.upperBound)
//                                    date = history.substringToIndex(range.startIndex)
                                    
                                    if let mediaItem = globals.mediaRepository.index![mediaItemID] {
                                        historyMenu.append(mediaItem.text!)
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
//                                    if (sections[index] == date.substringToIndex(date.rangeOfString(Constants.SINGLE_SPACE)!.startIndex)) {
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
                performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: nil)
                break
                
            case Constants.Settings:
                performSegue(withIdentifier: Constants.SEGUE.SHOW_SETTINGS, sender: nil)
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
                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: false, position: UITableViewScrollPosition.none)
            })
        })
    }
    
    func index(_ object:AnyObject?)
    {
        //In case we have one already showing
        dismiss(animated: true, completion: nil)

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Menu.Index
                
                popover.delegate = self
                
                popover.purpose = .selectingSection

                switch globals.grouping! {
                case Grouping.TITLE:
                    popover.strings = globals.active?.sectionTitles
                    popover.indexStrings = globals.active?.sectionIndexTitles
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
                            popover.strings?.append(contentsOf: other)
                        }
                    }
                    
//                    print(popover.strings)
                    
                    popover.indexStrings = popover.strings

                    popover.showIndex = false
                    popover.showSectionHeaders = false
                    break
                    
                case Grouping.SPEAKER:
                    popover.strings = globals.active?.sectionTitles
                    popover.indexStrings = globals.active?.sectionIndexTitles
                    
//                    popover.transform = lastNameFromName

                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    break
                    
                default:
                    popover.strings = globals.active?.sectionTitles
                    popover.indexStrings = globals.active?.sectionIndexTitles
                    popover.showIndex = false
                    popover.showSectionHeaders = false
                    break
                }
                
                present(navigationController, animated: true, completion: nil)
            }
        }

        // Too slow
//        if (globals.grouping == Constants.SERIES) {
//            let strings = seriesFromMediaItems(globals.activeMediaItems,withTitles: true)
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Options_Title.Grouping
                
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
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = Constants.Options_Title.Sorting
                
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
//        print(searchText)
        if (searchText != Constants.EMPTY_STRING) { //
            globals.searchText = searchText
            updateSearchResults(searchText)
        } else {
            globals.clearDisplay()
            tableView.reloadData()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarSearchButtonClicked:")
        searchBar.resignFirstResponder()
//        print(searchBar.text)
        if (searchBar.text != nil) && (searchBar.text != Constants.EMPTY_STRING) { //
            globals.searchText = searchBar.text
            updateSearchResults(searchBar.text)
        } else {
            globals.clearDisplay()
            tableView.reloadData()
            enableBarButtons()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        return !globals.isLoading && !globals.isRefreshing && (globals.media.all != nil) // !globals.mediaItemsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        globals.searchActive = true
        searchBar.showsCancelButton = true

//        print(searchBar.text)
        if (searchBar.text != nil) && (searchBar.text != Constants.EMPTY_STRING) { //
            globals.searchText = searchBar.text
            updateSearchResults(searchBar.text)
        }
        
        globals.clearDisplay()
        tableView.reloadData()
        disableBarButtons()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked:")
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
//        if (globals.searchText != nil) && (globals.searchText != Constants.EMPTY_STRING) {
//            _ = globals.search?.searches?.removeValue(forKey: globals.searchText!)
//        }

        globals.searchActive = false
        globals.searchText = nil
        
        didDismissSearch()
    }
    
    func setupViews()
    {
        setupTag()
        
        tableView.reloadData()
        
        setupTitle()
        
        addRefreshControl()
        
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
    
    func updateProgress()
    {
//        print("\(Float(globals.progress))")
//        print("\(Float(globals.finished))")
//        print("\(Float(globals.progress) / Float(globals.finished))")
        
        self.progressIndicator.progress = 0
        if (globals.finished > 0) {
            self.progressIndicator.isHidden = !showProgress
            self.progressIndicator.progress = Float(globals.progress) / Float(globals.finished)
        }
        
        //            print("\(self.progressIndicator.progress)")
        
        if self.progressIndicator.progress == 1.0 {
            self.progressTimer?.invalidate()
            
            self.progressIndicator.isHidden = true
            self.progressIndicator.progress = 0
            
            globals.progress = 0
            globals.finished = 0
        }
    }

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
                    print(error.localizedDescription)
                }
                
                print(json)
                return json
            } else {
                print("could not get json from URL, make sure that it exists and contains valid json.")
                
                do {
                    let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
                    
                    let json = JSON(data: data)
                    if json != JSON.null {
                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load.  Last available copy read and loaded.")
                        print("could get json from the file system.")
//                        print(json)
                        return json
                    } else {
                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load. Last available copy read but load failed.")
                        print("could not get json from the file system either.")
                    }
                } catch let error as NSError {
                    jsonAlert(title:"Media List Error",message:"Media list read but failed to load.  Last available copy read failed.")
                    print(error.localizedDescription)
                }
            }
        } catch let error as NSError {
            print("getting json from URL failed, make sure that it exists and contains valid json.")
            print(error.localizedDescription)
            
            do {
                let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
                
                let json = JSON(data: data)
                if json != JSON.null {
                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read and loaded.")
                    print("could get json from the file system.")
                    //                        print(json)
                    return json
                } else {
                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read but load failed.")
                    print("could not get json from the file system either.")
                }
            } catch let error as NSError {
                jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read failed.")
                print(error.localizedDescription)
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
        globals.progress = 0
        globals.finished = 0
        
        progressTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaTableViewController.updateProgress), userInfo: nil, repeats: true)
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.isLoading = true

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
            
            if globals.searchActive {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.searchBar.text = globals.searchText
                    self.searchBar.showsCancelButton = (self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)
                })

                let searchMediaItems = globals.search?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.search(searchText: globals.searchText)
                })
                
                if globals.search?.searches == nil {
                    globals.search?.searches = [String:MediaListGroupSort]()
                }
                globals.search?.searches?[globals.searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                globals.searchComplete = false
            }

            globals.setupDisplay()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (globals.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    globals.setupPlayer(globals.mediaPlayer.mediaItem,playOnLoad:false)
                }
            })
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.CBC.TITLE.SHORT
                
                self.setupViews()
                
                self.setupListActivityIndicator()
                
                if globals.searchComplete {
                    self.enableBarButtons()
                    self.setupCategoryButton()
                }
                
                if globals.mediaRepository.list != nil {
                    if globals.isRefreshing {
                        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                            self.refreshControl?.endRefreshing()
                            globals.isRefreshing = false
                        })
                    }
                }
            })
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion?()
            })
            
            globals.isLoading = false
        })
    }
    
    func setupCategoryButton()
    {
        mediaCategoryButton.setTitle(globals.mediaCategory.selected, for: UIControlState.normal)
        if globals.isLoading {
            mediaCategoryButton.isEnabled = false
        } else {
            if (globals.mediaRepository.list != nil) &&  globals.searchComplete {
                mediaCategoryButton.isEnabled = true
            }
        }
    }
    
    func setupBarButtons()
    {
        if globals.isLoading {
            disableBarButtons()
        } else {
            if (globals.mediaRepository.list != nil) &&  globals.searchComplete {
                enableBarButtons()
            }
        }
    }
    
    func setupListActivityIndicator()
    {
        if globals.isLoading {
            if !globals.isRefreshing {
                self.listActivityIndicator.startAnimating()
                self.listActivityIndicator.isHidden = false
            }
        } else {
            self.listActivityIndicator.stopAnimating()
            self.listActivityIndicator.isHidden = true
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
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.progressIndicator.isHidden = false
            
            print(totalBytesExpectedToWrite > 0 ? Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0.0)
            
            self.progressIndicator.progress = totalBytesExpectedToWrite > 0 ? Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0.0
        })

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.progressIndicator.isHidden = true
        })

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
                
                globals.setupDisplay()
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
        
//        if globals.mediaCategory.selected != "All Media" {
//            url = Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!
//        } else {
//            url = Constants.JSON.URL.MEDIA
//        }

        url = Constants.JSON.URL.MEDIA

        navigationItem.title = Constants.Title.Downloading_Media
        
//        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.CBC.SHORT.lowercaseString).\(Constants.SERMONS_JSON_FILENAME)"
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
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        globals.isRefreshing = true
        
        globals.unobservePlayer()
        
        if globals.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) {
            globals.mediaPlayer.pause() // IfPlaying
            
//            DispatchQueue.main.async(execute: { () -> Void in
//                globals.mediaPlayer.view?.isHidden = true
//            })
        }

        globals.cancelAllDownloads()

        globals.clearDisplay()
        
        searchBar.placeholder = nil

        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })

        if splitViewController != nil {
            DispatchQueue.main.async(execute: { () -> Void in
//                self.performSegue(withIdentifier: Constants.SEGUE.SHOW_SERMON, sender: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            })
        }

        DispatchQueue.main.async(execute: { () -> Void in
            self.setupBarButtons()
        })
        
        loadCategories()
        
        // loadMediaItems or downloadJSON
        
        switch jsonSource {
        case .download:
            downloadJSON()
            break
            
        case .direct:
            loadMediaItems()
            {
                if globals.mediaRepository.list == nil {
                    let alert = UIAlertController(title: "No media available.",
                                                  message: "Please check your network connection and try again.",
                        preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                        if globals.isRefreshing {
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                self.refreshControl?.endRefreshing()
                                globals.isRefreshing = false
                            })
                        } else {
                            self.listActivityIndicator.isHidden = true
                            self.listActivityIndicator.stopAnimating()
                        }
                    })
                    alert.addAction(action)
                    
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if globals.searchActive && globals.searchTranscripts && !globals.searchComplete {
                        self.updateSearchResults(globals.searchText)
                    }
                }
            }
            break
        }
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
    
    func editing()
    {
        refreshList = false
        searchBar.resignFirstResponder()
    }
    
    func notEditing()
    {
        if changesPending {
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        }
        refreshList = true
        changesPending = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: globals.media.tagged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.editing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.EDITING), object: globals.media.tagged)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.notEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_EDITING), object: globals.media.tagged)
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)

        setupBarButtons()
        
        if globals.mediaRepository.list == nil {
            //            disableBarButtons()
            
            loadCategories()
            
            // Download or Load
            
            switch jsonSource {
            case .download:
                downloadJSON()
                break
                
            case .direct:
                loadMediaItems()
                {
                    if globals.mediaRepository.list == nil {
                        let alert = UIAlertController(title: "No media available.",
                                                      message: "Please check your network connection and try again.",
                                                      preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                            if globals.isRefreshing {
                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                    self.refreshControl?.endRefreshing()
                                    globals.isRefreshing = false
                                })
                            } else {
                                self.listActivityIndicator.isHidden = true
                                self.listActivityIndicator.stopAnimating()
                            }
                        })
                        alert.addAction(action)
                        
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        if globals.searchActive && globals.searchTranscripts && !globals.searchComplete {
                            self.updateSearchResults(globals.searchText)
                        }
                    }
                }
                break
            }
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let selectedMediaItemKey = UserDefaults.standard.string(forKey: Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER) {
            selectedMediaItem = globals.mediaRepository.list?.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.id == selectedMediaItemKey
            }).first
        }
        
        // App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden when mode is changed to primaryHidden!
        splitViewController?.preferredDisplayMode = .automatic //iPad only
        
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
//        print("searchBarResultsListButtonClicked")
        
        if !globals.isLoading && !globals.isRefreshing && (globals.media.all?.mediaItemTags != nil) && (self.storyboard != nil) { // !globals.mediaItemsSortingOrGrouping &&
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .popover
                    //            popover?.preferredContentSize = CGSizeMake(300, 500)
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.sourceView = searchBar
                    navigationController.popoverPresentationController?.sourceRect = searchBar.bounds
                    
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
//        print(searchText)
        
        refreshList = true
        
        var abort = false

        if (searchText != nil) && (searchText != Constants.EMPTY_STRING) {
//            print(searchText!)

            globals.clearDisplay()

            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                self.disableBarButtons()
            })
            
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                //                print("1: ",searchText,Constants.EMPTY_STRING)
                
                if (globals.search?.searches?[searchText!] == nil) || !globals.searchComplete {
                    var searchMediaItems:[MediaItem]?
                    
                    //                    let searchMediaItems = globals.mediaToSearch?.filter({ (mediaItem:MediaItem) -> Bool in
                    //                        return mediaItem.search(searchText: searchText)
                    //                    })
                    
                    if globals.search?.list != nil {
                        for mediaItem in globals.search!.list! {
                            if !self.listActivityIndicator.isAnimating {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.listActivityIndicator.isHidden = false
                                    self.listActivityIndicator.startAnimating()
                                })
                            }
                            
                            let searchHit = mediaItem.search(searchText: globals.searchText)
                            //                            let searchHit = globals.searchTranscripts ? mediaItem.search(searchText: globals.searchText) || mediaItem.searchNotesHTML(searchText: globals.searchText) : mediaItem.search(searchText: globals.searchText)
                            
                            if searchHit {
                                if searchMediaItems == nil {
                                    searchMediaItems = [mediaItem]
                                } else {
                                    searchMediaItems?.append(mediaItem)
                                }
                                
                                if ((searchMediaItems!.count % Constants.SEARCH_RESULTS_BETWEEN_UPDATES) == 0) {
                                    //                                print("2: ",searchText,searchMediaItems?.count)
                                    //                                print(searchText!)
                                    //                                print(searchMediaItems?.count)
                                    
                                    if globals.search?.searches == nil {
                                        globals.search?.searches = [String:MediaListGroupSort]()
                                    }
                                    
                                    self.showProgress = false
                                    globals.search?.searches?[searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                                    self.showProgress = true
                                    
                                    if !globals.searchActive || ((self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)) {
                                        globals.setupDisplay()
                                    } else {
                                        globals.clearDisplay()
                                    }
                                    
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        if self.refreshList {
                                            self.tableView.reloadData()
                                        } else {
                                            self.changesPending = true
                                        }
                                    })
                                }
                            }
                            
                            if (globals.searchText != searchText) {
                                globals.search?.searches?[searchText!] = nil
                                abort = true
                                break
                            }
                        }

                        if globals.search?.searches == nil {
                            globals.search?.searches = [String:MediaListGroupSort]()
                        }
                        
                        if !abort {
                            self.showProgress = false
                            globals.search?.searches?[searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                            self.showProgress = true
                            
                            if !globals.searchActive || ((self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)) {
                                globals.setupDisplay()
                            } else {
                                globals.clearDisplay()
                            }
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                if self.refreshList {
                                    self.tableView.reloadData()
                                } else {
                                    self.changesPending = true
                                }
                            })
                        } else {
                            globals.search?.searches?[searchText!] = nil
                        }

                        if !abort && globals.searchTranscripts {
                            for mediaItem in globals.search!.list! {
                                if !self.listActivityIndicator.isAnimating {
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.listActivityIndicator.isHidden = false
                                        self.listActivityIndicator.startAnimating()
                                    })
                                }
                                
                                var searchHit = false
                                
                                if (searchMediaItems == nil) || !searchMediaItems!.contains(mediaItem) {
                                    searchHit = mediaItem.searchNotesHTML(searchText: globals.searchText)
                                }
                                //                            let searchHit = globals.searchTranscripts ? mediaItem.search(searchText: globals.searchText) || mediaItem.searchNotesHTML(searchText: globals.searchText) : mediaItem.search(searchText: globals.searchText)
                                
                                if searchHit {
                                    if searchMediaItems == nil {
                                        searchMediaItems = [mediaItem]
                                    } else {
                                        searchMediaItems?.append(mediaItem)
                                    }
                                    
//                                    if ((searchMediaItems!.count % Constants.SEARCH_RESULTS_BETWEEN_UPDATES) == 0) {
                                        //                                print("2: ",searchText,searchMediaItems?.count)
                                        //                                print(searchText!)
                                        //                                print(searchMediaItems?.count)
                                        
                                        if globals.search?.searches == nil {
                                            globals.search?.searches = [String:MediaListGroupSort]()
                                        }
                                        
                                        self.showProgress = false
                                        globals.search?.searches?[searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                                        self.showProgress = true
                                        
                                        if !globals.searchActive || ((self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)) {
                                            globals.setupDisplay()
                                        } else {
                                            globals.clearDisplay()
                                        }
                                        
                                        DispatchQueue.main.async(execute: { () -> Void in
                                            if self.refreshList {
                                                self.tableView.reloadData()
                                            } else {
                                                self.changesPending = true
                                            }
                                        })
//                                    }
                                }
                                
                                if (globals.searchText != searchText) {
                                    globals.search?.searches?[searchText!] = nil
                                    abort = true
                                    break
                                }
                            }

                            if !abort {
                                self.showProgress = false
                                globals.search?.searches?[searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                                self.showProgress = true
                                
                                if !globals.searchActive || ((self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)) {
                                    globals.setupDisplay()
                                } else {
                                    globals.clearDisplay()
                                }
                                
                                DispatchQueue.main.async(execute: { () -> Void in
                                    if self.refreshList {
                                        self.tableView.reloadData()
                                    } else {
                                        self.changesPending = true
                                    }
                                })
                            } else {
                                globals.search?.searches?[searchText!] = nil
                            }
                        }
                    }
                    
                    // Final search update since we're only doing them in batches of Constants.SEARCH_RESULTS_BETWEEN_UPDATES
                    
                    if globals.search?.searches == nil {
                        globals.search?.searches = [String:MediaListGroupSort]()
                    }
                    
                    if !abort {
                        self.showProgress = false
                        globals.search?.searches?[searchText!] = MediaListGroupSort(mediaItems: searchMediaItems)
                        self.showProgress = true
                    }
                }
                
                if !abort {
                    if !globals.searchActive || ((self.searchBar.text != nil) && (self.searchBar.text != Constants.EMPTY_STRING)) {
                        globals.setupDisplay()
                    } else {
                        globals.clearDisplay()
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        if self.refreshList {
                            self.tableView.reloadData()
                        } else {
                            self.changesPending = true
                        }
                        self.listActivityIndicator.stopAnimating()
                        self.listActivityIndicator.isHidden = true
                        self.enableBarButtons()
                    })
                    
                    globals.searchComplete = true
                }
            })
        } else {
//            print(searchText)
        }
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        if (mediaItem != nil) && (globals.active?.mediaItems?.index(of: mediaItem!) != nil) {
            var indexPath = IndexPath(item: 0, section: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let mediaItems = globals.active?.mediaItems

            if let index = mediaItems!.index(of: mediaItem!) {
                switch globals.grouping! {
                case Grouping.YEAR:
//                    let calendar = NSCalendar.currentCalendar()
//                    let components = calendar.components(.Year, fromDate: mediaItems![index].fullDate!)
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
                    section = globals.active!.sectionTitles!.index(of: mediaItem!.yearSection!)!
                    break
                    
                case Grouping.TITLE:
//                    print(globals.active!.sectionIndexTitles)
//                    print(mediaItem)
//                    print(mediaItem?.seriesSectionSort)
//                    print(globals.active!.sectionIndexTitles!.index(of: mediaItem!.seriesSectionSort!))
                    section = globals.active!.sectionIndexTitles!.index(of: mediaItem!.multiPartSectionSort!)!
                    break
                    
                case Grouping.BOOK:
                    section = globals.active!.sectionTitles!.index(of: mediaItem!.bookSection!)!
                    break
                    
                case Grouping.SPEAKER:
                    section = globals.active!.sectionTitles!.index(of: mediaItem!.speakerSection!)!
                    break
                    
                default:
                    break
                }

                row = index - globals.active!.sectionIndexes![section]
            }

//            print(section)
            
            if (section > -1) && (row > -1) {
                indexPath = IndexPath(item: row,section: section)
                
                //            print("\(globals.mediaItemSelected?.title)")
                //            print("Row: \(indexPath.item)")
                //            print("Section: \(indexPath.section)")
                
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

    
    fileprivate func setupTag()
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
        
        updateUI()
        
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
        
        //        setupSplitViewController()
        
        setupShowHide()
        
        setupTitle()
        
        navigationController?.isToolbarHidden = false
        
        setupBarButtons()
        setupListActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
                        selectedMediaItem = myCell.mediaItem //globals.activeMediaItems![index]

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
        
        if (splitViewController != nil) && (splitViewController!.viewControllers.count > 1) { //  && isFullScreen
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

//        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
//            if splitViewController != nil {
//                navigationItem.setRightBarButton(nil,animated: true)
//            }
//        } else {
//            if (splitViewController != nil) { //  && isFullScreen
//                switch splitViewController!.displayMode {
//                case .automatic:
//                    navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                    break
//                    
//                case .primaryHidden:
//                    navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                    break
//                    
//                case .allVisible:
//                    navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                    break
//                    
//                case .primaryOverlay:
//                    navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                    break
//                }
//            } else {
//                navigationItem.setRightBarButton(nil,animated: true)
//            }
//        }
        
        navigationItem.rightBarButtonItem?.isEnabled = !globals.isRefreshing && !globals.isLoading
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
//        if (self.view.window == nil) {
//            return
//        }
        
        if (splitViewController != nil) {
//            dismiss(animated: false, completion: nil)
//            if (popover != nil) {
//                dismiss(animated: false, completion: nil)
//                popover = nil
//            }
        }

        if (self.splitViewController != nil) {
//            print("Before")
//            print(splitViewController!.viewControllers.count)
//            print(navigationController!.viewControllers.count)
//            print(navigationController!.visibleViewController)
            
            let beforeSVCC = splitViewController!.viewControllers.count
            let beforeNVCC = navigationController!.viewControllers.count
            
            let sivc = self.navigationController?.visibleViewController as? ScriptureIndexViewController
            
            if (beforeSVCC == 1) && (beforeNVCC > beforeSVCC) && (sivc != nil) {
                // Keeps scripture index from showing up in the MVC rather than the MTVC hierarchy.
                _ = self.navigationController?.popToRootViewController(animated: false)
            }

            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//                print("After")
//                print(self.splitViewController?.viewControllers.count)
//                print(self.navigationController?.viewControllers.count)
//                print(self.navigationController?.visibleViewController)
                
                let afterSVCC = self.splitViewController!.viewControllers.count
                let afterNVCC = self.navigationController!.viewControllers.count

                if (afterNVCC == 1) && (sivc != nil) { //
                    if (afterSVCC == 1) || (afterNVCC < afterSVCC) { //
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.navigationController?.pushViewController(sivc!, animated: false)
                        })
                    }
                }

                //Without this background/main dispatching there isn't time to scroll after a reload.
//                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                    DispatchQueue.main.async(execute: { () -> Void in
//                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
//                    })
//                })

                //        setupSplitViewController()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setupShowHide()
                    self.setupTitle()
                })
            }
        } else {
            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                
            }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setupTitle()
                })
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
        if globals.display.sectionTitles != nil {
            if section < globals.display.sectionTitles!.count {
                return globals.display.sectionTitles![section]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if globals.display.sectionCounts != nil {
            if section < globals.display.sectionCounts!.count {
                return globals.display.sectionCounts![section]
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
    
//        cell.addObserver(self,
//                          forKeyPath: #keyPath(UITableViewCell.),
//                          options: [.old, .new],
//                          context: nil) // &GlobalPlayerContext

        // Configure the cell
        if (globals.display.sectionIndexes != nil) && (globals.display.mediaItems != nil) {
            if indexPath.section < globals.display.sectionIndexes!.count {
                if let section = globals.display.sectionIndexes?[indexPath.section] {
                    if section + indexPath.row < globals.display.mediaItems!.count {
                        cell.mediaItem = globals.display.mediaItems?[section + indexPath.row]
                    }
                } else {
                    print("No mediaItem for cell!")
                }
            }
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

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        refreshList = false
        
        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        guard let mediaItem = cell.mediaItem else {
            return nil
        }
        
        let search = UITableViewRowAction(style: .normal, title: Constants.Search) { action, index in
            if let searchStrings = mediaItem.searchStrings() {
                //                        print(searchTokens)
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        self.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = tableView
                        navigationController.popoverPresentationController?.sourceRect = cell.frame
                        
                        popover.navigationItem.title = Constants.Search
                        
                        popover.navigationController?.isNavigationBarHidden = false
                        
                        popover.delegate = self
                        popover.purpose = .selectingCellSearch
                        
                        popover.selectedMediaItem = mediaItem
                        
                        popover.showIndex = true
                        popover.showSectionHeaders = true
                        
                        popover.strings = searchStrings
                        
                        if globals.searchTranscripts && globals.searchActive && (globals.searchText != nil) && (globals.searchText != Constants.EMPTY_STRING) {
                            if mediaItem.hasNotesHTML && (mediaItem.notesHTML == nil) {
                                popover.stringsFunction = {
                                    var strings = popover.strings
                                    
                                    mediaItem.loadNotesHTML()
                                    
                                    if mediaItem.searchNotesHTML(searchText: globals.searchText) {
                                        strings?.insert(Constants.Transcript,at: 0)
                                    }
                                    
                                    return strings
                                }
                            } else {
                                if mediaItem.searchNotesHTML(searchText: globals.searchText) {
                                    popover.strings?.insert(Constants.Transcript,at: 0)
                                }
                            }
                        }
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false
                        
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
        search.backgroundColor = UIColor.controlBlue()
        
        let words = UITableViewRowAction(style: .normal, title: Constants.Tokens) { action, index in
            if let searchTokens = mediaItem.searchTokens() {
                //                        print(searchTokens)
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        self.dismiss(animated: true, completion: nil)
                        
                        navigationController.modalPresentationStyle = .popover
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.sourceView = tableView
                        navigationController.popoverPresentationController?.sourceRect = cell.frame
                        
                        popover.navigationItem.title = Constants.Search
                        
                        popover.navigationController?.isNavigationBarHidden = false
                        
                        popover.delegate = self
                        popover.purpose = .selectingCellSearch
                        
                        popover.selectedMediaItem = mediaItem
                        
                        popover.strings = nil
                        
                        popover.stringsFunction = {
                            if mediaItem.hasNotesHTML && (mediaItem.notesHTML == nil) {
                                mediaItem.loadNotesHTML()
                            }
                            var tokens = Set(searchTokens)
                            
                            if let notesTokens = tokensFromString(mediaItem.notesHTML) {
                                tokens = tokens.union(Set(notesTokens))
                            }
                            
                            let tokenArray = Array(tokens).sorted()
                            
//                            print(tokenArray)

                            return tokenArray
                        }
                        
                        popover.showIndex = true
                        popover.showSectionHeaders = true
                        
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
        words.backgroundColor = UIColor.blue
        
//        let transcript = UITableViewRowAction(style: .normal, title: Constants.Search) { action, index in
//            //                    if mediaItem?.notesHTML?.lowercased().range(of: globals.searchText!.lowercased()) != nil {
//            // put a <b></b> around the matched text everywhere it occurs
//            // load the transcript into a popover webViewController that loads the HTML string.
//            
//            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController {
//                if let popover = navigationController.viewControllers[0] as? WebViewController {
//                    self.dismiss(animated: true, completion: nil)
//                    
//                    navigationController.modalPresentationStyle = .overFullScreen
//                    navigationController.popoverPresentationController?.permittedArrowDirections = .any
//                    navigationController.popoverPresentationController?.delegate = self
//                    
//                    //                                navigationController.modalPresentationStyle = .popover
//                    //                                navigationController.popoverPresentationController?.sourceView = tableView
//                    //
//                    //                                navigationController.popoverPresentationController?.sourceRect = tableView.frame
//                    
//                    popover.navigationItem.title = Constants.Search_For
//                    
//                    popover.navigationController?.isNavigationBarHidden = false
//                    
//                    popover.selectedMediaItem = mediaItem
//                    popover.content = .notesHTML
//                    
//                    self.present(navigationController, animated: true, completion: nil
//                        //                                    {
//                        //                                        DispatchQueue.main.async(execute: { () -> Void in
//                        //                                            self.tableView.reloadData()
//                        //                                        })
//                        //                                    }
//                    )
//                }
//            }
//        }
//        transcript.backgroundColor = UIColor.controlBlue()
//
//        if globals.searchActive && (globals.searchText != nil) && (mediaItem.notesHTML != nil) {
//            return [search,transcript]
//        } else {
//            return [search]
//        }

        if mediaItem.hasNotesHTML {
            return [search, words]
        } else {
            return [search]
        }
    }
    
    /*
     // Override to support editing the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
       // the cells you would like the actions to appear needs to be editable
        return false
    }
     
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
