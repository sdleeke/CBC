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

extension UIAlertController {
    func makeOpaque()
    {
        if  let subView = view.subviews.first,
            let alertContentView = subView.subviews.first {
            alertContentView.backgroundColor = UIColor.white
            alertContentView.layer.cornerRadius = 10
            alertContentView.layer.masksToBounds = true
        }
    }
}

extension UIColor
{
    // MARK: UIColor extension
    
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
    
    case selectingCategory
    
    case selectingKeyword
    
    case selectingTopic
    case selectingTopicKeyword

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
        if scrollView.contentOffset.y < -100 { //change 100 to whatever you want
            if !globals.isRefreshing {
                refreshControl?.beginRefreshing()
                handleRefresh(refreshControl!)
            }
        } else if scrollView.contentOffset.y >= 0 {
            
        }
        
//        tableView?.isEditing = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
//        tableView?.isEditing = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
//        tableView.setEditing(false, animated: false)
        tableView?.isEditing = false
//
//        if let cells = tableView?.visibleCells {
//            for cell in cells {
//                cell.isEditing = false
//            }
//        }
    }
    
//    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
//    {
//        tableView?.isEditing = false
//        return true
//    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
    {
//        tableView.setEditing(false, animated: false)
        tableView?.isEditing = false
//
//        if let cells = tableView?.visibleCells {
//            for cell in cells {
//                cell.isEditing = false
//            }
//        }
    }
}

extension MediaTableViewController : UISearchBarDelegate
{
    // MARK: UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBar:textDidChange", completion: nil)
            return
        }
        let searchText = searchText.uppercased()
        
        globals.search.text = searchText
        
        if (searchText != Constants.EMPTY_STRING) { //
            updateSearchResults(searchText,completion: nil)
        } else {
            //            print("clearDisplay 2")
            globals.clearDisplay()
            
            tableView?.reloadData()
            
            disableBarButtons()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarSearchButtonClicked", completion: nil)
            return
        }
        //        print("searchBarSearchButtonClicked:")
        
        searchBar.resignFirstResponder()
        
        //        print(searchBar.text)
        
        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid {
            updateSearchResults(searchBar.text,completion: nil)
        } else {
            //            print("clearDisplay 3")
            globals.clearDisplay()
            
            tableView?.reloadData()
            
            enableBarButtons()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarShouldBeginEditing", completion: nil)
            return false
        }
        
        return !globals.isLoading && !globals.isRefreshing && (globals.media.all != nil) // !globals.mediaItemsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        globals.search.active = true
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidBeginEditing", completion: nil)
            return
        }
        
        //        print("searchBarTextDidBeginEditing:")
        
        searchBar.showsCancelButton = true
        
        //        print(searchBar.text)
        
        let searchText = searchBar.text?.uppercased()
        
        globals.search.text = searchText
        
        if globals.search.valid { //
            updateSearchResults(searchText,completion: nil)
        } else {
            //            print("clearDisplay 4")
            globals.clearDisplay()
            
            tableView?.reloadData()
            
            disableBarButtons()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarTextDidEndEditing", completion: nil)
            return
        }
        
        //        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        globals.search.active = false
        
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:searchBarCancelButtonClicked", completion: nil)
            return
        }
        
        //        print("searchBarCancelButtonClicked:")
        
        didDismissSearch()
    }
    
    func didDismissSearch()
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:didDismissSearch", completion: nil)
            return
        }
        
        globals.search.text = nil
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        
        disableBarButtons()
        
        globals.clearDisplay()
        
        tableView?.reloadData()
        
        //        self.listActivityIndicator.isHidden = false
        //        self.listActivityIndicator.s@objc @objc tartAnimating()
        
        startAnimating()
        
        globals.setupDisplay(globals.media.active)
        
        tableView?.reloadData()
        
        //        self.listActivityIndicator.stopAnimating()
        //        self.listActivityIndicator.isHidden = true
        
        stopAnimating()
        
        setupTag()
        setupActionAndTagsButton()
        
        enableBarButtons()
        
        //Moving the list can be very disruptive
        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: false, position: UITableViewScrollPosition.none)
    }
}

extension MediaTableViewController : MFMailComposeViewControllerDelegate
{
    // MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension MediaTableViewController : PopoverPickerControllerDelegate
{
    // MARK: PopoverPickerControllerDelegate
    
    func noMediaAvailable(handler:@escaping (UIAlertAction) -> Void)
    {
        alert(viewController:self,title: "No Media Available",message: "Please check your network connection and try again.",completion:nil)
    }

    func stringPicked(_ string:String?)
    {
        Thread.onMainThread() {
            self.dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
        }
        
        //        print(string)
        
        guard (globals.mediaCategory.selected != string) || (globals.mediaRepository.list == nil) else {
            return
        }
        
        globals.mediaCategory.selected = string
        
        globals.mediaPlayer.unobserve()
        
        if globals.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM) {
            globals.mediaPlayer.pause() // IfPlaying
        }
        
        globals.cancelAllDownloads()
        globals.clearDisplay()
        
        Thread.onMainThread() {
            self.tableView?.reloadData()
            
            self.tableView?.isHidden = true
            if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
                self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
            }

            if self.splitViewController?.viewControllers.count > 1 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            }
        }
        
        tagLabel.text = nil
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        globals.media = Globals.Media()
        globals.media.globals = globals
        
        loadMediaItems()
        {
            self.loadCompletion() // stringPickedCompletion()
        }
    }
}

class StringIndex {
    var dict : [String:[[String:Any]]]?
    
    subscript(key:String) -> [[String:Any]]? {
        get {
            return dict?[key]
        }
        set {
            if dict == nil {
                dict = [String:[[String:Any]]]()
            }
            
            dict?[key] = newValue
        }
    }
    
    var keys : [String]?
    {
        return dict?.keys.map({ (string:String) -> String in
            return string
        })
    }
}

extension MediaTableViewController : PopoverTableViewControllerDelegate
{
    // MARK: PopoverTableViewControllerDelegate
    
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [UITableViewRowAction]?
    {
        // Presence of a detailed disclosure means the action buttons don't get the right font.  Not sure why.
        guard !detailDisclosure(tableView:popover.tableView, indexPath:indexPath) else {
            return nil
        }
        
        guard self.deleteButton?.isEnabled == true else {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        
        var searchIndex:StringIndex?
        
        if popover.searchActive {
            searchIndex = StringIndex()
            
            if let text = popover.searchText {
                if let keys = self.stringIndex?.keys {
                    for key in keys {
                        if let values = self.stringIndex?[key] {
                            for value in values {
                                if (value["title"] as? String)?.range(of:text, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil {
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
            
        guard let keys = searchIndex?.keys?.sorted() else {
            return nil
        }
        
        let key = keys[indexPath.section]
        
        guard let values = searchIndex?[key] else {
            return nil
        }
        
        guard indexPath.section >= 0, indexPath.section < keys.count else {
            return nil
        }
        
        guard indexPath.row >= 0, indexPath.row < values.count else {
            return nil
        }
        
        let value = values[indexPath.row]
        
        if let mediaID = value["mediaID"] as? String, let title = value["title"] as? String {
            let deleteAction = UITableViewRowAction(style: .normal, title: Constants.FA.DELETE) { rowAction, indexPath in
                let alert = UIAlertController(  title: "Confirm Deletion of VoiceBase Media Item",
                                                message: title + "\n created on \(key == UIDevice.current.deviceName ? "this device" : key)",
                    preferredStyle: .alert)
                alert.makeOpaque()
                
                let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                    alertItem -> Void in
                    VoiceBase.delete(mediaID: mediaID)
                    
                    searchIndex?[key]?.remove(at: indexPath.row)
                    
                    if searchIndex?[key]?.count == 0 {
                        searchIndex?[key] = nil
                    }

                    if let keys = self.stringIndex?.keys?.sorted() {
                        for key in keys {
                            if let values = self.stringIndex?[key] {
                                for value in values {
                                    var count = 0
                                    
                                    if (value["mediaID"] as! String) == mediaID {
                                        self.stringIndex?[key]?.remove(at: count)
                                        
                                        if self.stringIndex?[key]?.count == 0 {
                                            self.stringIndex?[key] = nil
                                        }
                                        
                                        break
                                    }
                                    
                                    count += 1
                                }
                            }
                        }
                    }

                    var stringIndex = [String:[String]]()
                    
                    if let keys = searchIndex?.keys {
                        for key in keys {
                            if let values = searchIndex?[key] {
                                for value in values {
                                    if stringIndex[key] == nil {
                                        stringIndex[key] = [String]()
                                    }
                                    stringIndex[key]?.append(value["title"] as! String)
                                }
                            }
                        }
                    }
                    
                    popover.section.stringIndex = stringIndex.keys.count > 0 ? stringIndex : nil
                    
//                    var strings = [String]()
//                    
//                    var counter = 0
//                    
//                    var counts = [Int]()
//                    var indexes = [Int]()
//                    
//                    if let keys = self.stringIndex?.keys?.sorted() {
//                        for key in keys {
//                            indexes.append(counter)
//                            
//                            if let count = self.stringIndex?[key]?.count {
//                                counts.append(count)
//                                counter += count
//                            }
//                        }
//                    }
//                    
//                    popover.section.headerStrings = self.stringIndex?.keys?.sorted()
//                    popover.section.strings = strings.count > 0 ? strings : nil
//                    //                                            popover.section.indexHeaders = popover.section.headers
//                    
//                    popover.section.counts = counts.count > 0 ? counts : nil
//                    popover.section.indexes = indexes.count > 0 ? indexes : nil
                    
                    Thread.onMainThread() {
                        popover.tableView?.isEditing = false
                        popover.tableView?.reloadData()
                        popover.tableView?.reloadData()
                    }
                })
                alert.addAction(yesAction)
                
                let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                    alertItem -> Void in
                    
                })
                alert.addAction(noAction)
                
                let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction!) -> Void in
                    
                })
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            }
            deleteAction.backgroundColor = UIColor.red//controlBlue()
            actions.append(deleteAction)
            
            let mediaIDAction = UITableViewRowAction(style: .normal, title: "ID") { rowAction, indexPath in
                let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                message: nil,
                                                preferredStyle: .alert)
                alert.makeOpaque()
                
                alert.addTextField(configurationHandler: { (textField:UITextField) in
                    textField.text = mediaID
                })
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    alertItem -> Void in
                })
                alert.addAction(okayAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            mediaIDAction.backgroundColor = UIColor.lightGray
            actions.append(mediaIDAction)
            
            let detailsAction = UITableViewRowAction(style: .normal, title: Constants.FA.INFO) { rowAction, indexPath in
                process(viewController: self.popover!, work: { () -> (Any?) in
                    var data : Any?
                    
                    VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
                        print(json as Any)
                        
                        data = json
                    }, onError: { (json:[String : Any]?) -> (Void) in
                        data = "VoiceBase Media Item\nNot Found"
                        globals.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                    })
                    
                    while data == nil {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    
                    return data
                }, completion: { (data:Any?) in
                    let json = data as? [String:Any]
                    
                    if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? WebViewController {
                        
                        popover.html.fontSize = 12
                        popover.html.string = insertHead(VoiceBase.html(json),fontSize: popover.html.fontSize)
                        
                        popover.search = true
                        popover.content = .html
                        
                        popover.navigationItem.title = "VoiceBase Media Item"
                        
                        self.popover?.navigationController?.pushViewController(popover, animated: true)
                    }
                })
                
                //                                    popoverHTML(self, mediaItem: nil, title: "VoiceBase Media Item", barButtonItem: nil, sourceView: nil, sourceRectView: nil, htmlString: htmlString)
            }
            detailsAction.backgroundColor = UIColor.gray
            actions.append(detailsAction)
            
            let inspectorAction = UITableViewRowAction(style: .normal, title: Constants.FA.INSPECTOR) { rowAction, indexPath in
                process(viewController: self.popover!, work: { () -> (Any?) in
                    var data : Any?
                    
                    VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
                        print(json as Any)
                        
                        data = json
                        
                    }, onError: { (json:[String : Any]?) -> (Void) in
                        data = "VoiceBase Media Item\nNot Found"
                        globals.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                    })
                    
                    while data == nil {
                        Thread.sleep(forTimeInterval: 0.1)
                    }
                    
                    return data
                }, completion: { (data:Any?) in
                    let json = data as? [String:Any]
                    
                    if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                        let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        popover.search = true
                        
                        popover.navigationItem.title = "VoiceBase Media Item"
                        
                        popover.stringsAny = json
                        popover.purpose = .showingVoiceBaseMediaItem
                        
                        self.popover?.navigationController?.pushViewController(popover, animated: true)
                    }
                })
            }
            inspectorAction.backgroundColor = UIColor.darkGray
            actions.append(inspectorAction)
        }
        
        //                        mediaID = UITableViewRowAction(style: .normal, title: "ID") { rowAction, indexPath in
        //                            var value : [String:Any]?
        //
        //                            if let keys = stringIndex?.keys?.sorted() {
        //                                let key = keys[indexPath.section]
        //
        //                                if let values = stringIndex?[key] {
        //                                    value = values[indexPath.row]
        //
        //                                    if let mediaID = value?["mediaID"] as? String {
        //                                        let alert = UIAlertController(  title: "VoiceBase Media ID",
        //                                                                        message: nil,
        //                                                                        preferredStyle: .alert)
        //                                        alert.makeOpaque()
        //
        //                                        alert.addTextField(configurationHandler: { (textField:UITextField) in
        //                                            textField.text = mediaID
        //                                        })
        //
        //                                        let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
        //                                            alertItem -> Void in
        //                                        })
        //                                        alert.addAction(okayAction)
        //
        //                                        self.present(alert, animated: true, completion: nil)
        //                                    }
        //                                }
        //                            }
        //                        }
        //                        mediaID.backgroundColor = UIColor.gray
        //                        actions.append(mediaID)
        
        if let mediaID = value["mediaID"] as? String {
            if let mediaList = globals.media.all?.list {
                if let mediaItem = mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                        return transcript.mediaID == mediaID
                    }).count == 1
                }).first {
                    let mediaItemRowAction = UITableViewRowAction(style: .normal, title: Constants.FA.BOOKMARK) { rowAction, indexPath in
                        if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            //                                                self.popover?.tableView.isEditing = false
                        }
                        self.performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: mediaItem)
                    }
                    mediaItemRowAction.backgroundColor = UIColor.controlBlue()
                    actions.append(mediaItemRowAction)
                }
            }
        }
        
        //                        print("actions",Thread.isMainThread)
        
        return actions
    }
    
    func detailDisclosure(tableView:UITableView,indexPath:IndexPath) -> Bool
    {
        guard indexPath.section >= 0, indexPath.section < self.stringIndex?.keys?.count else {
            return false
        }
        
        if let keys = self.stringIndex?.keys?.sorted() {
            if (indexPath.section >= 0) && (indexPath.section < keys.count) {
                let key = keys[indexPath.section]
                
                if (key == Constants.Strings.LocalDevice) || (key == Constants.Strings.OtherDevices) {
                    return false
                }
                
                if let values = self.stringIndex?[key], indexPath.row >= 0, indexPath.row < values.count {
                    let value = values[indexPath.row]
                    
                    guard let mediaID = value["mediaID"] as? String else {
                        return true
                    }
                    
                    guard let metadata = value["metadata"] as? [String:Any] else {
                        return true
                    }
                    
                    guard let device = metadata["device"] as? [String:Any] else {
                        return true
                    }
                    
                    guard let deviceName = device["name"] as? String else {
                        return true
                    }
                    
                    guard deviceName == UIDevice.current.deviceName else {
                        return false
                    }
                    
                    if globals.media.all?.list?.filter({ (mediaItem:MediaItem) -> Bool in
                        return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                            return transcript.mediaID == mediaID
                        }).count > 0
                    }).count == 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func detailAction(tableView:UITableView,indexPath:IndexPath)
    {
        var value : [String:Any]?
        
        if let keys = self.stringIndex?.keys?.sorted() {
            let key = keys[indexPath.section]
            
            if let values = self.stringIndex?[key] {
                value = values[indexPath.row]
                
                if let mediaID = value?["mediaID"] as? String,let title = value?["title"] as? String {
                    var actions = [AlertAction]()
                    
                    actions.append(AlertAction(title: "Delete", style: .destructive, action: {
                        let alert = UIAlertController(  title: "Confirm Deletion of VoiceBase Media Item",
                                                        message: title + "\n created on \(key == UIDevice.current.deviceName ? "this device" : key)",
                            preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                            alertItem -> Void in
                            VoiceBase.delete(mediaID: mediaID)
                            
                            self.stringIndex?[key]?.remove(at: indexPath.row)
                            
                            if self.stringIndex?[key]?.count == 0 {
                                self.stringIndex?[key] = nil
                            }
                            
                            var strings = [String]()
                            
                            if let keys = self.stringIndex?.keys?.sorted() {
                                for key in keys {
                                    if let values = self.stringIndex?[key] {
                                        for value in values {
                                            strings.append(value["title"] as! String)
                                        }
                                    }
                                }
                            }
                            
                            var counter = 0
                            
                            var counts = [Int]()
                            var indexes = [Int]()
                            
                            if let keys = self.stringIndex?.keys?.sorted() {
                                for key in keys {
                                    indexes.append(counter)
                                    
                                    if let count = self.stringIndex?[key]?.count {
                                        counts.append(count)
                                        counter += count
                                    }
                                }
                            }
                            
                            self.popover?.section.headerStrings = self.stringIndex?.keys?.sorted()
                            self.popover?.section.strings = strings.count > 0 ? strings : nil
                            //                                                            self.popover?.section.indexHeaders = self.popover?.section.headers
                            
                            self.popover?.section.counts = counts.count > 0 ? counts : nil
                            self.popover?.section.indexes = indexes.count > 0 ? indexes : nil
                            
                            self.popover?.tableView?.isEditing = false
                            
                            self.popover?.tableView?.reloadData()
                            self.popover?.tableView?.reloadData()
                        })
                        alert.addAction(yesAction)
                        
                        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
                            alertItem -> Void in
                            
                        })
                        alert.addAction(noAction)
                        
                        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction!) -> Void in
                            
                        })
                        alert.addAction(cancel)
                        
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    actions.append(AlertAction(title: "Media ID", style: .default, action: {
                        let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        alert.addTextField(configurationHandler: { (textField:UITextField) in
                            textField.text = mediaID
                        })
                        
                        let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                            alertItem -> Void in
                        })
                        alert.addAction(okayAction)
                        
                        self.present(alert, animated: true, completion: nil)
                    }))
                    
                    actions.append(AlertAction(title: "Details", style: .default, action: {
                        process(viewController: self.popover!, work: { () -> (Any?) in
                            var data : Any?
                            
                            VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
                                print(json as Any)
                                
                                data = json
                            }, onError: { (json:[String : Any]?) -> (Void) in
                                data = "VoiceBase Media Item\nNot Found"
                                globals.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                            })
                            
                            while data == nil {
                                Thread.sleep(forTimeInterval: 0.1)
                            }
                            
                            return data
                        }, completion: { (data:Any?) in
                            let json = data as? [String:Any]
                            
                            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.WEB_VIEW) as? UINavigationController,
                                let popover = navigationController.viewControllers[0] as? WebViewController {
                                
                                popover.html.fontSize = 12
                                popover.html.string = insertHead(VoiceBase.html(json),fontSize: popover.html.fontSize)
                                
                                popover.search = true
                                popover.content = .html
                                
                                popover.navigationItem.title = "VoiceBase Media Item"
                                
                                self.popover?.navigationController?.pushViewController(popover, animated: true)
                            }
                        })
                    }))
                    
                    actions.append(AlertAction(title: "Inspector", style: .default, action: {
                        process(viewController: self.popover!, work: { () -> (Any?) in
                            var data : Any?
                            
                            VoiceBase.details(mediaID: mediaID, completion: { (json:[String : Any]?) -> (Void) in
                                print(json as Any)
                                
                                data = json
                                
                            }, onError: { (json:[String : Any]?) -> (Void) in
                                data = "VoiceBase Media Item\nNot Found"
                                globals.alert(title:"VoiceBase Media Item\nNot Found", message:title)
                            })
                            
                            while data == nil {
                                Thread.sleep(forTimeInterval: 0.1)
                            }
                            
                            return data
                        }, completion: { (data:Any?) in
                            let json = data as? [String:Any]
                            
                            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                                popover.search = true
                                
                                popover.navigationItem.title = "VoiceBase Media Item"
                                
                                popover.stringsAny = json
                                popover.purpose = .showingVoiceBaseMediaItem
                                
                                self.popover?.navigationController?.pushViewController(popover, animated: true)
                            }
                        })
                    }))
                    
                    //                                    actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, action: nil))
                    actions.append(AlertAction(title: Constants.Strings.Cancel, style: .default, action: nil))
                    
                    globals.alert(title:"VoiceBase Media Item\nNot in Use", message:"While created on this device:\n\n\(title)\n\nno longer appears to be in use.", actions:actions)
                }
            }
        }
    }
    
    // Begin by separating media into what was created on this device and what was created on something else.
    func buildInitialList(mediaItems:[[String:Any]]?)
    {
        guard let mediaList = globals.media.all?.list, let mediaItems = mediaItems else {
            self.popover?.section.strings = nil
            self.popover?.section.headerStrings = nil
            self.popover?.section.counts = nil
            self.popover?.section.indexes = nil
            
            return
        }
        
        for mediaItem in mediaItems {
            if  let mediaID = mediaItem["mediaId"] as? String,
                let metadata = mediaItem["metadata"] as? [String:Any],
                let title = metadata["title"] as? String {
                if mediaList.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                        return transcript.mediaID == mediaID
                    }).count == 1
                }).count == 1 {
                    if self.stringIndex?[Constants.Strings.LocalDevice] == nil {
                        self.stringIndex?[Constants.Strings.LocalDevice] = [[String:String]]()
                    }
                    print(Constants.Strings.LocalDevice,mediaID)
                    self.stringIndex?[Constants.Strings.LocalDevice]?.append(["title":title,"mediaID":mediaID])
                } else {
                    if self.stringIndex?[Constants.Strings.OtherDevices] == nil {
                        self.stringIndex?[Constants.Strings.OtherDevices] = [[String:String]]()
                    }
                    print(Constants.Strings.OtherDevices,mediaID)
                    self.stringIndex?[Constants.Strings.OtherDevices]?.append(["title":title,"mediaID":mediaID])
                }
            } else {
                print("Unable to add: \(mediaItem)")
            }
        }
        
        print(self.stringIndex?[Constants.Strings.LocalDevice]?.count as Any,self.stringIndex?[Constants.Strings.OtherDevices]?.count as Any)
        
        if let keys = self.stringIndex?.keys {
            for key in keys {
                self.stringIndex?[key] = self.stringIndex?[key]?.sorted(by: {
                    var date0 = ($0["title"] as? String)?.components(separatedBy: "\n").first
                    var date1 = ($1["title"] as? String)?.components(separatedBy: "\n").first
                    
                    if let range = date0?.range(of: " PM") {
                        date0 = date0?.substring(to: range.lowerBound)
                    }
                    if let range = date0?.range(of: " AM") {
                        date0 = date0?.substring(to: range.lowerBound)
                    }
                    
                    if let range = date1?.range(of: " PM") {
                        date1 = date1?.substring(to: range.lowerBound)
                    }
                    if let range = date1?.range(of: " AM") {
                        date1 = date1?.substring(to: range.lowerBound)
                    }
                    
                    return Date(string: date0!) < Date(string: date1!)
                })
            }
        }
        
        var strings = [String]()
        
        if let keys = self.stringIndex?.keys?.sorted() {
            for key in keys {
                if let values = self.stringIndex?[key] {
                    for value in values {
                        strings.append(value["title"] as! String)
                    }
                }
            }
        }
        
        var counter = 0
        
        var counts = [Int]()
        var indexes = [Int]()
        
        if let keys = self.stringIndex?.keys?.sorted() {
            for key in keys {
                indexes.append(counter)
                
                if let count = self.stringIndex?[key]?.count {
                    counts.append(count)
                    counter += count
                }
            }
        }
        
        self.popover?.section.strings = strings.count > 0 ? strings : nil
        self.popover?.section.headerStrings = self.stringIndex?.keys?.sorted()
        self.popover?.section.counts = counts.count > 0 ? counts : nil
        self.popover?.section.indexes = indexes.count > 0 ? indexes : nil
    }
    
    func buildList(mediaItems:[[String:Any]]?)
    {
        guard let mediaItems = mediaItems else {
            self.popover?.section.strings = nil
            self.popover?.section.headerStrings = nil
            self.popover?.section.counts = nil
            self.popover?.section.indexes = nil
            
            return
        }
        
        for mediaItem in mediaItems {
            if  let mediaID = mediaItem["mediaId"] as? String,
                let metadata = mediaItem["metadata"] as? [String:Any],
                let title = metadata["title"] as? String,
                let device = metadata["device"] as? [String:String],
                var deviceName = device["name"],
                let mimd = metadata["mediaItem"] as? [String:String],
                let id = mimd["id"],
                let purpose = mimd["purpose"],
                let media = globals.mediaRepository.index?[id] {
                var transcript : VoiceBase?
                
                switch purpose.uppercased() {
                case Purpose.audio:
                    transcript = media.audioTranscript
                    
                case Purpose.video:
                    transcript = media.videoTranscript
                    
                default:
                    break
                }
                
                if  transcript?.transcript == nil,
                    transcript?.mediaID == nil,
                    transcript?.resultsTimer == nil,
                    let transcribing = transcript?.transcribing, !transcribing {
                    transcript?.mediaID = mediaID
                    transcript?.transcribing = true
                    
                    Thread.onMainThread() {
                        transcript?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: transcript as Any, selector: #selector(transcript?.monitor(_:)), userInfo: transcript?.uploadUserInfo(alert:false), repeats: true)
                    }
                }

                if deviceName == UIDevice.current.deviceName {
                    deviceName += " (this device)"
                }
                
                if self.stringIndex?[deviceName] == nil {
                    self.stringIndex?[deviceName] = [["title":title,"mediaID":mediaID,"metadata":metadata as Any]]
                } else {
                    self.stringIndex?[deviceName]?.append(["title":title,"mediaID":mediaID,"metadata":metadata as Any])
                }
            } else {
                print("Unable to add: \(mediaItem)")
            }
        }
        
        if let keys = self.stringIndex?.keys {
            for key in keys {
                self.stringIndex?[key] = self.stringIndex?[key]?.sorted(by: {
                    var date0 = ($0["title"] as? String)?.components(separatedBy: "\n").first
                    var date1 = ($1["title"] as? String)?.components(separatedBy: "\n").first
                    
                    if let range = date0?.range(of: " PM") {
                        date0 = date0?.substring(to: range.lowerBound)
                    }
                    if let range = date0?.range(of: " AM") {
                        date0 = date0?.substring(to: range.lowerBound)
                    }
                    
                    if let range = date1?.range(of: " PM") {
                        date1 = date1?.substring(to: range.lowerBound)
                    }
                    if let range = date1?.range(of: " AM") {
                        date1 = date1?.substring(to: range.lowerBound)
                    }
                    
                    return Date(string: date0!) < Date(string: date1!)
                })
            }
        }
        
        var strings = [String]()
        var stringIndex = [String:[String]]()
        
        if let keys = self.stringIndex?.keys?.sorted() {
            for key in keys {
                stringIndex[key] = [String]()
                if let values = self.stringIndex?[key] {
                    for value in values {
                        let title = value["title"] as! String
                        strings.append(title)
                        stringIndex[key]?.append(title)
                    }
                }
            }
        }
        
        var counter = 0
        
        var counts = [Int]()
        var indexes = [Int]()
        
        if let keys = self.stringIndex?.keys?.sorted() {
            for key in keys {
                indexes.append(counter)
                
                if let count = self.stringIndex?[key]?.count {
                    counts.append(count)
                    counter += count
                }
            }
        }
        
        self.popover?.section.strings = strings.count > 0 ? strings : nil
        self.popover?.section.stringIndex = stringIndex.keys.count > 0 ? stringIndex : nil
        self.popover?.section.headerStrings = self.stringIndex?.keys?.sorted()
        self.popover?.section.counts = counts.count > 0 ? counts : nil
        self.popover?.section.indexes = indexes.count > 0 ? indexes : nil
    }
    
    func processFirst(mediaItems:[[String:Any]]?)
    {
        guard var mediaItems = mediaItems else {
            return
        }
        
        guard let mediaID = mediaItems.first?["mediaId"] as? String else {
            print("No mediaId: \(String(describing: mediaItems.first))")
            
            if self.stringIndex?.dict == nil {
                Thread.sleep(forTimeInterval: 0.3)
            }
            
            // Would have preferred to dispatch to main here direclty but compiler crashed, using a notification instead.
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.VOICE_BASE_FINISHED), object: nil)
            }
            
            return
        }
        
        Thread.onMainThread() {
            self.popover?.activityIndicator?.startAnimating()
        }
        
        VoiceBase.metadata(mediaID:mediaID,completion:{ (dict:[String:Any]?) -> Void in
            //                                print(dict)
            guard let metadata = dict?["metadata"] as? [String:Any] else {
                mediaItems.removeFirst()
                self.processFirst(mediaItems:mediaItems)
                return
            }
            
            guard let title = metadata["title"] as? String else {
                mediaItems.removeFirst()
                self.processFirst(mediaItems:mediaItems)
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                while (self.popover?.tableView != nil) && self.popover!.tableView.isEditing {
                    //                                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                if  let mimd = metadata["mediaItem"] as? [String:Any],
                    let id = mimd["id"] as? String,
                    let purpose = mimd["purpose"] as? String,
                    let mediaItem = globals.mediaRepository.index?[id] {
                    var transcript : VoiceBase?
                    
                    switch purpose.uppercased() {
                    case Purpose.audio:
                        transcript = mediaItem.audioTranscript
                        
                    case Purpose.video:
                        transcript = mediaItem.videoTranscript
                        
                    default:
                        break
                    }
                    
                    if  transcript?.transcript == nil,
                        transcript?.mediaID == nil,
                        transcript?.resultsTimer == nil,
                        let transcribing = transcript?.transcribing, !transcribing {
                        transcript?.mediaID = mediaID
                        transcript?.transcribing = true
                        
                        Thread.onMainThread() {
                            transcript?.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: transcript as Any, selector: #selector(transcript?.monitor(_:)), userInfo: transcript?.uploadUserInfo(alert:false), repeats: true)
                        }
                    }
                } else {
                    
                }

                if  let device = metadata["device"] as? [String:String],
                    var deviceName = device["name"] {
                    if deviceName == UIDevice.current.deviceName {
                        deviceName += " (this device)"
                    }
                    
                    if self.stringIndex?[deviceName] == nil {
                        self.stringIndex?[deviceName] = [["title":title,"mediaID":mediaID,"metadata":metadata as Any]]
                    } else {
                        self.stringIndex?[deviceName]?.append(["title":title,"mediaID":mediaID,"metadata":metadata as Any])
                    }
                    // Update the popover section information and reload the popover tableview to update
                    // Need to find a way to remove mediaItems from Local Device and Other Devices sections when we find
                    // the actual device name
                    //                                    print(self.stringIndex?.dict as Any)
                    
                    if let records = self.stringIndex?[Constants.Strings.LocalDevice] {
                        var i = 0
                        for record in records {
                            if (record["mediaID"] as? String == mediaID) {
                                print("removing: \(mediaID)")
                                self.stringIndex?[Constants.Strings.LocalDevice]?.remove(at: i)
                            }
                            i += 1
                        }
                        if self.stringIndex?[Constants.Strings.LocalDevice]?.count == 0 {
                            self.stringIndex?[Constants.Strings.LocalDevice] = nil
                        }
                    }
                    
                    if let records = self.stringIndex?[Constants.Strings.OtherDevices] {
                        var i = 0
                        for record in records {
                            if (record["mediaID"] as? String == mediaID) {
                                print("removing: \(mediaID)")
                                self.stringIndex?[Constants.Strings.OtherDevices]?.remove(at: i)
                            }
                            i += 1
                        }
                        if self.stringIndex?[Constants.Strings.OtherDevices]?.count == 0 {
                            self.stringIndex?[Constants.Strings.OtherDevices] = nil
                        }
                    }
                    
                    if let keys = self.stringIndex?.keys {
                        for key in keys {
                            self.stringIndex?[key] = self.stringIndex?[key]?.sorted(by: {
                                var date0 = ($0["title"] as? String)?.components(separatedBy: "\n").first
                                var date1 = ($1["title"] as? String)?.components(separatedBy: "\n").first
                                
                                if let range = date0?.range(of: " PM") {
                                    date0 = date0?.substring(to: range.lowerBound)
                                }
                                if let range = date0?.range(of: " AM") {
                                    date0 = date0?.substring(to: range.lowerBound)
                                }
                                
                                if let range = date1?.range(of: " PM") {
                                    date1 = date1?.substring(to: range.lowerBound)
                                }
                                if let range = date1?.range(of: " AM") {
                                    date1 = date1?.substring(to: range.lowerBound)
                                }
                                
                                return Date(string: date0!) < Date(string: date1!)
                                //                                        return stringWithoutPrefixes($0["title"] as? String) < stringWithoutPrefixes($1["title"] as? String)
                            })
                        }
                    }
                    
                    
                    var strings = [String]()
                    
                    if let keys = self.stringIndex?.keys?.sorted() {
                        for key in keys {
                            if let values = self.stringIndex?[key] {
                                for value in values {
                                    strings.append(value["title"] as! String)
                                }
                            }
                        }
                    }
                    
                    self.popover?.detailDisclosure = self.detailDisclosure
                    self.popover?.detailAction = self.detailAction
                    
                    self.popover?.section.headerStrings = self.stringIndex?.keys?.sorted()
                    self.popover?.section.strings = strings.count > 0 ? strings : nil
                    //                                    self.popover?.section.indexHeaders = self.popover?.section.headers
                    
                    var counter = 0
                    
                    var counts = [Int]()
                    var indexes = [Int]()
                    
                    if let keys = self.stringIndex?.keys?.sorted() {
                        for key in keys {
                            indexes.append(counter)
                            
                            if let count = self.stringIndex?[key]?.count {
                                counts.append(count)
                                counter += count
                            }
                        }
                    }
                    
                    self.popover?.section.counts = counts.count > 0 ? counts : nil
                    self.popover?.section.indexes = indexes.count > 0 ? indexes : nil
                    
                    //                                    self.popover?.section.showIndex = false
                    self.popover?.section.showHeaders = true
                    
                    if (self.popover?.tableView != nil) {
                        Thread.onMainThread() {
                            if self.popover?.tableView.isEditing == false {
                                self.popover?.tableView.reloadData()
                                self.popover?.setPreferredContentSize()
                            } else {
                                self.popover?.changesPending = true
                            }
                        }
                    }
                } else {
                    print("Unable to add: \(dict!.description)")
                }
                
                print(self.stringIndex?.keys?.count as Any,self.stringIndex?[Constants.Strings.LocalDevice]?.count as Any,self.stringIndex?[Constants.Strings.OtherDevices]?.count as Any)
                
                // MUST be inside the background dispatch to serialize processing.
                mediaItems.removeFirst()
                self.processFirst(mediaItems:mediaItems)
            }
        }, onError: { (dict:[String:Any]?) -> Void in
            print("ERROR: \(String(describing: dict))")
            
            mediaItems.removeFirst()
            self.processFirst(mediaItems:mediaItems)
        })
    }
    
    func showMenu(action:String?,mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
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
                if globals.media.active!.mediaItems!.contains(mediaItem) {
                    if tableView!.isEditing {
                        tableView?.setEditing(false, animated: true)
                        DispatchQueue.global(qos: .background).async {
                            Thread.sleep(forTimeInterval: 0.1)
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    } else {
                        selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                    }
                } else {
                    //                        dismiss(animated: true, completion: nil)
                    alert(viewController:self,title: "Not in List",message: "\"\(mediaItem.text!)\"\nis not in the list \"\(globals.contextTitle!).\"  Show \"All\" and try again.",completion:nil)
                }
            } else {
                //                    dismiss(animated: true, completion: nil)
                alert(viewController:self,title: "Media Item Not Found!",message: "Oops, this should never happen!",completion:nil)
            }
            break
            
        case Constants.Strings.Media_Playing:
            fallthrough
            
        case Constants.Strings.Media_Paused:
//            globals.gotoPlayingPaused = true
            
            globals.mediaPlayer.killPIP = true

            performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: globals.mediaPlayer.mediaItem)
            break
            
        case Constants.Strings.Scripture_Index:
            if (globals.media.active?.scriptureIndex?.eligible == nil) {
                alert(viewController:self,title:"No Scripture Index Available",message: "The Scripture references for these media items are not specific.",completion:nil)
            } else {
                if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SCRIPTURE_INDEX) as? ScriptureIndexViewController {
                    
                    viewController.mediaListGroupSort = globals.media.active
                    
                    navigationController?.pushViewController(viewController, animated: true)
                }
            }
            
            //                performSegue(withIdentifier: Constants.SEGUE.SHOW_SCRIPTURE_INDEX, sender: nil)
            break
            
        case Constants.Strings.Lexicon_Index:
            if (globals.media.active?.lexicon?.eligible == nil) {
                alert(viewController:self,title:"No Lexicon Index Available",
                      message: "These media items do not have HTML transcripts.",
                      completion:nil)
            } else {
                if let viewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.LEXICON_INDEX) as? LexiconIndexViewController {
                    
                    viewController.mediaListGroupSort = globals.media.active
                    
                    navigationController?.pushViewController(viewController, animated: true)
                }
            }
            break
            
        case Constants.Strings.History:
            if globals.relevantHistoryList == nil {
                alert(viewController:self,title: "History is empty.",
                      message: nil,
                      completion:nil)
            } else {
                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .overCurrentContext
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.barButtonItem = showButton
                    
                    popover.navigationItem.title = Constants.Strings.History
                    
                    popover.delegate = self
                    popover.purpose = .selectingHistory
                    
                    popover.section.strings = globals.relevantHistoryList
//
//                    popover.section.showIndex = false
//                    popover.section.showHeaders = false
                    
                    popover.vc = self.splitViewController
                    
                    present(navigationController, animated: true, completion: {
                        self.presentingVC = navigationController
//                        DispatchQueue.main.async(execute: { () -> Void in
//                            // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
//                            navigationController.popoverPresentationController?.passthroughViews = nil
//                        })
                    })
                }
            }
            break
            
        case Constants.Strings.Clear_History:
            firstSecondCancel(viewController: self, title: "Delete History?", message: nil,
                              firstTitle: "Delete", firstAction:    {
                                                                        globals.history = nil
                                                                        let defaults = UserDefaults.standard
                                                                        defaults.removeObject(forKey: Constants.SETTINGS.HISTORY)
                                                                        defaults.synchronize()
                                                                    }, firstStyle: .destructive,
                              secondTitle: nil, secondAction: nil, secondStyle: .default,
                              cancelAction: nil)
            break
            
        case Constants.Strings.Live:
            if  globals.streamEntries?.count > 0, globals.reachability.currentReachabilityStatus != .notReachable, //globals.streamEntries?.count > 0,
                let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.delegate = self
                
                popover.navigationItem.title = Constants.Strings.Live_Events
                
                popover.allowsSelection = true
                
                // An enhancement to selectively highlight (select)
                popover.shouldSelect = { (indexPath:IndexPath) -> Bool in
                    if let keys:[String] = popover.section.stringIndex?.keys.map({ (string:String) -> String in
                        return string
                    }).sorted() {
                        // We have to use sorted() because the order of keys is undefined.
                        // We are assuming they are presented in sort order in the tableView
                        return keys[indexPath.section] == Constants.Strings.Playing
                    }
                    
                    return false
                }

                // An alternative to rowClickedAt
                popover.didSelect = { (indexPath:IndexPath) -> Void in
                    if let keys:[String] = popover.section.stringIndex?.keys.map({ (string:String) -> String in
                        return string
                    }).sorted() {
                        // We have to use sorted() because the order of keys is undefined.
                        // We are assuming they are presented in sort order in the tableView
                        let key = keys[indexPath.section]
                        
                        if key == Constants.Strings.Playing {
                            self.dismiss(animated: true, completion: nil)

                            if let streamEntry = StreamEntry(globals.streamEntryIndex?[key]?[indexPath.row]) {
                                self.performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: streamEntry)
                            }
                        }
                    }
                }
                
                popover.search = true
                
                popover.refresh = {
                    popover.section.strings = nil
                    popover.section.headerStrings = nil
                    popover.section.counts = nil
                    popover.section.indexes = nil
                    
                    popover.tableView?.reloadData()
                    
                    self.loadLive() {
                        if #available(iOS 10.0, *) {
                            if let isRefreshing = popover.tableView?.refreshControl?.isRefreshing, isRefreshing {
                                popover.refreshControl?.endRefreshing()
                            }
                        } else {
                            // Fallback on earlier versions
                            if popover.isRefreshing {
                                popover.refreshControl?.endRefreshing()
                                popover.isRefreshing = false
                            }
                        }
                        
                        //                                popover.section.strings = globals.streamStrings
                        popover.section.stringIndex = globals.streamStringIndex
                        
                        popover.tableView.reloadData()
                    }
                }
                
                // These assume the streamEntries have been collected!
//                popover.section.strings = globals.streamStrings
//                popover.section.stringIndex = globals.streamStringIndex
                
                // This was an experiment - finally sorted out the need to set section.indexes/counts when showIndex is false
//                popover.stringsFunction = { (Void) -> [String]? in
//                    self.loadLive(completion: nil)
//                    return globals.streamStrings
//                }

                // Makes no sense w/o section.showIndex also being true - UNLESS you're using section.stringIndex
                popover.section.showHeaders = true
                
                present(navigationController, animated: true, completion: {
                    // This is an alternative to popover.stringsFunction
                    popover.activityIndicator.isHidden = false
                    popover.activityIndicator.startAnimating()
                    
                    self.loadLive() {
                        popover.section.stringIndex = globals.streamStringIndex
                        popover.tableView.reloadData()
                        
                        popover.activityIndicator.stopAnimating()
                        popover.activityIndicator.isHidden = true
                    }

                    self.presentingVC = navigationController
                    //                        DispatchQueue.main.async(execute: { () -> Void in
                    //                            // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                    //                            navigationController.popoverPresentationController?.passthroughViews = nil
                    //                        })
                })
            }
            break
            
        case Constants.Strings.Settings:
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.SETTINGS_NAVCON) as? UINavigationController,
                let _ = navigationController.viewControllers[0] as? SettingsViewController {
//                if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                    let hClass = traitCollection.horizontalSizeClass
//
//                    if hClass == .compact {
//                        navigationController.modalPresentationStyle = .overCurrentContext
//                    } else {
//                        // I don't think this ever happens: collapsed and regular
//                        navigationController.modalPresentationStyle = .popover
//                    }
//                } else {
//                    navigationController.modalPresentationStyle = .popover
//                }
                navigationController.modalPresentationStyle = .popover
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = showButton
                
                present(navigationController, animated: true, completion: {
                    self.presentingVC = navigationController
//                    DispatchQueue.main.async(execute: { () -> Void in
//                        // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
//                        navigationController.popoverPresentationController?.passthroughViews = nil
//                    })
                })
            }
            break
            
        case Constants.Strings.VoiceBase_API_Key:
            let alert = UIAlertController(  title: Constants.Strings.VoiceBase_API_Key,
                                            message: nil,
                                            preferredStyle: .alert)
            alert.makeOpaque()
            
            alert.addTextField(configurationHandler: { (textField:UITextField) in
                textField.text = globals.voiceBaseAPIKey
            })
            
            let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: {
                alertItem -> Void in
                globals.voiceBaseAPIKey = (alert.textFields![0] as UITextField).text
            })
            alert.addAction(okayAction)

            let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                (action : UIAlertAction!) -> Void in
            })
            alert.addAction(cancel)
            
            present(alert, animated: true, completion: nil)
            break
            
        case Constants.Strings.VoiceBase_Media:
            guard globals.reachability.currentReachabilityStatus != .notReachable else {
                return
            }
            
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
                navigationController.modalPresentationStyle = .overCurrentContext
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = self.showButton
                
                self.popover = navigationController.viewControllers[0] as? PopoverTableViewController
                
                self.deleteButton = UIBarButtonItem(title: "Delete All", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.deleteAllMedia))
                //                    deleteButton.setTitleTextAttributes(Constants.Fonts.Attributes.destructive, for: UIControlState.normal)
                
                self.popover?.navigationItem.leftBarButtonItem = self.deleteButton
                //                            self.deleteButton?.isEnabled = false
                
                self.popover?.navigationItem.title = Constants.Strings.VoiceBase_Media
                
                self.popover?.refresh = {
                    self.popover?.section.strings = nil
                    self.popover?.section.headerStrings = nil
                    self.popover?.section.counts = nil
                    self.popover?.section.indexes = nil
                    
                    self.popover?.tableView?.reloadData()
                    
                    VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        // Begin by separating media into what was created on this device and what was created on something else.
                        self.stringIndex = StringIndex()
                        
                        //                                self.buildInitialList(mediaItems:mediaItems)
                        self.buildList(mediaItems:mediaItems)
                        
                        self.popover?.updateSearchResults()
                        self.popover?.tableView?.reloadData()
                        
                        //                                // Start over and get specific devices
                        //                                self.processFirst(mediaItems:mediaItems)
                        
                        if #available(iOS 10.0, *) {
                            if let isRefreshing = self.popover?.tableView?.refreshControl?.isRefreshing, isRefreshing {
                                self.popover?.refreshControl?.endRefreshing()
                            }
                        } else {
                            // Fallback on earlier versions
                            if let isRefreshing = self.popover?.isRefreshing, isRefreshing {
                                self.popover?.refreshControl?.endRefreshing()
                                self.popover?.isRefreshing = false
                            }
                        }
                    },onError: nil)
                }
                
                self.popover?.editActionsAtIndexPath = self.rowActions
                
                self.popover?.delegate = self
                self.popover?.purpose = .showingVoiceBaseMediaItems
                self.popover?.allowsSelection = false
                
                self.popover?.section.showHeaders = true
                
                self.popover?.search = true
                
                self.popover?.vc = self.splitViewController
                
                //                    popover.popoverPresentationController?.passthroughViews = [globals.splitViewController.view!]
                
                self.present(navigationController, animated: true, completion: {
                    self.popover?.activityIndicator.startAnimating()
                    
                    VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
                        guard let mediaItems = json?["media"] as? [[String:Any]] else {
                            return
                        }
                        
                        // Begin by separating media into what was created on this device and what was created on something else.
                        self.stringIndex = StringIndex()
                        
                        //                                self.buildInitialList(mediaItems:mediaItems)
                        self.buildList(mediaItems:mediaItems)
                        
                        self.popover?.updateSearchResults()
                        
                        Thread.onMainThread(block: { (Void) -> (Void) in
                            self.popover?.tableView?.reloadData()
                            self.popover?.activityIndicator.stopAnimating()
                        })
                    },onError: nil)
                    
                    self.presentingVC = navigationController
                })
            }


//            VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
//                self.stringIndex = StringIndex()
//
//                guard let mediaItems = json?["media"] as? [[String:Any]] else {
//                    return
//                }
//
//                if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController {
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        self.popover = navigationController.viewControllers[0] as? PopoverTableViewController
//                        
//                        self.popover?.refresh = {
//                            self.popover?.section.strings = nil
//                            self.popover?.section.headerStrings = nil
//                            self.popover?.section.counts = nil
//                            self.popover?.section.indexes = nil
//                            
//                            self.popover?.tableView?.reloadData()
//
//                            VoiceBase.all(completion:{(json:[String:Any]?) -> Void in
//                                guard let mediaItems = json?["media"] as? [[String:Any]] else {
//                                    return
//                                }
//                                
//                                // Begin by separating media into what was created on this device and what was created on something else.
//                                self.stringIndex = StringIndex()
//                                
////                                self.buildInitialList(mediaItems:mediaItems)
//                                self.buildList(mediaItems:mediaItems)
//                                
//                                self.popover?.updateSearchResults()
//                                self.popover?.tableView?.reloadData()
//                                
////                                // Start over and get specific devices
////                                self.processFirst(mediaItems:mediaItems)
//
//                                if #available(iOS 10.0, *) {
//                                    if let isRefreshing = self.popover?.tableView?.refreshControl?.isRefreshing, isRefreshing {
//                                        self.popover?.refreshControl?.endRefreshing()
//                                    }
//                                } else {
//                                    // Fallback on earlier versions
//                                    if let isRefreshing = self.popover?.isRefreshing, isRefreshing {
//                                        self.popover?.refreshControl?.endRefreshing()
//                                        self.popover?.isRefreshing = false
//                                    }
//                                }
//                            },onError: nil)
//                        }
//                        
//                        self.popover?.editActionsAtIndexPath = self.rowActions
//                        
//                        self.popover?.delegate = self
//                        self.popover?.purpose = .showingVoiceBaseMediaItems
//                        self.popover?.allowsSelection = false
//                        
//                        self.popover?.section.showHeaders = true
//                        
//                        self.popover?.search = true
//                        
//                        self.popover?.vc = self.splitViewController
//                        
////                        self.buildInitialList(mediaItems:mediaItems)
//                        self.buildList(mediaItems:mediaItems)
//                        
//                        Thread.onMainThread() {
//                            navigationController.modalPresentationStyle = .overCurrentContext
//                            
//                            navigationController.popoverPresentationController?.permittedArrowDirections = .up
//                            navigationController.popoverPresentationController?.delegate = self
//                            
//                            navigationController.popoverPresentationController?.barButtonItem = self.showButton
//                            
//                            self.deleteButton = UIBarButtonItem(title: "Delete All", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.deleteAllMedia))
//                            //                    deleteButton.setTitleTextAttributes(Constants.Fonts.Attributes.destructive, for: UIControlState.normal)
//                            
//                            self.popover?.navigationItem.leftBarButtonItem = self.deleteButton
////                            self.deleteButton?.isEnabled = false
//                            
//                            self.popover?.navigationItem.title = "VoiceBase Media"
//                            
//                            //                    popover.popoverPresentationController?.passthroughViews = [globals.splitViewController.view!]
//                            
//                            self.present(navigationController, animated: true, completion: {
//    //                            self.popover?.activityIndicator.startAnimating()
//                                self.presentingVC = navigationController
//                            })
//                        }
//                        
//                        // Start over and get specific devices
////                        self.processFirst(mediaItems:mediaItems)
//                    }
//                }
//            }, onError: nil)
            break
            
        default:
            break
        }
    }

    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:rowClickedAtIndex", completion: nil)
            return
        }
        
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        guard let strings = strings else {
            return
        }
        
        guard index < strings.count else {
            return
        }
        
        let string = strings[index]
        
        switch purpose {
        case .selectingCategory:
            guard (globals.mediaCategory.selected != string) || (globals.mediaRepository.list == nil) else {
                return
            }
            
            globals.mediaCategory.selected = string
            
            globals.mediaPlayer.unobserve()
            
            globals.mediaPlayer.pause()

            globals.cancelAllDownloads()
            globals.clearDisplay()
            
            Thread.onMainThread() {
                self.tableView?.reloadData()
                
                self.tableView?.isHidden = true
                if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
                    self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
                }

                if self.splitViewController?.viewControllers.count > 1 {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
                }
            }
            
            tagLabel.text = nil
            
            // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
            globals.media = Globals.Media()
            globals.media.globals = globals

            loadMediaItems()
            {
                self.loadCompletion() // rowClickedCompletion()
            }
            break
            
        case .selectingCellSearch:
            var searchText = strings[index].uppercased()
            
            if let range = searchText.range(of: " (") {
                searchText = searchText.substring(to: range.lowerBound)
            }
            
            globals.search.active = true
            globals.search.text = searchText
            
            tableView?.setEditing(false, animated: true)
            searchBar.text = searchText
            searchBar.showsCancelButton = true
            
            updateSearchResults(searchText,completion: nil)
            break
            
        case .selectingCellAction:
            switch string {
            case Constants.Strings.Download_Audio:
                mediaItem?.audioDownload?.download()
                NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.downloadFailed(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: mediaItem?.audioDownload)
                break
                
            case Constants.Strings.Delete_Audio_Download:
                mediaItem?.audioDownload?.delete()
                break
                
            case Constants.Strings.Cancel_Audio_Download:
                mediaItem?.audioDownload?.cancelOrDelete()
                break
                
            default:
                break
            }
            break
            
        case .selectingLexicon:
            _ = navigationController?.popViewController(animated: true)
            
//            let string = strings[index]
            
            if let range = string.range(of: " (") {
                let searchText = string.substring(to: range.lowerBound).uppercased()
                
                globals.search.active = true
                globals.search.text = searchText
                
                Thread.onMainThread() {
                    self.searchBar.text = searchText
                    self.searchBar.showsCancelButton = true
                }
                
                // Show the results directly rather than by executing a search
                if let list:[MediaItem]? = globals.media.toSearch?.lexicon?.words?[searchText]?.map({ (mediaItemFrequency:(key: MediaItem,value: Int)) -> MediaItem in
                    return mediaItemFrequency.key
                }) {
                    updateSearches(searchText:searchText,mediaItems: list)
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
                        //                        dismiss(animated: true, completion: nil)
                        alert(  viewController:self,
                                title:"Not in List",
                                message: "\"\(mediaItem.text!)\"\nis not in the list \"\(globals.contextTitle!).\"  Show \"All\" and try again.",
                                completion:nil)
                    }
                } else {
                    alert(viewController:self,title:"Media Item Not Found!",
                          message: "Oops, this should never happen!",
                          completion:nil)
                }
            }
            break
            
        case .selectingTags:
            
            // Should we be showing globals.media.active!.mediaItemTags instead?  That would be the equivalent of drilling down.
            
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                //                    if (index >= 0) && (index <= globals.media.all!.mediaItemTags!.count) {
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch string {
                    case Constants.Strings.All:
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
                        Thread.onMainThread() {
                            globals.clearDisplay()
                            
                            self.tableView?.reloadData()
                            
                            //                            self.listActivityIndicator.isHidden = false
                            //                            self.listActivityIndicator.startAnimating()
                            
                            self.startAnimating()
                            
                            self.disableBarButtons()
                        }
                        
                        if (globals.search.active) {
                            self.updateSearchResults(globals.search.text,completion: nil)
                        }
                        
                        Thread.onMainThread() {
                            globals.setupDisplay(globals.media.active)
                            
                            self.tableView?.reloadData()
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
                            //                            self.listActivityIndicator.stopAnimating()
                            //                            self.listActivityIndicator.isHidden = true
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                            self.setupActionAndTagsButton()
                            self.setupTag()
                        }
                    }
                } else {
                    print("Index out of range")
                }
            })
            break
            
        case .selectingSection:
            if let section = globals.media.active?.section?.headerStrings?.index(of: strings[index]) {
                let indexPath = IndexPath(row: 0, section: section)
                
                if !(indexPath.section < tableView?.numberOfSections) {
                    NSLog("indexPath section ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView!.numberOfSections)")
                    break
                }
                
                if !(indexPath.row < tableView?.numberOfRows(inSection: indexPath.section)) {
                    NSLog("indexPath row ERROR in MTVC .selectingSection")
                    NSLog("Section: \(indexPath.section)")
                    NSLog("TableView Number of Sections: \(tableView!.numberOfSections)")
                    NSLog("Row: \(indexPath.row)")
                    NSLog("TableView Number of Rows in Section: \(tableView!.numberOfRows(inSection: indexPath.section))")
                    break
                }
                
//                tableView.setEditing(false, animated: false)
//                tableView?.isEditing = false

                //Can't use this reliably w/ variable row heights.
                tableView?.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            }
            break
            
        case .selectingGrouping:
            //            dismiss(animated: true, completion: nil)
            globals.grouping = globals.groupings[index]
            
            if globals.media.need.grouping {
                globals.clearDisplay()
                
                tableView?.reloadData()
                
                startAnimating()
                
                disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    globals.setupDisplay(globals.media.active)
                    
                    Thread.onMainThread() {
                        self.tableView?.reloadData()
                        
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self.stopAnimating()
                        
                        self.enableBarButtons()
                    }
                })
            }
            break
            
        case .selectingSorting:
            globals.sorting = Constants.sortings[index]
            
            if (globals.media.need.sorting) {
                globals.clearDisplay()
                
                Thread.onMainThread() {
                    self.tableView?.reloadData()
                    
                    self.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        globals.setupDisplay(globals.media.active)
                        
                        Thread.onMainThread() {
                            self.tableView?.reloadData()
                            
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                        }
                    })
                }
            }
            break
            
        case .selectingShow:
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            showMenu(action:strings[index],mediaItem:mediaItem)
            break
            
        case .selectingAction:
            switch string {
            case Constants.Strings.View_List:
                if let string = globals.media.active?.html?.string {
                    presentHTMLModal(viewController: self, medaiItem: nil, style: .overFullScreen, title: globals.contextTitle, htmlString: string)
                } else {
                    process(viewController: self, work: { () -> (Any?) in
                        if globals.media.active?.html?.string == nil {
                            globals.media.active?.html?.string = setupMediaItemsHTMLGlobal(includeURLs: true, includeColumns: true)
                        }
                        return globals.media.active?.html?.string
                    }, completion: { (data:Any?) in
                        presentHTMLModal(viewController: self, medaiItem: nil, style: .overFullScreen, title: globals.contextTitle, htmlString: data as? String)
                    })
                }
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

extension MediaTableViewController : URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset: Int64, expectedTotalBytes: Int64)
    {
        print("URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:")
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        print("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
//        var success = false
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        print("countOfBytesReceived: \(downloadTask.countOfBytesReceived)")
        
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
                    } catch let error as NSError {
                        print("failed to remove old json file: \(error.localizedDescription)")
                    }
                }
                
                do {
                    try fileManager.copyItem(at: location, to: destinationURL)
                    try fileManager.removeItem(at: location)
//                    success = true
                } catch let error as NSError {
                    print("failed to copy new json file to Documents: \(error.localizedDescription)")
                }
            } else {
                print("failed to get destinationURL")
            }
        } else {
            print("downloadTask.countOfBytesReceived not > 0")
        }
        
//        if success {
//            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
//            // file and successfully copied it to the Documents directory.
//            
//            // URL call back does NOT run on the main queue
//            DispatchQueue.main.async(execute: { () -> Void in
//                globals.mediaPlayer.pause() // IfPlaying
//                
//                globals.mediaPlayer.view?.isHidden = true
//                globals.mediaPlayer.view?.removeFromSuperview()
//                
//                //                self.loadCategories()
//                
//                self.loadMediaItems()
//                    {
//                        //                    self.refreshControl?.endRefreshing()
//                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                        //                    globals.isRefreshing = false
//                }
//            })
//        } else {
//            DispatchQueue.main.async(execute: { () -> Void in
//                if (UIApplication.shared.applicationState == UIApplicationState.active) {
//                    alert(viewController:self,title:"Unable to Download Media",
//                          message: "Please try to refresh the list again.",
//                          completion:nil)
//                }
//                
//                self.refreshControl!.endRefreshing()
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//                
//                globals.setupDisplay(globals.media.active)
//                self.tableView?.reloadData()
//                
//                globals.isRefreshing = false
//                
//                self.setupViews()
//            })
//        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        print("URLSession:task:didCompleteWithError")

        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
        //        removeTempFiles()
        
        if let filename = task.taskDescription {
            print("filename: \(filename)")
            
            if let error = error {
                print("Download failed for: \(task.taskDescription!) with error: \(error.localizedDescription)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Couldn't get categories from network, try to get media, use last downloaded
                    if let mediaFileName = globals.mediaCategory.filename {
                        downloadJSON(url:Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!,filename:mediaFileName)
                    }
                    break
                    
                case globals.mediaCategory.filename!:
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
                print("Download succeeded for: \(task.taskDescription!)")

                switch filename {
                case Constants.JSON.FILENAME.CATEGORIES:
                    // Load media
                    if let mediaFileName = globals.mediaCategory.filename {
                        downloadJSON(url:Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!,filename:mediaFileName)
                    }
                    break
                    
                case globals.mediaCategory.filename!:
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

extension MediaTableViewController : UIAdaptivePresentationControllerDelegate
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

extension MediaTableViewController : UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool
    {
        return popoverPresentationController.presentedViewController.modalPresentationStyle == .popover
    }
}

class MediaTableViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class MediaTableViewController : UIViewController // MediaController
{
    var popover : PopoverTableViewController?
    var deleteButton : UIBarButtonItem?
    
    var stringIndex : StringIndex? // [String:[String]]()

    func finish()
    {
        Thread.onMainThread() {
            self.popover?.activityIndicator?.stopAnimating()
            
            if self.stringIndex?.dict == nil {
                self.dismiss(animated: true, completion: nil)
                globals.alert(title: "No VoiceBase Media Items", message: "There are no media files stored on VoiceBase for transcription.")
            } else {
                self.deleteButton?.isEnabled = true
            }
        }
    }
    
    var changesPending = false
    
    var presentingVC : UIViewController?
    
    var jsonSource:JSONSource = .direct
    
    override var canBecomeFirstResponder : Bool
    {
        return true //let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
    {
        globals.motionEnded(motion,event: event)
    }

    func deleteAllMedia()
    {
        let alert = UIAlertController(  title: "Confirm Deletion of All VoiceBase Media Items",
                                        message: nil,
                                        preferredStyle: .alert)
        alert.makeOpaque()
        
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
            alertItem -> Void in
            self.dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
            
            VoiceBase.deleteAll()
        })
        alert.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
            alertItem -> Void in
            
        })
        alert.addAction(noAction)
        
        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        alert.addAction(cancel)
        
        // For .actionSheet style
//        alert.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
        
        present(alert, animated: true, completion: nil)
    }
    
    func downloadFailed(_ notification:NSNotification)
    {
//        if let download = notification.object as? Download {
//            if let index = download.task?.taskDescription?.range(of: "."),
//                let id = download.task?.taskDescription?.substring(to: index.lowerBound),
//                let mediaItem = globals.media.all?.index?[id] {
//                globals.alert(title: "Download Failed", message: "For \(mediaItem.title!)")
//            } else {
//                globals.alert(title: "Download Failed", message: nil)
//            }
//        }
    }
    
    @IBOutlet weak var logo: UIImageView!
    {
        didSet {
            logo.isHidden = true
        }
    }
    
//    var tagsToolbar: UIToolbar?
//    @IBOutlet weak var tagsButton: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    
    var refreshControl:UIRefreshControl?

    var session:URLSession? // Used for JSON
    
    @IBOutlet weak var mediaCategoryButton: UIButton!
    @IBAction func mediaCategoryButtonAction(_ button: UIButton)
    {
//        print("categoryButtonAction")
        
        guard Thread.isMainThread else {
            return
        }

        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {

            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                let hClass = traitCollection.horizontalSizeClass
                
                if hClass == .compact {
                    navigationController.modalPresentationStyle = .overCurrentContext
                } else {
                    // I don't think this ever happens: collapsed and regular
                    navigationController.modalPresentationStyle = .popover
                }
            } else {
                navigationController.modalPresentationStyle = .popover
            }

//            navigationController.modalPresentationStyle = .overCurrentContext

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.sourceView = self.view
            navigationController.popoverPresentationController?.sourceRect = mediaCategoryButton.frame

            popover.navigationItem.title = Constants.Strings.Select_Category
            
            popover.delegate = self
            popover.purpose = .selectingCategory
            
            popover.section.strings = globals.mediaCategory.names
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self.splitViewController
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var searchBar: UISearchBar!
    {
        didSet {
            searchBar.autocapitalizationType = .none
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    {
//        get {
//            return _tableView
//        }
//        set {
//            _tableView = newValue
//            
//            refreshControl = UIRefreshControl()
//            refreshControl?.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
//            
//            //            refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
//            
//            _tableView?.addSubview(refreshControl!)
//            
//            _tableView?.allowsSelection = true
//            
//            //Eliminates blank cells at end.
//            _tableView?.tableFooterView = UIView()
//        }
        didSet {
            tableView.register(MediaTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "MediaTableViewController")

            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(MediaTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
            
//            refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")

            tableView?.addSubview(refreshControl!)
            
            tableView?.allowsSelection = true

            //Eliminates blank cells at end.
            tableView?.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(_ button: UIBarButtonItem)
    {
        guard Thread.isMainThread else {
            return
        }

        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            // In case one is already showing
            dismiss(animated: true, completion: {
                self.presentingVC = nil
            })
      
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

//            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                let hClass = traitCollection.horizontalSizeClass
//                
//                if hClass == .compact {
//                    navigationController.modalPresentationStyle = .popover
//                } else {
//                    // I don't think this ever happens: collapsed and regular
//                    navigationController.modalPresentationStyle = .popover
//                }
//            } else {
//                navigationController.modalPresentationStyle = .popover
//            }

            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
//            popover.navigationItem.title = "Select" // Constants.Strings.Show
//            popover.navigationController?.isNavigationBarHidden = false
            
            popover.delegate = self
            popover.purpose = .selectingShow
            
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
            if (globals.display.mediaItems != nil) && (selectedMediaItem != nil) { // && (globals.display.mediaItems?.indexOf(selectedMediaItem!) != nil)
                showMenu.append(Constants.Strings.Current_Selection)
            }
            
            if (globals.mediaPlayer.mediaItem != nil) {
                var show:String = Constants.EMPTY_STRING
                
                if globals.mediaPlayer.url != URL(string: Constants.URL.LIVE_STREAM), let state = globals.mediaPlayer.state {
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
                
                if (splitViewController?.viewControllers.count > 1) {
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
            
//            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//                print("splitViewController.isCollapsed == true")
//            }
            
            if let vClass = splitViewController?.traitCollection.verticalSizeClass,
                let isCollapsed = splitViewController?.isCollapsed,
                (vClass != UIUserInterfaceSizeClass.compact) || isCollapsed {
                if (globals.media.active?.scriptureIndex?.eligible != nil) {
                    showMenu.append(Constants.Strings.Scripture_Index)
                }
                
                if (globals.media.active?.lexicon?.eligible != nil) {
                    showMenu.append(Constants.Strings.Lexicon_Index)
                }
            }
            
            if globals.history != nil {
                showMenu.append(Constants.Strings.History)
                showMenu.append(Constants.Strings.Clear_History)
            }

            if globals.streamEntries != nil, globals.reachability.currentReachabilityStatus != .notReachable {
                showMenu.append(Constants.Strings.Live)
            }
            
//            if let isCollapsed = splitViewController?.isCollapsed {
//                if isCollapsed {
//                    showMenu.append(Constants.Strings.Live)
//                } else {
//                    if  let count = splitViewController?.viewControllers.count,
//                        let detailView = splitViewController?.viewControllers[count - 1] as? UINavigationController,
//                        (detailView.viewControllers[0] as? LiveViewController) == nil {
//                        showMenu.append(Constants.Strings.Live)
//                    }
//                }
//            } else {
//                // SHOULD NEVER HAPPEN
//            }
            
            showMenu.append(Constants.Strings.Settings)
            
            showMenu.append(Constants.Strings.VoiceBase_API_Key)
            
            if let isVoiceBaseAvailable = globals.isVoiceBaseAvailable, isVoiceBaseAvailable {
                showMenu.append(Constants.Strings.VoiceBase_Media)
            }
            
            popover.section.strings = showMenu
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self.splitViewController

            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
//                DispatchQueue.main.async(execute: { () -> Void in
//                    // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
//                    navigationController.popoverPresentationController?.passthroughViews = nil
//                })
            })
        }
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            globals.selectedMediaItem.master = selectedMediaItem
        }
    }
    
    func disableToolBarButtons()
    {
        Thread.onMainThread() {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = false
                }
            }
        }
    }
    
    func disableBarButtons()
    {
        Thread.onMainThread() {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = false
                }
            }
        }
        
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        Thread.onMainThread() {
            if let barButtons = self.toolbarItems {
                for barButton in barButtons {
                    barButton.isEnabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMainThread() {
            if let barButtonItems = self.navigationItem.leftBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
            
            if let barButtonItems = self.navigationItem.rightBarButtonItems {
                for barButtonItem in barButtonItems {
                    barButtonItem.isEnabled = true
                }
            }
        }
        
        enableToolBarButtons()
    }
    
    func index(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })

        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Menu.Index
            
            popover.delegate = self
            
            popover.purpose = .selectingSection

            switch globals.grouping! {
            case GROUPING.BOOK:
                if let books = globals.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                    return bookNumberInBible(string) != Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                }) {
//                        print(books)
                    popover.section.strings = books

                    if let other = globals.media.active?.section?.headerStrings?.filter({ (string:String) -> Bool in
                        return bookNumberInBible(string) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE
                    }) {
                        popover.section.strings?.append(contentsOf: other)
                    }
                }
                
//                    print(popover.section.strings)
//                
//                popover.section.showIndex = false
//                popover.section.showHeaders = false
                break
                
            case GROUPING.TITLE:
                popover.section.showIndex = true
//                popover.section.showHeaders = true
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.CLASS:
                popover.section.showIndex = true
//                popover.section.showHeaders = true
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            case GROUPING.SPEAKER:
                popover.section.showIndex = true
//                popover.section.showHeaders = true
                popover.indexStringsTransform = lastNameFromName
                popover.section.strings = globals.media.active?.section?.headerStrings
                popover.search = popover.section.strings?.count > 10
                break
                
            default:
//                popover.section.showIndex = false
//                popover.section.showHeaders = false
                popover.section.strings = globals.media.active?.section?.headerStrings
                break
            }
            
            popover.vc = self.splitViewController
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }

    func grouping(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Options_Title.Grouping
            
            popover.delegate = self
            
            popover.purpose = .selectingGrouping
            popover.section.strings = globals.groupingTitles
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self.splitViewController
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }
    
    func sorting(_ object:AnyObject?)
    {
        guard Thread.isMainThread else {
            return
        }

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.mediaItemSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            let button = object as? UIBarButtonItem
            
            navigationController.modalPresentationStyle = .popover
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .down
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = button
            
            popover.navigationItem.title = Constants.Strings.Options_Title.Sorting
            
            popover.delegate = self
            
            popover.purpose = .selectingSorting
            popover.section.strings = Constants.SortingTitles
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self.splitViewController
            
            present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
    }

    fileprivate func setupShowMenu()
    {
        let showButton = navigationItem.leftBarButtonItem
        
        showButton?.title = Constants.FA.REORDER
        showButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
        
        showButton?.isEnabled = (globals.media.all != nil) //&& !globals.mediaItemsSortingOrGrouping
    }
    
    fileprivate func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Strings.Menu.Sorting, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Strings.Menu.Grouping, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Strings.Menu.Index, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.index(_:)))

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
    
    func setupViews()
    {
        setupTag()
        
        Thread.onMainThread() {
            self.tableView?.reloadData()
        }
        
        setupTitle()
        
        selectedMediaItem = globals.selectedMediaItem.master
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread() {
                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            }
        })
        
        if (splitViewController?.viewControllers.count > 1) {
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            }
        }
    }
    
//    func jsonAlert(title:String,message:String)
//    {
//        if (UIApplication.shared.applicationState == UIApplicationState.active) {
//            alert(viewController:self,title:title,
//                  message:message,
//                  completion:nil)
//        }
//    }

//    func jsonFromFileSystem(filename:String?) -> Any?
//    {
//        guard let filename = filename else {
//            return nil
//        }
//
//        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
//            return nil
//        }
//        
//        do {
//            let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
//            print("able to read json from the URL.")
//            
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//        } catch let error as NSError {
//            print("Network unavailable: json could not be read from the file system.")
//            NSLog(error.localizedDescription)
//            return nil
//        }
//    }
//    
//        do {
//            let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
//            print("json read from the file system.")
//            
////            let json = JSON(data: data)
////            
////            if json != JSON.null {
//////                globals.alert(title:"Network Error",message:"Media list read but failed to load.  Last available copy read and loaded.")
////                
////                print("json read and loaded from the file system.")
////                
//////                print(json)
////                
////                return json
////            } else {
//////                globals.alert(title:"Network Error",message:"Last available media list could not be loaded.")
////                print("Network unavailable: json read from the file system could not be loaded.")
////            }
//        } catch let error as NSError {
////            globals.alert(title:"Network Error",message:"Last available media list could not be read: " + error.localizedDescription)
//            print("Network unavailable: json could not be read from the file system.")
//            NSLog(error.localizedDescription)
//        }
//        
//        return nil
//    }
    
//    func jsonFromURL(url:String,filename:String) -> Any?
//    {
//        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
//            return nil
//        }
//        
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            print("json not reachable.")
//
////            globals.alert(title:"Network Error",message:"Newtork not available, attempting to load last available media list.")
//
//            return jsonFromFileSystem(filename: filename)
//        }
//        
//        do {
//            let data = try Data(contentsOf: URL(string: url)!) // , options: NSData.ReadingOptions.mappedIfSafe
//            print("able to read json from the URL.")
//
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//
//                do {
//                    try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
//                    
//                    print("able to write json to the file system")
//                } catch let error as NSError {
//                    print("unable to write json to the file system.")
//                    
//                    NSLog(error.localizedDescription)
//                }
//                
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return jsonFromFileSystem(filename: filename)
//            }
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            return jsonFromFileSystem(filename: filename)
//        }
//    }
    
//            let json = JSON(data: data)
//            
//            if json != JSON.null {
//                print(json)
//
//                do {
////                    globals.alert(title:"Pursue sanctification!",message:"Media list read, loaded, and written.")
//  
//                    try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
//                    
//                    print("able to write json to the file system")
//                } catch let error as NSError {
////                    globals.alert(title:"Network Error!",message:"Media list read and loaded but write failed: " + error.localizedDescription)
//                    
//                    print("unable to write json to the file system.")
//                    
//                    NSLog(error.localizedDescription)
//                }
//
//                return json
//            } else {
////                globals.alert(title:"Media List Error!",message:"Media list read but not loaded.  Attempting to load last available copy.")
//                
//                print("could not load json from URL.")
//                
//                return jsonFromFileSystem(filename: filename)
//
////                do {
////                    let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
////                    print("able to read json from the file system.")
////                    
////                    let json = JSON(data: data)
////                    if json != JSON.null {
////                        print("able to load json from the file system.")
//////                        print(json)
////                        return json
////                    } else {
////                        globals.alert(title:"Media List Error",message:"Last available media list read but failed to load.")
////                        print("could not load json from the file system.")
////                    }
////                } catch let error as NSError {
////                    globals.alert(title:"Media List Error",message:"Last available media list could not be read: " + error.localizedDescription)
////                    print("could not read json from the file system.")
////                    NSLog(error.localizedDescription)
////                }
//            }
//        } catch let error as NSError {
////            globals.alert(title:"Network Error",message:"Media list could not be read.  Attempting to load last available media list: " + error.localizedDescription)
//            print("unable to read json from the URL.")
//            print(error.localizedDescription)
//            
//            return jsonFromFileSystem(filename: filename)
//
////            do {
////                let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
////                print("able to read json from the file system.")
////                
////                let json = JSON(data: data)
////                if json != JSON.null {
////                    print("able to load json from the file system.")
////                    //                        print(json)
////                    return json
////                } else {
////                    globals.alert(title:"Media List Error",message:"Last available media list could be read but not loaded.")
////                    print("unable to load json from the file system.")
////                }
////            } catch let error as NSError {
////                globals.alert(title:"Media List Error",message:"Last available media list could not be read: " + error.localizedDescription)
////                print("unable to read json from the file system.")
////                NSLog(error.localizedDescription)
////            }
//        }
//
//        return nil
//    }
    
    func loadJSONDictsFromFileSystem(filename:String?,key:String) -> [[String:String]]? // CachesDirectory
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonFromFileSystem(filename:filename) as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)"
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                //            print(mediaItemDicts)
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }

//
//        if json != nil {
////            print("json:\(json)")
//            
//            let mediaItems = json[key]
//            
//            for i in 0..<mediaItems.count {
//                
//                var dict = [String:String]()
//                
//                for (key,value) in mediaItems[i] {
//                    dict[key] = "\(value)"
//                }
//                
//                mediaItemDicts.append(dict)
//            }
//            
//            //            print(mediaItemDicts)
//            
//            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
//        } else {
//            print("could not get json from file, make sure that file contains valid json.")
//        }
        
        return nil
    }
    
    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonFromURL(url: url,filename: filename) as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                //            print(mediaItemDicts)
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from URL, make sure that URL contains valid json.")
        }

//        if json != JSON.null {
//            print(json)
//            
//            let mediaItems = json[key]
//            
//            for i in 0..<mediaItems.count {
//                
//                var dict = [String:String]()
//                
//                for (key,value) in mediaItems[i] {
////                    print(key,value)
//                    dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                }
//                
//                mediaItemDicts.append(dict)
//            }
//            
//            //            print(mediaItemDicts)
//            
//            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
//        } else {
//            print("could not get json from URL, make sure that URL contains valid json.")
//        }
        
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
    
    func loadLive() -> [String:Any]?
    {
        return jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any]
    }
    
    func loadLive(completion:((Void)->(Void))?)
    {
        DispatchQueue.global(qos: .background).async() {
            Thread.sleep(forTimeInterval: 0.25)
        
            if let liveEvents = jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any] {
                //            print(liveEvents["streamEntries"] as? [[String:Any]])
                
                globals.streamEntries = liveEvents["streamEntries"] as? [[String:Any]]
                
                Thread.onMainThread(block: {
                    completion?()
                })
                
                //            print(globals.streamCategories)
                
                //            print(globals.streamSchedule)
                
            }
        }
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
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.isLoading = true

            self.setupSearchBar()
            self.setupCategoryButton()
            self.setupActionAndTagsButton()
            self.setupBarButtons()
            self.setupListActivityIndicator()

            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Loading_Media
            }

            self.loadLive(completion: nil)
            
            switch self.jsonSource {
            case .download:
                // From Caches Directory
                if let categoriesDicts = self.loadJSONDictsFromFileSystem(filename: Constants.JSON.FILENAME.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES) {
                    //                print(categoriesDicts)
                    
                    var mediaCategoryDicts = [String:String]()
                    
                    for categoriesDict in categoriesDicts {
                        mediaCategoryDicts[categoriesDict["category_name"]!] = categoriesDict["id"]
                    }
                    
                    globals.mediaCategory.dicts = mediaCategoryDicts
                    
                    //                print(globals.mediaCategories)
                }
                
                print(globals.mediaCategory.filename as Any)
                
                if  let mediaItemDicts = self.loadJSONDictsFromFileSystem(filename:globals.mediaCategory.filename,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                    globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                } else {
                    globals.mediaRepository.list = nil
                    print("FAILED TO LOAD")
                }
                break
                
            case .direct:
                // From URL
                //            print(Constants.JSON_CATEGORY_URL + globals.mediaCategoryID!)
                
                self.loadCategories()
                
//                if let categoriesDicts = self.loadJSONDictsFromURL(url: Constants.JSON.URL.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES,filename: Constants.JSON.FILENAME.CATEGORIES) {
//                    //                print(categoriesDicts)
//                    
//                    var mediaCategoryDicts = [String:String]()
//                    
//                    for categoriesDict in categoriesDicts {
//                        mediaCategoryDicts[categoriesDict["category_name"]!] = categoriesDict["id"]
//                    }
//                    
//                    globals.mediaCategory.dicts = mediaCategoryDicts
//                    
//                    //                print(globals.mediaCategories)
//                }
                
                print(globals.mediaCategory.filename as Any)
                
                if  let url = globals.mediaCategory.url,
                    let filename = globals.mediaCategory.filename,
                    let mediaItemDicts = self.loadJSONDictsFromURL(url: url,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES,filename: filename) {
                    globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                } else {
                    globals.mediaRepository.list = nil
                    print("FAILED TO LOAD")
                }
                break
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

            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Loading_Settings
            }
            globals.loadSettings()
            
            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Sorting_and_Grouping
            }
            
            globals.media.all = MediaListGroupSort(mediaItems: globals.mediaRepository.list)
            
//            print(globals.mediaRepository.list?.count)
//            print(globals.media.all?.list?.count)
            
            if globals.search.valid {
                Thread.onMainThread() {
                    self.searchBar.text = globals.search.text
                    self.searchBar.showsCancelButton = true
                }

                globals.search.complete = false
            }

            globals.setupDisplay(globals.media.active)
            
//            if globals.reachability.isReachableViaWiFi {
//                globals.media.all?.lexicon?.build()
//            }
            
            Thread.onMainThread() {
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (globals.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    globals.mediaPlayer.setup(globals.mediaPlayer.mediaItem,playOnLoad:false)
                }

                self.navigationItem.title = Constants.CBC.TITLE.SHORT
                
                self.setupViews()
                
                self.setupListActivityIndicator()
                
                if globals.mediaRepository.list != nil {
                    if globals.isRefreshing {
                        self.refreshControl?.endRefreshing()
                        self.tableView?.setContentOffset(CGPoint(x:self.tableView!.frame.origin.x, y:self.tableView!.frame.origin.y - 44), animated: false)
                        globals.isRefreshing = false
                    }
                }

                globals.isLoading = false
                
                completion?()

                self.setupBarButtons()
                self.setupActionAndTagsButton()
                self.setupCategoryButton()
                self.setupListActivityIndicator()
            }
        })
    }
    
    func setupCategoryButton()
    {
        Thread.onMainThread() {
            self.mediaCategoryButton.setTitle(globals.mediaCategory.selected, for: UIControlState.normal)
            
            if globals.isLoading || globals.isRefreshing || !globals.search.complete {
                self.mediaCategoryButton.isEnabled = false
            } else {
                if globals.search.complete { // (globals.mediaRepository.list != nil) &&
                    self.mediaCategoryButton.isEnabled = true
                }
            }
        }
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
                Thread.onMainThread() {
                    self.startAnimating()
                }
            } else {
                Thread.onMainThread() {
                    self.stopAnimating()
                }
            }
        } else {
            Thread.onMainThread() {
                self.stopAnimating()
            }
        }
    }
    
    func downloadJSON(url:String?,filename:String?)
    {
        guard url != nil else {
            return
        }
        
        guard filename != nil else {
            return
        }
        
        navigationItem.title = Constants.Title.Downloading_Media
        
        let downloadRequest = URLRequest(url: URL(string: url!)!)
        
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
        Thread.onMainThread() {
            self.searchBar.resignFirstResponder()
            self.searchBar.placeholder = nil
            self.searchBar.text = nil
            self.searchBar.showsCancelButton = false
        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl)
    {
        guard Thread.isMainThread else {
            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:handleRefresh", completion: nil)
            return
        }
        
        globals.isRefreshing = true
        
        setupListActivityIndicator()
        refreshControl.beginRefreshing()
        
        globals.mediaPlayer.unobserve()
        
        globals.mediaPlayer.pause() // IfPlaying

        globals.cancelAllDownloads()

        globals.clearDisplay()
        
        globals.search.active = false

        setupSearchBar()
        
        tableView?.reloadData()
        
        // tableView can't be hidden or refresh spinner won't show.
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = true // false // Don't like it offset, just hide it for now
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)

        setupActionAndTagsButton()
        setupCategoryButton()

        setupBarButtons()
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        globals.media = Globals.Media()
        globals.media.globals = globals

//        loadCategories()
        
        // loadMediaItems or downloadJSON
        
        switch jsonSource {
        case .download:
            navigationItem.title = "Downloading Media List"
            let categoriesFileName = Constants.JSON.FILENAME.CATEGORIES
            downloadJSON(url:Constants.JSON.URL.CATEGORIES,filename:categoriesFileName)
            break
            
        case .direct:
            loadMediaItems()
            {
                self.loadCompletion() // refreshCompletion()
            }
            break
        }
    }

    func updateList()
    {
        updateSearch()
        
        globals.setupDisplay(globals.media.active)

        updateUI()
        
        tableView?.reloadData()
    }
    
    var container:UIView!
    var loadingView:UIView!
    var actInd:UIActivityIndicatorView!

    func stopAnimating()
    {
        guard container != nil else {
            return
        }
        
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
//        print("stopAnimating")

        Thread.onMainThread() {
            self.actInd.stopAnimating()
            self.loadingView.isHidden = true
            self.container.isHidden = true
        }
    }
    
    func startAnimating()
    {
        if container == nil { // loadingView
            setupLoadingView()
        }

        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
//        print("startAnimating")
        
        Thread.onMainThread() {
            self.container.isHidden = false
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        }
    }
    
    func setupLoadingView()
    {
        guard (loadingView == nil) else {
            return
        }
        
        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
            return
        }

        container = loadingViewController.view!
        
        container.backgroundColor = UIColor.clear

        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView = loadingViewController.view.subviews[0]
        
        loadingView.isUserInteractionEnabled = false
        
        actInd = loadingView.subviews[0] as! UIActivityIndicatorView
        
        actInd.isUserInteractionEnabled = false
        
        view.addSubview(container)
    }
    
//    func stringPickedCompletion()
//    {
//        if globals.mediaRepository.list == nil {
//            self.noMediaAvailable() {_ in
//                if globals.isRefreshing {
//                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                        
//                    })
//                } else {
//                    self.setupListActivityIndicator()
//                }
//            }
//        } else {
//            self.selectedMediaItem = globals.selectedMediaItem.master
//            
//            if globals.search.active && !globals.search.complete {
//                self.updateSearchResults(globals.search.text,completion: {
//                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                        Thread.onMainThread() {
//                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
//                        }
//                    })
//                })
//            } else {
//                // Reload the table
//                self.tableView?.reloadData()
//                
//                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                    Thread.onMainThread() {
//                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
//                    }
//                })
//            }
//        }
//        
//        self.setupTitle()
//        self.tableView?.isHidden = false
//        self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
//    }

//    func refreshCompletion()
//    {
//        let liveStream = globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM)
//        
//        if liveStream {
//            Thread.onMainThread() {
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
//            }
//        }
//        
//        loadCompletion()
//        
////        if globals.mediaRepository.list == nil {
////            self.noMediaAvailable() {_ in
////                if globals.isRefreshing {
////                    self.refreshControl?.endRefreshing()
////                    globals.isRefreshing = false
////                } else {
////                    self.setupListActivityIndicator()
////                }
////            }
////        } else {
////            globals.isRefreshing = false
////            
////            self.selectedMediaItem = globals.selectedMediaItem.master
////            
////            if globals.search.active && !globals.search.complete {
////                self.updateSearchResults(globals.search.text,completion: {
////                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                        Thread.onMainThread() {
////                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
////                        }
////                    })
////                })
////            } else {
////                // Reload the table
////                self.tableView?.reloadData()
////                
////                if self.selectedMediaItem != nil {
////                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                        Thread.onMainThread() {
////                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
////                        }
////                    })
////                } else {
////                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                        Thread.onMainThread() {
////                            self.tableView?.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
////                        }
////                    })
////                }
////            }
////        }
////        
////        self.setupTitle()
////        self.tableView?.isHidden = false
////        self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
//    }
//    
//    func rowClickedCompletion()
//    {
////        let liveStream = globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM)
////        
////        if globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
////            Thread.onMainThread() {
////                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
////            }
////        }
//        
//        loadCompletion()
//        
////        if globals.mediaRepository.list == nil {
////            self.noMediaAvailable() {_ in
////                if globals.isRefreshing {
////                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                        
////                    })
////                } else {
////                    self.setupListActivityIndicator()
////                }
////            }
////        } else {
////            self.selectedMediaItem = globals.selectedMediaItem.master
////            
////            if globals.search.active && !globals.search.complete {
////                self.updateSearchResults(globals.search.text,completion: {
////                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                        Thread.onMainThread() {
////                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
////                        }
////                    })
////                })
////            } else {
////                // Reload the table
////                self.tableView?.reloadData()
////                
////                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
////                    Thread.onMainThread() {
////                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
////                    }
////                })
////            }
////        }
////        
////        self.setupTitle()
////        self.tableView?.isHidden = false
////        self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
//    }
    
    func loadCompletion()
    {
        if globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM) {
            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
            }
        }
        
        if globals.mediaRepository.list == nil {
            self.noMediaAvailable() {_ in
                if globals.isRefreshing {
                    self.refreshControl?.endRefreshing()
                    globals.isRefreshing = false
                } else {
                    self.setupListActivityIndicator()
                }
            }
        } else {
            globals.isRefreshing = false
            
            self.selectedMediaItem = globals.selectedMediaItem.master
            
            if globals.search.active && !globals.search.complete { // && globals.search.transcripts
                self.updateSearchResults(globals.search.text,completion: {
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        Thread.onMainThread() {
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    })
                })
            } else {
                // Reload the table
                self.tableView?.reloadData()
                
//                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                    Thread.onMainThread() {
//                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
//                    }
//                })

                if self.selectedMediaItem != nil {
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        Thread.onMainThread() {
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                        }
                    })
                } else {
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        Thread.onMainThread() {
                            self.tableView?.scrollToRow(at: IndexPath(row:0,section:0), at: UITableViewScrollPosition.top, animated: false)
                        }
                    })
                }
            }
        }
        
        self.setupTitle()
        self.tableView?.isHidden = false
        self.logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
    }

    func load()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard !globals.isLoading else {
            return
        }
        
        guard globals.mediaRepository.list == nil else {
            return
        }
        
        tableView?.isHidden = true
        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
            logo.isHidden = true // !self.tableView?.isHidden // Don't like it offset, just hide it for now
        }
        
//        startAnimating()
//        
//        loadCategories()
//        
//        stopAnimating()
        
        // Download or Load
        
        switch jsonSource {
        case .download:
            globals.isLoading = true
            
            setupSearchBar()
            setupCategoryButton()
            setupActionAndTagsButton()
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

    override func viewDidLoad()
    {
        super.viewDidLoad()

//        setupTagsToolbar()

        setupSortingAndGroupingOptions()
        setupShowMenu()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView?.estimatedRowHeight = tableView?.rowHeight
//        tableView?.rowHeight = UITableViewAutomaticDimension
        
        // App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden when mode is changed to primaryHidden!
//        splitViewController?.preferredDisplayMode = .automatic //iPad only
        
        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        navigationController?.isToolbarHidden = false
    }
    
//    func setupTagsToolbar()
//    {
//        self.tagsToolbar = UIToolbar(frame: self.tagsButton.frame)
//        self.tagsToolbar?.setItems([UIBarButtonItem(title: nil, style: .plain, target: self, action: nil)], animated: false)
//        self.tagsToolbar?.isHidden = true
//        
//        self.tagsToolbar?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
//        
//        self.view.addSubview(self.tagsToolbar!)
//        
//        let first = self.tagsToolbar
//        let second = self.tagsButton
//        
//        let centerX = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
//        self.view.addConstraint(centerX)
//        
//        let centerY = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: second!, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
//        self.view.addConstraint(centerY)
//        
//        //        let width = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
//        //        self.addConstraint(width)
//        //
//        //        let height = NSLayoutConstraint(item: first!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: second!, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
//        //        self.addConstraint(height)
//        
//        self.view.setNeedsLayout()
//    }
    
    func actionMenu() -> [String]?
    {
        var actionMenu = [String]()
        
        if globals.media.active?.list?.count > 0 {
            actionMenu.append(Constants.Strings.View_List)
        }
        
        return actionMenu.count > 0 ? actionMenu : nil
    }
    
    func actions()
    {
        guard Thread.isMainThread else {
            return
        }
        
        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .popover
            
            popover.navigationItem.title = "Select"
            navigationController.isNavigationBarHidden = false

            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self
            
            navigationController.popoverPresentationController?.barButtonItem = actionButton
            
//            popover.navigationController?.isNavigationBarHidden = true
            
            popover.delegate = self
            popover.purpose = .selectingAction
            
            popover.selectedMediaItem = selectedMediaItem
            
            popover.section.strings = actionMenu()
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
            
            popover.vc = self.splitViewController

            self.present(navigationController, animated: true, completion:  {
                self.presentingVC = navigationController
            })
        }
    }

    var tagsButton : UIBarButtonItem?
    var actionButton : UIBarButtonItem?
    
    func tagsMenu() -> [String]?
    {
        var strings = [Constants.Strings.All]
        
        if let mediaItemTags = globals.media.all?.mediaItemTags {
            strings.append(contentsOf: mediaItemTags)
        }
        
        return strings.sorted(by: { stringWithoutPrefixes($0)! < stringWithoutPrefixes($1)! })
    }
    
    func setupActionAndTagsButton()
    {
        guard !globals.isLoading && !globals.isRefreshing else {
            navigationItem.rightBarButtonItems = nil
            return
        }
        
        var barButtons = [UIBarButtonItem]()
        
        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.actions))
        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)

        if actionMenu()?.count > 0 {
            barButtons.append(actionButton!)
        }
        
        if (globals.media.all?.mediaItemTags?.count > 1) {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.selectingTagsAction(_:)))
        } else {
            tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.selectingTagsAction(_:)))
        }
        tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.normal)

        if tagsMenu()?.count > 0 {
            barButtons.append(tagsButton!)
        }
        
        if barButtons.count > 0 {
            navigationItem.setRightBarButtonItems(barButtons, animated: true)
        } else {
            navigationItem.rightBarButtonItems = nil
        }

//        let tagsButton = self.tagsButton
//        
//        DispatchQueue.main.async(execute: { () -> Void in
//            if let count = globals.media.all?.mediaItemTags?.count {
//                switch count {
//                case 0:
//                    tagsButton?.isEnabled = false
//                    tagsButton?.isHidden = true
//                    break
//                    
////                case 1: // Never happens because if there is one we add the All tag.
////                    tagsButton.setTitle(Constants.FA.TAG, for: UIControlState.normal)
////                    tagsButton.isEnabled = true
////                    tagsButton.isHidden = false
////                    break
//                    
//                default:
//                    tagsButton?.setTitle(Constants.FA.TAGS, for: UIControlState.normal)
//                    tagsButton?.isEnabled = true
//                    tagsButton?.isHidden = false
//                    break
//                }
//                
//            } else {
//                tagsButton?.isEnabled = false
//                tagsButton?.isHidden = true
//            }
//            
//            if (globals.mediaRepository.list ==  nil) || globals.isLoading || globals.isRefreshing || !globals.search.complete {
//                tagsButton?.isEnabled = false
//                tagsButton?.isHidden = false
//            }
//        })
    }
    
    @IBAction func selectingTagsAction(_ sender: UIButton)
    {
        guard Thread.isMainThread else {
            return
        }

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

        //In case we have one already showing
        dismiss(animated: true, completion: {
            self.presentingVC = nil
        })

        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            
            if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
                let hClass = traitCollection.horizontalSizeClass
                
                if hClass == .compact {
                    navigationController.modalPresentationStyle = .overCurrentContext
                } else {
                    // I don't think this ever happens: collapsed and regular
                    navigationController.modalPresentationStyle = .popover
                }
            } else {
                navigationController.modalPresentationStyle = .popover
            }

//            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.permittedArrowDirections = .up
            navigationController.popoverPresentationController?.delegate = self

            navigationController.popoverPresentationController?.barButtonItem = tagsButton

            popover.navigationItem.title = Constants.Strings.Show
            
            popover.delegate = self
            popover.purpose = .selectingTags
            
//            print(globals.media.all!.mediaItemTags!)
            
//            print(globals.media.all!.proposedTags)
            
            popover.section.showIndex = true
//            popover.section.showHeaders = true
            
            popover.section.strings = tagsMenu()
            
//            print(globals.media.all!.mediaItemTags)
            
//            popover.section.indexStringsTransform = stringWithoutPrefixes
            
            popover.search = popover.section.strings?.count > 10
            
            popover.vc = self.splitViewController
            
            self.present(navigationController, animated: true, completion: {
                self.presentingVC = navigationController
            })
        }
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
        }
        
        Thread.onMainThread() {
            if !self.tableView!.isEditing {
                self.tableView?.reloadData()
            } else {
                self.changesPending = true
            }
        }
    }

    func updateSearches(searchText:String?,mediaItems: [MediaItem]?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
//        self.showProgress = false
        
        if globals.media.toSearch?.searches == nil {
            globals.media.toSearch?.searches = [String:MediaListGroupSort]()
        }
        
        globals.media.toSearch?.searches?[searchText] = MediaListGroupSort(mediaItems: mediaItems)
        
//        self.showProgress = true
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
//        print(searchText)

        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard !searchText.isEmpty else {
            return
        }
        
//        print(searchText)
        
        guard (globals.media.toSearch?.searches?[searchText] == nil) else {
            updateDisplay(searchText:searchText)
            setupListActivityIndicator()
            setupBarButtons()
            setupCategoryButton()
            setupActionAndTagsButton()
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

        Thread.onMainThread() {
            self.tableView?.reloadData()
        }

        self.setupActionAndTagsButton()
        self.setupBarButtons()
        self.setupCategoryButton()

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            var searchMediaItems:[MediaItem]?
            
            if globals.media.toSearch?.list != nil {
                for mediaItem in globals.media.toSearch!.list! {
                    globals.search.complete = false
                    
                    self.setupListActivityIndicator()
                    
                    let searchHit = mediaItem.search(searchText)
                    
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
                                self.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                                self.updateDisplay(searchText:searchText)
                            }
                        }
                    }
                }
                
                if !abort {
                    self.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                    self.updateDisplay(searchText:searchText)
                } else {
                    globals.media.toSearch?.searches?[searchText] = nil
                }
                
                if !abort && globals.search.transcripts {
                    for mediaItem in globals.media.toSearch!.list! {
                        globals.search.complete = false
                        
                        self.setupListActivityIndicator()

                        let searchHit = mediaItem.searchFullNotesHTML(searchText)

                        abort = abort || shouldAbort() || !globals.search.transcripts
                        
                        if abort {
                            globals.media.toSearch?.searches?[searchText] = nil
                            break
                        } else {
                            if searchHit {
                                if (searchMediaItems == nil) || !searchMediaItems!.contains(mediaItem) {
                                    if searchMediaItems == nil {
                                        searchMediaItems = [mediaItem]
                                    } else {
                                        searchMediaItems?.append(mediaItem)
                                    }
                                }
                                
                                self.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
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
                self.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
                self.updateDisplay(searchText:searchText)
            }
            
            Thread.onMainThread() {
                completion?()
                
                globals.search.complete = true
                
                self.setupListActivityIndicator()
                self.setupBarButtons()
                self.setupCategoryButton()
                self.setupActionAndTagsButton()
            }
        })
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        guard !tableView!.isEditing else {
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
            case GROUPING.YEAR:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.yearSection!)!
                break
                
            case GROUPING.TITLE:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.multiPartSectionSort!)!
                break
                
            case GROUPING.BOOK:
                // For mediaItem.books.count > 1 this arbitrarily selects the first one, which may not be correct.
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.bookSections.first!)!
                break
                
            case GROUPING.SPEAKER:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.speakerSectionSort!)!
                break
                
            case GROUPING.CLASS:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.classSectionSort!)!
                break
                
            case GROUPING.EVENT:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.eventSectionSort!)!
                break
                
            default:
                break
            }
            
            row = index - globals.media.active!.sectionIndexes![section]
        }
        
        //            print(section)
        
        if (section >= 0) && (row >= 0) {
            indexPath = IndexPath(row: row,section: section)
            
//            print(tableView?.numberOfSections,tableView?.numberOfRows(inSection: section),indexPath)

            //            print("\(globals.mediaItemSelected?.title)")
            //            print("Row: \(indexPath.item)")
            //            print("Section: \(indexPath.section)")
            
            guard indexPath.section >= 0, (indexPath.section < tableView?.numberOfSections) else {
                NSLog("indexPath section ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView!.numberOfSections)")
                return
            }
            
            guard indexPath.row >= 0, indexPath.row < tableView?.numberOfRows(inSection: indexPath.section) else {
                NSLog("indexPath row ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView!.numberOfSections)")
                NSLog("Row: \(indexPath.row)")
                NSLog("TableView Number of Rows in Section: \(tableView!.numberOfRows(inSection: indexPath.section))")
                return
            }

            Thread.onMainThread() {
                self.tableView?.setEditing(false, animated: true)
            }

            if (select) {
                Thread.onMainThread() {
                    self.tableView?.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                }
            }
            
            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                Thread.onMainThread() {
                    self.tableView?.scrollToRow(at: indexPath, at: position, animated: false)
                }
            }
        }
    }

    
    fileprivate func setupTag()
    {
        Thread.onMainThread() {
            switch globals.media.tags.showing! {
            case Constants.ALL:
                self.tagLabel.text = Constants.Strings.All // searchBar.placeholder
                break
                
            case Constants.TAGGED:
                self.tagLabel.text = globals.media.tags.selected // searchBar.placeholder
                break
                
            default:
                break
            }
        }
    }
    

    func setupTitle()
    {
        if (!globals.isLoading && !globals.isRefreshing) {
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
                    if (UIDeviceOrientationIsLandscape(UIDevice.current.orientation)) {
                        if DeviceType.IS_IPHONE_6P_7P {
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
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.current.orientation)) {
            if (globals.media.all == nil) {
                splitViewController?.preferredDisplayMode = .primaryOverlay//iPad only
            } else {
                if (self.splitViewController?.viewControllers.count > 1) {
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
            if (self.splitViewController?.viewControllers.count > 1) {
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
    
    func updateSearch()
    {
        guard globals.search.valid else {
            return
        }
        
        updateSearchResults(globals.search.text,completion: nil)
    }
    
    func liveView()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: nil)
    }
    
    func playingPaused()
    {
//        globals.gotoPlayingPaused = true
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: globals.mediaPlayer.mediaItem)
    }
    
    func deviceOrientationDidChange()
    {

    }

    func stopEditing()
    {
        tableView.isEditing = false
    }
    
    func willEnterForeground()
    {
        
    }
    
    func didBecomeActive()
    {
        guard globals.mediaRepository.list == nil else {
            return
        }
        
        tableView.isHidden = true
        
        loadMediaItems()
            {
                if globals.mediaRepository.list == nil {
                    let alert = UIAlertController(title: "No media available.",
                                                  message: "Please check your network connection and try again.",
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    
                    let action = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                        self.setupListActivityIndicator()
                    })
                    alert.addAction(action)
                    
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.selectedMediaItem = globals.selectedMediaItem.master
                    
                    if globals.search.active && !globals.search.complete { // && globals.search.transcripts
                        self.updateSearchResults(globals.search.text,completion: {
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                                })
                            })
                        })
                    } else {
                        // Reload the table
                        self.tableView.reloadData()
                        
                        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                            })
                        })
                    }
                }
                
                self.tableView.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        load()

        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.finish), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.VOICE_BASE_FINISHED), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.playingPaused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYING_PAUSED), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.stopEditing), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        
//        if (self.splitViewController?.viewControllers.count > 1) {
//            NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.setupShowHide), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SHOW_HIDE), object: nil)
//        }

        updateUI()
        
        // Causes a crash in split screen on first swipe to get MVC to show when only DVC is showing.
        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
//        if (splitViewController?.preferredDisplayMode == .automatic) {
//            splitViewController?.preferredDisplayMode = .allVisible //iPad only
//        }

//        print(globals.mediaCategory)
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
    }
    
    func updateUI()
    {
        setupCategoryButton()
        
        setupTag()
        setupActionAndTagsButton()
        
//        setupShowHide()
        
        setupTitle()
        
        setupBarButtons()

        setupListActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        navigationController?.isToolbarHidden = false
        
        if (!globals.scrolledToMediaItemLastSelected) {
            selectOrScrollToMediaItem(selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
            globals.scrolledToMediaItemLastSelected = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Can't remove this or the list won't update correctly on iPhone where this VC is pushed off screen. 
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.EDITING), object: tableView)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.NOT_EDITING), object: tableView)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
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
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.SEGUE.SHOW_SETTINGS:
                if let svc = dvc as? SettingsViewController {
//                    svc.modalPresentationStyle = .popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.SEGUE.SHOW_LIVE:
                globals.mediaPlayer.killPIP = true
                
                if sender != nil {
                    (dvc as? LiveViewController)?.streamEntry = sender as? StreamEntry
                } else {
                    let defaults = UserDefaults.standard
                    if let streamEntry = StreamEntry(defaults.object(forKey: Constants.SETTINGS.LIVE) as? [String:Any]) {
                        (dvc as? LiveViewController)?.streamEntry = streamEntry
                    }
                }
                
//                splitViewController?.preferredDisplayMode = .primaryHidden
                break
                
            case Constants.SEGUE.SHOW_SCRIPTURE_INDEX:
                break
                
            case Constants.SEGUE.SHOW_ABOUT2:
                break
                
            case Constants.SEGUE.SHOW_MEDIAITEM:
                if globals.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM) && (globals.mediaPlayer.pip == .stopped) {
                    globals.mediaPlayer.pause() // DO NOT USE STOP HERE AS STOP SETS globals.mediaPlayer.mediaItem (used below) to nil
                    globals.mediaPlayer.playOnLoad = false
                }
                
//                if (globals.gotoPlayingPaused) {
//                    globals.gotoPlayingPaused = !globals.gotoPlayingPaused
////
////                    if let destination = dvc as? MediaViewController {
////                        destination.selectedMediaItem = globals.mediaPlayer.mediaItem
////                    }
//                }
                
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

    func showHide()
    {
        //It works!  Problem was in globals.mediaPlayer.controller?.player?.removeFromSuperview() in viewWillDisappear().  Moved it to viewWillAppear()
        //Thank you StackOverflow!
        
        //        globals.mediaPlayer.controller?.player?.setFullscreen(!globals.mediaPlayer.controller?.player!.isFullscreen, animated: true)
        
        if splitViewController?.viewControllers.count > 1 {
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
                if globals.mediaPlayer.fullScreen {
                    globals.mediaPlayer.fullScreen = false
                }
                break
            }

            Thread.onMainThread() {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            }

//            setupShowHide()
        }
    }
 
//    func setupShowHide()
//    {
//        guard Thread.isMainThread else {
//            alert(viewController:self,title: "Not Main Thread", message: "MediaTableViewController:setupShowHide", completion: nil)
//            return
//        }
//        
//        if let isCollapsed = splitViewController?.isCollapsed, isCollapsed {
//            print("splitViewController.isCollapsed == true")
//        }
//        
//        if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//            let vClass = self.splitViewController?.traitCollection.verticalSizeClass {
//            if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                navigationItem.rightBarButtonItem = nil
//                return
//            }
//        }
//
//        if (splitViewController?.viewControllers.count > 1) { //  && isFullScreen
//            switch splitViewController!.displayMode {
//            case .automatic:
//                navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                break
//                
//            case .primaryHidden:
//                navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                break
//                
//            case .allVisible:
//                navigationItem.setRightBarButton(UIBarButtonItem(title: "Hide", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                break
//                
//            case .primaryOverlay:
//                navigationItem.setRightBarButton(UIBarButtonItem(title: "Show", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaTableViewController.showHide)),animated: true)
//                break
//            }
//        } else {
//            navigationItem.setRightBarButton(nil,animated: true)
//        }
//
//        navigationItem.rightBarButtonItem?.isEnabled = !globals.isRefreshing && !globals.isLoading
//    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        var livc : LexiconIndexViewController?
        
        if let viewControllers = navigationController?.viewControllers {
            for viewController in viewControllers {
                if let _ = viewController as? LexiconIndexViewController {
                    livc = viewController as? LexiconIndexViewController
                }
            }
        }
        
        var sivc : ScriptureIndexViewController?
        
        if let viewControllers = navigationController?.viewControllers {
            for viewController in viewControllers {
                if let _ = viewController as? ScriptureIndexViewController {
                    sivc = viewController as? ScriptureIndexViewController
                }
            }
        }
        
        let wasNotFullScreen = !UIApplication.shared.isRunningInFullScreen()
        
        if DeviceType.IS_IPHONE_6P_7P {
            tableView.reloadData()
        }
        
        if wasNotFullScreen || (DeviceType.IS_IPHONE_6P_7P) {
            // This is a HACK.
            
            // If the Scripture VC or Lexicon VC is showing and the SplitViewController has ONE viewController showing (i.e. the SVC or LVC) and
            // the device is rotation and the SplitViewController will show TWO viewControllers when it finishes, then the SVC or LVC will be 
            // put in the detail view controller's position!
            
            // Unfortuantely I know of NO way to determine if the device is rotating or whether the split view controller is going from one view controller to two.
            
            // So, since this is called for situations that DO NOT involve rotation or changes in the number of split view controller's view controllers, this
            // causes popping to root in lots of other cases where I wish it did not.
            
            if (livc != nil) || (sivc != nil) {
                _ = self.navigationController?.popToRootViewController(animated: false)
            }
            
            if presentingVC?.popoverPresentationController?.presentationStyle == .popover {
                self.dismiss(animated: true, completion: {
                    self.presentingVC = nil
                })
            }
        }
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in

        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
//            self.setupShowHide()
            self.setupTitle()
            
//            if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
//                print("splitViewController.isCollapsed == true")
//            }
            
//            self.setDVCLeftBarButton()
//            if  let hClass = self.splitViewController?.traitCollection.horizontalSizeClass,
//                let vClass = self.splitViewController?.traitCollection.verticalSizeClass,
//                let count = self.splitViewController?.viewControllers.count {
//                if let navigationController = self.splitViewController?.viewControllers[count - 1] as? UINavigationController {
//                    if (hClass == UIUserInterfaceSizeClass.regular) && (vClass == UIUserInterfaceSizeClass.compact) {
//                        navigationController.topViewController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
//                    }
//                }
//            }
        }
    }
}

extension MediaTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return globals.display.section.headers != nil ? globals.display.section.headers!.count : 0
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if globals.display.section.headers != nil {
            if section >= 0, section < globals.display.section.headers!.count {
                return globals.display.section.headers![section]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if globals.display.section.counts != nil {
            if section >= 0, section < globals.display.section.counts!.count {
                return globals.display.section.counts![section]
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        cell.vc = self
        
        cell.searchText = globals.search.active ? globals.search.text : nil
        
        // Configure the cell
        if (globals.display.section.indexes != nil) && (globals.display.mediaItems != nil) {
            if indexPath.section >= 0, indexPath.section < globals.display.section.indexes!.count {
                if let section = globals.display.section.indexes?[indexPath.section] {
                    if (section + indexPath.row) >= 0,(section + indexPath.row) < globals.display.mediaItems!.count {
                        cell.mediaItem = globals.display.mediaItems?[section + indexPath.row]
                    }
                } else {
                    print("No mediaItem for cell!")
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section >= 0, section < globals.display.section.headers?.count, let title = globals.display.section.headers?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).height
        
//        print(height,max(Constants.HEADER_HEIGHT,height + 28))
        
        return max(Constants.HEADER_HEIGHT,height + 28)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
//            print(header.textLabel?.text)
            header.textLabel?.text = nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var view : MediaTableViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MediaTableViewController") as? MediaTableViewControllerHeaderView
        if view == nil {
            view = MediaTableViewControllerHeaderView()
        }
        
        if section >= 0, section < globals.display.section.headers?.count, let title = globals.display.section.headers?[section] {
            view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            if view?.label == nil {
                view?.label = UILabel()
                
                view?.label?.numberOfLines = 0
                view?.label?.lineBreakMode = .byWordWrapping
                
                view?.label?.translatesAutoresizingMaskIntoConstraints = false
                
                view?.addSubview(view!.label!)
                
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":view!.label!]))
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":view!.label!]))
            }
            
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold)

            view?.alpha = 0.85
        }

        return view
    }
}

extension MediaTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate

//    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
//    {
//        return .none
//    }

//    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
//        return false
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
//        print("didSelect")

        if globals.mediaPlayer.fullScreen {
            globals.mediaPlayer.fullScreen = false
        }

        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
//            print(selectedMediaItem)
        } else {
            
        }
    }
    
    func tableView(_ tableView:UITableView, willBeginEditingRowAt indexPath: IndexPath)
    {
        // Tells the delegate that the table view is about to go into editing mode.
        Thread.onMainThread() {
            self.searchBar.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView:UITableView, didEndEditingRowAt indexPath: IndexPath?)
    {
        // Tells the delegate that the table view has left editing mode.
        if changesPending {
            Thread.onMainThread() {
                self.tableView?.reloadData()
            }
        }
        
        changesPending = false
    }
    
    func tableView(_ tableView:UITableView, didDeselectRowAt indexPath: IndexPath) {
//        print("didDeselect")

//        if let cell: MediaTableViewCell = tableView?.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        } else {
//            
//        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true // actionsAtIndexPath(tableView, indexPath: indexPath) != nil <- This casues a recursive loop on cellForRowAt indexPath
    }
    
//    func authentication()
//    {
//        var request = URLRequest(url: URL(string: Constants.SCRIPTURE_BASE_URL)!)
//        request.httpMethod = "GET"
//        
//        let task = URLSession.shared.dataTask(with: request) {
//            data, response, error in
//            
//            if error != nil {
//                print("error=\(String(describing: error))")
//                return
//            }
//            
//            print("response = \(String(describing: response))")
//            
//            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//            print("responseString = \(String(describing: responseString))")
//        }
//        task.resume()
//    }

    func actionsAtIndexPath(_ tableView: UITableView, indexPath:IndexPath) -> [UITableViewRowAction]?
    {
        guard Thread.isMainThread else {
            return nil
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell else {
            return nil
        }
        
//        var mediaItem : MediaItem!
//        
//        if (globals.display.section.indexes != nil) && (globals.display.mediaItems != nil) {
//            if indexPath.section >= 0, indexPath.section < globals.display.section.indexes!.count {
//                if let section = globals.display.section.indexes?[indexPath.section] {
//                    if (section + indexPath.row) >= 0,(section + indexPath.row) < globals.display.mediaItems!.count {
//                        mediaItem = globals.display.mediaItems?[section + indexPath.row]
//                    }
//                } else {
//                    print("No mediaItem for cell!")
//                }
//            }
//        }

        guard let mediaItem = cell.mediaItem else {
            return nil
        }
        
        var search:UITableViewRowAction!
        var transcript:UITableViewRowAction!
        var recognizeAudio:UITableViewRowAction!
        var recognizeVideo:UITableViewRowAction!
        var words:UITableViewRowAction!
        var scripture:UITableViewRowAction!
        
        var actions = [UITableViewRowAction]()
        
        search = UITableViewRowAction(style: .normal, title: Constants.FA.SEARCH) { action, index in
            if let searchStrings = mediaItem.searchStrings(),
                let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: {
                    self.presentingVC = nil
                })
                
                navigationController.modalPresentationStyle = .popover
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.sourceView = cell.subviews[0]
                navigationController.popoverPresentationController?.sourceRect = cell.subviews[0].subviews[actions.index(of: search)!].frame
                
                popover.navigationItem.title = Constants.Strings.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.section.strings = searchStrings
//                
//                popover.section.showIndex = false
//                popover.section.showHeaders = false
                
                popover.vc = self.splitViewController
                
                self.present(navigationController, animated: true, completion:{
                    self.presentingVC = navigationController
                })
            }
        }
        search.backgroundColor = UIColor.controlBlue()
        
        func transcriptTokens()
        {
            guard Thread.isMainThread else {
                return
            }

            guard let tokens = mediaItem.notesTokens?.map({ (string:String,count:Int) -> String in
                return "\(string) (\(count))"
            }).sorted() else {
                networkUnavailable(self,"HTML transcript vocabulary unavailable.")
                return
            }
        
            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                self.dismiss(animated: true, completion: {
                    self.presentingVC = nil
                })
                
                navigationController.modalPresentationStyle = .overCurrentContext
                navigationController.popoverPresentationController?.permittedArrowDirections = .any // [.up,.down]
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.sourceView = cell.subviews[0]
                navigationController.popoverPresentationController?.sourceRect = cell.subviews[0].subviews[actions.index(of: words)!].frame
                
                popover.navigationItem.title = Constants.Strings.Search
                
                popover.navigationController?.isNavigationBarHidden = false
                
                popover.parser = { (string:String) -> [String] in
                    return [string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.UNBREAKABLE_SPACE)]
                }
                
                popover.delegate = self
                popover.purpose = .selectingCellSearch
                
                popover.selectedMediaItem = mediaItem
                
                popover.section.showIndex = true
//                popover.section.showHeaders = true
                
                popover.section.strings = tokens
                
                popover.vc = self.splitViewController
                
                popover.segments = true
                
                popover.sort.function = sort
                popover.sort.method = Constants.Sort.Alphabetical
                
                var segmentActions = [SegmentAction]()
                
                segmentActions.append(SegmentAction(title: Constants.Sort.Alphabetical, position: 0, action: {
                    popover.sort.method = Constants.Sort.Alphabetical
                    popover.section.showIndex = true
                    popover.section.strings = popover.sort.function?(popover.sort.method,popover.section.strings)
                    popover.tableView?.reloadData()
                }))
                segmentActions.append(SegmentAction(title: Constants.Sort.Frequency, position: 1, action: {
                    popover.sort.method = Constants.Sort.Frequency
                    popover.section.showIndex = false
                    popover.section.strings = popover.sort.function?(popover.sort.method,popover.section.strings)
                    popover.tableView?.reloadData()
                }))
                
                popover.segmentActions = segmentActions.count > 0 ? segmentActions : nil

                popover.search = popover.section.strings?.count > 10

                present(navigationController, animated: true, completion: {
                    self.presentingVC = navigationController
                })
            }
        }
        
        words = UITableViewRowAction(style: .normal, title: Constants.FA.WORDS) { action, index in
            if mediaItem.hasNotesHTML {
                if mediaItem.notesTokens == nil {
                    guard globals.reachability.currentReachabilityStatus != .notReachable else {
                        networkUnavailable(self,"HTML transcript words unavailable.")
                        return
                    }
                    
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
                
                if globals.search.valid && globals.search.transcripts {
                    htmlString = mediaItem.markedFullNotesHTML(searchText:globals.search.text, wholeWordsOnly: false, index: true)
                } else {
                    htmlString = mediaItem.fullNotesHTML
                }
                
                popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
            } else {
                guard globals.reachability.currentReachabilityStatus != .notReachable else {
                    networkUnavailable(self,"HTML transcript unavailable.")
                    return
                }
                
                process(viewController: self, work: { () -> (Any?) in
                    mediaItem.loadNotesHTML()
                    if globals.search.valid && globals.search.transcripts {
                        return mediaItem.markedFullNotesHTML(searchText:globals.search.text, wholeWordsOnly: false,index: true)
                    } else {
                        return mediaItem.fullNotesHTML
                    }
                }, completion: { (data:Any?) in
                    if let htmlString = data as? String {
                        popoverHTML(self,mediaItem:mediaItem,title:nil,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                    } else {
                        networkUnavailable(self,"HTML transcript unavailable.")
                    }
                    
                    //                presentHTMLModal(viewController: self,medaiItem: mediaItem, title: globals.contextTitle, htmlString: data as? String) //
                })
            }
        }
        transcript.backgroundColor = UIColor.purple
        
        recognizeAudio = mediaItem.audioTranscript?.recognizeRowActions(viewController:self,tableView:tableView) // recognizeTVTRA(transcript: mediaItem.audioTranscript)
        recognizeVideo = mediaItem.videoTranscript?.recognizeRowActions(viewController:self,tableView:tableView) // recognizeTVTRA(transcript: mediaItem.videoTranscript)
        
        scripture = UITableViewRowAction(style: .normal, title: Constants.FA.SCRIPTURE) { action, index in
            let sourceView = cell.subviews[0]
            let sourceRectView = cell.subviews[0].subviews[actions.index(of: scripture)!]
            
            if let reference = mediaItem.scriptureReference {
                //                mediaItem.scripture?.html?[reference] = nil // REMOVE THIS LATER
                
                if mediaItem.scripture?.html?[reference] != nil {
                    popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:mediaItem.scripture?.html?[reference])
                } else {
                    guard globals.reachability.currentReachabilityStatus != .notReachable else {
                        networkUnavailable(self,"Scripture text unavailable.")
                        return
                    }

                    process(viewController: self, work: { () -> (Any?) in
                        mediaItem.scripture?.loadJSON() // mediaItem.scripture?.reference
                        return mediaItem.scripture?.html?[reference]
                    }, completion: { (data:Any?) in
                        if let htmlString = data as? String {
                            popoverHTML(self,mediaItem:nil,title:reference,barButtonItem:nil,sourceView:sourceView,sourceRectView:sourceRectView,htmlString:htmlString)
                        } else {
                            networkUnavailable(self,"Scripture text unavailable.")
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

        if mediaItem.audioTranscript?.transcript != nil {
            recognizeAudio.backgroundColor = UIColor.lightGray
            actions.append(recognizeAudio)
        } else {
            if let transcribing = mediaItem.audioTranscript?.transcribing, transcribing {
                recognizeAudio.backgroundColor = UIColor.gray
                actions.append(recognizeAudio)
            } else {
                if mediaItem.hasAudio && globals.allowMGTs {
                    recognizeAudio.backgroundColor = UIColor.darkGray
                    actions.append(recognizeAudio)
                }
            }
        }
        
        if mediaItem.videoTranscript?.transcript != nil {
            recognizeVideo.backgroundColor = UIColor.lightGray
            actions.append(recognizeVideo)
        } else {
            if let transcribing = mediaItem.videoTranscript?.transcribing, transcribing {
                recognizeVideo.backgroundColor = UIColor.gray
                actions.append(recognizeVideo)
            } else {
                if mediaItem.hasVideo && globals.allowMGTs {
                    recognizeVideo.backgroundColor = UIColor.darkGray
                    actions.append(recognizeVideo)
                }
            }
        }
    
        return actions.count > 0 ? actions : nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        return actionsAtIndexPath(tableView, indexPath: indexPath)
    }
    
    /*
     // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath)
    {
        switch editingStyle {
        case .delete:
            // Delete the row from the data source
            tableView?.deleteRows(at: [indexPath], with: .fade)
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
