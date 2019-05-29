//
//  MediaTableViewController.swift
//  CBC
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI

enum PopoverPurpose {
    case selectingShow

    case selectingGapTime

    case selectingSorting
    case selectingGrouping
    case selectingSection
    
    case selectingSearch
    
    case selectingHistory
    case selectingLexicon
    
    case selectingWordCloud
    
    case selectingCellAction
    case selectingCellSearch
    
    case selectingAction
    
    case selectingWord
    
    case selectingCategory
    
    case selectingTimingIndexWord
    case selectingTimingIndexPhrase
    
    case selectingTimingIndexTopic
    case selectingTimingIndexTopicKeyword

    case selectingTime
    
    case selectingTags
    
    case showingVoiceBaseMediaItems
    case showingVoiceBaseMediaItem
    
    case showingTags
    case editingTags
}

enum JSONSource {
    case direct
    case download
}

extension MediaTableViewController : UIScrollViewDelegate
{
    // This shortens the distance the tableView must be pulled to initiate a refresh.
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {

    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        tableView?.isEditing = false
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
    {
        tableView?.isEditing = false
    }
}

extension MediaTableViewController : UISearchBarDelegate
{
    // MARK: UISearchBarDelegate

    @objc func searchActions()
    {
        self.popover?["SEARCH_HISTORY"]?.dismiss(animated: true, completion: nil)
        
        var alertActions = [AlertAction]()
        
        let yesAction = AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: { [weak self]
            () -> Void in
            Globals.shared.media.search.searches?.clear()
            self?.popover?["SEARCH_HISTORY"]?.dismiss(animated: true, completion: nil)
        })
        alertActions.append(yesAction)
        
        let noAction = AlertAction(title: Constants.Strings.No, style: .default, handler: { [weak self]
            () -> Void in
            
        })
        alertActions.append(noAction)
        
        Alerts.shared.alert(title: "Delete All Searches?", actions: alertActions)
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar)
    {
        if  let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.sourceRect = searchBar.frame
            navigationController.popoverPresentationController?.sourceView = view
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            
            popover.navigationItem.title = "Search History"
            
            popover.delegate = self
            popover.purpose = .selectingSearch
            
            self.popover?["SEARCH_HISTORY"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["SEARCH_HISTORY"] = nil
            }
            
            popover.stringsFunction = { [weak self, weak popover] ()->[String]? in
                let strings = Globals.shared.media.search.searches?.keys()?.filter({ (string:String) -> Bool in
                    return Globals.shared.media.search.isActive ? string.searchText != Globals.shared.media.search.text?.uppercased() : true
                }).map({ (string:String) -> String in
                    return string.searchText ?? ""
                }).set.array.sorted()
                
                Thread.onMain {
                    popover?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Constants.Strings.Delete_All, style: UIBarButtonItem.Style.plain, target: self, action: #selector(self?.searchActions))
                    popover?.navigationItem.leftBarButtonItem?.isEnabled = strings?.count > 0
                }
                
                return strings
            }

            navigationController.view.isHidden = true
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBar:textDidChange", completion: nil)
            return
        }
        
        let searchText = searchText.uppercased()
        
        Globals.shared.media.search.text = searchText
        
        if !searchText.isEmpty { //
            updateSearchResults(Globals.shared.media.active?.context,completion: nil)
        } else {
            display.clear()
            
            tableView?.reloadData()
            
            setupBarButtons()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBarSearchButtonClicked", completion: nil)
            return
        }

        searchBar.resignFirstResponder()

        let searchText = searchBar.text?.uppercased()
        
        Globals.shared.media.search.text = searchText
        
        if Globals.shared.media.search.isValid {
            updateSearchResults(Globals.shared.media.active?.context,completion: nil)
        } else {
            display.clear()
            
            tableView?.reloadData()
            
            setupBarButtons()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard self.isViewLoaded else {
            return false
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBarShouldBeginEditing", completion: nil)
            return false
        }
        
        return !Globals.shared.isLoading && !Globals.shared.isRefreshing && (Globals.shared.media.all != nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidBeginEditing", completion: nil)
            return
        }

        Globals.shared.media.search.isActive = true
        
        searchBar.showsCancelButton = true
        
        let searchText = searchBar.text?.uppercased()
        
        Globals.shared.media.search.text = searchText
        
        if Globals.shared.media.search.isValid { //
            updateSearchResults(Globals.shared.media.active?.context,completion: nil)
        } else {
            display.clear()
            
            tableView?.reloadData()
            
            setupBarButtons()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidEndEditing", completion: nil)
            return
        }
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:searchBarCancelButtonClicked", completion: nil)
            return
        }
        
        Globals.shared.media.search.isActive = false
        
        didDismissSearch()
    }
    
    func didDismissSearch()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:didDismissSearch", completion: nil)
            return
        }
        
        Globals.shared.media.search.text = nil
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        barButtonItems(isEnabled:false)

        display.clear()
        
        tableView?.reloadData()
        
        startAnimating()
        
        display.setup(Globals.shared.media.active)
        
        tableView?.reloadData()
        
        stopAnimating()
        
        setupTag()
        
        setupBarButtons()

        //Moving the list can be very disruptive
        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: false, position: UITableView.ScrollPosition.none)
    }
}

//extension MediaTableViewController : MFMailComposeViewControllerDelegate
//{
//    // MARK: MFMailComposeViewControllerDelegate
//    
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        controller.dismiss(animated: true, completion: nil)
//    }
//}

extension MediaTableViewController : URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset: Int64, expectedTotalBytes: Int64)
    {
        print("URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:")
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        print("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        if let filename = downloadTask.taskDescription {
            print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL \(location.lastPathComponent)")
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        print("countOfBytesReceived: \(downloadTask.countOfBytesReceived)")
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        if let filename = downloadTask.taskDescription {
            print("filename: \(filename) location: \(location)")
            
            if (downloadTask.countOfBytesReceived > 0) {
                let fileManager = FileManager.default
                
                //Get documents directory URL
                if let destinationURL = filename.fileSystemURL {
                    // Why delete?  Why not just let it be overwritten?
                    destinationURL.delete(block:true)
                    
                    do {
                        try fileManager.copyItem(at: location, to: destinationURL)
                        location.delete(block:true)
                    } catch let error {
                        print("failed to copy new json file to Documents: \(error.localizedDescription)")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            } else {
                print("downloadTask.countOfBytesReceived not > 0")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        print("URLSession:task:didCompleteWithError")

        // category.
        if let mediaFilename = Globals.shared.media.json.filename, let filename = task.taskDescription {
            print("filename: \(filename)")
            
            if let error = error {
                print("Download failed for: \(filename) with error: \(error.localizedDescription)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Couldn't get categories from network, try to get media, use last downloaded
                    // category.
                    if let mediaFilename = Globals.shared.media.json.filename { // , let selectedID = Globals.shared.media.category.selectedID
                        downloadJSON(url:Constants.JSON.URL.MEDIA,filename:mediaFilename) // CATEGORY + selectedID
                    }
                    break
                    
                case mediaFilename:
                    // Couldn't get media from network, use last downloaded
                    loadMediaItems()
                    {
                        self.loadCompletion()
                    }
                    break
                    
                default:
                    break
                }
            } else {
                print("Download succeeded for: \(filename)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Load media
                    // category.
                    if let mediaFilename = Globals.shared.media.json.filename { // , let selectedID = Globals.shared.media.category.selectedID
                        downloadJSON(url:Constants.JSON.URL.MEDIA,filename:mediaFilename) // CATEGORY + selectedID
                    }
                    break
                    
                case mediaFilename:
                    loadMediaItems()
                    {
                        self.loadCompletion()
                    }
                    break
                    
                default:
                    break
                }
            }
        }

        session.invalidateAndCancel()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        print("URLSession:didBecomeInvalidWithError")
        
    }
}

class MediaTableViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

/**

 The main view controller.

 */

class MediaTableViewController : MediaItemsViewController
{
    deinit {
        debug(self)
    }
    
    var display = Display()

    var actionsButton : UIBarButtonItem?
    
    var stringIndex : StringIndex? // [String:[String]]()
    
    var changesPending = false
    
    var jsonSource:JSONSource = .direct
    
    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        Globals.shared.motionEnded(motion,event: event)
    }

    func bulkDeleteMedia()
    {
        VoiceBase.all(completion:{ [weak self] (json:[String:Any]?) -> Void in
            guard let mediaItems = json?["media"] as? [[String:Any]] else {
                return
            }
            
            self?.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                if  let date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                    let date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                    return Date(string: date0) < Date(string: date1)
                } else {
                    return false // arbitrary
                }
            })

            Thread.onMain {
                if self?.stringIndex?.keys == nil {
                    Alerts.shared.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase.")
                } else {
                    var alertActions = [AlertAction]()
                    alertActions.append(AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { () -> (Void) in
                        VoiceBase.bulkDelete(alert: true)
                    }))
                    alertActions.append(AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: nil))
                    Alerts.shared.alert(title: "Confirm Bulk Deletion of VoiceBase Media",
                                        message: "This will delete all VoiceBase media files in the cloud for all transcripts generated on all devices using the same API key that is on this device.", actions:alertActions)
                }
            }
            },onError: nil)
    }
    
    @objc func downloadFailed(_ notification:NSNotification)
    {

    }
    
    @IBOutlet weak var logo: UIImageView!
    {
        didSet {
            logo.isHidden = true
        }
    }
    
    @IBOutlet weak var tagLabel: UILabel!
    
    var refreshControl:UIRefreshControl?

    var session:URLSession? // Used for JSON downloading
    
    @IBOutlet weak var mediaCategoryButton: UIButton!
    @IBAction func mediaCategoryButtonAction(_ button: UIButton)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:mediaCategoryButtonAction", completion: nil)
            return
        }

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = localModalPresentationStyle

            navigationController.popoverPresentationController?.delegate = self
            
            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.sourceView = self.view
                navigationController.popoverPresentationController?.sourceRect = mediaCategoryButton.frame
            }

            popover.navigationItem.title = Constants.Strings.Select_Category
            
            popover.delegate = self
            popover.purpose = .selectingCategory
            
            popover.stringSelected = Globals.shared.media.category.selected ?? Constants.Strings.All
            
            popover.section.strings = [Constants.Strings.All]
            
            if let categories = Globals.shared.media.categories.keys()?.sorted() {
                popover.section.strings?.append(contentsOf: categories)
            }

            self.popover?["CATEGORY"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["CATEGORY"] = nil
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(MediaTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "MediaTableViewController")

            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControl.Event.valueChanged)

            if #available(iOS 10.0, *) {
                tableView.refreshControl = refreshControl
            } else {
                // Fallback on earlier versions
                if let refreshControl = self.refreshControl {
                    Thread.onMain {
                        self.tableView?.addSubview(refreshControl)
                    }
                }
            }
            
            tableView?.allowsSelection = true

            //Eliminates blank cells at end.
            tableView?.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:show", completion: nil)
            return
        }

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            // In case one is already showing
            self.popover?.values.forEach({ (popover:PopoverTableViewController) in
                popover.dismiss(animated: true, completion: nil)
            })
      
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.delegate = self
            popover.purpose = .selectingShow

            self.popover?["SHOW"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["SHOW"] = nil
            }
            
            var showMenu = [String]()
            
            if let isCollapsed = splitViewController?.isCollapsed {
                if isCollapsed {
                    showMenu.append(Constants.Strings.About)
                } else {
                    if  let count = splitViewController?.viewControllers.count,
                        let detailView = splitViewController?.viewControllers[count - 1] as? UINavigationController,
                        (detailView.viewControllers[0] as? AboutViewController) == nil {
                        showMenu.append(Constants.Strings.About)
                    }
                }
            } else {
                // SHOULD NEVER HAPPEN
            }
            
            //Because the list extends above and below the visible area, visibleCells is deceptive - the cell can be hidden behind a navbar or toolbar and still returned in the array of visibleCells.
            
            if let selectedMediaItem = selectedMediaItem, display.mediaItems?.contains(selectedMediaItem) == true {
                showMenu.append(Constants.Strings.Current_Selection)
            }
            
            if (Globals.shared.mediaPlayer.mediaItem != nil) {
                var show:String = Constants.EMPTY_STRING
                
                if Globals.shared.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM), let state = Globals.shared.mediaPlayer.state {
                    switch state {
                    case .paused:
                        show = Constants.Strings.Media_Paused
                        break
                        
                    case .playing:
                        show = Constants.Strings.Media_Playing
                        break
                        
                    default:
                        show = Constants.Strings.None
                        break
                    }
                } else {
                    show = Constants.Strings.Media_Paused
                }
                
                if let count = splitViewController?.viewControllers.count, count > 1 {
                    if let nvc = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
                        if let myvc = nvc.topViewController as? MediaViewController {
                            if (myvc.selectedMediaItem != nil) {
                                if (myvc.selectedMediaItem?.title != Globals.shared.mediaPlayer.mediaItem?.title) || (myvc.selectedMediaItem?.date != Globals.shared.mediaPlayer.mediaItem?.date) {
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
            
            // SHOULD THESE BE ON THE ACTION MENU?
            if let vClass = splitViewController?.traitCollection.verticalSizeClass,
                let isCollapsed = splitViewController?.isCollapsed,
                (vClass != UIUserInterfaceSizeClass.compact) || isCollapsed {
                if (Globals.shared.media.active?.scriptureIndex?.eligible != nil) {
                    showMenu.append(Constants.Strings.Scripture_Index)
                }
                
                if (Globals.shared.media.active?.lexicon?.eligible != nil), Globals.shared.reachability.isReachable {
                    showMenu.append(Constants.Strings.Lexicon_Index)
                }
            } else {
                
            }
            
            showMenu.append(Constants.Strings.History)

            if Globals.shared.reachability.isReachable { // Globals.shared.media.stream.streamEntries != nil, 
                showMenu.append(Constants.Strings.Live)
            }
            
            showMenu.append(Constants.Strings.Settings)
            
            showMenu.append(Constants.Strings.VoiceBase_API_Key)
            
            if Globals.shared.isVoiceBaseAvailable ?? false {
                showMenu.append(Constants.Strings.VoiceBase_Media)
                showMenu.append(Constants.Strings.VoiceBase_Bulk_Delete)
                
                if Globals.shared.media.repository.list?.voiceBaseMediaItems > 0 {
                    showMenu.append(Constants.Strings.VoiceBase_Delete_All)
                }
            }
            
            popover.section.strings = showMenu

            present(navigationController, animated: true, completion: nil)
        }
    }
    
    var selectedMediaItem:MediaItem?
    {
        willSet {
            
        }
        didSet {
            if selectedMediaItem != Globals.shared.media.selected.master {
                Globals.shared.media.selected.master = selectedMediaItem
            }
        }
    }
    
    @objc func index(_ object:AnyObject?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:index", completion: nil)
            return
        }

        guard let grouping = Globals.shared.grouping else {
            return
        }
        
        //In case we have one already showing
        self.popover?.values.forEach({ (popover:PopoverTableViewController) in
            popover.dismiss(animated: true, completion: nil)
        })

        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.shared.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection

            switch grouping {
            case GROUPING.BOOK:
                if let books = Globals.shared.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                    return string.bookNumberInBible != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                }) {
                    popover.section.strings = books

                    if let other = Globals.shared.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                        return string.bookNumberInBible == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
                        popover.section.strings?.append(contentsOf: other)
                    }
                }
                break
                
            case GROUPING.TITLE:
                popover.section.showIndex = true
                popover.indexStringsTransform = { (string:String?) -> String? in
                    return string?.withoutPrefixes
                }
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.CLASS:
                popover.section.showIndex = true
                popover.indexStringsTransform = { (string:String?) -> String? in
                    return string?.withoutPrefixes
                }
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.SPEAKER:
                popover.section.showIndex = true
                popover.indexStringsTransform = { (string:String?) -> String? in
                    return string?.lastName
                } // lastNameFromName
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            default:
                popover.section.strings = Globals.shared.media.active?.section?.headerStrings
                break
            }

            self.popover?["INDEX"] = popover

            popover.completion = { [weak self] in
                self?.popover?["INDEX"] = nil
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }

    @objc func grouping(_ object:AnyObject?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:grouping", completion: nil)
            return
        }

        //In case we have one already showing
        self.popover?.values.forEach({ (popover:PopoverTableViewController) in
            popover.dismiss(animated: true, completion: nil)
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.shared.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Options_Title.Grouping
            
            popover.delegate = self

            self.popover?["GROUPING"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["GROUPING"] = nil
            }
            
            popover.purpose = .selectingGrouping
            popover.section.strings = Globals.shared.groupingTitles
            popover.stringSelected = Globals.shared.grouping?.translate
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func sorting(_ object:AnyObject?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:sorting", completion: nil)
            return
        }

        //In case we have one already showing
        popover?.values.forEach({ (popover:PopoverTableViewController) in
            popover.dismiss(animated: true, completion: nil)
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.shared.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Options_Title.Sorting
            
            popover.delegate = self

            self.popover?["SORTING"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["SORTING"] = nil
            }
            
            popover.purpose = .selectingSorting
            popover.section.strings = Constants.SortingTitles
            popover.stringSelected = Globals.shared.sorting?.translate

            present(navigationController, animated: true, completion: nil)
        }
    }

    fileprivate func setupShowMenu()
    {
        let showButton = navigationItem.leftBarButtonItem
        
        showButton?.title = Constants.FA.REORDER
        showButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)

        showButton?.isEnabled = (Globals.shared.media.all != nil)
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Strings.Menu.Sorting, style: UIBarButtonItem.Style.plain, target: self, action: #selector(sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Strings.Menu.Grouping, style: UIBarButtonItem.Style.plain, target: self, action: #selector(grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItem.Style.plain, target: self, action: #selector(index(_:)))

        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        barButtons.append(sortingButton)
        barButtons.append(spaceButton)
        barButtons.append(groupingButton)
        barButtons.append(spaceButton)
        barButtons.append(indexButton)
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.isTranslucent = false
        
        barButtons.forEach { (button:UIBarButtonItem) in
            button.isEnabled = Globals.shared.media.active?.mediaList?.list == nil
        }
        
        setToolbarItems(barButtons, animated: true)
    }

    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MTVC:Operations" + UUID().uuidString
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1 // Slides and Notes
        return operationQueue
    }()
    
    var searching : Bool
    {
        get {
            return operationQueue.operationCount > 0
        }
    }
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        Globals.shared.isLoading = true
        
        operationQueue.cancelAllOperations()
        
//        let operation = CancelableOperation { [weak self] (test:(()->Bool)?) in
        operationQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            self?.setupSearchBar()

            self?.setupBarButtons()
            
            self?.setupListActivityIndicator()

            Thread.onMain {
                self?.navigationItem.title = Constants.Title.Loading_Media
            }
            
            if let jsonSource = self?.jsonSource {
                switch jsonSource {
                case .download:
                    // From Caches Directory
                    if let categoryDicts = Globals.shared.media.json.load(filename: Constants.JSON.FILENAME.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES) {
                        
                        for categoryDict in categoryDicts {
                            if let name = categoryDict["category_name"] as? String {
                                Globals.shared.media.categories[name] = Category(categoryDict)
                            }
                        }
                    }
                    
                    if let groupDicts = Globals.shared.media.json.load(filename: Constants.JSON.FILENAME.CATEGORIES,key:Constants.JSON.ARRAY_KEY.GROUP_ENTRIES) {
                        
                        for groupDict in groupDicts {
                            if let name = groupDict["name"] as? String {
                                Globals.shared.media.groups[name] = Group(groupDict) // name:name,title:teachersDict["status"]
                            }
                        }
                    }
                    
                    if let teacherDicts = Globals.shared.media.json.load(filename: Constants.JSON.FILENAME.TEACHERS,key:Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES) {
                        
                        for teacherDict in teacherDicts {
                            if let name = teacherDict["name"] as? String {
                                Globals.shared.media.teachers[name] = Teacher(teacherDict) // name:name,title:teachersDict["status"]
                            }
                        }
                    }
                    
                    if  let mediaItemDicts = Globals.shared.media.json.load(filename:Globals.shared.media.json.filename,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                        Globals.shared.media.repository.list = mediaItemDicts.map({ (mediaItemDict:[String : Any]) -> MediaItem in
                            return MediaItem(storage: mediaItemDict)
                        })
                    } else {
                        Globals.shared.media.repository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                    
                case .direct:
                    Globals.shared.media.json.load(urlString: Constants.JSON.URL.GROUPS, key:Constants.JSON.ARRAY_KEY.GROUP_ENTRIES, filename: Constants.JSON.FILENAME.GROUPS)?.forEach({ (dict:[String : Any]) in
                        if let name = dict["name"] as? String {
                            Globals.shared.media.groups[name] = Group(dict)
                        }
                    })
                    
                    Globals.shared.media.json.load(urlString: Constants.JSON.URL.TEACHERS, key:Constants.JSON.ARRAY_KEY.TEACHER_ENTRIES, filename: Constants.JSON.FILENAME.TEACHERS)?.forEach({ (dict:[String : Any]) in
                        if let name = dict["name"] as? String {
                            Globals.shared.media.teachers[name] = Teacher(dict)
                        }
                    })
                    
                    Globals.shared.media.json.load(urlString: Constants.JSON.URL.CATEGORIES, key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES, filename: Constants.JSON.FILENAME.CATEGORIES)?.forEach({ (dict:[String : Any]) in
                        var key = ""
                        
                        if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_OLD {
                            key = "category_name"
                        }
                        
                        if Constants.JSON.URL.CATEGORIES == Constants.JSON.URL.CATEGORIES_NEW {
                            key = "name"
                        }
                        
                        if let name = dict[key] as? String {
                            Globals.shared.media.categories[name] = Category(dict)
                        }
                    })
                    
                    if  let url = Globals.shared.media.json.url,
                        let filename = Globals.shared.media.json.filename,
                        let json = Globals.shared.media.json.get(urlString: url, filename: filename) as? [String:Any],
                        let mediaItemDicts = json[Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES] as? [[String:Any]] {
                        Globals.shared.media.metadata = json[Constants.JSON.ARRAY_KEY.META_DATA] as? [String:Any]
                        
                        Globals.shared.media.repository.list = mediaItemDicts.filter({ (dict:[String : Any]) -> Bool in
                            return (dict["published"] as? Bool) != false
                        }).map({ (mediaItemDict:[String : Any]) -> MediaItem in
                            return MediaItem(storage: mediaItemDict)
                        })
                    } else {
                        Globals.shared.media.repository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                }
            }

            Thread.onMain {
                self?.navigationItem.title = Constants.Title.Loading_Settings
            }
            Globals.shared.loadSettings()
            
            Thread.onMain {
                self?.navigationItem.title = Constants.Title.Sorting_and_Grouping
            }
            
            if Globals.shared.media.category.selected == Constants.Strings.All {
                Globals.shared.media.all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: Globals.shared.media.repository.list)
            } else {
                Globals.shared.media.all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                    mediaItem.category == Globals.shared.media.category.selected
                }))
            }
            
            if Globals.shared.media.tags.showing == Constants.TAGGED, let tag = Globals.shared.media.category.tag, Globals.shared.media.tagged[tag] == nil {
                if Globals.shared.media.all == nil {
                    //This is filtering, i.e. searching all mediaItems => s/b in background
                    Globals.shared.media.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                        return mediaItem.category == Globals.shared.media.category.selected
                    }).withTag(tag: Globals.shared.media.tags.selected))
                } else {
                    if let sortTag = Globals.shared.media.tags.selected?.withoutPrefixes {
                        Globals.shared.media.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[sortTag])
                    }
                }
            }            

            if Globals.shared.media.search.isValid {
                Thread.onMain {
                    self?.searchBar.text = Globals.shared.media.search.text
                    self?.searchBar.showsCancelButton = true
                }

                Globals.shared.media.search.current?.complete = false
            }

            self?.display.setup(Globals.shared.media.active)
            
            Thread.onMain {
                self?.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (Globals.shared.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    Globals.shared.mediaPlayer.setup(Globals.shared.mediaPlayer.mediaItem,playOnLoad:false)
                }

                self?.navigationItem.title = Constants.CBC.TITLE.SHORT
                
                if let isCollapsed = self?.splitViewController?.isCollapsed, !isCollapsed {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
                }
                
                Globals.shared.isLoading = false
                
                completion?()

                self?.updateUI()
            }
        }
        
//        operationQueue.addOperation(operation)
    }
    
    func setupCategoryButton()
    {
        Thread.onMain {
            self.mediaCategoryButton.setTitle(Globals.shared.media.category.selected)

            if Globals.shared.isLoading || Globals.shared.isRefreshing {
                self.mediaCategoryButton.isEnabled = false
            } else {
                if !Globals.shared.media.search.isActive {
                    self.mediaCategoryButton.isEnabled = true
                } else {
                    self.mediaCategoryButton.isEnabled = Globals.shared.media.search.current?.complete ?? false
                }
            }
        }
    }
    
    func setupShowButton()
    {
        Thread.onMain {
            if Globals.shared.isLoading || Globals.shared.isRefreshing {
                self.navigationItem.leftBarButtonItem?.isEnabled = false
            } else {
                if !Globals.shared.media.search.isActive {
                    self.navigationItem.leftBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.leftBarButtonItem?.isEnabled = Globals.shared.media.search.current?.complete ?? false
                }
            }
        }
    }
    
    func setupToolbarButtons()
    {
        Thread.onMain {
            if Globals.shared.isLoading || Globals.shared.isRefreshing {
                self.toolbarItems?.forEach({ (button:UIBarButtonItem) in
                    button.isEnabled = Globals.shared.media.active?.mediaList?.list != nil
                })
            } else {
                if !Globals.shared.media.search.isActive {
                    self.toolbarItems?.forEach({ (button:UIBarButtonItem) in
                        button.isEnabled = Globals.shared.media.active?.mediaList?.list != nil
                    })
                } else {
                    self.toolbarItems?.forEach({ (button:UIBarButtonItem) in
                        button.isEnabled = (Globals.shared.media.search.current?.complete ?? false) && (self.display.mediaItems != nil)
                    })
                }
            }
        }
    }
    
    func setupBarButtons()
    {
        setupActionAndTagsButtons()
        setupCategoryButton()
        setupToolbarButtons()
        setupShowButton()
    }
    
    func setupListActivityIndicator(allowTouches:Bool = false)
    {
        if Globals.shared.isLoading || (Globals.shared.media.search.isValid && ((Globals.shared.media.search.current?.complete ?? false) == false)) {
            if !Globals.shared.isRefreshing {
                Thread.onMain {
                    self.startAnimating(allowTouches:allowTouches)
                }
            } else {
                Thread.onMain {
                    self.stopAnimating()
                }
            }
        } else {
            Thread.onMain {
                self.stopAnimating()
            }
        }
    }
    
    func downloadJSON(url:String?,filename:String?)
    {
        guard let urlString = url else {
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        guard filename != nil else {
            return
        }
        
        navigationItem.title = Constants.Title.Downloading_Media
        
        let downloadRequest = URLRequest(url: url)
        
        let configuration = URLSessionConfiguration.default
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTask(with: downloadRequest)
        downloadTask?.taskDescription = filename
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func setupSearchBar()
    {
        Thread.onMain {
            self.searchBar.resignFirstResponder()
            self.searchBar.placeholder = nil
            self.searchBar.text = nil
            self.searchBar.showsCancelButton = false
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl)
    {
//        print("1:",Date().timeIntervalSinceReferenceDate,refreshControl.isRefreshing,Globals.shared.isRefreshing)
        
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:handleRefresh", completion: nil)
            return
        }
        
        guard !Globals.shared.isRefreshing else {
            return
        }
        
//        print("2:",Date().timeIntervalSinceReferenceDate,refreshControl.isRefreshing,Globals.shared.isRefreshing)
        
        Globals.shared.isRefreshing = true
        
        self.yesOrNo(title: "Reload Media List?", message: nil,
                yesAction: { () -> (Void) in
                    self.setupListActivityIndicator()
                    
                    Globals.shared.mediaPlayer.unobserve()
                    
                    Globals.shared.mediaPlayer.pause() // IfPlaying
                    
                    Globals.shared.media.repository.cancelAllDownloads()
                    
                    self.display.clear()
                    
                    if Globals.shared.media.search.isActive {
                        self.operationQueue.cancelAllOperations()
                    }
                    
                    Globals.shared.media.search.isActive = false
                    
                    self.setupSearchBar()
                    
                    self.tableView?.reloadData()
                    
                    // tableView can't be hidden or refresh spinner won't show.
                    if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
                        self.logo.isHidden = false // Don't like it offset, just hide it for now
                    }
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
                    
                    self.setupBarButtons()
                    
                    // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
                    Globals.shared.media = Media()

                    switch self.jsonSource {
                    case .download:
                        self.navigationItem.title = "Downloading Media List"
                        let categoriesFileName = Constants.JSON.FILENAME.CATEGORIES
                        self.downloadJSON(url:Constants.JSON.URL.CATEGORIES,filename:categoriesFileName)
                        break
                        
                    case .direct:
                        self.loadMediaItems()
                        {
                            self.loadCompletion()
                        }
                        break
                    }
                }, yesStyle: .destructive, noAction: { () -> (Void) in
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    }
                    Globals.shared.isRefreshing = false
                }, noStyle: .default)
    }

    @objc func updateList()
    {
        updateSearch()
        
        display.setup(Globals.shared.media.active)

        updateUI()
        
        tableView?.reloadData()
    }
    
    func loadCompletion()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            return
        }
        
        if Globals.shared.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        }
        
        if Globals.shared.media.repository.list == nil {
            if Globals.shared.isRefreshing {
                self.refreshControl?.endRefreshing()
                Globals.shared.isRefreshing = false
            }

            self.alert(title: "No Media Available",message: "Please check your network connection and try again.")
        } else {
            if Globals.shared.isRefreshing {
                self.refreshControl?.endRefreshing()
                self.tableView?.setContentOffset(CGPoint(x:self.tableView.frame.origin.x, y:self.tableView.frame.origin.y - 44), animated: false)
                Globals.shared.isRefreshing = false
            }
            
            self.selectedMediaItem = Globals.shared.media.selected.master
            
            if Globals.shared.media.search.isValid, ((Globals.shared.media.search.current?.complete ?? false) == false) {
                self.updateSearchResults(Globals.shared.media.active?.context,completion: {
                    // Delay so UI works correctly.
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        Thread.onMain {
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.top)
                        }
                    }
                })
            } else {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    Thread.onMain {
                        // Reload the table
                        self?.tableView?.reloadData()
                        
                        if self?.selectedMediaItem != nil {
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.middle)
                        } else {
                            let indexPath = IndexPath(row:0,section:0)
                            if self?.tableView?.isValid(indexPath) == true {
                                self?.tableView?.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
                            }
                        }
                    }
                }
            }
        }
        
        self.setupTitle()
        self.tableView?.isHidden = false
        self.logo.isHidden = true
        
        // Navigate to a mediaitem pass in a URL.
        if let goto = Globals.shared.media.goto {
            navigationController?.popToRootViewController(animated: false)
            Globals.shared.media.goto = nil
            
            if let mediaItem = Globals.shared.media.repository.index[goto] {
                Globals.shared.media.selected.master = mediaItem
                selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: .top)
               
                // Delay required for iPhone
                // Delay so UI works correctly.
                DispatchQueue.global(qos: .background).async {
                    Thread.onMain {
                        self.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    }
                }
            }
        }
    }

    func load()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:load", completion: nil)
            return
        }
        
        guard !Globals.shared.isLoading else {
            return
        }
        
        guard Globals.shared.media.repository.list == nil else {
            return
        }
        
        tableView?.isHidden = true
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = true
        }
        
        // Download or Load
        
        switch jsonSource {
        case .download:
            Globals.shared.isLoading = true
            
            setupSearchBar()

            setupBarButtons()
            
            setupListActivityIndicator()
            
            navigationItem.title = "Downloading Media List"
            
            let categoriesFileName = Constants.JSON.FILENAME.CATEGORIES
            downloadJSON(url:Constants.JSON.URL.CATEGORIES,filename:categoriesFileName)
            break
            
        case .direct:
            loadMediaItems()
            {
                self.loadCompletion()
            }
            break
        }
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playingPaused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING_PAUSED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lastSegue), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_LAST_SEGUE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView?.estimatedRowHeight = tableView?.rowHeight
//        tableView?.rowHeight = UITableViewAutomaticDimension
    }

    var audioDownloads : Int?
    {
        get {
            return Globals.shared.media.active?.mediaList?.audioDownloads
        }
    }
    
    var audioDownloaded : Int?
    {
        get {
            return Globals.shared.media.active?.mediaList?.audioDownloaded
        }
    }
    
    var slidesDownloads : Int?
    {
        get {
            return Globals.shared.media.active?.mediaList?.slidesDownloads
        }
    }
    
    var notesDownloads : Int?
    {
        get {
            return Globals.shared.media.active?.mediaList?.notesDownloads
        }
    }
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        if Globals.shared.media.active?.mediaList?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    @objc func actions()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:actions", completion: nil)
            return
        }
        
        //In case we have one already showing
        popover?.values.forEach({ (popover:PopoverTableViewController) in
            popover.dismiss(animated: true, completion: nil)
        })

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            popover.section.strings = actionMenu()

            self.popover?["ACTION"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["ACTION"] = nil
            }
            
            present(navigationController, animated: true, completion:  nil)
        }
    }

    var tagsButton : UIBarButtonItem?
    var actionButton : UIBarButtonItem?
    
    func tagsMenu() -> [String]?
    {
        var strings = [Constants.Strings.All]
        
        if let mediaItemTags = Globals.shared.media.active?.mediaItemTags {
            strings.append(contentsOf: mediaItemTags)
        }
        
        return strings.count > 0 ? strings.sorted(by: {
            return $0.withoutPrefixes < $1.withoutPrefixes
        }) : nil
    }
    
    func setupActionAndTagsButtons()
    {
        guard !Globals.shared.isLoading && !Globals.shared.isRefreshing else {
            Thread.onMain {
                self.navigationItem.rightBarButtonItems = nil
            }
            return
        }
        
        var barButtons = [UIBarButtonItem]()
        
        if actionButton == nil {
            actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItem.Style.plain, target: self, action: #selector(actions))
            actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show)
        }

        if actionMenu()?.count > 0, let actionButton = actionButton {
            if Globals.shared.isLoading || Globals.shared.isRefreshing {
                actionButton.isEnabled = false
            } else {
                if !Globals.shared.media.search.isActive {
                    actionButton.isEnabled = true
                } else {
                    actionButton.isEnabled = !searching && ((Globals.shared.media.search.current?.complete == true) || (Globals.shared.media.search.current?.cancelled == true))
                }
            }
            barButtons.append(actionButton)
        }

        if tagsButton == nil {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItem.Style.plain, target: self, action: #selector(selectingTagsAction(_:)))
            tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags)
        }

        let tagsMenu = self.tagsMenu()
        
        if (tagsMenu?.count > 1) {
            tagsButton?.title = Constants.FA.TAGS
        } else {
            tagsButton?.title = Constants.FA.TAG
        }

        if tagsMenu?.count > 0, let tagsButton = tagsButton {
            if Globals.shared.isLoading || Globals.shared.isRefreshing {
                tagsButton.isEnabled = false
            } else {
                if !Globals.shared.media.search.isActive {
                    tagsButton.isEnabled = true
                } else {
                    tagsButton.isEnabled = !searching && ((Globals.shared.media.search.current?.complete == true) || (Globals.shared.media.search.current?.cancelled == true))
                }
            }
            barButtons.append(tagsButton)
        }
        
        Thread.onMain {
            if barButtons.count > 0 {
                self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
            } else {
                self.navigationItem.rightBarButtonItems = nil
            }
        }
    }
    
    var localModalPresentationStyle : UIModalPresentationStyle
    {
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            let hClass = traitCollection.horizontalSizeClass
            
            if hClass == .compact {
                return .overCurrentContext
            } else {
                // I don't think this ever happens: collapsed and regular
                return .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
            }
        } else {
            return .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
        }
    }
    
    @IBAction func selectingTagsAction(_ sender: UIButton)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:selectingTagsAction", completion: nil)
            return
        }

        guard !Globals.shared.isLoading else {
            return
        }
        
        guard !Globals.shared.isRefreshing else {
            return
        }

        //In case we have one already showing
        self.popover?.values.forEach({ (popover:PopoverTableViewController) in
            popover.dismiss(animated: true, completion: nil)
        })

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = localModalPresentationStyle

            navigationController.popoverPresentationController?.delegate = self

            if navigationController.modalPresentationStyle == .popover {
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = tagsButton
            }

            popover.navigationItem.title = Constants.Strings.Show
            
            popover.delegate = self
            popover.purpose = .selectingTags
            
            popover.stringSelected = Globals.shared.media.tags.selected ?? Constants.Strings.All
            
            popover.section.showIndex = true
            popover.indexStringsTransform = { (string:String?) -> String? in
                return string?.withoutPrefixes
            }

            popover.section.strings = tagsMenu()
            
            popover.search = popover.section.strings?.count > 10

            self.popover?["TAGS"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["TAGS"] = nil
            }
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func updateDisplay(context:String?)
    {
        guard let context = context else {
            return
        }
        
        // s/b equal or not equal?
        if (Globals.shared.media.active?.context == context) {
            display.setup(Globals.shared.media.active)
            
            Thread.onMain {
                if !self.tableView.isEditing {
                    self.tableView.reloadData()
                } else {
                    self.changesPending = true
                }
            }
        }
    }

    func updateSearchResults(_ context:String?,completion: (() -> Void)?)
    {
        guard let context = context else {
            return
        }
        
        guard !context.isEmpty else {
            return
        }
        
        if let search = Globals.shared.media.search.searches?[context], search.cancelled == false {
            updateDisplay(context:context)
            setupListActivityIndicator()
            
            setupBarButtons()
            
            return
        }
        
        var abort = false
        var cancel = false

        func shouldAbort() -> Bool
        {
            return !Globals.shared.media.search.isValid || (Globals.shared.media.active?.context != context)
        }
        
        // toSearch? // searchText
        Globals.shared.media.search.searches?[context]?.complete = false

        display.clear()

        Thread.onMain {
            self.tableView?.reloadData()
        }
        
        operationQueue.cancelAllOperations()
        
//        let op = CancelableOperation { [weak self] (test:(()->Bool)?) in
        operationQueue.addCancelableOperation { [weak self] (test:(() -> Bool)?) in
            Thread.onMainSync {
                _ = self?.loadingButton
            }
            
            var searchMediaItems:[MediaItem]?
            
            defer {
                if let searchText = Globals.shared.media.active?.context?.searchText {
                    if context.searchText == searchText {
                        Globals.shared.media.search.searches?[context] = MediaListGroupSort(mediaItems: searchMediaItems)
                    } else {
                        if let contextSearchText = context.searchText, let range = searchText.range(of: contextSearchText), range.lowerBound == searchText.startIndex, range.upperBound <= searchText.endIndex, Globals.shared.media.search.searches?[context]?.complete == false {
                            // delete incremental searches
                            Globals.shared.media.search.searches?[context] = nil
                        }
                    }
                }

                if abort {
                    cancel = true
                } else {
                    self?.updateDisplay(context:context)
                }
                
                completion?()
                
                Globals.shared.media.search.searches?[context]?.complete = true
                Globals.shared.media.search.searches?[context]?.cancelled = cancel
                
                self?.setupListActivityIndicator()
                
                self?.setupBarButtons()
                
//                Thread.onMain {
//                }
            }
            
            Thread.onMainSync {
                if self?.loadingButton?.tag == 1 {
                    cancel = true
                }
            }

            if cancel {
                return
            }
            
            if let mediaItems = Globals.shared.media.toSearch?.mediaList?.list {
                for mediaItem in mediaItems {
                    Thread.onMainSync {
                        if self?.loadingButton?.tag == 1 {
                            cancel = true
                        }
                    }

                    if cancel {
                        return
                    }

                    // toSearch? // searchText
                    Globals.shared.media.search.searches?[context]?.complete = false
                    
                    self?.setupListActivityIndicator(allowTouches:true)
                    
                    let searchHit = mediaItem.search(context.searchText)
                    
                    abort = abort || shouldAbort() || (test?() ?? false)
                    
                    if abort {
                        break
                    } else {
                        if searchHit {
                            autoreleasepool {
                                if searchMediaItems == nil {
                                    searchMediaItems = [mediaItem]
                                } else {
                                    searchMediaItems?.append(mediaItem)
                                }
                                
                                if let count = searchMediaItems?.count, ((count % Constants.SEARCH_RESULTS_BETWEEN_UPDATES) == 0) {
                                    Globals.shared.media.search.searches?[context] = MediaListGroupSort(mediaItems: searchMediaItems)
                                    self?.updateDisplay(context:context)
                                }
                            }
                        }
                    }
                }
                
                if !abort {
                    Globals.shared.media.search.searches?[context] = MediaListGroupSort(mediaItems: searchMediaItems)
                    self?.updateDisplay(context:context)
                }
                
                if !abort, Globals.shared.media.search.transcripts, let mediaItems = Globals.shared.media.toSearch?.mediaList?.list {
                    // toSearch?
                    Globals.shared.media.search.searches?[context]?.complete = false
                    
                    self?.setupListActivityIndicator(allowTouches:true)
                    
                    for mediaItem in mediaItems {
                        var searchHit = false
                        
                        autoreleasepool {
                            searchHit = mediaItem.searchNotes(context.searchText)
                        }

                        abort = abort || shouldAbort() || (test?() ?? false) || !Globals.shared.media.search.transcripts
                        
                        Thread.onMainSync {
                            if self?.loadingButton?.tag == 1 {
                                cancel = true
                            }
                        }
                        
                        if cancel {
                            return
                        }
                        
                        if abort {
                            break
                        } else {
                            if searchHit {
                                autoreleasepool {
                                    if searchMediaItems == nil {
                                        searchMediaItems = [mediaItem]
                                    } else
                                        
                                        if let contains = searchMediaItems?.contains(mediaItem), !contains {
                                            searchMediaItems?.append(mediaItem)
                                    }

                                    Globals.shared.media.search.searches?[context] = MediaListGroupSort(mediaItems: searchMediaItems)
                                    self?.updateDisplay(context:context)
                                }
                            }
                        }
                    }
                }
            }
            
            // Final search update since we're only doing them in batches of Constants.SEARCH_RESULTS_BETWEEN_UPDATES
            
            abort = abort || shouldAbort()
        }
//        operationQueue.addOperation(op)

        self.setupBarButtons()
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableView.ScrollPosition)
    {
        guard !tableView.isEditing else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let grouping = Globals.shared.grouping else {
            return
        }
        
        guard let indexStrings = Globals.shared.media.active?.section?.indexStrings else {
            return
        }
        
        guard let mediaItems = Globals.shared.media.active?.section?.mediaItems else {
            return
        }
        
        guard let index = mediaItems.firstIndex(of: mediaItem) else {
            print("No index")
            return
        }

//        print("index")

        var indexPath = IndexPath(item: 0, section: 0)
        
        var section:Int = -1
        var row:Int = -1
        
        var sectionIndex : String?
        
        switch grouping {
        case GROUPING.YEAR:
            sectionIndex = mediaItem.yearSection
            break
            
        case GROUPING.TITLE:
            sectionIndex = mediaItem.multiPartSectionSort
            break
            
        case GROUPING.BOOK:
            // For mediaItem.books.count > 1 this arbitrarily selects the first one, which may not be correct.
            sectionIndex = mediaItem.bookSections.first
            break
            
        case GROUPING.SPEAKER:
            sectionIndex = mediaItem.speakerSectionSort
            break
            
        case GROUPING.CLASS:
            sectionIndex = mediaItem.classSectionSort
            break
            
        case GROUPING.EVENT:
            sectionIndex = mediaItem.eventSectionSort
            break
            
        default:
            break
        }
        
        if let sectionIndex = sectionIndex, let stringIndex = indexStrings.firstIndex(of: sectionIndex) {
            section = stringIndex
        }
        
        if let sectionIndexes = Globals.shared.media.active?.section?.indexes {
            row = index - sectionIndexes[section]
        }
        
        guard (section >= 0) && (row >= 0) else {
            return
        }
        
        indexPath = IndexPath(row: row,section: section)
        
        guard indexPath.section >= 0, (indexPath.section < tableView.numberOfSections) else {
            NSLog("indexPath section ERROR in selectOrScrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            return
        }
        
        guard indexPath.row >= 0, indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
            NSLog("indexPath row ERROR in selectOrScrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            NSLog("Row: \(indexPath.row)")
            NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
            return
        }
        
        Thread.onMain {
            self.tableView?.setEditing(false, animated: true)

            guard self.tableView?.isValid(indexPath) == true else {
                return
            }

            if (select) {
                self.tableView?.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
            }

            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                self.tableView?.scrollToRow(at: indexPath, at: position, animated: false)
            }
        }
    }
    
    func setupTag()
    {
        guard let showing = Globals.shared.media.tags.showing else {
            return
        }
        
        Thread.onMain {
            switch showing {
            case Constants.ALL:
                self.tagLabel.text = Constants.Strings.All // searchBar.placeholder
                break
                
            case Constants.TAGGED:
                self.tagLabel.text = Globals.shared.media.tags.selected // searchBar.placeholder
                break
                
            default:
                break
            }
        }
    }

    func setupTitle()
    {
        guard !Globals.shared.isLoading, !Globals.shared.isRefreshing else {
            return
        }
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            switch traitCollection.horizontalSizeClass {
            case .regular:
                navigationItem.title = Constants.CBC.TITLE.LONG
                break
                
            case .compact:
                navigationItem.title = Constants.CBC.TITLE.SHORT
                break
                
            default:
                navigationItem.title = Constants.CBC.TITLE.SHORT
                break
            }
            break
            
        case .phone:
            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                if (UIDevice.current.orientation.isLandscape) {
                    if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
                        navigationItem.title = Constants.CBC.TITLE.SHORT
                    } else {
                        navigationItem.title = Constants.CBC.TITLE.LONG
                    }
                } else {
                    navigationItem.title = Constants.CBC.TITLE.SHORT
                }
            } else {
                navigationItem.title = Constants.CBC.TITLE.SHORT
            }
            break
            
        default:
            navigationItem.title = Constants.CBC.TITLE.SHORT
            break
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDevice.current.orientation.isPortrait) {
            if (Globals.shared.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if let count = splitViewController?.viewControllers.count, count > 1 {
                    if let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = .automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if let count = splitViewController?.viewControllers.count, count > 1 {
                if let nvc = splitViewController?.viewControllers[count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = .primaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = .automatic //iPad only
                    }
                }
            }
        }
    }
    
    @objc func updateSearch()
    {
        guard Globals.shared.media.search.isValid else {
            return
        }
        
        updateSearchResults(Globals.shared.media.active?.context,completion: nil)
    }
    
    @objc func liveView()
    {
        popover?["LIVE"]?.dismiss(animated: true, completion: nil)

        performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: nil)
    }
    
    @objc func playingPaused()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: Globals.shared.mediaPlayer.mediaItem ?? Globals.shared.media.selected.detail)
    }
    
    @objc func lastSegue()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: Globals.shared.media.selected.detail)
    }
    
    @objc func deviceOrientationDidChange()
    {

    }

    @objc func stopEditing()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:stopEditing", completion: nil)
            return
        }
        
        tableView.isEditing = false
    }
    
    @objc func willEnterForeground()
    {
        
    }
    
    @objc func didBecomeActive()
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:didBecomeActive", completion: nil)
            return
        }
        
        guard !Globals.shared.isLoading, Globals.shared.media.repository.list == nil else {
            return
        }
        
        tableView.isHidden = true
        
        loadMediaItems()
        {
            self.loadCompletion()
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        searchBar.showsSearchResultsButton = true
        
        setupSortingAndGroupingOptions()
        setupShowMenu()

        updateUI()
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: nil)
    }
    
    func updateUI()
    {
        guard self.isViewLoaded else {
            return
        }
        
        if navigationController?.visibleViewController == self {
            navigationController?.isToolbarHidden = false
        }

        setupTag()
        setupTitle()

        setupBarButtons()
        
        setupListActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        var show:Bool
        
        show = true

        switch identifier {
            case Constants.SEGUE.SHOW_ABOUT:
                break

            case Constants.SEGUE.SHOW_MEDIAITEM:
                break
            
            default:
                break
        }
        
        return show
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            dvc = visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_SETTINGS:
                if let svc = dvc as? SettingsViewController {
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.SEGUE.SHOW_LIVE:
                Globals.shared.mediaPlayer.killPIP = true
                
                if sender != nil {
                    (dvc as? LiveViewController)?.streamEntry = sender as? StreamEntry
                } else {
                    if let streamEntry = StreamEntry(UserDefaults.standard.object(forKey: Constants.SETTINGS.LIVE) as? [String:Any]) {
                        (dvc as? LiveViewController)?.streamEntry = streamEntry
                    }
                }
                break
                
            case Constants.SEGUE.SHOW_SCRIPTURE_INDEX:
                (dvc as? ScriptureIndexViewController)?.mediaListGroupSort = Globals.shared.media.active
                break
                
            case Constants.SEGUE.SHOW_LEXICON_INDEX:
                (dvc as? LexiconIndexViewController)?.mediaListGroupSort = Globals.shared.media.active
                break
                
            case Constants.SEGUE.SHOW_ABOUT2:
                break
                
            case Constants.SEGUE.SHOW_MEDIAITEM:
                if Globals.shared.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM) && (Globals.shared.mediaPlayer.pip == .stopped) {
                    Globals.shared.mediaPlayer.pause() // DO NOT USE STOP HERE AS STOP SETS Globals.shared.mediaPlayer.mediaItem (used below) to nil
                    Globals.shared.mediaPlayer.playOnLoad = false
                }
                
                if let myCell = sender as? MediaTableViewCell {
                    selectedMediaItem = myCell.mediaItem
                    
                    if selectedMediaItem != nil {
                        if let destination = dvc as? MediaViewController {
                            destination.selectedMediaItem = selectedMediaItem
                        }
                    }
                }
                
                if let mediaItem = sender as? MediaItem {
                    if let destination = dvc as? MediaViewController {
                        destination.selectedMediaItem = mediaItem
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

        let popover = self.popover?["SHOW"]
            
        popover?.dismiss(animated: false, completion: nil)
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { [weak self] (UIViewControllerTransitionCoordinatorContext) -> Void in
            self?.setupTitle()
            if popover != nil, let showButton = self?.showButton {
                self?.show(showButton)
            }
        }
    }
    
    // MARK: PopoverTableViewControllerDelegate
    override func tableViewRowActions(popover: PopoverTableViewController, tableView: UITableView, indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var actions = super.tableViewRowActions(popover: popover, tableView: tableView, indexPath: indexPath) ?? [UITableViewRowAction]()
        
        guard let purpose = popover.purpose else {
            return actions.count > 0 ? actions : nil
        }
        
        switch purpose {
        case .showingVoiceBaseMediaItems:
            // We return row alert actions, not more general tableview row actions.
            break
            
        case .selectingSearch:
            actions.append(UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction:UITableViewRowAction, indexPath:IndexPath) in
                if let search = popover.section.strings?[indexPath.row] {
                    if let keys = Globals.shared.media.search.searches?.keys() {
                        for key in keys {
                            if key.searchText == search {
                                Globals.shared.media.search.searches?[key] = nil
                                break
                            }
                        }
                    }
                    popover.section.strings?.remove(at: indexPath.row)
                    popover.setPreferredContentSize()
                    popover.tableView.reloadData()
                    if popover.section.strings?.count == 0 {
                        popover.navigationItem.leftBarButtonItem?.isEnabled = false
                    }
                }
            })
            break
            
        default:
            break
        }
        
        return actions.count > 0 ? actions : nil
    }
    
    func voiceBaseMediaRowAlertActions(popover:PopoverTableViewController, tableView:UITableView, indexPath:IndexPath) -> [AlertAction]?
    {
        var actions = [AlertAction]()
        
        var searchIndex:StringIndex?
        
        if popover.searchActive {
            searchIndex = StringIndex()
            
            if let text = popover.searchText {
                if let keys = self.stringIndex?.keys {
                    for key in keys {
                        if let values = self.stringIndex?[key] {
                            for value in values {
                                if (value["title"] as? String)?.replacingOccurrences(of: Constants.UNBREAKABLE_SPACE,with: " ").range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil {
                                    if searchIndex?[key] == nil {
                                        searchIndex?[key] = [[String:Any]]()
                                    }
                                    searchIndex?[key]?.append(value)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            searchIndex = self.stringIndex
        }
        
        guard let keys = searchIndex?.keys?.sorted(), indexPath.section >= 0, indexPath.section < keys.count else {
            return nil
        }
        
        let key = keys[indexPath.section]
        
        guard let values = searchIndex?[key] else {
            return nil
        }
        
        guard indexPath.row >= 0, indexPath.row < values.count else {
            return nil
        }
        
        let value = values[indexPath.row]
        
        if let mediaID = value["mediaId"] as? String,let title = value["title"] as? String {
            actions.append(AlertAction(title: Constants.Strings.Delete, style: .destructive) { [weak self, weak popover] in
                var alertActions = [AlertAction]()
                alertActions.append(AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: { () -> (Void) in
                    VoiceBase.delete(alert:true,mediaID: mediaID)
                    
                    searchIndex?[key]?.remove(at: indexPath.row)
                    
                    if searchIndex?[key]?.count == 0 {
                        searchIndex?[key] = nil
                    }
                    
                    if searchIndex != self?.stringIndex, let keys = self?.stringIndex?.keys?.sorted() {
                        for key in keys {
                            if let values = self?.stringIndex?[key] {
                                var count = 0
                                
                                for value in values {
                                    if (value["mediaId"] as? String) == mediaID {
                                        self?.stringIndex?[key]?.remove(at: count)
                                        
                                        if self?.stringIndex?[key]?.count == 0 {
                                            self?.stringIndex?[key] = nil
                                        }
                                        
                                        break
                                    }
                                    
                                    count += 1
                                }
                            }
                        }
                    }
                    
                    popover?.section.stringIndex = searchIndex?.stringIndex(key: "title", sort: nil) //.keys.count > 0 ? stringIndex : nil
                    
                    popover?.updateToolbar()
                    
                    Thread.onMain {
                        popover?.tableView?.isEditing = false
                        popover?.tableView?.reloadData()
                        popover?.tableView?.reloadData()
                    }
                }))
                alertActions.append(AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: nil))
                Alerts.shared.alert(title: "Confirm Removal From VoiceBase", message: title, actions: alertActions)
            })
            
            actions.append(AlertAction(title: "Media ID", style: .default) { [weak self] in
                var alertItems = [AlertItem]()
                alertItems.append(AlertItem.text(mediaID))
                alertItems.append(AlertItem.action(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil)))
                Alerts.shared.alert(title: "VoiceBase Media ID", message: title, items: alertItems)
            })
            
            actions.append(AlertAction(title: "Information", style: .default) { [weak self] in
                self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = false
                self?.popover?["VOICEBASE"]?.activityIndicator.startAnimating()
                
                VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                    if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? WebViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        popover.navigationItem.title = "Information" // self?.popover?.navigationItem.title // "VoiceBase Media Item"
                        
                        popover.html.fontSize = 12
                        popover.html.string = VoiceBase.html(json)?.insertHead(fontSize: popover.html.fontSize)
                        
                        popover.search = true
                        popover.content = .html
                        
                        Thread.onMain {
                            self?.popover?["VOICEBASE"]?.activityIndicator.stopAnimating()
                            self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = true
                            
                            self?.popover?["VOICEBASE"]?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                    }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                        self?.popover?["VOICEBASE"]?.activityIndicator.stopAnimating()
                        self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = true
                        
                        Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                })
            })
            
            actions.append(AlertAction(title: "Inspector", style: .default) { [weak self] in
                self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = false
                self?.popover?["VOICEBASE"]?.activityIndicator.startAnimating()
                
                VoiceBase.details(mediaID: mediaID, completion: { [weak self] (json:[String : Any]?) -> (Void) in
                    print(json as Any)
                    if let navigationController = self?.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .overCurrentContext
                        
                        popover.search = true
                        popover.stringsAny = json
                        popover.purpose = .showingVoiceBaseMediaItem
                        popover.navigationItem.title = "Inspector"
                        
                        Thread.onMain {
                            self?.popover?["VOICEBASE"]?.activityIndicator.stopAnimating()
                            self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = true
                            
                            // Present works reliably for subsequent pushes. Push DOES NOT I HAVE NO IDEA WHY
                            self?.popover?["VOICEBASE"]?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                    }, onError: { [weak self] (json:[String : Any]?) -> (Void) in
                        self?.popover?["VOICEBASE"]?.activityIndicator.stopAnimating()
                        self?.popover?["VOICEBASE"]?.activityIndicator.isHidden = true
                        
                        Alerts.shared.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                })
            })
        }
        
        if let mediaID = value["mediaId"] as? String {
            if let mediaList = Globals.shared.media.all?.mediaList?.list {
                let mediaItems = mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                        return transcript.mediaID == mediaID
                    }).count == 1
                })
                if mediaItems.count == 1, let mediaItem = mediaItems.first {
                    actions.append(AlertAction(title: "Locate", style: .default) { [weak self] in
                        self?.popover?["VOICEBASE"]?.dismiss(animated: true, completion: nil)
                        self?.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    })
                } else {
                    
                }
            }
        }
        
        return actions.count > 0 ? actions : nil
    }
    
    override func rowAlertActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]?
    {
        var actions = super.rowAlertActions(popover: popover, tableView: tableView, indexPath: indexPath) ?? [AlertAction]()
        
        guard let purpose = popover.purpose else {
            return actions.count > 0 ? actions : nil
        }
        
        switch purpose {
        case .showingVoiceBaseMediaItems:
            if let vbActions = voiceBaseMediaRowAlertActions(popover:popover, tableView:tableView, indexPath:indexPath) {
                actions.append(contentsOf: vbActions)
            }
            break
            
        case .selectingSearch: // Doesn't work because we're trying to alert w/ a popover showing.
//            if let searchHistoryActions = searchHistoryActions(popover:popover, tableView:tableView, indexPath:indexPath) {
//                actions.append(contentsOf: searchHistoryActions)
//            }
            // Instead, return a more general tableView row action.
            break
            
        default:
            break
        }
        
        return actions.count > 0 ? actions : nil
    }
    
//    func detailDisclosure(tableView:UITableView,indexPath:IndexPath) -> Bool
//    {
//        guard indexPath.section >= 0, indexPath.section < self.stringIndex?.keys?.count else {
//            return false
//        }
//
//        if let keys = self.stringIndex?.keys?.sorted() {
//            if (indexPath.section >= 0) && (indexPath.section < keys.count) {
//                let key = keys[indexPath.section]
//
//                if (key == Constants.Strings.LocalDevice) || (key == Constants.Strings.OtherDevices) {
//                    return false
//                }
//
//                if let values = self.stringIndex?[key], indexPath.row >= 0, indexPath.row < values.count {
//                    let value = values[indexPath.row]
//
//                    guard let mediaID = value["mediaId"] as? String else {
//                        return true
//                    }
//
//                    guard let metadata = value["metadata"] as? [String:Any] else {
//                        return true
//                    }
//
//                    guard let device = metadata["device"] as? [String:Any] else {
//                        return true
//                    }
//
//                    guard let deviceName = device["name"] as? String else {
//                        return true
//                    }
//
//                    guard deviceName == UIDevice.current.name else {
//                        return false
//                    }
//
//                    if Globals.shared.media.all?.mediaList?.list?.filter({ (mediaItem:MediaItem) -> Bool in
//                        return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
//                            return transcript.mediaID == mediaID
//                        }).count > 0
//                    }).count == 0 {
//                        return true
//                    }
//                }
//            }
//        }
//
//        return false
//    }

    @objc func historyActions()
    {
        var alertActions = [AlertAction]()
        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: { () -> (Void) in
            Globals.shared.media.history.list.clear() // = nil
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: Constants.SETTINGS.HISTORY)
            defaults.synchronize()
            self.popover?["HISTORY"]?.dismiss(animated: true, completion: nil)
        }))
        alertActions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.cancel, handler: nil))
        Alerts.shared.alert(title: "Delete History?", actions: alertActions)
    }
    
    func showMenu(action:String?,mediaItem:MediaItem?)
    {
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:showMenu", completion: nil)
            return
        }
        
        guard let action = action else {
            return
        }
        
        switch action {
        case Constants.Strings.About:
            about()
            break
            
        case Constants.Strings.Current_Selection:
            if let mediaItem = selectedMediaItem {
                if let contains = Globals.shared.media.active?.section?.mediaItems?.contains(mediaItem), contains {
                    if tableView.isEditing {
                        tableView.setEditing(false, animated: true)
                        
                        // Delay so UI works correctly.
                        DispatchQueue.global(qos: .background).async { [weak self] in
                            Thread.sleep(forTimeInterval: 0.1)
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.top)
                        }
                    } else {
                        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.top)
                    }
                } else {
                    if let text = mediaItem.text, let contextTitle = Globals.shared.contextTitle {
                        self.alert(title: "Not in List",message: "\(text)\nis not in the list \n\(contextTitle)\nSelect the All tag and try again.",completion:nil)
                    }
                }
            } else {
                self.alert(title: "Media Item Not Found!",message: "Oops, this should never happen!",completion:nil)
            }
            break
            
        case Constants.Strings.Media_Playing:
            fallthrough
            
        case Constants.Strings.Media_Paused:
            Globals.shared.mediaPlayer.killPIP = true
            
            performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: Globals.shared.mediaPlayer.mediaItem)
            break
            
        case Constants.Strings.Scripture_Index:
            if (Globals.shared.media.active?.scriptureIndex?.eligible == nil) {
                self.alert(title:"No Scripture Index Available",message: "The Scripture references for these media items are not specific.",completion:nil)
            } else {
                performSegue(withIdentifier: Constants.SEGUE.SHOW_SCRIPTURE_INDEX, sender: nil)
            }
            break
            
        case Constants.Strings.Lexicon_Index:
            guard (Globals.shared.media.active?.lexicon?.eligible != nil) else {
                self.alert(title:"No Lexicon Index Available",
                           message: "These media items do not have HTML transcripts.",
                           completion:nil)
                break
            }
            
            performSegue(withIdentifier: Constants.SEGUE.SHOW_LEXICON_INDEX, sender: nil)
            break
            
        case Constants.Strings.History:
            if  let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationItem.title = Constants.Strings.History
                
                popover.delegate = self
                popover.purpose = .selectingHistory
                
                self.popover?["HISTORY"] = popover
                
                popover.completion = { [weak self] in
                    self?.popover?["HISTORY"] = nil
                }
                
                popover.stringsFunction = { [weak self, weak popover] ()->[String]? in
                    let strings = Globals.shared.media.history.relevantText
                    
                    Thread.onMain {
                        popover?.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Constants.Strings.Delete_All, style: UIBarButtonItem.Style.plain, target: self, action: #selector(self?.historyActions))
                        popover?.navigationItem.leftBarButtonItem?.isEnabled = strings?.count > 0
                    }
                    
                    return strings
                }
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.Live:
            guard   // Globals.shared.media.stream.streamEntries?.count > 0,
                Globals.shared.reachability.isReachable,
                let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController else {
                    break
            }
            
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = self
            
            popover.navigationItem.title = Constants.Strings.Live_Events
            
            popover.allowsSelection = true
            
            // An enhancement to selectively highlight (select)
            popover.shouldSelect = { [weak popover] (indexPath:IndexPath) -> Bool in
                if let keys = popover?.section.stringIndex?.keys {
                    let sortedKeys = [String](keys).sorted()
                    if indexPath.section < sortedKeys.count {
                        return sortedKeys[indexPath.section] == Constants.Strings.Playing
                    }
                }
                
                return false
            }
            
            self.popover?["LIVE"] = popover
            
            popover.completion = { [weak self] in
                self?.popover?["LIVE"] = nil
            }
            
            // An alternative to rowClickedAt
            popover.didSelect = { [weak self, weak popover] (indexPath:IndexPath) -> Void in
                if let keys = popover?.section.stringIndex?.keys {
                    let sortedKeys = [String](keys).sorted()
                    
                    if indexPath.section < sortedKeys.count {
                        let key = sortedKeys[indexPath.section]
                        
                        if key == Constants.Strings.Playing {
                            self?.popover?["LIVE"]?.dismiss(animated: true, completion: nil)
                            
                            if indexPath.row < Globals.shared.media.stream.streamEntryIndex?[key]?.count {
                                if let streamEntry = StreamEntry(Globals.shared.media.stream.streamEntryIndex?[key]?[indexPath.row]) {
                                    self?.performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: streamEntry)
                                }
                            }
                        }
                    }
                }
            }
            
            popover.search = true
            
            popover.refresh = { [weak popover] in
                popover?.section.strings = nil
                popover?.section.headerStrings = nil
                popover?.section.counts = nil
                popover?.section.indexes = nil
                
                popover?.tableView?.reloadData()
                
                Globals.shared.media.stream.loadLive() {
                    if #available(iOS 10.0, *) {
                        if let isRefreshing = popover?.tableView?.refreshControl?.isRefreshing, isRefreshing {
                            popover?.refreshControl?.endRefreshing()
                        }
                    } else {
                        // Fallback on earlier versions
                        if popover?.isRefreshing == true {
                            popover?.refreshControl?.endRefreshing()
                            popover?.isRefreshing = false
                        }
                    }
                    
                    popover?.section.stringIndex = Globals.shared.media.stream.streamStringIndex
                    
                    popover?.tableView.reloadData()
                }
            }
            
            // Makes no sense w/o section.showIndex also being true - UNLESS you're using section.stringIndex
            popover.section.showHeaders = true

            process(work: { [weak self, weak popover] (test:(() -> Bool)?) -> (Any?) in
                var key = ""
                
                if Constants.URL.LIVE_EVENTS == Constants.URL.LIVE_EVENTS_OLD {
                    key = "streamEntries"
                }
                if Constants.URL.LIVE_EVENTS == Constants.URL.LIVE_EVENTS_NEW {
                    key = "mediaEntries"
                }
                return Globals.shared.media.stream.liveEvents?[key] as? [[String:Any]]
            }) { [weak self, weak popover] (data:Any?, test:(() -> Bool)?) in
                Globals.shared.media.stream.streamEntries = data as? [[String:Any]]
                
                if Globals.shared.media.stream.streamEntries != nil {
                    popover?.section.stringIndex = Globals.shared.media.stream.streamStringIndex
                    self?.present(navigationController, animated: true, completion: nil)
                } else {
                    self?.alert(title: "No Live Events Available")
                }
            }
            break
            
        case Constants.Strings.Settings:
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SETTINGS_NAVCON) as? UINavigationController,
                let _ = navigationController.viewControllers[0] as? SettingsViewController {
                navigationController.modalPresentationStyle = .popover // MUST OCCUR BEFORE PPC DELEGATE IS SET.
                
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.barButtonItem = showButton
                
                present(navigationController, animated: true, completion: nil)
            }
            break
            
        case Constants.Strings.VoiceBase_API_Key:
            let alert = CBCAlertController(  title: Constants.Strings.VoiceBase_API_Key,
                                             message: nil,
                                             preferredStyle: .alert)
            alert.makeOpaque()
            
            alert.addTextField(configurationHandler: { (textField:UITextField) in
                textField.text = Globals.shared.voiceBaseAPIKey
            })
            
            let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertAction.Style.default, handler: {
                (action : UIAlertAction) -> Void in
                Globals.shared.voiceBaseAPIKey = alert.textFields?[0].text
            })
            alert.addAction(okayAction)
            
            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                (action : UIAlertAction) -> Void in
            })
            alert.addAction(cancel)

            Alerts.shared.blockPresent(presenting: self, presented: alert, animated: true)
            break
            
        case Constants.Strings.VoiceBase_Delete_All:
            guard Globals.shared.media.repository.list?.voiceBaseMediaItems > 0 else {
                break
            }
            
            var alertActions = [AlertAction]()
            
            let yesAction = AlertAction(title: Constants.Strings.Yes, style: UIAlertAction.Style.destructive, handler: {
                () -> Void in
                Globals.shared.media.repository.deleteAllVoiceBaseMedia(alert:false, detailedAlert:false)
            })
            alertActions.append(yesAction)
            
            let noAction = AlertAction(title: Constants.Strings.No, style: UIAlertAction.Style.default, handler: {
                () -> Void in
                
            })
            alertActions.append(noAction)
            
            Alerts.shared.alert(title: "Confirm Deletion of All VoiceBase Media", message: "This will delete all VoiceBase media for the machine generated transcripts on this device.  If the same VoiceBase API key is used on multiple devices any VoiceBase media for those transcripts will not be deleted.", actions: alertActions)
            break
            
        case Constants.Strings.VoiceBase_Bulk_Delete:
            bulkDeleteMedia()
            break
            
        case Constants.Strings.VoiceBase_Media:
            guard Globals.shared.reachability.isReachable else {
                Alerts.shared.alert(title:"Network Error",message:"VoiceBase media not available.")
                return
            }
            
            if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                self.popover?["VOICEBASE"] = navigationController.viewControllers[0] as? PopoverTableViewController
                
                self.popover?["VOICEBASE"]?.sectionBarButtons = true
                
                self.popover?["VOICEBASE"]?.navigationItem.title = Constants.Strings.VoiceBase_Media
                
                self.popover?["VOICEBASE"]?.refresh = { [weak self] in
                    self?.popover?["VOICEBASE"]?.navigationController?.isToolbarHidden = true
                    
                    self?.popover?["VOICEBASE"]?.unfilteredSection.strings = nil
                    self?.popover?["VOICEBASE"]?.unfilteredSection.stringIndex = nil
                    self?.popover?["VOICEBASE"]?.unfilteredSection.headerStrings = nil
                    self?.popover?["VOICEBASE"]?.unfilteredSection.counts = nil
                    self?.popover?["VOICEBASE"]?.unfilteredSection.indexes = nil
                    
                    self?.popover?["VOICEBASE"]?.tableView?.reloadData()
                    
                    VoiceBase.all(completion:{ [weak self] (json:[String:Any]?) -> Void in
                        // To get a visible amount of delay
                        Thread.sleep(forTimeInterval: 1.0)
                        
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        self?.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                            if  let date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                                let date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                                return Date(string: date0) < Date(string: date1)
                            } else {
                                return false // arbitrary
                            }
                        })
                        
                        self?.popover?["VOICEBASE"]?.unfilteredSection.stringIndex = self?.stringIndex?.stringIndex(key: "title", sort: nil)
                        
                        Thread.onMain {
                            self?.popover?["VOICEBASE"]?.updateSearchResults()
                            
                            self?.popover?["VOICEBASE"]?.updateToolbar()
                            
                            self?.popover?["VOICEBASE"]?.tableView?.reloadData()
                            
                            if #available(iOS 10.0, *) {
                                if let isRefreshing = self?.popover?["VOICEBASE"]?.tableView?.refreshControl?.isRefreshing, isRefreshing {
                                    self?.popover?["VOICEBASE"]?.refreshControl?.endRefreshing()
                                }
                            } else {
                                // Fallback on earlier versions
                                if let isRefreshing = self?.popover?["VOICEBASE"]?.isRefreshing, isRefreshing {
                                    self?.popover?["VOICEBASE"]?.refreshControl?.endRefreshing()
                                    self?.popover?["VOICEBASE"]?.isRefreshing = false
                                }
                            }
                        }
                    },onError: nil)
                }
                
                self.popover?["VOICEBASE"]?.delegate = self
                
                self.popover?["VOICEBASE"]?.completion = { [weak self] in
                    self?.popover?["VOICEBASE"] = nil
                }
                
                self.popover?["VOICEBASE"]?.purpose = .showingVoiceBaseMediaItems
                self.popover?["VOICEBASE"]?.allowsSelection = false
                
                self.popover?["VOICEBASE"]?.section.showHeaders = true
                
                self.popover?["VOICEBASE"]?.search = true
                
                self.startAnimating()
                
                VoiceBase.all(completion:{ [weak self] (json:[String:Any]?) -> Void in
                    guard let mediaItems = json?["media"] as? [[String:Any]] else {
                        return
                    }
                    
                    self?.stringIndex = StringIndex(mediaItems:mediaItems, sort: { (lhs:[String:Any], rhs:[String:Any]) -> Bool in
                        if  let date0 = (lhs["title"] as? String)?.components(separatedBy: "\n").first,
                            let date1 = (rhs["title"] as? String)?.components(separatedBy: "\n").first {
                            return Date(string: date0) < Date(string: date1)
                        } else {
                            return false // arbitrary
                        }
                    })
                    
                    self?.popover?["VOICEBASE"]?.section.stringIndex = self?.stringIndex?.stringIndex(key: "title", sort: nil)
                    
                    self?.stopAnimating()
                    
                    Thread.onMain {
                        if self?.stringIndex?.keys == nil {
                            Alerts.shared.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase.")
                        } else {
                            self?.present(navigationController, animated: true, completion: {
                                self?.popover?["VOICEBASE"]?.updateToolbar()
                                self?.popover?["VOICEBASE"]?.updateSearchResults()
                                self?.popover?["VOICEBASE"]?.tableView?.reloadData()
                                self?.popover?["VOICEBASE"]?.activityIndicator.stopAnimating()
                            })
                        }
                    }
                },onError: nil)
            }
            break
            
        default:
            break
        }
    }
    
    override func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        super.rowClickedAtIndex(index, strings: strings, purpose: purpose, mediaItem: mediaItem)
        
        guard self.isViewLoaded else {
            return
        }
        
        guard Thread.isMainThread else {
            self.alert(title: "Not Main Thread", message: "MediaTableViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingCategory:
            self.popover?["CATEGORY"]?.dismiss(animated: true, completion: nil)
            
            guard (Globals.shared.media.category.selected != string) || (Globals.shared.media.repository.list == nil) else {
                return
            }
            
            Globals.shared.media.category.selected = string // != Constants.Strings.All ? string : nil
            
            self.display.clear()
            
            Thread.onMain {
                self.mediaCategoryButton.setTitle(Globals.shared.media.category.selected)
                self.tagLabel.text = nil
                self.tableView?.reloadData()
            }
            
            // test:(()->(Bool))?
            self.process(work: { [weak self] () -> (Any?) in
                self?.selectedMediaItem = Globals.shared.media.selected.master
                
                guard let selected = Globals.shared.media.category.selected else {
                    return nil
                }
                
                if Globals.shared.media.cache[selected] != nil {
                    Globals.shared.media.all = Globals.shared.media.cache[selected]
                } else {
                    if selected != Constants.Strings.All {
                        Globals.shared.media.all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: Globals.shared.media.repository.list?.filter({ (mediaItem) -> Bool in
                            mediaItem.category == Globals.shared.media.category.selected
                        }))
                    } else {
                        Globals.shared.media.all = MediaListGroupSort(name:Constants.Strings.All, mediaItems: Globals.shared.media.repository.list)
                    }
                    Globals.shared.media.cache[selected] = Globals.shared.media.all
                }
                
                Globals.shared.media.tagged.clear()
                
                if let tag = Globals.shared.media.tags.selected {
                    Globals.shared.media.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag.withoutPrefixes])
                }
                
                self?.display.setup(Globals.shared.media.active)
                
                return nil
            }) { [weak self] (data:Any?) in
                self?.updateUI()
                
                Thread.onMain {
                    if Globals.shared.media.search.isActive { //  && !Globals.shared.media.search.complete
                        self?.updateSearchResults(Globals.shared.media.active?.context,completion: {
                            // Delay so UI works correctly.
                            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                                Thread.onMain {
                                    self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.top)
                                }
                            }
                        })
                    } else {
                        // Reload the table
                        self?.tableView?.reloadData()
                        
                        if self?.selectedMediaItem != nil {
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.middle)
                        } else {
                            let indexPath = IndexPath(row:0,section:0)
                            if self?.tableView?.isValid(indexPath) == true {
                                self?.tableView?.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
                            }
                        }
                    }
                    
                    // Need to update the MVC cells.
                    if let isCollapsed = self?.splitViewController?.isCollapsed, !isCollapsed {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
                    }
                }
            }
            break
            
        case .selectingCellSearch:
            popover?.values.forEach({ (popover:PopoverTableViewController) in
                popover.dismiss(animated: true, completion: nil)
            })
            
            var searchText = strings[index].uppercased()
            
            searchText = searchText.word ?? searchText
            
            Globals.shared.media.search.isActive = true
            Globals.shared.media.search.text = searchText
            
            tableView?.setEditing(false, animated: true)
            searchBar.text = searchText
            searchBar.showsCancelButton = true
            
            updateSearchResults(Globals.shared.media.active?.context,completion: nil)
            break
            
        case .selectingCellAction:
            popover?.values.forEach({ (popover:PopoverTableViewController) in
                popover.dismiss(animated: true, completion: nil)
            })
            
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download(background: true)
                Thread.onMain {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
                }
                break
                
            case Constants.Strings.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete(block:true)
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            default:
                break
            }
            break
            
        case .selectingSearch:
            self.popover?["SEARCH_HISTORY"]?.dismiss(animated: true, completion: nil)
            
            let searchText = strings[index].uppercased()
            
            Globals.shared.media.search.isActive = true
            Globals.shared.media.search.text = searchText
            
            tableView?.setEditing(false, animated: true)
            searchBar.text = searchText
            searchBar.showsCancelButton = true
            
            updateSearchResults(Globals.shared.media.active?.context,completion: nil)
            break
            
        case .selectingHistory:
            self.popover?["HISTORY"]?.dismiss(animated: true, completion: nil)
            
            if let history = Globals.shared.media.history.relevant {
                var mediaItemID:String
                
                if let range = history[index].range(of: Constants.SEPARATOR) {
                    mediaItemID = String(history[index][range.upperBound...])
                } else {
                    mediaItemID = history[index]
                }
                
                if let mediaItem = Globals.shared.media.repository.index[mediaItemID] {
                    if mediaItem.text != strings[index] {
                        if let text = mediaItem.text {
                            print(text,strings[index])
                        }
                    }
                    
                    if let contains = Globals.shared.media.active?.section?.mediaItems?.contains(mediaItem), contains {
                        selectOrScrollToMediaItem(mediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.top) // was Middle
                    } else {
                        if let text = mediaItem.text, let contextTitle = Globals.shared.contextTitle {
                            self.alert( title:"Not in List",
                                        message: "\(text)\nis not in the list \n\(contextTitle)\nSelect the All tag and try again.",
                                completion:nil)
                        }
                    }
                } else {
                    self.alert(title:"Media Item Not Found!",
                               message: "Oops, this should never happen!",
                               completion:nil)
                }
            }
            break
            
        case .selectingTags:
            self.popover?["TAGS"]?.dismiss(animated: true, completion: nil)
            
            // Should we be showing Globals.shared.media.active?.mediaItemTags instead?  That would be the equivalent of drilling down.

            if (index < 0) || (index >= strings.count) {
                print("Index out of range")
            }
            
            // test:(()->(Bool))?
            self.process(work: { [weak self] () -> (Any?) in
                var new:Bool = false
                
                switch string {
                case Constants.Strings.All:
                    if (Globals.shared.media.tags.showing != Constants.ALL) {
                        new = true
                        Globals.shared.media.tags.selected = nil
                    }
                    break
                    
                default:
                    //Tagged
                    
                    let tagSelected = string // s[index]
                    
                    new = (Globals.shared.media.tags.showing != Constants.TAGGED) || (Globals.shared.media.tags.selected != tagSelected)
                    
                    if (new) {
                        Globals.shared.media.tags.selected = tagSelected
                    }
                    break
                }
                return new
            }) { [weak self] (data:Any?) in
                guard let new = data as? Bool else {
                    return
                }
                
                if (new) {
                    Thread.onMain {
                        self?.display.clear()
                        
                        self?.tableView?.reloadData()
                        
                        self?.startAnimating()
                        
                        self?.barButtonItems(isEnabled:false)
                    }
                    
                    if (Globals.shared.media.search.isActive) {
                        self?.updateSearchResults(Globals.shared.media.active?.context,completion: nil)
                    }
                    
                    Thread.onMain {
                        self?.display.setup(Globals.shared.media.active)
                        
                        self?.tableView?.reloadData()
                        self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.none) // was Middle
                        
                        self?.stopAnimating()
                        
                        self?.setupTag()
                        
                        self?.setupBarButtons()
                    }
                }
            }
            break
            
        case .selectingSection:
            self.popover?["INDEX"]?.dismiss(animated: true, completion: nil)
            
            if let section = Globals.shared.media.active?.section?.headerStrings?.firstIndex(of: strings[index]) {
                let indexPath = IndexPath(row: 0, section: section)
                
                if !(indexPath.section < tableView?.numberOfSections) {
                    NSLog("indexPath section ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    break
                }
                
                if !(indexPath.row < tableView?.numberOfRows(inSection: indexPath.section)) {
                    NSLog("indexPath row ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                    NSLog("Row: \(indexPath.row)")
                    NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                    break
                }
                
                //Can't use this reliably w/ variable row heights.
                if tableView?.isValid(indexPath) == true {
                    tableView?.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                }
            }
            break
            
        case .selectingGrouping:
            self.popover?["GROUPING"]?.dismiss(animated: true, completion: nil)
            
            Globals.shared.grouping = Globals.shared.groupings[index]
            
            if Globals.shared.media.need.grouping {
                display.clear()
                
                tableView?.reloadData()
                
                startAnimating()
                
                barButtonItems(isEnabled:false)
                
                operationQueue.addOperation { [weak self] in
                    self?.display.setup(Globals.shared.media.active)
                    
                    Thread.onMain {
                        self?.tableView?.reloadData()
                        
                        self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.none) // was Middle
                        
                        self?.stopAnimating()
                        
                        self?.setupBarButtons()
                    }
                }
            }
            break
            
        case .selectingSorting:
            self.popover?["SORTING"]?.dismiss(animated: true, completion: nil)
            
            Globals.shared.sorting = Constants.sortings[index]
            
            if (Globals.shared.media.need.sorting) {
                display.clear()
                
                Thread.onMain {
                    self.tableView?.reloadData()
                    
                    self.startAnimating()
                    
                    self.barButtonItems(isEnabled:false)
                    
                    self.operationQueue.addOperation { [weak self] in
                        self?.display.setup(Globals.shared.media.active)
                        
                        Thread.onMain {
                            self?.tableView?.reloadData()
                            
                            self?.selectOrScrollToMediaItem(self?.selectedMediaItem, select: true, scroll: true, position: UITableView.ScrollPosition.none) // was Middle
                            
                            self?.stopAnimating()
                            
                            self?.setupBarButtons()
                        }
                    }
                }
            }
            break
            
        case .selectingShow:
            popover?["SHOW"]?.dismiss(animated: true, completion: nil)
            
            showMenu(action:strings[index],mediaItem:mediaItem)
            break
            
        case .selectingAction:
            popover?["ACTION"]?.dismiss(animated: true, completion: nil)
            
            switch string {
            case Constants.Strings.View_List:
                self.process(work: { [weak self] (test:(()->(Bool))?) -> (Any?) in
                    if Globals.shared.media.active?.html?.string == nil {
                        Globals.shared.media.active?.html?.string = Globals.shared.media.active?.html(includeURLs:true, includeColumns:true, test:test)
                    }
                    return Globals.shared.media.active?.html?.string
                    }, completion: { [weak self] (data:Any?, test:(()->(Bool))?) in
                        if let vc = self {
                            vc.presentHTMLModal(mediaItem: nil, style: .overFullScreen, title: Globals.shared.contextTitle, htmlString: data as? String)
                        }
                })
                break
                
            default:
                break
            }
            break

        default:
            break
        }
    }
}

extension MediaTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int
    {
        guard let headers = display.section.headers else {
            return 0
        }
        
        return headers.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        return nil
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let headers = display.section.headers else {
            return nil
        }
        
        if section >= 0, section < headers.count {
            return headers[section]
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let counts = display.section.counts else {
            return 0
        }
        
        if section >= 0, section < counts.count {
            return counts[section]
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = (tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MEDIAITEM, for: indexPath) as? MediaTableViewCell) ?? MediaTableViewCell()
        
        cell.hideUI()
        
        cell.vc = self
        
        cell.searchText = Globals.shared.media.search.isValid ? Globals.shared.media.search.text : nil
        
        // Configure the cell
        if indexPath.section >= 0, indexPath.section < display.section.indexes?.count {
            if let section = display.section.indexes?[indexPath.section], let count = display.mediaItems?.count {
                if (section + indexPath.row) >= 0,(section + indexPath.row) < count {
                    cell.mediaItem = display.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section >= 0, section < display.section.headers?.count, let title = display.section.headers?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).height
        
        return max(Constants.HEADER_HEIGHT,height + 28)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
            header.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            header.textLabel?.text = nil
            header.textLabel?.textColor = UIColor.black
            
            header.alpha = 0.85
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var view : MediaTableViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MediaTableViewController") as? MediaTableViewControllerHeaderView
        if view == nil {
            view = MediaTableViewControllerHeaderView()
        }
        
        view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
        
        if view?.label == nil {
            let label = UILabel()
            
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view?.addSubview(label)

            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
            view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllLeft], metrics: nil, views: ["label":label]))
            
            view?.label = label
        }
        
        view?.alpha = 0.85
        
        if section >= 0, section < display.section.headers?.count, let title = display.section.headers?[section] {
            view?.label?.attributedText = NSAttributedString(string: title, attributes: Constants.Fonts.Attributes.bold)
        } else {
            view?.label?.attributedText = NSAttributedString(string: "ERROR", attributes: Constants.Fonts.Attributes.bold)
        }

        return view
    }
}

extension MediaTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if Globals.shared.mediaPlayer.fullScreen {
            Globals.shared.mediaPlayer.fullScreen = false
        }

        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
        } else {
            
        }
    }
    
    func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath: IndexPath)
    {
        // Tells the delegate that the table view is about to go into editing mode.
        Thread.onMain {
            self.searchBar.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMain {
                self.tableView?.reloadData()
            }
        }
        
        changesPending = false
    }
    
    func tableView(_ tableView:UITableView, didDeselectRowAt indexPath: IndexPath)
    {

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        if Globals.shared.media.search.isValid, ((Globals.shared.media.search.current?.complete ?? false) == false) {
            return false
        }
        
        var mediaItem : MediaItem?
        
        if indexPath.section >= 0, indexPath.section < display.section.indexes?.count {
            if let section = display.section.indexes?[indexPath.section], let count = display.mediaItems?.count {
                if (section + indexPath.row) >= 0,(section + indexPath.row) < count {
                    mediaItem = display.mediaItems?[section + indexPath.row]
                }
            } else {
                print("No mediaItem for cell!")
            }
        }

        return mediaItem?.editActions(viewController: self) != nil
    }
        
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        if let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell, let message = cell.mediaItem?.text {
            //            return editActions(cell: cell, mediaItem: cell.mediaItem)
            
            let action = UITableViewRowAction(style: .normal, title: Constants.Strings.Actions) { rowAction, indexPath in
                guard var actions = cell.mediaItem?.editActions(viewController: self) else {
                    return
                }
                
                actions.append(AlertAction(title: Constants.Strings.Cancel, style: UIAlertAction.Style.default, handler: nil))
                
                Alerts.shared.alert(title: Constants.Strings.Actions, message: message, actions: actions)
            }
            action.backgroundColor = UIColor.controlBlue()
            
            return [action]
        }
        
        return nil
    }
}
